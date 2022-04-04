// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/security/Pausable.sol";
//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RockstarApesCoin is ERC20, Pausable, Ownable, ReentrancyGuard{

    uint256 public maxSupply;
    uint256 public pricePerToken;

    constructor() ERC20("RockstarApesCoin", "ROCK"){
        maxSupply = 77000000 * 10^decimals();
    }

    function pause() public onlyOwner{
        _pause();
    }

    function unpause() public onlyOwner{
        _unpause();
    }


    function mintToken(address account, uint256 amount) public whenNotPaused returns(bool){
        uint256 realAmount = amount * 10^decimals();
        require(totalSupply() + realAmount <= maxSupply);
        _mint(account, realAmount);
        return false;
    }

    function sellToken(uint256 amount) public whenNotPaused nonReentrant{
        uint256 realAmount = amount * 10^decimals();
        calculatePrice();
        require(balanceOf(_msgSender()) >= realAmount);
        _burn(_msgSender(), realAmount);
        (bool sold, ) = payable(_msgSender()).call{value: (pricePerToken * realAmount)}("");
        require(sold, "Not enough ETH in the contract");
    }

    function buyToken(uint256 amount) public payable whenNotPaused nonReentrant{
        uint256 realAmount = amount * 10^decimals();
        calculatePrice();
        require(msg.value >= (pricePerToken * realAmount), "Need more ethereum");
        mintToken(_msgSender(), realAmount);
    }

    function calculatePrice() internal{
        pricePerToken = address(this).balance / totalSupply();
    }

    function spendToken(uint256 amount) public whenNotPaused{
        uint256 realAmount = amount * 10^decimals();
        _burn(_msgSender(), realAmount);
    }
}