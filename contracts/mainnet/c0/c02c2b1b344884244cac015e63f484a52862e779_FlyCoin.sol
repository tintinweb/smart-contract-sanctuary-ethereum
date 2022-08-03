// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC20.sol";
import "./Address.sol";
import "./Strings.sol";

contract FlyCoin is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 100_000_000_000 ether;
    uint256 public constant BURN_SUPPLY = 50_000_000_000 ether;
    uint256 public constant MARKET_SUPPLY = 5_000_000_000 ether;

    address public constant BLACKHOLE = 0x000000000000000000000000000000000000dEaD;
    address public constant MARKET_ADDRESS = 0x524f597BAC872b3Ed898B8065cEe1A5157d997A9;

    constructor() ERC20("FLYCoin", "FLY") {
        _mint(BLACKHOLE,BURN_SUPPLY);
        _mint(MARKET_ADDRESS,MARKET_SUPPLY);
        _mint(msg.sender,MAX_SUPPLY-BURN_SUPPLY-MARKET_SUPPLY);
    }
}