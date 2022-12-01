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
    string last_name;
    mapping(address=>uint) bills;
}
mapping(address=>Instructor) public instructors;

function set(address in_, address _in2) public {
    Instructor storage newI = instructors[in_];
    newI.age = 10;
    newI.first_name = "vasa";
    newI.last_name = "kolya";
    newI.bills[_in2] = 100;
}

function getInstructor(address a) internal view returns(Instructor storage){
    return instructors[a];
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