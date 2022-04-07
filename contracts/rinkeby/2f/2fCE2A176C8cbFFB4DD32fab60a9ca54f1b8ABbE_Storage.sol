/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    uint256 public MIN_VALUE = 0.01 ether;

    constructor() {
        number = 0;
    }

    function add(uint256 num) public {
        number = number + num;
    }

    function minus(uint256 num) public payable {
        require(msg.value >= MIN_VALUE, "not enough");
        number = number - num;
    }
    
    function retrieve() public view returns (uint256){
        return number;
    }
}