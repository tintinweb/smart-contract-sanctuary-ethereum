/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

contract Egov {
    struct Penalty {
        uint256 cost;
        string name;
        bool isPaid;
    }

    mapping(address => Penalty[]) addressToPenalties;
    mapping(address => uint256) addressToPenaltiesLength;
    mapping(string => bool) isNameTaken;

    constructor() {
    }

    function getPenaltiesLength() public view returns (uint256) {
        return addressToPenaltiesLength[msg.sender];
    }

    function getPenalty(string memory name)
        public
        view
        returns (
            uint256,
            string memory,
            bool
        )
    {
        for (uint256 i = 0; i < addressToPenaltiesLength[msg.sender]; i++) {
            if (
                keccak256(bytes(addressToPenalties[msg.sender][i].name)) ==
                keccak256(bytes(name))
            ) {
                return (
                    addressToPenalties[msg.sender][i].cost,
                    addressToPenalties[msg.sender][i].name,
                    addressToPenalties[msg.sender][i].isPaid
                );
            }
        }
    }

    function addPenalty(
        address _address,
        uint256 cost,
        string memory name
    ) public {
        require(msg.sender == _address);
        require(!isNameTaken[name]);
        addressToPenalties[_address].push(Penalty(cost, name, false));
        addressToPenaltiesLength[_address]++;
        isNameTaken[name]=true;
    }

    function payPenalty(string memory name) public payable {
        for (uint256 i = 0; i < addressToPenaltiesLength[msg.sender]; i++) {
            if (
                keccak256(bytes(addressToPenalties[msg.sender][i].name)) ==
                keccak256(bytes(name))
            ) {
                require(
                    addressToPenalties[msg.sender][i].cost ==
                        msg.value,
                    "Wrong amount"
                );
                addressToPenalties[msg.sender][i].isPaid = true;
            }
        }
    }
}