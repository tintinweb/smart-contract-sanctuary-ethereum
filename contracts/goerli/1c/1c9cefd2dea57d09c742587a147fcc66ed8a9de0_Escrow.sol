/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;
contract Escrow {
   struct trading {
       address  payable seller;
       address payable  buyer;
       uint256 value;
       bool isPaid ;
   }
    
    mapping(uint256 => trading) public trading_data ;
    event Deposit(address seller  , address buyer , uint256 value);
     event  confirmDeliveryy( address buyer , uint256 _id);
    event GetSeller_Buyer(address seller  , address buyer , uint256 _id);

    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE , CANCEL}
    State public currState;
    modifier onlySeller(uint256 _id) {
        require(msg.sender == trading_data[_id].seller, "Only seller can call this method");
        _;
    }
     function getSeller_Buyer(uint256 _id ,address payable _buyer, address payable  _seller) public {
         trading_data[_id].seller = _seller;
          trading_data[_id].buyer = _buyer;
          emit GetSeller_Buyer(trading_data[_id].seller  , trading_data[_id].buyer , _id);
    }
  
    function deposit(uint256 _id )  external  payable returns (bool) {
        require(!trading_data[_id].isPaid , "you already paid "  ) ; 
         trading_data[_id].value = msg.value;
        currState = State.AWAITING_DELIVERY;
        
       trading_data[_id].isPaid = true ; 
       emit Deposit( trading_data[_id].seller , trading_data[_id].buyer , trading_data[_id].value);

       return  trading_data[_id].isPaid ;
         


    }
    function confirmDelivery(uint256 _id )  onlySeller( _id) external {
         trading_data[_id].buyer.transfer(trading_data[_id].value);
         emit confirmDeliveryy( trading_data[_id].buyer , _id);
        currState = State.COMPLETE;
    }
    function dispute_Delivery(uint256 _id )   external {
         trading_data[_id].seller.transfer(trading_data[_id].value);
        currState = State.CANCEL;
    }
}