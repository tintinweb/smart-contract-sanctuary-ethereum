/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Twitter {
    address private _owner; 
    
    constructor()  {
      _owner = msg.sender;
    }

    mapping(string => bytes32) public addressOfTag; 
    mapping(bytes32 => uint) private balanceOfTags; 


    function owner() public view returns(address) {
        return _owner;
    }

    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function donateToHashTag(string calldata tag, uint amount) external payable {
       require(msg.value== amount * (10 ** 18)); 
       bytes32 _address = keccak256(abi.encodePacked(tag));
       addressOfTag[tag] = _address; 
       balanceOfTags[_address] += amount * (10 ** 18); 
    }

    function getDonatedAmountToHashTag(string calldata tag) external view returns(uint){
        return balanceOfTags[addressOfTag[tag]]; 
    }

    function transferFromHashTag(string memory tag, uint amount, address payable to) public onlyOwner{
        require(address(this).balance >= amount* (10 * 18)); 
        balanceOfTags[addressOfTag[tag]] -= amount * (10 ** 18); 
        to.transfer((amount * (10 ** 18))); 
        if(balanceOfTags[addressOfTag[tag]] == 0){
            delete balanceOfTags[addressOfTag[tag]];
            delete addressOfTag[tag]; 
        }
    }

    function getBalance() public view returns (uint ) {
        return address(this).balance; 
    }
}