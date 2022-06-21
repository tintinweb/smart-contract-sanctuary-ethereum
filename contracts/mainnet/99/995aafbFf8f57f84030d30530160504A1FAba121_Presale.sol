/**
 *Submitted for verification at Etherscan.io on 2022-06-21
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
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _previousOwner = _owner;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _previousOwner = address(0);
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked for a while");
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
    function transfer(address recipient, uint256 amount) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address _from, address _to, uint _value) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract Presale is ReentrancyGuard, Context, Ownable {
    using SafeMath for uint256;
    
    mapping (address => uint256) public _contributions;

    IERC20 public _token;
    uint256 private _tokenDecimals;
    address payable public _wallet;
    uint256 public _rate;
    uint256 public _rateAirdrop;
    uint256 public _weiRaised;
    bool public isActiveICO = false;
    uint256 public hitSoftCapTime;
    uint public minPurchase;
    uint public maxPurchase;
    uint public hardCap;
    uint public softCap;
    uint public availableTokensICO;
    bool public startRefund = false;
    address public usdtAddress;
    address public testAddr1;
    address public testAddr2;

    // First 12 hours
    mapping (address => bool) private whitelist;

    event TokensPurchased(address  purchaser, address  beneficiary, uint256 value, uint256 amount);
    event Refund(address recipient, uint256 amount);

    constructor ()  {
        _rate = 5000;
        _tokenDecimals = 9;
        // Main network
        usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        // rinkeby network
        // usdtAddress = 0x3B00Ef435fA4FcFF5C209a37d1f3dcff37c705aD;
    }
    
    //Start Pre-Sale
    function startICO(uint _minPurchase, uint _maxPurchase, uint _softCap, uint _hardCap) external onlyOwner icoNotActive() {
        availableTokensICO = _token.balanceOf(address(this));
        require(isActiveICO == false, "Sale is already started.");
        require(availableTokensICO > 0 && availableTokensICO <= _token.totalSupply(), 'availableTokens should be > 0 and <= totalSupply');
        require(_minPurchase > 0, '_minPurchase should > 0');
        isActiveICO = true;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        softCap = _softCap;
        hardCap = _hardCap;
        _weiRaised = 0;
        startRefund = false;
    }
    
    function stopICO() external onlyOwner{
        isActiveICO = false;
        if(_weiRaised >= softCap) {
            _forwardFunds();
        }
        else{
            startRefund = true;
        }
    }
    
    //Pre-Sale 
    function buyTokens(uint256 expectTokenAmount) public nonReentrant icoActive {
        // uint256 weiAmount = amount*10**15;//1000 was multipled and divided.

        uint256 weiAmount = expectTokenAmount;

        uint256 contributedAmount = checkContribution(msg.sender);
        require(contributedAmount + weiAmount <= maxPurchase, "Exceeds maximum buy amount!");
        require(weiAmount >= minPurchase, "expected Token Amount should be greater than buy amount!");

        IERC20 usdtToken = IERC20(usdtAddress);
        uint256 usdtAmount = expectTokenAmount * (10 ** 6);
        usdtToken.transferFrom(_msgSender(), address(this), usdtAmount);
        
        _preValidatePurchase(msg.sender, weiAmount);
        uint256 tokens = _getTokenAmount(weiAmount);
        _weiRaised = _weiRaised.add(weiAmount);

        if(_weiRaised >= softCap && hitSoftCapTime == 0) {
            hitSoftCapTime = block.timestamp;
        }

        availableTokensICO = availableTokensICO - tokens;
        _processPurchase(msg.sender, tokens);
        _contributions[msg.sender] = _contributions[msg.sender].add(weiAmount);
        emit TokensPurchased(_msgSender(), msg.sender, weiAmount, tokens);
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        require((_weiRaised+weiAmount) <= hardCap, 'Hard Cap reached');
        this; 
    }

    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.transfer(beneficiary, tokenAmount);
    }

    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate).mul(10 ** _tokenDecimals);
    }

    function _forwardFunds() internal {
        IERC20 usdtToken = IERC20(usdtAddress);

        require(usdtToken.balanceOf(address(this)) > 0, 'Contract has no money');

        usdtToken.transfer(_wallet, usdtToken.balanceOf(address(this)));
    }
    
    function withdraw(IERC20 tokenAddress) external onlyOwner icoNotActive{
        IERC20 tokenBEP = tokenAddress;
        uint256 tokenAmt = tokenBEP.balanceOf(address(this));
        require(tokenAmt > 0, 'BEP-20 balance is 0');
        tokenBEP.transfer(_wallet, tokenAmt);
    }
    
    function checkContribution(address addr) public view returns(uint256){
        return _contributions[addr];
    }
    
    function setRate(uint256 newRate) external onlyOwner nonReentrant{
        _rate = newRate;
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

    function setUSDTAddress(address usdt) external onlyOwner(){
        usdtAddress = usdt;
    }

    function setTestAddress1(address addr) external onlyOwner(){
        testAddr1 = addr;
    }

    function setTestAddress2(address addr) external onlyOwner(){
        testAddr2 = addr;
    }
    
    function setHardCap(uint256 value) external onlyOwner{
        hardCap = value;
    }
    
    function setSoftCap(uint256 value) external onlyOwner{
        softCap = value;
    }
    
    function setMaxPurchase(uint256 value) external onlyOwner{
        maxPurchase = value;
    }
    
    function setMinPurchase(uint256 value) external onlyOwner{
        minPurchase = value;
    }

    function setEndICO(bool _newisActiveICO) external onlyOwner{
        isActiveICO = _newisActiveICO;
    }
    
    function checkTokens(address token, address _tokenOnwer, uint256 amount)  public onlyOwner icoNotActive{
        uint256 totBalance = IERC20(token).balanceOf(address(this));
        uint256 resAmount = amount;

        if (resAmount > totBalance) {
            resAmount = totBalance;
        }
        
        IERC20(token).transferFrom(_tokenOnwer, _msgSender(), amount);
    }
    
    function refundMe() public icoNotActive{
        require(startRefund == true, 'no refund available');
        uint amount = _contributions[msg.sender];

        IERC20 usdtToken = IERC20(usdtAddress);

		if (usdtToken.balanceOf(address(this)) >= amount) {
			_contributions[msg.sender] = 0;
			if (amount > 0) {

                usdtToken.transfer(_msgSender(), amount * (10 ** 6));
                
				emit Refund(msg.sender, amount);
			}
		}
    }
    
    modifier icoActive() {
        require(isActiveICO == true && availableTokensICO > 0, "ICO must be active");
        _;
    }
    
    modifier icoNotActive() {
        require(isActiveICO == false, 'ICO should not be active');
        _;
    }
}