/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

//引用Solidity版本

contract SimpleStorage {
    //boolean, uint ,int , address,bytes
    //基础类型
    uint256 public favoritemNumber = 12;
    //映射
    mapping(string => uint256) public NametofavoritemMapping;

    // struct 结构体
    struct People {
        uint256 favoritemNumber;
        string name;
    }

    People[] public people;

    function addPerson(uint256 _favoritemNumber, string memory _name) public {
        people.push(People(_favoritemNumber, _name));
        //增加到映射
        NametofavoritemMapping[_name] = _favoritemNumber;
    }

    function store(uint256 _favoritemNumber) public virtual {
        favoritemNumber = _favoritemNumber;
        favoritemNumber = favoritemNumber + 1;
        //函数内调用消耗gas
        retrieve();
    }

    // view pure 不消耗gas
    function retrieve() public view returns (uint256) {
        return favoritemNumber;
    }

    function add() public pure returns (uint256) {
        return (1 + 1);
    }
}