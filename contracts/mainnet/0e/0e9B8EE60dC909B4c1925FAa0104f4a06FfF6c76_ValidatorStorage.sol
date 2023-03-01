// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

interface IGovernable {

    function getGovernanceAddress() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "./IStakingConfig.sol";

interface IStaking {

    function getStakingConfig() external view returns (IStakingConfig);

//    function getValidators() external view returns (address[] memory);

//    function isValidatorActive(address validator) external view returns (bool);

//    function isValidator(address validator) external view returns (bool);

    function getValidatorStatus(address validator) external view returns (
        address ownerAddress,
        uint8 status,
        uint256 totalDelegated,
        uint32 slashesCount,
        uint64 changedAt,
        uint64 jailedBefore,
        uint64 claimedAt,
        uint16 commissionRate,
        uint96 totalRewards
    );

    function getValidatorStatusAtEpoch(address validator, uint64 epoch) external view returns (
        address ownerAddress,
        uint8 status,
        uint256 totalDelegated,
        uint32 slashesCount,
        uint64 changedAt,
        uint64 jailedBefore,
        uint64 claimedAt,
        uint16 commissionRate,
        uint96 totalRewards
    );

//    function getValidatorByOwner(address owner) external view returns (address);

//    function registerValidator(address validator, uint16 commissionRate, uint256 amount) payable external;

    function addValidator(address validator) external;

    function activateValidator(address validator) external;

    function disableValidator(address validator) external;

//    function releaseValidatorFromJail(address validator) external;

//    function changeValidatorCommissionRate(address validator, uint16 commissionRate) external;

    function changeValidatorOwner(address validator, address newOwner) external;

    function getValidatorDelegation(address validator, address delegator) external view returns (
        uint256 delegatedAmount,
        uint64 atEpoch
    );

    function delegate(address validator, uint256 amount) payable external;

    function undelegate(address validator, uint256 amount) external;

//    function getValidatorFee(address validator) external view returns (uint256);

//    function getPendingValidatorFee(address validator) external view returns (uint256);

//    function claimValidatorFee(address validator) external;

    function getDelegatorFee(address validator, address delegator) external view returns (uint256);

    function getPendingDelegatorFee(address validator, address delegator) external view returns (uint256);

    function claimDelegatorFee(address validator) external;

    function claimStakingRewards(address validatorAddress) external;

    function claimPendingUndelegates(address validator) external;

    function calcAvailableForRedelegateAmount(address validator, address delegator) external view returns (uint256 amountToStake, uint256 rewardsDust);

    function calcAvailableForDelegateAmount(uint256 amount) external view returns (uint256 amountToStake, uint256 dust);

    function redelegateDelegatorFee(address validator) external;

    function currentEpoch() external view returns (uint64);

    function nextEpoch() external view returns (uint64);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "./IGovernable.sol";

interface IStakingConfig is IGovernable {

    function getActiveValidatorsLength() external view returns (uint32);

    function setActiveValidatorsLength(uint32 newValue) external;

    function getEpochBlockInterval() external view returns (uint32);

    function setEpochBlockInterval(uint32 newValue) external;

    function getMisdemeanorThreshold() external view returns (uint32);

    function setMisdemeanorThreshold(uint32 newValue) external;

    function getFelonyThreshold() external view returns (uint32);

    function setFelonyThreshold(uint32 newValue) external;

    function getValidatorJailEpochLength() external view returns (uint32);

    function setValidatorJailEpochLength(uint32 newValue) external;

    function getUndelegatePeriod() external view returns (uint32);

    function setUndelegatePeriod(uint32 newValue) external;

    function getMinValidatorStakeAmount() external view returns (uint256);

    function setMinValidatorStakeAmount(uint256 newValue) external;

    function getMinStakingAmount() external view returns (uint256);

    function setMinStakingAmount(uint256 newValue) external;

    function getGovernanceAddress() external view override returns (address);

    function setGovernanceAddress(address newValue) external;

    function getTreasuryAddress() external view returns (address);

    function setTreasuryAddress(address newValue) external;

    function getLockPeriod() external view returns (uint64);

    function setLockPeriod(uint64 newValue) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "./IStakingConfig.sol";
import "../libs/ValidatorUtil.sol";

interface IValidatorStorage {

    function getValidator(address) external view returns (Validator memory);

    function validatorOwners(address) external view returns (address);

    function create(
        address validatorAddress,
        address validatorOwner,
        ValidatorStatus status,
        uint64 epoch
    ) external;

    function activate(address validatorAddress) external returns (Validator memory);

    function disable(address validatorAddress) external returns (Validator memory);

    function change(address validatorAddress, uint64 epoch) external;

    function changeOwner(address validatorAddress, address newOwner) external returns (Validator memory);

//    function activeValidatorsList() external view returns (address[] memory);

    function isOwner(address validatorAddress, address addr) external view returns (bool);

    function migrate(Validator calldata validator) external;

    function getValidators() external view returns (address[] memory);
}

pragma solidity ^0.8.0;

enum ValidatorStatus {
    NotFound,
    Active,
    Pending,
    Jail
}

struct Validator {
    address validatorAddress;
    address ownerAddress;
    ValidatorStatus status;
    uint64 changedAt;
    uint64 jailedBefore;
    uint64 claimedAt;
}

library ValidatorUtil {

//    function isActive(Validator memory self) internal pure returns (bool) {
//        return self.status == ValidatorStatus.Active;
//    }
//
//    function isOwner(
//        Validator memory self,
//        address addr
//    ) internal pure returns (bool) {
//        return self.ownerAddress == addr;
//    }

//    function create(
//        Validator storage self,
//        address validatorAddress,
//        address validatorOwner,
//        ValidatorStatus status,
//        uint64 epoch
//    ) internal {
//        require(self.status == ValidatorStatus.NotFound, "Validator: already exist");
//        self.validatorAddress = validatorAddress;
//        self.ownerAddress = validatorOwner;
//        self.status = status;
//        self.changedAt = epoch;
//    }

//    function activate(
//        Validator storage self
//    ) internal returns (Validator memory vldtr) {
//        require(self.status == ValidatorStatus.Pending, "Validator: bad status");
//        self.status = ValidatorStatus.Active;
//        return self;
//    }

//    function disable(
//        Validator storage self
//    ) internal returns (Validator memory vldtr) {
//        require(self.status == ValidatorStatus.Active || self.status == ValidatorStatus.Jail, "Validator: bad status");
//        self.status = ValidatorStatus.Pending;
//        return self;
//    }

//    function jail(
//        Validator storage self,
//        uint64 beforeEpoch
//    ) internal {
//        require(self.status != ValidatorStatus.NotFound, "Validator: not found");
//        self.jailedBefore = beforeEpoch;
//        self.status = ValidatorStatus.Jail;
//    }

//    function unJail(
//        Validator storage self,
//        uint64 epoch
//    ) internal {
//        // make sure validator is in jail
//        require(self.status == ValidatorStatus.Jail, "Validator: bad status");
//        // only validator owner
//        require(msg.sender == self.ownerAddress, "Validator: only owner");
//        require(epoch >= self.jailedBefore, "Validator: still in jail");
//        forceUnJail(self);
//    }

    // @dev release validator from jail
//    function forceUnJail(
//        Validator storage self
//    ) internal {
//        // update validator status
//        self.status = ValidatorStatus.Active;
//        self.jailedBefore = 0;
//    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IStakingConfig.sol";

import "../libs/ValidatorUtil.sol";
import "../interfaces/IStaking.sol";
import "../interfaces/IValidatorStorage.sol";

contract ValidatorStorage is Initializable, IValidatorStorage {

    event StakingPoolChanged(address prevValue, address newValue);

    // mapping from validator address to validator
    mapping(address => Validator) internal _validatorsMap;
    // mapping from validator owner to validator address
    mapping(address => address) public validatorOwners;
    // list of all validators that are in validators mapping
    address[] public activeValidatorsList;
    // chain config with params
    IStakingConfig internal _stakingConfig;
    IStaking internal _stakingPool;
    // reserve some gap for the future upgrades
    uint256[50 - 5] private __reserved;

    modifier onlyFromGovernance() virtual {
        require(msg.sender == _stakingConfig.getGovernanceAddress(), "ValidatorStorage: only governance");
        _;
    }

    modifier onlyFromPool() virtual {
        require(msg.sender == address(_stakingPool), "ValidatorStorage: only pool");
        _;
    }

    function initialize(IStakingConfig stakingConfig, IStaking stakingPool) external initializer {
        __ValidatorStorage_init(stakingConfig, stakingPool);
    }

    function __ValidatorStorage_init(IStakingConfig stakingConfig, IStaking stakingPool) internal {
        _stakingConfig = stakingConfig;
        _stakingPool = stakingPool;
    }

    function getStakingConfig() external view virtual returns (IStakingConfig) {
        return _stakingConfig;
    }

    function getValidator(address validatorAddress) external view returns (Validator memory) {
        return _validatorsMap[validatorAddress];
    }

    function migrate(Validator calldata validator) external override onlyFromPool {
        _validatorsMap[validator.validatorAddress] = validator;
        validatorOwners[validator.ownerAddress] = validator.validatorAddress;
        if (validator.status == ValidatorStatus.Active) {
            activeValidatorsList.push(validator.validatorAddress);
        }
    }

    function create(
        address validatorAddress,
        address validatorOwner,
        ValidatorStatus status,
        uint64 epoch
    ) external override onlyFromPool {
        require(status != ValidatorStatus.NotFound, "ValidatorStorage: status not allowed");
        Validator storage self = _validatorsMap[validatorAddress];
        require(self.status == ValidatorStatus.NotFound, "ValidatorStorage: already exist");
        self.validatorAddress = validatorAddress;
        self.ownerAddress = validatorOwner;
        self.status = status;
        self.changedAt = epoch;

        // save validator owner
        require(validatorOwners[validatorOwner] == address(0x00), "owner in use");
        validatorOwners[validatorOwner] = validatorAddress;

        // add new validator to array
        if (status == ValidatorStatus.Active) {
            activeValidatorsList.push(validatorAddress);
        }
    }

    function activate(address validatorAddress) external override onlyFromPool returns (Validator memory) {
        Validator storage self = _validatorsMap[validatorAddress];
        require(self.status == ValidatorStatus.Pending, "Validator: bad status");
        self.status = ValidatorStatus.Active;

        activeValidatorsList.push(validatorAddress);

        return self;
    }

    function change(address validatorAddress, uint64 epoch) external override onlyFromPool {
        _validatorsMap[validatorAddress].changedAt = epoch;
    }

    function disable(address validatorAddress) external override onlyFromPool returns (Validator memory) {
        Validator storage self = _validatorsMap[validatorAddress];
        require(self.status == ValidatorStatus.Active || self.status == ValidatorStatus.Jail, "Validator: bad status");
        self.status = ValidatorStatus.Pending;

        _removeValidatorFromActiveList(validatorAddress);

        return self;
    }

    function _removeValidatorFromActiveList(address validatorAddress) internal onlyFromPool {
        // find index of validator in validator set
        int256 indexOf = - 1;
        for (uint256 i; i < activeValidatorsList.length; i++) {
            if (activeValidatorsList[i] != validatorAddress) continue;
            indexOf = int256(i);
            break;
        }
        // remove validator from array (since we remove only active it might not exist in the list)
        if (indexOf >= 0) {
            if (activeValidatorsList.length > 1 && uint256(indexOf) != activeValidatorsList.length - 1) {
                activeValidatorsList[uint256(indexOf)] = activeValidatorsList[activeValidatorsList.length - 1];
            }
            activeValidatorsList.pop();
        }
    }

    function changeOwner(address validatorAddress, address newOwner) external override onlyFromPool returns (Validator memory) {
        require(newOwner != address(0x0), "new owner cannot be zero address");
        Validator storage validator = _validatorsMap[validatorAddress];
        require(validatorOwners[newOwner] == address(0x00), "owner in use");
        delete validatorOwners[validator.ownerAddress];
        validator.ownerAddress = newOwner;
        validatorOwners[newOwner] = validatorAddress;

        return validator;
    }

    function isValidatorActive(address account) external view returns (bool) {
        if (!isActive(account)) {
            return false;
        }
        address[] memory topValidators = getValidators();
        for (uint256 i; i < topValidators.length; i++) {
            if (topValidators[i] == account) return true;
        }
        return false;
    }

    function isValidator(address account) external view returns (bool) {
        return _validatorsMap[account].status != ValidatorStatus.NotFound;
    }

    function isActive(address validatorAddress) public view returns (bool) {
        return _validatorsMap[validatorAddress].status == ValidatorStatus.Active;
    }

    function isOwner(address validatorAddress, address addr) external view override returns (bool) {
        return _validatorsMap[validatorAddress].ownerAddress == addr;
    }

    function getValidators() public view override returns (address[] memory) {
        return activeValidatorsList;
    }
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