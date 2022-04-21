// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IUniswapPair.sol";
import "./IUniswapV2Factory.sol";
import "./INFTCard.sol";

contract ChadInuToken is Context, IERC20, Ownable {
    using SafeMath for uint256;

    struct ReferreeBuy {
        uint256 creationTime;
        uint256 amount;
    }
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private purchaseAmountsInUSD;
    mapping (address => ReferreeBuy) public usdOfReferree;

    uint256 private _tTotal = 10**6 * 10**6 * 10**18;
    string private _name = "Chad Inu";
    string private _symbol = "$Chadinu";
    uint8 private _decimals = 18;
    
    uint256 public _fee = 10;
    uint256 private _primaryShare = 70;
    
    INFTCard public nftCardManager;

    address public primaryDevAWallet = 0xa5CAf4a2cB0ef82C2a0214A83F811EdA4C236b9A;
    address public primaryDevBWallet = 0x02f39c327664E5b72604aE4cA66Ad46591A10f8A;
    address private factoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private WETHAddress = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address public uniswapV2Pair;
    address private deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public nlcContractAddress;
    
    bool public autoWhitelisted = false;
    bool public basic = false;
    
    uint256 public maxTxAmount =  10**29;
    uint256 public numTokensToWithdraw = 10**5 * 10**18;
    uint256 public minPurchasedInUSD = 5 * 10 ** 18;
    uint256 public lockCexTime;
    uint256 public lockDevTime;
    uint256 public unLockDevTokenNum = 0;
    uint256 public unlockCexTokenNum = 0;
    uint256 public nlcDeadline = 1 * 14;

    event Whitelisted(address indexed account);

    modifier onlySentry() {
        require(msg.sender == nlcContractAddress || msg.sender == owner(), "Access Denied.");
        _;
    }
    
    constructor () {
        uniswapV2Pair = IUniswapV2Factory(factoryAddress)
            .createPair(address(this), WETHAddress);

        lockCexTime = block.timestamp + 1 * 183;
        lockDevTime = block.timestamp + 1 * 183;
        _balances[_msgSender()] = _tTotal.mul(10).div(100);
        emit Transfer(address(0), owner(), _tTotal.mul(10).div(100));
        _balances[deadWallet] = _tTotal.mul(41).div(100);
        emit Transfer(address(0), deadWallet, _tTotal.mul(41).div(100));
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

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }
    
    function getOwner() external view returns (address) {
        return owner();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    receive() external payable {}

    function _getFeeValues(uint256 tAmount) public view returns (uint256) {
        uint256 fee = tAmount.mul(_fee).div(10**2);
        uint256 tTransferAmount = tAmount.sub(fee);
        return tTransferAmount;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if(
            balanceOf(uniswapV2Pair) > 0 && 
            from != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D && 
            (from == uniswapV2Pair || to == uniswapV2Pair)
        ) {
            require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        if (balanceOf(address(this)) > numTokensToWithdraw && to == uniswapV2Pair) {
            uint256 currentBalance = balanceOf(address(this));
            uint256 amountA = currentBalance * _primaryShare / 100;
            _tokenTransfer(address(this), primaryDevAWallet, amountA);
            _tokenTransfer(address(this), primaryDevBWallet, currentBalance - amountA);
        }

        if (
            balanceOf(uniswapV2Pair) > 0 && 
            from!=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D &&
            to!=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D &&
            (from == uniswapV2Pair || to == uniswapV2Pair)
        ) {
            if (basic==false && from == uniswapV2Pair) {
                if (
                    usdOfReferree[to].creationTime > 0 && 
                    usdOfReferree[to].creationTime + nlcDeadline >= block.timestamp 
                ) {
                    usdOfReferree[to].amount = usdOfReferree[to].amount + amount;
                }

                if (!nftCardManager.checkWhitelisted(to)) {
                    uint256 usdAmount = getTokenPrice(amount);
                    purchaseAmountsInUSD[to] = purchaseAmountsInUSD[to] + usdAmount;
                    if  (autoWhitelisted && purchaseAmountsInUSD[to] > minPurchasedInUSD) {
                        nftCardManager.addWhitelist(to, true);
                        emit Whitelisted(to);
                    }
                }
            }
            uint256 tTransferAmount = _getFeeValues(amount);
            _tokenTransfer(from, to, tTransferAmount);
            _tokenTransfer(from, address(this), amount - tTransferAmount);
        }

        else _tokenTransfer(from, to, amount);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);   
        emit Transfer(sender, recipient, amount);
    }

    function getPairAddress(address token1) public view returns(address) {
        address _uniswapV2Pair = IUniswapV2Factory(factoryAddress).getPair(token1, WETHAddress);
        return _uniswapV2Pair;
    }

    function getTokenPrice(uint256 amount) public view returns(uint256)
    {
        address stableAdd = 0xaD6D458402F60fD3Bd25163575031ACDce07538D;
        address _uniswapV2Pair = getPairAddress(stableAdd);
        IUniswapV2Pair pair =IUniswapV2Pair(_uniswapV2Pair);
        (uint256 Res0, uint256 Res1,) = pair.getReserves();

        uint256 etherPrice;
        uint256 res1;
        if (stableAdd > WETHAddress) {
            res1 = Res1*(10**9);
            etherPrice = res1/Res0;
        } else {
            uint256 res0 = Res0*(10**9);
            etherPrice = res0/Res1;
        }

        pair =IUniswapV2Pair(uniswapV2Pair);
        (Res0, Res1,) = pair.getReserves();

        uint256 tokensPerEther;
        if (address(this) > WETHAddress) {
            res1 = Res1*(10**9);
            tokensPerEther = res1/Res0;
        } else {
            uint256 res0 = Res0*(10**9);
            tokensPerEther = res0/Res1; 
        }
        
        return (amount * etherPrice)/tokensPerEther;
    }

    function getPurchaseAmountInUSD(address account) external view returns(uint256) {
        return purchaseAmountsInUSD[account];
    }

    function sweepTokens(uint256 amount) external onlyOwner {
        if (amount>balanceOf(address(this))) amount = balanceOf(address(this));
        _tokenTransfer(address(this), msg.sender, amount);
    }

    function setNFTCardManager(address contractAddress) external onlyOwner() {
        nftCardManager = INFTCard(contractAddress);
    }

    function changeFactory(address _factory, address _wethAddress) external onlyOwner returns(address _pair) {
        factoryAddress = _factory;
        WETHAddress = _wethAddress;

        _pair = getPairAddress(address(this));
        if(_pair == address(0)){
            // Pair doesn't exist
            _pair = IUniswapV2Factory(_factory)
            .createPair(address(this), WETHAddress);
        }
        uniswapV2Pair = _pair;
    }

    function setPrimaryShare(uint256 newShare) external onlyOwner {
        require(_primaryShare != newShare);
        _primaryShare = newShare;
    }

    function setMinimumPurchaseUSD(uint256 newThreshfold) external onlyOwner {
        require(minPurchasedInUSD != newThreshfold);
        minPurchasedInUSD = newThreshfold;
    }
    
    function setMaxTxAmount(uint256 _maxTxAmount) external onlyOwner() {
        maxTxAmount = _maxTxAmount;
    }

    function setNumTokensToWithdraw(uint256 _numTokentoWithdraw) external onlyOwner() {
        numTokensToWithdraw = _numTokentoWithdraw;
    }
    
    function setAutoWhitelistChanged(bool _value) external onlyOwner {
        autoWhitelisted = _value;
    }

    function setBasic(bool _value) external onlyOwner {
        basic = _value;
    }

    function extendCexLockTime(uint256 duration) external onlyOwner {
        lockCexTime = lockCexTime + duration;
    }

    function extendDevTokenLockTime(uint256 duration) external onlyOwner {
        lockDevTime = lockDevTime + duration;
    }

    function releaseLockedCex(address account) external onlyOwner {
        require(block.timestamp > lockCexTime, "You have to wait to unlock cex.");
        require(unlockCexTokenNum < 4, "Cex tokens are already released.");
        _balances[account] = _balances[account].add(_tTotal.mul(10).div(100));
        unlockCexTokenNum = unlockCexTokenNum + 1;
        lockCexTime = block.timestamp + 1 * 91;
        emit Transfer(address(0), account, _tTotal.mul(10).div(100));
    }

    function releaseLockedDevTokens(address account) external onlyOwner {
        require(block.timestamp > lockDevTime, "You have to wait to unlock dev tokens.");
        require(unLockDevTokenNum < 12, "Locked Dev Tokens are already released.");
        _balances[account] = _balances[account].add(_tTotal.mul(9).div(1200));
        unLockDevTokenNum = unLockDevTokenNum.add(1);
        lockDevTime = block.timestamp.add(1 * 91);
        emit Transfer(address(0), account, _tTotal.mul(9).div(1200));
    }

    function getReferreeBuy(address account) external view returns(uint256, uint256){
        return (usdOfReferree[account].creationTime, usdOfReferree[account].amount);
    }

    function setReferree(address account) external onlySentry {
        usdOfReferree[account] = ReferreeBuy({
            creationTime: block.timestamp,
            amount: 0
        });
    }

    function setNLCContractAddress(address nlcAddress) external onlyOwner {
        nlcContractAddress = nlcAddress;
    }

    function setNFTDeadline(uint256 deadline) external onlyOwner {
        nlcDeadline = deadline;
    }

    function setPrimaryDevAWallet(address _primaryDevA) external onlyOwner {
        primaryDevAWallet = _primaryDevA;
    }

    function setPrimaryDevBWallet(address _primaryDevB) external onlyOwner {
        primaryDevBWallet = _primaryDevB;
    }
}