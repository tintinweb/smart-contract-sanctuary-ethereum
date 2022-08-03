/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract code2 {
    int n1;

    mapping(string => int) public nameToNo;

    struct People {
        int no;
        string name;
    }

    People public person1 = People({no: 12, name: "Sumit"});
    People[] public person;

    function set_n1(int _n1) public virtual {
        n1 = _n1;
    }

    function get_n1() public view returns (int) {
        return n1;
    }

    function set_person(string memory _name, int _no) public {
        person.push(People({name: _name, no: _no}));
        nameToNo[_name] = _no;
    }
}