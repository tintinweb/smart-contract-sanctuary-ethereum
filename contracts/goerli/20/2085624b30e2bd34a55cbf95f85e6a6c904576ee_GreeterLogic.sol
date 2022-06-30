/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File contracts/DataTypes.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// Resolve cyclic dependencies
library DataTypes {
    struct GreeterData {
        string greeting;
        uint256 lastUpdatedTimestamp;
    }
}


// File contracts/logics/GreeterLogic.sol


library GreeterLogic {
    function update(DataTypes.GreeterData storage data, string memory _greeting) public {
        data.greeting = _greeting;
        data.lastUpdatedTimestamp = block.timestamp;
    }
}