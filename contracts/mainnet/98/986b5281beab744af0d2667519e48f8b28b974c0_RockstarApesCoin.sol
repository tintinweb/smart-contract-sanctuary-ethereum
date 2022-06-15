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

    address nftAddress = 0x3d899e0Ce7Ce47888d86595b5f7254eFB53fa4db;
    address stakingAddress = 0xc5884BD00Ea49F22174CdeB0d911c5be9dd5E88c; //must change

    constructor() ERC20("RockstarApesCoin", "ROCK"){
        maxSupply = 770000000 * (10**decimals());

        mintToken(nftAddress, 6042729);
        mintToken(stakingAddress, 250000000);
        mintToken(owner(), 513957271);
    }

    function pause() public onlyOwner{
        _pause();
    }

    function unpause() public onlyOwner{
        _unpause();
    }


    function mintToken(address account, uint256 amount) public whenNotPaused onlyOwner{
        uint256 realAmount = amount * (10**decimals());
        require(totalSupply() + realAmount <= maxSupply);
        _mint(account, realAmount);
    }

    function spendToken(uint256 amount) public whenNotPaused{
        uint256 realAmount = amount * (10**decimals());
        _burn(_msgSender(), realAmount);
    }
}