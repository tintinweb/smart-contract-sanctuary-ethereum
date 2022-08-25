// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "../interfaces/IGenericHandler.sol";
import "../interfaces/iRouterCrossTalk.sol";
import "../interfaces/iGBridge.sol";
import "../interfaces/IFeeManagerGeneric.sol";

/// @title Handles generic deposits and deposit executions.
/// @author Router Protocol
/// @notice This contract is intended to be used with the Bridge contract.
contract GenericHandlerUpgradeable is Initializable, AccessControlUpgradeable {
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    // ----------------------------------------------------------------- //
    //                        DS Section Starts                          //
    // ----------------------------------------------------------------- //

    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");

    iGBridge public bridge;

    iFeeManagerGeneric private feeManager;

    bytes32 private resourceID;

    mapping(uint8 => mapping(uint64 => DepositRecord)) private _depositRecords;

    mapping(uint8 => mapping(uint64 => ExecuteRecord)) private _executeRecords;

    struct ExecuteRecord {
        bool isExecuted;
        bool _status;
        bytes _callback;
    }

    struct DepositRecord {
        bytes32 _resourceID;
        uint8 _srcChainID;
        uint8 _destChainID;
        uint64 _nonce;
        address _srcAddress;
        address _destAddress;
        bytes4 _selector;
        bytes data;
        bytes32 hash;
        uint256 _gas;
        address _feeToken;
    }

    struct RouterLinker {
        address _rSyncContract;
        uint8 _chainID;
        address _linkedContract;
    }

    mapping(uint8 => uint256) private defaultGas;
    mapping(uint8 => uint256) private defaultGasPrice;
    mapping(uint8 => mapping(uint64 => FeeRecord)) private _feeRecord;

    struct FeeRecord {
        uint8 _destChainID;
        uint64 _nonce;
        address _feeToken;
        uint256 _gasLimit;
        uint256 _gasPrice;
        uint256 _feeAmount;
    }

    uint8 private _chainId;

    event ReplayEvent(
        uint8 indexed destinationChainID,
        bytes32 indexed resourceID,
        uint64 indexed depositNonce,
        uint256 widgetID
    );

    // ----------------------------------------------------------------- //
    //                        DS Section Ends                            //
    // ----------------------------------------------------------------- //

    // ----------------------------------------------------------------- //
    //                        Init Section Starts                        //
    // ----------------------------------------------------------------- //

    function __GenericHandlerUpgradeable_init(address _bridge, bytes32 _resourceID) internal initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(BRIDGE_ROLE, _bridge);
        _setupRole(FEE_SETTER_ROLE, msg.sender);

        bridge = iGBridge(_bridge);
        resourceID = _resourceID;
    }

    function __GenericHandlerUpgradeable_init_unchained() internal initializer {}

    function initialize(address _bridge, bytes32 _resourceID) external initializer {
        __GenericHandlerUpgradeable_init(_bridge, _resourceID);
    }

    // ----------------------------------------------------------------- //
    //                        Init Section Ends                          //
    // ----------------------------------------------------------------- //

    // ----------------------------------------------------------------- //
    //                        Mapping Section Starts                     //
    // ----------------------------------------------------------------- //

    /// @notice Function Maps the two contracts on cross chain enviroment
    /// @param linker Linker object to be verified
    function MapContract(RouterLinker calldata linker) external {
        iRouterCrossTalk crossTalk = iRouterCrossTalk(linker._rSyncContract);
        require(
            msg.sender == crossTalk.fetchLinkSetter(),
            "Router Generichandler : Only Link Setter can map contracts"
        );
        crossTalk.Link{ gas: 57786 }(linker._chainID, linker._linkedContract);
    }

    /// @notice Function UnMaps the two contracts on cross chain enviroment
    /// @param linker Linker object to be verified

    function UnMapContract(RouterLinker calldata linker) external {
        iRouterCrossTalk crossTalk = iRouterCrossTalk(linker._rSyncContract);
        require(
            msg.sender == crossTalk.fetchLinkSetter(),
            "Router Generichandler : Only Link Setter can unmap contracts"
        );
        crossTalk.Unlink{ gas: 35035 }(linker._chainID);
    }

    // ----------------------------------------------------------------- //
    //                        Mapping Section Ends                       //
    // ----------------------------------------------------------------- //

    // ----------------------------------------------------------------- //
    //                        Deposit Section Starts                     //
    // ----------------------------------------------------------------- //

    /// @notice Function fired to fetch chain ID from bridge
    /// @return chainId for this chain
    function fetch_chainID() external view returns (uint8) {
        return _chainId;
    }

    /// @notice Function fired to trigger Cross Chain Communication
    /// @param  _destChainID Destination ChainID
    /// @param  _data Data for the cross chain function.
    /// @param  _gasLimit Gas Limit allowed for the transaction.
    /// @param  _gasPrice Gas Price for the transaction.
    /// @param  _feeToken Fee Token for the transaction.
    function genericDeposit(
        uint8 _destChainID,
        bytes calldata _data,
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _feeToken
    ) external returns (uint64) {
        require(defaultGas[_destChainID] != 0, "Router Generichandler : Destination Gas Not Set");
        require(defaultGasPrice[_destChainID] != 0, "Router Generichandler : Destination Gas Price Not Set");

        uint64 _nonce = bridge.genericDeposit(_destChainID, resourceID);
        iRouterCrossTalk crossTalk = iRouterCrossTalk(msg.sender);
        address destAddress = crossTalk.fetchLink(_destChainID);

        uint256 gasLimit = _gasLimit < defaultGas[_destChainID] ? defaultGas[_destChainID] : _gasLimit;
        uint256 gasPrice = _gasPrice < defaultGasPrice[_destChainID] ? defaultGasPrice[_destChainID] : _gasPrice;

        bytes4 _selector = abi.decode(_data, (bytes4));

        _genericDeposit(_nonce, _destChainID, _selector, _data, gasLimit, gasPrice, _feeToken, destAddress);
        return _nonce;
    }

    /// @notice Function fired to trigger Cross Chain Communication.
    /// @param  _nonce Nonce for the deposit.
    /// @param  _destChainID Destination ChainID.
    /// @param  _selector Selector for the cross chain function.
    /// @param  _data Data for the cross chain function.
    /// @param  _gasLimit Gas Limit allowed for the transaction.
    /// @param  _gasPrice Gas Price for the transaction.
    /// @param  _feeToken Fee Token for the transaction.
    /// @param  _destAddress Address of crosstalk on destination chain.
    function _genericDeposit(
        uint64 _nonce,
        uint8 _destChainID,
        bytes4 _selector,
        bytes calldata _data,
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _feeToken,
        address _destAddress
    ) internal {
        uint256 fees = deductFee(_destChainID, _feeToken, _gasLimit, _gasPrice, false);
        bytes32 hash = keccak256(abi.encode(_destChainID, _nonce));

        _depositRecords[_destChainID][_nonce] = DepositRecord(
            resourceID,
            _chainId,
            _destChainID,
            _nonce,
            msg.sender,
            _destAddress,
            _selector,
            _data,
            hash,
            _gasLimit,
            _feeToken
        );

        _feeRecord[_destChainID][_nonce] = FeeRecord(_destChainID, _nonce, _feeToken, _gasLimit, _gasPrice, fees);
    }

    /// @notice Function to replay a transaction which was stuck due to underpricing of gas
    /// @param  _destChainID Destination ChainID
    /// @param  _depositNonce Nonce for the transaction.
    /// @param  _gasLimit Gas limit allowed for the transaction.
    /// @param  _gasPrice Gas Price for the transaction.
    function replayGenericDeposit(
        uint8 _destChainID,
        uint64 _depositNonce,
        uint256 _gasLimit,
        uint256 _gasPrice
    ) external {
        require(defaultGas[_destChainID] != 0, "Router Generichandler : Destination Gas Not Set");
        require(defaultGasPrice[_destChainID] != 0, "Router Generichandler : Destination Gas Price Not Set");

        DepositRecord storage record = _depositRecords[_destChainID][_depositNonce];
        require(record._feeToken != address(0), "GenericHandler: Record not found");
        require(record._srcAddress == msg.sender, "GenericHandler: Unauthorized transaction");

        uint256 gasLimit = _gasLimit < defaultGas[_destChainID] ? defaultGas[_destChainID] : _gasLimit;
        uint256 gasPrice = _gasPrice < defaultGasPrice[_destChainID] ? defaultGasPrice[_destChainID] : _gasPrice;

        uint256 fee = deductFee(_destChainID, record._feeToken, gasLimit, gasPrice, true);

        _feeRecord[_destChainID][_depositNonce]._gasLimit = gasLimit;
        _feeRecord[_destChainID][_depositNonce]._gasPrice = gasPrice;
        _feeRecord[_destChainID][_depositNonce]._feeAmount += fee;

        emit ReplayEvent(_destChainID, resourceID, record._nonce, 0);
    }

    /// @notice Function fetches deposit record
    /// @param  _ChainID CHainID of the deposit
    /// @param  _nonce Nonce of the deposit
    /// @return DepositRecord
    function fetchDepositRecord(uint8 _ChainID, uint64 _nonce) external view returns (DepositRecord memory) {
        return _depositRecords[_ChainID][_nonce];
    }

    /// @notice Function fetches fee record
    /// @param  _ChainID Destination ChainID of the deposit
    /// @param  _nonce Nonce of the deposit
    /// @return feeRecord
    function fetchFeeRecord(uint8 _ChainID, uint64 _nonce) external view returns (FeeRecord memory) {
        return _feeRecord[_ChainID][_nonce];
    }

    /// @notice Function fetches execute record
    /// @param  _ChainID CHainID of the deposit
    /// @param  _nonce Nonce of the deposit
    /// @return ExecuteRecord
    function fetchExecuteRecord(uint8 _ChainID, uint64 _nonce) external view returns (ExecuteRecord memory) {
        return _executeRecords[_ChainID][_nonce];
    }

    /// @notice Function fetches resourceId
    function fetchResourceID() external view returns (bytes32) {
        return resourceID;
    }

    // ----------------------------------------------------------------- //
    //                        Deposit Section Ends                       //
    // ----------------------------------------------------------------- //

    // ----------------------------------------------------------------- //
    //                        Execute Section Starts                     //
    // ----------------------------------------------------------------- //

    /// @notice Function Executes a cross Chain Request on destination chain and can only be triggered by bridge
    /// @dev Can only be called by the bridge
    /// @param  _data Cross chain Data recived from relayer
    /// @return true
    function executeProposal(bytes calldata _data) external onlyRole(BRIDGE_ROLE) returns (bool) {
        DepositRecord memory depositData = decodeData(_data);
        require(
            _executeRecords[depositData._srcChainID][depositData._nonce].isExecuted == false,
            "GenericHandler: Already executed"
        );
        if (!depositData._destAddress.isContract()) {
            _executeRecords[depositData._srcChainID][depositData._nonce]._callback = "";
            _executeRecords[depositData._srcChainID][depositData._nonce]._status = false;
            _executeRecords[depositData._srcChainID][depositData._nonce].isExecuted = true;
            return true;
        }
        (bool success, bytes memory callback) = depositData._destAddress.call(
            abi.encodeWithSelector(
                0x06d07c59, // routerSync(uint8,address,bytes)
                depositData._srcChainID,
                depositData._srcAddress,
                depositData.data
            )
        );
        _executeRecords[depositData._srcChainID][depositData._nonce]._callback = callback;
        _executeRecords[depositData._srcChainID][depositData._nonce]._status = success;
        _executeRecords[depositData._srcChainID][depositData._nonce].isExecuted = true;
        return true;
    }

    /// @notice Function Decodes the data element recived from bridge
    /// @param  _data Cross chain Data recived from relayer
    /// @return DepositRecord
    function decodeData(bytes calldata _data) internal pure returns (DepositRecord memory) {
        DepositRecord memory depositData;
        (
            depositData._srcChainID,
            depositData._nonce,
            depositData._srcAddress,
            depositData._destAddress,
            depositData.data
        ) = abi.decode(_data, (uint8, uint64, address, address, bytes));

        return depositData;
    }

    // ----------------------------------------------------------------- //
    //                        Execute Section Ends                       //
    // ----------------------------------------------------------------- //

    // ----------------------------------------------------------------- //
    //                    Fee Manager Section Starts                     //
    // ----------------------------------------------------------------- //

    /// @notice Function fetches fee manager address
    /// @return feeManager
    function fetchFeeManager() external view returns (address) {
        return address(feeManager);
    }

    /// @notice Function sets fee manager address
    /// @dev can only be called by default admin address
    /// @param  _feeManager Address of the fee manager.
    function setFeeManager(address _feeManager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        feeManager = iFeeManagerGeneric(_feeManager);
    }

    /**
        @notice Function Fetches the default Gas for a chain ID .
    **/
    function fetchDefaultGas(uint8 _chainID) external view returns (uint256) {
        return defaultGas[_chainID];
    }

    /**
        @notice Function Sets default gas fees for chain.
        @param _chainID ChainID of the .
        @param _defaultGas Default gas for a chainid.
    **/
    function setDefaultGas(uint8 _chainID, uint256 _defaultGas) public onlyRole(DEFAULT_ADMIN_ROLE) {
        defaultGas[_chainID] = _defaultGas;
    }

    /**
        @notice Function Fetches the default Gas Price for a chain ID .
    **/
    function fetchDefaultGasPrice(uint8 _chainID) external view returns (uint256) {
        return defaultGasPrice[_chainID];
    }

    /**
        @notice Function Sets default gas price for chain.
        @param _chainID ChainID of the .
        @param _defaultGasPrice Default gas for a chainid.
    **/
    function setDefaultGasPrice(uint8 _chainID, uint256 _defaultGasPrice) public onlyRole(DEFAULT_ADMIN_ROLE) {
        defaultGasPrice[_chainID] = _defaultGasPrice;
    }

    /**
        @notice Function Sets chainId for chain.
        @param chainId ChainID of the .
    **/
    function setChainId(uint8 chainId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _chainId = chainId;
    }

    /// @notice Function Sets the fee for a fee token on to feemanager
    /// @dev Can only be called by fee setter.
    /// @param destinationChainID ID of the destination chain.
    /// @param feeTokenAddress Address of fee token.
    /// @param feeFactor FeeFactor for the cross chain call.
    /// @param bridgeFee Base Fee for bridge.
    /// @param accepted Bool value for enabling and disabling feetoken.
    function setFees(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 feeFactor,
        uint256 bridgeFee,
        bool accepted
    ) external onlyRole(FEE_SETTER_ROLE) {
        feeManager.setFee(destinationChainID, feeTokenAddress, feeFactor, bridgeFee, accepted);
    }

    /// @notice Calculates fees for a cross chain Call.
    /// @param destinationChainID id of the destination chain.
    /// @param feeTokenAddress Address fee token.
    /// @param gasLimit Gas limit required for cross chain call.
    /// @param gasPrice Gas Price for the transaction.
    /// @return total fees
    function calculateFees(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 gasLimit,
        uint256 gasPrice
    ) external view returns (uint256) {
        require(defaultGas[destinationChainID] != 0, "GenericHandler : Destination Gas Not Set");
        require(defaultGasPrice[destinationChainID] != 0, "GenericHandler : Destination Gas Price Not Set");

        uint8 feeTokenDecimals = IERC20MetadataUpgradeable(feeTokenAddress).decimals();
        uint256 _gasLimit = gasLimit < defaultGas[destinationChainID] ? defaultGas[destinationChainID] : gasLimit;
        uint256 _gasPrice = gasPrice < defaultGasPrice[destinationChainID]
            ? defaultGasPrice[destinationChainID]
            : gasPrice;

        (uint256 feeFactorX10e6, uint256 bridgeFees) = feeManager.getFee(destinationChainID, feeTokenAddress);

        if (feeTokenDecimals < 18) {
            uint8 decimalsToDivide = 18 - feeTokenDecimals;
            return bridgeFees + (feeFactorX10e6 * _gasPrice * _gasLimit) / (10**(decimalsToDivide + 6));
        }

        return (feeFactorX10e6 * _gasLimit * _gasPrice)/(10**6) + bridgeFees;
    }

    /// @notice Function deducts fees for a cross chain Call.
    /// @param destinationChainID id of the destination chain.
    /// @param feeTokenAddress Address fee token.
    /// @param gasLimit Gas limit required for cross chain call.
    /// @param gasPrice Gas Price for the transaction.
    /// @param isReplay True if it is a replay tx.
    /// @return totalFees
    function deductFee(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 gasLimit,
        uint256 gasPrice,
        bool isReplay
    ) internal returns (uint256) {
        uint8 feeTokenDecimals = IERC20MetadataUpgradeable(feeTokenAddress).decimals();

        (uint256 feeFactorX10e6, uint256 bridgeFees) = feeManager.getFee(destinationChainID, feeTokenAddress);

        if (isReplay) {
            bridgeFees = 0;
        }

        IERC20Upgradeable token = IERC20Upgradeable(feeTokenAddress);
        uint256 fees;

        if (feeTokenDecimals < 18) {
            uint8 decimalsToDivide = 18 - feeTokenDecimals;
            fees = bridgeFees + (feeFactorX10e6 * gasPrice * gasLimit) / (10**(decimalsToDivide + 6));
        } else {
            fees = (feeFactorX10e6 * gasLimit * gasPrice)/(10**6) + bridgeFees;
        }

        token.safeTransferFrom(msg.sender, address(feeManager), fees);
        return fees;
    }

    /// @notice Used to manually release ERC20 tokens from FeeManager.
    /// @dev Can only be called by default admin
    /// @param tokenAddress Address of token contract to release.
    /// @param recipient Address to release tokens to.
    /// @param amount The amount of ERC20 tokens to release.
    function withdrawFees(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        feeManager.withdrawFee(tokenAddress, recipient, amount);
    }

    /// @notice Function to set the bridge address
    /// @dev Can only be called by default admin
    /// @param _bridge Address of the bridge
    function setBridge(address _bridge) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bridge = iGBridge(_bridge);
    }

    // ----------------------------------------------------------------- //
    //                    Fee Manager Section Ends                       //
    // ----------------------------------------------------------------- //
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/// @title Interface for handler that handles generic deposits and deposit executions.
/// @author Router Protocol.
interface IGenericHandler {
    function genericDeposit(
        uint8 _destChainID,
        bytes4 _selector,
        bytes calldata _data,
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _feeToken
    ) external returns (uint64);

    function executeProposal(bytes calldata data) external;

    /// @notice Function to replay a transaction which was stuck due to underpricing of gas
    /// @param  _destChainID Destination ChainID
    /// @param  _depositNonce Nonce for the transaction.
    /// @param  _gasLimit Gas limit allowed for the transaction.
    /// @param  _gasPrice Gas Price for the transaction.
    function replayGenericDeposit(
        uint8 _destChainID,
        uint64 _depositNonce,
        uint256 _gasLimit,
        uint256 _gasPrice
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface iRouterCrossTalk {

    event Linkevent( uint8 indexed ChainID , address indexed linkedContract );

    event Unlinkevent( uint8 indexed ChainID , address indexed linkedContract );

    event CrossTalkSend(uint8 indexed sourceChain , uint8 indexed destChain , address sourceAddress , address destinationAddress ,bytes4 indexed _interface, bytes _data , bytes32 _hash );

    event CrossTalkReceive(uint8 indexed sourceChain , uint8 indexed destChain , address sourceAddress , address destinationAddress ,bytes4 indexed _interface, bytes _data , bytes32 _hash );

    function routerSync(uint8 srcChainID , address srcAddress , bytes4 _interface , bytes calldata _data , bytes32 hash ) external returns ( bool , bytes memory );

    function Link(uint8 _chainID , address _linkedContract) external;

    function Unlink(uint8 _chainID ) external;

    function fetchLinkSetter( ) external view returns( address);

    function fetchLink( uint8 _chainID ) external view returns( address);

    function fetchBridge( ) external view returns ( address );

    function fetchHandler( ) external view returns ( address );

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface iGBridge{

    function genericDeposit( uint8 _destChainID, bytes32 _resourceID ) external returns ( uint64 );

    function fetch_chainID( ) external view returns ( uint8 );

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

interface iFeeManagerGeneric {

    function withdrawFee(address tokenAddress, address recipient, uint256 amount) external;

    function setFee(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 feeFactor,
        uint256 bridgeFee,
        bool accepted
    ) external;

    function getFee(uint8 destinationChainID, address feeTokenAddress) external view returns (uint256 , uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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