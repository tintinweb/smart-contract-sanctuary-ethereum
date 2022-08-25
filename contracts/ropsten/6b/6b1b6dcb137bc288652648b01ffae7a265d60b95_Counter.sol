// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}

// $ forge create --rpc-url https://ropsten.infura.io/v3/429eb57532b54560b1d4cc4201724bf0 --private-key 0xbf24ac873f8118ac8344c4ed01d169accabb2893642ce62de949be7918ad17c1 src/Counter.sol:Counter --etherscan-api-key U772ATWP1Z8J3MNMFUXXFPYD213PEVEXAZ