/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

pragma solidity >= 0.8;
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
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract presale is ReentrancyGuard, Context, Ownable {
    using SafeMath for uint256;
    
    mapping (address => uint256) public _contributions;
    mapping (address => bool) public _whitelisted;
    IERC20 public _presaleToken;
    uint256 private _tokenDecimals;
    address payable _wallet;
    address payable _taxWallet;
    uint256 public _rate;
    uint256 public _raised;
    uint maxPurchaseAmount = 4 ether;
    uint cap = 500 ether;
    uint softCap = cap.div(2);
	bool public presaleMode = false;
	bool public presaleFinished = false;
	bool public whitelistMode = true;
	

    modifier presaleActive() {
        require(presaleMode, "Presale must be active");
        _;
    }
    
    constructor ()  {
        _wallet =  payable(msg.sender);
    }
	
    receive () external payable {
        if(presaleMode){
            contribute();
        } else{revert();}
    }
    
	function whitelist(address[] calldata _whitelist) external onlyOwner {
	    for (uint256 i = 0; i < _whitelist.length; i++) {
            _whitelisted[_whitelist[i]]= true;
        }
	}
	
    function begin() external onlyOwner  {
        presaleMode = true;
        presaleFinished = false;
        _raised = 0; 
    }
    
    function endPresale() external onlyOwner{
        require(_raised >= softCap);
        presaleMode = false;
        presaleFinished = true;
    }
    
	function publicSale() external onlyOwner  {
		require(presaleMode);
        whitelistMode = false;
    }
    
    //Pre-Sale 
    function contribute() public nonReentrant presaleActive payable {
		if(whitelistMode){require(_whitelisted[msg.sender]);}
        require(msg.value <= maxPurchaseAmount, 'Exceeds max contribution');
        require(_contributions[msg.sender].add(msg.value) <= maxPurchaseAmount, 'Exceeds max contribution');
        require((_raised + msg.value) <= cap, 'Hard Cap reached');
        _raised = _raised.add(msg.value);
        _contributions[msg.sender] = msg.value;
		if(_raised == cap){presaleMode = false;}
    }

    function claim() external {
        require(presaleFinished);
        uint256 tokensAmt = _getTokenAmount(_contributions[msg.sender]);
        _contributions[msg.sender] = 0;
        _presaleToken.transfer(msg.sender, tokensAmt);
    }


    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate).div(10**_tokenDecimals);
    }

    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }
    
     function withdraw() external onlyOwner {
         require(address(this).balance > 0);
        _wallet.transfer(address(this).balance);  
    }
    
    function emergencyWithdrawal() presaleActive external{
        require(_contributions[msg.sender] > 0);
        _raised = _raised.sub(_contributions[msg.sender]);
        uint256 withdrawalTax = _contributions[msg.sender].div(5);
        uint256 withdrawalAmount =  _contributions[msg.sender].sub(withdrawalTax);
        _contributions[msg.sender] = 0;
        _taxWallet.transfer(withdrawalTax);
        payable(msg.sender).transfer(withdrawalAmount);
    }
  
    function setRate(uint256 newRate) external onlyOwner {
        _rate = newRate;
    }
     
    function setWalletReceiver(address payable newWallet) external onlyOwner{
        _wallet = newWallet;
    }
    
    function setCap(uint256 _cap) external onlyOwner {
        cap = _cap;
    }
        
    function setMaxPurchaseAmount(uint256 _purchaseAmount) external onlyOwner {
        maxPurchaseAmount = _purchaseAmount;
    }

    function setToken(address _token) external onlyOwner {
        _presaleToken = IERC20(_token);
        _tokenDecimals = _presaleToken.decimals();
    }
        
    function takeTokens(IERC20 tokenAddress) public onlyOwner {
        IERC20 token = tokenAddress;
        uint256 tokenAmt = token.balanceOf(address(this));
        require(tokenAmt > 0, 'balance is 0');
        token.transfer(_wallet, tokenAmt);
    }
        
}