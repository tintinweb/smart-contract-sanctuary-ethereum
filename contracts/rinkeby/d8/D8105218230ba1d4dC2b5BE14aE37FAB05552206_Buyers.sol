// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Buyers {
    struct buyer {
        uint256 balance;
        address buyerAddress;
        string name;
    }

    mapping(address => buyer) addressToBuyer;

    function addNewBuyer(uint256 _balance, string memory _name) public {
        addressToBuyer[msg.sender] = buyer(_balance, msg.sender, _name);
    }

    function returnBuyer(address _address)
        public
        view
        returns (
            uint256,
            address,
            string memory
        )
    {
        return (
            addressToBuyer[msg.sender].balance,
            addressToBuyer[msg.sender].buyerAddress,
            addressToBuyer[msg.sender].name
        );
    }
}