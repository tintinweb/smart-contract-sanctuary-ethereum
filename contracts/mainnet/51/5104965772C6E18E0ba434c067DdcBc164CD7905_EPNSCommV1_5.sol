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

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
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
        (bool success, ) = recipient.call{ value: amount }("");
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

pragma solidity >=0.6.0 <0.7.0;

contract EPNSCommStorageV1_5 {
    /**
     * @notice User Struct that involves imperative details about
     * a specific User.
     **/
    struct User {
        // @notice Depicts whether or not a user is ACTIVE
        bool userActivated;
        // @notice Will be false until public key is emitted
        bool publicKeyRegistered;
        // @notice Events should not be polled before this block as user doesn't exist
        uint256 userStartBlock;
        // @notice Keep track of subscribers
        uint256 subscribedCount;
        /**
         * Depicts if User subscribed to a Specific Channel Address
         * 1 -> User is Subscribed
         * 0 -> User is NOT SUBSCRIBED
         **/
        mapping(address => uint8) isSubscribed;
        // Keeps track of all subscribed channels
        mapping(address => uint256) subscribed;
        mapping(uint256 => address) mapAddressSubscribed;
    }

    /** MAPPINGS **/
    mapping(address => User) public users;
    mapping(address => uint256) public nonces;
    mapping(uint256 => address) public mapAddressUsers;
    mapping(address => mapping(address => string)) public userToChannelNotifs;
    mapping(address => mapping(address => bool))
        public delegatedNotificationSenders;

    /** STATE VARIABLES **/
    address public governance;
    address public pushChannelAdmin;
    uint256 public chainID;
    uint256 public usersCount;
    bool public isMigrationComplete;
    address public EPNSCoreAddress;
    string public chainName;
    string public constant name = "EPNS COMM V1";
    bytes32 public constant NAME_HASH = keccak256(bytes(name));
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant SUBSCRIBE_TYPEHASH =
        keccak256("Subscribe(address channel,address subscriber,uint256 nonce,uint256 expiry)");
    bytes32 public constant UNSUBSCRIBE_TYPEHASH =
        keccak256("Unsubscribe(address channel,address subscriber,uint256 nonce,uint256 expiry)");
    bytes32 public constant SEND_NOTIFICATION_TYPEHASH =
        keccak256(
            "SendNotification(address channel,address recipient,bytes identity,uint256 nonce,uint256 expiry)"
        );
}

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT

/**
 * EPNS Communicator, as the name suggests, is more of a Communictation Layer
 * between END USERS and EPNS Core Protocol.
 * The Communicator Protocol is comparatively much simpler & involves basic
 * details, specifically about the USERS of the Protocols

 * Some imperative functionalities that the EPNS Communicator Protocol allows
 * are Subscribing to a particular channel, Unsubscribing a channel, Sending
 * Notifications to a particular recipient or all subscribers of a Channel etc.
**/

// Essential Imports
// import "hardhat/console.sol";
import "./EPNSCommStorageV1_5.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IERC1271.sol";

contract EPNSCommV1_5 is Initializable, EPNSCommStorageV1_5 {
    using SafeMath for uint256;

    /** EVENTS **/
    event SendNotification(
        address indexed channel,
        address indexed recipient,
        bytes identity
    );
    event UserNotifcationSettingsAdded(
        address _channel,
        address _user,
        uint256 _notifID,
        string _notifSettings
    );
    event AddDelegate(address channel, address delegate);
    event RemoveDelegate(address channel, address delegate);
    event Subscribe(address indexed channel, address indexed user);
    event Unsubscribe(address indexed channel, address indexed user);
    event PublicKeyRegistered(address indexed owner, bytes publickey);
    event ChannelAlias(
        string _chainName,
        uint256 indexed _chainID,
        address indexed _channelOwnerAddress,
        string _ethereumChannelAddress
    );

    /** MODIFIERS **/

    modifier onlyPushChannelAdmin() {
        require(
            msg.sender == pushChannelAdmin,
            "EPNSCommV1_5::onlyPushChannelAdmin: user not pushChannelAdmin"
        );
        _;
    }

    modifier onlyEPNSCore() {
        require(
            msg.sender == EPNSCoreAddress,
            "EPNSCommV1_5::onlyEPNSCore: Caller NOT EPNSCore"
        );
        _;
    }

    /* ***************

        INITIALIZER

    *************** */
    function initialize(address _pushChannelAdmin, string memory _chainName)
        public
        initializer
        returns (bool)
    {
        pushChannelAdmin = _pushChannelAdmin;
        governance = _pushChannelAdmin;
        chainName = _chainName;
        chainID = getChainId();
        return true;
    }

    /****************

    => SETTER FUNCTIONS <=

    ****************/
    function verifyChannelAlias(string memory _channelAddress) external {
        emit ChannelAlias(chainName, chainID, msg.sender, _channelAddress);
    }

    function completeMigration() external onlyPushChannelAdmin {
        isMigrationComplete = true;
    }

    function setEPNSCoreAddress(address _coreAddress)
        external
        onlyPushChannelAdmin
    {
        EPNSCoreAddress = _coreAddress;
    }

    function setGovernanceAddress(address _governanceAddress)
        external
        onlyPushChannelAdmin
    {
        governance = _governanceAddress;
    }

    function transferPushChannelAdminControl(address _newAdmin)
        external
        onlyPushChannelAdmin
    {
        require(
            _newAdmin != address(0),
            "EPNSCommV1_5::transferPushChannelAdminControl: Invalid Address"
        );
        require(
            _newAdmin != pushChannelAdmin,
            "EPNSCommV1_5::transferPushChannelAdminControl: Admin address is same"
        );
        pushChannelAdmin = _newAdmin;
    }

    /****************

    => SUBSCRIBE FUNCTIOANLTIES <=

    ****************/

    /**
     * @notice Helper function to check if User is Subscribed to a Specific Address
     * @param _channel address of the channel that the user is subscribing to
     * @param _user address of the Subscriber
     * @return True if User is actually a subscriber of a Channel
     **/
    function isUserSubscribed(address _channel, address _user)
        public
        view
        returns (bool)
    {
        User storage user = users[_user];
        if (user.isSubscribed[_channel] == 1) {
            return true;
        }
    }

    /**
     * @notice External Subscribe Function that allows users to Diretly interact with the Base Subscribe function
     * @dev   Subscribes the caller of the function to a particular Channel
     *        Takes into Consideration the "msg.sender"
     * @param _channel address of the channel that the user is subscribing to
     **/
    function subscribe(address _channel) external returns (bool) {
        _subscribe(_channel, msg.sender);
        return true;
    }

    /**
     * @notice Allows users to subscribe a List of Channels at once
     *
     * @param _channelList array of addresses of the channels that the user wishes to Subscribe
     **/
    function batchSubscribe(address[] calldata _channelList)
        external
        returns (bool)
    {
        for (uint256 i = 0; i < _channelList.length; i++) {
            _subscribe(_channelList[i], msg.sender);
        }
        return true;
    }

    /**
     * @notice This Function helps in migrating the already existing Subscriber's data to the New protocol
     *
     * @dev     Can only be called by pushChannelAdmin
     *          Can only be called if the Migration is not yet complete, i.e., "isMigrationComplete" boolean must be false
     *          Subscribes the Users to the respective Channels as per the arguments passed to the function
     *
     * @param _startIndex  starting Index for the LOOP
     * @param _endIndex    Last Index for the LOOP
     * @param _channelList array of addresses of the channels
     * @param _usersList   array of addresses of the Users or Subscribers of the Channels
     **/

    function migrateSubscribeData(
        uint256 _startIndex,
        uint256 _endIndex,
        address[] calldata _channelList,
        address[] calldata _usersList
    ) external onlyPushChannelAdmin returns (bool) {
        require(
            !isMigrationComplete,
            "EPNSCommV1_5::migrateSubscribeData: Migration of Subscribe Data is Complete Already"
        );
        require(
            _channelList.length == _usersList.length,
            "EPNSCommV1_5::migrateSubscribeData: Unequal Arrays passed as Argument"
        );

        for (uint256 i = _startIndex; i < _endIndex; i++) {
            if (isUserSubscribed(_channelList[i], _usersList[i])) {
                continue;
            } else {
                _subscribe(_channelList[i], _usersList[i]);
            }
        }
        return true;
    }

    /**
     * @notice Base Subscribe Function that allows users to Subscribe to a Particular Channel
     *
     * @dev Initializes the User Struct with crucial details about the Channel Subscription
     *      Addes the caller as a an Activated User of the protocol. (Only if the user hasn't been added already)
     *
     * @param _channel address of the channel that the user is subscribing to
     * @param _user    address of the Subscriber
     **/
    function _subscribe(address _channel, address _user) private {
        if (!isUserSubscribed(_channel, _user)) {
            _addUser(_user);

            User storage user = users[_user];

            uint256 _subscribedCount = user.subscribedCount;

            user.isSubscribed[_channel] = 1;
            // treat the count as index and update user struct
            user.subscribed[_channel] = _subscribedCount;
            user.mapAddressSubscribed[_subscribedCount] = _channel;
            user.subscribedCount = _subscribedCount.add(1); // Finally increment the subscribed count
            // Emit it
            emit Subscribe(_channel, _user);
        }
    }

    /**
     * @notice Subscribe Function through Meta TX
     * @dev Takes into Consideration the Sign of the User
     *      Inludes EIP1271 implementation: Standard Signature Validation Method for Contracts
     **/
    function subscribeBySig(
        address channel,
        address subscriber,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // EIP-712
        require(
            subscriber != address(0),
            "EPNSCommV1_5::subscribeBySig: Invalid signature"
        );
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, NAME_HASH, getChainId(), address(this))
        );
        bytes32 structHash = keccak256(
            abi.encode(SUBSCRIBE_TYPEHASH, channel, subscriber, nonce, expiry)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        if (Address.isContract(subscriber)) {
            // use EIP-1271
            bytes4 result = IERC1271(subscriber).isValidSignature(
                digest,
                abi.encodePacked(r, s, v)
            );
            require(result == 0x1626ba7e, "INVALID SIGNATURE FROM CONTRACT");
        } else {
            // validate with in contract
            address signatory = ecrecover(digest, v, r, s);
            require(signatory == subscriber, "INVALID SIGNATURE FROM EOA");
        }
        require(
            nonce == nonces[subscriber]++,
            "EPNSCommV1_5::subscribeBySig: Invalid nonce"
        );
        require(
            now <= expiry,
            "EPNSCommV1_5::subscribeBySig: Signature expired"
        );

        _subscribe(channel, subscriber);
    }

    /**
     * @notice Allows EPNSCore contract to call the Base Subscribe function whenever a User Creates his/her own Channel.
     *         This ensures that the Channel Owner is subscribed to imperative EPNS Channels as well as his/her own Channel.
     *
     * @dev    Only Callable by the EPNSCore. This is to ensure that Users should only able to Subscribe for their own addresses.
     *         The caller of the main Subscribe function should Either Be the USERS themselves(for their own addresses) or the EPNSCore contract
     *
     * @param _channel address of the channel that the user is subscribing to
     * @param _user address of the Subscriber of a Channel
     **/
    function subscribeViaCore(address _channel, address _user)
        external
        onlyEPNSCore
        returns (bool)
    {
        _subscribe(_channel, _user);
        return true;
    }

    /****************

    => USUBSCRIBE FUNCTIOANLTIES <=

    ****************/

    /**
     * @notice External Unsubcribe Function that allows users to directly unsubscribe from a particular channel
     *
     * @dev UnSubscribes the caller of the function from the particular Channel.
     *      Takes into Consideration the "msg.sender"
     *
     * @param _channel address of the channel that the user is subscribing to
     **/
    function unsubscribe(address _channel) external returns (bool) {
        // Call actual unsubscribe
        _unsubscribe(_channel, msg.sender);
        return true;
    }

    /**
     * @notice Allows users to unsubscribe from a List of Channels at once
     *
     * @param _channelList array of addresses of the channels that the user wishes to Unsubscribe
     **/
    function batchUnsubscribe(address[] calldata _channelList)
        external
        returns (bool)
    {
        for (uint256 i = 0; i < _channelList.length; i++) {
            _unsubscribe(_channelList[i], msg.sender);
        }
        return true;
    }

    /**
     * @notice Base Usubscribe Function that allows users to UNSUBSCRIBE from a Particular Channel
     * @dev Modifies the User Struct with crucial details about the Channel Unsubscription
     * @param _channel address of the channel that the user is subscribing to
     * @param _user address of the Subscriber
     **/
    function _unsubscribe(address _channel, address _user) private {
        if (isUserSubscribed(_channel, _user)) {
            User storage user = users[_user];

            uint256 _subscribedCount = user.subscribedCount;

            user.isSubscribed[_channel] = 0;

            user.subscribed[user.mapAddressSubscribed[_subscribedCount]] = user
                .subscribed[_channel];
            user.mapAddressSubscribed[user.subscribed[_channel]] = user
                .mapAddressSubscribed[_subscribedCount];

            // delete the last one and substract
            delete (user.subscribed[_channel]);
            delete (user.mapAddressSubscribed[_subscribedCount]);
            user.subscribedCount = _subscribedCount.sub(1);

            // Emit it
            emit Unsubscribe(_channel, _user);
        }
    }

    /**
     * @notice Unsubscribe Function through Meta TX
     * @dev Takes into Consideration the Signer of the transactioner
     *      Inludes EIP1271 implementation: Standard Signature Validation Method for Contracts
     **/
    function unsubscribeBySig(
        address channel,
        address subscriber,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(
            subscriber != address(0),
            "EPNSCommV1_5::unsubscribeBySig: Invalid signature"
        );
        // EIP-712
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, NAME_HASH, getChainId(), address(this))
        );
        bytes32 structHash = keccak256(
            abi.encode(UNSUBSCRIBE_TYPEHASH, channel, subscriber, nonce, expiry)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        if (Address.isContract(subscriber)) {
            // use EIP-1271
            bytes4 result = IERC1271(subscriber).isValidSignature(
                digest,
                abi.encodePacked(r, s, v)
            );
            require(result == 0x1626ba7e, "INVALID SIGNATURE FROM CONTRACT");
        } else {
            // validate with in contract
            address signatory = ecrecover(digest, v, r, s);
            require(signatory == subscriber, "INVALID SIGNATURE FROM EOA");
        }
        require(
            nonce == nonces[subscriber]++,
            "EPNSCommV1_5::unsubscribeBySig: Invalid nonce"
        );
        require(
            now <= expiry,
            "EPNSCommV1_5::unsubscribeBySig: Signature expired"
        );
        _unsubscribe(channel, subscriber);
    }

    /**
     * @notice Allows EPNSCore contract to call the Base UnSubscribe function whenever a User Destroys his/her TimeBound Channel.
     *         This ensures that the Channel Owner is unSubscribed from the imperative EPNS Channels as well as his/her own Channel.
     *         NOTE-If they don't unsubscribe before destroying their Channel, they won't be able to create their Channel again using the same Wallet Address.
     *
     * @dev    Only Callable by the EPNSCore.
     * @param _channel address of the channel being unsubscribed
     * @param _user address of the UnSubscriber of a Channel
     **/
    function unSubscribeViaCore(address _channel, address _user)
        external
        onlyEPNSCore
        returns (bool)
    {
        _unsubscribe(_channel, _user);
        return true;
    }

    /* **************

    => PUBLIC KEY BROADCASTING & USER ADDING FUNCTIONALITIES <=

    *************** */

    /**
     * @notice Activates/Adds a particular User's Address in the Protocol.
     *         Keeps track of the Total User Count
     * @dev   Executes its main actions only if the User is not activated yet.
     *        Does nothing if an address has already been added.
     *
     * @param _user address of the user
     * @return userAlreadyAdded returns whether or not a user is already added.
     **/
    function _addUser(address _user) private returns (bool userAlreadyAdded) {
        if (users[_user].userActivated) {
            userAlreadyAdded = true;
        } else {
            // Activates the user
            users[_user].userStartBlock = block.number;
            users[_user].userActivated = true;
            mapAddressUsers[usersCount] = _user;

            usersCount = usersCount.add(1);
        }
    }

    /* @dev Internal system to handle broadcasting of public key,
     *     A entry point for subscribe, or create channel but is optional
     */
    function _broadcastPublicKey(address _userAddr, bytes memory _publicKey)
        private
    {
        // Add the user, will do nothing if added already, but is needed before broadcast
        _addUser(_userAddr);

        // get address from public key
        address userAddr = getWalletFromPublicKey(_publicKey);

        if (_userAddr == userAddr) {
            // Only change it when verification suceeds, else assume the channel just wants to send group message
            users[userAddr].publicKeyRegistered = true;

            // Emit the event out
            emit PublicKeyRegistered(userAddr, _publicKey);
        } else {
            revert("Public Key Validation Failed");
        }
    }

    /// @dev Don't forget to add 0x into it
    function getWalletFromPublicKey(bytes memory _publicKey)
        public
        pure
        returns (address wallet)
    {
        if (_publicKey.length == 64) {
            wallet = address(uint160(uint256(keccak256(_publicKey))));
        } else {
            wallet = 0x0000000000000000000000000000000000000000;
        }
    }

    /// @dev Performs action by the user themself to broadcast their public key
    function broadcastUserPublicKey(bytes calldata _publicKey) external {
        // Will save gas
        if (users[msg.sender].publicKeyRegistered) {
            // Nothing to do, user already registered
            return;
        }

        // broadcast it
        _broadcastPublicKey(msg.sender, _publicKey);
    }

    /* **************

    => SEND NOTIFICATION FUNCTIONALITIES <=

    *************** */

    /**
     * @notice Allows a Channel Owner to ADD a Delegate for sending Notifications
     *         Delegate shall be able to send Notification on the Channel's Behalf
     * @dev    This function will be only be callable by the Channel Owner from the EPNSCore contract.
     * NOTE:   Verification of whether or not a Channel Address is actually the owner of the Channel, will be done via the PUSH NODES.
     *
     * @param _delegate address of the delegate who is allowed to Send Notifications
     **/
    function addDelegate(address _delegate) external {
        delegatedNotificationSenders[msg.sender][_delegate] = true;
        emit AddDelegate(msg.sender, _delegate);
    }

    /**
     * @notice Allows a Channel Owner to Remove a Delegate's Permission to Send Notification
     * @dev    This function will be only be callable by the Channel Owner from the EPNSCore contract.
     * NOTE:   Verification of whether or not a Channel Address is actually the owner of the Channel, will be done via the PUSH NODES.
     * @param _delegate address of the delegate who is allowed to Send Notifications
     **/
    function removeDelegate(address _delegate) external {
        delegatedNotificationSenders[msg.sender][_delegate] = false;
        emit RemoveDelegate(msg.sender, _delegate);
    }

    /***
      THREE main CALLERS for this function-
        1. Channel Owner sends Notif to all Subscribers / Subset of Subscribers / Individual Subscriber
        2. Delegatee of Channel sends Notif to Recipients
        3. User sends Notifs to Themselvs via a Channel
           NOTE: A user can only send notification to their own address
    <---------------------------------------------------------------------------------------------->
     * When a CHANNEL OWNER Calls the Function and sends a Notif:
     *    -> We ensure -> "Channel Owner Must be Valid" && "Channel Owner is the Caller"
     *    -> NOTE - Validation of wether or not an address is a CHANNEL, is done via PUSH NODES
     *
     * When a Delegatee wants to send Notif to Recipient:
     *   -> We ensure "Delegate is the Caller" && "Delegatee is Approved by Chnnel Owner"
     *
     * When User wants to Send a Notif to themselves:
     *  ->  We ensure "Caller of the Function is the Recipient of the Notification"
    **/

    function _checkNotifReq(address _channel, address _recipient)
        private
        view
        returns (bool)
    {
        if (
            (_channel == 0x0000000000000000000000000000000000000000 &&
                msg.sender == pushChannelAdmin) ||
            (_channel == msg.sender) ||
            (delegatedNotificationSenders[_channel][msg.sender]) ||
            (_recipient == msg.sender)
        ) {
            return true;
        }

        return false;
    }

    /**
     * @notice Allows a Channel Owners, Delegates as well as Users to send Notifications
     * @dev Emits out notification details once all the requirements are passed.
     * @param _channel address of the Channel
     * @param _recipient address of the reciever of the Notification
     * @param _identity Info about the Notification
     **/
    function sendNotification(
        address _channel,
        address _recipient,
        bytes memory _identity
    ) external returns (bool) {
        bool success = _checkNotifReq(_channel, _recipient);
        if (success) {
            // Emit the message out
            emit SendNotification(_channel, _recipient, _identity);
            return true;
        }

        return false;
    }

    /**
     * @notice Base Notification Function that Allows a Channel Owners, Delegates as well as Users to send Notifications
     *
     * @dev   Specifically designed to be called via the EIP 712 send notif function.
     *        Takes into consideration the Signatory address to perform all the imperative checks
     *
     * @param _channel address of the Channel
     * @param _recipient address of the reciever of the Notification
     * @param _signatory address of the SIGNER of the Send Notif Function call transaction
     * @param _identity Info about the Notification
     **/
    function _sendNotification(
        address _channel,
        address _recipient,
        address _signatory,
        bytes calldata _identity
    ) private returns (bool) {
        if (
            _channel == _signatory ||
            delegatedNotificationSenders[_channel][_signatory] ||
            _recipient == _signatory
        ) {
            // Emit the message out
            emit SendNotification(_channel, _recipient, _identity);
            return true;
        }

        return false;
    }

    /**
     * @notice Meta transaction function for Sending Notifications
     * @dev   Allows the Caller to Simply Sign the transaction to initiate the Send Notif Function
     *        Inludes EIP1271 implementation: Standard Signature Validation Method for Contracts
     * @return bool returns whether or not send notification credentials was successful.
     **/
    function sendNotifBySig(
        address _channel,
        address _recipient,
        address _signer,
        bytes calldata _identity,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool) {
        if (_signer == address(0) || nonce != nonces[_signer] || now > expiry) {
            return false;
        }

        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, NAME_HASH, getChainId(), address(this))
        );
        bytes32 structHash = keccak256(
            abi.encode(
                SEND_NOTIFICATION_TYPEHASH,
                _channel,
                _recipient,
                keccak256(_identity),
                nonce,
                expiry
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        if (Address.isContract(_signer)) {
            // use EIP-1271 signature check
            bytes4 result = IERC1271(_signer).isValidSignature(
                digest,
                abi.encodePacked(r, s, v)
            );
            if (result != 0x1626ba7e) return false;
        } else {
            address signatory = ecrecover(digest, v, r, s);
            if (signatory != _signer) return false;
        }

        // check sender & emit event
        bool success = _sendNotification(
            _channel,
            _recipient,
            _signer,
            _identity
        );

        // update nonce if signature valid
        nonces[_signer] = nonce.add(1);

        return success;
    }

    /* **************

    => User Notification Settings Function <=
    *************** */

    /**
     * @notice  Allows Users to Create and Subscribe to a Specific Notication Setting for a Channel.
     * @dev     Updates the userToChannelNotifs mapping to keep track of a User's Notification Settings for a Specific Channel
     *
     *          Deliminated Notification Settings string contains -> Decimal Representation Notif Settings + Notification Settings
     *          For instance, for a Notif Setting that looks like -> 3+1-0+2-0+3-1+4-98
     *          3 -> Decimal Representation of the Notification Options selected by the User
     *
     *          For Boolean Type Notif Options
     *          1-0 -> 1 stands for Option 1 - 0 Means the user didn't choose that Notif Option.
     *          3-1 stands for Option 3      - 1 Means the User Selected the 3rd boolean Option
     *
     *          For SLIDER TYPE Notif Options
     *          2-0 -> 2 stands for Option 2 - 0 is user's Choice
     *          4-98-> 4 stands for Option 4 - 98is user's Choice
     *
     * @param   _channel - Address of the Channel for which the user is creating the Notif settings
     * @param   _notifID- Decimal Representation of the Options selected by the user
     * @param   _notifSettings - Deliminated string that depicts the User's Notifcation Settings
     *
     **/

    function changeUserChannelSettings(
        address _channel,
        uint256 _notifID,
        string calldata _notifSettings
    ) external {
        require(
            isUserSubscribed(_channel, msg.sender),
            "EPNSCommV1_5::changeUserChannelSettings: User not Subscribed to Channel"
        );
        string memory notifSetting = string(
            abi.encodePacked(Strings.toString(_notifID), "+", _notifSettings)
        );
        userToChannelNotifs[msg.sender][_channel] = notifSetting;
        emit UserNotifcationSettingsAdded(
            _channel,
            msg.sender,
            _notifID,
            notifSetting
        );
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4 magicValue);
}