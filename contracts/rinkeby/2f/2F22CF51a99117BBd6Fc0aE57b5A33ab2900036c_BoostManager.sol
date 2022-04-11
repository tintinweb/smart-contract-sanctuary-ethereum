//SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../otokens/interfaces/IOToken.sol";
import "../interfaces/IComptroller.sol";

contract BoostManager is Ownable {
    bool public init; //todo set to true when using proxy
    uint256 private constant MULTIPLIER = 10**18;

    IERC20 public veOVIX;
    IComptroller public comptroller;

    mapping(address => bool) public authorized;
    // market => user => supply boostBasis
    mapping(address => mapping(address => uint256)) public supplyBoosterBasis;
    // market => user => borrow boostBasis
    mapping(address => mapping(address => uint256)) public borrowBoosterBasis;
    // market => user => old supply balance deltas
    mapping(address => mapping(address => uint256))
        public oldSupplyBalanceDeltas;
    // market => user => old borrow balance deltas
    mapping(address => mapping(address => uint256))
        public oldBorrowBalanceDeltas;
    // user => veBalance
    mapping(address => uint256) public veBalances;

    mapping(address => uint256) private deltaTotalSupply;
    mapping(address => uint256) private deltaTotalBorrows;

    constructor(bool _init) {
        init = _init;
    }

    function initialize(
        IERC20 ve,
        IComptroller _comptroller,
        address _owner
    ) external {
        require(!init, "contract already initialized");
        init = true;
        veOVIX = ve;
        comptroller = _comptroller;
        _transferOwnership(_owner);
    }

    modifier onlyAuthorized() {
        require(
            authorized[msg.sender] || comptroller.isMarket(msg.sender),
            "sender is not authorized"
        );
        _;
    }

    /**
     * @notice Updates the boost basis of the user with the latest veBalance
     * @param user Address of the user which booster needs to be updated
     * @return The boolean value indicating whether the user still has the booster greater than 1.0
     */
    function updateBoostBasis(address user)
        external
        onlyAuthorized
        returns (bool)
    {
        IOToken[] memory markets = comptroller.getAllMarkets();

        veBalances[user] = veOVIX.balanceOf(user);
        for (uint256 i = 0; i < markets.length; i++) {
            _updateBoostBasisPerMarket(address(markets[i]), user);
        }

        return veBalances[user] == 0 ? false : true;
    }

    function _updateBoostBasisPerMarket(address market, address user) internal {
        uint256 userSupply = IOToken(market).balanceOf(user);
        uint256 userBorrows = IOToken(market).borrowBalanceStored(user);
        if (userSupply > 0) {
            comptroller.updateAndDistributeSupplierRewardsForToken(
                market,
                user
            );
            _updateSupplyBoostBasis(market, user);
            _updateBoostBalance(
                market,
                user,
                userSupply,
                supplyBoosterBasis[market][user],
                0
            );
        }
        if (userBorrows > 0) {
            comptroller.updateAndDistributeBorrowerRewardsForToken(
                market,
                user
            );
            _updateBorrowBoostBasis(market, user);
            _updateBoostBalance(
                market,
                user,
                userBorrows,
                borrowBoosterBasis[market][user],
                1
            );
        }
    }

    function _updateSupplyBoostBasis(address market, address user) internal {
        supplyBoosterBasis[market][user] = calcBoostBasis(market, 0);
        emit BoostBasisUpdated(
            user,
            market,
            supplyBoosterBasis[market][user],
            0
        );
    }

    function _updateBorrowBoostBasis(address market, address user) internal {
        borrowBoosterBasis[market][user] = calcBoostBasis(market, 1);
        emit BoostBasisUpdated(
            user,
            market,
            borrowBoosterBasis[market][user],
            1
        );
    }

    // call from oToken
    function updateBoostSupplyBalances(
        address market,
        address user,
        uint256 oldBalance, // todo: removing oldbalance: needs to be updated in oToken too. keep it until updating the oToken is necessary
        uint256 newBalance
    ) external onlyAuthorized {
        _updateBoostBalance(
            market,
            user,
            newBalance,
            supplyBoosterBasis[market][user],
            0
        );
    }

    function updateBoostBorrowBalances(
        address market,
        address user,
        uint256 oldBalance, // todo: removing oldbalance: needs to be updated in oToken too. keep it until updating the oToken is necessary
        uint256 newBalance
    ) external onlyAuthorized {
        _updateBoostBalance(
            market,
            user,
            newBalance,
            borrowBoosterBasis[market][user],
            1
        );
    }

    function _updateBoostBalance(
        address market,
        address user,
        uint256 newBalance,
        uint256 newBoostBasis,
        uint256 marketType
    ) internal {
        if (marketType == 0) {
            uint256 deltaOldBalance = oldSupplyBalanceDeltas[market][user];
            uint256 deltaNewBalance = calcBoostedBalance(
                user,
                newBoostBasis,
                newBalance
            ) - newBalance;

            deltaTotalSupply[market] =
                deltaTotalSupply[market] +
                deltaNewBalance -
                deltaOldBalance;
            emit BoostedBalanceUpdated(
                user,
                market,
                deltaOldBalance,
                deltaNewBalance,
                deltaTotalSupply[market],
                marketType
            );
            oldSupplyBalanceDeltas[market][user] = deltaNewBalance;
        } else {
            uint256 deltaOldBalance = oldBorrowBalanceDeltas[market][user];
            uint256 deltaNewBalance = calcBoostedBalance(
                user,
                newBoostBasis,
                newBalance
            ) - newBalance;

            deltaTotalBorrows[market] =
                deltaTotalBorrows[market] +
                deltaNewBalance -
                deltaOldBalance;
            emit BoostedBalanceUpdated(
                user,
                market,
                deltaOldBalance,
                deltaNewBalance,
                deltaTotalBorrows[market],
                marketType
            );
            oldBorrowBalanceDeltas[market][user] = deltaNewBalance;
        }
    }

    // marketType: 0 = supply, 1 = borrow
    // boost basis = totalVeSupply/marketLiquidity
    function calcBoostBasis(address market, uint256 marketType)
        internal
        view
        returns (uint256)
    {
        require(marketType <= 1, "wrong market type");

        if (marketType == 0) {
            if (IOToken(market).totalSupply() == 0) return 0;
            return ((veOVIX.totalSupply() * MULTIPLIER) /
                IOToken(market).totalSupply());
        } else {
            if (IOToken(market).totalBorrows() == 0) return 0;
            return ((veOVIX.totalSupply() * MULTIPLIER) /
                IOToken(market).totalBorrows());
        }
    }

    // booster: if(veBalanceOfUser >= boostBasis * userBalance) = 2.5
    // booster: else: 1.5*veBalanceOfUser/(boostBasis * userBalance) + 1 = [1 <= booster < 2.5]
    // bosted balance = booster * userBalance
    function calcBoostedBalance(
        address user,
        uint256 boosterBasis,
        uint256 balance
    ) internal view returns (uint256) {
        if (veBalances[user] == 0 || boosterBasis == 0) return balance;

        uint256 minVe = (boosterBasis * balance) / MULTIPLIER;

        uint256 booster;

        if (veBalances[user] >= minVe) {
            booster = 25 * MULTIPLIER; // = 2,5
        } else {
            booster =
                ((15 * MULTIPLIER * veBalances[user]) / minVe) +
                10 *
                MULTIPLIER; // 1.5 * veBalance / minVe + 1;
        }
        return ((balance * booster) / (10 * MULTIPLIER));
    }

    function boostedSupplyBalanceOf(address market, address user)
        public
        view
        returns (uint256)
    {
        return (
            calcBoostedBalance(
                user,
                supplyBoosterBasis[market][user],
                IOToken(market).balanceOf(user)
            )
        );
    }

    function boostedBorrowBalanceOf(address market, address user)
        public
        view
        returns (uint256)
    {
        return (
            calcBoostedBalance(
                user,
                borrowBoosterBasis[market][user],
                IOToken(market).borrowBalanceStored(user)
            )
        );
    }

    function boostedTotalSupply(address market)
        external
        view
        returns (uint256)
    {
        return (IOToken(market).totalSupply() + deltaTotalSupply[market]);
    }

    function boostedTotalBorrows(address market)
        external
        view
        returns (uint256)
    {
        return (IOToken(market).totalBorrows() + deltaTotalBorrows[market]);
    }

    function setAuthorized(address addr, bool flag) external onlyOwner {
        authorized[addr] = flag;
        emit AuthorizedUpdated(addr, flag);
    }

    function isAuthorized(address addr) external view returns (bool) {
        return authorized[addr];
    }

    function setVeOVIX(IERC20 ve) external onlyOwner {
        veOVIX = ve;
        emit VeOVIXUpdated(veOVIX);
    }

    event BoostBasisUpdated(
        address indexed user,
        address indexed market,
        uint256 boostBasis,
        uint256 marketType
    );

    event BoostedBalanceUpdated(
        address indexed user,
        address indexed market,
        uint256 deltaOldBalance,
        uint256 deltaNewBalance,
        uint256 deltaTotal,
        uint256 marketType
    );

    event AuthorizedUpdated(address indexed addr, bool flag);
    event VeOVIXUpdated(IERC20 ve);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../interfaces/IComptroller.sol";
import "../../interest-rate-models/interfaces/IInterestRateModel.sol";
import "./IEIP20NonStandard.sol";
import "./IEIP20.sol";

interface IOToken is IEIP20{
    /**
     * @notice Indicator that this is a OToken contract (for inspection)
     */
    function isOToken() external view returns(bool);


    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address oTokenCollateral, uint seizeTokens);


    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when comptroller is changed
     */
    event NewComptroller(IComptroller oldComptroller, IComptroller newComptroller);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(IInterestRateModel oldInterestRateModel, IInterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

    /**
     * @notice Event emitted when the protocol seize share is changed
     */
    event NewProtocolSeizeShare(uint oldProtocolSeizeShareMantissa, uint newProtocolSeizeShareMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);

    function accrualBlockTimestamp() external returns(uint256);

    /*** User Interface ***/
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerTimestamp() external view returns (uint);
    function supplyRatePerTimestamp() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);

    function totalBorrows() external view returns(uint);
    function comptroller() external view returns(IComptroller);
    function borrowIndex() external view returns(uint);
    function reserveFactorMantissa() external view returns(uint);


    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint);
    function _acceptAdmin() external returns (uint);
    function _setComptroller(IComptroller newComptroller) external returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) external returns (uint);
    function _reduceReserves(uint reduceAmount) external returns (uint);
    function _setInterestRateModel(IInterestRateModel newInterestRateModel) external returns (uint);
    function _setProtocolSeizeShare(uint newProtocolSeizeShareMantissa) external returns (uint);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../otokens/interfaces/IOToken.sol";
import "../PriceOracle.sol";

interface IComptroller {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    function isComptroller() external view returns(bool);

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata oTokens) external returns (uint[] memory);
    function exitMarket(address oToken) external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address oToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(address oToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address oToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address oToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address oToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowVerify(address oToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address oToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);

    function liquidateBorrowAllowed(
        address oTokenBorrowed,
        address oTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);

    function seizeAllowed(
        address oTokenCollateral,
        address oTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);
        
    function seizeVerify(
        address oTokenCollateral,
        address oTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address oToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(address oToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address oTokenBorrowed,
        address oTokenCollateral,
        uint repayAmount) external view returns (uint, uint);



    function isMarket(address market) external view returns(bool);
    function getBoostManager() external view returns(address);
    function getAllMarkets() external view returns(IOToken[] memory);
    function oracle() external view returns(PriceOracle);

    function updateAndDistributeSupplierRewardsForToken(
        address oToken,
        address account
    ) external;

    function updateAndDistributeBorrowerRewardsForToken(
        address oToken,
        address borrower
    ) external;

    function _setRewardSpeeds(
        address[] memory oTokens,
        uint256[] memory supplySpeeds,
        uint256[] memory borrowSpeeds
    ) external;
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
  * @title 0VIX's IInterestRateModel Interface
  * @author 0VIX
  */
interface IInterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    function isInterestRateModel() external view returns(bool);

    /**
      * @notice Calculates the current borrow interest rate per timestmp
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @return The borrow rate per timestmp (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns (uint);

    /**
      * @notice Calculates the current supply interest rate per timestmp
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per timestmp (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view returns (uint);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title IEIP20NonStandard
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface IEIP20NonStandard {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface IEIP20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return success Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return success Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./otokens/interfaces/IOToken.sol";

abstract contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /**
      * @notice Get the underlying price of a oToken asset
      * @param oToken The oToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(IOToken oToken) external virtual view returns (uint);
}