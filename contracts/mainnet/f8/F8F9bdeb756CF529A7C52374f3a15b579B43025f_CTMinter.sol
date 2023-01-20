/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

// SPDX-License-Identifier: MIXED
pragma solidity ^0.8.17;
contract CryptoTajines {
    function safeMint(address to, string memory uri) public {}
}

contract CTMinter  {
   
    CryptoTajines ct;
    address public owner;
    uint16 public currentStage = 1;//changable
    uint160 public price = 0.01 ether;//changable
    bool public locked = true;//changable
    bool public whitelistLocked = true;//changable
    address payable private k001 = payable(0x001b6Ac6BF05E1c042817a502d445A57C5387590);//important get it back

    mapping(address => bool) public whitelist;
    mapping(address => bool) public blacklist;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

     constructor(address _t) {
        ct = CryptoTajines(_t);
        owner = msg.sender;
    }

    modifier costs(uint _amount){
        require(msg.value >= _amount,
        'Not enough to buy, oh no!');
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function changeStage(uint16 _stage) public onlyOwner{
        currentStage = _stage;
    }

    function changePrice(uint16 _price) public onlyOwner{
        price = _price;
    }
    
    function changeLock(bool _locked) public onlyOwner{
        locked = _locked;
    }

    function changeWhitelistLock(bool _locked) public onlyOwner{
        whitelistLocked = _locked;
    }
 
    function mint(address to, string memory uri) public  payable costs(price) onlyWhitelisted noBlacklist{
        require(!locked, "Mint is locked");
        ct.safeMint(to,uri);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdrawMoney() public {
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
            require(whitelist[msg.sender], "You need to be whitelisted");
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

    function addAddressToWhitelist(address addr) onlyOwner public returns(bool) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            return true; 
        }
        
        return false;
    }


    function addAddressesToWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
    }


    function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            return true;
        }
        
        return false;
    }


    function removeAddressesFromWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

    function isWhitelisted(address _whitelistedAddress) public view returns(bool) {
        return whitelist[_whitelistedAddress];
    }

    function isBlacklisted(address _address) public view returns(bool) {
        return blacklist[_address];
    }

}