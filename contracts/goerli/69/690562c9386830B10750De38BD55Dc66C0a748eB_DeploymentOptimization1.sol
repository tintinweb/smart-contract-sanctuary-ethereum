// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract DeploymentOptimization1 {
    uint256 public number;
    uint256 public additionResult;

    function setNumber(uint256 _number) public {
        number = _number;
    }

    function setAdditionResult() public {
        additionResult = number + number;
    }
}
// while deployments
//gas cost in hardhat         = 165,889

//gas cost in goerli testnet  = 165,889

//transaction fee in ETH      = 0.000000517208392422
// transaction fee in Gwei     = 517.208392422