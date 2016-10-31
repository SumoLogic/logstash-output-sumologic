## 1.0.0
 - First public release

### 1.0.1
 - Update gem description 

### 1.0.2
 - Support using `%{@json}` in format to send event in json format
 - Support pararmeter `json_mapping` to filter json fields. For example:
```
json_mapping => {
    "foo" => "%{@timestamp}"
    "bar" => "%{message}"
}
```
will create message as:
```
{"foo":"2016-07-27T18:37:59.460Z","bar":"hello world"}
{"foo":"2016-07-27T18:38:01.222Z","bar":"bye!"}
```

### 1.0.3
 - Remove version limitation so it works with Log Stash 5.0.0 core