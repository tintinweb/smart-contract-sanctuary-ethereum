/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

// import "hardhat/console.sol";

contract myContract {
    address public owner;
    
    function publicContract() public {
        owner = msg.sender;
    }

    function privateContract() private {
        owner = msg.sender;
    }

    function internalContract() internal {
        owner = msg.sender;
    }
    
    function externalContract() external {
        owner = msg.sender;
    }

}