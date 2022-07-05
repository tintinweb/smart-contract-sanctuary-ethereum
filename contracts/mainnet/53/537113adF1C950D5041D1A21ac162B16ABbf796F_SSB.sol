/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.15;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

abstract contract Ownable is Context {
    address internal _owner;
    address private _previousOwner;
    uint256 public _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }


        //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock.");
        require(block.timestamp > _lockTime , "Contract is locked.");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero addy");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero addy");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero addy");
        require(spender != address(0), "ERC20: approve to the zero addy");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

abstract contract ERC20Burnable is Context, ERC20 {
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

contract SSB is ERC20Burnable, Ownable {
    using SafeMath for uint256;
    uint256 constant _initial_supply = 1 * (10**10) * (10**18); // 1 billion tokens, 18 decimals

    uint256 public tokensBurned;
    address payable public _markettingWallet;
    address payable public _buybackWallet;
    mapping (address => bool) public superUsers;   

    uint256 public maxWalletSize = _initial_supply.mul(1).div(100); // 2% of totalsupply
    uint256 public maxTransactionSize = _initial_supply.mul(1).div(100); // 1% of totalsupply
    uint256 public swapThreshold = _initial_supply.mul(2).div(1000); // .02% of totalsupply

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 liquidityLockTime = 0;

    address public usd = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; //USDC

    mapping(address => bool) public _isExcludedFromFee;
    mapping(address => bool) public _isExcludedFromMaxTransaction;
    mapping(address => bool) public _isExcludedFromMaxWallet;

    enum FeeType {
        None,
        Buy,
        Sell
    }

    struct BuyFee {
        uint16 liquidity;
        uint16 dev;
        uint16 buyback;
    }

    struct SellFee {
        uint16 liquidity;
        uint16 dev;
        uint16 buyback;
    }

    BuyFee public buyFee;
    SellFee public sellFee;

    uint256 constant FEE_DENOM = 1000; // smallest fee unit is 0.1%

    event excludedFromFee(address account);
    event excludedFromMaxTransaction(address account);
    event excludedFromMaxWallet(address account);

    event includedInFee(address account);
    event includedInMaxTransaction(address account);
    event includedInMaxWallet(address account);

    event developmentWalletUpdated(address developmentWallet);
    event buybackWalletUpdated(address buybackWallet);
    event liquidityRemoved(uint256 amountToken, uint256 amountETH);

    event swapThresholdUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event MaxWalletSizeUpdated(uint256 maxWalletSize);
    event MaxTransactionSizeUpdated(uint256 maxTransactionSize);

    event LiquidityLockTimeUpdated(uint256 lockTime);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() ERC20("SSB", "SSB") {
        // set fees to max
        setSellFee(5, 5, 5);
        setBuyFee(5, 10, 5);

        _markettingWallet = payable(msg.sender);
        _buybackWallet = payable(msg.sender);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        _mint(msg.sender, _initial_supply.mul(50).div(100)); // for liquidity pool
        _mint(0x000000000000000000000000000000000000dEaD, _initial_supply.mul(50).div(100)); // burned to dEaD

        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromMaxTransaction[msg.sender] = true;
        _isExcludedFromMaxWallet[msg.sender] = true;

        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromMaxTransaction[address(this)] = true;
        _isExcludedFromMaxWallet[address(this)] = true;

        _isExcludedFromFee[_markettingWallet] = true;
        _isExcludedFromMaxTransaction[_markettingWallet] = true;
        _isExcludedFromMaxWallet[_markettingWallet] = true;

        _isExcludedFromFee[_buybackWallet] = true;
        _isExcludedFromMaxTransaction[_buybackWallet] = true;
        _isExcludedFromMaxWallet[_buybackWallet] = true;
    }

    receive() external payable {}

    function setSuperUser(address account, bool enabled) external onlyOwner {
        superUsers[account] = enabled;
    }

    // public functions
    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        address _owner = _msgSender();
        (bool takeFee, FeeType feeType) = checkFeeRequired(_owner, to);

        checkTransferAllowed(_owner, to, amount, takeFee);

        if (takeFee) {
            //check for swapAndLiquify available
            uint256 contractBalance = balanceOf(address(this));
            if (
                contractBalance >= swapThreshold &&
                !inSwapAndLiquify &&
                swapAndLiquifyEnabled &&
                _owner != uniswapV2Pair
            ) {
                //perform swapAndLiquify
                swapAndLiquify(swapThreshold);
            }

            uint256 fee = calculateFee(amount, feeType);
            _transfer(_owner, address(this), fee);
            _transfer(_owner, to, amount - fee);
        } else {
            _transfer(_owner, to, amount);
        }
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = _msgSender();

        (bool takeFee, FeeType feeType) = checkFeeRequired(from, to);
        checkTransferAllowed(from, to, amount, takeFee);

        _spendAllowance(from, spender, amount);

        if (takeFee) {
            //check for swapAndLiquify available
            uint256 contractBalance = balanceOf(address(this));
            if (
                contractBalance >= swapThreshold &&
                !inSwapAndLiquify &&
                swapAndLiquifyEnabled &&
                from != uniswapV2Pair
            ) {
                //perform swapAndLiquify
                swapAndLiquify(swapThreshold);
            }

            uint256 fee = calculateFee(amount, feeType);
            _transfer(from, address(this), fee);
            _transfer(from, to, amount - fee);
        } else {
            _transfer(from, to, amount);
        }

        return true;
    }

    function burn(uint256 amount) public override {
        _burn(_msgSender(), amount);
        tokensBurned += amount;
    }

    function burnFrom(address account, uint256 amount) public override {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
        tokensBurned += amount;
    }

    function liquidityLockedUntil() external view returns (uint256) {
        return liquidityLockTime;
    }

    // internal functions

    function checkTransferAllowed(
        address from,
        address to,
        uint256 amount,
        bool takeFee
    ) internal view {
        if (to != uniswapV2Pair) {
            require(
                balanceOf(to) + amount < maxWalletSize ||
                    _isExcludedFromMaxWallet[to],
                "Exceeds receivers maximum wallet size"
            );
        }
        if (takeFee) {
            require(
                amount <= maxTransactionSize ||
                    (_isExcludedFromMaxTransaction[from] ||
                        _isExcludedFromMaxTransaction[to]),
                "Transaction larger than allowed"
            );
        }
    }

    function checkFeeRequired(address from, address to)
        internal
        view
        returns (bool, FeeType)
    {
        if (from == uniswapV2Pair && !_isExcludedFromFee[to]) {
            return (true, FeeType.Buy);
        } else if (to == uniswapV2Pair && !_isExcludedFromFee[from]) {
            return (true, FeeType.Sell);
        } else {
            return (false, FeeType.None);
        }
    }

    function calculateFee(uint256 amount, FeeType feeType)
        internal
        view
        returns (uint256 fee)
    {
        uint256 feePercentage = 0;
        if (feeType == FeeType.Buy) {
            feePercentage =
                buyFee.liquidity +
                buyFee.dev +
                buyFee.buyback;
        } else if (feeType == FeeType.Sell) {
            feePercentage =
                sellFee.liquidity +
                sellFee.dev +
                sellFee.buyback;
        }
        fee = (amount * feePercentage) / FEE_DENOM;
        return fee;
    }

    function yourUSDValue(address yourAddress) public view returns (uint256) {
        address[] memory path = new address[](3);
        uint256 tokenBalance = balanceOf(yourAddress);
        uint256 zeroUsd = 0;
        
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = usd;

        try uniswapV2Router.getAmountsOut(tokenBalance, path) returns (uint[] memory amounts) {
            return amounts[2];
        }
        catch {
            return zeroUsd;
        }       
    }

    function getUsdDecimals() public view returns (uint8) {
        uint8 defaultDecimals = 18;

        try IERC20(usd).decimals() returns (uint8 usddecimals) {
            return usddecimals;
        }
        catch { return defaultDecimals; }
    }

    function changeUsdToken(address newUsdAddress) external onlyOwner {
        usd = newUsdAddress;
    }

    function swapAndLiquify(uint256 tokens) internal lockTheSwap {
        // split tokens by buy fee ratio
        uint256 feeDenominator = 
            buyFee.liquidity +
            buyFee.dev +
            buyFee.buyback;

        uint256 liquidityFee = (tokens * buyFee.liquidity) / feeDenominator;

        // sell tokens minus half of liquidity cut for eth
        swapTokensForEth(tokens - (liquidityFee / 2));

        // split resulting eth balance of contract by ratio, giving liquidity half weight
        uint256 contractEth = address(this).balance;

        uint256 ethDenominator = 
            (buyFee.liquidity / 2) +
            buyFee.dev +
            buyFee.buyback;

        uint256 liquidityEth = (contractEth * (buyFee.liquidity / 2)) /
            ethDenominator;
        uint256 buybackEth = (contractEth * buyFee.buyback) / ethDenominator;

        // provide liquidity with eth portion and remaining tokens

        if (liquidityEth > 0) {
            // Add liquidity to uniswap
            addLiquidity(liquidityFee / 2, liquidityEth);
        }

        _buybackWallet.transfer(buybackEth);

        // send all remaining eth to marketting wallet (in case of rounding)
        _markettingWallet.transfer(address(this).balance); 

        emit SwapAndLiquify(tokens, contractEth, liquidityFee / 2);
    }

    function swapTokensForEth(uint256 tokenAmount) internal {
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    // admin functions
    function setMarkettingWallet(address marketting) external onlyOwner {
        require(marketting != address(0), "Development wallet cannot be 0x0");
        _markettingWallet = payable(marketting);
    }

    function setBuybackWallet(address buyback) external onlyOwner {
        require(buyback != address(0), "Buyback wallet cannot be 0x0");
        _buybackWallet = payable(buyback);
        emit buybackWalletUpdated(_buybackWallet);
    }

    function setSellFee(
        uint16 liquidity,
        uint16 dev,
        uint16 buyback
    ) public onlyOwner {
        require(
            liquidity + dev + buyback < FEE_DENOM,
            "invalid fee structure"
        );

        sellFee.liquidity = liquidity;
        sellFee.dev = dev;
        sellFee.buyback = buyback;
    }

    function setBuyFee(
        uint16 liquidity,
        uint16 dev,
        uint16 buyback
    ) public onlyOwner {
        require(
            liquidity + dev + buyback < FEE_DENOM,
            "invalid fee structure"
        );

        buyFee.liquidity = liquidity;
        buyFee.dev = dev;
        buyFee.buyback = buyback;
    }

    function setSwapThreshold(uint256 newSwapThreshold) external onlyOwner {
        swapThreshold = newSwapThreshold;
        emit swapThresholdUpdated(newSwapThreshold);
    }

    function setMaxTransactionSize(uint256 maxTxSize) external onlyOwner {
        maxTransactionSize = maxTxSize;
        emit MaxTransactionSizeUpdated(maxTransactionSize);
    }

    function setMaxWalletSize(uint256 maxWallet) external onlyOwner {
        maxWalletSize = maxWallet;
        emit MaxWalletSizeUpdated(maxWalletSize);
    }

    function excludeFromFee(address account) external onlyOwner {
        require(
            !_isExcludedFromFee[account],
            "Account is already excluded from fee"
        );
        _isExcludedFromFee[account] = true;

        emit excludedFromFee(account);
    }

    function excludeFromMaxTransaction(address account) external onlyOwner {
        require(
            !_isExcludedFromMaxTransaction[account],
            "Account is already excluded from max transaction"
        );
        _isExcludedFromMaxTransaction[account] = true;

        emit excludedFromMaxTransaction(account);
    }

    function excludeFromMaxWallet(address account) external onlyOwner {
        require(
            !_isExcludedFromMaxWallet[account],
            "Account is already excluded from max wallet"
        );
        _isExcludedFromMaxWallet[account] = true;

        emit excludedFromMaxWallet(account);
    }

    function includeInFee(address account) external onlyOwner {
        require(
            _isExcludedFromFee[account],
            "Account is already included in fee"
        );
        _isExcludedFromFee[account] = false;

        emit includedInFee(account);
    }

    function includeInMaxTransaction(address account) external onlyOwner {
        require(
            _isExcludedFromMaxTransaction[account],
            "Account is already included in max transaction"
        );
        _isExcludedFromMaxTransaction[account] = false;

        emit includedInMaxTransaction(account);
    }

    function includeInMaxWallet(address account) external onlyOwner {
        require(
            _isExcludedFromMaxWallet[account],
            "Account is already included in max wallet"
        );
        _isExcludedFromMaxWallet[account] = false;

        emit includedInMaxWallet(account);
    }

    function updateLiquidityLock(uint256 lockTime) external onlyOwner {
        require(
            block.timestamp > liquidityLockTime,
            "New liquidity lock time must be after the current lock time"
        );
        liquidityLockTime = lockTime;
        emit LiquidityLockTimeUpdated(lockTime);
    }

    // wrapper for Uniswap removeLiquidity, can only be called if not locked
    function removeLiquidityETH(
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external onlyOwner {
        require(
            block.timestamp > liquidityLockTime,
            "Liquidity removal is locked"
        );

        (uint256 amountToken, uint256 amountETH) = uniswapV2Router
            .removeLiquidityETH(
                address(this),
                liquidity,
                amountTokenMin,
                amountETHMin,
                to,
                deadline
            );
        emit liquidityRemoved(amountToken, amountETH);
    }

    function toggleSwapAndLiquifyEnabled() external onlyOwner {
        swapAndLiquifyEnabled = !swapAndLiquifyEnabled;
        emit SwapAndLiquifyEnabledUpdated(swapAndLiquifyEnabled);
    }

    function adminSwapAndLiquify(uint256 swapBalance) external onlyOwner {
        swapAndLiquify(swapBalance);
    }

    // Recovery functions

    function rescueEth() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function rescueTokens(address _stuckToken, uint256 _amount) external onlyOwner
    {
        IERC20(_stuckToken).transfer(msg.sender, _amount);
    }

    function rescueBurn(uint256 _amount) external onlyOwner {
        _transfer(address(this), msg.sender, _amount);
    }
}