/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;
contract Escrow {
   struct trading {
       address  seller;
       address  buyer;
       uint256 value;
       bool isPaid ;
   }
    
    mapping(string  => trading) public trading_data ;
    event Deposit(address seller  , address buyer , uint256 value);
     event  confirmDeliveryy( address buyer , string _id);
    event GetSeller_Buyer(address seller  , address buyer , string  _id);

    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE , CANCEL}
    State public currState;
    modifier onlySeller(string memory   _id) {
        require(msg.sender == trading_data[_id].seller, "Only seller can call this method");
        _;
    }
     function getSeller_Buyer(string memory  _id ,address  _buyer, address _seller) public {
         trading_data[_id].seller = _seller;
          trading_data[_id].buyer = _buyer;
          emit GetSeller_Buyer(trading_data[_id].seller  , trading_data[_id].buyer , _id);
    }
  
    function deposit(string memory  _id , uint256 _value )  external  returns (bool) {
        require(!trading_data[_id].isPaid , "you already paid "  ) ; 
         trading_data[_id].value = _value;
        currState = State.AWAITING_DELIVERY;
        
       trading_data[_id].isPaid = true ; 
       emit Deposit( trading_data[_id].seller , trading_data[_id].buyer , trading_data[_id].value);

       return  trading_data[_id].isPaid ;
         


    }
    function confirmDelivery(string memory  _id , uint256 _value)  onlySeller( _id) external {
        
        trading_data[_id].value = _value;

         emit confirmDeliveryy( trading_data[_id].buyer , _id);
        currState = State.COMPLETE;
    }
    function dispute_Delivery(string memory  _id , uint256 _value)   external {
         trading_data[_id].value = _value;
        currState = State.CANCEL;
    }

    function search(string memory _id) public view returns (trading memory) {
        return trading_data[_id];
    }
}