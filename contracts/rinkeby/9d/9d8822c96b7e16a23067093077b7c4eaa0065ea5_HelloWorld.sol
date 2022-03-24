/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File contracts/FirstSmartContract.sol

pragma solidity ^0.7.3;

contract HelloWorld {
    string public firstContract;
    string public tag = "I can do this";

    constructor(string memory obstacleName) {
        firstContract = obstacleName;
    }

    function createWins(string memory newRecord) public {
        firstContract = newRecord;
    }

    function getWins() public view returns (string memory) {
        return string(abi.encodePacked(tag, firstContract));
    }
}