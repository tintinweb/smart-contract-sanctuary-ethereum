/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


abstract contract ReentrancyGuard {
   
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

   
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract Presale is ReentrancyGuard, Context, Ownable {
    using SafeMath for uint256;
    
    mapping (address => uint256) public _contributions;
    mapping (address => uint256) public _BUSDcontributions;

    IERC20 public _token;
    uint256 private _tokenDecimals; 
    IERC20 public _BUSD;
    IERC20 public reflecto;
    uint256 private _BUSDDecimal;
    address payable public _wallet;
    uint256 public _weirate;
    uint256 public _busdrate;
    uint256 public _weiRaised;
    uint256 public _busdRaised;
    uint256 public startPublicICOTime;
    uint256 public endPublicICOTime;
    uint256 public startICOTime;
    uint public hardCap;
    uint public minSaleBNB;
    uint256 public endICO;
    uint256 public endPrivateICO;
    uint public availableTokensICO;

    event TokensPurchased(address  purchaser, address  beneficiary, uint256 value, uint256 amount);
    constructor (uint256 weirate,uint256 busdrate, address payable wallet, IERC20 _reflecto, IERC20 token, IERC20 BUSD, uint256 tokenDecimals, uint256 busdDecimal,uint256 _minSaleBNB)  {
        require(weirate > 0, "Pre-Sale: weirate is 0");
        require(busdrate > 0, "Pre-Sale: busdrate is 0");
        require(wallet != address(0), "Pre-Sale: wallet is the zero address");
        require(address(token) != address(0), "Pre-Sale: token is the zero address");
        
        _weirate = weirate;
        _busdrate = busdrate;
        _wallet = wallet;
        _token = token;
        _BUSD = BUSD;
        _BUSDDecimal = busdDecimal;
        _tokenDecimals = 18 - tokenDecimals;
        reflecto = _reflecto;
        minSaleBNB = _minSaleBNB;
       }

    receive () external payable {
        if(endICO > 0 && block.timestamp < endICO){
            buyTokens(_msgSender());
        } else {
            endICO = 0;
            revert("Pre-Sale is closed");
        }
    }

    function calculateHardCap() public view returns(uint256){
        uint256 tokensAmt = _getTokenAmount(_weiRaised);
        uint256 ERCtokensAmt = _getTokenAmountERC(_busdRaised);
        uint256 totalAmount = tokensAmt + ERCtokensAmt;
        return totalAmount;
    }
    
    //Start Pre-Sale
    function startICO(uint startDuration, uint endDuration , uint256 _hardCap, uint256 _privateICODuration) external onlyOwner icoNotActive() {
        uint startDate = block.timestamp + startDuration;
        uint endDate = block.timestamp + endDuration;
        endPrivateICO= startDate + _privateICODuration;
        availableTokensICO = _token.balanceOf(address(this));
        require(startDuration < endDuration, "Start time must be less then end time");
        require(availableTokensICO > 0 , "availableTokens must be > 0");
        require(_hardCap < availableTokensICO,"Hardcap must be less the RUSD available in token");
        startICOTime = startDate;
        startPublicICOTime= startDate + _privateICODuration;
        endICO = endDate; 
        endPublicICOTime = endICO;
        hardCap = _hardCap;
        _weiRaised = 0;
        _busdRaised = 0;
    }
    
    function stopICO() external onlyOwner icoActive(){
        startICOTime = 0;
        endICO = 0;
        endPublicICOTime = 0;
         _forwardFunds();
    }
    
    //Pre-Sale 
    function buyTokens(address beneficiary) public nonReentrant icoActive payable {
        uint256 userBalance = reflecto.balanceOf(beneficiary); 
        uint256 rusdCanBuy = _getrusdMaxBuy(beneficiary);
        if(block.timestamp <= endPrivateICO && userBalance > 0){
            uint256 weiAmount = msg.value;
            uint rusdAmount = _getTokenAmount(weiAmount);    
            require(rusdAmount < rusdCanBuy, "Cannot buy more than percentage holdings of reflecto");
            _preValidatePurchase(beneficiary, weiAmount);
            uint256 tokens = _getTokenAmount(weiAmount);
            _weiRaised = _weiRaised.add(weiAmount);
            availableTokensICO = availableTokensICO - tokens;
            _contributions[beneficiary] = _contributions[beneficiary].add(weiAmount);
            emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);
        }
        else if(block.timestamp > endPrivateICO && userBalance == 0){
            uint256 weiAmount = msg.value;
            _preValidatePurchase(beneficiary, weiAmount);
            uint256 tokens = _getTokenAmount(weiAmount);
            _weiRaised = _weiRaised.add(weiAmount);
            availableTokensICO = availableTokensICO - tokens;
            _contributions[beneficiary] = _contributions[beneficiary].add(weiAmount);
            emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);
        }
    }

    function buyTokensERC20(address beneficiary, uint256 Value) public nonReentrant icoActive {
        uint256 userBalance = reflecto.balanceOf(beneficiary);
        uint256 rusdCanBuy = _getrusdMaxBuy(beneficiary);
        if(block.timestamp <= endPrivateICO && userBalance > 0){
            uint256 ERCAmount = Value;
            uint rusdAmount = _getTokenAmountERC(ERCAmount);  
            require(rusdAmount < rusdCanBuy, "Cannot buy more than percentage holdings of reflecto");
            _BUSD.approve(address(this), ERCAmount);
            _BUSD.transferFrom(msg.sender,address(this), ERCAmount);
            _preValidatePurchase(beneficiary, ERCAmount);
            uint256 tokens = _getTokenAmount(ERCAmount);
            _busdRaised = _busdRaised.add(ERCAmount);
            availableTokensICO = availableTokensICO - tokens;
            _BUSDcontributions[beneficiary] = _BUSDcontributions[beneficiary].add(ERCAmount);
            emit TokensPurchased(_msgSender(), beneficiary, ERCAmount, tokens);
         }else if(block.timestamp > endPrivateICO && userBalance >= 0){
            uint256 ERCAmount = Value;
            _BUSD.approve(address(this), ERCAmount);
            _BUSD.transferFrom(msg.sender,address(this), ERCAmount);
            _preValidatePurchase(beneficiary, ERCAmount);
            uint256 tokens = _getTokenAmount(ERCAmount);
            _busdRaised = _busdRaised.add(ERCAmount);
            availableTokensICO = availableTokensICO - tokens;
            _BUSDcontributions[beneficiary] = _BUSDcontributions[beneficiary].add(ERCAmount);
            emit TokensPurchased(_msgSender(), beneficiary, ERCAmount, tokens);
        }
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(weiAmount > minSaleBNB);    // 1e17
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        require(calculateHardCap() <= hardCap, "Hard Cap reached");
        this;
    }

    function _preValidatePurchaseERC(address beneficiary, uint256 ERCAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(ERCAmount != 0, "Crowdsale: weiAmount is 0");
        require(calculateHardCap() <= hardCap, "Hard Cap reached");
        this; 
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_weirate).div(10**_tokenDecimals);
    }

    function _getTokenAmountERC(uint256 ERCAmount) internal view returns (uint256) {
        return ERCAmount.mul(_busdrate).div(10**_tokenDecimals);
    }

    function _getrusdMaxBuy(address beneficiary) public view returns (uint256) {
        uint256 userBalance = reflecto.balanceOf(beneficiary); 
        uint256 totalSupply= reflecto.totalSupply();            
        uint reflectoUserPercentage= (userBalance*100)/totalSupply;   
        uint rusdSupply= _token.balanceOf(address(this));    
        uint rusdCanBuy= (reflectoUserPercentage * rusdSupply)/100; 
        return rusdCanBuy;
    }

    function _getrusdMaxBuyInBnb(address beneficiary) public view returns (uint256) {
        uint rusdCanBuy = _getrusdMaxBuy(beneficiary);
        uint maxrusdInBNB = rusdCanBuy.div(_weirate);
        return maxrusdInBNB;
    }

    function _getrusdMaxBuyInBusd(address beneficiary) public view returns (uint256) {
        uint rusdCanBuy = _getrusdMaxBuy(beneficiary);
        uint maxrusdInBUSD = rusdCanBuy.div(_busdrate);
        return maxrusdInBUSD;
    }

    function claimTokens() external icoNotActive{
        uint256 tokensAmt = _getTokenAmount(_contributions[msg.sender]);
        uint256 ERCtokensAmt = _getTokenAmountERC(_BUSDcontributions[msg.sender]);
        uint256 totalAmount =tokensAmt+ERCtokensAmt;
        require(totalAmount>0,"No claimable amount");
        _contributions[msg.sender] = 0;
         _BUSDcontributions[msg.sender] = 0;
        _token.transfer(msg.sender, totalAmount);
    }

    function _forwardFunds() internal {
        _wallet.transfer(_weiRaised);
        _BUSD.transfer(_wallet, _busdRaised);
    }
    
     function withdraw() external onlyOwner icoNotActive{
         uint256 busdbalance = _BUSD.balanceOf(address(this));
        _wallet.transfer(address(this).balance);  
        _BUSD.transfer(_wallet, busdbalance);
    }
    
    function checkContribution(address addr) public view returns(uint256){
        return _contributions[addr];
    }

    function checkErcContribution(address addr) public view returns(uint256){
        return _BUSDcontributions[addr];
    }

    function claimableAmount(address addr) public view returns(uint256){
        uint256 tokensAmt = _getTokenAmount(_contributions[addr]);
        uint256 ERCtokensAmt = _getTokenAmountERC(_BUSDcontributions[addr]);
        uint256 totalAmount = tokensAmt + ERCtokensAmt;
        return totalAmount;
    }
    
    function setWeiRate(uint256 newRate) external onlyOwner icoNotActive{
        _weirate = newRate;
    }

    function setBusdAddress(IERC20 busd) external onlyOwner icoNotActive{
        _BUSD = busd;
    }

    function setminSaleBNB(uint256 _minSaleBNB) external onlyOwner icoNotActive{
        minSaleBNB = _minSaleBNB;
    }

    function setReflecto(IERC20 _reflecto) external onlyOwner{
        reflecto = _reflecto;
    }

    function setbusdrate(uint256 newRate) external onlyOwner icoNotActive{
        _busdrate = newRate;
    }

    function setHardCap(uint256 value) external onlyOwner{
        require(value < availableTokensICO,"Hardcap must be less the RUSD available in token");
        hardCap = value;
    }
    
    function setAvailableTokens(uint256 amount) public onlyOwner icoNotActive{
        availableTokensICO = amount;
    }
 
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    function ercRaised() public view returns (uint256) {
        return _busdRaised;
    }
    
    function setWalletReceiver(address payable newWallet) external onlyOwner(){
        _wallet = newWallet;
    }
    
    function takeTokens(IERC20 tokenAddress)  public onlyOwner icoNotActive{
        IERC20 tokenBEP = tokenAddress;
        uint256 tokenAmt = tokenBEP.balanceOf(address(this));
        require(tokenAmt > 0, 'BEP-20 balance is 0');
        tokenBEP.transfer(_wallet, tokenAmt);
    }
    
    modifier icoActive() {
        require(endICO > 0 && block.timestamp < endICO && availableTokensICO > 0 && startICOTime < block.timestamp, "ICO must be active");
        _;
    }
    
    modifier icoNotActive() {
        require(endICO < block.timestamp, "ICO should not be active");
        _;
    }
    
}