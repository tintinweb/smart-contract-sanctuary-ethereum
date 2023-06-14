// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract SimpleStorage {
    uint256 public num;

    struct People {
        string name;
        uint256 age;
        string weapon;
        bool friendly;
    }

    People[] public people;
    mapping(string => uint256) public ageMap;
    mapping(string => string) public weaponMap;
    mapping(string => bool) public friendlyMap;

    function store(uint256 _num) public returns (uint256) {
        num = _num;
        return num;
    }

    function retrieve() public view returns (uint256) {
        return num;
    }

    function addPerson(
        string memory _name,
        uint256 _age,
        string memory _weapon,
        bool _friendly
    ) public {
        people.push(People(_name, _age, _weapon, _friendly));
        ageMap[_name] = _age;
        weaponMap[_name] = _weapon;
        friendlyMap[_name] = _friendly;
    }
}