// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Storage {
    uint256 number;
    event NumberChange(address indexed _user, uint256 _to);

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
        emit NumberChange(msg.sender, num);
    }

    /**
     * @dev Return value
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256) {
        return number;
    }
}