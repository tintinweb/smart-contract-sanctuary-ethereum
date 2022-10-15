/**
 *Submitted for verification at Etherscan.io on 2022-10-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract DevilGirlRefund{

    address public nft = address(0x941627511d283B3B8B502a9a77E041535852B53c);
    mapping(address => bool) public withrawed;
    uint256 public maxPayedTokenId = 190;
    uint256 public price = 0.003 ether;
    address public owner;

    constructor()
    {
        owner = msg.sender;
    } 

    fallback () payable external {

    }


    function refund() public {
        
        require(!withrawed[msg.sender],"Withdrawed.");
        uint256 numberMinted = DevilGirl(nft).numberMinted(msg.sender);
        require(numberMinted > 0,"Not minted.");
        uint256 balance = DevilGirl(nft).balanceOf(msg.sender);
        require(balance > 0, "No nft.");
        uint256 refundNum;
        for(uint256 i = 0 ; i < balance; i++){
            uint256 tokenId = DevilGirl(nft).tokenOfOwnerByIndex(msg.sender,i);
            if(tokenId <= maxPayedTokenId){
                refundNum += price;
            }
        }
        withrawed[msg.sender] = true;
        payable(msg.sender).transfer(refundNum);
    }

    function setMaxPayedTokenId(uint256 _maxPayedTokenId) public{

        require(msg.sender == owner, "Not owner.");
        maxPayedTokenId = _maxPayedTokenId;
    }


    function withdrawETH() public{

        require(msg.sender == owner, "Not owner.");
        payable(owner).transfer(address(this).balance);
    }


}

interface DevilGirl{
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function numberMinted(address _owner) external view returns (uint256);
}