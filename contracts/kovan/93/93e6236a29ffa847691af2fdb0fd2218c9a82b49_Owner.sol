/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Owner {
    address private owner;
    bytes32 internal constant ACCESS = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    }

    function changeOwner(address newOwner) public isOwner {
        assembly {
            sstore(ACCESS, newOwner)
        }
        owner = newOwner;
    }
   
   function getOwner() external view returns (address) {
        return owner;
    }
}