/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface PriceFeedInterface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

pragma solidity 0.8.17;

contract SmartHoldPublic {
    PriceFeedInterface internal priceFeed;
    mapping(address => LockData) public locksData;
    mapping(address => bool) public configuredLocks;

    struct LockData {
        uint256 lockForDays;
        uint256 depositedAt;
        int256 minExpectedPrice;
        uint256 balance;
    }

    string private constant ERRNOTCONFIGURED = "Address not configured.";
    string private constant ERRALREADYCONFIGURED =
        "Address already configured.";

    constructor(address _priceFeed) {
        priceFeed = PriceFeedInterface(_priceFeed);
    }

    function configureDeposit(
        uint256 _lockForDays,
        int256 _minExpectedPrice
    ) external payable {
        require(!configuredLocks[msg.sender], ERRALREADYCONFIGURED);
        require(_minExpectedPrice >= 0, "Invalid minExpectedPrice value.");
        require(_lockForDays < 10000, "Too long lockup period!");

        LockData memory newLock = LockData({
            lockForDays: _lockForDays,
            depositedAt: block.timestamp,
            minExpectedPrice: _minExpectedPrice,
            balance: msg.value
        });

        configuredLocks[msg.sender] = true;
        locksData[msg.sender] = newLock;
    }

    function deposit() external payable {
        require(configuredLocks[msg.sender], ERRNOTCONFIGURED);
        LockData storage lockData = locksData[msg.sender];
        lockData.balance = lockData.balance + msg.value;
    }

    function getLockForDays(address _account) public view returns (uint256) {
        require(configuredLocks[_account], ERRNOTCONFIGURED);
        LockData memory lockData = locksData[_account];
        return lockData.lockForDays;
    }

    function getDepositedAt(address _account) public view returns (uint256) {
        require(configuredLocks[_account], ERRNOTCONFIGURED);
        LockData memory lockData = locksData[_account];
        return lockData.depositedAt;
    }

    function getMinExpectedPrice(
        address _account
    ) public view returns (int256) {
        require(configuredLocks[_account], ERRNOTCONFIGURED);
        LockData memory lockData = locksData[_account];
        return lockData.minExpectedPrice;
    }

    function getBalance(address _account) public view returns (uint256) {
        require(configuredLocks[_account], ERRNOTCONFIGURED);
        LockData memory lockData = locksData[_account];
        return lockData.balance;
    }

    function canWithdraw(address _account) public view returns (bool) {
        require(configuredLocks[_account], ERRNOTCONFIGURED);
        LockData memory lockData = locksData[_account];

        uint256 releaseAt = lockData.depositedAt +
            (lockData.lockForDays * 1 days);

        if (releaseAt < block.timestamp) {
            return true;
        } else if (lockData.minExpectedPrice == 0) {
            return false;
        } else if (lockData.minExpectedPrice < getETHPrice()) {
            return true;
        } else return false;
    }

    function withdraw() external {
        require(configuredLocks[msg.sender], ERRNOTCONFIGURED);
        require(canWithdraw(msg.sender), "You cannot withdraw yet!");
        LockData storage lockData = locksData[msg.sender];

        uint256 balance = lockData.balance;
        lockData.balance = 0;

        payable(msg.sender).transfer(balance);
    }

    function getETHPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price / 10e7;
    }

    function increaseLockForDays(uint256 _newLockForDays) external {
        require(configuredLocks[msg.sender], ERRNOTCONFIGURED);
        require(_newLockForDays < 10000, "Too long lockup period!");

        LockData storage lockData = locksData[msg.sender];

        require(
            lockData.lockForDays < _newLockForDays,
            "New lockForDays value invalid!"
        );
        lockData.lockForDays = _newLockForDays;
    }

    function increaseMinExpectedPrice(int256 _newMinExpectedPrice) external {
        require(configuredLocks[msg.sender], ERRNOTCONFIGURED);
        LockData storage lockData = locksData[msg.sender];

        require(
            lockData.minExpectedPrice < _newMinExpectedPrice,
            "New lockForDays value invalid!"
        );
        lockData.minExpectedPrice = _newMinExpectedPrice;
    }
}