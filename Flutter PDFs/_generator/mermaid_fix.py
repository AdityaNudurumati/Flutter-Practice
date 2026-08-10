"""Repair the hand-written mermaid in the notes so it parses.

The notes contain a few recurring syntax mistakes that mermaid rejects outright,
which would otherwise leave a wall of diagram source in the PDF:

  * node labels containing `()`, `,`, `:`, `/` that are not quoted
  * `subgraph` titles with spaces/punctuation that are not quoted
  * class-diagram relations (`<|--`, `*--`, ...) used inside a `flowchart`

Every rule here is mechanical and preserves the author's wording.
"""
import re

# ---------------------------------------------------------------- flowcharts

# node shapes, longest delimiters first so `[[x]]` is not read as `[x]`
NODE_DELIMS = [("[[", "]]"), ("[(", ")]"), ("((", "))"), ("{{", "}}"),
               ("[", "]"), ("(", ")"), ("{", "}")]
PAIRS = {"[": "]", "(": ")", "{": "}"}
IDENT = re.compile(r"[A-Za-z_][\w-]*")
# lines that are directives rather than nodes
DIRECTIVE = re.compile(r"^\s*(subgraph|end|style|classDef|class|click|linkStyle|"
                       r"direction|flowchart|graph|%%)\b")
EDGE_LABEL = re.compile(r"\|(.+?)\|")
# `A -- some text --> B`: the text may not be quoted, so strip what breaks it
MID_LABEL = re.compile(r"(\s-{2,3}\s)([^-|>][^|]*?)(\s-{1,3}[->])")

CLASS_ARROWS = [
    (re.compile(r"\s<\|\.\.\s"), " <-.- "),   # implements
    (re.compile(r"\s<\|--\s"), " <-- "),      # inherits
    (re.compile(r"\s\.\.\|>\s"), " -.-> "),
    (re.compile(r"\s--\|>\s"), " --> "),
    (re.compile(r"\s\*--\s"), " --> "),       # composition
    (re.compile(r"\so--\s"), " --> "),        # aggregation
    (re.compile(r"\s\.\.>\s"), " -.-> "),     # dependency
]

SUBGRAPH = re.compile(r"^(\s*)subgraph\s+(.+?)\s*$")
SENTINEL = "%d"   # private-use chars: cannot occur in the notes

# ---------------------------------------------------------------- sequences

PARTICIPANT = re.compile(r"^(\s*)(participant|actor)\s+(\S+)\s+as\s+(.+?)\s*$")
NOTE = re.compile(r"^(\s*note\s+(?:over|left of|right of)\s+[^:]+:\s*)(.+?)\s*$", re.I)
SEQ_MSG = re.compile(r"^(\s*\S+\s*-{1,2}>>?[+-]?\s*\S+\s*:\s*)(.+?)\s*$")
BLOCK_KW = re.compile(r"^(\s*(?:alt|else|opt|loop|par|and|critical|rect|box)\s+)(.+?)\s*$")


def _quote(label):
    """Wrap a label in quotes unless it already is, escaping inner quotes."""
    label = label.strip()
    if len(label) >= 2 and label[0] == '"' and label[-1] == '"':
        return label
    return '"%s"' % label.replace('"', "'")


def _plain(text):
    """Strip characters mermaid's lexer rejects in an unquotable position."""
    text = re.sub(r"-{1,2}>{1,2}|→", "→", text)   # arrows in prose break the lexer
    return re.sub(r"[()\[\]{}<>;]", "", text).strip()


def _scan_label(line, start, open_d, close_d):
    """Return the index just past the delimiter closing `open_d` at `start`.

    Counts nesting on the outer bracket character so labels that themselves
    contain brackets — `X[ListView(children:[10k])]` — close in the right place.
    """
    outer, shut = open_d[0], PAIRS[open_d[0]]
    depth, i = 1, start + len(open_d)
    while i < len(line):
        ch = line[i]
        if ch == outer:
            depth += 1
        elif ch == shut:
            depth -= 1
            if depth == 0:
                end = i + 1
                # the close delimiter may be wider than one char, e.g. `)]`
                if len(close_d) > 1:
                    if line[end - len(close_d):end] != close_d:
                        return -1
                return end
        i += 1
    return -1


def _quote_nodes(line, park):
    """Quote the label of every node on the line, leaving structure untouched."""
    out, i = [], 0
    while i < len(line):
        m = IDENT.match(line, i)
        if not m or (i > 0 and (line[i - 1].isalnum() or line[i - 1] in '_"')):
            out.append(line[i])
            i += 1
            continue

        rest_at = m.end()
        delim = next((d for d in NODE_DELIMS if line.startswith(d[0], rest_at)), None)
        if not delim:
            out.append(m.group(0))
            i = rest_at
            continue

        open_d, close_d = delim
        end = _scan_label(line, rest_at, open_d, close_d)
        if end == -1:                      # unbalanced — leave the text alone
            out.append(m.group(0))
            i = rest_at
            continue

        label = line[rest_at + len(open_d):end - len(close_d)]
        out.append(park("%s%s%s%s" % (m.group(0), open_d, _quote(label), close_d)))
        i = end
    return "".join(out)


def _fix_flow_line(line):
    line = SUBGRAPH.sub(_fix_subgraph, line)
    for pat, repl in CLASS_ARROWS:
        line = pat.sub(repl, line)
    if DIRECTIVE.match(line):
        return line

    # Park edge labels before touching nodes: their text often contains
    # `foo(bar)`, which the round-node rule would otherwise read as a node.
    parked = []

    def park(text):
        parked.append(text)
        return SENTINEL % (len(parked) - 1)

    line = EDGE_LABEL.sub(lambda m: park("|%s|" % _quote(m.group(1))), line)
    line = _quote_nodes(line, park)
    line = MID_LABEL.sub(lambda m: m.group(1) + _plain(m.group(2)) + m.group(3), line)

    for i, text in enumerate(parked):
        line = line.replace(SENTINEL % i, text)
    return line


def _fix_subgraph(m):
    indent, title = m.groups()
    if not title or title.startswith('"'):
        return m.group(0)
    if re.match(r"^[\w-]+\[.*\]$", title):   # `subgraph id[Title]` is valid
        return m.group(0)
    if re.match(r"^[\w-]+$", title):         # bare single-word id is valid
        return m.group(0)
    return '%ssubgraph "%s"' % (indent, title.replace('"', "'"))


def _fix_seq_line(line):
    for pat in (PARTICIPANT,):
        m = pat.match(line)
        if m:
            indent, kw, ident, alias = m.groups()
            return "%s%s %s as %s" % (indent, kw, ident, _plain(alias))
    for pat in (NOTE, SEQ_MSG, BLOCK_KW):
        m = pat.match(line)
        if m:
            return m.group(1) + _plain(m.group(2))
    return line


def fix(src):
    lines = src.replace("\r\n", "\n").split("\n")
    head = next((l.strip() for l in lines if l.strip()), "")
    kind = head.split()[0] if head else ""

    if kind in ("flowchart", "graph"):
        return "\n".join(_fix_flow_line(l) for l in lines)
    if kind == "sequenceDiagram":
        return "\n".join(_fix_seq_line(l) for l in lines)
    return "\n".join(lines)
