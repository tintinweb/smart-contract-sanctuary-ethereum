/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract Tester {

    // ================= Custom Events =================

    event YouLived(uint256 score);
    event YouLost();

    uint256 test;


    function live() public {
        emit YouLived(1);
    }

    function die() public {
        emit YouLost();
    }


    function enterDoor() public {
        for (uint i=0; i < 20; i++){
            test= i;
        }
      
    }

    function registerContractPlayer(address _contract) public {
        test = 2;
    }

    function score(address) public pure returns (uint256){
        return 1;
    }


}


// contract Uniswap {

//     function swap(){
//         ...
//         Token(0x0000000000000000000000000000000000000000).balanceOf(msg.sender)
//         ...
//     }

// }