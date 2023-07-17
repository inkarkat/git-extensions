#!/usr/bin/awk

function abs(v)
{
    v += 0
    return (v < 0 ? -v : v)
}
function typeCompare(t1, t2)
# Returns -1 if t1 +1 == t2, +1 if t1 == t2 +1, else -99 / 0 / 99.
{
    if (t1 ~ /^[[:digit:]]+$/ && t2 ~ /^[[:digit:]]+$/) {
	t1 = int(t1)
	t2 = int(t2)

	return (t1 == t2 \
		? 0 \
		: (t1 < t2 \
		    ? (t1 + 1 == t2 ? -1 : -99) \
		    : (t1 == t2 + 1 ? 1 : 99) \
		) \
	)
    }

    return (t1 == t2 \
	? 0 \
	: (t1 < t2 ? -99 : 99) \
    )
}
function tupleCompare(separatorPattern, i1, v1, i2, v2,       n1, a1, n2, a2, i, cmp)
{
    n1 = split(v1, a1, separatorPattern)
    n2 = split(v2, a2, separatorPattern)
    while (n1 < n2) {
	a1[++n1] = -2
    }
    while (n2 < n1) {
	a2[++n2] = -2
    }

    for (i = 1; i <= n1; ++i) {
	cmp = typeCompare(a1[i], a2[i])
	if (cmp != 0) {
	    if (i == 1 && abs(cmp) > 1) {
		return cmp * 2	# First tuple should not be collected, unless it is a subsequent value.
	    }

	    # All following tuples must match to return a +/-1 (subsequent value).
	    for (++i; i <= n1; ++i) {
		if (typeCompare(a1[i], a2[i]) != 0) {
		    return cmp * 2  # Nope, not subsequent value.
		}
	    }
	    return cmp
	}
    }
    return 0
}
function versionCompare(i1, v1, i2, v2)
{
    return tupleCompare("\\.", i1, v1, i2, v2)
}
function lastTupleCompare(separatorPattern, v1, v2)
{
    return tupleCompare(separatorPattern, 0, v1, 0, v2)
}
function lastDigitCompare(v1, v2)
{
    return lastTupleCompare("\\.", v1, v2)
}
function lastPathCompare(v1, v2)
{
    return lastTupleCompare("\\/", v1, v2)
}
function versionRange(v1, v2,      n1, a1, n2, a2, result, i)
{
    n1 = split(v1, a1, /\./)
    n2 = split(v2, a2, /\./)

    for (i = 1; i <= n1; ++i) {
	if (typeCompare(a1[i], a2[i]) == 0) {
	    result = result (result == "" ? "" : ".") a1[i]
	} else {
	    result = result (result == "" ? "" : ".") "{" a1[i] ".." a2[i] "}"
	}
    }
    return result
}
function enumerate(v1, enumerationCnt, v2,      n1, a1, n2, a2, result, i, j)
{
    n1 = split(v1, a1, /\//)
    n2 = split(v2[1], a2, /\//)

    for (i = 1; i <= n1; ++i) {
	if (typeCompare(a1[i], a2[i]) == 0) {
	    result = result (result == "" ? "" : "/") a1[i]
	} else {
	    result = result (result == "" ? "" : "/") "{" a1[i]
	    for (j = 1; j <= enumerationCnt; ++j) {
		split(v2[j], a2, /\//)
		result = result "," a2[i]
	    }
	    result = result "}"
	}
    }
    return result
}
function join(array, start, end, sep,    result, i, last, range, enumeration, enumerationCnt, cmp)
{
    if (sep == "")
	sep = " "
    else if (sep == SUBSEP) # magic value
	sep = ""
    last = array[start]
    for (i = start + 1; i <= end; i++) {
	# print "#### " array[i-1] "<" cmp ">" array[i] > "/dev/stderr"
	if (abs(lastDigitCompare(array[i-1], array[i])) == 1 && enumerationCnt == 0) {
	    range = array[i]
	} else if (lastPathCompare(array[i-1], array[i]) == -99) {
	    if (range != "") {
		result = result versionRange(last, range) sep
		last = array[i]
		range = ""
	    } else {
		enumeration[++enumerationCnt] = array[i]
	    }
	} else {
	    result = result (range == "" ? (enumerationCnt == 0 ? last : enumerate(last, enumerationCnt, enumeration)) : versionRange(last, range)) sep
	    last = array[i]
	    range = ""
	    enumerationCnt = 0
	    delete enumeration
	}
    }
    return result (range == "" ? (enumerationCnt == 0 ? last : enumerate(last, enumerationCnt, enumeration)) : versionRange(last, range))
}
