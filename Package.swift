import PackageDescription

let package = Package(
    name: "PhoenixRedis",
    dependencies: [ 
    .Package(url: "git@github.ibm.com:ibmswift/Phoenix.git", majorVersion: 1),
],
    testDependencies: [
        .Package(url: "git@github.ibm.com:ibmswift/PhoenixTestFramework.git", majorVersion: 0)
        ]
)
