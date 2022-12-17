// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
error Bond_RefundFailed();
error Bond_CommissionFailed();
error Bond_ExchangeCoinsToEtherError();
error Bond_HasNoCoins();
error Bond_MonthNotPassed();
error Bond_NotEnoughETHEntered();
error Bond_NotFound();
error Bond_NotOwner();

contract Bond {
    address payable public immutable s_owner;
    mapping(address => uint256) private s_usersBonds;
    mapping(address => uint256) public s_last_user_reward;
    mapping(address => uint256) public s_usersCoins;
    uint256 private s_bondCounter;
    uint256 private s_coinsCounter;
    uint256 public immutable i_participation_amount;
    uint256 public immutable i_reward_interval;
    uint256 public immutable i_reward_time_unit;
    uint256 public immutable i_bonds_to_coins_exchange_rate;

    event BuyBond(address indexed participant, uint256 eth);
    event ChangeBondToCoins(
        address indexed participant,
        uint256 userCoins,
        uint256 userBonds
    );
    event ChangeCoinsToEth(
        address indexed participant,
        uint256 userCoins,
        uint256 eth
    );
    event RequestReward(address indexed participant, uint256 userCoins);

    constructor(
        uint256 participation_amount,
        uint256 reward_interval,
        uint256 reward_time_unit,
        uint256 bonds_to_coins_exchange_rate
    ) {
        s_owner = payable(msg.sender);
        i_participation_amount = participation_amount;
        i_reward_interval = reward_interval;
        i_reward_time_unit = reward_time_unit;
        i_bonds_to_coins_exchange_rate = bonds_to_coins_exchange_rate;
    }

    modifier isOwner() {
        if (msg.sender != s_owner) {
            revert Bond_NotOwner();
        }
        _;
    }

    function buyBond() public payable {
        if (msg.value < i_participation_amount) {
            revert Bond_NotEnoughETHEntered();
        }

        if (msg.value > i_participation_amount) {
            (bool success, ) = msg.sender.call{
                value: msg.value - i_participation_amount
            }("");
            if (!success) {
                revert Bond_RefundFailed();
            }
        }

        (bool successCommission, ) = s_owner.call{
            value: ((i_participation_amount * 6) / 100)
        }("");

        if (!successCommission) {
            revert Bond_CommissionFailed();
        }
        uint userBonds = s_usersBonds[msg.sender];

        if (userBonds > 0) {
            mintUserCoinsFromRequest();
        }

        s_usersBonds[msg.sender] += 1;
        s_last_user_reward[msg.sender] = block.timestamp;
        s_bondCounter++;
        emit BuyBond(msg.sender, i_participation_amount);
    }

    function requestReward() external {
        uint256 userBonds = s_usersBonds[msg.sender];
        if (userBonds < 1) {
            revert Bond_NotFound();
        }

        if (
            block.timestamp <
            (s_last_user_reward[msg.sender] +
                (i_reward_time_unit * i_reward_interval))
        ) {
            revert Bond_MonthNotPassed();
        }

        uint256 userCoins = mintUserCoinsFromRequest();

        s_last_user_reward[msg.sender] = block.timestamp;
        emit RequestReward(msg.sender, userCoins);
    }

    function getNotRequestedCoins() public view returns (uint256) {
        uint256 userBonds = s_usersBonds[msg.sender];

        return (((block.timestamp - s_last_user_reward[msg.sender]) /
            i_reward_time_unit) * userBonds);
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
        uint256 coins = userBonds * i_bonds_to_coins_exchange_rate;
        s_usersCoins[msg.sender] += coins;
        s_usersBonds[msg.sender] = 0;
        s_bondCounter -= userBonds;
        s_coinsCounter += coins;
        emit ChangeBondToCoins(msg.sender, coins, userBonds);
    }

    function getExchangeCoinsToEthRate(
        uint256 contractBalance,
        uint256 bondCounter,
        uint256 coinsCounter,
        uint256 bondsToCoinsExchangeRate
    ) public pure returns (uint256) {
        return
            contractBalance /
            ((bondCounter * bondsToCoinsExchangeRate) + coinsCounter);
    }

    function exchangeCoinsToEthRate() public view returns (uint256) {
        return
            getExchangeCoinsToEthRate(
                address(this).balance,
                s_bondCounter,
                s_coinsCounter,
                i_bonds_to_coins_exchange_rate
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

    function getLastUserReward(
        address participant
    ) external view returns (uint256) {
        return s_last_user_reward[participant];
    }

    function getContractBalance() external view isOwner returns (uint256) {
        return address(this).balance;
    }

    function entranceFee() external view returns (uint256) {
        return i_participation_amount;
    }

    function mintUserCoinsFromRequest() public returns (uint256) {
        uint256 userCoins = getNotRequestedCoins();
        s_usersCoins[msg.sender] += userCoins;
        s_coinsCounter += userCoins;
        return userCoins;
    }
}