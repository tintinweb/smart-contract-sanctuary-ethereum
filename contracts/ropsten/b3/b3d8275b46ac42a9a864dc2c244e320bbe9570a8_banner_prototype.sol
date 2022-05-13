pragma solidity ^0.4.24;

contract banner_prototype {

    mapping(string => string) ads_titles;
    mapping(string => string) ads_urls;
    mapping(string => uint256) ads_prices;
    uint256 min_price = 0;
    
    constructor () public {
        // make some examples by default
        string memory key = 'test keyword';
        ads_titles[key] = 'Vitalik Buterin Wikipedia';
        ads_urls[key] = 'https://bit.ly/2B9CWK7';
        key = 'cat food';
        ads_titles[key] = 'Kitekat - best cat food';
        ads_urls[key] = 'http://kitekat.ru/';
    }
    
    function set_ad(string memory key, string title_, string url_) public payable {
        require(msg.value >= min_price);
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

}