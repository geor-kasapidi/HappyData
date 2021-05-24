# Swift ORM

![SWORM](logo.svg)

## Features

1) Pure swift objects - no more subclasses of NSManagedObject
2) Extensible attribute system - store any type in CoreData storage by implementing a simple protocol in type extension
3) Strongly typed data queries
4) Progressive migrations

## Motivation

CoreData is hard. It was originally designed as a data layer for applications with a focus on I/O performance, but hardware has become more powerful over time and the complexity of CoreData still persists (lol). In modern applications, building CoreData-based data layer is expensive and often unreasonable decision.

Even the NSPersistentContainer doesn't relieve us of the need to keep track of the lifecycle of the managed objects associated with the context and remember to read / write on the context queue. In addition, an application often has a second set of data models, similar to managed objects and code for converting between the two sets of models.

Apple is aware of all of this and in modern guides prefers data persistence based on Codable models.

At the same time, CoreData has many advantages - a powerful visual editor for data models, automatic migrations, a simplified (compared to SQL) query system, secure multi-threaded access to data out of the box, and so on.

Sworm is a tool that hides the complexity of CoreData from the developer, but keeps the advantages.

## Usage

[Basic](docs/basic_usage.md)

## Links

[williamboles.me](https://williamboles.me/progressive-core-data-migration/)

[objc.io](https://www.objc.io/issues/4-core-data/core-data-migration/#progressive-migrations)

[kean.blog](https://kean.blog/post/core-data-progressive-migrations)

## Code style

`swiftformat --self insert --swiftversion 5.3 .`
