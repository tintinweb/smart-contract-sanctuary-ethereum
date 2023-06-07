/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract TestMintContract {
    //address public writingEditionsContract; // WritingEditions合约地址
    //string  public mintstr; // WritingEditions合约地址
    address public owner;
   
    mapping(address => uint256) public mintcount;
    mapping(address => uint256) public claimcount;
    mapping(address => uint256) public tokenlist;
    uint256 public tokenid;  
    uint256 public price=0.000777 ether;
    constructor() {
        owner=msg.sender;
        tokenid=1;
    }

    function mint(address toaddress) external payable {
         mintcount[toaddress]++;
    }
    function claim(address toaddress) external payable {
         claimcount[toaddress]++;
    }
    function purchase(uint256 q) external payable returns(uint256) {
        require(q>0,"q not >0");
        require(price==msg.value, "price not right");
        payable(address(this)).transfer(msg.value);
        tokenlist[msg.sender]=(tokenid);
        tokenid++;
        return tokenlist[msg.sender];
    }
    function transferFrom(address from, address to, uint256 tokenId) external  {
        require(tokenId>0,"tokenId not >0");
        require(from==msg.sender,"address not right");

        if(tokenId==tokenlist[from]){
                 tokenlist[to]=(tokenId);
                  tokenlist[from]=0;
             }
    }

    function removeElement(uint256[] storage array, uint256 element) internal {
    for (uint256 i = 0; i < array.length; i++) {
        if (array[i] == element) {
            if (i < array.length - 1) {
                array[i] = array[array.length - 1];
            }
            array.pop();
            break;
        }
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