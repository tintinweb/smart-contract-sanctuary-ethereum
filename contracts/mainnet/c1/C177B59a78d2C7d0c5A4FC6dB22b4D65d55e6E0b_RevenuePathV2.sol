// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IERC2771Recipient.sol";

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
}

// SPDX-License-Identifier: SPWPL
pragma solidity 0.8.15;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";

/*******************************
 * @title Revenue Path V2
 * @notice The revenue path clone instance contract.
 */

interface IReveelMainV2 {
    function getPlatformWallet() external view returns (address);
}

contract RevenuePathV2 is ERC2771Recipient, Ownable, Initializable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint32 public constant BASE = 1e7;
    uint8 public constant VERSION = 2;

    //@notice Status to flag if fee is applicable to the revenue paths
    bool private feeRequired;

    //@notice Status to flag if revenue path is immutable. True if immutable
    bool private isImmutable;

    //@notice Fee percentage that will be applicable for additional tiers
    uint32 private platformFee;

    //@notice address of origin factory
    address private mainFactory;

    /** @notice For a given tier & address, the token revenue distribution proportion is returned
     *  @dev Index for tiers starts from 0. i.e, the first tier is marked 0 in the list.
     */
    mapping(uint256 => mapping(address => uint256)) private revenueProportion;

    // @notice Amount of token released for a given wallet [token][wallet]=>[amount]
    mapping(address => mapping(address => uint256)) private released;

    //@notice token tier limits for given token address and tier
    mapping(address => mapping(uint256 => uint256)) private tokenTierLimits;

    mapping(address => uint256) private currentTokenTier;

    // @notice Total token released from the revenue path for a given token address
    mapping(address => uint256) private totalTokenReleased;

    // @notice Total token accounted for the revenue path for a given token address
    mapping(address => uint256) private totalTokenAccounted;

    /**  @notice For a given token & wallet address, the amount of the token that can been withdrawn by the wallet
    [token][wallet]*/
    mapping(address => mapping(address => uint256)) private tokenWithdrawable;

    // @notice Total amount of token distributed for a given tier at that time.
    //[token][tier]-> [distributed amount]
    mapping(address => mapping(uint256 => uint256)) private totalDistributed;

    //@noitce Total fee accumulated by the revenue path and waiting to be collected.
    mapping(address => uint256) private feeAccumulated;

    struct RevenuePath {
        address[] walletList;
    }

    struct PathInfo {
        uint32 platformFee;
        bool isImmutable;
        address factory;
        address forwarder;
    }

    RevenuePath[] private revenueTiers;

    /********************************
     *           EVENTS              *
     ********************************/

    /** @notice Emits when token payment is withdrawn/claimed by a member
     * @param account The wallet for which ETH has been claimed for
     * @param payment The amount of ETH that has been paid out to the wallet
     */
    event PaymentReleased(address indexed account, address indexed token, uint256 indexed payment);

    /** @notice Emits when ERC20 payment is withdrawn/claimed by a member
     * @param token The token address for which withdrawal is made
     * @param account The wallet address to which withdrawal is made
     * @param payment The amount of the given token the wallet has claimed
     */
    event ERC20PaymentReleased(address indexed token, address indexed account, uint256 indexed payment);

    /** @notice Emits when tokens are distributed during withdraw or external distribution call
     *  @param token Address of token for distribution. Zero address for native token like ETH
     *  @param amount The amount of token distributed in wei
     *  @param tier The tier for which the distribution occured
     */
    event TokenDistributed(address indexed token, uint256 indexed amount, uint256 indexed tier);

    /** @notice Emits on receive; mimics ERC20 Transfer
     *  @param from Address that deposited the eth
     *  @param value Amount of ETH deposited
     */
    event DepositETH(address indexed from, uint256 value);

    /**
     *  @notice Emits when fee is distributed
     *  @param token The token address. Address 0 for native gas token like ETH
     *  @param amount The amount of fee deducted
     */
    event FeeDistributed(address indexed token, uint256 indexed amount);

    /**
     *  @notice Emits when fee is released
     *  @param token The token address. Address 0 for native gas token like ETH
     *  @param amount The amount of fee released
     */
    event FeeReleased(address indexed token, uint256 indexed amount);

    /**
     * emits when one or more revenue tiers are added
     *  @param wallets Array of arrays of wallet lists (each array is a tier)
     *  @param distributions Array of arrays of distr %s (each array is a tier)
     */
    event RevenueTierAdded(address[][] wallets, uint256[][] distributions);

    /**
     * emits when one or more revenue tiers wallets/distributions are updated
     *  @param tierNumbers Array tier numbers being updated
     *  @param wallets Array of arrays of wallet lists (each array is a tier)
     *  @param distributions Array of arrays of distr %s (each array is a tier)
     */
    event RevenueTierUpdated(uint256[] tierNumbers, address[][] wallets, uint256[][] distributions);

    /**
     * emits when one revenue tier's limit is updated
     *  @param tier tier number being updated
     *  @param tokenList Array of tokens in that tier
     *  @param newLimits Array of limits for those tokens
     */
    event TierLimitUpdated(uint256 tier, address[] tokenList, uint256[] newLimits);

    /********************************
     *           MODIFIERS          *
     ********************************/
    /** @notice Entrant guard for mutable contract methods
     */
    modifier isMutable() {
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
    error WalletAndDistrbutionCtMismatch(uint256 walletCount, uint256 distributionCount);

    /** @dev Reverts when the member has zero  withdrawal balance available
     */
    error NoDuePayment();

    /** @dev Reverts when immutable path attempts to use mutable methods
     */
    error RevenuePathNotMutable();

    /** @dev Reverts when contract has insufficient token for withdrawal
     * @param contractBalance  The total balance of token available in the contract
     * @param requiredAmount The total amount of token requested for withdrawal
     */
    error InsufficentBalance(uint256 contractBalance, uint256 requiredAmount);

    /**
     *  @dev Reverts when duplicate wallet entry is present during initialize, addition or updates
     */
    error DuplicateWalletEntry();

    /**
     * @dev In case invalid zero address is provided for wallet address
     */
    error ZeroAddressProvided();

    /**
     * @dev Reverts when zero distribution percentage is provided
     */
    error ZeroDistributionProvided();

    /**
     * @dev Reverts when summation of distirbution is not equal to BASE
     */
    error TotalShareNot100();

    /**
     * @dev Reverts when a tier not in existence or added is attempted for update
     */
    error OnlyExistingTiersCanBeUpdated();

    /**
     * @dev Reverts when token already released is greater than the new limit that's being set for the tier.
     */
    error TokenLimitNotValid();

    /**
     *  @dev Reverts when tier limit given is zero in certain cases
     */
    error TierLimitGivenZero();

    /**
     * @dev Reverts when tier limit of a non-existant tier is attempted
     */
    error OnlyExistingTierLimitsCanBeUpdated();

    /**
     * @dev The total numb of tokens and equivalent token limit list count mismatch
     */
    error TokensAndTierLimitMismatch(uint256 tokenCount, uint256 limitListCount);

    /**
     * @dev The total tiers list and limits list length mismatch
     */
    error TotalTierLimitsMismatch(uint256 tiers, uint256 limits);

    /**
     * @dev Reverts when final tier is attempted for updates
     */
    error FinalTierLimitNotUpdatable();

    /********************************
     *           FUNCTIONS           *
     ********************************/

    /**
     * @notice Receive ETH
     */
    receive() external payable {
        emit DepositETH(_msgSender(), msg.value);
    }

    /** @notice Called for a given token to distribute, unallocated tokens to the respective tiers and wallet members
     *  @param token The address of the token
     */
    function distributePendingTokens(address token) public {
        uint256 pendingAmount = getPendingDistributionAmount(token);
        uint256 presentTier;
        uint256 currentTierDistribution;
        uint256 tokenLimit;
        uint256 tokenTotalDistributed;
        uint256 nextTierDistribution;
        while (pendingAmount > 0) {
            presentTier = currentTokenTier[token];
            tokenLimit = tokenTierLimits[token][presentTier];
            tokenTotalDistributed = totalDistributed[token][presentTier];
            if (tokenLimit > 0 && (tokenTotalDistributed + pendingAmount) > tokenLimit) {
                currentTierDistribution = tokenLimit - tokenTotalDistributed;
                nextTierDistribution = pendingAmount - currentTierDistribution;
            } else {
                currentTierDistribution = pendingAmount;
                nextTierDistribution = 0;
            }

            if (currentTierDistribution > 0) {
                address[] memory walletMembers = revenueTiers[presentTier].walletList;
                uint256 totalWallets = walletMembers.length;
                uint256 feeDeduction;
                if (feeRequired && platformFee > 0) {
                    feeDeduction = ((currentTierDistribution * platformFee) / BASE);
                    feeAccumulated[token] += feeDeduction;
                    currentTierDistribution -= feeDeduction;
                    emit FeeDistributed(token, feeDeduction);
                }

                for (uint256 i; i < totalWallets; ) {
                    tokenWithdrawable[token][walletMembers[i]] += ((currentTierDistribution *
                        revenueProportion[presentTier][walletMembers[i]]) / BASE);
                    unchecked {
                        i++;
                    }
                }

                totalTokenAccounted[token] += (currentTierDistribution + feeDeduction);
                totalDistributed[token][presentTier] += (currentTierDistribution + feeDeduction);
                emit TokenDistributed(token, currentTierDistribution, presentTier);
            }
            pendingAmount = nextTierDistribution;
            if (nextTierDistribution > 0) {
                currentTokenTier[token] += 1;
            }
        }
    }

    /** @notice Get the token amount that has not been allocated for in the revenue path
     *  @param token The token address
     */
    function getPendingDistributionAmount(address token) public view returns (uint256) {
        uint256 pathTokenBalance;
        if (token == address(0)) {
            pathTokenBalance = address(this).balance;
        } else {
            pathTokenBalance = IERC20(token).balanceOf(address(this));
        }
        uint256 pendingAmount = (pathTokenBalance + totalTokenReleased[token]) - totalTokenAccounted[token];
        return pendingAmount;
    }

    /** @notice Initializes revenue path
     *  @param _walletList Nested array for wallet list across different tiers
     *  @param _distribution Nested array for distribution percentage across different tiers
     *  @param _tokenList A list of tokens for which limits will be set
     *  @param _limitSequence A nested array of limits for each token
     *  @param pathInfo A property object for the path details
     *  @param _owner Address of path owner
     */
    function initialize(
        address[][] memory _walletList,
        uint256[][] memory _distribution,
        address[] memory _tokenList,
        uint256[][] memory _limitSequence,
        PathInfo memory pathInfo,
        address _owner
    ) external initializer {
        uint256 totalTiers = _walletList.length;
        uint256 totalTokens = _tokenList.length;
        if (totalTiers != _distribution.length) {
            revert WalletAndDistrbutionCtMismatch({
                walletCount: _walletList.length,
                distributionCount: _distribution.length
            });
        }

        if (totalTokens != _limitSequence.length) {
            revert TokensAndTierLimitMismatch({ tokenCount: totalTokens, limitListCount: _limitSequence.length });
        }
        for (uint256 i; i < totalTiers; ) {
            RevenuePath memory tier;

            uint256 walletMembers = _walletList[i].length;

            if (walletMembers != _distribution[i].length) {
                revert WalletAndDistrbutionCtMismatch({
                    walletCount: walletMembers,
                    distributionCount: _distribution[i].length
                });
            }

            tier.walletList = _walletList[i];

            uint256 totalShare;
            for (uint256 j; j < walletMembers; ) {
                address wallet = (_walletList[i])[j];
                if (revenueProportion[i][wallet] > 0) {
                    revert DuplicateWalletEntry();
                }
                if (wallet == address(0)) {
                    revert ZeroAddressProvided();
                }
                if ((_distribution[i])[j] == 0) {
                    revert ZeroDistributionProvided();
                }
                revenueProportion[i][wallet] = (_distribution[i])[j];
                totalShare += (_distribution[i])[j];
                unchecked {
                    j++;
                }
            }
            if (totalShare != BASE) {
                revert TotalShareNot100();
            }
            revenueTiers.push(tier);

            unchecked {
                i++;
            }
        }

        for (uint256 k; k < totalTokens; ) {
            address token = _tokenList[k];
            for (uint256 m; m < totalTiers; ) {
                if ((totalTiers - 1) != _limitSequence[k].length) {
                    revert TotalTierLimitsMismatch({ tiers: totalTiers, limits: _limitSequence[k].length });
                }
                // set tier limits, except for final tier which has no limit
                if (m != totalTiers - 1) {
                    if (_limitSequence[k][m] == 0) {
                        revert TierLimitGivenZero();
                    }
                    tokenTierLimits[token][m] = _limitSequence[k][m];
                }

                unchecked {
                    m++;
                }
            }

            unchecked {
                k++;
            }
        }

        if (revenueTiers.length > 1) {
            feeRequired = true;
        }
        mainFactory = pathInfo.factory;
        platformFee = pathInfo.platformFee;
        isImmutable = pathInfo.isImmutable;
        _transferOwnership(_owner);
        _setTrustedForwarder(pathInfo.forwarder);
    }

    /** @notice Adding new revenue tiers
     *  @param _walletList a nested list of new wallets
     *  @param _distribution a nested list of corresponding distribution
     */
    function addRevenueTiers(address[][] calldata _walletList, uint256[][] calldata _distribution)
        external
        isMutable
        onlyOwner
    {
        if (_walletList.length != _distribution.length) {
            revert WalletAndDistrbutionCtMismatch({
                walletCount: _walletList.length,
                distributionCount: _distribution.length
            });
        }

        uint256 listLength = _walletList.length;
        uint256 nextRevenueTier = revenueTiers.length;

        for (uint256 i; i < listLength; ) {
            uint256 walletMembers = _walletList[i].length;

            if (walletMembers != _distribution[i].length) {
                revert WalletAndDistrbutionCtMismatch({
                    walletCount: walletMembers,
                    distributionCount: _distribution[i].length
                });
            }
            RevenuePath memory tier;
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
                revert TotalShareNot100();
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
        emit RevenueTierAdded(_walletList, _distribution);
    }

    /** @notice Updating distribution for existing revenue tiers
     *  @param _walletList A nested list of wallet address
     *  @param _distribution A nested list of distribution percentage
     *  @param _tierNumbers A list of tier numbers to be updated
     */
    function updateRevenueTiers(
        address[][] calldata _walletList,
        uint256[][] calldata _distribution,
        uint256[] calldata _tierNumbers
    ) external isMutable onlyOwner {
        uint256 totalUpdates = _tierNumbers.length;
        if (_walletList.length != _distribution.length || _walletList.length != totalUpdates) {
            revert WalletAndDistrbutionCtMismatch({
                walletCount: _walletList.length,
                distributionCount: _distribution.length
            });
        }

        uint256 totalTiers = revenueTiers.length;

        for (uint256 i; i < totalUpdates; ) {
            uint256 totalWallets = _walletList[i].length;
            if (totalWallets != _distribution[i].length) {
                revert WalletAndDistrbutionCtMismatch({
                    walletCount: _walletList[i].length,
                    distributionCount: _distribution[i].length
                });
            }
            uint256 tier = _tierNumbers[i];
            if (tier >= totalTiers) {
                revert OnlyExistingTiersCanBeUpdated();
            }

            address[] memory previousWalletList = revenueTiers[tier].walletList;

            for (uint256 k; k < previousWalletList.length; ) {
                revenueProportion[tier][previousWalletList[k]] = 0;
                unchecked {
                    k++;
                }
            }

            uint256 totalShares;
            address[] memory newWalletList = new address[](totalWallets);
            for (uint256 j; j < totalWallets; ) {
                address wallet = (_walletList[i])[j];
                if (revenueProportion[tier][wallet] > 0) {
                    revert DuplicateWalletEntry();
                }

                if (wallet == address(0)) {
                    revert ZeroAddressProvided();
                }
                if ((_distribution[i])[j] == 0) {
                    revert ZeroDistributionProvided();
                }
                revenueProportion[tier][wallet] = (_distribution[i])[j];
                totalShares += (_distribution[i])[j];
                newWalletList[j] = wallet;

                unchecked {
                    j++;
                }
            }
            revenueTiers[tier].walletList = newWalletList;
            if (totalShares != BASE) {
                revert TotalShareNot100();
            }
            unchecked {
                i++;
            }
        }
        emit RevenueTierUpdated(_tierNumbers, _walletList, _distribution);
    }

    /** @notice Update tier limits for given tokens for an existing tier
     * @param tokenList A list of tokens for which limits will be updated
     * @param newLimits A list of corresponding limits for the tokens
     * @param tier The tier for which limits are being updated
     */
    function updateLimits(
        address[] calldata tokenList,
        uint256[] calldata newLimits,
        uint256 tier
    ) external isMutable onlyOwner {
        uint256 listCount = tokenList.length;
        uint256 totalTiers = revenueTiers.length;

        if (listCount != newLimits.length) {
            revert TokensAndTierLimitMismatch({ tokenCount: listCount, limitListCount: newLimits.length });
        }
        if (tier >= totalTiers) {
            revert OnlyExistingTierLimitsCanBeUpdated();
        }

        if (tier == totalTiers - 1) {
            revert FinalTierLimitNotUpdatable();
        }

        for (uint256 i; i < listCount; ) {
            if (totalDistributed[tokenList[i]][tier] > newLimits[i]) {
                revert TokenLimitNotValid();
            }
            tokenTierLimits[tokenList[i]][tier] = newLimits[i];

            unchecked {
                i++;
            }
        }
        emit TierLimitUpdated(tier, tokenList, newLimits);
    }

    /** @notice Releases distribute token
     * @param token The token address
     * @param account The address of the receiver
     */
    function release(address token, address payable account) external nonReentrant {
        distributePendingTokens(token);
        uint256 payment = tokenWithdrawable[token][account];
        if (payment == 0) {
            revert NoDuePayment();
        }

        released[token][account] += payment;
        totalTokenReleased[token] += payment;
        tokenWithdrawable[token][account] = 0;

        if (token == address(0)) {
            if (feeAccumulated[token] > 0) {
                uint256 value = feeAccumulated[token];
                feeAccumulated[token] = 0;
                totalTokenReleased[token] += value;
                address platformFeeWallet = IReveelMainV2(mainFactory).getPlatformWallet();
                sendValue(payable(platformFeeWallet), value);
                emit FeeReleased(token, value);
            }

            sendValue(account, payment);
            emit PaymentReleased(account, token, payment);
        } else {
            if (feeAccumulated[token] > 0) {
                uint256 value = feeAccumulated[token];
                feeAccumulated[token] = 0;
                totalTokenReleased[token] += value;
                address platformFeeWallet = IReveelMainV2(mainFactory).getPlatformWallet();
                IERC20(token).safeTransfer(platformFeeWallet, value);
                emit FeeReleased(token, value);
            }

            IERC20(token).safeTransfer(account, payment);

            emit ERC20PaymentReleased(token, account, payment);
        }
    }

    /** @notice Get the wallet list for a given revenue tier
     * @param tierNumber the index of the tier for which list needs to be provided.
     */
    function getRevenueTier(uint256 tierNumber) external view returns (address[] memory _walletList) {
        require(tierNumber < revenueTiers.length, "TIER_DOES_NOT_EXIST");
        address[] memory listWallet = revenueTiers[tierNumber].walletList;
        return (listWallet);
    }

    /** @notice Get the totalNumber of revenue tiers in the revenue path
     */
    function getTotalRevenueTiers() external view returns (uint256 total) {
        return revenueTiers.length;
    }

    /** @notice Get the current ongoing tier of revenue path
     * For eth: token address(0) is reserved
     */
    function getCurrentTier(address token) external view returns (uint256 tierNumber) {
        return currentTokenTier[token];
    }

    /** @notice Get the current ongoing tier of revenue path
     */
    function getFeeRequirementStatus() external view returns (bool required) {
        return feeRequired;
    }

    /** @notice Get the token revenue proportion for a given account at a given tier
     *  @param tier The tier to fetch revenue proportions for
     *  @param account The wallet address for which revenue proportion is requested
     */
    function getRevenueProportion(uint256 tier, address account) external view returns (uint256 proportion) {
        return revenueProportion[tier][account];
    }

    /** @notice Get the amount of token distrbuted for a given tier
     *  @param token The token address for which distributed amount is fetched
     *  @param tier The tier for which distributed amount is fetched
     */

    function getTierDistributedAmount(address token, uint256 tier) external view returns (uint256 amount) {
        return totalDistributed[token][tier];
    }

    /** @notice Get the amount of ETH accumulated for fee collection
     */

    function getTotalFeeAccumulated(address token) external view returns (uint256 amount) {
        return feeAccumulated[token];
    }

    /** @notice Get the amount of token released for a given account
     *  @param token the token address for which token released is fetched
     *  @param account the wallet address for whih the token released is fetched
     */

    function getTokenReleased(address token, address account) external view returns (uint256 amount) {
        return released[token][account];
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

    /** @notice Get the amount of total eth withdrawn by the account
     */
    function getTokenWithdrawn(address token, address account) external view returns (uint256) {
        return released[token][account];
    }

    function getTokenTierLimits(address token, uint256 tier) external view returns (uint256) {
        return tokenTierLimits[token][tier];
    }

    /** @notice Update the trusted forwarder address
     *  @param forwarder The address of the new forwarder
     *
     */
    function setTrustedForwarder(address forwarder) external onlyOwner {
        _setTrustedForwarder(forwarder);
    }

    /**
     *  @notice Total wallets available in a tier
     *  @param tier The tier for which wallet counts will be fetched
     */
    function getTierWalletCount(uint256 tier) external view returns (uint256) {
        return revenueTiers[tier].walletList.length;
    }

    /**
     * @notice Returns total token released
     * @param token The token for which total released amount is fetched
     */
    function getTotalTokenReleased(address token) external view returns (uint256) {
        return totalTokenReleased[token];
    }

    /**
     * @notice Returns total token accounted for a given token address
     * @param token The token for which total accountd amount is fetched
     */
    function getTotalTokenAccounted(address token) external view returns (uint256) {
        return totalTokenAccounted[token];
    }

    /**
     * @notice Returns withdrawable or claimable token amount for a given wallet in the revenue path
     */
    function getWithdrawableToken(address token, address wallet) external view returns (uint256) {
        return tokenWithdrawable[token][wallet];
    }

    /**
     * @notice Returns the ReveelMainV2 contract address
     */
    function getMainFactory() external view returns (address) {
        return mainFactory;
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

    function _msgSender() internal view virtual override(Context, ERC2771Recipient) returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    function _msgData() internal view virtual override(Context, ERC2771Recipient) returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return msg.data;
        }
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
                version == 1 && !Address.isContract(address(this)),
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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