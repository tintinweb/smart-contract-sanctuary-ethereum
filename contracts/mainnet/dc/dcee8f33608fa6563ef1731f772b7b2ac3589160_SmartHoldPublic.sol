/**
 *Submitted for verification at Etherscan.io on 2023-02-01
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
    mapping(address => DepositData) public depositsData;
    mapping(address => bool) public configuredDeposits;
    address[] public depositsAddresses;

    struct DepositData {
        uint256 lockForDays;
        uint256 createdAt;
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
        require(!configuredDeposits[msg.sender], ERRALREADYCONFIGURED);
        require(_minExpectedPrice >= 0, "Invalid minExpectedPrice value.");
        require(_lockForDays < 10000, "Too long lockup period!");

        depositsAddresses.push(msg.sender);

        DepositData memory newLock = DepositData({
            lockForDays: _lockForDays,
            createdAt: block.timestamp,
            minExpectedPrice: _minExpectedPrice,
            balance: msg.value
        });

        configuredDeposits[msg.sender] = true;
        depositsData[msg.sender] = newLock;
    }

    function deposit() external payable {
        require(configuredDeposits[msg.sender], ERRNOTCONFIGURED);
        DepositData storage depositData = depositsData[msg.sender];
        depositData.balance = depositData.balance + msg.value;
    }

    function getLockForDays(address _account) public view returns (uint256) {
        require(configuredDeposits[_account], ERRNOTCONFIGURED);
        DepositData memory depositData = depositsData[_account];
        return depositData.lockForDays;
    }

    function getCreatedAt(address _account) public view returns (uint256) {
        require(configuredDeposits[_account], ERRNOTCONFIGURED);
        DepositData memory depositData = depositsData[_account];
        return depositData.createdAt;
    }

    function getMinExpectedPrice(
        address _account
    ) public view returns (int256) {
        require(configuredDeposits[_account], ERRNOTCONFIGURED);
        DepositData memory depositData = depositsData[_account];
        return depositData.minExpectedPrice;
    }

    function getBalance(address _account) public view returns (uint256) {
        require(configuredDeposits[_account], ERRNOTCONFIGURED);
        DepositData memory depositData = depositsData[_account];
        return depositData.balance;
    }

    function canWithdraw(address _account) public view returns (bool) {
        require(configuredDeposits[_account], ERRNOTCONFIGURED);
        DepositData memory depositData = depositsData[_account];

        uint256 releaseAt = depositData.createdAt +
            (depositData.lockForDays * 1 days);

        if (releaseAt < block.timestamp) {
            return true;
        } else if (depositData.minExpectedPrice == 0) {
            return false;
        } else if (depositData.minExpectedPrice < getETHPrice()) {
            return true;
        } else return false;
    }

    function withdraw() external {
        require(configuredDeposits[msg.sender], ERRNOTCONFIGURED);
        require(canWithdraw(msg.sender), "You cannot withdraw yet!");
        DepositData storage depositData = depositsData[msg.sender];

        uint256 balance = depositData.balance;
        depositData.balance = 0;

        payable(msg.sender).transfer(balance);
    }

    function getETHPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price / 10e7;
    }

    function increaseLockForDays(uint256 _newLockForDays) external {
        require(configuredDeposits[msg.sender], ERRNOTCONFIGURED);
        require(_newLockForDays < 10000, "Too long lockup period!");

        DepositData storage depositData = depositsData[msg.sender];

        require(
            depositData.lockForDays < _newLockForDays,
            "New lockForDays value invalid!"
        );
        depositData.lockForDays = _newLockForDays;
    }

    function increaseMinExpectedPrice(int256 _newMinExpectedPrice) external {
        require(configuredDeposits[msg.sender], ERRNOTCONFIGURED);
        DepositData storage depositData = depositsData[msg.sender];

        require(
            depositData.minExpectedPrice != 0,
            "minExpectedPrice not configured!"
        );

        require(
            depositData.minExpectedPrice < _newMinExpectedPrice,
            "New value invalid!"
        );
        depositData.minExpectedPrice = _newMinExpectedPrice;
    }

    function getConfiguredDeposits() external view returns (address[] memory) {
        return depositsAddresses;
    }
}