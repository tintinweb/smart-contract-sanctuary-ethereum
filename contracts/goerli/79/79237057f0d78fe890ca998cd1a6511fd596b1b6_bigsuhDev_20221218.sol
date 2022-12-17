/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

// File: class.sol


// bigsuh's contract
pragma solidity ^0.8.12;

contract bigsuhDev_20221218 {

    //uint count = 3;

    string count = "Frist Story";
    

    function printStory() public view returns(string memory){
        return count;
    }

    function addStory(string memory txt) public{
        count = string.concat(count, txt);
    }

    function buy() external payable {
        
    }

    function withdraw() external {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }

}