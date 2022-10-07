// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./SingleCollateralMultiRewardPerformanceBond.sol";
import "./ERC20SingleCollateralPerformanceBond.sol";
import "../RoleAccessControl.sol";
import "./PerformanceBondCreator.sol";
import "../Roles.sol";
import "../Version.sol";
import "../sweep/SweepERC20.sol";

/**
 * @title Creates Performance Bond contracts.
 *
 * @dev An upgradable contract that encapsulates the Bond implementation and associated deployment cost.
 */
contract PerformanceBondFactory is
    PerformanceBondCreator,
    OwnableUpgradeable,
    PausableUpgradeable,
    SweepERC20,
    Version
{
    event CreatePerformanceBond(
        address indexed bond,
        PerformanceBond.MetaData metadata,
        PerformanceBond.Settings configuration,
        PerformanceBond.TimeLockRewardPool[] rewards,
        address indexed treasury,
        address indexed instigator
    );

    constructor(address treasury) initializer {
        __Ownable_init();
        __TokenSweep_init(treasury);
    }

    function createPerformanceBond(
        PerformanceBond.MetaData calldata metadata,
        PerformanceBond.Settings calldata configuration,
        PerformanceBond.TimeLockRewardPool[] calldata rewards,
        address treasury
    ) external override whenNotPaused returns (address) {
        SingleCollateralMultiRewardPerformanceBond bond = new SingleCollateralMultiRewardPerformanceBond();

        emit CreatePerformanceBond(
            address(bond),
            metadata,
            configuration,
            rewards,
            treasury,
            _msgSender()
        );

        bond.initialize(metadata, configuration, rewards, treasury);
        bond.transferOwnership(_msgSender());

        return address(bond);
    }

    /**
     * @notice Pauses most side affecting functions.
     */
    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    function setTokenSweepBeneficiary(address newBeneficiary)
        external
        whenNotPaused
        onlyOwner
    {
        _setTokenSweepBeneficiary(newBeneficiary);
    }

    /**
     * @notice Resumes all paused side affecting functions.
     */
    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    function sweepERC20Tokens(address tokens, uint256 amount)
        external
        whenNotPaused
        onlyOwner
    {
        _sweepERC20Tokens(tokens, amount);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "./ERC20SingleCollateralPerformanceBond.sol";
import "./TimeLockMultiRewardPerformanceBond.sol";
import "./PerformanceBond.sol";

contract SingleCollateralMultiRewardPerformanceBond is
    ERC20SingleCollateralPerformanceBond,
    TimeLockMultiRewardPerformanceBond
{
    function allowRedemption(string calldata reason) external override {
        _allowRedemption(reason);
        _setRedemptionTimestamp(uint128(block.timestamp));
    }

    function deposit(uint256 amount) external override {
        address claimant = _msgSender();
        uint256 claimantDebt = balanceOf(claimant) + amount;
        _calculateRewardDebt(claimant, claimantDebt, totalSupply());
        _deposit(amount);
    }

    function initialize(
        PerformanceBond.MetaData calldata metadata,
        PerformanceBond.Settings calldata configuration,
        PerformanceBond.TimeLockRewardPool[] calldata rewards,
        address erc20CapableTreasury
    ) external initializer {
        __ERC20SingleCollateralBond_init(
            metadata,
            configuration,
            erc20CapableTreasury
        );
        __TimeLockMultiRewardBond_init(rewards);
    }

    function updateRewardTimeLock(address tokens, uint128 timeLock)
        external
        override
        onlyOwner
    {
        _updateRewardTimeLock(tokens, timeLock);
    }

    /**
     * @dev When debt tokens are transferred before redemption is allowed, the new holder gains full proportional
     *      rewards for the new holding of debt tokens, while the previous holder looses any entitlement.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (amount > 0 && !redeemable()) {
            uint256 supply = totalSupply();
            _calculateRewardDebt(from, balanceOf(from), supply);
            _calculateRewardDebt(to, balanceOf(to), supply);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./ExpiryTimestamp.sol";
import "./SingleCollateralPerformanceBond.sol";
import "./MetaDataStore.sol";
import "./Redeemable.sol";
import "../Version.sol";
import "./PerformanceBond.sol";
import "../sweep/SweepERC20.sol";

/**
 * @title A PerformanceBond is an issuance of debt tokens, which are exchange for deposit of collateral.
 *
 * @notice A single type of ERC20 token is accepted as collateral.
 *
 * The PerformanceBond uses a single redemption model. Before redemption, receiving and slashing collateral is permitted,
 * while after redemption, redeem (by guarantors) or complete withdrawal (by owner) is allowed.
 *
 * @dev A single token type is held by the contract as collateral, with the PerformanceBond ERC20 token being the debt.
 */
abstract contract ERC20SingleCollateralPerformanceBond is
    ERC20Upgradeable,
    ExpiryTimestamp,
    SingleCollateralPerformanceBond,
    MetaDataStore,
    OwnableUpgradeable,
    PausableUpgradeable,
    Redeemable,
    SweepERC20,
    Version
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Slash {
        string reason;
        uint256 collateralAmount;
    }

    Slash[] private _slashes;

    // Multiplier / divider for four decimal places, used in redemption ratio calculation.
    uint256 private constant _REDEMPTION_RATIO_ACCURACY = 1e4;

    /*
     * Collateral that is held by the bond, owed to the Guarantors (unless slashed).
     *
     * Kept to guard against the edge case of collateral tokens being directly transferred
     * (i.e. transfer in the collateral contract, not via deposit) to the contract address inflating redemption amounts.
     */
    uint256 private _collateral;

    uint256 private _collateralSlashed;

    address private _collateralTokens;

    uint256 private _debtTokensInitialSupply;

    // Balance of debts tokens held by guarantors, double accounting avoids potential affects of any minting/burning
    uint256 private _debtTokensOutstanding;

    // Balance of debt tokens held by the Bond when redemptions were allowed.
    uint256 private _debtTokensRedemptionExcess;

    // Minimum debt holding allowed in the pre-redemption state.
    uint256 private _minimumDeposit;

    /*
     * Ratio value between one (100% bond redeem) and zero (0% redeem), accuracy defined by _REDEMPTION_RATIO_ACCURACY.
     *
     * Calculated only once, when the redemption is allowed. Ratio will be one, unless slashing has occurred.
     */
    uint256 private _redemptionRatio;

    address private _treasury;

    event AllowRedemption(address indexed authorizer, string reason);
    event DebtIssue(
        address indexed receiver,
        address indexed debTokens,
        uint256 debtAmount
    );
    event Deposit(
        address indexed depositor,
        address indexed collateralTokens,
        uint256 collateralAmount
    );
    event Expire(
        address indexed treasury,
        address indexed collateralTokens,
        uint256 collateralAmount,
        address indexed instigator
    );
    event PartialCollateral(
        address indexed collateralTokens,
        uint256 collateralAmount,
        address indexed debtTokens,
        uint256 debtRemaining,
        address indexed instigator
    );
    event FullCollateral(
        address indexed collateralTokens,
        uint256 collateralAmount,
        address indexed instigator
    );
    event Redemption(
        address indexed redeemer,
        address indexed debtTokens,
        uint256 debtAmount,
        address indexed collateralTokens,
        uint256 collateralAmount
    );
    event SlashDeposits(
        address indexed collateralTokens,
        uint256 collateralAmount,
        string reason,
        address indexed instigator
    );
    event WithdrawCollateral(
        address indexed treasury,
        address indexed collateralTokens,
        uint256 collateralAmount,
        address indexed instigator
    );

    /**
     *  @notice Moves all remaining collateral to the Treasury and pauses the bond.
     *
     *  @dev A fail safe, callable by anyone after the Bond has expired.
     *       If control is lost, this can be used to move all remaining collateral to the Treasury,
     *       after which petitions for redemption can be made.
     *
     *  Expiry operates separately to pause, so a paused contract can be expired (fail safe for loss of control).
     */
    function expire() external whenBeyondExpiry {
        uint256 collateralBalance = IERC20Upgradeable(_collateralTokens)
            .balanceOf(address(this));
        require(collateralBalance > 0, "Bond: no collateral remains");

        emit Expire(
            _treasury,
            _collateralTokens,
            collateralBalance,
            _msgSender()
        );

        IERC20Upgradeable(_collateralTokens).safeTransfer(
            _treasury,
            collateralBalance
        );

        _pauseSafely();
    }

    function pause() external override whenNotPaused onlyOwner {
        _pause();
    }

    function redeem(uint256 amount)
        external
        override
        whenNotPaused
        whenRedeemable
    {
        require(amount > 0, "Bond: too small");
        require(balanceOf(_msgSender()) >= amount, "Bond: too few debt tokens");

        uint256 totalSupply = totalSupply() - _debtTokensRedemptionExcess;
        uint256 redemptionAmount = _redemptionAmount(amount, totalSupply);
        _collateral -= redemptionAmount;
        _debtTokensOutstanding -= redemptionAmount;

        emit Redemption(
            _msgSender(),
            address(this),
            amount,
            _collateralTokens,
            redemptionAmount
        );

        _burn(_msgSender(), amount);

        // Slashing can reduce redemption amount to zero
        if (redemptionAmount > 0) {
            IERC20Upgradeable(_collateralTokens).safeTransfer(
                _msgSender(),
                redemptionAmount
            );
        }
    }

    function unpause() external override whenPaused onlyOwner {
        _unpause();
    }

    function slash(uint256 amount, string calldata reason)
        external
        override
        whenNotPaused
        whenNotRedeemable
        onlyOwner
    {
        require(amount > 0, "Bond: too small");
        require(amount <= _collateral, "Bond: too large");

        _collateral -= amount;
        _collateralSlashed += amount;

        emit SlashDeposits(_collateralTokens, amount, reason, _msgSender());

        _slashes.push(Slash(reason, amount));

        IERC20Upgradeable(_collateralTokens).safeTransfer(_treasury, amount);
    }

    function setMetaData(string calldata data)
        external
        override
        whenNotPaused
        onlyOwner
    {
        return _setMetaData(data);
    }

    function setTreasury(address replacement)
        external
        override
        whenNotPaused
        onlyOwner
    {
        require(replacement != address(0), "Bond: treasury is zero address");
        _treasury = replacement;
        _setTokenSweepBeneficiary(replacement);
    }

    function sweepERC20Tokens(address tokens, uint256 amount)
        external
        override
        whenNotPaused
        onlyOwner
    {
        require(tokens != _collateralTokens, "Bond: no collateral sweeping");
        _sweepERC20Tokens(tokens, amount);
    }

    function withdrawCollateral()
        external
        override
        whenNotPaused
        whenRedeemable
        onlyOwner
    {
        uint256 collateralBalance = IERC20Upgradeable(_collateralTokens)
            .balanceOf(address(this));
        require(collateralBalance > 0, "Bond: no collateral remains");

        emit WithdrawCollateral(
            _treasury,
            _collateralTokens,
            collateralBalance,
            _msgSender()
        );

        IERC20Upgradeable(_collateralTokens).safeTransfer(
            _treasury,
            collateralBalance
        );
    }

    /**
     * @notice How much collateral held by the bond is owned to the Guarantors.
     *
     * @dev Collateral has come from guarantors, with the balance changes on deposit, redeem, slashing and flushing.
     *      This value may differ to balanceOf(this), if collateral tokens have been directly transferred
     *      i.e. direct transfer interaction with the token contract, rather then using the Bond functions.
     */
    function collateral() external view returns (uint256) {
        return _collateral;
    }

    /**
     * @notice The ERC20 contract being used as collateral.
     */
    function collateralTokens() external view returns (address) {
        return address(_collateralTokens);
    }

    /**
     * @notice Sum of collateral moved from the bond to the Treasury by slashing.
     *
     * @dev Other methods of performing moving of collateral outside of slashing, are not included.
     */
    function collateralSlashed() external view returns (uint256) {
        return _collateralSlashed;
    }

    /**
     * @notice Balance of debt tokens held by the bond.
     *
     * @dev Number of debt tokens that can still be swapped for collateral token (if before redemption state),
     *          or the amount of under-collateralization (if during redemption state).
     *
     */
    function debtTokens() external view returns (uint256) {
        return _debtTokensRemaining();
    }

    /**
     * @notice Balance of debt tokens held by the guarantors.
     *
     * @dev Number of debt tokens still held by Guarantors. The number only reduces when guarantors redeem
     *          (swap their debt tokens for collateral).
     */
    function debtTokensOutstanding() external view returns (uint256) {
        return _debtTokensOutstanding;
    }

    /**
     * @notice Balance of debt tokes outstanding when the redemption state was entered.
     *
     * @dev As the collateral deposited is a 1:1, this is amount of collateral that was not received.
     *
     * @return zero if redemption is not yet allowed or full collateral was met, otherwise the number of debt tokens
     *          remaining without matched deposit when redemption was allowed,
     */
    function excessDebtTokens() external view returns (uint256) {
        return _debtTokensRedemptionExcess;
    }

    /**
     * @notice Debt tokens created on initialization.
     *
     * @dev Number of debt tokens minted on init. The total supply of debt tokens will decrease, as redeem burns them.
     */
    function initialDebtTokens() external view returns (uint256) {
        return _debtTokensInitialSupply;
    }

    /**
     * @notice Minimum amount of debt allowed.
     *
     * @dev Avoids micro holdings, as some operations cost scale linear to debt holders.
     *      Once an account holds the minimum, any deposit from is acceptable as their holding is above the minimum.
     */
    function minimumDeposit() external view returns (uint256) {
        return _minimumDeposit;
    }

    function treasury() external view returns (address) {
        return _treasury;
    }

    function getSlashes() external view returns (Slash[] memory) {
        return _slashes;
    }

    function getSlashByIndex(uint256 index)
        external
        view
        returns (Slash memory)
    {
        require(index < _slashes.length, "Bond: slash does not exist");
        return _slashes[index];
    }

    function hasFullCollateral() public view returns (bool) {
        return _debtTokensRemaining() == 0;
    }

    //slither-disable-next-line naming-convention
    function __ERC20SingleCollateralBond_init(
        PerformanceBond.MetaData calldata metadata,
        PerformanceBond.Settings calldata configuration,
        address erc20CapableTreasury
    ) internal onlyInitializing {
        require(
            erc20CapableTreasury != address(0),
            "Bond: treasury is zero address"
        );
        require(
            configuration.collateralTokens != address(0),
            "Bond: collateral is zero address"
        );

        __ERC20_init(metadata.name, metadata.symbol);
        __Ownable_init();
        __Pausable_init();
        __ExpiryTimestamp_init(configuration.expiryTimestamp);
        __MetaDataStore_init(metadata.data);
        __Redeemable_init();
        __TokenSweep_init(erc20CapableTreasury);

        _collateralTokens = configuration.collateralTokens;
        _debtTokensInitialSupply = configuration.debtTokenAmount;
        _minimumDeposit = configuration.minimumDeposit;
        _treasury = erc20CapableTreasury;

        _mint(configuration.debtTokenAmount);
    }

    function _allowRedemption(string calldata reason)
        internal
        whenNotPaused
        whenNotRedeemable
        onlyOwner
    {
        _setAsRedeemable(reason);
        emit AllowRedemption(_msgSender(), reason);

        if (_hasDebtTokensRemaining()) {
            _debtTokensRedemptionExcess = _debtTokensRemaining();

            emit PartialCollateral(
                _collateralTokens,
                IERC20Upgradeable(_collateralTokens).balanceOf(address(this)),
                address(this),
                _debtTokensRemaining(),
                _msgSender()
            );
        }

        if (_hasBeenSlashed()) {
            _redemptionRatio = _calculateRedemptionRatio();
        }
    }

    function _deposit(uint256 amount) internal whenNotPaused whenNotRedeemable {
        require(amount > 0, "Bond: too small");
        require(amount <= _debtTokensRemaining(), "Bond: too large");
        require(
            balanceOf(_msgSender()) + amount >= _minimumDeposit,
            "Bond: below minimum"
        );

        _collateral += amount;
        _debtTokensOutstanding += amount;

        emit Deposit(_msgSender(), _collateralTokens, amount);

        IERC20Upgradeable(_collateralTokens).safeTransferFrom(
            _msgSender(),
            address(this),
            amount
        );

        emit DebtIssue(_msgSender(), address(this), amount);

        _transfer(address(this), _msgSender(), amount);

        if (hasFullCollateral()) {
            emit FullCollateral(
                _collateralTokens,
                IERC20Upgradeable(_collateralTokens).balanceOf(address(this)),
                _msgSender()
            );
        }
    }

    /**
     * @dev Mints additional debt tokens, inflating the supply. Without additional deposits the redemption ratio is affected.
     */
    function _mint(uint256 amount) private whenNotPaused whenNotRedeemable {
        require(amount > 0, "Bond::mint: too small");
        _mint(address(this), amount);
    }

    /**
     *  @dev Pauses the Bond if not already paused. If already paused, does nothing (no revert).
     */
    function _pauseSafely() private {
        if (!paused()) {
            _pause();
        }
    }

    /**
     * @dev Collateral is deposited at a 1 to 1 ratio, however slashing can change that lower.
     */
    function _redemptionAmount(uint256 amount, uint256 totalSupply)
        private
        view
        returns (uint256)
    {
        if (_collateral == totalSupply) {
            return amount;
        } else {
            return _applyRedemptionRation(amount);
        }
    }

    function _applyRedemptionRation(uint256 amount)
        private
        view
        returns (uint256)
    {
        return (_redemptionRatio * amount) / _REDEMPTION_RATIO_ACCURACY;
    }

    /**
     * @return Redemption ration float value as an integer.
     *           The float has been multiplied by _REDEMPTION_RATIO_ACCURACY, with any excess accuracy floored (lost).
     */
    function _calculateRedemptionRatio() private view returns (uint256) {
        return
            (_REDEMPTION_RATIO_ACCURACY * _collateral) /
            (totalSupply() - _debtTokensRedemptionExcess);
    }

    /**
     * @dev The balance of debt token held; amount of debt token that are awaiting collateral swap.
     */
    function _debtTokensRemaining() private view returns (uint256) {
        return balanceOf(address(this));
    }

    /**
     * @dev Whether the Bond has been slashed. Assumes a 1:1 deposit ratio (collateral to debt).
     */
    function _hasBeenSlashed() private view returns (bool) {
        return _collateral != (totalSupply() - _debtTokensRedemptionExcess);
    }

    /**
     * @dev Whether the Bond has held debt tokens.
     */
    function _hasDebtTokensRemaining() private view returns (bool) {
        return _debtTokensRemaining() > 0;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "./RoleMembership.sol";
import "./Roles.sol";

/**
 * @title Access control using a predefined set of roles.
 *
 * @notice The roles and their relationship to each other are defined.
 *
 * @dev There are two categories of role:
 * - Global; permissions granted across all DAOs.
 * - Dao; permissions granted only in a single DAO.
 */
abstract contract RoleAccessControl is RoleMembership {
    uint8 private _superUserCounter;

    modifier onlySuperUserRole() {
        if (_isMissingGlobalRole(Roles.SUPER_USER, _msgSender())) {
            revert(
                _revertMessageMissingGlobalRole(Roles.SUPER_USER, _msgSender())
            );
        }
        _;
    }

    modifier atLeastDaoCreatorRole() {
        if (
            _isMissingGlobalRole(Roles.SUPER_USER, _msgSender()) &&
            _isMissingGlobalRole(Roles.DAO_CREATOR, _msgSender())
        ) {
            revert(
                _revertMessageMissingGlobalRole(Roles.DAO_CREATOR, _msgSender())
            );
        }
        _;
    }

    modifier atLeastSysAdminRole() {
        if (
            _isMissingGlobalRole(Roles.SUPER_USER, _msgSender()) &&
            _isMissingGlobalRole(Roles.SYSTEM_ADMIN, _msgSender())
        ) {
            revert(
                _revertMessageMissingGlobalRole(
                    Roles.SYSTEM_ADMIN,
                    _msgSender()
                )
            );
        }
        _;
    }

    modifier atLeastDaoAdminRole(uint256 daoId) {
        if (
            _isMissingGlobalRole(Roles.SUPER_USER, _msgSender()) &&
            _isMissingDaoRole(daoId, Roles.DAO_ADMIN, _msgSender())
        ) {
            revert(
                _revertMessageMissingDaoRole(
                    daoId,
                    Roles.DAO_ADMIN,
                    _msgSender()
                )
            );
        }
        _;
    }

    modifier atLeastDaoMeepleRole(uint256 daoId) {
        if (
            _isMissingGlobalRole(Roles.SUPER_USER, _msgSender()) &&
            _isMissingDaoRole(daoId, Roles.DAO_ADMIN, _msgSender()) &&
            _isMissingDaoRole(daoId, Roles.DAO_MEEPLE, _msgSender())
        ) {
            revert(
                _revertMessageMissingDaoRole(
                    daoId,
                    Roles.DAO_MEEPLE,
                    _msgSender()
                )
            );
        }
        _;
    }

    function grantSuperUserRole(address account) external onlySuperUserRole {
        _grantGlobalRole(Roles.SUPER_USER, account);
        _superUserCounter++;
    }

    function grantDaoCreatorRole(address account) external onlySuperUserRole {
        _grantGlobalRole(Roles.DAO_CREATOR, account);
    }

    function grantSysAdminRole(address account) external atLeastSysAdminRole {
        _grantGlobalRole(Roles.SYSTEM_ADMIN, account);
    }

    function grantDaoAdminRole(uint256 daoId, address account)
        external
        atLeastDaoAdminRole(daoId)
    {
        _grantDaoRole(daoId, Roles.DAO_ADMIN, account);
    }

    function grantDaoMeepleRole(uint256 daoId, address account)
        external
        atLeastDaoAdminRole(daoId)
    {
        _grantDaoRole(daoId, Roles.DAO_MEEPLE, account);
    }

    function revokeSuperUserRole(address account) external onlySuperUserRole {
        _revokeGlobalRole(Roles.SUPER_USER, account);
        require(_superUserCounter > 1, "RAC: no revoking last SuperUser");
        _superUserCounter--;
    }

    function revokeDaoCreatorRole(address account) external onlySuperUserRole {
        _revokeGlobalRole(Roles.DAO_CREATOR, account);
    }

    function revokeSysAdminRole(address account) external atLeastSysAdminRole {
        _revokeGlobalRole(Roles.SYSTEM_ADMIN, account);
    }

    function revokeDaoAdminRole(uint256 daoId, address account)
        external
        atLeastDaoAdminRole(daoId)
    {
        _revokeDaoRole(daoId, Roles.DAO_ADMIN, account);
    }

    function revokeDaoMeepleRole(uint256 daoId, address account)
        external
        atLeastDaoAdminRole(daoId)
    {
        _revokeDaoRole(daoId, Roles.DAO_MEEPLE, account);
    }

    function hasSuperUserAccess(address account) external view returns (bool) {
        return _hasGlobalRole(Roles.SUPER_USER, account);
    }

    function hasDaoAdminAccess(uint256 daoId, address account)
        external
        view
        returns (bool)
    {
        return
            _hasGlobalRole(Roles.SUPER_USER, account) ||
            _hasDaoRole(daoId, Roles.DAO_ADMIN, account);
    }

    function hasDaoCreatorAccess(address account) external view returns (bool) {
        return
            _hasGlobalRole(Roles.SUPER_USER, account) ||
            _hasGlobalRole(Roles.DAO_CREATOR, account);
    }

    function hasDaoMeepleAccess(uint256 daoId, address account)
        external
        view
        returns (bool)
    {
        return
            _hasGlobalRole(Roles.SUPER_USER, account) ||
            _hasDaoRole(daoId, Roles.DAO_ADMIN, account) ||
            _hasDaoRole(daoId, Roles.DAO_MEEPLE, account);
    }

    function hasSysAdminAccess(address account) external view returns (bool) {
        return
            _hasGlobalRole(Roles.SUPER_USER, account) ||
            _hasGlobalRole(Roles.SYSTEM_ADMIN, account);
    }

    /**
     * @notice The _msgSender() is given membership of the SuperUser role.
     *
     * @dev Allows granting and future renouncing after other addresses have been setup.
     */
    //slither-disable-next-line naming-convention
    function __RoleAccessControl_init() internal onlyInitializing {
        __RoleMembership_init();

        _grantGlobalRole(Roles.SUPER_USER, _msgSender());
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "./PerformanceBond.sol";

/**
 * @title Deploys new PerformanceBonds.
 *
 * @notice Creating a Performance Bond involves the two steps of deploying and initialising.
 */
interface PerformanceBondCreator {
    /**
     * @notice Deploys and initialises a new PerformanceBond.
     *
     * @param metadata General details about the Bond no essential for operation.
     * @param configuration Values to use during the Bond creation process.
     * @param rewards Motivation for the guarantors to deposit, available after redemption.
     * @param treasury Receiver of any slashed or swept tokens or collateral.
     */
    function createPerformanceBond(
        PerformanceBond.MetaData calldata metadata,
        PerformanceBond.Settings calldata configuration,
        PerformanceBond.TimeLockRewardPool[] calldata rewards,
        address treasury
    ) external returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

/**
 * @title Roles within the hierarchical DAO access control schema.
 *
 * @notice Similar to a Linux permission system there is a super user, with some of the other roles being tiered
 *          amongst each other.
 *
 *  SUPER_USER role the manage for DAO_CREATOR roles, in addition to being a super set to to all other roles functions.
 *  DAO_CREATOR role only business is creating DAOs and their configurations.
 *  DAO_ADMIN role can update the DAOs configuration and may intervene to sweep / flush.
 *  DAO_MEEPLE role is deals with the life cycle of the DAOs products.
 *  SYSTEM_ADMIN role deals with tasks such as pause-ability and the upgrading of contract.
 */
library Roles {
    bytes32 public constant DAO_ADMIN = "DAO_ADMIN";
    bytes32 public constant DAO_CREATOR = "DAO_CREATOR";
    bytes32 public constant DAO_MEEPLE = "DAO_MEEPLE";
    bytes32 public constant SUPER_USER = "SUPER_USER";
    bytes32 public constant SYSTEM_ADMIN = "SYSTEM_ADMIN";
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

abstract contract Version {
    string public constant VERSION = "v0.0.1";
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "./TokenSweep.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title Adds the ability to sweep ERC20 tokens to a beneficiary address
 */
abstract contract SweepERC20 is TokenSweep {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event ERC20Sweep(
        address indexed beneficiary,
        address indexed tokens,
        uint256 amount,
        address indexed instigator
    );

    /**
     * @notice Sweep the erc20 tokens to the beneficiary address
     *
     * @param tokens The registry for the ERC20 token to transfer,
     * @param amount How many tokens, in the ERC20's decimals to transfer.
     **/
    function _sweepERC20Tokens(address tokens, uint256 amount) internal {
        require(tokens != address(this), "SweepERC20: self transfer");
        require(tokens != address(0), "SweepERC20: address zero");

        emit ERC20Sweep(tokenSweepBeneficiary(), tokens, amount, _msgSender());

        IERC20Upgradeable(tokens).safeTransfer(tokenSweepBeneficiary(), amount);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./PerformanceBond.sol";

/**
 * @title Multiple reward with time lock support.
 *
 * @notice Supports multiple ERC20 rewards with an optional time lock on pull based claiming.
 *         Rewards are not accrued, rather they are given to token holder on redemption of their debt token.
 *
 * @dev Each reward has it's own time lock, allowing different rewards to be claimable at different points in time.
 *
 *      When a guarantor deposits collateral or transfers debt tokens (for a purpose other than redemption), then
 *      _calculateRewardDebt() must be called to keep their rewards updated.
 */
abstract contract TimeLockMultiRewardPerformanceBond is PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct ClaimableReward {
        address tokens;
        uint256 amount;
    }

    mapping(address => mapping(address => uint256))
        private _claimantToRewardPoolDebt;
    PerformanceBond.TimeLockRewardPool[] private _rewardPools;
    uint256 private _redemptionTimestamp;
    mapping(address => bool) private _tokensCounter;

    event ClaimReward(
        address indexed tokens,
        uint256 amount,
        address indexed instigator
    );
    event RegisterReward(
        address indexed tokens,
        uint256 amount,
        uint256 timeLock,
        address indexed instigator
    );
    event RewardDebt(
        address indexed tokens,
        address indexed claimant,
        uint256 rewardDebt,
        address indexed instigator
    );
    event RedemptionTimestampUpdate(
        uint256 timestamp,
        address indexed instigator
    );
    event RewardTimeLockUpdate(
        address indexed tokens,
        uint256 timeLock,
        address indexed instigator
    );

    /**
     * @notice Makes a function callable only when the contract has the redemption times set.
     *
     * @dev Reverts unless the redemption timestamp has been set.
     */
    modifier whenRedemptionTimestampSet() {
        require(_isRedemptionTimeSet(), "Rewards: redemption time not set");
        _;
    }

    /**
     * @notice Makes a function callable only when the contract has not yet had a redemption times set.
     *
     * @dev Reverts unless the redemption timestamp has been set.
     */
    modifier whenNoRedemptionTimestamp() {
        require(!_isRedemptionTimeSet(), "Rewards: redemption time set");
        _;
    }

    /**
     * @notice Claims any available rewards for the caller.
     *
     * @dev Rewards are claimable when their are registered and their time lock has expired.
     *
     *  NOTE: If there is nothing to claim, the function completes execution without revert. Handle this problem
     *        with UI. Only display a claim when there an available reward to claim.
     */
    function claimAllAvailableRewards()
        external
        whenNotPaused
        whenRedemptionTimestampSet
    {
        address claimant = _msgSender();

        for (uint256 i = 0; i < _rewardPools.length; i++) {
            PerformanceBond.TimeLockRewardPool
                storage rewardPool = _rewardPools[i];
            _claimReward(claimant, rewardPool);
        }
    }

    /**
     * @notice The set of total rewards outstanding for the PerformanceBond.
     *
     * @dev These rewards will be split proportionally between the debt holders.
     *
     *      After claiming, these value remain unchanged (as they are not used after redemption is allowed,
     *      only for calculations after deposits and transfers).
     *
     * NOTE: Values are copied to a memory array be wary of gas cost if call within a transaction!
     *       Expected usage is by view accessors that are queried without any gas fees.
     */
    function allRewardPools()
        external
        view
        returns (PerformanceBond.TimeLockRewardPool[] memory)
    {
        PerformanceBond.TimeLockRewardPool[]
            memory rewards = new PerformanceBond.TimeLockRewardPool[](
                _rewardPools.length
            );

        for (uint256 i = 0; i < _rewardPools.length; i++) {
            rewards[i] = _rewardPools[i];
        }
        return rewards;
    }

    /**
     * @notice Retrieves the set full set of rewards, with the amounts populated for only claimable rewards.
     *
     * @dev Rewards that are not yet claimable, or have already been claimed are zero.
     *
     * NOTE: Values are copied to a memory array be wary of gas cost if call within a transaction!
     *       Expected usage is by view accessors that are queried without any gas fees.
     */
    // Intentional use of timestamp for time lock expiry check
    //slither-disable-next-line timestamp
    function availableRewards()
        external
        view
        returns (ClaimableReward[] memory)
    {
        ClaimableReward[] memory rewards = new ClaimableReward[](
            _rewardPools.length
        );
        address claimant = _msgSender();

        for (uint256 i = 0; i < _rewardPools.length; i++) {
            PerformanceBond.TimeLockRewardPool
                storage rewardPool = _rewardPools[i];
            rewards[i].tokens = rewardPool.tokens;

            if (
                _hasTimeLockExpired(rewardPool) &&
                _hasRewardDebt(claimant, rewardPool)
            ) {
                rewards[i].amount = _rewardDebt(claimant, rewardPool);
            }
        }

        return rewards;
    }

    function redemptionTimestamp() external view returns (uint256) {
        return _redemptionTimestamp;
    }

    /**
     * @notice Reward debt currently assigned to claimant.
     *
     * @dev These rewards are the sum owed pending the time lock after redemption timestamp.
     */
    function rewardDebt(address claimant, address tokens)
        external
        view
        returns (uint256)
    {
        return _claimantToRewardPoolDebt[claimant][tokens];
    }

    /**
     * @notice Initial time locked reward pools available for participating in the PerformanceBond.
     *
     * @dev The initial configuration for the pools is retrieve .i.e. not decremented as rewards are claimed.
     *
     * NOTE: Values are copied to a memory array be wary of gas cost if call within a transaction!
     *       Expected usage is by view accessors that are queried without any gas fees.
     */
    function timeLockRewardPools()
        external
        view
        returns (PerformanceBond.TimeLockRewardPool[] memory)
    {
        return _rewardPools;
    }

    /**
     * @notice Calculate the rewards the claimant will be entitled to after redemption and corresponding lock up period.
     *
     * @dev Must be called when the guarantor deposits collateral or on transfer of debt tokens, but not when they
     *      the claimant redeems, otherwise you will erase their rewards.
     */
    function _calculateRewardDebt(
        address claimant,
        uint256 claimantDebtTokens,
        uint256 totalSupply
    ) internal whenNotPaused whenNoRedemptionTimestamp {
        require(claimantDebtTokens <= totalSupply, "Rewards: too much debt");

        for (uint256 i = 0; i < _rewardPools.length; i++) {
            PerformanceBond.TimeLockRewardPool
                storage rewardPool = _rewardPools[i];

            uint256 owed = (rewardPool.amount * claimantDebtTokens) /
                totalSupply;

            _claimantToRewardPoolDebt[claimant][rewardPool.tokens] = owed;
            emit RewardDebt(rewardPool.tokens, claimant, owed, _msgSender());
        }
    }

    function _updateRewardTimeLock(address tokens, uint128 timeLock)
        internal
        whenNotPaused
        whenNoRedemptionTimestamp
    {
        PerformanceBond.TimeLockRewardPool
            storage rewardPool = _rewardPoolByToken(tokens);

        rewardPool.timeLock = timeLock;

        emit RewardTimeLockUpdate(tokens, timeLock, _msgSender());
    }

    /**
     * @notice The time at which the debt tokens are redeemable.
     *
     * @dev Until a redemption time is set, no rewards are claimable.
     */
    function _setRedemptionTimestamp(uint128 timestamp)
        internal
        whenNotPaused
        whenNoRedemptionTimestamp
    {
        require(
            _isPresentOrFutureTime(timestamp),
            "Rewards: time already past"
        );

        _redemptionTimestamp = timestamp;

        emit RedemptionTimestampUpdate(timestamp, _msgSender());
    }

    /**
     * @param rewardPools Set of rewards claimable after a time lock following bond becoming redeemable.
     */
    //slither-disable-next-line naming-convention
    function __TimeLockMultiRewardBond_init(
        PerformanceBond.TimeLockRewardPool[] calldata rewardPools
    ) internal onlyInitializing {
        __Pausable_init();

        _enforceUniqueRewardTokens(rewardPools);
        _registerRewardPools(rewardPools);
    }

    /**
     * @dev When there are insufficient fund the transfer causes the transaction to revert,
     *      either as a revert in the ERC20 or when the return boolean is false.
     */
    function _claimReward(
        address claimant,
        PerformanceBond.TimeLockRewardPool storage rewardPool
    ) private {
        if (_hasTimeLockExpired(rewardPool)) {
            address tokens = rewardPool.tokens;
            uint256 amount = _claimantToRewardPoolDebt[claimant][tokens];
            delete _claimantToRewardPoolDebt[claimant][tokens];

            emit ClaimReward(tokens, amount, _msgSender());

            _transferReward(tokens, amount, claimant);
        }
    }

    function _registerRewardPools(
        PerformanceBond.TimeLockRewardPool[] memory rewardPools
    ) private {
        for (uint256 i = 0; i < rewardPools.length; i++) {
            _registerRewardPool(rewardPools[i]);
        }
    }

    function _registerRewardPool(
        PerformanceBond.TimeLockRewardPool memory rewardPool
    ) private {
        require(rewardPool.tokens != address(0), "Rewards: address is zero");
        require(rewardPool.amount > 0, "Rewards: no reward amount");

        emit RegisterReward(
            rewardPool.tokens,
            rewardPool.amount,
            rewardPool.timeLock,
            _msgSender()
        );

        _rewardPools.push(rewardPool);
    }

    // Claiming multiple rewards in a single function, looping is unavoidable
    //slither-disable-next-line calls-loop
    function _transferReward(
        address tokens,
        uint256 amount,
        address claimant
    ) private {
        IERC20Upgradeable(tokens).safeTransfer(claimant, amount);
    }

    function _enforceUniqueRewardTokens(
        PerformanceBond.TimeLockRewardPool[] calldata rewardPools
    ) private {
        for (uint256 i = 0; i < rewardPools.length; i++) {
            // Ensure no prev entries contain the same tokens address
            if (_tokensCounter[rewardPools[i].tokens]) {
                revert("Rewards: tokens must be unique");
            }
            _tokensCounter[rewardPools[i].tokens] = true;
        }
        for (uint256 i = 0; i < rewardPools.length; i++) {
            delete _tokensCounter[rewardPools[i].tokens];
        }
    }

    function _hasRewardDebt(
        address claimant,
        PerformanceBond.TimeLockRewardPool storage rewardPool
    ) private view returns (bool) {
        return _claimantToRewardPoolDebt[claimant][rewardPool.tokens] > 0;
    }

    function _rewardDebt(
        address claimant,
        PerformanceBond.TimeLockRewardPool storage rewardPool
    ) private view returns (uint256) {
        return _claimantToRewardPoolDebt[claimant][rewardPool.tokens];
    }

    // Intentional use of timestamp for time lock expiry check
    //slither-disable-next-line timestamp
    function _hasTimeLockExpired(
        PerformanceBond.TimeLockRewardPool storage rewardPool
    ) private view returns (bool) {
        return block.timestamp >= rewardPool.timeLock + _redemptionTimestamp;
    }

    // Intentional use of timestamp for input validation
    //slither-disable-next-line timestamp
    function _isPresentOrFutureTime(uint128 timestamp)
        private
        view
        returns (bool)
    {
        return timestamp >= block.timestamp;
    }

    function _isRedemptionTimeSet() private view returns (bool) {
        return _redemptionTimestamp > 0;
    }

    function _rewardPoolByToken(address tokens)
        private
        view
        returns (PerformanceBond.TimeLockRewardPool storage)
    {
        for (uint256 i = 0; i < _rewardPools.length; i++) {
            PerformanceBond.TimeLockRewardPool
                storage rewardPool = _rewardPools[i];

            if (rewardPool.tokens == tokens) {
                return rewardPool;
            }
        }

        revert("Rewards: tokens not found");
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

/**
 * @title Domain model for Performance Bonds.
 */
library PerformanceBond {
    struct MetaData {
        /** Description of the purpose for the Performance Bond. */
        string name;
        /** Abbreviation to identify the Performance Bond. */
        string symbol;
        /** Metadata bucket not required for the operation of the Performance Bond, but needed by external actors. */
        string data;
    }

    struct Settings {
        /** Number of tokens to create, which get swapped for collateral tokens by depositing. */
        uint256 debtTokenAmount;
        /** Token contract for the collateral that is swapped for debt tokens during deposit. */
        address collateralTokens;
        /**
         * Unix timestamp for when the Bond is expired and anyone can move the remaining collateral to the Treasury,
         * then petitions may be made for redemption.
         */
        uint256 expiryTimestamp;
        /**
         * Minimum debt holding allowed in the deposit phase. Once the minimum is met,
         * any sized deposit from that account is allowed, as the minimum has already been met.
         */
        uint256 minimumDeposit;
    }

    struct TimeLockRewardPool {
        /** Tokens being used for the reward. */
        address tokens;
        /** Total number of tokens awarded to guarantors. */
        uint128 amount;
        /** Seconds reward is locked up after redemption is allowed. */
        uint128 timeLock;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
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
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Provides an expiry timestamp, with evaluation modifier.
 *
 * @dev Time evaluation uses the block current timestamp.
 */
abstract contract ExpiryTimestamp is Initializable {
    uint256 private _expiry;

    /**
     * @notice Reverts when the time has not met or passed the expiry timestamp.
     *
     * @dev Warning: use of block timestamp introduces risk of miner time manipulation.
     */
    modifier whenBeyondExpiry() {
        require(block.timestamp >= _expiry, "ExpiryTimestamp: not yet expired");
        _;
    }

    /**
     * @notice The timestamp compared with the block time to determine expiry.
     *
     * @dev Timestamp is the Unix time.
     */
    function expiryTimestamp() external view returns (uint256) {
        return _expiry;
    }

    /**
     * @notice Initialisation of the expiry timestamp to enable the 'hasExpired' modifier.
     *
     * @param timestamp expiry without any restriction e.g. it has not yet passed.
     */
    //slither-disable-next-line naming-convention
    function __ExpiryTimestamp_init(uint256 timestamp)
        internal
        onlyInitializing
    {
        _expiry = timestamp;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

interface SingleCollateralPerformanceBond {
    /**
     * @notice Transitions the PerformanceBond state, from being non-redeemable (accepting deposits and slashing) to
     *          redeemable (accepting redeem and withdraw collateral).
     *
     * @dev Debt tokens are not allowed to be redeemed before the owner grants permission.
     */
    function allowRedemption(string calldata reason) external;

    /**
     * @notice Deposit swaps collateral tokens for an equal amount of debt tokens.
     *
     * @dev Before the deposit can be made, this contract must have been approved to transfer the given amount
     * from the ERC20 token being used as collateral.
     *
     * @param amount The number of collateral token to transfer from the _msgSender().
     *          Must be in the range of one to the number of debt tokens available for swapping.
     *          The _msgSender() receives the debt tokens.
     */
    function deposit(uint256 amount) external;

    /**
     * @notice Pauses most side affecting functions.
     *
     * @dev The ony side effecting (non view or pure function) function exempt from pausing is expire().
     */
    function pause() external;

    /**
     * @notice Redeem swaps debt tokens for collateral tokens.
     *
     * @dev Converts the amount of debt tokens owned by the sender, at the exchange ratio determined by the remaining
     *  amount of collateral against the remaining amount of debt.
     *  There are operations that reduce the held collateral, while the debt remains constant.
     *
     * @param amount The number of debt token to transfer from the sender.
     *          Must be in the range of one to the number of debt tokens available for swapping.
     */
    function redeem(uint256 amount) external;

    /**
     * @notice Sweep any non collateral ERC20 tokens to the beneficiary address
     *
     * @param tokens The registry for the ERC20 token to transfer,
     * @param amount How many tokens, in the ERC20's decimals to transfer.
     */
    function sweepERC20Tokens(address tokens, uint256 amount) external;

    /**
     * @notice Resumes all paused side affecting functions.
     */
    function unpause() external;

    /**
     * @notice Enact a penalty for guarantors, a loss of a portion of their bonded collateral.
     *          The designated Treasury is the recipient for the slashed collateral.
     *
     * @dev The penalty can range between one and all of the collateral.
     *
     * As the amount of debt tokens remains the same. Slashing reduces the collateral tokens, so each debt token
     * is redeemable for less collateral, altering the redemption ratio calculated on allowRedemption().
     *
     * @param amount The number of bonded collateral token to transfer from the Bond to the Treasury.
     *          Must be in the range of one to the number of collateral tokens held by the Bond.
     */
    function slash(uint256 amount, string calldata reason) external;

    /**
     * @notice Replaces any stored metadata.
     *
     * @dev As metadata is not pertinent for PerformanceBond operations, this may be anything e.g. a delimitated string.
     *
     * @param data Information useful for off-chain actions e.g. performance factor, assessment date, rewards pool.
     */
    function setMetaData(string calldata data) external;

    /**
     * @notice Permits the owner to update the Treasury address.
     *
     * @dev treasury is the recipient of slashed, expired or withdrawn collateral.
     *          Must be a non-zero address.
     *
     * @param replacement Treasury recipient for future operations. Must not be zero address.
     */
    function setTreasury(address replacement) external;

    /**
     * @notice Overwrites the existing time lock for a Bond reward.
     *
     * @param tokens ERC20 rewards already registered.
     * @param timeLock seconds to lock rewards after redemption is allowed.
     */
    function updateRewardTimeLock(address tokens, uint128 timeLock) external;

    /**
     * @notice Permits the owner to transfer all collateral held by the Bond to the Treasury.
     *
     * @dev Intention is to sweeping up excess collateral from redemption ration calculation, such as  when there has
     *      been slashing. Slashing can result in collateral remaining due to flooring.
     *
     *  Can also provide an emergency extracting moving of funds out of the Bond by the owner.
     */
    function withdrawCollateral() external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @title A string storage bucket for metadata.
 *
 * @notice Useful for off-chain actors to store on data on-chain.
 *          Information related to the contract but not required for contract operations.
 *
 * @dev Metadata could include UI related pieces, perhaps in a delimited format to support multiple items.
 */
abstract contract MetaDataStore is ContextUpgradeable {
    string private _metaData;

    event MetaDataUpdate(string data, address indexed instigator);

    /**
     * @notice The storage box for metadata. Information not required by the contract for operations.
     *
     * @dev Information related to the contract but not needed by the contract.
     */
    function metaData() external view returns (string memory) {
        return _metaData;
    }

    //slither-disable-next-line naming-convention
    function __MetaDataStore_init(string calldata data)
        internal
        onlyInitializing
    {
        _setMetaData(data);
    }

    /**
     * @notice Replaces any existing stored metadata.
     *
     * @dev To expose the setter externally with modifier access control, create a new method invoking _setMetaData.
     */
    function _setMetaData(string calldata data) internal {
        _metaData = data;
        emit MetaDataUpdate(data, _msgSender());
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @title Encapsulates the state of being redeemable.
 *
 * @notice The state of being redeemable is boolean and single direction transition from false to true.
 */
abstract contract Redeemable is ContextUpgradeable {
    bool private _redeemable;

    string private _reason;

    event RedeemableUpdate(
        bool isRedeemable,
        string reason,
        address indexed instigator
    );

    /**
     * @notice Makes a function callable only when the contract is not redeemable.
     *
     * @dev Reverts when the contract is redeemable.
     *
     * Requirements:
     * - The contract must not be redeemable.
     */
    modifier whenNotRedeemable() {
        require(!_redeemable, "whenNotRedeemable: redeemable");
        _;
    }

    /**
     * @notice Makes a function callable only when the contract is redeemable.
     *
     * @dev Reverts when the contract is not yet redeemable.
     *
     * Requirements:
     * - The contract must be redeemable.
     */
    modifier whenRedeemable() {
        require(_redeemable, "whenRedeemable: not redeemable");
        _;
    }

    function redemptionReason() external view returns (string memory) {
        return _reason;
    }

    function redeemable() public view returns (bool) {
        return _redeemable;
    }

    //slither-disable-next-line naming-convention
    function __Redeemable_init() internal onlyInitializing {}

    /**
     * @dev Transitions redeemable from `false` to `true`.
     *
     * No affect if state is already transitioned.
     */
    function _setAsRedeemable(string calldata reason) internal {
        _redeemable = true;
        _reason = reason;
        emit RedeemableUpdate(true, reason, _msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @title Abstract upgradeable contract providing the ability to sweep tokens to a nominated beneficiary address.
 *
 * @dev Access control implementation is required for many functions by design.
 */
abstract contract TokenSweep is ContextUpgradeable {
    address private _beneficiary;

    event BeneficiaryUpdate(
        address indexed beneficiary,
        address indexed instigator
    );

    function tokenSweepBeneficiary() public view returns (address) {
        return _beneficiary;
    }

    //slither-disable-next-line naming-convention
    function __TokenSweep_init(address beneficiary) internal onlyInitializing {
        __Context_init();
        _setTokenSweepBeneficiary(beneficiary);
    }

    /**
     * @notice Sets the beneficiary of the token sweep.
     *
     * @dev Needs access control implemented in the inheriting contract.
     *
     * @param newBeneficiary The address to replace as the nominated beneficiary of any sweeping.
     */
    function _setTokenSweepBeneficiary(address newBeneficiary) internal {
        require(newBeneficiary != address(0), "TokenSweep: beneficiary zero");
        require(newBeneficiary != address(this), "TokenSweep: self address");
        require(newBeneficiary != _beneficiary, "TokenSweep: beneficiary same");

        _beneficiary = newBeneficiary;
        emit BeneficiaryUpdate(newBeneficiary, _msgSender());
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/**
 * @title Role based set membership.
 *
 * @notice Encapsulation of tracking, management and validation of role membership of addresses.
 *
 *  A role is a bytes32 value.
 *
 *  There are two distinct classes of roles:
 *  - Global; without scope limit.
 *  - Dao; membership scoped to that of the key (uint256).
 *
 * @dev Meaningful application of role membership is expected to come from derived contracts.
 *      e.g. access control.
 */
abstract contract RoleMembership is ContextUpgradeable {
    // DAOs to their roles to members; scoped to an individual DAO
    mapping(uint256 => mapping(bytes32 => mapping(address => bool)))
        private _daoRoleMembers;

    // Global roles to members; apply across all DAOs
    mapping(bytes32 => mapping(address => bool)) private _globalRoleMembers;

    event GrantDaoRole(
        uint256 indexed daoId,
        bytes32 indexed role,
        address account,
        address indexed instigator
    );
    event GrantGlobalRole(
        bytes32 indexedrole,
        address account,
        address indexed instigator
    );
    event RevokeDaoRole(
        uint256 indexed daoId,
        bytes32 indexed role,
        address account,
        address indexed instigator
    );
    event RevokeGlobalRole(
        bytes32 indexed role,
        address account,
        address indexed instigator
    );

    function hasGlobalRole(bytes32 role, address account)
        external
        view
        returns (bool)
    {
        return _globalRoleMembers[role][account];
    }

    function hasDaoRole(
        uint256 daoId,
        bytes32 role,
        address account
    ) external view returns (bool) {
        return _daoRoleMembers[daoId][role][account];
    }

    function _grantDaoRole(
        uint256 daoId,
        bytes32 role,
        address account
    ) internal {
        if (_hasDaoRole(daoId, role, account)) {
            revert(_revertMessageAlreadyHasDaoRole(daoId, role, account));
        }

        _daoRoleMembers[daoId][role][account] = true;
        emit GrantDaoRole(daoId, role, account, _msgSender());
    }

    function _grantGlobalRole(bytes32 role, address account) internal {
        if (_hasGlobalRole(role, account)) {
            revert(_revertMessageAlreadyHasGlobalRole(role, account));
        }

        _globalRoleMembers[role][account] = true;
        emit GrantGlobalRole(role, account, _msgSender());
    }

    function _revokeDaoRole(
        uint256 daoId,
        bytes32 role,
        address account
    ) internal {
        if (_isMissingDaoRole(daoId, role, account)) {
            revert(_revertMessageMissingDaoRole(daoId, role, account));
        }

        delete _daoRoleMembers[daoId][role][account];
        emit RevokeDaoRole(daoId, role, account, _msgSender());
    }

    function _revokeGlobalRole(bytes32 role, address account) internal {
        if (_isMissingGlobalRole(role, account)) {
            revert(_revertMessageMissingGlobalRole(role, account));
        }

        delete _globalRoleMembers[role][account];
        emit RevokeGlobalRole(role, account, _msgSender());
    }

    //slither-disable-next-line naming-convention
    function __RoleMembership_init() internal onlyInitializing {}

    function _hasDaoRole(
        uint256 daoId,
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return _daoRoleMembers[daoId][role][account];
    }

    function _hasGlobalRole(bytes32 role, address account)
        internal
        view
        returns (bool)
    {
        return _globalRoleMembers[role][account];
    }

    function _isMissingDaoRole(
        uint256 daoId,
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return !_daoRoleMembers[daoId][role][account];
    }

    function _isMissingGlobalRole(bytes32 role, address account)
        internal
        view
        returns (bool)
    {
        return !_globalRoleMembers[role][account];
    }

    /**
     * @dev Override for a custom revert message.
     */
    function _revertMessageAlreadyHasGlobalRole(bytes32 role, address account)
        internal
        view
        virtual
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "RoleMembership: account ",
                    StringsUpgradeable.toHexString(uint160(account), 20),
                    " already has role ",
                    StringsUpgradeable.toHexString(uint256(role), 32)
                )
            );
    }

    /**
     * @dev Override the function for a custom revert message.
     */
    function _revertMessageAlreadyHasDaoRole(
        uint256 daoId,
        bytes32 role,
        address account
    ) internal view virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "RoleMembership: account ",
                    StringsUpgradeable.toHexString(uint160(account), 20),
                    " already has role ",
                    StringsUpgradeable.toHexString(uint256(role), 32),
                    " in DAO ",
                    StringsUpgradeable.toHexString(daoId, 32)
                )
            );
    }

    /**
     * @dev Override the function for a custom revert message.
     */
    function _revertMessageMissingGlobalRole(bytes32 role, address account)
        internal
        view
        virtual
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "RoleMembership: account ",
                    StringsUpgradeable.toHexString(uint160(account), 20),
                    " is missing role ",
                    StringsUpgradeable.toHexString(uint256(role), 32)
                )
            );
    }

    /**
     * @dev Override the function for a custom revert message.
     */
    function _revertMessageMissingDaoRole(
        uint256 daoId,
        bytes32 role,
        address account
    ) internal view virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "RoleMembership: account ",
                    StringsUpgradeable.toHexString(uint160(account), 20),
                    " is missing role ",
                    StringsUpgradeable.toHexString(uint256(role), 32),
                    " in DAO ",
                    StringsUpgradeable.toHexString(daoId, 32)
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}