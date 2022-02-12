/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

//import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}

//https://kovan.etherscan.io/token/0xa766631087e45d8e3061dd05e40a7aa39e52d712#balances
interface TokenMinterInterface {
    function mint(address account, uint256 amount) external returns (bool);
}

contract KeeperMinter is KeeperCompatibleInterface {

    uint public counter;    // Public counter variable
    TokenMinterInterface public minter;


    // Use an interval in seconds and a timestamp to slow execution of Upkeep
    uint public immutable interval;
    uint public lastTimeStamp;    

    constructor(uint updateInterval) {
      interval = updateInterval;
      lastTimeStamp = block.timestamp;
      counter = 0;
      minter = TokenMinterInterface(0xc30e8BDd13871f4789e3207C2E3FcA5c69Ff4544);
    }

    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external override {
        lastTimeStamp = block.timestamp;
        counter = counter + 1;
        minter.mint(0x0aBF67Be2454B6ae1397195346D3D0ae11e695d7, 100);
        performData;
    }
}