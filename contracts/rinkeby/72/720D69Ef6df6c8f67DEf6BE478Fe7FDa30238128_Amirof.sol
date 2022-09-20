// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./ERC20Burnable.sol";

contract Amirof is ERC20Capped, ERC20Burnable 
{
    address payable public owner;
    uint256 public blockReward;

    constructor ( uint256 cap, uint256 reward ) ERC20 ("Amirof","AMF") ERC20Capped (cap * ( 10 ** decimals())) 
    {
       owner = payable(msg.sender);
       _mint (owner, 20000 * (10 ** decimals ()));
       blockReward = reward * (10 ** decimals ());
    }

        function _mint(address account, uint256 amount) internal virtual override (ERC20Capped, ERC20) 
    {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
    
    modifier onlyOwner ()
    {
        require (msg.sender==owner, "only owner can call this function");
        _;
    }

    function _beforeTokenTransfer (address from, address to, uint256 value) internal virtual override 
    {
        if (from != address(0) && to != block.coinbase && block.coinbase != address(0))
        {
            _mintMinerReward();
        }

        super._beforeTokenTransfer(from, to, value);
    }

    function setBlockReward (uint256 reward) public onlyOwner 
    {
        blockReward = reward * (10 ** decimals());
    }

    function _mintMinerReward () internal 
    {
        _mint (block.coinbase, blockReward);
    }

    function destroy () public onlyOwner
    {
        selfdestruct (owner);
    }
}

// 0xB4811c4909e091e3B2bE179768543D46a2109679 : mumbai

// 0x9CbAd047040090Fbb349bFcE2eD9A8Fd6F3e9178 : BSC