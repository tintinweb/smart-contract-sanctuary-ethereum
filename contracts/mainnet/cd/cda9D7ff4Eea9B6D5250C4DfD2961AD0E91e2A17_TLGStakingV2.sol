// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IOldStaking.sol";
import "./interfaces/IMintable.sol";

contract TLGStakingV2 is Initializable, OwnableUpgradeable, IStaking {
    struct StakerReward {
        uint256 lastUpdated;
        uint256 unclaimed;
    }

    uint256 public constant ROUNDING_PRECISION = 1000;
    uint256 public lostPerDay;

    IOldStaking public oldStaking;
    IERC721Upgradeable public tlgNfts;
    IERC721Upgradeable public comic;
    IMintable public lost;

    mapping(uint256 => address) public userStakedGlitch;
    mapping(address => uint256[]) public stakedGlitches;
    mapping(address => uint256) public override stakedComic;
    mapping(address => StakerReward) public rewards;
    mapping(address => mapping(uint256 => uint256)) public stakedGlitchIndex;

    struct NumValue {
        uint256 value;
        bool exists;
    }

    struct BoolValue {
        bool value;
        bool exists;
    }

    /**
     * A mapping that remembers how many glitches an address has staked in the old
     * contract when first interacting with this contract. After that, this contract
     * will not accept new staked glitches in the old contract.
     */
    mapping(address => NumValue) public stakedGlitchesInOldContractInitially;

    /**
     * See `stakedInOldContractInitially`. This is the same just for comics.
     */
    mapping(address => BoolValue) public stakedComicInOldContractInitially;

    event DepositedGlitches(address indexed staker, uint256[] indexed ids);
    event DepositedComic(address indexed staker, uint256 indexed id);
    event WithdrawnGlitches(address indexed staker, uint256[] indexed ids);
    event WithdrawnComic(address indexed staker, uint256 indexed id);
    event ClaimedRewards(address indexed staker, uint256 indexed amount);
    event UpdateUnclaimedRewards(
        address indexed staker,
        uint256 indexed newReward,
        uint256 indexed oldReward,
        uint256 duration
    );

    function initialize(IOldStaking _oldStaking, IERC721Upgradeable _tlgNfts, IERC721Upgradeable _comic, IMintable _lost) external initializer {
        oldStaking = _oldStaking;
        tlgNfts = _tlgNfts;
        comic = _comic;
        lost = _lost;

        lostPerDay = 1;

        __Ownable_init();
    }

    function balanceOf(address owner) public override view returns (uint256) {
        require(owner != address(0), "TLGStakingV2: balance query for the zero address");
        return stakedGlitches[owner].length;
    }

    function ownerOf(uint256 tokenId) public override view returns (address) {
        return userStakedGlitch[tokenId];
    }

    function numberOfDepositedGlitches(address staker) public override view returns (uint256 amount) {
        return stakedGlitches[staker].length;
    }

    function numberOfDepositedGlitchesCombined(address staker) public view returns (uint256 amount) {
        return numberOfDepositedGlitches(staker) +
            min(oldStaking.numberOfDepositedGlitches(staker), stakedGlitchesInOldContractInitially[staker].value);
    }

    function hasComicStakedCombined(address staker) public view returns (bool) {
        bool stakedInOld = stakedComicInOldContractInitially[staker].value;
        if (oldStaking.stakedComic(staker) == 0) {
            stakedInOld = false;
        }

        return stakedComic[staker] != 0 || stakedInOld;
    }

    function depositComic(uint256 comicId) external {
        require(comicId != 0, "TLGStakingV2: Comic 0 currently not stakeable");
        require(!hasComicStakedCombined(msg.sender), "TLGStakingV2: Already staked one comic");

        _setStakedComicInOldContractInitially(msg.sender);
        _updateUnclaimedRewards(msg.sender);

        stakedComic[msg.sender] = comicId;
        comic.transferFrom(msg.sender, address(this), comicId);

        emit DepositedComic(msg.sender, comicId);
    }

    function withdrawComic(uint256 comicId) external {
        require(stakedComic[msg.sender] == comicId, "TLGStakingV2: Comic not staked");

        _updateUnclaimedRewards(msg.sender);

        delete stakedComic[msg.sender];
        comic.transferFrom(address(this), msg.sender, comicId);

        emit WithdrawnComic(msg.sender, comicId);
    }

    function depositGlitches(uint256[] calldata glitches) external {
        _setStakedGlitchesInOldContractInitially(msg.sender);
        _updateUnclaimedRewards(msg.sender);

        for (uint256 i = 0; i < glitches.length; i++) {
            // add glitch to the list and update staking info
            stakedGlitches[msg.sender].push(glitches[i]);
            stakedGlitchIndex[msg.sender][glitches[i]] = stakedGlitches[msg.sender].length - 1;
            userStakedGlitch[glitches[i]] = msg.sender;
            tlgNfts.transferFrom(msg.sender, address(this), glitches[i]);
        }

        emit DepositedGlitches(msg.sender, glitches);
    }

    function withdrawGlitches(uint256[] calldata _glitches) external {
        require(stakedGlitches[msg.sender].length > 0, "TLGStakingV2: No glitches staked");

        _updateUnclaimedRewards(msg.sender);

        for (uint256 i = 0; i < _glitches.length; i++) {
            require(userStakedGlitch[_glitches[i]] == msg.sender, "TLGStakingV2: You do not own this glitch");
            // remove glitch from stakedGlitches
            uint256 index = stakedGlitchIndex[msg.sender][_glitches[i]];
            if (stakedGlitches[msg.sender].length - 1 == index) {
                stakedGlitches[msg.sender].pop();
            } else {
                stakedGlitches[msg.sender][index] = stakedGlitches[msg.sender][stakedGlitches[msg.sender].length - 1];
                stakedGlitchIndex[msg.sender][stakedGlitches[msg.sender][index]] = index;
                stakedGlitches[msg.sender].pop();
            }
            // remove the staking info and the index
            delete stakedGlitchIndex[msg.sender][_glitches[i]];
            delete userStakedGlitch[_glitches[i]];

            tlgNfts.transferFrom(address(this), msg.sender, _glitches[i]);
        }

        emit WithdrawnGlitches(msg.sender, _glitches);
    }

    function claimRewards() external {
        require(rewards[msg.sender].lastUpdated != 0, "TLGStakingV2: Rewards have never been updated");
        _updateUnclaimedRewards(msg.sender);
        lost.mint(msg.sender, rewards[msg.sender].unclaimed);
        emit ClaimedRewards(msg.sender, rewards[msg.sender].unclaimed);
        rewards[msg.sender].unclaimed = 0;
    }

    function currentMultiplier(address staker) public view returns (uint256 amount) {
        uint256 numOfStakedGlitches = numberOfDepositedGlitchesCombined(staker);

        if (numOfStakedGlitches == 1) {
            return 1 * ROUNDING_PRECISION;
        }

        uint256 multi = (numOfStakedGlitches * ROUNDING_PRECISION) / 10 + ROUNDING_PRECISION;
        if (multi > 2 * ROUNDING_PRECISION) {
            multi = 2 * ROUNDING_PRECISION;
        }
        return multi;
    }

    function _setStakedGlitchesInOldContractInitially(address staker) internal {
        if (!stakedGlitchesInOldContractInitially[msg.sender].exists) {
            stakedGlitchesInOldContractInitially[msg.sender] = NumValue({
                value: oldStaking.numberOfDepositedGlitches(msg.sender),
                exists: true
            });
        }
    }

    function _setStakedComicInOldContractInitially(address staker) internal {
        if (!stakedComicInOldContractInitially[staker].exists) {
            stakedComicInOldContractInitially[staker] = BoolValue({
                value: oldStaking.stakedComic(staker) != 0,
                exists: true
            });
        }
    }

    function _updateUnclaimedRewards(address staker) internal {
        uint256 newReward = _calculateNewRewards(staker);
        emit UpdateUnclaimedRewards(
            staker,
            newReward,
            rewards[msg.sender].unclaimed,
            block.timestamp - rewards[msg.sender].lastUpdated
        );
        rewards[msg.sender].lastUpdated = block.timestamp;
        rewards[msg.sender].unclaimed += newReward;
    }

    function _calculateNewRewards(address staker) internal view returns (uint256) {
        if (rewards[staker].lastUpdated == 0) {
            return 0;
        }
        uint256 numGlitches = numberOfDepositedGlitchesCombined(staker);
        uint256 newReward;
        uint256 diff = block.timestamp - rewards[staker].lastUpdated;
        uint256 daysDiff = diff / 1 days;
        uint256 dailyReward = daysDiff * lostPerDay * numGlitches;

        uint256 multi = currentMultiplier(staker);
        dailyReward = dailyReward * multi;
        newReward = (dailyReward * 1e18) / ROUNDING_PRECISION;

        if (hasComicStakedCombined(staker)) {
            newReward = (newReward * 12) / 10;
        }

        return newReward;
    }

    function calculateRewards(address staker) external view returns (uint256) {
        uint256 newReward = _calculateNewRewards(staker);
        return newReward + rewards[staker].unclaimed;
    }

    function addRewards(address[] memory stakers, uint256[] memory amounts, bool sub) external onlyOwner {
        require(stakers.length == amounts.length, "TLGStakingV2: Not same length!");
        for (uint256 i = 0; i < stakers.length; i++) {
            _setStakedGlitchesInOldContractInitially(stakers[i]);
            _setStakedComicInOldContractInitially(stakers[i]);
            if (sub) {
                rewards[stakers[i]].unclaimed -= amounts[i];
            } else {
                rewards[stakers[i]].unclaimed += amounts[i];
            }
            rewards[stakers[i]].lastUpdated = block.timestamp;
        }
    }

    /**
     * Just for utility
     */
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a >= b ? b : a;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
pragma solidity ^0.8.2;

interface IStaking {
    function stakedComic(address) external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function ownerOf(uint256) external view returns (address);
    function numberOfDepositedGlitches(address) external view returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IStaking.sol";

interface IOldStaking is IStaking {
    function lastClaimed(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IMintable {
    function mint(address to, uint256 amount) external;
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