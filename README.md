<p align="center">
    <a href="http://kitura.io/">
        <img src="https://raw.githubusercontent.com/IBM-Swift/Kitura/master/Sources/Kitura/resources/kitura-bird.svg?sanitize=true" height="100" alt="Kitura">
    </a>
</p>


<p align="center">
    <a href="https://ibm-swift.github.io/Kitura-redis/index.html">
    <img src="https://img.shields.io/badge/apidoc-KituraRedis-1FBCE4.svg?style=flat" alt="APIDoc">
    </a>
    <a href="https://travis-ci.org/IBM-Swift/Kitura-redis">
    <img src="https://travis-ci.org/IBM-Swift/Kitura-redis.svg?branch=master" alt="Build Status - Master">
    </a>
    <img src="https://img.shields.io/badge/os-macOS-green.svg?style=flat" alt="macOS">
    <img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux">
    <img src="https://img.shields.io/badge/license-Apache2-blue.svg?style=flat" alt="Apache 2">
    <a href="http://swift-at-ibm-slack.mybluemix.net/">
    <img src="http://swift-at-ibm-slack.mybluemix.net/badge.svg" alt="Slack Status">
    </a>
</p>

# KituraRedis

KituraRedis is a pure Swift client for interacting with a Redis database.

## Swift version
The latest version of Kitura-redis requires **Swift 4.0.3 or later**. You can download this version of the Swift binaries by following this [link](https://swift.org/download/). Compatibility with other Swift versions is not guaranteed.

## Usage

#### Add dependencies

Add the `Kitura-redis` package to the dependencies within your application’s `Package.swift` file. Substitute `"x.x.x"` with the latest `Kitura-redis` [release](https://github.com/IBM-Swift/Kitura-redis/releases).

```swift
.package(url: "https://github.com/IBM-Swift/Kitura-redis.git", from: "x.x.x")
```

Add `SwiftRedis` to your target's dependencies:

```swift
.target(name: "example", dependencies: ["SwiftRedis"]),
```

#### Import package

  ```swift
  import SwiftRedis
  ```

## Redis installation

To test Kitura-redis locally you need to install [Redis](https://redis.io).

### macOS
```
brew install redis
```

To start redis as a background service and have the service restarted at login:
```
brew services start redis
```

Or, if you don't want redis running as a background service:
```
redis-server /usr/local/etc/redis.conf
```

## Example

This example shows you how to connect and make calls to Redis from Swift.

#### Create simple Swift executable

Create a directory for this project, change into it and then initialize the project:
```
$ mkdir exampleRedis && cd exampleRedis
$ swift package init --type executable
```

Add Kitura-redis as a dependency as described above in "Add dependencies".

Now, edit your `main.swift` file to contain:

```swift
import Foundation
import SwiftRedis

let redis = Redis()

redis.connect(host: "localhost", port: 6379) { (redisError: NSError?) in
    if let error = redisError {
        print(error)
    }
    else {
        print("Connected to Redis")
        // Set a key
        redis.set("Redis", value: "on Swift") { (result: Bool, redisError: NSError?) in
            if let error = redisError {
                print(error)
            }
            // Get the same key
            redis.get("Redis") { (string: RedisString?, redisError: NSError?) in
                if let error = redisError {
                    print(error)
                }
                else if let string = string?.asString {
                    print("Redis \(string)")
                }
            }
        }
    }
}
```

Next, build the program and run it (either within Xcode or on the command line):
```
$ swift build
$ .build/debug/redisExample
```

You should see:
```
$ Connected to Redis
$ Redis on Swift
```
This shows that we've connected to Redis, set a string value for a key and then successfully retrieved the value for that key.

## Run Tests

If you'd like to contribute to the Kitura-redis repository, once you've built the code using `swift build` you may need to run the Kitura-redis tests. The following example uses Docker to run Redis detached with the required password defined in `Tests/SwiftRedis/password.txt`.

  - `docker run -d -p 6379:6379 redis:alpine redis-server --requirepass password123`
  - `swift test`

## API Documentation
For more information visit our [API reference](https://ibm-swift.github.io/Kitura-redis/index.html).

## Community

We love to talk server-side Swift, and Kitura. Join our [Slack](http://swift-at-ibm-slack.mybluemix.net/) to meet the team!

## License
This library is licensed under Apache 2.0. Full license text is available in [LICENSE](https://github.com/IBM-Swift/Kitura-redis/blob/master/LICENSE.txt).
