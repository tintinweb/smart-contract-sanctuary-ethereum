/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

contract subasta {

    address payable public beneficiary; 
    uint public auctionStart;
    uint public auctionEndTime;
    string public name;
    uint public bidMin;
    uint biddingTime;
    
    //estado actual de la subasta
    address public highestBidder;
    uint public highestBid;
    bool ended;

    // devoluciones pendientes {dirección => cantidad} Lo podemos poner público
    mapping(address => uint) pendingReturns;

    // evento para cuando se supera la subasta
    event highestBidIncreased(address bidder, uint amount);

    //evento para cuando finaliza la subasta, indica quien gana y la cantidad
    event auctionEnded(address winner, uint amount);

    //evento para cuando alguien que no ha ganado la puja, retira su dinero (el beneficiario podría devolver el dinero a los que no ganan)
    event LogWithdrawal(address withdrawer, address withdrawalAccount, uint amount);

    constructor(uint _biddingTime, address payable _beneficiary, string memory _name, uint _bidMin) {
        require(block.timestamp <= block.timestamp + _biddingTime);
        require(_beneficiary != address(0x0));
        biddingTime = _biddingTime;
        beneficiary = _beneficiary;
        auctionStart = block.timestamp;
        auctionEndTime = block.timestamp + _biddingTime;
        name = _name;
        bidMin = _bidMin;
    }

    function bid() public payable onlyBeforeEnd onlyExceedsMinimum onlyExceedsHighBid onlyNotBeneficiary {       
        if (highestBid != 0){
            pendingReturns[highestBidder] += highestBid; 
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        emit highestBidIncreased(msg.sender, msg.value);
    }

    function TimeNow() public view returns(uint){
        return block.timestamp;
    }

    function AuctionLeft() public view returns(uint){
        return auctionEndTime - block.timestamp;
    }

    function BidAmount(address _bidder) public view onlyBeneficiary returns(uint) {
        uint amount = pendingReturns[_bidder];

        if (amount > 0) {
            return amount;
        } else {
            revert('This address has not made any bids');
        } 
    }

    function withdraw(address _withdrawalAccount) public payable returns(bool) {
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
        require(msg.sender == beneficiary);
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