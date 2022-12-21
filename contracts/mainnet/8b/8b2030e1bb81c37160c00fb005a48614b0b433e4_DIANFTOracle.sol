/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// compiled using solidity 0.7.4

pragma solidity 0.7.4;

contract DIANFTOracle {
    struct Values {
        uint256 value0;
        uint256 value1;
    }
    mapping (string => Values) public values;
    address oracleUpdater;
    
    event OracleUpdate(string key, uint64 value0, uint64 value1, uint64 value2, uint64 value3, uint64 value4, uint64 timestamp);
    event UpdaterAddressChange(address newUpdater);
    
    constructor() {
        oracleUpdater = msg.sender;
    }
    
    function setValue(string memory key, uint64 value0, uint64 value1, uint64 value2, uint64 value3, uint64 value4, uint64 timestamp) public {
        require(msg.sender == oracleUpdater);
        uint256 cValue0 = (((uint256)(value0)) << 192) + (((uint256)(value1)) << 128) + (((uint256)(value2)) << 64);
        uint256 cValue1 = (((uint256)(value3)) << 192) + (((uint256)(value4)) << 128) + (((uint256)(timestamp)) << 64);
        Values storage cStruct = values[key];
        cStruct.value0 = cValue0;
        cStruct.value1 = cValue1;
        emit OracleUpdate(key, value0, value1, value2, value3, value4, timestamp);
    }
    
    function getValue(string memory key) external view returns (uint64, uint64, uint64, uint64, uint64, uint64) {
        Values storage cStruct = values[key];
        uint64 rValue0 = (uint64)(cStruct.value0 >> 192);
        uint64 rValue1 = (uint64)((cStruct.value0 >> 128) % 2**64);
        uint64 rValue2 = (uint64)((cStruct.value0 >> 64) % 2**64);
        uint64 rValue3 = (uint64)(cStruct.value1 >> 192);
        uint64 rValue4 = (uint64)((cStruct.value1 >> 128) % 2**64);
        uint64 timestamp = (uint64)((cStruct.value1 >> 64) % 2**64);
        return (rValue0, rValue1, rValue2, rValue3, rValue4, timestamp);
    }
    
    function updateOracleUpdaterAddress(address newOracleUpdaterAddress) public {
        require(msg.sender == oracleUpdater);
        oracleUpdater = newOracleUpdaterAddress;
        emit UpdaterAddressChange(newOracleUpdaterAddress);
    }
}