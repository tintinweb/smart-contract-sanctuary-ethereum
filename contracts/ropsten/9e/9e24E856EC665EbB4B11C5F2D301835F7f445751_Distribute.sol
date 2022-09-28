// SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "./token.sol";
import "./Extras/Interface/IERC20.sol";
import "./Extras/Interface/Vesting.sol";
import "./crowdsale.sol";
import './Vesting/vest.sol';

contract Distribute is Crowdsale {
  
    mapping(address => uint256) public contributions;

    address private admin;

    // Token Distribution
    uint256 public PrivateToken=900000000;
    uint256 public PublicToken=2500000000;
    uint256 public MarketingToken=1700000000;
    uint256 public founderCommunityToken=1000000000;
    uint256 public AdvisorToken=300000000;
    uint256 public EcoSystemToken=1100000000;
    uint256 public TreasuryToken=2500000000;

    // Token reserve funds
    address public Private;
    address public Public;
    address public Marketing=0x8005Bd2698fD7dd63B92132530D961915fbD1B4C;
    address public founderCommunity=0x718148ff5E44254ac51a9D2D544fdd168c1a85D4;
    address public Advisor=0x6C763a8E16266c05e796f5798C88FF1305c4878d;
    address public EcoSystem=0x02E839EF8a2e3812eCcf7ad6119f48aB2560228a;
    address public Treasury=0xfE30c9B5495EfD5fC81D8969483acfE6Efe08d61;
  
   event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
       modifier onlyOwner() {
        require(admin == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    // Token Time lock

    address public foundersTimelock;
    address public PublicTimelock;
    address public PrivateTimelock;
    address public MarketingTimelock;
    address public AdvisorTimelock;
    address public EcoSystemTimelock;
    

    bool private _finalized;
    event CrowdsaleFinalized();

  

    constructor(
        uint256 _rate,
        address payable _wallet,
        IERC20 _token
       
      
    ) 
        Crowdsale(_rate, _wallet, _token) public
  
    {
       
        _finalized = false;
        admin = msg.sender;
        Private=_wallet;
        Public=_wallet;
      
        
    }

    function getUserContributions(address _beneficiary) public view returns (uint256) {
        return contributions[_beneficiary];
    }

  

    // function setCrowdsaleStage(uint _stage) public {
    //     require(msg.sender == admin, "TokenSale: No access to call function");
    //     if(uint(CrowdsaleStage.PreICO) == _stage) {
    //         stage = CrowdsaleStage.PreICO;
    //     } else if (uint(CrowdsaleStage.ICO) == _stage) {
    //         stage = CrowdsaleStage.ICO;
    //     }

    //     // if(stage == CrowdsaleStage.PreICO) {
    //     //     _rate = 500;
    //     // } else if(stage == CrowdsaleStage.ICO) {
    //     //     _rate = 250;
    //     // }
    // }

    function _forwardFunds() internal override {
 
            _wallet.transfer(msg.value);
        
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal override(Crowdsale) {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        uint256 _existingContribution = contributions[_beneficiary];
        uint256 _newContribution = _existingContribution + _weiAmount;
        // require(_newContribution >= minInvestorPrice && _newContribution <= maxInvestorPrice, "TokenSale: Investor price is not up to minimum or has exceeded maximum");
        contributions[_beneficiary] = _newContribution;
    }

     function finalized() public view returns(bool) {
        return _finalized;
    }


    function finalize() public {
        require(msg.sender == admin, "No access to call function");
        require(!_finalized, "FinalizedCrowdsale: already finalized");
        //require(hasClosed(), "FinalizableCrowdsale: crowdsale has not closed");

       IERC20 funtoken=_token;
      
       // uint256 alreadyMinted = funtoken.totalSupply();
        uint256 decimalfactor = 1e18;

        //uint256 _finalTokenSupply = (alreadyMinted / tokenSalePercentage) * 100;

        // TokenTimelock _foundersTimelock = new TokenTimelock(funtoken, founderCommunity, releaseTime);
        // Vesting Vest = new Vesting(_token);
    
      
        Vesting _foundersTimelock = new Vesting(_token,founderCommunity);
        Vesting _AdvisorTimelock = new Vesting(_token,Advisor);
        Vesting _MarketingTimelock = new Vesting(_token,Marketing);
        Vesting _PublicTimelock = new Vesting(_token,_wallet);
        Vesting _EcoSystemTimelock = new Vesting(_token,EcoSystem);
    
       

        foundersTimelock = address(_foundersTimelock);
        PublicTimelock=address(_PublicTimelock);
        //PrivateTimelock=address(_PrivateTimelock);
        MarketingTimelock=address(_MarketingTimelock);
        AdvisorTimelock=address(_AdvisorTimelock);
        EcoSystemTimelock=address(_EcoSystemTimelock);


        funtoken.mint(foundersTimelock, (founderCommunityToken * decimalfactor) );
        funtoken.mint(PublicTimelock,PublicToken * decimalfactor);
        funtoken.mint(Private,PrivateToken * decimalfactor);
        funtoken.mint(MarketingTimelock,MarketingToken * decimalfactor);
        funtoken.mint(AdvisorTimelock,AdvisorToken * decimalfactor);
        funtoken.mint(EcoSystemTimelock,EcoSystemToken * decimalfactor);
        funtoken.mint(Treasury,TreasuryToken * decimalfactor);
        _foundersTimelock.addVesting(64646,6666464,646);
        _PublicTimelock.addVesting(1663926794, 1663926907,250);
        // Vest.grant(founderCommunity,400000000,1726759983,1789831983,1789838983,false);
    

        _finalized = true;

        _finalization();
        emit CrowdsaleFinalized();
    }

    function _finalization() internal {} 
    function release( address _benefiary, uint256 vesting_id) public {
        IVest Vest = IVest(_benefiary);
        Vest.release(vesting_id);
    }
     
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(admin, newOwner);
        admin = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
// network avalanche
//token deployed to 0xEaA8Df0496B7B11229F6Ba98e0Ee24B2cb528ecC
//pre ico deployed to 0x25Ce9bA5aE6147471987B107CDA18a2cB2B4273a
//distribute deployed to 0xFC347fd6D85AcCd900D2671ce1245018dCB26b75

import './Extras/access/Ownable.sol';
contract Token is Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 decimalfactor;
    uint256 public Max_Token;
    bool mintAllowed=true;


    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    // address public ICO=0x03D2434Ef06Ca621aeB961F399cFEAE1A2134D7F;
    // address public Marketing=0x8005Bd2698fD7dd63B92132530D961915fbD1B4C;
    // address public founderCommunity=0x718148ff5E44254ac51a9D2D544fdd168c1a85D4;
    // address public Advisor=0x6C763a8E16266c05e796f5798C88FF1305c4878d;
    // address public Reserves=0x02E839EF8a2e3812eCcf7ad6119f48aB2560228a;
    // address public Staking=0xfE30c9B5495EfD5fC81D8969483acfE6Efe08d61;
    // address public futures=0x6203F881127C9F4f1DdE0e7de9C23c8C9289c34D;
    
    // uint256 public ICOToken=2500000000;
    // uint256 public MarketingToken=1700000000;
    // uint256 public founderCommunityToken=1000000000;
    // uint256 public AdvisorToken=500000000;
    // uint256 public ReservesToken=1500000000;
    // uint256 public StakingToken=1000000000;
    // uint256 public futuresToken=500000000;
    
    // address public PrivateICO= 0xf8e81D47203A594245E36C48e151709F0C19fBe8;
    
    // uint256 public privateICOToken=900000000;
    

    constructor (string memory SYMBOL, 
                string memory NAME,
                uint8 DECIMALS) public{
        symbol=SYMBOL;
        name=NAME;
        decimals=DECIMALS;
        decimalfactor = 10 ** uint256(decimals);
        Max_Token = 10000000000 * decimalfactor;
        // mint(ICO,ICOToken * decimalfactor);
        // mint(Marketing,MarketingToken * decimalfactor);
        // mint(founderCommunity,founderCommunityToken * decimalfactor);
        // mint(Advisor,AdvisorToken * decimalfactor);
        // mint(Reserves,ReservesToken * decimalfactor);
        // mint(Staking,StakingToken * decimalfactor);
        // mint(futures,futuresToken * decimalfactor);
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0),"zero address");
        require(balanceOf[_from] >= _value,"Not enough balance");
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // require(_value <= allowance[_from][msg.sender], "Allowance error");
        // allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
       allowance[msg.sender][_spender] = _value;
       return true;
    }
    
   function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;            
        Max_Token -= _value;
        totalSupply -=_value;                      
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function mint(address _to, uint256 _value) public returns (bool success) {
        require(Max_Token>=(totalSupply+_value));
        require(mintAllowed,"Max supply reached");
        if(Max_Token==(totalSupply+_value)){
            mintAllowed=false;
        }
        //require(msg.sender == owner,"Only Owner Can Mint");
        balanceOf[_to] += _value;
        totalSupply +=_value;
        require(balanceOf[_to] >= _value);
        emit Transfer(address(0), _to, _value); 
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./token.sol";
import "./Extras/Interface/IERC20.sol";
import "./Extras/reentrancy.sol";
import "./Extras/utils/context.sol";
import "./Extras/Interface/IERC20.sol";




abstract contract Crowdsale is Context, ReentrancyGuard {
    IERC20 internal _token;
    address payable internal _wallet;
    uint256 internal _rate;
    uint256 private _weiRaised;

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor(uint256 rate_, address payable wallet_, IERC20 token_) public {
        require(rate_ > 0, "Crowdsale: rate cannot be 0");
        require(wallet_ != address(0), "Crowdsale: wallet cannot be zero address");
        require(address(token_) != address(0), "Crowdsale: token address cannot be zero address");

        _rate = rate_;
        _wallet = wallet_;
        _token = IERC20(token_);
    }

    function token() public view returns (address) {
        return address(_token);
    }

    function wallet() public view returns (address payable) {
        return _wallet;
    }

    function rate() public view returns(uint256) {
        return _rate;
    }

    function weiRaised() public view returns(uint256) {
        return _weiRaised;
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
        return weiAmount * _rate;
    }

    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.transfer(beneficiary, tokenAmount);
    }

    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {}

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal virtual {
        require(beneficiary != address(0), "Crowdsale: beneficiary cannot be zero address");
        require(weiAmount != 0, "Crowdsale: wei amount cannot be 0");
        this;
    }

    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal {}

    function _forwardFunds() internal virtual {
        _wallet.transfer(msg.value);
    }

    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

        uint256 tokens = _getTokenAmount(weiAmount);

        _weiRaised += weiAmount;

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);

    }

    fallback() external payable {
        buyTokens(_msgSender());
    }

    receive() external payable {
        buyTokens(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
import "../Extras/Library/Safemath.sol";
import "../Extras/Interface/IERC20.sol";



contract Vesting  {
    using SafeMath for uint256;
  

    IERC20 private Token;
    uint256 public tokensToVest = 0;
    uint256 private vestingId = 0;
    address internal Beneficiary;
    address owner;

    string private constant INSUFFICIENT_BALANCE = "Insufficient balance";
    string private constant INVALID_VESTING_ID = "Invalid vesting id";
    string private constant VESTING_ALREADY_RELEASED = "Vesting already released";
    string private constant INVALID_BENEFICIARY = "Invalid beneficiary address";
    string private constant NOT_VESTED = "Tokens have not vested yet";

    struct Vesting_ {
        uint256 startTime;
        uint256 releaseTime;
        uint256 amount;
        address beneficiary;
        bool released;
    }
    mapping(uint256 => Vesting_) public vestings;

    event TokenVestingReleased(uint256 indexed vestingId, address indexed beneficiary, uint256 amount);
    event TokenVestingAdded(uint256 indexed vestingId, address indexed beneficiary, uint256 amount);
    event TokenVestingRemoved(uint256 indexed vestingId, address indexed beneficiary, uint256 amount);

    modifier onlyOwner(){
        require(msg.sender==owner,"Only owner can run this");
        _;
    }

    constructor(IERC20 _token,address _beneficiary) public {
        require(address(_token) != address(0x0), "Matic token address is not valid");
        Token = _token;
        Beneficiary=_beneficiary;
        owner=Beneficiary;
    }

    function token() public view returns (IERC20) {
        return Token;
    }

    function beneficiary(uint256 _vestingId) public view returns (address) {
        return vestings[_vestingId].beneficiary;
    }
 
    function releaseTime(uint256 _vestingId) public view returns (uint256){
        return vestings[_vestingId].releaseTime;
    }

    function vestingAmount(uint256 _vestingId) public view returns (uint256) {
        return vestings[_vestingId].amount;
    }

    function removeVesting(uint256 _vestingId) public onlyOwner {
        Vesting_ storage vesting = vestings[_vestingId];
        require(vesting.beneficiary != address(0x0), INVALID_VESTING_ID);
        require(!vesting.released , VESTING_ALREADY_RELEASED);
        vesting.released = true;
        tokensToVest = tokensToVest.sub(vesting.amount);
        emit TokenVestingRemoved(_vestingId, vesting.beneficiary, vesting.amount);
    }

    function addVesting(uint _startTime, uint256 _releaseTime, uint256 _amount) public  {
        require(Beneficiary != address(0x0), INVALID_BENEFICIARY);
        require(Token.balanceOf(address(this))>=_amount+tokensToVest);
        tokensToVest = tokensToVest.add(_amount);
        vestingId = vestingId.add(1);
        vestings[vestingId] = Vesting_({
            startTime:_startTime,
            beneficiary: Beneficiary,
            releaseTime: _releaseTime,
            amount: _amount,
            released: false
        });
        emit TokenVestingAdded(vestingId,Beneficiary, _amount);
    }

    function release(uint256 _vestingId) public {
        Vesting_ storage vesting = vestings[_vestingId];
        require(vesting.beneficiary != address(0x0), INVALID_VESTING_ID);
        require(!vesting.released , VESTING_ALREADY_RELEASED);
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= vesting.releaseTime, NOT_VESTED);

        require(Token.balanceOf(address(this)) >= vesting.amount, INSUFFICIENT_BALANCE);
        vesting.released = true;
        tokensToVest = tokensToVest.sub(vesting.amount);
        Token.transfer(vesting.beneficiary, vesting.amount);
        emit TokenVestingReleased(_vestingId, vesting.beneficiary, vesting.amount);
    }

    function retrieveExcessTokens(uint256 _amount) public onlyOwner {
        require(_amount <= Token.balanceOf(address(this)).sub(tokensToVest), INSUFFICIENT_BALANCE);
        Token.transfer(owner, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
       function mint(address _to, uint256 _value) external returns (bool success);
          function burn(uint256 _value) external returns (bool success);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./IERC20.sol";
interface IVest{
  event Released(uint256 amount);
  event Revoked();
   function release(IERC20 token) external returns (bool);
   function revoke(IERC20 token) external returns(bool);
   function releasableAmount(IERC20 token) external view returns (uint256);
  function vestedAmount(IERC20 token) external view returns (uint256);
   function token() external view returns (IERC20);
    function releaseTime(uint256 _vestingId) external view returns (uint256);
   function beneficiary(uint256 _vestingId) external view returns (address);
   function vestingAmount(uint256 _vestingId) external view returns (uint256);
    function removeVesting(uint256 _vestingId) external;
    function addVesting(uint _startTime, uint256 _releaseTime, uint256 _amount) external;
    function release(uint256 _vestingId) external;
            
    function retrieveExcessTokens(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../utils/context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.6.12;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() public {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}