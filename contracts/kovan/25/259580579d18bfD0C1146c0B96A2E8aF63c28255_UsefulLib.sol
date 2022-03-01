/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
contract UsefulLib{
    struct NUM{
        uint256 num;
    }

    NUM public n;
    function help() external returns (bool){
        n.num = 100;

        return true;
    }

    function killme() public {
        selfdestruct(payable(0));
    }

    fallback() external payable{
        n.num = 404;
        assembly{
            return(0,32)
        }
    }
}