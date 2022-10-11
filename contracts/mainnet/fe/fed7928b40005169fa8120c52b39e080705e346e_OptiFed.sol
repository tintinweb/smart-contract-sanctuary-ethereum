/**
 *Submitted for verification at Etherscan.io on 2022-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Returns the decimal points used by the token.
     */
    function decimals() external view returns (uint8);

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
     * @dev Burns `amount` of token, shringking total supply
     */
    function burn(uint amount) external;

    /**
     * @dev Mints `amount` of token to address `to` increasing total supply
     */
    function mint(address to, uint amount) external;

    //For testing
    function addMinter(address minter_) external;
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IDola {
    function decimals() external view returns (uint8);
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    function mint(address recipient, uint256 amount) external;
    function burn(uint256 amount) external;

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function addMinter(address minter) external;

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

/**
 * @title IL1ERC20Bridge
 */
interface IL1ERC20Bridge {
    /**********
     * Events *
     **********/

    event ERC20DepositInitiated(
        address indexed _l1Token,
        address indexed _l2Token,
        address indexed _from,
        address _to,
        uint256 _amount,
        bytes _data
    );

    event ERC20WithdrawalFinalized(
        address indexed _l1Token,
        address indexed _l2Token,
        address indexed _from,
        address _to,
        uint256 _amount,
        bytes _data
    );

    /********************
     * Public Functions *
     ********************/

    /**
     * @dev get the address of the corresponding L2 bridge contract.
     * @return Address of the corresponding L2 bridge contract.
     */
    function l2TokenBridge() external returns (address);

    /**
     * @dev deposit an amount of the ERC20 to the caller's balance on L2.
     * @param _l1Token Address of the L1 ERC20 we are depositing
     * @param _l2Token Address of the L1 respective L2 ERC20
     * @param _amount Amount of the ERC20 to deposit
     * @param _l2Gas Gas limit required to complete the deposit on L2.
     * @param _data Optional data to forward to L2. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function depositERC20(
        address _l1Token,
        address _l2Token,
        uint256 _amount,
        uint32 _l2Gas,
        bytes calldata _data
    ) external;

    /**
     * @dev deposit an amount of ERC20 to a recipient's balance on L2.
     * @param _l1Token Address of the L1 ERC20 we are depositing
     * @param _l2Token Address of the L1 respective L2 ERC20
     * @param _to L2 address to credit the withdrawal to.
     * @param _amount Amount of the ERC20 to deposit.
     * @param _l2Gas Gas limit required to complete the deposit on L2.
     * @param _data Optional data to forward to L2. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function depositERC20To(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 _l2Gas,
        bytes calldata _data
    ) external;

    /*************************
     * Cross-chain Functions *
     *************************/

    /**
     * @dev Complete a withdrawal from L2 to L1, and credit funds to the recipient's balance of the
     * L1 ERC20 token.
     * This call will fail if the initialized withdrawal from L2 has not been finalized.
     *
     * @param _l1Token Address of L1 token to finalizeWithdrawal for.
     * @param _l2Token Address of L2 token where withdrawal was initiated.
     * @param _from L2 address initiating the transfer.
     * @param _to L1 address to credit the withdrawal to.
     * @param _amount Amount of the ERC20 to deposit.
     * @param _data Data provided by the sender on L2. This data is provided
     *   solely as a convenience for external contracts. Aside from enforcing a maximum
     *   length, these contracts provide no guarantees about its content.
     */
    function finalizeERC20Withdrawal(
        address _l1Token,
        address _l2Token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external;
}

interface ICurvePool {

	// Deployment
	function __init__() external;
	function initialize(string memory _name, string memory _symbol, address _coin, uint _decimals, uint _A, uint _fee, address _admin) external;

	// ERC20 Standard
	function decimals() external view returns (uint);
	function transfer(address _to, uint _value) external returns (uint256);
	function transferFrom(address _from, address _to, uint _value) external returns (bool);
	function approve(address _spender, uint _value) external returns (bool);
	function balanceOf(address _owner) external view returns (uint256);
	function totalSupply() external view returns (uint256);

	// StableSwap Functionality
	function get_previous_balances() external view returns (uint[2] memory);
	function get_twap_balances(uint[2] memory _first_balances, uint[2] memory _last_balances, uint _time_elapsed) external view returns (uint[2] memory);
	function get_price_cumulative_last() external view returns (uint[2] memory);
	function admin_fee() external view returns (uint);
	function A() external view returns (uint);
	function A_precise() external view returns (uint);
	function get_virtual_price() external view returns (uint);
	function calc_token_amount(uint[2] memory _amounts, bool _is_deposit) external view returns (uint);
	function calc_token_amount(uint[2] memory _amounts, bool _is_deposit, bool _previous) external view returns (uint);
	function add_liquidity(uint[2] memory _amounts, uint _min_mint_amount) external returns (uint);
	function add_liquidity(uint[3] memory _amounts, uint _min_mint_amount) external;
	function add_liquidity(uint[2] memory _amounts, uint _min_mint_amount, address _receiver) external returns (uint);
	function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
	function get_dy(int128 i, int128 j, uint256 dx, uint256[2] memory _balances) external view returns (uint256);
	function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);
	function get_dy_underlying(int128 i, int128 j, uint256 dx, uint256[2] memory _balances) external view returns (uint256);
	function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
	function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver) external returns (uint256);
	function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
	function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver) external returns (uint256);
	function remove_liquidity(uint256 _burn_amount, uint256[2] memory _min_amounts) external returns (uint256[2] memory);
	function remove_liquidity(uint256 _burn_amount, uint256[2] memory _min_amounts, address _receiver) external returns (uint256[2] memory);
	function remove_liquidity_imbalance(uint256[2] memory _amounts, uint256 _max_burn_amount) external returns (uint256);
	function remove_liquidity_imbalance(uint256[2] memory _amounts, uint256 _max_burn_amount, address _receiver) external returns (uint256);
	function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);
	function calc_withdraw_one_coin(uint256 _burn_amount, int128 i, bool _previous) external view returns (uint256);
	function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_received) external returns (uint256);
	function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_received, address _receiver) external returns (uint256);
	function ramp_A(uint256 _future_A, uint256 _future_time) external;
	function stop_ramp_A() external;
	function admin_balances(uint256 i) external view returns (uint256);
	function withdraw_admin_fees() external;
}

contract OptiFed {
    address public chair;
    address public gov;
    address public pendingGov;
    uint public dolaSupply;
    uint public maxSlippageBpsDolaToUsdc;
    uint public maxSlippageBpsUsdcToDola;

    uint constant PRECISION = 10_000;
    uint public constant DOLA_USDC_CONVERSION_MULTI= 1e12;

    IDola public constant DOLA = IDola(0x865377367054516e17014CcdED1e7d814EDC9ce4);
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IL1ERC20Bridge public constant optiBridge = IL1ERC20Bridge(0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1);
    address public constant DOLA_OPTI = 0x8aE125E8653821E851F12A49F7765db9a9ce7384;
    address public constant USDC_OPTI = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
    ICurvePool public curvePool = ICurvePool(0xE57180685E3348589E9521aa53Af0BCD497E884d);
    address public veloFarmer;

    event Expansion(uint amount);
    event Contraction(uint amount);

    error OnlyGov();
    error OnlyPendingGov();
    error OnlyChair();
    error CantBurnZeroDOLA();
    error MaxSlippageTooHigh();
    error DeltaAboveMax();
    error SwapMoreDolaThanMinted();

    constructor(
            address gov_,
            address chair_,
            address veloFarmer_,
            uint maxSlippageBpsDolaToUsdc_,
            uint maxSlippageBpsUsdcToDola_)
    {
        gov = gov_;
        chair = chair_;
        veloFarmer = veloFarmer_;
        maxSlippageBpsDolaToUsdc = maxSlippageBpsDolaToUsdc_;
        maxSlippageBpsUsdcToDola = maxSlippageBpsUsdcToDola_;
    }

    /**
    @notice Mints `dolaAmount` of DOLA, swaps `dolaToSwap` of DOLA to USDC, then transfers all to `veloFarmer` through optimism bridge
    @param dolaAmount Amount of DOLA to mint
    @param dolaToSwap Amount of DOLA to swap for USDC
    */
    function expansionAndSwap(uint dolaAmount, uint dolaToSwap) external {
        if (msg.sender != chair) revert OnlyChair();
        if (dolaToSwap > dolaAmount) revert SwapMoreDolaThanMinted();
        
        dolaSupply += dolaAmount;
        DOLA.mint(address(this), dolaAmount);

        DOLA.approve(address(curvePool), dolaToSwap);
        uint usdcAmount = curvePool.exchange_underlying(0, 2, dolaToSwap, dolaToSwap * (PRECISION - maxSlippageBpsDolaToUsdc) / PRECISION / DOLA_USDC_CONVERSION_MULTI);

        uint dolaToBridge = dolaAmount - dolaToSwap;
        DOLA.approve(address(optiBridge), dolaToBridge);
        USDC.approve(address(optiBridge), usdcAmount);
        optiBridge.depositERC20To(address(DOLA), DOLA_OPTI, veloFarmer, dolaToBridge, 200_000, "");
        optiBridge.depositERC20To(address(USDC), USDC_OPTI, veloFarmer, usdcAmount, 200_000, "");

        emit Expansion(dolaAmount);
    }

    /**
    @notice Mints & deposits `amountUnderlying` of `underlying` tokens into Optimism bridge to the `veloFarmer` contract
    @param dolaAmount Amount of underlying token to mint & deposit into Velodrome farmer on Optimism
    */
    function expansion(uint dolaAmount) external {
        if (msg.sender != chair) revert OnlyChair();
        
        dolaSupply += dolaAmount;
        DOLA.mint(address(this), dolaAmount);

        DOLA.approve(address(optiBridge), dolaAmount);
        optiBridge.depositERC20To(address(DOLA), DOLA_OPTI, veloFarmer, dolaAmount, 200_000, "");

        emit Expansion(dolaAmount);
    }

    /**
    @notice Burns `dolaAmount` of DOLA held in this contract
    @param dolaAmount Amount of DOLA to burn
    */
    function contraction(uint dolaAmount) public {
        if (msg.sender != chair) revert OnlyChair();

        _contraction(dolaAmount);
    }

    /**
    @notice Attempts to contract (burn) all DOLA held by this contract
    */
    function contractAll() external {
        if (msg.sender != chair) revert OnlyChair();

        _contraction(DOLA.balanceOf(address(this)));
    }

    /**
    @notice Attempts to contract (burn) `amount` of DOLA. Sends remainder to `gov` if `amount` > DOLA minted by this fed.
    @param amount Amount of DOLA to contract.
    */
    function _contraction(uint amount) internal{
        if (amount == 0) revert CantBurnZeroDOLA();
        if(amount > dolaSupply){
            DOLA.burn(dolaSupply);
            DOLA.transfer(gov, amount - dolaSupply);
            emit Contraction(dolaSupply);
            dolaSupply = 0;
        } else {
            DOLA.burn(amount);
            dolaSupply -= amount;
            emit Contraction(amount);
        }
    }

    /**
    @notice Swap `usdcAmount` of USDC for DOLA through curve.
    @dev Will revert if actual slippage > `maxSlippageBpsUsdcToDola`
    @param usdcAmount Amount of USDC to be swapped to DOLA through curve.
    */
    function swapUSDCtoDOLA(uint usdcAmount) external {
        if (msg.sender != chair) revert OnlyChair();
        
        USDC.approve(address(curvePool), usdcAmount);
        curvePool.exchange_underlying(2, 0, usdcAmount, usdcAmount * (PRECISION - maxSlippageBpsUsdcToDola) / PRECISION * DOLA_USDC_CONVERSION_MULTI);
    }

    /**
    @notice Swap `dolaAmount` of DOLA for USDC through curve.
    @dev Will revert if actual slippage > `maxSlippageBpsDolaToUsdc`
    @param dolaAmount Amount of DOLA to be swapped to USDC through curve.
    */
    function swapDOLAtoUSDC(uint dolaAmount) external {
        if (msg.sender != chair) revert OnlyChair();
        
        DOLA.approve(address(curvePool), dolaAmount);
        curvePool.exchange_underlying(0, 2, dolaAmount, dolaAmount * (PRECISION - maxSlippageBpsDolaToUsdc) / PRECISION / DOLA_USDC_CONVERSION_MULTI);
    }

    /**
    @notice Method for current chair of the Opti FED to resign
    */
    function resign() external {
        if (msg.sender != chair) revert OnlyChair();
        chair = address(0);
    }

    /**
    @notice Governance only function for setting acceptable slippage when swapping DOLA -> USDC
    @param newMaxSlippageBps The new maximum allowed loss for DOLA -> USDC swaps. 1 = 0.01%
    */
    function setMaxSlippageDolaToUsdc(uint newMaxSlippageBps) external {
        if (msg.sender != gov) revert OnlyGov();
        if (newMaxSlippageBps > 10000) revert MaxSlippageTooHigh();
        maxSlippageBpsDolaToUsdc = newMaxSlippageBps;
    }

    /**
    @notice Governance only function for setting acceptable slippage when swapping USDC -> DOLA
    @param newMaxSlippageBps The new maximum allowed loss for USDC -> DOLA swaps. 1 = 0.01%
    */
    function setMaxSlippageUsdcToDola(uint newMaxSlippageBps) external {
        if (msg.sender != gov) revert OnlyGov();
        if (newMaxSlippageBps > 10000) revert MaxSlippageTooHigh();
        maxSlippageBpsUsdcToDola = newMaxSlippageBps;
    }

    /**
    @notice Method for `gov` to change `pendingGov` address
    @dev `pendingGov` will have to call `claimGov` to complete `gov` transfer
    @param newPendingGov_ Address to be set as `pendingGov`
    */
    function setPendingGov(address newPendingGov_) external {
        if (msg.sender != gov) revert OnlyGov();
        pendingGov = newPendingGov_;
    }

    /**
    @notice Method for `pendingGov` to claim `gov` role.
    */
    function claimGov() external {
        if (msg.sender != pendingGov) revert OnlyPendingGov();
        gov = pendingGov;
        pendingGov = address(0);
    }

    /**
    @notice Method for gov to change the chair
    @param newChair_ Address to be set as chair
    */
    function changeChair(address newChair_) external {
        if (msg.sender != gov) revert OnlyGov();
        chair = newChair_;
    }

    /**
    @notice Method for gov to change the L2 veloFarmer address
    @dev veloFarmer is the L2 address that receives all bridged DOLA from expansion
    @param newVeloFarmer_ L2 address to be set as veloFarmer
    */
     function changeVeloFarmer(address newVeloFarmer_) external {
        if (msg.sender != gov) revert OnlyGov();
        veloFarmer = newVeloFarmer_;
    }

    /**
    @notice Method for gov to change the curve pool address
    @param newCurvePool_ Address to be set as curvePool
    */
     function changeCurvePool(address newCurvePool_) external {
        if (msg.sender != gov) revert OnlyGov();
        curvePool = ICurvePool(newCurvePool_);
    }
}