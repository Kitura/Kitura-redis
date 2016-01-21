import PackageDescription

let package = Package(
    name: "PhoenixRedis",
    dependencies: [ ],
    testDependencies: [
        .Package(url: "git@github.ibm.com:ibmswift/PhoenixTestFramework.git", majorVersion: 0)
        ]
)
