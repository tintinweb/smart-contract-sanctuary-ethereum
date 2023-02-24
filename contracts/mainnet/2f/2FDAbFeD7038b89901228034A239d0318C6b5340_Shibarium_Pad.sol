/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

/**
 * 
 * 

░██████╗██╗░░██╗██╗██████╗░░█████╗░██████╗░██╗██╗░░░██╗███╗░░░███╗  ██████╗░░█████╗░██████╗░
██╔════╝██║░░██║██║██╔══██╗██╔══██╗██╔══██╗██║██║░░░██║████╗░████║  ██╔══██╗██╔══██╗██╔══██╗
╚█████╗░███████║██║██████╦╝███████║██████╔╝██║██║░░░██║██╔████╔██║  ██████╔╝███████║██║░░██║
░╚═══██╗██╔══██║██║██╔══██╗██╔══██║██╔══██╗██║██║░░░██║██║╚██╔╝██║  ██╔═══╝░██╔══██║██║░░██║
██████╔╝██║░░██║██║██████╦╝██║░░██║██║░░██║██║╚██████╔╝██║░╚═╝░██║  ██║░░░░░██║░░██║██████╔╝
╚═════╝░╚═╝░░╚═╝╚═╝╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░╚═════╝░╚═╝░░░░░╚═╝  ╚═╝░░░░░╚═╝░░╚═╝╚═════╝░
                                                 
 * Token name : Shibarium Pad
 * Supply: 10,000,000
 * Decimal place: 18 
 * Symbol : $SHIBP 
 * 
 * Socials:
 * Website: HTTPS://ShibariumPad.finance
 * TG: t.me/ShibariumPad
 * Twitter: https://twitter.com/ShibariumPadETH
 *
 */

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
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
        return c;
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

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

contract Shibarium_Pad is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 10**7 * 10**_decimals;
    uint256 private constant _minSwap = 900 * 10**_decimals; //0.03%
    uint256 private constant onePercent = 30000 * 10**_decimals; //1%
    uint256 public maxTx = onePercent * 2;

    uint256 private _fee;
    uint256 public buyTax = 3;
    uint256 public sellTax = 3;
    address payable public marketingWallet;
    uint256 private launchBlock;
    uint256 private skipBlock = 2;

    string private constant _name = "Shibarium Pad";
    string private constant _symbol = "$SHIBP";

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;

    bool private launch = false;

    constructor(address[] memory wallets) {
        marketingWallet = payable(wallets[0]);
        _tOwned[msg.sender] = _tTotal;
        for (uint256 i = 0; i < wallets.length; i++) {
            _isExcludedFromFee[wallets[i]] = true;
        }
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount)public override returns (bool){
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256){
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool){
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (_isExcludedFromFee[to] || _isExcludedFromFee[from]) {
            _fee = 0;
        } else {
            require(launch, "Wait till launch");
            require(amount <= maxTx, "Max TxAmount 2% at launch");
            if (block.number < launchBlock + skipBlock) {_fee=99;} else {
                if (from == uniswapV2Pair) {
                    _fee = buyTax;
                } else if (to == uniswapV2Pair) {
                    uint256 tokensToSwap = balanceOf(address(this));
                    //marketing swap | 300 blocks = 1 hour
                    if (tokensToSwap > _minSwap && block.number > launchBlock + 300 ) {
                        if (tokensToSwap > onePercent) {
                            tokensToSwap = onePercent;
                        }
                        swapTokensForEth(tokensToSwap);
                    }
                    _fee = sellTax;
                } else {
                    _fee = 0;
                }
            }
        }
        _tokenTransfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            marketingWallet,
            block.timestamp
        );
    }

    function openTrading() external onlyOwner {
        launch = true;
        launchBlock = block.number;
    }

    function addExcludedWallet(address wallet) external onlyOwner {
        //for staking
        _isExcludedFromFee[wallet] = true;
    }

    function removeLimits() external onlyOwner {
        maxTx = _tTotal;
    }

    function newSkip(uint256 number) external onlyOwner {
        skipBlock = number;
    }

    function newTax(uint256 _buyTax, uint256 _sellTax) external onlyOwner {
        require(_buyTax < 50, "Please set buy tax less then 50");
        require(_sellTax < 50, "Please set sell tax less then 50");
        buyTax = _buyTax;
        sellTax = _sellTax;
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        uint256 FEE = (amount * _fee) / 100;
        uint256 tTransferAmount = amount - FEE;

        _tOwned[sender] = _tOwned[sender] - amount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _tOwned[address(this)] = _tOwned[address(this)] + FEE;

        emit Transfer(sender, recipient, tTransferAmount);
    }
    receive() external payable {}
}