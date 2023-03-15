/**
 *Submitted for verification at Etherscan.io on 2023-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IpfsCidDatabase {

    struct Element {
        string name;
        string cid;
    }

    address public administrator;
    uint256 public counter;
    mapping(uint256 => Element) elements;

    event newElementAdded(uint256 index, Element element);

    constructor() {
        administrator = msg.sender;
        counter = 0;
    }

    function getElement(uint256 index) public view returns(Element memory) {
        return elements[index];
    }

    function addElement(string memory name, string memory cid) public {
        require(msg.sender == administrator, "Access denied.");
        elements[counter] = Element(name, cid);
        emit newElementAdded(counter, elements[counter]);
        counter++;
    }

}