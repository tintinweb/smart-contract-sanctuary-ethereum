//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}

contract TestKeeper is KeeperCompatibleInterface {

    address _host;
    uint public counter;

    event UpkeepChecked(uint256 , address );
    event UpkeepPerformed( uint  );

    constructor (address host, uint seed) {
        _host = host;
        counter = seed;
    }

    function checkUpkeep(bytes calldata checkData) external override returns (bool upkeepNeeded, bytes memory performData) {
        performData = checkData;
        upkeepNeeded = true;
        emit UpkeepChecked(block.timestamp, _host);
    }

    function performUpkeep(bytes calldata /*performData*/) external override {
        counter++;
        emit UpkeepPerformed(counter);
    }
}