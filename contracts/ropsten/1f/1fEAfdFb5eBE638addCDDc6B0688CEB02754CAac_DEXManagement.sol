// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./DEX/interfaces/IGooseBumpsSwapRouter02.sol";
import "./DEX/interfaces/IGooseBumpsSwapFactory.sol";

// found issue with transfer fee tokens
contract DEXManagement is Ownable, Pausable, ReentrancyGuard {
    //--------------------------------------
    // State variables
    //--------------------------------------

    address public TREASURY; // Must be multi-sig wallet or Treasury contract
    uint256 public SWAP_FEE; // Fee = SWAP_FEE / FEE_DENOMINATOR
    uint256 public SWAP_FEE_0X; // Fee = SWAP_FEE_0X / FEE_DENOMINATOR
    uint256 public FEE_DENOMINATOR = 10000;

    IGooseBumpsSwapRouter02 public dexRouter_;

    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------

    event LogReceived(address indexed, uint256);
    event LogFallback(address indexed, uint256);
    event LogSetTreasury(address indexed, address indexed);
    event LogSetSwapFee(address indexed, uint256);
    event LogSetSwapFee0x(address indexed, uint256);
    event LogSetDexRouter(address indexed, address indexed);
    event LogSwapExactTokensForTokens(
        address indexed,
        address indexed,
        uint256,
        uint256
    );
    event LogSwapExactETHForTokens(address indexed, uint256, uint256);
    event LogSwapExactTokenForETH(address indexed, uint256, uint256);
    event LogSwapExactTokensForTokensOn0x(
        address indexed,
        address indexed,
        uint256,
        uint256
    );
    event LogSwapExactETHForTokensOn0x(address indexed, uint256, uint256);
    event LogSwapExactTokenForETHOn0x(address indexed, uint256, uint256);

    //-------------------------------------------------------------------------
    // CONSTRUCTOR
    //-------------------------------------------------------------------------

    /**
     * @param   _router: router address
     * @param   _treasury: treasury address
     * @param   _swapFee: swap fee value
     * @param   _swapFee0x: swap fee for 0x value
     */
    constructor(
        address _router,
        address _treasury,
        uint256 _swapFee,
        uint256 _swapFee0x
    ) {
        require(_treasury != address(0), "Zero address");
        dexRouter_ = IGooseBumpsSwapRouter02(_router);
        TREASURY = _treasury;
        SWAP_FEE = _swapFee;
        SWAP_FEE_0X = _swapFee0x;
    }

    /**
     * @param   _tokenA: tokenA contract address
     * @param   _tokenB: tokenB contract address
     * @return  bool: if pair is in DEX, return true, else, return false.
     */
    function isPairExists(address _tokenA, address _tokenB)
        public
        view
        returns (bool)
    {
        return
            IGooseBumpsSwapFactory(dexRouter_.factory()).getPair(
                _tokenA,
                _tokenB
            ) != address(0);
    }

    /**
     * @param   _tokenA: tokenA contract address
     * @param   _tokenB: tokenB contract address
     * @return  bool: if path is in DEX, return true, else, return false.
     */
    function isPathExists(address _tokenA, address _tokenB)
        public
        view
        returns (bool)
    {
        return
            IGooseBumpsSwapFactory(dexRouter_.factory()).getPair(
                _tokenA,
                _tokenB
            ) !=
            address(0) ||
            (IGooseBumpsSwapFactory(dexRouter_.factory()).getPair(
                _tokenA,
                dexRouter_.WETH()
            ) !=
                address(0) &&
                IGooseBumpsSwapFactory(dexRouter_.factory()).getPair(
                    dexRouter_.WETH(),
                    _tokenB
                ) !=
                address(0));
    }

    /**
     * @param   tokenIn: tokenIn contract address
     * @param   tokenOut: tokenOut contract address
     * @param   _amountIn: amount of input token
     * @return  uint256: Given an input asset amount, returns the maximum output amount of the other asset.
     */
    function getAmountOut(
        address tokenIn,
        address tokenOut,
        uint256 _amountIn
    ) external view returns (uint256) {
        require(_amountIn > 0, "Invalid amount");
        require(isPathExists(tokenIn, tokenOut), "Invalid path");

        address[] memory path;
        if (isPairExists(tokenIn, tokenOut)) {
            path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;
        } else {
            path = new address[](3);
            path[0] = tokenIn;
            path[1] = dexRouter_.WETH();
            path[2] = tokenOut;
        }
        uint256[] memory amountOutMaxs = dexRouter_.getAmountsOut(
            (_amountIn * (FEE_DENOMINATOR - SWAP_FEE)) / FEE_DENOMINATOR,
            path
        );
        return amountOutMaxs[path.length - 1];
    }

    /**
     * @param   tokenIn: tokenIn contract address
     * @param   tokenOut: tokenOut contract address
     * @param   _amountOut: amount of output token
     * @return  uint256: Returns the minimum input asset amount required to buy the given output asset amount.
     */
    function getAmountIn(
        address tokenIn,
        address tokenOut,
        uint256 _amountOut
    ) external view returns (uint256) {
        require(_amountOut > 0, "Invalid amount");
        require(isPathExists(tokenIn, tokenOut), "Invalid path");

        address[] memory path;
        if (isPairExists(tokenIn, tokenOut)) {
            path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;
        } else {
            path = new address[](3);
            path[0] = tokenIn;
            path[1] = dexRouter_.WETH();
            path[2] = tokenOut;
        }
        uint256[] memory amountInMins = dexRouter_.getAmountsIn(
            _amountOut,
            path
        );
        return
            (amountInMins[0] * FEE_DENOMINATOR) / (FEE_DENOMINATOR - SWAP_FEE);
    }

    /**
     * @param   _amountIn: Amount of InputToken to swap on GooseBumps
     * @param   _amountOutMin: The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param   path: Swappath on Goosebumps
     * @param   to: Recipient of the output tokens.
     * @param   deadline: Deadline, Timestamp after which the transaction will revert.
     * @notice  Swap ERC20 token to ERC20 token on GooseBumps
     */
    function swapExactTokensForTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external whenNotPaused nonReentrant {
        require(
            IERC20(path[0]).transferFrom(
                _msgSender(),
                address(this),
                _amountIn
            ),
            "Faild TransferFrom"
        );

        uint256 _swapAmountIn = (_amountIn * (FEE_DENOMINATOR - SWAP_FEE)) /
            FEE_DENOMINATOR;

        require(IERC20(path[0]).approve(address(dexRouter_), _swapAmountIn));

        uint256 boughtAmount = IERC20(path[path.length - 1]).balanceOf(to);
        dexRouter_.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _swapAmountIn,
            _amountOutMin,
            path,
            to,
            deadline
        );
        boughtAmount =
            IERC20(path[path.length - 1]).balanceOf(to) -
            boughtAmount;

        require(
            IERC20(path[0]).transfer(TREASURY, _amountIn - _swapAmountIn),
            "Faild Transfer"
        );

        emit LogSwapExactTokensForTokens(
            path[0],
            path[path.length - 1],
            _amountIn,
            boughtAmount
        );
    }

    /**
     * @param   tokenA: InputToken Address to swap on 0x, The `sellTokenAddress` field from the API response
     * @param   tokenB: OutputToken Address to swap on 0x, The `buyTokenAddress` field from the API response
     * @param   _amountIn: Amount of InputToken to swap on 0x, The `sellAmount` field from the API response
     * @param   spender: Spender to approve the amount of InputToken, The `allowanceTarget` field from the API response
     * @param   swapTarget: SwapTarget contract address, The `to` field from the API response
     * @param   swapCallData: CallData, The `data` field from the API response
     * @param   to: Recipient of the output tokens.
     * @param   deadline: Deadline, Timestamp after which the transaction will revert.
     * @notice  Swap ERC20 token to ERC20 token by using 0x protocol
     */
    function swapExactTokensForTokensOn0x(
        address tokenA,
        address tokenB,
        uint256 _amountIn,
        address spender,
        address payable swapTarget,
        bytes calldata swapCallData,
        address to,
        uint256 deadline
    ) external whenNotPaused nonReentrant {
        require(deadline >= block.timestamp, "DEXManagement: EXPIRED");
        require(_amountIn > 0, "Invalid amount");
        require(address(swapTarget) != address(0), "Zero address");

        require(
            IERC20(tokenA).transferFrom(_msgSender(), address(this), _amountIn),
            "Faild TransferFrom"
        );
        uint256 _swapAmountIn = (_amountIn * (FEE_DENOMINATOR - SWAP_FEE_0X)) /
            FEE_DENOMINATOR;

        require(IERC20(tokenA).approve(spender, _swapAmountIn));

        uint256 boughtAmount = IERC20(tokenB).balanceOf(address(this));

        (bool success, ) = swapTarget.call(swapCallData);
        require(success, "SWAP_CALL_FAILED");

        boughtAmount = IERC20(tokenB).balanceOf(address(this)) - boughtAmount;

        require(IERC20(tokenB).transfer(to, boughtAmount), "Faild Transfer");

        require(
            IERC20(tokenA).transfer(TREASURY, _amountIn - _swapAmountIn),
            "Faild Transfer"
        );

        emit LogSwapExactTokensForTokensOn0x(
            tokenA,
            tokenB,
            _amountIn,
            boughtAmount
        );
    }

    /**
     * @param   token: OutputToken Address to swap on GooseBumps
     * @param   _amountOutMin: The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param   to: Recipient of the output tokens.
     * @param   deadline: Deadline, Timestamp after which the transaction will revert.
     * @notice  Swap ETH to ERC20 token on GooseBumps
     */
    function swapExactETHForTokens(
        address token,
        uint256 _amountOutMin,
        address to,
        uint256 deadline
    ) external payable whenNotPaused nonReentrant {
        require(isPathExists(token, dexRouter_.WETH()), "Invalid path");
        require(msg.value > 0, "Invalid amount");

        address[] memory path = new address[](2);
        path[0] = dexRouter_.WETH();
        path[1] = token;

        uint256 _swapAmountIn = (msg.value * (FEE_DENOMINATOR - SWAP_FEE)) /
            FEE_DENOMINATOR;

        uint256 boughtAmount = IERC20(token).balanceOf(to);
        dexRouter_.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: _swapAmountIn
        }(_amountOutMin, path, to, deadline);
        boughtAmount = IERC20(token).balanceOf(to) - boughtAmount;

        payable(TREASURY).transfer(msg.value - _swapAmountIn);

        emit LogSwapExactETHForTokens(token, msg.value, boughtAmount);
    }

    /**
     * @param   token: OutputToken Address to swap on 0x, The `buyTokenAddress` field from the API response
     * @param   swapTarget: SwapTarget contract address, The `to` field from the API response
     * @param   swapCallData: CallData, The `data` field from the API response
     * @param   to: Recipient of the output tokens.
     * @param   deadline: Deadline, Timestamp after which the transaction will revert.
     * @notice  Swap ETH to ERC20 token by using 0x protocol
     */
    function swapExactETHForTokensOn0x(
        address token,
        address payable swapTarget,
        bytes calldata swapCallData,
        address to,
        uint256 deadline
    ) external payable whenNotPaused nonReentrant {
        require(deadline >= block.timestamp, "DEXManagement: EXPIRED");
        require(msg.value > 0, "Invalid amount");
        require(address(swapTarget) != address(0), "Zero address");

        uint256 _swapAmountIn = (msg.value * (FEE_DENOMINATOR - SWAP_FEE_0X)) /
            FEE_DENOMINATOR;

        uint256 boughtAmount = IERC20(token).balanceOf(address(this));

        (bool success, ) = swapTarget.call{value: _swapAmountIn}(swapCallData);
        require(success, "SWAP_CALL_FAILED");

        boughtAmount = IERC20(token).balanceOf(address(this)) - boughtAmount;

        require(IERC20(token).transfer(to, boughtAmount), "Faild Transfer");

        payable(TREASURY).transfer(msg.value - _swapAmountIn);

        emit LogSwapExactETHForTokensOn0x(token, msg.value, boughtAmount);
    }

    /**
     * @param   token: InputToken Address to swap on GooseBumps
     * @param   _amountIn: Amount of InputToken to swap on GooseBumps
     * @param   _amountOutMin: The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param   to: Recipient of the output tokens.
     * @param   deadline: Deadline, Timestamp after which the transaction will revert.
     * @notice  Swap ERC20 token to ETH on GooseBumps
     */
    function swapExactTokenForETH(
        address token,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address to,
        uint256 deadline
    ) external whenNotPaused nonReentrant {
        require(isPathExists(token, dexRouter_.WETH()), "Invalid path");
        require(_amountIn > 0, "Invalid amount");

        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = dexRouter_.WETH();

        require(
            IERC20(token).transferFrom(_msgSender(), address(this), _amountIn),
            "Faild TransferFrom"
        );
        uint256 _swapAmountIn = (_amountIn * (FEE_DENOMINATOR - SWAP_FEE)) /
            FEE_DENOMINATOR;

        require(IERC20(token).approve(address(dexRouter_), _swapAmountIn));

        uint256 boughtAmount = address(to).balance;
        dexRouter_.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _swapAmountIn,
            _amountOutMin,
            path,
            to,
            deadline
        );
        boughtAmount = address(to).balance - boughtAmount;

        require(
            IERC20(token).transfer(TREASURY, _amountIn - _swapAmountIn),
            "Faild Transfer"
        );

        emit LogSwapExactTokenForETH(token, _amountIn, boughtAmount);
    }

    /**
     * @param   token: InputToken Address to swap on 0x, The `sellTokenAddress` field from the API response
     * @param   _amountIn: Amount of InputToken to swap on 0x, The `sellAmount` field from the API response
     * @param   spender: Spender to approve the amount of InputToken, The `allowanceTarget` field from the API response
     * @param   swapTarget: SwapTarget contract address, The `to` field from the API response
     * @param   swapCallData: CallData, The `data` field from the API response
     * @param   to: Recipient of the output tokens.
     * @param   deadline: Deadline, Timestamp after which the transaction will revert.
     * @notice  Swap ERC20 token to ETH by using 0x protocol
     */
    function swapExactTokenForETHOn0x(
        address token,
        uint256 _amountIn,
        address spender,
        address payable swapTarget,
        bytes calldata swapCallData,
        address to,
        uint256 deadline
    ) external whenNotPaused nonReentrant {
        require(deadline >= block.timestamp, "DEXManagement: EXPIRED");
        require(_amountIn > 0, "Invalid amount");
        require(address(swapTarget) != address(0), "Zero address");
        require(to != address(0), "'to' is Zero address");

        require(
            IERC20(token).transferFrom(_msgSender(), address(this), _amountIn),
            "Faild TransferFrom"
        );
        uint256 _swapAmountIn = (_amountIn * (FEE_DENOMINATOR - SWAP_FEE_0X)) /
            FEE_DENOMINATOR;

        require(IERC20(token).approve(spender, _swapAmountIn));

        uint256 boughtAmount = address(this).balance;

        (bool success, ) = swapTarget.call(swapCallData);
        require(success, "SWAP_CALL_FAILED");

        boughtAmount = address(this).balance - boughtAmount;

        payable(to).transfer(boughtAmount);

        require(
            IERC20(token).transfer(TREASURY, _amountIn - _swapAmountIn),
            "Faild Transfer"
        );

        emit LogSwapExactTokenForETHOn0x(token, _amountIn, boughtAmount);
    }

    struct FillResults {
        uint256 makerAssetFilledAmount; // Total amount of makerAsset(s) filled.
        uint256 takerAssetFilledAmount; // Total amount of takerAsset(s) filled.
        uint256 makerFeePaid; // Total amount of fees paid by maker(s) to feeRecipient(s).
        uint256 takerFeePaid; // Total amount of fees paid by taker to feeRecipients(s).
        uint256 protocolFeePaid; // Total amount of fees paid by taker to the staking contract.
    }

    event LogSwapTest(FillResults);
    event LogSwapTestWithETH(FillResults);

    function swapTest(bytes calldata swapCallData, address payable swapTarget)
        external
        returns (FillResults memory fillResults)
    {
        (bool success, bytes memory data) = swapTarget.call(swapCallData);
        require(success, "SWAP_CALL_FAILED");
        fillResults = abi.decode(data, (FillResults));
    }

    function swapTestWithETH(
        bytes calldata swapCallData,
        address payable swapTarget
    ) external payable returns (FillResults memory fillResults) {
        (bool success, bytes memory data) = swapTarget.call{value: msg.value}(
            swapCallData
        );
        require(success, "SWAP_CALL_FAILED");
        fillResults = abi.decode(data, (FillResults));
    }

    receive() external payable {
        emit LogReceived(_msgSender(), msg.value);
    }

    fallback() external payable {
        emit LogFallback(_msgSender(), msg.value);
    }

    //-------------------------------------------------------------------------
    // set functions
    //-------------------------------------------------------------------------

    function setPause() external onlyOwner {
        _pause();
    }

    function setUnpause() external onlyOwner {
        _unpause();
    }

    function setTreasury(address _newTreasury) external onlyOwner {
        require(
            TREASURY != _newTreasury,
            "Same address! Notice: Must be Multi-sig Wallet!"
        );
        TREASURY = _newTreasury;

        emit LogSetTreasury(_msgSender(), TREASURY);
    }

    function setSwapFee(uint256 _newSwapFee) external onlyOwner {
        require(SWAP_FEE != _newSwapFee, "Same value!");
        SWAP_FEE = _newSwapFee;

        emit LogSetSwapFee(_msgSender(), SWAP_FEE);
    }

    function setSwapFee0x(uint256 _newSwapFee0x) external onlyOwner {
        require(SWAP_FEE_0X != _newSwapFee0x, "Same value!");
        SWAP_FEE_0X = _newSwapFee0x;

        emit LogSetSwapFee0x(_msgSender(), SWAP_FEE_0X);
    }

    function setDexRouter(address _newRouter) external onlyOwner {
        require(address(dexRouter_) != _newRouter, "Same router!");
        dexRouter_ = IGooseBumpsSwapRouter02(_newRouter);

        emit LogSetDexRouter(_msgSender(), address(dexRouter_));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import './IGooseBumpsSwapRouter01.sol';

interface IGooseBumpsSwapRouter02 is IGooseBumpsSwapRouter01 {
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IGooseBumpsSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IGooseBumpsSwapRouter01 {
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