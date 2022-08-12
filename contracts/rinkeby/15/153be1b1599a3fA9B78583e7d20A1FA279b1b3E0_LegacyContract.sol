// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

contract LegacyContract {
    struct Children {
        address adres;
        string name;
        uint256 balance;
        uint256 age;
    }

    struct Parent {
        address adres;
        string name;
        mapping(address => Children) childrens;
        uint256 childrenSize;
    }

    struct Admin {
        address adres;
        string name;
    }

    uint256 balanceAccessAge = 18;

    Admin public owner;

    mapping(address => Parent) public parents;

    address[] public parentAddress;

    uint256 public value;

    /* constructor(string memory _ownerName) {
        owner.adres = msg.sender;
        owner.name = _ownerName;
    } **/

    function joinParent(string memory _name) public {
        Parent storage newParent = parents[msg.sender];
        newParent.name = _name;
        newParent.adres = msg.sender;
        newParent.childrenSize = 0;
        parentAddress.push(msg.sender);
    }

    function addChildren(
        address _adres,
        string memory _name,
        uint256 _age
    ) public {
        Children memory newChild = Children(_adres, _name, 0, _age);
        parents[msg.sender].childrens[_adres] = newChild;
        parents[msg.sender].childrenSize++;
    }

    function sendMoney(address _toAdres) internal {}

    function testValueSet(uint256 _value) public {
        value = _value;
    }

    function testValueGet() public view returns (uint256) {
        return value;
    }

    function setBalanceAccessAge(uint256 _balanceAccessAge) public {
        balanceAccessAge = _balanceAccessAge;
    }

    function getBalanceAccessAge() public view returns (uint256) {
        return balanceAccessAge;
    }
}