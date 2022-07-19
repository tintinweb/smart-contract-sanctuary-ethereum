// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Information
 * @dev Store & retrieve value in a variable
 */
contract Information {
    //可以存取字符串
    string public information;
    //点击store调用storeLog事件，包含方法，调用者地址，调用时时间戳，数据
    //点击retrieve调用retrieveLog事件，包含方法，调用者地址，调用时时间戳，数据
    event storeLog(string way, address indexed sender, uint256 indexed time, string message);
    event retrieveLog(string way, address indexed sender, uint256 indexed time, string message);

    /*
     * @dev Store value in variable
     * @param num value to store
     */
    function store(string memory _information) public {
        information = _information;
        emit storeLog("store", msg.sender, block.number, information);
    }

    /**
     * @dev Return value
     * @return value of 'number'
     */
    function retrieve() public returns (string memory) {
        emit retrieveLog("retrieve", msg.sender, block.number, information);
        return information;
    }
}