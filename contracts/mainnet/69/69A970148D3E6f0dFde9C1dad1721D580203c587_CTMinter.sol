/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// SPDX-License-Identifier: MIXED
pragma solidity ^0.8.17;
contract CryptoTajines {
    uint256 public totalSupply;
    function safeMint(address to, string memory uri) public {}
}

contract CTMinter  {
   
    CryptoTajines ct;
    address public owner;
    uint256 public currentStage = 1000;//changable
    uint256 public price = 0.07 ether;//changable
    uint256 public dateOpen = 1677628800;//1st march by default
    bool public locked = true;//changable
    bool public whitelistLocked = true;//changable
    address payable private k001 = payable(0x001b6Ac6BF05E1c042817a502d445A57C5387590);//important get it back

    mapping(address => uint16) public whitelist;//should be private?
    mapping(address => bool) public blacklist;

    event WhitelistedAddressAdded(address addr, uint16 amount);
    event WhitelistedAddressRemoved(address addr);

     constructor(address _t) {
        ct = CryptoTajines(_t);
        owner = msg.sender;
    }

    modifier costs(uint _amount){
        if(whitelist[msg.sender] <= 0){
            require(msg.value >= _amount,'Not enough to buy, oh no!');
        }
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function changeStage(uint256 _stage) public onlyOwner{
        currentStage = _stage;
    }

    function changeOpenDate(uint256 date) public onlyOwner{
        dateOpen = date;
    }

    function changePrice(uint256 _price) public onlyOwner{
        price = _price;
    }
    
    function changeLock(bool _locked) public onlyOwner{
        locked = _locked;
    }

    function changeWhitelistLock(bool _locked) public onlyOwner{
        whitelistLocked = _locked;
    }
 
    function mint(address to, string memory uri) public  payable costs(price) onlyWhitelisted noBlacklist{
        require(currentStage > ct.totalSupply(), "Current Stage is sold out!");
        require(!locked, "Mint is locked");
        require(block.timestamp > dateOpen, "Opening date not yet reached!");
        if(whitelist[msg.sender] > 0)
        {
            whitelist[msg.sender]--;
        }
        ct.safeMint(to,uri);
    }

    function isOpen() public view returns(bool) {
        return block.timestamp > dateOpen && !locked;
    }

    function getSupply() public view returns(uint) {
        return ct.totalSupply();
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdrawMoney() onlyOwner public {
        k001.transfer(getBalance());
    }

    function transfer() public onlyOwner {
        (bool success, ) = k001.call{value: getBalance()}("");
        require(success, "Failed to send Ether");
    }

    /**
    * @dev Throws if called by any account that's not whitelisted.
    */
    modifier onlyWhitelisted() {
        if(whitelistLocked && msg.sender != owner)
        {
            require(whitelist[msg.sender] > 0, "You need to be whitelisted");
        }
        _;
    }

    modifier noBlacklist() {
        require(!blacklist[msg.sender], "You are blacklisted!");
        _;
    }

    function addAddressToBlacklist(address addr) onlyOwner public returns(bool success) {
        if (!blacklist[addr]) {
            blacklist[addr] = true;
            return true;
        }
        return false;
    }

    function removeAddressFromBlacklist(address addr) onlyOwner public returns(bool) {
        if (blacklist[addr]) {
            blacklist[addr] = false;
            return true;
        }
        return false;
    }

    function addAddressToWhitelist(address addr, uint16 amount) onlyOwner public returns(bool) {
        // if (whitelist[addr] > 0) {
            whitelist[addr] = amount;
            emit WhitelistedAddressAdded(addr, amount);
            return true; 
        // }
        
        // return false;
    }


    // function addAddressesToWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
    //     for (uint256 i = 0; i < addrs.length; i++) {
    //         if (addAddressToWhitelist(addrs[i])) {
    //             success = true;
    //         }
    //     }
    // }


    // function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool) {
    //     if (whitelist[addr]) {
    //         whitelist[addr] = false;
    //         emit WhitelistedAddressRemoved(addr);
    //         return true;
    //     }
        
    //     return false;
    // }


    // function removeAddressesFromWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
    //     for (uint256 i = 0; i < addrs.length; i++) {
    //         if (removeAddressFromWhitelist(addrs[i])) {
    //             success = true;
    //         }
    //     }
    // }

    function isWhitelisted(address _whitelistedAddress) public view returns(uint16) {
        return whitelist[_whitelistedAddress];
    }

    function isBlacklisted(address _address) public view returns(bool) {
        return blacklist[_address];
    }

}