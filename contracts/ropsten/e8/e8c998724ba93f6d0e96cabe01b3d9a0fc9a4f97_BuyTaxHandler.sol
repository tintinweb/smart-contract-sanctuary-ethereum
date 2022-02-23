//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * SAFEMATH LIBRARY
 */
library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

interface ITaxHandler {
    function process() external;
    function setRewardPool(address _address) external;
    function setLiquidityPool(address _address) external;
    function setDevPool(address _address) external;
}

contract BuyTaxHandler is ITaxHandler,Auth {
    using SafeMath for uint256;
    address BUSD = 0x110a13FC3efE6A245B50102D2d79B3E76125Ae83;
    address public rewardPool;
    address public liquidityPool;
    IERC20 public token;
    uint256 public taxToReward;
    uint256 public taxToLiquidity;

    IDEXRouter public router;

    constructor(address _router) Auth(msg.sender){
        token = IERC20(msg.sender);
        router = IDEXRouter(_router);
    }
    function process() external override {
        uint256 amount = token.balanceOf(address(this));
        if(amount>0) {
            uint256 amountForReward = amount.mul(taxToReward).div(taxToLiquidity+taxToReward);
            uint256 amountForLiquidity = amount.sub(amountForReward);
            token.transfer(rewardPool, amountForReward);
            address[] memory path = new address[](2);
            path[0] = address(token);
            path[1] = BUSD;
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountForLiquidity,
                0,
                path,
                liquidityPool,
                block.timestamp
            );
        }
    }

    function setRewardPool(address _address) external override authorized {
        rewardPool = _address;
    }
    function setLiquidityPool(address _address) external override authorized {
        liquidityPool = _address;
    }
    function setDevPool(address _address) external override {
        
    }
}

contract SellTaxHandler is ITaxHandler,Auth {
    using SafeMath for uint256;
    address BUSD = 0x110a13FC3efE6A245B50102D2d79B3E76125Ae83;
    address rewardPool;
    address liquidityPool;
    address devPool;
    IERC20 public token;
    uint256 public taxToReward;
    uint256 public taxToLiquidity;
    uint256 public taxToDev;

    IDEXRouter public router;

    constructor(address _router) Auth(msg.sender){
        token = IERC20(msg.sender);
        router = IDEXRouter(_router);
    }
    function process() external override {
        uint256 amount = token.balanceOf(address(this));
        if(amount>0) {
            uint256 amountForReward = amount.mul(taxToReward).div(taxToLiquidity+taxToReward+taxToDev);
            uint256 amountForDevLq = amount.sub(amountForReward);
            token.transfer(rewardPool, amountForReward);
            address[] memory path = new address[](2);
            path[0] = address(token);
            path[1] = BUSD;
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountForDevLq,
                0,
                path,
                address(this),
                block.timestamp
            );
            uint256 busdAmount = IERC20(BUSD).balanceOf(address(this));
            IERC20(BUSD).transfer(liquidityPool,busdAmount.mul(taxToLiquidity).div(taxToLiquidity+taxToDev));
            IERC20(BUSD).transfer(devPool, busdAmount.mul(taxToDev).div(taxToLiquidity+taxToDev));
        }
    }

    function setRewardPool(address _address) external override authorized {
        rewardPool = _address;
    }

    function setLiquidityPool(address _address) external override authorized {
        liquidityPool = _address;
    }
    function setDevPool(address _address) external override authorized {
        devPool = _address;
    }
}


contract BloodStone is IERC20, Auth {
    using SafeMath for uint256;

    address public BUSD = 0x110a13FC3efE6A245B50102D2d79B3E76125Ae83;
    
    string constant _name = "Crypto Legions Bloodstone";
    string constant _symbol = "BLOODSTONE";
    uint8 constant _decimals = 18;
    
    uint256 _totalSupply = 5000000 * (10 ** _decimals);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    uint256 public sellTaxReward = 300;
    uint256 public sellTaxLiquidity = 400;
    uint256 public sellTaxDev = 100;
    uint256 public buyTaxLiquidity = 100;
    uint256 public buyTaxReward = 100;
    uint256 feeDenominator = 10000;
    
    address public rewardPool;
    address public liquidityPool;
    address public devWallet;
    
    IDEXRouter public router;
    address public pair;
    bool public addingLiquidity;

    ITaxHandler public buyTaxHandler;
    ITaxHandler public sellTaxHandler;

    constructor (
        address _dexRouter
    ) Auth(msg.sender) {
        router = IDEXRouter(_dexRouter);
        addingLiquidity = true;
        pair = IDEXFactory(router.factory()).createPair(BUSD, address(this));

        buyTaxHandler = new BuyTaxHandler(_dexRouter);
        sellTaxHandler = new SellTaxHandler(_dexRouter);

        _allowances[address(this)][address(router)] = _totalSupply;

        approve(_dexRouter, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(sender==address(pair)) { // When purchasing BLST in BUSD
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
            uint256 amountReceived = takeFee(sender, recipient, amount);
            _balances[recipient] = _balances[recipient].add(amountReceived);
            emit Transfer(sender, recipient, amountReceived);
            return true;
        } else if(!addingLiquidity && recipient==address(pair)) { //When selling token
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
            uint256 amountReceived = takeFee1(sender, recipient, amount);
            _balances[recipient] = _balances[recipient].add(amountReceived);
            emit Transfer(sender, recipient, amountReceived);
            return true;
        } else {
            return _basicTransfer(sender, recipient, amount);
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 buyTaxAmount = amount.mul(buyTaxReward+buyTaxLiquidity).div(feeDenominator);
        _balances[address(buyTaxHandler)] = _balances[address(buyTaxHandler)].add(buyTaxAmount);
        emit Transfer(sender, address(buyTaxHandler), buyTaxAmount);
        return amount.sub(buyTaxAmount);
    }

    function takeFee1(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(sellTaxDev+sellTaxLiquidity+sellTaxReward).div(feeDenominator);
        _balances[address(sellTaxHandler)] = _balances[address(sellTaxHandler)].add(feeAmount);
        emit Transfer(sender, address(sellTaxHandler), feeAmount);
        return amount.sub(feeAmount);
    }

    function setFees(uint256 _taxFee, uint256 _feeDenominator) external authorized {

    }

    function setAddingLiquidity(bool _addingLiquidity) external onlyOwner {
        addingLiquidity = _addingLiquidity;
    }

    function setRewadPool(address _address) external onlyOwner {
        buyTaxHandler.setRewardPool(_address);
        sellTaxHandler.setRewardPool(_address);
    }
    function setLiquidityPool(address _address) external onlyOwner {
        buyTaxHandler.setLiquidityPool(_address);
        sellTaxHandler.setLiquidityPool(_address);
    }
    function setDevPool(address _address) external onlyOwner {
        sellTaxHandler.setDevPool(_address);
    }
}