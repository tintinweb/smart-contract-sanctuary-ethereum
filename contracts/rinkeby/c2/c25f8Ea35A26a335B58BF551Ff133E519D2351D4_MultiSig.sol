// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import '../../interfaces/IAccessibilitySettings.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '../../interfaces/IERC20_PDN.sol';

contract MultiSig is Initializable{

    using SafeMathUpgradeable for uint256;
 
    uint N_BLOCK_DAY = uint(5760);
    uint N_BLOCK_WEEK = uint(7).mul(N_BLOCK_DAY);

    struct multiSigPollStruct {
        uint pollType;
        uint pollBlockStart; 
        address voteReceiverAddress;
        uint amountApprovedVoteReceiver;             // Number of Approved vote received for this poll
        mapping(address => uint) vote;           // Vote received from the multisig addess
    }

    enum pollTypeMetaData{
        NULL,
        CHANGE_CREATOR,
        DELETE_ADDRESS_ON_MULTISIG_LIST,
        ADD_ADDRESS_ON_MULTISIG_LIST,
        UNFREEZE,
        CHANGE_PDN_SMARTCONTRACT_OWNER
    }

    enum voteMetaData {
        NULL,
        APPROVED,
        DECLINED
    }

    mapping(address => bool) public multiSigDAO;
    uint public multiSigLength;
    mapping(uint => multiSigPollStruct) public multiSigPoll;

    uint public indexPoll;

    address public accessibilitySettingsAddress;
    address public ERC20Address;

    event NewMultisigPollEvent(address indexed creator, uint  pollIndex, uint pollType, address voteReceiver);
    event VoteMultisigPollEvent(address indexed voter, uint pollIndex, uint vote);
    event ChangeStatementMultisigPollEvent(uint pollIndex, address voteReceiver);


    function initialize(address _accessibilitySettingsAddress, address[] memory _multiSigAddresses) public {
        require(_accessibilitySettingsAddress != address(0), "CANT_SET_NULL_ADDRESS");
        require(_multiSigAddresses.length >= 5, "MULTISIG_NEEDS_MIN_5_ADDRESSES");
        accessibilitySettingsAddress = _accessibilitySettingsAddress;
        for(uint index = 0; index < _multiSigAddresses.length; index++){
            require(_multiSigAddresses[index] != address(0), "CANT_SET_NULL_ADDRESS");
            multiSigDAO[_multiSigAddresses[index]] = true;
        }
        multiSigLength = _multiSigAddresses.length;
        IAccessibilitySettings(accessibilitySettingsAddress).multiSigInitialize(address(this));
    }

    function createMultiSigPoll(uint _pollTypeID, address _voteReceiverAddress) public returns(uint){
        require(multiSigDAO[msg.sender], "NOT_ABLE_TO_CREATE_A_MULTISIG_POLL");
        require(_pollTypeID > uint(pollTypeMetaData.NULL) && _pollTypeID <= uint(pollTypeMetaData.CHANGE_PDN_SMARTCONTRACT_OWNER), "POLL_ID_DISMATCH");
        uint refPollIndex = indexPoll.add(1);
        indexPoll = refPollIndex;
        multiSigPoll[refPollIndex].pollType = _pollTypeID;
        multiSigPoll[refPollIndex].pollBlockStart = block.number;
        multiSigPoll[refPollIndex].voteReceiverAddress = _voteReceiverAddress;
        emit NewMultisigPollEvent(msg.sender, refPollIndex, _pollTypeID, _voteReceiverAddress);
        return refPollIndex;
    }

    function voteMultiSigPoll(uint _pollIndex, uint _vote) public returns(bool){
        require(_vote == uint(voteMetaData.APPROVED) || _vote == uint(voteMetaData.DECLINED), "VOTE_NOT_VALID");
        require(multiSigDAO[msg.sender], "NOT_ABLE_TO_VOTE_FOR_A_MULTISIG_POLL");
        uint amountApprovedVoteReceiver = multiSigPoll[_pollIndex].amountApprovedVoteReceiver;
        address voteReceiverAddress = multiSigPoll[_pollIndex].voteReceiverAddress;
        require((block.number).sub(multiSigPoll[_pollIndex].pollBlockStart) <= N_BLOCK_WEEK, "MULTISIG_POLL_EXPIRED");
        uint vote = multiSigPoll[_pollIndex].vote[msg.sender];
        require(vote == uint(voteMetaData.NULL), "ADDRESS_HAS_ALREADY_VOTED");
        multiSigPoll[_pollIndex].vote[msg.sender] = _vote;
        if(_vote == uint(voteMetaData.APPROVED)){
            multiSigPoll[_pollIndex].amountApprovedVoteReceiver = amountApprovedVoteReceiver.add(1);
            if((amountApprovedVoteReceiver.add(1)).mul(uint(2)) > multiSigLength){
                runMultiSigFunction(multiSigPoll[_pollIndex].pollType, voteReceiverAddress);
                emit ChangeStatementMultisigPollEvent(multiSigPoll[_pollIndex].pollType, voteReceiverAddress);
                delete multiSigPoll[_pollIndex];
            }
        }
        emit VoteMultisigPollEvent(msg.sender, _pollIndex, _vote);
        return true;
    }

    function runMultiSigFunction(uint _functionID, address _voteFor) private returns(bool){
        if(_functionID == uint(pollTypeMetaData.CHANGE_CREATOR)){
            IAccessibilitySettings(accessibilitySettingsAddress).changeDAOCreator(_voteFor);
        }
        if(_functionID == uint(pollTypeMetaData.DELETE_ADDRESS_ON_MULTISIG_LIST)){
            uint newMultiSigLength = multiSigLength.sub(1);
            require(newMultiSigLength >= uint(5), "NOT_ENOUGH_MULTISIG_ADDRESSES");
            require(multiSigDAO[_voteFor], "CANT_DELETE_NOT_EXISTING_ADDRESS");
            multiSigLength = newMultiSigLength;
            multiSigDAO[_voteFor] = false;
        }        
        if(_functionID == uint(pollTypeMetaData.ADD_ADDRESS_ON_MULTISIG_LIST)){
            require(!multiSigDAO[_voteFor], "CANT_ADD_EXISTING_ADDRESS");
            multiSigLength = multiSigLength.add(1);
            multiSigDAO[_voteFor] = true;
        }
        if(_functionID == uint(pollTypeMetaData.UNFREEZE)){
            IAccessibilitySettings(accessibilitySettingsAddress).restoreIsFrozen();
        }
        if(_functionID == uint(pollTypeMetaData.CHANGE_PDN_SMARTCONTRACT_OWNER)){
            address tmpERC20Address = ERC20Address;
            require(tmpERC20Address != address(0), "CANT_CHANGE_PDN_OWNER_OF_NULL_ADDRESS"); //TEST
            IERC20_PDN(tmpERC20Address).changeOwnerWithMultisigDAO(_voteFor);
        }
        return true;
    }

    function getMultiSigLength() public view returns(uint){
        return multiSigLength;
    }

    function getIsMultiSigAddress(address _address) public view returns(bool){
        return multiSigDAO[_address];
    }

    function getVoterVote(address _voter, uint _pollID) public view returns(uint){
        return multiSigPoll[_pollID].vote[_voter];
    }

    function getPollMetaData(uint _pollID) public view returns(uint, uint, address, uint){
        return (multiSigPoll[_pollID].pollType, multiSigPoll[_pollID].pollBlockStart, multiSigPoll[_pollID].voteReceiverAddress, multiSigPoll[_pollID].amountApprovedVoteReceiver);
    }

    function getExpirationBlockTime(uint _pollID) public view returns(uint){
        return N_BLOCK_WEEK.sub(block.number.sub(multiSigPoll[_pollID].pollBlockStart));
    }

    function getListOfActivePoll() public view returns(uint[] memory){
        uint refPollIndex = indexPoll;
        uint countActive = uint(0);
        bool[] memory activePolls = new bool[](uint(refPollIndex));
        for(uint index = uint(0); index < refPollIndex; index++){
            if(multiSigPoll[index.add(1)].pollType != uint(pollTypeMetaData.NULL)){
                if((block.number).sub(multiSigPoll[index.add(1)].pollBlockStart) <= N_BLOCK_WEEK){
                    activePolls[index] = true;
                    countActive = countActive.add(1);
                } 
            }
        }
        uint[] memory resultActivePoll = new uint[](uint(countActive));
        uint tmpIndex = uint(0);
        for(uint index = uint(0); index < refPollIndex; index++){
            if(activePolls[index]){
                resultActivePoll[tmpIndex] = index;
                tmpIndex = tmpIndex.add(1);
            }
        }
        return resultActivePoll;
    }

    function setERC1155Address(address _ERC20Address) public returns(bool){
        require(getIsMultiSigAddress(msg.sender), "REQUIRE_MULTISIG_ADDRESS");
        ERC20Address = _ERC20Address;
        return true;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IAccessibilitySettings {
    function getAccessibility(bytes4 _functionSignature, address _userAddress) external view returns(bool);
    function getUserGroup(address _userAddress) external view returns(uint);
    function enableSignature(bytes4[] memory _functionSignatureList, uint[] memory _userRoles) external returns(bool);
    function disableSignature(bytes4[] memory _functionSignatureList, uint[] memory _userRoles) external returns(bool);
    function setUserListRole(address[] memory _userAddress, uint[] memory _userGroup) external returns(bool);
    function getDAOCreator() external view returns(address);
    function getIsFrozen() external view returns(bool);
    function changeDAOCreator(address _newDAOCreator) external returns(bool);
    function restoreIsFrozen() external returns(bool);
    function multiSigInitialize(address _multiSigRefAddress) external returns(bool);
    function getMultiSigRefAddress() external view returns(address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IERC20_PDN {
    function mint(address _to, uint _totalSupply, uint _decimals) external returns(bool);
    function burn(uint _amount) external returns(bool);
    function changeOwnerWithMultisigDAO(address _newOwner) external returns(bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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