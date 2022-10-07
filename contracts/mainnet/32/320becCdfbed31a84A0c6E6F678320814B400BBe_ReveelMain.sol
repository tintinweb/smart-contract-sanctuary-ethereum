// SPDX-License-Identifier: SPWPL
pragma solidity 0.8.9;

import "openzeppelin-solidity/contracts/proxy/Clones.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/Pausable.sol";
import "./RevenuePath.sol";

contract ReveelMain is Ownable, Pausable {

    uint256 public constant BASE = 1e7;
    //@notice Fee percentage that will be applicable for additional tiers
    uint88 private platformFee;
    //@notice Address of platform wallet to collect fees
    address private platformWallet;
    //@notice The list of revenue path contracts
    RevenuePath[] private revenuePaths;
    //@notice The revenue path contract address who's bytecode will be used for cloning
    address private libraryAddress;

    /********************************
     *           EVENTS              *
     ********************************/
    /** @notice Emits when a new revenue path is created
     * @param path The address of the new revenue path
     */
    event RevenuePathCreated(RevenuePath indexed path, string name);
    /** @notice Updates the libaray contract address
     * @param newLibrary The address of the library contract
     */
    event UpdatedLibraryAddress(address newLibrary);

    /** @notice Updates the platform fee percentage
     * @param newFeePercentage The new fee percentage
     */
    event UpdatedPlatformFee(uint88 newFeePercentage);

    /** @notice Updates the platform fee collecting wallet
     * @param newWallet The new fee collecting wallet
     */
    event UpdatedPlatformWallet(address newWallet);

    /** @notice Intialize the Revenue main contract
     * @param _libraryAddress The revenue path contract address who's bytecode will be used for cloning
     * @param _platformFee The platform fee percentage
     * @param _platformWallet The platform fee collector wallet
     */

    /********************************
     *           ERRORS              *
     ********************************/
    /** @dev Reverts when zero address is assigned
     */
    error ZeroAddressProvided();

    /**
     * @dev Reverts when platform fee out of bound
     */

    error PlatformFeeNotAppropriate();

    constructor(
        address _libraryAddress,
        uint88 _platformFee,
        address _platformWallet
    ) {
        if (_libraryAddress == address(0) || _platformWallet == address(0)) {
            revert ZeroAddressProvided();
        }

        if(platformFee > BASE){
            revert PlatformFeeNotAppropriate();
        }
        libraryAddress = _libraryAddress;
        platformFee = _platformFee;
        platformWallet = _platformWallet;
    }

    /** @notice Create a new revenue path
     * @param _walletList A nested array of member wallet list
     * @param _distribution A nested array of distribution percentages
     * @param tierLimit A sequential list of tier limit
     * @param isImmutable Set this flag to true if immutable
     */
    function createRevenuePath(
        address[][] memory _walletList,
        uint256[][] memory _distribution,
        uint256[] memory tierLimit,
        string memory _name,
        bool isImmutable
    ) external whenNotPaused {
        RevenuePath path = RevenuePath(payable(Clones.clone(libraryAddress)));
        revenuePaths.push(path);

        RevenuePath.PathInfo memory pathInfo;
        pathInfo.name = _name;
        pathInfo.platformFee = platformFee;
        pathInfo.platformWallet = platformWallet;
        pathInfo.isImmutable = isImmutable;
        pathInfo.factory = address(this);

        path.initialize(_walletList, _distribution, tierLimit, pathInfo, msg.sender);
        emit RevenuePathCreated(path,_name);
    }

    /** @notice Sets the libaray contract address
     * @param _libraryAddress The address of the library contract
     */
    function setLibraryAddress(address _libraryAddress) external onlyOwner {
        if (_libraryAddress == address(0)) {
            revert ZeroAddressProvided();
        }
        libraryAddress = _libraryAddress;
        emit UpdatedLibraryAddress(libraryAddress);
    }

    /** @notice Set the platform fee percentage
     * @param newFeePercentage The new fee percentage
     */
    function setPlatformFee(uint88 newFeePercentage) external onlyOwner {
        
        if(platformFee > BASE){
            revert PlatformFeeNotAppropriate();
        }
        platformFee = newFeePercentage;
        emit UpdatedPlatformFee(platformFee);
    }

    /** @notice Set the platform fee collecting wallet
     * @param newWallet The new fee collecting wallet
     */
    function setPlatformWallet(address newWallet) external onlyOwner {
        if (newWallet == address(0)) {
            revert ZeroAddressProvided();
        }
        platformWallet = newWallet;
        emit UpdatedPlatformWallet(platformWallet);
    }


    /**
     * @notice Owner can toggle & pause contract
     * @dev emits relevant Pausable events
     */
    function toggleContractState() external onlyOwner {
        if (!paused()) {
            _pause();
        } else {
            _unpause();
        }
    }

    /** @notice Get the list of revenue paths deployed and count
     */
    function getPaths() external view returns (RevenuePath[] memory, uint256 totalPaths) {
        return (revenuePaths, revenuePaths.length);
    }

    /** @notice Gets the libaray contract address
     */
    function getLibraryAddress() external view returns (address) {
        return libraryAddress;
    }

    /** @notice Gets the platform fee percentage
     */
    function getPlatformFee() external view returns (uint88) {
        return platformFee;
    }

    /** @notice Gets the platform fee percentage
     */
    function getPlatformWallet() external view returns (address) {
        return platformWallet;
    }

    function renounceOwnership() public virtual override onlyOwner {
        revert();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: SPWPL
pragma solidity 0.8.9;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";

/*******************************
 * @title Revenue Path V1
 * @notice The revenue path clone instance contract.
 */
interface IReveelMain {
    function getPlatformWallet() external view returns (address);
}

contract RevenuePath is Ownable, Initializable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant BASE = 1e7; // 10000
    uint8 public constant VERSION = 1;

    //@notice Addres of platform wallet to collect fees
    address private platformFeeWallet;

    //@notice Status to flag if fee is applicable to the revenue paths
    bool private feeRequired;

    //@notice Status to flag if revenue path is immutable. True if immutable
    bool private isImmutable;

    //@notice Fee percentage that will be applicable for additional tiers
    uint88 private platformFee;

    //@notice Current ongoing tier for eth distribution, in case multiple tiers are added
    uint256 private currentTier;

    //@noitce Total fee accumulated by the revenue path and waiting to be collected.
    uint256 private feeAccumulated;

    //@notice Total ETH that has been released/withdrawn by the revenue path members
    uint256 private totalReleased;

    string private name;

    address private mainFactory;

    /// ETH

    // @notice ETH revenue waiting to be collected for a given address
    mapping(address => uint256) private ethRevenuePending;

    /** @notice For a given tier & address, the eth revenue distribution proportion is returned
     *  @dev Index for tiers starts from 0. i.e, the first tier is marked 0 in the list.
     */
    mapping(uint256 => mapping(address => uint256)) private revenueProportion;

    // @notice Amount of ETH release for a given address
    mapping(address => uint256) private released;

    // @notice Total amount of ETH distributed for a given tier at that time.
    mapping(uint256 => uint256) private totalDistributed;

    /// ERC20
    // @notice ERC20 revenue share/proportion for a given address
    mapping(address => uint256) private erc20RevenueShare;

    /**  @notice For a given token & wallet address, the amount of the token that has been released
    . erc20Released[token][wallet]*/
    mapping(address => mapping(address => uint256)) private erc20Released;

    // @notice Total ERC20 released from the revenue path for a given token address
    mapping(address => uint256) private totalERC20Released;

    /**  @notice For a given token & wallet address, the amount of the token that can been withdrawn by the wallet
    . erc20Withdrawable[token][wallet]*/
    mapping(address => mapping(address => uint256)) public erc20Withdrawable;

    // @notice Total ERC20 accounted for the revenue path for a given token address
    mapping(address => uint256) private totalERC20Accounted;

    // array of address having erc20 distribution shares
    address[] private erc20DistributionWallets;

    struct Revenue {
        uint256 limitAmount;
        address[] walletList;
    }

    struct PathInfo {
        uint88 platformFee;
        address platformWallet;
        bool isImmutable;
        string name;
        address factory;
    }

    Revenue[] private revenueTiers;

    /********************************
     *           EVENTS              *
     ********************************/

    /** @notice Emits when incoming ETH is distributed among members
     * @param amount The amount of eth that has been distributed in a tier
     * @param distributionTier the tier index at which the distribution is being done.
     * @param walletList the list of wallet addresses for which ETH has been distributed
     */
    event EthDistributed(uint256 indexed amount, uint256 indexed distributionTier, address[] walletList);

    /** @notice Emits when ETH payment is withdrawn/claimed by a member
     * @param account The wallet for which ETH has been claimed for
     * @param payment The amount of ETH that has been paid out to the wallet
     */
    event PaymentReleased(address indexed account, uint256 indexed payment);

    /** @notice Emits when ERC20 payment is withdrawn/claimed by a member
     * @param token The token address for which withdrawal is made
     * @param account The wallet address to which withdrawal is made
     * @param payment The amount of the given token the wallet has claimed
     */
    event ERC20PaymentReleased(address indexed token, address indexed account, uint256 indexed payment);

    /** @notice Emits when new revenue tier is added
     * @param addedWalletLists The nested wallet list of different tiers
     * @param addedDistributionLists The corresponding shares of all tiers
     * @param newTiersCount The total number of new tiers added
     */
    event RevenueTiersAdded(
        address[][] addedWalletLists,
        uint256[][] addedDistributionLists,
        uint256 indexed newTiersCount
    );

    /** @notice Emits when revenue tiers are updated
     * @param updatedWalletList The wallet list of different tiers
     * @param updatedDistributionLists The corresponding shares of all tiers
     * @param updatedTierNumber The number of the updated tier
     * @param newLimit The limit of the updated tier
     */
    event RevenueTiersUpdated(
        address[] updatedWalletList,
        uint256[] updatedDistributionLists,
        uint256 indexed updatedTierNumber,
        uint256 indexed newLimit
    );

    /** @notice Emits when erc20 revenue list is are updated
     * @param updatedWalletList The wallet list of different tiers
     * @param updatedDistributionList The corresponding shares of all tiers
     */
    event ERC20RevenueUpdated(address[] updatedWalletList, uint256[] updatedDistributionList);

    /** @notice Emits when erc20 revenue accounting is done
     * @param token The token for which accounting has been done
     * @param amount The amount of token that has been accounted for
     */
    event ERC20Distributed(address indexed token, uint256 indexed amount);

    /********************************
     *           MODIFIERS          *
     ********************************/
    /** @notice Entrant guard for mutable contract methods
     */
    modifier isAllowed() {
        // require(!isImmutable, "IMMUTABLE_PATH_CAN_NOT_USE_THIS");
        if (isImmutable) {
            revert RevenuePathNotMutable();
        }
        _;
    }

    /********************************
     *           ERRORS          *
     ********************************/

    /** @dev Reverts when passed wallet list and distribution list length is not equal
     * @param walletCount Length of wallet list
     * @param distributionCount Length of distribution list
     */
    error WalletAndDistributionCountMismatch(uint256 walletCount, uint256 distributionCount);

    /** @dev Reverts when passed wallet list and tier limit count doesn't add up.
       The tier limit count should be 1 less than wallet list
     * @param walletCount  Length of wallet list
     * @param tierLimitCount Length of tier limit list
     */
    error WalletAndTierLimitMismatch(uint256 walletCount, uint256 tierLimitCount);

    /** @dev Reverts when zero address is assigned
     */
    error ZeroAddressProvided();

    /** @dev Reverts when limit is not greater than already distributed amount for the given tier
     * @param alreadyDistributed The amount of ETH that has already been distributed for that tier
     * @param proposedNewLimit The amount of ETH proposed to be added/updated as limit for the given tier
     */
    error LimitNotGreaterThanTotalDistributed(uint256 alreadyDistributed, uint256 proposedNewLimit);

    /** @dev Reverts when the tier is not eligible for being updated.
      Requested tier for update must be greater than or equal to current tier.
     * @param currentTier The ongoing tier for distribution
     * @param requestedTier The tier which is requested for an update
     */
    error IneligibileTierUpdate(uint256 currentTier, uint256 requestedTier);

    /** @dev Reverts when the member has zero ETH withdrawal balance available
     */
    error InsufficientWithdrawalBalance();
    /** @dev Reverts when the member has zero percentage shares for ERC20 distribution
     */
    error ZeroERC20Shares(address wallet);

    /** @dev Reverts when wallet has no due ERC20 available for withdrawal
     * @param wallet The member's wallet address
     * @param tokenAddress The requested token address
     */
    error NoDueERC20Payment(address wallet, address tokenAddress);

    /** @dev Reverts when immutable path attempts to use mutable methods
     */
    error RevenuePathNotMutable();

    /** @dev Reverts when contract has insufficient ETH for withdrawal
     * @param contractBalance  The total balance of ETH available in the contract
     * @param requiredAmount The total amount of ETH requested for withdrawal
     */
    error InsufficentBalance(uint256 contractBalance, uint256 requiredAmount);

    /**
     * @dev Reverts when sum of all distribution is not equal to BASE
     */
    error TotalShareNotHundred();

    /**
     *  @dev Reverts when duplicate wallet entry is present during addition or updates
     */

    error DuplicateWalletEntry();

    /**
     *  @dev Reverts when tier limit given is zero in certain cases
     */

    error TierLimitGivenZero();

    /**
     * @dev Reverts if zero distribution is given for a passed wallet
     */

    error ZeroDistributionProvided();

    /********************************
     *           FUNCTIONS           *
     ********************************/

    /** @notice Contract ETH receiver, triggers distribution. Called when ETH is transferred to the revenue path.
     */
    receive() external payable {
        distributeHoldings(msg.value, currentTier);
    }

    /**
     * @notice Performs accounting and allocation on passed erc20 balances
     * @param token Address of the token being accounted for
     */

    function erc20Accounting(address token) public {
        uint256 pathTokenBalance = IERC20(token).balanceOf(address(this));
        uint256 pendingAmount = (pathTokenBalance + totalERC20Released[token]) - totalERC20Accounted[token];

        if (pendingAmount == 0) {
            return;
        }
        uint256 totalWallets = erc20DistributionWallets.length;

        for (uint256 i; i < totalWallets; ) {
            address account = erc20DistributionWallets[i];
            erc20Withdrawable[token][account] += (pendingAmount * erc20RevenueShare[account]) / BASE;

            unchecked {
                i++;
            }
        }

        totalERC20Accounted[token] += pendingAmount;

        emit ERC20Distributed(token, pendingAmount);
    }

    /** @notice The initializer for revenue path, directly called from the RevenueMain contract.._
     * @param _walletList A nested array list of member wallets
     * @param _distribution A nested array list of distribution percentages
     * @param _tierLimit A list of tier limits
     * @param pathInfo The basic info related to the path
     * @param _owner The owner of the revenue path
     */

    function initialize(
        address[][] memory _walletList,
        uint256[][] memory _distribution,
        uint256[] memory _tierLimit,
        PathInfo memory pathInfo,
        address _owner
    ) external initializer {
        if (_walletList.length != _distribution.length) {
            revert WalletAndDistributionCountMismatch({
                walletCount: _walletList.length,
                distributionCount: _distribution.length
            });
        }

        if ((_walletList.length - 1) != _tierLimit.length) {
            revert WalletAndTierLimitMismatch({ walletCount: _walletList.length, tierLimitCount: _tierLimit.length });
        }

        uint256 listLength = _walletList.length;

        for (uint256 i; i < listLength; ) {
            Revenue memory tier;

            uint256 walletMembers = _walletList[i].length;

            if (walletMembers != _distribution[i].length) {
                revert WalletAndDistributionCountMismatch({
                    walletCount: walletMembers,
                    distributionCount: _distribution[i].length
                });
            }

            tier.walletList = _walletList[i];
            if (i != listLength - 1) {
                if (_tierLimit[i] == 0) {
                    revert TierLimitGivenZero();
                }
                tier.limitAmount = _tierLimit[i];
            }
            uint256 totalShare;
            for (uint256 j; j < walletMembers; ) {
                if (revenueProportion[i][(_walletList[i])[j]] > 0) {
                    revert DuplicateWalletEntry();
                }
                if ((_walletList[i])[j] == address(0)) {
                    revert ZeroAddressProvided();
                }
                if ((_distribution[i])[j] == 0) {
                    revert ZeroDistributionProvided();
                }
                revenueProportion[i][(_walletList[i])[j]] = (_distribution[i])[j];
                totalShare += (_distribution[i])[j];
                unchecked {
                    j++;
                }
            }
            if (totalShare != BASE) {
                revert TotalShareNotHundred();
            }
            revenueTiers.push(tier);

            unchecked {
                i++;
            }
        }

        uint256 erc20WalletMembers = _walletList[listLength - 1].length;
        for (uint256 k; k < erc20WalletMembers; ) {
            address userWallet = (_walletList[listLength - 1])[k];
            erc20RevenueShare[userWallet] = (_distribution[listLength - 1])[k];
            erc20DistributionWallets.push(userWallet);

            unchecked {
                k++;
            }
        }

        if (revenueTiers.length > 1) {
            feeRequired = true;
        }
        platformFeeWallet = pathInfo.platformWallet;

        platformFee = pathInfo.platformFee;
        mainFactory = pathInfo.factory;
        isImmutable = pathInfo.isImmutable;
        name = pathInfo.name;
        _transferOwnership(_owner);
    }

    /** @notice Adds multiple revenue tiers. Only for mutable revenue path
     * @param _walletList A nested array list of member wallets
     * @param _distribution A nested array list of distribution percentages
     * @param previousTierLimit A list of tier limits, starting with the current last tier's new limit.
     */
    function addRevenueTier(
        address[][] calldata _walletList,
        uint256[][] calldata _distribution,
        uint256[] calldata previousTierLimit
    ) external isAllowed onlyOwner {
        if (_walletList.length != _distribution.length) {
            revert WalletAndDistributionCountMismatch({
                walletCount: _walletList.length,
                distributionCount: _distribution.length
            });
        }
        if ((_walletList.length) != previousTierLimit.length) {
            revert WalletAndTierLimitMismatch({
                walletCount: _walletList.length,
                tierLimitCount: previousTierLimit.length
            });
        }

        uint256 listLength = _walletList.length;
        uint256 nextRevenueTier = revenueTiers.length;
        for (uint256 i; i < listLength; ) {
            if (previousTierLimit[i] == 0) {
                revert TierLimitGivenZero();
            }

            if (previousTierLimit[i] < totalDistributed[nextRevenueTier - 1]) {
                revert LimitNotGreaterThanTotalDistributed({
                    alreadyDistributed: totalDistributed[nextRevenueTier - 1],
                    proposedNewLimit: previousTierLimit[i]
                });
            }

            Revenue memory tier;
            uint256 walletMembers = _walletList[i].length;

            if (walletMembers != _distribution[i].length) {
                revert WalletAndDistributionCountMismatch({
                    walletCount: walletMembers,
                    distributionCount: _distribution[i].length
                });
            }
            revenueTiers[nextRevenueTier - 1].limitAmount = previousTierLimit[i];
            tier.walletList = _walletList[i];
            uint256 totalShares;
            for (uint256 j; j < walletMembers; ) {
                if (revenueProportion[nextRevenueTier][(_walletList[i])[j]] > 0) {
                    revert DuplicateWalletEntry();
                }

                if ((_walletList[i])[j] == address(0)) {
                    revert ZeroAddressProvided();
                }
                if ((_distribution[i])[j] == 0) {
                    revert ZeroDistributionProvided();
                }

                revenueProportion[nextRevenueTier][(_walletList[i])[j]] = (_distribution[i])[j];
                totalShares += (_distribution[i])[j];
                unchecked {
                    j++;
                }
            }

            if (totalShares != BASE) {
                revert TotalShareNotHundred();
            }
            revenueTiers.push(tier);
            nextRevenueTier += 1;

            unchecked {
                i++;
            }
        }
        if (!feeRequired) {
            feeRequired = true;
        }

        emit RevenueTiersAdded(_walletList, _distribution, revenueTiers.length);
    }

    /** @notice Update given revenue tier. Only for mutable revenue path
     * @param _walletList A list of member wallets
     * @param _distribution A list of distribution percentages
     * @param newLimit The new limit of the requested tier
     * @param tierNumber The tier index for which update is being requested.
     */
    function updateRevenueTier(
        address[] calldata _walletList,
        uint256[] calldata _distribution,
        uint256 newLimit,
        uint256 tierNumber
    ) external isAllowed onlyOwner {
        if (tierNumber < currentTier || tierNumber > (revenueTiers.length - 1)) {
            revert IneligibileTierUpdate({ currentTier: currentTier, requestedTier: tierNumber });
        }

        if (tierNumber < revenueTiers.length - 1) {
            if (newLimit == 0) {
                revert TierLimitGivenZero();
            }

            if (newLimit < totalDistributed[tierNumber]) {
                revert LimitNotGreaterThanTotalDistributed({
                    alreadyDistributed: totalDistributed[tierNumber],
                    proposedNewLimit: newLimit
                });
            }
        }

        if (_walletList.length != _distribution.length) {
            revert WalletAndDistributionCountMismatch({
                walletCount: _walletList.length,
                distributionCount: _distribution.length
            });
        }

        address[] memory previousWalletList = revenueTiers[tierNumber].walletList;
        uint256 previousWalletListLength = previousWalletList.length;

        for (uint256 i; i < previousWalletListLength; ) {
            revenueProportion[tierNumber][previousWalletList[i]] = 0;
            unchecked {
                i++;
            }
        }

        revenueTiers[tierNumber].limitAmount = (tierNumber == revenueTiers.length - 1) ? 0 : newLimit;

        uint256 listLength = _walletList.length;
        address[] memory newWalletList = new address[](listLength);
        uint256 totalShares;
        for (uint256 j; j < listLength; ) {
            if (revenueProportion[tierNumber][_walletList[j]] > 0) {
                revert DuplicateWalletEntry();
            }

            if (_walletList[j] == address(0)) {
                revert ZeroAddressProvided();
            }
            if (_distribution[j] == 0) {
                revert ZeroDistributionProvided();
            }
            revenueProportion[tierNumber][_walletList[j]] = _distribution[j];
            totalShares += _distribution[j];
            newWalletList[j] = _walletList[j];
            unchecked {
                j++;
            }
        }
        if (totalShares != BASE) {
            revert TotalShareNotHundred();
        }

        revenueTiers[tierNumber].walletList = newWalletList;
        emit RevenueTiersUpdated(_walletList, _distribution, tierNumber, newLimit);
    }

    /** @notice Update ERC20 revenue distribution. Only for mutable revenue path
     * @param _walletList A list of member wallets
     * @param _distribution A list of distribution percentages
     */
    function updateErc20Distribution(address[] calldata _walletList, uint256[] calldata _distribution)
        external
        isAllowed
        onlyOwner
    {
        if (_walletList.length != _distribution.length) {
            revert WalletAndDistributionCountMismatch({
                walletCount: _walletList.length,
                distributionCount: _distribution.length
            });
        }

        uint256 listLength = _walletList.length;
        uint256 previousWalletListLength = erc20DistributionWallets.length;
        uint256 totalShares;

        for (uint256 i; i < previousWalletListLength; ) {
            erc20RevenueShare[erc20DistributionWallets[i]] = 0;
            unchecked {
                i++;
            }
        }

        delete erc20DistributionWallets;

        for (uint256 j; j < listLength; ) {
            if (erc20RevenueShare[_walletList[j]] > 0) {
                revert DuplicateWalletEntry();
            }
            erc20RevenueShare[_walletList[j]] = _distribution[j];
            erc20DistributionWallets.push(_walletList[j]);
            totalShares += _distribution[j];
            unchecked {
                j++;
            }
        }

        if (totalShares != BASE) {
            revert TotalShareNotHundred();
        }

        emit ERC20RevenueUpdated(_walletList, _distribution);
    }

    /** @notice Releases distributed ETH for the provided address
     * @param account The member's wallet address
     */
    function release(address payable account) external {
        if (ethRevenuePending[account] == 0) {
            revert InsufficientWithdrawalBalance();
        }

        uint256 payment = ethRevenuePending[account];
        released[account] += payment;
        totalReleased += payment;
        ethRevenuePending[account] = 0;

        if (feeAccumulated > 0) {
            uint256 value = feeAccumulated;
            feeAccumulated = 0;
            totalReleased += value;
            platformFeeWallet = IReveelMain(mainFactory).getPlatformWallet();
            sendValue(payable(platformFeeWallet), value);
        }

        sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /** @notice Releases allocated ERC20 for the provided address
     * @param token The address of the ERC20 token
     * @param account The member's wallet address
     */
    function releaseERC20(address token, address account) external nonReentrant {
        erc20Accounting(token);
        uint256 payment = erc20Withdrawable[token][account];

        if (payment == 0) {
            revert NoDueERC20Payment({ wallet: account, tokenAddress: token });
        }

        erc20Released[token][account] += payment;
        erc20Withdrawable[token][account] = 0;
        totalERC20Released[token] += payment;

        IERC20(token).safeTransfer(account, payment);

        emit ERC20PaymentReleased(token, account, payment);
    }

    /** @notice Get the limit amoutn & wallet list for a given revenue tier
     * @param tierNumber the index of the tier for which list needs to be provided.
     */
    function getRevenueTier(uint256 tierNumber)
        external
        view
        returns (uint256 _limitAmount, address[] memory _walletList)
    {
        require(tierNumber <= revenueTiers.length, "TIER_DOES_NOT_EXIST");
        uint256 limit = revenueTiers[tierNumber].limitAmount;
        address[] memory listWallet = revenueTiers[tierNumber].walletList;
        return (limit, listWallet);
    }

    /** @notice Get the totalNumber of revenue tiers in the revenue path
     */
    function getTotalRevenueTiers() external view returns (uint256 total) {
        return revenueTiers.length;
    }

    /** @notice Get the current ongoing tier of revenue path
     */
    function getCurrentTier() external view returns (uint256 tierNumber) {
        return currentTier;
    }

    /** @notice Get the current ongoing tier of revenue path
     */
    function getFeeRequirementStatus() external view returns (bool required) {
        return feeRequired;
    }

    /** @notice Get the pending eth balance for given address
     */
    function getPendingEthBalance(address account) external view returns (uint256 pendingAmount) {
        return ethRevenuePending[account];
    }

    /** @notice Get the ETH revenue proportion for a given account at a given tier
     */
    function getRevenueProportion(uint256 tier, address account) external view returns (uint256 proportion) {
        return revenueProportion[tier][account];
    }

    /** @notice Get the amount of ETH distrbuted for a given tier
     */

    function getTierDistributedAmount(uint256 tier) external view returns (uint256 amount) {
        return totalDistributed[tier];
    }

    /** @notice Get the amount of ETH accumulated for fee collection
     */

    function getTotalFeeAccumulated() external view returns (uint256 amount) {
        return feeAccumulated;
    }

    /** @notice Get the amount of ETH accumulated for fee collection
     */

    function getERC20Released(address token, address account) external view returns (uint256 amount) {
        return erc20Released[token][account];
    }

    /** @notice Get the platform wallet address
     */
    function getPlatformWallet() external view returns (address) {
        return platformFeeWallet;
    }

    /** @notice Get the platform fee percentage
     */
    function getPlatformFee() external view returns (uint256) {
        return platformFee;
    }

    /** @notice Get the revenue path Immutability status
     */
    function getImmutabilityStatus() external view returns (bool) {
        return isImmutable;
    }

    /** @notice Get the total amount of eth withdrawn from revenue path
     */
    function getTotalEthReleased() external view returns (uint256) {
        return totalReleased;
    }

    /** @notice Get the revenue path name.
     */
    function getRevenuePathName() external view returns (string memory) {
        return name;
    }

    /** @notice Get the amount of total eth withdrawn by the account
     */
    function getEthWithdrawn(address account) external view returns (uint256) {
        return released[account];
    }

    /** @notice Get the erc20 revenue share percentage for given account
     */
    function getErc20WalletShare(address account) external view returns (uint256) {
        return erc20RevenueShare[account];
    }

    /** @notice Get the total erc2o released from the revenue path.
     */
    function getTotalErc20Released(address token) external view returns (uint256) {
        return totalERC20Released[token];
    }

    /** @notice Get the token amount that has not been accounted for in the revenue path
     */
    function getPendingERC20Account(address token) external view returns (uint256) {
        uint256 pathTokenBalance = IERC20(token).balanceOf(address(this));
        uint256 pendingAmount = (pathTokenBalance + totalERC20Released[token]) - totalERC20Accounted[token];

        return pendingAmount;
    }

    function getTierWalletCount(uint256 tier) external view returns (uint256) {
        return revenueTiers[tier].walletList.length;
    }

    /** @notice Transfer handler for ETH
     * @param recipient The address of the receiver
     * @param amount The amount of ETH to be received
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert InsufficentBalance({ contractBalance: address(this).balance, requiredAmount: amount });
        }

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "ETH_TRANSFER_FAILED");
    }

    /** @notice Distributes received ETH based on the required conditions of the tier sequences
     * @param amount The amount of ETH to be distributed
     * @param presentTier The current tier for which distribution will take place.
     */

    function distributeHoldings(uint256 amount, uint256 presentTier) private {
        uint256 currentTierDistribution = amount;
        uint256 nextTierDistribution;

        if (
            totalDistributed[presentTier] + amount > revenueTiers[presentTier].limitAmount &&
            revenueTiers[presentTier].limitAmount > 0
        ) {
            currentTierDistribution = revenueTiers[presentTier].limitAmount - totalDistributed[presentTier];
            nextTierDistribution = amount - currentTierDistribution;
        }

        uint256 totalDistributionAmount = currentTierDistribution;

        if (platformFee > 0 && feeRequired) {
            uint256 feeDeduction = ((currentTierDistribution * platformFee) / BASE);
            feeAccumulated += feeDeduction;
            currentTierDistribution -= feeDeduction;
        }

        uint256 totalMembers = revenueTiers[presentTier].walletList.length;

        for (uint256 i; i < totalMembers; ) {
            address wallet = revenueTiers[presentTier].walletList[i];
            ethRevenuePending[wallet] += ((currentTierDistribution * revenueProportion[presentTier][wallet]) / BASE);
            unchecked {
                i++;
            }
        }

        totalDistributed[presentTier] += totalDistributionAmount;

        emit EthDistributed(currentTierDistribution, presentTier, revenueTiers[presentTier].walletList);

        if (nextTierDistribution > 0) {
            currentTier += 1;
            return distributeHoldings(nextTierDistribution, currentTier);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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