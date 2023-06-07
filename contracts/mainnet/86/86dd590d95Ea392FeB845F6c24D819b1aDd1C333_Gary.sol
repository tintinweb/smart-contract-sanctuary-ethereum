/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

//  _______  __    __    ______  __  ___ 
// |   ____||  |  |  |  /      ||  |/  / 
// |  |__   |  |  |  | |  ,----'|  '  /  
// |   __|  |  |  |  | |  |     |    <   
// |  |     |  `--'  | |  `----.|  .  \  
// |__|      \______/   \______||__|\__\ 
//                                       
//   _______      ___      .______     ____    ____ 
//  /  _____|    /   \     |   _  \    \   \  /   / 
// |  |  __     /  ^  \    |  |_)  |    \   \/   /  
// |  | |_ |   /  /_\  \   |      /      \_    _/   
// |  |__| |  /  _____  \  |  |\  \----.   |  |     
//  \______| /__/     \__\ | _| `._____|   |__|     
                                               
// Twitter: https://twitter.com/FuckGary2023
// Telegram: https://t.me/fuck_Gary
// Website: https://fuckgary.xyz

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

}

contract Gary is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private isExcluded;
   
    uint8 private _decimals = 18;
    uint256 private _tTotal;
    uint256 public supply = 417202100000000 * (10 ** 18);

    string private _name = "Fuck Gary";
    string private _symbol = "Gary";

    address public router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public initPoolAddress;
    address cexAddress = 0xbb1Dfe96b533e30aAEF18f7dE01819a5b8B7dEdb;

    mapping(address => bool) public ammPairs;

    uint256 launchedBlock;
    uint256 private firstBlock = 1;
    uint256 private secondBlock = 3;

    mapping (uint256 => uint256) public tradingCount;
    uint256 tradingCountLimit = 7;
    uint256 tradingAmountLimit = supply / 100;
    
    constructor () {
        initPoolAddress = owner();
        _tOwned[initPoolAddress] = supply;
        _tTotal = supply;

        isExcluded[address(msg.sender)] = true;
        isExcluded[initPoolAddress] = true;
        isExcluded[cexAddress] = true;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);

        address ethPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        ammPairs[ethPair] = true;

        emit Transfer(address(0), initPoolAddress, _tTotal);
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

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Gary: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "Gary: decreased allowance below zero"));
        return true;
    }

    receive() external payable {}

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Gary: approve from the zero address");
        require(spender != address(0), "Gary: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "Gary: transfer from the zero address");
        require(amount > 0, "Gary: transfer amount must be greater than zero");

        uint256 fee;

        if(ammPairs[to] && IERC20(to).totalSupply() == 0){
            launchedBlock = block.number;
        }

        if(isExcluded[from] || isExcluded[to]){
            return _tokenTransfer(from,to,amount,fee); 
        }

        uint256 currentBlock = block.number;

        if (ammPairs[from]) {
            if (currentBlock - launchedBlock < firstBlock + 1) {
                fee = amount.mul(95).div(100);
            } else if (currentBlock - launchedBlock < secondBlock + 1) {
                tradingCount[currentBlock] = tradingCount[currentBlock] + 1;
                if (tradingCount[currentBlock] > tradingCountLimit) {
                    fee = amount.mul(95).div(100);
                }
            }
            if (currentBlock - launchedBlock < secondBlock + 1) {
                require(amount <= tradingAmountLimit, "Gary: Trading limit");
            }
        }

        _tokenTransfer(from,to,amount,fee);
    }

    function _tokenTransfer(address sender, address recipient, uint256 tAmount, uint256 fee) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tAmount.sub(fee));
        emit Transfer(sender, recipient, tAmount.sub(fee));
        
        if (fee > 0) {
            _tOwned[address(this)] = _tOwned[address(this)].add(fee);
            emit Transfer(sender, address(this), fee);
        }
    }

    function setTradingLimit(uint256 _tradingCountLimit, uint256 _tradingAmountLimit)external onlyOwner{
        tradingCountLimit = _tradingCountLimit;
        tradingAmountLimit = _tradingAmountLimit;
    }

    function setBlocks(uint256 _firstBlock, uint256 _secondBlock) external onlyOwner{
        firstBlock = _firstBlock;
        secondBlock = _secondBlock;
    }

    function muliSetExclude(address[] calldata users, bool _isExclude) external onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            isExcluded[users[i]] = _isExclude;
        }
    }

    function setAmmPair(address pair,bool hasPair) external onlyOwner {
        ammPairs[pair] = hasPair;
    }

    function withDraw(address _token, uint256 _amount, address _to) external onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }

}