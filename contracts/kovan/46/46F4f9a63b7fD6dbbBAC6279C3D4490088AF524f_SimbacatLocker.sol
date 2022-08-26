/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

/*
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

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



pragma solidity ^0.8.0;


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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
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


pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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


contract SimbacatLocker is Ownable, ReentrancyGuard{

	mapping(bytes32 => bool) internal boolStorage;

	using SafeMath for uint256;

	struct Locker{
		address ownerAddress;
		uint256 initialAmount;
		uint256 amount;
		uint256 lockDate;
		uint256 unlockDate;
	}

	mapping(address => address[]) public lockedTokens;
	mapping(address => address[]) public lockedUser;
	mapping(address =>  mapping (address => Locker)) public TokensLocker;

	uint256 private _fee;
	uint256 private _affiliatePercent;
    uint256 private _affiliateFee;

	address payable private _devAddress;

	mapping(address => bool) public IsAffiliate;
    mapping(address => uint8) public FreeAffiliate;

	event onDeposit(address lpToken, address user, uint256 amount, uint256 lockDate, uint256 unlockDate);
  	event onWithdraw(address lpToken, uint256 amount);
    event affiliateEarn(address tokenAddress, address user, address referral, uint256 commission);

    constructor(uint256 fee_, uint256 affiliatePercent_, address payable devAddress_, uint256 affiliateFee_){
        _fee = fee_;
        _affiliatePercent = affiliatePercent_;
        _devAddress = devAddress_;
        _affiliateFee = affiliateFee_;
    }

	function GetFee() public view returns(uint256 Fee){
		return _fee;
	}
	function SetFee(uint256 fee_) public onlyOwner returns(bool IsSuccessful){
		require(fee_ >=0, "Fee must be greater or equal to zero");
		_fee = fee_;
		return true;
	}
    function GetAffiliateFee() public view returns(uint256 AffiliateFee){
		return _affiliateFee;
	}
	function SetAffiliateFee(uint256 affiliateFee_) public onlyOwner returns(bool IsSuccessful){
		require(affiliateFee_ >=0, "Fee must be greater or equal to zero");
		_affiliateFee = affiliateFee_;
		return true;
	}
	function GetAffiliatePercent() public view returns(uint256 AffiliateFee){
		return _affiliatePercent;
	}
	function SetAffiliatePercent(uint256 affiliatePercent_) public onlyOwner returns(bool IsSuccessful){
		require(affiliatePercent_ >=0, "AffiliateFee must be greater or equal to zero");
		_affiliatePercent = affiliatePercent_;
		return true;
	}
	function GetDevAddress() public view returns(address DevAddress){
		return _devAddress;
	}
	function SetDevAddress(address payable devAddress_) public onlyOwner returns(bool IsSuccessful){
		require(devAddress_ !=address(0), "DevAddress can't be zero address");
		_devAddress = devAddress_;
		return true;
	}
	function SetAfiliate(address _affiliateAddress, bool _state) public onlyOwner returns(bool IsSuccessful){
		require(_affiliateAddress !=address(0), "affiliateAddress can't be zero address");
		IsAffiliate[_affiliateAddress] = _state;
		return true;
	}
    function BecomeAffiliate(address _affiliateAddress) external payable returns(bool IsSuccessful){
        require(msg.value ==_affiliateFee, "Insufficient amount");
        IsAffiliate[_affiliateAddress] = true;
        _devAddress.transfer(_affiliateFee);
        return true;
    }
	function LockToken(address _tokenAddress, uint256 _amount, uint256 _unlockDate, address payable _withdrawer, address payable _affiliateAddress) external payable nonReentrant{
		require(_unlockDate < 10000000000, 'TIMESTAMP INVALID');
		require(_amount > 0, 'INSUFFICIENT');

		IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);

		require(msg.value == _fee, 'FEE NOT MET');

		uint256 _devFee = _fee;

		if(IsAffiliate[_affiliateAddress] || FreeAffiliate[_affiliateAddress] > 2){
			uint256 _affFee = _fee.mul(_affiliatePercent).div(100);
			_affiliateAddress.transfer(_affFee);

			_devFee = _fee.sub(_affFee);
            emit affiliateEarn(_tokenAddress, msg.sender, _affiliateAddress, _affFee);
		}
        else{
            uint8 _counter = FreeAffiliate[_affiliateAddress] + 1;
            FreeAffiliate[_affiliateAddress] = _counter;
        }
		_devAddress.transfer(_devFee);

		require(!boolStorage[keccak256(abi.encodePacked(_tokenAddress,_withdrawer))], "Token already locked");

		
		Locker memory token_lock;
        token_lock.lockDate = block.timestamp;
        token_lock.amount = _amount;
        token_lock.initialAmount = _amount;
        token_lock.unlockDate = _unlockDate;
        token_lock.ownerAddress = _withdrawer;
        
        TokensLocker[_tokenAddress][_withdrawer] = token_lock;
        boolStorage[keccak256(abi.encodePacked(_tokenAddress,_withdrawer))] = true;

        if(!boolStorage[keccak256(abi.encodePacked(_withdrawer,_tokenAddress))]){
	        lockedTokens[_tokenAddress].push(_withdrawer);
	        lockedUser[_withdrawer].push(_tokenAddress);
	        boolStorage[keccak256(abi.encodePacked(_withdrawer,_tokenAddress))] = true;
    	}
    	emit onDeposit(_tokenAddress, msg.sender, token_lock.amount, token_lock.lockDate, token_lock.unlockDate);
		
	}
	function AddToLockedToken(address _tokenAddress, uint256 _amount, uint256 _unlockDate, address payable _withdrawer) external nonReentrant{
		require(_unlockDate < 10000000000, 'TIMESTAMP INVALID');
		require(_amount > 0, 'INSUFFICIENT');
		require(boolStorage[keccak256(abi.encodePacked(_tokenAddress,_withdrawer))], "Token not yet lock");

		IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);

		//require(msg.sender == _withdrawer, '_withdrawer no sender');
	    Locker storage tokenLock = TokensLocker[_tokenAddress][_withdrawer];
		tokenLock.amount= tokenLock.amount.add(_amount);
		tokenLock.initialAmount= tokenLock.initialAmount.add(_amount);
		//tokenLock.lockDate = block.timestamp;
		if(_unlockDate > tokenLock.unlockDate){
		    tokenLock.unlockDate = _unlockDate;
		}
		emit onDeposit(_tokenAddress, msg.sender, tokenLock.amount, tokenLock.lockDate, tokenLock.unlockDate);
	}
	function ExtendLockDate (address _tokenAddress,  uint256 _unlock_date) external nonReentrant {
	    require(_unlock_date < 10000000000, 'TIMESTAMP INVALID');
	    Locker storage userLock = TokensLocker[_tokenAddress][msg.sender];
	    require(userLock.ownerAddress == msg.sender, 'Address owner is not the locker'); 
	    require(userLock.unlockDate < _unlock_date, 'UNLOCK BEFORE');

	    userLock.unlockDate = _unlock_date;

  	}
  	function withdraw (address _tokenAddress, uint256 _amount) external nonReentrant {
	    require(_amount > 0, 'ZERO WITHDRAWL');
	    Locker storage userLock = TokensLocker[_tokenAddress][msg.sender];
	    require(userLock.ownerAddress == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected
	    require(userLock.unlockDate < block.timestamp, 'NOT YET');
	    userLock.amount = userLock.amount.sub(_amount);

	    // clean user storage
	    if (userLock.amount == 0) {
			boolStorage[keccak256(abi.encodePacked(_tokenAddress,msg.sender))] = false;
	    }
	    
	    IERC20(_tokenAddress).transfer(msg.sender, _amount);
	    emit onWithdraw(_tokenAddress, _amount);
  	}
  	function GetTokenLocker (address _tokenAddress) external view returns (address[] memory Users) {
	    address[] memory addr_list = lockedTokens[_tokenAddress];
	    return addr_list;
  	}
	  
	function GetTokenLockedByUser (address _user) external view returns (address[] memory TokenAddresses) {
	    address[] memory addr_list = lockedUser[_user];
	    return addr_list;
  	}
	  
  	function GetTokenLockedDetailFromUser (address _user, address _tokenAddress) external view returns (uint256 LockDate, uint256 LockAmount, uint256 InitailAmount, uint256 UnlockDate, address LockOwner) {
	    Locker storage tokenLock = TokensLocker[_tokenAddress][_user];
	    return (tokenLock.lockDate, tokenLock.amount, tokenLock.initialAmount, tokenLock.unlockDate, tokenLock.ownerAddress);
  	}
}