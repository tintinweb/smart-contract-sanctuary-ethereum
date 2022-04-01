// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {
    uint256 _counter = 100;

    uint256 number;

    function store() external {
       uint256 _data = abi.decode(msg.data,(uint256));
       _counter = _counter *  _data;
       if(!(_counter > 0)) revert("ddnt work");
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}