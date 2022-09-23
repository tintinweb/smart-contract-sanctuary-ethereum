/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract foodpick {
    uint p;
    uint ph;
    uint h;
    uint hh;

    function food(uint num) public returns(uint) {
        if(num == 0){
            p = p + 1;
            return p;
        }
        else if(num == 1){
            ph = ph + 1;
            return ph;
        }
        else if(num == 2){
            h = h + 1;
            return h;
        }
        else{
            hh = hh + 1;
            return hh;
        }
    }
}