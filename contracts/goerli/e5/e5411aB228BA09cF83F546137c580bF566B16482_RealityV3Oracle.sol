/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

pragma solidity 0.8.17;

// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

struct Template {
    address addrezz;
    uint128 version;
    uint256 id;
    string specification;
}


/// @title Base templates manager interface
/// @dev Interface for the base templates manager contract.
/// @author Federico Luzzi - <[email protected]>
interface IBaseTemplatesManager {
    function addTemplate(address _template, string calldata _specification)
        external;

    function removeTemplate(uint256 _id) external;

    function upgradeTemplate(
        uint256 _id,
        address _newTemplate,
        string calldata _newSpecification
    ) external;

    function updateTemplateSpecification(
        uint256 _id,
        string calldata _newSpecification
    ) external;

    function template(uint256 _id) external view returns (Template memory);

    function template(uint256 _id, uint128 _version)
        external
        view
        returns (Template memory);

    function exists(uint256 _id) external view returns (bool);

    function templatesAmount() external view returns (uint256);

    function enumerate(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        returns (Template[] memory);
}


/// @title Oracles manager interface
/// @dev Interface for the oracles manager contract.
/// @author Federico Luzzi - <[email protected]>
interface IOraclesManager1 is IBaseTemplatesManager {
    function predictInstanceAddress(
        address _creator,
        uint256 _id,
        bytes memory _initializationData
    ) external view returns (address);

    function instantiate(
        address _creator,
        uint256 _id,
        bytes memory _initializationData
    ) external payable returns (address);
}


/// @title Types
/// @dev General collection of reusable types.
/// @author Federico Luzzi - <[email protected]>

struct TokenAmount {
    address token;
    uint256 amount;
}

struct InitializeKPITokenParams {
    address creator;
    address oraclesManager;
    address kpiTokensManager;
    address feeReceiver;
    uint256 kpiTokenTemplateId;
    uint128 kpiTokenTemplateVersion;
    string description;
    uint256 expiration;
    bytes kpiTokenData;
    bytes oraclesData;
}

struct InitializeOracleParams {
    address creator;
    address kpiToken;
    uint256 templateId;
    uint128 templateVersion;
    bytes data;
}


/// @title Oracle interface
/// @dev Oracle interface.
/// @author Federico Luzzi - <[email protected]>
interface IOracle {
    function initialize(InitializeOracleParams memory _params) external payable;

    function kpiToken() external returns (address);

    function template() external view returns (Template memory);

    function finalized() external returns (bool);

    function data() external view returns (bytes memory);
}


/// @title KPI tokens manager interface
/// @dev Interface for the KPI tokens manager contract.
/// @author Federico Luzzi - <[email protected]>
interface IKPITokensManager1 is IBaseTemplatesManager {
    function predictInstanceAddress(
        address _creator,
        uint256 _id,
        string memory _description,
        uint256 _expiration,
        bytes memory _initializationData,
        bytes memory _oraclesInitializationData
    ) external view returns (address);

    function instantiate(
        address _creator,
        uint256 _templateId,
        string memory _description,
        uint256 _expiration,
        bytes memory _initializationData,
        bytes memory _oraclesInitializationData
    ) external returns (address, uint128);
}


/// @title KPI token interface
/// @dev KPI token interface.
/// @author Federico Luzzi - <[email protected]>
interface IKPIToken {
    function initialize(InitializeKPITokenParams memory _params)
        external
        payable;

    function finalize(uint256 _result) external;

    function redeem(bytes memory _data) external;

    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;

    function template() external view returns (Template memory);

    function description() external view returns (string memory);

    function finalized() external view returns (bool);

    function expiration() external view returns (uint256);

    function data() external view returns (bytes memory);

    function oracles() external view returns (address[] memory);
}


/// @title Reality.eth v3 interface
/// @dev Interface for the Reality.eth v3 contract.
/// @author Federico Luzzi - <[email protected]>
interface IRealityV3 {
    function askQuestionWithMinBond(
        uint256 _templateId,
        string memory _question,
        address _arbitrator,
        uint32 _timeout,
        uint32 _openingTs,
        uint256 _nonce,
        uint256 _minimumBond
    ) external payable returns (bytes32);

    function getArbitrator(bytes32 _id) external view returns (address);

    function getOpeningTS(bytes32 _id) external view returns (uint32);

    function getTimeout(bytes32 _id) external view returns (uint32);

    function resultForOnceSettled(bytes32 _id) external view returns (bytes32);
}

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Reality oracle
/// @dev An oracle template imlementation leveraging Reality.eth
/// crowdsourced, manual oracle to get data about real-world events
/// on-chain. Since the oracle is crowdsourced, it's extremely flexible,
/// and any condition that can be put into text can leverage Reality.eth
/// as an oracle. The setup is of great importance to ensure the safety
/// of the solution (question timeout, opening timestamp, arbitrator atc must be set
/// with care to avoid unwanted results).
/// @author Federico Luzzi - <[email protected]>
contract RealityV3Oracle is IOracle, Initializable {
    bool public finalized;
    address public kpiToken;
    address internal oraclesManager;
    uint128 internal templateVersion;
    uint256 internal templateId;
    bytes32 internal questionId;
    string internal question;

    error Forbidden();
    error ZeroAddressKpiToken();
    error ZeroAddressReality();
    error ZeroAddressArbitrator();
    error InvalidRealityTemplate();
    error InvalidQuestion();
    error InvalidQuestionTimeout();
    error InvalidOpeningTimestamp();

    event Initialize(address indexed kpiToken, uint256 indexed templateId);
    event Finalize(uint256 result);

    /// @dev Initializes the template through the passed in data. This function is
    /// generally invoked by the oracles manager contract, in turn invoked by a KPI
    /// token template at creation-time. For more info on some of this parameters check
    /// out the Reality.eth docs here: https://reality.eth.limo/app/docs/html/dapp.html#.
    /// @param _params The params are passed in a struct to make it less likely to encounter
    /// stack too deep errors while developing new templates. The params struct contains:
    /// - `_creator`: the address of the entity creating the KPI token.
    /// - `_kpiToken`: the address of the KPI token to which the oracle must be linked to.
    ///   This address is also used to know to which contract to report results back to.
    /// - `_templateId`: the id of the template.
    /// - `_data`: an ABI-encoded structure forwarded by the created KPI token from the KPI token
    ///   creator, containing the initialization parameters for the oracle template.
    ///   In particular the structure is formed in the following way:
    ///     - `address _arbitrator`: The arbitrator for the Reality.eth question.
    ///     - `uint256 _realityTemplateId`: The template id for the Reality.eth question.
    ///     - `string memory _question`: The question that must be submitted to Reality.eth.
    ///     - `uint32 _questionTimeout`: The question timeout as described in the Reality.eth
    ///        docs (linked above).
    ///     - `uint32 _openingTimestamp`: The question opening timestamp as described in the
    ///        Reality.eth docs (linked above).
    ///     - `uint256 minimumBond`: The minimum bond that can be used to answer the question.
    function initialize(InitializeOracleParams memory _params)
        external
        payable
        override
        initializer
    {
        if (_params.kpiToken == address(0)) revert ZeroAddressKpiToken();

        (
            address _arbitrator,
            uint256 _realityTemplateId,
            string memory _question,
            uint32 _questionTimeout,
            uint32 _openingTimestamp,
            uint256 _minimumBond
        ) = abi.decode(
                _params.data,
                (address, uint256, string, uint32, uint32, uint256)
            );

        if (_arbitrator == address(0)) revert ZeroAddressArbitrator();
        if (_realityTemplateId > 4) revert InvalidRealityTemplate();
        if (bytes(_question).length == 0) revert InvalidQuestion();
        if (_questionTimeout == 0) revert InvalidQuestionTimeout();
        if (_openingTimestamp <= block.timestamp)
            revert InvalidOpeningTimestamp();

        oraclesManager = msg.sender;
        templateVersion = _params.templateVersion;
        templateId = _params.templateId;
        kpiToken = _params.kpiToken;
        question = _question;
        questionId = IRealityV3(_reality()).askQuestionWithMinBond{
            value: msg.value
        }(
            _realityTemplateId,
            _question,
            _arbitrator,
            _questionTimeout,
            _openingTimestamp,
            0,
            _minimumBond
        );

        emit Initialize(_params.kpiToken, _params.templateId);
    }

    /// @dev Once the question is finalized on Reality.eth, this must be called to
    /// report back the result to the linked KPI token. This also marks the oracle as finalized.
    function finalize() external {
        if (finalized) revert Forbidden();
        finalized = true;
        uint256 _result = uint256(
            IRealityV3(_reality()).resultForOnceSettled(questionId)
        );
        IKPIToken(kpiToken).finalize(_result);
        emit Finalize(_result);
    }

    /// @dev View function returning all the most important data about the oracle, in
    /// an ABI-encoded structure. The structure pretty much includes all the initialization
    /// data and some.
    /// @return The ABI-encoded data.
    function data() external view override returns (bytes memory) {
        address _reality = _reality(); // gas optimization
        bytes32 _questionId = questionId; // gas optimization
        return
            abi.encode(
                _reality,
                _questionId,
                IRealityV3(_reality).getArbitrator(_questionId),
                question,
                IRealityV3(_reality).getTimeout(_questionId),
                IRealityV3(_reality).getOpeningTS(_questionId)
            );
    }

    /// @dev View function returning info about the template used to instantiate this oracle.
    /// @return The template struct.
    function template() external view override returns (Template memory) {
        return
            IBaseTemplatesManager(oraclesManager).template(
                templateId,
                templateVersion
            );
    }

    function _reality() internal pure returns (address) {
        return address(0xc1C6805B857Bef1f412519C4A842522431aFed39); // will be replaced by codegen-chain-specific-contracts.js
    }
}