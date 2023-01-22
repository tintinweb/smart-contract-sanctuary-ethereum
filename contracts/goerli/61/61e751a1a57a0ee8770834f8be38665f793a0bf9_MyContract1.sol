/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

// File: contracts/PyraContract/Proxiable.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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
// File: contracts/PyraContract/MyProxy.sol

pragma solidity ^0.8.9;


contract MyContract1 is Proxiable{

    address public owner;
    uint256 public counter;
    bool public initialized = false;

    //don't use constructor b'ze proxy contract will not call the constructor 
    function initialize() public {
        require(!initialized, "Already initialized!!");
        owner = msg.sender;
        initialized = true;
    }

    function increment() public {
        counter++;
    }

    //this is where can update the contract and only owner can peform this
    function updateCode(address newAddress) public {
        require(msg.sender == owner, "only owner can perform an action!");
        updateCodeAddress(newAddress);
    }



}