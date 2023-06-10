/**
 *Submitted for verification at Etherscan.io on 2023-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract TestMintContract {
    //address public writingEditionsContract; // WritingEditions合约地址
    //string  public mintstr; // WritingEditions合约地址
    address public owner;
   
    mapping(address => uint256) private  tokenlist;
    uint256 public tokenid;  
    uint256 public price=0.000777 ether;
    constructor() {
        owner=msg.sender;
        tokenid=1;
    }

    function purchase(uint256 q) public  payable returns(uint256) {
        require(q>0,"q not >0");
        require(price==msg.value, "price not right");
        //payable(address(this)).transfer(msg.value);
        tokenlist[msg.sender]=(tokenid);
        tokenid++;
        return tokenlist[msg.sender];
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) external  {
        require(tokenId>0,"tokenId not >0");
        require(from==msg.sender,"address not right");

        if(tokenId==tokenlist[from]){
                 tokenlist[to]=(tokenId);
                  tokenlist[from]=0;
             }
    }

    
function withdraw() external {
    require(msg.sender == owner, "Only owner can withdraw");

    uint256 balance = address(this).balance;
    payable(owner).transfer(balance);
}
function find(address from) external view  returns(uint256){
        return (tokenlist[from]);
}

}