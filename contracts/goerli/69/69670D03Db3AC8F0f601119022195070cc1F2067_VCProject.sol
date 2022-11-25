// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Errors} from "./Errors.sol";

struct CampaignData {
    uint256 target;
    uint256 softTarget;
    uint256 raisedAmount;
    uint256 balance;
    uint256 startTime;
    uint256 endTime;
    uint256 backersDeadline;
    bool resultsPublished;
}

enum CampaignStatus {
    ACTIVE,
    NOTFUNDED,
    FUNDED,
    SUCCEEDED,
    DEFEATED
}

contract VCProject is Initializable {
    address _starter;
    address _lab;
    uint256 _numberOfCampaigns;
    bool _projectStatus;

    mapping(uint256 => CampaignData) _campaigns;
    mapping(uint256 => mapping(address => mapping(IERC20 => uint256))) _backers;
    mapping(uint256 => mapping(IERC20 => uint256)) _campaignBalance;

    // Project balances: increase after funding and decrease after deposit
    mapping(IERC20 => uint256) _totalCampaignsBalance;
    mapping(IERC20 => uint256) _totalOutsideCampaignsBalance;
    uint256 _projectBalance; // en USD

    // Raised amounts: only increase after funding, never decrease
    uint256 _raisedAmountOutsideCampaigns; // en USD

    constructor() {}

    function init(address starter, address lab) external initializer {
        _starter = starter;
        _lab = lab;
        _numberOfCampaigns = 0;
        _raisedAmountOutsideCampaigns = 0;
        _projectStatus = true;
    }

    ///////////////////////
    // PROJECT FUNCTIONS //
    ///////////////////////

    function fundProject(uint256 _amount, IERC20 _currency) external {
        _onlyStarter();

        _raisedAmountOutsideCampaigns += _amount;
        _totalOutsideCampaignsBalance[_currency] += _amount;
        _projectBalance += _amount;
    }

    function closeProject() external {
        _onlyStarter();

        bool canBeClosed = _projectStatus && _projectBalance == 0;
        if (_numberOfCampaigns > 0) {
            uint256 lastCampaignId = _numberOfCampaigns - 1;
            CampaignStatus lastCampaignStatus = getCampaignStatus(lastCampaignId);
            bool lastResultsPublished = _campaigns[lastCampaignId].resultsPublished;

            canBeClosed =
                canBeClosed &&
                (lastCampaignStatus == CampaignStatus.DEFEATED ||
                    (lastCampaignStatus == CampaignStatus.SUCCEEDED && lastResultsPublished));
        }

        if (!canBeClosed) {
            revert Errors.ProjCannotBeClosed();
        }
        _projectStatus = false;
    }

    ////////////////////////
    // CAMPAIGN FUNCTIONS //
    ////////////////////////

    function startCampaign(
        uint256 _target,
        uint256 _softTarget,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _backersDeadline
    ) external returns (uint256) {
        _onlyStarter();

        bool canStartCampaign = _projectStatus;
        if (_numberOfCampaigns > 0) {
            uint256 lastCampaignId = _numberOfCampaigns - 1;
            CampaignStatus lastCampaignStatus = getCampaignStatus(lastCampaignId);
            bool lastResultsPublished = _campaigns[lastCampaignId].resultsPublished;

            canStartCampaign =
                canStartCampaign &&
                (lastCampaignStatus == CampaignStatus.DEFEATED ||
                    (lastCampaignStatus == CampaignStatus.SUCCEEDED && lastResultsPublished));
        }

        if (!canStartCampaign) {
            revert Errors.ProjCampaignCannotStart();
        }

        uint256 currentId = _numberOfCampaigns;
        _numberOfCampaigns++;

        _campaigns[currentId] = CampaignData(_target, _softTarget, 0, 0, _startTime, _endTime, _backersDeadline, false);
        return currentId;
    }

    function publishCampaignResults() external {
        _onlyStarter();

        uint256 currentCampaignId = _numberOfCampaigns - 1;
        CampaignStatus campaignStatus = getCampaignStatus(currentCampaignId);
        bool resultsPublished = _campaigns[currentCampaignId].resultsPublished;

        if (campaignStatus != CampaignStatus.SUCCEEDED || resultsPublished == true) {
            revert Errors.ProjResultsCannotBePublished();
        }

        _campaigns[currentCampaignId].resultsPublished = true;
    }

    function fundCampaign(
        IERC20 _currency,
        address _user,
        uint256 _amount
    ) external {
        _onlyStarter();
        uint256 currentCampaignId = _numberOfCampaigns - 1;

        _backers[currentCampaignId][_user][_currency] += _amount;
        _updateBalances(currentCampaignId, _currency, _amount, true);
    }

    function validateMint(
        uint256 _campaignId,
        IERC20 _currency,
        address _user
    ) external returns (uint256 backerBalance) {
        _onlyStarter();
        CampaignStatus currentCampaignStatus = getCampaignStatus(_campaignId);

        if (currentCampaignStatus == CampaignStatus.ACTIVE || currentCampaignStatus == CampaignStatus.NOTFUNDED) {
            revert Errors.ProjCampaignNotSucceededNorFundedNorDefeated();
        }

        backerBalance = _backers[_campaignId][_user][_currency];
        if (backerBalance == 0) {
            revert Errors.ProjBalanceIsZero();
        }
        _backers[_campaignId][_user][_currency] = 0;
    }

    function backerWithdrawDefeated(
        uint256 _campaignId,
        address _user,
        IERC20 _currency
    ) external returns (uint256 backerBalance, bool statusDefeated) {
        _onlyStarter();

        if (getCampaignStatus(_campaignId) != CampaignStatus.NOTFUNDED) {
            revert Errors.ProjCampaignNotNotFunded();
        }

        backerBalance = _backers[_campaignId][_user][_currency];
        if (backerBalance == 0) {
            revert Errors.ProjBalanceIsZero();
        }

        _backers[_campaignId][_user][_currency] = 0;
        _updateBalances(_campaignId, _currency, backerBalance, false);
        if (_campaigns[_campaignId].balance == 0) {
            statusDefeated = true;
        }

        if (!_currency.transfer(_user, backerBalance)) {
            revert Errors.ProjERC20TransferError();
        }
    }

    function labCampaignWithdraw(IERC20 _currency)
        external
        returns (
            uint256 currentCampaignId,
            uint256 withdrawAmount,
            bool statusSucceeded
        )
    {
        _onlyStarter();
        currentCampaignId = _numberOfCampaigns - 1;

        if (getCampaignStatus(currentCampaignId) != CampaignStatus.FUNDED) {
            revert Errors.ProjCampaignNotFunded();
        }

        withdrawAmount = _campaignBalance[currentCampaignId][_currency];

        if (withdrawAmount == 0) {
            revert Errors.ProjBalanceIsZero();
        }

        _updateBalances(currentCampaignId, _currency, withdrawAmount, false);
        if (_campaigns[currentCampaignId].balance == 0) {
            statusSucceeded = true;
        }

        if (!_currency.transfer(_lab, withdrawAmount)) {
            revert Errors.ProjERC20TransferError();
        }
    }

    function labWithdraw(IERC20 _currency) external returns (uint256 _amount) {
        _onlyStarter();

        _amount = _totalOutsideCampaignsBalance[_currency];

        if (_totalOutsideCampaignsBalance[_currency] == 0) {
            revert Errors.ProjBalanceIsZero();
        }

        if (!_currency.transfer(_lab, _amount)) {
            revert Errors.ProjERC20TransferError();
        }
        _totalOutsideCampaignsBalance[_currency] = 0;
        _projectBalance -= _amount;
    }

    function withdrawToPool(IERC20 _currency, address _receiver) external returns (uint256 amountAvailable) {
        _onlyStarter();
        amountAvailable =
            _currency.balanceOf(address(this)) -
            _totalCampaignsBalance[_currency] -
            _totalOutsideCampaignsBalance[_currency];
        if (amountAvailable == 0) {
            revert Errors.ProjZeroAmountToWithdraw();
        }
        if (!_currency.transfer(_receiver, amountAvailable)) {
            revert Errors.ProjERC20TransferError();
        }
    }

    function transferUnclaimedFunds(
        uint256 _campaignId,
        IERC20 _currency,
        address _pool
    ) external returns (uint256 _amountToPool, bool _statusDefeated) {
        _onlyStarter();

        if (getCampaignStatus(_campaignId) != CampaignStatus.DEFEATED) {
            revert Errors.ProjCampaignNotDefeated();
        }
        _amountToPool = _campaignBalance[_campaignId][_currency];
        if (_amountToPool == 0) {
            revert Errors.ProjBalanceIsZero();
        }

        _updateBalances(_campaignId, _currency, _amountToPool, false);
        if (_campaigns[_campaignId].balance == 0) {
            _statusDefeated = true;
        }

        if (!_currency.transfer(_pool, _amountToPool)) {
            revert Errors.SttrERC20TransferError();
        }
    }

    ////////////////////
    // VIEW FUNCTIONS //
    ////////////////////

    function getNumberOfCampaigns() external view returns (uint256) {
        return _numberOfCampaigns;
    }

    function getCampaignRaisedAmount(uint256 _campaignId) external view returns (uint256) {
        return _campaigns[_campaignId].raisedAmount;
    }

    function getRaisedAmountFromCampaigns() public view returns (uint256 raisedAmount) {
        for (uint256 i = 0; i <= _numberOfCampaigns; i++) {
            if (getCampaignStatus(i) == CampaignStatus.SUCCEEDED) {
                raisedAmount += _campaigns[i].raisedAmount;
            }
        }
    }

    function getRaisedAmountOutsideCampaigns() public view returns (uint256 raisedAmount) {
        return _raisedAmountOutsideCampaigns;
    }

    function getTotalRaisedAmount() external view returns (uint256) {
        return getRaisedAmountFromCampaigns() + _raisedAmountOutsideCampaigns;
    }

    function campaignBalance(uint256 _campaignId, IERC20 _currency) external view returns (uint256) {
        return _campaignBalance[_campaignId][_currency];
    }

    function totalCampaignBalance(IERC20 _currency) external view returns (uint256) {
        return _totalCampaignsBalance[_currency];
    }

    function totalOutsideCampaignsBalance(IERC20 _currency) external view returns (uint256) {
        return _totalOutsideCampaignsBalance[_currency];
    }

    function projectBalance() external view returns (uint256) {
        return _projectBalance;
    }

    function getCampaignStatus(uint256 _campaignId) public view returns (CampaignStatus currentStatus) {
        CampaignData memory campaignData = _campaigns[_campaignId];

        uint256 target = campaignData.target;
        uint256 softTarget = campaignData.softTarget;
        uint256 raisedAmount = campaignData.raisedAmount;
        uint256 balance = campaignData.balance;
        uint256 endTime = campaignData.endTime;
        uint256 backersDeadline = campaignData.backersDeadline;

        uint256 currentTime = block.timestamp;

        if (raisedAmount == target || (raisedAmount >= softTarget && currentTime > endTime)) {
            if (balance > 0) {
                return CampaignStatus.FUNDED;
            } else {
                return CampaignStatus.SUCCEEDED;
            }
        } else if (currentTime <= endTime) {
            return CampaignStatus.ACTIVE;
        } else if (currentTime <= backersDeadline && balance > 0) {
            return CampaignStatus.NOTFUNDED;
        } else {
            return CampaignStatus.DEFEATED;
        }
    }

    function getProjectStatus() external view returns (bool) {
        return _projectStatus;
    }

    function getFundingAmounts(uint256 _amount)
        external
        view
        returns (
            uint256 currentCampaignId,
            uint256 amountToCampaign,
            uint256 amountToPool,
            bool isFunded
        )
    {
        _onlyStarter();
        currentCampaignId = _numberOfCampaigns - 1;

        if (getCampaignStatus(currentCampaignId) != CampaignStatus.ACTIVE) {
            revert Errors.ProjCampaignNotActive();
        }

        uint256 amountToTarget = _campaigns[currentCampaignId].target - _campaigns[currentCampaignId].balance;

        if (amountToTarget > _amount) {
            amountToCampaign = _amount;
            amountToPool = 0;
            isFunded = false;
        } else {
            amountToCampaign = amountToTarget;
            amountToPool = _amount - amountToCampaign;
            isFunded = true;
        }
    }

    function _onlyStarter() private view {
        if (msg.sender != _starter) {
            revert Errors.ProjOnlyStarter();
        }
    }

    ////////////////////////////////
    // PRIVATE/INTERNAL FUNCTIONS //
    ////////////////////////////////

    function _updateBalances(
        uint256 _campaignId,
        IERC20 _currency,
        uint256 _amount,
        bool _fund
    ) private {
        if (_fund) {
            _campaigns[_campaignId].balance += _amount;
            _campaigns[_campaignId].raisedAmount += _amount;
            _campaignBalance[_campaignId][_currency] += _amount;
            _totalCampaignsBalance[_currency] += _amount;
            _projectBalance += _amount;
        } else {
            _campaigns[_campaignId].balance -= _amount;
            _campaignBalance[_campaignId][_currency] -= _amount;
            _totalCampaignsBalance[_currency] -= _amount;
            _projectBalance -= _amount;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Errors {
    // Starter Errors
    error SttrNotAdmin();
    error SttrNotWhitelistedLab();
    error SttrNotLabOwner();
    error SttrNotCoreTeam();
    error SttrLabAlreadyWhitelisted();
    error SttrLabAlreadyBlacklisted();
    error SttrFundingAmountIsZero();
    error SttrCurrencyAlreadyListed();
    error SttrCurrencyAlreadyUnlisted();
    error SttrMinCampaignDurationError();
    error SttrMaxCampaignDurationError();
    error SttrMinCampaignTargetError();
    error SttrMaxCampaignTargetError();
    error SttrSoftTargetBpsError();
    error SttrLabCannotFundOwnProject();
    error SttrCurrencyNotWhitelisted();
    error SttrBlacklistedLab();
    error SttrCampaignTargetError();
    error SttrCampaignDurationError();
    error SttrERC20TransferError();
    error SttrExistingProjectRequest();
    error SttrNonExistingProjectRequest();
    error SttrInvalidSignature();
    error SttrProjectIsNotActive();
    error SttrResultsCannotBePublished();

    // Project Errors
    error ProjOnlyStarter();
    error ProjBalanceIsZero();
    error ProjCampaignNotActive();
    error ProjERC20TransferError();
    error ProjZeroAmountToWithdraw();
    error ProjCampaignNotDefeated();
    error ProjCampaignNotNotFunded();
    error ProjCampaignNotFunded();
    error ProjCampaignNotSucceededNorFundedNorDefeated();
    error ProjResultsCannotBePublished();
    error ProjCampaignCannotStart();
    error ProjCannotBeClosed();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
}