//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Greeter {
    string greet;
    address public owner = msg.sender;

    // The Ownable constructor sets the original `owner` of the contract to the sender account.
    constructor(){
        owner = msg.sender;
    }    

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    } 
    
    function setGreet(string memory _greet) public onlyOwner{
        greet = _greet;
    }

    function getGreet() public view returns(string memory){
        return greet;
    }

    function getOwner() public view returns(address){
        return owner;
    }

    // function getFunds(address _addrSender, uint _amount) public{
        
    // }

}