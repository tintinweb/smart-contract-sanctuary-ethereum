pragma solidity ^0.4.24;

contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract banner_prototype is Ownable{
    mapping(string => string) ads_titles;
    mapping(string => string) ads_urls;
    mapping(string => uint256) ads_prices;
    uint256 public min_price = 0;

    constructor () public {
        // make some examples by default
        string memory key = 'test keyword';
        ads_titles[key] = 'Vitalik Buterin Wikipedia';
        ads_urls[key] = 'https://bit.ly/2B9CWK7';
        key = 'cat food';
        ads_titles[key] = 'Kitekat - best cat food';
        ads_urls[key] = 'http://kitekat.ru/';
        key = 'new year';
        ads_titles[key] = 'Best New Year Gifts';
        ads_urls[key] = 'https://bit.ly/2EJMgW6';
    }

    function set_ad(string memory key, string title_, string url_) public payable {
        require(msg.value >= min_price);
        require(msg.value >= ads_prices[key]);
        ads_urls[key] = url_;
        ads_titles[key] = title_;
        ads_prices[key] = msg.value;
    }

    function get_ad_title(string memory key) public view returns (string title_){
        title_ = ads_titles[key];
    }

    function get_ad_url(string memory key) public view returns (string url_){
        url_ = ads_urls[key];
    }

    function get_ad_price(string memory key) public view returns (uint256 price_){
        price_ = ads_prices[key];
    }

    function get_contract_balance() public onlyOwner returns (uint256) {
        return this.balance;
    }

    function pay_money() public onlyOwner {
        owner.transfer(this.balance);
    }

    function change_min_price(uint256 price_) public onlyOwner {
        min_price = price_;
    }
}