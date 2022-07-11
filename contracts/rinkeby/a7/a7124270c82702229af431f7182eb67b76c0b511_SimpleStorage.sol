/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

contract SimpleStorage {
    uint256 num; //initialized to zero. default visibility is internal
    address myAdd = 0x4d4438D2752A0Af1c2f58202D1f698F01700888C;

    struct People {
        uint256 num;
        string name;
    }

    mapping(string => uint256) public balances;

    People[] public people;

    function store(uint256 input) public {
        num = input;
    }

    //view and pure keywords don't change the state of the blockchain, so they don't cost gas to run
    function retrieve() public view returns(uint256) {
        return num;
    }

    //we need to decide whether to store the string in memory or in storage. Memory means that only used for this function, storage means it is stored forever
    function addPerson(string memory _name, uint256 _num) public{
        people.push(People(_num,_name));
        balances[_name] = _num;
    }
}