/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.6;

contract Storage {

    uint256 number;

    event Received(address indexed sender, uint256 amount);
    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    receive() external payable {
       emit Received(msg.sender, msg.value);
    }
    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}