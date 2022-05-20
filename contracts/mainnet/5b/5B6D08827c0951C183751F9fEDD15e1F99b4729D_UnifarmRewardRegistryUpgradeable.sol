// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

import {OwnableUpgradeable} from './access/OwnableUpgradeable.sol';
import {TransferHelpers} from './library/TransferHelpers.sol';
import {IWETH} from './interfaces/IWETH.sol';
import {Initializable} from './proxy/Initializable.sol';
import {UnifarmRewardRegistryUpgradeableStorage} from './storage/UnifarmRewardRegistryUpgradeableStorage.sol';
import {IUnifarmRewardRegistryUpgradeable} from './interfaces/IUnifarmRewardRegistryUpgradeable.sol';

/// @title UnifarmRewardRegistryUpgradeable Contract
/// @author UNIFARM
/// @notice contract handles rewards mechanism of unifarm cohorts

contract UnifarmRewardRegistryUpgradeable is
    IUnifarmRewardRegistryUpgradeable,
    UnifarmRewardRegistryUpgradeableStorage,
    Initializable,
    OwnableUpgradeable
{
    /**
     * @dev not throws if called by owner or multicall
     */

    modifier onlyMulticallOrOwner() {
        onlyOwnerOrMulticall();
        _;
    }

    /**
     * @dev verifying valid caller
     */

    function onlyOwnerOrMulticall() internal view {
        require(_msgSender() == multiCall || _msgSender() == owner(), 'IS');
    }

    /**
     * @notice initialize the reward registry
     * @param masterAddress master wallet address
     * @param trustedForwarder trusted forwarder address
     * @param multiCall_ multicall contract address
     * @param referralPercentage referral percentage in 3 precised decimals
     */

    function __UnifarmRewardRegistryUpgradeable_init(
        address masterAddress,
        address trustedForwarder,
        address multiCall_,
        uint256 referralPercentage
    ) external initializer {
        __UnifarmRewardRegistryUpgradeable_init_unchained(multiCall_, referralPercentage);
        __Ownable_init(masterAddress, trustedForwarder);
    }

    /**
     * @dev set default referral and multicall
     * @param multiCall_ multicall contract address
     * @param referralPercentage referral percentage in 3 precised decimals
     */

    function __UnifarmRewardRegistryUpgradeable_init_unchained(address multiCall_, uint256 referralPercentage) internal {
        multiCall = multiCall_;
        refPercentage = referralPercentage;
    }

    /**
     * @inheritdoc IUnifarmRewardRegistryUpgradeable
     */

    function updateRefPercentage(uint256 newRefPercentage) external override onlyMulticallOrOwner {
        refPercentage = newRefPercentage;
        emit UpdatedRefPercentage(newRefPercentage);
    }

    /**
     * @inheritdoc IUnifarmRewardRegistryUpgradeable
     */

    function addInfluencers(address[] memory userAddresses, uint256[] memory referralPercentages) external override onlyMulticallOrOwner {
        require(userAddresses.length == referralPercentages.length, 'AIF');
        uint8 usersLength = uint8(userAddresses.length);
        uint8 k;
        while (k < usersLength) {
            referralConfig[userAddresses[k]] = ReferralConfiguration({userAddress: userAddresses[k], referralPercentage: referralPercentages[k]});
            k++;
        }
    }

    /**
     * @inheritdoc IUnifarmRewardRegistryUpgradeable
     */

    function updateMulticall(address newMultiCallAddress) external onlyOwner {
        require(newMultiCallAddress != multiCall, 'SMA');
        multiCall = newMultiCallAddress;
    }

    /**
     * @inheritdoc IUnifarmRewardRegistryUpgradeable
     */

    function setRewardCap(
        address cohortId,
        address[] memory rewardTokenAddresses,
        uint256[] memory rewards
    ) external override onlyMulticallOrOwner returns (bool) {
        require(cohortId != address(0), 'ICI');
        require(rewardTokenAddresses.length == rewards.length, 'IL');
        uint8 rewardTokensLength = uint8(rewardTokenAddresses.length);
        for (uint8 v = 0; v < rewardTokensLength; v++) {
            require(rewards[v] > 0, 'IRA');
            rewardCap[cohortId][rewardTokenAddresses[v]] = rewards[v];
        }
        return true;
    }

    /**
     * @inheritdoc IUnifarmRewardRegistryUpgradeable
     */

    function setRewardTokenDetails(address cohortId, bytes calldata rewards) external onlyMulticallOrOwner {
        require(cohortId != address(0), 'ICI');
        _rewards[cohortId] = rewards;
        emit SetRewardTokenDetails(cohortId, rewards);
    }

    /**
     * @inheritdoc IUnifarmRewardRegistryUpgradeable
     */

    function getRewardTokens(address cohortId) public view returns (address[] memory rewardTokens, uint256[] memory pbr) {
        bytes memory rewardByte = _rewards[cohortId];
        (rewardTokens, pbr) = abi.decode(rewardByte, (address[], uint256[]));
    }

    /**
     * @inheritdoc IUnifarmRewardRegistryUpgradeable
     */

    function getInfluencerReferralPercentage(address influencerAddress) public view override returns (uint256 referralPercentage) {
        ReferralConfiguration memory referral = referralConfig[influencerAddress];
        bool isConfigurationAvailable = referral.userAddress != address(0);
        if (isConfigurationAvailable) {
            referralPercentage = referral.referralPercentage;
        } else {
            referralPercentage = refPercentage;
        }
    }

    /**
     * @dev performs single token transfer to user
     * @param cohortId cohort contract address
     * @param rewardTokenAddress reward token address
     * @param user user address
     * @param referralAddress influencer address
     * @param referralPercentage referral percentage
     * @param pbr1 per block reward for first reward token
     * @param rValue Aggregated R Value
     * @param hasContainWrapToken has reward contain wToken
     */

    function sendOne(
        address cohortId,
        address rewardTokenAddress,
        address user,
        address referralAddress,
        uint256 referralPercentage,
        uint256 pbr1,
        uint256 rValue,
        bool hasContainWrapToken
    ) internal {
        uint256 rewardValue = (pbr1 * rValue) / (1e12);
        require(rewardCap[cohortId][rewardTokenAddress] >= rewardValue, 'RCR');
        uint256 refEarned = (rewardValue * referralPercentage) / (100000);
        uint256 userEarned = rewardValue - refEarned;
        bool zero = referralAddress != address(0);
        if (hasContainWrapToken) {
            IWETH(rewardTokenAddress).withdraw(rewardValue);
            if (zero) TransferHelpers.safeTransferParentChainToken(referralAddress, refEarned);
            TransferHelpers.safeTransferParentChainToken(user, userEarned);
        } else {
            if (zero) TransferHelpers.safeTransfer(rewardTokenAddress, referralAddress, refEarned);
            TransferHelpers.safeTransfer(rewardTokenAddress, user, userEarned);
        }
        rewardCap[cohortId][rewardTokenAddress] = rewardCap[cohortId][rewardTokenAddress] - rewardValue;
    }

    /**
     * @dev perform multi token transfers to user
     * @param cohortId cohort contract address
     * @param rewardTokens array of reward token addresses
     * @param pbr array of per block rewards
     * @param userAddress user address
     * @param referralAddress influencer address
     * @param referralPercentage referral percentage
     * @param rValue Aggregated R Value
     */

    function sendMulti(
        address cohortId,
        address[] memory rewardTokens,
        uint256[] memory pbr,
        address userAddress,
        address referralAddress,
        uint256 referralPercentage,
        uint256 rValue
    ) internal {
        uint8 rTokensLength = uint8(rewardTokens.length);
        for (uint8 r = 1; r < rTokensLength; r++) {
            uint256 exactReward = (pbr[r] * rValue) / 1e12;
            require(rewardCap[cohortId][rewardTokens[r]] >= exactReward, 'RCR');
            uint256 refEarned = (exactReward * referralPercentage) / 100000;
            uint256 userEarned = exactReward - refEarned;
            if (referralAddress != address(0)) TransferHelpers.safeTransfer(rewardTokens[r], referralAddress, refEarned);
            TransferHelpers.safeTransfer(rewardTokens[r], userAddress, userEarned);
            rewardCap[cohortId][rewardTokens[r]] = rewardCap[cohortId][rewardTokens[r]] - exactReward;
        }
    }

    /**
     * @inheritdoc IUnifarmRewardRegistryUpgradeable
     */

    function distributeRewards(
        address cohortId,
        address userAddress,
        address influcenerAddress,
        uint256 rValue,
        bool hasContainsWrappedToken
    ) external override {
        require(_msgSender() == cohortId, 'IS');
        (address[] memory rewardTokens, uint256[] memory pbr) = getRewardTokens(cohortId);
        uint256 referralPercentage = getInfluencerReferralPercentage(influcenerAddress);
        sendOne(cohortId, rewardTokens[0], userAddress, influcenerAddress, referralPercentage, pbr[0], rValue, hasContainsWrappedToken);
        sendMulti(cohortId, rewardTokens, pbr, userAddress, influcenerAddress, referralPercentage, rValue);
    }

    /**
     * @inheritdoc IUnifarmRewardRegistryUpgradeable
     */

    function safeWithdrawEth(address withdrawableAddress, uint256 amount) external onlyOwner returns (bool) {
        require(withdrawableAddress != address(0), 'IWA');
        TransferHelpers.safeTransferParentChainToken(withdrawableAddress, amount);
        return true;
    }

    /**
     * @inheritdoc IUnifarmRewardRegistryUpgradeable
     */

    function safeWithdrawAll(
        address withdrawableAddress,
        address[] memory tokens,
        uint256[] memory amounts
    ) external onlyOwner {
        require(withdrawableAddress != address(0), 'IWA');
        require(tokens.length == amounts.length, 'SF');
        uint8 i = 0;
        uint8 tokensLength = uint8(tokens.length);
        while (i < tokensLength) {
            TransferHelpers.safeTransfer(tokens[i], withdrawableAddress, amounts[i]);
            i++;
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: GNU GPLv3

// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

pragma solidity =0.8.9;

import {ERC2771ContextUpgradeable} from '../metatx/ERC2771ContextUpgradeable.sol';
import {Initializable} from '../proxy/Initializable.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner
 */

abstract contract OwnableUpgradeable is Initializable, ERC2771ContextUpgradeable {
    address private _owner;
    address private _master;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner
     */
    function __Ownable_init(address master, address trustedForwarder) internal initializer {
        __Ownable_init_unchained(master);
        __ERC2771ContextUpgradeable_init(trustedForwarder);
    }

    function __Ownable_init_unchained(address masterAddress) internal initializer {
        _transferOwnership(_msgSender());
        _master = masterAddress;
    }

    /**
     * @dev Returns the address of the current owner
     * @return _owner - _owner address
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), 'ONA');
        _;
    }

    /**
     * @dev Throws if called by any account other than the master
     */
    modifier onlyMaster() {
        require(_master == _msgSender(), 'OMA');
        _;
    }

    /**
     * @dev Transfering the owner ship to master role in case of emergency
     *
     * NOTE: Renouncing ownership will transfer the contract ownership to master role
     */

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(_master);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`)
     * Can only be called by the current owner
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'INA');
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`)
     * Internal function without access restriction
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

interface IUnifarmRewardRegistryUpgradeable {
    /**
     * @notice function is used to distribute cohort rewards
     * @dev only cohort contract can access this function
     * @param cohortId cohort contract address
     * @param userAddress user wallet address
     * @param influencerAddress influencer wallet address
     * @param rValue Aggregated R value
     * @param hasContainsWrappedToken has contain wrap token in rewards
     */

    function distributeRewards(
        address cohortId,
        address userAddress,
        address influencerAddress,
        uint256 rValue,
        bool hasContainsWrappedToken
    ) external;

    /**
     * @notice admin can add more influencers with some percentage
     * @dev can only be called by owner or multicall
     * @param userAddresses list of influencers wallet addresses
     * @param referralPercentages list of referral percentages
     */

    function addInfluencers(address[] memory userAddresses, uint256[] memory referralPercentages) external;

    /**
     * @notice update multicall contract address
     * @dev only called by owner access
     * @param newMultiCallAddress new multicall address
     */

    function updateMulticall(address newMultiCallAddress) external;

    /**
     * @notice update default referral percenatge
     * @dev can only be called by owner or multicall
     * @param newRefPercentage referral percentage in 3 decimals
     */

    function updateRefPercentage(uint256 newRefPercentage) external;

    /**
     * @notice set reward tokens for a particular cohort
     * @dev function can be called by only owner
     * @param cohortId cohort contract address
     * @param rewards per block rewards in bytes
     */

    function setRewardTokenDetails(address cohortId, bytes calldata rewards) external;

    /**
     * @notice set reward cap for particular cohort
     * @dev function can be called by only owner
     * @param cohortId cohort address
     * @param rewardTokenAddresses reward token addresses
     * @param rewards rewards available
     * @return Transaction Status
     */

    function setRewardCap(
        address cohortId,
        address[] memory rewardTokenAddresses,
        uint256[] memory rewards
    ) external returns (bool);

    /**
     * @notice rescue ethers
     * @dev can called by only owner in rare sitution
     * @param withdrawableAddress withdrawable address
     * @param amount to send
     * @return Transaction Status
     */

    function safeWithdrawEth(address withdrawableAddress, uint256 amount) external returns (bool);

    /**
      @notice withdraw list of erc20 tokens in emergency sitution
      @dev can called by only owner on worst sitution  
      @param withdrawableAddress withdrawble wallet address
      @param tokens list of token address
      @param amounts list of amount to withdraw
     */

    function safeWithdrawAll(
        address withdrawableAddress,
        address[] memory tokens,
        uint256[] memory amounts
    ) external;

    /**
     * @notice derive reward tokens for a specfic cohort
     * @param cohortId cohort address
     * @return rewardTokens array of reward token address
     * @return pbr array of per block reward
     */

    function getRewardTokens(address cohortId) external view returns (address[] memory rewardTokens, uint256[] memory pbr);

    /**
     * @notice get influencer referral percentage
     * @return referralPercentage the referral percentage
     */

    function getInfluencerReferralPercentage(address influencerAddress) external view returns (uint256 referralPercentage);

    /**
     * @notice emit when referral percetage updated
     * @param newRefPercentage - new referral percentage
     */
    event UpdatedRefPercentage(uint256 newRefPercentage);

    /**
     * @notice set reward token details
     * @param cohortId - cohort address
     * @param rewards - list of token address and rewards
     */
    event SetRewardTokenDetails(address indexed cohortId, bytes rewards);
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

interface IWETH {
    /**
     * @dev deposit eth to the contract
     */

    function deposit() external payable;

    /**
     * @dev transfer allows to transfer to a wallet or contract address
     * @param to recipient address
     * @param value amount to be transfered
     * @return Transfer status.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev allow to withdraw weth from contract
     */

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

// solhint-disable  avoid-low-level-calls

/// @title TransferHelpers library
/// @author UNIFARM
/// @notice handles token transfers and ethereum transfers for protocol
/// @dev all the functions are internally used in the protocol

library TransferHelpers {
    /**
     * @dev make sure about approval before use this function
     * @param target A ERC20 token address
     * @param sender sender wallet address
     * @param recipient receiver wallet Address
     * @param amount number of tokens to transfer
     */

    function safeTransferFrom(
        address target,
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = target.call(abi.encodeWithSelector(0x23b872dd, sender, recipient, amount));
        require(success && data.length > 0, 'STFF');
    }

    /**
     * @notice transfer any erc20 token
     * @param target ERC20 token address
     * @param to receiver wallet address
     * @param amount number of tokens to transfer
     */

    function safeTransfer(
        address target,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = target.call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && data.length > 0, 'STF');
    }

    /**
     * @notice transfer parent chain token
     * @param to receiver wallet address
     * @param value of eth to transfer
     */

    function safeTransferParentChainToken(address to, uint256 value) internal {
        (bool success, ) = to.call{value: uint128(value)}(new bytes(0));
        require(success, 'STPCF');
    }
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

import {Initializable} from '../proxy/Initializable.sol';

/**
 * @dev Context variant with ERC2771 support
 */

// solhint-disable
abstract contract ERC2771ContextUpgradeable is Initializable {
    /**
     * @dev holds the trust forwarder
     */

    address public trustedForwarder;

    /**
     * @dev context upgradeable initializer
     * @param tForwarder trust forwarder
     */

    function __ERC2771ContextUpgradeable_init(address tForwarder) internal initializer {
        __ERC2771ContextUpgradeable_init_unchained(tForwarder);
    }

    /**
     * @dev called by initializer to set trust forwarder
     * @param tForwarder trust forwarder
     */

    function __ERC2771ContextUpgradeable_init_unchained(address tForwarder) internal {
        trustedForwarder = tForwarder;
    }

    /**
     * @dev check if the given address is trust forwarder
     * @param forwarder forwarder address
     * @return isForwarder true/false
     */

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * @dev if caller is trusted forwarder will return exact sender.
     * @return sender wallet address
     */

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    /**
     * @dev returns msg data for called function
     * @return function call data
     */

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity =0.8.9;

import '../utils/AddressUpgradeable.sol';

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
 * Avoid leaving a contract uninitialized
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
     * @dev Indicates that the contract has been initialized
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered
        require(_initializing ? _isConstructor() : !_initialized, 'CIAI');

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
     * {initializer} modifier, directly or indirectly
     */
    modifier onlyInitializing() {
        require(_initializing, 'CINI');
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

abstract contract UnifarmRewardRegistryUpgradeableStorage {
    // solhint-disable-next-line
    receive() external payable {}

    /// @notice referral percentage
    uint256 public refPercentage;

    /// @notice struct to store referral commision for each unifarm influceners.
    struct ReferralConfiguration {
        // influencer wallet address.
        address userAddress;
        // decided referral percentage
        uint256 referralPercentage;
    }

    /// @notice reward cap
    mapping(address => mapping(address => uint256)) public rewardCap;

    /// @notice mapping for storing reward per block.
    mapping(address => bytes) internal _rewards;

    /// @notice Referral Configuration
    mapping(address => ReferralConfiguration) public referralConfig;

    /// @notice add multicall support
    address public multiCall;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity =0.8.9;

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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        require(isContract(target), 'Address: call to non-contract');

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
        return functionStaticCall(target, data, 'Address: low-level static call failed');
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
        require(isContract(target), 'Address: static call to non-contract');

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