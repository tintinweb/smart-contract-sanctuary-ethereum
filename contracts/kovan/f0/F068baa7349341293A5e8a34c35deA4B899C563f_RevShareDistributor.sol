// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "./OdysseyXP.sol";

contract RevShareDistributor is Initializable, OwnableUpgradeable, KeeperCompatible {
    struct LevelAllocation {
        uint256 numUsers;
        uint256 xpPerUser;
    }

    uint256[] public xpLevelDistributions;

    uint256 public prevBalance;
    uint256 public epochClaimedAmount;
    mapping(address => uint256) balances;

    OdysseyXP public xpContract;
    IERC20Upgradeable public gOhmContract;

    uint256 public interval;
    uint256 public lastTimeStamp;

    function initialize(
        uint256[] memory _xpLevelDistributions,
        address _xpContract,
        address _gOhmContract,
        uint256 _interval
    ) public initializer {
        __Ownable_init();
        interval = _interval;
        setXpLevelDistributions(_xpLevelDistributions);
        xpContract = OdysseyXP(_xpContract);
        gOhmContract = IERC20Upgradeable(_gOhmContract);
    }

    /* ====================== Chainlink Keeper Implementation ====================== */

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        if ((block.timestamp - lastTimeStamp) > interval) {
            lastTimeStamp = block.timestamp;
            _distribute();
        }
    }

    function getBalance(address _user) public view returns (uint256) {
        return balances[_user];
    }

    function claim() public {
        require(balances[msg.sender] > 0, "No balance to claim");

        uint256 _amount = balances[msg.sender];
        epochClaimedAmount += _amount;
        balances[msg.sender] = 0;
        gOhmContract.transfer(_msgSender(), _amount);
    }

    function distribute() public onlyOwner {
        _distribute();
    }

    function _distribute() internal {
        (address[] memory users, uint256[] memory userLevels) = xpContract.getXPLevels();
        LevelAllocation[] memory levelAllocations = _getLevelAllocations(users, userLevels);
        prevBalance = gOhmContract.balanceOf(address(this));
        epochClaimedAmount = 0;
        for (uint256 i = 0; i < users.length; i++) {
            uint256 xpLevel = getUserLevelOrMax(userLevels[i]);
            uint256 xpPerUser = levelAllocations[xpLevel].xpPerUser;
            balances[users[i]] += xpPerUser;
        }
    }

    function _getLevelAllocations(address[] memory users, uint256[] memory userLevels)
        internal
        view
        returns (LevelAllocation[] memory)
    {
        LevelAllocation[] memory levels = new LevelAllocation[](xpLevelDistributions.length);
        uint256 epochRevenue = gOhmContract.balanceOf(address(this)) - prevBalance + epochClaimedAmount;
        for (uint256 i = 0; i < users.length; i++) {
            levels[getUserLevelOrMax(userLevels[i])].numUsers++;
        }
        for (uint256 i = 0; i < levels.length; i++) {
            uint256 xpAllocatedForLevel = (epochRevenue * xpLevelDistributions[i]) / 100;
            if (levels[i].numUsers > 0) {
                levels[i].xpPerUser = xpAllocatedForLevel / levels[i].numUsers;
            }
        }
        return levels;
    }

    function setXpLevelDistributions(uint256[] memory _xpLevelDistributions) public onlyOwner {
        require(_xpLevelDistributions[0] == 0, "First xp level must be default (0 allocation)");
        require(sumValues(_xpLevelDistributions) == 100, "Total xp level distribution must equal 100");
        xpLevelDistributions = _xpLevelDistributions;
    }

    function sumValues(uint256[] memory _values) internal pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < _values.length; i++) {
            sum += _values[i];
        }
        return sum;
    }

    function getUserLevelOrMax(uint256 userLevel) public view returns (uint256) {
        if (userLevel > xpLevelDistributions.length) {
            return xpLevelDistributions.length - 1;
        } else {
            return userLevel;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract OdysseyXP is Initializable, OwnableUpgradeable {
    struct Rewards {
        uint256 purchase;
        uint256 sale;
        uint256 gOhmPurchase;
        uint256 multiplier;
        bool isSet;
    }

    struct NFT {
        address addr;
        uint256 id;
    }

    modifier grantsXP {
        require(xpGrantingContracts[msg.sender], "Not authorized to grant XP");
        _;
    }

    /* ========== EVENTS ========== */

    event purchase(address addr);
    event sale(address addr);
    event gOhmPurchase(address addr);
    event grantXP(address addr, uint256 amount);

    /* ========== STATE VARIABLES ========== */

    // Mapping user addresses to their current XP balance
    mapping(address => uint256) public xpBalances;

    // Mapping contract addresses to their permission to grant XP
    mapping(address => bool) public xpGrantingContracts;

    // Mapping ERC1155 NFT address + id to the reward amounts
    mapping(address => mapping(uint256 => Rewards)) public erc1155Rewards;
    // Mapping ERC721 NFT address to reward amounts
    mapping(address => Rewards) public erc721Rewards;

    // Array of user addresses for retrieving XP
    address[] public users;

    // Array of all custom rewards NFTs used for iterating
    NFT[] public erc1155s;
    NFT[] public erc721s;

    // Default reward amounts for events
    Rewards public defaultRewards;

    /* ========== INITIALIZE ========== */

    /*
     * @notice Initializes the contract through the proxy,
     *   setting the owner in the proxy's state and default NFT rewards
     */
    function initialize() external initializer {
        __Ownable_init();
        setRewards(1, 1, 3, 1);
    }

    /* ========== READ STATE ========== */

    /*
     * @notice Returns the current XP balance of the given address
     */
    function getXP(address _to) public view returns (uint256) {
        return xpBalances[_to];
    }

    /*
     * @notice Returns all users and their current XP levels
     */
    function getXPLevels() public view virtual returns (address[] memory, uint256[] memory) {
        uint256[] memory levels = new uint256[](users.length);
        for (uint256 i = 0; i < users.length; i++) {
            levels[i] = xpBalances[users[i]] / 3; // 3 XP is one level
        }
        return (users, levels);
    }

    /*
     * @notice Returns default XP rewards and multiplier
     */
    function getRewards() public view returns (uint256[4] memory) {
        return ([defaultRewards.purchase, defaultRewards.sale, defaultRewards.gOhmPurchase, defaultRewards.multiplier]);
    }

    /*
     * @notice Returns the reward amounts for the given NFT
     * @param _nftAddress The address of the NFT contract
     * @param _id The ID of the NFT
     * @dev If no custom rewards set, returns default rewards
     */
    function getRewards(address _nftAddress, uint256 _id) public view returns (uint256[4] memory) {
        Rewards memory rewards = _getRewards(_nftAddress, _id);
        return ([rewards.purchase, rewards.sale, rewards.gOhmPurchase, rewards.multiplier]);
    }

    /* ========== EXTERNAL STATE MODIFICATION ========== */

    /*
     * @notice Assign permissions to XP granting contract
     * @param _contract The address of the contract to grant XP
     * @param _granting Enable or disable granting priveleges
     */
    function setGrantingContract(address _contractAddress, bool _granting) external onlyOwner {
        xpGrantingContracts[_contractAddress] = _granting;
    }

    /*
     * @notice Sets the default reward amounts for purchase, sale, gOHM purchase, and multiplier
     * @param _purchase The default amount of XP to be awarded for a purchase
     * @param _sale The default amount of XP to be awarded for a sale
     * @param _gOhmPurchase The default amount of XP to be awarded for a purchase made with gOHM
     * @param _multiplier The default multiplier for all events
     * @dev The default multiplier must be between 1 and 4 and is meant for temporary promotions
     */
    function setRewards(
        uint256 _purchase,
        uint256 _sale,
        uint256 _gOhmPurchase,
        uint256 _multiplier
    ) public onlyOwner {
        require(_multiplier > 0, "Multiplier must be greater than 0");
        require(_multiplier <= 4, "Multiplier must be less than or equal to 4");
        defaultRewards.purchase = _purchase;
        defaultRewards.sale = _sale;
        defaultRewards.gOhmPurchase = _gOhmPurchase;
        defaultRewards.multiplier = _multiplier;
    }

    /*
     * @notice Sets the reward amounts for the erc1155 compliant NFT
     * @param _nftAddress The address of the NFT contract
     * @param _id The ID of the NFT
     * @param _purchase The amount of XP to be awarded for a purchase
     * @param _sale The amount of XP to be awarded for a sale
     * @param _gOhmPurchase The amount of XP to be awarded for a purchase made with gOHM
     * @param _multiplier The XP multiplier for each NFT held
     */
    function setErc1155Rewards(
        address _nftAddress,
        uint256 _id,
        uint256 _purchase,
        uint256 _sale,
        uint256 _gOhmPurchase,
        uint256 _multiplier
    ) public onlyOwner {
        erc1155Rewards[_nftAddress][_id] = Rewards(_purchase, _sale, _gOhmPurchase, _multiplier, true);
        erc1155s.push(NFT(_nftAddress, _id));
    }

    /*
     * @notice Sets the reward amounts for the erc721 compliant NFT
     * @param _nftAddress The address of the NFT contract
     * @param _purchase The amount of XP to be awarded for a purchase
     * @param _sale The amount of XP to be awarded for a sale
     * @param _gOhmPurchase The amount of XP to be awarded for a purchase made with gOHM
     * @param _multiplier The XP multiplier for each NFT held
     */
    function setErc721Rewards(
        address _nftAddress,
        uint256 _purchase,
        uint256 _sale,
        uint256 _gOhmPurchase,
        uint256 _multiplier
    ) public onlyOwner {
        erc721Rewards[_nftAddress] = Rewards(_purchase, _sale, _gOhmPurchase, _multiplier, true);
        erc721s.push(NFT(_nftAddress, 0));
    }

    /*
     * @notice Removes custom rewards for the given NFT
     */
    function removeCustomRewards(address _nftAddress, uint256 _id) external onlyOwner {
        if (erc1155Rewards[_nftAddress][_id].isSet) {
            erc1155Rewards[_nftAddress][_id].isSet = false;
        } else if (erc721Rewards[_nftAddress].isSet) {
            erc721Rewards[_nftAddress].isSet = false;
        }
    }

    /*
     * @notice Adds XP to the given address for a purchase of the given NFT
     * @param _nftAddress The address of the NFT contract
     * @param _id The ID of the NFT
     * @param _to The address purchasing the XP
     */
    function purchaseXP(
        address _nftAddress,
        uint256 _id,
        address _to
    ) external grantsXP {
        _grantXP(_to, _getRewards(_nftAddress, _id).purchase);
        emit purchase(_to);
    }

    /*
     * @notice Adds XP to the given address for a sale of the given NFT
     * @param _nftAddress The address of the NFT contract
     * @param _id The ID of the NFT
     * @param _to The address selling the NFT
     */
    function saleXP(
        address _nftAddress,
        uint256 _id,
        address _to
    ) external grantsXP {
        _grantXP(_to, _getRewards(_nftAddress, _id).sale);
        emit sale(_to);
    }

    /*
     * @notice Adds XP to the given address for a purchase made with gOHM
     * @param _nftAddress The address of the NFT contract
     * @param _id The ID of the NFT
     * @param _to The address purchasing the NFT
     */
    function gOhmPurchaseXP(
        address _nftAddress,
        uint256 _id,
        address _to
    ) external grantsXP {
        _grantXP(_to, _getRewards(_nftAddress, _id).gOhmPurchase);
        emit gOhmPurchase(_to);
    }

    /* ========== PRIVATE ========== */

    /*
     * @notice Grants XP to the given address
     * @param _to The address to grant XP to
     * @param _amount The amount of XP to grant
     * @dev The _amount parameter is the XP amount *prior* to applying the multiplier
     */
    function _grantXP(address _to, uint256 _xpAmount) internal {
        require(_to != address(0), "Invalid address");
        if (xpBalances[_to] == 0) {
            users.push(_to);
        }
        xpBalances[_to] += (_getMultiplier(_to) * _xpAmount);
        emit grantXP(_to, _xpAmount);
    }

    /*
     * @notice Returns the rewards for a given NFT
     * @param _nftAddress The address of the NFT contract
     * @param _id The ID of the NFT
     * @dev The _id can be 0 if an ERC721 token
     */
    function _getRewards(address _nftAddress, uint256 _id) internal view returns (Rewards storage) {
        if (erc1155Rewards[_nftAddress][_id].isSet) {
            return erc1155Rewards[_nftAddress][_id];
        } else if (erc721Rewards[_nftAddress].isSet) {
            return erc721Rewards[_nftAddress];
        } else {
            return defaultRewards;
        }
    }

    /*
     * @notice Gets the XP multiplier for the given address
     * @param _account The address to get the multiplier for
     */
    function _getMultiplier(address _account) internal view returns (uint256) {
        uint256 multiplier = 0;

        // Check for ERC1155s
        for (uint256 i = 0; i < erc1155s.length; i++) {
            NFT storage nft = erc1155s[i];
            if (erc1155Rewards[nft.addr][nft.id].isSet) {
                uint256 balance = IERC1155Upgradeable(nft.addr).balanceOf(_account, nft.id);
                multiplier += (erc1155Rewards[nft.addr][nft.id].multiplier * balance);
            }
        }

        // Check for ERC721s
        for (uint256 i = 0; i < erc721s.length; i++) {
            NFT storage nft = erc721s[i];
            if (erc721Rewards[nft.addr].isSet) {
                uint256 balance = IERC721Upgradeable(nft.addr).balanceOf(_account);
                multiplier += (erc721Rewards[nft.addr].multiplier * balance);
            }
        }

        if (multiplier == 0) {
            multiplier = defaultRewards.multiplier;
        }

        return multiplier;
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
pragma solidity ^0.8.0;

contract KeeperBase {
  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    require(tx.origin == address(0), "only for simulated backend");
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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