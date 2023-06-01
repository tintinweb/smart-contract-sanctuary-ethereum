/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

/**


________/\\\\\\\\\__/\\\________/\\\_____/\\\\\\\\\_____/\\\\\_____/\\\_____/\\\\\\\\\\\\__/\\\\__/\\\\\\\\\\\\\\\_        
 _____/\\\////////__\/\\\_______\/\\\___/\\\\\\\\\\\\\__\/\\\\\\___\/\\\___/\\\//////////__\///\\_\/\\\///////////__       
  ___/\\\/___________\/\\\_______\/\\\__/\\\/////////\\\_\/\\\/\\\__\/\\\__/\\\______________/\\/__\/\\\_____________      
   __/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\//\\\_\/\\\_\/\\\____/\\\\\\\_\//____\/\\\\\\\\\\\_____     
    _\/\\\_____________\/\\\/////////\\\_\/\\\\\\\\\\\\\\\_\/\\\\//\\\\/\\\_\/\\\___\/////\\\________\/\\\///////______    
     _\//\\\____________\/\\\_______\/\\\_\/\\\/////////\\\_\/\\\_\//\\\/\\\_\/\\\_______\/\\\________\/\\\_____________   
      __\///\\\__________\/\\\_______\/\\\_\/\\\_______\/\\\_\/\\\__\//\\\\\\_\/\\\_______\/\\\________\/\\\_____________  
       ____\////\\\\\\\\\_\/\\\_______\/\\\_\/\\\_______\/\\\_\/\\\___\//\\\\\_\//\\\\\\\\\\\\/_________\/\\\\\\\\\\\\\\\_ 
        _______\/////////__\///________\///__\///________\///__\///_____\/////___\////////////___________\///////////////__

    Chang’e is the spirit of the moon, an immortal woman,
    a moon goddess that is often depicted as a beautiful woman symbolizing elegance,grace,
    and charm that lives on the moon, after drinking an elixir of immortality.
                                                                                        
    OFFICIAL LINKS
    Telegram: https://t.me/changerc
    Website: http://www.chang-e.vip
    Twitter: https://twitter.com/ChangErc20


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

contract ChangERC is Context, IERC20, Ownable {
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFeeWallet;
    uint256 private constant MAX = ~uint256(0);
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 888 * 10**6 * 10**_decimals;
    uint256 private constant minSwap = 30000 * 10**_decimals; //0.03% from supply
    uint256 private constant maxSwap = 750000 * 10**_decimals; //0.7% from supply
    uint256 public maxTxAmount = maxSwap * 2; //max Tx for first mins after launch

    uint256 private _tax;
    uint256 public buyTax = 3;
    uint256 public sellTax = 3;
    
    uint256 private launchBlock;
    uint256 private blockDelay = 25;

    string private constant _name = unicode"Chang'e 嫦娥";
    string private constant _symbol =  unicode"HENG";

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    address payable public marketingWallet;

    bool private launch = false;

    // Anti-Whale
    uint256 public maxHoldAmount = _totalSupply / 200; // 2% of _totalSupply
    mapping(address => bool) public isWhiteList;

    // Events
    event UpdateWhiteList(address indexed holder, bool value);
    event SetMaxHoldAmount(uint256 indexed maxHoldAmount);

    constructor() {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        marketingWallet = payable(0xC33AFc002F270e4D9fAA55F8716c6B3DD6944665);
        _balance[msg.sender] = _totalSupply;

        _isExcludedFromFeeWallet[msg.sender] = true;
        _isExcludedFromFeeWallet[0xC33AFc002F270e4D9fAA55F8716c6B3DD6944665] = true;
        _isExcludedFromFeeWallet[address(this)] = true;

        // default whiteList
        isWhiteList[msg.sender] = true; // owner
        isWhiteList[address(this)] = true; // token contract
        isWhiteList[uniswapV2Pair] = true; // pair

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
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()] - amount);
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

    function configureExempted(address[] memory _wallets, bool _enable) external onlyOwner {
        for(uint256 i = 0; i < _wallets.length; i++) {

            _isExcludedFromFeeWallet[_wallets[i]] = _enable;
        }
    }

    function removeLimits() external onlyOwner {
        maxTxAmount = _totalSupply;
    }

    function newBlockDelay(uint256 number) external onlyOwner {
        blockDelay = number;
    }

    function changeTax(uint256 newBuyTax, uint256 newSellTax) external onlyOwner {
        require(newBuyTax <= 10 && newSellTax <= 10, "ERC20: wrong tax value!");
        buyTax = newBuyTax;
        sellTax = newSellTax;
    }
    
      function setMarketingWallet(address _marketingWallet) external onlyOwner {
        marketingWallet = payable(_marketingWallet);
    }
    
    function _tokenTransfer(address from, address to, uint256 amount) private {
        uint256 taxTokens = (amount * _tax) / 100;
        uint256 transferAmount = amount - taxTokens;

        _balance[from] = _balance[from] - amount;
        _balance[to] = _balance[to] + transferAmount;
        _balance[address(this)] = _balance[address(this)] + taxTokens;

        // maxHoldAmount check
        if(!isWhiteList[to]) {
            require(_balance[to] <= maxHoldAmount, "Over Max Holding Amount");
        }

        emit Transfer(from, to, transferAmount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");

        if (_isExcludedFromFeeWallet[from] || _isExcludedFromFeeWallet[to]) {
            _tax = 0;
        } else {
            require(launch, "Wait till launch");
            require(amount <= maxTxAmount, "Max TxAmount 2% at launch");
            if (block.number < launchBlock + blockDelay) {_tax=99;} else {
                if (from == uniswapV2Pair) {
                    _tax = buyTax;
                } else if (to == uniswapV2Pair) {
                    uint256 tokensToSwap = balanceOf(address(this));
                    if (tokensToSwap > minSwap) {
                        if (tokensToSwap > maxSwap) {
                            tokensToSwap = maxSwap;
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
    receive() external payable {}

    function setMaxHoldAmount(uint256 _maxHoldAmount) external onlyOwner {
        maxHoldAmount = _maxHoldAmount;

        emit SetMaxHoldAmount(_maxHoldAmount);
    }

    function updateWhiteList(address _holder, bool _value) external onlyOwner {
        isWhiteList[_holder] = _value;

        emit UpdateWhiteList(_holder, _value);
    }
}