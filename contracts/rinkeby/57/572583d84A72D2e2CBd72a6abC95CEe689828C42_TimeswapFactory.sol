// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

import {IFactory} from './interfaces/IFactory.sol';
import {IPair} from './interfaces/IPair.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {TimeswapPair} from './TimeswapPair.sol';

/// @title Timeswap Factory
/// @author Timeswap Labs
/// @notice It is recommended to use Timeswap Convenience to interact with this contract.
/// @notice All error messages are coded and can be found in the documentation.
contract TimeswapFactory is IFactory {
    /* ===== MODEL ===== */

    /// @inheritdoc IFactory
    address public override owner;
    /// @inheritdoc IFactory
    address public override pendingOwner;
    /// @inheritdoc IFactory
    uint256 public immutable override fee;
    /// @inheritdoc IFactory
    uint256 public immutable override protocolFee;

    /// @inheritdoc IFactory
    mapping(IERC20 => mapping(IERC20 => IPair)) public override getPair;

    /* ===== INIT ===== */

    /// @param _owner The chosen owner address.
    /// @param _fee The chosen fee rate.
    /// @param _protocolFee The chosen protocol fee rate.
    constructor(
        address _owner,
        uint16 _fee,
        uint16 _protocolFee
    ) {
        require(_owner != address(0), 'E101');
        require(_fee != 0);
        require(_protocolFee != 0);
        owner = _owner;
        fee = _fee;
        protocolFee = _protocolFee;
    }

    /* ===== UPDATE ===== */

    /// @inheritdoc IFactory
    function createPair(IERC20 asset, IERC20 collateral) external override returns (IPair pair) {
        require(asset != collateral, 'E103');
        require(asset != IERC20(address(0)), 'E101');
        require(collateral != IERC20(address(0)), 'E101');
        require(getPair[asset][collateral] == IPair(address(0)), 'E104');

        pair = new TimeswapPair{salt: keccak256(abi.encode(asset, collateral))}(asset, collateral, uint16(fee), uint16(protocolFee));

        getPair[asset][collateral] = pair;

        emit CreatePair(asset, collateral, pair);
    }

    /// @inheritdoc IFactory
    function setPendingOwner(address _pendingOwner) external override {
        require(msg.sender == owner, 'E102');
        require(_pendingOwner != address(0), 'E101');
        pendingOwner = _pendingOwner;

        emit SetOwner(_pendingOwner);
    }

    /// @inheritdoc IFactory
    function acceptOwner() external override {
        require(msg.sender == pendingOwner, 'E102');
        owner = msg.sender;
        pendingOwner = address(0);

        emit AcceptOwner(msg.sender);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;

import {IPair} from './IPair.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IFactory {
    /* ===== EVENT ===== */

    /// @dev Emits when a new Timeswap Pair contract is created.
    /// @param asset The address of the ERC20 being lent and borrowed.
    /// @param collateral The address of the ERC20 used as collateral.
    /// @param pair The address of the Timeswap Pair contract created.
    event CreatePair(IERC20 indexed asset, IERC20 indexed collateral, IPair pair);

    /// @dev Emits when a new pending owner is set.
    /// @param pendingOwner The address of the new pending owner.
    event SetOwner(address indexed pendingOwner);

    /// @dev Emits when the pending owner has accepted being the new owner.
    /// @param owner The address of the new owner.
    event AcceptOwner(address indexed owner);

    /* ===== VIEW ===== */

    /// @dev Return the address that receives the protocol fee.
    /// @return The address of the owner.
    function owner() external view returns (address);

    /// @dev Return the new pending address to replace the owner.
    /// @return The address of the pending owner.
    function pendingOwner() external view returns (address);

    /// @dev Return the fee per second earned by liquidity providers.
    /// @dev Must be downcasted to uint16.
    /// @return The fee following UQ0.40 format.
    function fee() external view returns (uint256);

    /// @dev Return the protocol fee per second earned by the owner.
    /// @dev Must be downcasted to uint16.
    /// @return The protocol fee per second following UQ0.40 format.
    function protocolFee() external view returns (uint256);

    /// @dev Returns the address of a deployed pair.
    /// @param asset The address of the ERC20 being lent and borrowed.
    /// @param collateral The address of the ERC20 used as collateral.
    /// @return pair The address of the Timeswap Pair contract.
    function getPair(IERC20 asset, IERC20 collateral) external view returns (IPair pair);

    /* ===== UPDATE ===== */

    /// @dev Creates a Timeswap Pool based on ERC20 pair parameters.
    /// @dev Cannot create a Timeswap Pool with the same pair parameters.
    /// @param asset The address of the ERC20 being lent and borrowed.
    /// @param collateral The address of the ERC20 as the collateral.
    /// @return pair The address of the Timeswap Pair contract.
    function createPair(IERC20 asset, IERC20 collateral) external returns (IPair pair);

    /// @dev Set the pending owner of the factory.
    /// @dev Can only be called by the current owner.
    /// @param _pendingOwner the chosen pending owner.
    function setPendingOwner(address _pendingOwner) external;

    /// @dev Set the pending owner as the owner of the factory.
    /// @dev Reset the pending owner to zero.
    /// @dev Can only be called by the pending owner.
    function acceptOwner() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;

import {IFactory} from './IFactory.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IPair {
    /* ===== STRUCT ===== */

    struct Tokens {
        uint128 asset;
        uint128 collateral;
    }

    struct Claims {
        uint112 bondPrincipal;
        uint112 bondInterest;
        uint112 insurancePrincipal;
        uint112 insuranceInterest;
    }

    struct Due {
        uint112 debt;
        uint112 collateral;
        uint32 startBlock;
    }

    struct State {
        Tokens reserves;
        uint256 feeStored;
        uint256 totalLiquidity;
        Claims totalClaims;
        uint120 totalDebtCreated;
        uint112 x;
        uint112 y;
        uint112 z;
    }

    struct Pool {
        State state;
        mapping(address => uint256) liquidities;
        mapping(address => Claims) claims;
        mapping(address => Due[]) dues;
    }

    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param liquidityTo The address of the receiver of liquidity balance.
    /// @param dueTo The addres of the receiver of collateralized debt balance.
    /// @param xIncrease The increase in the X state.
    /// @param yIncrease The increase in the Y state.
    /// @param zIncrease The increase in the Z state.
    /// @param data The data for callback.
    struct MintParam {
        uint256 maturity;
        address liquidityTo;
        address dueTo;
        uint112 xIncrease;
        uint112 yIncrease;
        uint112 zIncrease;
        bytes data;
    }

    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param assetTo The address of the receiver of asset ERC20.
    /// @param collateralTo The addres of the receiver of collateral ERC20.
    /// @param liquidityIn The amount of liquidity balance burnt by the msg.sender.
    struct BurnParam {
        uint256 maturity;
        address assetTo;
        address collateralTo;
        uint256 liquidityIn;
    }

    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param bondTo The address of the receiver of bond balance.
    /// @param insuranceTo The addres of the receiver of insurance balance.
    /// @param xIncrease The increase in x state and the amount of asset ERC20 sent.
    /// @param yDecrease The decrease in y state.
    /// @param zDecrease The decrease in z state.
    /// @param data The data for callback.
    struct LendParam {
        uint256 maturity;
        address bondTo;
        address insuranceTo;
        uint112 xIncrease;
        uint112 yDecrease;
        uint112 zDecrease;
        bytes data;
    }

    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param assetTo The address of the receiver of asset ERC20.
    /// @param collateralTo The addres of the receiver of collateral ERC20.
    /// @param claimsIn The amount of bond balance and insurance balance burnt by the msg.sender.
    struct WithdrawParam {
        uint256 maturity;
        address assetTo;
        address collateralTo;
        Claims claimsIn;
    }

    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param assetTo The address of the receiver of asset ERC20.
    /// @param dueTo The address of the receiver of collateralized debt.
    /// @param xDecrease The decrease in x state and amount of asset ERC20 received by assetTo.
    /// @param yIncrease The increase in y state.
    /// @param zIncrease The increase in z state.
    /// @param data The data for callback.
    struct BorrowParam {
        uint256 maturity;
        address assetTo;
        address dueTo;
        uint112 xDecrease;
        uint112 yIncrease;
        uint112 zIncrease;
        bytes data;
    }

    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param to The address of the receiver of collateral ERC20.
    /// @param owner The addres of the owner of collateralized debt.
    /// @param ids The array indexes of collateralized debts.
    /// @param assetsIn The amount of asset ERC20 paid per collateralized debts.
    /// @param collateralsOut The amount of collateral ERC20 withdrawn per collaterlaized debts.
    /// @param data The data for callback.
    struct PayParam {
        uint256 maturity;
        address to;
        address owner;
        uint256[] ids;
        uint112[] assetsIn;
        uint112[] collateralsOut;
        bytes data;
    }

    /* ===== EVENT ===== */

    /// @dev Emits when the state gets updated.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param x The new x state of the pool.
    /// @param y The new y state of the pool.
    /// @param z The new z state of the pool.
    event Sync(uint256 indexed maturity, uint112 x, uint112 y, uint112 z);

    /// @dev Emits when mint function is called.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param sender The address of the caller.
    /// @param liquidityTo The address of the receiver of liquidity balance.
    /// @param dueTo The address of the receiver of collateralized debt balance.
    /// @param assetIn The increase in the X state.
    /// @param liquidityOut The amount of liquidity balance received by liquidityTo.
    /// @param id The array index of the collateralized debt received by dueTo.
    /// @param dueOut The collateralized debt received by dueTo.
    /// @param feeIn The amount of fee asset ERC20 deposited.
    event Mint(
        uint256 maturity,
        address indexed sender,
        address indexed liquidityTo,
        address indexed dueTo,
        uint256 assetIn,
        uint256 liquidityOut,
        uint256 id,
        Due dueOut,
        uint256 feeIn
    );

    /// @dev Emits when burn function is called.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param sender The address of the caller.
    /// @param assetTo The address of the receiver of asset ERC20.
    /// @param collateralTo The addres of the receiver of collateral ERC20.
    /// @param liquidityIn The amount of liquidity balance burnt by the sender.
    /// @param assetOut The amount of asset ERC20 received.
    /// @param collateralOut The amount of collateral ERC20 received.
    /// @param feeOut The amount of fee asset ERC20 received.
    event Burn(
        uint256 maturity,
        address indexed sender,
        address indexed assetTo,
        address indexed collateralTo,
        uint256 liquidityIn,
        uint256 assetOut,
        uint128 collateralOut,
        uint256 feeOut
    );

    /// @dev Emits when lend function is called.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param sender The address of the caller.
    /// @param bondTo The address of the receiver of bond balance.
    /// @param insuranceTo The addres of the receiver of insurance balance.
    /// @param assetIn The increase in X state.
    /// @param claimsOut The amount of bond balance and insurance balance received.
    /// @param feeIn The amount of fee paid by lender.
    /// @param protocolFeeIn The amount of protocol fee paid by lender.
    event Lend(
        uint256 maturity,
        address indexed sender,
        address indexed bondTo,
        address indexed insuranceTo,
        uint256 assetIn,
        Claims claimsOut,
        uint256 feeIn,
        uint256 protocolFeeIn
    );

    /// @dev Emits when withdraw function is called.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param sender The address of the caller.
    /// @param assetTo The address of the receiver of asset ERC20.
    /// @param collateralTo The address of the receiver of collateral ERC20.
    /// @param claimsIn The amount of bond balance and insurance balance burnt by the sender.
    /// @param tokensOut The amount of asset ERC20 and collateral ERC20 received.
    event Withdraw(
        uint256 maturity,
        address indexed sender,
        address indexed assetTo,
        address indexed collateralTo,
        Claims claimsIn,
        Tokens tokensOut
    );

    /// @dev Emits when borrow function is called.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param sender The address of the caller.
    /// @param assetTo The address of the receiver of asset ERC20.
    /// @param dueTo The address of the receiver of collateralized debt.
    /// @param assetOut The amount of asset ERC20 received by assetTo.
    /// @param id The array index of the collateralized debt received by dueTo.
    /// @param dueOut The collateralized debt received by dueTo.
    /// @param feeIn The amount of fee paid by lender.
    /// @param protocolFeeIn The amount of protocol fee paid by lender.
    event Borrow(
        uint256 maturity,
        address indexed sender,
        address indexed assetTo,
        address indexed dueTo,
        uint256 assetOut,
        uint256 id,
        Due dueOut,
        uint256 feeIn,
        uint256 protocolFeeIn
    );

    /// @dev Emits when pay function is called.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param sender The address of the caller.
    /// @param to The address of the receiver of collateral ERC20.
    /// @param owner The address of the owner of collateralized debt.
    /// @param ids The array indexes of collateralized debts.
    /// @param assetsIn The amount of asset ERC20 paid per collateralized debts.
    /// @param collateralsOut The amount of collateral ERC20 withdrawn per collaterelized debts.
    /// @param assetIn The total amount of asset ERC20 paid.
    /// @param collateralOut The total amount of collateral ERC20 received.
    event Pay(
        uint256 maturity,
        address indexed sender,
        address indexed to,
        address indexed owner,
        uint256[] ids,
        uint112[] assetsIn,
        uint112[] collateralsOut,
        uint128 assetIn,
        uint128 collateralOut
    );

    /// @dev Emits when collectProtocolFee function is called
    /// @param sender The address of the caller.
    /// @param to The address of the receiver of asset ERC20.
    /// @param protocolFeeOut The amount of protocol fee asset ERC20 received.
    event CollectProtocolFee(
        address indexed sender,
        address indexed to,
        uint256 protocolFeeOut
    );

    /* ===== VIEW ===== */

    /// @dev Return the address of the factory contract that deployed this contract.
    /// @return The address of the factory contract.
    function factory() external view returns (IFactory);

    /// @dev Return the address of the ERC20 being lent and borrowed.
    /// @return The address of the asset ERC20.
    function asset() external view returns (IERC20);

    /// @dev Return the address of the ERC20 as collateral.
    /// @return The address of the collateral ERC20.
    function collateral() external view returns (IERC20);

    //// @dev Return the fee per second earned by liquidity providers.
    /// @dev Must be downcasted to uint16.
    //// @return The transaction fee following the UQ0.40 format.
    function fee() external view returns (uint256);

    /// @dev Return the protocol fee per second earned by the owner.
    /// @dev Must be downcasted to uint16.
    /// @return The protocol fee per second following the UQ0.40 format.
    function protocolFee() external view returns (uint256);

    /// @dev Return the fee stored of the Pool given maturity.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @return The fee in asset ERC20 stored in the Pool.
    function feeStored(uint256 maturity) external view returns (uint256);

    /// @dev Return the protocol fee stored.
    /// @return The protocol fee in asset ERC20 stored.
    function protocolFeeStored() external view returns (uint256);

    /// @dev Returns the Constant Product state of a Pool.
    /// @dev The Y state follows the UQ80.32 format.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @return x The x state.
    /// @return y The y state.
    /// @return z The z state.
    function constantProduct(uint256 maturity)
        external
        view
        returns (
            uint112 x,
            uint112 y,
            uint112 z
        );

    /// @dev Returns the asset ERC20 and collateral ERC20 balances of a Pool.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @return The asset ERC20 and collateral ERC20 locked.
    function totalReserves(uint256 maturity) external view returns (Tokens memory);

    /// @dev Returns the total liquidity supply of a Pool.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @return The total liquidity supply.
    function totalLiquidity(uint256 maturity) external view returns (uint256);

    /// @dev Returns the liquidity balance of a user in a Pool.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param owner The address of the user.
    /// @return The liquidity balance.
    function liquidityOf(uint256 maturity, address owner) external view returns (uint256);

    /// @dev Returns the total claims of a Pool.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @return The total claims.
    function totalClaims(uint256 maturity) external view returns (Claims memory);

    /// @dev Returms the claims of a user in a Pool.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param owner The address of the user.
    /// @return The claims balance.
    function claimsOf(uint256 maturity, address owner) external view returns (Claims memory);

    /// @dev Returns the total debt created.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @return The total asset ERC20 debt created.
    function totalDebtCreated(uint256 maturity) external view returns (uint120);

    /// @dev Returns the number of dues owned by owner.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param owner The address of the user.
    function totalDuesOf(uint256 maturity, address owner) external view returns (uint256);

    /// @dev Returns a collateralized debt of a user in a Pool.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param owner The address of the user.
    /// @param id The index of the collateralized debt
    /// @return The collateralized debt balance.
    function dueOf(uint256 maturity, address owner, uint256 id) external view returns (Due memory);

    /* ===== UPDATE ===== */

    /// @dev Add liquidity into a Pool by a liquidity provider.
    /// @dev Liquidity providers can be thought as making both lending and borrowing positions.
    /// @dev Must be called by a contract implementing the ITimeswapMintCallback interface.
    /// @param param The mint parameter found in the MintParam struct.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return liquidityOut The amount of liquidity balance received by liquidityTo.
    /// @return id The array index of the collateralized debt received by dueTo.
    /// @return dueOut The collateralized debt received by dueTo.
    function mint(MintParam calldata param)
        external
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            Due memory dueOut
        );

    /// @dev Remove liquidity from a Pool by a liquidity provider.
    /// @dev Can only be called after the maturity of the Pool.
    /// @param param The burn parameter found in the BurnParam struct.
    /// @return assetOut The amount of asset ERC20 received.
    /// @return collateralOut The amount of collateral ERC20 received.
    function burn(BurnParam calldata param) 
        external 
        returns (
            uint256 assetOut,
            uint128 collateralOut 
        );

    /// @dev Lend asset ERC20 into the Pool.
    /// @dev Must be called by a contract implementing the ITimeswapLendCallback interface.
    /// @param param The lend parameter found in the LendParam struct.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return claimsOut The amount of bond balance and insurance balance received.
    function lend(LendParam calldata param) 
        external 
        returns (
            uint256 assetIn,
            Claims memory claimsOut
        );

    /// @dev Withdraw asset ERC20 and/or collateral ERC20 for lenders.
    /// @dev Can only be called after the maturity of the Pool.
    /// @param param The withdraw parameter found in the WithdrawParam struct.
    /// @return tokensOut The amount of asset ERC20 and collateral ERC20 received.
    function withdraw(WithdrawParam calldata param)
        external 
        returns (
            Tokens memory tokensOut
        );

    /// @dev Borrow asset ERC20 from the Pool.
    /// @dev Must be called by a contract implementing the ITimeswapBorrowCallback interface.
    /// @param param The borrow parameter found in the BorrowParam struct.
    /// @return assetOut The amount of asset ERC20 received.
    /// @return id The array index of the collateralized debt received by dueTo.
    /// @return dueOut The collateralized debt received by dueTo.
    function borrow(BorrowParam calldata param)
        external 
        returns (
            uint256 assetOut,
            uint256 id, 
            Due memory dueOut
        );

    /// @dev Pay asset ERC20 into the Pool to repay debt for borrowers.
    /// @dev If there are asset paid, must be called by a contract implementing the ITimeswapPayCallback interface.
    /// @param param The pay parameter found in the PayParam struct.
    /// @return assetIn The total amount of asset ERC20 paid.
    /// @return collateralOut The total amount of collateral ERC20 received.
    function pay(PayParam calldata param)
        external 
        returns (
            uint128 assetIn, 
            uint128 collateralOut
        );

    /// @dev Collect the stored protocol fee.
    /// @dev Can only be called by the owner.
    /// @param to The receiver of the protocol fee.
    /// @return protocolFeeOut The total amount of protocol fee asset ERC20 received.
    function collectProtocolFee(address to) external returns (uint256 protocolFeeOut);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

import {IPair} from './interfaces/IPair.sol';
import {IFactory} from './interfaces/IFactory.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {TimeswapMath} from './libraries/TimeswapMath.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {Array} from './libraries/Array.sol';
import {Callback} from './libraries/Callback.sol';
import {BlockNumber} from './libraries/BlockNumber.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/// @title Timeswap Pair
/// @author Timeswap Labs
/// @notice It is recommended to use Timeswap Convenience to interact with this contract.
/// @notice All error messages are coded and can be found in the documentation.
contract TimeswapPair is IPair, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Array for Due[];

    /* ===== MODEL ===== */

    /// @inheritdoc IPair
    IFactory public immutable override factory;
    /// @inheritdoc IPair
    IERC20 public immutable override asset;
    /// @inheritdoc IPair
    IERC20 public immutable override collateral;
    /// @inheritdoc IPair
    uint256 public immutable override fee;
    /// @inheritdoc IPair
    uint256 public immutable override protocolFee;

    /// @inheritdoc IPair
    uint256 public override protocolFeeStored;

    /// @dev Stores the individual states of each Pool.
    mapping(uint256 => Pool) private pools;

    /* ===== VIEW =====*/

    /// @inheritdoc IPair
    function feeStored(uint256 maturity)
        external
        view
        override
        returns (uint256) 
    {
        return pools[maturity].state.feeStored;
    }

    /// @inheritdoc IPair
    function constantProduct(uint256 maturity)
        external
        view
        override
        returns (uint112, uint112, uint112)
    {
        State memory state = pools[maturity].state;
        return (state.x, state.y, state.z);
    }

    /// @inheritdoc IPair
    function totalReserves(uint256 maturity) external view override returns (Tokens memory) {
        return pools[maturity].state.reserves;
    }

    /// @inheritdoc IPair
    function totalLiquidity(uint256 maturity) external view override returns (uint256) {
        return pools[maturity].state.totalLiquidity;
    }

    /// @inheritdoc IPair
    function liquidityOf(uint256 maturity, address owner) external view override returns (uint256) {
        return pools[maturity].liquidities[owner];
    }

    /// @inheritdoc IPair
    function totalClaims(uint256 maturity) external view override returns (Claims memory) {
        return pools[maturity].state.totalClaims;
    }

    /// @inheritdoc IPair
    function claimsOf(uint256 maturity, address owner) external view override returns (Claims memory) {
        return pools[maturity].claims[owner];
    }

    /// @inheritdoc IPair
    function totalDebtCreated(uint256 maturity) external view override returns (uint120) {
        return pools[maturity].state.totalDebtCreated;
    }

    /// @inheritdoc IPair
    function totalDuesOf(uint256 maturity, address owner) external view override returns (uint256) {
        return pools[maturity].dues[owner].length;
    }

    /// @inheritdoc IPair
    function dueOf(uint256 maturity, address owner, uint256 id) external view override returns (Due memory) {
        return pools[maturity].dues[owner][id];
    }

    /* ===== INIT ===== */

    /// @dev Initializes the Pair contract.
    /// @dev Called by the Timeswap factory contract.
    /// @param _asset The address of the ERC20 being lent and borrowed.
    /// @param _collateral The address of the ERC20 as the collateral.
    /// @param _fee The chosen fee rate.
    /// @param _protocolFee The chosen protocol fee rate.
    constructor(
        IERC20 _asset,
        IERC20 _collateral,
        uint16 _fee,
        uint16 _protocolFee
    ) ReentrancyGuard() {
        factory = IFactory(msg.sender);
        asset = _asset;
        collateral = _collateral;
        fee = _fee;
        protocolFee = _protocolFee;
    }

    /* ===== UPDATE ===== */

    /// @inheritdoc IPair
    function mint(MintParam calldata param)
        external
        override
        nonReentrant
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            Due memory dueOut
        )
    {   
        require(block.timestamp < param.maturity, 'E202');
        unchecked { require(param.maturity - block.timestamp < 0x100000000, 'E208'); }
        require(param.liquidityTo != address(0), 'E201');
        require(param.dueTo != address(0), 'E201');
        require(param.liquidityTo != address(this), 'E204');
        require(param.dueTo != address(this), 'E204');
        require(param.xIncrease != 0, 'E205');
        require(param.yIncrease != 0, 'E205');
        require(param.zIncrease != 0, 'E205');
        
        Pool storage pool = pools[param.maturity];
        State memory state = pool.state;

        uint256 feeStoredIncrease;
        (liquidityOut, dueOut, feeStoredIncrease) = TimeswapMath.mint(
            param.maturity,
            pool.state,
            param.xIncrease,
            param.yIncrease,
            param.zIncrease
        );

        require(liquidityOut != 0, 'E212');
        state.totalLiquidity += liquidityOut;
        pool.liquidities[param.liquidityTo] += liquidityOut;

        state.feeStored += feeStoredIncrease;

        id = pool.dues[param.dueTo].insert(dueOut);

        state.reserves.asset += param.xIncrease;
        state.reserves.collateral += dueOut.collateral;
        state.totalDebtCreated += dueOut.debt;

        state.x += param.xIncrease;
        state.y += param.yIncrease;
        state.z += param.zIncrease;

        pool.state = state;

        assetIn = param.xIncrease;
        assetIn += feeStoredIncrease;
        Callback.mint(asset, collateral, assetIn, dueOut.collateral, param.data);

        emit Sync(param.maturity, pool.state.x, pool.state.y, pool.state.z);
        emit Mint(
            param.maturity, 
            msg.sender, 
            param.liquidityTo, 
            param.dueTo, 
            assetIn, 
            liquidityOut, 
            id, 
            dueOut,
            feeStoredIncrease
        );
    }

    /// @inheritdoc IPair
    function burn(BurnParam calldata param) 
        external 
        override 
        nonReentrant 
        returns (
            uint256 assetOut, 
            uint128 collateralOut
        ) 
    {
        require(block.timestamp >= param.maturity, 'E203');
        require(param.assetTo != address(0), 'E201');
        require(param.collateralTo != address(0), 'E201');
        require(param.assetTo != address(this), 'E204');
        require(param.collateralTo != address(this), 'E204');
        require(param.liquidityIn != 0, 'E205');

        Pool storage pool = pools[param.maturity];
        State memory state = pool.state;
        require(state.totalLiquidity != 0, 'E206');

        uint128 _assetOut;
        uint256 feeOut;
        (_assetOut, collateralOut, feeOut) = TimeswapMath.burn(
            pool.state,
            param.liquidityIn
        );

        state.totalLiquidity -= param.liquidityIn;

        pool.liquidities[msg.sender] -= param.liquidityIn;

        assetOut = _assetOut;
        assetOut += feeOut;

        if (assetOut != 0) {
            state.reserves.asset -= _assetOut;
            state.feeStored -= feeOut;
            asset.safeTransfer(param.assetTo, assetOut);
        }
        if (collateralOut != 0) {
            state.reserves.collateral -= collateralOut;
            collateral.safeTransfer(param.collateralTo, collateralOut);
        }

        pool.state = state;

        emit Burn(
            param.maturity,
            msg.sender, 
            param.assetTo, 
            param.collateralTo, 
            param.liquidityIn, 
            assetOut, 
            collateralOut,
            feeOut
        );
    }

    /// @inheritdoc IPair
    function lend(LendParam calldata param) 
        external 
        override 
        nonReentrant 
        returns (
            uint256 assetIn,
            Claims memory claimsOut
        ) 
    {
        require(block.timestamp < param.maturity, 'E202');
        require(param.bondTo != address(0), 'E201');
        require(param.insuranceTo != address(0), 'E201');
        require(param.bondTo != address(this), 'E204');
        require(param.insuranceTo != address(this), 'E204');
        require(param.xIncrease != 0, 'E205');

        Pool storage pool = pools[param.maturity];
        State memory state = pool.state;
        require(state.totalLiquidity != 0, 'E206');

        uint256 feeStoredIncrease;
        uint256 protocolFeeStoredIncrease;
        (claimsOut, feeStoredIncrease, protocolFeeStoredIncrease) = TimeswapMath.lend(
            param.maturity,
            pool.state,
            param.xIncrease,
            param.yDecrease,
            param.zDecrease,
            fee,
            protocolFee
        );

        state.feeStored += feeStoredIncrease;
        protocolFeeStored += protocolFeeStoredIncrease;

        state.totalClaims.bondPrincipal += claimsOut.bondPrincipal;
        state.totalClaims.bondInterest += claimsOut.bondInterest;
        state.totalClaims.insurancePrincipal += claimsOut.insurancePrincipal;
        state.totalClaims.insuranceInterest += claimsOut.insuranceInterest;

        pool.claims[param.bondTo].bondPrincipal += claimsOut.bondPrincipal;
        pool.claims[param.bondTo].bondInterest += claimsOut.bondInterest;
        pool.claims[param.insuranceTo].insurancePrincipal += claimsOut.insurancePrincipal;
        pool.claims[param.insuranceTo].insuranceInterest += claimsOut.insuranceInterest;

        state.reserves.asset += param.xIncrease;

        state.x += param.xIncrease;
        state.y -= param.yDecrease;
        state.z -= param.zDecrease;

        pool.state = state;

        assetIn = param.xIncrease;
        assetIn += feeStoredIncrease;
        assetIn += protocolFeeStoredIncrease;

        Callback.lend(asset, assetIn, param.data);

        emit Sync(param.maturity, pool.state.x, pool.state.y, pool.state.z);
        emit Lend(
            param.maturity,
            msg.sender, 
            param.bondTo, 
            param.insuranceTo, 
            assetIn, 
            claimsOut,
            feeStoredIncrease,
            protocolFeeStoredIncrease
        );
    }

    /// @inheritdoc IPair
    function withdraw(WithdrawParam calldata param)
        external 
        override 
        nonReentrant 
        returns (
            Tokens memory tokensOut
        ) 
    {
        require(block.timestamp >= param.maturity, 'E203');
        require(param.assetTo != address(0), 'E201');
        require(param.collateralTo != address(0), 'E201');
        require(param.assetTo != address(this), 'E204');
        require(param.collateralTo != address(this), 'E204');
        require(
            param.claimsIn.bondPrincipal != 0 || 
            param.claimsIn.bondInterest != 0 ||
            param.claimsIn.insurancePrincipal != 0 ||
            param.claimsIn.insuranceInterest != 0, 
            'E205'
        );

        Pool storage pool = pools[param.maturity];
        State memory state = pool.state;

        tokensOut = TimeswapMath.withdraw(pool.state, param.claimsIn);

        state.totalClaims.bondPrincipal -= param.claimsIn.bondPrincipal;
        state.totalClaims.bondInterest -= param.claimsIn.bondInterest;
        state.totalClaims.insurancePrincipal -= param.claimsIn.insurancePrincipal;
        state.totalClaims.insuranceInterest -= param.claimsIn.insuranceInterest;

        Claims memory sender = pool.claims[msg.sender];

        sender.bondPrincipal -= param.claimsIn.bondPrincipal;
        sender.bondInterest -= param.claimsIn.bondInterest;
        sender.insurancePrincipal -= param.claimsIn.insurancePrincipal;
        sender.insuranceInterest -= param.claimsIn.insuranceInterest;

        pool.claims[msg.sender] = sender;

        if (tokensOut.asset != 0) {
            state.reserves.asset -= tokensOut.asset;
            asset.safeTransfer(param.assetTo, tokensOut.asset);
        }
        if (tokensOut.collateral != 0) {
            state.reserves.collateral -= tokensOut.collateral;
            collateral.safeTransfer(param.collateralTo, tokensOut.collateral);
        }

        pool.state = state;

        emit Withdraw(
            param.maturity,
            msg.sender, 
            param.assetTo, 
            param.collateralTo, 
            param.claimsIn, 
            tokensOut
        );
    }

    /// @inheritdoc IPair
    function borrow(BorrowParam calldata param)
        external 
        override 
        nonReentrant 
        returns (
            uint256 assetOut,
            uint256 id, 
            Due memory dueOut
        ) 
    {
        require(block.timestamp < param.maturity, 'E202');
        require(param.assetTo != address(0), 'E201');
        require(param.dueTo != address(0), 'E201');
        require(param.assetTo != address(this), 'E204');
        require(param.dueTo != address(this), 'E204');
        require(param.xDecrease != 0, 'E205');

        Pool storage pool = pools[param.maturity];
        State memory state = pool.state;
        require(state.totalLiquidity != 0, 'E206');

        uint256 feeStoredIncrease;
        uint256 protocolFeeStoredIncrease;
        (dueOut, feeStoredIncrease, protocolFeeStoredIncrease) = TimeswapMath.borrow(
            param.maturity,
            pool.state,
            param.xDecrease,
            param.yIncrease,
            param.zIncrease,
            fee,
            protocolFee
        );

        state.feeStored += feeStoredIncrease;
        protocolFeeStored += protocolFeeStoredIncrease;

        id = pool.dues[param.dueTo].insert(dueOut);

        state.reserves.asset -= param.xDecrease;
        state.reserves.collateral += dueOut.collateral;
        state.totalDebtCreated += dueOut.debt;

        state.x -= param.xDecrease;
        state.y += param.yIncrease;
        state.z += param.zIncrease;

        pool.state = state;

        assetOut = param.xDecrease;
        assetOut -= feeStoredIncrease;
        assetOut -= protocolFeeStoredIncrease;

        asset.safeTransfer(param.assetTo, assetOut);

        Callback.borrow(collateral, dueOut.collateral, param.data);

        emit Sync(param.maturity, pool.state.x, pool.state.y, pool.state.z);
        emit Borrow(
            param.maturity, 
            msg.sender, 
            param.assetTo, 
            param.dueTo, 
            assetOut, 
            id, 
            dueOut,
            feeStoredIncrease,
            protocolFeeStoredIncrease
        );
    }

    /// @inheritdoc IPair
    function pay(PayParam calldata param)
        external 
        override 
        nonReentrant 
        returns (
            uint128 assetIn, 
            uint128 collateralOut
        ) 
    {
        require(block.timestamp < param.maturity, 'E202');
        require(param.owner != address(0), 'E201');
        require(param.to != address(0), 'E201');
        require(param.to != address(this), 'E204');
        
        uint256 length = param.ids.length;
        require(length== param.assetsIn.length, 'E205');
        require(length == param.collateralsOut.length, 'E205');

        Pool storage pool = pools[param.maturity];

        Due[] storage dues = pool.dues[param.owner];
        require(dues.length >= length, 'E205');

        for (uint256 i; i < length;) {
            Due storage due = dues[param.ids[i]];
            require(due.startBlock != BlockNumber.get(), 'E207');

            uint112 _assetIn = param.assetsIn[i];
            uint112 _collateralOut = param.collateralsOut[i];

            if (param.owner != msg.sender) require(_collateralOut == 0, 'E213');
            require(uint256(_assetIn) * due.collateral >= uint256(_collateralOut) * due.debt, 'E303');
            
            due.debt -= _assetIn;
            due.collateral -= _collateralOut;
            assetIn += _assetIn;
            collateralOut += _collateralOut;

            unchecked { ++i; }
        }

        pool.state.reserves.asset += assetIn;
        pool.state.reserves.collateral -= collateralOut;

        if (collateralOut != 0) collateral.safeTransfer(param.to, collateralOut);

        if (assetIn != 0) Callback.pay(asset, assetIn, param.data);

        emit Pay(
            param.maturity, 
            msg.sender, 
            param.to, 
            param.owner, 
            param.ids, 
            param.assetsIn, 
            param.collateralsOut, 
            assetIn, 
            collateralOut
        );
    }

    /// @inheritdoc IPair
    function collectProtocolFee(address to) external override nonReentrant returns (uint256 protocolFeeOut) {
        require(msg.sender == factory.owner(), 'E216');
        require(to != address(0), 'E201');

        protocolFeeOut = protocolFeeStored;
        protocolFeeStored = 0;

        asset.safeTransfer(to, protocolFeeOut);

        emit CollectProtocolFee(msg.sender, to, protocolFeeOut);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

import {IPair} from '../interfaces/IPair.sol';
import {Math} from './Math.sol';
import {FullMath} from './FullMath.sol';
import {ConstantProduct} from './ConstantProduct.sol';
import {SafeCast} from './SafeCast.sol';
import {BlockNumber} from './BlockNumber.sol';

library TimeswapMath {
    using Math for uint256;
    using FullMath for uint256;
    using ConstantProduct for IPair.State;
    using SafeCast for uint256;

    uint256 private constant BASE = 0x10000000000;

    function mint(
        uint256 maturity,
        IPair.State memory state,
        uint112 xIncrease, 
        uint112 yIncrease, 
        uint112 zIncrease
    ) 
        external 
        view 
        returns(
            uint256 liquidityOut,
            IPair.Due memory dueOut,
            uint256 feeStoredIncrease
        )
    {
        if (state.totalLiquidity == 0) {
            liquidityOut = xIncrease;
            liquidityOut <<= 16;
        } else {
            uint256 fromX = state.totalLiquidity.mulDiv(xIncrease, state.x);
            uint256 fromY = state.totalLiquidity.mulDiv(yIncrease, state.y);
            uint256 fromZ = state.totalLiquidity.mulDiv(zIncrease, state.z);

            require(fromY <= fromX,'E214');
            require(fromZ <= fromX, 'E215');

            liquidityOut = fromY <= fromZ ? fromY : fromZ;

            feeStoredIncrease = state.feeStored.mulDivUp(liquidityOut, state.totalLiquidity);
        }

        uint256 _debtIn = maturity;
        _debtIn -= block.timestamp;
        _debtIn *= yIncrease;
        _debtIn = _debtIn.shiftRightUp(32);
        _debtIn += xIncrease;
        dueOut.debt = _debtIn.toUint112();

        uint256 _collateralIn = maturity;
        _collateralIn -= block.timestamp; 
        _collateralIn *= zIncrease;
        _collateralIn = _collateralIn.shiftRightUp(25); 
        _collateralIn += zIncrease; 
        dueOut.collateral = _collateralIn.toUint112();

        dueOut.startBlock = BlockNumber.get();
    }

    function burn(
        IPair.State memory state,
        uint256 liquidityIn
    )
        external
        pure
        returns (
            uint128 assetOut,
            uint128 collateralOut,
            uint256 feeOut
        )
    {
        uint256 totalAsset = state.reserves.asset;
        uint256 totalCollateral = state.reserves.collateral;
        uint256 totalBond = state.totalClaims.bondPrincipal;
        totalBond += state.totalClaims.bondInterest;

        if (totalAsset >= totalBond) {
            uint256 _assetOut = totalAsset;
            unchecked { _assetOut -= totalBond; }
            _assetOut = _assetOut.mulDiv(liquidityIn, state.totalLiquidity);
            assetOut = _assetOut.toUint128();

            uint256 _collateralOut = totalCollateral;
            _collateralOut = _collateralOut.mulDiv(liquidityIn, state.totalLiquidity);
            collateralOut = _collateralOut.toUint128();
        } else {
            uint256 deficit = totalBond;
            unchecked { deficit -= totalAsset; }

            uint256 totalInsurance = state.totalClaims.insurancePrincipal;
            totalInsurance += state.totalClaims.insuranceInterest;

            if (totalCollateral * totalBond > deficit * totalInsurance) {
                uint256 _collateralOut = totalCollateral;
                uint256 subtrahend = deficit;
                subtrahend *= totalInsurance;
                subtrahend = subtrahend.divUp(totalBond);
                _collateralOut -= subtrahend;
                _collateralOut = _collateralOut.mulDiv(liquidityIn, state.totalLiquidity);
                collateralOut = _collateralOut.toUint128();
            }
        }

        feeOut = state.feeStored.mulDiv(liquidityIn, state.totalLiquidity);
    }

    function lend(
        uint256 maturity,
        IPair.State memory state,
        uint112 xIncrease,
        uint112 yDecrease,
        uint112 zDecrease,
        uint256 fee,
        uint256 protocolFee
    )
        external
        view
        returns (
            IPair.Claims memory claimsOut,
            uint256 feeStoredIncrease,
            uint256 protocolFeeStoredIncrease
        ) 
    {   
        lendCheck(state, xIncrease, yDecrease, zDecrease);

        claimsOut.bondPrincipal = xIncrease;
        claimsOut.bondInterest = getBondInterest(maturity, yDecrease);
        claimsOut.insurancePrincipal = getInsurancePrincipal(state, xIncrease);
        claimsOut.insuranceInterest = getInsuranceInterest(maturity, zDecrease);

        (feeStoredIncrease, protocolFeeStoredIncrease) = lendGetFees(
            maturity,
            xIncrease,
            fee,
            protocolFee
        );
    }

    function lendCheck(
        IPair.State memory state,
        uint112 xIncrease,
        uint112 yDecrease,
        uint112 zDecrease
    ) private pure {
        uint112 xReserve = state.x + xIncrease;
        uint112 yReserve = state.y - yDecrease;
        uint112 zReserve = state.z - zDecrease;
        state.checkConstantProduct(xReserve, yReserve, zReserve);

        uint256 yMin = xIncrease;
        yMin *= state.y;
        yMin /= xReserve;
        yMin >>= 4;
        require(yDecrease >= yMin, 'E217');
    }

    function getBondInterest(
        uint256 maturity,
        uint112 yDecrease
    ) private view returns (uint112 bondInterestOut) {
        uint256 _bondInterestOut = maturity;
        _bondInterestOut -= block.timestamp;
        _bondInterestOut *= yDecrease;
        _bondInterestOut >>= 32;
        bondInterestOut = _bondInterestOut.toUint112();
    }

    function getInsurancePrincipal(
        IPair.State memory state,
        uint112 xIncrease
    ) private pure returns (uint112 insurancePrincipalOut) {
        uint256 _insurancePrincipalOut = state.z;
        _insurancePrincipalOut *= xIncrease;
        uint256 denominator = state.x;
        denominator += xIncrease;
        _insurancePrincipalOut /= denominator;
        insurancePrincipalOut = _insurancePrincipalOut.toUint112();
    }

    function getInsuranceInterest(
        uint256 maturity,
        uint112 zDecrease
    ) private view returns (uint112 insuranceInterestOut) {
        uint256 _insuranceInterestOut = maturity;
        _insuranceInterestOut -= block.timestamp;
        _insuranceInterestOut *= zDecrease;
        _insuranceInterestOut >>= 25;
        insuranceInterestOut = _insuranceInterestOut.toUint112();
    }

    function lendGetFees(
        uint256 maturity,
        uint112 xIncrease,
        uint256 fee,
        uint256 protocolFee
    ) private view returns (
        uint256 feeStoredIncrease,
        uint256 protocolFeeStoredIncrease
        )
    {
        uint256 totalFee = fee;
        totalFee += protocolFee;

        uint256 numerator = maturity;
        numerator -= block.timestamp;
        numerator *= totalFee;
        numerator += BASE;

        uint256 adjusted = xIncrease;
        adjusted *= numerator;
        adjusted = adjusted.divUp(BASE);
        uint256 totalFeeStoredIncrease = adjusted;
        unchecked { totalFeeStoredIncrease -= xIncrease; }

        feeStoredIncrease = totalFeeStoredIncrease;
        feeStoredIncrease *= fee;
        feeStoredIncrease /= totalFee;
        protocolFeeStoredIncrease = totalFeeStoredIncrease;
        unchecked { protocolFeeStoredIncrease -= feeStoredIncrease; }
    }

    function withdraw(
        IPair.State memory state,
        IPair.Claims memory claimsIn
    ) external pure returns (IPair.Tokens memory tokensOut) {
        uint256 totalAsset = state.reserves.asset;
        uint256 totalBondPrincipal = state.totalClaims.bondPrincipal;
        uint256 totalBondInterest = state.totalClaims.bondInterest;
        uint256 totalBond = totalBondPrincipal;
        totalBond += totalBondInterest;

        if (totalAsset >= totalBond) {
            tokensOut.asset = claimsIn.bondPrincipal;
            tokensOut.asset += claimsIn.bondInterest;
        } else {
            if (totalAsset >= totalBondPrincipal) {
                uint256 remaining = totalAsset;
                unchecked { remaining -= totalBondPrincipal; }
                uint256 _assetOut = claimsIn.bondInterest;
                _assetOut *= remaining;
                _assetOut /= totalBondInterest;
                _assetOut += claimsIn.bondPrincipal;
                tokensOut.asset = _assetOut.toUint128();
            } else {
                uint256 _assetOut = claimsIn.bondPrincipal;
                _assetOut *= totalAsset;
                _assetOut /= totalBondPrincipal;
                tokensOut.asset = _assetOut.toUint128();
            }
            
            uint256 deficit = totalBond;
            unchecked { deficit -= totalAsset; }

            uint256 totalInsurancePrincipal = state.totalClaims.insurancePrincipal;
            totalInsurancePrincipal *= deficit;
            uint256 totalInsuranceInterest = state.totalClaims.insuranceInterest;
            totalInsuranceInterest *= deficit;
            uint256 totalInsurance = totalInsurancePrincipal;
            totalInsurance += totalInsuranceInterest;

            uint256 totalCollateral = state.reserves.collateral;
            totalCollateral *= totalBond;

            if (totalCollateral >= totalInsurance) {
                uint256 _collateralOut = claimsIn.insurancePrincipal;
                _collateralOut += claimsIn.insuranceInterest;
                _collateralOut *= deficit;
                _collateralOut /= totalBond;
                tokensOut.collateral = _collateralOut.toUint128();
            } else if (totalCollateral >= totalInsurancePrincipal) {
                uint256 remaining = totalCollateral;
                unchecked { remaining -= totalInsurancePrincipal; }
                uint256 _collateralOut = claimsIn.insuranceInterest;
                _collateralOut *= deficit;
                uint256 denominator = totalInsuranceInterest;
                denominator *= totalBond;
                _collateralOut = _collateralOut.mulDiv(remaining, denominator);
                uint256 addend = claimsIn.insurancePrincipal;
                addend *= deficit;
                addend /= totalBond;
                _collateralOut += addend;
                tokensOut.collateral = _collateralOut.toUint128();
            } else {
                uint256 _collateralOut = claimsIn.insurancePrincipal;
                _collateralOut *= deficit;
                uint256 denominator = totalInsurancePrincipal;
                denominator *= totalBond;
                _collateralOut = _collateralOut.mulDiv(totalCollateral, denominator);
                tokensOut.collateral = _collateralOut.toUint128();
            }
        }
    }

    function borrow(
        uint256 maturity,
        IPair.State memory state,
        uint112 xDecrease,
        uint112 yIncrease,
        uint112 zIncrease,
        uint256 fee,
        uint256 protocolFee
    )
        external
        view
        returns (
            IPair.Due memory dueOut,
            uint256 feeStoredIncrease,
            uint256 protocolFeeStoredIncrease
        )
    {
        borrowCheck(state, xDecrease, yIncrease, zIncrease);

        dueOut.debt = getDebt(maturity, xDecrease, yIncrease);
        dueOut.collateral = getCollateral(maturity, state, xDecrease, zIncrease);
        dueOut.startBlock = BlockNumber.get();

        (feeStoredIncrease, protocolFeeStoredIncrease) = borrowGetFees(
            maturity,
            xDecrease,
            fee,
            protocolFee
        );
    }

    function borrowCheck(
        IPair.State memory state,
        uint112 xDecrease,
        uint112 yIncrease,
        uint112 zIncrease
    ) private pure {
        uint112 xReserve = state.x - xDecrease;
        uint112 yReserve = state.y + yIncrease;
        uint112 zReserve = state.z + zIncrease;
        state.checkConstantProduct(xReserve, yReserve, zReserve);

        uint256 yMax = xDecrease;
        yMax *= state.y;
        yMax = yMax.divUp(xReserve);
        require(yIncrease <= yMax, 'E214');

        uint256 zMax = xDecrease;
        zMax *= state.z;
        zMax = zMax.divUp(xReserve);
        require(zIncrease <= zMax, 'E215');

        uint256 yMin = yMax;
        yMin = yMin.shiftRightUp(4);
        require(yIncrease >= yMin, 'E217');
    }

    function getDebt(
        uint256 maturity,
        uint112 xDecrease,
        uint112 yIncrease
    ) private view returns (uint112 debtIn) {
        uint256 _debtIn = maturity;
        _debtIn -= block.timestamp;
        _debtIn *= yIncrease;
        _debtIn = _debtIn.shiftRightUp(32);
        _debtIn += xDecrease;
        debtIn = _debtIn.toUint112();
    }

    function getCollateral(
        uint256 maturity,
        IPair.State memory state,
        uint112 xDecrease,
        uint112 zIncrease
    ) private view returns (uint112 collateralIn) {
        uint256 _collateralIn = maturity;
        _collateralIn -= block.timestamp;
        _collateralIn *= zIncrease;
        _collateralIn = _collateralIn.shiftRightUp(25);
        uint256 minimum = state.z;
        minimum *= xDecrease;
        uint256 denominator = state.x;
        denominator -= xDecrease;
        minimum = minimum.divUp(denominator);
        _collateralIn += minimum;
        collateralIn = _collateralIn.toUint112();
    }

    function borrowGetFees(
        uint256 maturity,
        uint112 xDecrease,
        uint256 fee,
        uint256 protocolFee
    ) private view returns (
            uint256 feeStoredIncrease,
            uint256 protocolFeeStoredIncrease
        )
    {

        uint256 totalFee = fee;
        totalFee += protocolFee;

        uint256 denominator = maturity;
        denominator -= block.timestamp;
        denominator *= totalFee;
        denominator += BASE;

        uint256 adjusted = xDecrease;
        adjusted *= BASE;
        adjusted /= denominator;
        uint256 totalFeeStoredIncrease = xDecrease;
        unchecked { totalFeeStoredIncrease -= adjusted; }

        feeStoredIncrease = totalFeeStoredIncrease;
        feeStoredIncrease *= fee;
        feeStoredIncrease /= totalFee;
        protocolFeeStoredIncrease = totalFeeStoredIncrease;
        unchecked { protocolFeeStoredIncrease -= feeStoredIncrease; }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;

import {IPair} from '../interfaces/IPair.sol';

library Array {
    function insert(IPair.Due[] storage dues, IPair.Due memory dueOut) internal returns (uint256 id) {
        id = dues.length;   
        
        dues.push(dueOut);
        
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ITimeswapMintCallback} from '../interfaces/callback/ITimeswapMintCallback.sol';
import {ITimeswapLendCallback} from '../interfaces/callback/ITimeswapLendCallback.sol';
import {ITimeswapBorrowCallback} from '../interfaces/callback/ITimeswapBorrowCallback.sol';
import {ITimeswapPayCallback} from '../interfaces/callback/ITimeswapPayCallback.sol';
import {SafeBalance} from './SafeBalance.sol';
import {SafeCast} from './SafeCast.sol';

library Callback {
    using SafeBalance for IERC20;
    using SafeCast for uint256;

    function mint(
        IERC20 asset,
        IERC20 collateral,
        uint256 assetIn,
        uint112 collateralIn,
        bytes calldata data
    ) internal {
        uint256 assetReserve = asset.safeBalance();
        uint256 collateralReserve = collateral.safeBalance();
        ITimeswapMintCallback(msg.sender).timeswapMintCallback(assetIn, collateralIn, data);
        uint256 _assetReserve = asset.safeBalance();
        uint256 _collateralReserve = collateral.safeBalance();
        require(_assetReserve >= assetReserve + assetIn, 'E304');
        require(_collateralReserve >= collateralReserve + collateralIn, 'E305');
    }

    function lend(
        IERC20 asset,
        uint256 assetIn,
        bytes calldata data
    ) internal {
        uint256 assetReserve = asset.safeBalance();
        ITimeswapLendCallback(msg.sender).timeswapLendCallback(assetIn, data);
        uint256 _assetReserve = asset.safeBalance();
        require(_assetReserve >= assetReserve + assetIn, 'E304');
    }

    function borrow(
        IERC20 collateral,
        uint112 collateralIn,
        bytes calldata data
    ) internal {
        uint256 collateralReserve = collateral.safeBalance();
        ITimeswapBorrowCallback(msg.sender).timeswapBorrowCallback(collateralIn, data);
        uint256 _collateralReserve = collateral.safeBalance();
        require(_collateralReserve >= collateralReserve + collateralIn, 'E305');
    }
    
    function pay(
        IERC20 asset,
        uint128 assetIn,
        bytes calldata data
    ) internal {
        uint256 assetReserve = asset.safeBalance();
        ITimeswapPayCallback(msg.sender).timeswapPayCallback(assetIn, data);
        uint256 _assetReserve = asset.safeBalance();
        require(_assetReserve >= assetReserve + assetIn, 'E304');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;

library BlockNumber {
    function get() internal view returns (uint32 blockNumber) {
        // can overflow
        blockNumber = uint32(block.number);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;

library Math {
    function divUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x / y;
        if (x % y != 0) z++;
    }

    function shiftRightUp(uint256 x, uint8 y) internal pure returns (uint256 z) {
        z = x >> y;
        if (x != z << y) z++;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

library FullMath {
    function mul512(uint256 a, uint256 b) internal pure returns (uint256 prod0, uint256 prod1) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }
    }
    
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            (uint256 prod0, uint256 prod1) = mul512(a, b);

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator != 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos;
            twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;    

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv;
            inv = (3 * denominator) ^ 2;

            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;

            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) != 0) result++;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

import {IPair} from '../interfaces/IPair.sol';
import {FullMath} from './FullMath.sol';

library ConstantProduct {
    using FullMath for uint256;

    function checkConstantProduct(
        IPair.State memory state,
        uint112 xReserve,
        uint128 yAdjusted,
        uint128 zAdjusted
    ) internal pure {

        (uint256 prod0, uint256 prod1) = (uint256(yAdjusted) * zAdjusted).mul512(xReserve);
        (uint256 _prod0, uint256 _prod1) = ((uint256(state.y) * state.z)).mul512(state.x);

        require(prod1 >= _prod1, 'E301');
        if (prod1 == _prod1) require(prod0 >= _prod0, 'E301');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;

library SafeCast {    
    function toUint112(uint256 x) internal pure returns (uint112 y) {
        require(x <= type(uint112).max);
        y = uint112(x);
    }

    function toUint128(uint256 x) internal pure returns (uint128 y) {
        require(x <= type(uint128).max);
        y = uint128(x);
    }

    function truncateUint112(uint256 x) internal pure returns (uint112 y) {
        if (x > type(uint112).max) return y = type(uint112).max;
        y = uint112(x);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;

/// @title Callback for ITimeswapPair#mint
/// @notice Any contract that calls ITimeswapPair#mint must implement this interface
interface ITimeswapMintCallback {
    /// @notice Called to `msg.sender` after initiating a mint from ITimeswapPair#mint.
    /// @dev In the implementation you must pay the asset token and collateral token owed for the mint transaction.
    /// The caller of this method must be checked to be a TimeswapPair deployed by the canonical TimeswapFactory.
    /// @param assetIn The amount of asset tokens owed due to the pool for the mint transaction.
    /// @param collateralIn The amount of collateral tokens owed due to the pool for the min transaction.
    /// @param data Any data passed through by the caller via the ITimeswapPair#mint call
    function timeswapMintCallback(
        uint256 assetIn,
        uint112 collateralIn,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;

/// @title Callback for ITimeswapPair#lend
/// @notice Any contract that calls ITimeswapPair#lend must implement this interface
interface ITimeswapLendCallback {
    /// @notice Called to `msg.sender` after initiating a lend from ITimeswapPair#lend.
    /// @dev In the implementation you must pay the asset token owed for the lend transaction.
    /// The caller of this method must be checked to be a TimeswapPair deployed by the canonical TimeswapFactory.
    /// @param assetIn The amount of asset tokens owed due to the pool for the lend transaction
    /// @param data Any data passed through by the caller via the ITimeswapPair#lend call
    function timeswapLendCallback(
        uint256 assetIn,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;

/// @title Callback for ITimeswapPair#borrow
/// @notice Any contract that calls ITimeswapPair#borrow must implement this interface
interface ITimeswapBorrowCallback {
    /// @notice Called to `msg.sender` after initiating a borrow from ITimeswapPair#borrow.
    /// @dev In the implementation you must pay the collateral token owed for the borrow transaction.
    /// The caller of this method must be checked to be a TimeswapPair deployed by the canonical TimeswapFactory.
    /// @param collateralIn The amount of asset tokens owed due to the pool for the borrow transaction
    /// @param data Any data passed through by the caller via the ITimeswapPair#borrow call
    function timeswapBorrowCallback(
        uint112 collateralIn,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;

/// @title Callback for ITimeswapPair#pay
/// @notice Any contract that calls ITimeswapPair#pay must implement this interface
interface ITimeswapPayCallback {
    /// @notice Called to `msg.sender` after initiating a pay from ITimeswapPair#pay.
    /// @dev In the implementation you must pay the asset token owed for the pay transaction.
    /// The caller of this method must be checked to be a TimeswapPair deployed by the canonical TimeswapFactory.
    /// @param assetIn The amount of asset tokens owed due to the pool for the pay transaction
    /// @param data Any data passed through by the caller via the ITimeswapPair#pay call
    function timeswapPayCallback(
        uint128 assetIn,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';

library SafeBalance {
    using Address for address;

    function safeBalance(
        IERC20 token
    ) internal view returns (uint256) {
        bytes memory data =
            address(token).functionStaticCall(
                abi.encodeWithSelector(IERC20.balanceOf.selector, address(this)),
                "Failed ERC20 balanceOf"
            );
        return abi.decode(data, (uint256));
    }
}