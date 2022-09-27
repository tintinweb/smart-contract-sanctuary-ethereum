/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract Auction {

    address payable public beneficiary; 
    uint public auctionStart;
    uint public auctionEndTime;
    string public name;
    uint public bidMin;
    uint biddingTime;
    uint energy;
    
    //estado actual de la subasta
    address public highestBidder;
    uint public highestBid;
    bool ended;

    // devoluciones pendientes {dirección => cantidad} 
    mapping(address => uint) public pendingReturns;

    // evento para cuando se supera la subasta
    event highestBidIncreased(address bidder, uint amount);

    //evento para cuando finaliza la subasta, indica quien gana y la cantidad
    event auctionEnded(address winner, uint amount);

    //evento para cuando alguien que no ha ganado la puja, retira su dinero (el beneficiario podría devolver el dinero a los que no ganan)
    event LogWithdrawal(address withdrawer, address withdrawalAccount, uint amount);

    constructor(uint _biddingTime, address payable _beneficiary, string memory _name, uint _bidMin, uint _energy) {
        require(block.timestamp <= block.timestamp + _biddingTime);
        require(_beneficiary != address(0x0));
        biddingTime = _biddingTime;
        beneficiary = _beneficiary;
        auctionStart = block.timestamp;
        auctionEndTime = block.timestamp + _biddingTime;
        name = _name;
        bidMin = _bidMin;
        energy = _energy;
    }

    function bid() public payable onlyBeforeEnd onlyExceedsMinimum onlyExceedsHighBid onlyNotBeneficiary {       
        if (highestBid != 0){
            pendingReturns[highestBidder] += highestBid; 
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        emit highestBidIncreased(msg.sender, msg.value);
    }

    function TimeNow() private view returns(uint){
        return block.timestamp;
    }

    function AuctionLeft() public view returns(uint){
        if (auctionEndTime > block.timestamp ) {
            return auctionEndTime - block.timestamp;
        } else {
            return 0;
        }
    }

    function BidAmount(address _bidder) public onlyBeneficiary view returns(uint) {
        uint amount = pendingReturns[_bidder];

        if (amount > 0) {
            return amount;
        } else {
            revert('This address has not made any bids');
        } 
    }

    function withdraw(address _withdrawalAccount) public payable returns(bool) {
        if (_withdrawalAccount == highestBidder) revert('The highest bidder cannot withdraw!');
        if (msg.sender != beneficiary && msg.sender != _withdrawalAccount) revert('you cannot withdraw from this account!');
        uint amount = pendingReturns[_withdrawalAccount];

        if (amount > 0) {
            pendingReturns[_withdrawalAccount] = 0;
        } else {
            revert('there is nothing to withdraw for this account');
        }

        if (!payable(_withdrawalAccount).send(amount)) {
            pendingReturns[_withdrawalAccount] = amount;
        }

        emit LogWithdrawal(msg.sender, _withdrawalAccount, amount);
        return true;
    }

    function auctionEnd() public onlyAfterEnd AuctionIsEnded {
        ended = true;
         
        emit auctionEnded(highestBidder, highestBid);
        beneficiary.transfer(highestBid);
    }

    modifier onlyBeneficiary {
        if (msg.sender != beneficiary) revert('Only the beneficiary can do this!');
        _;
    }

    modifier onlyNotBeneficiary {
        if (msg.sender == beneficiary) revert('The beneficiary can not bid!');
        _;
    }

    modifier onlyBeforeEnd {
        if (block.timestamp > auctionEndTime) revert('The auction has ended!');
        _;
    }

    modifier AuctionIsEnded {
        if (ended) revert('the auction is already over!');
        _;
    }

    modifier onlyAfterEnd {
        if (block.timestamp < auctionEndTime) revert('The auction has not ended yet!');
        _;
    }

    modifier onlyExceedsMinimum {
        if (highestBid == 0 && msg.value < bidMin) revert('sorry, the bid is below the minimum!');
        _;
    }

    modifier onlyExceedsHighBid {
        if (msg.value <= highestBid) revert('sorry, the bid is not high enough!');
        _;
    }
}