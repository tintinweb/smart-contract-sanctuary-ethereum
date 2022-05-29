/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

pragma solidity >=0.6.0 <=0.9.0;

contract simplestorage{

    uint256 number;

    struct people{
        string name;
        uint256 age;
    }

    people public person = people({name:"dick", age:18});

    people[] public People;

    mapping(string => uint256) public nametoage;

    function addperson(string memory _name, uint256 _age) public{
        People.push(people({name: _name, age: _age}));
        nametoage[_name]=_age;
    }

    function assign(uint256 _number) public{
        number = _number;
    }

    function read() public view returns(uint256){
        return number;
    }

}