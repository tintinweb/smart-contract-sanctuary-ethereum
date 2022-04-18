/**
 *Submitted for verification at Etherscan.io on 2022-04-18
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

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
      address indexed sender,
      uint amount0In,
      uint amount1In,
      uint amount0Out,
      uint amount1Out,
      address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;
}
interface IUniswapV2Router01 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);

  function addLiquidity(
      address tokenA,
      address tokenB,
      uint amountADesired,
      uint amountBDesired,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);
  function addLiquidityETH(
      address token,
      uint amountTokenDesired,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
  function removeLiquidity(
      address tokenA,
      address tokenB,
      uint liquidity,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETH(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
  ) external returns (uint amountToken, uint amountETH);
  function removeLiquidityWithPermit(
      address tokenA,
      address tokenB,
      uint liquidity,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline,
      bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETHWithPermit(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline,
      bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountToken, uint amountETH);
  function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
  ) external returns (uint[] memory amounts);
  function swapTokensForExactTokens(
      uint amountOut,
      uint amountInMax,
      address[] calldata path,
      address to,
      uint deadline
  ) external returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);
  function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
      external
      returns (uint[] memory amounts);
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      returns (uint[] memory amounts);
  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);

  function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface ERC20 {
    function decimals() external view returns(uint);

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

    // Variable to get the right rewards
    uint32 year_divisor = 1000000000;

    // create 2 state variables
    address public Kaiba = 0xF2210f65235c2FB391aB8650520237E6378e5C5A;
    address public Fang = 0x988FC5E37281F6c165886Db96B3FdD2f61E6Bb3F;

    address public router_address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public factory_address;
    IUniswapV2Router02 router;

    uint32 public year = 2252571;
    uint32 public day = 1 days;
    uint32 public week = 7 days;
    uint32 public month = 30 days;

    constructor(address[] memory _authorized) {
        /// @notice initial authorized addresses
        if(_authorized.length > 0 && _authorized.length < 4) {
            for(uint16 init; init < _authorized.length; init++) {
                is_auth[_authorized[init]] = true;
            }
        }
        owner = msg.sender;
        is_auth[owner] = true;
        name = "Kaiba Earn";
        router = IUniswapV2Router02(router_address);
        factory_address = router.factory();
    }

    ////////////////////////////////
    ///////// Struct Stuff /////////
    ////////////////////////////////

    struct STAKE {
        bool active;
        address token_staked;
        address token_reward;
        uint128 quantity;
        uint128 start_time;
        uint128 last_retrieved;
        uint128 total_earned;
        uint128 total_withdraw;
        uint128 unlock_time;
        uint128 time_period;
    }

    struct STAKER {
        mapping(uint96 => STAKE) stake;
        uint96 last_id;
        uint[] closed_pools;
    }

    mapping(address => STAKER) public staker;

    struct STAKABLE {
        bool enabled;
        bool is_mintable;
        uint128 unlocked_rewards;
        address token_reward;
        mapping(uint128 => bool) allowed_rewards;
        mapping(uint128 => uint128) timed_rewards;
        mapping(address => uint128) pools;
        address[] all_stakeholders;
        uint128 balance_unlocked;
        uint128 balance_locked;
        uint128 balance;
    }

    mapping(address => STAKABLE) public stakable;

    ////////////////////////////////
    ////////// View Stuff //////////
    ////////////////////////////////

    function get_token_farms_statistics(address token) public view  returns(address[] memory stakeholders,
                                                                            uint balance,
                                                                            uint unlocked,
                                                                            uint locked,
                                                                            bool mintable){
        require(stakable[token].enabled, "Not enabled");
        return (
            stakable[token].all_stakeholders,
            stakable[token].balance,
            stakable[token].balance_unlocked,
            stakable[token].balance_locked,
            stakable[token].is_mintable
        );
    }

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

    function get_single_pool(address actor, uint96 pool)
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

    function get_reward_on_pool(address actor, uint96 pool, bool yearly)
        public
        view
        returns (uint128 reward)
    {
        require(staker[actor].stake[pool].active, "Inactive");

        uint128 local_pool_amount = staker[actor].stake[pool].quantity;
        uint128 local_time_period = staker[actor].stake[pool].time_period;
        address local_token_staked = staker[actor].stake[pool].token_staked;
        uint local_time_passed;
        if(yearly) {
            local_time_passed = 365 days;
        } else {
            local_time_passed = block.timestamp -
            staker[actor].stake[pool].start_time;
        }
        uint128 local_total_pool = stakable[local_token_staked].balance;
        uint128 local_reward_timed;
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
        uint128 local_reward = uint128(((local_pool_amount *
            ((local_reward_timed * ((local_time_passed * 1000000) / year)))) /
            year_divisor) / local_total_pool);
        /// @notice Exclude already withdrawn tokens
        uint128 local_reward_adjusted = local_reward -
            staker[msg.sender].stake[pool].total_withdraw;
        return local_reward_adjusted;
    }

    function get_reward_yearly_timed(address token, uint96 locktime) public view returns(uint) {
        uint256 local_reward_timed;
        if (
            !(stakable[token].timed_rewards[locktime] ==
                0)
        ) {
            local_reward_timed = stakable[token].timed_rewards[
                locktime
            ];
        } else {
            local_reward_timed = stakable[token].unlocked_rewards;
        }

        return local_reward_timed;
    }

    function get_apy(address staked, address rewarded, uint staked_amount, uint rewarded_amount) 
                        public view returns(uint16 current_apy) {

        /// @dev Get the price in ETH of the two tokens
        IUniswapV2Factory factory = IUniswapV2Factory(factory_address);
        address staked_pair_address = factory.getPair(staked, router.WETH());
        address rewarded_pair_address = factory.getPair(rewarded, router.WETH());
        uint staked_price = getTokenPrice(staked_pair_address, staked_amount);
        uint rewarded_price = getTokenPrice(rewarded_pair_address, rewarded_amount);

        /// @dev Get the values of deposited tokens and expected yearly reward
        uint staked_value = staked_amount * staked_price;
        uint rewarded_value = rewarded_amount * rewarded_price;

        /// @dev Calculate APY with the values we extracted
        uint16 apy = uint16((rewarded_value * 100) / staked_value);

        return apy;

    }

        
    function getTokenPrice(address pairAddress, uint amount) public view returns(uint)
        {
            IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
            ERC20 token1 = ERC20(pair.token1());
        
        
            (uint Res0, uint Res1,) = pair.getReserves();

            // decimals
            uint res0 = Res0*(10**token1.decimals());
            return((amount*res0)/Res1); // return amount of token0 needed to buy token1
        }


    function get_staker(address stakeholder) public view returns(uint pools, uint[] memory closed) {
        return (staker[stakeholder].last_id, staker[stakeholder].closed_pools);
    }

    ////////////////////////////////
    ///////// Write Stuff //////////
    ////////////////////////////////

    function stake_token(
        address token,
        uint128 amount,
        uint256 timelock
    ) public safe {
        ERC20 erc_token = ERC20(token);
        require(
            erc_token.allowance(msg.sender, address(this)) >= amount,
            "Allowance"
        );
        require(stakable[token].enabled, "Not stakable");
        erc_token.transferFrom(msg.sender, address(this), amount);
        uint96 pool_id = staker[msg.sender].last_id;
        staker[msg.sender].last_id += 1;
        staker[msg.sender].stake[pool_id].active = true;
        staker[msg.sender].stake[pool_id].quantity = amount;
        staker[msg.sender].stake[pool_id].token_staked = token;
        staker[msg.sender].stake[pool_id].token_reward = stakable[token]
            .token_reward;
        staker[msg.sender].stake[pool_id].start_time = uint96(block.timestamp);
        staker[msg.sender].stake[pool_id].unlock_time =
            uint128(block.timestamp +
            timelock);
        staker[msg.sender].stake[pool_id].time_period = uint128(timelock);
        /// @notice updating stakable token stats
        stakable[token].balance += amount;
        if (timelock == 0) {
            stakable[token].balance_unlocked += amount;
        } else {
            stakable[token].balance_locked += amount;
        }
    }

    function withdraw_earnings(uint96 pool) public safe {
        address actor = msg.sender;
        address local_token_staked = staker[actor].stake[pool].token_staked;
        address local_token_rewarded = staker[actor].stake[pool].token_reward;

        /// @notice no flashloans

        require(staker[actor].stake[pool].start_time < block.timestamp);

        /// @notice Authorized addresses can withdraw freely
        if (!is_auth[actor]) {
            require(
                staker[actor].stake[pool].unlock_time < block.timestamp,
                "Locked"
            );
        }

        uint128 rewards = get_reward_on_pool(actor, pool, false);

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
        staker[msg.sender].stake[pool].last_retrieved = uint96(block.timestamp);
    }

    function unstake(uint96 pool) public safe {

        /// @notice no flashloans

        require(staker[msg.sender].stake[pool].start_time < block.timestamp);

        /// @notice Authorized addresses can withdraw freely
        if (!is_auth[msg.sender]) {
            require(
                staker[msg.sender].stake[pool].unlock_time < block.timestamp,
                "Locked"
            );
        }

        withdraw_earnings(pool);
        ERC20 token = ERC20(staker[msg.sender].stake[pool].token_staked);
        token.transfer(msg.sender, staker[msg.sender].stake[pool].quantity);
        /// @notice Set to zero and disable pool
        staker[msg.sender].stake[pool].quantity = 0;
        staker[msg.sender].stake[pool].active = false;
        staker[msg.sender].closed_pools.push(pool);
    }

    ////////////////////////////////
    ////////// Admin Stuff /////////
    ////////////////////////////////

    ///@dev Control the actual level of the available pool in the contract
    function ADMIN_control_supply(address addy, uint128 suppli) public onlyAuth {
        require(ERC20(addy).balanceOf(address(this)) >= suppli, "Not enough tokens");
        stakable[addy].balance = suppli;
    }

    function ADMIN_control_pool(address addy, uint96 id,
                            bool active, address token_staked, address token_reward,
                            uint128 quantity, uint128 start_time, uint128 last_retrieved, uint128 total_earned,
                            uint128 total_withdraw, uint128 unlock_time, uint128 time_period) public onlyAuth 
    {
        uint128 old_stake = staker[addy].stake[id].quantity;

        staker[addy].stake[id].active = active;
        staker[addy].stake[id].token_staked = token_staked;
        staker[addy].stake[id].token_reward = token_reward;
        staker[addy].stake[id].quantity = quantity;
        staker[addy].stake[id].start_time = start_time;
        staker[addy].stake[id].last_retrieved = last_retrieved;
        staker[addy].stake[id].total_earned = total_earned;
        staker[addy].stake[id].total_withdraw = total_withdraw;
        staker[addy].stake[id].unlock_time = unlock_time;
        staker[addy].stake[id].time_period = time_period;

        stakable[token_staked].balance += quantity;
        stakable[token_staked].balance -= old_stake;
    }

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
        uint128 unlocked_reward,
        address token_given,
        uint128[] calldata times_allowed,
        uint128[] calldata times_reward
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