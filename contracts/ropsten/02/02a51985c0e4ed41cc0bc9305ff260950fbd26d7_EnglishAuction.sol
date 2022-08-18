/**
 *Submitted for verification at Etherscan.io on 2022-08-16
*/

pragma solidity ^0.4.21;

interface IERC20Token {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function decimals() external returns (uint256);
}

contract EnglishAuction {
    address seller;

    IERC20Token public token;
    uint256 public timeoutPeriod;

    uint256 public auctionEnd;

    constructor(
        IERC20Token _token,
        uint256 _timeoutPeriod
    )
        public
    {
        token = _token;
        timeoutPeriod = _timeoutPeriod;

        seller = msg.sender;
        auctionEnd = now + timeoutPeriod;
    }

    address highestBidder;

    mapping(address => uint256) public balanceOf;

    function withdraw() public {
        require(msg.sender != highestBidder);

        uint256 amount = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    event Bid(address highestBidder, uint256 bid);

    function bid(uint256 amount) public payable {
        // Complete this part

        require(now <= auctionEnd);
        require(balanceOf[msg.sender] <= 0);
        uint256 highestBid = balanceOf[highestBidder];
        require(amount > highestBid);
        // Accept bid
        balanceOf[msg.sender] = amount;
        highestBidder = msg.sender;
        // take money
        seller.transfer(amount);

        // Your code above this line

        auctionEnd = now + timeoutPeriod;

        emit Bid(highestBidder, amount);
    }

    function resolve() public {
        require(now >= auctionEnd);

        uint256 t = token.balanceOf(this);
        if (highestBidder == 0) {
            require(token.transfer(seller, t));
        } else {
            require(token.transfer(highestBidder, t));

            balanceOf[seller] += balanceOf[highestBidder];
            balanceOf[highestBidder] = 0;

            highestBidder = 0;
        }
    }
}