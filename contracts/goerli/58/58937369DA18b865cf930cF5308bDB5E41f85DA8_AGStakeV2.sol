// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

interface IAlphaGang {
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}

interface IGangToken {
    function mint(address to, uint256 amount) external;
}

contract AGStakeV2 is ERC1155HolderUpgradeable, OwnableUpgradeable {
    event Stake(address owner, uint256 tokenId, uint256 count);
    event Unstake(address owner, uint256 tokenId, uint256 count);
    event StakeAll(address owner, uint256[] tokenIds, uint256[] counts);
    event UnstakeAll(address owner, uint256[] tokenIds, uint256[] counts);

    /**
     * Event called when a stake is claimed by user
     * Args:
     * owner: address for which it was claimed
     * amount: amount of $GANG tokens claimed
     * count: count of staked(hard or soft) tokens
     * multiplier: flag indicating wheat the applied multiplier is
     */
    event Claim(
        address owner,
        uint256 amount,
        uint256 count,
        uint256 multiplier
    );

    // references to the AG contracts
    IAlphaGang alphaGang;
    IGangToken gangToken;

    uint256 public ogStakeRate;
    uint256 public softStakeRate;

    // maps tokenId to stake
    mapping(uint256 => mapping(address => uint256)) public vault;
    // records block timestamp when last claim occured
    mapping(address => uint256) public lastClaim;
    mapping(address => uint256) public lastSoftClaim;
    // default start time for claiming rewards
    uint256 public START;

    // constructor(
    //     IAlphaGang _nft,
    //     IGangToken _token,
    //     address[] memory _owners,
    //     uint256[][] memory tokens // uint256[] memory timestamp, // uint256[] memory timestampSoft
    // ) {
    //     alphaGang = _nft;
    //     gangToken = _token;
    //     START = block.timestamp;
    //     registerVault(_owners, tokens); // , timestamp, timestampSoft
    // }

    function initialize(
        IAlphaGang _nft,
        IGangToken _token,
        address[] memory _owners,
        uint256[][] memory tokens
    ) external {
        alphaGang = _nft;
        gangToken = _token;
        registerVault(_owners, tokens);

        ogStakeRate = 496031746031746;
        softStakeRate = 124007936507936;
        START = 1651556570;
    }

    function stakeSingle(uint256 tokenId, uint256 tokenCount) external {
        address _owner = msg.sender;

        // claim unstaked tokens, since count/rate will change
        claimForAddress(_owner, true);
        claimForAddress(_owner, false);

        alphaGang.safeTransferFrom(
            _owner,
            address(this),
            tokenId,
            tokenCount,
            ""
        );

        unchecked {
            vault[tokenId][_owner] += tokenCount;
        }

        emit Stake(_owner, tokenId, tokenCount);
    }

    function unstakeSingle(uint256 tokenId, uint256 tokenCount) external {
        address _owner = msg.sender;
        uint256 totalStaked = vault[tokenId][_owner];

        require(
            totalStaked >= 0,
            "You do have any tokens available for unstaking"
        );
        require(
            totalStaked >= tokenCount,
            "You do not have requested token amount available for unstaking"
        );

        // claim rewards before unstaking
        claimForAddress(_owner, true);
        claimForAddress(_owner, false);
        unchecked {
            vault[tokenId][_owner] -= tokenCount;
        }

        alphaGang.safeTransferFrom(
            address(this),
            _owner,
            tokenId,
            tokenCount,
            ""
        );

        emit Unstake(msg.sender, tokenId, tokenCount);
    }

    function _stakeAll() internal {
        address _owner = msg.sender;
        uint256[] memory totalAvailable = unstakedBalanceOf(_owner);

        uint256[] memory tokens = new uint256[](3);
        tokens[0] = 1;
        tokens[1] = 2;
        tokens[2] = 3;

        alphaGang.safeBatchTransferFrom(
            _owner,
            address(this),
            tokens,
            totalAvailable,
            ""
        );

        // loop over and update the vault
        unchecked {
            for (uint32 i = 1; i < 4; i++) {
                vault[i][_owner] += totalAvailable[i - 1];
            }
        }

        emit StakeAll(msg.sender, tokens, totalAvailable);
    }

    function _unstakeAll() internal {
        address _owner = msg.sender;
        uint256[] memory totalStaked = stakedBalanceOf(_owner);

        uint256[] memory tokens = new uint256[](3);
        tokens[0] = 1;
        tokens[1] = 2;
        tokens[2] = 3;

        // loop over and update the vault
        unchecked {
            for (uint32 i = 1; i < 4; i++) {
                vault[i][_owner] -= totalStaked[i - 1];
            }
        }

        alphaGang.safeBatchTransferFrom(
            address(this),
            _owner,
            tokens,
            totalStaked,
            ""
        );

        emit UnstakeAll(_owner, tokens, totalStaked);
    }

    /** Views */
    function stakedBalanceOf(address account)
        public
        view
        returns (uint256[] memory _tokenBalance)
    {
        uint256[] memory tokenBalance = new uint256[](3);

        unchecked {
            for (uint32 i = 1; i < 4; i++) {
                uint256 stakedCount = vault[i][account];
                if (stakedCount > 0) {
                    tokenBalance[i - 1] += stakedCount;
                }
            }
        }
        return tokenBalance;
    }

    function unstakedBalanceOf(address account)
        public
        view
        returns (uint256[] memory _tokenBalance)
    {
        // This consumes ~4k gas less than batchBalanceOf with address array
        uint256[] memory totalTokenBalance = new uint256[](3);
        totalTokenBalance[0] = alphaGang.balanceOf(account, 1);
        totalTokenBalance[1] = alphaGang.balanceOf(account, 2);
        totalTokenBalance[2] = alphaGang.balanceOf(account, 3);

        return totalTokenBalance;
    }

    /**
     * Contract addresses referencing functions in case we make a mistake in constructor settings
     */
    function setAlphaGang(address _alphaGang) external onlyOwner {
        alphaGang = IAlphaGang(_alphaGang);
    }

    function setGangToken(address _gangToken) external onlyOwner {
        gangToken = IGangToken(_gangToken);
    }

    /**
     * FE Call fns
     */
    function claim() external {
        _claim(msg.sender);
    }

    function claimSoft() external {
        _claimSoft(msg.sender);
    }

    function claimForAddress(address account, bool hardStake) public {
        if (hardStake) {
            _claim(account);
        } else {
            _claimSoft(account);
        }
    }

    function stakeAll() external {
        _claim(msg.sender);
        _claimSoft(msg.sender);
        _stakeAll();
    }

    function unstakeAll() external {
        _claim(msg.sender);
        _claimSoft(msg.sender);
        _unstakeAll();
    }

    function _claim(address account) internal {
        uint256 stakedAt = lastClaim[account] >= START
            ? lastClaim[account]
            : START;

        uint256 tokenCount = 0;

        // bonus of 6.25% is applied for holding all 3 assets(can only be applied once)
        uint256 triBonusCount = 0;

        // 300 per week for hard, 75 for soft staked
        uint256 stakeRate = 496031746031746;

        uint256[] memory stakedCount = stakedBalanceOf(account);

        unchecked {
            for (uint32 i; i < 3; i++) {
                if (stakedCount[i] > 0) {
                    tokenCount += stakedCount[i];
                    triBonusCount++;
                }
            }
        }
        uint256 timestamp = block.timestamp;

        lastClaim[account] = timestamp;
        if (tokenCount > 0) {
            // 35%, 52.5%, 61.25% | Order: 50, Mac, Riri
            uint256 bonusBase = 350_000;
            uint256 bonus = 1_000_000; // multiplier of 1

            unchecked {
                // calculate total bonus to be applied, start adding bonus for more hodls
                for (uint32 j = 1; j < tokenCount; j++) {
                    bonus += bonusBase;
                    bonusBase /= 2;
                }

                // triBonus for holding all 3 OGs
                if (triBonusCount == 3) {
                    bonus += 87_500;
                }
            }

            uint256 earned = ((timestamp - stakedAt) * bonus * stakeRate) /
                1_000_000;

            gangToken.mint(account, earned);

            emit Claim(account, earned, tokenCount, bonus);
        }
    }

    function _claimSoft(address account) internal {
        // To start soft staking you will have to claim once
        uint256 stakedAt = lastSoftClaim[account];

        uint256 tokenCount = 0;

        uint256 stakeRate = 124007936507936;

        uint256[] memory stakedCount = unstakedBalanceOf(account);

        unchecked {
            for (uint32 i; i < 3; i++) {
                if (stakedCount[i] > 0) {
                    tokenCount++;
                    break;
                }
            }
        }
        uint256 timestamp = block.timestamp;

        lastClaim[account] = timestamp;

        if (tokenCount > 0) {
            uint256 earned = ((timestamp - stakedAt) * stakeRate);

            lastSoftClaim[account] = timestamp;

            gangToken.mint(account, earned);

            emit Claim(account, earned, tokenCount, block.timestamp);
        }
    }

    function getSoftPendingRewards(address account)
        external
        view
        returns (uint256 rewards)
    {
        uint256 stakedAt = lastSoftClaim[account] >= START
            ? lastSoftClaim[account]
            : START;

        uint256 tokenCount = 0;

        uint256 stakeRate = 124007936507936;

        uint256[] memory stakedCount = unstakedBalanceOf(account);

        unchecked {
            for (uint32 i; i < 3; i++) {
                if (stakedCount[i] > 0) {
                    tokenCount++;
                    break;
                }
            }
        }
        if (tokenCount == 0) {
            return 0;
        }
        uint256 timestamp = block.timestamp;

        uint256 earned = ((timestamp - stakedAt) * stakeRate);
        return earned;
    }

    function getPendingRewards(address account)
        external
        view
        returns (uint256 rewards)
    {
        uint256 stakedAt = lastClaim[account] >= START
            ? lastClaim[account]
            : START;

        uint256 tokenCount = 0;

        // bonus of 6.25% is applied for holding all 3 assets(can only be applied once)
        uint256 triBonusCount = 0;

        uint256 stakeRate = 496031746031746;

        uint256[] memory stakedCount = stakedBalanceOf(account);

        unchecked {
            for (uint32 i; i < 3; i++) {
                if (stakedCount[i] > 0) {
                    tokenCount += stakedCount[i];
                    triBonusCount++;
                }
            }
        }
        if (tokenCount == 0) {
            return 0;
        }
        // 35%, 52.5%, 61.25% | Order: 50, Mac, Riri
        uint256 bonusBase = 350_000;
        uint256 bonus = 1_000_000; // multiplier of 1

        unchecked {
            // calculate total bonus to be applied, start adding bonus for more hodls
            for (uint32 j = 1; j < tokenCount; j++) {
                bonus += bonusBase;
                bonusBase /= 2;
            }

            // triBonus for holding all 3 OGs
            if (triBonusCount == 3) {
                bonus += 87_500;
            }
        }

        uint256 timestamp = block.timestamp;

        uint256 earned = ((timestamp - stakedAt) * bonus * stakeRate) /
            1_000_000;

        return earned;
    }

    function setStakeRate(uint256 _newRate, bool isOGRate) external onlyOwner {
        if (isOGRate) {
            ogStakeRate = _newRate;
        } else {
            softStakeRate = _newRate;
        }
    }

    /**
     * Vault functions
     */
    function registerVault(address[] memory _owners, uint256[][] memory tokens)
        public
        onlyOwner
    {
        require(_owners.length == tokens.length, "Lengths must match!");
        // require(
        //     timestamp.length == timestampSoft.length,
        //     "Lengths must match!"
        // );

        for (uint256 i; i < _owners.length; i++) {
            for (uint256 j; j < 3; j++) {
                if (tokens[i][j] > 0) {
                    vault[j][_owners[i]] = tokens[i][j];
                }
            }
        }
    }

    function registerTimestamps(
        address[] memory _owners,
        uint256[] memory timestamp
    ) public onlyOwner {
        for (uint256 i; i < _owners.length; i++) {
            lastClaim[_owners[i]] = timestamp[i];
            // lastSoftClaim[_owners[i]] = timestampSoft[i];
        }
    }

    function setVaultEntry(address _owner, uint256[] memory tokens)
        external
        onlyOwner
    {
        for (uint256 i; i < 3; i++) {
            if (tokens[i] > 0) {
                vault[i + 1][_owner] = tokens[i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
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