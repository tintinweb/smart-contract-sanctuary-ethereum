// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract SimpleStorage {
    uint256 number;
    People[] public people;
    mapping(string => uint256) public nameToNumber;

    struct People {
        uint256 number;
        string name;
    }

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public virtual {
        number = num;
    }

    function addPerson(string memory _name, uint256 _number) public {
        People memory newPerson = People({number: _number, name: _name});
        people.push(newPerson);
        nameToNumber[_name] = _number;
    }

    /**
     * @dev Return value
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256) {
        return number;
    }
}