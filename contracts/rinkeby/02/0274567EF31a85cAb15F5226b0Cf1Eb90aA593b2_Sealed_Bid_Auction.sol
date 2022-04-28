// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract Sealed_Bid_Auction {
    address public owner;
    string public DOGGO_NFT =
        "https://drive.google.com/file/d/1ULKxa4PFUAg0Q7NsyfErE3p6_669Kf5u/view?usp=sharing";
    bool public auction_open = false;
    bool public no_one_bidded = false;
    bool public pending_sale = false;
    uint256 public auction_end_time = 0;
    uint256 public base_price = 0;

    address[] bidderAddresses;
    mapping(address => uint256) addressToAmountBidded;

    address public pendingWinner;
    uint256 public pendingPaymentAmnt = 0;

    constructor() public {
        owner = msg.sender;
    }

    function get_owner() public view returns (address) {
        return owner;
    }

    function get_nft() public view returns (string memory) {
        return DOGGO_NFT;
    }

    function get_pendingWinner_and_price()
        public
        view
        returns (address, uint256)
    {
        return (pendingWinner, pendingPaymentAmnt);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _; // The sell_nft() function will run after checking that the owner called the function
    }

    function sell_nft(uint256 _auction_time, uint256 _base_price)
        public
        onlyOwner
    {
        auction_open = true;
        auction_end_time = block.timestamp + _auction_time;
        base_price = _base_price;
    }

    function check_if_auction_open() public view returns (bool, uint256) {
        return (auction_open, auction_end_time);
    }

    function check_if_bidded_before() internal view returns (bool) {
        for (uint256 i = 0; i < bidderAddresses.length; i++)
            if (msg.sender == bidderAddresses[i]) return true;

        return false;
    }

    modifier auction_open_check_bidder() {
        require(auction_open == true, "The auction is not open");
        require(
            block.timestamp < auction_end_time,
            "The auction no longer open"
        ); //Check this in case no one has calculated results yet
        require(msg.sender != owner, "The owner cannot bid");
        require(check_if_bidded_before() == false, "You have already bidded");

        _;
    }

    function submit_bid(uint256 _ethAmount) public auction_open_check_bidder {
        require(
            _ethAmount >= base_price,
            "Bid price must be greater than base_price"
        );
        bidderAddresses.push(msg.sender);
        addressToAmountBidded[msg.sender] = _ethAmount;
    }

    function find_winner_and_price() internal {
        uint256 highestBid = 0;
        address highestBidder;
        uint256 secondHighest = 0;

        //If there is only one bidder, they will only pay the base_price
        if (bidderAddresses.length == 1) {
            highestBidder = bidderAddresses[0];
            secondHighest = base_price;
        } else {
            for (uint256 i = 0; i < bidderAddresses.length; i++) {
                if (addressToAmountBidded[bidderAddresses[i]] > highestBid) {
                    highestBid = addressToAmountBidded[bidderAddresses[i]];
                    highestBidder = bidderAddresses[i];
                }
            }

            for (uint256 i = 0; i < bidderAddresses.length; i++) {
                if (highestBidder == bidderAddresses[i]) continue;
                else if (
                    addressToAmountBidded[bidderAddresses[i]] > secondHighest
                ) secondHighest = addressToAmountBidded[bidderAddresses[i]];
            }
        }
        pendingWinner = highestBidder;
        pendingPaymentAmnt = secondHighest;
    }

    modifier auction_ended() {
        require(
            block.timestamp + 10 seconds >= auction_end_time,
            "The auction is not over"
        );
        require(auction_open == true, "The auction is not open");
        _;
    }

    function get_auction_results() public auction_ended {
        auction_open = false;
        if (bidderAddresses.length > 0) {
            pending_sale = true;
            find_winner_and_price();
        } else no_one_bidded = true;
    }

    modifier only_winner() {
        require(msg.sender == pendingWinner, "You are not the pending winner");
        require(
            msg.value == pendingPaymentAmnt,
            "Please send the amount of ETH for 'pendingAmnt' "
        );
        _;
    }

    function transfer_ownership() public payable only_winner {
        payable(owner).transfer(address(this).balance);
        owner = msg.sender;

        //Need To Reset the Dictionary and Array of bidders
        for (uint256 i = 0; i < bidderAddresses.length; i++)
            addressToAmountBidded[bidderAddresses[i]] = 0; //Reset the Dictionary
        bidderAddresses = new address[](0); //Reset the array of Bidders

        pendingWinner = address(0);
        pendingPaymentAmnt = 0;
        base_price = 0;
        auction_end_time = 0;
        pending_sale = false;
    }

    function revert_to_owner() public onlyOwner {
        require(block.timestamp >= auction_end_time + 2 days || no_one_bidded);

        //Need To Reset the Dictionary and Array of bidders
        for (uint256 i = 0; i < bidderAddresses.length; i++)
            addressToAmountBidded[bidderAddresses[i]] = 0; //Reset the Dictionary
        bidderAddresses = new address[](0); //Reset the array of Bidders

        pendingWinner = address(0);
        pendingPaymentAmnt = 0;

        no_one_bidded = false;
        pending_sale = false;
        auction_end_time = 0;
        base_price = 0;
    }
}