// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// hh

error Bond_NotEnoughETHEntered();
error Bond_NotOwner();
error Bond__RefundFailed();
error Bond_MonthNotPassed();
error Bond_NotFound();
error Bond_CommissionFailed();
error Bond_HasNoCoins();
error Bond_ExchangeCoinsToEtherError();

contract Bond {
    address payable public immutable s_owner;
    uint256 private s_bondCounter;
    uint256 private s_coinsCounter;
    mapping(address => uint256) private s_usersBonds;
    mapping(address => uint256) public s_usersCoins;
    uint256 public constant PARTICIPATION_AMOUT = 0.001 ether;
    uint256 public constant MONTH = 60 * 60 * 24 * 30;
    mapping(address => uint256) public s_last_user_reward;

    event BuyBond(address indexed participant, uint256 eth);
    event RequestReward(address indexed participant, uint256 userCoins);
    event ChangeCoinsToEth(
        address indexed participant,
        uint256 userCoins,
        uint256 eth
    );
    event ChangeBondToCoins(
        address indexed participant,
        uint256 userCoins,
        uint256 userBonds
    );

    constructor() {
        s_owner = payable(msg.sender);
    }

    modifier isOwner() {
        if (msg.sender != s_owner) {
            revert Bond_NotOwner();
        }
        _;
    }

    function buyBond() public payable {
        if (msg.value < PARTICIPATION_AMOUT) {
            revert Bond_NotEnoughETHEntered();
        }

        if (msg.value > PARTICIPATION_AMOUT) {
            (bool success, ) = msg.sender.call{
                value: msg.value - PARTICIPATION_AMOUT
            }("");
            if (!success) {
                revert Bond__RefundFailed();
            }
        }

        (bool successCommission, ) = s_owner.call{
            value: ((PARTICIPATION_AMOUT * 6) / 100)
        }("");

        if (!successCommission) {
            revert Bond_CommissionFailed();
        }
        uint userBonds = s_usersBonds[msg.sender];

        // TODO два раза исползую
        if (userBonds > 0) {
            uint256 userCoins = getNotRequestedCoins();
            s_usersCoins[msg.sender] += userCoins;
            s_coinsCounter += userCoins;
        }

        s_usersBonds[msg.sender] += 1;
        s_last_user_reward[msg.sender] = block.timestamp;
        s_bondCounter++;
        emit BuyBond(msg.sender, PARTICIPATION_AMOUT);
    }

    function requestReward() external {
        uint256 userBonds = s_usersBonds[msg.sender];
        if (userBonds < 1) {
            revert Bond_NotFound();
        }

        if (block.timestamp < (s_last_user_reward[msg.sender] + MONTH)) {
            revert Bond_MonthNotPassed();
        }

        uint256 userCoins = getNotRequestedCoins();
        s_usersCoins[msg.sender] += userCoins;
        s_coinsCounter += userCoins;
        s_last_user_reward[msg.sender] = block.timestamp;
        emit RequestReward(msg.sender, userCoins);
    }

    function getNotRequestedCoins() public view returns (uint256) {
        uint256 userBonds = s_usersBonds[msg.sender];

        return (((block.timestamp - s_last_user_reward[msg.sender]) /
            60 /
            60 /
            24) * userBonds);
    }

    function changeCoinsToEth() external {
        uint256 userCoins = s_usersCoins[msg.sender];
        if (userCoins < 1) {
            revert Bond_HasNoCoins();
        }
        uint256 exchangerate = exchangeCoinsToEthRate();
        uint256 eth = exchangerate * userCoins;
        (bool success, ) = msg.sender.call{value: eth}("");

        if (!success) {
            revert Bond_ExchangeCoinsToEtherError();
        }
        s_usersCoins[msg.sender] = 0;
        s_coinsCounter -= userCoins;
        emit ChangeCoinsToEth(msg.sender, userCoins, eth);
    }

    function changeBondsToCoins() external {
        uint256 userBonds = s_usersBonds[msg.sender];
        if (userBonds < 1) {
            revert Bond_NotFound();
        }
        uint256 coins = userBonds * 30;
        s_usersCoins[msg.sender] += coins;
        s_usersBonds[msg.sender] = 0;
        s_bondCounter -= userBonds;
        s_coinsCounter += coins;
        emit ChangeBondToCoins(msg.sender, coins, userBonds);
    }

    function getExchangeCoinsToEthRate(
        uint256 contractBalance,
        uint256 bondCounter,
        uint256 coinsCounter
    ) public pure returns (uint256) {
        return contractBalance / ((bondCounter * 30) + coinsCounter);
    }

    function exchangeCoinsToEthRate() public view returns (uint256) {
        return
            getExchangeCoinsToEthRate(
                address(this).balance,
                s_bondCounter,
                s_coinsCounter
            );
    }

    function getUserBonds(address participant) public view returns (uint256) {
        return s_usersBonds[participant];
    }

    function getUserCoins(address participant) public view returns (uint256) {
        return s_usersCoins[participant];
    }

    function getBondCounter() external view isOwner returns (uint256) {
        return s_bondCounter;
    }

    function getCoinsCounter() external view isOwner returns (uint256) {
        return s_coinsCounter;
    }

    function get_last_user_reward(
        address participant
    ) external view returns (uint256) {
        return s_last_user_reward[participant];
    }

    function getContractBalance() external view isOwner returns (uint256) {
        return address(this).balance;
    }

    function entranceFee() external pure returns (uint256) {
        return PARTICIPATION_AMOUT;
    }
}