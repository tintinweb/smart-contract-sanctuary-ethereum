// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./NTVE721_eth.sol";


contract Trader {

    mapping(address => mapping(uint256 => Listing)) public listings;


    uint256 public adminFeesCollected;


    address public adminAccount;

    constructor(){
        adminAccount = msg.sender;
    }

   
    struct Listing {
        uint256 price;
        address seller;
    }




    function changeAdmin(address _newAccount)public{
        require(msg.sender == adminAccount , "Only admin allowed to change");
        adminAccount = _newAccount;
    }


    function addListing(uint256 price, address contractAddr, uint256 tokenId) public {
        ERC721 token = ERC721(contractAddr);
        require(token.ownerOf(tokenId) == msg.sender, "caller must own given token");
        require(token.getApproved(tokenId) == address(this), "contract must be approved");
        listings[contractAddr][tokenId] = Listing(price,msg.sender);

    }

 


    function purchase(address contractAddr, uint256 tokenId) public payable {
        Listing memory item = listings[contractAddr][tokenId];
        address payable seller = payable(item.seller); 
        address payable admin = payable(adminAccount);
        require(msg.value >= item.price, "insufficient funds sent");
        
        uint256 adminFee = (msg.value * 2/100);
        adminFeesCollected += adminFee;

        ERC721 token = ERC721(contractAddr);

        address tokenCreator = token.getCreator(tokenId);
        address tokenOwner = token.ownerOf(tokenId);
        uint256 royalty = token.royaltyFee(tokenId); 

        
        if(tokenOwner != tokenCreator){

            //transfer with royalty
         
            uint256 royaltyFee = (msg.value * royalty/100);
            
   
            payable(tokenCreator).transfer(royaltyFee);
            admin.transfer(adminFee);
            seller.transfer(msg.value - (adminFee)- (royaltyFee));       
      
        }

        else
        {           
            //transfer without royalty
            admin.transfer(adminFee);
            seller.transfer(msg.value - (adminFee));           
        }

        token.transferFrom(item.seller,msg.sender,tokenId);
        delete listings[contractAddr][tokenId];
        
    }
}