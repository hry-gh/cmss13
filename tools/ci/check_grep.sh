#!/bin/bash
set -euo pipefail

#nb: must be bash to support shopt globstar
shopt -s globstar extglob

#ANSI Escape Codes for colors to increase contrast of errors
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

st=0

# check for ripgrep
if command -v rg >/dev/null 2>&1; then
	grep=rg
	pcre2_support=1
	if [ ! rg -P '' >/dev/null 2>&1 ] ; then
		pcre2_support=0
	fi
	code_files="code/**/**.dm"
	map_files="maps/**/**.dmm"
	code_x_515="code/**/!(_byond_version_compat).dm"
else
	pcre2_support=0
	grep=grep
	code_files="-r --include=code/**/**.dm"
	map_files="-r --include=maps/**/**.dmm"
	code_x_515="-r --include=code/**/!(_byond_version_compat).dm"
fi

echo -e "${BLUE}Using grep provider at $(which $grep)${NC}"

part=0
section() {
	echo -e "${BLUE}Checking for $1${NC}..."
	part=0
}

part() {
	part=$((part+1))
	padded=$(printf "%02d" $part)
	echo -e "${GREEN} $padded- $1${NC}"
}

section "map issues"

part "TGM"
if grep -El '^\".+\" = \(.+\)' $map_files;	then
	echo
	echo -e "${RED}ERROR: Non-TGM formatted map detected. Please convert it using Map Merger!${NC}"
	st=1
fi;

section "whitespace issues"

part "space indentation"
if grep -P '(^ {2})|(^ [^ * ])|(^    +)' $code_files; then
	echo
	echo -e "${RED}ERROR: space indentation detected.${NC}"
	st=1
fi;

part "mixed tab/space indentation"
if grep -P '^\t+ [^ *]' $code_files; then
	echo
	echo -e "${RED}ERROR: mixed <tab><space> indentation detected.${NC}"
	st=1
fi;

part "missing trailing newlines"
nl='
'
nl=$'\n'
while read f; do
	t=$(tail -c2 "$f"; printf x); r1="${nl}$"; r2="${nl}${r1}"
	if [[ ! ${t%x} =~ $r1 ]]; then
		echo
		echo -e "${RED}ERROR: file $f is missing a trailing newline.${NC}"
		st=1
	fi;
done < <(find . -type f -name '*.dm')

section "common mistakes"

part "var in proc args"
if grep -P '^/[\w/]\S+\(.*(var/|, ?var/.*).*\)' $code_files; then
	echo
	echo -e "${RED}ERROR: changed files contains proc argument starting with 'var'.${NC}"
	st=1
fi;

#part "unmanaged global vars"
#if grep -P '^/*var/' $code_files; then
#	echo
#	echo -e "${RED}ERROR: Unmanaged global var use detected in code, please use the helpers.${NC}"
#	st=1
#fi;


part "map json naming"
if ls maps/*.json | grep -P "[A-Z]"; then
	echo
	echo -e "${RED}ERROR: Uppercase in a map json detected, these must be all lowercase.${NC}"
	st=1
fi;

part "map json sanity"
for json in maps/*.json
do
	map_path=$(jq -r '.map_path' $json)
	while read map_file; do
		filename="maps/$map_path/$map_file"
		if [ ! -f $filename ]
		then
			echo
			echo -e "${RED}ERROR: found invalid file reference to $filename in _maps/$json.${NC}"
			st=1
		fi
	done < <(jq -r '[.map_file] | flatten | .[]' $json)
done

part "balloon_alert sanity"
if $grep 'balloon_alert\(".*"\)' $code_files; then
	echo
	echo -e "${RED}ERROR: Found a balloon alert with improper arguments.${NC}"
	st=1
fi;

if $grep 'balloon_alert(.*span_)' $code_files; then
	echo
	echo -e "${RED}ERROR: Balloon alerts should never contain spans.${NC}"
	st=1
fi;

part "balloon_alert idiomatic usage"
if $grep 'balloon_alert\(.*?, ?"[A-Z]' $code_files; then
	echo
	echo -e "${RED}ERROR: Balloon alerts should not start with capital letters. This includes text like 'AI'. If this is a false positive, wrap the text in UNLINT().${NC}"
	st=1
fi;

section "515 Proc Syntax"
part "proc ref syntax"
if $grep '\.proc/' $code_x_515 ; then
    echo
    echo -e "${RED}ERROR: Outdated proc reference use detected in code, please use proc reference helpers.${NC}"
    st=1
fi;

if [ "$pcre2_support" -eq 1 ]; then
	section "regexes requiring PCRE2"
	part "long list formatting"
	if $grep -PU '^(\t)[\w_]+ = list\(\n\1\t{2,}' code/**/*.dm; then
		echo -e "${RED}ERROR: Long list overindented, should be two tabs.${NC}"
		st=1
	fi;
	if $grep -PU '^(\t)[\w_]+ = list\(\n\1\S' code/**/*.dm; then
		echo -e "${RED}ERROR: Long list underindented, should be two tabs.${NC}"
		st=1
	fi;
	if $grep -PU '^(\t)[\w_]+ = list\([^\s)]+( ?= ?[\w\d]+)?,\n' code/**/*.dm; then
		echo -e "${RED}ERROR: First item in a long list should be on the next line.${NC}"
		st=1
	fi;
	if $grep -PU '^(\t)[\w_]+ = list\(\n(\1\t\S+( ?= ?[\w\d]+)?,\n)*\1\t[^\s,)]+( ?= ?[\w\d]+)?\n' code/**/*.dm; then
		echo -e "${RED}ERROR: Last item in a long list should still have a comma.${NC}"
		st=1
	fi;
	if $grep -PU '^(\t)[\w_]+ = list\(\n(\1\t[^\s)]+( ?= ?[\w\d]+)?,\n)*\1\t[^\s)]+( ?= ?[\w\d]+)?\)' code/**/*.dm; then
		echo -e "${RED}ERROR: The ) in a long list should be on a new line.${NC}"
		st=1
	fi;
	if $grep -PU '^(\t)[\w_]+ = list\(\n(\1\t[^\s)]+( ?= ?[\w\d]+)?,\n)+\1\t\)' code/**/*.dm; then
		echo -e "${RED}ERROR: The ) in a long list should match identation of the opening list line.${NC}"
		st=1
	fi;
else
	echo -e "${RED}pcre2 not supported, skipping checks requiring pcre2"
	echo -e "if you want to run these checks install ripgrep with pcre2 support.${NC}"
fi

if [ $st = 0 ]; then
	echo
	echo -e "${GREEN}No errors found using grep!${NC}"
fi;

if [ $st = 1 ]; then
	echo
	echo -e "${RED}Errors found, please fix them and try again.${NC}"
fi;

exit $st
