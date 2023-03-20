/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// SPDX-License-Identifier: AGPL-3.0-only
// v2.0.03200148

/*
  _____        __ _       _ _         ____  _ _         _
 |_   _|      / _(_)     (_) |       |  _ \(_) |       (_)
   | |  _ __ | |_ _ _ __  _| |_ _   _| |_) |_| |_       _  ___
   | | | '_ \|  _| | '_ \| | __| | | |  _ <| | __|     | |/ _ \
  _| |_| | | | | | | | | | | |_| |_| | |_) | | |_   _  | | (_) |
 |_____|_| |_|_| |_|_| |_|_|\__|\__, |____/|_|\__| (_) |_|\___/
                                 __/ |
                                |___/
  v2
*/
// InfinityBit Token (IBIT) - v2
// https://infinitybit.io
// TG: https://t.me/infinitybit_io
// Twitter: https://twitter.com/infinitybit_io

pragma solidity 0.8.18;


// License: MIT
// pragma solidity ^0.8.0;
/**
 * @dev Collection of functions related to the address type
 */
library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// License: GPL-3.0
// https://github.com/Uniswap

// pragma solidity ^0.8.0;

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


// License: GPL-3.0
// https://github.com/Uniswap

// pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}


// License: GPL-3.0
// https://github.com/Uniswap

// pragma solidity >=0.8.0;

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

    function initialize(address, address) external;
}

//
// InfinityBit Token v2
//
// License: AGPL-3.0-only

// pragma solidity 0.8.18;

contract InfinityBitTokenV2 is IERC20, Ownable {
    using Address for address;

    event TaxesAutoswap(uint256 amount_eth);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals = 8;
    uint256 private _deployHeight;
    address private _contractDeployer;

    // flags
    bool private _maxWalletEnabled = true;
    bool public _autoSwapTokens = true;
    bool public _transfersEnabled = false;
    bool public _sellFromTaxWallets = true;

    // Maximum Supply is 5,700,000,000. This is immutable and cannot be changed.
    uint256 private immutable _maxSupply = 5_700_000_000 * (10 ** uint256(_decimals));

    // Maximum total tax rate. This is immutable and cannot be changed.
    uint8 private immutable _maxTax = 50; // 5%
    // Maximum wallet. This is immutable and cannot be changed.
    uint256 private immutable _maxWallet = 125000000 * (10 ** uint256(_decimals));

    // Marketing Tax - has one decimal.
    uint8 private _marketingTax = 30; // 3%
    address payable private _marketingWallet = payable(0xd1CB9007D51FB812805d80618A97418Fd388B0C5);
    address payable immutable private _legacyMarketingWallet = payable(0xA6e18D5F6b20dFA84d7d245bb656561f1f9aff69);

    // Developer Tax
    uint8 private _devTax = 18; // 1.8%
    address payable private _devWallet = payable(0x02DAb704810C40C87374eBD85927c3D8a9815Eb0);
    address payable immutable private _legacyDevWallet = payable(0x9d0D8E5e651Ab7d54Af5B0F655b3978504E67E0C);

    // LP Tax
    uint8 private _lpTax = 0; // 0%

    // Burn Address
    address private immutable _burnAddress = 0x000000000000000000000000000000000000D34d;

    // Deadline in seconds for UniswapV2 autoswap
    uint8 private _autoSwapDeadlineSeconds = 0;

    // Taxless Allow-List
    //  This is a list of wallets which are exempt from taxes.
    mapping(address=>bool) TaxlessAllowList;

    // IgnoreMaxWallet Allow-List
    //  This is a list of wallets which are exempt from the maximum wallet.
    mapping(address=>bool) IgnoreMaxWalletAllowList;

    // SwapThreshold - Amount that will be autoswapped- has one decimal.
    uint8 public _swapLimit = 25; // 2.5%
    uint8 public immutable _swapLimitMax = 50; // 5% hardcoded max
    uint8 public _swapThreshold = 10; // 1%
    uint8 public immutable _swapThresholdMax = 50; // 5% hardcoded max

    // Required to recieve ETH from UniswapV2Router on automated token swaps
    receive() external payable {}

    // Uniswap V2
    IUniswapV2Router02 public _uniswapV2Router;
    address private _uniswapV2RouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private _uniswapUniversalRouter = 0x4648a43B2C14Da09FdF82B161150d3F634f40491;
    address private _uniswapV2PairAddress;
    IUniswapV2Factory public _uniswapV2Factory;

    constructor() payable {
        _name = "InfinityBit Token";
        _symbol = "IBIT";
        _decimals = 8;

        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);
        _uniswapV2Router = uniswapV2Router;

        // Create Uniswap V2 Pair
        _uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
        _uniswapV2PairAddress = _uniswapV2Factory.createPair(address(this), _uniswapV2Router.WETH());
        _uniswapV2Router = uniswapV2Router;

        // Mint Supply
        _mint(msg.sender, _maxSupply);
        _totalSupply = _maxSupply;

        // IgnoreMaxWallet Allowlist
        IgnoreMaxWalletAllowList[_uniswapUniversalRouter] = true;
        IgnoreMaxWalletAllowList[_uniswapV2RouterAddress] = true;
        IgnoreMaxWalletAllowList[_uniswapV2PairAddress] = true;
        IgnoreMaxWalletAllowList[_marketingWallet] = true;
        IgnoreMaxWalletAllowList[_devWallet] = true;
        IgnoreMaxWalletAllowList[_legacyMarketingWallet] = true;
        IgnoreMaxWalletAllowList[_legacyDevWallet] = true;
        IgnoreMaxWalletAllowList[address(owner())] = true;

        // Taxless Allowlist
        TaxlessAllowList[_uniswapUniversalRouter] = true;
        TaxlessAllowList[_uniswapV2RouterAddress] = true;
        TaxlessAllowList[_marketingWallet] = true;
        TaxlessAllowList[_devWallet] = true;
        TaxlessAllowList[address(owner())] = true;
    }

    //
    //
    //

    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    function _approve(address from, address spender, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[from][spender] = amount;
        emit Approval(from, spender, amount);
    }
    function _spendAllowance(address from, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(from, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
            _approve(from, spender, currentAllowance - amount);
        }
        }
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance(msg.sender, spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = allowance(msg.sender, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
    }

        return true;
    }


    //
    //
    //


    function _mint(address to, uint value) internal {
        _totalSupply = _totalSupply+value;
        _balances[to] = _balances[to] + value;
        emit Transfer(address(0), to, value);
    }

    // Once transfers are enabled, they cannot be disabled.
    function enableTransfers() public onlyOwner() {
        _transfersEnabled = true;
    }

    // Set the Dev Wallet Address
    function setDevWallet(address devWallet) public onlyOwner {
        require(devWallet != address(0), "IBIT: cannot set to the zero address");
        _devWallet = payable(devWallet);
    }

    // Set the Marketing Wallet Address
    function setMarketingWallet(address marketingWallet) public onlyOwner {
        require(marketingWallet != address(0), "IBIT: cannot set to the zero address");
        _marketingWallet = payable(marketingWallet);
    }

    function isSell(address sender, address recipient) private view returns (bool) {
        if(sender == _uniswapV2RouterAddress || sender == _uniswapV2PairAddress || sender == _uniswapUniversalRouter) {
            return false;
        }

        if(recipient == _uniswapV2PairAddress || recipient == address(_uniswapV2Router)) {
            return true;
        }

        return false;
    }

    function isBuy(address sender) private view returns (bool) {
        return sender == _uniswapV2PairAddress || sender == address(_uniswapV2Router);
    }

    event AutoswapFailed(uint256 amount);

    function _swapTokensForETH(uint256 amount) private {
        if(amount == 0) {
            return;
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), amount);

        try _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp+_autoSwapDeadlineSeconds
        ) {

        } catch {
            emit AutoswapFailed(amount);
        }
    }

    function addLiquidity(uint256 amount_tokens, uint256 amount_eth) private returns (bool) {
        if(amount_tokens == 0 || amount_eth == 0) {
            return true;
        }

        _approve(address(this), address(_uniswapV2Router), amount_tokens);
        try _uniswapV2Router.addLiquidityETH{value: amount_eth}(
            address(this),
            amount_tokens,
            0,
            0,
            owner(),
            block.timestamp
        ) {
            return true;
        } catch {
            return false;
        }
    }

    function getDevTax() public view returns (uint8) {
        return _devTax;
    }

    function toggleAutoSwapTokens(bool enable) public onlyOwner {
        _autoSwapTokens = enable;
    }

    function getLpTax() public view returns (uint8) {
        return _lpTax;
    }

    function getMarketingTax() public view returns (uint8) {
        return _marketingTax;
    }

    function setDevTax(uint8 tax) public onlyOwner {
        require(_lpTax+_marketingTax+tax <= _maxTax, "IBIT: total tax cannot exceed max tax");
        _devTax = tax;
    }

    function setLpTax(uint8 tax) public onlyOwner {
        require((_devTax+_marketingTax+tax) <= _maxTax, "IBIT: total tax cannot exceed max tax");
        _lpTax = tax;
    }

    function setMarketingTax(uint8 tax) public onlyOwner {
        require(_devTax+_lpTax+tax <= _maxTax, "IBIT: total tax cannot exceed max tax");
        _marketingTax = tax;
    }

    function setAutoswapDeadline(uint8 deadline_seconds) public onlyOwner {
        _autoSwapDeadlineSeconds = deadline_seconds;
    }

    function DetectMaxWalletEnabled() public view returns (bool) {
        return _maxWalletEnabled;
    }

    function ToggleMaxWallet(bool _enable) public onlyOwner {
        _maxWalletEnabled = _enable;
    }

    function SetUniswapV2Pair(address _w) public onlyOwner {
        _uniswapV2PairAddress = _w;
    }

    function GetUniswapV2Pair() public view returns (address) {
        return _uniswapV2PairAddress;
    }

    // Add a wallet address to the taxless allow-list.
    function SetTaxlessAllowList(address _w) public onlyOwner {
        TaxlessAllowList[_w] = true;
    }

    // Remove a wallet address from the taxless allow-list.
    function UnsetTaxlessAllowList(address _w) public onlyOwner {
        TaxlessAllowList[_w] = false;
    }

    // Add a wallet address to the max wallet allow-list.
    function SetMaxWalletAllowList(address _w) public onlyOwner {
        IgnoreMaxWalletAllowList[_w] = true;
    }

    // Remove a wallet address from the max wallet allow-list.
    function UnsetMaxWalletAllowList(address _w) public onlyOwner {
        IgnoreMaxWalletAllowList[_w] = false;
    }

    // Returns true if the provided address is tax-exempt, otherwise returns false.
    function isTaxExempt(address from, address to) public view returns(bool) {
        if(TaxlessAllowList[from] || TaxlessAllowList[to])
        {
            return true;
        }

        if(from == owner() || to == owner())
        {
            return true;
        }

        return false;
    }

    // Returns true if the provided address is maxWallet-exempt, otherwise returns false.
    function isMaxWalletExempt(address _w) public view returns (bool) {
        if(_w == address(owner()))
        {
            return true;
        }

        return IgnoreMaxWalletAllowList[_w];
    }

    // Returns the total tax %
    function totalTax() public view returns (uint8) {
        return _lpTax+_devTax+_marketingTax;
    }

    // Sends Ether to specified 'to' address
    function sendEther(address payable to, uint256 amount) private returns (bool) {
        return to.send(amount);
    }

    // Returns the amount of IBIT tokens in the Liquidity Pool
    function getLiquidityIBIT() public view returns (uint256) {
        return _balances[_uniswapV2PairAddress];
    }

    // Limit the maximum autoswap based on _swapLimit percent
    function getMaxAutoswap() public view returns (uint256 max_autoswap_limit) {
        return (_swapLimit * getLiquidityIBIT()) / 1000;
    }

    // Returns the autoswap limit (ie, the maximum which will be autoswapped) as a percent with one decimal, i.e. 50 = 5%
    function getAutoswapLimit() public view returns (uint8 autoswap_limit_percent) {
        return _swapLimit;
    }

    function setAutoswapLimit(uint8 swapLimit) public onlyOwner {
        require(swapLimit < _swapLimitMax, "IBIT: swapLimit exceeds max");
        _swapLimit = swapLimit;
    }

    // Returns the autoswap threshold,  the minimum tokens which must be
    // reached before an autoswap will occur. expressed as a percent with one decimal, i.e. 50 = 5%
    function getAutoswapThreshold() public view returns (uint8 autoswap_threshold_percent) {
        return _swapThreshold;
    }

    function setAutoswapThreshold(uint8 swapThreshold) public onlyOwner {
        require(_swapThreshold < _swapThresholdMax, "IBIT: swapThreshold exceeds max");
        _swapThreshold = swapThreshold;
    }

    event AutoLiquidityFailed(uint256 token_amount, uint256 eth_amount, uint256 tokens_collected, uint256 tokens_swapped, uint256 eth_collected);
    event AutoLiquiditySuccess(uint256 token_amount, uint256 eth_amount, uint256 tokens_collected, uint256 tokens_swapped, uint256 eth_collected);
    event DeductTaxes(uint256 dev_tax_amount, uint256 marketing_tax_amount, uint256 lp_tax_amount);

    // Returns the maximum amount which can be autoswapped if everything is sold
    function autoswapTotalTokensAvailable(uint256 amount) public view returns (uint256) {
        return _calcLpTaxAmount(amount)/2 + _calcDevTaxAmount(amount) + _calcMarketingTaxAmount(amount) + _balances[_devWallet] + _balances[_marketingWallet];
    }

    function calcAutoswapAmount(uint256 sell_amount) public view returns (uint256) {
        uint256 lp_tokens = _calcLpTaxAmount(sell_amount)/2;
        return lp_tokens + _calcDevTaxAmount(sell_amount) + _calcMarketingTaxAmount(sell_amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");

        if(!_transfersEnabled) {
            require(from == owner() || to == owner(), "IBIT: transfers disabled until initial LP");
        }

        uint256 tax_amount;

        // Begin Tax Check
        if(isTaxExempt(from, to))
        {
            tax_amount = 0;
        }
        else
        {
            tax_amount = _calcTaxes(amount);
        }

        uint256 transfer_amount = amount - tax_amount;

        // Begin Max Wallet Check, owner always ignores max wallet check.
        if(!isMaxWalletExempt(to) && from != owner() && _maxWalletEnabled)
        {
            require((balanceOf(to) + transfer_amount) <= _maxWallet, "IBIT: maximum wallet cannot be exceeded");
        }

        if(tax_amount == 0)
        {
            _taxlessTransfer(from, to, amount);
            return;
        }

        // Take taxes
        _takeTaxes(from, tax_amount);
        emit DeductTaxes(_calcDevTaxAmount(amount), _calcMarketingTaxAmount(amount), _calcLpTaxAmount(amount));

        if(autoSwapConditionCheck(from, to, amount))
        {
            _autoSwapTaxForEth(from, to, amount);
        }
        else
        {
            // Distribute Taxes (Tokens)
            _balances[_devWallet] += _calcDevTaxAmount(amount);
            _balances[_marketingWallet] += _calcMarketingTaxAmount(amount);
            _balances[address(this)] += _calcLpTaxAmount(amount);
        }

        // Emit
        _taxlessTransfer(from, to, transfer_amount);
    }

    function _autoSwapTaxForEth(address from, address to, uint256 amount) private {
        uint256 autoswap_amount = calcAutoswapAmount(amount);

        if(autoswap_amount == 0)
        {
            return;
        }

        uint256 max_autoswap = getMaxAutoswap();

        if(autoswap_amount < max_autoswap)
        {
            // Take tokens from marketing and dev wallets
            uint256 max_extra_autoswap = max_autoswap-autoswap_amount;
            autoswap_amount += _takeTokensFromMarketingAndDevWallets(max_extra_autoswap);
        }
        else if(autoswap_amount > max_autoswap)
        {
            autoswap_amount = max_autoswap;
        }

        // Execute autoswap
        uint256 startingBalance = address(this).balance;
        _swapTokensForETH(autoswap_amount);
        uint256 ethCollected = address(this).balance - startingBalance;
        emit TaxesAutoswap(ethCollected);

        // Auto Liquidity (LP Tax)
        if(_lpTax > 0 && !isTaxExempt(from, to))
        {
            uint256 tax_amount = _calcTaxes(amount);
            uint256 lp_tokens = _calcLpTaxAmount(amount)/2;
            if(to == _uniswapV2PairAddress && from != _uniswapV2RouterAddress && from != _uniswapUniversalRouter)
            {
                uint256 lp_tax_eth = _calcTaxDistribution(ethCollected, _lpTax);
                if(!addLiquidity(lp_tokens, lp_tax_eth)) {
                    emit AutoLiquidityFailed(lp_tokens, lp_tax_eth, tax_amount, autoswap_amount, ethCollected);
                } else {
                    emit AutoLiquiditySuccess(lp_tokens, lp_tax_eth, tax_amount, autoswap_amount, ethCollected);
                }
            }
        }

        // Distribute Taxes (ETH)
        uint256 marketing_tax_eth = _calcTaxDistribution(ethCollected, _marketingTax);
        uint256 dev_tax_eth = _calcTaxDistribution(ethCollected, _devTax);

        if(marketing_tax_eth > 0) {
            sendEther(_marketingWallet, marketing_tax_eth);
        }

        if(dev_tax_eth > 0) {
            sendEther(_devWallet, dev_tax_eth);
        }
    }

    // Returns true if the conditions are met for an autoswap, otherwise returns false.
    function autoSwapConditionCheck(address from, address to, uint256 amount) public view returns (bool) {
        if(!_autoSwapTokens) {
            return false;
        }

        if(!isSell(from, to)) {
            return false;
        }

        if(_swapThreshold == 0) {
            return true;
        }

        uint256 swapThresholdAmountTokens = (getLiquidityIBIT() * _swapThreshold)/1000;
        if(autoswapTotalTokensAvailable(amount) >= swapThresholdAmountTokens) {
            return true;
        }

        return false;
    }

    function toggleSellFromTaxWallets(bool enable) public onlyOwner {
        _sellFromTaxWallets = enable;
    }

    function takeTokensFromTaxWallets(uint256 max_amount) public onlyOwner returns (uint256 amount_taken) {
        return _takeTokensFromMarketingAndDevWallets(max_amount);
    }

    // Try to take max_extra_autoswap from marketing and dev wallets
    function _takeTokensFromMarketingAndDevWallets(uint256 max_extra_autoswap) private returns (uint256 amount_taken) {
        if(_sellFromTaxWallets == false) {
            return 0;
        }

        // Don't take tokens unless there are at least 100K
        if(_balances[_marketingWallet] + _balances[_devWallet] < 10000000000000)
        {
            return 0;
        }

        uint256 extra_amount_taken = 0;

        if(_balances[_marketingWallet] >= max_extra_autoswap)
        {
            unchecked {
                _balances[_marketingWallet] -= max_extra_autoswap;
                _balances[address(this)] += max_extra_autoswap;
            }
            return max_extra_autoswap;
        }

        if(_balances[_devWallet] >= max_extra_autoswap)
        {
            unchecked {
                _balances[_devWallet] -= max_extra_autoswap;
                _balances[address(this)] += max_extra_autoswap;
            }
            return max_extra_autoswap;
        }

        extra_amount_taken = _balances[_devWallet];

        unchecked {
            _balances[_devWallet] = 0;
            _balances[address(this)] += extra_amount_taken;
        }

        if(extra_amount_taken >= max_extra_autoswap)
        {
            return max_extra_autoswap;
        }

        uint256 mwBalance;
        if(extra_amount_taken + _balances[_marketingWallet] <= max_extra_autoswap)
        {
            mwBalance = _balances[_marketingWallet];

            unchecked {
                _balances[address(this)] += mwBalance;
                _balances[_marketingWallet] = 0;
            }
            return extra_amount_taken + mwBalance;
        }

        uint256 left_to_take = max_extra_autoswap - amount_taken;
        if(_balances[_marketingWallet] >= left_to_take)
        {
            unchecked {
                _balances[_marketingWallet] -= left_to_take;
                _balances[address(this)] += left_to_take;
            }
            return max_extra_autoswap;
        }

        mwBalance = _balances[_marketingWallet];
        unchecked {
            _balances[_marketingWallet] = 0;
            _balances[address(this)] += mwBalance;
        }
        return extra_amount_taken + mwBalance;
    }

    function _calcTaxDistribution(uint256 eth_collected, uint256 tax_rate) private view returns(uint256 distribution_eth)
    {
        // Equivilent to (eth_collected * (tax_rate/totalTax))
        return (eth_collected * tax_rate) / totalTax();
    }

    function _calcLpTaxAmount(uint256 amount) private view returns(uint256 tax)
    {
        return (amount * _lpTax) / 1000;
    }
    function _calcDevTaxAmount(uint256 amount) private view returns(uint256 tax)
    {
        return (amount * _devTax) / 1000;
    }
    function _calcMarketingTaxAmount(uint256 amount) private view returns(uint256 tax)
    {
        return (amount * _marketingTax) / 1000;
    }

    // Given an amount, calculate the taxes which would be collected. Excludes LP tax.
    function _calcTaxes(uint256 amount) public view returns (uint256 tax_to_collect) {
        return _calcDevTaxAmount(amount) + _calcMarketingTaxAmount(amount) + _calcLpTaxAmount(amount);
    }

    // Taxes taxes as specified by 'tax_amount'
    function _takeTaxes(address from, uint256 tax_amount) private {
        if(tax_amount == 0 || totalTax() == 0)
        {
            return;
        }

        // Remove tokens from sender
    unchecked {
        _balances[from] -= tax_amount;
    }

        // Collect taxes
    unchecked {
        _balances[address(this)] += tax_amount;
    }
    }

    function _taxlessTransfer(address from, address to, uint256 amount) private {
    unchecked {
        _balances[from] -= amount;
        _balances[to] += amount;
    }
        emit Transfer(from, to, amount);
    }

    // Migrate from Legacy
    address[] _legacyHolders;
    mapping(address=>uint256) _legacyHoldersBalances;

    bool _holdersAirdropped = false;

    function setLegacyHolder(address _w, uint256 balance) private {
        if(_legacyHoldersBalances[_w] != 0) {
            return; // duplicate
        }

        if(balance == 0) {
            return;
        }

        _legacyHolders.push(_w);
        _legacyHoldersBalances[_w] = balance;
    }

    // Airdrop Legacy Holders
    function initialAirdrop() public onlyOwner {
        require(_holdersAirdropped == false, "IBIT: Holders can only be airdropped once");
        _holdersAirdropped = true;

        setLegacyBalancesFromSnapshot();

        for(uint i = 0; i < _legacyHolders.length; i++) {
            address to = _legacyHolders[i];
            uint256 balance = _legacyHoldersBalances[to];

            _taxlessTransfer(owner(), to, balance);
        }
    }

    function setLegacyBalancesFromSnapshot() private {

        // NULS Partnership
        // 0x649Fd8b99b1d61d8FE7A9C7eec86dcfF829633F0, 14210000100000000); // 142,100,001 IBIT
        _taxlessTransfer(owner(), _legacyMarketingWallet, 14210000100000000);

        // These wallets completed migration from legacy
        setLegacyHolder(0x89Abd93CaBa3657919674a663D55E1C185A4CA25, 5000000000000000); // 50,000,000 IBIT
        setLegacyHolder(0x2e9EdC685510F3B6B92B5aA8B14E66a18707F5aB, 5000000000000000); // 50,000,000 IBIT
        setLegacyHolder(0xDB1C0B51328D40c11ebE5C9C7098477B88551e8d, 2500000000000000); // 25,000,000 IBIT
        setLegacyHolder(0x52747Fd7866eF249b015bB99E95a3169B9eC4497, 10490511753749771); // 104,905,118 IBIT
        setLegacyHolder(0xb2C91Cf2Fd763F2cC4558ed3cEDE401Fc1d1B675, 4000000000000000); // 40,000,000 IBIT
        setLegacyHolder(0x2E64b76130819f30bE2df0A0740D990d706B9926, 9317247665468201); // 93,172,477 IBIT
        setLegacyHolder(0x1E69003E5267E945962ae38578a76222CA408584, 5000000000000000); // 50,000,000 IBIT
        setLegacyHolder(0x16F39f8ff59caead81bC680e6cd663069Eb978BE, 10100000000000000); // 101,000,000 IBIT
        setLegacyHolder(0x6d102206CB3F043E22A62B4b7ecC83b877f85d9A, 5001685678902763); // 50,016,857 IBIT
        setLegacyHolder(0xEC61A284Df18c4937B50880F70EB181d38fe86Bb, 1660752476400742); // 16,607,525 IBIT
        setLegacyHolder(0x4C999827Bc4b51fbd6911f066d8b82baaC286a9b, 3500000000000000); // 35,000,000 IBIT
        setLegacyHolder(0x5415672D7334F8d2798022242675829B16bf94db, 1441870099079523); // 14,418,701 IBIT
        setLegacyHolder(0xdF10d9688528b5b60957D1727a70A30450cE9604, 5000000000000000); // 50,000,000 IBIT
        setLegacyHolder(0x831114051c0edDe239ae672EdcC4c63371deC82b, 3869772286660397); // 38,697,723 IBIT
        setLegacyHolder(0x1d9c8Ae02d75db48dF0d13424cF7fb188dfa4B6E, 2112190583266945); // 21,121,906 IBIT
        setLegacyHolder(0x6e7182cFe90cC9AaD11f7082cC4c462dbFD2D73C, 1083000000000000); // 10,830,000 IBIT
        setLegacyHolder(0x287044c98a99F08764d681eD898aECb68A5543BC, 2320032256026266); // 23,200,323 IBIT
        setLegacyHolder(0x5159cD8087B040E3E5F95e1489ce1018E186795C, 2250000000000000); // 22,500,000 IBIT
        setLegacyHolder(0x5eD277Af83D32fa421091244Fa802e90FE8e896d, 5464909136753054); // 54,649,091 IBIT
        setLegacyHolder(0x7aBc57C6f67853D16a4400685d18eE53980A3F4F, 7697889041792168); // 76,978,890 IBIT
        setLegacyHolder(0x09b3a9Ea542713dcC182728F9DebBdfCB1a0112F, 5000000000000000); // 50,000,000 IBIT
        setLegacyHolder(0xF3598aD305Bbd8b40A480947e00a5dc3E29dC5a5, 4875000000000000); // 48,750,000 IBIT
        setLegacyHolder(0x2Aeda0568E111Da6A465bb735D912899A15015c2, 10782747817992883); // 107,827,478 IBIT
        setLegacyHolder(0xb578B5157Bcc9Fd2e73AcACf7E853FD9F861F55d, 2000000000000000); // 20,000,000 IBIT
        setLegacyHolder(0x16C73eaFAA9c6f915d9026D3C2d1b6E9407d2F73, 5159396904718724); // 51,593,969 IBIT
        setLegacyHolder(0x3140dD4B65C557Fda703B081C475CE4945EaaCa3, 5000000000000000); // 50,000,000 IBIT
        setLegacyHolder(0xe632450E74165110459fEf989bc11E90Ee9029D1, 9350739929318052); // 93,507,399 IBIT
        setLegacyHolder(0xF6E82162D8938D91b44EFd4C307DBa91EcBD6950, 2907543953360030); // 29,075,440 IBIT
        setLegacyHolder(0x33AF2064Be09C34302C4cA8B8529A0E659243016, 660000000000000); // 6,600,000 IBIT
        setLegacyHolder(0xAA9d9D742b5c915D65649C636fb2D485911ece4D, 1318142836424375); // 13,181,428 IBIT
        setLegacyHolder(0x5507F5a1076742e3299cE8199fEEd98079ECeE34, 2500000000000000); // 25,000,000 IBIT
        setLegacyHolder(0x5e75d35893200849889DD98a50fce78E3D5641F3, 3263084246964091); // 32,630,842 IBIT
        setLegacyHolder(0x0665d03bDDFd7bA36b1bDC7aDdB26C48273111c8, 500000000000000); // 5,000,000 IBIT
        setLegacyHolder(0x8A541f614A14B00366d92dCe6e927bF550f1c897, 5000000000000000); // 50,000,000 IBIT
        setLegacyHolder(0xC8aFB078896B5780bD7b7174429AF2DAff61199b, 6139352996536699); // 61,393,530 IBIT
        setLegacyHolder(0xffa25D69EF4909454825904904A2D876eA43E437, 2968750000000000); // 29,687,500 IBIT
        setLegacyHolder(0xCd0951939b77e22e497895820Ea7BD3AeF480E1C, 121526011734471); // 1,215,260 IBIT
        setLegacyHolder(0x1ca92Baf56A806527952Ebe610d06A66B54Bf5f1, 800000000000000); // 8,000,000 IBIT
        setLegacyHolder(0xa51670db54Edf9Dd5D5E3570f619FF46535E3679, 9500000000000); // 95,000 IBIT
        setLegacyHolder(0xdd30235DC68011F4de01A5c4059fC20145D5c874, 2509039665732949); // 25,090,397 IBIT
        setLegacyHolder(0x9161c6B026e65Ba6B583fE8F552FA26b6D39eA89, 1425000000000000); // 14,250,000 IBIT
        setLegacyHolder(0xDa85C4A66eBea97aa48a6e1741EC0E639fFe1783, 3138834219770145); // 31,388,342 IBIT
        setLegacyHolder(0xCEe85e997E80B724c69a1474a9489dBFA4cF5d2C, 484424921158839); // 4,844,249 IBIT
        setLegacyHolder(0x79D6F80D880f1bc1671b6fe3f88977D09eAe4DAA, 1814845856095380); // 18,148,459 IBIT
        setLegacyHolder(0x6D9e1352e1F8f66F96669CC28FDCfE8e7FCF5524, 3200000000000000); // 32,000,000 IBIT
        setLegacyHolder(0xA6e18D5F6b20dFA84d7d245bb656561f1f9aff69, 11246699192462885); // 112,466,992 IBIT
        setLegacyHolder(0x9d0D8E5e651Ab7d54Af5B0F655b3978504E67E0C, 11031132794975236); // 110,311,328 IBIT
        setLegacyHolder(0x141278EF1F894a60cBC8637871E4d19c3f2a7336, 5000000000000000); // 50,000,000 IBIT
        setLegacyHolder(0x8AefCE4e323DbB2eCD5818869acF90e5415559C5, 5000000000000000); // 50,000,000 IBIT
        setLegacyHolder(0x5ea0c07ADa402b67F1a9467d008EC11eD9Ca1127, 5000000000000000); // 50,000,000 IBIT
        setLegacyHolder(0x2B09aCED766f8290de1F5E4E0d3B3B8915C49189, 5000000000000000); // 50,000,000 IBIT
        setLegacyHolder(0xFb1BAD0Dc29a9a485F08F4FE6bFBFEdeba10ad8d, 12125000000000000); // 121,250,000 IBIT
        setLegacyHolder(0x56be74F547b1c3b01E97f87461E2f3C75902374A, 1124603943161942); // 11,246,039 IBIT
        setLegacyHolder(0x4A9381E176D676A07DD17A83d8BFd1287b342c77, 4810000000000000); // 48,100,000 IBIT
        setLegacyHolder(0xFCe082295b4db70097c4135Ca254B13B070800E7, 10000000000000000); // 100,000,000 IBIT
        setLegacyHolder(0x7ea69F87f9836FFc6797B6B2D045c11e0881b740, 5000000000000000); // 50,000,000 IBIT
        setLegacyHolder(0x1cC4A2522c3847687aF45AcdA2b5d6EbB64490A9, 402527671912807); // 4,025,277 IBIT
        setLegacyHolder(0x89E364598BDa1f96B6618EBE5D9879F070066358, 4750000000000000); // 47,500,000 IBIT

        // These wallets did not migrate. 50% penalty as decided by the community.
        setLegacyHolder(0x7FF0373F706E07eE326d538f6a6B2Cf8F7397e77, uint256(uint256(1250924993795650) / 2));
        setLegacyHolder(0x5F7425396747897F91b68149915826aFc2C14c16, uint256(uint256(1097767093335720) / 2));
        setLegacyHolder(0xa9b809Cfe8d95EdbDD61603Ba40081Ba6da4F24b, uint256(uint256(711944117144372) / 2));
        setLegacyHolder(0x817271eA29E0297D26e87c0fCae5d7086c06ae94, uint256(uint256(263389054436059) / 2));
        setLegacyHolder(0x15Cd32F5e9C286FaD0c6E6F40D1fc07c2c1a8584, uint256(uint256(130033069564332) / 2));
        setLegacyHolder(0x90a71A274Cf69c0AD430481241206cd8fec7a1ED, uint256(uint256(117107416670239) / 2));
        setLegacyHolder(0xC5DcAdf158Dc6DE2D6Bc1dDBB40Fb03572000D32, uint256(uint256(45488054291697) / 2));
    }
}