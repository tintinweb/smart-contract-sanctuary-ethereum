// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC20.sol";
import "./Address.sol";
import "./Strings.sol";

contract LFCoin is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 100_000_000_000 ether;
    uint256 public constant BURN_SUPPLY = 50_000_000_000 ether;
    uint256 public constant MARKET_SUPPLY = 5_000_000_000 ether;

    address public constant BLACKHOLE = 0x000000000000000000000000000000000000dEaD;
    address public constant MARKET_ADDRESS = 0xa0b56C99865F7B09eA334A077402b1cc9a0Ae54C;

    constructor() ERC20("LFCoin", "LF") {
        _mint(BLACKHOLE,BURN_SUPPLY);
        _mint(MARKET_ADDRESS,MARKET_SUPPLY);
        _mint(msg.sender,MAX_SUPPLY-BURN_SUPPLY-MARKET_SUPPLY);
    }
    
}