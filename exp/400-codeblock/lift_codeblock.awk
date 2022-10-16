BEGIN {
    verbatim=0;
    last="";
    lastlast="";    
    # enter state=Initial
    state=0;
    laststate=0;
    lastlaststate=0;
}

# capture state history
{
    lastlaststate=laststate;
    laststate=state;
}

# enable for troubleshooting
# {
#     printf "[state=%d,laststate=%s,lastlaststate=%s] current = %50s | last = %50s | lastlast = %50s\n", state, laststate, lastlaststate, $0, last, lastlast;
# }

# exit state=Code_Block_Header if and only if we are not on a blank line
state == 1 && NF > 1 {
    # enter state=In_Code_Block
    state = 2;
}

state == 3 {
    # enter state=Initial
    state = 0;
}

# exit state=In_Code_Block if and only if we encounter a terminating ```
state == 2 && $1 == "```" {
    # enter state=End_Code_Block
    state = 3;
}

# are we in ``` + ::code-block:: ?
laststate == 0 && last == "```" && $1 == "::code-block::" && NF > 1 {
    # remove ::code-block::
    $1="";
    sub(/^ */, "");
    # edit the last line
    last=sprintf("```%s", $0);
    # enter state=Code_Block_Header
    state=1;
    # we are in {v ... v} block
    verbatim=1;
}

# are we in ``` with no ::code-block:: ? then default odoc code block is OCaml
laststate == 0 && last == "```" {
    # edit the last line
    last=sprintf("```ocaml");
    # enter state=In_Code_Block
    state=2;
    # we are not in {v ... v} block
    verbatim=0;
}

# in code block remove the excess space that odoc puts in
# for verbatim blocks (why does it put it in?)
state==2 && verbatim==0 {
    sub(/^     /, "", $0);
}
state==2 && verbatim==1 {
    sub(/^        /, "", $0);
}


(state==0 || state==2 || state==3) && NR>2 {
    print lastlast;
}

(state==0 || state==2 || state==3) {
    lastlast=last;
    last=$0;
}

END {
    print lastlast;
    print last;
}