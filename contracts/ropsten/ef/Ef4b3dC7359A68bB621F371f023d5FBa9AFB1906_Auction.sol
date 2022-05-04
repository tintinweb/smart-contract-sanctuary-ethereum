//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.4;

contract Auction {
    mapping(address => uint256) biddersData;
    uint256 highestBidAmount;
    address highestBidder;
    uint256 startTime = block.timestamp;
    uint256 endTime;
    bool endAuction = false;

    //put new bid
    function putBid() public payable {
        uint256 calculateAmount = biddersData[msg.sender] + msg.value;
        require(endAuction == false, "auction is ended");
        require(msg.value > 0, "Bid amount cannot be zero");
        //require(block.timestamp<=endTime,"auction is ended");

        require(
            highestBidAmount < calculateAmount,
            "highest bid already present"
        );

        biddersData[msg.sender] = calculateAmount;
        highestBidAmount = calculateAmount;
        highestBidder = msg.sender;
    }

    function getBidderBid(address _address) public view returns (uint256) {
        return biddersData[_address];
    }

    //get highest bid bidAmount
    function HighestBid() public view returns (uint256) {
        return highestBidAmount;
    }

    //get highest bidder address
    function HighestBidder() public view returns (address) {
        return highestBidder;
    }

    //put end time
    function putEndTime(uint256 _endTime) public {
        endTime = _endTime;
    }

    function EndAuction() public {
        endAuction = true;
    }

    function withdrawBid(address payable _address) public {
        require(biddersData[_address] > 0, "you havent bid");
        require(_address != highestBidder, "highest bidder cannot refund");
        _address.transfer(biddersData[_address]);
    }
}