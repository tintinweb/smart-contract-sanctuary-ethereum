/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

pragma solidity ^0.8.7;

// SPDX-License-Identifier: GPL-3.0-or-later

contract Comment {


    function record (
       string memory Ledger,
       string memory TXID,
       string memory Comment,
       string memory IPFS,
       address payable IDX_A,
       address payable IDX_B,
       address payable IDX_C
              ) public
   {
   address payable Index_A = payable(IDX_A);
   address payable Index_B = payable(IDX_B);
   address payable Index_C = payable(IDX_C);

   Index_A.transfer(0);
   Index_B.transfer(0);
   Index_C.transfer(0);

/* 

Internal index addresses are created with https://github.com/johnrigler/unspendable
These are also obviously unspendable generation one addresses that should be used sparingly since
they create UTXOs which can never be spent

> un DAx "caroline fowler"
DAxCARoLiNExFoWLERzzzzzzzzzzbpv9Dn
> un DBx "john rigler"
DBxJoHNxRiGLERzzzzzzzzzzzzzzZAGsQB
> un DCx "9th baptist"
DCx9THxBAPTiSTzzzzzzzzzzzzzzWWNnpd

Use these function to transform and restore:

un () 
{ 
    local _ARG1=$1;
    shift;
    python3 ./QmSrMiD6n2x3zyHGHXpJhLiHZBcWcAHRZHRbh7MwBF2EcU $_ARG1 "$*"
}


transform () 
{ 
    first=$1;
    shift;
    begin=$(un $first $* | cut -c 2-28);
    val=$(echo -n $begin | base58 -d | xxd -p);
    echo "0x"$val
}


restore () 
{ 
    val=$(echo $1 | cut -c 2-);
    echo -n $val | xxd -p -r | base58;
    echo
}

*/



       // No static at all.
   }
}