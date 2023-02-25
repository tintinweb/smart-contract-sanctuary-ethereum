/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint256);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address _owner, address spender)
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

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

contract Token is Ownable, IERC20 {
    using SafeMath for uint256;

    string  private _name;
    string  private _symbol;
    uint256 private _decimals;
    uint256 private _totalSupply;

    uint256 public  maxTx;
    uint256 public  maxWalletLimit;
    address payable public devWallet;
    address public  lpPair;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    IUniswapV2Router02 public dexRouter;

    uint256 public taxRate;
    uint256 public taxDivPercentage;
    bool    public tradingActive;

    uint256 public totalBurned;
    uint256 public totalReflected;
    uint256 public totalLP;

    uint256 public ethReflectionBasis;
    mapping(address => bool)    private _reflectionExcluded;
    mapping(address => uint256) public lastReflectionBasis;
    mapping(address => bool)    private _isExcludedFromTax;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public lpPairs;

    event DevWallet(address indexed previousWallet, address indexed newWallet);

    constructor(/*string memory name_, string memory symbol_, uint256 decimals_, uint256 totalSupply_,
        address payable devWallet_*/) {
        _name              = "Some Token"; //name_;
        _symbol            = "ST"; //symbol_;
        _decimals          = 18; //decimals_;
        _totalSupply       = 1000000000 * 10**_decimals;
        _balances[owner()] = _balances[owner()].add(_totalSupply);

        devWallet               = payable(0xDdaA6e9b7D427cb53b6dE5A1959cAF3E4c33B71c);
        tradingActive           = false;
        taxRate                 = 10;
        taxDivPercentage        = 70;
        maxTx                   = 5000 ether;
        maxWalletLimit          = 1000 ether;
//0xE592427A0AEce92De3Edee1F18E0157C05861564

        dexRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        lpPair    = IUniswapV2Factory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());
        lpPairs[lpPair] = true;

        _approve(owner(), address(dexRouter), type(uint256).max);
        _approve(address(this), address(dexRouter), type(uint256).max);
        _approve(owner(), lpPair, type(uint256).max);
        _approve(address(this), lpPair, type(uint256).max);

        _isExcludedFromTax[owner()]       = true;
        _isExcludedFromTax[address(this)] = true;
        _isExcludedFromTax[lpPair]        = true;

        //_isExcludedFromTax[dexRouter]     = true;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    //@dev All ERC20 functions implementation
    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address _owner, address spender) public view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0), "ERC20: You can't send from a null address.");
        require(recipient != DEAD, "ERC20: You can't send to null address.");
        require(_balances[msg.sender] >= amount, "ERC20: You have low balance.");

        _transfer(msg.sender, recipient, amount);
        // if (msg.sender == owner() || recipient == owner()) {
        //     _transfer(msg.sender, recipient, amount);
        // } else {
        //     require(amount <= maxTx, "ERC20: Amount should be less then max transaction limit.");
        //     require(maxWalletLimit >= balanceOf(recipient).add(amount), "ERC20: Wallet limit exceeds");

            
        // }
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) private {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0), "ERC20: You can't send from a null address.");
        require(recipient != DEAD, "ERC20: You can't send to null address.");
        require(_allowances[sender][msg.sender] >= amount, "ERC20: Insufficient allowance.");
        require(_balances[sender] >= amount, "ERC20: Senders balance is less then the amount.");

        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender]  = _allowances[sender][msg.sender].sub(amount);
        }

        _transfer(sender, recipient, amount);

        // if (sender == owner() || recipient == owner()) {
        //     _transfer(sender, recipient, amount);
        // } else {
        //     require(amount <= maxTx, "ERC20: Amount should be less then max transaction limit.");
        //     require(maxWalletLimit >= balanceOf(recipient).add(amount), "ERC20: Wallet limit exceeds");

            
        // }
        return true;
    }

    // @notice Enables trading on Uniswap
    function enableTrading() external onlyOwner {
        tradingActive = true;
    }

    // @notice Disables trading on Uniswap
    function disableTrading() external onlyOwner {
        tradingActive = false;
    }

    function checkWalletLimit(address recipient, uint256 amount) private view returns(bool){
        require(maxWalletLimit >= balanceOf(recipient).add(amount), "ERC20: Wallet limit exceeds");
        return true;
    }

    function checkTxLimit(uint256 amount) private view returns(bool){
        require(amount <= maxTx, "ERC20: Amount should be less then max transaction limit.");
        return true;
    }

    //@dev Tranfer functions call depencding upon if sender or recipient tax exclusion
    function _transfer(address sender, address recipient, uint256 amount) private {
        if (lpPairs[sender]==true || lpPairs[recipient]==true) { //sell, buy
            require(tradingActive == true, "ERC20: Trading is not active.");
            if (_isExcludedFromTax[sender] && !_isExcludedFromTax[recipient] && checkWalletLimit(recipient, amount) && checkTxLimit(amount)) {
                _transferFromExcluded(sender, recipient, amount);//buy
            } 
            
            else if (!_isExcludedFromTax[sender] && _isExcludedFromTax[recipient] && checkTxLimit(amount)) {
               _transferToExcluded(sender, recipient, amount);//sell
            } 
            
            else if (_isExcludedFromTax[sender] && _isExcludedFromTax[recipient]) {
                if (sender == owner() || recipient == owner() || sender == address(this) || recipient == address(this)) {
                    _transferBothExcluded(sender, recipient, amount);
                } else if (lpPairs[recipient]) {
                    if (checkTxLimit(amount)) {
                        _transferBothExcluded(sender, recipient, amount);
                    }
                } else if (checkWalletLimit(recipient, amount) && checkTxLimit(amount)){
                    _transferBothExcluded(sender, recipient, amount);
                }
            } 
            
            // else {
            //     if (sender == owner() || recipient == owner() || sender == address(this) || recipient == address(this)) {
            //         _transferStandard(sender, recipient, amount);
            //     } else if(checkWallet(recipient, amount)){
            //         _transferStandard(sender, recipient, amount);
            //     }  
            // }
        } 
        
        else {
            if (sender == owner() || recipient == owner() || sender == address(this) || recipient == address(this)) {
                    _transferBothExcluded(sender, recipient, amount);
                } else if(checkWalletLimit(recipient, amount) && checkTxLimit(amount)){
                    _transferBothExcluded(sender, recipient, amount);
                }
        }
    }

    //@dev Called when both sender and receiver are paying tax
    // function _transferStandard(address sender, address recipient, uint256 amount) private {
    //     uint256 randomNumber = _generateRandomNumber();
    //     uint256 taxAmount = amount.mul(taxRate).div(100);
    //     uint256 sentAmount = amount.add(taxAmount);
    //     uint256 receiveAmount = amount.sub(taxAmount);
    //     (
    //     uint256 devAmount,
    //     uint256 burnAmount,
    //     uint256 lpAmount,
    //     uint256 reflectionAmount
    //     ) = _getTaxAmount(taxAmount.add(taxAmount));

    //     _balances[sender]    = _balances[sender].sub(sentAmount);
    //     _balances[recipient] = _balances[recipient].add(receiveAmount);
    //     _swap(devAmount);

    //     if (randomNumber == 1) {
    //         _burn(sender, burnAmount);
    //     } else if (randomNumber == 2) {
    //         _takeLP(sender, lpAmount);
    //     } else if (randomNumber == 3) {
    //         _swapReflection(reflectionAmount);
    //         totalReflected = totalReflected.add(reflectionAmount);
    //     }
    //     emit Transfer(sender, recipient, amount);
    // }

    //@dev Called when only sender is paying tax
    function _transferToExcluded(address sender, address recipient, uint256 amount) private {
        uint256 randomNumber = _generateRandomNumber();
        uint256 taxAmount = amount.mul(taxRate).div(100);
        uint256 sentAmount = amount.add(taxAmount);
        (
        uint256 devAmount,
        uint256 burnAmount,
        uint256 lpAmount,
        uint256 reflectionAmount
        ) = _getTaxAmount(taxAmount);

        _balances[sender] = _balances[sender].sub(sentAmount);
        _balances[recipient] = _balances[recipient].add(amount);
        _swap(devAmount);

        if (randomNumber == 1) {
            _burn(sender, burnAmount);
        } else if (randomNumber == 2) {
            _takeLP(sender, lpAmount);
        } else if (randomNumber == 3) {
            _swapReflection(reflectionAmount);
            totalReflected = totalReflected.add(reflectionAmount);
        }
        emit Transfer(sender, recipient, amount);
    }

    //@dev Called when only recipient is paying tax
    function _transferFromExcluded(address sender, address recipient, uint256 amount) private {
        uint256 randomNumber = _generateRandomNumber();
        uint256 taxAmount = amount.mul(taxRate).div(100);
        uint256 receiveAmount = amount.sub(taxAmount);
        (
        uint256 devAmount,
        uint256 burnAmount,
        uint256 lpAmount,
        uint256 reflectionAmount
        ) = _getTaxAmount(taxAmount);

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(receiveAmount);
        _swap(devAmount);

        if (randomNumber == 1) {
            _burn(sender, burnAmount);
        } else if (randomNumber == 2) {
            _takeLP(sender, lpAmount);
        } else if (randomNumber == 3) {
            _swapReflection(reflectionAmount);
            totalReflected = totalReflected.add(reflectionAmount);
        }

        emit Transfer(sender, recipient, amount);
    }

    //@dev Called when nither sender nor receiver pay tax
    function _transferBothExcluded(address sender, address recipient, uint256 amount) private {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function setMaxTx(uint256 amount) public onlyOwner {
        maxTx = amount;
    }

    function setMaxWalletLimit(uint256 amount) public onlyOwner {
        maxWalletLimit = amount;
    }

    receive() external payable {}

    //@dev Burn function for public use, anyone can burn their tokens
    function burn(uint256 amountTokens) public {
        address sender = msg.sender;
        require(_balances[sender] >= amountTokens, "ERC20: You do not have enough tokens.");

        if (amountTokens > 0) {
            _balances[sender] = _balances[sender].sub(amountTokens);
            _burn(sender, amountTokens);
        }
    }

    //@dev Private burn to decrease total supply
    function _burn(address from, uint256 amount) private {
        _totalSupply = _totalSupply.sub(amount);
        totalBurned  = totalBurned.add(amount);

        emit Transfer(from, address(0), amount);
    }

    //@dev Adding tax to the LP address
    function _takeLP(address from, uint256 tax) private {
        if (tax > 0) {
            (, , uint256 lp, ) = _getTaxAmount(tax);
            _balances[lpPair] = _balances[lpPair].add(lp);
            totalLP = totalLP.add(tax);

            emit Transfer(from, lpPair, tax);
        }
    }

    function LpPair(address pair, bool status) public onlyOwner{
        //require(!lpPairs[pair], "ERC20: Pair is already added.");
        lpPairs[pair] = status;
        _isExcludedFromTax[pair] = status;
    }

    function addReflection() external payable {
        ethReflectionBasis += msg.value;
    }

    function isReflectionExcluded(address account) public view returns (bool) {
        return _reflectionExcluded[account];
    }

    function removeReflectionExcluded(address account) external onlyOwner {
        require(isReflectionExcluded(account), "ERC20: Account must be excluded");

        _reflectionExcluded[account] = false;
    }

    function addReflectionExcluded(address account) external onlyOwner {
        _addReflectionExcluded(account);
    }

    function _addReflectionExcluded(address account) internal {
        require(!isReflectionExcluded(account), "ERC20: Account must not be excluded");
        _reflectionExcluded[account] = true;
    }

    function unclaimedReflection(address addr) public view returns (uint256) {
        if (addr == lpPair || addr == address(dexRouter)) return 0;

        uint256 basisDifference = ethReflectionBasis - lastReflectionBasis[addr];
        return (basisDifference * balanceOf(addr)) / _totalSupply;
    }

    /// @notice Claims reflection pool ETH
    /// @param addr The address to claim the reflection for
    function _claimReflection(address payable addr) internal {
        uint256 unclaimed         = unclaimedReflection(addr);
        lastReflectionBasis[addr] = ethReflectionBasis;
        if (unclaimed > 0) {
            addr.transfer(unclaimed);
        }
    }

    function claimReflection() external {
        _claimReflection(payable(msg.sender));
    }

    function _swap(uint256 amount) private {
        require(tradingActive == true, "ERC20: Trading is not active.");
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            devWallet,
            block.timestamp
        );
    }

    function _swapReflection(uint256 amount) private {
        require(tradingActive == true, "ERC20: Trading is not active.");
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    //@ Owner can remove all the taxes
    function removeAllTax() public onlyOwner {
        require(taxRate > 0, "ERC20: Tax is already removed.");
        taxRate = 0;
        taxDivPercentage = 0;
    }

    //@dev Owner can set or change Development wallet address
    function setDevWallet(address payable newDevWallet) public onlyOwner {
        require(newDevWallet != address(0), "ERC20: Can't set development wallet as null address.");
        devWallet = newDevWallet;
    }

    //@dev Owner can set all the taxes
    function setTaxes(uint256 tax) public onlyOwner {
        require(tax <= 100, "ERC20: The percentage can't more 100.");
        taxRate = tax;
    }

    //@dev Owner can set the division of taxes between Development Tax and Burn/LP/Reflection
    //the given percentage will go to the three functionalites
    function setTaxDivPercentage(uint256 percentage) public onlyOwner {
        require(percentage <= 100, "ERC20: The percentage can't more then 100");
        taxDivPercentage = percentage;
    }

    //@dev Owner can set address which are excluded from paying tax
    function excludeFromTax(address account) public onlyOwner {
        require(!_isExcludedFromTax[account], "ERC20: Account is already excluded.");
        _isExcludedFromTax[account] = true;
    }

    //@dev Owner can add back addresses to pay tax
    function includeInTax(address account) public onlyOwner {
        require(_isExcludedFromTax[account], "ERC20: Account is already included.");
        _isExcludedFromTax[account] = false;
    }

    //@dev Generating Random number
    function _generateRandomNumber() private view returns (uint256) {
        return (uint256(keccak256(abi.encodePacked( block.timestamp, block.difficulty, block.gaslimit, tx.origin, block.number, tx.gasprice))) % 3) + 1;
    }

    function _getTaxAmount(uint256 _tax) private view returns (uint256 _devAmount, uint256 Burn, uint256 LP, uint256 Reflection) {
        uint256 devAmount;
        uint256 burnAmount;
        uint256 lpAmount;
        uint256 reflectionAmount;

        if (taxRate > 0) {
            devAmount = _tax.mul((100 - taxDivPercentage)).div(100);
            burnAmount = _tax.mul(taxDivPercentage).div(100);
            lpAmount = _tax.mul(taxDivPercentage).div(100);
            reflectionAmount = _tax.mul(taxDivPercentage).div(100);
        }
        return (devAmount, burnAmount, lpAmount, reflectionAmount);
    }

    function checkExludedFromTax(address account) public view returns (bool) {
        return _isExcludedFromTax[account];
    }

    function recoverAllEth() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function recoverErc20token(address token, uint256 amount) public onlyOwner {
        IERC20(token).transfer(owner(), amount);
    }

    function addLiquidity(uint256 tokens) external payable onlyOwner {
        //_approve(address(this), address(dexRouter), tokens);

        dexRouter.addLiquidityETH{value: msg.value}(
            address(this),
            tokens,
            0,
            0,
            owner(),
            block.timestamp
        );
    }
}