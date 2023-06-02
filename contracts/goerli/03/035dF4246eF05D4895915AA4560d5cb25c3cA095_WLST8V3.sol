// SPDX-License-Identifier: MIT

/*
==== WLST8V3 TOKENOMICS ====

Total supply: 1,000,000
Presale: 300,000
Team: 200,000
Liquidity pool: 500,000

==== CONTRACT FUNCTIONS ==== 

1. Airdrop (pre-saler tokens distribution)
2. Blacklist (anti-bots)
3. Holdinglimit (whale prevention)
*/

pragma solidity ^0.8.0;

import { ERC20 } from "./2.ERC20.sol";
import { Ownable } from "./3.Ownable.sol";

// ==== Contract definition ====
contract WLST8V3 is Ownable, ERC20 {
    // ==== Variables declaration ====
    address public uniswapContractAddress;
    uint256 public tradingStartTime;

    // ===== Whale prevention-related variables
    bool public holdLimitState = false;
    uint256 public holdLimitAmount;

    // ===== BL & WL variables
    mapping(address => bool) public blacklisted;

    // ==== Emit events declaration ====
    event Blacklisted(address indexed _address);
    event UnBlacklisted(address indexed _address);

    // ==== Constructor definition (Sets total supply & tax wallet address ====
    constructor(uint256 _totalSupply) ERC20("WLST8V3", "WLST8V3") {
        _mint(msg.sender, _totalSupply);
    }

    // ==== Token airdrop function ====
    function airdropTokens(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Mismatched input arrays");

        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(owner(), recipients[i], amounts[i]);
        }
    }

    // ==== Set holding limit ====
    function setHoldLimit(bool _holdLimitState, uint256 _holdLimitAmount) external onlyOwner {
        holdLimitState = _holdLimitState;
        holdLimitAmount = _holdLimitAmount;
    }

    // ==== BL function ====
    function blacklist(address[] calldata _address, bool _isBlacklisted) external onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            blacklisted[_address[i]] = _isBlacklisted;
            if (_isBlacklisted) {
                emit Blacklisted(_address[i]);
            } else {
                emit UnBlacklisted(_address[i]);
            }
        }
    }

    // ==== Set Uniswap V3 Pool address ====
    function setUniswapContractAddress(address _uniswapContractAddress) external onlyOwner {
        require(uniswapContractAddress == address(0), "Uniswap contract address already set");
        uniswapContractAddress = _uniswapContractAddress;
        tradingStartTime = block.timestamp;
    }

    // ==== Checks before token transfer happens ====
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // ==== Check if wallet is blacklisted ====
        require(!blacklisted[to] && !blacklisted[from], "Wallet is blacklisted");

        // ==== Check if trading started ====
        if (uniswapContractAddress == address(0) && from != address(0)) {
            require(from == owner(), "Trading yet to begin");
            return;
        }

        // ==== Check if successful buy transaction will exceed holding limit ====
        if (holdLimitState && from == uniswapContractAddress) {
            require(super.balanceOf(to) + amount <= holdLimitAmount, "Exceeds allowable holding limit per wallet");
        }
    }
}