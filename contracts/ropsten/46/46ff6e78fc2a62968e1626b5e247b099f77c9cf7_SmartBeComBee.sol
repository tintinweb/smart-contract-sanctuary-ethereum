/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

/**
 *Submitted for verification at BscScan.com on 2022-07-22
*/

//smart contract BSC

pragma solidity <0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


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

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        //(bool success, ) = recipient.call{ value: amount }("");
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        //(bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        (bool success, bytes memory returndata) = target.call.value(weiValue)(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract SmartBeComBee {

    using SafeERC20 for IERC20;
    
    struct B3 {
        address currentReferrer;
        address[] referrals;
        uint reinvestCount;
        bool blocked;
    }
    
    struct B6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        uint reinvestCount;
        bool blocked;

        address closedPart;
    }

    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) activeB3Levels;
        mapping(uint8 => bool) activeB6Levels;
        
        mapping(uint8 => B3) b3Matrix;
        mapping(uint8 => B6) b6Matrix;
    }

    uint8 public constant LAST_LEVEL = 9;
    
    mapping(address => uint) public balances; 
    mapping(uint => address) public userIds;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;

    address public owner;
    uint public lastUserId = 2;
    
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    
    mapping(uint8 => uint) public levelCost;

    IERC20 public _token;

    constructor(address ownerAddress) public {

        levelCost[1] = 30;
        levelCost[2] = 70;
        levelCost[3] = 150;
        levelCost[4] = 300;
        levelCost[5] = 600;
        levelCost[6] = 1500;
        levelCost[7] = 3000;
        levelCost[8] = 6000;
        levelCost[9] = 12000;
        
        // levelCost[1] = 0.025 ether;
        // for (uint8 i = 2; i <= LAST_LEVEL; i++) {

        //     levelCost[i] = levelCost[i-1] * 2;
        // }

        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            partnersCount: uint(0),
            referrer: address(0)
        });
        
        idToAddress[1] = ownerAddress;
        users[ownerAddress] = user;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeB3Levels[i] = true;

            users[ownerAddress].activeB6Levels[i] = true;
        }
        
        userIds[1] = ownerAddress;
    }

    // function getUser(address userAddress) public view returns(User memory) {
    //     User memory result = users[userAddress];
    //     result.activeB3Levels = [];

    //     for(uint i = 0; i < 9; i++){
    //         result.activeB3Levels[i] = usersActiveB3Levels(userAddress, 1+1);
    //     }
    //     for(uint i = 0; i < 9; i++){
    //         result.activeB3Levels[i] = usersB3Matrix(userAddress, 1+1);
    //     }

    //     return result;
    // }

    function registration(address referrerAddress, address tokenAddress) external payable {
        registrationbase(msg.sender, referrerAddress, tokenAddress);
    }
    
    function registrationbase(address userAddress, address referrerAddress, address tokenAddress) private {

        if (tokenAddress != 0x0000000000000000000000000000000000000000){
            _token = IERC20(tokenAddress);
            //_token.transfer(receiver, 1e18);
            
            uint256 amount = 1.27e18;            
            uint256 allowance = _token.allowance(msg.sender, address(this));
            //emit AllowanceToken(allowance, amount);
            require(allowance >= amount, "Check the token allowance");

            _token.safeTransferFrom(msg.sender, address(this), amount);
        }

        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        //require(msg.value == 0.05 ether, "registration cost 0.05");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        userIds[lastUserId] = userAddress;
        lastUserId++;

        // users[userAddress].activeB3Levels[1] = true; 
        // users[userAddress].activeB6Levels[1] = true;
        
        //address freeB3Referrer = findFreeB3Refer(userAddress, 1);
        //users[userAddress].b3Matrix[1].currentReferrer = freeB3Referrer;

        users[referrerAddress].partnersCount++;

        //updB3Refer(userAddress, freeB3Referrer, 1);
        //updB6Referrer(userAddress, findFreeB6Referrer(userAddress, 1), 1);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }

    function buyLevel(uint8 matrix, uint8 level, address tokenAddress) external payable {

        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        //require(msg.value == levelCost[level], "invalid price");
        require(level >= 1 && level <= LAST_LEVEL, "invalid level");
        
        if (tokenAddress != 0x0000000000000000000000000000000000000000){
            _token = IERC20(tokenAddress);
            //_token.transfer(receiver, 1e18);

            uint256 amount = levelCost[level]*1e13 + 1e18;            
            uint256 allowance = _token.allowance(msg.sender, address(this));
            //emit AllowanceToken(allowance, amount);
            require(allowance >= amount, "Check the token allowance");

            _token.safeTransferFrom(msg.sender, address(this), amount);
        }

        if (matrix == 1) {
            //b3
            //require(users[msg.sender].activeB3Levels[level-1], "buy previous level first");
            require(!users[msg.sender].activeB3Levels[level], "level already activated");

            if (users[msg.sender].b3Matrix[level-1].blocked) {
                users[msg.sender].b3Matrix[level-1].blocked = false;
            }
    
            address freeB3Refer = findFreeB3Refer(msg.sender, level);
            users[msg.sender].b3Matrix[level].currentReferrer = freeB3Refer;
            users[msg.sender].activeB3Levels[level] = true;
            updB3Refer(msg.sender, freeB3Refer, level);
            
            emit Upgrade(msg.sender, freeB3Refer, 1, level);

        // } else {
            //b6
            //require(users[msg.sender].activeB6Levels[level-1], "buy previous level first");
            require(!users[msg.sender].activeB6Levels[level], "level already activated"); 

            if (users[msg.sender].b6Matrix[level-1].blocked) {
                users[msg.sender].b6Matrix[level-1].blocked = false;
            }

            address freeB6Referrer = findFreeB6Referrer(msg.sender, level);
            
            users[msg.sender].activeB6Levels[level] = true;
            updB6Referrer(msg.sender, freeB6Referrer, level);
            
            emit Upgrade(msg.sender, freeB6Referrer, 2, level);
        }
    }      
    
    function updB3Refer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].b3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].b3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].b3Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].b3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeB3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].b3Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeB3Refer(referrerAddress, level);
            if (users[referrerAddress].b3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].b3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].b3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updB3Refer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(owner, userAddress, 1, level);
            users[owner].b3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }   

    function updB6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeB6Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].b6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].b6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].b6Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].b6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].b6Matrix[level].currentReferrer;            
            users[ref].b6Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].b6Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].b6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].b6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].b6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].b6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].b6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].b6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].b6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }

            return updB6ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].b6Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].b6Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].b6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].b6Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].b6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].b6Matrix[level].closedPart)) {

                updB6(userAddress, referrerAddress, level, true);
                return updB6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].b6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].b6Matrix[level].closedPart) {
                updB6(userAddress, referrerAddress, level, true);
                return updB6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updB6(userAddress, referrerAddress, level, false);
                return updB6ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].b6Matrix[level].firstLevelReferrals[1] == userAddress) {
            updB6(userAddress, referrerAddress, level, false);
            return updB6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].b6Matrix[level].firstLevelReferrals[0] == userAddress) {
            updB6(userAddress, referrerAddress, level, true);
            return updB6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].b6Matrix[level].firstLevelReferrals[0]].b6Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].b6Matrix[level].firstLevelReferrals[1]].b6Matrix[level].firstLevelReferrals.length) {
            updB6(userAddress, referrerAddress, level, false);
        } else {
            updB6(userAddress, referrerAddress, level, true);
        }
        
        updB6ReferrerSecondLevel(userAddress, referrerAddress, level);
    } 
    function updB6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].b6Matrix[level].firstLevelReferrals[0]].b6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].b6Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].b6Matrix[level].firstLevelReferrals[0]].b6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].b6Matrix[level].firstLevelReferrals[0]].b6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].b6Matrix[level].currentReferrer = users[referrerAddress].b6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].b6Matrix[level].firstLevelReferrals[1]].b6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].b6Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].b6Matrix[level].firstLevelReferrals[1]].b6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].b6Matrix[level].firstLevelReferrals[1]].b6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].b6Matrix[level].currentReferrer = users[referrerAddress].b6Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updB6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].b6Matrix[level].secondLevelReferrals.length < 4) {
            return sendETHDividends(referrerAddress, userAddress, 2, level);
        }
        
        address[] memory b6 = users[users[referrerAddress].b6Matrix[level].currentReferrer].b6Matrix[level].firstLevelReferrals;
        
        if (b6.length == 2) {
            if (b6[0] == referrerAddress ||
                b6[1] == referrerAddress) {
                users[users[referrerAddress].b6Matrix[level].currentReferrer].b6Matrix[level].closedPart = referrerAddress;
            } else if (b6.length == 1) {
                if (b6[0] == referrerAddress) {
                    users[users[referrerAddress].b6Matrix[level].currentReferrer].b6Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].b6Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].b6Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].b6Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeB6Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].b6Matrix[level].blocked = true;
        }

        users[referrerAddress].b6Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeB6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updB6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendETHDividends(owner, userAddress, 2, level);
        }
    }
    
    function findFreeB3Refer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeB3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }

    function findFreeB6Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeB6Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveB3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeB3Levels[level];
    }
    function usersActiveB3Levels2(address userAddress, uint8 level) public view returns(bool, uint8) {
        return (users[userAddress].activeB3Levels[level], 
                level);
    }
    function usersActiveB3LevelsAll(address userAddress) public view returns(bool[] memory) {
        bool[] memory result;

        for(uint i = 0; i < 9; i++){
            result[i] = users[userAddress].activeB3Levels[uint8(i+1)];
        }

        return result;
    }

    function usersActiveB6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeB6Levels[level];
    }
    function usersActiveB6Levels2(address userAddress, uint8 level) public view returns(bool, uint8) {
        return (users[userAddress].activeB6Levels[level], 
                level);
    }
    function usersActiveB6LevelsAll(address userAddress) public view returns(bool[] memory) {
        bool[] memory result;

        for(uint i = 0; i < 9; i++){
            result[i] = users[userAddress].activeB6Levels[uint8(i+1)];
        }

        return result;
    }

    function usersB3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].b3Matrix[level].currentReferrer,
                users[userAddress].b3Matrix[level].referrals,
                users[userAddress].b3Matrix[level].blocked);
    }
    function usersB3Matrix2(address userAddress, uint8 level) public view returns(address, address[] memory, bool, uint8) {
        return (users[userAddress].b3Matrix[level].currentReferrer,
                users[userAddress].b3Matrix[level].referrals,
                users[userAddress].b3Matrix[level].blocked, 
                level);
    }

    function usersB6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address) {
        return (users[userAddress].b6Matrix[level].currentReferrer,
                users[userAddress].b6Matrix[level].firstLevelReferrals,
                users[userAddress].b6Matrix[level].secondLevelReferrals,
                users[userAddress].b6Matrix[level].blocked,
                users[userAddress].b6Matrix[level].closedPart);
    }
    function usersB6Matrix2(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address, uint8) {
        return (users[userAddress].b6Matrix[level].currentReferrer,
                users[userAddress].b6Matrix[level].firstLevelReferrals,
                users[userAddress].b6Matrix[level].secondLevelReferrals,
                users[userAddress].b6Matrix[level].blocked,
                users[userAddress].b6Matrix[level].closedPart,
                level);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].b3Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].b3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].b6Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].b6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

        uint256 amount = levelCost[level]*1e13 + 1e18;   
        _token.safeTransfer(receiver, amount);
        // if (!address(uint160(receiver)).send(levelCost[level])) {
        //     return address(uint160(receiver)).transfer(address(this).balance);
        // }
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    
    function transfertoken(address receiver, address tokenAddress) external payable {
        require(msg.value > 0, "invalid price");

        //transfer ether from contrat to address
        //return address(uint160(receiver)).transfer(msg.value);

        //transfer token from token contract to address
        //_token = IERC20(address_contract);
        _token = IERC20(tokenAddress);
        _token.transfer(receiver, 1e18);
    }
}