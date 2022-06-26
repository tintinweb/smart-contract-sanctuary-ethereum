// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SpaceToken.sol";
import "./IERC20.sol";

contract SpaceMarketplace is Ownable{
    SpaceToken private spaceToken;
    IERC20 private token;
    uint256 price;
    uint256 chargeRate;
   address public ownerAddress;
  struct TokenForSale {
    uint256 id;
    uint256 num;
    address  seller;
    uint256 createTime;
  }
  struct TokenBuyer {
    uint256 id;
    uint256 orderId;
    uint256 num;
    address  buyer;
    uint256 createTime;
  }
  TokenForSale[] public orderList;
  TokenBuyer[] public recordList;
  event itemSold(uint256 id, address buyer, uint256 num);

  constructor(SpaceToken _spaceToken,IERC20 _token,uint256 _price) {
      token = _token;
      spaceToken = _spaceToken;
      price = _price;
      ownerAddress=msg.sender;
  }




  function putTokenForSale(uint256 _num,address _seller)
    external 
    returns (uint256){
      require(msg.sender ==  address(spaceToken), "Sender does not own the item");
      uint256 newItemId = orderList.length;
      orderList.push(TokenForSale({
        id: newItemId,
        num  : _num,
        seller: _seller,
        createTime: block.timestamp
      }));
      assert(orderList[newItemId].id == newItemId);
      return newItemId;
  }

  function buyItem(uint256 _id,uint256 _num)
    payable
    external {
      require(token.balanceOf(msg.sender) >= _num*price*(10 ** 4), "Not enough token sent");
      require(orderList.length >= _id, "The order is invalid");
      require(msg.sender != orderList[_id].seller,"Can't buy your own token!");
      uint256 newItemId = recordList.length;
      recordList.push(TokenBuyer({
      id: newItemId,
      orderId: _id,
      num  : _num,
      buyer: msg.sender,
      createTime: block.timestamp
      }));
       orderList[_id].num = orderList[_id].num-_num;
      spaceToken.transferFrom(ownerAddress, msg.sender, _num*(10 ** 18));
      token.transferFrom(msg.sender,orderList[_id].seller,_num*price*(10 ** 4));
      emit itemSold(_id, msg.sender, _num);
    }


   function soldOut(uint256 id) external  returns(bool) {
     require(id < orderList.length && orderList[id].id == id, "Could not find order");
     require(msg.sender == orderList[id].seller,"You're not the seller!");
     require(orderList[id].num>0,"It's already sold!");
     uint256 residualNum=orderList[id].num;
     orderList[id].num=0;
     spaceToken.transferFrom(ownerAddress, msg.sender, residualNum*(10 ** 18));
     return true;
  }
  function getOwnerAddress() external view returns(address) {
    return ownerAddress;
  }
  function setPrice(uint256 _price) public onlyOwner{
      price = _price;
  }
}