/**
 *Submitted for verification at Etherscan.io on 2022-03-02
*/

/**
 *Submitted for verification at BscScan.com on 2022-02-24
*/

/**
 *Submitted for verification at BscScan.com on 2022-02-24
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

interface IBEP20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed owner, address indexed to, uint value);
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}


library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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

interface ISwapProxy {
    function swapAndLiquify(uint256 contractTokenBalance) external;
}

contract BEP20 is Context, Ownable, IBEP20 {
    using SafeMath for uint;
    using Address for address;

    mapping (address => uint) internal _balances;
    mapping (address => mapping (address => uint)) internal _allowances;
    mapping (address => bool) private _isExcluded;
    mapping(address => address) public inviter;
    mapping (address => bool) public isMarketPair;
    mapping (address => bool) public isRouter;

    uint public totalBurn;
    
    uint internal _totalSupply;

    uint256 public _taxFee = 11;
    uint256 public _burnFee = 1;
    uint256 public _lpFee = 3;
    uint256 public _liquidityFee = 2;
    uint256 public _inviterFee = 2;
    uint256 public _fundFee = 1;
    uint256 public _marketingFee = 2; 
    bool    public _sellFeeEnable = true;
    bool    public _buyFeeEnable = true;
    uint256 private numTokensSellToAddToLiquidity = 5 * 10 ** 18;
    uint256 public _maxHolder = 30 * 10 ** 18;
    uint256 public _maxBuy = 5 * 10 ** 18;
    bool    private inSwapAndLiquify;

    address public Fund = 0xfa5bD39C90Df0719Df423Fd29d9167C4Ef69acaF;
    address public Marketing = 0x7e04406880De4CBD70EcE86BE53a4DF739035DfB;
    address public Lp = 0x785F48d19D2ee5b85A516D26405EE2bcF942A61a;
    address public DeadAddress = 0x000000000000000000000000000000000000dEaD;
    address public NoViterFee = 0xE978974192c8BC0Da6177962dD5C0438b25B21C9;

    IPancakeRouter02 public uniswapV2Router;
    address public uniswapPair;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () internal {
        uniswapV2Router = IPancakeRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapPair = IPancakeFactory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());

        _isExcluded[owner()] = true;
        _isExcluded[address(this)] = true;
        isMarketPair[uniswapPair] = true;
        isRouter[address(uniswapV2Router)] = true;
    }

    receive() external payable {}
  
    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public override  returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address towner, address spender) public view override returns (uint) {
        return _allowances[towner][spender];
    }
    function approve(address spender, uint amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");

        if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            
            if ((_buyFeeEnable && isMarketPair[sender] && !isRouter[recipient])) {
                require(balanceOf(recipient).add(amount) <= _maxHolder, "max holder limit");
                require(amount <= _maxBuy, "buy limit");
            }
            if ((_sellFeeEnable && isMarketPair[recipient])) {
                require(balanceOf(sender) <= _maxHolder, "max holder limit");
                require(amount <= balanceOf(sender) * 9 / 10, "sell limit");
            }
            if (isRouter[sender] && !isMarketPair[recipient]) {
                require(balanceOf(recipient).add(amount) <= _maxHolder, "max holder limit");
                require(amount <= _maxBuy, "buy limit");
            }
        }

        if (inSwapAndLiquify) {
            _basicTransfer(sender, recipient, amount); 
        } else {
            // set invite
            bool shouldSetInviter = balanceOf(recipient) == 0 && inviter[recipient] == address(0) 
                && !Address.isContract(sender) && !Address.isContract(recipient);

            _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");

            _swap(recipient);

            uint256 netAmount = _takeFee(sender, recipient, amount);

            _balances[recipient] = _balances[recipient].add(netAmount);

            _burn(sender, recipient, amount);

            emit Transfer(sender, recipient, netAmount);

            if (shouldSetInviter) {
                inviter[recipient] = sender;
            }
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function testValue(address sender, address recipient) view external returns (bool) {
        return ((!isMarketPair[sender] && !isRouter[recipient]) && !_isExcluded[sender] && !_isExcluded[recipient]);
    }

    function _takeFee(address sender, address recipient, uint256 amount) internal returns (uint256 netAmount)  {

        uint256 tax = 0;

        if ((!isMarketPair[recipient] && isRouter[sender]) || (_buyFeeEnable && isMarketPair[sender]) || (_sellFeeEnable && isMarketPair[recipient])) {
            tax = amount.mul(_taxFee).div(100);
        }

        if ((isMarketPair[sender] && isRouter[recipient]) || _isExcluded[sender] || _isExcluded[recipient]) {
            tax = 0;
        }

        netAmount = amount - tax;
   
        if (tax > 0) {
            _takeLpFee(sender, Lp, tax);
            _takeLiquidityFee(sender, address(this), tax);
            _takeBurnFee(sender, DeadAddress, tax);
            _takeFundFee(sender, Fund, tax);
            _takeMarketingFee(sender, Marketing, tax);
            _takeInviterFee(sender, recipient, tax);
        }
    }

    function _takeLpFee(
        address sender,
        address recipient,
        uint256 tax) private {
        uint256 fee = tax.mul(_lpFee).div(_taxFee);
        _balances[recipient] = _balances[recipient].add(fee);
        emit Transfer(sender, recipient, fee);
    }

    function _takeLiquidityFee(
        address sender,
        address recipient,
        uint256 tax) private {
        uint256 fee = tax.mul(_liquidityFee).div(_taxFee);
        _balances[recipient] = _balances[recipient].add(fee);
        emit Transfer(sender, recipient, fee);
    }

    function _takeBurnFee(
        address sender,
        address recipient,
        uint256 tax) private {
        uint256 fee = tax.mul(_burnFee).div(_taxFee);
        _balances[recipient] = _balances[recipient].add(fee);
        _burn(sender, recipient, fee);
        emit Transfer(sender, recipient, fee);
    }

    function _takeFundFee(
        address sender,
        address recipient,
        uint256 tax) private {
        uint256 fee = tax.mul(_fundFee).div(_taxFee);
        _balances[recipient] = _balances[recipient].add(fee);
        emit Transfer(sender, recipient, fee);
    }

    function _takeMarketingFee(
        address sender,
        address recipient,
        uint256 tax) private {
        uint256 fee = tax.mul(_marketingFee).div(_taxFee);
        _balances[recipient] = _balances[recipient].add(fee);
        emit Transfer(sender, recipient, fee);
    }

    function _takeInviterFee(
        address sender,
        address recipient,
        uint256 tax
    ) private {
        if (_inviterFee == 0) return;
        uint256 fee = tax.mul(_inviterFee).div(_taxFee);
        address cur = sender;
        if (isMarketPair[sender]) {
            cur = recipient;
        } else if (isMarketPair[recipient]) {
            cur = sender;
        }
        cur = inviter[cur];
        if (cur == address(0)) {
            cur = NoViterFee;
        }

        _balances[cur] = _balances[cur].add(fee);
        emit Transfer(sender, cur, fee);
    }

    function _burn(address sender, address recipient, uint amount) private {
        if (recipient == address(0) || recipient == DeadAddress) {
            totalBurn = totalBurn.add(amount);
            _totalSupply = _totalSupply.sub(amount);

            emit Burn(sender, DeadAddress, amount);
        }
    }
 
    function _approve(address towner, address spender, uint amount) internal {
        require(towner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[towner][spender] = amount;
        emit Approval(towner, spender, amount);
    }

    function _swap(address recipient) internal {
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (overMinTokenBalance &&
            !inSwapAndLiquify &&
            isMarketPair[recipient]) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            // add liquidity
            swapAndLiquify(contractTokenBalance);
        }
    }


    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
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

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function excludeFrom(address account) external onlyOwner() {
        _isExcluded[account] = false;
    }

    function includeIn(address account) external onlyOwner() {
        _isExcluded[account] = true;
    }

    function setLpAddr(address _addr) external onlyOwner {
      Lp = _addr;
    }

    function setFundAddr(address _addr) external onlyOwner {
      Fund = _addr;
    }

    function setMarketingAddr(address _addr) external onlyOwner {
      Marketing = _addr;
    }

    function setNoViterFeeAddr(address _addr) external onlyOwner {
        NoViterFee = _addr;
    }

    function setSellToAddToLiquidity(uint256 _num) external onlyOwner {
        numTokensSellToAddToLiquidity = _num;
    }

    function setMarketPairStatus(address account, bool newValue) external onlyOwner {
        isMarketPair[account] = newValue;
    }

    function getMarketPairStatus(address account) external view returns (bool) {
        return isMarketPair[account];
    }

    function setSellFeeEnable(bool newValue) external onlyOwner() {
        _sellFeeEnable = newValue;
    }

    function setBuyFeeEnable(bool newValue) external onlyOwner() {
        _buyFeeEnable = newValue;
    }

    function getRecommender(address _addr) external view returns (address) {
        return inviter[_addr];
    }

    function setMaxHolder(uint256 _num) external onlyOwner() {
        _maxHolder = _num;
    }

    function setMaxBuy(uint256 _num) external onlyOwner() {
        _maxBuy = _num;
    }
}

contract BEP20Detailed is BEP20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory tname, string memory tsymbol, uint8 tdecimals) BEP20() internal {
        _name = tname;
        _symbol = tsymbol;
        _decimals = tdecimals;
        
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract StarToken is BEP20Detailed {

    constructor() BEP20Detailed("Star", "Star", 18) public {
        _totalSupply = 88000 * (10**18);
    
	    _balances[_msgSender()] = _totalSupply;

	    emit Transfer(address(0), _msgSender(), _totalSupply);
    }
  
    function takeOutTokenInCase(address _token, uint256 _amount, address _to) public onlyOwner {
        IBEP20(_token).transfer(_to, _amount);
    }
}