//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //0.8.12  >=0.8.7 <0.9.0

contract SimpleStorage {
    uint256 hasFavNum3;

    function store(uint256 _num) public virtual {
        hasFavNum3 = _num;
    }

    function store2(uint256 _num) public returns (uint256) {
        hasFavNum3 = _num;
        uint256 testVar = 5;

        return hasFavNum3 + testVar;
    }

    function retrieve() public view returns (uint256) {
        return hasFavNum3;
    }

    People public p1 = People({name: "xxx", age: 18});

    People public p2 = People(28, "xiaoming");

    People[] public peoples;

    mapping(string => uint256) public nameToAge;

    struct People {
        uint256 age;
        string name;
    }

    function addPerson(string memory _name, uint256 _age) public {
        peoples.push(People(_age, _name));

        nameToAge[_name] = _age;
    }
}