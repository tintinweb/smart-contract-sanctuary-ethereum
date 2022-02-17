/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;


contract test {

    mio public rm;

    uint public a;

     constructor(address xx) {
        rm = mio(xx);
    }

    function setVal (uint256 setv, uint256 sec) public {
        a =  setv;
        rm.ts(sec);
    }

    function setM(uint xxx) public {
        a = xxx;
    }
}


contract mio {



    function ts(uint a) public {
      test(msg.sender).setM(a);
    }
}