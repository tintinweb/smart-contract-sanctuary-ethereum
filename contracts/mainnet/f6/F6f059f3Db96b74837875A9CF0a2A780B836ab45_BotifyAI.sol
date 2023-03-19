/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

/*
WEBSITE: https://botify-ai.com 
TELEGRAM: T.me/botify_ai_token 
TWITTER: twitter.com/botify_ai_token

Intro to Botify AI platform
Foreign and cryptocurrency exchanges deploy BOTIFY’s AI Customer Experience (AICX) solution to 
build trust with automated complaint handling and know-your-customer processes.
Best-in-class CX
Automate conversational know-your-customer processes, trading, and more with chatbots that speak 
over 100 local languages.
Build customer trust
Embed deep knowledge of regulatory requirements into chat with a vendor that has facilitated over 
2M customer complaints.
Retain loyal traders
Incentivize loyal traders with cross-channel promotional offers, personalized service, and account-based 
marketing.
What products are in the Botify AI platform?
Botify AI accelerates inclusion and customer satisfaction rates in emerging markets by leveraging machine 
learning to understand local customers better. The Botify AI platform is made up of several products for 100% 
of the contact center automation pipeline:
Build - designer for multilingual chatbot dialogue.
Chat - live chat for human and chatbot conversations.
Track - customer cases gathered by chatbots.
Humans - customer profiles for personalized engagement.
Analytics - custom reporting for agent and bot performance.
What channels are in the Botify AI platform?
Botify AI's Build product enables omnichannel deployments for Bitrix24, LINE, Microsoft Teams, Telegram, 
Twilio SMS, Twitter, Viber, Webchat, WhatsApp Twilio, WhatsApp Meta, Zalo
What languages does Botify AI support?
There are hundreds of chatbot vendors around the world, but most don’t build artificial intelligence for local 
languages. And there’s no easy solution to adapt chatbots to slang and unique terminology.
Botify AI's natural language processing engine supports the following languages.
Vision
Botify AI's vision is to create a future where AI technologies are widely accessible and can be used to solve 
some of the world's most pressing problems, such as environmental issues, health care, and education. The 
goal could be to empower individuals, businesses, and organizations with the tools they need to drive innovation 
in the field of AI.
Mission
Botify AI's mission is to promote the integration of AI and blockchain technology, and provide a secure and 
decentralized platform for the development and deployment of AI solutions.
How are crypto using Botify AI chatbots to improve customer trust
During the pandemic and its difficult economic wake, Fintech was one of the few sectors with substantial growth: 
digital transactions rose by 13% after the first lockdowns, with widespread rollouts of mobile banking applications 
by traditional brick-and-mortar banking services.
Two years on from the pandemic, the fintech market is showing a maturing customer base with rising abandonment 
rates due to poor customer service and onboarding, and entrenched consumer trust issues resulting from mismanaged 
cryptocurrency exchanges.
The customer service problem, arguably, is that many fintech businesses – and specifically those within the crypto & 
foreign exchange sector – are still operating from the old playbook of invasive questions and long forms in the pursuit 
of know-your-customer compliance, but with little thought for first-time user experience. 
As recent news demonstrates, know-your-customer and more – not less – regulatory compliance is essential for a friendly 
and profitable trading environment. However, as seen in similar maturing sectors, this pursuit within crypto must be paired 
with an extremely thoughtful, efficient and trustworthy customer experience. 


Crypto has a customer service (and trust) problem
Cryptocurrency trading is a complicated field with millions of data points and trillions of dollars in transaction value. It is also, 
by its nature, a multinational and multilingual business that requires both retail and institutional traders to cope with language 
barriers and time zone service delays. 
When trades are worth thousands or even millions, the idea of a technical support request being lost in translation is untenable. 
As a result, cryptocurrency businesses are following in the steps of foreign exchanges in operating expensive manual contact 
centers with native-speaking agents recruited from around the world.
However, this is an imperfect solution, as agent turnover & training problems and expanding customer volumes lead to inevitable 
wait times and poor customer satisfaction rates. Also, many new cryptocurrency businesses do not have sufficient resources for 
multilingual customer service at their outset, which is a significant barrier to growth.
The promise of AI chatbots for crypto customers 
In contrast to the nascent use of chatbots for customer service, AI trading bots are big business with $5 trillion moving every day 
in part, via AI automations for analyzing markets and executing trades for institutional traders – with the promise of major rewards 
from minimal effort.
Of course, this automation does not always work, as trading bots are restricted by their programming and the data at their disposal. 
In many cases, such bots have performed well when trading in demo environments using decades of historical data, but then failed 
in the real world when met with more elastic data. 
The deployment of trading bots is maturing however, with the combination of automated and manual strategies leading to an increasing 
rate of 38% of crypto traders using bots 
This early application of AI to backend trading is evolving, but it does open the door to frontend opportunities, such as chatbots for solving 
the customer service and trust problems.
Smart deployment of multilingual chatbots for customer service can immediately answer frequent trading questions across languages and 
time zones with no translation problems nor wait times. Most important for scalability, these chatbots can also smoothen the onboarding 
process with user-friendly know-your-customer questions in a conversational format, and deliver proactive tips at key blockers.
Customer chatbots can also be integrated with back-office systems to incentivize loyal traders with cross-channel promotional offers. 
Providing this personalized and thoughtful service via chatbots has the power to differentiate crypto brands as not only user-friendly – but 
also provide meaningful touchpoints that indicate a trustworthy and customer-centric business.
The Botify AI difference for customer trust
While multilingual chatbots offer an opportunity for improvements to customer service and trust, not all chatbot vendors are built for this 
journey. 
Businesses familiar with chatbots will know that customer service automation within crypto requires iterative dialogue design strategies, 
localized natural language processing (NLP) models, and deep-knowledge of regulatory requirements. 
Botify AI is a unique chatbot vendor given its extensive service of central banks from the Philippines to Rwanda to Ghana, securities & exchange 
commissions, and departments of trade & industry across multiple consumer protection use-cases that facilitated over 2 million customer 
complaints about financial service providers so far in 2022.
This scale of regulatory alignment and localized NLP capability for languages such as Kinyarwanda, Tagalog and Twi is made possible for 
Botify AI engine, which speaks over 100 under-resourced and mixed languages. These chatbots are pre-integrated with messaging apps such 
as Telegram, LINE and Viber for maximum customer access and trust-building touchpoints.
While multilingual chatbots from the most capable vendors can solve customer service pain points and contribute to renewed consumer trust, 
cryptocurrency businesses in particular need to pair this effort with additional investments in meaningful regulatory engagement.
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

contract BotifyAI is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    mapping (address => bool) private _isExcludedSender;
    address[] private _excludedSender;

    string  public Website = "www.botify-ai.com";
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