// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/security/Pausable.sol";
//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RockstarApesCoin is ERC20, Pausable, Ownable, ReentrancyGuard{

    uint256 public maxSupply;
    uint256 public pricePerToken;

    constructor() ERC20("RockstarApesCoin", "ROCK"){
        maxSupply = 77000000;
    }

    function pause() public onlyOwner{
        _pause();
    }

    function unpause() public onlyOwner{
        _unpause();
    }


    function mintToken(address account, uint256 amount) public whenNotPaused returns(bool){
        if(totalSupply() + amount <= maxSupply){
            _mint(account, amount);
            return true;    
        }
        return false;
    }

    function sellToken(uint256 amount) public whenNotPaused nonReentrant{
        calculatePrice();
        _burn(_msgSender(), amount);
        require(balanceOf(_msgSender()) >= amount);
        payable(_msgSender()).transfer(pricePerToken * amount);
    }

    function buyToken(uint256 amount) public payable whenNotPaused nonReentrant{
        calculatePrice();
        require(msg.value >= (pricePerToken * amount), "Need more ethereum");
        mintToken(_msgSender(), amount);
    }

    function calculatePrice() internal{
        pricePerToken = address(this).balance / totalSupply();
    }

    function spendToken(uint256 amount) public whenNotPaused{
        _burn(_msgSender(), amount);
    }
}