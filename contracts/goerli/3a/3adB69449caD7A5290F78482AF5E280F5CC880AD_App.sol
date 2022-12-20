// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.11;

// Author: @rapelista
contract App {
    Auction[] public auctions;

    function open_auction (
        string memory _item_name,
        string memory _description,
        string memory _img_url,
        uint _price_init
    ) public {
        Auction new_auction = new Auction(_item_name, _description, _img_url, _price_init, payable(msg.sender));
        auctions.push(new_auction);
    }

    function get_auctions() public view returns(Auction[] memory) {
        return auctions;
    }
}

// Author: @rapelista
contract Auction {
    string public item_name;
    string public description;
    string public img_url;
    uint public price_init;
    address payable public owner;
    bool public is_active;

    uint public price_highest;
    address payable public bidder_highest;
    mapping(address => uint) public bids;

    constructor(
        string memory _item_name,
        string memory _description,
        string memory _img_url,
        uint _price_init,
        address payable _owner
    ) {
        item_name = _item_name;
        description = _description;
        img_url = _img_url;
        price_init = _price_init;
        price_highest = _price_init;
        bidder_highest = _owner;
        owner = _owner;
        is_active = true;
    }

    function set_bid() public payable returns(bool) {
        require(is_active == true);
        require(msg.sender != owner);
        require(msg.value > 0);

        uint current_bid = msg.value;
        require(current_bid > price_highest);

        bids[msg.sender] = current_bid;

        address payable temp_bidder = bidder_highest;
        uint temp_price = price_highest;

        price_highest = current_bid;
        bidder_highest = payable(msg.sender);     

        temp_bidder.transfer(temp_price);   

        return true;
    }

    function finish() public payable {
        require(msg.sender == owner);
        
        owner.transfer(address(this).balance);
        is_active = false;
    }

    function get_data() public view returns(
        string memory,
        string memory,
        uint,
        bool,
        address,
        string memory,
        uint
    ) {
        return (
            item_name,
            description,
            price_init,
            is_active,
            owner,
            img_url,
            price_highest
        );
    }
}