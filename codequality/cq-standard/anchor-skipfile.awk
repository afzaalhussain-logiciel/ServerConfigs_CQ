# Rewrites a repo-relative CodeChecker skipfile into one anchored at -v root.
#
# CodeChecker matches each rule against the ABSOLUTE path of the file, so a
# rule like "+*/src/*" also matches the checkout root /src itself and pulls in
# every directory under it. The baseline lives at /src-baseline, which has no
# /src/ segment, so the same rule gave the two refs different scope and the
# extra files scored as net-new. README.md.
#
# Each relative rule becomes two anchored rules - at the repo root and at any
# depth below it - which is what the unanchored "*/" meant within the repo.
/^[[:space:]]*(#|$)/ { print; next }
{
    sign = substr($0, 1, 1)
    pat  = substr($0, 2)
    # "-*" is the catch-all terminator and "/usr/*" is deliberately absolute.
    if (pat == "*" || substr(pat, 1, 1) == "/") { print; next }
    if (substr(pat, 1, 2) == "*/") pat = substr(pat, 3)
    printf "%s%s/%s\n",   sign, root, pat
    printf "%s%s/*/%s\n", sign, root, pat
}
