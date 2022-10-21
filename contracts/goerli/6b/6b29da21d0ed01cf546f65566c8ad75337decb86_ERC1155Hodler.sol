// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC1155Receiver.sol";


contract ERC1155Hodler is ERC1155Receiver {
  
 uint256 public BRONZE_TOKEN_ID = 1;
 uint256 public SILVER_TOKEN_ID = 2;
 uint256 public GOLD_TOKEN_ID = 3;
 uint256 public PLATINUM_TOKEN_ID = 4;
 uint256 public BLACK_TOKEN_ID = 5;

  struct Staker {
        uint256 bronzeAmount;
        uint256 silverAmount;
        uint256 goldAmount;
        uint256 platinumAmount;
        uint256 blackAmount;
        uint256 timestamp;
   }

   mapping(address => Staker) public stakes;
  

    function unStake(uint256 bronzeCount, uint256 silverCount, uint256 goldCount, uint256 platiniumCount, uint256 blackCount) external  {
      
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

        stakes[msg.sender] = Staker(0,0,0,0,0, block.timestamp);
        return this.onERC1155BatchReceived.selector;
    }

function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata ids,
    uint256[] calldata values,
    bytes calldata data
    )
    external
    override
    returns(bytes4)
    {
        stakes[msg.sender] = Staker(0,0,0,0,0, block.timestamp);
        return this.onERC1155BatchReceived.selector;
    }
}