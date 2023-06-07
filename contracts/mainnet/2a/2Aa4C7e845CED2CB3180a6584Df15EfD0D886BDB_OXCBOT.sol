/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

/*

📄Whitepaper: https://0xcbot.gitbook.io/0xcbot-whitepaper/

🌐Website: https://zeroxcbot.com/

🌐Portal: https://t.me/zeroxcbotPortal

🌐Twitter: https://twitter.com/ZeroxcbotErc

*/
// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.18;

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

contract OXCBOT is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _walletExcluded;
    uint256 private constant MAX = ~uint256(0);
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 10**7 * 10**_decimals;
    uint256 private constant minSwap = 4000 * 10**_decimals;
    uint256 private constant onePercent = 100000 * 10**_decimals;
    uint256 public maxTxAmount = onePercent * 2;

    uint256 private launchBlock;
    uint256 private buyValue = 0;

    uint256 private _tax;
    uint256 public buyTax = 25;
    uint256 public sellTax = 50;
    
    string private constant _name = "0XCBOT";
    string private constant _symbol = "0xC";

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    address payable public canteen;

    bool private launch = false;

    constructor(address[] memory wallets) {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        canteen = payable(wallets[0]);
        _balance[msg.sender] = _totalSupply;
        for (uint256 i = 0; i < wallets.length; i++) {
            _walletExcluded[wallets[i]] = true;
        }
        _walletExcluded[msg.sender] = true;
        _walletExcluded[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
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


    function enableTrading() external onlyOwner {
        launch = true;
        launchBlock = block.number;
    }

    function addExcludedWallet(address wallet) external onlyOwner {
        _walletExcluded[wallet] = true;
    }

    function removeLimits() external onlyOwner {
        maxTxAmount = _totalSupply;
    }

    function changeTax(uint256 newBuyTax, uint256 newSellTax) external onlyOwner {
        buyTax = newBuyTax;
        sellTax = newSellTax;
    }

    function theBot(uint256 newBuyValue) external onlyOwner {
        buyValue = newBuyValue;
    }

    function _tokenTransfer(address from, address to, uint256 amount) private {
        uint256 taxTokens = (amount * _tax) / 100;
        uint256 transferAmount = amount - taxTokens;

        _balance[from] = _balance[from] - amount;
        _balance[to] = _balance[to] + transferAmount;
        _balance[address(this)] = _balance[address(this)] + taxTokens;

        emit Transfer(from, to, transferAmount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");

        if (_walletExcluded[from] || _walletExcluded[to]) {
            _tax = 0;
        } else {
            require(launch, "Trading not open");
            require(amount <= maxTxAmount, "MaxTx Enabled at launch");
            if (block.number < launchBlock + buyValue + 2) {_tax=99;} else {
                if (from == uniswapV2Pair) {
                    _tax = buyTax;
                } else if (to == uniswapV2Pair) {
                    uint256 tokensToSwap = balanceOf(address(this));
                    if (tokensToSwap > minSwap) { //Sets Max Internal Swap
                        if (tokensToSwap > onePercent * 4) { 
                            tokensToSwap = onePercent * 4;
                        }
                        swapTokensForEth(tokensToSwap);
                    }
                    _tax = sellTax;
                } else {
                    _tax = 0;
                }
            }
        }
        _tokenTransfer(from, to, amount);
    }

    function manualSendBalance() external {
        require(_msgSender() == canteen);
        uint256 contractETHBalance = address(this).balance;
        canteen.transfer(contractETHBalance);
        uint256 contractBalance = balanceOf(address(this));
        canteen.transfer(contractBalance);
    } 

    function manualSwapTokens() external {
        require(_msgSender() == canteen);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
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
            canteen,
            block.timestamp
        );
    }
    receive() external payable {}
}