# gitdraw
A tool to generate git commits in the past in order to draw stuff in the github activity calendar.

Results screenshot:

![Screenshot](https://github.com/minjaslavkovic/gitdraw/blob/9ec4058775c6b16e423c025420c4f4ff4e9100f6/screenshot.jpg)

## Usage

First fetch the current repository state into a "calendar" text file:

```
$ git clone ...
$ ruby gitdraw.rb $PWD cal_file.txt fetch
```

Draw stuff by placing 1s in that file and then run the following to generate commits:

```
$ ruby gitdraw.rb $PWD cal_file.txt commit
```

Finally do `git push`.
