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

contract HighHorseCoin is ERC20, Pausable, Ownable, ReentrancyGuard{

    uint256 public maxSupply;

    address stakingAddress;

    constructor() ERC20("Horse Coin", "HORS"){
        maxSupply = 1000000 * (10**decimals());
        mintToken(owner(), 400000);
    }

    modifier onlyParent(){
        require(_msgSender() == stakingAddress || _msgSender() == owner(), "caller is not owner/contract");
        _;
    }

    function pause() public onlyOwner{
        _pause();
    }

    function unpause() public onlyOwner{
        _unpause();
    }


    function mintToken(address account, uint256 amount) public whenNotPaused onlyParent{
        uint256 realAmount = amount * (10**decimals());
        require(totalSupply() + realAmount <= maxSupply);
        _mint(account, realAmount);
    }

    function spendToken(uint256 amount) public whenNotPaused{
        uint256 realAmount = amount * (10**decimals());
        _burn(_msgSender(), realAmount);
    }

    function SetContract(address addy) public onlyOwner{
        stakingAddress = addy;
    }
}