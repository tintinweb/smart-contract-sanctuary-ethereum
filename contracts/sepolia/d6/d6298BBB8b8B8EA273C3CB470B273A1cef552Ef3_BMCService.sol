// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import "./interfaces/IBSH.sol";
import "./interfaces/ICCService.sol";
import "./interfaces/IOwnerManager.sol";
import "./interfaces/IBMCPeriphery.sol";
import "./interfaces/ICCManagement.sol";
import "./interfaces/ICCPeriphery.sol";
import "./libraries/Types.sol";
import "./libraries/Errors.sol";
import "./libraries/BTPAddress.sol";
import "./libraries/ParseAddress.sol";
import "./libraries/Strings.sol";
import "./libraries/RLPDecodeStruct.sol";
import "./libraries/RLPEncodeStruct.sol";
import "./libraries/Utils.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract BMCService is IBSH, ICCService, Initializable {
    using BTPAddress for string;
    using ParseAddress for string;
    using Strings for string;
    using RLPDecodeStruct for bytes;
    using RLPEncodeStruct for Types.BTPMessage;
    using RLPEncodeStruct for Types.BMCMessage;
    using RLPEncodeStruct for Types.ResponseMessage;
    using RLPEncodeStruct for Types.ClaimMessage;
    using Utils for uint256[];

    address private bmcPeriphery;
    address private bmcManagement;
    string private network;

    mapping(string => mapping(string => mapping(int256 => Types.Response))) private responseMap;
    mapping(int256 => Types.Request) private requestMap;
    mapping(address => mapping(string => uint256)) private rewardMap;

    function initialize(
        address _bmcManagementAddr
    ) public initializer {
        bmcManagement = _bmcManagementAddr;
    }

    /**
       @notice Get address of BMCManagement.
       @return address of BMCManagement
     */
    function getBMCManagement(
    ) external view returns (
        address
    ) {
        return bmcManagement;
    }

    function requireBMCManagementAccess(
    ) internal view {
        require(msg.sender == bmcManagement, Errors.BMC_REVERT_UNAUTHORIZED);
    }

    /**
       @notice Update BMCPeriphery.
       @dev Caller must be an Owner of BTP network
       @param _addr    address of BMCPeriphery.
     */
    function setBMCPeriphery(
        address _addr
    ) external {
        require(IOwnerManager(bmcManagement).isOwner(msg.sender), Errors.BMC_REVERT_UNAUTHORIZED);
        require(_addr != address(0), Errors.BMC_REVERT_INVALID_ARGUMENT);
        bmcPeriphery = _addr;
        network = IBMCPeriphery(bmcPeriphery).getNetworkAddress();
    }

    /**
       @notice Get address of BMCPeriphery.
       @return address of BMCPeriphery
     */
    function getBMCPeriphery(
    ) external view returns (
        address
    ) {
        return bmcPeriphery;
    }

    function requireBMCPeripheryAccess(
    ) internal view {
        require(msg.sender == bmcPeriphery, Errors.BMC_REVERT_UNAUTHORIZED);
    }

    function _addReward(
        string memory net,
        address addr,
        uint256 amount
    ) internal {
        if (amount > 0) {
            rewardMap[addr][net] = rewardMap[addr][net] + amount;
        }
    }

    function _collectRemainFee(
        Types.FeeInfo memory feeInfo
    ) internal returns (
        Types.FeeInfo memory
    ){
        _addReward(feeInfo.network, bmcPeriphery, feeInfo.values.sumFromUints());
        feeInfo.values = new uint256[](0);
        return feeInfo;
    }

    function getReward(
        string calldata _network,
        address _addr
    ) external view override returns (uint256) {
        return rewardMap[_addr][_network];
    }

    function clearReward(
        string calldata _network,
        address _addr
    ) external override returns (uint256) {
        requireBMCPeripheryAccess();
        uint256 reward = rewardMap[_addr][_network];
        require(reward > 0, Errors.BMC_REVERT_NOT_EXISTS_REWARD);
        rewardMap[_addr][_network] = 0;
        return reward;
    }

    function _accumulateFee(
        address addr,
        Types.FeeInfo memory feeInfo
    ) internal returns (
        Types.FeeInfo memory
    ){
        if (feeInfo.values.length > 0) {
            _addReward(feeInfo.network, addr, feeInfo.values[0]);
            //pop first
            uint256[] memory nextValues = new uint256[](feeInfo.values.length - 1);
            for (uint256 i = 0; i < nextValues.length; i++) {
                nextValues[i] = feeInfo.values[i + 1];
            }
            feeInfo.values = nextValues;
        }
        return feeInfo;
    }

    function handleFee(
        address _addr,
        bytes memory _msg
    ) external override returns (
        Types.BTPMessage memory
    ) {
        requireBMCPeripheryAccess();
        Types.BTPMessage memory btpMsg = _msg.decodeBTPMessage();
        btpMsg.feeInfo = _accumulateFee(_addr, btpMsg.feeInfo);

        if (btpMsg.dst.compareTo(network)) {
            if (btpMsg.sn > 0) {
                _collectRemainFee(responseMap[btpMsg.src][btpMsg.svc][btpMsg.sn].feeInfo);
                responseMap[btpMsg.src][btpMsg.svc][btpMsg.sn] = Types.Response(
                    btpMsg.nsn, btpMsg.feeInfo);
            } else {
                btpMsg.feeInfo = _collectRemainFee(btpMsg.feeInfo);
            }
        }
        return btpMsg;
    }

    function handleErrorFee(
        string memory _src,
        int256 _sn,
        Types.FeeInfo memory _feeInfo
    ) external override returns (
        Types.FeeInfo memory
    ) {
        requireBMCPeripheryAccess();
        if (_sn > 0) {
            uint256 hop = ICCManagement(bmcManagement).getHop(_src);
            if (hop > 0 && _feeInfo.values.length > hop) {
                uint256 remainLen = _feeInfo.values.length - hop;
                uint256[] memory nextValues = new uint256[](_feeInfo.values.length);
                for (uint256 i = 0; i < hop; i++) {
                    nextValues[i] = _feeInfo.values[remainLen+i];
                }
                for (uint256 i = 0; i < remainLen; i++) {
                    nextValues[hop+i] = _feeInfo.values[i];
                }
                _feeInfo.values = nextValues;
            }
            return _feeInfo;
        } else {
            return _collectRemainFee(_feeInfo);
        }
    }

    function handleDropFee(
        string memory _network,
        uint256[] memory _values
    ) external override returns (
        Types.FeeInfo memory
    ) {
        requireBMCManagementAccess();
        return _accumulateFee(bmcPeriphery, Types.FeeInfo(_network, _values));
    }

    function addReward(
        string memory _network,
        address _addr,
        uint256 _amount
    ) external override {
        requireBMCPeripheryAccess();
        _addReward(_network, _addr, _amount);
    }

    function addRequest(
        int256 _nsn,
        string memory _dst,
        address _sender,
        uint256 _amount
    ) external override {
        requireBMCPeripheryAccess();
        requestMap[_nsn] = Types.Request(_nsn, _dst, _sender, _amount);
    }

    function removeResponse(
        string memory _to,
        string memory _svc,
        int256 _sn
    ) external override returns (
        Types.Response memory
    ) {
        requireBMCPeripheryAccess();
        Types.Response memory response = responseMap[_to][_svc][_sn];
        require(response.nsn > 0, Errors.BMC_REVERT_NOT_EXISTS_RESPONSE);
        delete responseMap[_to][_svc][_sn];
        return response;
    }

    function _handleResponse(
        int256 nsn,
        uint256 result
    ) internal {
        Types.Request memory request = requestMap[nsn];
        require(request.nsn > 0, Errors.BMC_REVERT_NOT_EXISTS_REQUEST);
        delete requestMap[request.nsn];
        if (result != Types.ECODE_NONE) {
            _addReward(request.dst, request.caller, request.amount);
        }
        ICCPeriphery(bmcPeriphery).emitClaimRewardResult(
            request.caller, request.dst, request.nsn, result);
    }

    function handleBTPMessage(
        string calldata _from,
        string calldata _svc,
        uint256 _sn,
        bytes calldata _msg
    ) external override {
        requireBMCPeripheryAccess();

        Types.BMCMessage memory bmcMsg = _msg.decodeBMCMessage();
        bytes32 msgType = keccak256(abi.encodePacked(bmcMsg.msgType));
        if (msgType == keccak256(abi.encodePacked(Types.BMC_INTERNAL_CLAIM))) {
            Types.ClaimMessage memory claimMsg = bmcMsg.payload.decodeClaimMessage();
            _addReward(
                    network,
                    claimMsg.receiver.parseAddress(Errors.BMC_REVERT_INVALID_ARGUMENT),
                    claimMsg.amount);
            IBMCPeriphery(bmcPeriphery).sendMessage(
                _from,
                Types.BMC_SERVICE,
                int256(_sn) * -1,
                Types.BMCMessage(Types.BMC_INTERNAL_RESPONSE,
                    Types.ResponseMessage(0, "").encodeResponseMessage()
                ).encodeBMCMessage());
        } else if (msgType == keccak256(abi.encodePacked(Types.BMC_INTERNAL_RESPONSE))) {
            _handleResponse(int256(_sn), bmcMsg.payload.decodeResponseMessage().code);
        } else if (msgType == keccak256(abi.encodePacked(Types.BMC_INTERNAL_LINK))) {
            ICCManagement(bmcManagement).addReachable(_from,
                bmcMsg.payload.decodePropagateMessage());
        } else if (msgType == keccak256(abi.encodePacked(Types.BMC_INTERNAL_UNLINK))) {
            ICCManagement(bmcManagement).removeReachable(_from,
                bmcMsg.payload.decodePropagateMessage());
        } else if (msgType == keccak256(abi.encodePacked(Types.BMC_INTERNAL_INIT))) {
            string[] memory l = bmcMsg.payload.decodeInitMessage();
            for(uint256 i = 0; i < l.length; i++) {
                ICCManagement(bmcManagement).addReachable(_from, l[i]);
            }
        } else {
            revert(Errors.BMC_REVERT_NOT_EXISTS_INTERNAL);
        }
    }

    function handleBTPError(
        string calldata _src,
        string calldata _svc,
        uint256 _sn,
        uint256 _code,
        string calldata _msg
    ) external override {
        requireBMCPeripheryAccess();
        _handleResponse(int256(_sn), _code);
    }

    function decodeResponseMessage(
        bytes calldata _rlp
    ) external pure override returns (
        Types.ResponseMessage memory
    ) {
        return _rlp.decodeResponseMessage();
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import "../libraries/Types.sol";

interface IBMCPeriphery {
    //FIXME remove getBtpAddress
    /**
        @notice Get BMC BTP address
     */
    function getBtpAddress(
    ) external view returns (
        string memory
    );

    /**
        @notice Gets Network Address of BMC
     */
    function getNetworkAddress(
    ) external view returns (
        string memory
    );

    /**
        @notice Verify and decode RelayMessage with BMV, and dispatch BTP Messages to registered BSHs
        @dev Caller must be a registered relayer.
        @param _prev    BTP Address of the BMC generates the message
        @param _msg     serialized bytes of Relay Message refer RelayMessage structure
     */
    function handleRelayMessage(
        string calldata _prev,
        bytes calldata _msg
    ) external;

    /**
        @notice Send the message to a specific network.
        @dev Caller must be an registered BSH.
        @param _to      Network Address of destination network
        @param _svc     Name of the service
        @param _sn      Serial number of the message, it should be positive
        @param _msg     Serialized bytes of Service Message
        @return nsn     Network serial number
     */
    function sendMessage(
        string calldata _to,
        string calldata _svc,
        int256 _sn,
        bytes calldata _msg
    ) external payable returns (
        int256 nsn
    );

    /**
        @notice (EventLog) Sends the message to the next BMC.
        @dev The relay monitors this event.
        @param _next String ( BTP Address of the BMC to handle the message )
        @param _seq Integer ( sequence number of the message from current BMC to the next )
        @param _msg Bytes ( serialized bytes of BTP Message )
    */
    event Message(string indexed _next, uint256 indexed _seq, bytes _msg);

    /*
        @notice Get status of BMC.
        @param _link        BTP Address of the connected BMC
        @return _status  The link status
     */
    function getStatus(
        string calldata _link
    ) external view returns (
        Types.LinkStatus memory _status
    );

    /**
        @notice (EventLog) Drop the message of the connected BMC
        @param _prev String ( BTP Address of the previous BMC )
        @param _seq  Integer ( sequence number of the message from connected BMC )
        @param _msg  Bytes ( serialized bytes of BTP Message )
        @param _ecode Integer ( error code )
        @param _emsg  String ( error message )
    */
    event MessageDropped(string indexed _prev, uint256 indexed _seq, bytes _msg, uint256 _ecode, string _emsg);

    /**
        @notice (EventLog) Logs the event that handle the message
        @dev The tracker monitors this event.
        @param _src String ( Network Address of source BMC )
        @param _nsn Integer ( Network serial number )
        @param _next String ( BTP Address of the BMC to handle the message )
        @param _event String ( Event )
     */
    event BTPEvent(string indexed _src, int256 indexed _nsn, string _next, string _event);

    /**
       @notice It returns the amount of claimable reward to the target
       @param _network String ( Network address to claim )
       @param _addr    Address ( Address of the relay )
       @return _reward Integer (The claimable reward to the target )
    */
    function getReward(
        string calldata _network,
        address _addr
    ) external view returns (
        uint256 _reward
    );

    /**
       @notice Sends the claim message to a given network if a claimable reward exists.
       @dev It expects a response, so it would use a positive serial number for the message.
       If _network is the current network then it transfers a reward and a sender pays nothing.
       If the <sender> is FeeHandler, then it transfers the remaining reward to the receiver.
       @param _network  String ( Network address to claim )
       @param _receiver String ( Address of the receiver of target chain )
    */
    function claimReward(
        string calldata _network,
        string calldata _receiver
    ) external payable;

    /**
       @notice (EventLog) Logs the claim.
       @dev If it claims the reward in it's own network,
            _network is current network and _nsn is zero.
       @param _sender Address ( Address of the sender )
       @param _network String ( Network address to claim )
       @param _receiver String ( Address of the receiver of target chain )
       @param _amount Integer ( Amount of reward to claim )
       @param _nsn  Integer ( Network serial number of the claim message )
    */
    event ClaimReward(address indexed _sender, string indexed _network, string _receiver, uint256 _amount, int256 _nsn);

    /**
       @notice (EventLog) Logs the result of claim at receiving the response or error.
       @dev _result : 0 for success, others for failure
       @param _sender Address ( Address of the sender )
       @param _network String ( Network address to claim )
       @param _nsn  Integer ( Network serial number of the claim message )
       @param _result Integer ( Result of processing )
    */
    event ClaimRewardResult(address indexed _sender, string indexed _network, int256 _nsn, uint256 _result);

    /**
       @notice Gets the fee to the target network
       @dev _response should be true if it uses positive value for _sn of {@link #sendMessage}.
            If _to is not reachable, then it reverts.
            If _to does not exist in the fee table, then it returns zero.
       @param  _to       String ( BTP Network Address of the destination BMC )
       @param  _response Boolean ( Whether the responding fee is included )
       @return _fee      Integer (The fee of sending a message to a given destination network )
     */
    function getFee(
        string calldata _to,
        bool _response
    ) external view returns (
        uint256 _fee
    );

    function getNetworkSn(
    ) external view returns (
        int256
    );
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;
pragma abicoder v2;

interface IBMV {

    struct VerifierStatus {
        uint256 height; // Last verified block height
        bytes extra;
    }

    /**
        @notice Gets status of BMV.
        @return Types.VerifierStatus
                height Integer ( Last verified block height )
                extra  Bytes ( extra rlp encoded bytes )
     */
    function getStatus(
    ) external view returns (
        VerifierStatus memory
    );

    /**
        @notice Decodes Relay Messages and process BTP Messages.
                If there is an error, then it sends a BTP Message containing the Error Message.
                BTP Messages with old sequence numbers are ignored. A BTP Message contains future sequence number will fail.
        @param _bmc BTP Address of the BMC handling the message
        @param _prev BTP Address of the previous BMC
        @param _seq next sequence number to get a message
        @param _msg serialized bytes of Relay Message
        @return _serializedMessages List of serialized bytes of a BTP Message
     */
    function handleRelayMessage(
        string memory _bmc,
        string memory _prev,
        uint256 _seq,
        bytes calldata _msg
    ) external returns (
        bytes[] memory _serializedMessages
    );
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface IBSH {
    /**
       @notice Handle BTP Message from other blockchain.
       @dev Accept the message only from the BMC.
       Every BSH must implement this function
       @param _from    Network Address of source network
       @param _svc     Name of the service
       @param _sn      Serial number of the message
       @param _msg     Serialized bytes of ServiceMessage
   */

    function handleBTPMessage(
        string calldata _from,
        string calldata _svc,
        uint256 _sn,
        bytes calldata _msg
    ) external;

    /**
       @notice Handle the error on delivering the message.
       @dev Accept the error only from the BMC.
       Every BSH must implement this function
       @param _src     BTP Address of BMC generates the error
       @param _svc     Name of the service
       @param _sn      Serial number of the original message
       @param _code    Code of the error
       @param _msg     Message of the error
   */
    function handleBTPError(
        string calldata _src,
        string calldata _svc,
        uint256 _sn,
        uint256 _code,
        string calldata _msg
    ) external;

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import "../libraries/Types.sol";

interface ICCManagement {
    /**
        @notice Get address of BSH.
        @param _svc (String) Name of the service
        @return address of BSH
     */
    function getService(
        string memory _svc
    ) external view returns (
        address
    );

    /**
        @notice Get address of BMV.
        @param _net (String) Network Address of the blockchain
        @return address of BMV
     */
    function getVerifier(
        string memory _net
    ) external view returns (
        address
    );

    /**
       @notice Gets the fee to the target network
       @dev _response should be true if it uses positive value for _sn of {@link #sendMessage}.
            If _to is not reachable, then it reverts.
            If _to does not exist in the fee table, then it returns zero.
       @param  _to       String ( BTP Network Address of the destination BMC )
       @param  _response Boolean ( Whether the responding fee is included )
       @return _fee      Integer (The fee of sending a message to a given destination network )
       @return _values   []Integer (The fee of sending a message to a given destination network )
     */
    function getFee(
        string calldata _to,
        bool _response
    ) external view returns (
        uint256 _fee,
        uint256[] memory _values
    );

    /**
       @notice Checking whether one specific address is registered relay.
       @dev Caller can be ANY
       @param _link BTP Address of the connected BMC
       @param _addr Address needs to verify.
       @return whether one specific address is registered relay
     */
    function isLinkRelay(
        string calldata _link,
        address _addr
    ) external view returns (
        bool
    );

    /**
        @notice resolve next BMC.
        @param _dst   network address of destination
        @return _next BTP address of next BMC
     */
    function resolveNext(
        string memory _dst
    ) external view returns (
        string memory _next
    );

    function addReachable(
        string memory _from,
        string memory _reachable
    ) external;

    function removeReachable(
        string memory _from,
        string memory _reachable
    ) external;

    function getHop(
        string memory _dst
    ) external view returns (
        uint256
    );
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import "../libraries/Types.sol";

interface ICCPeriphery {

    function sendInternal(
        string memory _next,
        bytes memory _msg
    ) external;

    function dropMessage(
        string memory _prev,
        uint256 _seq,
        Types.BTPMessage memory _msg
    ) external;

    function clearSeq(
        string memory _link
    ) external;

    function emitClaimRewardResult(
        address _sender,
        string memory _network,
        int256 _nsn,
        uint256 _result
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import "../libraries/Types.sol";

interface ICCService {

    /**
       @notice It returns the amount of claimable reward to the target
       @param _network String ( Network address to claim )
       @param _addr    Address ( Address of the relay )
       @return _reward Integer (The claimable reward to the target )
    */
    function getReward(
        string calldata _network,
        address _addr
    ) external view returns (uint256 _reward);

    function handleFee(
        address _addr,
        bytes memory _msg
    ) external returns (
        Types.BTPMessage memory
    );

    function handleErrorFee(
        string memory _src,
        int256 _sn,
        Types.FeeInfo memory _feeInfo
    ) external returns (
        Types.FeeInfo memory
    );

    function handleDropFee(
        string memory _network,
        uint256[] memory _values
    ) external returns (
        Types.FeeInfo memory
    );

    function addReward(
        string memory _network,
        address _addr,
        uint256 _amount
    ) external;

    function clearReward(
        string calldata _network,
        address _addr
    ) external returns (
        uint256
    );

    function addRequest(
        int256 _nsn,
        string memory _dst,
        address _sender,
        uint256 _amount
    ) external;

    function removeResponse(
        string memory _to,
        string memory _svc,
        int256 _sn
    ) external returns (
        Types.Response memory
    );

    function decodeResponseMessage(
        bytes calldata _rlp
    ) external pure returns (
        Types.ResponseMessage memory
    );

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;
pragma abicoder v2;

interface IOwnerManager {
    /**
       @notice Adding another Onwer.
       @dev Caller must be an Onwer of BTP network
       @param _owner    Address of a new Onwer.
     */
    function addOwner(address _owner) external;

    /**
       @notice Removing an existing Owner.
       @dev Caller must be an Owner of BTP network
       @dev If only one Owner left, unable to remove the last Owner
       @param _owner    Address of an Owner to be removed.
     */
    function removeOwner(address _owner) external;

    /**
       @notice Checking whether one specific address has Owner role.
       @dev Caller can be ANY
       @param _owner    Address needs to verify.
     */
    function isOwner(address _owner) external view returns (bool);

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

/**
   BTPAddress 'btp://NETWORK_ADDRESS/ACCOUNT_ADDRESS'
*/
library BTPAddress {
    bytes internal constant PREFIX = bytes("btp://");
    string internal constant REVERT = "invalidBTPAddress";
    bytes internal constant DELIMITER = bytes("/");

    /**
       @notice Parse BTP address
       @param _str (String) BTP address
       @return (String) network address
       @return (String) account address
    */
    function parseBTPAddress(
        string memory _str
    ) internal pure returns (
        string memory,
        string memory
    ) {
        uint256 offset = _validate(_str);
        return (_slice(_str, 6, offset),
        _slice(_str, offset+1, bytes(_str).length));
    }

    /**
       @notice Gets network address of BTP address
       @param _str (String) BTP address
       @return (String) network address
    */
    function networkAddress(
        string memory _str
    ) internal pure returns (
        string memory
    ) {
        return _slice(_str, 6, _validate(_str));
    }

    function _validate(
        string memory _str
    ) private pure returns (
        uint256 offset
    ){
        bytes memory _bytes = bytes(_str);

        uint256 i = 0;
        for (; i < 6; i++) {
            if (_bytes[i] != PREFIX[i]) {
                revert(REVERT);
            }
        }
        for (; i < _bytes.length; i++) {
            if (_bytes[i] == DELIMITER[0]) {
                require(i > 6 && i < (_bytes.length -1), REVERT);
                return i;
            }
        }
        revert(REVERT);
    }

    function _slice(
        string memory _str,
        uint256 _from,
        uint256 _to
    ) private pure returns (
        string memory
    ) {
        //If _str is calldata, could use slice
        //        return string(bytes(_str)[_from:_to]);
        bytes memory _bytes = bytes(_str);
        bytes memory _ret = new bytes(_to - _from);
        uint256 j = _from;
        for (uint256 i = 0; i < _ret.length; i++) {
            _ret[i] = _bytes[j++];
        }
        return string(_ret);
    }

    /**
       @notice Create BTP address by network address and account address
       @param _net (String) network address
       @param _addr (String) account address
       @return (String) BTP address
    */
    function btpAddress(
        string memory _net,
        string memory _addr
    ) internal pure returns (
        string memory
    ) {
        return string(abi.encodePacked(PREFIX, _net, DELIMITER, _addr));
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import "../interfaces/IBMV.sol";

library Errors {
    string internal constant BMC_REVERT_UNAUTHORIZED = "11:Unauthorized";
    string internal constant BMC_REVERT_INVALID_SN = "12:InvalidSn";
    string internal constant BMC_REVERT_ALREADY_EXISTS_BMV = "13:AlreadyExistsBMV";
    string internal constant BMC_REVERT_NOT_EXISTS_BMV = "14:NotExistsBMV";
    string internal constant BMC_REVERT_ALREADY_EXISTS_BSH = "15:AlreadyExistsBSH";
    string internal constant BMC_REVERT_NOT_EXISTS_BSH = "16:NotExistsBSH";
    string internal constant BMC_REVERT_ALREADY_EXISTS_LINK = "17:AlreadyExistsLink";
    string internal constant BMC_REVERT_NOT_EXISTS_LINK = "18:NotExistsLink";
    string internal constant BMC_REVERT_ALREADY_EXISTS_BMR = "19:AlreadyExistsBMR";
    string internal constant BMC_REVERT_NOT_EXISTS_BMR = "20:NotExistsBMR";
    string internal constant BMC_REVERT_UNREACHABLE = "21:Unreachable";
    string internal constant BMC_REVERT_DROP = "22:Drop";
    string internal constant BMC_REVERT_INVALID_ARGUMENT = "10:InvalidArgument";
    string internal constant BMC_REVERT_ALREADY_EXISTS_OWNER = "10:AlreadyExistsOwner";
    string internal constant BMC_REVERT_NOT_EXISTS_OWNER = "10:NotExistsOwner";
    string internal constant BMC_REVERT_LAST_OWNER = "10:LastOwner";
    string internal constant BMC_REVERT_ALREADY_EXISTS_ROUTE = "10:AlreadyExistRoute";
    string internal constant BMC_REVERT_NOT_EXISTS_ROUTE = "10:NotExistsRoute";
    string internal constant BMC_REVERT_REFERRED_BY_ROUTE = "10:ReferredByRoute";
    string internal constant BMC_REVERT_PARSE_FAILURE = "10:ParseFailure";
    string internal constant BMC_REVERT_NOT_EXISTS_INTERNAL = "10:NotExistsInternal";
    string internal constant BMC_REVERT_INVALID_SEQ = "10:InvalidSeq";
    string internal constant BMC_REVERT_LENGTH_MUST_BE_EVEN = "10:LengthMustBeEven";
    string internal constant BMC_REVERT_MUST_BE_POSITIVE = "10:MustBePositive";
    string internal constant BMC_REVERT_NOT_ENOUGH_FEE = "10:NotEnoughFee";
    string internal constant BMC_REVERT_NOT_EXISTS_REWARD = "10:NotExistsReward";
    string internal constant BMC_REVERT_NOT_EXISTS_REQUEST = "10:NotExistsRequest";
    string internal constant BMC_REVERT_NOT_EXISTS_RESPONSE = "10:NotExistsResponse";
    string internal constant BMC_REVERT_ERROR_HANDLE_FEE = "10:ErrHandleFee";
    string internal constant BMV_REVERT_UNKNOWN = "25:Unknown";
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

/*
 * Utility library of inline functions on addresses
 */
library ParseAddress {
    /**
     * @dev Get a checksummed string hex representation of an account address.
     * @param account address The account to get the checksum for.
     * @return The checksummed account string in ASCII format. Note that leading
     * "0x" is not included.
     */
    function toString(address account) internal pure returns (string memory) {
        // call internal function for converting an account to a checksummed string.
        return _toChecksumString(account);
    }

    /**
     * @dev Get a fixed-size array of whether or not each character in an account
     * will be capitalized in the checksum.
     * @param account address The account to get the checksum capitalization
     * information for.
     * @return A fixed-size array of booleans that signify if each character or
     * "nibble" of the hex encoding of the address will be capitalized by the
     * checksum.
     */
    function getChecksumCapitalizedCharacters(address account)
        internal
        pure
        returns (bool[40] memory)
    {
        // call internal function for computing characters capitalized in checksum.
        return _toChecksumCapsFlags(account);
    }

    /**
     * @dev Determine whether a string hex representation of an account address
     * matches the ERC-55 checksum of that address.
     * @param accountChecksum string The checksummed account string in ASCII
     * format. Note that a leading "0x" MUST NOT be included.
     * @return A boolean signifying whether or not the checksum is valid.
     */
    function isChecksumValid(string calldata accountChecksum)
        internal
        pure
        returns (bool)
    {
        // call internal function for validating checksum strings.
        return _isChecksumValid(accountChecksum);
    }

    function _toChecksumString(address account)
        internal
        pure
        returns (string memory asciiString)
    {
        // convert the account argument from address to bytes.
        bytes20 data = bytes20(account);

        // create an in-memory fixed-size bytes array.
        bytes memory asciiBytes = new bytes(40);

        // declare variable types.
        uint8 b;
        uint8 leftNibble;
        uint8 rightNibble;
        bool leftCaps;
        bool rightCaps;
        uint8 asciiOffset;

        // get the capitalized characters in the actual checksum.
        bool[40] memory caps = _toChecksumCapsFlags(account);

        // iterate over bytes, processing left and right nibble in each iteration.
        for (uint256 i = 0; i < data.length; i++) {
            // locate the byte and extract each nibble.
            b = uint8(uint160(data) / (2**(8 * (19 - i))));
            leftNibble = b / 16;
            rightNibble = b - 16 * leftNibble;

            // locate and extract each capitalization status.
            leftCaps = caps[2 * i];
            rightCaps = caps[2 * i + 1];

            // get the offset from nibble value to ascii character for left nibble.
            asciiOffset = _getAsciiOffset(leftNibble, leftCaps);

            // add the converted character to the byte array.
            asciiBytes[2 * i] = bytes1(leftNibble + asciiOffset);

            // get the offset from nibble value to ascii character for right nibble.
            asciiOffset = _getAsciiOffset(rightNibble, rightCaps);

            // add the converted character to the byte array.
            asciiBytes[2 * i + 1] = bytes1(rightNibble + asciiOffset);
        }

        return string(abi.encodePacked("0x", string(asciiBytes)));
    }

    function _toChecksumCapsFlags(address account)
        internal
        pure
        returns (bool[40] memory characterCapitalized)
    {
        // convert the address to bytes.
        bytes20 a = bytes20(account);

        // hash the address (used to calculate checksum).
        bytes32 b = keccak256(abi.encodePacked(_toAsciiString(a)));

        // declare variable types.
        uint8 leftNibbleAddress;
        uint8 rightNibbleAddress;
        uint8 leftNibbleHash;
        uint8 rightNibbleHash;

        // iterate over bytes, processing left and right nibble in each iteration.
        for (uint256 i; i < a.length; i++) {
            // locate the byte and extract each nibble for the address and the hash.
            rightNibbleAddress = uint8(a[i]) % 16;
            leftNibbleAddress = (uint8(a[i]) - rightNibbleAddress) / 16;
            rightNibbleHash = uint8(b[i]) % 16;
            leftNibbleHash = (uint8(b[i]) - rightNibbleHash) / 16;

            characterCapitalized[2 * i] = (leftNibbleAddress > 9 &&
                leftNibbleHash > 7);
            characterCapitalized[2 * i + 1] = (rightNibbleAddress > 9 &&
                rightNibbleHash > 7);
        }
    }

    function _isChecksumValid(string memory provided)
        internal
        pure
        returns (bool ok)
    {
        // convert the provided string into account type.
        address account = _toAddress(provided);

        // return false in the event the account conversion returned null address.
        if (account == address(0)) {
            // ensure that provided address is not also the null address first.
            bytes memory b = bytes(provided);
            for (uint256 i; i < b.length; i++) {
                if (b[i] != hex"30") {
                    return false;
                }
            }
        }

        // get the capitalized characters in the actual checksum.
        string memory actual = _toChecksumString(account);

        // compare provided string to actual checksum string to test for validity.
        return (keccak256(abi.encodePacked(actual)) ==
            keccak256(abi.encodePacked(provided)));
    }

    function _getAsciiOffset(uint8 nibble, bool caps)
        internal
        pure
        returns (uint8 offset)
    {
        // to convert to ascii characters, add 48 to 0-9, 55 to A-F, & 87 to a-f.
        if (nibble < 10) {
            offset = 48;
        } else if (caps) {
            offset = 55;
        } else {
            offset = 87;
        }
    }

    function _toAddress(string memory account)
        internal
        pure
        returns (address accountAddress)
    {
        // convert the account argument from address to bytes.
        bytes memory accountBytes = bytes(account);

        // create a new fixed-size byte array for the ascii bytes of the address.
        bytes memory accountAddressBytes = new bytes(20);

        // declare variable types.
        uint8 b;
        uint8 nibble;
        uint8 asciiOffset;

        // only proceed if the provided string has a length of 40.
        if (accountBytes.length == 40) {
            for (uint256 i; i < 40; i++) {
                // get the byte in question.
                b = uint8(accountBytes[i]);

                // ensure that the byte is a valid ascii character (0-9, A-F, a-f)
                if (b < 48) return address(0);
                if (57 < b && b < 65) return address(0);
                if (70 < b && b < 97) return address(0);
                if (102 < b) return address(0); //bytes(hex"");

                // find the offset from ascii encoding to the nibble representation.
                if (b < 65) {
                    // 0-9
                    asciiOffset = 48;
                } else if (70 < b) {
                    // a-f
                    asciiOffset = 87;
                } else {
                    // A-F
                    asciiOffset = 55;
                }

                // store left nibble on even iterations, then store byte on odd ones.
                if (i % 2 == 0) {
                    nibble = b - asciiOffset;
                } else {
                    accountAddressBytes[(i - 1) / 2] = (
                        bytes1(16 * nibble + (b - asciiOffset))
                    );
                }
            }

            // pack up the fixed-size byte array and cast it to accountAddress.
            bytes memory packed = abi.encodePacked(accountAddressBytes);
            assembly {
                accountAddress := mload(add(packed, 20))
            }
        }
    }

    // based on https://ethereum.stackexchange.com/a/56499/48410
    function _toAsciiString(bytes20 data)
        internal
        pure
        returns (string memory asciiString)
    {
        // create an in-memory fixed-size bytes array.
        bytes memory asciiBytes = new bytes(40);

        // declare variable types.
        uint8 b;
        uint8 leftNibble;
        uint8 rightNibble;

        // iterate over bytes, processing left and right nibble in each iteration.
        for (uint256 i = 0; i < data.length; i++) {
            // locate the byte and extract each nibble.
            b = uint8(uint160(data) / (2**(8 * (19 - i))));
            leftNibble = b / 16;
            rightNibble = b - 16 * leftNibble;

            // to convert to ascii characters, add 48 to 0-9 and 87 to a-f.
            asciiBytes[2 * i] = bytes1(
                leftNibble + (leftNibble < 10 ? 48 : 87)
            );
            asciiBytes[2 * i + 1] = bytes1(
                rightNibble + (rightNibble < 10 ? 48 : 87)
            );
        }

        return string(asciiBytes);
    }

    function parseAddress(
        string memory account,
        string memory revertMsg
    ) internal pure returns (address accountAddress)
    {
        bytes memory accountBytes = bytes(account);
        require(
            accountBytes.length == 42 &&
            accountBytes[0] == bytes1("0") &&
            accountBytes[1] == bytes1("x"),
            revertMsg
        );

        // create a new fixed-size byte array for the ascii bytes of the address.
        bytes memory accountAddressBytes = new bytes(20);

        // declare variable types.
        uint8 b;
        uint8 nibble;
        uint8 asciiOffset;

        for (uint256 i = 0; i < 40; i++) {
            // get the byte in question.
            b = uint8(accountBytes[i + 2]);

            bool isValidASCII = true;
            // ensure that the byte is a valid ascii character (0-9, A-F, a-f)
            if (b < 48) isValidASCII = false;
            if (57 < b && b < 65) isValidASCII = false;
            if (70 < b && b < 97) isValidASCII = false;
            if (102 < b) isValidASCII = false; //bytes(hex"");

            // If string contains invalid ASCII characters, revert()
            if (!isValidASCII) revert(revertMsg);

            // find the offset from ascii encoding to the nibble representation.
            if (b < 65) {
                // 0-9
                asciiOffset = 48;
            } else if (70 < b) {
                // a-f
                asciiOffset = 87;
            } else {
                // A-F
                asciiOffset = 55;
            }

            // store left nibble on even iterations, then store byte on odd ones.
            if (i % 2 == 0) {
                nibble = b - asciiOffset;
            } else {
                accountAddressBytes[(i - 1) / 2] = (
                bytes1(16 * nibble + (b - asciiOffset))
                );
            }
        }

        // pack up the fixed-size byte array and cast it to accountAddress.
        bytes memory packed = abi.encodePacked(accountAddressBytes);
        assembly {
            accountAddress := mload(add(packed, 20))
        }

        // return false in the event the account conversion returned null address.
        if (accountAddress == address(0)) {
            // ensure that provided address is not also the null address first.
            for (uint256 i = 2; i < accountBytes.length; i++)
                require(accountBytes[i] == hex"30", revertMsg);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

/*
 *  Change supporting solidity compiler version
 *  The original code can be found via this link: https://github.com/hamdiallam/Solidity-RLP.git
 */

library RLPDecode {
    uint8 private constant STRING_SHORT_START = 0x80;
    uint8 private constant STRING_LONG_START = 0xb8;
    uint8 private constant LIST_SHORT_START = 0xc0;
    uint8 private constant LIST_LONG_START = 0xf8;
    uint8 private constant WORD_SIZE = 32;

    struct RLPItem {
        uint256 len;
        uint256 memPtr;
    }

    struct Iterator {
        RLPItem item; // Item that's being iterated over.
        uint256 nextPtr; // Position of the next item in the list.
    }

    /*
     * @dev Returns the next element in the iteration. Reverts if it has not next element.
     * @param self The iterator.
     * @return The next element in the iteration.
     */
    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self), "Must have next elements");

        uint256 ptr = self.nextPtr;
        uint256 itemLength = _itemLength(ptr);
        self.nextPtr = ptr + itemLength;

        return RLPItem(itemLength, ptr);
    }

    /*
     * @dev Returns true if the iteration has more elements.
     * @param self The iterator.
     * @return true if the iteration has more elements.
     */
    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self.item;
        return self.nextPtr < item.memPtr + item.len;
    }

    /*
     * @param item RLP encoded bytes
     */
    function toRlpItem(bytes memory item)
        internal
        pure
        returns (RLPItem memory)
    {
        uint256 memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
     * @dev Create an iterator. Reverts if item is not a list.
     * @param self The RLP item.
     * @return An 'Iterator' over the item.
     */
    function iterator(RLPItem memory self)
        internal
        pure
        returns (Iterator memory)
    {
        require(isList(self), "Must be a list");

        uint256 ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    /*
     * @param item RLP encoded bytes
     */
    function rlpLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len;
    }

    /*
     * @param item RLP encoded bytes
     */
    function payloadLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len - _payloadOffset(item.memPtr);
    }

    /*
     * @param item RLP encoded list in bytes
     */
    function toList(RLPItem memory item)
        internal
        pure
        returns (RLPItem[] memory)
    {
        require(isList(item), "Must be a list");

        uint256 items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint256 memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 dataLen;
        for (uint256 i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint256 memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START) return false;
        return true;
    }

    function isNull(RLPItem memory item) internal pure returns (bool) {
        if (item.len != 2) return false;

        uint8 byte0;
        uint8 itemLen;
        uint256 memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
            memPtr := add(memPtr, 1)
            itemLen := byte(0, mload(memPtr))
        }
        if (byte0 != LIST_LONG_START || itemLen != 0) return false;
        return true;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;

        uint256 ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte except "0x80" is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1, "Must have length 1");
        uint256 result;
        uint256 memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        // SEE Github Issue #5.
        // Summary: Most commonly used RLP libraries (i.e Geth) will encode
        // "0" as "0x80" instead of as "0". We handle this edge case explicitly
        // here.
        if (result == 0 || result == STRING_SHORT_START) {
            return false;
        } else {
            return true;
        }
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21, "Must have length 21");

        return address(uint160(toUint(item)));
    }

    function toUint(RLPItem memory item) internal pure returns (uint256) {
        require(item.len > 0 && item.len <= 33, "Invalid uint number");

        uint256 offset = _payloadOffset(item.memPtr);
        uint256 len = item.len - offset;

        uint256 result;
        uint256 memPtr = item.memPtr + offset;
        assembly {
            result := mload(memPtr)

            // shfit to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    function toInt(RLPItem memory item) internal pure returns (int256) {
        if ((toBytes(item)[0] & 0x80) == 0x80) {
            return int256(toUint(item)) - int256(2**(toBytes(item).length * 8));
        }

        return int256(toUint(item));
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint256) {
        // one byte prefix
        require(item.len == 33, "Must have length 33");

        uint256 result;
        uint256 memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0, "Invalid length");

        uint256 offset = _payloadOffset(item.memPtr);
        uint256 len = item.len - offset; // data length
        bytes memory result = new bytes(len);

        uint256 destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(item.memPtr + offset, destPtr, len);
        return result;
    }

    /*
     * Private Helpers
     */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint256) {
        if (item.len == 0) return 0;

        uint256 count = 0;
        uint256 currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr); // skip over an item
            count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint256 memPtr) private pure returns (uint256) {
        uint256 itemLen;
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) itemLen = 1;
        else if (byte0 < STRING_LONG_START)
            itemLen = byte0 - STRING_SHORT_START + 1;
        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte

                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        } else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        } else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint256 memPtr) private pure returns (uint256) {
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) return 0;
        else if (
            byte0 < STRING_LONG_START ||
            (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)
        ) return 1;
        else if (byte0 < LIST_SHORT_START)
            // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else return byte0 - (LIST_LONG_START - 1) + 1;
    }

    /*
     * @param src Pointer to source
     * @param dest Pointer to destination
     * @param len Amount of memory to copy from the source
     */
    function copy(
        uint256 src,
        uint256 dest,
        uint256 len
    ) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        if (len > 0) {
            // left over bytes. Mask is used to remove unwanted bytes from the word
            uint256 mask = 256**(WORD_SIZE - len) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask)) // zero out src
                let destpart := and(mload(dest), mask) // retrieve the bytes
                mstore(dest, or(destpart, srcpart))
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import "./RLPDecode.sol";
import "./Types.sol";

library RLPDecodeStruct {
    using RLPDecode for RLPDecode.RLPItem;
    using RLPDecode for RLPDecode.Iterator;
    using RLPDecode for bytes;

    using RLPDecodeStruct for bytes;

    uint8 private constant LIST_SHORT_START = 0xc0;
    uint8 private constant LIST_LONG_START = 0xf7;

    function _decodeFeeInfo(
        RLPDecode.RLPItem memory item
    ) private pure returns (
        Types.FeeInfo memory
    ) {
        if (item.isNull()) {
            return Types.FeeInfo("", new uint256[](0));
        }
        RLPDecode.RLPItem[] memory ls = item.toList();
        RLPDecode.RLPItem[] memory rlpValues = ls[1].toList();
        uint256[] memory _values = new uint256[](rlpValues.length);
        for (uint256 i = 0; i < rlpValues.length; i++)
            _values[i] = rlpValues[i].toUint();
        return
        Types.FeeInfo(
            string(ls[0].toBytes()),
            _values
        );
    }

    function decodeFeeInfo(bytes memory _rlp)
    internal
    pure
    returns (Types.FeeInfo memory)
    {
        return _decodeFeeInfo(_rlp.toRlpItem());
    }

    function decodeBMCMessage(bytes memory _rlp)
        internal
        pure
        returns (Types.BMCMessage memory)
    {
        RLPDecode.RLPItem[] memory ls = _rlp.toRlpItem().toList();
        return
            Types.BMCMessage(
                string(ls[0].toBytes()),
                ls[1].toBytes() //  bytes array of RLPEncode(Data)
            );
    }

    function decodePropagateMessage(bytes memory _rlp)
        internal
        pure
        returns (string memory)
    {
        RLPDecode.RLPItem[] memory ls = _rlp.toRlpItem().toList();
        return string(ls[0].toBytes());
    }

    function decodeInitMessage(bytes memory _rlp)
        internal
        pure
        returns (string[] memory _links)
    {
        RLPDecode.RLPItem[] memory ls = _rlp.toRlpItem().toList();
        RLPDecode.RLPItem[] memory rlpLinks = ls[0].toList();
        _links = new string[](rlpLinks.length);
        for (uint256 i = 0; i < rlpLinks.length; i++)
            _links[i] = string(rlpLinks[i].toBytes());
    }

    function decodeBTPMessage(bytes memory _rlp)
        internal
        pure
        returns (Types.BTPMessage memory)
    {
        RLPDecode.RLPItem[] memory ls = _rlp.toRlpItem().toList();
        return
            Types.BTPMessage(
                string(ls[0].toBytes()),
                string(ls[1].toBytes()),
                string(ls[2].toBytes()),
                ls[3].toInt(),
                ls[4].toBytes(),
                ls[5].toInt(),
                _decodeFeeInfo(ls[6])
            );
    }

    function decodeResponseMessage(bytes memory _rlp)
        internal
        pure
        returns (Types.ResponseMessage memory)
    {
        RLPDecode.RLPItem[] memory ls = _rlp.toRlpItem().toList();
        return Types.ResponseMessage(ls[0].toUint(), string(ls[1].toBytes()));
    }

    function decodeClaimMessage(bytes memory _rlp)
    internal
    pure
    returns (Types.ClaimMessage memory)
    {
        RLPDecode.RLPItem[] memory ls = _rlp.toRlpItem().toList();
        return Types.ClaimMessage(ls[0].toUint(), string(ls[1].toBytes()));
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

/**
 * @title RLPEncode
 * @dev A simple RLP encoding library.
 * @author Bakaoh
 * The original code was modified. For more info, please check the link:
 * https://github.com/bakaoh/solidity-rlp-encode.git
 */
library RLPEncode {
    bytes internal constant NULL = hex"f800";

    int8 internal constant MAX_INT8 = type(int8).max;
    int16 internal constant MAX_INT16 = type(int16).max;
    int24 internal constant MAX_INT24 = type(int24).max;
    int32 internal constant MAX_INT32 = type(int32).max;
    int40 internal constant MAX_INT40 = type(int40).max;
    int48 internal constant MAX_INT48 = type(int48).max;
    int56 internal constant MAX_INT56 = type(int56).max;
    int64 internal constant MAX_INT64 = type(int64).max;
    int72 internal constant MAX_INT72 = type(int72).max;
    int80 internal constant MAX_INT80 = type(int80).max;
    int88 internal constant MAX_INT88 = type(int88).max;
    int96 internal constant MAX_INT96 = type(int96).max;
    int104 internal constant MAX_INT104 = type(int104).max;
    int112 internal constant MAX_INT112 = type(int112).max;
    int120 internal constant MAX_INT120 = type(int120).max;
    int128 internal constant MAX_INT128 = type(int128).max;

    uint8 internal constant MAX_UINT8 = type(uint8).max;
    uint16 internal constant MAX_UINT16 = type(uint16).max;
    uint24 internal constant MAX_UINT24 = type(uint24).max;
    uint32 internal constant MAX_UINT32 = type(uint32).max;
    uint40 internal constant MAX_UINT40 = type(uint40).max;
    uint48 internal constant MAX_UINT48 = type(uint48).max;
    uint56 internal constant MAX_UINT56 = type(uint56).max;
    uint64 internal constant MAX_UINT64 = type(uint64).max;
    uint72 internal constant MAX_UINT72 = type(uint72).max;
    uint80 internal constant MAX_UINT80 = type(uint80).max;
    uint88 internal constant MAX_UINT88 = type(uint88).max;
    uint96 internal constant MAX_UINT96 = type(uint96).max;
    uint104 internal constant MAX_UINT104 = type(uint104).max;
    uint112 internal constant MAX_UINT112 = type(uint112).max;
    uint120 internal constant MAX_UINT120 = type(uint120).max;
    uint128 internal constant MAX_UINT128 = type(uint128).max;

    /*
     * Internal functions
     */

    /**
     * @dev RLP encodes a byte string.
     * @param self The byte string to encode.
     * @return The RLP encoded string in bytes.
     */
    function encodeBytes(bytes memory self)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory encoded;
        if (self.length == 1 && uint8(self[0]) <= 128) {
            encoded = self;
        } else {
            encoded = concat(encodeLength(self.length, 128), self);
        }
        return encoded;
    }

    /**
     * @dev RLP encodes a list of RLP encoded byte byte strings.
     * @param self The list of RLP encoded byte strings.
     * @return The RLP encoded list of items in bytes.
     */
    function encodeList(bytes[] memory self)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory list = flatten(self);
        return concat(encodeLength(list.length, 192), list);
    }

    /**
     * @dev RLP encodes a string.
     * @param self The string to encode.
     * @return The RLP encoded string in bytes.
     */
    function encodeString(string memory self)
        internal
        pure
        returns (bytes memory)
    {
        return encodeBytes(bytes(self));
    }

    /**
     * @dev RLP encodes an address.
     * @param self The address to encode.
     * @return The RLP encoded address in bytes.
     */
    function encodeAddress(address self) internal pure returns (bytes memory) {
        bytes memory inputBytes;
        assembly {
            let m := mload(0x40)
            mstore(
                add(m, 20),
                xor(0x140000000000000000000000000000000000000000, self)
            )
            mstore(0x40, add(m, 52))
            inputBytes := m
        }
        return encodeBytes(inputBytes);
    }

    /**
     * @dev RLP encodes a uint.
     * @param self The uint to encode.
     * @return The RLP encoded uint in bytes.
     */
    function encodeUint(uint256 self) internal pure returns (bytes memory) {
        uint nBytes = bitLength(self)/8 + 1;
        bytes memory uintBytes = encodeUintByLength(self);
        if (nBytes - uintBytes.length > 0) {
            uintBytes = abi.encodePacked(bytes1(0), uintBytes);
        }
        return encodeBytes(uintBytes);
    }

    /**
     * @dev convert int to strict bytes.
     * @notice only handle to int128 due to contract code size limit
     * @param n The int to convert.
     * @return The int in strict bytes without padding.
     */
    function intToStrictBytes(int256 n) internal pure returns (bytes memory) {
        if (-MAX_INT8 - 1 <= n && n <= MAX_INT8) {
            return abi.encodePacked(int8(n));
        } else if (-MAX_INT16 - 1 <= n && n <= MAX_INT16) {
            return abi.encodePacked(int16(n));
        } else if (-MAX_INT24 - 1 <= n && n <= MAX_INT24) {
            return abi.encodePacked(int24(n));
        } else if (-MAX_INT32 - 1 <= n && n <= MAX_INT32) {
            return abi.encodePacked(int32(n));
        } else if (-MAX_INT40 - 1 <= n && n <= MAX_INT40) {
            return abi.encodePacked(int40(n));
        } else if (-MAX_INT48 - 1 <= n && n <= MAX_INT48) {
            return abi.encodePacked(int48(n));
        } else if (-MAX_INT56 - 1 <= n && n <= MAX_INT56) {
            return abi.encodePacked(int56(n));
        } else if (-MAX_INT64 - 1 <= n && n <= MAX_INT64) {
            return abi.encodePacked(int64(n));
        } else if (-MAX_INT72 - 1 <= n && n <= MAX_INT72) {
            return abi.encodePacked(int72(n));
        } else if (-MAX_INT80 - 1 <= n && n <= MAX_INT80) {
            return abi.encodePacked(int80(n));
        } else if (-MAX_INT88 - 1 <= n && n <= MAX_INT88) {
            return abi.encodePacked(int88(n));
        } else if (-MAX_INT96 - 1 <= n && n <= MAX_INT96) {
            return abi.encodePacked(int96(n));
        } else if (-MAX_INT104 - 1 <= n && n <= MAX_INT104) {
            return abi.encodePacked(int104(n));
        } else if (-MAX_INT112 - 1 <= n && n <= MAX_INT112) {
            return abi.encodePacked(int112(n));
        } else if (-MAX_INT120 - 1 <= n && n <= MAX_INT120) {
            return abi.encodePacked(int120(n));
        }
        require(-MAX_INT128 - 1 <= n && n <= MAX_INT128, "outOfBounds: [-2^128-1, 2^128]");
        return abi.encodePacked(int128(n));
    }

    /**
     * @dev RLP encodes an int.
     * @param self The int to encode.
     * @return The RLP encoded int in bytes.
     */
    function encodeInt(int256 self) internal pure returns (bytes memory) {
        return encodeBytes(intToStrictBytes(self));
    }

    /**
     * @dev RLP encodes a bool.
     * @param self The bool to encode.
     * @return The RLP encoded bool in bytes.
     */
    function encodeBool(bool self) internal pure returns (bytes memory) {
        bytes memory encoded = new bytes(1);
        encoded[0] = (self ? bytes1(0x01) : bytes1(0x00));
        return encoded;
    }

    /**
     * @dev RLP encodes null.
     * @return bytes for null
     */
    function encodeNull() internal pure returns (bytes memory) {
        return NULL;
    }

    /*
     * Private functions
     */

    /**
     * @dev Encode the first byte, followed by the `len` in binary form if `length` is more than 55.
     * @param len The length of the string or the payload.
     * @param offset 128 if item is string, 192 if item is list.
     * @return RLP encoded bytes.
     */
    function encodeLength(uint256 len, uint256 offset)
        private
        pure
        returns (bytes memory)
    {
        bytes memory encoded;
        if (len < 56) {
            encoded = new bytes(1);
            encoded[0] = bytes32(len + offset)[31];
        } else {
            uint256 lenLen;
            uint256 i = 1;
            while (len / i != 0) {
                lenLen++;
                i *= 256;
            }

            encoded = new bytes(lenLen + 1);
            encoded[0] = bytes32(lenLen + offset + 55)[31];
            for (i = 1; i <= lenLen; i++) {
                encoded[i] = bytes32((len / (256**(lenLen - i))) % 256)[31];
            }
        }
        return encoded;
    }

    /**
     * @dev Encode integer in big endian binary form with no leading zeroes.
     * @notice TODO: This should be optimized with assembly to save gas costs.
     * @param _x The integer to encode.
     * @return RLP encoded bytes.
     */
    function toBinary(uint256 _x) private pure returns (bytes memory) {
        //  Modify library to make it work properly when _x = 0
        if (_x == 0) {
            return abi.encodePacked(uint8(_x));
        }
        bytes memory b = new bytes(32);
        assembly {
            mstore(add(b, 32), _x)
        }
        uint256 i;
        for (i = 0; i < 32; i++) {
            if (b[i] != 0) {
                break;
            }
        }
        bytes memory res = new bytes(32 - i);
        for (uint256 j = 0; j < res.length; j++) {
            res[j] = b[i++];
        }
        return res;
    }

    /**
     * @dev Flattens a list of byte strings into one byte string.
     * @notice From: https://github.com/sammayo/solidity-rlp-encoder/blob/master/RLPEncode.sol.
     * @param _list List of byte strings to flatten.
     * @return The flattened byte string.
     */
    function flatten(bytes[] memory _list) private pure returns (bytes memory) {
        if (_list.length == 0) {
            return new bytes(0);
        }

        uint256 len;
        uint256 i;
        for (i = 0; i < _list.length; i++) {
            len += _list[i].length;
        }

        bytes memory flattened = new bytes(len);
        uint256 flattenedPtr;
        assembly {
            flattenedPtr := add(flattened, 0x20)
        }

        for (i = 0; i < _list.length; i++) {
            bytes memory item = _list[i];

            uint256 listPtr;
            assembly {
                listPtr := add(item, 0x20)
            }

            memcpy(flattenedPtr, listPtr, item.length);
            flattenedPtr += _list[i].length;
        }

        return flattened;
    }

    /**
     * @dev Copies a piece of memory to another location.
     * @notice From: https://github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol.
     * @param dest Destination location.
     * @param src Source location.
     * @param len Length of memory to copy.
     */
    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = type(uint).max;
        if (len > 0) {
            mask = 256 ** (32 - len) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask))
                let destpart := and(mload(dest), mask)
                mstore(dest, or(destpart, srcpart))
            }
        }
    }

    /**
     * @dev Concatenates two bytes.
     * @notice From: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol.
     * @param _preBytes First byte string.
     * @param _postBytes Second byte string.
     * @return Both byte string combined.
     */
    function concat(bytes memory _preBytes, bytes memory _postBytes)
        private
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            tempBytes := mload(0x40)

            let length := mload(_preBytes)
            mstore(tempBytes, length)

            let mc := add(tempBytes, 0x20)
            let end := add(mc, length)

            for {
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            mc := end
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31)
                )
            )
        }

        return tempBytes;
    }

    /**
     * @dev convert uint to strict bytes.
     * @notice only handle to uint128 due to contract code size limit
     * @param length The uint to convert.
     * @return The uint in strict bytes without padding.
     */
    function encodeUintByLength(uint256 length)
        internal
        pure
        returns (bytes memory)
    {
        if (length < MAX_UINT8) {
            return abi.encodePacked(uint8(length));
        } else if (length >= MAX_UINT8 && length < MAX_UINT16) {
            return abi.encodePacked(uint16(length));
        } else if (length >= MAX_UINT16 && length < MAX_UINT24) {
            return abi.encodePacked(uint24(length));
        } else if (length >= MAX_UINT24 && length < MAX_UINT32) {
            return abi.encodePacked(uint32(length));
        } else if (length >= MAX_UINT32 && length < MAX_UINT40) {
            return abi.encodePacked(uint40(length));
        } else if (length >= MAX_UINT40 && length < MAX_UINT48) {
            return abi.encodePacked(uint48(length));
        } else if (length >= MAX_UINT48 && length < MAX_UINT56) {
            return abi.encodePacked(uint56(length));
        } else if (length >= MAX_UINT56 && length < MAX_UINT64) {
            return abi.encodePacked(uint64(length));
        } else if (length >= MAX_UINT64 && length < MAX_UINT72) {
            return abi.encodePacked(uint72(length));
        } else if (length >= MAX_UINT72 && length < MAX_UINT80) {
            return abi.encodePacked(uint80(length));
        } else if (length >= MAX_UINT80 && length < MAX_UINT88) {
            return abi.encodePacked(uint88(length));
        } else if (length >= MAX_UINT88 && length < MAX_UINT96) {
            return abi.encodePacked(uint96(length));
        } else if (length >= MAX_UINT96 && length < MAX_UINT104) {
            return abi.encodePacked(uint104(length));
        } else if (length >= MAX_UINT104 && length < MAX_UINT112) {
            return abi.encodePacked(uint112(length));
        } else if (length >= MAX_UINT112 && length < MAX_UINT120) {
            return abi.encodePacked(uint120(length));
        }
        require(length >= MAX_UINT120 && length < MAX_UINT128, "outOfBounds: [0, 2^128]");
        return abi.encodePacked(uint128(length));
    }

    function bitLength(uint256 n) internal pure returns (uint256) {
        uint256 count;
        while (n != 0) {
            count += 1;
            n >>= 1;
        }
        return count;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import "./RLPEncode.sol";
import "./Types.sol";

library RLPEncodeStruct {
    using RLPEncode for bytes;
    using RLPEncode for string;
    using RLPEncode for uint256;
    using RLPEncode for int256;
    using RLPEncode for address;

    uint8 internal constant LIST_SHORT_START = 0xc0;
    uint8 internal constant LIST_LONG_START = 0xf7;

    function encodeFeeInfo(Types.FeeInfo memory _fi)
    internal
    pure
    returns (bytes memory)
    {
        bytes memory _rlpValues;
        for (uint256 i = 0; i < _fi.values.length; i++) {
            _rlpValues = abi.encodePacked(_rlpValues, _fi.values[i].encodeUint());
        }
        _rlpValues = abi.encodePacked(addLength(_rlpValues.length, false), _rlpValues);
        bytes memory _rlp = abi.encodePacked(
            _fi.network.encodeString(),
            _rlpValues
        );
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeBMCMessage(Types.BMCMessage memory _bs)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory _rlp =
            abi.encodePacked(
                _bs.msgType.encodeString(),
                _bs.payload.encodeBytes());
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeBTPMessage(Types.BTPMessage memory _bm)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory _rlp =
            abi.encodePacked(
                _bm.src.encodeString(),
                _bm.dst.encodeString(),
                _bm.svc.encodeString(),
                _bm.sn.encodeInt(),
                _bm.message.encodeBytes(),
                _bm.nsn.encodeInt(),
                encodeFeeInfo(_bm.feeInfo)
            );
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeResponseMessage(Types.ResponseMessage memory _res)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory _rlp =
            abi.encodePacked(
                _res.code.encodeUint(),
                _res.message.encodeString()
            );
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeInitMessage(string[] memory _links)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory _rlp;
        for (uint256 i = 0; i < _links.length; i++) {
            _rlp = abi.encodePacked(_rlp, _links[i].encodeString());
        }
        _rlp = abi.encodePacked(addLength(_rlp.length, false), _rlp);
    return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodePropagateMessage(string memory _link)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory _rlp = abi.encodePacked(_link.encodeString());
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeClaimMessage(Types.ClaimMessage memory _cm)
    internal
    pure
    returns (bytes memory)
    {
        bytes memory _rlp =
        abi.encodePacked(
            _cm.amount.encodeUint(),
            _cm.receiver.encodeString());
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    //  Adding LIST_HEAD_START by length
    //  There are two cases:
    //  1. List contains less than or equal 55 elements (total payload of the RLP) -> LIST_HEAD_START = LIST_SHORT_START + [0-55] = [0xC0 - 0xF7]
    //  2. List contains more than 55 elements:
    //  - Total Payload = 512 elements = 0x0200
    //  - Length of Total Payload = 2
    //  => LIST_HEAD_START = \x (LIST_LONG_START + length of Total Payload) \x (Total Payload) = \x(F7 + 2) \x(0200) = \xF9 \x0200 = 0xF90200
    function addLength(uint256 length, bool isLongList)
        internal
        pure
        returns (bytes memory)
    {
        if (length > 55 && !isLongList) {
            bytes memory payLoadSize = RLPEncode.encodeUintByLength(length);
            return
                abi.encodePacked(
                    addLength(payLoadSize.length, true),
                    payLoadSize
                );
        } else if (length <= 55 && !isLongList) {
            return abi.encodePacked(uint8(LIST_SHORT_START + length));
        }
        return abi.encodePacked(uint8(LIST_LONG_START + length));
    }

    function emptyListHeadStart() internal pure returns (bytes memory) {
        bytes memory payLoadSize = RLPEncode.encodeUintByLength(0);
        return
            abi.encodePacked(
                abi.encodePacked(uint8(LIST_LONG_START + payLoadSize.length)),
                payLoadSize
            );
    }

    function emptyListShortStart() internal pure returns (bytes memory) {
        return abi.encodePacked(LIST_SHORT_START);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

/**
 * Strings Library
 *
 * This is a simple library of string functions which try to simplify
 * string operations in solidity.
 *
 * Please be aware some of these functions can be quite gas heavy so use them only when necessary
 *
 * The original library was modified. If you want to know more about the original version
 * please check this link: https://github.com/willitscale/solidity-util.git
 */
library Strings {

    function bytesToHex(bytes memory buffer) public pure returns (string memory) {
        if (buffer.length == 0) {
            return string("0x");
        }
        // Fixed buffer size for hexadecimal convertion
        bytes memory converted = new bytes(buffer.length * 2);

        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return string(abi.encodePacked("0x", converted));
    }

    /**
     * Concat
     *
     * Appends two strings together and returns a new value
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string which will be the concatenated
     *              prefix
     * @param _value The value to be the concatenated suffix
     * @return string The resulting string from combinging the base and value
     */
    function concat(string memory _base, string memory _value)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(_base, _value));
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(string memory _base, string memory _value)
        internal
        pure
        returns (int256)
    {
        return _indexOf(_base, _value, 0);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function _indexOf(
        string memory _base,
        string memory _value,
        uint256 _offset
    ) internal pure returns (int256) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint256 i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int256(i);
            }
        }

        return -1;
    }

    /**
     * Length
     *
     * Returns the length of the specified string
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string to be measured
     * @return uint The length of the passed string
     */
    function length(string memory _base) internal pure returns (uint256) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }

    /*
     * String Split (Very high gas cost)
     *
     * Splits a string into an array of strings based off the delimiter value.
     * Please note this can be quite a gas expensive function due to the use of
     * storage so only use if really required.
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string value to be split.
     * @param _value The delimiter to split the string on which must be a single
     *               character
     * @return string[] An array of values split based off the delimiter, but
     *                  do not container the delimiter.
     */
    function split(string memory _base, string memory _value)
        internal
        pure
        returns (string[] memory splitArr)
    {
        bytes memory _baseBytes = bytes(_base);

        uint256 _offset = 0;
        uint256 _splitsCount = 1;
        while (_offset < _baseBytes.length - 1) {
            int256 _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1) break;
            else {
                _splitsCount++;
                _offset = uint256(_limit) + 1;
            }
        }

        splitArr = new string[](_splitsCount);

        _offset = 0;
        _splitsCount = 0;
        while (_offset < _baseBytes.length - 1) {
            int256 _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1) {
                _limit = int256(_baseBytes.length);
            }

            string memory _tmp = new string(uint256(_limit) - _offset);
            bytes memory _tmpBytes = bytes(_tmp);

            uint256 j = 0;
            for (uint256 i = _offset; i < uint256(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            _offset = uint256(_limit) + 1;
            splitArr[_splitsCount++] = string(_tmpBytes);
        }
        return splitArr;
    }

    /**
     * Compare To
     *
     * Compares the characters of two strings, to ensure that they have an
     * identical footprint
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent
     */
    function compareTo(string memory _base, string memory _value)
        internal
        pure
        returns (bool)
    {
        if (
            keccak256(abi.encodePacked(_base)) ==
            keccak256(abi.encodePacked(_value))
        ) {
            return true;
        }
        return false;
    }

    /**
     * Lower
     *
     * Converts all the values of a string to their corresponding lower case
     * value.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to lower case
     * @return string
     */
    function lower(string memory _base)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Lower
     *
     * Convert an alphabetic character to lower case and return the original
     * value when not alphabetic
     *
     * @param _b1 The byte to be converted to lower case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a upper case otherwise returns the original value
     */
    function _lower(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import "../interfaces/IBMV.sol";

library Types {
    string internal constant BMC_SERVICE = "bmc";

    uint256 internal constant ECODE_NONE = 0;
    uint256 internal constant ECODE_UNKNOWN = 1;
    uint256 internal constant ECODE_NO_ROUTE = 2;
    uint256 internal constant ECODE_NO_BSH = 3;
    uint256 internal constant ECODE_BSH_REVERT = 4;

    string internal constant BMC_INTERNAL_INIT = "Init";
    string internal constant BMC_INTERNAL_LINK = "Link";
    string internal constant BMC_INTERNAL_UNLINK = "Unlink";
    string internal constant BMC_INTERNAL_CLAIM = "Claim";
    string internal constant BMC_INTERNAL_RESPONSE = "Response";

    uint256 internal constant ROUTE_TYPE_NONE = 0;
    uint256 internal constant ROUTE_TYPE_LINK = 1;
    uint256 internal constant ROUTE_TYPE_REACHABLE = 2;
    uint256 internal constant ROUTE_TYPE_MANUAL = 3;

    string internal constant BTP_EVENT_SEND = "SEND";
    string internal constant BTP_EVENT_ROUTE = "ROUTE";
    string internal constant BTP_EVENT_REPLY = "REPLY";
    string internal constant BTP_EVENT_ERROR = "ERROR";
    string internal constant BTP_EVENT_RECEIVE = "RECEIVE";
    string internal constant BTP_EVENT_DROP = "DROP";

    struct Service {
        string svc;
        address addr;
    }

    struct Verifier {
        string net;
        address addr;
    }

    struct Route {
        string dst; //  Network Address of destination BMC
        string next; //  Network Address of a BMC before reaching dst BMC
    }

    struct RouteInfo {
        string dst; //  Network Address of destination BMC
        string next; //  Network Address of a BMC before reaching dst BMC
        uint256 reachable;
        uint256 routeType;//{0:unregistered, 1:link, 2:reachable, 3:manual}
    }

    struct Link {
        string btpAddress;
        string[] reachable;
    }

    struct LinkStatus {
        uint256 rxSeq;
        uint256 txSeq;
        IBMV.VerifierStatus verifier;
        uint256 currentHeight;
    }

    struct FeeInfo {
        string network;
        uint256[] values;
    }

    struct BTPMessage {
        string src;
        string dst;
        string svc;
        int256 sn;
        bytes message;
        int256 nsn;
        FeeInfo feeInfo;
    }

    struct ResponseMessage {
        uint256 code;
        string message;
    }

    struct BMCMessage {
        string msgType;
        bytes payload;
    }

    struct Request {
        int256 nsn;
        string dst;
        address caller;
        uint256 amount;
    }

    struct ClaimMessage {
        uint256 amount;
        string receiver;
    }

    struct Response {
        int256 nsn;
        FeeInfo feeInfo;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import "./Strings.sol";

library Utils {
    using Strings for string;

    function removeFromStrings(string[] storage arr, string memory _str) internal returns (bool) {
        uint256 last = arr.length - 1;
        for (uint256 i = 0; i <= last; i++) {
            if (arr[i].compareTo(_str)) {
                if (i < last) {
                    arr[i] = arr[last];
                }
                arr.pop();
                return true;
            }
        }
        return false;
    }

    function containsFromStrings(string[] memory arr, string memory _str) internal pure returns (bool) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i].compareTo(_str)) {
                return true;
            }
        }
        return false;
    }

    function removeFromAddresses(address[] storage arr, address _addr) internal {
        uint256 last = arr.length - 1;
        for (uint256 i = 0; i <= last; i++) {
            if (arr[i] == _addr) {
                if (i < last) {
                    arr[i] = arr[last];
                }
                arr.pop();
                break;
            }
        }
    }

    function containsFromAddresses(address[] memory arr, address _addr) internal pure returns (bool) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == _addr) {
                return true;
            }
        }
        return false;
    }

    function removeFromUints(uint256[] storage arr, uint256 _value) internal returns (bool) {
        uint256 last = arr.length - 1;
        for (uint256 i = 0; i <= last; i++) {
            if (arr[i] == _value) {
                if (i < last) {
                    arr[i] = arr[last];
                }
                arr.pop();
                return true;
            }
        }
        return false;
    }

    function containsFromUints(uint256[] memory arr, uint256 _value) internal pure returns (bool) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == _value) {
                return true;
            }
        }
        return false;
    }

    function sumFromUints(uint256[] memory arr) internal pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < arr.length; i++) {
            sum += arr[i];
        }
        return sum;
    }
}