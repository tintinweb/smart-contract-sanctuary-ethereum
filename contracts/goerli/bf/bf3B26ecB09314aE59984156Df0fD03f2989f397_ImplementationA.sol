/**
 *Submitted for verification at Etherscan.io on 2022-09-18
*/

// File: contracts/Proxiable.sol



pragma solidity >=0.7.0 <0.9.0;

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly { // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, newAddress)
        }
    }
    function proxiableUUID() public pure returns (bytes32) {
        return 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
}
// File: contracts/implementationA.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;


contract ImplementationA is Proxiable {

    address public owner;
    uint public count;
    bool public initalized = false;

    function initialize() public {
        require(owner == address(0), "Already initalized");
        require(!initalized, "Already initalized");
        owner = msg.sender;
        initalized = true;
    }
    function encode() public pure returns(bytes memory ){
        return abi.encodeWithSignature("initialize()");
    }

    function increment() public {
        count++;
    }

    function updateCode(address newCode) onlyOwner public {
        updateCodeAddress(newCode);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed to perform this action");
        _;
    }
}