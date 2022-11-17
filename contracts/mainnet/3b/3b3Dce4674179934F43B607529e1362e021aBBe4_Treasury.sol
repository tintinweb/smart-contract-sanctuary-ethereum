/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: mintTest.sol

// contracts/MyContract.sol


pragma solidity >=0.8.0;



interface IStableSwap3Pool {
    function calc_token_amount(uint256[3] calldata _amounts, bool _is_deposit) external returns (uint256);
    function add_liquidity(uint256[3] calldata _amounts, uint256 _min_mint_amount) external returns (uint256);
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external returns (uint256);
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount)
        external
        returns (uint256);
    function coins(uint256 i) external returns (address);
    function get_virtual_price() external returns (uint256);
}


contract Treasury {
    struct SupportedStable {
        bool supported;
        int128 curveIndex;
    }

    // Storage Variables
    // Ethereum
    address public stableSwap3PoolAddress = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address public curveToken = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    // Gnosis
    // address public stableSwap3PoolAddress = 0x7f90122BF0700F9E7e1F688fe926940E8839F353;
    // address public curveToken = 0x1337BedC9D22ecbe766dF105c9623922A27963EC;
    mapping(address => SupportedStable) public supportedStables;

    // Test Variables
    uint256 public previousLpTokenPrice;
    uint256 public lpTokenPrice;
    uint256 public mintAmount;
    uint256 public lpTokens;

    function mint(address _stable, uint256 _amount) public returns (bool) {
        require(supportedStables[_stable].supported || _stable == curveToken, "Unsupported stable.");

        // Obtain user's input tokens
        IERC20(_stable).transferFrom(msg.sender, address(this), _amount);

        if (_stable != curveToken) {
            // Add liquidity to Curve
            IERC20(_stable).approve(stableSwap3PoolAddress, _amount);

            uint256[3] memory amounts;
            amounts[uint256(uint128(supportedStables[_stable].curveIndex))] = _amount;
            lpTokens = IStableSwap3Pool(stableSwap3PoolAddress).add_liquidity(amounts, 0);
        } else {
            lpTokens = _amount;
        }

        // Obtain current LP token virtual price (3CRV:USX conversion factor)
        lpTokenPrice = IStableSwap3Pool(stableSwap3PoolAddress).get_virtual_price();

        // Don't allow LP token price to decrease
        if (lpTokenPrice < previousLpTokenPrice) {
            lpTokenPrice = previousLpTokenPrice;
        } else {
            previousLpTokenPrice = lpTokenPrice;
        }

        // Mint USX tokens
        mintAmount = (lpTokens * lpTokenPrice) / 1e18;

        return true;
    }

    function addSupportedStable(address _stable, int128 _curveIndex) public {
        supportedStables[_stable] = SupportedStable(true, _curveIndex);
    }
}