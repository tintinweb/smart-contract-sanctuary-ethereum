// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../utils/NZAGuard.sol";

import "./IPrime.sol";
import "./Asset.sol";

/// @title A contract for control Clearpool Prime membership database
contract Prime is Initializable, OwnableUpgradeable, IPrime, NZAGuard {
    using Asset for Asset.Data;

    Asset.Data private _stablecoins;

    uint256 public blocksPerDay;
    uint256 public penaltyRatePerDay;

    /// @dev A record of each member's info, by address
    mapping(address => Member) private _members;

    /// @dev Keep track of the total protocol fee
    uint256 public protocolFeeRate; // from 0 (0%) to 1e18 (100%)
    address public feeCollector;

    /// @notice An event that's emitted when a member is created
    event MemberCreated(address indexed member);
    /// @notice An event that's emitted when a member is whitelisted
    event MemberWhitelisted(address indexed member);
    /// @notice An event that's emitted when a member is blacklisted
    event MemberBlacklisted(address indexed member);

    /// @notice An event that's emitted when a member's riskScore is changed
    event RiskScoreChanged(address indexed member, uint256 score);

    /// @notice An event that's emitted when the value of the blocksPerDay is changed
    event BlocksPerDayUpdated(uint256 oldValue, uint256 newValue);

    /// @notice An event that's emitted when the value of the penaltyRatePerDay is changed
    event PenaltyRatePerDayUpdated(uint256 oldValue, uint256 newValue);

    /// @notice An event that's emitted when the value of the protocolFeeRate is changed
    event ProtocolRateChanged(uint256 oldValue, uint256 newValue);

    /// @notice An event that's emitted when the value of the feeCollector is changed
    event FeeCollectorChanged(address oldValue, address newValue);

    /// @dev Modifier for checking membership record availability
    modifier onlyMember(address _member) {
        require(_members[_member].created, "NPM");
        _;
    }

    function __Prime_init(
        address[] memory stablecoins,
        uint256 blocksPerDay_,
        uint256 penaltyRatePerDay_
    ) external virtual initializer {
        require(blocksPerDay_ > 0, "ZVL");
        require(penaltyRatePerDay_ > 0, "ZVL");
        __Prime_init_unchained(stablecoins, blocksPerDay_, penaltyRatePerDay_);
    }

    /// @dev Let's stick to the 3 main stablecoins USDC, USDT, DAI
    function __Prime_init_unchained(
        address[] memory stablecoins,
        uint256 blocksPerDay_,
        uint256 penaltyRatePerDay_
    ) internal initializer {
        __Ownable_init_unchained();

        blocksPerDay = blocksPerDay_;
        penaltyRatePerDay = penaltyRatePerDay_;

        for (uint256 i = 0; i < stablecoins.length; i++) {
            require(_stablecoins.insert(stablecoins[i]), "TIF");
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @inheritdoc IPrime
     */
    function isMember(address _member) external view override returns (bool) {
        Member storage member = _members[_member];
        return member.created && member.status == MemberStatus.WHITELISTED;
        // TODO: implement check for riskScore
    }

    /**
     * @inheritdoc IPrime
     */
    function borrowRate(uint256 interestRate, uint256 interval)
        external
        view
        override
        returns (uint256)
    {
        uint256 blocksFromSeconds = (blocksPerDay * interval) / 86400;
        uint256 blocksPerYear = blocksPerDay * 365;

        return (interestRate * blocksFromSeconds) / blocksPerYear;
    }

    /**
     * @inheritdoc IPrime
     */
    function penaltyRate(uint256 interval)
        external
        view
        override
        returns (uint256)
    {
        uint256 blocksFromSeconds = (blocksPerDay * interval) / 86400;

        return (penaltyRatePerDay * blocksFromSeconds) / blocksPerDay;
    }

    /**
     * @inheritdoc IPrime
     */
    function isAssetAvailable(address asset)
        external
        view
        override
        nonZA(asset)
        returns (bool)
    {
        return _stablecoins.contains(asset);
    }

    function availableAssets() external view returns (address[] memory) {
        return _stablecoins.getList();
    }

    /**
     * @inheritdoc IPrime
     */
    function membershipOf(address _member)
        external
        view
        override
        returns (Member memory)
    {
        return _members[_member];
    }

    /**
     * @notice Request a membership record
     *
     *
     * @dev Emits a {MemberCreated} event.
     */
    function requestMembership(address _requester) public nonZA(_requester) {
        require(!_members[_requester].created, "MAC");

        _members[_requester] = Member(0, MemberStatus.PENDING, true);
        emit MemberCreated(_requester);
    }

    /**
     * @notice Alter or creates membership record by setting `_member` status and `_riskScore`
     * @param _member The member address
     * @param _riskScore The number up to 100 representing member's score
     *
     * @dev Emits a {MemberCreated} event.
     * @dev Emits a {MemberWhitelisted} event.
     * @dev Emits a {RiskScoreChanged} event.
     */
    function whitelistMember(address _member, uint256 _riskScore)
        external
        nonZA(_member)
        onlyOwner
    {
        Member storage member = _members[_member];

        if (!member.created) {
            requestMembership(_member);
        }

        require(member.status != MemberStatus.WHITELISTED, "AAD");
        require(_riskScore <= 100 && _riskScore > 0, "RSI");

        member.status = MemberStatus.WHITELISTED;
        emit MemberWhitelisted(_member);

        if (member.riskScore != _riskScore) {
            member.riskScore = _riskScore;
            emit RiskScoreChanged(_member, _riskScore);
        }
    }

    /**
     * @notice Alter membership record by setting `_member` status
     * @param _member The member address
     *
     * @dev Emits a {MemberBlacklisted} event.
     */
    function blacklistMember(address _member)
        external
        nonZA(_member)
        onlyMember(_member)
        onlyOwner
    {
        Member storage member = _members[_member];

        require(member.status != MemberStatus.BLACKLISTED, "AAD");

        member.status = MemberStatus.BLACKLISTED;
        emit MemberBlacklisted(_member);
    }

    /**
     * @notice Alter membership record by setting member `_riskScore`
     * @param _member The member address
     * @param _riskScore The number up to 100 representing member's score
     *
     * @dev Emits a {RiskScoreChanged} event.
     */
    function changeMemberRiskScore(address _member, uint256 _riskScore)
        external
        nonZA(_member)
        onlyMember(_member)
        onlyOwner
    {
        require(_riskScore <= 100 && _riskScore > 0, "RSI");

        Member storage member = _members[_member];
        if (member.riskScore != _riskScore) {
            member.riskScore = _riskScore;
            emit RiskScoreChanged(_member, _riskScore);
        }
    }

    function changeProtocolRate(uint256 protocolFeeRate_) external onlyOwner {
        require(protocolFeeRate_ > 0 && protocolFeeRate_ <= 1e18, "PRI");
        /// @dev block owner to update the protocol rate if no collector is set. Could end up in losing tokens
        require(feeCollector != address(0), "PCS");
        
        uint256 currentValue = protocolFeeRate;
        require(protocolFeeRate_ != currentValue, "SAR");
        
        protocolFeeRate = protocolFeeRate_;
        emit ProtocolRateChanged(currentValue, protocolFeeRate_);
    }

    function changeProtocolRateCollector(address protocolCollector_)
        external
        nonZA(protocolCollector_)
        onlyOwner
    {
        address currentValue = feeCollector;
        require(protocolCollector_ != currentValue, "SAR");

        feeCollector = protocolCollector_;
        emit FeeCollectorChanged(currentValue, protocolCollector_);
    }

    function updateBlocksPerDay(uint256 newValue) external onlyOwner {
        require(newValue > 0, "ZVL");

        uint256 currentValue = blocksPerDay;
        require(currentValue != newValue, "AAD");

        blocksPerDay = newValue;
        emit BlocksPerDayUpdated(currentValue, newValue);
    }

    function updatePenaltyRatePerDay(uint256 newValue) external onlyOwner {
        require(newValue > 0, "ZVL");

        uint256 currentValue = penaltyRatePerDay;
        require(currentValue != newValue, "AAD");

        penaltyRatePerDay = newValue;
        emit PenaltyRatePerDayUpdated(currentValue, newValue);
    }

    uint256[44] private __gap;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;

/**
 * @title Interface of the Prime membership contract
 */
interface IPrime {
    /// @notice Member status enum
    enum MemberStatus {
        PENDING,
        WHITELISTED,
        BLACKLISTED
    }

    /// @notice A record of member info
    struct Member {
        uint256 riskScore;
        MemberStatus status;
        bool created;
    }

    /**
     * @notice Check membership status for a given `_member`
     * @param _member The address of member
     * @return Boolean flag containing membership status
     */
    function isMember(address _member) external view returns (bool);

    /**
     * @notice Calculates the borrow rate for a given interest rate and specific interval
     * @param interestRate The interest rate as a percentage number between [0, 100]
     * @param interval The interval in seconds
     * @return The borrow rate as a mantissa between [0, 1e18]
     */
    function borrowRate(
        uint256 interestRate,
        uint256 interval
    ) external view returns (uint256);

    /**
     * @notice Calculates the penalty rate for a given interval
     * @param interval The interval in seconds
     * @return The penalty rate as a mantissa between [0, 1e18]
     */
    function penaltyRate(uint256 interval) external view returns (uint256);

    /**
     * @notice Check Stablecoin existence for a given `asset` address
     * @param asset The address of asset
     * @return Boolean flag containing asset availability
     */
    function isAssetAvailable(address asset) external view returns (bool);

    /**
     * @notice Get membership info for a given `_member`
     * @param _member The address of member
     * @return The member info struct
     */
    function membershipOf(
        address _member
    ) external view returns (Member memory);

    /**
     * @notice Returns current protocol rate value
     * @return The protocol rate as a mantissa between [0, 1e18]
     */
    function protocolFeeRate() external view returns (uint256);

    /**
     * @notice Returns current protocol fee collector address
     * @return address of protocol fee collector
     */
    function feeCollector() external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;

library Asset {
    struct Data {
        mapping(address => bool) flags;
        mapping(address => uint256) addressIndex;
        address[] addresses;
        uint256 id;
    }

    function insert(Data storage self, address asset) internal returns (bool) {
        if (self.flags[asset]) {
            return false;
        }

        self.flags[asset] = true;
        self.addresses.push(asset);
        self.addressIndex[asset] = self.id;
        self.id++;
        return true;
    }

    function contains(
        Data storage self,
        address asset
    ) internal view returns (bool) {
        return self.flags[asset];
    }

    function getList(
        Data storage self
    ) internal view returns (address[] memory) {
        return self.addresses;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;

abstract contract NZAGuard {
    modifier nonZA(address _address) {
        require(_address != address(0), "NZA");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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