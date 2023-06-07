/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Storage {
    function WithGasLeft() public view returns(uint a){
        while(a < 100000000 && gasleft() > 50000)
            a++;
    }

    function WithOutGasLeft() public pure returns(uint a){
        while(a < 100000000)
            a++;
    }
}