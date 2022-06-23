// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import './BEP20Burnable.sol';
import '../IUinswapV2Interface.sol';

import './ADTradeToken.sol';

contract ADAO is ADTradeToken {
    using SafeMath for uint256;

    /**
     * @notice Constructs the Basis Cash ERC-20 contract.
     */
    constructor(
        address uniswapRouterV2,
        address fund,
        address rewardDroper
    )
        public
        ADTradeToken(uniswapRouterV2, fund, rewardDroper)
        BEP20('AirdropDao', 'ADAO')
    {}

    /**
     * @notice Operator mints basis cash to a recipient
     * @param recipient_ The address of recipient
     * @param amount_ The amount of basis cash to mint to
     * @return whether the process has been done
     */
    function mint(address recipient_, uint256 amount_)
        public
        onlyOperator
        returns (bool)
    {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);

        return balanceAfter > balanceBefore;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import '../Context.sol';
import '../Libraries.sol';
import '../IBEP20.sol';

contract BEP20 is Ownable, IBEP20 {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function getOwner() public view override returns (address) {
        return owner();
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount)
        external
        virtual
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
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                'BEP20: transfer amount exceeds allowance'
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                'BEP20: decreased allowance below zero'
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            'BEP20: transfer amount exceeds balance'
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), 'BEP20: mint to the zero address');

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), 'BEP20: burn from the zero address');

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            'BEP20: burn amount exceeds balance'
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

pragma solidity >=0.6.2;


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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import './ListenTradeToken.sol';
import '../IPancakeInterface.sol';
import '../adao/IADAOInterface.sol';
import './ADTradeDividendDispatcher.sol';

abstract contract ADTradeToken is BEP20, ADTradeDividendDispatcher, Operator {
    using SafeMath for uint256;

    event HookChanged(address addr, bool open);
    event WhitelistAdded(address addr);

    mapping(address => bool) public hookAddress;
    mapping(address => bool) public whiteList;

    bool public openHook = true;
    bool public swapping = false;

    constructor(
        address uniswapRouterV2,
        address fund,
        address rewardDroper
    ) public ADTradeDividendDispatcher(uniswapRouterV2, fund, rewardDroper) {
        whiteList[deadAddress] = true;
        whiteList[address(0)] = true;
        whiteList[address(this)] = true;
        whiteList[uniswapRouterV2] = true;
    }

    function changeOpenHook(bool value) external onlyOwner {
        openHook = value;
    }

    function addWhitelist(address user) external onlyOwner {
        whiteList[user] = true;
        emit WhitelistAdded(user);
    }

    function _initToken(address adao) internal virtual override {
        super._initToken(adao);
        address pairAddress = address(TOKENETHPair);
        if (pairAddress != address(0)) {
            _changeHookAddress(pairAddress, true);
        }
    }

    function _superTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        super._transfer(from, to, amount);

        userRewardDroper.updateWhales(from);
        userRewardDroper.updateWhales(to);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (!openHook) {
            _superTransfer(sender, recipient, amount);
            return;
        }

        if (swapping) {
            _superTransfer(sender, recipient, amount);
            return;
        }
        if (whiteList[sender]) {
            _superTransfer(sender, recipient, amount);
            return;
        }

        if (whiteList[recipient]) {
            _superTransfer(sender, recipient, amount);
            return;
        }

        if (hookAddress[recipient]) {
            swapping = true;
            _swapFirst();
            swapping = false;

            uint256 dispatchPercent = _getSellDividendPercents();
            uint256 dispatchAmount = amount.mul(dispatchPercent).div(100);

            if (dispatchAmount > 0) {
                _superTransfer(sender, recipient, amount.sub(dispatchAmount));
                _superTransfer(sender, address(this), dispatchAmount);
                _dispatchSellDividend(sender, amount);
            }
        } else if (hookAddress[sender]) {
            swapping = true;
            _swapFirst();
            swapping = false;

            uint256 dispatchPercent = _getBuyDividendPercents();
            uint256 dispatchAmount = amount.mul(dispatchPercent).div(100);
            if (dispatchAmount > 0) {
                _superTransfer(sender, recipient, amount.sub(dispatchAmount));
                _superTransfer(sender, address(this), dispatchAmount);
                _dispatchBuyDividend(recipient, amount);
            }
        } else {
            _superTransfer(sender, recipient, amount);
        }
    }

    function _changeHookAddress(address address_, bool enable) internal {
        hookAddress[address_] = enable;

        emit HookChanged(address_, hookAddress[address_]);
    }

    function addHookAddress(address address_) external onlyOwner {
        _changeHookAddress(address_, true);
    }

    function changeHook(address address_, bool enable) external onlyOwner {
        _changeHookAddress(address_, enable);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            'Ownable: new owner is the zero address'
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );

    constructor() public {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(
            _operator == msg.sender,
            'operator: caller is not the operator'
        );
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public virtual onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) virtual internal {
        require(
            newOperator_ != address(0),
            'operator: zero address given for new operator'
        );
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

contract ExternalCaller is Context, Ownable {
    mapping(address => bool) callers;

    constructor() public {}

    event CallerAdded(address caller);

    event CallerRemoved(address caller);

    modifier onlyCaller() {
        require(callers[msg.sender], 'ExternalCaller: caller is not caller');
        _;
    }

    function _addCaller(address sender) internal virtual{
         callers[sender] = true;

         emit CallerAdded(sender);
    }

    function _removeCaller(address sender) internal virtual{
         callers[sender] = false;

         emit CallerRemoved(sender);
    }

    function addCaller(address sender) external onlyOwner {
        _addCaller(sender);
    }

    function removeCaller(address sender) external onlyOwner {
        _removeCaller(sender);
    }

    function isCaller(address sender) public view returns (bool) {
        return callers[sender];
    }
}

contract Father is Context, ExternalCaller {
    mapping(address => bool) fathers;

    constructor() public {}

    modifier onlyFather() {
        require(fathers[msg.sender], 'Father: caller is not father');
        _;
    }

    function addFather(address father_) external virtual onlyOwner {
        fathers[father_] = true;
    }

    function removeFather(address father_) external virtual onlyOwner {
        fathers[father_] = false;
    }

    function isFather() public view returns  (bool) {
        return fathers[msg.sender];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import './Interfaces.sol';
import "./IBEP20.sol";
/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            'Address: insufficient balance'
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(
            success,
            'Address: unable to send value, recipient may have reverted'
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

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
                'Address: low-level call with value failed'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            'Address: insufficient balance for call'
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: weiValue}(data);
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeERC20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                'SafeERC20: decreased allowance below zero'
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata =
            address(token).functionCall(
                data,
                'SafeERC20: low-level call failed'
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                'SafeERC20: ERC20 operation did not succeed'
            );
        }
    }
}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                'SafeBEP20: decreased allowance below zero'
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata =
            address(token).functionCall(
                data,
                'SafeBEP20: low-level call failed'
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                'SafeBEP20: BEP20 operation did not succeed'
            );
        }
    }
}



library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor() internal {
        _addWhitelistAdmin(msg.sender);
    }

    modifier onlyWhitelistAdmin() {
        require(
            isWhitelistAdmin(msg.sender),
            "WhitelistAdminRole: caller does not have the WhitelistAdmin role"
        );
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(msg.sender);
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function removeWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _removeWhitelistAdmin(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IERC20 {
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import './BEP20Burnable.sol';
import '../IUinswapV2Interface.sol';

abstract contract ListenTradeToken is Operator, BEP20 {
    using SafeMath for uint256;

    mapping(address => uint256) private addressBuyAmount;
    mapping(address => uint256) private addressSellAmount;
    mapping(address => uint256) private addressTradeAmount;

    mapping(address => bool) private listenAddress;

    bool public openListen = true;

    event BuyAmountUpdate(
        address sender,
        uint256 buyAmount,
        uint256 tradeAmount
    );
    event SellAmountUpdate(
        address sender,
        uint256 sellAmount,
        uint256 tradeAmount
    );

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    function open(bool value) onlyOwner external
    {
        openListen = value;
    }

    function _tradeSum(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        if (listenAddress[recipient]) {

            addressSellAmount[sender] = addressSellAmount[sender].add(amount);
            addressTradeAmount[sender] = addressTradeAmount[sender].add(amount);
            emit SellAmountUpdate(
                sender,
                addressSellAmount[sender],
                addressTradeAmount[sender]
            );
        } else if (listenAddress[sender]) {
            addressBuyAmount[recipient] = addressBuyAmount[recipient].add(amount);
            addressTradeAmount[recipient] = addressTradeAmount[recipient].add(amount);

            emit BuyAmountUpdate(
                sender,
                addressBuyAmount[recipient],
                addressTradeAmount[recipient]
            );
        }
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override virtual {
        super._transfer(sender, recipient, amount);
        if(openListen){
            _tradeSum(sender, recipient, amount);
        }
    }

    function getAddressTradeSum(address sender)
        external
        view
        returns (
            uint256 buyAmount,
            uint256 sellAmount,
            uint256 totalAmount
        )
    {
        buyAmount = addressBuyAmount[sender];
        sellAmount = addressSellAmount[sender];
        totalAmount = addressTradeAmount[sender];
    }

    function _doAddListenAddress(address address_) internal 
    {
        listenAddress[address_]=true;
    }

    function addListenAddress(address address_) onlyOwner external
    {
        _doAddListenAddress(address_);   
    }

    function addListenETHSwapWithUniswapRouterV2(address routerAddress) onlyOwner external
    {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(routerAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());

        _doAddListenAddress(_uniswapV2Pair);
    }

    function addListenTokenSwapWithUniswapRouterV2(address routerAddress,address tokenAddress) onlyOwner external
    {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(routerAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), tokenAddress);

        _doAddListenAddress(_uniswapV2Pair);
    }
}

pragma solidity >=0.6.2;

interface IPancakeFactory {
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


interface IPancakeRouter01 {
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

interface IPancakeRouter02 is IPancakeRouter01 {
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

interface IPancakePair {
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IADAOUserInterface {
    function register(address user, address inviter) external;

    function getInviter(address sender) external view returns (address inviter);

    function queryUserInfo(address user)
        external
        view
        returns (
            bool active,
            address inviter,
            uint256 inviteCount,
            bool isKnight,
            uint256 activeTime,
            uint256 activeBlock
        );

    function addCaller(address sender) external;
}

interface IADBNB2RewardDroperInterface {
    function dropReward(uint256 bnbAmount, address receiver)
        external
        returns (uint256);

    function getBNB2PriceInBNB() external view returns (uint256 price);

    function addCaller(address sender) external;
}

interface IADMappingInterface {
    function addMappingADAOAmount(uint256 amount) external;
}

interface IADSwapHelperInterfae {
    function getBNB2PriceInBNB() external view returns (uint256 price);

    function getDAOTPriceInBNB() external view returns (uint256 price);

    function getADAOPriceInBNB() external view returns (uint256 price);

    function swapADAOToBNB(uint256 tokenAmount, address receiver) external;

    function addADAOLiquidity(uint256 tokenAmount) external payable;
}

interface IADTradeDividendDipatcherInterface {
    function getBuyDividendPercents() external view returns (uint256);

    function getSellDividendPercents() external view returns (uint256);

    function dispatchBuyDividend(address user, uint256 buyAmount) external;

    function dispatchSellDividend(address user, uint256 buyAmount) external;

    function getSwapRouterAddress() external view returns (address);

    function getTokenETHPairAddress() external view returns (address);

    function swapFirst() external;
}

interface IADTradeHoldingDispatcher {
    function dispatch(uint256 amount) external;
}

interface IADUserRewardInterface {
    function getBNB2PriceInBNB() external view returns (uint256 price);

    function dividendBNB2(address user, uint256 amount)
        external
        returns (uint256);

    function updateWhales(address user) external;

    function addTradeWhaleDividendADAO(uint256 amount) external;

    function addTradeWhaleDividendBNB(uint256 amount) external;

    function addADWhaleDividendMonth(uint256 amount) external;

    function addADWhaleDividendQuater(uint256 amount) external;

    function addKnight(address user) external;

    function addKnightQuaterDividendADAO(uint256 amount) external;

    function addKnightMonthDividendADAO(uint256 amount) external;

    function dispatchKnightMonthEpoch(uint256 amount) external;

    function dispatchKnightQuaterEpoch(uint256 amount) external;

    function queryTotalKnightRewardInfo()
        external
        view
        returns (
            uint256 knightUserCount,
            uint256 knightUserHoldTotalAmount,
            uint256 knightMonthTotalRewardAmount,
            uint256 knightMonthLeftRewardAmount,
            uint256 knightQuaterTotalRewardAmount,
            uint256 knightQuaterLeftRewardAmount
        );

    function queryUserRewardInfo(address user)
        external
        view
        returns (
            uint256 withdrawableADAO,
            uint256 withdrawableBNB,
            uint256 withdrawnADAO,
            uint256 withdrawnBNB,
            uint256 knightMonthRewardAmount,
            uint256 knightQuaterRewardAmount,
            uint256 adWhaleRewardAmountQuater,
            uint256 adWhaleRewardAmountMonth,
            uint256 tradeWhaleRewardADAOAmount,
            uint256 tradeWhaleRewardBNBAmount
        );

    function queryUserRewardDetail(address user)
        external
        view
        returns (
            uint256 knightHoldAmount,
            uint256 adHoldAmount,
            uint256 tradeHoldAmount
        );

    function queryTotalWhaleRewardInfo()
        external
        view
        returns (
            uint256 adWhaleUserCount,
            uint256 adWhaleUserHoldTotalAmount,
            uint256 adWhaleTotalRewardAmountMonth,
            uint256 adWhaleLeftRewardAmountMonth,
            uint256 adWhaleTotalRewardAmountQuater,
            uint256 adWhaleLeftRewardAmountQuater,
            uint256 tradeWhaleUserCount,
            uint256 tradeWhaleUserHoldTotalAmount,
            uint256 tradeWhaleTotalRewardADAOAmount,
            uint256 tradeWhaleTotalRewardBNBAmount,
            uint256 tradeWhaleLeftRewardADAOAmount,
            uint256 tradeWhaleLeftRewardBNBAmount
        );

    function withdrawAll() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import './ListenTradeToken.sol';
import '../adao/IADAOInterface.sol';
import '../base/Swapable.sol';

contract ADTradeDividendDispatcher is Swapable {
    using SafeMath for uint256;
    using Address for address;
    using SafeBEP20 for IBEP20;

    IADUserRewardInterface userRewardDroper;

    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    // address public holdingRewardAddress;
    // address public holdingRewardBNBAddress;
    address public fundAddress;

    bool public enableBuyDispatch = true;
    bool public enableSellDispatch = true;

    mapping(address => uint256) public userBuyDividendAmount;
    mapping(address => uint256) public userSellDividendAmount;
    uint256 public globalBuyDividendAmount;
    uint256 public globalSellDividendAmount;

    //buy
    uint256 public buyDividendDeadPercent = 1;
    uint256 public buyDividendHoldingPercent = 3;
    uint256 public buyDividendLiquidityPercent = 3;
    uint256 public buyDividendFundPercent = 5;

    //sell
    uint256 public sellDividendDeadPercent = 1;
    uint256 public sellDividendHoldingPercent = 2;
    uint256 public sellDividendLiquidityPercent = 7;
    uint256 public sellDividendFundPercent = 5;

    //sum
    uint256 public globalDeadTokenAmount = 0;
    uint256 public globalHoldingTokenAmount = 0;
    uint256 public globalHoldingBNBAmount = 0;
    uint256 public globalLiquidityTokenAmount = 0;
    uint256 public globalFundTokenAmount = 0;

    uint256 public needSwapAndQuilifyAmount = 0;
    uint256 public needSwapAndEthAmount = 0;

    //option
    bool public openLiquidityDividend = true;
    bool public openDeadDividend = true;
    bool public openHoldingDividend = true;
    bool public openFundDividend = true;

    bool public enableSwap = true;
    bool public enableLiquify = true;

    event BuyDividendDeadDisptached(address receiver, uint256 amount);
    event BuyDividendHoldingDisptached(address receiver, uint256 amount);
    event BuyDividendFundDisptached(address receiver, uint256 amount);

    event BuyDividendAllDisptached(uint256 amount);

    event SellDividendDeadDisptached(address receiver, uint256 amount);
    event SellDividendHoldingDisptached(address receiver, uint256 amount);
    event SellDividendFundDisptached(address receiver, uint256 amount);

    event SellDividendAllDisptached(uint256 amount);

    event SwapAndQuilified(uint256 amount);
    event SwapAndDividend(uint256 amount);

    constructor(
        address uniswapRouterV2,
        address fund,
        address rewardDroper
    ) public Swapable(uniswapRouterV2) {
        fundAddress = fund;

        userRewardDroper = IADUserRewardInterface(rewardDroper);
    }

    function changeSwapAndLiquifyOption(bool swap_, bool liquify_)
        external
        onlyOwner
    {
        enableSwap = swap_;
        enableLiquify = liquify_;
    }

    function getSwapRouterAddress() external view returns (address) {
        return address(PancakeRouter);
    }

    function getTokenETHPairAddress() external view returns (address) {
        return address(TOKENETHPair);
    }

    function changeOpenLiquidityDividend(bool value) external onlyOwner {
        openLiquidityDividend = value;
    }

    function changeOpenDeadDividend(bool value) external onlyOwner {
        openDeadDividend = value;
    }

    function changeOpenHoldingDividend(bool value) external onlyOwner {
        openHoldingDividend = value;
    }

    function changeOpenFundDividend(bool value) external onlyOwner {
        openFundDividend = value;
    }

    function changeRewardDroper(address addr) external onlyOwner {
        userRewardDroper = IADUserRewardInterface(addr);
    }

    function changeFundAddress(address addr) external onlyOwner {
        fundAddress = addr;
    }

    function transferETH(address receiver) external onlyOwner {
        address(uint160(receiver)).transfer(address(this).balance);
    }

    function transferToken(address receiver) external onlyOwner {
        TOKEN.safeTransfer(receiver, TOKEN.balanceOf(address(this)));
    }

    function _getBuyDividendPercents() internal view virtual returns (uint256) {
        uint256 dividendPercent = 0;
        if (openDeadDividend) {
            dividendPercent = dividendPercent.add(buyDividendDeadPercent);
        }
        if (openHoldingDividend) {
            dividendPercent = dividendPercent.add(buyDividendHoldingPercent);
        }
        if (openLiquidityDividend) {
            dividendPercent = dividendPercent.add(buyDividendLiquidityPercent);
        }
        if (openFundDividend) {
            dividendPercent = dividendPercent.add(buyDividendFundPercent);
        }

        return dividendPercent;
    }

    function _getSellDividendPercents()
        internal
        view
        virtual
        returns (uint256)
    {
        uint256 dividendPercent = 0;
        if (openDeadDividend) {
            dividendPercent = dividendPercent.add(sellDividendDeadPercent);
        }
        if (openHoldingDividend) {
            dividendPercent = dividendPercent.add(sellDividendHoldingPercent);
        }
        if (openLiquidityDividend) {
            dividendPercent = dividendPercent.add(sellDividendLiquidityPercent);
        }
        if (openFundDividend) {
            dividendPercent = dividendPercent.add(sellDividendFundPercent);
        }

        return dividendPercent;
    }

    function _dispatchBuyDividend(address user, uint256 buyAmount)
        internal
        virtual
    {
        if (enableBuyDispatch) {
            uint256 total = _buyDividend(buyAmount);
            userBuyDividendAmount[user] = userBuyDividendAmount[user].add(
                total
            );

            globalBuyDividendAmount = globalBuyDividendAmount.add(total);

            emit BuyDividendAllDisptached(total);
        }
    }

    function _dispatchSellDividend(address user, uint256 sellAmount)
        internal
        virtual
    {
        if (enableSellDispatch) {
            uint256 total = _sellDividend(sellAmount);
            userSellDividendAmount[user] = userSellDividendAmount[user].add(
                total
            );

            globalSellDividendAmount = globalSellDividendAmount.add(total);

            emit SellDividendAllDisptached(total);
        }
    }

    function _swapFirst() internal virtual {
        if (needSwapAndQuilifyAmount > 0) {
            uint256 amount = Math.min(
                TOKEN.balanceOf(address(this)),
                needSwapAndQuilifyAmount
            );
            _dividendToSwapAndLiquidity(amount);

            emit SwapAndQuilified(amount);
        }

        if (needSwapAndEthAmount > 0) {
            uint256 amount = Math.min(
                TOKEN.balanceOf(address(this)),
                needSwapAndEthAmount
            );
            _dividendToSwapAndShareHolding(amount);
            emit SwapAndDividend(amount);
        }
    }

    function _buyDividend(uint256 buyAmount)
        internal
        virtual
        returns (uint256)
    {
        uint256 dividendAmount = 0;

        if (openDeadDividend) {
            uint256 deadAmount = buyAmount.mul(buyDividendDeadPercent).div(100);
            _dividendToDead(deadAmount);
            dividendAmount = dividendAmount.add(deadAmount);

            emit BuyDividendDeadDisptached(deadAddress, deadAmount);
        }

        if (openHoldingDividend) {
            uint256 holdAmount = buyAmount.mul(buyDividendHoldingPercent).div(
                100
            );
            // _dividendToHoldingForBuy(holdAmount);
            needSwapAndEthAmount = needSwapAndEthAmount.add(holdAmount);

            dividendAmount = dividendAmount.add(holdAmount);
        }

        if (openFundDividend) {
            uint256 fundAmount = buyAmount.mul(buyDividendFundPercent).div(100);
            _dividendToFund(fundAmount);
            dividendAmount = dividendAmount.add(fundAmount);
            emit BuyDividendFundDisptached(deadAddress, fundAmount);
        }

        if (openLiquidityDividend) {
            uint256 lpAmount = buyAmount.mul(buyDividendLiquidityPercent).div(
                100
            );

            needSwapAndQuilifyAmount = needSwapAndQuilifyAmount.add(lpAmount);

            dividendAmount = dividendAmount.add(lpAmount);
        }

        return dividendAmount;
    }

    function _sellDividend(uint256 sellAmount)
        internal
        virtual
        returns (uint256)
    {
        uint256 dividendAmount = 0;

        if (openDeadDividend) {
            uint256 deadAmount = sellAmount.mul(sellDividendDeadPercent).div(
                100
            );
            _dividendToDead(deadAmount);
            dividendAmount = dividendAmount.add(deadAmount);

            emit SellDividendDeadDisptached(deadAddress, deadAmount);
        }

        if (openHoldingDividend) {
            uint256 holdAmount = sellAmount.mul(sellDividendHoldingPercent).div(
                100
            );
            _dividendToHolding(holdAmount);

            dividendAmount = dividendAmount.add(holdAmount);

            emit SellDividendHoldingDisptached(deadAddress, holdAmount);
        }

        if (openFundDividend) {
            uint256 fundAmount = sellAmount.mul(sellDividendFundPercent).div(
                100
            );
            _dividendToFund(fundAmount);
            dividendAmount = dividendAmount.add(fundAmount);
            emit SellDividendFundDisptached(deadAddress, fundAmount);
        }

        if (openLiquidityDividend) {
            uint256 lpAmount = sellAmount.mul(sellDividendLiquidityPercent).div(
                100
            );

            needSwapAndQuilifyAmount = needSwapAndQuilifyAmount.add(lpAmount);

            dividendAmount = dividendAmount.add(lpAmount);
        }

        return dividendAmount;
    }

    function _dividendToDead(uint256 amount) internal virtual {
        require(
            amount > 0,
            'ADTradeDividendDispatcher _dividendToDead amount must > 0'
        );

        TOKEN.safeTransfer(deadAddress, amount);
        globalDeadTokenAmount = globalDeadTokenAmount.add(amount);
    }

    function _dividendToFund(uint256 amount) internal virtual {
        require(
            amount > 0,
            'ADTradeDividendDispatcher _dividendToFund amount must > 0'
        );

        TOKEN.safeTransfer(fundAddress, amount);
        globalFundTokenAmount = globalFundTokenAmount.add(amount);
    }

    function _dividendToHolding(uint256 amount) internal virtual {
        require(
            amount > 0,
            'ADTradeDividendDispatcher _dividendToHolding amount must > 0'
        );

        TOKEN.safeTransfer(address(userRewardDroper), amount);
        userRewardDroper.addTradeWhaleDividendBNB(amount);

        globalHoldingTokenAmount = globalHoldingTokenAmount.add(amount);
    }

    function _dividendToSwapAndLiquidity(uint256 amount) internal virtual {
        uint256 swapAmount = amount.div(2);
        uint256 liquidityAmount = amount.sub(swapAmount);

        uint256 initETHBalance = address(this).balance;
        _swapADAOToBNB(swapAmount, address(this));

        uint256 swapETHBalance = address(this).balance.sub(initETHBalance);
        _addADAOLiquidity(liquidityAmount, swapETHBalance);
    }

    function _dividendToSwapAndShareHolding(uint256 amount) internal virtual {
        require(
            amount > 0,
            'ADTradeDividendDispatcher _dividendToHoldingForBuy token amount must > 0'
        );

        uint256 initETHBalance = address(this).balance;
        _swapADAOToBNB(amount, address(this));
        uint256 swapETHBalance = address(this).balance.sub(initETHBalance);

        require(
            swapETHBalance > 0,
            'ADTradeDividendDispatcher _dividendToHoldingForBuy eth amount must > 0'
        );

        payable(address(userRewardDroper)).transfer(swapETHBalance);
        userRewardDroper.addTradeWhaleDividendBNB(swapETHBalance);

        globalHoldingBNBAmount = globalHoldingBNBAmount.add(swapETHBalance);
        globalHoldingTokenAmount = globalHoldingTokenAmount.add(amount);
    }

    function _swapADAOToBNB(uint256 adaoAmount, address receiver)
        internal
        virtual
    {
        _swapTokensForEth(address(TOKEN), adaoAmount, receiver);
    }

    function _addADAOLiquidity(uint256 adaoAmount, uint256 ethAmount)
        internal
        virtual
    {
        _addLiquidity(address(TOKEN), adaoAmount, ethAmount, address(this));
    }

    function _removeADAOLiquidity(address receiver) internal virtual {
        _removeLiquidity(address(TOKEN), receiver);
    }

    function swapADAOManual(uint256 amount)
        external
        onlyOwner
        returns (uint256)
    {
        _swapADAOToBNB(amount, address(this));
    }

    function addLiquidityExternalManual(uint256 amount)
        external
        payable
        onlyOwner
    {
        _addADAOLiquidity(amount, msg.value);
    }

    function addLiquidityInternalManual() external onlyOwner {
        _addADAOLiquidity(
            TOKEN.balanceOf(address(this)),
            address(this).balance
        );
    }

    function removeLiquidityInternalManual() external onlyOwner {
        _removeADAOLiquidity(msg.sender);
    }

    function queryTotalDividendInfo()
        external
        view
        returns (
            uint256 deadTokenAmount,
            uint256 holdingTokenAmount,
            uint256 holdingBNBAmount,
            uint256 liquidityTokenAmount,
            uint256 fundTokenAmount,
            uint256 totalBuyDividendAmount,
            uint256 totalSellDividendAmount
        )
    {
        deadTokenAmount = globalDeadTokenAmount;
        holdingTokenAmount = globalHoldingTokenAmount;
        holdingBNBAmount = globalHoldingBNBAmount;
        liquidityTokenAmount = globalLiquidityTokenAmount;
        fundTokenAmount = globalFundTokenAmount;
        totalBuyDividendAmount = globalBuyDividendAmount;
        totalSellDividendAmount = globalSellDividendAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import '../Context.sol';
import '../Libraries.sol';
import '../IPancakeInterface.sol';

abstract contract Swapable is Father {
    using SafeMath for uint256;
    using Address for address;
    using SafeBEP20 for IBEP20;

    IBEP20 public TOKEN;

    IPancakeRouter02 public PancakeRouter;

    address public TOKENETHPairAddress;
    IBEP20 TOKENETHPair;

    constructor(address pancakeRouter) public {
        PancakeRouter = IPancakeRouter02(pancakeRouter);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _changeTokenETHPair(address addr) internal virtual {
        TOKENETHPairAddress = addr;
        TOKENETHPair = IBEP20(TOKENETHPairAddress);

        TOKENETHPair.approve(
            address(PancakeRouter),
            100000000000000000000 ether
        );
        TOKEN.approve(addr, 100000000000000000000 ether);
    }

    function transferLP() external onlyOwner {
        TOKENETHPair.safeTransfer(
            msg.sender,
            TOKENETHPair.balanceOf(address(this))
        );
    }

    function changeTokenETHPair(address addr) external onlyOwner {
        _changeTokenETHPair(addr);
    }

    function changeToken(address adao_) external onlyOwner {
        TOKEN = IBEP20(adao_);
        TOKEN.approve(address(PancakeRouter), 1000000000000000 ether);
    }

    function changePancakeRouter(address pancakeRouter) external onlyOwner {
        PancakeRouter = IPancakeRouter02(pancakeRouter);

        TOKEN.approve(address(PancakeRouter), 1000000000000000 ether);
    }

    function _initToken(address adao) internal virtual {
        TOKEN = IBEP20(adao);
        TOKEN.approve(address(PancakeRouter), 1000000000000000 ether);

        _createTokenETHPair();
    }

    function initToken(address adao) external onlyOwner {
        _initToken(adao);
    }

    function _createTokenETHPair() internal virtual {
        address _uniswapV2Pair = IPancakeFactory(PancakeRouter.factory())
            .createPair(PancakeRouter.WETH(), address(TOKEN));
        _changeTokenETHPair(_uniswapV2Pair);
    }

    function _getTokenPriceFromPancake(address token)
        internal
        view
        virtual
        returns (uint256)
    {
        uint112 reserve0;
        uint112 reserve1;
        uint32 blockTimestampLast;

        IPancakeFactory factory = IPancakeFactory(PancakeRouter.factory());
        IPancakePair pair = IPancakePair(
            factory.getPair(PancakeRouter.WETH(), token)
        );
        (reserve0, reserve1, blockTimestampLast) = pair.getReserves();
        uint256 price = reserve1 / reserve0;
        return price;
    }

    function getTokenPriceInBNB(address token)
        public
        view
        returns (uint256 price)
    {
        return _getTokenPriceFromPancake(token);
    }

    function _swapTokensForEth(
        address tokenAddress,
        uint256 tokenAmount,
        address receiver
    ) internal virtual {
        // generate the uniswap pair path of token -> weth
        TOKEN.approve(address(PancakeRouter), tokenAmount);

        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = PancakeRouter.WETH();

        // make the swap
        //swapExactTokensForTokensSupportingFeeOnTransferTokens
        PancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            receiver,
            block.timestamp
        );
    }

    function _addLiquidity(
        address tokenAddress,
        uint256 tokenAmount,
        uint256 ethAmount,
        address receiver
    ) internal virtual {
        TOKEN.approve(address(PancakeRouter), tokenAmount);

        // add the liquidity
        PancakeRouter.addLiquidityETH{value: ethAmount}(
            tokenAddress,
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            receiver,
            block.timestamp
        );
    }

    // function removeLiquidityETH(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountToken, uint amountETH);

    function _removeLiquidity(address tokenAddress, address receiver)
        internal
        virtual
    {
        // add the liquidity
        PancakeRouter.removeLiquidityETH(
            tokenAddress,
            TOKENETHPair.balanceOf(address(this)),
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            receiver,
            block.timestamp
        );
    }

    function removeAllTokenETHLiquidity() external onlyOwner {
        _removeLiquidity(address(TOKEN), msg.sender);
    }
}