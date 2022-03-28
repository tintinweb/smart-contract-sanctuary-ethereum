/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

/*

 /$$   /$$           /$$ /$$                 /$$$$$$$$                              
| $$  /$$/          |__/| $$                | $$_____/                              
| $$ /$$/   /$$$$$$  /$$| $$$$$$$   /$$$$$$ | $$        /$$$$$$   /$$$$$$  /$$$$$$$ 
| $$$$$/   |____  $$| $$| $$__  $$ |____  $$| $$$$$    |____  $$ /$$__  $$| $$__  $$
| $$  $$    /$$$$$$$| $$| $$  \ $$  /$$$$$$$| $$__/     /$$$$$$$| $$  \__/| $$  \ $$
| $$\  $$  /$$__  $$| $$| $$  | $$ /$$__  $$| $$       /$$__  $$| $$      | $$  | $$
| $$ \  $$|  $$$$$$$| $$| $$$$$$$/|  $$$$$$$| $$$$$$$$|  $$$$$$$| $$      | $$  | $$
|__/  \__/ \_______/|__/|_______/  \_______/|________/ \_______/|__/      |__/  |__/
                                                                                                                                                                    
                                                                            
               .-'''''-.
             .'         `.
            :             :
           :               :
           :      _/|      :
            :   =/_/      :
             `._/ |     .'
          (   /  ,|...-'
           \_/^\/||__
        _/~  `""~`"` \_
     __/  -'/  `-._ `\_\__
   /     /-'`  `\   \  \-.\

*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

interface ERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface ERC20RewardToken is ERC20 {
    function mint_rewards(uint256 qty, address receiver) external;

    function burn_tokens(uint256 qty, address burned) external;
}

contract protected {
    mapping(address => bool) is_auth;

    function is_it_auth(address addy) public view returns (bool) {
        return is_auth[addy];
    }

    function set_is_auth(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }

    modifier onlyAuth() {
        require(is_auth[msg.sender] || msg.sender == owner, "not owner");
        _;
    }

    address owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }
}

contract KaibaEarn is protected {
    string public name = "Kaiba Earn";

    // create 2 state variables
    address public Kaiba = 0xaCA834418F815587d205Fc01CA2cA8a0bCEC1227;
    address public Fang = 0x71C5e6E1b9De8D25a1E8347386b1fF9343dEBB2c;

    uint256 public year = 2252571;
    uint256 public day = 1 days;
    uint256 public week = 7 days;
    uint256 public month = 30 days;

    constructor() {
        owner = msg.sender;
        is_auth[owner] = true;
        name = "Kaiba Earn";
    }

    ////////////////////////////////
    ///////// Struct Stuff /////////
    ////////////////////////////////

    struct STAKE {
        bool active;
        address token_staked;
        address token_reward;
        uint256 quantity;
        uint256 start_time;
        uint256 last_retrieved;
        uint256 total_earned;
        uint256 total_withdraw;
        uint256 unlock_time;
        uint256 time_period;
    }

    struct STAKER {
        mapping(uint256 => STAKE) stake;
        uint256 last_id;
    }

    mapping(address => STAKER) staker;

    struct STAKABLE {
        bool enabled;
        bool is_mintable;
        uint256 unlocked_rewards;
        address token_reward;
        mapping(uint256 => bool) allowed_rewards;
        mapping(uint256 => uint256) timed_rewards;
        mapping(address => uint256) pools;
        uint256 balance;
    }

    mapping(address => STAKABLE) stakable;

    ////////////////////////////////
    ////////// View Stuff //////////
    ////////////////////////////////

    function get_stakable_token(address token)
        public
        view
        returns (
            bool enabled,
            uint256 unlocked,
            uint256 amount_in
        )
    {
        if (!stakable[token].enabled) {
            return (false, 0, 0);
        } else {
            return (
                true,
                stakable[token].unlocked_rewards,
                stakable[token].balance
            );
        }
    }

    function get_single_pool(address actor, uint256 pool)
        public
        view
        returns (
            uint256 quantity,
            uint256 unlock_block,
            uint256 start_block
        )
    {
        require(staker[actor].stake[pool].active, "Inactive");

        return (
            staker[actor].stake[pool].quantity,
            staker[actor].stake[pool].unlock_time,
            staker[actor].stake[pool].start_time
        );
    }

    function get_reward_on_pool(address actor, uint256 pool)
        public
        view
        returns (uint256 reward)
    {
        require(staker[actor].stake[pool].active, "Inactive");
        require(
            staker[actor].stake[pool].unlock_time < block.timestamp,
            "Locked"
        );
        uint256 local_pool_amount = staker[actor].stake[pool].quantity;
        uint256 local_time_period = staker[actor].stake[pool].time_period;
        address local_token_staked = staker[actor].stake[pool].token_staked;
        uint256 local_time_passed = block.timestamp -
            staker[actor].stake[pool].start_time;
        uint256 local_total_pool = stakable[local_token_staked].balance;
        uint256 local_reward_timed;
        if (
            !(stakable[local_token_staked].timed_rewards[local_time_period] ==
                0)
        ) {
            local_reward_timed = stakable[local_token_staked].timed_rewards[
                local_time_period
            ];
        } else {
            local_reward_timed = stakable[local_token_staked].unlocked_rewards;
        }
        /// @notice Multiplying the staked quantity with the part on an year staked time;
        ///         Dividng this for the total of the pool.
        ///         AKA: staked * (reward_in_a_year * part_of_time_on_a_year) / total_pool;
        uint256 local_reward = ((local_pool_amount *
            ((local_reward_timed * ((local_time_passed * 1000000) / year)))) /
            1000000000) / local_total_pool;
        /// @notice Exclude already withdrawn tokens
        uint256 local_reward_adjusted = local_reward -
            staker[msg.sender].stake[pool].total_withdraw;
        return local_reward_adjusted;
    }

    ////////////////////////////////
    ///////// Write Stuff //////////
    ////////////////////////////////

    function stake_token(
        address token,
        uint256 amount,
        uint256 timelock
    ) public safe {
        ERC20 erc_token = ERC20(token);
        require(
            erc_token.allowance(msg.sender, address(this)) >= amount,
            "Allowance"
        );
        require(stakable[token].enabled, "Not stakable");
        erc_token.transferFrom(msg.sender, address(this), amount);
        uint256 pool_id = staker[msg.sender].last_id;
        staker[msg.sender].last_id += 1;
        staker[msg.sender].stake[pool_id].active = true;
        staker[msg.sender].stake[pool_id].quantity = amount;
        staker[msg.sender].stake[pool_id].token_staked = token;
        staker[msg.sender].stake[pool_id].token_reward = stakable[token]
            .token_reward;
        staker[msg.sender].stake[pool_id].start_time = block.timestamp;
        staker[msg.sender].stake[pool_id].unlock_time =
            block.timestamp +
            timelock;
        staker[msg.sender].stake[pool_id].time_period = timelock;
    }

    function withdraw_earnings(uint256 pool) public safe {
        address actor = msg.sender;
        address local_token_staked = staker[actor].stake[pool].token_staked;
        address local_token_rewarded = staker[actor].stake[pool].token_reward;
        uint256 rewards = get_reward_on_pool(actor, pool);

        /// @notice Differentiate minting and not minting rewards
        if (stakable[local_token_staked].is_mintable) {
            ERC20RewardToken local_erc_rewarded = ERC20RewardToken(
                local_token_rewarded
            );
            local_erc_rewarded.mint_rewards(rewards, msg.sender);
        } else {
            ERC20 local_erc_rewarded = ERC20(local_token_rewarded);
            require(local_erc_rewarded.balanceOf(address(this)) >= rewards);
            local_erc_rewarded.transfer(msg.sender, rewards);
        }
        /// @notice Update those variables that control the status of the stake
        staker[msg.sender].stake[pool].total_earned += rewards;
        staker[msg.sender].stake[pool].total_withdraw += rewards;
        staker[msg.sender].stake[pool].last_retrieved = block.timestamp;
    }

    function unstake(uint256 pool) public safe {
        withdraw_earnings(pool);
        ERC20 token = ERC20(staker[msg.sender].stake[pool].token_staked);
        token.transfer(msg.sender, staker[msg.sender].stake[pool].quantity);
        /// @notice Set to zero and disable pool
        staker[msg.sender].stake[pool].quantity = 0;
        staker[msg.sender].stake[pool].active = false;
    }

    ////////////////////////////////
    ////////// Admin Stuff /////////
    ////////////////////////////////

    function ADMIN_set_auth(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }

    function ADMIN_set_token_state(address token, bool _stakable)
        public
        onlyAuth
    {
        stakable[token].enabled = _stakable;
    }

    function ADMIN_configure_token_stake(
        address token,
        bool _stakable,
        bool mintable,
        uint256 unlocked_reward,
        address token_given,
        uint256[] calldata times_allowed,
        uint256[] calldata times_reward
    ) public onlyAuth {
        require(stakable[token].enabled);
        stakable[token].enabled = _stakable;
        stakable[token].is_mintable = mintable;
        stakable[token].unlocked_rewards = unlocked_reward;
        stakable[token].token_reward = token_given;

        /// @notice If specified, assign a different reward value for locked stakings
        if (times_allowed.length > 0) {
            require(
                times_allowed.length == times_reward.length,
                "Set a reward per time"
            );
            for (uint256 i; i < times_allowed.length; i++) {
                stakable[token].allowed_rewards[times_allowed[i]] = true;
                stakable[token].timed_rewards[times_allowed[i]] = times_reward[
                    i
                ];
            }
        }
    }

    ////////////////////////////////
    ///////// Fallbacks ////////////
    ////////////////////////////////

    receive() external payable {}

    fallback() external payable {}
}