/**
 *Submitted for verification at Etherscan.io on 2022-10-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract BooRewards {

    IERC20 public immutable poolToken;

    address public owner;

    address[] participants_addresses;
    uint[] participants_stakes;

    uint min_stake = 1000000 * 10**18;
    uint max_stake = 30000000000 * 10**18;

    bool is_in_progress = false;
    address lottery_winner = address(0);
    bool is_allowed_to_claim = false;
    uint amount_to_claim = 0;
    uint last_stake_time = 0;
    bool has_claimed = false;

    uint lottery_end_time = 0;

    uint amount_in_pool = 0;

    constructor(address poolToken_) {
        owner = msg.sender;
        poolToken = IERC20(poolToken_);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner can call this method");
        _;
    }

    function accountExists(address account_) internal view returns (uint) {
        for (uint i = 0; i < participants_addresses.length; i++) {
            if (participants_addresses[i] == account_) {
                return i + 1;
            }
        }
        return 0;
    }

    function adjustMinStake(uint value_) external onlyOwner {
        min_stake = value_;
    }

    function adjustMaxStake(uint value_) external onlyOwner {
        max_stake = value_;
    }

    function clearStakes() internal onlyOwner {
        address[] memory addresses_;
        uint[] memory stakes_;
        participants_stakes = stakes_;
        participants_addresses = addresses_;
    }

    function startLottery() external onlyOwner {
        require(is_in_progress == false, "Lottery already in progress");
        lottery_end_time = block.timestamp + 1800;
        is_in_progress = true;
        has_claimed = false;
        clearStakes();
        is_allowed_to_claim = false;
        amount_to_claim = 0;
    }

    function stopLottery(uint index_) external onlyOwner {
        require(is_in_progress == true, "Lottery not in progress");
        poolToken.transfer(owner, (20 * amount_in_pool) / 100);
        is_in_progress = false;
        lottery_winner = participants_addresses[index_];
        amount_to_claim = (70 * amount_in_pool) / 100;
        is_allowed_to_claim = true;
        amount_in_pool = (10 * amount_in_pool) / 100;
        lottery_end_time = block.timestamp;
    }

    function stakeTokens(uint amount_) public virtual returns (bool) {
        
        require(amount_ > 0, "Amount must be greater than 0");
        require(is_in_progress == true, "Lottery not in progress");
        require(lottery_end_time >= block.timestamp, "Lottery time exceeded");
        if (last_stake_time > 0) {
            require(((block.timestamp - last_stake_time) <= 1800), "The Ghost has dominated the pot");
        }
        uint exists = accountExists(msg.sender);

        uint stakes = 0;

        if (exists > 0) {
            stakes = participants_stakes[exists - 1];
        }
        else {
            stakes = 0;
        }

        uint final_stake = stakes + amount_;

        require(final_stake >= min_stake, "Stake amount less than min allowed stake");
        require(final_stake <= max_stake, "Stake amount greater than max allowed stake");

        poolToken.transferFrom(msg.sender, address(this), amount_);

        if (exists > 0) {
            participants_stakes[exists - 1] += amount_;
        }
        else {
            participants_stakes.push(amount_);
            participants_addresses.push(msg.sender);
        }

        amount_in_pool += amount_;
        last_stake_time = block.timestamp;

        return true;

    }

    function participantsAddresses() public view returns (address[] memory) {
        return participants_addresses;
    }

    function participantsStakes() public view returns (uint[] memory) {
        return participants_stakes;
    }
    
    function isInProgress() public view returns (bool) {
        return is_in_progress;
    }

    function amountInPool() public view returns (uint) {
        return amount_in_pool;
    }

    function amountToClaim() public view returns (uint) {
        return amount_to_claim;
    }

    function stakeAmount(address account_) public view returns (uint) {
        uint exists = accountExists(account_);
        if (exists == 0) {
            return 0;
        }
        else {
            return participants_stakes[exists - 1];
        }
    }

    function lastStakeTime() public view returns (uint) {
        return last_stake_time;
    }

    function claimStatus() public view returns (bool) {
        if (is_allowed_to_claim == true) {
            return false;
        }
        else {
            return true;
        }
    }

    function lotteryWinner() public view returns (address) {
        return lottery_winner;
    }

    function lotteryEndTime() public view returns (uint) {
        return lottery_end_time;
    }

    function GhostStatus() public view returns (bool) {
        if (((block.timestamp - last_stake_time) >= 1800) && last_stake_time > 0) {
            return true;
        }
        else {
            return false;
        }
    }

    function claimTokens() public virtual returns (bool) {
        
        require(is_allowed_to_claim == true, "Not allowed to claim");
        require(lottery_winner == msg.sender, "Not allowed to claim");

        poolToken.transfer(msg.sender, amount_to_claim);

        is_allowed_to_claim = false;
        has_claimed = true;

        return true;

    }
}

interface IERC20 {

    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
}