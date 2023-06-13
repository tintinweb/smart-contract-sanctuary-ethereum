/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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

    function _revert(
        bytes memory returndata,
        string memory errorMessage
    ) private pure {
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
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
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

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

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
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

contract NBA is Context, IERC20, Ownable {
    using Address for address;
    //Contract Update Information
    string public constant contractVersion = "3.3";
    string public constant contractDev = "CFG";
    string public constant contractEdition = "Factory";
    //Definition of Wallets for Marketing or team.
    address payable public marketingWallet =
        payable(0x0E91DDbf6b8c713A3c2053dEd510cE9239352E85);
    //adding customer wallet to send supply and exclude from fees.
    address payable public safuWallet =
        payable(0x9882d8183408632200663196e450186984b58Dff);

    //Dead Wallet for SAFU Contract
    address public constant deadWallet =
        0x000000000000000000000000000000000000dEaD;
    //Mapping section for better tracking.
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    //Loging and Event Information for better troubleshooting.
    event Log(string, uint256);
    event AuditLog(string, address);
    event RewardLiquidityProviders(uint256 tokenAmount);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SwapTokensForETH(uint256 amountIn, address[] path);
    //Supply Definition.
    uint256 private _tTotal = 800_000_0000 ether;
    uint256 private _tFeeTotal;
    //Token Definition.
    string public constant name = "Never Broke Again";
    string public constant symbol = "$NBA";
    uint8 public constant decimals = 18;
    //Taxes Definition.
    uint public buyFee = 8;

    uint256 public sellFee = 8;

    uint256 public marketingTokensCollected = 0;
    uint256 public totalMarketingTokensCollected = 0;

    uint256 public minimumTokensBeforeSwap = 100_000 ether;

    //Oracle Price Update, Manual Process.
    uint256 public swapOutput = 0;
        //Trading Controls added for SAFU Requirements
    bool public tradingEnabled;
    //Router and Pair Configuration.
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address private immutable WETH;
    //Tracking of Automatic Swap vs Manual Swap.
    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
//What is my router and exclude pinksale locker.
        address currentRouter;
        //Adding Variables for all the routers for easier deployment for our customers.
        if (block.chainid == 56) {
            currentRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // PCS Router
            _isExcludedFromFee[0x407993575c91ce7643a4d4cCACc9A98c36eE1BBE] = true;
        } else if (block.chainid == 97) {
            currentRouter = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // PCS Testnet
            _isExcludedFromFee[0x5E5b9bE5fd939c578ABE5800a90C566eeEbA44a5] = true;
            safuWallet = payable(0x4c4DAFf8A144213896db1dD85730163d17EB6afe);
        } else if (block.chainid == 43114) {
            currentRouter = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4; //Avax Mainnet
            _isExcludedFromFee[0x9479C6484a392113bB829A15E7c9E033C9e70D30] = true;
        } else if (block.chainid == 42161) {
            currentRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; //Arbitrum Sushi
            _isExcludedFromFee[0xeBb415084Ce323338CFD3174162964CC23753dFD] = true;
        } else if (block.chainid == 1 || block.chainid == 5) {
            currentRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //Mainnet
            _isExcludedFromFee[0x71B5759d73262FBb223956913ecF4ecC51057641] = true;
        } else {
            revert("You're not Blade");
        }

        //End of Router Variables.
        //Owner of balance
        _tOwned[safuWallet] = _tTotal;
        //Create Pair in the contructor, this may fail on some blockchains and can be done in a separate line if needed.
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(currentRouter);
        WETH = _uniswapV2Router.WETH();
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), WETH);
        uniswapV2Router = _uniswapV2Router;
        //Approve router to be used.
        _approve(msg.sender, address(uniswapV2Router), type(uint256).max);
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        //Exclude from fees the owner, contract and SAFU.
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[safuWallet] = true;


        emit Transfer(address(0), safuWallet, _tTotal);
        _transferOwnership(safuWallet);
    }

    //Readable Functions.
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    //ERC 20 Standard Transfer Functions
    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    //ERC 20 Standard Allowance Function
    function allowance(
        address _owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    //ERC 20 Standard Approve Function
    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    //ERC 20 Standard Transfer From
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    //ERC 20 Standard increase Allowance
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    //ERC 20 Standard decrease Allowance
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - subtractedValue
        );
        return true;
    }

    //Approve Function
    function _approve(address _owner, address spender, uint256 amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    //Transfer function, validate correct wallet structure, take fees, and other custom taxes are done during the transfer.
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            _tOwned[from] >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        //Enable Trade after sale is finilized
        require(tradingEnabled || _isExcludedFromFee[from] || _isExcludedFromFee[to], "Trading not yet enabled!");

        //Adding logic for automatic swap.
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >=
            minimumTokensBeforeSwap;
        uint fee = 0;
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            overMinimumTokenBalance &&
            swapAndLiquifyEnabled
        ) {
            swapAndLiquify();
        }
        if (to == uniswapV2Pair && !_isExcludedFromFee[from]) {
            fee = (sellFee * amount) / 100;
        }
        if (from == uniswapV2Pair && !_isExcludedFromFee[to]) {
            fee = (buyFee * amount) / 100;
        }
        amount -= fee;
        if (fee > 0) {
            _tokenTransfer(from, address(this), fee);
            marketingTokensCollected += fee;
            totalMarketingTokensCollected += fee;
        }
        _tokenTransfer(from, to, amount);
    }

    //Swap Tokens for BNB or to add liquidity either automatically or manual, by default this is set to manual.
    //Corrected newBalance bug, it sending bnb to wallet and any remaining is on contract and can be recoverred.
    function swapAndLiquify() public lockTheSwap {
        uint256 totalTokens = balanceOf(address(this));
        swapTokensForEth(totalTokens);
        uint ethBalance = address(this).balance;

        transferToAddressETH(marketingWallet, ethBalance);

        marketingTokensCollected = 0;
    }

    //swap for eth is to support the converstion of tokens to weth during swapandliquify this is a supporting function
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
    }

    //ERC 20 standard transfer, only added if taking fees to countup the amount of fees for better tracking and split purpose.
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _tOwned[sender] -= amount;
        _tOwned[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    //exclude wallets from fees, this is needed for launch or other contracts.
    function excludeFromFee(address account) external onlyOwner {
        require(_isExcludedFromFee[account] != true, "The wallet is already excluded!");
        _isExcludedFromFee[account] = true;
        emit AuditLog(
            "We have excluded the following walled in fees:",
            account
        );
    }

    //include wallet back in fees.
    function includeInFee(address account) external onlyOwner {
        require(_isExcludedFromFee[account] != false, "The wallet is already included!");
        _isExcludedFromFee[account] = false;
        emit AuditLog(
            "We have including the following walled in fees:",
            account
        );
    }

    //Automatic Swap Configuration.
    function setTokensToSwap(
        uint256 _minimumTokensBeforeSwap
    ) external onlyOwner {
        require(
            _minimumTokensBeforeSwap >= 100 ether,
            "You need to enter more than 100 tokens."
        );
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
        emit Log(
            "We have updated minimunTokensBeforeSwap to:",
            minimumTokensBeforeSwap
        );
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        require(swapAndLiquifyEnabled != _enabled, "Value already set");
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    //set a new marketing wallet.
    function setMarketingWallet(address _marketingWallet) external onlyOwner {
        require(_marketingWallet != address(0), "setmarketingWallet: ZERO");
        marketingWallet = payable(_marketingWallet);
        emit AuditLog("We have Updated the MarketingWallet:", marketingWallet);
    }

    function setBuyFee(uint256 _buyFee) external onlyOwner {
        require(_buyFee <= 10, "Buy Fee cannot be more than 10%");
        buyFee = _buyFee;
        emit Log("We have updated the buy fee to:", buyFee);
    }

    function setSellFee(uint256 _sellFee) external onlyOwner {
        require(_sellFee <= 10, "Sell Fee cannot be more than 10%");
        sellFee = _sellFee;
        emit Log("We have updated the sell fee to:", sellFee);
    }

    function transferToAddressETH(
        address payable recipient,
        uint256 amount
    ) private {
        (bool succ, ) = recipient.call{value: amount}("");
        require(succ, "Transfer failed.");
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    /////---fallback--////
    //This cannot be removed as is a fallback to the swapAndLiquify
    event SwapETHForTokens(uint256 amountIn, address[] path);

    function swapETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);
        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(
            swapOutput, // accept any amount of Tokens
            path,
            deadWallet, // Burn address
            block.timestamp + 300
        );
        emit SwapETHForTokens(amount, path);
    }

    // Withdraw ETH that's potentially stuck in the Contract
    function recoverETHfromContract() external onlyOwner {
        uint ethBalance = address(this).balance;
        (bool succ, ) = payable(marketingWallet).call{value: ethBalance}("");
        require(succ, "Transfer failed");
        emit AuditLog(
            "We have recover the stuck eth from contract.",
            marketingWallet
        );
    }

    // Withdraw ERC20 tokens that are potentially stuck in Contract
    function recoverTokensFromContract(
        address _tokenAddress,
        uint256 _amount
    ) external onlyOwner {
        require(
            _tokenAddress != address(this),
            "Owner can't claim contract's balance of its own tokens"
        );
        bool succ = IERC20(_tokenAddress).transfer(marketingWallet, _amount);
        require(succ, "Transfer failed");
        emit Log("We have recovered tokens from contract:", _amount);
    }
        //Trading Controls for SAFU Contract
        function enableTrading() external onlyOwner{
        require(!tradingEnabled, "Trading already enabled.");
        tradingEnabled = true;
        swapAndLiquifyEnabled = true;
        emit AuditLog("We have Enable Trading and Automatic Swaps:", msg.sender);
    }
    //Updated code to enable swapAndLiquify at the time of enable trade.
}