// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Record
{
    struct record
    {
        uint256 amount;
        uint256 percentage;
    }
    record[]public records;
    address[] public users;

    function set(address _user, uint256 _amount, uint256 _percentage)public
    {
        require((_user != address(0) && _amount != 0 && _percentage != 0), "Invalid Input!");
        records.push(record(_amount, _percentage));
        users.push(_user);
    }
    function get()public view returns(address[] memory _users,record[] memory _records)
    {
        return(users, records);
    }

    receive()external payable
    {
        revert("Unable to accept ETH!");
    }
}