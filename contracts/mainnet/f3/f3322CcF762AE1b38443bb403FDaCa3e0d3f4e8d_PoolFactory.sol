// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "./interfaces/IPoolMaster.sol";
import "./interfaces/IFlashGovernor.sol";
import "./interfaces/IMembershipStaking.sol";
import "./libraries/Decimal.sol";

contract PoolFactory is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ClonesUpgradeable for address;
    using SafeCastUpgradeable for uint256;
    using Decimal for uint256;

    /// @notice CPOOL token contract
    IERC20Upgradeable public cpool;

    /// @notice MembershipStaking contract
    IMembershipStaking public staking;

    /// @notice FlashGovernor contract
    IFlashGovernor public flashGovernor;

    /// @notice Pool master contract
    address public poolMaster;

    /// @notice Interest Rate Model contract address
    address public interestRateModel;

    /// @notice Address of the auction contract
    address public auction;

    /// @notice Address of the treasury
    address public treasury;

    /// @notice Reserve factor as 18-digit decimal
    uint256 public reserveFactor;

    /// @notice Insurance factor as 18-digit decimal
    uint256 public insuranceFactor;

    /// @notice Pool utilization that leads to warning state (as 18-digit decimal)
    uint256 public warningUtilization;

    /// @notice Pool utilization that leads to provisional default (as 18-digit decimal)
    uint256 public provisionalDefaultUtilization;

    /// @notice Grace period for warning state before pool goes to default (in seconds)
    uint256 public warningGracePeriod;

    /// @notice Max period for which pool can stay not active before it can be closed by governor (in seconds)
    uint256 public maxInactivePeriod;

    /// @notice Period after default to start auction after which pool can be closed by anyone (in seconds)
    uint256 public periodToStartAuction;

    /// @notice Allowance of different currencies in protocol
    mapping(address => bool) public currencyAllowed;

    struct ManagerInfo {
        address currency;
        address pool;
        address staker;
        uint32 proposalId;
        uint256 stakedAmount;
        bytes32 ipfsHash;
        string managerSymbol;
    }

    /// @notice Mapping of manager addresses to their pool info
    mapping(address => ManagerInfo) public managerInfo;

    /// @notice Mapping of manager symbols to flags if they are already used
    mapping(string => bool) public usedManagerSymbols;

    /// @notice Mapping of addresses to flags indicating if they are pools
    mapping(address => bool) public isPool;

    // EVENTS

    /// @notice Event emitted when new pool is proposed
    event PoolProposed(address indexed manager, address indexed currency);

    /// @notice Event emitted when proposed pool is cancelled
    event PoolCancelled(address indexed manager, address indexed currency);

    /// @notice Event emitted when new pool is created
    event PoolCreated(
        address indexed pool,
        address indexed manager,
        address indexed currency,
        bool forceCreated
    );

    /// @notice Event emitted when pool is closed
    event PoolClosed(
        address indexed pool,
        address indexed manager,
        address indexed currency
    );

    /// @notice Event emitted when status of the currency is set
    event CurrencySet(address currency, bool allowed);

    /// @notice Event emitted when new pool master is set
    event PoolMasterSet(address newPoolMaster);

    /// @notice Event emitted when new interest rate model is set
    event InterestRateModelSet(address newModel);

    /// @notice Event emitted when new treasury is set
    event TreasurySet(address newTreasury);

    /// @notice Event emitted when new reserve factor is set
    event ReserveFactorSet(uint256 factor);

    /// @notice Event emitted when new insurance factor is set
    event InsuranceFactorSet(uint256 factor);

    /// @notice Event emitted when new warning utilization is set
    event WarningUtilizationSet(uint256 utilization);

    /// @notice Event emitted when new provisional default utilization is set
    event ProvisionalDefaultUtilizationSet(uint256 utilization);

    /// @notice Event emitted when new warning grace period is set
    event WarningGracePeriodSet(uint256 period);

    /// @notice Event emitted when new max inactive period is set
    event MaxInactivePeriodSet(uint256 period);

    /// @notice Event emitted when new period to start auction is set
    event PeriodToStartAuctionSet(uint256 period);

    /// @notice Event emitted when new reward per block is set for some pool
    event PoolRewardPerBlockSet(address indexed pool, uint256 rewardPerBlock);

    // CONSTRUCTOR

    /**
     * @notice Upgradeable contract constructor
     * @param cpool_ The address of the CPOOL contract
     * @param staking_ The address of the Staking contract
     * @param flashGovernor_ The address of the FlashGovernor contract
     * @param poolMaster_ The address of the PoolMaster contract
     * @param interestRateModel_ The address of the InterestRateModel contract
     * @param auction_ The address of the Auction contract
     */
    function initialize(
        IERC20Upgradeable cpool_,
        IMembershipStaking staking_,
        IFlashGovernor flashGovernor_,
        address poolMaster_,
        address interestRateModel_,
        address auction_
    ) external initializer {
        require(address(cpool_) != address(0), "AIZ");
        require(address(staking_) != address(0), "AIZ");
        require(address(flashGovernor_) != address(0), "AIZ");
        require(poolMaster_ != address(0), "AIZ");
        require(interestRateModel_ != address(0), "AIZ");
        require(auction_ != address(0), "AIZ");

        __Ownable_init();

        cpool = cpool_;
        staking = staking_;
        flashGovernor = flashGovernor_;
        poolMaster = poolMaster_;
        interestRateModel = interestRateModel_;
        auction = auction_;
    }

    /* PUBLIC FUNCTIONS */

    /**
     * @notice Function used to propose new pool for the first time (with manager's info)
     * @param currency Address of the ERC20 token that would act as currnecy in the pool
     * @param ipfsHash IPFS hash of the manager's info
     * @param managerSymbol Manager's symbol
     */
    function proposePoolInitial(
        address currency,
        bytes32 ipfsHash,
        string memory managerSymbol
    ) external {
        _setManager(msg.sender, ipfsHash, managerSymbol);
        _proposePool(currency);
    }

    /**
     * @notice Function used to propose new pool (when manager's info already exist)
     * @param currency Address of the ERC20 token that would act as currnecy in the pool
     */
    function proposePool(address currency) external {
        require(managerInfo[msg.sender].ipfsHash != bytes32(0), "MHI");

        _proposePool(currency);
    }

    /**
     * @notice Function used to create proposed and approved pool
     */
    function createPool() external {
        ManagerInfo storage info = managerInfo[msg.sender];
        flashGovernor.execute(info.proposalId);
        IPoolMaster pool = IPoolMaster(poolMaster.clone());
        pool.initialize(msg.sender, info.currency);
        info.pool = address(pool);
        isPool[address(pool)] = true;

        emit PoolCreated(address(pool), msg.sender, info.currency, false);
    }

    /**
     * @notice Function used to cancel proposed but not yet created pool
     */
    function cancelPool() external {
        ManagerInfo storage info = managerInfo[msg.sender];
        require(info.proposalId != 0 && info.pool == address(0), "NPP");

        emit PoolCancelled(msg.sender, info.currency);

        info.currency = address(0);
        info.proposalId = 0;
        staking.unlockStake(info.staker, info.stakedAmount);
    }

    // RESTRICTED FUNCTIONS

    /**
     * @notice Function used to immedeately create new pool for some manager for the first time
     * @notice Skips approval, restricted to owner
     * @param manager Manager to create pool for
     * @param currency Address of the ERC20 token that would act as currnecy in the pool
     * @param ipfsHash IPFS hash of the manager's info
     * @param managerSymbol Manager's symbol
     */
    function forceCreatePoolInitial(
        address manager,
        address currency,
        bytes32 ipfsHash,
        string memory managerSymbol
    ) external onlyOwner {
        _setManager(manager, ipfsHash, managerSymbol);

        _forceCreatePool(manager, currency);
    }

    /**
     * @notice Function used to immediately create new pool for some manager (when info already exist)
     * @notice Skips approval, restricted to owner
     * @param manager Manager to create pool for
     * @param currency Address of the ERC20 token that would act as currnecy in the pool
     */
    function forceCreatePool(address manager, address currency)
        external
        onlyOwner
    {
        require(managerInfo[manager].ipfsHash != bytes32(0), "MHI");

        _forceCreatePool(manager, currency);
    }

    /**
     * @notice Function is called by contract owner to update currency allowance in the protocol
     * @param currency Address of the ERC20 token
     * @param allowed Should currency be allowed or forbidden
     */
    function setCurrency(address currency, bool allowed) external onlyOwner {
        currencyAllowed[currency] = allowed;
        emit CurrencySet(currency, allowed);
    }

    /**
     * @notice Function is called by contract owner to set new PoolMaster
     * @param poolMaster_ Address of the new PoolMaster contract
     */
    function setPoolMaster(address poolMaster_) external onlyOwner {
        require(poolMaster_ != address(0), "AIZ");
        poolMaster = poolMaster_;
        emit PoolMasterSet(poolMaster_);
    }

    /**
     * @notice Function is called by contract owner to set new InterestRateModel
     * @param interestRateModel_ Address of the new InterestRateModel contract
     */
    function setInterestRateModel(address interestRateModel_)
        external
        onlyOwner
    {
        require(interestRateModel_ != address(0), "AIZ");
        interestRateModel = interestRateModel_;
        emit InterestRateModelSet(interestRateModel_);
    }

    /**
     * @notice Function is called by contract owner to set new treasury
     * @param treasury_ Address of the new treasury
     */
    function setTreasury(address treasury_) external onlyOwner {
        require(treasury_ != address(0), "AIZ");
        treasury = treasury_;
        emit TreasurySet(treasury_);
    }

    /**
     * @notice Function is called by contract owner to set new reserve factor
     * @param reserveFactor_ New reserve factor as 18-digit decimal
     */
    function setReserveFactor(uint256 reserveFactor_) external onlyOwner {
        require(reserveFactor_ <= Decimal.ONE, "GTO");
        reserveFactor = reserveFactor_;
        emit ReserveFactorSet(reserveFactor_);
    }

    /**
     * @notice Function is called by contract owner to set new insurance factor
     * @param insuranceFactor_ New reserve factor as 18-digit decimal
     */
    function setInsuranceFactor(uint256 insuranceFactor_) external onlyOwner {
        require(insuranceFactor_ <= Decimal.ONE, "GTO");
        insuranceFactor = insuranceFactor_;
        emit InsuranceFactorSet(insuranceFactor_);
    }

    /**
     * @notice Function is called by contract owner to set new warning utilization
     * @param warningUtilization_ New warning utilization as 18-digit decimal
     */
    function setWarningUtilization(uint256 warningUtilization_)
        external
        onlyOwner
    {
        require(warningUtilization_ <= Decimal.ONE, "GTO");
        warningUtilization = warningUtilization_;
        emit WarningUtilizationSet(warningUtilization_);
    }

    /**
     * @notice Function is called by contract owner to set new provisional default utilization
     * @param provisionalDefaultUtilization_ New provisional default utilization as 18-digit decimal
     */
    function setProvisionalDefaultUtilization(
        uint256 provisionalDefaultUtilization_
    ) external onlyOwner {
        require(provisionalDefaultUtilization_ <= Decimal.ONE, "GTO");
        provisionalDefaultUtilization = provisionalDefaultUtilization_;
        emit ProvisionalDefaultUtilizationSet(provisionalDefaultUtilization_);
    }

    /**
     * @notice Function is called by contract owner to set new warning grace period
     * @param warningGracePeriod_ New warning grace period in seconds
     */
    function setWarningGracePeriod(uint256 warningGracePeriod_)
        external
        onlyOwner
    {
        warningGracePeriod = warningGracePeriod_;
        emit WarningGracePeriodSet(warningGracePeriod_);
    }

    /**
     * @notice Function is called by contract owner to set new max inactive period
     * @param maxInactivePeriod_ New max inactive period in seconds
     */
    function setMaxInactivePeriod(uint256 maxInactivePeriod_)
        external
        onlyOwner
    {
        maxInactivePeriod = maxInactivePeriod_;
        emit MaxInactivePeriodSet(maxInactivePeriod_);
    }

    /**
     * @notice Function is called by contract owner to set new period to start auction
     * @param periodToStartAuction_ New period to start auction
     */
    function setPeriodToStartAuction(uint256 periodToStartAuction_)
        external
        onlyOwner
    {
        periodToStartAuction = periodToStartAuction_;
        emit PeriodToStartAuctionSet(periodToStartAuction_);
    }

    /**
     * @notice Function is called by contract owner to set new CPOOl reward per block speed in some pool
     * @param pool Pool where to set reward
     * @param rewardPerBlock Reward per block value
     */
    function setPoolRewardPerBlock(address pool, uint256 rewardPerBlock)
        external
        onlyOwner
    {
        IPoolMaster(pool).setRewardPerBlock(rewardPerBlock);
        emit PoolRewardPerBlockSet(pool, rewardPerBlock);
    }

    /**
     * @notice Function is called through pool at closing to unlock manager's stake
     */
    function closePool() external {
        require(isPool[msg.sender], "SNP");
        address manager = IPoolMaster(msg.sender).manager();
        ManagerInfo storage info = managerInfo[manager];

        address currency = info.currency;
        info.currency = address(0);
        info.pool = address(0);
        staking.unlockStake(info.staker, info.stakedAmount);

        emit PoolClosed(msg.sender, manager, currency);
    }

    /**
     * @notice Function is called through pool to burn manager's stake when auction starts
     */
    function burnStake() external {
        require(isPool[msg.sender], "SNP");
        ManagerInfo storage info = managerInfo[
            IPoolMaster(msg.sender).manager()
        ];

        staking.burnStake(info.staker, info.stakedAmount);
        info.staker = address(0);
        info.stakedAmount = 0;
    }

    /**
     * @notice Function is used to withdraw CPOOL rewards from multiple pools
     * @param pools List of pools to withdrawm from
     */
    function withdrawReward(address[] memory pools) external {
        uint256 totalReward;
        for (uint256 i = 0; i < pools.length; i++) {
            require(isPool[pools[i]], "NPA");
            totalReward += IPoolMaster(pools[i]).withdrawReward(msg.sender);
        }

        if (totalReward > 0) {
            cpool.safeTransfer(msg.sender, totalReward);
        }
    }

    // VIEW FUNCTIONS

    /**
     * @notice Function returns symbol for new pool based on currency and manager
     * @param currency Pool's currency address
     * @param manager Manager's address
     * @return Pool symbol
     */
    function getPoolSymbol(address currency, address manager)
        external
        view
        returns (string memory)
    {
        return
            string(
                bytes.concat(
                    bytes("cp"),
                    bytes(managerInfo[manager].managerSymbol),
                    bytes("-"),
                    bytes(IERC20MetadataUpgradeable(currency).symbol())
                )
            );
    }

    // INTERNAL FUNCTIONS

    /**
     * @notice Internal function that proposes pool
     * @param currency Currency of the pool
     */
    function _proposePool(address currency) private {
        require(currencyAllowed[currency], "CNA");
        ManagerInfo storage info = managerInfo[msg.sender];
        require(info.currency == address(0), "AHP");

        info.proposalId = flashGovernor.propose();
        info.currency = currency;
        info.staker = msg.sender;
        info.stakedAmount = staking.lockStake(msg.sender);

        emit PoolProposed(msg.sender, currency);
    }

    /**
     * @notice Internal function that immedeately creates pool
     * @param manager Manager of the pool
     * @param currency Currency of the pool
     */
    function _forceCreatePool(address manager, address currency) private {
        require(currencyAllowed[currency], "CNA");
        ManagerInfo storage info = managerInfo[manager];
        require(info.currency == address(0), "AHP");

        IPoolMaster pool = IPoolMaster(poolMaster.clone());
        pool.initialize(manager, currency);

        info.pool = address(pool);
        info.currency = currency;
        info.staker = msg.sender;
        info.stakedAmount = staking.lockStake(msg.sender);

        isPool[address(pool)] = true;

        emit PoolCreated(address(pool), manager, currency, true);
    }

    /**
     * @notice Internal function that sets manager's info
     * @param manager Manager to set info for
     * @param info Manager's info IPFS hash
     * @param symbol Manager's symbol
     */
    function _setManager(
        address manager,
        bytes32 info,
        string memory symbol
    ) private {
        require(managerInfo[manager].ipfsHash == bytes32(0), "AHI");
        require(info != bytes32(0), "CEI");
        require(!usedManagerSymbols[symbol], "SAU");

        managerInfo[manager].ipfsHash = info;
        managerInfo[manager].managerSymbol = symbol;
        usedManagerSymbols[symbol] = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.0 (proxy/Clones.sol)

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
library ClonesUpgradeable {
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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPoolMaster {
    function manager() external view returns (address);

    function currency() external view returns (address);

    function borrows() external view returns (uint256);

    function insurance() external view returns (uint256);

    function getBorrowRate() external view returns (uint256);

    function getSupplyRate() external view returns (uint256);

    enum State {
        Active,
        Warning,
        ProvisionalDefault,
        Default,
        Closed
    }

    function state() external view returns (State);

    function initialize(address manager_, address currency_) external;

    function setRewardPerBlock(uint256 rewardPerBlock_) external;

    function withdrawReward(address account) external returns (uint256);

    function transferReserves() external;

    function processAuctionStart() external;

    function processDebtClaim() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IFlashGovernor {
    function proposalEndBlock(uint32 proposalId)
        external
        view
        returns (uint256);

    function propose() external returns (uint32);

    function execute(uint32 proposalId) external;

    enum ProposalState {
        Pending,
        Active,
        Defeated,
        Succeeded,
        Executed
    }

    function state(uint32 proposalId) external view returns (ProposalState);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IMembershipStaking {
    function managerMinimalStake() external view returns (uint256);

    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint256);

    function lockStake(address account) external returns (uint256);

    function unlockStake(address account, uint256 amount) external;

    function burnStake(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Decimal {
    /// @notice Number one as 18-digit decimal
    uint256 internal constant ONE = 1e18;

    /**
     * @notice Internal function for 10-digits decimal division
     * @param number Integer number
     * @param decimal Decimal number
     * @return Returns multiplied numbers
     */
    function mulDecimal(uint256 number, uint256 decimal)
        internal
        pure
        returns (uint256)
    {
        return (number * decimal) / ONE;
    }

    /**
     * @notice Internal function for 10-digits decimal multiplication
     * @param number Integer number
     * @param decimal Decimal number
     * @return Returns integer number divided by second
     */
    function divDecimal(uint256 number, uint256 decimal)
        internal
        pure
        returns (uint256)
    {
        return (number * ONE) / decimal;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}