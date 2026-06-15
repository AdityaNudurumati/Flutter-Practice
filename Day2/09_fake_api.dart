// =============================================================================
// Day 2 · Part 9 — Fake API + loading / error / success states
// Run: dart run Day2/09_fake_api.dart
// =============================================================================
//
// Goal: model a real Flutter data flow WITHOUT Flutter. A repository exposes
// getPosts() -> Future<List<Post>>, simulates network latency, and THROWS on
// failure (or empty). The CALLER drives an explicit LOADING -> SUCCESS/ERROR
// state — exactly what a FutureBuilder / BLoC / Cubit does in a real app.
// =============================================================================

import 'dart:async';

Future<void> main() async {
  final api = FakeApi();

  // Try a few scenarios so you see every branch of the state machine.
  await loadAndRender(api, scenario: 'ok'); // SUCCESS with data
  await loadAndRender(api, scenario: 'empty'); // throws -> ERROR
  await loadAndRender(api, scenario: 'network'); // throws -> ERROR
}

// The CALLER. This is the loading/error/success pattern in plain Dart.
// In Flutter this maps 1:1 to: setState(loading) -> await -> setState(data/error),
// or a Cubit emitting Loading/Success/Failure states.
Future<void> loadAndRender(FakeApi api, {required String scenario}) async {
  print('\n=== scenario: $scenario ===');

  PostsState state = const PostsLoading(); // 1. LOADING
  render(state);

  try {
    final posts = await api.getPosts(scenario: scenario);
    state = PostsSuccess(posts); // 2. SUCCESS
  } on EmptyResultException catch (e) {
    state = PostsError('No posts: ${e.message}'); // 3a. ERROR (empty)
  } on ApiException catch (e) {
    state = PostsError('Request failed: ${e.message}'); // 3b. ERROR (network)
  } catch (e) {
    state = PostsError('Unexpected: $e'); // 3c. safety net
  }

  render(state);
}

// Render the current state. Switch over the sealed hierarchy => exhaustive.
void render(PostsState state) {
  switch (state) {
    case PostsLoading():
      print('[UI] spinner...');
    case PostsSuccess(:final posts):
      print('[UI] showing ${posts.length} posts:');
      for (final p in posts) {
        print('     - #${p.id} ${p.title}');
      }
    case PostsError(:final message):
      print('[UI] error banner: $message');
  }
}

// ---- The fake API / repository --------------------------------------------
class FakeApi {
  // Returns a Future<List<Post>>. Simulates latency, then succeeds or throws.
  Future<List<Post>> getPosts({String scenario = 'ok'}) async {
    await Future.delayed(const Duration(seconds: 1)); // simulate the network

    switch (scenario) {
      case 'network':
        throw ApiException('500 Internal Server Error');
      case 'empty':
        final data = <Post>[];
        if (data.isEmpty) throw EmptyResultException('server returned 0 rows');
        return data;
      default:
        return const [
          Post(1, 'Dart Futures explained'),
          Post(2, 'Streams vs Futures'),
          Post(3, 'Why isolates matter'),
        ];
    }
  }
}

// ---- Model -----------------------------------------------------------------
class Post {
  final int id;
  final String title;
  const Post(this.id, this.title);
}

// ---- Exceptions ------------------------------------------------------------
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
}

class EmptyResultException implements Exception {
  final String message;
  EmptyResultException(this.message);
}

// ---- UI state (a sealed class = exhaustive switch, like a Cubit's states) --
sealed class PostsState {
  const PostsState();
}

class PostsLoading extends PostsState {
  const PostsLoading();
}

class PostsSuccess extends PostsState {
  final List<Post> posts;
  const PostsSuccess(this.posts);
}

class PostsError extends PostsState {
  final String message;
  const PostsError(this.message);
}
