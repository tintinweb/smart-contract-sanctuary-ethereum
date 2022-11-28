// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;


import "./Ownable.sol";
import "./IERC1155.sol";
import "./ERC1155Receiver.sol";


contract ERC1155Hodler is ERC1155Receiver, Ownable {
  
    uint256 public constant BRONZE_TOKEN_ID = 1;
    uint256 public constant SILVER_TOKEN_ID = 2;
    uint256 public constant GOLD_TOKEN_ID = 3;
    uint256 public constant PLATINUM_TOKEN_ID = 4;
    uint256 public constant BLACK_TOKEN_ID = 5;

    address public wangenCollectionAddress = 0x8F4252878bDBE76a9475cbD2d38C386871db88E1;
    IERC1155 private wangenCollection;

    struct Tokens {
            uint256 bronzeAmount;
            uint256 silverAmount;
            uint256 goldAmount;
            uint256 platinumAmount;
            uint256 blackAmount;
    }

    mapping(address => Tokens) public stakes;
     
    function setWangenCollectionAddress(address  newaddr) external onlyOwner {
        wangenCollectionAddress = newaddr;
    }

    function unStake(uint256[] memory ids,uint256[] memory amounts ) external  {              
        require(ids.length == amounts.length, 'Bad ids and amounts parameters');

        uint256 bronzeAmount = stakes[msg.sender].bronzeAmount;
        uint256 silverAmount = stakes[msg.sender].silverAmount;
        uint256 goldAmount = stakes[msg.sender].goldAmount;
        uint256 platinumAmount = stakes[msg.sender].platinumAmount;
        uint256 blackAmount = stakes[msg.sender].blackAmount;
        bool  amountIsValid = true; 
        for(uint i = 0 ; i < ids.length; i++){
                if(ids[i] == BRONZE_TOKEN_ID && bronzeAmount < amounts[i] ){
                    amountIsValid = false;
                    break;
                }else if(ids[i] == SILVER_TOKEN_ID && silverAmount < amounts[i] ){
                    amountIsValid = false;
                    break;
                }else if(ids[i] == GOLD_TOKEN_ID && goldAmount < amounts[i] ){
                    amountIsValid = false;
                    break;
                }else if(ids[i] == PLATINUM_TOKEN_ID && platinumAmount < amounts[i] ){
                    amountIsValid = false;
                    break;
                }else if(ids[i] == BLACK_TOKEN_ID && blackAmount < amounts[i] ){
                    amountIsValid = false;
                    break;
                }
        }
        require(amountIsValid == true, 'Not enought token');
        bytes memory data  = bytes("0x00");
        wangenCollection = IERC1155(wangenCollectionAddress);
        wangenCollection.safeBatchTransferFrom(address(this),  msg.sender, ids, amounts, data);
       
        for(uint i = 0 ;  i < ids.length; i++) {
            if(ids[i] == BRONZE_TOKEN_ID){
                stakes[ msg.sender].bronzeAmount =  stakes[ msg.sender].bronzeAmount - amounts[i];
            }else if(ids[i] == SILVER_TOKEN_ID){
                stakes[ msg.sender].silverAmount =  stakes[ msg.sender].silverAmount - amounts[i];
            }else if(ids[i] == GOLD_TOKEN_ID){
                stakes[ msg.sender].goldAmount =  stakes[ msg.sender].goldAmount - amounts[i];
            }else if(ids[i] == PLATINUM_TOKEN_ID){
                stakes[ msg.sender].platinumAmount =  stakes[ msg.sender].platinumAmount - amounts[i];
            }else if(ids[i] == BLACK_TOKEN_ID){
                stakes[ msg.sender].blackAmount =  stakes[ msg.sender].blackAmount - amounts[i];
            }
        }

    }
  
  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
    )
    external
    override
    returns(bytes4)
    {
        require(msg.sender == wangenCollectionAddress, "Sender is not allowed");
        uint256 bronzeAmount = stakes[from].bronzeAmount;
        uint256 silverAmount = stakes[from].silverAmount;
        uint256 goldAmount = stakes[from].goldAmount;
        uint256 platinumAmount = stakes[from].platinumAmount;
        uint256 blackAmount = stakes[from].blackAmount;
        
        if(id == BRONZE_TOKEN_ID ){
            stakes[from].bronzeAmount = bronzeAmount + value;
        }
        if(id == SILVER_TOKEN_ID ){
            stakes[from].silverAmount = silverAmount + value;
        }
        if(id == GOLD_TOKEN_ID ){
            stakes[from].goldAmount = goldAmount + value;
        }
        if(id == PLATINUM_TOKEN_ID ){
            stakes[from].platinumAmount = platinumAmount + value;
        }
        if(id == BLACK_TOKEN_ID ){
            stakes[from].blackAmount = blackAmount + value;
        }
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
        )
        external
        override
        returns(bytes4)
        {
        require(msg.sender == wangenCollectionAddress, "Sender is not allowed");
            for (uint i = 0; i < ids.length; i++) {
                if(ids[i] == BRONZE_TOKEN_ID ){
                    stakes[from].bronzeAmount = stakes[from].bronzeAmount + amounts[i];
                }
                if(ids[i] == SILVER_TOKEN_ID ){
                    stakes[from].silverAmount = stakes[from].silverAmount + amounts[i];
                }
                if(ids[i] == GOLD_TOKEN_ID ){
                    stakes[from].goldAmount = stakes[from].goldAmount + amounts[i];
                }
                if(ids[i] == PLATINUM_TOKEN_ID ){
                    stakes[from].platinumAmount =  stakes[from].platinumAmount + amounts[i];
                }
                if(ids[i] == BLACK_TOKEN_ID ){
                    stakes[from].blackAmount =  stakes[from].blackAmount + amounts[i];
                }
            }
            
            return this.onERC1155BatchReceived.selector;
        }
    }