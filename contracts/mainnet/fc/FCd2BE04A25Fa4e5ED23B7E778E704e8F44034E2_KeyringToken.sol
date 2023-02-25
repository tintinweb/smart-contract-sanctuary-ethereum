/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

/*
KEYRING TOKEN

WEB: https://keyringtoken.com
TWITTER: twitter.com/keyringtoken
TELEGRAM: t.me/keyringtoken

Introduction
Blockchain is now recognized as a new field in IT. In recent years, there have been kits and services for blockchain 
development, and it has even come to be called the blockchain industry.
One of the biggest barriers to blockchain development is interoperability. Different blockchains cannot communicate 
with each other, and tokens cannot be transferred between them. Several projects have been launched to solve these 
problems. However, the blockchain industry is growing in size and services are fragmented. The Keyring Project focuses 
on the blockchain app industry, which has been developing remarkably in recent years, and aims to solve this interoperability 
problem as well as to create a new, fragmented blockchain service. There are some other problems that Keyring app solves 
as well such as complexity of dealing with crypto assets, currency risks, reliability problem and so on.
The main advantage of the Keyring app is that it combines innovative technologies, brand-new product ideas and leading 
business models in order to overcome the obstacles of the economy we live in.
Keyring token has multiple use cases and acting as a payment method and a tool in keyring app and developing a strong 
sense of community not only on the blockchain but in the real world as well. All the products and different parts of ecosystem 
come together to provide its users with all benefits of blockchain and Web3.
Keyring is pioneering the mass-adoption of DeFi by creating Non-Custodial, Institutional-Grade Investment Products for Core 
Crypto Assets and distributing them. Institutional Market via Keyring Advisors. The Keyring is built on Ethereum and will be built 
on Arbitrum, Ethereum's leading Layer 2 scaling chain soon. It is managed by Keyring team. blockchain services company, and 
governed by holders of the $KEYRING token.
About app
KEYRING offers a compact package for professional travelers to explore the Blockchain space from DeFi to Metaverse comfortably.
At first, KEYRING SWAP seems to be a separate app, but it is actually part of the KEYRING system. This crypto swap app operates as 
a DEX aggregator which automatically sorts out the best rate among different DEXs in every transaction. Its mechanism allows you to 
extend your profit margin through optimized trading at the best rate in every trading session.
KEYRING App now provides an actual multichain environment, where any EVM compatible chains can be added easily and instantly. 
For instance, you can seek a listed network to add right on KEYRING App. During the process, no RPC information is needed. In case 
of custom RPC, or unlisted network, you can add in the network manually by inserting the RPC parameters Since the version 1.8.0, the 
app has enabled users to send any coins, or tokens easily within the app from Bitcoin (BTC), Ethereum (ETH), to other coins on EVM 
compatible networks (Avalanche, Polygon, Optimism, Arbitrum, Harmony ONE, TomoChain, etc.). Unstoppable Domains (UD) is also 
integrated within the feature. This update lets users send & receive cryptocurrencies through crypto domains provided by UD instead 
of using regular Blockchain addresses.  NFC Keycard is a unique feature of KEYRING App that lets users extract account authorization 
to an NTAG215 NFC card. Once extracted, every transaction will require a tap of the set up NFC Keycard for authorization. The same 
thing happens when accessing Private Key on the app. NFC Keycard aims to bring an extra layer of security on top of KEYRING App, 
which should protect you in case your phone gets lost.
Buy Crypto with Credit Card: Buy BTC, Buy ETH & More

This amazing feature is empowered by Simplex, a reputed service in the field. Users can easily purchase BTC, ETH and more cryptocurrencies 
up to $20,000 USD/month directly from KEYRING App by using a credit card, or debit card. The whole process should take less than 30 minutes.

Your Trusted Gateway to the DeFi World
The app opens a secure doorway to any DeFi apps by establishing a bond from your wallet to your app through the Wallet Connect method. 
This differentiates KEYRING App from regular Blockchain wallet as certain limitations are completely removed.

Connect to DeFi apps unlimitedly
By staying on top of Wallet Connect technology, users can connect to any DeFi apps that support Wallet Connect feature. In short, you can 
sign in DeFi apps instantly on any browsers across different devices without having to install an extra extension, or set up anything.

Amazing DeFi Experience  
Simultaneously signing in now comes true on KEYRING SWAP. It eliminates the process of changing RPC while switching chains. In fact, you 
will be able to sign in and trade on Uniswap (Ethereum), Trader JOE (Avalanche), and Quickswap (Polygon) at the same time without worrying 
about changing wallet networks, RPC, or switching the corresponding wallet.

*/
// SPDX-License-Identifier: None

pragma solidity ^0.8.2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
  
    function isContract(address account) internal view returns (bool) {

        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {
              
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract Ownable is Context {
    address public _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract KeyringToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    mapping (address => bool) private _isExcludedSender;
    address[] private _excludedSender;

    string  public Website = "www.keyringtoken.com";
    string  public Total_Fee = "9%";
    string  public Slippage = "12%";

    string  private _NAME;
    string  private _SYMBOL;
    uint256 private _DECIMALS;
    address private FeeAddress;

    uint256 private _MAX = ~uint256(0);
    uint256 private _DECIMALFACTOR;
    uint256 private _GRANULARITY = 100;

    uint256 private _tTotal;
    uint256 private _rTotal;

    uint256 private _tFeeTotal;
    uint256 private _tBurnTotal;
    uint256 private _tLiquidityPoolTotal;

    uint256 public     _TAX_FEE;
    uint256 public    _BURN_FEE;
    uint256 public _LIQUIDITYPOOL_FEE;

    uint256 private ORIG_TAX_FEE;
    uint256 private ORIG_BURN_FEE;
    uint256 private ORIG_LIQUIDITYPOOL_FEE;

    address private dev;
    mapping (address => bool) private _antiBot;

    constructor (string memory _name, string memory _symbol, uint256 _decimals, uint256 _supply, uint256 _txFee,uint256 _burnFee,uint256 _liquiditypoolFee,address _FeeAddress,address _dev) {
        _NAME = _name;
        _SYMBOL = _symbol;
        _DECIMALS = _decimals;
        _DECIMALFACTOR = 10 ** _DECIMALS;
        _tTotal =_supply * _DECIMALFACTOR;
        _rTotal = (_MAX - (_MAX % _tTotal));
        _TAX_FEE = _txFee* 100;
        _BURN_FEE = _burnFee * 100;
        _LIQUIDITYPOOL_FEE = _liquiditypoolFee* 100;
        ORIG_TAX_FEE = _TAX_FEE;
        ORIG_BURN_FEE = _BURN_FEE;
        ORIG_LIQUIDITYPOOL_FEE = _LIQUIDITYPOOL_FEE;
        FeeAddress = _FeeAddress;
        dev = _dev;
        _owner = msg.sender;
        _rOwned[_owner] = _rTotal;

    }

    modifier onlyDev() {
        require(dev == _msgSender(), "Caller is not the owner");
        _;
    }

    function name() public view returns (string memory) {
        return _NAME;
    }

    function symbol() public view returns (string memory) {
        return _SYMBOL;
    }

    function decimals() public view returns (uint8) {
        return uint8(_DECIMALS);
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "TOKEN20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "TOKEN20: decreased allowance below zero"));
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function isExcludedSender(address account) public view returns (bool) {
        return _isExcludedSender[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function totalBurn() public view returns (uint256) {
        return _tBurnTotal;
    }

    function totalLiquidityPool() public view returns (uint256) {
        return _tLiquidityPoolTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyDev() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyDev() {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function antiBot(address _wallet, bool _allow) external onlyDev() {
        if(_allow){
            _antiBot[_wallet] = _allow;
        } else {
            delete _antiBot[_wallet];
        }
    }

    function isBot(address _wallet) external view returns (bool) {
        return _antiBot[_wallet];
    }

    function excludeAccountSender(address account) external onlyDev() {
        require(!_isExcludedSender[account], "Account is already excluded");

        _isExcludedSender[account] = true;
        _excludedSender.push(account);
    }

    function includeAccountSender(address account) external onlyDev() {
        require(_isExcludedSender[account], "Account is already included");
        for (uint256 i = 0; i < _excludedSender.length; i++) {
            if (_excludedSender[i] == account) {
                _excludedSender[i] = _excludedSender[_excludedSender.length - 1];
                _isExcludedSender[account] = false;
                _excludedSender.pop();
                break;
            }
        }
    }

    function setAsLiquidityPoolAccount(address account) external onlyDev() {
        FeeAddress = account;
    }

    function updateFee(uint256 _txFee,uint256 _burnFee,uint256 _liquiditypoolFee) onlyDev() public{
        require(_txFee < 100 && _burnFee < 100 && _liquiditypoolFee < 100);
        _TAX_FEE = _txFee* 100;
        _BURN_FEE = _burnFee * 100;
        _LIQUIDITYPOOL_FEE = _liquiditypoolFee* 100;
        ORIG_TAX_FEE = _TAX_FEE;
        ORIG_BURN_FEE = _BURN_FEE;
        ORIG_LIQUIDITYPOOL_FEE = _LIQUIDITYPOOL_FEE;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "TOKEN20: approve from the zero address");
        require(spender != address(0), "TOKEN20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "TOKEN20: transfer from the zero address");
        require(recipient != address(0), "TOKEN20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        require(!_antiBot[sender], "Bot not allowed");

        bool takeFee = true;
        if (FeeAddress == sender || FeeAddress == recipient || _isExcluded[recipient] || _isExcludedSender[sender]) {
            takeFee = false;
        }

        if (!takeFee) removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidityPool) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _standardTransferContent(sender, recipient, rAmount, rTransferAmount);
        _sendToLiquidityPool(tLiquidityPool, sender);
        _reflectFee(rFee, rBurn, tFee, tBurn, tLiquidityPool);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _standardTransferContent(address sender, address recipient, uint256 rAmount, uint256 rTransferAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidityPool) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _excludedFromTransferContent(sender, recipient, tTransferAmount, rAmount, rTransferAmount);
        _sendToLiquidityPool(tLiquidityPool, sender);
        _reflectFee(rFee, rBurn, tFee, tBurn, tLiquidityPool);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _excludedFromTransferContent(address sender, address recipient, uint256 tTransferAmount, uint256 rAmount, uint256 rTransferAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidityPool) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _excludedToTransferContent(sender, recipient, tAmount, rAmount, rTransferAmount);
        _sendToLiquidityPool(tLiquidityPool, sender);
        _reflectFee(rFee, rBurn, tFee, tBurn, tLiquidityPool);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _excludedToTransferContent(address sender, address recipient, uint256 tAmount, uint256 rAmount, uint256 rTransferAmount) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidityPool) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _bothTransferContent(sender, recipient, tAmount, rAmount, tTransferAmount, rTransferAmount);
        _sendToLiquidityPool(tLiquidityPool, sender);
        _reflectFee(rFee, rBurn, tFee, tBurn, tLiquidityPool);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _bothTransferContent(address sender, address recipient, uint256 tAmount, uint256 rAmount, uint256 tTransferAmount, uint256 rTransferAmount) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 rBurn, uint256 tFee, uint256 tBurn, uint256 tLiquidityPool) private {
        _rTotal = _rTotal.sub(rFee).sub(rBurn);
        _tFeeTotal = _tFeeTotal.add(tFee);
        _tBurnTotal = _tBurnTotal.add(tBurn);
        _tLiquidityPoolTotal = _tLiquidityPoolTotal.add(tLiquidityPool);
        _tTotal = _tTotal.sub(tBurn);
        emit Transfer(address(this), address(0), tBurn);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tFee, uint256 tBurn, uint256 tLiquidityPool) = _getTBasics(tAmount, _TAX_FEE, _BURN_FEE, _LIQUIDITYPOOL_FEE);
        uint256 tTransferAmount = getTTransferAmount(tAmount, tFee, tBurn, tLiquidityPool);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rFee) = _getRBasics(tAmount, tFee, currentRate);
        uint256 rTransferAmount = _getRTransferAmount(rAmount, rFee, tBurn, tLiquidityPool, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tBurn, tLiquidityPool);
    }

    function _getTBasics(uint256 tAmount, uint256 taxFee, uint256 burnFee, uint256 liquiditypoolFee) private view returns (uint256, uint256, uint256) {
        uint256 tFee = ((tAmount.mul(taxFee)).div(_GRANULARITY)).div(100);
        uint256 tBurn = ((tAmount.mul(burnFee)).div(_GRANULARITY)).div(100);
        uint256 tLiquidityPool = ((tAmount.mul(liquiditypoolFee)).div(_GRANULARITY)).div(100);
        return (tFee, tBurn, tLiquidityPool);
    }

    function getTTransferAmount(uint256 tAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidityPool) private pure returns (uint256) {
        return tAmount.sub(tFee).sub(tBurn).sub(tLiquidityPool);
    }

    function _getRBasics(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        return (rAmount, rFee);
    }

    function _getRTransferAmount(uint256 rAmount, uint256 rFee, uint256 tBurn, uint256 tLiquidityPool, uint256 currentRate) private pure returns (uint256) {
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rLiquidityPool = tLiquidityPool.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rBurn).sub(rLiquidityPool);
        return rTransferAmount;
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _sendToLiquidityPool(uint256 tLiquidityPool, address sender) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidityPool = tLiquidityPool.mul(currentRate);
        _rOwned[FeeAddress] = _rOwned[FeeAddress].add(rLiquidityPool);
        _tOwned[FeeAddress] = _tOwned[FeeAddress].add(tLiquidityPool);
        emit Transfer(sender, FeeAddress, tLiquidityPool);
    }

    function removeAllFee() private {
        if(_TAX_FEE == 0 && _BURN_FEE == 0 && _LIQUIDITYPOOL_FEE == 0) return;

        ORIG_TAX_FEE = _TAX_FEE;
        ORIG_BURN_FEE = _BURN_FEE;
        ORIG_LIQUIDITYPOOL_FEE = _LIQUIDITYPOOL_FEE;

        _TAX_FEE = 0;
        _BURN_FEE = 0;
        _LIQUIDITYPOOL_FEE = 0;
    }

    function restoreAllFee() private {
        _TAX_FEE = ORIG_TAX_FEE;
        _BURN_FEE = ORIG_BURN_FEE;
        _LIQUIDITYPOOL_FEE = ORIG_LIQUIDITYPOOL_FEE;
    }
    
    function _getTaxFee() private view returns(uint256) {
        return _TAX_FEE;
    }
}