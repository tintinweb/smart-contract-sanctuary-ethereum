/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract HelloWorld {
    uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    
    event Store(uint256 indexed num);

    function store(uint256 num) public {
        require(num > 100, "can not less than 100");
        number = num;
        emit Store(num);
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}