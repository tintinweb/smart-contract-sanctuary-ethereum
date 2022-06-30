/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract SuperWhaleMemory_0630 {
    enum DataType {
        REAL_NAME,
        ELECTRONIC_CONTRACT
    }

    struct MemoryItem {
        uint256 timestamp;
        DataType dataType;
    }

    mapping(bytes32 => MemoryItem) _memoryData;

    address owner;
    /*
    0.启用
    1.暂停使用
    2.作废
    */
    uint8 state;

    mapping(address => bool) allowedAddress;

    constructor() {
        owner = msg.sender;
        allowedAddress[owner] = true;
        state = 0;
    }

    modifier allow() {
        require(
            allowedAddress[msg.sender] == true,
            "Do not have permission to execute this function"
        );
        _;
    }

    modifier checkState() {
        require(state == 0, "Contract not available");
        _;
    }

    modifier checkRepeat(bytes32 _hash) {
        require(
            _memoryData[_hash].timestamp == 0,
            "The stored data is not allowed to be modified."
        );
        _;
    }

    function updateState(uint8 _state) public allow {
        state = _state;
    }

    function setAllowedAddress(address _address) public allow {
        allowedAddress[_address] = true;
    }

    function store(bytes32 _hash, DataType _dataType)
        public
        checkState
        checkRepeat(_hash)
    {
        _memoryData[_hash].timestamp = block.timestamp;
        _memoryData[_hash].dataType = _dataType;
    }

    function storeBatch(bytes32[] memory _hashs, DataType _dataType) public {
        uint256 i = 0;
        while (_hashs.length > i) {
            bytes32 _hash = _hashs[i];
            store(_hash, _dataType);
            i++;
        }
    }

    function _view(bytes32 _hash) public view returns (MemoryItem memory) {
        MemoryItem memory item = _memoryData[_hash];
        return item;
    }

    function authenticate(bytes32 _hash) public view returns (bool) {
        return _memoryData[_hash].timestamp != 0;
    }
}