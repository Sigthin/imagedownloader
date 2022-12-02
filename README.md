## Getting Started

This is a simple image downloading tool. Main pros are:
+ Multithreaded
+ Extensible
+ Maintable
+ Builtin foolproof checks (limited to technology stack)
+ RSpec covered
+ Rubocop passed

### Installation

```sh
git clone https://github.com/Sigthin/imagedownloader.git
cd imagedownloader
bundle install
```

### RSpec

```sh
bundle exec rspec
```

### Rubocop

```sh
bundle exec rubocop
```

### Usage

Feed new-line separated urls file

```sh
bin/run /path/to/file.txt
```
