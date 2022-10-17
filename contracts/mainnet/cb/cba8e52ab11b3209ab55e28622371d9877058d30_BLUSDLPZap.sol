/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

pragma solidity ^0.8.11;

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ICurvePool is IERC20 { 
    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external returns (uint256 mint_amount);

    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount, address _receiver) external returns (uint256 mint_amount);

    function remove_liquidity(uint256 burn_amount, uint256[2] memory _min_amounts) external;

    function remove_liquidity(uint256 burn_amount, uint256[2] memory _min_amounts, address _receiver) external;

    function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_received) external;

    function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_received, address _receiver) external;

    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver) external returns (uint256);

    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver) external returns (uint256);

    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);

    function calc_token_amount(uint256[2] memory _amounts, bool _is_deposit) external view returns (uint256);

    function balances(uint256 arg0) external view returns (uint256);

    function token() external view returns (address);

    function totalSupply() external view returns (uint256);

    function get_dy(int128 i,int128 j, uint256 dx) external view returns (uint256);

    function get_dy_underlying(int128 i,int128 j, uint256 dx) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function fee() external view returns (uint256);

    function D() external returns (uint256);

    function future_A_gamma_time() external returns (uint256);
}

// Not extending ICurvePool, because get_dy() and exchange() are incompatible
interface ICurveCryptoPool {
    function future_A_gamma_time() external returns (uint256);
    function token() external view returns (address);
    function balances(uint256 i) external view returns (uint256);
    function D() external returns (uint256);
    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256);
    function price_scale() external view returns (uint256);
    function lp_price() external view returns (uint256);
    function price_oracle() external view returns (uint256);
    function calc_token_amount(uint256[2] memory amounts) external view returns (uint256);
    function calc_withdraw_one_coin(uint256 token_amount, uint256 i) external view returns (uint256);

    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external returns (uint256);
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount, bool use_eth, address receiver) external returns (uint256 mint_amount);
    function remove_liquidity(uint256 burn_amount, uint256[2] memory min_amounts) external;
    function remove_liquidity(uint256 burn_amount, uint256[2] memory min_amounts, bool use_eth, address receiver) external;
    function remove_liquidity_one_coin(uint256 token_amount, uint256 i, uint256 min_amount, bool use_eth, address receiver) external;
}

interface ICurveLiquidityGaugeV5 is IERC20 {
    // Public state getters

    function reward_data(address _reward_token) external returns (
        address token,
        address distributor,
        uint256 period_finish,
        uint256 rate,
        uint256 last_update,
        uint256 integral
    );

    // User-facing functions

    function deposit(uint256 _value) external;
    function deposit(uint256 _value, address _addr) external;
    function deposit(uint256 _value, address _addr, bool _claim_rewards) external;

    function withdraw(uint256 _value) external;
    function withdraw(uint256 _value, bool _claim_rewards) external;

    function claim_rewards() external;
    function claim_rewards(address _addr) external;
    function claim_rewards(address _addr, address _receiver) external;

    function user_checkpoint(address addr) external returns (bool);
    function set_rewards_receiver(address _receiver) external;
    function kick(address addr) external;

    // Admin functions

    function deposit_reward_token(address _reward_token, uint256 _amount) external;
    function add_reward(address _reward_token, address _distributor) external;
    function set_reward_distributor(address _reward_token, address _distributor) external;
    function set_killed(bool _is_killed) external;

    // View methods

    function claimed_reward(address _addr, address _token) external view returns (uint256);
    function claimable_reward(address _user, address _reward_token) external view returns (uint256);
    function claimable_tokens(address addr) external view returns (uint256);

    function integrate_checkpoint() external view returns (uint256);
    function future_epoch_time() external view returns (uint256);
    function inflation_rate() external view returns (uint256);

    function factory() external view returns (address);

    function version() external view returns (string memory);
}

//import "forge-std/console.sol";

contract BLUSDLPZap {
    address constant LUSD_TOKEN_ADDRESS = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
    address constant BLUSD_TOKEN_ADDRESS = 0xB9D7DdDca9a4AC480991865EfEf82E01273F79C3;
    address constant LUSD_3CRV_POOL_ADDRESS = 0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA;
    address constant BLUSD_LUSD_3CRV_POOL_ADDRESS = 0x74ED5d42203806c8CDCf2F04Ca5F60DC777b901c;
    address constant BLUSD_LUSD_3CRV_LP_TOKEN_ADDRESS = 0x5ca0313D44551e32e0d7a298EC024321c4BC59B4;
    address constant BLUSD_LUSD_3CRV_GAUGE_ADDRESS= 0xdA0DD1798BE66E17d5aB1Dc476302b56689C2DB4;

    uint256 constant LUSD_3CRV_POOL_FEE_DENOMINATOR = 10 ** 10;

    IERC20 constant public lusdToken = IERC20(LUSD_TOKEN_ADDRESS);
    IERC20 constant public bLUSDToken = IERC20(BLUSD_TOKEN_ADDRESS);
    ICurvePool constant public lusd3CRVPool = ICurvePool(LUSD_3CRV_POOL_ADDRESS);
    ICurveCryptoPool constant public bLUSDLUSD3CRVPool = ICurveCryptoPool(BLUSD_LUSD_3CRV_POOL_ADDRESS);
    IERC20 constant public bLUSDLUSD3CRVLPToken = IERC20(BLUSD_LUSD_3CRV_LP_TOKEN_ADDRESS);
    ICurveLiquidityGaugeV5 constant public bLUSDGauge = ICurveLiquidityGaugeV5(BLUSD_LUSD_3CRV_GAUGE_ADDRESS);

    // TODO: add permit version
    function _addLiquidity(
        uint256 _bLUSDAmount,
        uint256 _lusdAmount,
        uint256 _minLPTokens,
        address _receiver
    )
        internal
        returns (uint256 bLUSDLUSD3CRVTokens)
    {
        require(_bLUSDAmount > 0 || _lusdAmount > 0, "BLUSDLPZap: Cannot provide zero liquidity");

        uint256 lusd3CRVAmount;
        if (_lusdAmount > 0) {
            lusdToken.transferFrom(msg.sender, address(this), _lusdAmount);

            // add LUSD single sided
            lusdToken.approve(address(lusd3CRVPool), _lusdAmount);
            lusd3CRVAmount = lusd3CRVPool.add_liquidity([_lusdAmount, 0], 0, address(this));
        }

        bLUSDToken.transferFrom(msg.sender, address(this), _bLUSDAmount);

        // add bLUSD/LUSD-3CRV
        bLUSDToken.approve(address(bLUSDLUSD3CRVPool), _bLUSDAmount);
        if (lusd3CRVAmount > 0) {
            lusd3CRVPool.approve(address(bLUSDLUSD3CRVPool), lusd3CRVAmount);
        }
        bLUSDLUSD3CRVTokens = bLUSDLUSD3CRVPool.add_liquidity([_bLUSDAmount, lusd3CRVAmount], _minLPTokens, false, _receiver);

        return bLUSDLUSD3CRVTokens;
    }

    function addLiquidity(uint256 _bLUSDAmount, uint256 _lusdAmount, uint256 _minLPTokens) external returns (uint256 bLUSDLUSD3CRVTokens) {
        // add liquidity
        bLUSDLUSD3CRVTokens = _addLiquidity(_bLUSDAmount, _lusdAmount, _minLPTokens, msg.sender);

        return bLUSDLUSD3CRVTokens;
    }

    function addLiquidityAndStake(
        uint256 _bLUSDAmount,
        uint256 _lusdAmount,
        uint256 _minLPTokens
    )
        external
        returns (uint256 bLUSDLUSD3CRVTokens)
    {
        // add liquidity
        bLUSDLUSD3CRVTokens = _addLiquidity(_bLUSDAmount, _lusdAmount, _minLPTokens, address(this));

        // approve LP tokens to Gauge
        bLUSDLUSD3CRVLPToken.approve(address(bLUSDGauge), bLUSDLUSD3CRVTokens);

        // stake into gauge
        bLUSDGauge.deposit(bLUSDLUSD3CRVTokens, msg.sender, false); // make sure rewards are not claimed

        return bLUSDLUSD3CRVTokens;
    }

    function getMinLPTokens(uint256 _bLUSDAmount, uint256 _lusdAmount) external view returns (uint256 bLUSDLUSD3CRVTokens) {
        uint256 lusd3CRVAmount;
        if (_lusdAmount > 0) {
            lusd3CRVAmount = lusd3CRVPool.calc_token_amount([_lusdAmount, 0], true);
            //Accounting for fees approximately
            lusd3CRVAmount -= lusd3CRVAmount * lusd3CRVPool.fee() / LUSD_3CRV_POOL_FEE_DENOMINATOR;
        }

        bLUSDLUSD3CRVTokens = bLUSDLUSD3CRVPool.calc_token_amount([_bLUSDAmount, lusd3CRVAmount]);

        return bLUSDLUSD3CRVTokens;
    }

    function removeLiquidityBalanced(uint256 _lpAmount, uint256 _minBLUSD, uint256 _minLUSD) external {
        // pull LP tokens
        bLUSDLUSD3CRVLPToken.transferFrom(msg.sender, address(this), _lpAmount);

        // All those balances should be zero, but just in case:
        uint256 initialLUSD3CRVBalance = lusd3CRVPool.balanceOf(address(this));
        uint256 initialBLUSDBalance = bLUSDToken.balanceOf(address(this));

        // withdraw bLUSD/LUSD-3CRV
        bLUSDLUSD3CRVPool.remove_liquidity(_lpAmount, [_minBLUSD, 0], false, address(this));
        uint256 bLUSDAmount = bLUSDToken.balanceOf(address(this)) - initialBLUSDBalance;
        uint256 lusd3CRVAmount = lusd3CRVPool.balanceOf(address(this)) - initialLUSD3CRVBalance;

        // withdraw LUSD from LUSD/3pool, and tranfer it to sender
        if (lusd3CRVAmount > 0) {
            lusd3CRVPool.remove_liquidity_one_coin(
                lusd3CRVAmount,
                0,
                _minLUSD,
                msg.sender
            );
        } else {
            require(_minLUSD == 0, "Min LUSD amount not reached");
        }

        // transfer BLUSD
        if (bLUSDAmount > 0) {
            bLUSDToken.transfer(msg.sender, bLUSDAmount);
        }
    }

    function removeLiquidityLUSD(uint256 _lpAmount, uint256 _minLUSD) external {
        // pull LP tokens
        bLUSDLUSD3CRVLPToken.transferFrom(msg.sender, address(this), _lpAmount);

        // All those balances should be zero, but just in case:
        uint256 initialLUSD3CRVBalance = lusd3CRVPool.balanceOf(address(this));

        // withdraw bLUSD/LUSD-3CRV
        bLUSDLUSD3CRVPool.remove_liquidity_one_coin(_lpAmount, 1, 0, false, address(this));

        // withdraw LUSD from LUSD/3pool, and tranfer it to sender
        lusd3CRVPool.remove_liquidity_one_coin(
            lusd3CRVPool.balanceOf(address(this)) - initialLUSD3CRVBalance,
            0,
            _minLUSD,
            msg.sender
        );
    }

    function getMinWithdrawBalanced(uint256 _lpAmount) external view returns (uint256 bLUSDAmount, uint256 lusdAmount) {
        bLUSDAmount = _lpAmount * bLUSDLUSD3CRVPool.balances(0) / bLUSDLUSD3CRVLPToken.totalSupply();
        uint256 lusd3CRVAmount = _lpAmount * bLUSDLUSD3CRVPool.balances(1) / bLUSDLUSD3CRVLPToken.totalSupply();
        lusdAmount = lusd3CRVPool.calc_withdraw_one_coin(lusd3CRVAmount, 0);

        return (bLUSDAmount, lusdAmount);
    }

    function getMinWithdrawLUSD(uint256 _lpAmount) external view returns (uint256 lusdAmount) {
        uint256 lusd3CRVAmount = bLUSDLUSD3CRVPool.calc_withdraw_one_coin(_lpAmount, 1);
        lusdAmount = lusd3CRVPool.calc_withdraw_one_coin(lusd3CRVAmount, 0);

        return lusdAmount;
    }
}