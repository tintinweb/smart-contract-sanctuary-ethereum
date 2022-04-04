/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Hodl {
    constructor(uint256 hodlDays) {
        hodl_days = hodlDays;
        owner_address = payable(msg.sender);
        AddHodler(owner_address);
    }

    uint256 public hodl_days;
    address payable owner_address;
    address[] all_hodler_address;
    uint256 all_hodler_count = 0;

    struct Hodler {
        uint256 serial_number;
        uint256 balance;
        uint256 registerTime;
    }

    mapping(address => Hodler) address_hodler;

    function AddHodler(address payable newAddress) internal {
        all_hodler_address.push(newAddress);
        address_hodler[newAddress].serial_number = ++all_hodler_count;
        address_hodler[newAddress].balance = 0;
        address_hodler[newAddress].registerTime = block.timestamp;
    }

    function AddBalance(address payable hodlerAddress, uint256 value) internal {
        address_hodler[hodlerAddress].balance += value;
    }

    function GetRemainingTime(address hodlerAddress)
        internal
        view
        returns (uint256)
    {
        return address_hodler[hodlerAddress].registerTime + hodl_days * 1 days;
    }

    function CheckMyBalance() external view returns (uint256) {
        return address_hodler[msg.sender].balance;
    }

    function CheckMyRemainingTime() external view returns (uint256) {
        return (GetRemainingTime(msg.sender) - block.timestamp) / 60 / 60 / 24;
    }

    function CheckAllBalance() public view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < all_hodler_address.length; i++) {
            address temp = all_hodler_address[i];
            sum += address_hodler[temp].balance;
        }
        return sum;
    }

    function Withdraw() external returns (bool) {
        address payable hodler_address = payable(msg.sender);
        if (block.timestamp < GetRemainingTime(hodler_address)) return false;
        uint256 balance = address_hodler[hodler_address].balance;
        hodler_address.transfer(balance);
        address_hodler[hodler_address].balance = 0;
        address_hodler[hodler_address].registerTime = block.timestamp;
        return true;
    }

    receive() external payable {
        address payable hodler_address = payable(msg.sender);
        if (address_hodler[hodler_address].serial_number == 0) {
            AddHodler(hodler_address);
        }
        AddBalance(hodler_address, msg.value);
    }

    fallback() external payable {}

    function Destroy() external returns (bool) {
        if (CheckAllBalance() != 0) return false;
        selfdestruct(owner_address);
        return true;
    }
}