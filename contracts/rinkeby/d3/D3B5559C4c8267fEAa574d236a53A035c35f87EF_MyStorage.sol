/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

//import "hardhat/console.sol";

contract MyStorage {
    uint256 storedData;
    uint256 deviceID;
    uint256 dataTime;
    uint256 dataValue;

    constructor(uint256 _storedData) {
        //console.log("Deployed by: ", msg.sender);
        //console.log("Deployed with value: %s", _storedData);
        storedData = _storedData;
        deviceID = 0;
        dataTime = 0;
        dataValue = 0;
    }

    function set(uint256 x) public {
        //console.log("Set value to: %s", x);
        storedData = x;
    }

    function setData(uint256 dev_id, uint256 value) public {
        deviceID = dev_id;
        dataTime = block.timestamp;
        dataValue = value;
    }

    function get() public view returns (uint256) {
        //console.log("Retrieved value: %s", storedData);
        return storedData;
    }

    function getData() public view returns (uint256,uint256,uint256) {
        return (deviceID,dataTime,dataValue);
    }
}