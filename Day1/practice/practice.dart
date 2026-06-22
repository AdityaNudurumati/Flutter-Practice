void main(){
  var x = 1;
  x = 3;
  print(x);
  int y = 2;
  y = 1;
  print(y);
  num z = -1;
  z = 2.3;
  print(z);
  dynamic xx = 'sita';
  xx = 2.0;
  Object yy = 'xy';
  yy = 21;
}

void list(){
  final numbers = <int>[1,2,3,4,5];
  print("original list: $numbers");
  numbers.add(6);
  print("6 Added:$numbers");
  numbers.remove(4);
  print("4 removed: $numbers");
  numbers.insert(0,0);
  print("0 inserted at 0: $numbers");
  numbers.removeAt(1);
  print("element at index 1 removed:$numbers");
  print("first: ${numbers.first} last: ${numbers.last} length: ${numbers.length}");
  print("${numbers.indexOf(5)}");
  print("${numbers.contains(4)}");
  
  final words = <String>['apple','cherry','banana','carrot'];
  words.sort();
  print(words);
  words.sort((a,b)=>a.compareTo(b));
  print(words);
  words.sort((a,b)=>b.length.compareTo(a.length));
  print(words);
  final combinedList = [...numbers, ...words];
  print(combinedList);
  print(combinedList.runtimeType);
  for(final item in combinedList){
    print(item);
    if(item == 'carrot') break;
  }
  for(var i=0;i<numbers.length;i++){
    print("$i : ${numbers[i]}");
  }
}

void sets(){
  final a = {1,2,3,4,5};
  final b = {4,5,6,7,8};
  print("${a.union(b)}");
  print("${a.intersection(b)}");
  print("${a.difference(b)}");
  print("${a.contains(3)}");
  final c = [1,2,3,'a','b',2,3,4];
  final uniqueC = c.toSet().toList();
  print(uniqueC);
}

void maps(){
  final score = {'aditya':84,'sai':89,'ram':76};
  score['dan'] = score['dan'] ?? 72;
  print(score['aditya']);
  print(score['dan']);
  score.putIfAbsent('santhosh',()=>50);
  print(score);
  score.update('bob',(v)=>v+=5, ifAbsent:()=>0);
  print(score);
  score.forEach((key,value)=>print("$key - $value"));
  print("${score.keys.toList()}");
  print("${score.values.toList()}");
  print("${score.entries.map((e)=>'${e.key} - ${e.value}').join(', ')}");
}

void transformations(){
  final nums = [1,2,3,4,5,6,7,8,9,10];
  final squares = nums.map((n)=>n*n).toList();
  print(squares);
  final even = nums.where((n)=>n.isEven).toList();
  print(even);
  final evenSquared = nums.where((n)=>n.isEven).map((n)=>n*n).toList();
  print(evenSquared);
  
  final sum = nums.fold(0,(acc,n)=>acc+n);
  print(sum);
  final joined = nums.fold("",(acc,n)=>acc==""?"$n":"$acc $n");
  print(joined);
  
  final product = nums.reduce((acc,n)=>acc+n);
  print(product);
  
  print("${nums.any((n)=>n>9)}");
  print("${nums.every((n)=>n>0)}");
}