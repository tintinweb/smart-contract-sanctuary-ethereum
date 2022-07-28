/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

struct Instructor{
    uint age;
    string name;
    address addr;
}

enum State{
    Open,
    Closed,
    Unkown

}


contract School{

}


contract Academy{
    Instructor public academyIns;
    State public academyState = State.Open;

    constructor(uint _age, string memory _name){
        academyIns.name = _name;
        academyIns.age = _age;
        academyIns.addr = msg.sender;
    }

    function changeInstructor(uint _age, string memory _name) public{
        if(academyState == State.Open){
            Instructor memory myInstructor = Instructor({
                age: _age,
                name: _name,
                addr: msg.sender
            });
            academyIns = myInstructor;
        }
    }

    function changeInstructor2(uint _age, string memory _name) public{
        academyIns.name = _name;
        academyIns.age = _age;
    }
}

contract Pratice{

    //1. Boolean type
    bool public sold;

    //2. interger type
    uint8 public value;

    uint[3] public numbers = [1, 2, 3];

    bytes1 public b1;
    bytes2 public b2;
    bytes3 public b3;

    uint[] public nums;

    bytes public bs1 = 'abc';
    string public s1 = 'abc';

    function setElement(uint index, uint val) public{
        numbers[index] = val;
    }

    function getLength() public view returns(uint){
        return numbers.length;
    }

    function setBytesArray() public{
        b1 = "a";
        b2 = "ab";
        b3 = "abc";
    }
    
    function getLength2() public view returns(uint){
        return nums.length;
    }

    function addElement(uint item) public {
        nums.push(item);
    }

    function getElement(uint i) public view returns(uint){
        if(i < nums.length){
            return nums[i];
        }
        return 0;
    }

    function addElement() public{
        bs1.push('d');
        // s1.push('d');
    }

    function getElement2(uint i) public view returns(bytes1){
        return bs1[i];
    }

}


//for mappings
contract Auction{
    mapping(address => uint) public bids;


    function bid() payable public{
        bids[msg.sender] = msg.value;
    }
}

contract StorageAndMemory{
    string[] public cities = ['Singapore','Paris'];


    function f_memory() public{
        string[] memory s1 = cities;
        s1[0] = 'BeiJing';
    }

    function f_storage() public{
        string[] storage s1 = cities;
        s1[0] = 'BeiJing';
    }
}

contract GlobalVariables{
    address public owner;
    uint public sentValue;
    uint public this_moment = block.timestamp;
    uint public block_number = block.number;
    uint public difficulty = block.difficulty;
    uint public gaslimit = block.gaslimit;

    constructor(){
        owner = msg.sender;
    }

    function changeOwner() public{
        owner = msg.sender;
    }

    function sendEth() public payable{
        sentValue = msg.value;
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }


    function howMuchGas() public view returns(uint){
        uint start = gasleft();
        uint j = 1;
        for(uint i = 1; i < 20; i++){
            j *= i;
        }
        uint end = gasleft();
        return start - end;
    }
}


contract Deposit{

    address public owner;

    constructor(){
        owner = msg.sender;
    }

    receive() external payable{

    }

    fallback() external payable{

    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function sendEth() public payable{
        uint x;
        x++;
    }

    function transferEth(address payable recipient, uint amount) public returns(bool){
        require(owner == msg.sender, "Transfer failed, you are not the owner!");

        if(amount <= address(this).balance){
            recipient.transfer(amount);
            return true;
        }
        return false;
    }
}

contract VisiblityTest{
    int public x = 10;
    int y = 20;

    function getY() public view returns(int){
        return y;
    }

    function f1() private view returns(int){
        return x;
    }

    function f2() public view returns(int){
        int a = f1();
        return a;
    }

    function f3() internal view returns(int){
        return x;
    }

    function f4() external view returns(int){
        return x;
    }

    function f5() public pure returns(int){
        return 0;
    }
}

contract VisiblityTest2 is VisiblityTest{
    int public xy = f3();
}

contract VisiblityTest3{
    VisiblityTest public contractA = new VisiblityTest();
    int public xx = contractA.f4();
    // int public y = contractA.f3();
    // int public x = contractA.f1();
}