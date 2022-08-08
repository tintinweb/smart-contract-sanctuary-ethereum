/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

/**
 *Submitted for verification at BscScan.com on 2022-07-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

abstract contract Receiver {
    function onReceiveSMT(address, uint256) public virtual;
}

contract SMT {
    uint256 constant FUNDS_FACTOR = 1e18;
    uint256 constant SHARE_FACTOR = 1e18;
    uint256 constant MINIMUM_DEPOSIT = 0.0001 ether;
    uint256 constant BUY_FEE = 10;
    uint256 constant SELL_FEE = 5;
    uint256 constant REFERRAL_FEE = 33;

    address public owner = msg.sender;
    uint256 public totalSupply;
    uint256 public totalShare;
    mapping(address => uint256) public tokensOf;
    mapping(address => uint256) public dividendsOf;
    mapping(address => uint256) public shareOf;
    mapping(address => address) public referralOf;

    event Record(address holder, address referral, uint256 funds, bool isPurchased);

    function buySMT(address referral) public payable {
        _setReferral(msg.sender, referral);
        _buySMT(msg.sender, msg.value);
    }

    function sellSMT(uint256 tokens) public {
        _sellSMT(msg.sender, tokens);
    }

    function transferSMT(address to, uint256 tokens) public {
        _transferSMT(msg.sender, to, tokens);
    }

    function withdrawDividends() public {
        _withdrawDividends(msg.sender);
    }

    function reinvestDividends() public {
        _reinvestDividends(msg.sender);
    }

    function _buySMT(address buyer, uint256 amount) internal {
        require(amount >= MINIMUM_DEPOSIT, "the amount is less than the minimum deposit");
        _claimDividends(buyer);
        uint256 feeFunds = (amount * BUY_FEE) / 100;
        uint256 funds = amount - feeFunds;
        uint256 tokens = _fundsToTokens(totalSupply, funds);
        totalSupply += tokens;
        tokensOf[buyer] += tokens;
        _distributeDividends(buyer, feeFunds);
        address referral = referralOf[buyer];
        emit Record(buyer, referral, amount, true);
    }

    function _sellSMT(address seller, uint256 tokens) internal {
        require(tokens > 0, "tokens must be more than zero");
        uint256 funds = _tokensToFunds(totalSupply, tokens);
        uint256 feeFunds = (funds * SELL_FEE) / 100;
        funds -= feeFunds;
        _distributeDividends(seller, feeFunds);
        _claimDividends(seller);
        totalSupply -= tokens;
        tokensOf[seller] -= tokens;
        address referral = referralOf[seller];
        emit Record(seller, referral, funds + feeFunds, false);
        payable(seller).transfer(funds);
    }

    function _transferSMT(
        address from,
        address to,
        uint256 tokens
    ) internal {
        require(tokens > 0, "tokens must be more than zero");
        require(from != to, "you cannot transfer tokens to yourself");
        require(referralOf[to] != address(0), "account is not initialized");
        _claimDividends(from);
        _claimDividends(to);
        tokensOf[from] -= tokens;
        tokensOf[to] += tokens;
        if (to.code.length > 0) {
            Receiver(to).onReceiveSMT(from, tokens);
        }
    }

    function _claimDividends(address claimer) internal {
        uint256 share = totalShare - shareOf[claimer];
        if (share > 0) {
            uint256 dividends = (share * tokensOf[claimer]) / SHARE_FACTOR;
            dividendsOf[claimer] += dividends;
            shareOf[claimer] = totalShare;
        }
    }

    function _withdrawDividends(address receiver) internal {
        _claimDividends(receiver);
        uint256 dividends = dividendsOf[receiver];
        dividendsOf[receiver] = 0;
        payable(receiver).transfer(dividends);
    }

    function _reinvestDividends(address holder) internal {
        _claimDividends(holder);
        uint256 dividends = dividendsOf[holder];
        dividendsOf[holder] = 0;
        _buySMT(holder, dividends);
    }

    function _distributeDividends(address distributor, uint256 funds) internal {
        uint256 shareFunds = (funds * (100 - REFERRAL_FEE)) / 100;
        totalShare += (shareFunds * SHARE_FACTOR) / totalSupply;
        address referral = referralOf[distributor];
        dividendsOf[referral] += funds - shareFunds;
    }

    function _setReferral(address member, address referral) internal {
        if (referralOf[member] == address(0)) {
            referralOf[member] = referralOf[referral] == address(0) ? owner : referral;
        }
    }

    function _tokensToFunds(uint256 totalTokens, uint256 burnTokens) internal pure returns (uint256) {
        uint256 n1 = totalTokens;
        uint256 n2 = totalTokens - burnTokens;
        uint256 S1 = ((n1 + 1) * n1) / 2;
        uint256 S2 = ((n2 + 1) * n2) / 2;
        return (S1 - S2) / FUNDS_FACTOR;
    }

    function _fundsToTokens(uint256 totalTokens, uint256 addedFunds) internal pure returns (uint256) {
        uint256 a = totalTokens + 1;
        uint256 S = addedFunds * FUNDS_FACTOR;
        return (_sqrt((2 * a - 1)**2 + 8 * S) - 2 * a + 1) / 2;
    }

    function _sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}