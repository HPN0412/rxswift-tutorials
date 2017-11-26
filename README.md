[TOC]

## 1. Approach



### 1.1. Delegation

```swift
let dev = Developer()
// dev.leader = Leader()
dev.start() // How can developer refer leader for decision making? 
```

```swift
private protocol DeveloperDelegation {
    func me(_ me: Developer, shouldStart task: Task) -> YesNo
}
```

```swift
private class Leader: DeveloperDelegation {
    func me(_ me: Developer, shouldStart task: Task) -> YesNo {
        switch task {
        case .implement(_): return Yes
        case .report:       return Yes
        case .drinkBeer:    return No
        }
    }
}
```

```swift
private class Developer {
    var leader: DeveloperDelegation!
    var tasks: [Task] = [.implement(taskId: "123"), .implement(taskId: "456"), .report, .drinkBeer]
    
    func start() {
        for task in tasks {
            guard leader.me(self, shouldStart: task) else { continue }
            start(task)
        }
        stop()
    }
    
    func start(_ task: Task) { }
    
    func stop() { }
}
```



### 1.2. Callback

The delegation is clear enough.

But, sometime:

- There's only one case in definition
- The refer's process only, no referenced subject is needed

Callback (completion block) is created for this.

```swift
let dev = Developer()
dev.start(.implement(taskId: "123"), completion: { result in
    switch result {
    case .merged:
        dev.start(.drinkBeer, completion: nil)
    case .rejected:
        dev.start(.report, completion: nil)
    }
})
```



### 1.3. Functional

```swift
typealias Minutes = Double
struct Ride {
    let name: String
    let categories: Set<RideCategory>
    let waitTime: Minutes
}
```

```swift
extension Array where Element == Ride {
    // imperative programming with insertion sort
    func _sortedNames() -> [String] {
        var names = [String]()
        for ride in self {
            names.append(ride.name)
        }
        for (i, name) in names.enumerated() {
            for j in stride(from: i, to: -1, by: -1) {
                if name.localizedCompare(names[j]) == .orderedAscending {
                    names.remove(at: i)
                    names.insert(name, at: j)
                }
            }
        }
        return names
    }

    // functional programming - what's order rule? that's all
    func sortedNames() -> [String] {
        return map { ride in ride.name }
            .sorted { s1, s2 in s1.localizedCompare(s2) == .orderedAscending }
    }
}
```



### 1.4. Promise

Promise - the golden path keeper & nested callback avoiding.

Implementation:

```swift
private class Developer {
    // via regular way
    func start(_ task: Task, completion: ((TaskResult) -> Void)?) {
        completion(.merged) // or
        completion(.rejected)
    }

    // via promise
    @discardableResult
    func start(_ task: Task) -> Promise<TaskResult> {
        return Promise { fulfill, reject in
            fulfill(.merged) // or
            reject(Issue.bug)
        }
    }
}
```

Usage:

```swift
let dev = Developer()
// via regular way
dev.start(.implement(taskId: "123"), completion: { result in
    switch result {
    case .merged:
        dev.start(.drinkBeer, completion: nil)
    case .rejected:
        dev.start(.report, completion: nil)
    }
})
// via promise
dev.start(.implement(taskId: "123"))
    .then { _ in dev.start(.drinkBeer) }
    .catch { _ in dev.start(.report) }
```



### 1.5. Reactive



## 2. Getting Started

### 2.1. Observable - starter

> Khái niệm observable đến từ observer design pattern là một đối tượng thông báo cho các đối tượng theo dõi về một điều gì đó đang diễn ra. [source](https://xgrommx.github.io/rx-book/content/observable/index.html#)

- Diagrams dưới đây đại diện cho  `Observables` và quá trình biến đổi của `Observables`:

![Observable-diagram](./Images/Observable-diagram.png)

- Trong [ReactiveX](http://reactivex.io/documentation/observable.html), một `observer` đăng ký một `Observable` sau đó `observer` sẽ phản ứng lại bất cứ item hay chuỗi các item mà `Observable` phát ra. Phần nãy sẽ giải thích reactive parttern là gì? `Observables`, `observers` là gì? và làm thế nào các `observers` đăng ký với `Observables`. 

#### 2.1.1 Mở đầu

- Có nhiều rất nhiều thuật ngữ dùng để mô tả mô hình và thiết kế của lập trình bất đồng bộ. Trong tài liệu này sẽ thống nhất sử dụng những thuật ngữ sau: Một `observer` đăng ký với `Observable`. Một `Observable` phát ra các items hoặc gửi các notifications đến các `observers` bằng cách gọi các `observers` methods, trong các tài liệu khác hoặc các ngữ cảnh khác, đôi lúc chúng ta gọi `observer` là một `subscriber`, `watcher` hoặc `reactor`. Mô hình thường được gọi là [reactor pattern](https://en.wikipedia.org/wiki/Reactor_pattern)

#### 2.1.2 Khởi tạo `Observers`

- Trong mô hình bất đồng bộ, flow sẽ giống như sau:

  1. Define a method that does something useful with the return value from the asynchronous call; this method is part of the `*observer*`.
  2. Define the asynchronous call itself as an `*Observable*`.
  3. Attach the observer to that Observable by *subscribing* it (this also initiates the actions of the Observable).
  4. Go on with your business; whenever the call returns, the observer’s method will begin to operate on its return value or values — the *items* emitted by the Observable.

  ```
  // Khai báo, nhưng không gọi, handler onNext của Subscriber
  // Trong ví dụ này, observer rất đơn giản và chỉ có onNext handler
  def myOnNext = { it -> do sth usefull with it }
  // defines, nhưng ko gọi, Observable
  def myObservable = someObservable(itsParameters);
  // Đăng ký Subscriber(myOnNext) Observable(myObservable), và invokes Observable
  myObservable.subscribe(myOnNext);
  // go on about my business
  ```

- **onNext, onCompleted, và onErrror**

  ​	[The `Subscribe` method](http://reactivex.io/documentation/operators/subscribe.html) là cách bạn kết nối `observer` với `Observable`. observer implement của bạn là tập hợp các methods dưới đây:

  `onNext`: `Observable` gọi hàm này bất cứ khi nào `Observable` phát đi item. Hàm này có tham số là item được phát ra bởi `Observable`.

  `onError`: `Observable` gọi hàm này để biểu thị có lỗi phát sinh trong khi xử lý dữ liệu hoặc có một số lỗi khá. Nó sẽ không gọi thêm đến các hàm `onNext` hoặc `onCompleted`. 

  `onCompleted`: `Observable` gọi hàm này sau khi hàm `onNext` cuối cùng được gọi, nếu không có bất kì lỗi nào xảy ra.

  A more complete `subscribe` call example looks like this:

  ```
  def myOnNext = { item -> /* do something useful with item */ };
  def myError = { throwable -> /* react sensibly to a failed call */ };
  def myComplete = { /* clean up after the final response */ };
  def myObservable = someMethod(itsParameters);
  myObservable.subscribe(myOnNext, myError, myComplete);
  // go on about my business
  ```

- **"Hot" và "Cold" Observable**

  Khi nào observable phát ra chuối các items? Điều đó phụ thuộc vào observable. Một "hot" Observable có thể bắt đầu phát các items ngay khi nó được tạo ra, và sau đó bất kỳ observer sau đó đăng ký tới observable có thể bắt đầu observing. "Cold" observable thì chờ cho đến khi một observer đăng kí vào observable trước khi nó bắt đầu phát ra các items.

  [Read more](http://reactivex.io/documentation/observable.html)

### 2.2. Observer - handler

Sau khi đã khởi tạo **Observable**, thì subcribes **Observable** để nhận các sự kiện (events). Và ở đây, **Observer** dùng để nhận sự kiện mỗi khi có sự kiện phát ra.

**Observers** có thể nhận 3 kiểu sự kiện:

- **next**: Observable có thể có không hoặc nhiều elements nên sẽ có không hoặc nhiều `next` events được gửi tới **Observer** và đây là nơi để **Observer** nhận dữ liệu từ Observable.
- **completed**: nhận sự kiện này khi Observable hoàn thành life-cycle của nó, và không còn phát ra bất kỳ events nào nữa (không vào sự kiện **next** nữa)
- **error**: nhận sự kiện này khi Observable kết thúc với một error và tương tự như *completed*, **Observer** không nhận một sự kiện `next` nào nữa.

Sau khi phát sự kiện *completed* và *error*, thì các dữ liệu của **Observable** sẽ được giải phóng

**return** hàm `subscribe(_ observer: O)`  là **Disposable** dùng để cancel Observable và giải phóng bộ nhớ

**Example**

```swift
let obj = Observable.from(["🐶", "🐱", "🐭", "🐹"]) // Khởi tạo một Observable
obj.subscribe( // Thực hiện subscribe Observable
  onNext: { data in
    print(data) // Nơi nhận dữ liệu của Observer được gửi đi từ Observable
  }, 
  onError: { error in
    print(error) // Nơi nhận error và Observable được giải phóng
  }, 
  onCompleted: {
    print("Completed") // Nhận được sự kiện khi Observable hoàn thành life-cycle và Observable được giải phóng
  })
   .disposed()
```

```swift
🐶
🐱
🐭
🐹
Completed
```

**iOS**

```swift
@IBOutlet weak var textField: UITextField!

override func viewDidLoad() {
  super.viewDidLoad()
  let observable = textField.rx.text.orEmpty // Khởi tạo observable
  observable.subscribe(onNext: { (text) in 
  // Mỗi lần thay đổi text trong textField, Observer sẽ nhận được giá trị text mới của textField.
    print(text)
  })
}
```



### 2.3. Operator - man in the middle
Operators là những phép toán cho phép biển đổi observable thành observable mới để phù hợp với nhu cầu sử dụng

Một số operators cơ bản trong RxSwift được liệt kê tại mục 3.2

**Example 1:**

![Filter](./3.2.2.png)

```swift
let observable = Observable.of(2,30,22,5,60,1) // 1
let newObservable = observable.filter { $0 > 10 } // 2
```
**OUTPUT: 30 22 60**

1. Khởi tạo observable các số nguyên --2--30--22--5--60--1
2. Qua phép filter với điều kiện ($0 > 10). Chúng ta đã có được một observable mới là --30--22--60


**Example 2:**
	Ở ví dụ này chúng ta sử dụng phép filter vào việc tìm kiếm bằng UISearchBar control
	
```swift	
let observable = searchBar.rx.text.orEmpty.asObservable() // 1   

observable.filter { $0.hasPrefix("Number") } // 2
.subscribe(onNext: { (text) in // 3
	// Do something when emit events
})
.disposed(by: disposeBag) // dispose it on deinit.
```
1. Khởi tạo observable thể hiện cho sự thay đổi nội dung của search bar
2. Lọc nội dụng bắt đầu bằng chuỗi `Number`
3. Subcrible một observable để có thể xử lý mỗi khi nội dung search bar thay đổi

## 3. Deep Dive

### 3.1. Creation

### 3.2. Operators

#### 3.2.1. Conditional

#### 3.2.2. Combination

#### 3.2.3. Filtering

#### 3.2.4. Mathematical

#### 3.2.5. Transformation

#### 3.2.6. Time Based

## 4. Testing

### 4.1. RxTest

### 4.2. RxNimble

https://academy.realm.io/posts/testing-functional-reactive-programming-code/

## 5. References



