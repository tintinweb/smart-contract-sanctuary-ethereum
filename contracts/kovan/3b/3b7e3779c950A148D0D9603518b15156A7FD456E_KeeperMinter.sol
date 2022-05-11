/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
 
//import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
interface KeeperCompatibleInterface {
        function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
        function performUpkeep(bytes calldata performData) external;
}
 
//https://kovan.etherscan.io/token/0xaddress#balances
interface TokenMinterInterface {
        function mint(address account, uint256 amount) external returns (bool);
}
 
contract KeeperMinter is KeeperCompatibleInterface {
 
        uint public counter;        // Public counter variable
        TokenMinterInterface public minter;
        address to;
 
        // Use an interval in seconds and a timestamp to slow execution of Upkeep
        uint public immutable interval;
        uint public lastTimeStamp;    
 
        constructor(uint updateInterval, address tokenMinter, address _to) {
          interval = updateInterval;
          lastTimeStamp = block.timestamp;
          counter = 0;
          minter = TokenMinterInterface(tokenMinter);
          to = _to;
        }
 
        function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
            upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
            performData = checkData;
        }
 
        function performUpkeep(bytes calldata performData) external override {
            lastTimeStamp = block.timestamp;
            counter = counter + 1;
            minter.mint(to, 100);
            performData;
        }
}