//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Auction {
     //A smart contract that allows users to place bids and, after
     //the auction is complete, then users will withdraw their funds. 
     //The owner of the auction needs to be able to cancel the auction in exceptional cases,
     // and must also be allowed to withdraw the winning bid.

    address public owner;
    address payable _beneficiaryAddress;
    uint256 public _auctionCloseTime;

    // The current state of the auction.
    address public highestBidder;
    uint256 public _highestBid;

    // Allowed withdrawals of previous bids
    mapping(address => uint256) _returnsPending;

    // Will be set true once the auction is complete, it will prevent any further change
    bool auctionCompleted;
    bool ended;

    // Events to fire when change happens in the state.
    event highestBidIncrement(address bidder, uint bidAmount);
    event auctionResult(address winner, uint bidAmount);
    
     // owner to control the access to the contract
     modifier onlyOwner() {
         require(msg.sender == owner, "only owner has access to auction");
         _;
     }

      constructor() {
        // the owner that can call the address in the contract
        owner = msg.sender;
      }

      // Create an auctionAction with `_bidTime`
    // then the seconds for bidding on behalf of the beneficiary address `_beneficiary`.
     function auctionAction(uint _bidTime, address payable _beneficiary) external onlyOwner {
        _beneficiaryAddress = _beneficiary;
        _auctionCloseTime = block.timestamp + _bidTime;
     }

     function placeBid() external payable {
          // Reverting the call in case the bidding period is over.
        require(block.timestamp <= _auctionCloseTime, "Your bidding time is over! Try Again Chief!");
       
        // If the bid is not greater, the money will be sent back to the owner.
            if(msg.value > _highestBid) {
            
            if(_returnsPending[msg.sender] > 0)
            {
                uint amount = _returnsPending[msg.sender];
                payable(msg.sender).transfer(amount);
            }

            _returnsPending[msg.sender] = msg.value; 
            highestBidder = msg.sender;
            _highestBid = msg.value;
            emit highestBidIncrement(msg.sender, msg.value);
        }
        else {
            revert('sorry, the bid is not high enough. Check it again!');
        }
     }

      //withdraw bid that is overbid
     function withdraw() external payable returns(bool success) {
         uint bidAmount = _returnsPending[msg.sender];
         
         if(bidAmount > 0) {
            _returnsPending[msg.sender] = 0;

         } 
            if(!payable(msg.sender).send(bidAmount)) {
               _returnsPending[msg.sender] = bidAmount;
            }
             return true;
         }

        function auctionClose() external {
        require(block.timestamp > _auctionCloseTime, "The Auction Cannot End Before The Time You Specified"); // auction did not yet end
        //  require(!auctionCompleted); 
         if(auctionCompleted) 
         revert("the auction is already over! Try again chief!");
         auctionCompleted = true;
        emit auctionResult(highestBidder, _highestBid);
        _beneficiaryAddress.transfer(_highestBid);
    }

}