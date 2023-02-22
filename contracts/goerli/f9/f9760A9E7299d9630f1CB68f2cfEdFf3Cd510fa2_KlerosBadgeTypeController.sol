/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: [@remedcu]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.0;

import "./IArbitrator.sol";

/**
 * @title IArbitrable
 * Arbitrable interface.
 * When developing arbitrable contracts, we need to:
 * - Define the action taken when a ruling is received by the contract.
 * - Allow dispute creation. For this a function must call arbitrator.createDispute{value: _fee}(_choices,_extraData);
 */
interface IArbitrable {
    /**
     * @dev To be raised when a ruling is given.
     * @param _arbitrator The arbitrator giving the ruling.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling The ruling which was given.
     */
    event Ruling(IArbitrator indexed _arbitrator, uint256 indexed _disputeID, uint256 _ruling);

    /**
     * @dev Give a ruling for a dispute. Must be called by the arbitrator.
     * The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint256 _disputeID, uint256 _ruling) external;
}

/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: [@remedcu]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.0;

import "./IArbitrable.sol";

/**
 * @title Arbitrator
 * Arbitrator abstract contract.
 * When developing arbitrator contracts we need to:
 * - Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, may nbDisputes).
 * - Define the functions for cost display (arbitrationCost and appealCost).
 * - Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
interface IArbitrator {
    enum DisputeStatus {
        Waiting,
        Appealable,
        Solved
    }

    /**
     * @dev To be emitted when a dispute is created.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev To be emitted when a dispute can be appealed.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event AppealPossible(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev To be emitted when the current ruling is appealed.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event AppealDecision(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev Create a dispute. Must be called by the arbitrable contract.
     * Must be paid at least arbitrationCost(_extraData).
     * @param _choices Amount of choices the arbitrator can make in this dispute.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return disputeID ID of the dispute created.
     */
    function createDispute(uint256 _choices, bytes calldata _extraData) external payable returns (uint256 disputeID);

    /**
     * @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Amount to be paid.
     */
    function arbitrationCost(bytes calldata _extraData) external view returns (uint256 cost);

    /**
     * @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     * @param _disputeID ID of the dispute to be appealed.
     * @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(uint256 _disputeID, bytes calldata _extraData) external payable;

    /**
     * @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be higly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _disputeID ID of the dispute to be appealed.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Amount to be paid.
     */
    function appealCost(uint256 _disputeID, bytes calldata _extraData) external view returns (uint256 cost);

    /**
     * @dev Compute the start and end of the dispute's current or next appeal period, if possible. If not known or appeal is impossible: should return (0, 0).
     * @param _disputeID ID of the dispute.
     * @return start The start of the period.
     * @return end The end of the period.
     */
    function appealPeriod(uint256 _disputeID) external view returns (uint256 start, uint256 end);

    /**
     * @dev Return the status of a dispute.
     * @param _disputeID ID of the dispute to rule.
     * @return status The status of the dispute.
     */
    function disputeStatus(uint256 _disputeID) external view returns (DisputeStatus status);

    /**
     * @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     * @param _disputeID ID of the dispute.
     * @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint256 _disputeID) external view returns (uint256 ruling);
}

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ILightGeneralizedTCR } from "../interfaces/ILightGeneralizedTCR.sol";
import { ILightGTCRFactory } from "../interfaces/ILightGTCRFactory.sol";
import { IArbitrator } from "../../lib/erc-792/contracts/IArbitrator.sol";

import "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../interfaces/IBadgeController.sol";
import "../interfaces/ITheBadge.sol";
import "../utils/CappedMath.sol";

contract KlerosBadgeTypeController is Initializable, IBadgeController {
    ITheBadge public theBadge;
    IArbitrator public arbitrator;
    address public tcrFactory;

    using CappedMath for uint256;

    /**
     * Struct to use as args to create a Kleros badge type strategy.
     *  @param badgeMetadata IPFS uri for the badge
     *  @param governor An address with permission to updates parameters of the list. Use Kleros governor for full decentralization.
     *  @param admin The address with permission to add/remove items directly.
     *  @param courtId The ID of the kleros's court.
     *  @param numberOfJurors The number of jurors required if a dispute is initiated.
     *  @param registrationMetaEvidence The URI of the meta evidence object for registration requests.
     *  @param clearingMetaEvidence The URI of the meta evidence object for clearing requests.
     *  @param challengePeriodDuration The time in seconds parties have to challenge a request.
     *  @param baseDeposits The base deposits for requests/challenges as follows:
     *  - The base deposit to submit an item.
     *  - The base deposit to remove an item.
     *  - The base deposit to challenge a submission.
     *  - The base deposit to challenge a removal request.
     *  @param stakeMultipliers Multipliers of the arbitration cost in basis points (see GeneralizedTCR MULTIPLIER_DIVISOR) as follows:
     *  - The multiplier applied to each party's fee stake for a round when there is no winner/loser in the previous round (e.g. when it's the first round or the arbitrator refused to arbitrate).
     *  - The multiplier applied to the winner's fee stake for an appeal round.
     *  - The multiplier applied to the loser's fee stake for an appeal round.
     * @param mintCost The cost for minting a badge, it goes to the emitter.
     * @param validFor The time in seconds of how long the badge is valid. (cero for infinite)
     */
    struct CreateBadgeType {
        address governor;
        address admin;
        uint256 courtId;
        uint256 numberOfJurors;
        string registrationMetaEvidence;
        string clearingMetaEvidence;
        uint256 challengePeriodDuration;
        uint256[4] baseDeposits;
        uint256[3] stakeMultipliers;
    }

    struct RequestBadgeData {
        string evidence;
    }

    /**
     * @param tcrList The TCR List created for a particular badge type
     */
    struct KlerosBadgeType {
        address tcrList;
    }

    /**
     * @param itemID internal Kleros TCR list ID
     * @param callee address paying the deposit
     * @param deposit the deposit amount
     */
    struct KlerosBadge {
        bytes32 itemID;
        address callee;
        uint256 deposit;
    }

    /**
     * =========================
     * Store
     * =========================
     */

    /**
     * @notice Kleros's badge information.
     * badgeId => KlerosBadgeInfo
     */
    mapping(uint256 => KlerosBadgeType) public klerosBadgeType;

    /**
     * @notice Information related to a specific asset from a kleros strategy
     * badgeId => address => KlerosAssetInfo
     */
    mapping(uint256 => mapping(address => KlerosBadge)) public klerosBadge;

    /**
     * =========================
     * Events
     * =========================
     */
    event NewKlerosBadgeType(uint256 indexed badgeId, address indexed klerosTCRAddress, string registrationMetadata);
    event RequestKlerosBadge(
        address indexed callee,
        uint256 indexed badgeTypeId,
        bytes32 klerosItemID,
        address indexed to,
        string evidence
    );

    /**
     * =========================
     * Errors
     * =========================
     */
    error KlerosBadgeTypeController__createBadgeType_badgeTypeAlreadyCreated();
    error KlerosBadgeTypeController__onlyTheBadge_senderNotTheBadge();
    error KlerosBadgeTypeController__mintBadge_alreadyMinted();
    error KlerosBadgeTypeController__mintBadge_wrongBadgeType();
    error KlerosBadgeTypeController__mintBadge_isPaused();
    error KlerosBadgeTypeController__mintBadge_wrongValue();
    error KlerosBadgeTypeController__claimBadge_insufficientBalance();
    error KlerosBadgeTypeController__createBadgeType_TCRListAddressZero();

    /**
     * =========================
     * Modifiers
     * =========================
     */

    modifier onlyTheBadge() {
        if (address(theBadge) != msg.sender) {
            revert KlerosBadgeTypeController__onlyTheBadge_senderNotTheBadge();
        }
        _;
    }

    // constructor(address _theBadge, address _arbitrator, address _tcrFactory) {
    //     theBadge = ITheBadge(_theBadge);
    //     arbitrator = IArbitrator(_arbitrator);
    //     tcrFactory = _tcrFactory;
    // }

    function initialize(address _theBadge, address _arbitrator, address _tcrFactory) public initializer {
        theBadge = ITheBadge(_theBadge);
        arbitrator = IArbitrator(_arbitrator);
        tcrFactory = _tcrFactory;
    }

    /**
     * @notice Allows to create off-chain kleros strategies for registered entities
     * @param badgeId BadgeId from TheBadge contract
     * @param data Encoded data required to create a Kleros TCR list
     */
    function createBadgeType(uint256 badgeId, bytes calldata data) public payable onlyTheBadge {
        KlerosBadgeType storage _klerosBadgeType = klerosBadgeType[badgeId];
        if (_klerosBadgeType.tcrList != address(0)) {
            revert KlerosBadgeTypeController__createBadgeType_badgeTypeAlreadyCreated();
        }

        ILightGTCRFactory lightGTCRFactory = ILightGTCRFactory(tcrFactory);

        CreateBadgeType memory args = abi.decode(data, (CreateBadgeType));

        lightGTCRFactory.deploy(
            IArbitrator(arbitrator),
            bytes.concat(abi.encodePacked(args.courtId), abi.encodePacked(args.numberOfJurors)),
            address(0), // TODO: check this.
            args.registrationMetaEvidence,
            args.clearingMetaEvidence,
            args.governor,
            args.baseDeposits,
            args.challengePeriodDuration,
            args.stakeMultipliers,
            args.admin
        );

        // Get the address for the strategy created
        uint256 index = lightGTCRFactory.count() - 1;
        address klerosTcrListAddress = address(lightGTCRFactory.instances(index));
        if (klerosTcrListAddress == address(0)) {
            revert KlerosBadgeTypeController__createBadgeType_TCRListAddressZero();
        }

        klerosBadgeType[badgeId] = KlerosBadgeType(klerosTcrListAddress);

        emit NewKlerosBadgeType(badgeId, klerosTcrListAddress, args.registrationMetaEvidence);
    }

    /**
     * @notice Returns the cost for minting a badge for a kleros strategy
     * It sums kleros base deposit + kleros arbitration cost
     */
    function badgeRequestValue(uint256 badgeId) public view returns (uint256) {
        KlerosBadgeType storage _klerosBadgeType = klerosBadgeType[badgeId];

        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeType.tcrList);

        uint256 arbitrationCost = arbitrator.arbitrationCost(lightGeneralizedTCR.arbitratorExtraData());
        uint256 baseDeposit = lightGeneralizedTCR.submissionBaseDeposit();

        return arbitrationCost + baseDeposit;
    }

    /**
     * @notice Badge can be minted if it was never requested for the address or if it has a due date before now
     */
    function canRequestBadge(uint256 _badgeId, address _account) public view returns (bool) {
        ITheBadge.Badge memory _badge = theBadge.badge(_badgeId, _account);

        if (_badge.dueDate == 0 && (_badge.status == BadgeStatus.InReview || _badge.status == BadgeStatus.Approved)) {
            return false;
        }

        if (_badge.dueDate > 0 && block.timestamp < _badge.dueDate) {
            return false;
        }

        return true;
    }

    /**
     * @notice mint badge for kleros strategy
     */
    function requestBadge(address callee, uint256 badgeId, address account, bytes calldata data) public payable {
        uint256 mintCost = badgeRequestValue(badgeId);
        if (msg.value != mintCost) {
            revert KlerosBadgeTypeController__mintBadge_wrongValue();
        }

        KlerosBadgeType storage _klerosBadgeType = klerosBadgeType[badgeId];

        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeType.tcrList);
        RequestBadgeData memory args = abi.decode(data, (RequestBadgeData));

        // save deposit amount for callee as it has to be returned if it was not challenged.
        lightGeneralizedTCR.addItem{ value: (msg.value) }(args.evidence);

        bytes32 klerosItemID = keccak256(abi.encodePacked(args.evidence));
        klerosBadge[badgeId][account] = KlerosBadge(klerosItemID, callee, msg.value);

        emit RequestKlerosBadge(callee, badgeId, klerosItemID, account, args.evidence);
    }

    /**
     * @notice get the arbitration cost for a submission or a remove. If the badge is in other state it will return wrong information
     * @param badgeId the badge type id
     * @param account the account that request the badge
     */
    function getChallengeValue(uint256 badgeId, address account) public view returns (uint256) {
        KlerosBadgeType storage _klerosBadgeType = klerosBadgeType[badgeId];
        KlerosBadge storage _klerosBadge = klerosBadge[badgeId][account];
        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeType.tcrList);

        (, , uint120 requestCount) = lightGeneralizedTCR.items(_klerosBadge.itemID);
        uint256 lastRequestIndex = requestCount - 1;

        (, , , , , , , , bytes memory requestArbitratorExtraData, ) = lightGeneralizedTCR.getRequestInfo(
            _klerosBadge.itemID,
            lastRequestIndex
        );

        uint256 arbitrationCost = arbitrator.arbitrationCost(requestArbitratorExtraData);

        uint256 challengerBaseDeposit = theBadge.badge(badgeId, account).status == BadgeStatus.InReview
            ? lightGeneralizedTCR.submissionChallengeBaseDeposit()
            : lightGeneralizedTCR.removalChallengeBaseDeposit();

        return arbitrationCost.addCap(challengerBaseDeposit);
    }

    /**
     * @notice Challenges a badge with status InReview. Accepts enough ETH to cover the deposit
     * @param badgeId the badge type id
     * @param account the account that request the badge
     * @param evidence the IPFS hash of the evidence.
     */
    function challengeBadge(uint256 badgeId, address account, string calldata evidence) external payable {
        KlerosBadgeType storage _klerosBadgeType = klerosBadgeType[badgeId];
        KlerosBadge storage _klerosBadge = klerosBadge[badgeId][account];

        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeType.tcrList);
        lightGeneralizedTCR.challengeRequest{ value: (msg.value) }(_klerosBadge.itemID, evidence);
    }

    /**
     * @notice claim a badge from a TCR list
     * a. Marks asset as Approved
     * b. Transfers deposit to badge's callee
     * c. Sets badge's callee deposit to 0
     */
    function claimBadge(uint256 badgeId, address account) public payable {
        KlerosBadgeType storage _klerosBadgeType = klerosBadgeType[badgeId];
        KlerosBadge storage _klerosBadge = klerosBadge[badgeId][account];

        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeType.tcrList);
        lightGeneralizedTCR.executeRequest(_klerosBadge.itemID);

        theBadge.updateBadgeStatus(badgeId, account, BadgeStatus.Approved);

        if (_klerosBadge.deposit > address(this).balance) {
            revert KlerosBadgeTypeController__claimBadge_insufficientBalance();
        }

        payable(_klerosBadge.callee).transfer(_klerosBadge.deposit);
        _klerosBadge.deposit = 0;
    }

    function balanceOf(uint256 badgeId, address account) public view returns (uint256) {
        KlerosBadgeType storage _klerosBadgeType = klerosBadgeType[badgeId];
        KlerosBadge storage _klerosBadge = klerosBadge[badgeId][account];

        if (_klerosBadgeType.tcrList != address(0)) {
            ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeType.tcrList);
            (uint8 klerosItemStatus, , ) = lightGeneralizedTCR.getItemInfo(_klerosBadge.itemID);
            if (klerosItemStatus == 1 || klerosItemStatus == 3) {
                return 1;
            }
        }

        return 0;
    }

    /**
     * @notice we need a receive function to receive deposits devolution from kleros
     */
    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../utils/enums.sol";

interface IBadgeController {
    function createBadgeType(uint256 badgeId, bytes calldata data) external payable;

    function requestBadge(address callee, uint256 badgeId, address account, bytes calldata data) external payable;

    function claimBadge(uint256 badgeId, address account) external payable;

    function badgeRequestValue(uint256 badgeId) external view returns (uint256);

    function canRequestBadge(uint256 badgeId, address account) external view returns (bool);

    function balanceOf(uint256 badgeId, address account) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IArbitrator } from "../../lib/erc-792/contracts/IArbitrator.sol";

/**
 *  @title LightGeneralizedTCR
 *  Aa curated registry for any types of items. Just like a TCR contract it features the request-challenge protocol and appeal fees crowdfunding.
 *  The difference between LightGeneralizedTCR and GeneralizedTCR is that instead of storing item data in storage and event logs,
 *  LightCurate only stores the URI of item in the logs. This makes it considerably cheaper to use and allows more flexibility with the item columns.
 */
interface ILightGeneralizedTCR {
    enum Status {
        Absent, // The item is not in the registry.
        Registered, // The item is in the registry.
        RegistrationRequested, // The item has a request to be added to the registry.
        ClearingRequested // The item has a request to be removed from the registry.
    }

    enum Party {
        None, // Party per default when there is no challenger or requester. Also used for unconclusive ruling.
        Requester, // Party that made the request to change a status.
        Challenger // Party that challenges the request to change a status.
    }

    enum RequestType {
        Registration, // Identifies a request to register an item to the registry.
        Clearing // Identifies a request to remove an item from the registry.
    }

    struct Item {
        Status status; // The current status of the item.
        uint128 sumDeposit; // The total deposit made by the requester and the challenger (if any).
        uint120 requestCount; // The number of requests.
        mapping(uint256 => Request) requests; // List of status change requests made for the item in the form requests[requestID].
    }

    // Arrays with 3 elements map with the Party enum for better readability:
    // - 0: is unused, matches `Party.None`.
    // - 1: for `Party.Requester`.
    // - 2: for `Party.Challenger`.
    struct Request {
        RequestType requestType;
        uint64 submissionTime; // Time when the request was made. Used to track when the challenge period ends.
        uint24 arbitrationParamsIndex; // The index for the arbitration params for the request.
        address payable requester; // Address of the requester.
        // Pack the requester together with the other parameters, as they are written in the same request.
        address payable challenger; // Address of the challenger, if any.
    }

    /**
     * @dev Submit a request to register an item. Accepts enough ETH to cover the deposit, reimburses the rest.
     * @param _item The URI to the item data.
     */
    function addItem(string calldata _item) external payable;

    /**
     * @notice Gets the arbitratorExtraData for new requests.
     * @dev Gets the latest value in arbitrationParamsChanges.
     * @return The arbitrator extra data.
     */
    function arbitratorExtraData() external view returns (bytes memory);

    function submissionBaseDeposit() external view returns (uint256);

    function submissionChallengeBaseDeposit() external view returns (uint256);

    function removalChallengeBaseDeposit() external view returns (uint256);

    function items(bytes32 item) external view returns (Status status, uint128 sumDeposit, uint120 requestCount);

    function getRequestInfo(
        bytes32 _itemID,
        uint256 _requestID
    )
        external
        view
        returns (
            bool disputed,
            uint256 disputeID,
            uint256 submissionTime,
            bool resolved,
            address payable[3] memory parties,
            uint256 numberOfRounds,
            Party ruling,
            IArbitrator requestArbitrator,
            bytes memory requestArbitratorExtraData,
            uint256 metaEvidenceID
        );

    function getItemInfo(
        bytes32 _itemID
    ) external view returns (uint8 status, uint256 numberOfRequests, uint256 sumDeposit);

    function executeRequest(bytes32 _itemID) external;

    function challengeRequest(bytes32 _itemID, string calldata _evidence) external payable;

    function challengePeriodDuration() external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ILightGeneralizedTCR } from "./ILightGeneralizedTCR.sol";

import { IArbitrator } from "../../lib/erc-792/contracts/IArbitrator.sol";

/**
 *  @title LightGTCRFactory
 *  registry for LightGeneralizedTCR instances.
 */
interface ILightGTCRFactory {
    /**
     *  @dev Deploy the arbitrable curated registry.
     *  @param _arbitrator Arbitrator to resolve potential disputes. The arbitrator is trusted to support appeal periods and not reenter.
     *  @param _arbitratorExtraData Extra data for the trusted arbitrator contract.
     *  @param _connectedTCR The address of the TCR that stores related TCR addresses. This parameter can be left empty.
     *  @param _registrationMetaEvidence The URI of the meta evidence object for registration requests.
     *  @param _clearingMetaEvidence The URI of the meta evidence object for clearing requests.
     *  @param _governor The trusted governor of this contract.
     *  @param _baseDeposits The base deposits for requests/challenges as follows:
     *  - The base deposit to submit an item.
     *  - The base deposit to remove an item.
     *  - The base deposit to challenge a submission.
     *  - The base deposit to challenge a removal request.
     *  @param _challengePeriodDuration The time in seconds parties have to challenge a request.
     *  @param _stakeMultipliers Multipliers of the arbitration cost in basis points (see LightGeneralizedTCR MULTIPLIER_DIVISOR) as follows:
     *  - The multiplier applied to each party's fee stake for a round when there is no winner/loser in the previous round.
     *  - The multiplier applied to the winner's fee stake for an appeal round.
     *  - The multiplier applied to the loser's fee stake for an appeal round.
     *  @param _relayContract The address of the relay contract to add/remove items directly.
     */
    function deploy(
        IArbitrator _arbitrator,
        bytes memory _arbitratorExtraData,
        address _connectedTCR,
        string memory _registrationMetaEvidence,
        string memory _clearingMetaEvidence,
        address _governor,
        uint256[4] memory _baseDeposits,
        uint256 _challengePeriodDuration,
        uint256[3] memory _stakeMultipliers,
        address _relayContract
    ) external;

    function instances(uint256 index) external returns (ILightGeneralizedTCR);

    function count() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../utils/enums.sol";

interface ITheBadge {
    struct Badge {
        BadgeStatus status;
        uint256 dueDate;
    }

    function badge(uint256 _badgeId, address _account) external view returns (Badge memory);

    function updateBadgeStatus(uint256 badgeId, address badgeOwner, BadgeStatus status) external;
}

/**
 *  @authors: [@mtsalenc*]
 *  @reviewers: [@clesaege*]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.17;

/**
 * @title CappedMath
 * @dev Math operations with caps for under and overflow.
 */
library CappedMath {
    uint256 private constant UINT_MAX = 2 ** 256 - 1;

    /**
     * @dev Adds two unsigned integers, returns 2^256 - 1 on overflow.
     */
    function addCap(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        return c >= _a ? c : UINT_MAX;
    }

    /**
     * @dev Subtracts two integers, returns 0 on underflow.
     */
    function subCap(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_b > _a) return 0;
        else return _a - _b;
    }

    /**
     * @dev Multiplies two unsigned integers, returns 2^256 - 1 on overflow.
     */
    function mulCap(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring '_a' not being zero, but the
        // benefit is lost if '_b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) return 0;

        uint256 c = _a * _b;
        return c / _a == _b ? c : UINT_MAX;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

// TODO: check how it can be marked as challenged.
// Also how if it was rejected by kleros, can it be marked as Rejected here.
enum BadgeStatus {
    // The asset has not been created.
    NotCreated,
    // The asset is going through an approval process.
    InReview,
    // The asset was approved.
    Approved,
    // The asset was rejected.
    Rejected,
    // The asset was revoked.
    Revoked
}