/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/Dapptutorial.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.6 <0.9.0;

////// src/Dapptutorial.sol
/* pragma solidity ^0.8.6; */

contract Dapptutorial {
    uint256 public value = 1;
    uint256 public valueTimesTwo = 2;

    receive() external payable {
    }

    function add(uint256 x, uint256 y) public pure returns(uint256) {
        return x+y;
    }

    function increase() public {
        value++;
        valueTimesTwo = value * 2;
    }

/*     function breakTheInvariant(uint8 theAnswer) public {
        require(theAnswer == 42, "NOT_THE_ANSWER");
        valueTimesTwo -= 1;
    } */

    function withdraw(uint password) public {
        require(password == 42, "Access denied!");
        payable(msg.sender).transfer(address(this).balance);
    }
}