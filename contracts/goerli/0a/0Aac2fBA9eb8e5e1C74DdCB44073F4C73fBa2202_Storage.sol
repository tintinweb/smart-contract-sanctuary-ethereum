// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    uint256 number;
    uint256 public numberSecond;
    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    function changeOwner(address _addr) public {
        owner = _addr;
    }

    function storeOwner(uint256 num) public {
        require(owner == msg.sender, 'not the owner');
        numberSecond = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}