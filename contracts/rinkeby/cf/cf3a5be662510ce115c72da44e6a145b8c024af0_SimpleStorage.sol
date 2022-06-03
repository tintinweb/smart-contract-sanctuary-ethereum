/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 public number=5;
    bool hun = true;
    address myAddress = 0x7bb63Cae1Fbe48e46381fcBDB478b43da927048c;
    string[]  stTest = ["we", "wew", "lo"];
    uint[]  balance = [1, 2, 3];

    Person public bob = Person({number:12, name:"bob"});

    Person[] public people;

    mapping (string => uint256) public nameToNumber;


    struct Person {
        uint256 number;
        string name;
    }


    function store(uint256 _number) public{
        number = _number;
        
    }

    // View
    function square() public view returns(string memory){
        return bob.name;
    }
    
    // Pure
    function squarePure() public pure returns(uint256){
        return 2**2;
    }

    function addPerson(string memory _name, uint256 _number) public {
        people.push(Person(_number, _name));
        nameToNumber[_name] = _number;
    }

/*     function addPerson(string calldata _name, uint256 _number) public {
        _name = "qwq";
        people.push(Person(_number, _name));
    }
 */
}