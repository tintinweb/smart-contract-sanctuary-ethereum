/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

//SPDX-License-Identifier: OSL-3.0
pragma solidity ^0.8.0;

library SafeMath{
  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }
}

contract Primary{
    address primary;
    address crawler;

    constructor(address crawlerAddress){
        primary = msg.sender;
        crawler = crawlerAddress;
    }

    function primarypermission() public view returns(bool){
        require(tx.origin == primary);
        return true;
    }

    function crawlerpermission() external view returns(bool){
        require(tx.origin == crawler);
        return true;
    }

    function updateprimary(address _primary) external{
        require(_primary != address(0));
        require(primarypermission() == true,'only primary owner');
        primary = _primary;
    }
}

contract Crawler{
    /*
    *    eth\~$ Get ebook over Onion network
    * 1. post title, author, year, publisher
    * 2. deposit 0.0002 ether to Crawler contract
    * 3. crawler find ebook over Onion network and notify on channel
    * 4. complete your deposit and pay 0.0015 ether
    * 5. crawler releases the Onion file to you
    */

    using SafeMath for *;

    uint256 pre = 0.0002 ether;
    uint256 paid = 0.0015 ether;
    uint256 balance;

    Primary public primary;

    //@dev prepaid
    mapping(address => uint) prepaid;
    mapping(address => bool) do_prepaid;
    mapping(address => bool) alreadyfind;

    //@dev postpaid
    mapping(address => uint) postpaid;
    mapping(address => bool) do_postpaid;
    mapping(address => bool) release;

    //@dev Crawler events
    event Predeposit(uint timestamp, address indexed customer);
    event Fulldeposit(uint timestamp, address indexed customer);
    event Queue(uint timestamp, address indexed customer);
    event Notify(uint timestamp, address indexed customer);

    constructor(address primaryAddress){
        primary = Primary(primaryAddress);
    }

    struct ebook{
        string email;
        string title;
        string author;
        string year;
        string publisher;
    }

    ebook[] public book;

    /* verify the crawler address */
    function OnlyCrawler() internal view returns(bool status){
        if(primary.crawlerpermission()) return true;
        else return false;
    }
    
    function predeposit(string memory Email,string memory Title, string memory Author, string memory Year, string memory Publisher)
    external payable{
        require(msg.value == pre,'send me 0.0002 ether');
        prepaid[msg.sender] = prepaid[msg.sender].add(msg.value);
        do_prepaid[msg.sender] = true;
        balance = balance.add(msg.value);
        book.push(ebook({email: Email, title: Title, author: Author, year: Year, publisher:Publisher}));
        emit Queue(block.timestamp, msg.sender);
        emit Predeposit(block.timestamp, msg.sender);
    }

    function get() external view returns(ebook[] memory){
        require(OnlyCrawler() == true,'only crawler');
        return book;
    }

    function notify(address customer) external{
        require(OnlyCrawler() == true,'only crawler');
        require(do_prepaid[customer] == true);
        alreadyfind[customer] = true;
        emit Notify(block.timestamp, customer);
    }

    function fulldeposit() external payable{
        require(do_prepaid[msg.sender] == true,'no predeposit');
        require(msg.value == paid,'send me 0.0015 ether');
        require(alreadyfind[msg.sender] == true,'crawler has been not found yet');
        postpaid[msg.sender] = postpaid[msg.sender].add(msg.value);
        do_postpaid[msg.sender] = true;
        balance = balance.add(msg.value);
        release[msg.sender] = true;
        reset_actions();
        emit Fulldeposit(block.timestamp, msg.sender);
    }

    function resetRelease(address customer) external{
        require(OnlyCrawler() == true,'only crawler');
        release[customer] = false;
    }

    function reset_actions() internal{
        prepaid[msg.sender]  = 0 ether; postpaid[msg.sender] = 0 ether;
        do_prepaid[msg.sender]  = false; do_postpaid[msg.sender] = false;
        alreadyfind[msg.sender] = false;
    }

    /*
    * @dev: white space
    */

    function withdraw(uint amount) external{
        require(OnlyOwner() == true,'only primary owner');
        require(amount <= address(this).balance,'amount is higher than balance');
        balance = balance.sub(amount);
        require(payable(msg.sender).send(amount), "failed to send Ether");
    }

    /* verify the owner address */
    function OnlyOwner() internal view returns(bool status){
        if(primary.primarypermission()) return true;
        else return false;
    }
}