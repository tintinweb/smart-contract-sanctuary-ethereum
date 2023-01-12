pragma solidity >=0.5.16;
pragma experimental ABIEncoderV2;

import "./EIP20Interface.sol";
import "./SafeMath.sol";
import "./LendingWhiteList.sol";
import "./EnumerableSet.sol";
import "./owned.sol";

contract EsgSHIP is owned, LendingWhiteList {
	using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _set;

    /// @notice ESG token
    EIP20Interface public esg;

    /// @notice Emitted when referral set referral
    event SetReferral(address referralAddress);

    /// @notice Emitted when ESG is staked  
    event EsgStaked(address account, uint amount);

    /// @notice Emitted when ESG is withdrawn 
    event EsgWithdrawn(address account, uint amount);

    /// @notice Emitted when ESG is claimed 
    event EsgClaimed(address account, uint amount);

    // @notice The rate every day. 
    uint256 public dayEsgRate; 

    // @notice A checkpoint for staking
    struct Checkpoint {
        uint256 deposit_time; //last check time
        uint256 total_staked;
        uint256 bonus_unclaimed;
    }

    // @notice staking struct of every account
    mapping (address => Checkpoint) public stakings;

    mapping (address => EnumerableSet.AddressSet) inviteelist;//1:n

	struct User {
        address referrer_addr;
    }

    mapping (address => User) referrerlist;//1:1

    // @notice total stake amount
    uint256 public total_deposited;
    uint256 public referrer_rate;
    uint256 public ship_rate;
    uint256 public referrer_limit_num;
    uint256 public referrer_reward_limit_num;
    uint256 public ship_reward_limit_num;

    constructor(address esgAddress) public {
        owner = msg.sender;
		dayEsgRate = 1.37e15;
		referrer_rate = 2e17;
	    ship_rate = 8e16;
	    referrer_limit_num = 1e21;
	    referrer_reward_limit_num = 0;
	    ship_reward_limit_num = 1e23;
		esg = EIP20Interface(esgAddress);
    }

    function setInvitee(address inviteeAddress) public returns (bool) {
    	require(inviteeAddress != address(0), "inviteeAddress should not be 0x0.");

    	EnumerableSet.AddressSet storage es = inviteelist[msg.sender];
    	User storage user = referrerlist[inviteeAddress];
    	require(user.referrer_addr == address(0), "This account had been invited!");

    	Checkpoint storage cpt = stakings[inviteeAddress];
    	require(cpt.total_staked == 0, "This account had staked!");

    	Checkpoint storage cp = stakings[msg.sender];

    	if(isWhitelisted(msg.sender)){
    		EnumerableSet.add(es, inviteeAddress);  	
	    	user.referrer_addr = msg.sender;
	    }else{
	    	if(cp.total_staked >= referrer_limit_num){
	    		EnumerableSet.add(es, inviteeAddress);
		    	user.referrer_addr = msg.sender;
		    }else{
		        return false;
		    }
	    }
    	emit SetReferral(inviteeAddress);
        return true;   
    }

    function getInviteelist(address referrerAddress) public view returns (address[] memory) {
    	require(referrerAddress != address(0), "referrerAddress should not be 0x0.");
    	EnumerableSet.AddressSet storage es = inviteelist[referrerAddress];
    	uint256 _length = EnumerableSet.length(es);
    	address[] memory _inviteelist = new address[](_length);
    	for(uint i=0; i<EnumerableSet.length(es); i++){
    		_inviteelist[i] = EnumerableSet.at(es,i);
    	}
    	return _inviteelist;
    }

    function getReferrer(address inviteeAddress) public view returns (address) {
    	require(inviteeAddress != address(0), "inviteeAddress should not be 0x0.");
    	User storage user = referrerlist[inviteeAddress];
    	return user.referrer_addr;
    }

    /**
     * @notice Stake ESG token to contract 
     * @param amount The amount of address to be staked 
     * @return Success indicator for whether staked 
     */
    function stake(uint256 amount) public returns (bool) {
		require(amount > 0, "No zero.");
		require(amount <= esg.balanceOf(msg.sender), "Insufficient ESG token.");

		Checkpoint storage cp = stakings[msg.sender];

		esg.transferFrom(msg.sender, address(this), amount);

		if(cp.deposit_time > 0)
		{
			uint256 bonus = block.timestamp.sub(cp.deposit_time).mul(cp.total_staked).mul(dayEsgRate).div(1e18).div(86400);
			cp.bonus_unclaimed = cp.bonus_unclaimed.add(bonus);
			cp.total_staked = cp.total_staked.add(amount);
			cp.deposit_time = block.timestamp;
		}else
		{
			cp.total_staked = amount;
			cp.deposit_time = block.timestamp;
		}
	    total_deposited = total_deposited.add(amount);
		emit EsgStaked(msg.sender, amount);

		return true;
    }

    /**
     * @notice withdraw all ESG token staked in contract 
     * @return Success indicator for success 
     */
    function withdraw() public returns (bool) {
    	
    	Checkpoint storage cp = stakings[msg.sender];
		uint256 amount = cp.total_staked;
		uint256 bonus = block.timestamp.sub(cp.deposit_time).mul(cp.total_staked).mul(dayEsgRate).div(1e18).div(86400);
		cp.bonus_unclaimed = cp.bonus_unclaimed.add(bonus);
		cp.total_staked = 0;
		cp.deposit_time = 0;
	    total_deposited = total_deposited.sub(amount);
		
		esg.transfer(msg.sender, amount);

		emit EsgWithdrawn(msg.sender, amount); 

		return true;
    }

    /**
     * @notice claim all ESG token bonus in contract 
     * @return Success indicator for success 
     */
    function claim() public returns (bool) {
		User storage user = referrerlist[msg.sender];
    	address _referrer_addr = user.referrer_addr;
    	uint256 incentive;
    	uint256 incentive_holder;

		Checkpoint storage cp = stakings[msg.sender];
		Checkpoint storage cpt = stakings[_referrer_addr];

		uint256 amount = cp.bonus_unclaimed;
		if(cp.deposit_time > 0)
		{
			uint256 bonus = block.timestamp.sub(cp.deposit_time).mul(cp.total_staked).mul(dayEsgRate).div(1e18).div(86400);
			amount = amount.add(bonus);
			cp.bonus_unclaimed = 0; 
			cp.deposit_time = block.timestamp;
			
		}else{
			//has beed withdrawn
			cp.bonus_unclaimed = 0;
		}

		if(total_deposited >= ship_reward_limit_num){
			incentive_holder = amount.mul(ship_rate).div(1e18);
			if(_referrer_addr != address(0)){
				if(cpt.total_staked >= referrer_reward_limit_num){
					incentive = amount.mul(referrer_rate).div(1e18);
					esg.transfer(_referrer_addr, incentive);
				}
				esg.transfer(owner, incentive_holder);
				esg.transfer(msg.sender, amount);
    		}else
	    	{
	    		esg.transfer(owner, incentive_holder);
	    		esg.transfer(msg.sender, amount.sub(incentive_holder));
	    	}
		}else
		{
			if(_referrer_addr != address(0)){
				if(cpt.total_staked >= referrer_reward_limit_num){
					incentive = amount.mul(referrer_rate).div(1e18);
					esg.transfer(_referrer_addr, incentive);
				}
				esg.transfer(msg.sender, amount);
    		}else
	    	{
	    		esg.transfer(msg.sender, amount);
	    	}
		}

		emit EsgClaimed (msg.sender, amount); 

		return true;
    }

    // set the dayrate
    function setDayEsgRate(uint256 dayRateMantissa) public{
	    require(msg.sender == owner, "only owner can set this value.");
	    dayEsgRate = dayRateMantissa;
    }

    // set referrerRate
    function setReferrerRate(uint256 referrerRateMantissa) public{
	    require(msg.sender == owner, "only owner can set this value.");
	    referrer_rate = referrerRateMantissa;
    }

    // set shipRate
    function setShipRate(uint256 shipRateMantissa) public{
	    require(msg.sender == owner, "only owner can set this value.");
	    ship_rate = shipRateMantissa;
    }

    // set referrerLimitNum
    function setReferrerLimitNum(uint256 referrerLimitNum) public{
	    require(msg.sender == owner, "only owner can set this value.");
	    referrer_limit_num = referrerLimitNum;
    }

    // set referrerRewardLimitNum
    function setReferrerRewardLimitNum(uint256 referrerRewardLimitNum) public{
	    require(msg.sender == owner, "only owner can set this value.");
	    referrer_reward_limit_num = referrerRewardLimitNum;
    }

    // set shipRewardLimitNum
    function setShipRewardLimitNum(uint256 shipRewardLimitNum) public{
	    require(msg.sender == owner, "only owner can set this value.");
	    ship_reward_limit_num = shipRewardLimitNum;
    }

    function _withdrawERC20Token(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "invalid address");
        uint256 tokenAmount = esg.balanceOf(address(this));
        if(tokenAmount > 0)
            esg.transfer(msg.sender, tokenAmount);
        else
            revert("insufficient ERC20 tokens");
    }

    /**
     * @notice Returns the balance of ESG an account has staked
     * @param account The address of the account 
     * @return balance of ESG 
     */
    function getStakingBalance(address account) external view returns (uint256) {
		Checkpoint memory cp = stakings[account];
        return cp.total_staked;
    }

    /**
     * @notice Return the unclaimed bonus ESG of staking 
     * @param account The address of the account 
     * @return The amount of unclaimed ESG 
     */
    function getUnclaimedEsg(address account) public view returns (uint256) {
		Checkpoint memory cp = stakings[account];

		uint256 amount = cp.bonus_unclaimed;
		if(cp.deposit_time > 0)
		{
			uint256 bonus = block.timestamp.sub(cp.deposit_time).mul(cp.total_staked).mul(dayEsgRate).div(1e18).div(86400);
			amount = amount.add(bonus);
		}
		return amount;
    }

    /**
     * @notice Return the APY of staking 
     * @return The APY multiplied 1e18
     */
    function getStakingAPYMantissa() public view returns (uint256) {
        return dayEsgRate.mul(365);
    }

    /**
     * @notice Return the address of the ESG token
     * @return The address of ESG 
     */
    function getEsgAddress() public view returns (address) {
        return address(esg);
    }

}

pragma solidity >=0.5.16;

contract owned {
    address public owner;
 
    constructor() public {
        owner = msg.sender;
    }
 
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
 
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}

pragma solidity ^0.5.16;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

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
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    /**
   * @dev gives square root of given x.
   */
  function sqrt(uint256 x) internal pure returns(uint256 y) {
        uint256 z = ((add(x, 1)) / 2);
        y = x;
        while (z < y) {
            y = z;
            z = ((add((x / z), z)) / 2);
        }
  }

  /**
   * @dev gives square. multiplies x by x
   */
  function sq(uint256 x) internal pure returns(uint256) {
       return (mul(x, x));
  }

  /**
   * @dev x to the power of y
   */
  function pwr(uint256 x, uint256 y) internal pure returns(uint256) {
    if (x == 0)
      return (0);
    else if (y == 0)
      return (1);
    else {
      uint256 z = x;
      for (uint256 i = 1; i < y; i++)
        z = mul(z, x);
      return (z);
    }
  }
}

pragma solidity >=0.5.16;

import "./EnumerableSet.sol";
import "./owned.sol";

contract LendingWhiteList is owned {

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _whitelist;

    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    constructor() public {
    }

    modifier onlyWhitelisted {
        require(isWhitelisted(msg.sender), "LendingWhiteList: caller is not in whitelist");
        _;
    }

    function add(address _address) public onlyOwner returns(bool) {
        require(_address != address(0), "LendingWhiteList: _address is the zero address");
        EnumerableSet.add(_whitelist, _address);
        emit AddedToWhitelist(_address);
        return true;
    }

    function remove(address _address) public onlyOwner returns(bool) {
        require(_address != address(0), "LendingWhiteList: _address is the zero address");
        EnumerableSet.remove(_whitelist, _address);
        emit RemovedFromWhitelist(_address);
        return true;
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return EnumerableSet.contains(_whitelist, _address);
    }
}

pragma solidity >=0.5.16;
/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

pragma solidity ^0.5.16;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}