# Packfile Reader

Git packs up several of "loose" objects into a single binary file called a “packfile” in order to save space and be more efficient.

"packfiles" usually come in pairs: a `.pack` file and a `.idx` file.

The `.idx` file contains offsets for all the objects in the `.pack` file, so it is easier to find the content you are looking for on the packfile.

When we have both files, we can use `git verify-pack` command to read the content and metadata about the objects in the packfile, but sometimes we only have the `.pack` file, and in this case `git` is not really helpful.

![packfile](packfile-format.png?raw=true "Packfile Format")

I created this tool to help with parsing packfiles without their index files counterpart.

# Installation

This gem is published at rubygems.org already, so you can just `gem install packfile_reader`.

If you want to download the source code and play with it locally, clone the repository then

```
gem build packfile_reader.gemspec
gem install ./packfile_reader-<version>.gem
```

# Usage

```
This tool is used to parse and extract data from git packfiles without a .idx file.
By default, the script will only report the object ids, their type and their deflated sizes.
You can also make the script expand the content of the objects in the local directory or a directory
of your choice.

Usage:
  packfile_reader [options] <packfile>
where [options] are:
  -h, --headers-only         Display only the headers of the packfile
  -n, --no-headers           Skip displaying the headers of the packfile
  -i, --filter-by-ids=<s>    Comma separated list of object ids to look for (default: any)
  -e, --expand-objects       Whether to expand objects data
  -o, --output-dir=<s>       Directory to store the expanded objects (default: .)
  -v, --verbose              Log some debugging informaiton to stderr
  -r, --version              Print version and exit
  -l, --help                 Show this message

```

## Example:

The output of the command includes the headers for the packfile and a list of objects found in the file in format:

```
<object-id> <object-type> <size-uncompressed>
```

### Filtering by object ids

```
packfile_reader -i "5297f8f21ad868d9eb6a9c01ad09a9d186177047,96438dd1e26e6963fa65be0012e8f6e84209bc5d" pack.sample
```

```
Packfile Headers
- Signature: PACK
- Version: 2
- Entries: 3

96438dd1e26e6963fa65be0012e8f6e84209bc5d	OBJ_COMMIT	653
5297f8f21ad868d9eb6a9c01ad09a9d186177047	OBJ_BLOB	10
```

### Getting header only

```
packfile_reader --headers-only pack.sample 
```

```
Packfile Headers
- Signature: PACK
- Version: 2
- Entries: 3
```

### Getting the list of objects only

```
packfile_reader --no-headers pack.sample 
```

```
96438dd1e26e6963fa65be0012e8f6e84209bc5d	OBJ_COMMIT	653
5297f8f21ad868d9eb6a9c01ad09a9d186177047	OBJ_BLOB	10
bf195faf9d23ce0615cdefd2b746a077ef82f03f	OBJ_TREE	37
```

### Deflating an object data

You can also ask the tool to deflate the object data, by using the `--expand-objects` option. `packfile_reader` will create a file named after the object id. By default the file is created on the local directory. To change that, use `--output-dir` option.

```
packfile_reader -i "5297f8f21ad868d9eb6a9c01ad09a9d186177047" -e -o /tmp pack.sample 
```

```
Packfile Headers
- Signature: PACK
- Version: 2
- Entries: 3
5297f8f21ad868d9eb6a9c01ad09a9d186177047	OBJ_BLOB	10
```

```
$ cat /tmp/5297f8f21ad868d9eb6a9c01ad09a9d186177047.txt 
# test-git%
```

### Debugging information

Passing `--verbose` to the command will add some debugging information to the output as well as the timestamp when the entry got processed at the beginning of the entry line.

```
packfile_reader --no-headers -verbose pack.sample 
```

```
[2020-12-01 21:24:43 -0800] 96438dd1e26e6963fa65be0012e8f6e84209bc5d	OBJ_COMMIT	653
[2020-12-01 21:24:43 -0800] 5297f8f21ad868d9eb6a9c01ad09a9d186177047	OBJ_BLOB	10
[2020-12-01 21:24:44 -0800] bf195faf9d23ce0615cdefd2b746a077ef82f03f	OBJ_TREE	37
```
# References
-  http://shafiul.github.io/gitbook/7_the_packfile.html
