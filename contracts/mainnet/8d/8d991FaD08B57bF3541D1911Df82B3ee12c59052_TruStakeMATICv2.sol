// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.19;

// Polygon
import {IValidatorShare} from "../interfaces/IValidatorShare.sol";
import {IStakeManager} from "../interfaces/IStakeManager.sol";
import {IMasterWhitelist} from "../interfaces/IMasterWhitelist.sol";

// OpenZeppelin
import {ERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

// TruFin
import {ITruStakeMATICv2} from "../interfaces/ITruStakeMATICv2.sol";
import {TruStakeMATICv2Storage} from "./TruStakeMATICv2Storage.sol";
import "./Types.sol";

uint256 constant PHI_PRECISION = 1e4;

/// @title TruStakeMATICv2
/// @notice An auto-compounding liquid staking MATIC vault with reward-allocating functionality.
contract TruStakeMATICv2 is
    TruStakeMATICv2Storage,
    ITruStakeMATICv2,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC4626Upgradeable
{
    // *** LIBRARIES ***

    using SafeERC20Upgradeable for IERC20Upgradeable;

    // *** CONSTRUCTOR & INITIALIZER ***

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Vault state initializer.
    /// @param _stakingTokenAddress MATIC token address.
    /// @param _stakeManagerContractAddress Polygon's StakeManager contract address.
    /// @param _validatorShareContractAddress Share contract of the validator the vault delegates to.
    /// @param _whitelistAddress The vault's whitelist contract address.
    /// @param _treasuryAddress Treasury address that receives vault fees.
    /// @param _phi Fee taken on restake in basis points.
    /// @param _distPhi Fee taken during the distribution of rewards earned from non-strict allocations.
    /// @param _cap Limit placed on combined vault deposits.
    function initialize(
        address _stakingTokenAddress,
        address _stakeManagerContractAddress,
        address _validatorShareContractAddress,
        address _whitelistAddress,
        address _treasuryAddress,
        uint256 _phi,
        uint256 _distPhi,
        uint256 _cap
    ) external initializer {
        // Initialize derived state
        __ReentrancyGuard_init();
        __Ownable_init();
        __ERC4626_init(IERC20Upgradeable(_stakingTokenAddress));
        __ERC20_init("TruStake MATIC Vault Shares", "TruMATIC");

        // Ensure addresses are non-zero
        _checkNotZeroAddress(_stakingTokenAddress);
        _checkNotZeroAddress(_stakeManagerContractAddress);
        _checkNotZeroAddress(_validatorShareContractAddress);
        _checkNotZeroAddress(_whitelistAddress);
        _checkNotZeroAddress(_treasuryAddress);

        if (_phi > PHI_PRECISION) {
            revert PhiTooLarge();
        }

        if (_distPhi > PHI_PRECISION) {
            revert DistPhiTooLarge();
        }

        // Initialize contract state
        stakingTokenAddress = _stakingTokenAddress;
        stakeManagerContractAddress = _stakeManagerContractAddress;
        validatorShareContractAddress = _validatorShareContractAddress;
        whitelistAddress = _whitelistAddress;
        treasuryAddress = _treasuryAddress;
        phi = _phi;
        cap = _cap;
        distPhi = _distPhi;
        epsilon = 1e4;
        allowStrict = false; // strictness disabled until fully implemented

        emit StakerInitialized(
            _stakingTokenAddress,
            _stakeManagerContractAddress,
            _validatorShareContractAddress,
            _whitelistAddress,
            _treasuryAddress,
            _phi,
            _cap,
            _distPhi
        );
    }

    // *** MODIFIERS ***

    // Reverts call if caller is not whitelisted
    modifier onlyWhitelist() {
        if (!IMasterWhitelist(whitelistAddress).isUserWhitelisted(msg.sender)) {
            revert UserNotWhitelisted();
        }
        _;
    }

    // **************************************** VIEW FUNCTIONS ****************************************

    // *** VAULT INFO ***

    /// @notice Gets the total amount of MATIC currently staked by the vault.
    /// @return Total amount of MATIC staked by the vault via validator delegation.
    function totalStaked() public view returns (uint256) {
        (uint256 stake,) = IValidatorShare(validatorShareContractAddress).getTotalStake(address(this));
        return stake;
    }

    /// @notice Gets the vault's unclaimed MATIC rewards.
    /// @return Amount of liquid claimable MATIC earned through validator delegation.
    function totalRewards() public view returns (uint256) {
        return IValidatorShare(validatorShareContractAddress).getLiquidRewards(address(this));
    }

    /// @notice Gets the price of one TruMATIC share in MATIC.
    /// @dev Represented via a fraction. Factor of 1e18 included in numerator to avoid rounding errors (currently redundant).
    /// @return globalPriceNum Numerator of the vault's share price fraction.
    /// @return globalPriceDenom Denominator of the vault's share price fraction.
    function sharePrice() public view returns (uint256, uint256) {
        if (totalSupply() == 0) return (1e18, 1);

        uint256 totalCapitalTimesPhiPrecision = (totalStaked() + totalAssets()) *
            PHI_PRECISION +
            (PHI_PRECISION - phi) *
            totalRewards();

        // Calculate share price fraction components
        uint256 globalPriceNum = totalCapitalTimesPhiPrecision * 1e18;
        uint256 globalPriceDenom = totalSupply() * PHI_PRECISION;

        return (globalPriceNum, globalPriceDenom);
    }

    // *** GETTERS ***

    /// @notice Convenience getter for retrieving user-relevant info.
    /// @param _user Address of the user.
    /// @return maxRedeemable Maximum TruMATIC that can be redeemed by the user.
    /// @return maxWithdrawAmount Maximum MATIC that can be withdrawn by the user.
    /// @return globalPriceNum Numerator of the vault's share price fraction.
    /// @return globalPriceDenom Denominator of the vault's share price fraction.
    /// @return epoch Current Polygon epoch.
    function getUserInfo(address _user) public view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 globalPriceNum, uint256 globalPriceDenom) = sharePrice();
        uint256 maxRedeemable = maxRedeem(_user);
        uint256 maxWithdrawAmount = maxWithdraw(_user);
        uint256 epoch = getCurrentEpoch();

        return (maxRedeemable, maxWithdrawAmount, globalPriceNum, globalPriceDenom, epoch);
    }

    /// @notice Calculates the amount of fees from MATIC rewards that haven't yet been turned into shares.
    /// @return The amount of fees from rewards that haven't yet been turned into shares
    function getDust() external view returns (uint256) {
        return (totalRewards() * phi) / PHI_PRECISION;
    }

    /// @notice Gets the latest unbond nonce from the vault's delegator.
    /// @return Current unbond nonce for vault-delegator unbonds.
    function getUnbondNonce() external view returns (uint256) {
        return IValidatorShare(validatorShareContractAddress).unbondNonces(address(this));
    }

    /// @notice Gets the current epoch from Polygons's StakeManager contract.
    /// @return Current Polygon epoch.
    function getCurrentEpoch() public view returns (uint256) {
        return IStakeManager(stakeManagerContractAddress).epoch();
    }

    /// @notice Gets a recipient's distributors.
    /// @param _user The recipient.
    /// @param _strict Whether to get strict-distributors (true) or loose distributors (false).
    /// @return The recipient's distributors.
    function getDistributors(address _user, bool _strict) public view returns (address[] memory) {
        return distributors[_user][_strict];
    }

    /// @notice Gets a distributor's recipients.
    /// @param _user The distributor.
    /// @param _strict Whether to get strict-recipients (true) or loose recipients (false).
    /// @return The distributor's recipients.
    function getRecipients(address _user, bool _strict) public view returns (address[] memory) {
        return recipients[_user][_strict];
    }

    /// @notice Checks if the unbond specified via the input nonce can be claimed from the delegator.
    /// @param _unbondNonce Nonce of the unbond under consideration.
    /// @return Boolean indicating whether the unbond can be claimed.
    function isClaimable(uint256 _unbondNonce) external view returns (bool) {
        // Get epoch at which unbonding of delegated MATIC was initiated
        (, uint256 withdrawEpoch) = IValidatorShare(validatorShareContractAddress).unbonds_new(
            address(this),
            _unbondNonce
        );

        // Check required epochs have passed
        bool epochsPassed = getCurrentEpoch() >= withdrawEpoch + 80;

        bool withdrawalPresent = unbondingWithdrawals[_unbondNonce].user != address(0);

        return withdrawalPresent && epochsPassed;
    }

    // *** MAXIMUMS ***

    /// @notice Gets the maximum amount of MATIC a user could deposit into the vault.
    /// @return The amount of MATIC.
    function maxDeposit(address) public view override returns (uint256) {
        return cap - totalStaked();
    }

    /// @notice Gets the maximum number of TruMATIC shares a user could mint.
    /// @return The amount of TruMATIC.
    function maxMint(address) public view override returns (uint256) {
        return previewDeposit(maxDeposit(address(0)));
    }

    /// @notice Gets the maximum amount of MATIC a user can withdraw from the vault.
    /// @param _user The user under consideration.
    /// @return The amount of MATIC.
    function maxWithdraw(address _user) public view override returns (uint256) {
        uint256 preview = previewRedeem(maxRedeem(_user));

        if (preview == 0) {
            return 0;
        }

        return preview + epsilon;
    }

    /// @notice Gets the maximum number of TruMATIC shares a user can redeem into MATIC.
    /// @param _user The user under consideration.
    /// @return The amount of TruMATIC.
    function maxRedeem(address _user) public view override returns (uint256) {
        Allocation storage totalAllocation = totalAllocated[_user][true];

        // Cache from storage
        uint256 maticAmount = totalAllocation.maticAmount;

        // Redeemer can't withdraw shares equivalent to their total allocation plus its rewards
        uint256 unredeemableShares = (maticAmount == 0)
            ? 0
            : MathUpgradeable.mulDiv(
                totalAllocation.maticAmount * 1e18,
                totalAllocation.sharePriceDenom,
                totalAllocation.sharePriceNum,
                MathUpgradeable.Rounding.Up
            );

        // We rounded up unredeemableShares to ensure excess shares are not returned
        return balanceOf(_user) > unredeemableShares ? balanceOf(_user) - unredeemableShares : 0;
    }

    /// @inheritdoc ERC4626Upgradeable
    function previewRedeem(uint256 _shares) public view override returns (uint256) {
        return _convertToAssets(_shares, MathUpgradeable.Rounding.Up);
    }

    // **************************************** STATE-CHANGING FUNCTIONS ****************************************

    // *** JOINING THE VAULT ***

    /// @notice Deposits an amount of caller->-vault approved MATIC into the vault.
    /// @param _assets The amount of MATIC to deposit.
    /// @param _receiver The address to receive TruMATIC shares (must be caller to avoid reversion).
    /// @return The resulting amount of TruMATIC shares minted to the caller (receiver).
    function deposit(uint256 _assets, address _receiver) public override onlyWhitelist nonReentrant returns (uint256) {
        if (msg.sender != _receiver) {
            revert SenderAndOwnerMustBeReceiver();
        }

        _deposit(msg.sender, _assets);

        return previewDeposit(_assets);
    }

    /// @notice Mints an amount of vault shares to the caller.
    /// @dev Requires equivalent value of MATIC to be approved to the vault by the caller (converted using current share price).
    /// @param _shares The amount of shares to mint.
    /// @param _receiver The address to receive said TruMATIC shares (must be caller to avoid reversion).
    /// @return The resulting amount of MATIC deposited into the vault.
    function mint(uint256 _shares, address _receiver) public override onlyWhitelist nonReentrant returns (uint256) {
        if (msg.sender != _receiver) {
            revert SenderAndOwnerMustBeReceiver();
        }

        uint256 assets = previewMint(_shares);

        _deposit(msg.sender, assets);

        return assets;
    }

    // *** LEAVING THE VAULT ***

    /// @notice Initiates a withdrawal request for an amount of MATIC from the vault and burns corresponding TruMATIC shares.
    /// @param _assets The amount of MATIC to withdraw.
    /// @param _receiver The address to receive the MATIC (must be caller to avoid reversion).
    /// @param _user The address whose shares are to be burned (must be caller to avoid reversion).
    /// @return The resulting amount of TruMATIC shares burned from the caller (owner).
    function withdraw(
        uint256 _assets,
        address _receiver,
        address _user
    ) public override onlyWhitelist nonReentrant returns (uint256) {
        if (msg.sender != _receiver || msg.sender != _user) {
            revert SenderAndOwnerMustBeReceiver();
        }

        _withdrawRequest(msg.sender, _assets);

        return previewWithdraw(_assets);
    }

    /// @notice Initiates a withdrawal request for the underlying MATIC of an amount of TruMATIC shares from the vault.
    /// @param _shares The amount of TruMATIC shares to redeem and burn.
    /// @param _receiver The address to receive the underlying MATIC (must be caller to avoid reversion).
    /// @param _user The address whose shares are to be burned (must be caller to avoid reversion).
    /// @return The amount of MATIC scheduled for withdrawal from the vault.
    function redeem(
        uint256 _shares,
        address _receiver,
        address _user
    ) public override onlyWhitelist nonReentrant returns (uint256) {
        if (msg.sender != _receiver || msg.sender != _user) {
            revert SenderAndOwnerMustBeReceiver();
        }

        uint256 assets = previewRedeem(_shares);

        _withdrawRequest(msg.sender, assets);

        return assets;
    }

    // *** CLAIMING WITHDRAWALS ***

    /// @notice Claims a previous requested and now unbonded withdrawal.
    /// @param _unbondNonce Nonce of the corresponding delegator unbond.
    function withdrawClaim(uint256 _unbondNonce) external onlyWhitelist nonReentrant {
        _withdrawClaim(_unbondNonce);
    }

    /// @notice Claims multiple previously requested and now unbonded withdrawals.
    /// @param _unbondNonces List of delegator unbond nonces corresponding to said withdrawals.
    function claimList(uint256[] calldata _unbondNonces) external onlyWhitelist nonReentrant {
        uint256 len = _unbondNonces.length;

        for (uint256 i = 0; i < len; ) {
            _withdrawClaim(_unbondNonces[i]);

            unchecked {
                i++;
            }
        }
    }

    /// @notice Stakes MATIC lingering in the vault.
    /// @dev Such MATIC arrives in the vault via auto-claiming during vault delegations/unbonds (buy/sell validator vouchers).
    function stakeClaimedRewards() external nonReentrant {
        _deposit(address(0), 0);
    }

    /// @notice Restakes the vault's current unclaimed delegation-earned rewards.
    /// @dev Can be called manually to prevent the rewards surpassing reserves. This could lead to insufficient funds for
    /// withdrawals, as they are taken from delegated MATIC and not its rewards.
    function compoundRewards() external nonReentrant {
        uint256 amountRestaked = totalRewards();

        // To keep share price constant when rewards are staked, new shares need to be minted
        uint256 shareIncrease = convertToShares(totalStaked() + amountRestaked + totalAssets()) - totalSupply();

        _restake();

        // Minted shares are given to the treasury to effectively take a fee
        _mint(treasuryAddress, shareIncrease);

        // Emitted for ERC4626 compliance
        emit Deposit(msg.sender, treasuryAddress, 0, shareIncrease);

        emit RewardsCompounded(amountRestaked, shareIncrease);
    }

    // *** ALLOCATIONS ***

    /// @notice Allocates the validation rewards earned by an amount of the caller's staked MATIC to a user.
    /// @param _amount The amount of staked MATIC.
    /// @param _recipient The address of the target recipient.
    /// @param _strict Boolean indicating the type of the allocation (true/false for strict/loose).
    function allocate(uint256 _amount, address _recipient, bool _strict) external onlyWhitelist nonReentrant {
        if (_strict && !allowStrict) {
            revert StrictAllocationDisabled();
        }
        _checkNotZeroAddress(_recipient);

        if (_amount > maxWithdraw(msg.sender)) {
            // not strictly necessary but used anyway for non-strict allocations
            revert InsufficientDistributorBalance();
        }

        if (_amount < 1e18) {
            revert AllocationUnderOneMATIC();
        }

        uint256 individualAmount;
        uint256 individualPriceNum;
        uint256 individualPriceDenom;

        uint256 totalAmount;
        uint256 totalNum;
        uint256 totalDenom;
        // variables up here for stack too deep issues

        {
            (uint256 globalPriceNum, uint256 globalPriceDenom) = sharePrice();

            Allocation storage oldIndividualAllocation = allocations[msg.sender][_recipient][_strict];

            if (oldIndividualAllocation.maticAmount == 0) {
                // if this is a new allocation
                individualAmount = _amount;
                individualPriceNum = globalPriceNum;
                individualPriceDenom = globalPriceDenom;

                // update mappings to keep track of recipients for each dist and vice versa
                distributors[_recipient][_strict].push(msg.sender);
                recipients[msg.sender][_strict].push(_recipient);
            } else {
                // performing update allocation

                individualAmount = oldIndividualAllocation.maticAmount + _amount;

                individualPriceNum = oldIndividualAllocation.maticAmount * 1e22 + _amount * 1e22;

                individualPriceDenom =
                    MathUpgradeable.mulDiv(
                        oldIndividualAllocation.maticAmount * 1e22,
                        oldIndividualAllocation.sharePriceDenom,
                        oldIndividualAllocation.sharePriceNum,
                        MathUpgradeable.Rounding.Down
                    ) +
                    MathUpgradeable.mulDiv(
                        _amount * 1e22,
                        globalPriceDenom,
                        globalPriceNum,
                        MathUpgradeable.Rounding.Down
                    );

                // rounding individual allocation share price denominator DOWN, in order to maximise the individual allocation share price
                // which minimises the amount that is distributed in `distributeRewards()`
            }

            allocations[msg.sender][_recipient][_strict] = Allocation(
                individualAmount,
                individualPriceNum,
                individualPriceDenom
            );

            // set or update total allocation value for user

            Allocation storage totalAllocation = totalAllocated[msg.sender][_strict];

            if (totalAllocation.maticAmount == 0) {
                // set total allocated amount + share price

                totalAmount = _amount;
                totalNum = globalPriceNum;
                totalDenom = globalPriceDenom;
            } else {
                // update total allocated amount + share price

                totalAmount = totalAllocation.maticAmount + _amount;

                totalNum = totalAllocation.maticAmount * 1e22 + _amount * 1e22;

                totalDenom =
                    MathUpgradeable.mulDiv(
                        totalAllocation.maticAmount * 1e22,
                        totalAllocation.sharePriceDenom,
                        totalAllocation.sharePriceNum,
                        MathUpgradeable.Rounding.Up
                    ) +
                    MathUpgradeable.mulDiv(
                        _amount * 1e22,
                        globalPriceDenom,
                        globalPriceNum,
                        MathUpgradeable.Rounding.Up
                    );

                // rounding total allocated share price denominator UP, in order to minimise the total allocation share price
                // which maximises the amount owed by the distributor, which they cannot withdraw/transfer (strict allocations)
            }

            totalAllocated[msg.sender][_strict] = Allocation(totalAmount, totalNum, totalDenom);
        }

        emit Allocated(
            msg.sender,
            _recipient,
            individualAmount,
            individualPriceNum,
            individualPriceDenom,
            totalAmount,
            totalNum,
            totalDenom,
            _strict
        );
    }

    /// @notice Deallocates an amount of MATIC previously allocated to a user.
    /// @dev Distributes any outstanding rewards to the recipient before deallocating (strict allocations only).
    /// @param _amount The amount the caller wishes to reduce the target's allocation by.
    /// @param _recipient The address of the user whose allocation is being reduced.
    /// @param _strict Boolean indicating the type of the allocation (true/false for strict/loose).
    function deallocate(uint256 _amount, address _recipient, bool _strict) external onlyWhitelist nonReentrant {
        Allocation storage individualAllocation = allocations[msg.sender][_recipient][_strict];

        uint256 individualSharePriceNum = individualAllocation.sharePriceNum;
        uint256 individualSharePriceDenom = individualAllocation.sharePriceDenom;
        uint256 individualMaticAmount = individualAllocation.maticAmount;

        (uint256 globalPriceNum, uint256 globalPriceDenom) = sharePrice();

        if (individualMaticAmount == 0) {
            revert NoRewardsAllocatedToRecipient();
        }

         if (individualMaticAmount < _amount) {
            revert ExcessDeallocation();
        }
        
        unchecked {
           individualMaticAmount -= _amount;
        }

         if (individualMaticAmount < 1e18 && individualMaticAmount !=0 ) {
            revert AllocationUnderOneMATIC();
        }

        // check if the share price has moved - if yes, distribute first
        if (
            _strict &&
            individualSharePriceNum / individualSharePriceDenom <
            globalPriceNum / globalPriceDenom
        ) {
            _distributeRewardsUpdateTotal(_recipient, msg.sender, _strict);
        }

        // check if this is a complete deallocation
        if (individualMaticAmount == 0) {
            // remove recipient from distributor's recipient array
            delete allocations[msg.sender][_recipient][_strict];

            address[] storage rec = recipients[msg.sender][_strict];
            uint256 rlen = rec.length;

            for (uint256 i; i < rlen; ) {
                if (rec[i] == _recipient) {
                    rec[i] = rec[rlen - 1];
                    rec.pop();
                    break;
                }

                unchecked {
                    ++i;
                }
            }

            // remove distributor from recipient's distributor array

            address[] storage dist = distributors[_recipient][_strict];
            uint256 dlen = dist.length;

            for (uint256 i; i < dlen; ) {
                if (dist[i] == msg.sender) {
                    dist[i] = dist[dlen - 1];
                    dist.pop();
                    break;
                }

                unchecked {
                    ++i;
                }
            }
        }
        else{
            individualAllocation.maticAmount = individualMaticAmount;
            }

        // update total allocation values - rebalance

        uint256 totalAmount;
        uint256 totalPriceNum;
        uint256 totalPriceDenom;

        Allocation storage totalAllocation = totalAllocated[msg.sender][_strict];

        totalAmount = totalAllocation.maticAmount - _amount;

        if (totalAmount == 0) {
            delete totalAllocated[msg.sender][_strict];
        } else {
            if(_strict){
                individualSharePriceNum = globalPriceNum;
                individualSharePriceDenom = globalPriceDenom;
            }

            // in the case of deallocating a strict allocation, rewards will have been distributed
            // at the start of the deallocate function, therefore we must use the old share price
            // in the weighted sum below to update the total allocation share price. This is because
            // the individual share price has already been updated to the global share price.

            totalPriceNum = totalAllocation.maticAmount * 1e22 - _amount * 1e22;

            totalPriceDenom =
                MathUpgradeable.mulDiv(
                    totalAllocation.maticAmount * 1e22,
                    totalAllocation.sharePriceDenom,
                    totalAllocation.sharePriceNum,
                    MathUpgradeable.Rounding.Up
                ) -
                MathUpgradeable.mulDiv(
                    _amount * 1e22,
                    individualSharePriceDenom,
                    individualSharePriceNum,
                    MathUpgradeable.Rounding.Down
                );

            // rounding total allocated share price denominator UP, in order to minimise the total allocation share price
            // which maximises the amount owed by the distributor, which they cannot withdraw/transfer (strict allocations)
            
            totalAllocated[msg.sender][_strict] = Allocation(totalAmount, totalPriceNum, totalPriceDenom);
        }


        emit Deallocated(
            msg.sender,
            _recipient,
            individualMaticAmount,
            totalAmount,
            totalPriceNum,
            totalPriceDenom,
            _strict
        );
    }

    /// @notice Reallocates an amount of the caller's loosely allocated MATIC from one recipient to another.
    /// @param _oldRecipient The previous recipient of the allocation.
    /// @param _newRecipient The new recipient of the allocation.
    function reallocate(address _oldRecipient, address _newRecipient) external onlyWhitelist nonReentrant {
        _checkNotZeroAddress(_newRecipient);

        // Loose allocations only => strictness = false
        Allocation memory oldIndividualAllocation = allocations[msg.sender][_oldRecipient][false];

        // assert they there is an old allocation
        if (oldIndividualAllocation.maticAmount == 0) {
            revert AllocationNonExistent();
        }

        Allocation storage newAllocation = allocations[msg.sender][_newRecipient][false];

        uint256 individualAmount;
        uint256 individualPriceNum;
        uint256 individualPriceDenom;

        // check if new recipient has already been allocated to
        if (newAllocation.maticAmount == 0) {
            // set new one
            individualAmount = oldIndividualAllocation.maticAmount;
            individualPriceNum = oldIndividualAllocation.sharePriceNum;
            individualPriceDenom = oldIndividualAllocation.sharePriceDenom;

            // pop old one from recipients array, set it equal to new address
            address[] storage rec = recipients[msg.sender][false];
            uint256 rlen = rec.length;

            for (uint256 i; i < rlen; ) {
                if (rec[i] == _oldRecipient) {
                    rec[i] = _newRecipient;
                    break;
                }

                unchecked {
                    ++i;
                }
            }

            // to newRecipient's distributors array: add distributor
            distributors[_newRecipient][false].push(msg.sender);
        } else {
            // update existing recipient allocation with weighted sum

            individualAmount = oldIndividualAllocation.maticAmount + newAllocation.maticAmount;

            individualPriceNum = oldIndividualAllocation.maticAmount * 1e22 + newAllocation.maticAmount * 1e22;

            individualPriceDenom =
                MathUpgradeable.mulDiv(
                    oldIndividualAllocation.maticAmount * 1e22,
                    oldIndividualAllocation.sharePriceDenom,
                    oldIndividualAllocation.sharePriceNum,
                    MathUpgradeable.Rounding.Down
                ) +
                MathUpgradeable.mulDiv(
                    newAllocation.maticAmount * 1e22,
                    newAllocation.sharePriceDenom,
                    newAllocation.sharePriceNum,
                    MathUpgradeable.Rounding.Down
                );

            // rounding individual allocation share price denominator DOWN, in order to maximise the individual allocation share price
            // which minimises the amount that is distributed in `distributeRewards()`

            // pop old one from recipients array
            address[] storage rec = recipients[msg.sender][false];
            uint256 rlen = rec.length;

            for (uint256 i; i < rlen; ) {
                if (rec[i] == _oldRecipient) {
                    rec[i] = rec[rlen - 1];
                    rec.pop();
                    break;
                }

                unchecked {
                    ++i;
                }
            }
        }
        // delete old one
        delete allocations[msg.sender][_oldRecipient][false];
        // set the new allocation amount
        allocations[msg.sender][_newRecipient][false] = Allocation(
            individualAmount,
            individualPriceNum,
            individualPriceDenom
        );

        // from oldRecipient's distributors array: pop distributor
        address[] storage dist = distributors[_oldRecipient][false];
        uint256 dlen = dist.length;

        for (uint256 i; i < dlen; ) {
            if (dist[i] == msg.sender) {
                dist[i] = dist[dlen - 1];
                dist.pop();
                break;
            }

            unchecked {
                ++i;
            }
        }

        emit Reallocated(
            msg.sender,
            _oldRecipient,
            _newRecipient,
            individualAmount,
            individualPriceNum,
            individualPriceDenom
        );
    }

    /// @notice Distributes allocation rewards from a distributor to a recipient.
    /// @dev Caller must be a distributor of the recipient in the case of loose allocations.
    /// @param _recipient Address of allocation's recipient.
    /// @param _distributor Address of allocation's distributor.
    /// @param _strict Boolean indicating the type of the allocation (true/false for strict/loose).
    function distributeRewards(address _recipient, address _distributor, bool _strict) public nonReentrant {
        if (!_strict && msg.sender != _distributor) {
            revert OnlyDistributorCanDistributeRewards();
        }
        _distributeRewardsUpdateTotal(_recipient, _distributor, _strict);
    }

    /// @notice Distributes the rewards from a specific allocator's allocations to all their recipients.
    /// @dev Caller must be a distributor of the recipient in the case of loose allocations.
    /// @param _distributor Address of distributor whose allocations are to have their rewards distributed.
    /// @param _strict Boolean indicating the type of the allocation (true/false for strict/loose).
    function distributeAll(address _distributor, bool _strict) external nonReentrant {
        if (!_strict && msg.sender != _distributor) {
            revert OnlyDistributorCanDistributeRewards();
        }

        address[] storage rec = recipients[_distributor][_strict];
        uint256 len = rec.length;

        (uint256 globalPriceNum, uint256 globalPriceDenom) = sharePrice();

        for (uint256 i; i < len; ) {
            Allocation storage individualAllocation = allocations[_distributor][rec[i]][_strict];

            if (
                individualAllocation.sharePriceNum / individualAllocation.sharePriceDenom <
                globalPriceNum / globalPriceDenom
            ) {
                _distributeRewards(rec[i], _distributor, _strict, false);
            }
            unchecked {
                ++i;
            }
        }

        // reset total allocation

        Allocation storage totalAllocation = totalAllocated[msg.sender][_strict];
        totalAllocation.sharePriceNum = globalPriceNum;
        totalAllocation.sharePriceDenom = globalPriceDenom;

        emit DistributedAll(_distributor, globalPriceNum, globalPriceDenom, _strict);
    }

    // *** VAULT OWNER ADMIN SETTERS ***

    function setValidatorShareContract(address _validatorShareContractAddress) external onlyOwner {
        _checkNotZeroAddress(_validatorShareContractAddress);
        emit SetValidatorShareContract(validatorShareContractAddress, _validatorShareContractAddress);
        validatorShareContractAddress = _validatorShareContractAddress;
    }

    function setWhitelist(address _whitelistAddress) external onlyOwner {
        _checkNotZeroAddress(_whitelistAddress);
        emit SetWhitelist(whitelistAddress, _whitelistAddress);
        whitelistAddress = _whitelistAddress;
    }

    function setTreasury(address _treasuryAddress) external onlyOwner {
        _checkNotZeroAddress(_treasuryAddress);
        emit SetTreasury(treasuryAddress, _treasuryAddress);
        treasuryAddress = _treasuryAddress;
    }

    function setCap(uint256 _cap) external onlyOwner {
        if (_cap < totalStaked()) {
            revert CapTooLow();
        }
        //check for cap too high as well/instead?
        emit SetCap(cap, _cap);
        cap = _cap;
    }

    /// @dev phi validated: phi must be less than or equal to precision
    function setPhi(uint256 _phi) external onlyOwner {
        if (_phi > PHI_PRECISION) {
            revert PhiTooLarge();
        }
        emit SetPhi(phi, _phi);
        phi = _phi;
    }

    function setDistPhi(uint256 _distPhi) external onlyOwner {
        if (_distPhi > PHI_PRECISION) {
            revert DistPhiTooLarge();
        }
        emit SetDistPhi(distPhi, _distPhi);
        distPhi = _distPhi;
    }

    function setEpsilon(uint256 _epsilon) external onlyOwner {
        if (_epsilon > 1e12) {
            revert EpsilonTooLarge();
        }
        emit SetEpsilon(epsilon, _epsilon);
        epsilon = _epsilon;
    }

    function setAllowStrict(bool _allowStrict) external onlyOwner {
        emit SetAllowStrict(allowStrict, _allowStrict);
        allowStrict = _allowStrict;
    }

    /// *** INTERNAL METHODS ***

    function _deposit(address _user, uint256 _amount) private {
        if (_amount < 1e18 && _amount > 0) {
            revert DepositUnderOneMATIC();
        }

        if (_amount > maxDeposit(_user)) {
            revert DepositSurpassesVaultCap();
        }

        (uint256 globalPriceNum, uint256 globalPriceDenom) = sharePrice();

        // calculate share increase
        uint256 shareIncreaseUser = convertToShares(_amount);
        uint256 shareIncreaseTsy = (totalRewards() * phi * 1e18 * globalPriceDenom) / (globalPriceNum * PHI_PRECISION);

        // piggyback previous withdrawn rewards in this staking call
        uint256 stakeAmount = _amount + totalAssets();
        // adjust share balances
        if (_user != address(0)) {
            _mint(_user, shareIncreaseUser);
            emit Deposit(_user, _user, _amount, shareIncreaseUser);
            // erc-4626 event needed for integration
        }

        _mint(treasuryAddress, shareIncreaseTsy);
        emit Deposit(_user, treasuryAddress, 0, shareIncreaseTsy);
        // erc-4626 event needed for integration

        // transfer staking token from user to Staker
        IERC20Upgradeable(stakingTokenAddress).safeTransferFrom(_user, address(this), _amount);

        // approve funds to Stake Manager
        IERC20Upgradeable(stakingTokenAddress).safeIncreaseAllowance(stakeManagerContractAddress, stakeAmount);

        // interact with Validator Share contract to stake
        _stake(stakeAmount);
        // claimed rewards increase here as liquid rewards on validator share contract
        // are set to zero rewards and transferred to this vault

        emit Deposited(_user, shareIncreaseTsy, shareIncreaseUser, _amount, stakeAmount, totalAssets());
    }

    function _withdrawRequest(address _user, uint256 _amount) private {
        if (_amount == 0) {
            revert WithdrawalRequestAmountCannotEqualZero();
        }

        uint256 maxWithdrawal = maxWithdraw(_user);
        if (_amount > maxWithdrawal) {
            revert WithdrawalAmountTooLarge();
        }

        (uint256 globalPriceNum, uint256 globalPriceDenom) = sharePrice();

        // calculate share decrease

        uint256 shareDecreaseUser = (_amount * globalPriceDenom * 1e18) / globalPriceNum;

        uint256 shareIncreaseTsy = (totalRewards() * phi * globalPriceDenom * 1e18) / (globalPriceNum * PHI_PRECISION);

        // If remaining user balance is below 1 MATIC, entire balance is withdrawn and all shares 
        // are burnt. We allow the user to withdraw their deposited amount + epsilon
        uint256 remainingBalance = maxWithdrawal - _amount; 
        if (remainingBalance < 1e18){
            _amount = maxWithdrawal;
            shareDecreaseUser = balanceOf(_user);
        }

        _burn(_user, shareDecreaseUser);
        emit Withdraw(_user, _user, _user, _amount, shareDecreaseUser); // erc-4626 event needed for integration

        _mint(treasuryAddress, shareIncreaseTsy);
        emit Deposit(_user, treasuryAddress, 0, shareIncreaseTsy); // erc-4626 event needed for integration

        // interact with staking contract to initiate unbonding
        uint256 unbondNonce = _unbond(_amount);

        // store user under unbond nonce, used for fair claiming
        unbondingWithdrawals[unbondNonce] = Withdrawal(_user, _amount);

        // only once 80 epochs have passed can this be claimed
        uint256 epoch = getCurrentEpoch();

        emit WithdrawalRequested(
            _user,
            shareIncreaseTsy,
            shareDecreaseUser,
            _amount,
            totalAssets(),
            unbondNonce,
            epoch
        );
    }

    function _withdrawClaim(uint256 _unbondNonce) private {
        Withdrawal storage withdrawal = unbondingWithdrawals[_unbondNonce];

        if (withdrawal.user != msg.sender) {
            revert SenderMustHaveInitiatedWithdrawalRequest();
        }

        // claim will revert if unbonding not finished for this unbond nonce
        _claimStake(_unbondNonce);

        // transfer claimed matic to claimer
        IERC20Upgradeable(stakingTokenAddress).safeTransfer(msg.sender, withdrawal.amount);

        emit WithdrawalClaimed(msg.sender, _unbondNonce, withdrawal.amount);

        delete unbondingWithdrawals[_unbondNonce];
    }

    function _stake(uint256 _amount) private {
        IValidatorShare(validatorShareContractAddress).buyVoucher(_amount, _amount);
    }

    function _unbond(uint256 _amount) private returns (uint256 unbondNonce) {
        IValidatorShare(validatorShareContractAddress).sellVoucher_new(_amount, _amount);

        return IValidatorShare(validatorShareContractAddress).unbondNonces(address(this));
    }

    function _claimStake(uint256 _unbondNonce) private {
        IValidatorShare(validatorShareContractAddress).unstakeClaimTokens_new(_unbondNonce);
    }

    function _restake() private {
        IValidatorShare(validatorShareContractAddress).restake();
    }

    function _distributeRewardsUpdateTotal(address _recipient, address _distributor, bool _strict) private {
        Allocation storage individualAllocation = allocations[_distributor][_recipient][_strict];

        if (individualAllocation.maticAmount == 0) {
            revert NothingToDistribute();
        }
        Allocation storage totalAllocation = totalAllocated[_distributor][_strict];
        // moved up for stack too deep issues
        (uint256 globalPriceNum, uint256 globalPriceDenom) = sharePrice();

        uint256 amountDistributed;
        uint256 sharesDistributed;

        {
            // check necessary to avoid div by zero error
            if (
                individualAllocation.sharePriceNum / individualAllocation.sharePriceDenom ==
                globalPriceNum / globalPriceDenom
            ) {
                return;
            }
            uint256 oldIndividualSharePriceNum;
            uint256 oldIndividualSharePriceDenom;

            // dist rewards private fn, which does not update total allocated
            (oldIndividualSharePriceNum, oldIndividualSharePriceDenom, sharesDistributed) = _distributeRewards(
                _recipient,
                _distributor,
                _strict,
                true
            );

            amountDistributed = convertToAssets(sharesDistributed);

            // note: this amount was rounded, but it's only being used as a parameter in the emitted event,
            // should be cautious when using rounded values in calculations

            // update total allocated

            totalAllocation.sharePriceDenom =
                totalAllocation.sharePriceDenom +
                MathUpgradeable.mulDiv(
                    individualAllocation.maticAmount * 1e22,
                    globalPriceDenom * totalAllocation.sharePriceNum,
                    totalAllocation.maticAmount * globalPriceNum,
                    MathUpgradeable.Rounding.Up
                ) /
                1e22 -
                MathUpgradeable.mulDiv(
                    individualAllocation.maticAmount * 1e22,
                    oldIndividualSharePriceDenom * totalAllocation.sharePriceNum,
                    totalAllocation.maticAmount * oldIndividualSharePriceNum,
                    MathUpgradeable.Rounding.Down
                ) /
                1e22;

            // totalAllocation.sharePriceNum unchanged

            // rounding total allocated share price denominator UP, in order to minimise the total allocation share price
            // which maximises the amount owed by the distributor, which they cannot withdraw/transfer (strict allocations)
        }

        emit DistributedRewards(
            _distributor,
            _recipient,
            amountDistributed,
            sharesDistributed,
            globalPriceNum,
            globalPriceDenom,
            totalAllocation.sharePriceNum,
            totalAllocation.sharePriceDenom,
            _strict
        );
    }

    function _distributeRewards(
        address _recipient,
        address _distributor,
        bool _strict,
        bool _individual
    ) private returns (uint256, uint256, uint256) {
        Allocation storage individualAllocation = allocations[_distributor][_recipient][_strict];
        uint256 amt = individualAllocation.maticAmount;

        uint256 oldNum = individualAllocation.sharePriceNum;
        uint256 oldDenom = individualAllocation.sharePriceDenom;

        (uint256 globalPriceNum, uint256 globalPriceDenom) = sharePrice();

        // calculate amount of TruMatic to move from distributor to recipient

        uint256 sharesToMove;

        {
            uint256 totalShares = MathUpgradeable.mulDiv(amt, oldDenom * 1e18, oldNum, MathUpgradeable.Rounding.Down) -
                MathUpgradeable.mulDiv(amt, globalPriceDenom * 1e18, globalPriceNum, MathUpgradeable.Rounding.Up);

            if (!_strict) {
                // calc fees and transfer

                uint256 fee = (totalShares * distPhi) / PHI_PRECISION;

                sharesToMove = totalShares - fee;

                // Use parent _transfer function to bypass strict allocation share lock
                super._transfer(_distributor, treasuryAddress, fee);
            } else {
                sharesToMove = totalShares;
            }
        }

        // Use parent _transfer function to bypass strict allocation share lock
        super._transfer(_distributor, _recipient, sharesToMove);

        individualAllocation.sharePriceNum = globalPriceNum;
        individualAllocation.sharePriceDenom = globalPriceDenom;

        if (!_individual) {
            emit DistributedRewards(
                _distributor,
                _recipient,
                convertToAssets(sharesToMove),
                sharesToMove,
                globalPriceNum,
                globalPriceDenom,
                0,
                0,
                _strict
            );
        }

        return (oldNum, oldDenom, sharesToMove);
    }

    function _checkNotZeroAddress(address toCheck) private pure {
        assembly {
            //more gas efficient to use assembly for zero address check
            if iszero(toCheck) {
                let ptr := mload(0x40)
                mstore(ptr, 0x1cb411bc00000000000000000000000000000000000000000000000000000000) // selector for `ZeroAddressNotSupported()`
                revert(ptr, 0x4)
            }
        }
    }

    function _convertToShares(
        uint256 assets,
        MathUpgradeable.Rounding rounding
    ) internal view override returns (uint256 shares) {
        (uint256 globalPriceNum, uint256 globalPriceDenom) = sharePrice();
        return MathUpgradeable.mulDiv(assets * 1e18, globalPriceDenom, globalPriceNum, rounding);
    }

    function _convertToAssets(
        uint256 shares,
        MathUpgradeable.Rounding rounding
    ) internal view override returns (uint256) {
        (uint256 globalPriceNum, uint256 globalPriceDenom) = sharePrice();
        return MathUpgradeable.mulDiv(shares, globalPriceNum, globalPriceDenom * 1e18, rounding);
    }

    // We override this function as we want to block users from transferring strict allocations and associated rewards.
    // We avoid using the _beforeTokenTransfer hook as we wish to utilise unblocked super._transfer functionality in reward distribution.
    function _transfer(address from, address to, uint256 amount) internal override {
        if (from != address(0) && amount > maxRedeem(from)) {
            revert ExceedsUnallocatedBalance();
        }

        super._transfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";
import "../token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626Upgradeable is IERC20Upgradeable, IERC20MetadataUpgradeable {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/ERC4626.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../utils/SafeERC20Upgradeable.sol";
import "../../../interfaces/IERC4626Upgradeable.sol";
import "../../../utils/math/MathUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the ERC4626 "Tokenized Vault Standard" as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[EIP-4626].
 *
 * This extension allows the minting and burning of "shares" (represented using the ERC20 inheritance) in exchange for
 * underlying "assets" through standardized {deposit}, {mint}, {redeem} and {burn} workflows. This contract extends
 * the ERC20 standard. Any additional extensions included along it would affect the "shares" token represented by this
 * contract and not the "assets" token which is an independent contract.
 *
 * [CAUTION]
 * ====
 * In empty (or nearly empty) ERC-4626 vaults, deposits are at high risk of being stolen through frontrunning
 * with a "donation" to the vault that inflates the price of a share. This is variously known as a donation or inflation
 * attack and is essentially a problem of slippage. Vault deployers can protect against this attack by making an initial
 * deposit of a non-trivial amount of the asset, such that price manipulation becomes infeasible. Withdrawals may
 * similarly be affected by slippage. Users can protect against this attack as well as unexpected slippage in general by
 * verifying the amount received is as expected, using a wrapper that performs these checks such as
 * https://github.com/fei-protocol/ERC4626#erc4626router-and-base[ERC4626Router].
 *
 * Since v4.9, this implementation uses virtual assets and shares to mitigate that risk. The `_decimalsOffset()`
 * corresponds to an offset in the decimal representation between the underlying asset's decimals and the vault
 * decimals. This offset also determines the rate of virtual shares to virtual assets in the vault, which itself
 * determines the initial exchange rate. While not fully preventing the attack, analysis shows that the default offset
 * (0) makes it non-profitable, as a result of the value being captured by the virtual shares (out of the attacker's
 * donation) matching the attacker's expected gains. With a larger offset, the attack becomes orders of magnitude more
 * expensive than it is profitable. More details about the underlying math can be found
 * xref:erc4626.adoc#inflation-attack[here].
 *
 * The drawback of this approach is that the virtual shares do capture (a very small) part of the value being accrued
 * to the vault. Also, if the vault experiences losses, the users try to exit the vault, the virtual shares and assets
 * will cause the first user to exit to experience reduced losses in detriment to the last users that will experience
 * bigger losses. Developers willing to revert back to the pre-v4.9 behavior just need to override the
 * `_convertToShares` and `_convertToAssets` functions.
 *
 * To learn more, check out our xref:ROOT:erc4626.adoc[ERC-4626 guide].
 * ====
 *
 * _Available since v4.7._
 */
abstract contract ERC4626Upgradeable is Initializable, ERC20Upgradeable, IERC4626Upgradeable {
    using MathUpgradeable for uint256;

    IERC20Upgradeable private _asset;
    uint8 private _underlyingDecimals;

    /**
     * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
     */
    function __ERC4626_init(IERC20Upgradeable asset_) internal onlyInitializing {
        __ERC4626_init_unchained(asset_);
    }

    function __ERC4626_init_unchained(IERC20Upgradeable asset_) internal onlyInitializing {
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(asset_);
        _underlyingDecimals = success ? assetDecimals : 18;
        _asset = asset_;
    }

    /**
     * @dev Attempts to fetch the asset decimals. A return value of false indicates that the attempt failed in some way.
     */
    function _tryGetAssetDecimals(IERC20Upgradeable asset_) private view returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_).staticcall(
            abi.encodeWithSelector(IERC20MetadataUpgradeable.decimals.selector)
        );
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    /**
     * @dev Decimals are computed by adding the decimal offset on top of the underlying asset's decimals. This
     * "original" value is cached during construction of the vault contract. If this read operation fails (e.g., the
     * asset has not been created yet), a default of 18 is used to represent the underlying asset's decimals.
     *
     * See {IERC20Metadata-decimals}.
     */
    function decimals() public view virtual override(IERC20MetadataUpgradeable, ERC20Upgradeable) returns (uint8) {
        return _underlyingDecimals + _decimalsOffset();
    }

    /** @dev See {IERC4626-asset}. */
    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view virtual override returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /** @dev See {IERC4626-convertToShares}. */
    function convertToShares(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Down);
    }

    /** @dev See {IERC4626-convertToAssets}. */
    function convertToAssets(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Down);
    }

    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxWithdraw}. */
    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        return _convertToAssets(balanceOf(owner), MathUpgradeable.Rounding.Down);
    }

    /** @dev See {IERC4626-maxRedeem}. */
    function maxRedeem(address owner) public view virtual override returns (uint256) {
        return balanceOf(owner);
    }

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Down);
    }

    /** @dev See {IERC4626-previewMint}. */
    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Up);
    }

    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Up);
    }

    /** @dev See {IERC4626-previewRedeem}. */
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Down);
    }

    /** @dev See {IERC4626-deposit}. */
    function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-mint}.
     *
     * As opposed to {deposit}, minting is allowed even if the vault is in a state where the price of a share is zero.
     * In this case, the shares will be minted without requiring any assets to be deposited.
     */
    function mint(uint256 shares, address receiver) public virtual override returns (uint256) {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(uint256 assets, address receiver, address owner) public virtual override returns (uint256) {
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(uint256 shares, address receiver, address owner) public virtual override returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     */
    function _convertToShares(uint256 assets, MathUpgradeable.Rounding rounding) internal view virtual returns (uint256) {
        return assets.mulDiv(totalSupply() + 10 ** _decimalsOffset(), totalAssets() + 1, rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 shares, MathUpgradeable.Rounding rounding) internal view virtual returns (uint256) {
        return shares.mulDiv(totalAssets() + 1, totalSupply() + 10 ** _decimalsOffset(), rounding);
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal virtual {
        // If _asset is ERC777, `transferFrom` can trigger a reentrancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20Upgradeable.safeTransferFrom(_asset, caller, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(owner, shares);
        SafeERC20Upgradeable.safeTransfer(_asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function _decimalsOffset() internal view virtual returns (uint8) {
        return 0;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/IERC20PermitUpgradeable.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20Upgradeable token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && AddressUpgradeable.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.19;

/**
 * @title Master Whitelist Interface
 * @notice Interface for contract that manages the whitelists for: Lawyers, Market Makers, Users, Vaults, and Assets
 */
interface IMasterWhitelist {
    /**
     * @notice Checks if a Market Maker is in the Whitelist
     * @param _mm is the Market Maker address
     */
    function isMMWhitelisted(address _mm) external view returns (bool);

    /**
     * @notice Checks if a Vault is in the Whitelist
     * @param _vault is the Vault address
     */
    function isVaultWhitelisted(address _vault) external view returns (bool);

    /**
     * @notice Checks if a User is in the Whitelist
     * @param _user is the User address
     */
    function isUserWhitelisted(address _user) external view returns (bool);

    /**
     * @notice Checks if a User is in the Blacklist
     * @param _user is the User address
     */
    function isUserBlacklisted(address _user) external view returns (bool);

    /**
     * @notice Checks if a Swap Manager is in the Whitelist
     * @param _sm is the Swap Manager address
     */
    function isSwapManagerWhitelisted(address _sm) external view returns (bool);

    /**
     * @notice Checks if an Asset is in the Whitelist
     * @param _asset is the Asset address
     */
    function isAssetWhitelisted(address _asset) external view returns (bool);

    /**
     * @notice Returns id of a market maker address
     * @param _mm is the market maker address
     */
    function getIdMM(address _mm) external view returns (bytes32);

    function isLawyer(address _lawyer) external view returns (bool);

    /**
     * @notice Checks if a user is whitelisted for the Gnosis auction, returns "0x19a05a7e" if it is
     * @param _user is the User address
     * @param _auctionId is not needed for now
     * @param _callData is not needed for now
     */
    function isAllowed(
        address _user,
        uint256 _auctionId,
        bytes calldata _callData
    ) external view returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.19;

interface IStakeManager {
    // validator replacement
    function startAuction(
        uint256 validatorId,
        uint256 amount,
        bool acceptDelegation,
        bytes calldata signerPubkey
    ) external;

    function confirmAuctionBid(uint256 validatorId, uint256 heimdallFee) external;

    function transferFunds(
        uint256 validatorId,
        uint256 amount,
        address delegator
    ) external returns (bool);

    function delegationDeposit(
        uint256 validatorId,
        uint256 amount,
        address delegator
    ) external returns (bool);

    function unstake(uint256 validatorId) external;

    function totalStakedFor(address addr) external view returns (uint256);

    function stakeFor(
        address user,
        uint256 amount,
        uint256 heimdallFee,
        bool acceptDelegation,
        bytes memory signerPubkey
    ) external;

    function checkSignatures(
        uint256 blockInterval,
        bytes32 voteHash,
        bytes32 stateRoot,
        address proposer,
        uint[3][] calldata sigs
    ) external returns (uint256);

    function updateValidatorState(uint256 validatorId, int256 amount) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function slash(bytes calldata slashingInfoList) external returns (uint256);

    function validatorStake(uint256 validatorId) external view returns (uint256);

    function epoch() external view returns (uint256);

    function getRegistry() external view returns (address);

    function withdrawalDelay() external view returns (uint256);

    function delegatedAmount(uint256 validatorId) external view returns(uint256);

    function decreaseValidatorDelegatedAmount(uint256 validatorId, uint256 amount) external;

    function withdrawDelegatorsReward(uint256 validatorId) external returns(uint256);

    function delegatorsReward(uint256 validatorId) external view returns(uint256);

    function dethroneAndStake(
        address auctionUser,
        uint256 heimdallFee,
        uint256 validatorId,
        uint256 auctionAmount,
        bool acceptDelegation,
        bytes calldata signerPubkey
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.19;

interface ITruStakeMATICv2 {
    // --- Events ---

    /// @notice emitted on initialize
    /// @dev params same as initialize function
    event StakerInitialized(
        address _stakingTokenAddress,
        address _stakeManagerContractAddress,
        address _validatorShareContractAddress,
        address _whitelistAddress,
        address _treasuryAddress,
        uint256 _phi,
        uint256 _cap,
        uint256 _distPhi
    );

    // user tracking

    /// @notice emitted on user deposit
    /// @param _user user which made the deposit tx
    /// @param _treasuryShares newly minted shares added to the treasury user's balance
    /// @param _userShares newly minted shares added to the depositing user's balance
    /// @param _amount amount of MATIC transferred by user into the staker
    /// @param _stakedAmount _amount + any auto-claimed MATIC rewards sitting in the
    ///   staker from previous deposits or withdrawal requests made by any user
    /// @param _totalAssets auto-claimed MATIC rewards that will sit in the staker
    ///   until the next deposit made by any user
    event Deposited(
        address indexed _user,
        uint256 _treasuryShares,
        uint256 _userShares,
        uint256 _amount,
        uint256 _stakedAmount,
        uint256 _totalAssets
    );

    /// @notice emitted on user requesting a withdrawal
    /// @param _user user which made the withdraw request tx
    /// @param _treasuryShares newly minted shares added to the treasury user's balance
    ///   (fees taken: shares are newly minted as a result of the auto-claimed MATIC rewards)
    /// @param _userShares burnt shares removed from the depositing user's balance
    /// @param _amount amount of MATIC unbonding, which will be claimable by user in
    ///   80 checkpoints
    /// @param _totalAssets auto-claimed MATIC rewards that will sit in the staker
    ///   until the next deposit made by any user
    /// @param _unbondNonce nonce of this unbond, which will be passed into the function
    ///   `withdrawClaim(uint256 _unbondNonce)` in 80 checkpoints in order to claim this
    ///   the amount from this request
    /// @param _epoch the current checkpoint the stake manager is at, used to track how
    ///   how far from claiming the request is
    event WithdrawalRequested(
        address indexed _user,
        uint256 _treasuryShares,
        uint256 _userShares,
        uint256 _amount,
        uint256 _totalAssets,
        uint256 indexed _unbondNonce,
        uint256 indexed _epoch
    );

    /// @notice emitted on user claiming a withdrawal
    /// @param _user user which made the withdraw claim tx
    /// @param _unbondNonce nonce of the original withdrawal request, which was passed
    ///   into the `withdrawClaim` function
    /// @param _amount amount of MATIC claimed from staker (originally from stake manager)
    event WithdrawalClaimed(address indexed _user, uint256 indexed _unbondNonce, uint256 _amount);

    // global tracking

    /// @notice emitted on rewards compound call
    /// @param _amount amount of MATIC moved from rewards on the validator to staked funds
    /// @param _shares newly minted shares added to the treasury user's balance (fees taken)
    event RewardsCompounded(uint256 _amount, uint256 _shares);

    // allocations

    /// @notice emitted on allocation
    /// @param _distributor address of user who has allocated to someone else
    /// @param _recipient address of user to whom something was allocated
    /// @param _individualAmount total amount allocated to recipient by this distributor
    /// @param _individualNum average share price numerator at which allocations occurred
    /// @param _individualDenom average share price denominator at which allocations occurred
    /// @param _totalAmount total amount distributor has allocated
    /// @param _totalNum average share price numerator at which distributor allocated
    /// @param _totalDenom average share price denominator at which distributor allocated
    /// @param _strict bool to determine whether deallocation of funds allocated here should
    ///   be subject to checks or not
    event Allocated(
        address indexed _distributor,
        address indexed _recipient,
        uint256 _individualAmount,
        uint256 _individualNum,
        uint256 _individualDenom,
        uint256 _totalAmount,
        uint256 _totalNum,
        uint256 _totalDenom,
        bool indexed _strict
    );

    /// @notice emitted on deallocations
    /// @param _distributor address of user who has allocated to someone else
    /// @param _recipient address of user to whom something was allocated
    /// @param _individualAmount remaining amount allocated to recipient
    /// @param _totalAmount total amount distributor has allocated
    /// @param _totalNum average share price numerator at which distributor allocated
    /// @param _totalDenom average share price denominator at which distributor allocated
    /// @param _strict bool to determine whether the deallocation of these funds was
    ///   subject to strictness checks or not
    event Deallocated(
        address indexed _distributor,
        address indexed _recipient,
        uint256 _individualAmount,
        uint256 _totalAmount,
        uint256 _totalNum,
        uint256 _totalDenom,
        bool indexed _strict
    );

    /// @notice emitted on reallocations
    /// @param _distributor address of user who is switching allocation recipient
    /// @param _oldRecipient previous recipient of allocated rewards
    /// @param _newRecipient new recipient of allocated rewards
    /// @param _newAmount matic amount stored in allocation of the new recipient
    /// @param _newNum numerator of share price stored in allocation of the new recipient
    /// @param _newDenom denominator of share price stored in allocation of the new recipient
    event Reallocated(
        address indexed _distributor,
        address indexed _oldRecipient,
        address indexed _newRecipient,
        uint256 _newAmount,
        uint256 _newNum,
        uint256 _newDenom
    );

    /// @notice emitted when rewards are distributed
    /// @param _distributor address of user who has allocated to someone else
    /// @param _recipient address of user to whom something was allocated
    /// @param _amount amount of matic being distributed
    /// @param _shares amount of shares being distributed
    /// @param _individualNum average share price numerator at which distributor allocated
    /// @param _individualDenom average share price numerator at which distributor allocated
    /// @param _totalNum average share price numerator at which distributor allocated
    /// @param _totalDenom average share price denominator at which distributor allocated
    /// @param _strict bool to determine whether these funds came from the strict or
    ///   non-strict allocation mappings
    event DistributedRewards(
        address indexed _distributor,
        address indexed _recipient,
        uint256 _amount,
        uint256 _shares,
        uint256 _individualNum,
        uint256 _individualDenom,
        uint256 _totalNum,
        uint256 _totalDenom,
        bool indexed _strict
    );

    /// @notice emitted when rewards are distributed
    /// @param _distributor address of user who has allocated to someone else
    /// @param _curNum current share price numerator
    /// @param _curDenom current share price denominator
    /// @param _strict bool to determine whether these funds came from the strict or
    ///   non-strict allocation mappings
    event DistributedAll(address indexed _distributor, uint256 _curNum, uint256 _curDenom, bool indexed _strict);

    // setter tracking

    event SetValidatorShareContract(address _oldValidatorShareContract, address _newValidatorShareContract);

    event SetWhitelist(address _oldWhitelistAddress, address _newWhitelistAddress);

    event SetTreasury(address _oldTreasuryAddress, address _newTreasuryAddress);

    event SetCap(uint256 _oldCap, uint256 _newCap);

    event SetPhi(uint256 _oldPhi, uint256 _newPhi);

    event SetDistPhi(uint256 _oldDistPhi, uint256 _newDistPhi);

    event SetEpsilon(uint256 _oldEpsilon, uint256 _newEpsilon);

    event SetAllowStrict(bool _oldAllowStrict, bool _newAllowStrict);

    // --- Errors ---

    /// @notice error thrown when the phi value is larger than the phi precision constant
    error PhiTooLarge();

    /// @notice error thrown when a user tries to interact with a whitelisted-only function
    error UserNotWhitelisted();

    /// @notice error thrown when a user tries to deposit under 1 MATIC
    error DepositUnderOneMATIC();

    /// @notice error thrown when a deposit causes the vault staked amount to surpass the cap
    error DepositSurpassesVaultCap();

    /// @notice error thrown when a user tries to request a withdrawal with an amount larger
    ///   than their shares entitle them to
    error WithdrawalAmountTooLarge();

    /// @notice error thrown when a user tries to request a withdrawal of amount zero
    error WithdrawalRequestAmountCannotEqualZero();

    /// @notice error thrown when a user tries to claim a withdrawal they did not request
    error SenderMustHaveInitiatedWithdrawalRequest();

    /// @notice error used in ERC-4626 integration, thrown when user tries to act on
    ///   behalf of different user
    error SenderAndOwnerMustBeReceiver();

    /// @notice error used in ERC-4626 integration, thrown when user tries to transfer
    ///   or approve to zero address
    error ZeroAddressNotSupported();

    /// @notice error thrown when user allocates more MATIC than available
    error InsufficientDistributorBalance();

    /// @notice error thrown when user calls distributeRewards for
    ///   recipient with nothing allocated to them
    error NoRewardsAllocatedToRecipient();

    /// @notice error thrown when user calls distributeRewards when the allocation
    ///   share price is the same as the current share price
    error NothingToDistribute();

    /// @notice error thrown when a user tries to a distribute rewards allocated by
    ///   a different user
    error OnlyDistributorCanDistributeRewards();

    /// @notice error thrown when a user tries to transfer more share than their
    ///   balance subtracted by the total amount they have strictly allocated
    error ExceedsUnallocatedBalance();

    /// @notice error thrown when a user attempts to allocate less than one MATIC
    error AllocationUnderOneMATIC();

    /// @notice error thrown when a user tries to reallocate from a user they do
    ///   not currently have anything allocated to
    error AllocationNonExistent();

    /// @notice error thrown when a user tries to strictly allocate but `allowStrict`
    ///   has been set to false
    error StrictAllocationDisabled();

    /// @notice error thrown when the distribution fee is higher than the fee precision
    error DistPhiTooLarge();

    /// @notice error thrown when new cap is less than current amount staked
    error CapTooLow();

    ///@notice error thrown when epsilon is set too high
    error EpsilonTooLarge();

    /// @notice error thrown when deallocation is greater than allocated amount
    error ExcessDeallocation();
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.19;

interface IValidatorShare {
    function buyVoucher(uint256 _amount, uint256 _minSharesToMint) external returns (uint256 amountToDeposit);
    
    function sellVoucher_new(uint256 claimAmount, uint256 maximumSharesToBurn) external;

    function unstakeClaimTokens_new(uint256 unbondNonce) external;
    // https://goerli.etherscan.io/tx/0xa92befb3c1bca72e9492eb846c58168fc6511ad580a2703e8abf94e0c3682e26
    // https://goerli.etherscan.io/tx/0x452d26ed9d0fa2e634d26302fab71d0f00401690c79ca8c0c998fdefd2fdb9e8

    function getLiquidRewards(address user) external view returns (uint256);
    
    function restake() external returns (uint256 amountRestaked, uint256 liquidReward);

    function unbondNonces(address) external view returns (uint256); // automatically generated getter of a public mapping

    function balanceOf(address) external view returns (uint256);

    function approve(address, uint256) external;

    function transfer(address, uint256) external;
    
    function transferFrom(address, address, uint256) external;

    function unbonds_new(address, uint256) external view returns (uint256, uint256);

    function exchangeRate() external view returns (uint256);

    function getTotalStake(address) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.19;

import "./Types.sol";

/// @title TruStakeMATICStorage
/// @author Pietro Demicheli (Field Labs)
abstract contract TruStakeMATICv2Storage {
    // Staker constants

    /// @notice address of MATIC on this chain (Ethereum and Goerli supported)
    address public stakingTokenAddress;

    /// @notice the stake manager contract deployed by Polygon
    address public stakeManagerContractAddress;

    /// @notice the validator share contract deployed by a validator
    address public validatorShareContractAddress;

    /// @notice the whitelist contract keeps track of what users can interact with
    ///   certain function in the TruStakeMATIC contract
    address public whitelistAddress;

    /// @notice the treasury gathers fees during the restaking of rewards as shares
    address public treasuryAddress;

    /// @notice size of fee taken on rewards
    /// @dev phi in basis points
    uint256 public phi;

    /// @notice size of fee taken on non-strict allocations
    /// @dev phi in basis points
    uint256 public distPhi;

    /// @notice cap on deposits into the vault
    uint256 public cap;

    /// @notice mapping to keep track of (user, amount) values for each unbond nonce
    /// @dev Maps nonce of validator unbonding to a Withdrawal (user & amount).
    mapping(uint256 => Withdrawal) public unbondingWithdrawals;

    /// @notice allocated balance mapping to ensure users can only withdraw fudns not still allocated to a user
    mapping(address => mapping(bool => Allocation)) public totalAllocated;

    /// @notice mapping of distributor to recipient to amount and shareprice
    mapping(address => mapping(address => mapping(bool => Allocation))) public allocations;

    /// @notice array of distributors to their recipients
    mapping(address => mapping(bool => address[])) public recipients;

    /// @notice array of recipients to their distributors
    mapping(address => mapping(bool => address[])) public distributors;

    /// @notice value to offset rounding errors (move up in next deployment)
    uint256 public epsilon;

    // @notice strictness lock (move up in next deployment)
    bool public allowStrict;

    /// @notice gap for upgradeability
    uint256[48] private __gap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.19;

struct Withdrawal {
    address user;
    uint256 amount;
}

struct Allocation {
    uint256 maticAmount;
    uint256 sharePriceNum;
    uint256 sharePriceDenom;
}

/// @notice struct to hold information on a user's withdrawal request for fair claiming
/// @param user the user which made the withdrawal request
/// @param amount the amount of MATIC which the user requested to withdraw
/// @dev not storing epoch of withdrawal as that is the key in the `unbondingWithdrawals`
///   mapping