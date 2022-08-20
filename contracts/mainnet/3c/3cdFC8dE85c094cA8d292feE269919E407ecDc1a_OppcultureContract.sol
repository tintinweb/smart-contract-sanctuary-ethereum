/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

/*
    OPPCULTURE | CULT

    Refer to the smart contract's 'Read Contract' tab for additional information.
 */

// SPDX-License-Identifier: none

pragma solidity 0.6.12;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
interface IERC20XP {
    function Mint(address recipient, uint256 amount) external returns (bool);
}

interface ILottery {
    function autoBuyTickets(address sender, uint256 amount) external returns (bool);
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
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
 
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
 
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
 
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
 
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

////////////////////////////////
///////// Interfaces ///////////
////////////////////////////////
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
 
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
 
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
 
    function createPair(address tokenA, address tokenB) external returns (address pair);
 
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
 
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
 
 pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
 
    function addLiquidity( address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline ) external returns (uint amountA, uint amountB, uint liquidity); 
    function addLiquidityETH( address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external payable returns (uint amountToken, uint amountETH, uint liquidity); 
    function removeLiquidity( address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline ) external returns (uint amountA, uint amountB); 
    function removeLiquidityETH( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external returns (uint amountToken, uint amountETH); 
    function removeLiquidityWithPermit( address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns (uint amountA, uint amountB); 
    function removeLiquidityETHWithPermit( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns (uint amountToken, uint amountETH); 
    function swapExactTokensForTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external returns (uint[] memory amounts); 
    function swapTokensForExactTokens( uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline ) external returns (uint[] memory amounts); 
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts); 
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts); 
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts); 
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts); 
 
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external returns (uint amountETH); 
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns (uint amountETH); 
 
 
    function swapExactTokensForTokensSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external; 
    function swapExactETHForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path, address to, uint deadline ) external payable; 
    function swapExactTokensForETHSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external; 
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */

contract ERC20 is Context, IERC20, Ownable {
    using SafeMath for uint256;
 
    mapping (address => uint256) private _balances;
 
    mapping (address => mapping (address => uint256)) private _allowances;
 
    uint256 private _totalSupply;
 
    string private _name;
    string private _symbol;
    string private _description;
    string private _website;
    string private _legalDisclaimer;
    uint8 private _decimals;
    uint256 public TotalBurned = 0;

    mapping (address => string) private _tokenHolders;

    address public DistributorContract; //Sends to Treasury addresses 
 
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }
 
    function name() public view virtual returns (string memory) {
        return _name;
    }
 
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function Description() public view virtual returns (string memory) {
        return _description;
    }

    function Website() public view virtual returns (string memory) {
        return _website;
    }

    function LegalDisclaimer() public view virtual returns (string memory) {
        return _legalDisclaimer;
    }
 
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }
 
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
 
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function TokenHoldersName(address account) public view virtual returns (string memory) {
        return _tokenHolders[account];
    }
 
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
 
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function EditName(string memory Name) public onlyOwner {
        _name = Name;
    }
    function EditSymbol(string memory Symbol) public onlyOwner {
        _symbol = Symbol;
    }
    function EditDescription(string memory description) public onlyOwner {
       _description = description;
    }
    function EditWebsite(string memory website) public onlyOwner {
        _website = website;
    }
    function EditLegalDisclaimer(string memory legalDisclaimer) public onlyOwner {
        _legalDisclaimer = legalDisclaimer;
    }
    function EditTokenHolderName(string memory tokenHolderName) public {
        _tokenHolders[_msgSender()] = tokenHolderName;
    }
    function EditOtherTokenHolderName(address tokenHolderAddress, string memory tokenHolderName) public onlyOwner {
        _tokenHolders[tokenHolderAddress] = tokenHolderName;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
 
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
 
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
 
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
 
        _beforeTokenTransfer(sender, recipient, amount);
 
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
 
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
 
        _beforeTokenTransfer(address(0), account, amount);
 
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
 
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
 
        _beforeTokenTransfer(account, address(0), amount);
 
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        TotalBurned = TotalBurned.add(amount);
        emit Transfer(account, address(0), amount);
    }
 
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
 
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }
 
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub( amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

abstract contract ERC20Coinbase is Context, ERC20 {
    uint256 public StartTimeStamp = 0;
    uint256 private oneDay = 86400;

    constructor() internal {
        StartTimeStamp = block.timestamp;
    }
     
    function Emit() public {
        uint256 tokenCoinbase = (((block.timestamp.sub(StartTimeStamp)).div(oneDay)).add(1) * 10**uint256(18)).sub(totalSupply().add(TotalBurned));

        if (tokenCoinbase > 0) {
            _mint(DistributorContract, tokenCoinbase);
        }
    }  
}


contract OppcultureContract is ERC20, ERC20Burnable, ERC20Coinbase {
    string private NAME = "OPPCULTURE";
    string private SYMBOL = "CULT";
    uint256 private INITAL_SUPPLY = 1 * 10**uint256(18);
    
    mapping (address => bool) private isExcludedFromFees;
    mapping (address => bool) private isExcludedFromMaxWallet;
    mapping (address => bool) private automatedMarketMakerPairs;
    mapping (address => bool) private lotteryContracts;

    uint256[] public daily24hrVolumes = new uint256[](24);
    uint256 private lastTimestamp;

    address public OppcultureEquityContract = 0x14895D191C8c2BdE4c488BE84fdAe95339eabfa1;
    address public OppcultureXPContract = 0xaB75d34Fd25cEd43c2b5636Bc3c6397B9c83C629;
    uint256 public EquityHoldersCutoff = 10**uint256(18);
    uint256 public EquityHoldersDiscount = 50;
    uint256 public XPTradingRatio = 10**uint256(18);
    uint256 public MinimumVolumeToAdd = 10**uint256(15);

    uint256 public BuyFee = 0;
    uint256 public SellFee = 0;
    uint256 public BurnFee = 0;
    uint256[] public BuyFeesVolumeSchedule = [1000,100000,200000,300000,400000,500000,600000,700000,800000,900000,0];
    uint256[] public BuyFeesPercentSchedule = [100,50,40,30,20,10,9,8,7,6,5];
    uint256[] public SellFeesVolumeSchedule = [0,0,0,0,0,0];
    uint256[] public SellFeesPercentSchedule = [5,5,5,5,5,5];
    bool public IsVolumeScheduleOn = true;
    
    uint256 public SwapTokensAtPercent = 1; // 0.1% of Supply
    uint256 public MaxWalletPercent = 50;
    
    IUniswapV2Router02 public immutable uniV2Router;
    address public immutable uniV2Pair;
    
    bool inSwapAndLiquify;
    bool public SwapAndLiquifyEnabled = true;

    AggregatorV3Interface internal ethPriceFeed;

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() public ERC20(NAME, SYMBOL) { 
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Create a pair for this new token
        address _uniV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniV2Router = uniswapV2Router;
        uniV2Pair = _uniV2Pair;

        ethPriceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        lastTimestamp = block.timestamp;

        isExcludedFromFees[DistributorContract] = true;
        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[address(this)] = true;

        automatedMarketMakerPairs[_uniV2Pair] = true;
                        
        _mint(_msgSender(), INITAL_SUPPLY);
    }

    function getLatestETHPrice() public view returns (uint) { 
        (, int price ,,,) = ethPriceFeed.latestRoundData();
        return uint(price).div(10**uint256(6));
    }

    function DailyVolume() public view returns(uint256) {
        uint volume;
        for (uint i = 0; i < 24; i++) {
            volume = volume.add(daily24hrVolumes[i]);
        }
        return volume.div(10**uint256(18));
    }

    function change24hrVolumes(uint256 hour, uint256 amount) public onlyOwner {
            daily24hrVolumes[hour] = daily24hrVolumes[hour].add(amount);
    }

    function IsExcludedFromFees(address account) public view returns(bool) {
        return isExcludedFromFees[account];
    }
    function ExcludeFromFee(address account, bool value) public onlyOwner {
        isExcludedFromFees[account] = value;
    }
    function IsExcludedFromMaxWallet(address account) public view returns(bool) {
        return isExcludedFromMaxWallet[account];
    }
    function ExcludeFromMaxWallet(address account, bool value) public onlyOwner {
        isExcludedFromMaxWallet[account] = value;
    }
    function IsAutomatedMarketMakerPair(address account) public view returns(bool) {
        return automatedMarketMakerPairs[account];
    }
    function SetAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
        automatedMarketMakerPairs[pair] = value;
    }
    function IsLotteryContract(address account) public view returns(bool) {
        return lotteryContracts[account];
    }
    function SetLotteryContract(address account, bool value) public onlyOwner {
        lotteryContracts[account] = value;
    }

    function SetBuyFeePercent(uint256 percent) external onlyOwner() {
        BuyFee = percent;
    }
    function SetSellFeePercent(uint256 percent) external onlyOwner() {
        SellFee = percent;
    }
    function SetBurnFeePercent(uint256 percent) external onlyOwner() {
        BurnFee = percent;
    }
    function SetMaxWalletPercent(uint256 percent) external onlyOwner() {
        MaxWalletPercent = percent;
    }
    function SetSwapTokensAtPercent(uint256 percent) external onlyOwner() {
        SwapTokensAtPercent = percent;
    }

    function SetVolumeScheduleState(bool state) external onlyOwner() {
        IsVolumeScheduleOn = state;
    }

    function SetVolumeSchedule(uint256[] memory buyVolumes, uint256[] memory buyFees, uint256[] memory sellVolumes, uint256[] memory sellFees) external onlyOwner() {
        require(buyVolumes.length == buyFees.length && sellVolumes.length == sellFees.length, "Pairs must be same length.");

        BuyFeesVolumeSchedule = buyVolumes;
        BuyFeesPercentSchedule = buyFees;
        SellFeesVolumeSchedule = sellVolumes;
        SellFeesPercentSchedule = sellFees;
    }
    
    function SetEquityHoldersCutoff(uint256 percent, uint256 numDecimals) external onlyOwner() {
        EquityHoldersCutoff = (100 * 10**uint256(18) * percent).div(10**(uint256(numDecimals) + 2));
    }
    function SetEquityHoldersDiscountPercent(uint256 percent) external onlyOwner() {
        EquityHoldersDiscount = percent;
    }
    function SetOppcultureEquityContract(address oppcultureEquityContract) external onlyOwner() {
        OppcultureEquityContract = oppcultureEquityContract;
    }
    function SetOppcultureXPContract(address oppcultureXPContract) external onlyOwner() {
        OppcultureXPContract = oppcultureXPContract;
    }
    function SetXPTradingRatio(uint256 ratio) external onlyOwner() {
        XPTradingRatio = ratio;
    }
    function SetMinimumVolumeToAdd(uint256 percent, uint256 numDecimals) external onlyOwner() {
        MinimumVolumeToAdd = totalSupply().mul(percent).div(10**(uint256(numDecimals) + 2));
    }

    function SetDistributorContract(address distributorContract) external onlyOwner() {
        DistributorContract = distributorContract;
        isExcludedFromFees[distributorContract] = true;
        isExcludedFromMaxWallet[distributorContract] = true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (!isExcludedFromMaxWallet[recipient] && sender != owner() && recipient != owner() && recipient != address(1) && !automatedMarketMakerPairs[recipient]) {
            require(balanceOf(recipient).add(amount) <= totalSupply().mul(MaxWalletPercent).div(1000), "Exceeds maximum wallet token amount.");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= totalSupply().mul(SwapTokensAtPercent).div(1000);
        if (overMinimumTokenBalance && !inSwapAndLiquify && !automatedMarketMakerPairs[sender] && SwapAndLiquifyEnabled) {
            swapTokensForETH(contractTokenBalance);
        }

        bool excludedAccount = isExcludedFromFees[sender] || isExcludedFromFees[recipient];

        if(!excludedAccount && (automatedMarketMakerPairs[sender] || automatedMarketMakerPairs[recipient])) {
        	uint256 fees;

            if (IsVolumeScheduleOn)
                calculateFeesBasedOnVolume();

            if (automatedMarketMakerPairs[sender]) {
                fees = amount.div(1000).mul(BuyFee);
                addTradeVolumes(amount, recipient);
            } else if (automatedMarketMakerPairs[recipient]) {
                fees = amount.div(1000).mul(SellFee);
                addTradeVolumes(amount, sender);
            }

            if (IERC20(OppcultureEquityContract).balanceOf(sender) >= EquityHoldersCutoff || IERC20(OppcultureEquityContract).balanceOf(recipient) >= EquityHoldersCutoff)
                fees = fees.div(100).mul(EquityHoldersDiscount);

        	amount = amount.sub(fees);

            uint256 burnAmount = fees.div(1000).mul(BurnFee);
            if (BurnFee != 0)
                super._burn(sender, burnAmount);

            if (fees != 0)
                super._transfer(sender, address(this), fees.sub(burnAmount));
        }
        if (lotteryContracts[recipient])
            ILottery(recipient).autoBuyTickets(sender, amount);
        
        super._transfer(sender, recipient, amount);
        Emit();
    }

    function addTradeVolumes(uint256 amount, address adr) private {
        if (amount >= MinimumVolumeToAdd) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = uniV2Router.WETH();
            amount = uniV2Router.getAmountsOut(amount, path)[1].mul(getLatestETHPrice()).div(10**uint256(2)); //USD amount

            IERC20XP(OppcultureXPContract).Mint(adr, (amount.mul(XPTradingRatio)).div(10**uint256(18))); //Mint XP tokens based on volume.

            if (IsVolumeScheduleOn) {
                uint256 hour = block.timestamp.mod(86400).div(3600);
                hour = hour == 24 ? 0 : hour;

                daily24hrVolumes[hour] = daily24hrVolumes[hour].add(amount);
                lastTimestamp = block.timestamp;
            }
        }
    }

    function updateTradeVolume() public {
        uint256 hour = block.timestamp.mod(86400).div(3600);
        uint256 previousHour = lastTimestamp.mod(86400).div(3600);
        uint256 timeSince = block.timestamp.sub(lastTimestamp);

        if (timeSince >= 86400 || (timeSince >= 82800 && hour == previousHour)) {    // erase if over a day
            for (uint i = 0; i <= 23; i++)
                daily24hrVolumes[i] = 0;
        } else if (hour != previousHour) {
            if (previousHour > hour) {
                for (uint i = previousHour+1; i <= 23; i++)
                    daily24hrVolumes[i] = 0;
                for (uint i = 0; i <= hour; i++)
                    daily24hrVolumes[i] = 0;
            } else {
                for (uint i = previousHour+1; i <= hour; i++)
                    daily24hrVolumes[i] = 0;
            }
        }
    }

    function calculateFeesBasedOnVolume() private {
        updateTradeVolume();
        uint dailyVolume = DailyVolume();
        
        for (uint i = 0; i < BuyFeesVolumeSchedule.length; i++) {
            if (dailyVolume < BuyFeesVolumeSchedule[i] || BuyFeesVolumeSchedule[i] == 0) {
                BuyFee = BuyFeesPercentSchedule[i];
                break;
            }
        }
        for (uint i = 0; i < SellFeesVolumeSchedule.length; i++) {
            if (dailyVolume < SellFeesVolumeSchedule[i] || SellFeesVolumeSchedule[i] == 0) {
                SellFee = SellFeesPercentSchedule[i];
                break;
            }
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniV2Router.WETH();
 
        _approve(address(this), address(uniV2Router), tokenAmount);
 
        // make the swap
        uniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            DistributorContract,
            block.timestamp
        );
    }

    receive() external payable {}
}