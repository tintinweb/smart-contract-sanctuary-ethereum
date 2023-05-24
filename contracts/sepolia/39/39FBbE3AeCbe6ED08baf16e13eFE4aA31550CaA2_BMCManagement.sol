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

import "./interfaces/IBMCManagement.sol";
import "./interfaces/IOwnerManager.sol";
import "./interfaces/ICCManagement.sol";
import "./interfaces/IBMCPeriphery.sol";
import "./interfaces/ICCPeriphery.sol";
import "./interfaces/ICCService.sol";
import "./libraries/Types.sol";
import "./libraries/Errors.sol";
import "./libraries/BTPAddress.sol";
import "./libraries/Strings.sol";
import "./libraries/RLPEncodeStruct.sol";
import "./libraries/Utils.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract BMCManagement is IBMCManagement, IOwnerManager, ICCManagement, Initializable {
    using BTPAddress for string;
    using Strings for string;
    using RLPEncodeStruct for Types.BMCMessage;
    using RLPEncodeStruct for Types.ResponseMessage;
    using RLPEncodeStruct for string[];
    using RLPEncodeStruct for string;
    using Utils for string[];
    using Utils for address[];
    using Utils for uint256[];

    mapping(address => bool) private _owners;
    uint256 private numOfOwner;

    mapping(string => address) private bmvMap;//net of bmv => address of BMV
    mapping(string => address) private bshMap;//svc of bsh => address of BSH
    mapping(string => Types.Link) private linkMap; //link => net of link
    mapping(string => address[]) private relayMap; //link => list of address of relay
    mapping(string => Types.RouteInfo) private routeInfoMap;//net of destination => RouteInfo
    mapping(string => uint256[]) private feeMap;//net of destination => list of fee
    string[] private bmvKeyList;//list of net of bmv
    string[] private bshKeyList;//list of svc of bsh
    string[] private linkList;//list of link
    string[] private routeInfoList; //list of destination of routeInfoMap
    address private feeHandler;
    address private bmcPeriphery;
    address private bmcService;

    function requireOwnerAccess(
    ) internal view {
        require(_owners[msg.sender] == true, Errors.BMC_REVERT_UNAUTHORIZED);
    }

    function requireValidAddress(
        address addr
    ) internal pure {
        require(addr != address(0), Errors.BMC_REVERT_INVALID_ARGUMENT);
    }

    function initialize(
    ) public initializer {
        _owners[msg.sender] = true;
        numOfOwner++;
    }

    /**
       @notice Update BMC periphery.
       @dev Caller must be an Owner of BTP network
       @param _addr    Address of a new periphery.
     */
    function setBMCPeriphery(
        address _addr
    ) external {
        requireOwnerAccess();
        requireValidAddress(_addr);
        bmcPeriphery = _addr;
    }

    /**
       @notice Get address of BMC periphery.
       @return address of BMC periphery
     */
    function getBMCPeriphery(
    ) external view returns (
        address
    ) {
        return bmcPeriphery;
    }

    /**
       @notice Update BMC periphery.
       @dev Caller must be an Owner of BTP network
       @param _addr    Address of a new periphery.
     */
    function setBMCService(
        address _addr
    ) external {
        requireOwnerAccess();
        requireValidAddress(_addr);
        bmcService = _addr;
    }

    /**
       @notice Get address of BMC periphery.
       @return address of BMC periphery
     */
    function getBMCService(
    ) external view returns (
        address
    ) {
        return bmcService;
    }

    /*****************************************************************************************
                                        Add Authorized Owner of Contract
        - addOwner(): register additional Owner of this Contract
        - removeOwner(): un-register existing Owner of this Contract. Unable to remove last
        - isOwner(): checking Ownership of an arbitrary address
    *****************************************************************************************/

    function addOwner(
        address _owner
    ) external override {
        requireOwnerAccess();
        requireValidAddress(_owner);
        require(_owners[_owner] == false, Errors.BMC_REVERT_ALREADY_EXISTS_OWNER);
        _owners[_owner] = true;
        numOfOwner++;
    }

    function removeOwner(
        address _owner
    ) external override {
        requireOwnerAccess();
        require(_owners[_owner] == true, Errors.BMC_REVERT_NOT_EXISTS_OWNER);
        require(numOfOwner > 1, Errors.BMC_REVERT_LAST_OWNER);
        delete _owners[_owner];
        numOfOwner--;
    }

    function isOwner(
        address _owner
    ) external view override returns (bool) {
        return _owners[_owner];
    }

    function addService(
        string memory _svc,
        address _addr
    ) external override {
        requireOwnerAccess();
        requireValidAddress(_addr);
        //TODO require(_svc.isAlphaNumeric && _svc != Types.BMC_SERVICE)
        require(!existsService(_svc), Errors.BMC_REVERT_ALREADY_EXISTS_BSH);

        bshMap[_svc] = _addr;
        bshKeyList.push(_svc);
    }

    function removeService(
        string memory _svc
    ) external override {
        requireOwnerAccess();
        requireService(_svc);
        delete bshMap[_svc];
        bshKeyList.removeFromStrings(_svc);
    }

    function getServices(
    ) external view override returns (
        Types.Service[] memory
    ){
        Types.Service[] memory services = new Types.Service[](bshKeyList.length);
        for (uint256 i = 0; i < bshKeyList.length; i++) {
            services[i] = Types.Service(
                bshKeyList[i],
                bshMap[bshKeyList[i]]
            );
        }
        return services;
    }

    function addVerifier(
        string memory _net,
        address _addr
    ) external override {
        requireOwnerAccess();
        requireValidAddress(_addr);
        require(!existsVerifier(_net), Errors.BMC_REVERT_ALREADY_EXISTS_BMV);
        bmvMap[_net] = _addr;
        bmvKeyList.push(_net);
    }

    function removeVerifier(
        string memory _net
    ) external override {
        requireOwnerAccess();
        requireVerifier(_net);
        delete bmvMap[_net];
        bmvKeyList.removeFromStrings(_net);
    }

    function getVerifiers(
    ) external view override returns (
        Types.Verifier[] memory
    ){
        Types.Verifier[] memory verifiers = new Types.Verifier[](bmvKeyList.length);
        for (uint256 i = 0; i < bmvKeyList.length; i++) {
            verifiers[i] = Types.Verifier(
                bmvKeyList[i],
                bmvMap[bmvKeyList[i]]
            );
        }
        return verifiers;
    }

    function addLink(
        string calldata _link
    ) external override {
        requireOwnerAccess();
        string memory net = _link.networkAddress();
        require(!existsLink(net), Errors.BMC_REVERT_ALREADY_EXISTS_LINK);
        requireVerifier(net);

        propagateInternal(
            Types.BMCMessage(Types.BMC_INTERNAL_LINK, _link.encodePropagateMessage())
            .encodeBMCMessage());
        bytes memory initMsg = Types.BMCMessage(
            Types.BMC_INTERNAL_INIT, linkList.encodeInitMessage()
        ).encodeBMCMessage();

        linkMap[_link] = Types.Link(_link, new string[](0));
        linkList.push(_link);
        _addRouteInfo(net, _link, Types.ROUTE_TYPE_LINK);

        sendInternal(_link, initMsg);
    }

    function removeLink(
        string calldata _link
    ) external override {
        requireOwnerAccess();
        requireLink(_link);
        for (uint256 i = 0; i < routeInfoList.length; i++) {
            if (routeInfoMap[routeInfoList[i]].routeType == Types.ROUTE_TYPE_MANUAL &&
                routeInfoMap[routeInfoList[i]].next.compareTo(_link)) {
                revert(Errors.BMC_REVERT_REFERRED_BY_ROUTE);
            }
        }

        _removeRouteInfo(_link.networkAddress(), false, "");

        //remove linkList before _removeRouteInfo(reachable)
        //linkList referred by _resolveNextInReachable in _removeRouteInfo
        linkList.removeFromStrings(_link);

        for (uint256 i = 0; i < linkMap[_link].reachable.length; i++) {
            _removeRouteInfo(linkMap[_link].reachable[i].networkAddress(), true, _link);
        }

        delete linkMap[_link];

        ICCPeriphery(bmcPeriphery).clearSeq(_link);
        delete relayMap[_link];

        propagateInternal(
            Types.BMCMessage(Types.BMC_INTERNAL_UNLINK, _link.encodePropagateMessage())
            .encodeBMCMessage());
    }

    function getLinks(
    ) external view override returns (
        string[] memory
    ) {
        return linkList;
    }

    function propagateInternal(
        bytes memory _msg
    ) private {
        for (uint256 i = 0; i < linkList.length; i++) {
            sendInternal(linkList[i], _msg);
        }
    }

    function sendInternal(
        string memory link,
        bytes memory _msg
    ) private {
        ICCPeriphery(bmcPeriphery).sendInternal(link, _msg);
    }

    function addRelay(
        string memory _link,
        address _addr
    ) external override {
        requireOwnerAccess();
        requireValidAddress(_addr);
        requireLink(_link);
        require(!relayMap[_link].containsFromAddresses(_addr), Errors.BMC_REVERT_ALREADY_EXISTS_BMR);
        relayMap[_link].push(_addr);
    }

    function removeRelay(
        string memory _link,
        address _addr
    ) external override {
        requireOwnerAccess();
        requireLink(_link);
        require(relayMap[_link].containsFromAddresses(_addr), Errors.BMC_REVERT_NOT_EXISTS_BMR);

        //@Notice the order may be changed after remove
        //  arr[index of remove]=arr[last index]
        relayMap[_link].removeFromAddresses(_addr);
    }

    function getRelays(
        string memory _link
    ) external view override returns (
        address[] memory
    ){
        requireLink(_link);
        return relayMap[_link];
    }

    function _addRouteInfo(
        string memory _dst,
        string memory _link,
        uint256 routeType
    ) internal {
        if(routeInfoMap[_dst].routeType == Types.ROUTE_TYPE_NONE) {
            routeInfoMap[_dst] = Types.RouteInfo(_dst, _link, 0, routeType);
            routeInfoList.push(_dst);
        }
        if (routeType == Types.ROUTE_TYPE_REACHABLE) {
            routeInfoMap[_dst].reachable++;
        } else if (routeType == Types.ROUTE_TYPE_MANUAL) {
            routeInfoMap[_dst].routeType = Types.ROUTE_TYPE_MANUAL;
            routeInfoMap[_dst].next = _link;
        }
    }

    function addRoute(
        string memory _dst,
        string memory _link
    ) external override {
        requireOwnerAccess();
        require(!_dst.compareTo(_link), Errors.BMC_REVERT_INVALID_ARGUMENT);
        require(routeInfoMap[_dst].routeType != Types.ROUTE_TYPE_MANUAL, Errors.BMC_REVERT_ALREADY_EXISTS_ROUTE);
        require(existsLink(_link), Errors.BMC_REVERT_NOT_EXISTS_LINK);

        _addRouteInfo(_dst, routeInfoMap[_link].next, Types.ROUTE_TYPE_MANUAL);
        //ignore shortest-path check
        //case : _link is not connected with _dst (3 hop) and other link connected with _dst (2 hop)
    }

    function _resolveNextInReachable(
        string memory _dst
    ) internal view returns (
        string memory
    ) {
        for(uint256 i = 0; i < linkList.length; i++) {
            for(uint256 j = 0; j < linkMap[linkList[i]].reachable.length; j++) {
                if (linkMap[linkList[i]].reachable[j].networkAddress().compareTo(_dst)) {
                    return linkList[i];
                }
            }
        }
        revert(Errors.BMC_REVERT_UNREACHABLE);
    }

    function _removeRouteInfo(
        string memory _dst,
        bool reachable,
        string memory _link
    ) internal {
        if (reachable) {
            routeInfoMap[_dst].reachable--;
        }
        if (routeInfoMap[_dst].reachable > 0) {
            if (!reachable || routeInfoMap[_dst].next.compareTo(_link)) {
                routeInfoMap[_dst].next = _resolveNextInReachable(_dst);
            }
            if (!reachable) {//call by removeRoute
                routeInfoMap[_dst].routeType = Types.ROUTE_TYPE_REACHABLE;
            }
        } else {
            routeInfoList.removeFromStrings(_dst);
            delete routeInfoMap[_dst];
            _removeFee(_dst);
        }
    }

    function removeRoute(
        string memory _dst
    ) external override {
        requireOwnerAccess();
        require(routeInfoMap[_dst].routeType == Types.ROUTE_TYPE_MANUAL, Errors.BMC_REVERT_NOT_EXISTS_ROUTE);
        _removeRouteInfo(_dst, false, "");
    }

    function getRoutes(
    ) external view override returns (
        Types.Route[] memory
    ){
        Types.Route[] memory _routes = new Types.Route[](routeInfoList.length);
        for (uint256 i = 0; i < routeInfoList.length; i++) {
            _routes[i] = Types.Route(routeInfoList[i],
                routeInfoMap[routeInfoList[i]].next.networkAddress());
        }
        return _routes;
    }

    function _removeFee(
        string memory dst
    ) internal {
        if (feeMap[dst].length > 0) {
            delete feeMap[dst];
        }
    }

    function setFeeTable(
        string[] memory _dst,
        uint256[][] memory _value
    ) external override {
        requireOwnerAccess();
        require(_dst.length == _value.length, Errors.BMC_REVERT_INVALID_ARGUMENT);
        for (uint256 i = 0; i < _dst.length; i++) {
            if (_value[i].length > 0) {
                require(_value[i].length % 2 == 0, Errors.BMC_REVERT_LENGTH_MUST_BE_EVEN);
                for (uint256 j = 0; j < _value[i].length; j++) {
                    require(_value[i][j] >= 0, Errors.BMC_REVERT_MUST_BE_POSITIVE);
                }
                if (_value[i].length == 2) {
                    require(existsLink(_dst[i]), Errors.BMC_REVERT_NOT_EXISTS_LINK);
                } else {
                    _resolveNext(_dst[i]);
                }
                feeMap[_dst[i]] = _value[i];
            } else {
                _removeFee(_dst[i]);
            }
        }
    }

    function getFeeTable(
        string[] calldata _dst
    ) external view override returns (
        uint256[][] memory _feeTable
    ) {
        uint256[][] memory ret = new uint256[][](_dst.length);
        for (uint256 i = 0; i < _dst.length; i++) {
            _resolveNext(_dst[i]);
            if (feeMap[_dst[i]].length > 0) {
                ret[i] = feeMap[_dst[i]];
            }
        }
        return ret;
    }

    function getFee(
        string calldata _to,
        bool _response
    ) external view override returns (
        uint256,
        uint256[] memory
    ) {
        uint256 len = feeMap[_to].length;
        if (!_response) {
            len = len / 2;
        }
        uint256 sum = 0;
        uint256[] memory values = new uint256[](len);
        if (len > 0) {
            for (uint256 i = 0; i < len; i++) {
                values[i] = feeMap[_to][i];
                sum += values[i];
            }
        }
        return (sum, values);
    }

    function setFeeHandler(
        address _addr
    ) external override {
        requireOwnerAccess();
        feeHandler = _addr;
    }

    function getFeeHandler(
    ) external view override returns (
        address
    ) {
        return feeHandler;
    }

    function dropMessage(
        string calldata _src,
        uint256 _seq,
        string calldata _svc,
        int256 _sn,
        int256 _nsn,
        string calldata  _feeNetwork,
        uint256[] memory _feeValues
    ) external override {
        requireOwnerAccess();
        string memory next = _resolveNext(_src);
        requireService(_svc);
        require(!((_nsn == 0) || (_nsn > 0 && _sn < 0) || (_nsn < 0 && _sn > 0)),
            Errors.BMC_REVERT_INVALID_SN);

        Types.BTPMessage memory btpMsg = Types.BTPMessage(
            _src,
            "",
            _svc,
            _sn,
            new bytes(0),
            _nsn,
            ICCService(bmcService).handleDropFee(_feeNetwork, _feeValues)
        );
        ICCPeriphery(bmcPeriphery).dropMessage(
            next,
            _seq,
            btpMsg
        );
    }

    function requireService(
        string memory _svc
    ) internal view {
        require(existsService(_svc), Errors.BMC_REVERT_NOT_EXISTS_BSH);
    }

    function existsService(
        string memory _svc
    ) internal view returns (
        bool
    ) {
        return bshMap[_svc] != address(0);
    }

    function getService(
        string memory _svc
    ) external view override returns (
        address
    ){
        requireService(_svc);
        return bshMap[_svc];
    }

    function requireVerifier(
        string memory _net
    ) internal view {
        require(existsVerifier(_net), Errors.BMC_REVERT_NOT_EXISTS_BMV);
    }

    function existsVerifier(
        string memory _net
    ) internal view returns (
        bool
    ){
        return bmvMap[_net] != address(0);
    }

    function getVerifier(
        string memory _net
    ) external view override returns (
        address
    ){
        requireVerifier(_net);
        return bmvMap[_net];
    }

    function requireLink(
        string memory _link
    ) internal view {
        require(bytes(linkMap[_link].btpAddress).length > 0, Errors.BMC_REVERT_NOT_EXISTS_LINK);
    }

    function existsLink(
        string memory net
    ) internal view returns (bool) {
        return routeInfoMap[net].routeType == Types.ROUTE_TYPE_LINK;
    }

    function isLinkRelay(
        string calldata _link,
        address _addr
    ) external view override returns (
        bool
    ){
        requireLink(_link);
        return relayMap[_link].containsFromAddresses(_addr);
    }

    function _resolveNext(
        string memory _dst
    ) internal view returns (
        string memory
    ){
        if (routeInfoMap[_dst].routeType != Types.ROUTE_TYPE_NONE) {
            return routeInfoMap[_dst].next;
        }
        revert(Errors.BMC_REVERT_UNREACHABLE);
    }

    function resolveNext(
        string memory _dst
    ) external view override returns (
        string memory
    ){
        return _resolveNext(_dst);
    }

    function addReachable(
        string memory _from,
        string memory _reachable
    ) external override {
        require(msg.sender == bmcService, Errors.BMC_REVERT_UNAUTHORIZED);
        linkMap[routeInfoMap[_from].next].reachable.push(_reachable);
        _addRouteInfo(_reachable.networkAddress(), routeInfoMap[_from].next, Types.ROUTE_TYPE_REACHABLE);
    }

    function removeReachable(
        string memory _from,
        string memory _reachable
    ) external override {
        require(msg.sender == bmcService, Errors.BMC_REVERT_UNAUTHORIZED);
        linkMap[routeInfoMap[_from].next].reachable.removeFromStrings(_reachable);
        _removeRouteInfo(_reachable.networkAddress(), true, routeInfoMap[_from].next);
    }

    function getHop(
        string memory _dst
    ) external view override returns (
        uint256
    ) {
        return feeMap[_dst].length/2;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import "../libraries/Types.sol";

interface IBMCManagement {
    /**
       @notice Add the smart contract for the service.
       @dev Caller must be an operator of BTP network.
       @param _svc     Name of the service
       @param _addr    Service's contract address
     */
    function addService(
        string memory _svc,
        address _addr
    ) external;

    /**
       @notice De-registers the smart contract for the service.
       @dev Caller must be an operator of BTP network.
       @param _svc     Name of the service
     */
    function removeService(
        string calldata _svc
    ) external;

    /**
       @notice Get registered services.
       @return _servicers   An array of Service.
     */
    function getServices(
    ) external view returns (
        Types.Service[] memory _servicers
    );

    /**
       @notice Registers BMV for the network.
       @dev Caller must be an operator of BTP network.
       @param _net     Network Address of the blockchain
       @param _addr    Address of BMV
     */
    function addVerifier(
        string calldata _net,
        address _addr
    ) external;

    /**
       @notice De-registers BMV for the network.
       @dev Caller must be an operator of BTP network.
       @param _net     Network Address of the blockchain
     */
    function removeVerifier(
        string calldata _net
    ) external;

    /**
       @notice Get registered verifiers.
       @return _verifiers   An array of Verifier.
     */
    function getVerifiers(
    ) external view returns (
        Types.Verifier[] memory _verifiers
    );

    /**
       @notice Initializes status information for the link.
       @dev Caller must be an operator of BTP network.
       @param _link    BTP Address of connected BMC
     */
    function addLink(
        string calldata _link
    ) external;

    /**
       @notice Removes the link and status information.
       @dev Caller must be an operator of BTP network.
       @param _link    BTP Address of connected BMC
     */
    function removeLink(
        string calldata _link
    ) external;

    /**
       @notice Get registered links.
       @return _links   An array of links ( BTP Addresses of the BMCs ).
     */
    function getLinks(
    ) external view returns (
        string[] memory _links
    );

    /**
       @notice Registers relay for the network.
       @dev Caller must be an operator of BTP network.
       @param _link     BTP Address of connected BMC
       @param _addr     The address of relay
     */
    function addRelay(
        string calldata _link,
        address _addr
    ) external;

    /**
       @notice Unregisters Relay for the network.
       @dev Caller must be an operator of BTP network.
       @param _link     BTP Address of connected BMC
       @param _addr     The address of relay
     */
    function removeRelay(
        string calldata _link,
        address _addr
    ) external;

    /**
       @notice Get relays status by link.
       @param _link        BTP Address of the connected BMC.
       @return _relays list of address of relay
     */
    function getRelays(
        string calldata _link
    ) external view returns (
        address[] memory _relays
    );

    /**
       @notice Add route to the BMC.
       @dev Caller must be an operator of BTP network.
       @param _dst     Network Address of the destination BMC
       @param _link    Network Address of the next BMC for the destination
     */
    function addRoute(
        string calldata _dst,
        string calldata _link
    ) external;

    /**
       @notice Remove route to the BMC.
       @dev Caller must be an operator of BTP network.
       @param _dst     Network Address of the destination BMC
     */
    function removeRoute(
        string calldata _dst
    ) external;

    /**
       @notice Get routing information.
       @return _routes An array of Route.
     */
    function getRoutes(
    ) external view returns (
        Types.Route[] memory _routes
    );

    /**
       @notice Sets the fee table
       @dev Caller must be an operator of BTP network.
       @param _dst   String[] ( List of BTP Network Address of the destination BMC )
       @param _value Integer[][] ( List of lists of relay fees in the path including return path.
                     If it provides an empty relay fee list, then it removes the entry from the table. )
    */
    function setFeeTable(
        string[] memory _dst,
        uint256[][] memory _value
    ) external;

    /**
       @notice Gets the fee table
       @dev It reverts if the one of destination networks is not reachable.
            If there is no corresponding fee table, then it returns an empty list.
       @param  _dst      String[] ( List of BTP Network Address of the destination BMC )
       @return _feeTable Integer[][] ( List of lists of relay fees in the path including return path )
     */
    function getFeeTable(
        string[] calldata _dst
    ) external view returns (
        uint256[][] memory _feeTable
    );

    /**
       @notice Sets the address to handle the remaining reward fee.
       @dev Caller must be an operator of BTP network.
       @param _addr Address ( the address to handle the remaining reward fee )
    */
    function setFeeHandler(
        address _addr
    ) external;

    /**
       @notice Gets the address to handle the remaining reward fee.
       @return _addr Address ( the address to handle the remaining reward fee )
    */
    function getFeeHandler(
    ) external view returns (
        address _addr
    );

    /**
        @notice Drop the next message that to be relayed from a specific network
        @dev Called by the operator to manage the BTP network.
        @param _src  String ( Network Address of source BMC )
        @param _seq  Integer ( number of the message from connected BMC )
        @param _svc  String ( number of the message from connected BMC )
        @param _sn   Integer ( serial number of the message, must be positive )
        @param _nsn        Integer ( network serial number of the message )
        @param _feeNetwork String ( Network Address of the relay fee of the message )
        @param _feeValues  Integer[] ( list of relay fees of the message )
     */
    function dropMessage(
        string calldata _src,
        uint256 _seq,
        string calldata _svc,
        int256 _sn,
        int256 _nsn,
        string calldata  _feeNetwork,
        uint256[] memory _feeValues
    ) external;
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