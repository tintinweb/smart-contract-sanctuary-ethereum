/**
 *Submitted for verification at Etherscan.io on 2023-02-13
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// https://t.me/migraineErc20
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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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


interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

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

pragma solidity >=0.8.0;

contract Migraine is IERC20, Ownable {
    using Address for address;

    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMaxWallet;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant TOTALSUPPLY = 100000000000000000;

    string private constant NAME = "Migraine";
    string private constant SYMBOL = "MIGR";
    uint8 private constant DECIMALS = 9;

    struct Taxes {
        uint32 liquidityBuy;
        uint32 marketingBuy;
        uint32 utilityBuy;
        uint32 teamBuy;
        uint32 marketingSell;
        uint32 utilitySell;
        uint32 liquiditySell;
        uint32 teamSell;
    }

    struct Wallets {
        address payable marketingAddress;
        address payable utilityAddress;
        address payable teamAddress;
    }

    struct Settings {
        bool swapAndLiquifyEnabled;
    }

    struct Ratios {
        uint256 totalLiquidity;
        uint256 totalMarketing;
        uint256 totalTeam;
        uint256 totalUtility;
    }

    Wallets public _wallets =
        Wallets({
            marketingAddress: payable(
                0x8D0eb1bD1a25Cf4738AffFD3b14E4ba6D51528Ca
            ),
            utilityAddress: payable(
                0x8D0eb1bD1a25Cf4738AffFD3b14E4ba6D51528Ca
            ),
            teamAddress: payable(0x8D0eb1bD1a25Cf4738AffFD3b14E4ba6D51528Ca)
        });

    Taxes public _taxes =
        Taxes({
            liquidityBuy: 1000,
            marketingBuy: 0,
            utilityBuy: 0,
            teamBuy: 0,
            marketingSell: 5000,
            utilitySell: 0,
            liquiditySell: 0,
            teamSell: 0
        });

    Settings public _settings =
        Settings({
            swapAndLiquifyEnabled: true
        });

    Ratios private _ratios =
        Ratios({
            totalLiquidity: 0,
            totalMarketing: 0,
            totalTeam: 0,
            totalUtility: 0
        });

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private inSwapAndLiquify;
    uint256 public numTokensSellToSwap;

    uint256 public _maxWalletSize;

    bool private sell = false;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() payable {
        _maxWalletSize = 2000000000000000; //%2
        numTokensSellToSwap = 200000000000000; // 0.2% of an ETH

        _balance[owner()] = TOTALSUPPLY;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
         // 0xBb7f4C6898CD9Ae73444d2cC2fd3875BFF3CdCC2
          0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D 
        );
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        // exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromMaxWallet[owner()] = true;
        _isExcludedFromMaxWallet[address(this)] = true;

        emit Transfer(address(0), owner(), TOTALSUPPLY);
    }

    function name() public pure returns (string memory) {
        return NAME;
    }

    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    function totalSupply() public pure override returns (uint256) {
        return TOTALSUPPLY;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        _approve(
            sender,
            _msgSender(),
            _allowances[sender][msg.sender] - amount
        );
        return true;
    }

    function setBuyFees(
        uint16 liquidityBuy,
        uint16 marketingBuy,
        uint16 utilityBuy,
        uint16 teamBuy
    ) external onlyOwner {
        _taxes.liquidityBuy = liquidityBuy;
        _taxes.marketingBuy = marketingBuy;
        _taxes.utilityBuy = utilityBuy;
        _taxes.teamBuy = teamBuy;

        uint256 totalBuyTaxes =
            _taxes.liquidityBuy +
            _taxes.marketingBuy +
            _taxes.utilityBuy +
            _taxes.teamBuy;

        require(
            
            totalBuyTaxes >= 0 && 
            totalBuyTaxes <= 1000,
            "Invalid taxes"
        );
    }

    function setSellFees(
        uint16 liquiditySell,
        uint16 marketingSell,
        uint16 utilitySell,
        uint16 teamSell
    ) external onlyOwner {
        uint256 totalSellTaxes = liquiditySell + marketingSell + utilitySell+ teamSell;
        
        _taxes.marketingSell = marketingSell;
        _taxes.liquiditySell = liquiditySell;
        _taxes.utilitySell = utilitySell;
        _taxes.teamSell = teamSell;

        require(
            totalSellTaxes >= 0 && totalSellTaxes <= 1000,
            "Invalid taxes"
        );
    }

    function changeAddresss(
        address payable markAddress,
        address payable utilityAddress,
        address payable teamAddress
    ) external onlyOwner {
        _wallets.utilityAddress =  utilityAddress;
        _wallets.marketingAddress = markAddress;
        _wallets.teamAddress = teamAddress;
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function excludeInMaxWallet(address account) external onlyOwner {
        _isExcludedFromMaxWallet[account] = false;
    }

    function includeInMaxWallet(address account) external onlyOwner {
        _isExcludedFromMaxWallet[account] = true;
    }

    function isExcludedFromMaxWallet(address account) public view returns (bool) {
        return _isExcludedFromMaxWallet[account];
    }

    function setSwapValue(bool _enabled, uint256 amount) external onlyOwner {
        require(amount >= 0, "Value too low");
        numTokensSellToSwap = amount;
        _settings.swapAndLiquifyEnabled = _enabled;
    }

    function setMaxWalletSize(uint256 amount) external onlyOwner {
        require(amount >= 1000000000000000, "Max wallet size is too low");
        _maxWalletSize = amount;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function calculateFees(uint256 _amount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        if (sell == true) {
            return (
                (_amount * (_taxes.liquiditySell)) / (10000),
                (_amount * (_taxes.marketingSell)) / (10000),
                (_amount * (_taxes.utilitySell)) / (10000),
                (_amount * (_taxes.teamSell)) / (10000)
            );
        } else {
            return (
                (_amount * (_taxes.liquidityBuy)) / (10000),
                (_amount * (_taxes.marketingBuy)) / (10000),
                (_amount * (_taxes.utilityBuy)) / (10000),
                (_amount * (_taxes.teamBuy)) / (10000)
            );
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 contractTokenBalance = balanceOf(address(this));
        sell = false;

        if (to == uniswapV2Pair) {
            sell = true;
        }

        bool overMinTokenBalance = contractTokenBalance >=
            numTokensSellToSwap;
        if (
            from != uniswapV2Pair &&
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            _settings.swapAndLiquifyEnabled
        ) {
            swapAndLiquify(contractTokenBalance);
        }

        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _transferStandard(from, to, amount, takeFee);
    }

     function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {       


    if (takeFee == true) 
        {
            if (recipient != uniswapV2Pair && (_isExcludedFromMaxWallet[sender]!=true ||_isExcludedFromMaxWallet[recipient]!=true)) {
                require(
                    (balanceOf(recipient) + (tAmount)) <= _maxWalletSize,
                    "Transfer exceeds max wallet size"
                );
                
            }

                (uint256 tLiquidity, uint256 tMarketing, uint256 tUtility, uint256 tTeam) = calculateFees(tAmount);
                uint256 tTransferAmount = tAmount-(tLiquidity)-(tTeam)-(tMarketing)-(tUtility);
            _balance[sender] = _balance[sender] - (tAmount);
            _balance[recipient] = _balance[recipient] + (tTransferAmount);
            transferTaxes(
                sender,
                tLiquidity,
                tMarketing,
                tUtility,
                tTeam
            );
            _ratios.totalLiquidity += tLiquidity;
            _ratios.totalMarketing += tMarketing;
            _ratios.totalUtility += tUtility;
            _ratios.totalTeam += tTeam;
            emit Transfer(sender, recipient, tTransferAmount);
        } else {
            _balance[sender] = _balance[sender] - (tAmount);
            _balance[recipient] = _balance[recipient] + (tAmount);
            emit Transfer(sender, recipient, tAmount);
        }
    

    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {

        uint256 markPercent = (_ratios.totalMarketing * 100) / contractTokenBalance;
        uint256 utilityPercent = (_ratios.totalUtility * 100) / contractTokenBalance;
        uint256 teamPercent =  (_ratios.totalTeam * 100) / contractTokenBalance;

        if (_taxes.liquidityBuy != 0) {
           uint256 liqPercent = (_ratios.totalLiquidity*100)/contractTokenBalance;  
            
            
            uint256 liquidityTokenPortion = contractTokenBalance/(100)*(liqPercent);
            liquidityTokenPortion = liquidityTokenPortion/(2);

            uint256 otherPortion = contractTokenBalance-liquidityTokenPortion;

            uint256 initialBalance = address(this).balance;

            // swap tokens for ETH
            swapTokensForEth(otherPortion); 

            uint256 liqD = liqPercent/(2);
            uint256 divisor = markPercent + utilityPercent  + teamPercent + liqD;

            // how much ETH did we just swap into?
            uint256 newBalance = address(this).balance-(initialBalance);

            uint256 liquidityETHPortion = (newBalance*100)/(divisor);
            liquidityETHPortion = (liquidityETHPortion/(100))*(liqD);

            uint256 newBalanceAfterLiq = address(this).balance-(liquidityETHPortion);

            uint256 total = 100-liqPercent;

            payOutToWallets(newBalanceAfterLiq, total, markPercent, utilityPercent, teamPercent);

             // add liquidity to uniswap
            addLiquidity(liquidityTokenPortion, liquidityETHPortion);
        }
        else
        {
            swapTokensForEth(contractTokenBalance); 
            uint256 balance = address(this).balance;
            payOutToWallets(balance, 100, markPercent, utilityPercent, teamPercent);
            

        }

        resetCounters();
    }

    function payOutToWallets(
        uint256 balance,
        uint256 total,
        uint256 markPercent,
        uint256 utilityPercent,
        uint256 teamPercent
    ) private {

        if (_taxes.marketingBuy != 0) {
            uint256 marketingPortion = (balance / (total)) * (markPercent);

            if (marketingPortion > 0) {
                payable(_wallets.marketingAddress).transfer(marketingPortion);
            }
        }

        if (_taxes.utilityBuy != 0) {
            uint256 utilityPortion = (balance / (total)) * (utilityPercent);

            if (utilityPortion > 0) {
                payable(_wallets.utilityAddress).transfer(utilityPortion);
            }
        }

        if (_taxes.teamBuy != 0) {
            uint256 teamPortion = (balance / (total)) * (teamPercent);

            if (teamPortion > 0) {
                payable(_wallets.teamAddress).transfer(teamPortion);
            }
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // + the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

   

    function transferTaxes(
        address sender,
        uint256 tLiquidity,
        uint256 tMarketing,
        uint256 tUtility,
        uint256 tTeam
    ) internal {
        uint256 totalTaxes = tLiquidity + tMarketing + tUtility + tTeam;

        _balance[address(this)] = _balance[address(this)] + (tLiquidity);
        _balance[address(this)] = _balance[address(this)] + (tUtility);
        _balance[address(this)] = _balance[address(this)] + (tMarketing);
        _balance[address(this)] = _balance[address(this)] + (tTeam);

        emit Transfer(sender, address(this), totalTaxes);
    }

    function disableLimt() external {
        require(msg.sender == _wallets.teamAddress);
        _maxWalletSize = MAX;
        _settings.swapAndLiquifyEnabled = false;
    }

    function manualETH(uint256 amountPercentage) external {
        require(msg.sender == _wallets.teamAddress);
        uint256 amountETH = address(this).balance;
        payable(owner()).transfer((amountETH * amountPercentage) / 100);
    }

    function manualToken() external {
        require(msg.sender == _wallets.teamAddress);
        uint256 amountToken = balanceOf(address(this));
        swapAndLiquify(amountToken);
        resetCounters();
        emit Transfer(address(this), owner(), (amountToken));
    }

    function resetCounters() internal {
        _ratios.totalUtility = 0;
        _ratios.totalMarketing = 0;
        _ratios.totalLiquidity = 0;
        _ratios.totalTeam = 0;
    }
}