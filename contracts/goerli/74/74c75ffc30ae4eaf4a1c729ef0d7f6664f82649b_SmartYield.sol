// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {ClonesUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import {PausableUpgradeable} from "openzeppelin-contracts-upgradeable/security/PausableUpgradeable.sol";

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

import {ISmartYield} from "./interfaces/ISmartYield.sol";
import {IBond} from "./interfaces/IBond.sol";
import {IProvider} from "./interfaces/IProvider.sol";

/**
 * @title SmartYield
 * @author Plug
 * @notice SmartYield provide fixed income DeFi protocol
 **/
contract SmartYield is ISmartYield, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeERC20 for IERC20;

    struct TermInfo {
        uint256 start;
        uint256 end;
        uint256 feeRate;
        address nextTerm;
        address bond;
        uint256 realizedYield;
        uint256 depositCap;
        bool liquidated;
    }

    // Smart Yield Pool, each provide has a unique pool.
    struct Pool {

        // the underlying token
        address underlying;

        //  the balance as the liquidity provider
        uint256 liquidityProviderBalance;

        // keep track of the active term
        address activeTerm;

        // used as a safe barrier when borrow
        // 100 means the same threshold as aave, 110 means 110% health factor to stay safe
        uint256 healthFactorGuard;

        // id used for next debt
        uint256 nextDebtId;

        // information for each term
        mapping(address => TermInfo) bondData;

        // the list of all the debts
        mapping(uint256 => IProvider.Debt) debtData;
    }

    mapping(address => Pool) public poolByProvider;

    mapping(address => address) public providerByBond;

    // multisig on this chain representing the DAO
    address public controller;
    // vault contract to controll the funds
    address public vault;
    // the address for the bond token implementation
    address public bondTokenImpl;

    function setPaused(bool paused) external onlyController {
        if (paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    uint256 private constant SECONDS_IN_A_DAY = 1 days;
    // v3
    // event RewardsClaimed(address indexed user, address indexed to, address[] rewardsList, uint256[] claimedAmounts);
    // v2
    event RewardsClaimed(address indexed user, address indexed to, uint256 claimedAmounts);
    event BondIssued(address indexed owner, address indexed bond, uint256 amount);
    event BondRedeemed(address indexed owner, address indexed bond, uint256 amount);
    event BondRolledOver(
        address indexed owner,
        address indexed oldBond,
        address indexed newBond,
        uint256 oldAmount,
        uint256 newAmount
    );
    event AddLiquidity(address indexed owner, address indexed provider, uint256 providerBalance, uint256 amount);
    event RemoveLiquidity(address indexed owner, address indexed provider, uint256 providerBalance, uint256 amount);
    event InjectedRealizedYield(address indexed user, address indexed bond, TermInfo term);
    event TermSetUp(address indexed controller, address indexed bond, TermInfo currentTerm, TermInfo term);
    event PoolCreated(address indexed controller, address provider);
    event TermLiquidated(address indexed bond);
    event Borrowed(address indexed user, uint256 nextId, IProvider.Debt debt);
    event Repaied(address indexed user, uint256 debtId, IProvider.Debt debt);
    event Liquidated(address indexed user, uint256 debtId, IProvider.Debt debt);
    event DepositCapSet(address indexed bond, uint256 depositCap);

    modifier onlyController() {
        require(msg.sender == controller, "only controller");
        _;
    }

    modifier onlyVault() {
        require(msg.sender == vault, "only vault");
        _;
    }

    modifier defaultCheck(address _bond) {
        require(!paused(), "paused");
        require(providerByBond[_bond] != address(0), "invalid bond");
        _;
    }

    /**
     * @dev initialize the contract
     * @param _controller multisig on this chain representing the DAO
     * @param _bondTokenImpl the address of the reference implementation of the bond token
     */
    function initialize(address _controller, address _bondTokenImpl) external initializer {
        __ReentrancyGuard_init();
        __Pausable_init();
        controller = _controller;
        bondTokenImpl = _bondTokenImpl;
    }

    // view functions
    function getHealthFactor(address _bondProvider, uint256 _debtId)
        external
        view
        returns (uint256 healthFactor, uint256 compoundedBalance)
    {
        Pool storage pool = poolByProvider[_bondProvider];
        require(pool.underlying != address(0), "invalid provider");
        return IProvider(_bondProvider).computeHealthFactor(pool.debtData[_debtId]);
    }

    function getTermInfo(address _bond) external view returns (TermInfo memory termInfo) {
        require(providerByBond[_bond] != address(0), "invalid bond");
        address bondProvider = providerByBond[_bond];
        Pool storage pool = poolByProvider[bondProvider];
        termInfo = pool.bondData[_bond];
    }

    function underlying(address _bondProvider) external view returns (address) {
        Pool storage pool = poolByProvider[_bondProvider];
        require(pool.underlying != address(0), "invalid provider");
        return pool.underlying;
    }

    /**
     * @dev add liquidity
     * @param _tokenAmount the amount of the underlying token to add
     */
    function addLiquidity(address _bondProvider, uint256 _tokenAmount) external override onlyVault {
        require(_tokenAmount > 0, "Must be > 0");
        Pool storage pool = poolByProvider[_bondProvider];
        require(pool.underlying != address(0), "invalid provider");
        pool.liquidityProviderBalance = pool.liquidityProviderBalance + _tokenAmount;
        IERC20(pool.underlying).safeTransferFrom(msg.sender, address(this), _tokenAmount);
        IProvider(_bondProvider).deposit(_tokenAmount);
        emit AddLiquidity(msg.sender, _bondProvider, pool.liquidityProviderBalance, _tokenAmount);
    }

    // functions for the vault

    /**
     * @dev remove liquidity from the vault
     * @param _tokenAmount the amount of the underlying token to remove
     */
    function removeLiquidity(address _bondProvider, uint256 _tokenAmount) external override onlyVault {
        require(_tokenAmount > 0, "Amount must be > 0");
        Pool storage pool = poolByProvider[_bondProvider];
        require(pool.underlying != address(0), "invalid provider");
        pool.liquidityProviderBalance = pool.liquidityProviderBalance - _tokenAmount;
        uint256 balanceBefore = IERC20(pool.underlying).balanceOf(address(this));
        IProvider(_bondProvider).withdraw(_tokenAmount);
        uint256 balanceAfter = IERC20(pool.underlying).balanceOf(address(this));
        IERC20(pool.underlying).safeTransfer(msg.sender, balanceAfter - balanceBefore);
        emit RemoveLiquidity(msg.sender, _bondProvider, pool.liquidityProviderBalance, _tokenAmount);
    }

    /**
     * @dev provide extra realized yield from vault, especially for first term
     * @param _bond the address of the bond token, represents the key for the term we are adding realized yield
     * @param _tokenAmount the amount of the underlying taken from the vault
     */
    function provideRealizedYield(address _bond, uint256 _tokenAmount) external override onlyVault {
        require(_tokenAmount > 0, "Amount must be > 0");
        address bondProvider = providerByBond[_bond];
        Pool storage pool = poolByProvider[bondProvider];
        require(!pool.bondData[_bond].liquidated, "Term has been liquidated");
        IERC20(pool.underlying).safeTransferFrom(msg.sender, address(this), _tokenAmount);
        IProvider(bondProvider).deposit(_tokenAmount);
        pool.bondData[_bond].realizedYield = pool.bondData[_bond].realizedYield + _tokenAmount;
        emit InjectedRealizedYield(msg.sender, _bond, pool.bondData[_bond]);
    }

    // external functions

    /**
     * @dev issue a bond
     * @param _bond the address of bond token, represent the term user is buying
     * @param _tokenAmount the amount of the underlying token
     */
    function buyBond(address _bond, uint256 _tokenAmount) external override nonReentrant defaultCheck(_bond) {
        require(_tokenAmount > 0, "Amount must be > 0");
        
        address bondProvider = providerByBond[_bond];
        Pool storage pool = poolByProvider[bondProvider];
        TermInfo memory termInfo = pool.bondData[_bond];
        require(!termInfo.liquidated, "term is liquidated");
        require(termInfo.start > block.timestamp, "cannot buy now");
        require(IBond(_bond).totalSupply() + _tokenAmount <= termInfo.depositCap, "deposit cap reached");

        IERC20(pool.underlying).safeTransferFrom(msg.sender, address(this), _tokenAmount);
        IProvider(bondProvider).deposit(_tokenAmount);
        IBond(_bond).mint(msg.sender, _tokenAmount);
        emit BondIssued(msg.sender, _bond, _tokenAmount);
    }

    /**
     * @dev redeem a bond
     * @param _bond the address of bond token, represent the term user is redeeming
     * @param _tokenAmount the amount of the underlying token
     */
    function redeemBond(address _bond, uint256 _tokenAmount) external override nonReentrant defaultCheck(_bond) {
        address bondProvider = providerByBond[_bond];
        Pool storage pool = poolByProvider[bondProvider];
        require(_tokenAmount > 0, "Amount must be > 0");
        TermInfo memory termInfo = pool.bondData[_bond];
        require(termInfo.liquidated, "term is not liquidated");
        uint256 _totalRedeem = _redeem(bondProvider, _bond, _tokenAmount);
        uint256 balanceBefore = IERC20(pool.underlying).balanceOf(address(this));
        IProvider(bondProvider).withdraw(_totalRedeem);
        uint256 balanceAfter = IERC20(pool.underlying).balanceOf(address(this));
        IERC20(pool.underlying).safeTransfer(msg.sender, balanceAfter - balanceBefore);
        IBond(_bond).burn(msg.sender, _tokenAmount);
        emit BondRedeemed(msg.sender, _bond, _totalRedeem);
    }

    /**
     * @dev allow user to signal he would like to stay in the pool for the next term
     * @param _bond the address of bond token, represent the term user wants to roll over
     * @param _tokenAmount the amount of the underlying token
     */
    function rolloverBond(address _bond, uint256 _tokenAmount) external override nonReentrant defaultCheck(_bond) {
        require(_tokenAmount > 0, "Amount must be > 0");

        address bondProvider = providerByBond[_bond];
        Pool storage pool = poolByProvider[bondProvider];
        TermInfo memory termInfo = pool.bondData[_bond];
        address nextTerm = termInfo.nextTerm;
        require(block.timestamp > termInfo.start && block.timestamp < termInfo.end, "not valid timestamp");
        require(nextTerm != address(0), "nextTerm is not set");
        require(pool.activeTerm == _bond, "can only rollover an active term");
        
        TermInfo memory nextTermInfo = pool.bondData[nextTerm];
        require(block.timestamp < nextTermInfo.start, "next term has started");
        require(IBond(nextTerm).totalSupply() + _tokenAmount <= nextTermInfo.depositCap, "deposit cap reached");
        

        uint256 claimable = _redeem(bondProvider, _bond, _tokenAmount);
        IBond(_bond).burn(msg.sender, _tokenAmount);
        IBond(nextTerm).mintLocked(msg.sender, claimable);
        emit BondRolledOver(msg.sender, _bond, nextTerm, _tokenAmount, claimable);
    }

    /**
     * @dev allow user to borrow against his bond token, currently only considering stable coins only, assuming we are only borrowing against stable interest mode
     * @param _bond the address of bond token, represent the term user wants to borrow against
     * @param _bondAmount the amount of the bond used as collateral
     * @param _borrowAsset the asset to be borrowed
     * @param _borrowAmount the amount of the borrowed token
     */
    function borrow(
        address _bond,
        uint256 _bondAmount,
        address _borrowAsset,
        uint256 _borrowAmount
    ) external override nonReentrant defaultCheck(_bond) {
        address bondProvider = providerByBond[_bond];
        Pool storage pool = poolByProvider[bondProvider];
        require(((_bondAmount > 0) && (_borrowAmount > 0)), "invalid amount");
        require(pool.underlying != _borrowAsset, "invalid asset");
        uint256 healthFactor = IProvider(bondProvider).getHealthFactor();
        require(healthFactor > ((1e18 * pool.healthFactorGuard) / 100), "not healthy");
        uint256 borrowRate = IProvider(bondProvider).getBorrowRate(_borrowAsset);
        IProvider.Debt memory debt = IProvider.Debt(
            _borrowAsset,
            _borrowAmount,
            uint40(block.timestamp),
            borrowRate,
            _bond,
            _bondAmount,
            IProvider.DebtStatus.Active,
            msg.sender
        );
        (uint256 _newHealthFactor, ) = IProvider(bondProvider).computeLtv(debt);
        require(_newHealthFactor > 1e18, "proposed debt is not safe");
        pool.debtData[pool.nextDebtId] = debt;
        uint256 currentDebtId = pool.nextDebtId;
        pool.nextDebtId++;
        IERC20(_bond).safeTransferFrom(msg.sender, address(this), _bondAmount);
        IProvider(bondProvider).borrow(_borrowAsset, _borrowAmount);
        IERC20(_borrowAsset).safeTransfer(msg.sender, _borrowAmount);
        emit Borrowed(msg.sender, currentDebtId, debt);
    }

    /**
     * @dev allow user to fully repay against his debt, both princilple and interest
     * @param _debtId the id the debt to be repaid
     */
    function repay(address _bondProvider, uint256 _debtId) external override nonReentrant whenNotPaused {
        Pool storage pool = poolByProvider[_bondProvider];
        require(pool.underlying != address(0), "invalid provider");
        IProvider.Debt memory debt = pool.debtData[_debtId];
        require(debt.status == IProvider.DebtStatus.Active, "debt is not active");
        require(debt.borrower == msg.sender, "not the borrower");
        (, uint256 compoundBalance) = IProvider(_bondProvider).computeHealthFactor(debt);
        pool.debtData[_debtId].status = IProvider.DebtStatus.Finished;
        IERC20(debt.borrowAsset).safeTransferFrom(msg.sender, _bondProvider, compoundBalance);
        IProvider(_bondProvider).repay(debt.borrowAsset, compoundBalance);
        IERC20(debt.collateralBond).safeTransfer(msg.sender, debt.collateralAmount);
        emit Repaied(msg.sender, _debtId, pool.debtData[_debtId]);
    }

    /**
     * @dev allow user to liquidate unhealthy debt for others, i.e. repay for them, and transfer the collateral to the liquidator
     * @param _debtId the id the debt to be repaid
     */
    function liquidateDebt(address _bondProvider, uint256 _debtId) external override nonReentrant whenNotPaused {
        Pool storage pool = poolByProvider[_bondProvider];
        require(pool.underlying != address(0), "invalid provider");
        IProvider.Debt memory debt = pool.debtData[_debtId];
        require(debt.status == IProvider.DebtStatus.Active, "debt is not active");
        (uint256 healthFactor, uint256 compoundBalance) = IProvider(_bondProvider).computeHealthFactor(debt);
        require(healthFactor < 1e18, "debt is still healthy");
        pool.debtData[_debtId].status = IProvider.DebtStatus.Liquidated;
        IERC20(debt.borrowAsset).safeTransferFrom(msg.sender, _bondProvider, compoundBalance);
        IProvider(_bondProvider).repay(debt.borrowAsset, compoundBalance);
        IERC20(debt.collateralBond).safeTransfer(msg.sender, debt.collateralAmount);
        emit Liquidated(msg.sender, _debtId, pool.debtData[_debtId]);
    }

    /**
     * @dev calculate the yield for next term, ends current term, allow bond holders to claim their rewards
     * @param _bond the bond token address for the term
     */
    function liquidateTerm(address _bond) external nonReentrant defaultCheck(_bond) {
        address bondProvider = providerByBond[_bond];
        Pool storage pool = poolByProvider[bondProvider];
        require(pool.underlying != address(0), "invalid provider");
        TermInfo memory termInfo = pool.bondData[_bond];
        require(!termInfo.liquidated, "already liquidated");
        uint256 _end = termInfo.end;
        address nextTerm = termInfo.nextTerm;
        require(block.timestamp > _end, "not ended");
        IProvider(bondProvider).harvest();
        uint256 underlyingBalance_ = IProvider(bondProvider).underlyingBalance();
        uint256 _realizedYield = underlyingBalance_ - IProvider(bondProvider).totalUnRedeemed();
        IProvider(bondProvider).addTotalUnRedeemed(_realizedYield);
        if (nextTerm != address(0)) {
            pool.bondData[nextTerm].realizedYield = pool.bondData[nextTerm].realizedYield + _realizedYield;
            pool.activeTerm = nextTerm;
        } else {
            // if no more term is set up, then the yield goes to liqudity provider
            pool.liquidityProviderBalance = pool.liquidityProviderBalance + _realizedYield;
        }
        pool.bondData[_bond].liquidated = true;
        emit TermLiquidated(_bond);
    }

    // functions for the controller

    /**
     * @dev claim extra rewards
     * @param _to the address of the user to claim rewards to
     */
    function claimReward(address _bondProvider, address _to) external onlyController {
        IProvider(_bondProvider).claimRewardsTo(_to);
    }

    function setVault(address _vault) external onlyController {
        vault = _vault;
    }

    function setController(address _newController) external onlyController {
        controller = _newController;
    }

    function setHealthFactorGuard(address _bondProvider, uint256 _healthFactorGuard) external onlyController {
        Pool storage pool = poolByProvider[_bondProvider];
        pool.healthFactorGuard = _healthFactorGuard;
    }

    function createPool(
        address _bondProvider,
        uint256 _healthFactorGuard
    ) external onlyController {
        Pool storage pool = poolByProvider[_bondProvider];
        require(pool.underlying == address(0), "already created");
        pool.underlying = IProvider(_bondProvider).underlying();
        pool.nextDebtId = 1;
        pool.healthFactorGuard = _healthFactorGuard;
        _giveAllowances(pool.underlying, _bondProvider);
        emit PoolCreated(controller, _bondProvider);
    }

    /**
     * @dev set next term for a term, if the current term is address 0, means it is the first term
     * @param _start when should the term start
     * @param _termLength the length of the term in days
     * @param _feeRate the fee rate in this term, 50 means 0.5%
     * @param _currentTerm the bond token address for current term
     * @param _depositCap the max amount of deposits allowed in this term
     */
    function setNextTermFor(
        address _bondProvider,
        uint256 _start,
        uint16 _termLength,
        uint16 _feeRate,
        address _currentTerm,
        uint256 _depositCap
    ) external onlyController {
        Pool storage pool = poolByProvider[_bondProvider];
        require(pool.underlying != address(0), "invalid provider");
        require(_start > block.timestamp, "invalid start");
        if (_currentTerm != address(0)) {
            require(pool.bondData[_currentTerm].start > 0, "invalid current term");
        }
        uint256 _end = _start + _termLength * SECONDS_IN_A_DAY;
        address _bond = ClonesUpgradeable.clone(bondTokenImpl);
        IBond(_bond).initialize(pool.underlying, pool.bondData[_currentTerm].end);

        pool.bondData[_bond].start = _start;
        pool.bondData[_bond].end = _end;
        pool.bondData[_bond].feeRate = _feeRate;
        pool.bondData[_bond].bond = _bond;
        pool.bondData[_bond].depositCap = _depositCap;

        if (_currentTerm != address(0)) {
            pool.bondData[_currentTerm].nextTerm = _bond;
        } else {
            pool.activeTerm = _bond;
        }
        providerByBond[_bond] = _bondProvider;
        emit TermSetUp(controller, _bond, pool.bondData[_currentTerm], pool.bondData[_bond]);
    }

    function setDepositCap(address _bond, uint256 _depositCap) external onlyController {
        Pool storage pool = poolByProvider[providerByBond[_bond]];
        pool.bondData[_bond].depositCap = _depositCap;
        emit DepositCapSet(_bond, _depositCap);
    }

    /**
     * @dev enable the asset to be borrowed
     *      Only applicable to providers with borrow capability, such as aave
     * @param _asset the bond token address for the term
     */
    function enableBorrowAsset(address _bondProvider, address _asset) external onlyController {
        IProvider(_bondProvider).enableBorrowAsset(_asset);
    }

    /**
     * @dev disable the asset to be borrowed
     *      Only applicable to providers with borrow capability, such as aave
     * @param _asset the bond token address for the term
     */
    function disableBorrowAsset(address _bondProvider, address _asset) external onlyController {
        IProvider(_bondProvider).disableBorrowAsset(_asset);
    }

    /**
     * @dev controll whether provider is allowed to use the underlying as collateral
     *      Only applicable to providers with borrow capability, such as aave
     * @param _asset the bond token address for the term
     */
    function setUserUseReserveAsCollateral(
        address _bondProvider,
        address _asset,
        bool _useAsCollateral
    ) external onlyController {
        IProvider(_bondProvider).setUserUseReserveAsCollateral(_asset, _useAsCollateral);
    }

    // internal functions

    /**
     * @dev redeem the bond, state maintainance and calculation
     * @param _bond the bond token address for the term
     * @param _tokenAmount the amount of the bond
     * @return _totalRedeem_ the total amount we need to withdraw from provider
     */
    function _redeem(
        address _bondProvider,
        address _bond,
        uint256 _tokenAmount
    ) internal returns (uint256) {
        Pool storage pool = poolByProvider[_bondProvider];
        TermInfo memory termInfo = pool.bondData[_bond];
        uint256 rewards = (termInfo.realizedYield * _tokenAmount) / (IERC20(_bond).totalSupply());
        pool.bondData[_bond].realizedYield = pool.bondData[_bond].realizedYield - rewards;
        uint256 fee = (_tokenAmount * termInfo.feeRate) / 10000;
        uint256 totalRedeem_ = _tokenAmount + rewards - fee;
        pool.liquidityProviderBalance = pool.liquidityProviderBalance + fee;
        return totalRedeem_;
    }

    function _giveAllowances(address token, address provider) internal {
        IERC20(token).safeApprove(provider, 0);
        IERC20(token).safeApprove(provider, type(uint256).max);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "openzeppelin-contracts-upgradeable/interfaces/IERC20MetadataUpgradeable.sol";

interface IBond is IERC20MetadataUpgradeable {
    function initialize(address _underlying, uint256 _timestamp) external;

    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;

    function mintLocked(address to, uint256 amount) external;

    function freeBalanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IProvider {
    enum DebtStatus {
        Invalid,
        Active,
        Finished,
        Liquidated
    }

    struct Debt {
        address borrowAsset;
        uint256 borrowAmount;
        uint40 start;
        uint256 borrowRate;
        address collateralBond;
        uint256 collateralAmount;
        DebtStatus status;
        address borrower;
    }

    function smartYield() external view returns (address);

    function underlying() external view returns (address);

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function harvest() external;

    function underlyingBalance() external view returns (uint256);

    function claimRewardsTo(address to) external;

    function borrow(address borrowAsset, uint256 amount) external;

    function repay(address borrowAsset, uint256 amount) external payable;

    function enableBorrowAsset(address asset) external;

    function disableBorrowAsset(address asset) external;

    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    function totalUnRedeemed() external view returns (uint256);

    function addTotalUnRedeemed(uint256 amount) external;

    function computeHealthFactor(Debt memory debt) external view returns (uint256, uint256);

    function computeLtv(IProvider.Debt memory _debt) external view returns (uint256, uint256);

    function getBorrowRate(address asset) external view returns (uint256);

    function getHealthFactor() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;

interface ISmartYield {
    function underlying(address _bondProvider) external view returns (address);

    function providerByBond(address _bond) external view returns (address);

    function addLiquidity(address _bondProvider, uint256 tokenAmount_) external;

    function removeLiquidity(address _bondProvider, uint256 tokenAmount_) external;

    function provideRealizedYield(address bond_, uint256 tokenAmount_) external;

    function buyBond(address bond_, uint256 tokenAmount_) external;

    function redeemBond(address bond_, uint256 tokenAmount_) external;

    function rolloverBond(address bond_, uint256 tokenAmount_) external;

    function liquidateDebt(address _bondProvider, uint256 debtId) external;

    function repay(address _bondProvider, uint256 debtId) external;

    function borrow(
        address bond,
        uint256 bondAmount,
        address borrowAsset,
        uint256 borrowAmount
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

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
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
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
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
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
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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