// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.2;

import {IERC20PermitUpgradeable as IERC20Permit} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable as IERC20Metadata} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../interfaces/IMarket.sol";
import "../interfaces/IMarketPositionManagement.sol";
import "../interfaces/IBST.sol";
import "../interfaces/IClientMarketAdapter.sol";
import "../interfaces/IWETH9.sol";
import "../interfaces/IProtocolConfig.sol";
import "../interfaces/IIncentives.sol";
import "../interfaces/IState.sol";
import "../interfaces/ICalculation.sol";

import "../libraries/OptionFlagsHelper.sol";

import "../access/ModuleAccessController.sol";

import "hardhat/console.sol";

/// @notice Adapter providing a stable interface for connecting end-clients to market functions
contract ClientMarketAdapter is ModuleAccessController, IClientMarketAdapter {
    using OptionFlagsHelper for uint192;
    using SafeERC20 for IERC20;

    /// @notice protocol config contract
    IProtocolConfig public immutable config;

    /// @notice volatile asset token of a targeted market
    IERC20 public immutable asset;

    /// @notice stable token of a targeted market
    IERC20 public immutable stable;

    /// @notice stable precision
    uint public immutable DIVIDER_STABLE;

    /// @notice bump token
    IERC20 public immutable bump;

    /// @notice targeted market
    IMarket public immutable market;

    /// @notice bumper stable token
    IBST public immutable bst;

    /// @notice market bond contract
    IBond public immutable bond;

    /// @notice Protocol incentives calculation contract
    IIncentives public immutable incentives;

    /// @notice flag that controls whether position cancellation is available
    bool public cancellationPermitted;

    /// @notice flag that controls whether position abandonment is available
    bool public abandonmentPermitted;

    /// @notice minimal amount of asset that can be provided
    /// to open a position
    uint public minTakerPositionSize;

    /// @notice minimal amount of stable that can be provided
    /// to open a position
    uint public minMakerPositionSize;

    // market of the protocol that support native tokens
    address public immutable wrappedNativeMarket;

    /// @notice emits whenever {cancellationPermitted} changes
    /// @param permitted new {cancellationPermitted} value
    event CancellationPermit(bool permitted);

    /// @notice emits whenever {abandonmentPermitted} changes
    /// @param permitted new {abandonmentPermitted} value
    event AbandonmentPermit(bool permitted);

    /// @dev requires msg.sender to be an owner of a given taker position
    /// @param id taker position id
    modifier onlyTakerPositionOwner(uint id) {
        require(
            msg.sender ==
                IMarketPositionManagement(address(market)).takerPositionOwner(
                    id
                ),
            "CMA: not-taker-position-owner"
        );
        _;
    }

    /// @dev requires msg.sender to be an owner of a given taker position
    /// @param id maker position id
    modifier onlyMakerPositionOwner(uint id) {
        require(
            msg.sender ==
                IMarketPositionManagement(address(market)).makerPositionOwner(
                    id
                ),
            "CMA: not-maker-position-owner"
        );
        _;
    }

    /// @param _config protocol config contract address
    /// @param _stable stable token address of a {_market}
    /// @param _market market contract address
    /// @param _bst bumper stable token address
    /// @param _bond bond contract address of a {_market}
    /// @param _bump bump token address
    constructor(
        address _config,
        address _stable,
        address _market,
        address _bst,
        address _bond,
        address _incentives,
        address _bump
    ) ModuleAccessController(IProtocolConfig(_config).getGAC()) {

        require(_stable != address(0), "CMA: stable-token-address-zero");
        require(_market != address(0), "CMA: market-address-zero");
        require(_bst != address(0), "CMA: bst-address-zero");
        require(_bond != address(0), "CMA: bond-address-zero");
        require(_bump != address(0), "CMA: bump-token-address-zero");
        require(_incentives != address(0), "CMA: incentives-address-zero");

        config = IProtocolConfig(_config);
        stable = IERC20(_stable);
        market = IMarket(_market);
        asset = IMarket(_market).ASSET();
        bst = IBST(_bst);
        bond = IBond(_bond);
        incentives = IIncentives(_incentives);
        bump = IERC20(_bump);
        wrappedNativeMarket = IProtocolConfig(_config).getWrappedNativeMarket();

        DIVIDER_STABLE = (10**IERC20Metadata(_stable).decimals());
    }

    /// @inheritdoc IMakerPosition
    function depositWithPermitWithAutoBondingPermit(
        uint amount,
        uint16 tier,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        bytes memory permitStable,
        bytes memory permitBump
    ) external override returns (uint id) {
        _bumpBondPermit(bumpAmount, permitBump);

        (uint deadline, uint8 v, bytes32 r, bytes32 s) = _decodePermit(
            permitStable
        );

        return
            depositWithPermit(amount, tier, term, autorenew, deadline, v, r, s);
    }

    /// @inheritdoc ITakerPosition
    function protectWithPermitWithAutoBondingPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        bytes memory permitAsset,
        bytes memory permitBump
    ) external override returns (uint id) {
        _bumpBondPermit(bumpAmount, permitBump);

        (uint deadline, uint8 v, bytes32 r, bytes32 s) = _decodePermit(
            permitAsset
        );

        return
            protectWithPermit(amount, risk, term, autorenew, deadline, v, r, s);
    }

    /// @inheritdoc ITakerPosition
    function protectWithAutoBondingPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint id) {
        _bumpBondPermit(bumpAmount, deadline, v, r, s);
        return protect(amount, risk, term, autorenew);
    }

    /// @inheritdoc IMakerPosition
    function depositWithAutoBondingPermit(
        uint amount,
        uint16 tier,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint id) {
        _bumpBondPermit(bumpAmount, deadline, v, r, s);
        return deposit(amount, tier, term, autorenew);
    }

    /// @inheritdoc IMakerPosition
    function depositWithPermit(
        uint amount,
        uint16 tier,
        uint16 term,
        bool autorenew,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override returns (uint id) {
        IERC20Permit(address(stable)).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        return deposit(amount, tier, term, autorenew);
    }

    /// @inheritdoc ITakerPosition
    function protectWithPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override returns (uint id) {
        IERC20Permit(ASSET_ADDRESS()).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        return protect(amount, risk, term, autorenew);
    }

    /// @inheritdoc ITakerPosition
    function protect(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew
    ) public virtual override returns (uint) {

        // Verify supplied risk and term parameters (revert if it is not supported)
        ICalculation(market.getRiskCalc()).validateTakerPos(risk, term);            

        // Update market state
        IState(market.getState()).updateStateToCurrentTime();

        // apply incentives
        uint boostAmount = incentives.boostForTaker(address(asset), amount);
        uint incentivesAmount = incentives.coordinationForTaker(address(asset), amount);       

        // transfer token to market contract
        asset.safeTransferFrom(msg.sender, address(market), amount );

        // lock BUMP tokens using Bond contract
        (uint bumpAmount, , uint reduceAmount) = bond.autoLockBondTakerPosition(
            msg.sender,
            ASSET_ADDRESS(),
            amount,
            risk,
            term, 
            boostAmount,
            incentivesAmount
        );
        amount -= reduceAmount;
        require(amount >= minTakerPositionSize, "MB: below-taker-minsize");
 
        // open position and transfer tokens
        uint192 flags = OptionFlagsHelper.EMPTY.setAutorenew(autorenew);
        (uint id, uint floor) = market.protect(msg.sender, amount, reduceAmount, risk, term, bumpAmount, flags);

        emit Protect(
            msg.sender,
            id,
            amount,
            floor,
            risk,
            term,
            flags,
            bumpAmount,
            boostAmount,
            incentivesAmount
        );        

        return id;
    }

    /// @inheritdoc ITakerPosition
    function protectNative(
        uint16 risk,
        uint16 term,
        bool autorenew
    ) external payable virtual override returns (uint id) {
        require(
            address(market) == wrappedNativeMarket,
            "CMA: native-not-allowed"
        );
        
        // Verify supplied risk and term parameters (revert if it is not supported)
        ICalculation(market.getRiskCalc()).validateTakerPos(risk, term);            

        // Update market state
        IState(market.getState()).updateStateToCurrentTime();

        // open position and transfer tokens
        _wrapNativeAsset();

        // transfer token to market contract
        asset.safeTransfer(address(market), msg.value );

        uint amount = msg.value;
        // apply incentives
        uint boostAmount = incentives.boostForTaker(address(asset), amount);
        uint incentivesAmount = incentives.coordinationForTaker(address(asset), amount);        

        // lock BUMP tokens using Bond contract
        (uint bumpAmount, , uint reduceAmount) = bond.autoLockBondTakerPosition(
            msg.sender,
            ASSET_ADDRESS(),
            msg.value,
            risk,
            term,
            boostAmount,
            incentivesAmount      
        );
        amount -= reduceAmount;

        // check minimum position size
        require( amount >= minTakerPositionSize, "MB: below-taker-minsize");       
     
        uint192 flags = OptionFlagsHelper.EMPTY.setAutorenew(autorenew);

        // create taker position    
        uint floor;
        (id, floor) = market.protect(
            msg.sender, 
            amount, 
            reduceAmount, 
            risk, 
            term, 
            bumpAmount, 
            flags);   

        emit Protect(
            msg.sender,
            id,
            amount,
            floor,
            risk,
            term,
            flags,
            bumpAmount,
            boostAmount,
            incentivesAmount
        );    
    }

    /// @inheritdoc ITakerPosition
    function close(
        uint id,
        bool unwrap,
        bool withdrawBond
    ) external virtual override onlyTakerPositionOwner(id) {
        // Update market state
        IState(market.getState()).updateStateToCurrentTime();

        // get locked BUMP token amount for this position
        uint bumpAmount = market.getTakerPositionBond(id);        
        // unlock BUMP tokens
        if (bumpAmount > 0) {
            _withdrawBond(msg.sender, bumpAmount, withdrawBond);
        }
        // close position
        (uint premium, Payout memory payout) = market.close(msg.sender, id, unwrap, address(stable));

        emit Close(
            msg.sender,
            id,
            premium,
            payout.assetAmount,
            payout.stableAmount
        );        
    }

    /// @inheritdoc ITakerPosition
    function claim(uint id, bool withdrawBond)
        external
        virtual
        override
        onlyTakerPositionOwner(id)
    {
        // Update market state
        IState(market.getState()).updateStateToCurrentTime();

        // get locked BUMP token amount for this position
        uint bumpAmount = market.getTakerPosition(id).bumpAmount;
        // unlock BUMP tokens
        if (bumpAmount > 0) {
            _withdrawBond(msg.sender, bumpAmount, withdrawBond);
        }
        // claim position
        (uint floor, Payout memory payout) = market.claim(msg.sender, id, address(stable));

        emit Claim(
            msg.sender,
            id,
            floor,
            payout.assetAmount,
            payout.stableAmount
        );        
    }

    /// @inheritdoc ITakerPosition
    function cancel(
        uint id,
        bool unwrap
    ) external virtual override onlyTakerPositionOwner(id) {
        require(cancellationPermitted == true, "MB: cancellation-disabled");

        // Update market state
        IState(market.getState()).updateStateToCurrentTime();

        // liquidate bonds for this position
        uint bumpAmount = market.getTakerPositionBond(id);
        bond.liquidate(msg.sender, bumpAmount );

        // close position
        (uint premium, Payout memory payout) = market.cancel(msg.sender, id, unwrap, address(stable));

        emit Cancel(
            msg.sender,
            id,
            premium,
            payout.assetAmount,
            payout.stableAmount
        );        
    }

    /// @inheritdoc IMakerPosition
    function deposit(
        uint amount,
        uint16 tier,
        uint16 term,
        bool autorenew
    ) public virtual override returns (uint id) {
        // Verify supplied risk and term parameters (revert if it is not supported)
        ICalculation(market.getRiskCalc()).validateMakerPos(tier, term);            

        // Update market state
        IState(market.getState()).updateStateToCurrentTime();

        // convert stable to BST and mint it to market address
        uint bstAmount = (amount * (10**18)) / DIVIDER_STABLE;
        bst.mint(bstAmount, address(market));

        // apply incentives
        uint boostAmount = incentives.boostForMaker(address(asset), bstAmount);
        uint incentivesAmount = incentives.coordinationForMaker(address(asset), bstAmount);

        // lock BUMP tokens using Bond contract
        (uint bumpAmount, , uint reduceAmount) = bond.autoLockBondMakerPosition(
            msg.sender,
            address(asset),
            bstAmount,
            tier,
            term, 
            boostAmount,
            incentivesAmount
        );

        // user have to buy BUMP tokens on reduceAmount
        bstAmount -= reduceAmount;

        // check minimal position size
        require(bstAmount > minMakerPositionSize, "CMA: below-minsize");

        // transfer stable tokens to BST
        stable.safeTransferFrom(msg.sender, address(bst), amount);        
       
        uint192 flags = OptionFlagsHelper.EMPTY.setAutorenew(autorenew);
        // deposit tokens and open position
        id = market.deposit(
                msg.sender,
                bstAmount,
                reduceAmount,
                tier,
                term,
                bumpAmount,              
                flags
            );

        emit Deposit(
            msg.sender,
            id,
            amount,
            tier,
            term,
            flags,
            bumpAmount,
            boostAmount,
            incentivesAmount            
        );            
    }

    /// @inheritdoc IMakerPosition
    function withdraw(uint id, bool withdrawBond)
        external
        virtual
        override
        onlyMakerPositionOwner(id)
    {
        // Update market state
        IState(market.getState()).updateStateToCurrentTime();

        // get locked BUMP tokens for this position
        uint bumpAmount = market.getMakerPosition(id).bumpAmount;
        // unlock BUMP tokens using Bond contract
        if (bumpAmount > 0) {
            _withdrawBond(msg.sender, bumpAmount, withdrawBond);
        }

        (int yield, Payout memory payout) = market.withdraw(msg.sender, id, address(stable));

        emit Withdraw(
            msg.sender,
            id,
            yield,
            payout.assetAmount,
            payout.stableAmount
        );        
    }

    /// @inheritdoc IMakerPosition
    function abandon(uint id)
        external
        virtual
        override
        onlyMakerPositionOwner(id)
    {
        require(abandonmentPermitted == true, "CMA: abandonment-disabled");

        // Update market state
        IState(market.getState()).updateStateToCurrentTime();

        // liquidate bonds for this position
        uint bumpAmount = market.getMakerPositionBond(id);
        bond.liquidate(msg.sender, bumpAmount );

        // abandon position
        (int yield, Payout memory payout) = market.abandon(msg.sender, id, address(stable));

        emit Abandon(
            msg.sender,
            id,
            yield,
            payout.assetAmount,
            payout.stableAmount
        );        
    }

    /// @inheritdoc ITakerPosition
    function toggleTakerAutorenew(uint id)
        external
        virtual
        override
        onlyTakerPositionOwner(id)
    {
        (
            uint32 start,
            ,
            uint16 term,
            uint192 flags
        ) = IMarketPositionManagement(address(market)).takerPositionOptions(id);

        if (flags.getAutorenew()) {
            flags = flags.setAutorenew(false);
            uint8 terms = uint8((block.timestamp - start) / (term * 1 days) + 1);
            flags = flags.setAutorenewTerms( terms );

            IMarketPositionManagement(address(market)).setTakerPositionFlags(
                id,
                flags
            );
            
        } else {
            require(
                block.timestamp < start + term * 1 days,
                "CMA: term-has-elapsed"
            );
            flags = flags.setAutorenew(true);
            IMarketPositionManagement(address(market)).setTakerPositionFlags(
                id,
                flags
            );
        }
    }

    /// @inheritdoc IMakerPosition
    function toggleMakerAutorenew(uint id)
        external
        virtual
        override
        onlyMakerPositionOwner(id)
    {
        (
            uint32 start,
            ,
            uint16 term,
            uint192 flags
        ) = IMarketPositionManagement(address(market)).makerPositionOptions(id);

        if (flags.getAutorenew()) {
            flags = flags.setAutorenew(false);
            uint8 terms = uint8((block.timestamp - start) / (term * 1 days) + 1);
            flags = flags.setAutorenewTerms( terms );

            IMarketPositionManagement(address(market)).setMakerPositionFlags(
                id,
                flags
            );
        } else {
            require(
                block.timestamp < start + term * 1 days,
                "CMA: term-has-elapsed"
            );
            flags = flags.setAutorenew(true);
            IMarketPositionManagement(address(market)).setMakerPositionFlags(
                id,
                flags
            );
        }
    }

    /// @inheritdoc IClientMarketAdapter
    function ASSET_ADDRESS() public view override returns (address) {
        return address(asset);
    }

    /// @inheritdoc IClientMarketAdapter
    function STABLE_ADDRESS() public view override returns (address) {
        return address(stable);
    }

    /// @inheritdoc ITakerPosition
    function getTakerPosition(uint id)
        public
        view
        override
        returns (TakerPosition memory)
    {
        return market.getTakerPosition(id);
    }

    /// @inheritdoc IMakerPosition
    function getMakerPosition(uint id)
        public
        view
        override
        returns (MakerPosition memory)
    {
        return market.getMakerPosition(id);
    }

    /// @notice sets minimal position sizes for taker and maker positions
    function setMinPositionSize(uint minMaker, uint minTaker)
        external
        onlyGovernance
    {
        minTakerPositionSize = minTaker;
        minMakerPositionSize = minMaker;
    }

    /// @notice toggles taker cancellation functionality
    function toggleCancellation() external onlyGovernance {
        cancellationPermitted = !cancellationPermitted;
        emit CancellationPermit(cancellationPermitted);
    }

    /// @notice toggles maker abandonment functionality
    function toggleAbandonment() external onlyGovernance {
        abandonmentPermitted = !abandonmentPermitted;
        emit AbandonmentPermit(abandonmentPermitted);
    }

    /// @notice Check if the given position can be liquidated
    function canEject(uint id) external view override returns (bool) {
        MakerPosition memory pos = market.getMakerPosition(id);
        int yield = market.yieldOnWithdraw(id);
        return (yield + int(pos.stableAmount)) <= 0;
    }

    /// @notice Liquidate position that has premium equal to position size
    function ejectR(uint id) external override {
        MakerPosition memory pos = market.getMakerPosition(id);
        int yield = market.yieldOnWithdraw(id);
        require((yield + int(pos.stableAmount)) <= 0, "CMA: cant-liquidate");
        // liquidate bonds
        bond.liquidate(pos.owner, pos.bumpAmount );
        // liquidate position using withdraw function (close automaticaly liquidates position with yield >= stableAmount)
        market.withdraw(msg.sender, id, address(stable));
        
    }

    /// @notice withdraw tokens
    function govWithdraw(address token, address to, uint amount ) external onlyGovernance {
        IERC20(token).transfer(to, amount);
    } 

    /// @dev bump permitting using raw permit values
    function _bumpBondPermit(
        uint amount,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        IERC20Permit(address(bump)).permit(
            msg.sender,
            address(bond),
            amount,
            deadline,
            v,
            r,
            s
        );
    }

    /// @dev bump permitting using encoded permit value
    function _bumpBondPermit(uint amount, bytes memory permitBump) internal {
        (uint deadline, uint8 v, bytes32 r, bytes32 s) = _decodePermit(
            permitBump
        );
        _bumpBondPermit(amount, deadline, v, r, s);
    }

    /// @dev decodes encoded permit values
    function _decodePermit(bytes memory permitEncoded)
        private
        pure
        returns (
            uint deadline,
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        (deadline, v, r, s) = abi.decode(
            permitEncoded,
            (uint, uint8, bytes32, bytes32)
        );
    }

    /// @dev unlock and withdraw bump bond from market bond contract
    function _withdrawBond(
        address user,
        uint bondAmount,
        bool withdrawBond
    ) internal {
        bond.unlock(user, bondAmount);
        if (withdrawBond) {
            bond.withdrawFrom(user, bondAmount);
        }
    }

    /// @dev wraps native token
    function _wrapNativeAsset() internal {
        IWETH9(address(asset)).deposit{value: msg.value}();
    }

    /// @dev unwraps native token
    function _unwrapToNativeToken(uint amount) internal {
        IWETH9(address(asset)).withdraw(amount);
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable as IERC20Metadata} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../struct/TakerPosition.sol";
import "../struct/MakerPosition.sol";
import "../struct/UserPositions.sol";
import "../struct/Payout.sol";

import "./IMakerPosition.sol";
import "./ITakerPosition.sol";
import "./IBond.sol";

interface IMarket {
    /// @notice opens a new taker position
    /// @param account initial position owner
    /// @param amount asset amount to protect
    /// @param risk position risk value
    /// @param term position term value
    /// @param bumpAmount bump amount to lock as a bond in the position
    /// @param flags packed position flags
    /// @return id created position id
    /// @dev allowed values of {risk} and {term} are depends of a particular
    /// market and a {Calculation} contract that is uses
    function protect(
        address account,
        uint amount,
        uint toTreasury,
        uint16 risk,
        uint16 term,
        uint bumpAmount,
        uint192 flags
    ) external returns (uint id, uint floor);

    /// @notice closes an existing taker position
    /// @notice position can be closed only if position term is over
    /// @param account position owner
    /// @param id taker position id
    /// @param unwrap if market is a wrapped native, this flag is says that asset should be
    /// unwrapped to native or it should be returned as a wrapped native
    /// @param stable stable token address to make payout in
    function close(
        address account,
        uint id,
        bool unwrap,
        address stable
    ) external returns (uint premium, Payout memory payout);

    /// @notice closes an existing taker position and claims stable
    /// @notice position can be closed only if position term is over
    /// @param account position owner
    /// @param id taker position id
    /// @param stable stable token address to make payout in
    function claim(
        address account,
        uint id,
        address stable
    ) external returns (uint premium, Payout memory payout);

    /// @notice cancel existing taker position
    /// @notice position can be canceled even if position term is not over
    /// @param account position owner
    /// @param id taker position id
    /// @param unwrap if market is a wrapped native, this flag is says that asset should be
    /// unwrapped to native or it should be returned as a wrapped native
    /// @param stable stable token address to make payout in
    function cancel(
        address account,
        uint id,
        bool unwrap,
        address stable
    ) external returns (uint premium, Payout memory payout);

    /// @notice opens a new maker position
    /// @param account initial position owner
    /// @param amount asset amount to protect
    /// @param risk position risk value
    /// @param term position term value
    /// @param bumpAmount bump amount to lock as a bond in the position
    /// @param flags packed position flags
    /// @return id created position id
    /// @dev allowed values of {risk} and {term} are depends of a particular
    /// market and a {Calculation} contract that is uses
    function deposit(
        address account,
        uint amount,
        uint toTreasury,
        uint16 risk,
        uint16 term,
        uint bumpAmount,
        uint192 flags
    ) external returns (uint id);

    /// @notice closes an existing maker position and claim yield
    /// @notice position can be closed only if position term is over
    /// @param account initial position owner
    /// @param id existing position id
    /// @param stable stable token address to make payout in
    function withdraw(
        address account,
        uint id,
        address stable
    ) external returns (int yield, Payout memory payout);

    /// @notice Allows a Maker to terminate their position before the end of the fixed term.
    /// @notice Comes with forfeiture of positive yield and an early termination penalty.
    /// @param account initial position owner
    /// @param id existing position id
    /// @param stable stable token address to make payout in
    function abandon(
        address account,
        uint id,
        address stable
    ) external returns (int yield, Payout memory payout);

    function setUserProfile(address account, uint profile) external;

    /// @notice Asset token address
    /// @return Asset token
    function ASSET() external pure returns (IERC20);

    /// @notice Stable token address
    /// @return Stable token
    function STABLE() external view returns (IERC20);

    /// @return risk calculation contract address
    function getRiskCalc() external view returns (address);

    /// @return market state contract address
    function getState() external view returns (address);

    /// @notice Get all Taker`s positions
    /// @param taker taker address
    /// @return array of ids of all taker`s positions
    function getTakerPositions(address taker)
        external
        view
        returns (uint[] memory);

    /// @notice Get all Maker`s positions
    /// @param maker maker address
    /// @return array of ids of all maker`s positions
    function getMakerPositions(address maker)
        external
        view
        returns (uint[] memory);

    /// @notice Get Taker position by position id
    /// @param id position id
    /// @return position struct
    function getTakerPosition(uint id)
        external
        view
        returns (TakerPosition memory);

    /// @notice Get Maker position by position id
    /// @param id position id
    /// @return position struct
    function getMakerPosition(uint id)
        external
        view
        returns (MakerPosition memory);

    /// @notice Get locked bond amount for Taker position
    /// @param id position id
    /// @return locked bond amount
    function getTakerPositionBond(uint id) external view returns (uint);

    /// @notice Get locked bond amount for Maker position
    /// @param id position id
    /// @return locked bond amount
    function getMakerPositionBond(uint id) external view returns (uint);

    function getUserProfile(address account) external view returns (uint);

    // function liquidateZeroTakerPosition(address account, uint id) external;
    // function liquidateZeroMakerPosition(address account, uint id) external;
    // calculate premium
    function premiumOnClose(uint id) external view returns (uint);

    function premiumOnClaim(uint id) external view returns (uint);

    function premiumOnCancel(uint id) external view returns (uint);

    // calculate yield
    function yieldOnWithdraw(uint id) external view returns (int);

    function yieldOnAbandon(uint id) external view returns (int);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../struct/TakerPosition.sol";
import "../struct/MakerPosition.sol";

interface IMarketPositionManagement {
    /// @notice Transfer Taker position from one owner to another
    /// @param from - current owner of the position NFT
    /// @param to - new owner of the position NFT
    /// @param id - position id
    function safeTransferTakerPosition(
        address from,
        address to,
        uint id
    ) external;

    /// @notice Transfer Maker position from one owner to another
    /// @param from - current owner of the position NFT
    /// @param to - new owner of the position NFT
    /// @param id - id of a maker position
    function safeTransferMakerPosition(
        address from,
        address to,
        uint id
    ) external;

    /// @notice updates existing Taker position
    /// @param id position id
    /// @param pos position data struct
    function updateTakerPosition(uint id, TakerPosition calldata pos) external;

    /// @notice updates existing Maker position
    /// @param id position id
    /// @param pos position data struct
    function updateMakerPosition(uint id, MakerPosition calldata pos) external;

    /// @notice creates new Taker position
    /// @param pos position data struct
    function newTakerPositon(TakerPosition calldata pos)
        external
        returns (uint newId);

    /// @notice creates new Maker position
    /// @param pos position data struct
    function newMakerPositon(MakerPosition calldata pos)
        external
        returns (uint newId);

    /// @notice set flags for an existing Taker position
    /// @param id position id
    /// @param flags position flags
    function setTakerPositionFlags(uint id, uint192 flags) external;

    /// @notice set flags for an existing Maker position
    /// @param id position id
    /// @param flags position flags
    function setMakerPositionFlags(uint id, uint192 flags) external;

    /// @notice Check if given Taker position is exists
    /// @param id position id
    /// @return exists or not exists
    function existsTakerPosition(uint id) external view returns (bool);

    /// @notice Check if given Maker position is exists
    /// @param id position id
    /// @return exists or not exists
    function existsMakerPosition(uint id) external view returns (bool);

    /// @notice Get owner of Taker position
    /// @param id position id
    /// @return owner of a given position id
    function takerPositionOwner(uint id) external view returns (address);

    /// @notice Get owner of Maker position
    /// @param id position id
    /// @return owner of a given position id
    function makerPositionOwner(uint id) external view returns (address);

    /// @notice Get only options from Taker position
    /// @param id position id
    /// @return start position start timestamp
    /// @return risk position risk
    /// @return term position term
    /// @return flags position flags
    function takerPositionOptions(uint id)
        external
        view
        returns (
            uint32 start,
            uint16 risk,
            uint16 term,
            uint192 flags
        );

    /// @notice Get only options from Maker position
    /// @param id position id
    /// @return start position start timestamp
    /// @return risk position risk
    /// @return term position term
    /// @return flags position flags
    function makerPositionOptions(uint id)
        external
        view
        returns (
            uint32 start,
            uint16 risk,
            uint16 term,
            uint192 flags
        );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @title IBST
interface IBST {
    function mint(uint amount, address mintTo) external;

    function withdraw(
        address stable,
        uint amount,
        address burnFrom,
        address to
    ) external;

    function swapTo(
        address stable,
        uint amountInBST
    ) external;   
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/ITakerPosition.sol";
import "../interfaces/IMakerPosition.sol";
import "../interfaces/IBond.sol";

interface IClientMarketAdapter is ITakerPosition, IMakerPosition {
    /// @return addr address of market asset token
    function ASSET_ADDRESS() external view returns (address);

    /// @return addr address of adapter stable token
    function STABLE_ADDRESS() external view returns (address);

    /// @return true if the given position can be liquidated
    function canEject(uint id) external view returns (bool);

    /// @notice Liquidate position that has yield equal or more then position size
    function ejectR(uint id) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint _amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

/// @notice Interface for accessing protocol configuration parameters
interface IProtocolConfig {
    /// @notice get Global access controller
    function getGAC() external view returns (address);

    /// @notice Version of the protocol
    function getVersion() external view returns (uint16);

    /// @notice Stable coin address
    function getStable() external view returns (address);

    /// @notice Get address of NFT maker for given market
    function getNFTMaker(address token) external view returns (address);

    /// @notice Get address of NFT taker for given market
    function getNFTTaker(address token) external view returns (address);

    /// @notice Get address of B-token for given market
    function getBToken(address token) external view returns (address);

    /// @notice Get market contract address by token address
    function getMarket(address token) external view returns (address);

    /// @notice Get supported assets array 
    function getAssets()
        external
        view
        returns (address[] memory);

    /// @notice Get wrapped native market address
    function getWrappedNativeMarket() external view returns (address);

    /// @notice Get wrapped native token address
    function getWrappedNativeToken() external view returns (address);    

    /// @notice Get rebalancer contract address
    function getRebalancer() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @title IIncentives
interface IIncentives {
    /// @notice calculates boost fot taker position
    /// @param token address of market asset token
    /// @param amount address of market asset token
    /// @return boost value
    function boostForTaker(address token, uint amount)
        external
        view
        returns (uint);

    /// @notice calculates boost fot maker position
    /// @param token address of market asset token
    /// @param amount address of market asset token
    /// @return boost value
    function boostForMaker(address token, uint amount)
        external
        view
        returns (uint);

    /// @notice calculates incentive fot taker position
    /// @param token address of market asset token
    /// @param amount address of market asset token
    /// @return incentive value
    function coordinationForTaker(address token, uint amount)
        external
        view
        returns (uint);

    /// @notice calculates incentive fot maker position
    /// @param token address of market asset token
    /// @param amount address of market asset token
    /// @return incentive value
    function coordinationForMaker(address token, uint amount)
        external
        view
        returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../struct/TakerPosition.sol";
import "../struct/MakerPosition.sol";
import "../struct/MarketState.sol";
import "../struct/Payout.sol";

interface IState {
    /// @return current asset Pool value
    function AP() external view returns (uint);

    /// @return current asset Reserve value
    function AR() external view returns (uint);

    /// @return current book value
    function B() external view returns (uint);

    /// @return current liability value in price oracle precision
    function L() external view returns (uint);

    /// @return current capital Pool value
    function CP() external view returns (uint);

    /// @return current capital Reserve value
    function CR() external view returns (uint);

    /// @return current debt value
    function D() external view returns (uint);

    /// @return current yield target value
    function E() external view returns (uint);

    /// @return current risk weighted asset pool value
    function RWA() external view returns (uint);

    /// @return current risk weighted liability value
    function RWL() external view returns (uint);

    /// @return current risk weighted capital value with positive rate
    function RWCp() external view returns (uint);

    /// @return current risk weighted capital value with negative rate
    function RWCn() external view returns (uint);

    /// @notice current calculated probability of claim for lastPrice
    function probabilityOfClaim() external view returns (uint);

    /// @notice create new taker position state callback
    /// @param assetAmount amount of asset token
    /// @param risk position risk value
    /// @param term position term value
    /// @param floor position floor value
    function newTakerPosition(
        uint assetAmount,
        uint16 risk,
        uint16 term,
        uint floor
    ) external;

    /// @notice create taker position state callback
    /// @param assetAmount amount of asset token
    /// @param risk position risk value
    /// @param term position term value
    /// @param floor position floor value
    /// @param payout payout stuct value
    function closeTakerPosition(
        uint assetAmount,
        uint16 risk,
        uint16 term,
        uint floor,
        uint premium,
        Payout calldata payout
    ) external;

    /// @notice claim on taker position state callback
    /// @param assetAmount amount of asset token
    /// @param risk position risk value
    /// @param term position term value
    /// @param floor position floor value
    /// @param payout payout stuct value
    function claimTakerPosition(
        uint assetAmount,
        uint16 risk,
        uint16 term,
        uint floor,
        uint premium,
        Payout calldata payout
    ) external;

    /// @notice create new maker position state callback
    /// @param stableAmount amount of stable token
    /// @param tier position tier value
    /// @param term position term value
    function newMakerPosition(
        uint stableAmount,
        uint16 tier,
        uint16 term
    ) external;

    /// @notice close maker position state callback
    /// @param stableAmount amount of stable token
    /// @param tier position tier value
    /// @param term position term value
    /// @param yield position yield value
    /// @param payout payout stuct value
    function closeMakerPosition(
        uint stableAmount,
        uint16 tier,
        uint16 term,
        int yield,
        Payout calldata payout
    ) external;

    /// @notice returns asset information from a price feed
    /// @return _price current asset price
    /// @return _updatedAt price updated at timestamp
    /// @return _roundId latest price update id
    function price()
        external
        view
        returns (
            int _price,
            uint _updatedAt,
            uint80 _roundId
        );

    /// @notice returns last used price information
    /// @return _price last used asset price
    /// @return _updatedAt last used price updated at timestamp
    /// @return _roundId last used price update id
    function lastUsedPrice()
        external
        view
        returns (
            int _price,
            uint _updatedAt,
            uint80 _roundId
        );

    /// @notice returns price info by roundId used price information
    /// @param roundId price update round id
    /// @return _price price by a given round id
    /// @return _updatedAt price updated at by a given round id
    function priceAt(uint80 roundId)
        external
        view
        returns (int _price, uint _updatedAt);

    /// @notice updates state veriable by a given delta values
    /// @param deltaAP delta Asset Pool value
    /// @param deltaAR delta Asset Reserve value
    /// @param deltaCP delta Capital Pool value
    /// @param deltaCR delta Capital Reserve value
    /// @param deltaY delta Yeld target value
    function update(
        int deltaAP,
        int deltaAR,
        int deltaCP,
        int deltaCR,
        int deltaY
    ) external;

    /// @notice updates state variables to current time
    function updateStateToCurrentTime() external;

    /// @notice updates state variables to last price
    function updateStateToLastPrice() external;

    /// @return state variables as a struct
    function getStateAsStruct() external view returns (MarketState memory);

    /// @notice returns state variables by a single function call
    function getState()
        external
        view
        returns (
            uint AP,
            uint AR,
            uint CP,
            uint CR,
            uint B,
            uint L,
            uint D,
            uint Y
        );

    /// @notice set a rebalancer contract address
    /// @param _rebalancer new rebalancer address
    function setRebalancer(address _rebalancer) external;

    /// @notice set a risk calculation contract address
    /// @param _calc new risk calculation address
    function setRiskCalc(address _calc) external;

    /// @notice calculates a cumulative index for taker
    /// @return cia cummulative index (in assets)
    /// @return cis cummulative index (in stables)
    function calcCI()
        external
        view
        returns (
            uint cia,
            uint cis
        );

    function ciTakerAsset() external view returns (uint);

    function ciTakerStable() external view returns (uint);

    function ciMaker() external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IRebalanceCalculation.sol";
import "./IRiskCalculation.sol";

interface ICalculation is IRebalanceCalculation, IRiskCalculation {
    function validateMakerPos(uint16 risk, uint16 term) external pure;

    function validateTakerPos(uint16 risk, uint16 term) external pure;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

library OptionFlagsHelper {
    uint192 internal constant EMPTY = 0;

    uint192 private constant AUTORENEW_OFFSET = 0;
    uint192 private constant AUTORENEW_MASK = uint192(1) << AUTORENEW_OFFSET; // size 1

    uint192 private constant AUTORENEW_TERMS_OFFSET = 1;
    uint192 private constant AUTORENEW_TERMS_MASK = uint192(0xFF) << AUTORENEW_TERMS_OFFSET; //size 8

    uint192 private constant FLAG2_OFFSET = 9;
    uint192 private constant FLAG2_MASK = uint192(1) << FLAG2_OFFSET; // size 1

    function getAutorenew(uint192 flags) internal pure returns (bool) {
        return (flags & AUTORENEW_MASK) > 0;
    }

    function setAutorenew(uint192 flags, bool autorenew)
        internal
        pure
        returns (uint192)
    {
        if (autorenew) {
            return flags | AUTORENEW_MASK;
        } else {
            return flags & (~AUTORENEW_MASK);
        }
    }

    function getAutorenewTerms(uint192 flags) internal pure returns (uint8 terms) {
        terms =  uint8((flags & AUTORENEW_TERMS_MASK) >> AUTORENEW_TERMS_OFFSET);
        return terms > 0 ? terms : 1;
    }

    function setAutorenewTerms(uint192 flags, uint8 value)
        internal
        pure
        returns (uint192)
    {        
        return (flags & ~AUTORENEW_TERMS_MASK) | (uint192(value) << AUTORENEW_TERMS_OFFSET);
    }

    function getFlag2(uint192 flags) internal pure returns (bool) {
        return (flags & FLAG2_MASK) > 0;
    }

    function setFlag2(uint192 flags, bool autorenew)
        internal
        pure
        returns (uint192)
    {
        if (autorenew) {
            return flags | FLAG2_MASK;
        } else {
            return flags & (~FLAG2_MASK);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IGlobalAccessControl.sol";

/// @notice Module Access Controller (MAC)
/// @notice Inherit this to provide access control functions.
abstract contract ModuleAccessController is AccessControl {
    /// @dev contract-owned role, stored in AccessControl
    bytes32 public constant LOCAL_GOVERNANCE_ROLE =
        keccak256("LOCAL_GOVERNANCE_ROLE");

    /// @dev protocol-owned role, stored in GlobalAccessController
    bytes32 public constant GLOBAL_GOVERNANCE_ROLE =
        keccak256("GLOBAL_GOVERNANCE_ROLE");

    /// @dev GlobalAccessController instance reference
    IGlobalAccessControl public gac;

    /// @param _gac GlobalAccessController address
    constructor(address _gac) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setGlobalAccessController(_gac);
    }

    /// @dev requires msg.sender to have DEFAULT_ADMIN_ROLE
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "MAC: not-Admin");
        _;
    }

    /// @dev requires msg.sender to have either a LOCAL_GOVERNANCE_ROLE or a GLOBAL_GOVERNANCE_ROLE or both
    modifier onlyGovernance() {
        require(
            hasRole(LOCAL_GOVERNANCE_ROLE, msg.sender) ||
                gac.userHasRole(GLOBAL_GOVERNANCE_ROLE, msg.sender),
            "MAC: not-Governance"
        );
        _;
    }

    /// @dev requires msg.sender to have a LOCAL_GOVERNANCE_ROLE
    modifier onlyLocalGovernance() {
        require(
            hasRole(LOCAL_GOVERNANCE_ROLE, msg.sender),
            "MAC: not-localGov"
        );
        _;
    }

    /// @dev requires msg.sender to have a GLOBAL_GOVERNANCE_ROLE
    modifier onlyGlobalGovernance() {
        require(
            gac.userHasRole(gac.GLOBAL_GOVERNANCE_ROLE(), msg.sender),
            "MAC: not-globalGov"
        );
        _;
    }

    /// @dev requires msg.sender to have a GLOBAL_KEEPER_ROLE
    modifier onlyKeeper() {
        require(
            gac.userHasRole(gac.GLOBAL_KEEPER_ROLE(), msg.sender),
            "MAC: not-keeper"
        );
        _;
    }


    /// @notice store external global access controller address to check access using global permission storage
    function _setGlobalAccessController(address _gac) internal {
        gac = IGlobalAccessControl(_gac);
    }

    /// @notice grants a given role to a given account
    /// @notice can be called only from address with a DEFAULT_ADMIN_ROLE
    /// @dev same as {_grantRole}
    function grantRole(bytes32 role, address account)
        public
        override
        onlyAdmin
    {
        _grantRole(role, account);
    }

    /// @notice revokes a given role from a given account
    /// @notice can be called only from address with a DEFAULT_ADMIN_ROLE
    /// @dev same as {_revokeRole}
    function revokeRole(bytes32 role, address account)
        public
        override
        onlyAdmin
    {
        _revokeRole(role, account);
    }

    /// @notice returns is a user has a role on a GlobalAccessController
    function userHasRole(bytes32 role, address account)
        public
        view
        returns (bool)
    {
        return gac.userHasRole(role, account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @notice Taker position representation structure
struct TakerPosition {
    address owner; // owner of the position
    uint assetAmount; // amount of tokens
    uint floor; // floor price of the protected tokens
    uint bumpAmount; // locked bump amount for this position
    uint ci; // start position cummulative index
    uint32 start; // timestamp when position was opened
    uint16 risk; // risk in percentage with 100 multiplier (9000 means 90%)
    uint16 term; // term (in days) of protection
    uint192 flags; // option flags
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @notice Maker position representaion structure
struct MakerPosition {
    address owner; // owner of the position
    uint stableAmount; // amount of stable tokens
    uint bumpAmount; // locked bump amount for this position
    uint ci; // start position cummulative index
    uint32 start; // CI when position was opened
    uint16 term; // term (in days) of protection
    uint16 tier; // tier number (1-5)
    uint192 flags; // option flags
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

struct UserPositions {
    EnumerableSet.UintSet taker;
    EnumerableSet.UintSet maker;
    uint profile;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @notice Maker position representaion structure
struct Payout {
    //uint bumpAmount;
    uint assetAmount;
    uint stableAmount;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../struct/MakerPosition.sol";

interface IMakerPosition {
    /// @notice creates a new maker position
    /// @notice takes part of an {amount} to lock as a bond
    /// if deposited bond amount is insufficient
    /// @param amount asset amount to protect
    /// @param tier position tier value
    /// @param term position term value
    /// @param autorenew whether position auto renewing is available
    /// or it`s not
    /// @return id created position id
    /// @dev allowed values of {tier} and {term} are depends of a particular
    /// market and a {Calculation} contract that is uses
    function deposit(
        uint amount,
        uint16 tier,
        uint16 term,
        bool autorenew
    ) external returns (uint id);

    /// @notice protect with bump bond permit only
    /// @notice See more in {deposit}
    function depositWithAutoBondingPermit(
        uint amount,
        uint16 tier,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint id);

    /// @notice deposit with both stable and bump bond permits
    /// @notice See more in {depositWithPermit}
    /// @param permitStable encoded [deadline, v, r, s] values for stable permit using abi.encode
    /// @param permitBump encoded [deadline, v, r, s] values for bump permit using abi.encode
    function depositWithPermitWithAutoBondingPermit(
        uint amount,
        uint16 tier,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        bytes memory permitStable,
        bytes memory permitBump
    ) external returns (uint id);

    /// @notice deposit with stable token permit only
    /// @notice See more in {deposit}
    function depositWithPermit(
        uint amount,
        uint16 tier,
        uint16 term,
        bool autorenew,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint id);

    /// @notice closes an existing maker position and claim yield
    /// @notice position can be closed only if position term is over
    /// @param id existing position id
    /// @param withdrawBond says to withdraw deposited bump tokens back to user or not
    function withdraw(uint id, bool withdrawBond) external;

    /// @notice emergency close of an existing maker position
    /// @notice position can be abandoned even if position term is not over
    /// @param id existing position id
    /// @dev requires {abandonmentPermitted} flag to be true
    function abandon(uint id) external;

    /// @notice toggles an auto renew flag value for existing maker position
    /// @notice can be called only from position owner
    /// @param id existing position id
    function toggleMakerAutorenew(uint id) external;

    /// @param id existing maker position id
    /// @return pos maker position struct
    function getMakerPosition(uint id)
        external
        view
        returns (MakerPosition memory);

    /// @notice emits when new Maker position opens
    /// @param account position owner
    /// @param id created position id
    /// @param amount position asset amount
    /// @param tier position tier value
    /// @param term position term value
    /// @param flags position packed flags
    event Deposit(
        address indexed account,
        uint id,
        uint amount,
        uint16 tier,
        uint16 term,
        uint192 flags,
        uint bumpAmount,
        uint boost,
        uint incentives
    );

    /// @notice emits whenever Taker makes withdraw
    /// @param account position owner
    /// @param id position id
    /// @param reward maker claimed reward
    /// @param assetAmount position claimed asset amount
    /// @param stableAmount position claimed stable amount
    event Withdraw(
        address indexed account,
        uint id,
        int reward,
        uint assetAmount,
        uint stableAmount
    );

    /// @notice emits whenever Taker abandons the position
    /// @param account position owner
    /// @param id position id
    /// @param reward maker claimed reward
    /// @param assetAmount position claimed asset amount
    /// @param stableAmount position claimed stable amount
    event Abandon(
        address indexed account,
        uint id,
        int reward,
        uint assetAmount,
        uint stableAmount
    );        
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../struct/TakerPosition.sol";

interface ITakerPosition {
    /// @notice opens a new taker position
    /// @notice takes part of an {amount} to lock as a bond
    /// if deposited bond amount is insufficient
    /// @param amount asset amount to protect
    /// @param risk position risk value
    /// @param term position term value
    /// @param autorenew whether position auto renewing is available
    /// or it`s not
    /// @return id created position id
    /// @dev allowed values of {risk} and {term} are depends of a particular
    /// market and a {Calculation} contract that is uses
    function protect(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew
    ) external returns (uint id);

    /// @notice opens a new taker position
    /// @notice takes a part of an position amount to lock as a bond
    /// if deposited bond amount is insufficient
    /// @param risk position risk value
    /// @param term position term value
    /// @param autorenew whether position auto renewing is available
    /// or it`s not
    /// @return id created position id
    /// @dev allowed values of {risk} and {term} are depends of a particular
    /// market and a {Calculation} contract that is uses
    /// @dev position asset amount should be passed to function as msg.value
    function protectNative(
        uint16 risk,
        uint16 term,
        bool autorenew
    ) external payable returns (uint id);

    /// @notice protect with bump bond permit only
    /// @notice See more in {protect}
    function protectWithAutoBondingPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint id);

    /// @notice protect with both asset and bump bond permits
    /// @notice See more in {protectWithPermit}
    /// @param permitAsset encoded [deadline, v, r, s] values for asset permit using abi.encode
    /// @param permitBump encoded [deadline, v, r, s] values for bump permit using abi.encode
    function protectWithPermitWithAutoBondingPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        bytes memory permitAsset,
        bytes memory permitBump
    ) external returns (uint id);

    /// @notice protect with asset token permit only
    /// @notice See more in {protect}
    function protectWithPermit(
        uint amount,
        uint16 risk,
        uint16 term,    
        bool autorenew,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint id);

    /// @notice closes an existing taker position
    /// @notice position can be closed only if position term is over
    /// @param id taker position id
    /// @param unwrap if market is a wrapped native, this flag is says that asset should be
    /// unwrapped to native or it should be returned as a wrapped native
    /// @param withdrawBond says to withdraw deposited bump tokens back to user or not
    function close(
        uint id,
        bool unwrap,
        bool withdrawBond
    ) external;

    /// @notice closes an existing taker position and claims stable
    /// @notice position can be closed only if position period has passed
    /// @param id taker position id
    /// @param withdrawBond says to withdraw deposited bump tokens back to user or not
    function claim(uint id, bool withdrawBond) external;

    /// @notice cancel taker position
    /// @notice position can be canceled even if position term is not over
    /// @param id taker position id
    /// @param unwrap if market is a wrapped native, this flag is says that asset should be
    /// unwrapped to native or it should be returned as a wrapped native
    /// @dev requires {cancellationPermitted} flag to be true
    function cancel(
        uint id,
        bool unwrap
    ) external;

    /// @notice toggles an auto renew flag value for existing taker position
    /// @notice can be called only from position owner
    /// @param id existing position id
    function toggleTakerAutorenew(uint id) external;

    /// @param id existing maker position id
    /// @return pos taker position struct
    function getTakerPosition(uint id)
        external
        view
        returns (TakerPosition memory);

    /// @notice emits when new Taker position opens
    /// @param account position owner
    /// @param id created position id
    /// @param amount position asset amount
    /// @param floor position asset price floor
    /// @param risk position risk value
    /// @param term position term value
    /// @param flags position packed flags
    event Protect(
        address indexed account,
        uint id,
        uint amount,
        uint floor,
        uint16 risk,
        uint16 term,
        uint192 flags,
        uint bumpAmount,
        uint boost,
        uint incentives
    );

    /// @notice emits whenever Maker makes claim
    /// @param account position owner
    /// @param id position id
    /// @param floor position asset price floor
    /// @param assetAmount position claimed asset amount
    /// @param stableAmount position claimed stable amount
    event Claim(
        address indexed account,
        uint id,
        uint floor,
        uint assetAmount,
        uint stableAmount
    );

    /// @notice emits whenever Maker makes close
    /// @param account position owner
    /// @param id position id
    /// @param premium paid premium
    /// @param assetAmount position claimed asset amount
    /// @param stableAmount position claimed stable amount
    event Close(
        address indexed account,
        uint id,
        uint premium,
        uint assetAmount,
        uint stableAmount
    );

    /// @notice emits whenever Maker cancels a position
    /// @param account position owner
    /// @param id position id
    /// @param premium paid premium
    /// @param assetAmount position claimed asset amount
    /// @param stableAmount position claimed stable amount
    event Cancel(
        address indexed account,
        uint id,
        uint premium,
        uint assetAmount,
        uint stableAmount
    );

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../struct/BondConfig.sol";

/// @title IBond
interface IBond {
    /// @return address of token which contract stores
    function BOND_TOKEN_ADDRESS() external view returns (address);

    /// @notice transfers amount from your address to contract
    /// @param depositTo - address on which tokens will be deposited
    /// @param amount - amount of token to store in contract
    function deposit(address depositTo, uint amount) external;

    /// @notice permit version of {deposit} method
    function depositWithPermit(
        address depositTo,
        uint amount,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @notice transfers amount from given address to contract
    /// @dev should be called only from authorized accounts
    /// @param from - user address
    /// @param amount - amount of token to withdraw from contract
    function withdrawFrom(address from, uint amount) external;

    /// @notice transfers amount from your address to contract
    /// @param amount - amount of token to withdraw from contract
    function withdraw(uint amount) external;

    /// @notice unlocks amount of token in contract
    /// @param _owner - owner of the position
    /// @param bondAmount - amount of bond token to unlock
    function unlock(address _owner, uint bondAmount) external;

    /// @notice calculates taker's bond to lock in contract
    /// @param token - token address
    /// @param amount - amount of asset token
    /// @param risk - risk in percentage with 100 multiplier (9000 means 90%)
    /// @param term - term (in days) of protection
    /// @return bondAmount to lock based on taker position
    function takerBond(
        address token,
        uint amount,
        uint16 risk,
        uint16 term
    ) external view returns (uint bondAmount);

    /// @notice calculates maker's bond to lock in contract
    /// @param token - token address
    /// @param amount - amount of stable token to lock
    /// @param risk - risk number (1-5)
    /// @param term - term (in days) of protection
    /// @return bondAmount to lock based on maker position
    function makerBond(
        address token,
        uint amount,
        uint16 risk,
        uint16 term
    ) external view returns (uint bondAmount);

    /// @notice how much of bond amount will be reduced for taker position
    function takerToSwap(address token, uint bondAmount)
        external
        view
        returns (uint amount);

    /// @notice how much of bond amount will be reduced for maker position
    function makerToSwap(address token, uint bondAmount)
        external
        view
        returns (uint amount);

    function autoLockBondTakerPosition(
        address recipient,
        address token,
        uint amount,
        uint16 risk,
        uint16 term,
        uint boostAmount,
        uint incentivesAmount              
    )
        external
        returns (
            uint bondAmount,
            uint toTransfer,
            uint toReduce
        );

    function autoLockBondMakerPosition(
        address recipient,
        address token,
        uint amount,
        uint16 risk,
        uint16 term,
        uint boostAmount,
        uint incentivesAmount              
    )
        external
        returns (
            uint bondAmount,
            uint toTransfer,
            uint toReduce
        );

    /// @notice calculates amount of bond position for taker
    function calcBondSizeForTakerPosition(
        address recipient,
        address token,
        uint amount,
        uint16 risk,
        uint16 term  
    )
        external
        view
        returns (
            uint toLock,
            uint toTransfer,
            uint toReduce
        );

    /// @notice calculates amount of bond position for maker
    function calcBondSizeForMakerPosition(
        address recipient,
        address token,
        uint amount,
        uint16 risk,
        uint16 term     
    )
        external
        view
        returns (
            uint toLock,
            uint toTransfer,
            uint toReduce
        );

    /// @notice locks amount of deposited bond
    function lock(address addr, uint amount) external;

    /// @param addr - address of user
    /// @return amount - locked amount of particular user
    function lockedOf(address addr) external view returns (uint amount);

    /// @param addr - address of user
    /// @return amount - deposited amount of particular user
    function balanceOf(address addr) external view returns (uint amount);

    /// @notice transfer locked bond between accounts
    function transferLocked(
        address from,
        address to,
        uint amount
    ) external;

    /// @notice Calculate Bond multipliers for given token
    function calcBonding(
        address token,
        uint bumpPrice,
        uint assetPrice
    ) external;

    function setBondTheta(
        address token, 
        uint thetaAsset1, 
        uint thetaStable1, 
        uint thetaAsset2, 
        uint thetaStable2 
    ) external;

    /// @notice liquidate user locked bonds (used in liquidation flow)
    function liquidate(address from, uint amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @title BondConfig
struct BondConfig {
    uint bumpPerAsset; 
    uint bumpPerStable; 
    uint assetPerBump;  
    uint stablePerBump;
    uint thetaAsset1;
    uint thetaAsset2;
    uint thetaStable1;
    uint thetaStable2;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

struct MarketState {
    int AP; // Asset pool (in tokens with DIVIDER precision)
    int AR; // Asset reserve (in tokens with DIVIDER precision)
    int CP; // Capital pool with DIVIDER precision
    int CR; // Capital reserve with DIVIDER precision
    int B; // Book (in tokens with DIVIDER precision)
    int L; // Liability in ORACLE precision
    int D; // Debt with DIVIDER precision
    int E; // Yield target value with DIVIDER precision (can be negative)
    int RWA; // Risk weighted asset pool
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../struct/TakerPosition.sol";
import "../struct/MakerPosition.sol";
import "../struct/MarketState.sol";
import "../struct/RebalanceAmount.sol";

/// @notice Rebalance parameters calculation
interface IRebalanceCalculation {
    function getSellAmount()  external view returns (uint sellToken, uint sellStable);

    function rebalanceAmount(int changeToken, int changeStable) external view returns (RebalanceAmount memory);

    function rebalanceTokenPool(int changeToken, uint AP, uint AR, uint B, int beta) external pure returns(int deltaAP, int deltaAR);

    function rebalanceStablePool(int changeStable, uint CP, uint CR, uint L, uint D, uint E, int beta) external pure returns(int deltaCP, int deltaCR);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IMarket.sol";
import "./ITakerPositionRate.sol";
import "./IMakerPositionRate.sol";
import "./IPAPCalculation.sol";
import "./IYieldCalculation.sol";
import "../struct/BoostingParameters.sol";

interface IRiskCalculation is ITakerPositionRate, IMakerPositionRate, IPAPCalculation, IYieldCalculation {

    function premiumOnClose(uint id) external view returns (uint);

    function premiumOnClaim(uint id) external view returns (uint);

    function premiumOnCancel(uint id) external view returns (uint);

    function yieldOnWithdraw(uint id) external view returns (int);

    function yieldOnAbandon(uint id) external view returns (int);

    function boostParameters() external returns (BoostingParameters memory);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

struct RebalanceAmount {
    int deltaAP;
    int deltaAR;
    int deltaCP;
    int deltaCR;
    int deltaE;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface ITakerPositionRate {
    function getTakerRate(uint16 risk, uint16 term)
        external
        pure
        returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IMakerPositionRate {
    function getMakerRate(uint16 tier, uint16 term)
        external
        pure
        returns (uint, uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "../struct/MarketState.sol";
interface IPAPCalculation {

    /// @notice Calculate premium against the asset pool
    /// @param toCurrentTime - force update to current time
    function calcNewPaps(bool toCurrentTime)
    external
    view
    returns (
        uint papsInAsset,
        uint papsInStable,
        int _lastPrice,
        uint _lastTimestamp,
        uint80 _lastRoundId,
        uint _probabilityOfClaim,
        uint numberUpdatePrice
    );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IYieldCalculation {
    function YIELD_EPSILON() external pure returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

struct BoostingParameters {
    int w1max;
    int w11max;
    int w1;
    int lrr1;
    int w11;
    int lrr11;
    int pbl1;
    int pbl11;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @notice Interface for shared access control
interface IGlobalAccessControl {
    function GLOBAL_GOVERNANCE_ROLE() external view returns (bytes32);
    
    function GLOBAL_KEEPER_ROLE() external view returns (bytes32);

    function userHasRole(bytes32 role, address account)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
interface IERC165 {
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