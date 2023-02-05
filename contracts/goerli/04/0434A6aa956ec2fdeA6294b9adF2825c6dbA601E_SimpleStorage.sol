// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

/**
 * @title ContractName
 * @dev ContractDescription
 * @custom:dev-run-script file_path
 */

contract SimpleStorage {
    uint256 public favoriteNumber;
    mapping(string => uint256) public nameToNum;

    struct People {
        string name;
        uint256 num2;
    }

    // People public people = People({name: "Godstime", num2:70});
    People[] public people;

    function store(uint256 _num) public {
        favoriteNumber = _num;
    }

    function retrieve(string memory _name, uint256 _num2) public {
        people.push(People(_name, _num2));
        // people.push(People({name: _name, num2: _num2}));
        nameToNum[_name] = _num2;
    }
}
// 0xd9145CCE52D386f254917e481eB44e9943F39138