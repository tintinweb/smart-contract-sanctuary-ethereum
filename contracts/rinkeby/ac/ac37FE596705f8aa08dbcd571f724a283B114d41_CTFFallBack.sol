/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

pragma solidity ^0.4.21;

contract CTFFallBack {
    address private owner;
    function CTFFallBack () {
        owner = msg.sender;
    }

    // 强制发送以太币给 _address
    function attack(address _address) public payable{
        require(msg.value == 0.0001 ether);
        // selfdestruct(_address);
        address(_address).call.value(msg.value);
    }

    function attack2(address _address) public payable{
        require(msg.value == 0.0001 ether);
        // selfdestruct(_address);
        address(_address).call.value(msg.value).gas(1000000);
    }

    function attack3(address _address) public payable{
        require(msg.value == 0.0001 ether);
        // selfdestruct(_address);
        address(_address).transfer(msg.value);
    }

    function attack4(address _address) public payable{
        require(msg.value == 0.0001 ether);
        // selfdestruct(_address);
        address(_address).send(msg.value);
    }


    function addMoney() public payable{
    }

    function withdraw() public{
        require(msg.sender == owner);

        owner.transfer(address(this).balance);
    }
}