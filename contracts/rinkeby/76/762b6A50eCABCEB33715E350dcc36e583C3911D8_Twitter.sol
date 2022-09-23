/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Twitter {
    address private _owner; 
    
    constructor()  {
      _owner = msg.sender;
    }

    mapping(string => address) private addressOfTag; 
    mapping(address => uint) private balanceOfTags; 

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

    function contributeToHashTag(string calldata tag) external payable {
       require(msg.value > 100 wei, "Minimun donation is 100 wei.");
       address _address = address(uint160(uint256(keccak256(abi.encodePacked(tag)))));
       addressOfTag[tag] = _address; 
       balanceOfTags[_address] += msg.value; 
    }

    function getHashTagBalance(string calldata tag) external view returns(uint){
        return balanceOfTags[addressOfTag[tag]]; 
    }

    function transferFromHashTag(string memory tag, uint amount, address payable to) public onlyOwner{
        require(address(this).balance >= amount); 
        require(balanceOfTags[addressOfTag[tag]] >= (amount));
        balanceOfTags[addressOfTag[tag]] -= amount; 
        to.transfer((amount)); 
        if(balanceOfTags[addressOfTag[tag]] == 0){
            delete balanceOfTags[addressOfTag[tag]];
            delete addressOfTag[tag]; 
        }
    }

    function getBalance() public view returns (uint ) {
        return address(this).balance; 
    }
}