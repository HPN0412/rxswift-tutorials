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

### 2.2. Observer - handler

### 2.3. Operator - man in the middle

## 3. Deep Dive

### 3.1. Creation

Có một vài cách để tạo **Observable**

#### 3.1.1. just

Tạo một *Observable* với một *single element*.

![just.c](resources/imgs/just.c.png)

`just` chuyển đổi một *item* vào trong một **Observable** mà sẽ phát ra chính *item* đó.

**Examples**

```swift
import RxSwift

Observable.just("🔴")
    .subscribe { event in
        print(event)
    }.dispose()
```

```swift
// Kết quả
next(🔴)
completed
```

```swift
import RxSwift
import RxCocoa
import UIKit

weak var label: UILabel!

func setupLabel() {
	let observable = Observable.just("This is text")
    .subscribe(onNext: { text in
        label.text = text
    })
}
```

#### 3.1.2. from

Tạo một *Observable* từ một *Sequence* như Array, Dictionary hay Set.

![from.c](resources/imgs/from.c.png)

Một hàm khởi tạo *Observable* quan trọng, khi làm việc với *Observable* có thể dễ dàng biểu diễn dự liệu của ứng dụng sang **Observable**.

**Examples**

```swift
import RxSwift
Observable.from(["🐶", "🐱", "🐭", "🐹"])
    .subscribe(onNext: { print($0) })
    .dispose()
```

```swift
// Kết quả
🐶
🐱
🐭
🐹
```

```swift
import RxSwift
import RxCocoa
import UIKit

// Need examples for iOS
```

#### 3.1.3. create

Tạo một custom **Observable** với input bất kỳ với **create**.

![create.c](resources/imgs/create.c.png)

Tạo một custom **Observable** với đầu vào bất kì, và custom lúc nào gọi **observer** handle sự kiện (onNext, onError, onComplete)

Examples**

```swift
import RxSwift

let disposeBag = DisposeBag()    
let myJust = { (element: String) -> Observable<String> in
    // return một Observable custom
    return Observable.create { observer in
        // Biến đổi input element
        let newElement = "New: \(element)"
        
        // Gọi observer handle sự kiện next
        observer.on(.next(newElement))
        // Gọi observer handle sự kiện completion
        observer.on(.completed)
        return Disposables.create()
    }
}
myJust("🔴")
.subscribe { print($0) }
.disposed(by: disposeBag)
```

```swift
// Kết quả
next(New: 🔴)
completed
```

```swift
import RxSwift
import RxCocoa
import UIKit

weak var usernameTextField: UITextField!
weak var passwordTextField: UITextField!
weak var loginButton: UIButton!

// Custom một Observable
let userObservable = { (username, password) -> Observable<User> in
    return Observable.create { observer in 
               let user = User(username: username, password: password)
               observer.onNext(user)
               return Disposables.create()
           }
}

func setupObservable() {
  // Observables
  let username = usernameTextField.rx.text.orEmpty
  let password = passwordTextField.rx.text.orEmpty
  let loginTap = loginButton.rx.tap.asObservable()
  
  // Đọc thêm phần combineLatest
  let combineLastestData = Observable.combineLatest(username, password) { ($0, $1) }
  
  let loginObservable: Observable<User> = loginTap
                                          .withLatestFrom(combineLastestData)
                                          .flatMapLatest { (username, password) in
                                              return userObservable(username, password) 
                                          }

  loginObservable.bind { [weak self] user in
      // Call API With User
  }.dispose()
}

final class User {
    let username: String = ""
    var password: String?

    init(username: String, password: String? = nil) {
        self.username = username
        self.password = password
    }
}

```

#### 3.1.x. of

#### 3.1.x. empty

Tạo một *Observable* mà chỉ phát ra một **Completed** event.

#### 3.1.x. never

Tạo một *Observable* mà không phát ra bất kì events và cũng không kết thúc

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



