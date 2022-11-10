pragma solidity ^0.8.13;
// SPDX-License-Identifier: UNLICENSED

import "./Owner.sol";

contract Auction is Ownable{
    uint256 epoch = 30 minutes;
    uint256 auctionEnd;
    uint256 auctionCount = 0;
    uint256 public biddersCount = 0;
    struct IBid{
        uint256 _amount;
        string _message;
        address _address;
    }
    mapping(uint256 => IBid) public bidders;
    mapping(address => uint256) public biddersAdd;
    mapping(uint256 => IBid) public highestBidderW;
    mapping(address => bool) public isHighest;

    // total funds won
    uint256 winningFundsT;
    // total won funds withdrawn
    uint256 winningFundsW;
    
    event Withdraw(address _address, uint256 _amount);

    constructor(){
        auctionEnd = block.timestamp + epoch;
    }

    function getHighestBidder() public view returns(uint256 _highestBidderIndex){
        uint256 highestValIndex = 1;
        for(uint i= 2; i <= biddersCount; i++){
            if(bidders[i]._amount > bidders[highestValIndex]._amount)
                highestValIndex = i;
        }
        return highestValIndex;
    }

    function update() external onlyOwner{
        resolve();
    }

    function bid(string memory _message) external payable{
        // bidded amount sent as ETH
        uint256 _amount = msg.value;
        resolve();

        uint256 index = biddersAdd[msg.sender];
        if(index == 0){
            // record the new bidder
            biddersCount = biddersCount + 1;
            index = biddersCount;
        }

        bidders[index] = IBid(
            bidders[index]._amount + _amount,
            _message,
            msg.sender
        );

        biddersAdd[msg.sender] = index;
    }


    function withdraw() external {
        resolve();
        require(biddersAdd[msg.sender] != 0, "No available bids / you were highest bidder");
        // record his bid as temp
        uint256 _bidAmt = bidders[biddersAdd[msg.sender]]._amount;

        // remove his data from current bidders
        bidders[biddersAdd[msg.sender]] = IBid(
            0,
            "",
            address(0)
        );
        biddersAdd[msg.sender] = 0;

        // refund the bid amount
        payable(msg.sender).transfer(_bidAmt);

        emit Withdraw(msg.sender, _bidAmt);
    }

    function getWinningBids() external onlyOwner{
        resolve();
        uint256 _toWithdraw = winningFundsT - winningFundsW;
        require(_toWithdraw > 0, "No available funds");
        winningFundsW = winningFundsW + _toWithdraw;
        payable(msg.sender).transfer(_toWithdraw);
        emit Withdraw(msg.sender, _toWithdraw);
    }

    function resolve() internal {
        // if the previous auction has ended?
        // check the highest bidder & record
        // update the new auction end date
        if(block.timestamp > auctionEnd) {
            // get highest bidder
            uint256 _indexH  = getHighestBidder();
            // increase auction's week count
            auctionCount = auctionCount + 1;
            // record the highest bidder data per week
            highestBidderW[auctionCount] = bidders[_indexH];
            // record the highest bidder data per address
            isHighest[bidders[_indexH]._address] = true;
            // increase the total withdraw available for owners
            winningFundsT = winningFundsT + bidders[_indexH]._amount;
            // remove his record from the current bidders mapping
            address _temp = bidders[_indexH]._address;
            bidders[biddersAdd[_temp]] = IBid(0, "", address(0));
            biddersAdd[_temp] = 0;
            // update the new ending date
            auctionEnd = endDate();
        }
    }

    function currentHighestBidder() external view returns(uint256 _amt, string memory _msg, address _add){
        uint256 _indexH  = getHighestBidder();
        IBid memory _b = bidders[_indexH];
        return(_b._amount, _b._message, _b._address);
    }

    function endDate() public view returns(uint256){
        if(block.timestamp > auctionEnd){
            uint256 newEnd = ((block.timestamp - auctionEnd) / epoch) * epoch;
            return (newEnd + auctionEnd + epoch);
        }
        else return auctionEnd;
    }

    function FundsAvailable() external view returns(uint256 _availableFunds) {
        uint256 _available = winningFundsT - winningFundsW;
        // if the previous auction has ended?
        // check the highest bidder & record
        // update the new auction end date
        if(block.timestamp > auctionEnd) {
            // get highest bidder
            uint256 _indexH  = getHighestBidder();
            _available = _available + bidders[_indexH]._amount;
        }
        return _available;
    }

    function TotalFundsWon() external view returns (uint256 _totalFunds){
        uint256 _total = winningFundsT;
        // if the previous auction has ended?
        // check the highest bidder & record
        // update the new auction end date
        if(block.timestamp > auctionEnd) {
            // get highest bidder
            uint256 _indexH  = getHighestBidder();
            _total = _total + bidders[_indexH]._amount;
        }
        return _total;
    }

    function TotalFundsWithdrawn() external view returns (uint256 _totalWithdraw){
        return winningFundsW;
    }
}