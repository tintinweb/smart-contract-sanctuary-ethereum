/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-24
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
    address private _manager;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _manager = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(
            _owner == _msgSender() || _manager == _msgSender(),
            "Ownable: caller is not the owner"
        );
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
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

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}
  

contract Presale is ReentrancyGuard, Context, Ownable {
    using SafeMath for uint256;
    
    mapping (address => uint256) public _contributions;

    IERC20 public _token;    
    IERC20 public _usdtToken;                       
    uint256 private _tokenDecimals;                 
    address payable public _wallet;   
    uint256 public _rateByUsdt;                           
    uint256 public _weiRaised;
    bool public endICO = true;
    
    uint public softCap;
    uint public availableTokensICO;
    bool public startRefund = false;

    AggregatorV3Interface internal priceFeed;

    mapping(uint => uint256) supplyBySteps;
    uint currentLevel = 0;

    event TokensPurchased(address  purchaser, address  beneficiary, uint256 value, uint256 amount);
    event Refund(address recipient, uint256 amount);
    constructor (uint256 betaSaleCap)  {        
        availableTokensICO = betaSaleCap;
        _rateByUsdt = 333333;
        _tokenDecimals = 9;
        _token = IERC20(0x9b3EDB30B7C61067Ff7Db8594acCc159bAc25998); // Have to repair
        _usdtToken = IERC20(0xcF68f6eC21ff9B4ebEDd0471A7197C48E8E975cF); // Have to repair
        priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    }
    
    //Start Pre-Sale
    function startICO() external onlyOwner icoNotActive() {
        require(availableTokensICO > 0 && availableTokensICO <= _token.totalSupply(), 'availableTokens should be > 0 and <= totalSupply');
        endICO = false; 
        softCap = _token.balanceOf(address(this));
        supplyBySteps[currentLevel] = _token.balanceOf(address(this));
        _weiRaised = 0;
    }
    
    function stopICO() external onlyOwner icoActive(){
        endICO = true;
        if(_weiRaised == softCap) {
            _forwardFunds();
            softCap = 0;
        } else{
            startRefund = true;
        }
        currentLevel = currentLevel + 1;
    }
    
    
    //Pre-Sale 
    
    // Presale By USDT

    function buyTokensByUsdt(uint256 amount) public nonReentrant icoActive {
        uint256 weiAmount = amount;
        _preValidatePurchase(msg.sender, weiAmount);
        uint256 tokens = _getTokenAmount(weiAmount);

        _usdtToken.approve(address(this), amount);

        _weiRaised = _weiRaised.add(weiAmount);
        availableTokensICO = availableTokensICO - tokens;
        _processPurchase(msg.sender, tokens);
        _contributions[msg.sender] = _contributions[msg.sender].add(weiAmount);
        emit TokensPurchased(_msgSender(), msg.sender, weiAmount, tokens);
    }

    // Presale By Ether
    function buyTokensByEther() public nonReentrant payable {
        uint256 weiAmount = msg.value * uint256(getEtherToUSDT()) / (10**18);
        _preValidatePurchase(msg.sender, weiAmount);
        uint256 tokens = _getTokenAmount(weiAmount);
        _weiRaised = _weiRaised.add(weiAmount);
        availableTokensICO = availableTokensICO - tokens;
        // _processPurchase(msg.sender, tokens);
        // _contributions[msg.sender] = _contributions[msg.sender].add(weiAmount);
        emit TokensPurchased(_msgSender(), msg.sender, weiAmount, tokens);
    }  

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");

        this; 
    }
 
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _token.transfer(beneficiary, tokenAmount);
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rateByUsdt).div(10**_tokenDecimals);
    }

    function _forwardFunds() internal {
        require(address(this).balance > 0, 'Contract has no money');
        _wallet.transfer(address(this).balance);  
    }
    
    function withdraw() external onlyOwner icoNotActive{
         require(startRefund == false);
         require(address(this).balance > 0, 'Contract has no Ether');
         require(_usdtToken.balanceOf(address(this)) > 0, 'Contract has no usdt');
        _wallet.transfer(address(this).balance);
        _usdtToken.approve(address(this), _usdtToken.balanceOf(address(this)));
        _usdtToken.transferFrom(address(this), _wallet, _usdtToken.balanceOf(address(this)));
    }
    
    function checkContribution(address addr) public view returns(uint256){
        return _contributions[addr];
    }

    function getEtherToUSDT() public view returns (int) {
        (
            , 
            int price,
            ,
            ,            
        ) = priceFeed.latestRoundData();
        return price;
    }
    
    function setRate(uint256 newRate) external onlyOwner icoNotActive{
        _rateByUsdt = newRate;
    }
    
    function setAvailableTokens(uint256 amount) public onlyOwner icoNotActive{
        availableTokensICO = amount;
    }
 
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }
    
    function setWalletReceiver(address payable newWallet) external onlyOwner(){
        _wallet = newWallet;
    }
    function setToken(IERC20 token) external onlyOwner(){
        _token = token;
    }
    
    function setSoftCap(uint256 value) external onlyOwner{
        softCap = value;
    }
    
    function takeTokens(IERC20 tokenAddress) public onlyOwner icoNotActive{
        IERC20 tokenBEP = tokenAddress;
        uint256 tokenAmt = tokenBEP.balanceOf(address(this));
        require(tokenAmt > 0, 'BEP-20 balance is 0');
        tokenBEP.transfer(_wallet, tokenAmt);
    }
    
    function refundMe() public icoNotActive{
        require(startRefund == true, 'no refund available');
        uint amount = _contributions[msg.sender];
		if (address(this).balance >= amount) {
			_contributions[msg.sender] = 0;
			if (amount > 0) {
			    address payable recipient = payable(msg.sender);
				recipient.transfer(amount);
				emit Refund(msg.sender, amount);
			}
		}
    }
    
    modifier icoActive() {
        require(endICO == false && availableTokensICO > 0, "ICO must be active");
        _;
    }
    
    modifier icoNotActive() {
        require(endICO == true, 'ICO should not be active');
        _;
    }
    
}