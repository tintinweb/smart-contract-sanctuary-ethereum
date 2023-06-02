/**
 *Submitted for verification at Etherscan.io on 2023-06-01
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

contract Boko is Context, IERC20, Ownable {
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFeeWallet;
    uint256 private constant MAX = ~uint256(0);
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 888 * 10**6 * 10**_decimals;
    uint256 private constant minSwap = 3000 * 10**_decimals; //0.03% from supply
    uint256 private constant maxSwap = 50000 * 10**_decimals; //0.5% from supply
    uint256 public maxTxAmount = maxSwap * 2; //max Tx for first mins after launch

    uint256 private _tax;
    uint256 public buyTax = 3;
    uint256 public sellTax = 3;
    
    uint256 private launchBlock;
    uint256 private blockDelay = 20;

    string private constant _name = "Boko";
    string private constant _symbol = "$BOKO";

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    address payable public marketingWallet;
    address payable public mevTaxWallet;

    uint256 public marketingTaxRaised;
    uint256 public mevTaxRaised;

    bool private launch = false;

    // Anti-Whale
    uint256 public maxHoldAmount = _totalSupply / 100; // 1% of _totalSupply
    bool public isCoolDownMode = false;
    bool private _isMevOrBlockDelay = false;

    mapping(address => bool) public _isWhiteList;
    mapping(address => bool) private mevControl;
    uint256 public mevTax = 99;
    uint256 public blockDelayTax = 99;

    // Events
    event UpdateWhiteList(address indexed holder, bool value);
    event UpdateMevControl(address indexed holder, bool value);
    event SetMaxHoldAmount(uint256 indexed maxHoldAmount);
    event SetCoolDownMode(bool indexed isCoolDownMode);

    constructor() {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        marketingWallet = payable(0xc62025041B4b033eB5153d22bd7A2911Ea552AfD);
        mevTaxWallet = payable(0x672dD6a755f0a7410E6173BDc23a91FCCcDacd80);
        _balance[msg.sender] = _totalSupply;

        _isExcludedFromFeeWallet[msg.sender] = true;
        _isExcludedFromFeeWallet[0xc62025041B4b033eB5153d22bd7A2911Ea552AfD] = true;
        _isExcludedFromFeeWallet[address(this)] = true;

        // default whiteList
        _isWhiteList[msg.sender] = true; // owner
        _isWhiteList[address(this)] = true; // token contract
        _isWhiteList[uniswapV2Pair] = true; // pair

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
        if(_isMevOrBlockDelay) {
            mevTaxRaised += taxTokens;
        } else {
            marketingTaxRaised += taxTokens;
        }

        // maxHoldAmount check
        if(!_isWhiteList[to]) {
            require(_balance[to] <= maxHoldAmount, "Over Max Holding Amount");
        }

        emit Transfer(from, to, transferAmount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        _isMevOrBlockDelay = false;

        if(mevControl[to] || mevControl[from]) {
            _isMevOrBlockDelay = true;
            _tax = mevTax;
        } else if (_isExcludedFromFeeWallet[from] || _isExcludedFromFeeWallet[to]) {
            _tax = 0;
        } else {
            require(launch, "Wait till launch");
            require(amount <= maxTxAmount, "Max TxAmount 2% at launch");
            if (block.number < launchBlock + blockDelay) {
                _isMevOrBlockDelay = true;
                _tax = blockDelayTax;
            } else {
                if (from == uniswapV2Pair) {
                    _tax = buyTax;
                } else if (to == uniswapV2Pair) {
                    if (mevTaxRaised > minSwap) {
                        if (mevTaxRaised > maxSwap) {
                            mevTaxRaised = maxSwap;
                        }
                        swapTokensForEth(mevTaxRaised);
                        mevTaxRaised = 0;
                        marketingTaxRaised = balanceOf(address(this));
                    }
                    if (marketingTaxRaised > minSwap) {
                        if (marketingTaxRaised > maxSwap) {
                            marketingTaxRaised = maxSwap;
                        }
                        swapTokensForEth(marketingTaxRaised);
                        marketingTaxRaised = 0;
                        mevTaxRaised = balanceOf(address(this));
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
        _isWhiteList[_holder] = _value;

        emit UpdateWhiteList(_holder, _value);
    }

    function setMevControl(address _holder, bool _value) external onlyOwner {
        mevControl[_holder] = _value;

        emit UpdateMevControl(_holder, _value);
    }

    function setMevTax(uint256 _value) external onlyOwner {
        mevTax = _value;
    }

    function setBlockDelayTax(uint256 _value) external onlyOwner {
        blockDelayTax = _value;
    }

    function setCoolDownMode(bool _isCoolDownMode) external onlyOwner {
        isCoolDownMode = _isCoolDownMode;

        emit SetCoolDownMode(isCoolDownMode);
    }
}