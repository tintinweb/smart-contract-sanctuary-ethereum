/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;
contract Escrow {
   struct trading {
       address  payable seller;
       address payable  buyer;
       uint256 value;
       bool isPaid ;
       bool initialized ;
       State  currState;
   }

   address public owner ;
    
    mapping(uint256 => trading) internal  trading_data ;
    event Deposit(address seller  , address buyer , uint256 value);
     event  confirmDeliveryy( address buyer , uint256 _id);
    event GetSeller_Buyer(address seller  , address buyer , uint256 _id);

    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE , CANCEL}
    
    modifier onlySeller(uint256 _id) {
        require(msg.sender == trading_data[_id].seller, "Only seller can call this method");
        _;
    }
       modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        
        _;
    }
      constructor() {
        owner = msg.sender;
    }
     function getSeller_Buyer(uint256 _id ,address payable _buyer, address payable  _seller) onlyOwner  public {
        require(trading_data[_id].initialized == false , "sorry this trade already initialized");
          trading_data[_id].seller = _seller;
          trading_data[_id].buyer = _buyer;
          trading_data[_id].initialized = true ;
          emit GetSeller_Buyer(trading_data[_id].seller  , trading_data[_id].buyer , _id);
    }
  
    function deposit(uint256 _id ) onlySeller( _id) external  payable returns (bool) {
        require(!trading_data[_id].isPaid , "you already paid "  ) ; 
         trading_data[_id].value = msg.value;
        trading_data[_id].currState = State.AWAITING_DELIVERY;
        
       trading_data[_id].isPaid = true ; 
       emit Deposit( trading_data[_id].seller , trading_data[_id].buyer , trading_data[_id].value);

       return  trading_data[_id].isPaid ;
    }
    function confirmDelivery(uint256 _id )  onlySeller( _id) external {
        require(trading_data[_id].currState == State.AWAITING_DELIVERY , "This trade is not ready for complete");
         trading_data[_id].buyer.transfer(trading_data[_id].value);
         emit confirmDeliveryy( trading_data[_id].buyer , _id);
        trading_data[_id].currState = State.COMPLETE;
    }
    function dispute_Delivery(uint256 _id )  onlyOwner external {
        require(trading_data[_id].currState != State.COMPLETE , "This trade already completed");
         trading_data[_id].seller.transfer(trading_data[_id].value);
        trading_data[_id].currState = State.CANCEL;
    }

     
}