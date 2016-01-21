import PackageDescription

let package = Package(
    name: "SwiftRedis",
    dependencies: [ 
    .Package(url: "git@github.ibm.com:ibmswift/Phoenix.git", majorVersion: 0),
],
    testDependencies: [
        .Package(url: "git@github.ibm.com:ibmswift/PhoenixTestFramework.git", majorVersion: 0)
        ]
)
