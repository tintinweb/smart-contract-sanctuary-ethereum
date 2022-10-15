/**
 *Submitted for verification at Etherscan.io on 2022-10-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract DevilGirlRefund{

    address public nft = address(0x941627511d283B3B8B502a9a77E041535852B53c);
    mapping(address => bool) public withrawed;
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
        uint256 refundNum = numberMinted*price;
        withrawed[msg.sender] = true;
        payable(msg.sender).transfer(refundNum);
    }



    function withdrawETH() public{

        require(msg.sender == owner, "Not owner.");
        payable(owner).transfer(address(this).balance);
    }


}

interface DevilGirl{
    function numberMinted(address _owner) external view returns (uint256);
}