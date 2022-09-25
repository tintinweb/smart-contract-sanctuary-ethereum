// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleStorage {
    // this will get initialized to 0!
    uint256 balance;
    string coin;

    struct People {
        uint256 p_balance;
        string p_coin;
        string p_name;
    }

    People[] public peeps;
    mapping(string => uint256) public name_to_balance;
    uint256[] public nums;

    function store(uint256 _balance) public {
        balance = _balance;
    }

    function retrieve() public view returns (uint256) {
        return balance;
    }

    function addNum(uint256 n) public {
        nums.push(n);
    }

    function getNums() public view returns (uint256[] memory) {
        return nums;
    }

    function addPerson(
        string memory _name,
        uint256 _balance,
        string memory _coin
    ) public {
        peeps.push(People(_balance, _coin, _name));
        name_to_balance[_name] = _balance;
    }

    function getPersons() public view returns (People[] memory) {
        return peeps;
    }
}