pragma solidity ^0.8.11;

import "@xcute/contracts/JobUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../interfaces/oracles/IOracle.sol";
import "../interfaces/IOraclesManager.sol";
import "../interfaces/kpi-tokens/IKPIToken.sol";
import "../interfaces/external/IReality.sol";

error ZeroAddressKpiToken();
error ZeroAddressReality();
error ZeroAddressArbitrator();
error InvalidQuestion();
error InvalidBounds();
error InvalidQuestionTimeout();
error InvalidExpiry();
error NoWorkRequired();

/**
 * @title AutomatedRealityOracle
 * @dev AutomatedRealityOracle contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
contract AutomatedRealityOracle is JobUpgradeable, IOracle {
    bool public finalized;
    address public kpiToken;
    address public reality;
    bytes32 internal questionId;
    string internal question;
    IOraclesManager.Template public __template;

    function initialize(
        address _kpiToken,
        IOraclesManager.Template memory _template,
        bytes memory _data
    ) external initializer {
        if (_kpiToken == address(0)) revert ZeroAddressKpiToken();

        (
            address _workersMaster,
            address _reality,
            address _arbitrator,
            string memory _question,
            uint32 _questionTimeout,
            uint32 _expiry,
            bool _binary
        ) = abi.decode(
                _data,
                (address, address, address, string, uint32, uint32, bool)
            );

        if (_reality == address(0)) revert ZeroAddressReality();
        if (_arbitrator == address(0)) revert ZeroAddressArbitrator();
        if (bytes(_question).length == 0) revert InvalidQuestion();
        if (_questionTimeout == 0) revert InvalidQuestionTimeout();
        if (_expiry <= block.timestamp) revert InvalidExpiry();
        __Job_init(_workersMaster);

        __template = _template;
        kpiToken = _kpiToken;
        reality = _reality;
        question = _question;
        questionId = IReality(_reality).askQuestion(
            _binary ? 0 : 1,
            _question,
            _arbitrator,
            _questionTimeout,
            _expiry,
            0
        );
    }

    function _workable() internal view returns (bool) {
        return !finalized && IReality(reality).isFinalized(questionId);
    }

    function workable(bytes memory)
        external
        view
        override
        returns (bool, bytes memory)
    {
        return (_workable(), bytes(""));
    }

    function work(bytes memory) external override needsExecution {
        if (!_workable()) revert NoWorkRequired();
        IKPIToken(kpiToken).finalize(
            uint256(IReality(reality).resultFor(questionId))
        );
        finalized = true;
    }

    function data() external view override returns (bytes memory) {
        address _reality = reality; // gas optimization
        bytes32 _questionId = questionId; // gas optimization
        return
            abi.encode(
                _reality,
                IReality(_reality).getArbitrator(_questionId),
                question,
                IReality(_reality).getTimeout(_questionId),
                IReality(_reality).getOpeningTS(_questionId)
            );
    }

    function template()
        external
        view
        override
        returns (IOraclesManager.Template memory)
    {
        return __template;
    }
}

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IMaster.sol";
import "./interfaces/IJob.sol";

error ZeroAddressMaster();
error NotAWorker();
error InvalidWorker();

/**
 * @title JobUpgradeable
 * @dev JobUpgradeable contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
abstract contract JobUpgradeable is IJob, Initializable, ContextUpgradeable {
    address public master;

    function __Job_init(address _master) internal initializer {
        __Context_init_unchained();
        __Job_init_unchained(_master);
    }

    function __Job_init_unchained(address _master) internal initializer {
        if (_master == address(0)) revert ZeroAddressMaster();
        master = _master;
    }

    function workable(bytes calldata _data)
        external
        view
        virtual
        override
        returns (bool, bytes calldata);

    function work(bytes calldata _data) external virtual override;

    modifier needsExecution() {
        IMaster(master).initializeWork(_msgSender());
        _;
        IMaster(master).finalizeWork(_msgSender());
    }

    modifier needsExecutionWithRequirements(
        uint256 _minimumBonded,
        uint256 _minimumEarned,
        uint256 _minimumAge
    ) {
        IMaster(master).initializeWorkWithRequirements(
            _msgSender(),
            _minimumBonded,
            _minimumEarned,
            _minimumAge
        );
        _;
        IMaster(master).finalizeWork(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

pragma solidity ^0.8.11;

import "../IOraclesManager.sol";

/**
 * @title IOracle
 * @dev IOracle contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
interface IOracle {
    function initialize(
        address _kpiToken,
        IOraclesManager.Template memory _template,
        bytes memory _initializationData
    ) external;

    function kpiToken() external returns (address);

    function template() external view returns (IOraclesManager.Template memory);

    function finalized() external returns (bool);

    function data() external view returns (bytes memory);
}

pragma solidity ^0.8.11;

/**
 * @title IOraclesManager
 * @dev IOraclesManager contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
interface IOraclesManager {
    struct Template {
        uint256 id;
        address addrezz;
        string specification;
        bool automatable;
        bool exists;
    }

    struct EnumerableTemplateSet {
        uint256 ids;
        mapping(uint256 => Template) map;
        uint256[] keys;
    }

    function predictInstanceAddress(
        uint256 _id,
        address _automationFundingToken,
        uint256 _automationFundingAmount,
        bytes memory _initializationData
    ) external view returns (address);

    function instantiate(
        uint256 _id,
        address _automationFundingToken,
        uint256 _automationFundingAmount,
        bytes memory _initializationData
    ) external returns (address);

    function addTemplate(
        address _template,
        bool _automatable,
        string calldata _specification
    ) external;

    function removeTemplate(uint256 _id) external;

    function updgradeTemplate(
        uint256 _id,
        address _newTemplate,
        string calldata _newSpecification
    ) external;

    function updateTemplateSpecification(
        uint256 _id,
        string calldata _newSpecification
    ) external;

    function template(uint256 _id) external view returns (Template memory);

    function templatesAmount() external view returns (uint256);

    function templatesSlice(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        returns (Template[] memory);
}

pragma solidity ^0.8.11;

import "../IKPITokensManager.sol";

/**
 * @title IKPIToken
 * @dev IKPIToken contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
interface IKPIToken {
    function initialize(
        address _creator,
        IKPITokensManager.Template memory _template,
        string memory _description,
        bytes memory _data
    ) external;

    function initializeOracles(address _oraclesManager, bytes memory _data)
        external;

    function collectProtocolFees(address _feeReceiver) external;

    function finalize(uint256 _result) external;

    function redeem() external;

    function creator() external view returns (address);

    function template()
        external
        view
        returns (IKPITokensManager.Template memory);

    function oracles() external view returns (address[] memory);

    function description() external view returns (string memory);

    function finalized() external view returns (bool);

    function protocolFee(bytes memory _data)
        external
        view
        returns (bytes memory);

    function data() external view returns (bytes memory);
}

pragma solidity ^0.8.11;

/**
 * @title KPIToken
 * @dev KPIToken contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
interface IReality {
    function askQuestion(
        uint256 _templateId,
        string calldata _question,
        address _arbitrator,
        uint32 _timeout,
        uint32 _openingTs,
        uint256 _nonce
    ) external returns (bytes32 _questionId);

    function isFinalized(bytes32 _id) external view returns (bool);

    function getArbitrator(bytes32 _id) external view returns (address);

    function getOpeningTS(bytes32 _id) external view returns (uint32);

    function getTimeout(bytes32 _id) external view returns (uint32);

    function resultFor(bytes32 _id) external view returns (bytes32);
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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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

pragma solidity >=0.8.9;

/**
 * @title IMaster
 * @dev IMaster contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IMaster {
    function setBonder(address _bonder) external;

    function setJobsRegistry(address _jobsRegistry) external;

    function setWorkEvaluator(address _workEvaluator) external;

    function bonder() external returns (address);

    function jobsRegistry() external returns (address);

    function workEvaluator() external returns (address);

    function initializeWork(address _worker) external;

    function initializeWorkWithRequirements(
        address _worker,
        uint256 _minimumBonded,
        uint256 _minimumEarned,
        uint256 _minimumAge
    ) external;

    function finalizeWork(address _worker) external;

    function finalizeWork(
        address _worker,
        address _rewardToken,
        uint256 _amount
    ) external;
}

pragma solidity >=0.8.9;

/**
 * @title IJob
 * @dev IJob contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IJob {
    function workable(bytes memory _data)
        external
        view
        returns (bool, bytes memory);

    function work(bytes memory _data) external;
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

pragma solidity ^0.8.11;

/**
 * @title IKPITokensManager
 * @dev IKPITokensManager contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
interface IKPITokensManager {
    struct Template {
        uint256 id;
        address addrezz;
        string specification;
        bool exists;
    }

    struct EnumerableTemplateSet {
        uint256 ids;
        mapping(uint256 => Template) map;
        uint256[] keys;
    }

    function predictInstanceAddress(
        uint256 _id,
        string memory _description,
        bytes memory _initializationData,
        bytes memory _oraclesInitializationData
    ) external view returns (address);

    function instantiate(
        uint256 _id,
        string memory _description,
        bytes memory _initializationData,
        bytes memory _oraclesInitializationData
    ) external returns (address);

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

    function templatesAmount() external view returns (uint256);

    function templatesSlice(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        returns (Template[] memory);
}