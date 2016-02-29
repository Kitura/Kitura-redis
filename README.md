# KituraRedis

***Swift Redis library***

KituraRedis is a Swift library for interacting with a Redis database using [Hiredis](https://github.com/redis/hiredis).

It is dependent on the [Kitura-sys](https://github.com/IBM-Swift/Kitura-sys) module.

#Running Tests:

  1. `swift build -Xcc -fblocks -Xswiftc -I/usr/local/include -Xlinker -L/usr/local/lib`
  2. `swift test`