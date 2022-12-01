// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

pragma experimental ABIEncoderV2;

contract A{
    uint public x;
    address public sender;
    uint160 adr = uint160(bytes20(sender));
    struct Instructor {
    uint age;
    string first_name;
    mapping(address=>uint) bills;
}
event Set(address account);
mapping(address=>Instructor) public instructors;

function set(address in_, address _in2) public {
    Instructor storage newI = instructors[in_];
    newI.age = 10;
    newI.first_name = "vasa";
    newI.bills[_in2] = 100;
    emit Set(in_);
}

function _getInstructor(address a) public view returns(uint age, string memory name){
    age = instructors[a].age;
    name = instructors[a].first_name;
}

    function setX() public payable{
        x = msg.value;
        sender = msg.sender;
    }

    function getX() public pure returns(uint){
        return 222;
    }
}

contract B{
    uint public x;
    address public sender;
    bytes[] public vasa = [bytes("vasa"), bytes("kolya")];
    event GetData(uint data);
    function setX(address contr) public payable {
        (bool success,) = contr.delegatecall(abi.encodeWithSignature("setX()"));
        require(success);
    }

    function getX() public view returns(uint){
        return x;
    }
}