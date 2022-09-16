/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/*

 /$$   /$$ /$$$$$$$$       /$$$$$$$$ /$$
| $$  / $$|_____ $$/      | $$_____/|__/
|  $$/ $$/     /$$/       | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$
 \  $$$$/     /$$/        | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$
  >$$  $$    /$$/         | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$
 /$$/\  $$  /$$/          | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/
| $$  \ $$ /$$/           | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$
|__/  |__/|__/            |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/

Contract: ERC-20 Token Time Lock

This contract will NOT be renounced.

The X7TokenTimeLock is a general purpose token time lock suitable for holding the Liquidity Provider tokens for all X7 ecosystem uniswap pairs.

There is a global unlock time and token specific unlock times. If a token is locked either by the global lock or the token specific lock, it will be locked.

Withdrawals should be orchestrated by contracts to enable trustless withdrawal in the event of an upgrade.

The following are the only functions that can be called on the contract that affect the contract:

    function setWETH(address weth_) external onlyOwner {
        weth = IWETH(weth_);
    }

    function setGlobalUnlockTimestamp(uint256 unlockTimestamp) external onlyOwner {
        require(unlockTimestamp > globalUnlockTimestamp);
        globalUnlockTimestamp = unlockTimestamp;
        emit GlobalUnlockTimestampSet(unlockTimestamp);
    }

    function extendGlobalUnlockTimestamp(uint256 extendSeconds) external onlyOwner {
        globalUnlockTimestamp += extendSeconds;
        emit GlobalUnlockTimeExtended(extendSeconds, globalUnlockTimestamp);
    }

    function setTokenUnlockTimestamp(address tokenAddress, uint256 unlockTimestamp) external onlyOwner {
        require(unlockTimestamp > tokenUnlockTimestamp[tokenAddress]);
        tokenUnlockTimestamp[tokenAddress] = unlockTimestamp;
        emit TokenUnlockTimestampSet(tokenAddress, unlockTimestamp);
    }

    function extendTokenUnlockTimestamp(address tokenAddress, uint256 extendSeconds) external onlyOwner {
        tokenUnlockTimestamp[tokenAddress] += extendSeconds;
        emit TokenUnlockTimeExtended(tokenAddress, extendSeconds, tokenUnlockTimestamp[tokenAddress]);
    }

    function setTokenOwner(address tokenAddress, address ownerAddress) external onlyOwner {
        require(tokenOwner[tokenAddress] != ownerAddress);
        address oldOwner = tokenOwner[tokenAddress];
        tokenOwner[tokenAddress] = ownerAddress;
        emit TokenOwnerSet(tokenAddress, oldOwner, ownerAddress);
    }

These functions will be passed to DAO governance once the ecosystem stabilizes.

*/

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract X7TokenTimeLock is Ownable {

    IWETH weth;

    // The timestamp after which tokens without their own unlock timestamp will unlock
    uint256 public globalUnlockTimestamp;

    // token => unlock timestamp
    mapping(address => uint256) public tokenUnlockTimestamp;

    // The token owner is the only identity permitted to withdraw tokens.
    // The contract owner may SET the token owner, but does not have any
    // ability to withdraw tokens.
    // token address => owner address
    mapping(address => address) public tokenOwner;

    event GlobalUnlockTimestampSet(uint256 unlockTimestamp);
    event GlobalUnlockTimeExtended(uint256 secondsExtended, uint256 newUnlockTimestamp);
    event TokenUnlockTimestampSet(address indexed tokenAddress, uint256 unlockTimestamp);
    event TokenUnlockTimeExtended(address indexed tokenAddress, uint256 secondsExtended, uint256 newUnlockTimestamp);
    event TokenOwnerSet(address indexed tokenAddress, address indexed oldTokenOwner, address indexed newTokenOwner);
    event TokensWithdrawn(address indexed tokenAddress, address indexed recipientAddress, uint256 amount);

    constructor(address weth_) Ownable(address(0x7000a09c425ABf5173FF458dF1370C25d1C58105)) {
        weth = IWETH(weth_);
    }

    receive () external payable {
        weth.deposit{value: msg.value}();
    }

    function setWETH(address weth_) external onlyOwner {
        weth = IWETH(weth_);
    }

    function setGlobalUnlockTimestamp(uint256 unlockTimestamp) external onlyOwner {
        require(unlockTimestamp > globalUnlockTimestamp);
        globalUnlockTimestamp = unlockTimestamp;
        emit GlobalUnlockTimestampSet(unlockTimestamp);
    }

    function extendGlobalUnlockTimestamp(uint256 extendSeconds) external onlyOwner {
        globalUnlockTimestamp += extendSeconds;
        emit GlobalUnlockTimeExtended(extendSeconds, globalUnlockTimestamp);
    }

    function setTokenUnlockTimestamp(address tokenAddress, uint256 unlockTimestamp) external onlyOwner {
        require(unlockTimestamp > tokenUnlockTimestamp[tokenAddress]);
        tokenUnlockTimestamp[tokenAddress] = unlockTimestamp;
        emit TokenUnlockTimestampSet(tokenAddress, unlockTimestamp);
    }

    function extendTokenUnlockTimestamp(address tokenAddress, uint256 extendSeconds) external onlyOwner {
        tokenUnlockTimestamp[tokenAddress] += extendSeconds;
        emit TokenUnlockTimeExtended(tokenAddress, extendSeconds, tokenUnlockTimestamp[tokenAddress]);
    }

    function setTokenOwner(address tokenAddress, address ownerAddress) external onlyOwner {
        require(tokenOwner[tokenAddress] != ownerAddress);
        address oldOwner = tokenOwner[tokenAddress];
        tokenOwner[tokenAddress] = ownerAddress;
        emit TokenOwnerSet(tokenAddress, oldOwner, ownerAddress);
    }

    function getTokenUnlockTimestamp(address tokenAddress) public view returns (uint256) {
        uint256 unlockTimestamp = tokenUnlockTimestamp[tokenAddress];

        if (globalUnlockTimestamp > unlockTimestamp) {
            return globalUnlockTimestamp;
        }

        return unlockTimestamp;
    }

    function withdrawTokens(address tokenAddress, uint256 amount) external {
        require(tokenOwner[tokenAddress] == msg.sender);
        require(block.timestamp >= getTokenUnlockTimestamp(tokenAddress));
        IERC20(tokenAddress).transfer(msg.sender, amount);
        emit TokensWithdrawn(tokenAddress, msg.sender, amount);
    }
}