// SPDX-License-Identifier: UNLICENSED

// Cauldron

//    (                (   (
//    )\      )    (   )\  )\ )  (
//  (((_)  ( /(   ))\ ((_)(()/(  )(    (    (
//  )\___  )(_)) /((_) _   ((_))(()\   )\   )\ )
// ((/ __|((_)_ (_))( | |  _| |  ((_) ((_) _(_/(
//  | (__ / _` || || || |/ _` | | '_|/ _ \| ' \))
//   \___|\__,_| \_,_||_|\__,_| |_|  \___/|_||_|

// Copyright (c) 2021 BoringCrypto - All rights reserved
// Twitter: @Boring_Crypto

// Special thanks to:
// @0xKeno - for all his invaluable contributions
// @burger_crypto - for the idea of trying to let the LPs benefit from liquidations

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@boringcrypto/boring-solidity/contracts/ERC20.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IMasterContract.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "./MagicInternetMoney.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/ISwapper.sol";

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

/// @title Cauldron
/// @dev This contract allows contract calls to any contract (except BentoBox)
/// from arbitrary callers thus, don't trust calls from this contract in any circumstances.
contract Cauldron is BoringOwnable, IMasterContract {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;

    event LogExchangeRate(uint256 rate);
    event LogAccrue(uint128 accruedAmount);
    event LogAddCollateral(address indexed from, address indexed to, uint256 share);
    event LogRemoveCollateral(address indexed from, address indexed to, uint256 share);
    event LogBorrow(address indexed from, address indexed to, uint256 amount, uint256 part);
    event LogRepay(address indexed from, address indexed to, uint256 amount, uint256 part);
    event LogFeeTo(address indexed newFeeTo);
    event LogWithdrawFees(address indexed feeTo, uint256 feesEarnedFraction);

    // Immutables (for MasterContract and all clones)
    IBentoBoxV1 public immutable bentoBox;
    Cauldron public immutable masterContract;
    IERC20 public immutable magicInternetMoney;

    // MasterContract variables
    address public feeTo;

    // Per clone variables
    // Clone init settings
    IERC20 public collateral;
    IOracle public oracle;
    bytes public oracleData;

    // Total amounts
    uint256 public totalCollateralShare; // Total collateral supplied
    Rebase public totalBorrow; // elastic = Total token amount to be repayed by borrowers, base = Total parts of the debt held by borrowers

    // User balances
    mapping(address => uint256) public userCollateralShare;
    mapping(address => uint256) public userBorrowPart;

    /// @notice Exchange and interest rate tracking.
    /// This is 'cached' here because calls to Oracles can be very expensive.
    uint256 public exchangeRate;

    struct AccrueInfo {
        uint64 lastAccrued;
        uint128 feesEarned;
    }

    AccrueInfo public accrueInfo;

    // Settings
    uint256 private constant INTEREST_PER_SECOND = 317097920;

    uint256 private constant COLLATERIZATION_RATE = 75000; // 75%
    uint256 private constant COLLATERIZATION_RATE_PRECISION = 1e5; // Must be less than EXCHANGE_RATE_PRECISION (due to optimization in math)

    uint256 private constant EXCHANGE_RATE_PRECISION = 1e18;

    uint256 private constant LIQUIDATION_MULTIPLIER = 112000; // add 12%
    uint256 private constant LIQUIDATION_MULTIPLIER_PRECISION = 1e5;

    uint256 private constant BORROW_OPENING_FEE = 50; // 0.05%
    uint256 private constant BORROW_OPENING_FEE_PRECISION = 1e5;

    /// @notice The constructor is only used for the initial master contract. Subsequent clones are initialised via `init`.
    constructor(IBentoBoxV1 bentoBox_, IERC20 magicInternetMoney_) public {
        bentoBox = bentoBox_;
        magicInternetMoney = magicInternetMoney_;
        masterContract = this;
    }

    /// @notice Serves as the constructor for clones, as clones can't have a regular constructor
    /// @dev `data` is abi encoded in the format: (IERC20 collateral, IERC20 asset, IOracle oracle, bytes oracleData)
    function init(bytes calldata data) public payable override {
        require(address(collateral) == address(0), "Cauldron: already initialized");
        (collateral, oracle, oracleData) = abi.decode(data, (IERC20, IOracle, bytes));
        require(address(collateral) != address(0), "Cauldron: bad pair");
    }

    /// @notice Accrues the interest on the borrowed tokens and handles the accumulation of fees.
    function accrue() public {
        AccrueInfo memory _accrueInfo = accrueInfo;
        // Number of seconds since accrue was called
        uint256 elapsedTime = block.timestamp - _accrueInfo.lastAccrued;
        if (elapsedTime == 0) {
            return;
        }
        _accrueInfo.lastAccrued = uint64(block.timestamp);

        Rebase memory _totalBorrow = totalBorrow;
        if (_totalBorrow.base == 0) {
            accrueInfo = _accrueInfo;
            return;
        }

        // Accrue interest
        uint128 extraAmount = (uint256(_totalBorrow.elastic).mul(INTEREST_PER_SECOND).mul(elapsedTime) / 1e18).to128();
        _totalBorrow.elastic = _totalBorrow.elastic.add(extraAmount);

        _accrueInfo.feesEarned = _accrueInfo.feesEarned.add(extraAmount);
        totalBorrow = _totalBorrow;
        accrueInfo = _accrueInfo;

        emit LogAccrue(extraAmount);
    }

    /// @notice Concrete implementation of `isSolvent`. Includes a third parameter to allow caching `exchangeRate`.
    /// @param _exchangeRate The exchange rate. Used to cache the `exchangeRate` between calls.
    function _isSolvent(address user, uint256 _exchangeRate) internal view returns (bool) {
        // accrue must have already been called!
        uint256 borrowPart = userBorrowPart[user];
        if (borrowPart == 0) return true;
        uint256 collateralShare = userCollateralShare[user];
        if (collateralShare == 0) return false;

        Rebase memory _totalBorrow = totalBorrow;

        return
            bentoBox.toAmount(
                collateral,
                collateralShare.mul(EXCHANGE_RATE_PRECISION / COLLATERIZATION_RATE_PRECISION).mul(COLLATERIZATION_RATE),
                false
            ) >=
            // Moved exchangeRate here instead of dividing the other side to preserve more precision
            borrowPart.mul(_totalBorrow.elastic).mul(_exchangeRate) / _totalBorrow.base;
    }

    /// @dev Checks if the user is solvent in the closed liquidation case at the end of the function body.
    modifier solvent() {
        _;
        require(_isSolvent(msg.sender, exchangeRate), "Cauldron: user insolvent");
    }

    /// @notice Gets the exchange rate. I.e how much collateral to buy 1e18 asset.
    /// This function is supposed to be invoked if needed because Oracle queries can be expensive.
    /// @return updated True if `exchangeRate` was updated.
    /// @return rate The new exchange rate.
    function updateExchangeRate() public returns (bool updated, uint256 rate) {
        (updated, rate) = oracle.get(oracleData);

        if (updated) {
            exchangeRate = rate;
            emit LogExchangeRate(rate);
        } else {
            // Return the old rate if fetching wasn't successful
            rate = exchangeRate;
        }
    }

    /// @dev Helper function to move tokens.
    /// @param token The ERC-20 token.
    /// @param share The amount in shares to add.
    /// @param total Grand total amount to deduct from this contract's balance. Only applicable if `skim` is True.
    /// Only used for accounting checks.
    /// @param skim If True, only does a balance check on this contract.
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    function _addTokens(
        IERC20 token,
        uint256 share,
        uint256 total,
        bool skim
    ) internal {
        if (skim) {
            require(share <= bentoBox.balanceOf(token, address(this)).sub(total), "Cauldron: Skim too much");
        } else {
            bentoBox.transfer(token, msg.sender, address(this), share);
        }
    }

    /// @notice Adds `collateral` from msg.sender to the account `to`.
    /// @param to The receiver of the tokens.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.x
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    /// @param share The amount of shares to add for `to`.
    function addCollateral(
        address to,
        bool skim,
        uint256 share
    ) public {
        userCollateralShare[to] = userCollateralShare[to].add(share);
        uint256 oldTotalCollateralShare = totalCollateralShare;
        totalCollateralShare = oldTotalCollateralShare.add(share);
        _addTokens(collateral, share, oldTotalCollateralShare, skim);
        emit LogAddCollateral(skim ? address(bentoBox) : msg.sender, to, share);
    }

    /// @dev Concrete implementation of `removeCollateral`.
    function _removeCollateral(address to, uint256 share) internal {
        userCollateralShare[msg.sender] = userCollateralShare[msg.sender].sub(share);
        totalCollateralShare = totalCollateralShare.sub(share);
        emit LogRemoveCollateral(msg.sender, to, share);
        bentoBox.transfer(collateral, address(this), to, share);
    }

    /// @notice Removes `share` amount of collateral and transfers it to `to`.
    /// @param to The receiver of the shares.
    /// @param share Amount of shares to remove.
    function removeCollateral(address to, uint256 share) public solvent {
        // accrue must be called because we check solvency
        accrue();
        _removeCollateral(to, share);
    }

    /// @dev Concrete implementation of `borrow`.
    function _borrow(address to, uint256 amount) internal returns (uint256 part, uint256 share) {
        uint256 feeAmount = amount.mul(BORROW_OPENING_FEE) / BORROW_OPENING_FEE_PRECISION; // A flat % fee is charged for any borrow
        (totalBorrow, part) = totalBorrow.add(amount.add(feeAmount), true);
        accrueInfo.feesEarned = accrueInfo.feesEarned.add(uint128(feeAmount));
        userBorrowPart[msg.sender] = userBorrowPart[msg.sender].add(part);

        // As long as there are tokens on this contract you can 'mint'... this enables limiting borrows
        share = bentoBox.toShare(magicInternetMoney, amount, false);
        bentoBox.transfer(magicInternetMoney, address(this), to, share);

        emit LogBorrow(msg.sender, to, amount.add(feeAmount), part);
    }

    /// @notice Sender borrows `amount` and transfers it to `to`.
    /// @return part Total part of the debt held by borrowers.
    /// @return share Total amount in shares borrowed.
    function borrow(address to, uint256 amount) public solvent returns (uint256 part, uint256 share) {
        accrue();
        (part, share) = _borrow(to, amount);
    }

    /// @dev Concrete implementation of `repay`.
    function _repay(
        address to,
        bool skim,
        uint256 part
    ) internal returns (uint256 amount) {
        (totalBorrow, amount) = totalBorrow.sub(part, true);
        userBorrowPart[to] = userBorrowPart[to].sub(part);

        uint256 share = bentoBox.toShare(magicInternetMoney, amount, true);
        bentoBox.transfer(magicInternetMoney, skim ? address(bentoBox) : msg.sender, address(this), share);
        emit LogRepay(skim ? address(bentoBox) : msg.sender, to, amount, part);
    }

    /// @notice Repays a loan.
    /// @param to Address of the user this payment should go.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    /// @param part The amount to repay. See `userBorrowPart`.
    /// @return amount The total amount repayed.
    function repay(
        address to,
        bool skim,
        uint256 part
    ) public returns (uint256 amount) {
        accrue();
        amount = _repay(to, skim, part);
    }

    // Functions that need accrue to be called
    uint8 internal constant ACTION_REPAY = 2;
    uint8 internal constant ACTION_REMOVE_COLLATERAL = 4;
    uint8 internal constant ACTION_BORROW = 5;
    uint8 internal constant ACTION_GET_REPAY_SHARE = 6;
    uint8 internal constant ACTION_GET_REPAY_PART = 7;
    uint8 internal constant ACTION_ACCRUE = 8;

    // Functions that don't need accrue to be called
    uint8 internal constant ACTION_ADD_COLLATERAL = 10;
    uint8 internal constant ACTION_UPDATE_EXCHANGE_RATE = 11;

    // Function on BentoBox
    uint8 internal constant ACTION_BENTO_DEPOSIT = 20;
    uint8 internal constant ACTION_BENTO_WITHDRAW = 21;
    uint8 internal constant ACTION_BENTO_TRANSFER = 22;
    uint8 internal constant ACTION_BENTO_TRANSFER_MULTIPLE = 23;
    uint8 internal constant ACTION_BENTO_SETAPPROVAL = 24;

    // Any external call (except to BentoBox)
    uint8 internal constant ACTION_CALL = 30;

    int256 internal constant USE_VALUE1 = -1;
    int256 internal constant USE_VALUE2 = -2;

    /// @dev Helper function for choosing the correct value (`value1` or `value2`) depending on `inNum`.
    function _num(
        int256 inNum,
        uint256 value1,
        uint256 value2
    ) internal pure returns (uint256 outNum) {
        outNum = inNum >= 0 ? uint256(inNum) : (inNum == USE_VALUE1 ? value1 : value2);
    }

    /// @dev Helper function for depositing into `bentoBox`.
    function _bentoDeposit(
        bytes memory data,
        uint256 value,
        uint256 value1,
        uint256 value2
    ) internal returns (uint256, uint256) {
        (IERC20 token, address to, int256 amount, int256 share) = abi.decode(data, (IERC20, address, int256, int256));
        amount = int256(_num(amount, value1, value2)); // Done this way to avoid stack too deep errors
        share = int256(_num(share, value1, value2));
        return bentoBox.deposit{value: value}(token, msg.sender, to, uint256(amount), uint256(share));
    }

    /// @dev Helper function to withdraw from the `bentoBox`.
    function _bentoWithdraw(
        bytes memory data,
        uint256 value1,
        uint256 value2
    ) internal returns (uint256, uint256) {
        (IERC20 token, address to, int256 amount, int256 share) = abi.decode(data, (IERC20, address, int256, int256));
        return bentoBox.withdraw(token, msg.sender, to, _num(amount, value1, value2), _num(share, value1, value2));
    }

    /// @dev Helper function to perform a contract call and eventually extracting revert messages on failure.
    /// Calls to `bentoBox` are not allowed for obvious security reasons.
    /// This also means that calls made from this contract shall *not* be trusted.
    function _call(
        uint256 value,
        bytes memory data,
        uint256 value1,
        uint256 value2
    ) internal returns (bytes memory, uint8) {
        (address callee, bytes memory callData, bool useValue1, bool useValue2, uint8 returnValues) =
            abi.decode(data, (address, bytes, bool, bool, uint8));

        if (useValue1 && !useValue2) {
            callData = abi.encodePacked(callData, value1);
        } else if (!useValue1 && useValue2) {
            callData = abi.encodePacked(callData, value2);
        } else if (useValue1 && useValue2) {
            callData = abi.encodePacked(callData, value1, value2);
        }

        require(callee != address(bentoBox) && callee != address(this), "Cauldron: can't call");

        (bool success, bytes memory returnData) = callee.call{value: value}(callData);
        require(success, "Cauldron: call failed");
        return (returnData, returnValues);
    }

    struct CookStatus {
        bool needsSolvencyCheck;
        bool hasAccrued;
    }

    /// @notice Executes a set of actions and allows composability (contract calls) to other contracts.
    /// @param actions An array with a sequence of actions to execute (see ACTION_ declarations).
    /// @param values A one-to-one mapped array to `actions`. ETH amounts to send along with the actions.
    /// Only applicable to `ACTION_CALL`, `ACTION_BENTO_DEPOSIT`.
    /// @param datas A one-to-one mapped array to `actions`. Contains abi encoded data of function arguments.
    /// @return value1 May contain the first positioned return value of the last executed action (if applicable).
    /// @return value2 May contain the second positioned return value of the last executed action which returns 2 values (if applicable).
    function cook(
        uint8[] calldata actions,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external payable returns (uint256 value1, uint256 value2) {
        CookStatus memory status;
        for (uint256 i = 0; i < actions.length; i++) {
            uint8 action = actions[i];
            if (!status.hasAccrued && action < 10) {
                accrue();
                status.hasAccrued = true;
            }
            if (action == ACTION_ADD_COLLATERAL) {
                (int256 share, address to, bool skim) = abi.decode(datas[i], (int256, address, bool));
                addCollateral(to, skim, _num(share, value1, value2));
            } else if (action == ACTION_REPAY) {
                (int256 part, address to, bool skim) = abi.decode(datas[i], (int256, address, bool));
                _repay(to, skim, _num(part, value1, value2));
            } else if (action == ACTION_REMOVE_COLLATERAL) {
                (int256 share, address to) = abi.decode(datas[i], (int256, address));
                _removeCollateral(to, _num(share, value1, value2));
                status.needsSolvencyCheck = true;
            } else if (action == ACTION_BORROW) {
                (int256 amount, address to) = abi.decode(datas[i], (int256, address));
                (value1, value2) = _borrow(to, _num(amount, value1, value2));
                status.needsSolvencyCheck = true;
            } else if (action == ACTION_UPDATE_EXCHANGE_RATE) {
                (bool must_update, uint256 minRate, uint256 maxRate) = abi.decode(datas[i], (bool, uint256, uint256));
                (bool updated, uint256 rate) = updateExchangeRate();
                require((!must_update || updated) && rate > minRate && (maxRate == 0 || rate > maxRate), "Cauldron: rate not ok");
            } else if (action == ACTION_BENTO_SETAPPROVAL) {
                (address user, address _masterContract, bool approved, uint8 v, bytes32 r, bytes32 s) =
                    abi.decode(datas[i], (address, address, bool, uint8, bytes32, bytes32));
                bentoBox.setMasterContractApproval(user, _masterContract, approved, v, r, s);
            } else if (action == ACTION_BENTO_DEPOSIT) {
                (value1, value2) = _bentoDeposit(datas[i], values[i], value1, value2);
            } else if (action == ACTION_BENTO_WITHDRAW) {
                (value1, value2) = _bentoWithdraw(datas[i], value1, value2);
            } else if (action == ACTION_BENTO_TRANSFER) {
                (IERC20 token, address to, int256 share) = abi.decode(datas[i], (IERC20, address, int256));
                bentoBox.transfer(token, msg.sender, to, _num(share, value1, value2));
            } else if (action == ACTION_BENTO_TRANSFER_MULTIPLE) {
                (IERC20 token, address[] memory tos, uint256[] memory shares) = abi.decode(datas[i], (IERC20, address[], uint256[]));
                bentoBox.transferMultiple(token, msg.sender, tos, shares);
            } else if (action == ACTION_CALL) {
                (bytes memory returnData, uint8 returnValues) = _call(values[i], datas[i], value1, value2);

                if (returnValues == 1) {
                    (value1) = abi.decode(returnData, (uint256));
                } else if (returnValues == 2) {
                    (value1, value2) = abi.decode(returnData, (uint256, uint256));
                }
            } else if (action == ACTION_GET_REPAY_SHARE) {
                int256 part = abi.decode(datas[i], (int256));
                value1 = bentoBox.toShare(magicInternetMoney, totalBorrow.toElastic(_num(part, value1, value2), true), true);
            } else if (action == ACTION_GET_REPAY_PART) {
                int256 amount = abi.decode(datas[i], (int256));
                value1 = totalBorrow.toBase(_num(amount, value1, value2), false);
            }
        }

        if (status.needsSolvencyCheck) {
            require(_isSolvent(msg.sender, exchangeRate), "Cauldron: user insolvent");
        }
    }

    /// @notice Handles the liquidation of users' balances, once the users' amount of collateral is too low.
    /// @param users An array of user addresses.
    /// @param maxBorrowParts A one-to-one mapping to `users`, contains maximum (partial) borrow amounts (to liquidate) of the respective user.
    /// @param to Address of the receiver in open liquidations if `swapper` is zero.
    function liquidate(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        address to,
        ISwapper swapper
    ) public {
        // Oracle can fail but we still need to allow liquidations
        (, uint256 _exchangeRate) = updateExchangeRate();
        accrue();

        uint256 allCollateralShare;
        uint256 allBorrowAmount;
        uint256 allBorrowPart;
        Rebase memory _totalBorrow = totalBorrow;
        Rebase memory bentoBoxTotals = bentoBox.totals(collateral);
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (!_isSolvent(user, _exchangeRate)) {
                uint256 borrowPart;
                {
                    uint256 availableBorrowPart = userBorrowPart[user];
                    borrowPart = maxBorrowParts[i] > availableBorrowPart ? availableBorrowPart : maxBorrowParts[i];
                    userBorrowPart[user] = availableBorrowPart.sub(borrowPart);
                }
                uint256 borrowAmount = _totalBorrow.toElastic(borrowPart, false);
                uint256 collateralShare =
                    bentoBoxTotals.toBase(
                        borrowAmount.mul(LIQUIDATION_MULTIPLIER).mul(_exchangeRate) /
                            (LIQUIDATION_MULTIPLIER_PRECISION * EXCHANGE_RATE_PRECISION),
                        false
                    );

                userCollateralShare[user] = userCollateralShare[user].sub(collateralShare);
                emit LogRemoveCollateral(user, to, collateralShare);
                emit LogRepay(msg.sender, user, borrowAmount, borrowPart);

                // Keep totals
                allCollateralShare = allCollateralShare.add(collateralShare);
                allBorrowAmount = allBorrowAmount.add(borrowAmount);
                allBorrowPart = allBorrowPart.add(borrowPart);
            }
        }
        require(allBorrowAmount != 0, "Cauldron: all are solvent");
        _totalBorrow.elastic = _totalBorrow.elastic.sub(allBorrowAmount.to128());
        _totalBorrow.base = _totalBorrow.base.sub(allBorrowPart.to128());
        totalBorrow = _totalBorrow;
        totalCollateralShare = totalCollateralShare.sub(allCollateralShare);

        uint256 allBorrowShare = bentoBox.toShare(magicInternetMoney, allBorrowAmount, true);

        // Swap using a swapper freely chosen by the caller
        // Open (flash) liquidation: get proceeds first and provide the borrow after
        bentoBox.transfer(collateral, address(this), to, allCollateralShare);
        if (swapper != ISwapper(0)) {
            swapper.swap(collateral, magicInternetMoney, msg.sender, allBorrowShare, allCollateralShare);
        }

        bentoBox.transfer(magicInternetMoney, msg.sender, address(this), allBorrowShare);
    }

    /// @notice Withdraws the fees accumulated.
    function withdrawFees() public {
        accrue();
        address _feeTo = masterContract.feeTo();
        uint256 _feesEarned = accrueInfo.feesEarned;
        uint256 share = bentoBox.toShare(magicInternetMoney, _feesEarned, false);
        bentoBox.transfer(magicInternetMoney, address(this), _feeTo, share);
        accrueInfo.feesEarned = 0;

        emit LogWithdrawFees(_feeTo, _feesEarned);
    }

    /// @notice Sets the beneficiary of interest accrued.
    /// MasterContract Only Admin function.
    /// @param newFeeTo The address of the receiver.
    function setFeeTo(address newFeeTo) public onlyOwner {
        feeTo = newFeeTo;
        emit LogFeeTo(newFeeTo);
    }

    /// @notice reduces the supply of MIM
    /// @param amount amount to reduce supply by
    function reduceSupply(uint256 amount) public {
        require(msg.sender == masterContract.owner(), "Caller is not the owner");
        bentoBox.withdraw(magicInternetMoney, address(this), address(this), amount, 0);
        MagicInternetMoney(address(magicInternetMoney)).burn(amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= uint64(-1), "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= uint32(-1), "BoringMath: uint32 Overflow");
        c = uint32(a);
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint64.
library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// Audit on 5-Jan-2021 by Keno and BoringCrypto
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./interfaces/IERC20.sol";
import "./Domain.sol";

// solhint-disable no-inline-assembly
// solhint-disable not-rely-on-time

// Data part taken out for building of contracts that receive delegate calls
contract ERC20Data {
    /// @notice owner > balance mapping.
    mapping(address => uint256) public balanceOf;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public allowance;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) public nonces;
}

abstract contract ERC20 is IERC20, Domain {
    /// @notice owner > balance mapping.
    mapping(address => uint256) public override balanceOf;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public override allowance;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) public nonces;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /// @notice Transfers `amount` tokens from `msg.sender` to `to`.
    /// @param to The address to move the tokens.
    /// @param amount of the tokens to move.
    /// @return (bool) Returns True if succeeded.
    function transfer(address to, uint256 amount) public returns (bool) {
        // If `amount` is 0, or `msg.sender` is `to` nothing happens
        if (amount != 0 || msg.sender == to) {
            uint256 srcBalance = balanceOf[msg.sender];
            require(srcBalance >= amount, "ERC20: balance too low");
            if (msg.sender != to) {
                require(to != address(0), "ERC20: no zero address"); // Moved down so low balance calls safe some gas

                balanceOf[msg.sender] = srcBalance - amount; // Underflow is checked
                balanceOf[to] += amount;
            }
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Transfers `amount` tokens from `from` to `to`. Caller needs approval for `from`.
    /// @param from Address to draw tokens from.
    /// @param to The address to move the tokens.
    /// @param amount The token amount to move.
    /// @return (bool) Returns True if succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        // If `amount` is 0, or `from` is `to` nothing happens
        if (amount != 0) {
            uint256 srcBalance = balanceOf[from];
            require(srcBalance >= amount, "ERC20: balance too low");

            if (from != to) {
                uint256 spenderAllowance = allowance[from][msg.sender];
                // If allowance is infinite, don't decrease it to save on gas (breaks with EIP-20).
                if (spenderAllowance != type(uint256).max) {
                    require(spenderAllowance >= amount, "ERC20: allowance too low");
                    allowance[from][msg.sender] = spenderAllowance - amount; // Underflow is checked
                }
                require(to != address(0), "ERC20: no zero address"); // Moved down so other failed calls safe some gas

                balanceOf[from] = srcBalance - amount; // Underflow is checked
                balanceOf[to] += amount;
            }
        }
        emit Transfer(from, to, amount);
        return true;
    }

    /// @notice Approves `amount` from sender to be spend by `spender`.
    /// @param spender Address of the party that can draw from msg.sender's account.
    /// @param amount The maximum collective amount that `spender` can draw.
    /// @return (bool) Returns True if approved.
    function approve(address spender, uint256 amount) public override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparator();
    }

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant PERMIT_SIGNATURE_HASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice Approves `value` from `owner_` to be spend by `spender`.
    /// @param owner_ Address of the owner.
    /// @param spender The address of the spender that gets approved to draw from `owner_`.
    /// @param value The maximum collective amount that `spender` can draw.
    /// @param deadline This permit must be redeemed before this deadline (UTC timestamp in seconds).
    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(owner_ != address(0), "ERC20: Owner cannot be 0");
        require(block.timestamp < deadline, "ERC20: Expired");
        require(
            ecrecover(_getDigest(keccak256(abi.encode(PERMIT_SIGNATURE_HASH, owner_, spender, value, nonces[owner_]++, deadline))), v, r, s) ==
                owner_,
            "ERC20: Invalid Signature"
        );
        allowance[owner_][spender] = value;
        emit Approval(owner_, spender, value);
    }
}

contract ERC20WithSupply is IERC20, ERC20 {
    uint256 public override totalSupply;

    function _mint(address user, uint256 amount) internal {
        uint256 newTotalSupply = totalSupply + amount;
        require(newTotalSupply >= totalSupply, "Mint overflow");
        totalSupply = newTotalSupply;
        balanceOf[user] += amount;
        emit Transfer(address(0), user, amount);
    }

    function _burn(address user, uint256 amount) internal {
        require(balanceOf[user] >= amount, "Burn too much");
        totalSupply -= amount;
        balanceOf[user] -= amount;
        emit Transfer(user, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function init(bytes calldata data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./BoringMath.sol";

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    using BoringMath for uint256;
    using BoringMath128 for uint128;

    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = elastic.mul(total.base) / total.elastic;
            if (roundUp && base.mul(total.elastic) / total.base < elastic) {
                base = base.add(1);
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = base.mul(total.elastic) / total.base;
            if (roundUp && elastic.mul(total.base) / total.elastic < base) {
                elastic = elastic.add(1);
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic = total.elastic.add(elastic.to128());
        total.base = total.base.add(base.to128());
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic = total.elastic.sub(elastic.to128());
        total.base = total.base.sub(base.to128());
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = total.elastic.add(elastic.to128());
        total.base = total.base.add(base.to128());
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = total.elastic.sub(elastic.to128());
        total.base = total.base.sub(base.to128());
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic = total.elastic.add(elastic.to128());
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic = total.elastic.sub(elastic.to128());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "../interfaces/IERC20.sol";

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_BALANCE_OF = 0x70a08231; // balanceOf(address)
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a gas-optimized balance check to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @param to The address of the user to check.
    /// @return amount The token amount.
    function safeBalanceOf(IERC20 token, address to) internal view returns (uint256 amount) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_BALANCE_OF, to));
        require(success && data.length >= 32, "BoringERC20: BalanceOf failed");
        amount = abi.decode(data, (uint256));
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import '@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol';
import '@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol';
import './IBatchFlashBorrower.sol';
import './IFlashBorrower.sol';
import './IStrategy.sol';

interface IBentoBoxV1 {
    event LogDeploy(address indexed masterContract, bytes data, address indexed cloneAddress);
    event LogDeposit(address indexed token, address indexed from, address indexed to, uint256 amount, uint256 share);
    event LogFlashLoan(address indexed borrower, address indexed token, uint256 amount, uint256 feeAmount, address indexed receiver);
    event LogRegisterProtocol(address indexed protocol);
    event LogSetMasterContractApproval(address indexed masterContract, address indexed user, bool approved);
    event LogStrategyDivest(address indexed token, uint256 amount);
    event LogStrategyInvest(address indexed token, uint256 amount);
    event LogStrategyLoss(address indexed token, uint256 amount);
    event LogStrategyProfit(address indexed token, uint256 amount);
    event LogStrategyQueued(address indexed token, address indexed strategy);
    event LogStrategySet(address indexed token, address indexed strategy);
    event LogStrategyTargetPercentage(address indexed token, uint256 targetPercentage);
    event LogTransfer(address indexed token, address indexed from, address indexed to, uint256 share);
    event LogWhiteListMasterContract(address indexed masterContract, bool approved);
    event LogWithdraw(address indexed token, address indexed from, address indexed to, uint256 amount, uint256 share);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function balanceOf(IERC20, address) external view returns (uint256);
    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns (bool[] memory successes, bytes[] memory results);
    function batchFlashLoan(IBatchFlashBorrower borrower, address[] calldata receivers, IERC20[] calldata tokens, uint256[] calldata amounts, bytes calldata data) external;
    function claimOwnership() external;
    function deploy(address masterContract, bytes calldata data, bool useCreate2) external payable;
    function deposit(IERC20 token_, address from, address to, uint256 amount, uint256 share) external payable returns (uint256 amountOut, uint256 shareOut);
    function flashLoan(IFlashBorrower borrower, address receiver, IERC20 token, uint256 amount, bytes calldata data) external;
    function harvest(IERC20 token, bool balance, uint256 maxChangeAmount) external;
    function masterContractApproved(address, address) external view returns (bool);
    function masterContractOf(address) external view returns (address);
    function nonces(address) external view returns (uint256);
    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
    function pendingStrategy(IERC20) external view returns (IStrategy);
    function permitToken(IERC20 token, address from, address to, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function registerProtocol() external;
    function setMasterContractApproval(address user, address masterContract, bool approved, uint8 v, bytes32 r, bytes32 s) external;
    function setStrategy(IERC20 token, IStrategy newStrategy) external;
    function setStrategyTargetPercentage(IERC20 token, uint64 targetPercentage_) external;
    function strategy(IERC20) external view returns (IStrategy);
    function strategyData(IERC20) external view returns (uint64 strategyStartDate, uint64 targetPercentage, uint128 balance);
    function toAmount(IERC20 token, uint256 share, bool roundUp) external view returns (uint256 amount);
    function toShare(IERC20 token, uint256 amount, bool roundUp) external view returns (uint256 share);
    function totals(IERC20) external view returns (Rebase memory totals_);
    function transfer(IERC20 token, address from, address to, uint256 share) external;
    function transferMultiple(IERC20 token, address from, address[] calldata tos, uint256[] calldata shares) external;
    function transferOwnership(address newOwner, bool direct, bool renounce) external;
    function whitelistMasterContract(address masterContract, bool approved) external;
    function whitelistedMasterContracts(address) external view returns (bool);
    function withdraw(IERC20 token_, address from, address to, uint256 amount, uint256 share) external returns (uint256 amountOut, uint256 shareOut);
}

// SPDX-License-Identifier: MIT

// Magic Internet Money

// ███╗   ███╗██╗███╗   ███╗
// ████╗ ████║██║████╗ ████║
// ██╔████╔██║██║██╔████╔██║
// ██║╚██╔╝██║██║██║╚██╔╝██║
// ██║ ╚═╝ ██║██║██║ ╚═╝ ██║
// ╚═╝     ╚═╝╚═╝╚═╝     ╚═╝

// BoringCrypto, 0xMerlin

pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/ERC20.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";

/// @title Cauldron
/// @dev This contract allows contract calls to any contract (except BentoBox)
/// from arbitrary callers thus, don't trust calls from this contract in any circumstances.
contract MagicInternetMoney is ERC20, BoringOwnable {
    using BoringMath for uint256;
    // ERC20 'variables'
    string public constant symbol = "MIM";
    string public constant name = "Magic Internet Money";
    uint8 public constant decimals = 18;
    uint256 public override totalSupply;

    struct Minting {
        uint128 time;
        uint128 amount;
    }

    Minting public lastMint;
    uint256 private constant MINTING_PERIOD = 24 hours;
    uint256 private constant MINTING_INCREASE = 15000;
    uint256 private constant MINTING_PRECISION = 1e5;

    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "MIM: no mint to zero address");

        // Limits the amount minted per period to a convergence function, with the period duration restarting on every mint
        uint256 totalMintedAmount = uint256(lastMint.time < block.timestamp - MINTING_PERIOD ? 0 : lastMint.amount).add(amount);
        require(totalSupply == 0 || totalSupply.mul(MINTING_INCREASE) / MINTING_PRECISION >= totalMintedAmount);

        lastMint.time = block.timestamp.to128();
        lastMint.amount = totalMintedAmount.to128();

        totalSupply = totalSupply + amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function mintToBentoBox(address clone, uint256 amount, IBentoBoxV1 bentoBox) public onlyOwner {
        mint(address(bentoBox), amount);
        bentoBox.deposit(IERC20(address(this)), address(bentoBox), clone, amount, 0);
    }

    function burn(uint256 amount) public {
        require(amount <= balanceOf[msg.sender], "MIM: not enough");

        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.12;

interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data) external returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data) external view returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.12;
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";

interface ISwapper {
    /// @notice Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper.
    /// Swaps it for at least 'amountToMin' of token 'to'.
    /// Transfers the swapped tokens of 'to' into the BentoBox using a plain ERC20 transfer.
    /// Returns the amount of tokens 'to' transferred to BentoBox.
    /// (The BentoBox skim function will be used by the caller to get the swapped funds).
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) external returns (uint256 extraShare, uint256 shareReturned);

    /// @notice Calculates the amount of token 'from' needed to complete the swap (amountFrom),
    /// this should be less than or equal to amountFromMax.
    /// Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper.
    /// Swaps it for exactly 'exactAmountTo' of token 'to'.
    /// Transfers the swapped tokens of 'to' into the BentoBox using a plain ERC20 transfer.
    /// Transfers allocated, but unused 'from' tokens within the BentoBox to 'refundTo' (amountFromMax - amountFrom).
    /// Returns the amount of 'from' tokens withdrawn from BentoBox (amountFrom).
    /// (The BentoBox skim function will be used by the caller to get the swapped funds).
    function swapExact(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        address refundTo,
        uint256 shareFromSupplied,
        uint256 shareToExact
    ) external returns (uint256 shareUsed, uint256 shareReturned);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// Based on code and smartness by Ross Campbell and Keno
// Uses immutable to store the domain separator to reduce gas usage
// If the chain id changes due to a fork, the forked chain will calculate on the fly.
pragma solidity 0.6.12;

// solhint-disable no-inline-assembly

contract Domain {
    bytes32 private constant DOMAIN_SEPARATOR_SIGNATURE_HASH = keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
    // See https://eips.ethereum.org/EIPS/eip-191
    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";

    // solhint-disable var-name-mixedcase
    bytes32 private immutable _DOMAIN_SEPARATOR;
    uint256 private immutable DOMAIN_SEPARATOR_CHAIN_ID;

    /// @dev Calculate the DOMAIN_SEPARATOR
    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_SIGNATURE_HASH, chainId, address(this)));
    }

    constructor() public {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(DOMAIN_SEPARATOR_CHAIN_ID = chainId);
    }

    /// @dev Return the DOMAIN_SEPARATOR
    // It's named internal to allow making it public from the contract that uses it by creating a simple view function
    // with the desired public name, such as DOMAIN_SEPARATOR or domainSeparator.
    // solhint-disable-next-line func-name-mixedcase
    function _domainSeparator() internal view returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId == DOMAIN_SEPARATOR_CHAIN_ID ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId);
    }

    function _getDigest(bytes32 dataHash) internal view returns (bytes32 digest) {
        digest = keccak256(abi.encodePacked(EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA, _domainSeparator(), dataHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import '@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol';

interface IBatchFlashBorrower {
    function onBatchFlashLoan(
        address sender,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata fees,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import '@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol';

interface IFlashBorrower {
    function onFlashLoan(
        address sender,
        IERC20 token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IStrategy {
    // Send the assets to the Strategy and call skim to invest them
    function skim(uint256 amount) external;

    // Harvest any profits made converted to the asset and pass them to the caller
    function harvest(uint256 balance, address sender) external returns (int256 amountAdded);

    // Withdraw assets. The returned amount can differ from the requested amount due to rounding.
    // The actualAmount should be very close to the amount. The difference should NOT be used to report a loss. That's what harvest is for.
    function withdraw(uint256 amount) external returns (uint256 actualAmount);

    // Withdraw all assets in the safest way possible. This shouldn't fail.
    function exit(uint256 balance) external returns (int256 amountAdded);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "./IOracle.sol";
import "./ISwapper.sol";

interface IKashiPair {
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event LogAccrue(uint256 accruedAmount, uint256 feeFraction, uint64 rate, uint256 utilization);
    event LogAddAsset(address indexed from, address indexed to, uint256 share, uint256 fraction);
    event LogAddCollateral(address indexed from, address indexed to, uint256 share);
    event LogBorrow(address indexed from, address indexed to, uint256 amount, uint256 part);
    event LogExchangeRate(uint256 rate);
    event LogFeeTo(address indexed newFeeTo);
    event LogRemoveAsset(address indexed from, address indexed to, uint256 share, uint256 fraction);
    event LogRemoveCollateral(address indexed from, address indexed to, uint256 share);
    event LogRepay(address indexed from, address indexed to, uint256 amount, uint256 part);
    event LogWithdrawFees(address indexed feeTo, uint256 feesEarnedFraction);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function accrue() external;

    function accrueInfo()
        external
        view
        returns (
            uint64 interestPerBlock,
            uint64 lastBlockAccrued,
            uint128 feesEarnedFraction
        );

    function addAsset(
        address to,
        bool skim,
        uint256 share
    ) external returns (uint256 fraction);

    function addCollateral(
        address to,
        bool skim,
        uint256 share
    ) external;

    function allowance(address, address) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function asset() external view returns (IERC20);

    function balanceOf(address) external view returns (uint256);

    function bentoBox() external view returns (IBentoBoxV1);

    function borrow(address to, uint256 amount) external returns (uint256 part, uint256 share);

    function claimOwnership() external;

    function collateral() external view returns (IERC20);

    function cook(
        uint8[] calldata actions,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external payable returns (uint256 value1, uint256 value2);

    function decimals() external view returns (uint8);

    function exchangeRate() external view returns (uint256);

    function feeTo() external view returns (address);

    function getInitData(
        IERC20 collateral_,
        IERC20 asset_,
        IOracle oracle_,
        bytes calldata oracleData_
    ) external pure returns (bytes memory data);

    function init(bytes calldata data) external payable;

    function isSolvent(address user, bool open) external view returns (bool);

    function liquidate(
        address[] calldata users,
        uint256[] calldata borrowParts,
        address to,
        ISwapper swapper,
        bool open
    ) external;

    function masterContract() external view returns (address);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function oracle() external view returns (IOracle);

    function oracleData() external view returns (bytes memory);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function removeAsset(address to, uint256 fraction) external returns (uint256 share);

    function removeCollateral(address to, uint256 share) external;

    function repay(
        address to,
        bool skim,
        uint256 part
    ) external returns (uint256 amount);

    function setFeeTo(address newFeeTo) external;

    function setSwapper(ISwapper swapper, bool enable) external;

    function swappers(ISwapper) external view returns (bool);

    function symbol() external view returns (string memory);

    function totalAsset() external view returns (uint128 elastic, uint128 base);

    function totalBorrow() external view returns (uint128 elastic, uint128 base);

    function totalCollateralShare() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function updateExchangeRate() external returns (bool updated, uint256 rate);

    function userBorrowPart(address) external view returns (uint256);

    function userCollateralShare(address) external view returns (uint256);

    function withdrawFees() external;
}

// SPDX-License-Identifier: UNLICENSED

// Cauldron

//    (                (   (
//    )\      )    (   )\  )\ )  (
//  (((_)  ( /(   ))\ ((_)(()/(  )(    (    (
//  )\___  )(_)) /((_) _   ((_))(()\   )\   )\ )
// ((/ __|((_)_ (_))( | |  _| |  ((_) ((_) _(_/(
//  | (__ / _` || || || |/ _` | | '_|/ _ \| ' \))
//   \___|\__,_| \_,_||_|\__,_| |_|  \___/|_||_|

// Copyright (c) 2021 BoringCrypto - All rights reserved
// Twitter: @Boring_Crypto

// Special thanks to:
// @0xKeno - for all his invaluable contributions
// @burger_crypto - for the idea of trying to let the LPs benefit from liquidations

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";

import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IMasterContract.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/ISimpleSwapper.sol";
import "./libraries/FullMath.sol";

/// @title PrivatePool
/// @dev This contract allows contract calls to any contract (except BentoBox)
/// from arbitrary callers thus, don't trust calls from this contract in any circumstances.
contract PrivatePool is BoringOwnable, IMasterContract {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;

    event LogExchangeRate(uint256 rate);
    event LogAccrue(uint256 accruedAmount, uint256 feeAmount);
    event LogAddCollateral(
        address indexed from,
        address indexed to,
        uint256 share
    );
    event LogAddAsset(address indexed from, uint256 share);
    event LogRemoveCollateral(
        address indexed from,
        address indexed to,
        uint256 share
    );
    event LogRemoveAsset(address indexed to, uint256 share);
    event LogBorrow(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 openFeeAmount,
        uint256 part
    );
    event LogRepay(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 part
    );
    event LogSeizeCollateral(
        address indexed from,
        uint256 collateralShare,
        uint256 debtAmount,
        uint256 debtPart
    );
    event LogFeeTo(address indexed newFeeTo);
    event LogWithdrawFees(
        address indexed feeTo,
        uint256 assetFeeShare,
        uint256 collateralFeeShare
    );

    // Immutables (for MasterContract and all clones)
    IBentoBoxV1 public immutable bentoBox;
    PrivatePool public immutable masterContract;

    // MasterContract variables
    address public feeTo;

    // Per clone variables
    // Clone init settings
    IERC20 public collateral;
    IERC20 public asset;
    IOracle public oracle;
    bytes public oracleData;

    // A note on terminology:
    // "Shares" are BentoBox shares.
    // "Parts" and represent shares held in the debt pool

    // The BentoBox balance is the sum of the below two.
    // Since that fits in a single uint128, we can often forgo overflow checks.
    struct AssetBalance {
        uint128 reservesShare;
        uint128 feesEarnedShare;
    }
    AssetBalance public assetBalance;
    uint256 public feesOwedAmount; // Positive only if reservesShare = 0

    // The BentoBox balance is the sum of the below two.
    // Seized collateral goes to the "userCollateralShare" account of the
    // lender.
    struct CollateralBalance {
        uint128 userTotalShare;
        uint128 feesEarnedShare;
    }
    CollateralBalance public collateralBalance;
    mapping(address => uint256) public userCollateralShare;

    // Elastic: Exact asset token amount that currently needs to be repaid
    // Base: Total parts of the debt held by borrowers (borrowerDebtPart)
    Rebase public totalDebt;
    mapping(address => uint256) public borrowerDebtPart;

    address public lender;
    mapping(address => bool) public approvedBorrowers;

    /// @notice Exchange and interest rate tracking.
    /// This is 'cached' here because calls to Oracles can be very expensive.
    uint256 public exchangeRate;

    struct AccrueInfo {
        uint64 lastAccrued;
        uint64 INTEREST_PER_SECOND; // (in units of 1/10^18)
        uint64 EXPIRATION;
        uint16 COLLATERALIZATION_RATE_BPS;
        uint16 LIQUIDATION_MULTIPLIER_BPS;
        uint16 BORROW_OPENING_FEE_BPS;
        bool LIQUIDATION_SEIZE_COLLATERAL;
    }
    AccrueInfo public accrueInfo;

    uint256 private constant PROTOCOL_FEE_BPS = 1000; // 10%
    uint256 private constant BPS = 10_000;
    uint256 private constant EXCHANGE_RATE_PRECISION = 1e18;

    /// @notice The constructor is only used for the initial master contract. Subsequent clones are initialised via `init`.
    constructor(IBentoBoxV1 bentoBox_) public {
        bentoBox = bentoBox_;
        masterContract = this;
    }

    struct InitSettings {
        IERC20 collateral;
        IERC20 asset;
        IOracle oracle;
        bytes oracleData;
        address lender;
        address[] borrowers;
        uint64 INTEREST_PER_SECOND;
        uint64 EXPIRATION;
        uint16 COLLATERALIZATION_RATE_BPS;
        uint16 LIQUIDATION_MULTIPLIER_BPS;
        uint16 BORROW_OPENING_FEE_BPS;
        bool LIQUIDATION_SEIZE_COLLATERAL;
    }

    /// @notice Serves as the constructor for clones, as clones can't have a regular constructor
    function init(bytes calldata data) public payable override {
        require(
            address(collateral) == address(0),
            "PrivatePool: already initialized"
        );

        InitSettings memory settings = abi.decode(data, (InitSettings));
        require(
            address(settings.collateral) != address(0),
            "PrivatePool: bad pair"
        );
        require(
            settings.LIQUIDATION_MULTIPLIER_BPS >= BPS,
            "PrivatePool: negative liquidation bonus"
        );
        require(
            settings.COLLATERALIZATION_RATE_BPS <= BPS,
            "PrivatePool: bad collateralization rate"
        );

        collateral = settings.collateral;
        asset = settings.asset;
        oracle = settings.oracle;
        oracleData = settings.oracleData;
        lender = settings.lender;

        AccrueInfo memory _aI;
        _aI.INTEREST_PER_SECOND = settings.INTEREST_PER_SECOND;
        _aI.EXPIRATION = settings.EXPIRATION == 0
            ? uint64(-1)
            : settings.EXPIRATION;
        _aI.COLLATERALIZATION_RATE_BPS = settings.COLLATERALIZATION_RATE_BPS;
        _aI.LIQUIDATION_MULTIPLIER_BPS = settings.LIQUIDATION_MULTIPLIER_BPS;
        _aI.BORROW_OPENING_FEE_BPS = settings.BORROW_OPENING_FEE_BPS;
        _aI.LIQUIDATION_SEIZE_COLLATERAL = settings
            .LIQUIDATION_SEIZE_COLLATERAL;
        accrueInfo = _aI;

        for (uint256 i = 0; i < settings.borrowers.length; i++) {
            approvedBorrowers[settings.borrowers[i]] = true;
        }
    }

    function setApprovedBorrowers(address borrower, bool approved)
        external
        onlyOwner
    {
        approvedBorrowers[borrower] = approved;
    }

    /// @notice Accrues the interest on the borrowed tokens and handles the accumulation of fees.
    function accrue() public {
        AccrueInfo memory _accrueInfo = accrueInfo;
        // Number of seconds since accrue was called
        uint256 elapsedTime = block.timestamp - _accrueInfo.lastAccrued;
        if (elapsedTime == 0) {
            return;
        }
        accrueInfo.lastAccrued = uint64(block.timestamp);

        Rebase memory _totalDebt = totalDebt;
        if (_totalDebt.base == 0) {
            return;
        }
        // No overflow:
        // - _totalDebt.elastic is 128 bits
        // - INTEREST_PER_SECOND is 64 bits
        // - elapsedTime fits in 64 bits for the next 580 billion (10^9) years
        uint256 extraAmount = (uint256(_totalDebt.elastic) *
            _accrueInfo.INTEREST_PER_SECOND *
            elapsedTime) / 1e18;

        // If the interest rate is too high, then this will overflow and
        // effectively lock up all funds. Do not set the interest rate too
        // high.
        _totalDebt.elastic = _totalDebt.elastic.add(extraAmount.to128());
        totalDebt = _totalDebt;

        // No overflow: extraAmount is divided by 1e18 > 2^59; we need 16 bits
        uint256 feeAmount = (extraAmount * PROTOCOL_FEE_BPS) / BPS;

        AssetBalance memory _assetBalance = assetBalance;
        if (_assetBalance.reservesShare == 0) {
            // Fees owed are always part of the debt, and the debt just got
            // at least `feeAmount` added to it. If that fit, so does this:
            feesOwedAmount += feeAmount;
        } else {
            uint256 feeShare = bentoBox.toShare(asset, feeAmount, false);
            if (_assetBalance.reservesShare < feeShare) {
                _assetBalance.feesEarnedShare += _assetBalance.reservesShare;
                feesOwedAmount += bentoBox.toAmount(
                    asset,
                    feeShare - _assetBalance.reservesShare,
                    false
                );
                _assetBalance.reservesShare = 0;
            } else {
                // feesEarned + fee <= feesEarned + reserves <= Bento balance:
                _assetBalance.reservesShare -= uint128(feeShare);
                _assetBalance.feesEarnedShare += uint128(feeShare);
            }
            assetBalance = _assetBalance;
        }

        emit LogAccrue(extraAmount, feeAmount);
    }

    function _isSolvent(address borrower) internal returns (bool) {
        (, uint256 _exchangeRate) = updateExchangeRate();

        // accrue must have already been called!
        uint256 debtPart = borrowerDebtPart[borrower];
        if (debtPart == 0) return true;
        uint256 collateralShare = userCollateralShare[borrower];
        if (collateralShare == 0) return false;

        // The inequality that needs to hold for a user to be solvent is:
        //
        //    (value of user collateral) * (max LTV) >= (value of user debt)
        //
        // Our exchange rates give "collateral per ether of asset", so it makes
        // sense to express the value in the collateral token. The calculation
        // for the collateral value is:
        //
        //                                BentoBox tokens
        //               value = shares * ---------------
        //                                BentoBox shares
        //
        // where BentoBox tokens resp. shares refer to the balances for the
        // collateral (ERC20) contract. For the debt we get:
        //
        //                  Total debt tokens   Collateral wei per asset ether
        //  value = parts * ----------------- * ------------------------------
        //                   Total debt parts               1e18
        //
        // ..since "tokens" is in wei. We call this EXCHANGE_RATE_PRECISION.
        // Finally, max LTV is
        //
        //          COLLATERALIZATION_RATE_BPS
        //  ratio = --------------------------.
        //                     1e4
        //
        // We use the below table to (fit the inequality in 80 characters and)
        // move some things around and justify our calculations.
        //
        //      Description                 Variable in contract        Bits
        // -----------------------------------------------------------------
        // cs   shares                      collateralShare             128*
        // Be   BentoBox tokens             bentoBoxTotals.elastic      128
        // Bb   BentoBox shares             bentoBoxTotals.base         128
        // -----------------------------------------------------------------
        // dp   parts                       debtPart                    128*
        // De   Total debt tokens           totalDebt.elastic           128
        // Db   Total debt parts            totalDebt.base              128
        // xr   Coll. wei per asset ether   exchangeRate                256
        //      1e18                        EXCHANGE_RATE_PRECISION      60
        // ----------------------------------------------------------------
        // ltv                              COLLATERALIZATION_RATE_BPS   14
        //      1e4                         BPS                          14
        //      1e14                                                     47
        //
        // (* as in other proofs, these values fit in some 128-bit total).
        // The inequality, without regard for integer division:
        //
        //                       Be   ltv         De    xr
        //                  cs * -- * --- >= dp * -- * ----
        //                       Bb   1e4         Db   1e18
        //
        // This is equivalent to:
        //
        //    cs *  Be * ltv *  Db * 1e14 >=  dp *  De *  xr *  Bb
        //
        // Corresponding bit counts:
        //
        //   128 + 128 +  14 + 128 + 47;     128 + 128 + 256 + 128
        //
        // So, the LHS definitely fits in 512 bits, and as long as one token is
        // not 2^68 times as valuable as another. Of course the other terms
        // leave some leeway, too; if the exchange rate is this high, then the
        // Bento share count is very unlikely to take up the full 128 bits.
        //
        // "Full" multiplication is not very expensive or cumbersome; the case
        // where `exchangeRate` is too big is a little more involved, but
        // manageable.

        Rebase memory _totalDebt = totalDebt;
        Rebase memory bentoBoxTotals = bentoBox.totals(collateral);

        (uint256 leftLo, uint256 leftHi) = FullMath.fullMul(
            collateralShare * bentoBoxTotals.elastic,
            // Cast needed to avoid uint128 overflow
            uint256(accrueInfo.COLLATERALIZATION_RATE_BPS) *
                _totalDebt.base *
                1e14
        );
        uint256 rightLo;
        uint256 rightHi;
        if (_exchangeRate <= type(uint128).max) {
            (rightLo, rightHi) = FullMath.fullMul(
                debtPart * _totalDebt.elastic,
                _exchangeRate * bentoBoxTotals.base
            );
        } else {
            // We multiply it out in stages to be safe. If the total overflows
            // 512 bits then we are done, as the LHS is guaranteed to be less.
            //
            //               aHi * 2^256 + aLo =                    dp * De * Bb
            // -----------------------------------------------------------------
            // The total is then the sum of:
            //
            // bHi * 2^512 + bLo * 2^256       = xr * aHi * 2^256
            //               cHi * 2^256 + cLo = xr *               aLo
            //
            (uint256 aLo, uint256 aHi) = FullMath.fullMul(
                debtPart * _totalDebt.elastic,
                bentoBoxTotals.base
            );
            (uint256 bLo, uint256 bHi) = FullMath.fullMul(_exchangeRate, aHi);
            if (bHi > 0) {
                return false;
            }

            uint256 cHi; // (cLo is rightLo)
            (rightLo, cHi) = FullMath.fullMul(_exchangeRate, aLo);
            rightHi = cHi + bLo;
            if (rightHi < cHi) {
                return false;
            }
        }
        return leftHi > rightHi || (leftHi == rightHi && leftLo >= rightLo);
    }

    /// @dev Checks if the borrower is solvent in the closed liquidation case at the end of the function body.
    modifier solvent() {
        _;
        require(_isSolvent(msg.sender), "PrivatePool: borrower insolvent");
    }

    /// @notice Gets the exchange rate. I.e how much collateral to buy 1e18 asset.
    /// This function is supposed to be invoked if needed because Oracle queries can be expensive.
    /// @return updated True if `exchangeRate` was updated.
    /// @return rate The new exchange rate.
    function updateExchangeRate() public returns (bool updated, uint256 rate) {
        (updated, rate) = oracle.get(oracleData);

        if (updated) {
            exchangeRate = rate;
            emit LogExchangeRate(rate);
        } else {
            // Return the old rate if fetching wasn't successful
            rate = exchangeRate;
        }
    }

    /// @dev Helper function to move tokens.
    /// @param token The ERC-20 token.
    /// @param share The amount in shares to add.
    /// @param total Grand total amount to deduct from this contract's balance. Only applicable if `skim` is True.
    /// Only used for accounting checks.
    /// @param skim If True, only does a balance check on this contract.
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    function _addTokens(
        IERC20 token,
        uint256 share,
        uint256 total,
        bool skim
    ) internal {
        if (skim) {
            require(
                share <= bentoBox.balanceOf(token, address(this)).sub(total),
                "PrivatePool: skim too much"
            );
        } else {
            bentoBox.transfer(token, msg.sender, address(this), share);
        }
    }

    /// @notice Adds `collateral` from msg.sender to the account `to`.
    /// @param to The receiver of the tokens.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    /// @param share The amount of shares to add for `to`.
    function addCollateral(
        address to,
        bool skim,
        uint256 share
    ) public {
        uint256 supplied = userCollateralShare[to];
        require(
            supplied > 0 || approvedBorrowers[to],
            "PrivatePool: unapproved borrower"
        );

        // No overflow: the total for ALL users fits in 128 bits, or the
        // BentoBox transfer (_addTokens) fails.
        userCollateralShare[to] = supplied + share;
        CollateralBalance memory _collateralBalance = collateralBalance;
        // No overflow: the sum fits in the BentoBox total
        uint256 prevTotal = _collateralBalance.userTotalShare +
            _collateralBalance.feesEarnedShare;
        // No overflow if cast safe: fits in the BentoBox or _addTokens reverts
        // Cast safe: _addTokens does not truncate the value
        collateralBalance.userTotalShare =
            _collateralBalance.userTotalShare +
            uint128(share);
        _addTokens(collateral, share, prevTotal, skim);
        emit LogAddCollateral(skim ? address(bentoBox) : msg.sender, to, share);
    }

    /// @dev Concrete implementation of `removeCollateral`.
    function _removeCollateral(address to, uint256 share) internal {
        userCollateralShare[msg.sender] = userCollateralShare[msg.sender].sub(
            share
        );
        // No underflow: userTotalShare > userCollateralShare[msg.sender]
        // Cast safe: Bento transfer reverts if it is not.
        collateralBalance.userTotalShare -= uint128(share);
        emit LogRemoveCollateral(msg.sender, to, share);
        bentoBox.transfer(collateral, address(this), to, share);
    }

    /// @notice Removes `share` amount of collateral and transfers it to `to`.
    /// @param to The receiver of the shares.
    /// @param share Amount of shares to remove.
    function removeCollateral(address to, uint256 share) public solvent {
        // accrue must be called because we check solvency
        accrue();
        _removeCollateral(to, share);
    }

    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// @param toReservesShare Amount of shares to reserves.
    /// @param toReservesAmount Token amount. Ignored if `toReservesShare` nonzero.
    /// @param toFeesAmount Token fee amount. Ignored if `toReservesShare` nonzero.
    function _receiveAsset(
        bool skim,
        uint256 toReservesShare,
        // (There is no case where we pass along a fee in shares)
        uint256 toReservesAmount,
        uint256 toFeesAmount
    ) internal {
        IERC20 _asset = asset;
        AssetBalance memory _assetBalance = assetBalance;
        uint256 priorAssetTotalShare = _assetBalance.reservesShare +
            _assetBalance.feesEarnedShare;
        Rebase memory bentoBoxTotals = bentoBox.totals(_asset);

        uint256 toFeesShare = 0;
        if (toReservesShare == 0) {
            toReservesShare = bentoBoxTotals.toBase(toReservesAmount, true);
            if (toFeesAmount > 0) {
                toFeesShare = bentoBoxTotals.toBase(toFeesAmount, false);
            }
        }
        uint256 takenShare = toReservesShare.add(toFeesShare);

        if (_assetBalance.reservesShare == 0) {
            uint256 _feesOwedAmount = feesOwedAmount;
            if (_feesOwedAmount > 0) {
                uint256 feesOwedShare = bentoBoxTotals.toBase(
                    _feesOwedAmount,
                    false
                );
                // New fees cannot pay off existing fees:
                if (toReservesShare < feesOwedShare) {
                    feesOwedAmount = bentoBoxTotals.toElastic(
                        feesOwedShare - toReservesShare,
                        false
                    );
                    _assetBalance.feesEarnedShare += uint128(takenShare);
                } else {
                    feesOwedAmount = 0;
                    // No overflow: assuming the transfer at the end succeeds:
                    //     feesOwedShare <= toReservesShare <= (Bento balance),
                    _assetBalance.feesEarnedShare += uint128(
                        feesOwedShare + toFeesShare
                    );
                    _assetBalance.reservesShare = uint128(
                        toReservesShare - feesOwedShare
                    );
                }
            } else {
                _assetBalance.reservesShare = uint128(toReservesShare);
                _assetBalance.feesEarnedShare += uint128(toFeesShare);
            }
        } else {
            _assetBalance.reservesShare += uint128(toReservesShare);
            _assetBalance.feesEarnedShare += uint128(toFeesShare);
        }
        assetBalance = _assetBalance;

        _addTokens(_asset, takenShare, priorAssetTotalShare, skim);
    }

    /// @dev Concrete implementation of `addAsset`.
    function _addAsset(bool skim, uint256 share) internal {
        _receiveAsset(skim, share, 0, 0);
        emit LogAddAsset(skim ? address(bentoBox) : msg.sender, share);
    }

    /// @notice Adds assets to the lending pair.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    /// @param share The amount of shares to add.
    function addAsset(bool skim, uint256 share) public {
        accrue();
        _addAsset(skim, share);
    }

    /// @dev Concrete implementation of `removeAsset`.
    function _removeAsset(address to, uint256 share) internal {
        require(msg.sender == lender, "PrivatePool: not the lender");
        // Cast safe: Bento transfer reverts unless stronger condition holds
        assetBalance.reservesShare = assetBalance.reservesShare.sub(
            uint128(share)
        );
        bentoBox.transfer(asset, address(this), to, share);
        emit LogRemoveAsset(to, share);
    }

    /// @notice Removes an asset from msg.sender and transfers it to `to`.
    /// @param to The address that receives the removed assets.
    /// @param share The amount of shares to remove.
    function removeAsset(address to, uint256 share) public {
        accrue();
        _removeAsset(to, share);
    }

    /// @dev Concrete implementation of `borrow`.
    function _borrow(address to, uint256 amount)
        internal
        returns (uint256 part, uint256 share)
    {
        require(
            approvedBorrowers[msg.sender],
            "PrivatePool: unapproved borrower"
        );
        IERC20 _asset = asset;
        Rebase memory bentoBoxTotals = bentoBox.totals(_asset);
        AccrueInfo memory _accrueInfo = accrueInfo;

        share = bentoBoxTotals.toBase(amount, false);

        // No overflow: `share` is not modified any more, and fits in the
        // BentoBox shares total if the transfer succeeds. But then "amount"
        // must fit in the token total; at least up to some rounding error,
        // which cannot be more than 128 bits either.
        uint256 openFeeAmount = (amount * _accrueInfo.BORROW_OPENING_FEE_BPS) /
            BPS;
        // No overflow: Same reason. Also, we just divided by BPS..
        uint256 protocolFeeAmount = (openFeeAmount * PROTOCOL_FEE_BPS) / BPS;
        uint256 protocolFeeShare = bentoBoxTotals.toBase(
            protocolFeeAmount,
            false
        );

        // The protocol component of the opening fee cannot be owed:
        AssetBalance memory _assetBalance = assetBalance;
        // No overflow on the add: protocolFeeShare < share < Bento total, or
        // the transfer reverts. The transfer is independent of the results of
        // these calculations: `share` is not modified.
        // Theoretically the fee could just make it overflow 128 bits.
        // Underflow check is core business logic:
        _assetBalance.reservesShare = _assetBalance.reservesShare.sub(
            (share + protocolFeeShare).to128()
        );
        // Cast is safe: `share` fits. Also, the checked cast above succeeded.
        // No overflow: protocolFeeShare < reservesShare, and both balances
        // together fit in the Bento share balance,
        _assetBalance.feesEarnedShare += uint128(protocolFeeShare);
        assetBalance = _assetBalance;

        // No overflow (inner add): amount fits in 128 bits, as shown before,
        // and openFeeAmount is less.
        (totalDebt, part) = totalDebt.add(amount + openFeeAmount, true);
        // No overflow: totalDebt.base is the sum of all borrowerDebtParts,
        //              fits in 128 bits and just had "part" added to it.
        borrowerDebtPart[msg.sender] += part;
        emit LogBorrow(msg.sender, to, amount, openFeeAmount, part);

        bentoBox.transfer(_asset, address(this), to, share);
    }

    /// @notice Sender borrows `amount` and transfers it to `to`.
    /// @return part Total part of the debt held by borrowers.
    /// @return share Total amount in shares borrowed.
    function borrow(address to, uint256 amount)
        public
        solvent
        returns (uint256 part, uint256 share)
    {
        accrue();
        (part, share) = _borrow(to, amount);
    }

    /// @dev Concrete implementation of `repay`.
    function _repay(
        address to,
        bool skim,
        uint256 part
    ) internal returns (uint256 amount) {
        (totalDebt, amount) = totalDebt.sub(part, true);
        borrowerDebtPart[to] = borrowerDebtPart[to].sub(part);
        _receiveAsset(skim, 0, amount, 0);
        emit LogRepay(skim ? address(bentoBox) : msg.sender, to, amount, part);
    }

    /// @notice Repays a loan.
    /// @param to Address of the borrower this payment should go.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    /// @param part The amount to repay as part. See `borrowerDebtPart`.
    /// @return amount The total amount repayed.
    function repay(
        address to,
        bool skim,
        uint256 part
    ) public returns (uint256 amount) {
        accrue();
        amount = _repay(to, skim, part);
    }

    // Functions that need accrue to be called
    uint8 internal constant ACTION_ADD_ASSET = 1;
    uint8 internal constant ACTION_REPAY = 2;
    uint8 internal constant ACTION_REMOVE_ASSET = 3;
    uint8 internal constant ACTION_REMOVE_COLLATERAL = 4;
    uint8 internal constant ACTION_BORROW = 5;
    uint8 internal constant ACTION_GET_REPAY_SHARE = 6;
    uint8 internal constant ACTION_GET_REPAY_PART = 7;
    uint8 internal constant ACTION_ACCRUE = 8;

    // Functions that don't need accrue to be called
    uint8 internal constant ACTION_ADD_COLLATERAL = 10;
    uint8 internal constant ACTION_UPDATE_EXCHANGE_RATE = 11;

    // Function on BentoBox
    uint8 internal constant ACTION_BENTO_DEPOSIT = 20;
    uint8 internal constant ACTION_BENTO_WITHDRAW = 21;
    uint8 internal constant ACTION_BENTO_TRANSFER = 22;
    uint8 internal constant ACTION_BENTO_TRANSFER_MULTIPLE = 23;
    uint8 internal constant ACTION_BENTO_SETAPPROVAL = 24;

    // Any external call (except to BentoBox)
    uint8 internal constant ACTION_CALL = 30;

    int256 internal constant USE_VALUE1 = -1;
    int256 internal constant USE_VALUE2 = -2;

    /// @dev Helper function for choosing the correct value (`value1` or `value2`) depending on `inNum`.
    function _num(
        int256 inNum,
        uint256 value1,
        uint256 value2
    ) internal pure returns (uint256 outNum) {
        outNum = inNum >= 0
            ? uint256(inNum)
            : (inNum == USE_VALUE1 ? value1 : value2);
    }

    /// @dev Helper function for depositing into `bentoBox`.
    function _bentoDeposit(
        bytes memory data,
        uint256 value,
        uint256 value1,
        uint256 value2
    ) internal returns (uint256, uint256) {
        (IERC20 token, address to, int256 amount, int256 share) = abi.decode(
            data,
            (IERC20, address, int256, int256)
        );
        amount = int256(_num(amount, value1, value2)); // Done this way to avoid stack too deep errors
        share = int256(_num(share, value1, value2));
        return
            bentoBox.deposit{value: value}(
                token,
                msg.sender,
                to,
                uint256(amount),
                uint256(share)
            );
    }

    /// @dev Helper function to withdraw from the `bentoBox`.
    function _bentoWithdraw(
        bytes memory data,
        uint256 value1,
        uint256 value2
    ) internal returns (uint256, uint256) {
        (IERC20 token, address to, int256 amount, int256 share) = abi.decode(
            data,
            (IERC20, address, int256, int256)
        );
        return
            bentoBox.withdraw(
                token,
                msg.sender,
                to,
                _num(amount, value1, value2),
                _num(share, value1, value2)
            );
    }

    /// @dev Helper function to perform a contract call and eventually extracting revert messages on failure.
    /// Calls to `bentoBox` are not allowed for obvious security reasons.
    /// This also means that calls made from this contract shall *not* be trusted.
    function _call(
        uint256 value,
        bytes memory data,
        uint256 value1,
        uint256 value2
    ) internal returns (bytes memory, uint8) {
        (
            address callee,
            bytes memory callData,
            bool useValue1,
            bool useValue2,
            uint8 returnValues
        ) = abi.decode(data, (address, bytes, bool, bool, uint8));

        if (useValue1 && !useValue2) {
            callData = abi.encodePacked(callData, value1);
        } else if (!useValue1 && useValue2) {
            callData = abi.encodePacked(callData, value2);
        } else if (useValue1 && useValue2) {
            callData = abi.encodePacked(callData, value1, value2);
        }

        require(
            callee != address(bentoBox) && callee != address(this),
            "PrivatePool: can't call"
        );

        (bool success, bytes memory returnData) = callee.call{value: value}(
            callData
        );
        require(success, "PrivatePool: call failed");
        return (returnData, returnValues);
    }

    struct CookStatus {
        bool needsSolvencyCheck;
        bool hasAccrued;
    }

    /// @notice Executes a set of actions and allows composability (contract calls) to other contracts.
    /// @param actions An array with a sequence of actions to execute (see ACTION_ declarations).
    /// @param values A one-to-one mapped array to `actions`. ETH amounts to send along with the actions.
    /// Only applicable to `ACTION_CALL`, `ACTION_BENTO_DEPOSIT`.
    /// @param datas A one-to-one mapped array to `actions`. Contains abi encoded data of function arguments.
    /// @return value1 May contain the first positioned return value of the last executed action (if applicable).
    /// @return value2 May contain the second positioned return value of the last executed action which returns 2 values (if applicable).
    function cook(
        uint8[] calldata actions,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external payable returns (uint256 value1, uint256 value2) {
        CookStatus memory status;
        for (uint256 i = 0; i < actions.length; i++) {
            uint8 action = actions[i];
            if (!status.hasAccrued && action < 10) {
                accrue();
                status.hasAccrued = true;
            }
            if (action == ACTION_ADD_COLLATERAL) {
                (int256 share, address to, bool skim) = abi.decode(
                    datas[i],
                    (int256, address, bool)
                );
                addCollateral(to, skim, _num(share, value1, value2));
            } else if (action == ACTION_ADD_ASSET) {
                (int256 share, bool skim) = abi.decode(
                    datas[i],
                    (int256, bool)
                );
                _addAsset(skim, _num(share, value1, value2));
            } else if (action == ACTION_REPAY) {
                (int256 part, address to, bool skim) = abi.decode(
                    datas[i],
                    (int256, address, bool)
                );
                _repay(to, skim, _num(part, value1, value2));
            } else if (action == ACTION_REMOVE_ASSET) {
                (int256 share, address to) = abi.decode(
                    datas[i],
                    (int256, address)
                );
                _removeAsset(to, _num(share, value1, value2));
            } else if (action == ACTION_REMOVE_COLLATERAL) {
                (int256 share, address to) = abi.decode(
                    datas[i],
                    (int256, address)
                );
                _removeCollateral(to, _num(share, value1, value2));
                status.needsSolvencyCheck = true;
            } else if (action == ACTION_BORROW) {
                (int256 amount, address to) = abi.decode(
                    datas[i],
                    (int256, address)
                );
                (value1, value2) = _borrow(to, _num(amount, value1, value2));
                status.needsSolvencyCheck = true;
            } else if (action == ACTION_UPDATE_EXCHANGE_RATE) {
                (bool must_update, uint256 minRate, uint256 maxRate) = abi
                    .decode(datas[i], (bool, uint256, uint256));
                (bool updated, uint256 rate) = updateExchangeRate();
                require(
                    (!must_update || updated) &&
                        rate > minRate &&
                        (maxRate == 0 || rate > maxRate),
                    "PrivatePool: rate not ok"
                );
            } else if (action == ACTION_BENTO_SETAPPROVAL) {
                (
                    address user,
                    address _masterContract,
                    bool approved,
                    uint8 v,
                    bytes32 r,
                    bytes32 s
                ) = abi.decode(
                        datas[i],
                        (address, address, bool, uint8, bytes32, bytes32)
                    );
                bentoBox.setMasterContractApproval(
                    user,
                    _masterContract,
                    approved,
                    v,
                    r,
                    s
                );
            } else if (action == ACTION_BENTO_DEPOSIT) {
                (value1, value2) = _bentoDeposit(
                    datas[i],
                    values[i],
                    value1,
                    value2
                );
            } else if (action == ACTION_BENTO_WITHDRAW) {
                (value1, value2) = _bentoWithdraw(datas[i], value1, value2);
            } else if (action == ACTION_BENTO_TRANSFER) {
                (IERC20 token, address to, int256 share) = abi.decode(
                    datas[i],
                    (IERC20, address, int256)
                );
                bentoBox.transfer(
                    token,
                    msg.sender,
                    to,
                    _num(share, value1, value2)
                );
            } else if (action == ACTION_BENTO_TRANSFER_MULTIPLE) {
                (
                    IERC20 token,
                    address[] memory tos,
                    uint256[] memory shares
                ) = abi.decode(datas[i], (IERC20, address[], uint256[]));
                bentoBox.transferMultiple(token, msg.sender, tos, shares);
            } else if (action == ACTION_CALL) {
                (bytes memory returnData, uint8 returnValues) = _call(
                    values[i],
                    datas[i],
                    value1,
                    value2
                );

                if (returnValues == 1) {
                    (value1) = abi.decode(returnData, (uint256));
                } else if (returnValues == 2) {
                    (value1, value2) = abi.decode(
                        returnData,
                        (uint256, uint256)
                    );
                }
            } else if (action == ACTION_GET_REPAY_SHARE) {
                int256 part = abi.decode(datas[i], (int256));
                value1 = bentoBox.toShare(
                    asset,
                    totalDebt.toElastic(_num(part, value1, value2), true),
                    true
                );
            } else if (action == ACTION_GET_REPAY_PART) {
                int256 amount = abi.decode(datas[i], (int256));
                value1 = totalDebt.toBase(_num(amount, value1, value2), false);
            }
        }

        if (status.needsSolvencyCheck) {
            require(_isSolvent(msg.sender), "PrivatePool: borrower insolvent");
        }
    }

    /// @notice Handles the liquidation of borrowers' balances, once the borrowers' amount of collateral is too low.
    /// @param borrowers An array of borrower addresses.
    /// @param maxDebtParts A one-to-one mapping to `borrowers`, contains maximum part (not token amount) of the debt that will be liquidated of the respective borrower.
    /// @param to Address of the receiver if `swapper` is zero.
    /// @param swapper Contract address of the `ISimpleSwapper` implementation.
    function liquidate(
        address[] calldata borrowers,
        uint256[] calldata maxDebtParts,
        address to,
        ISimpleSwapper swapper
    ) public {
        // Oracle can fail but we still need to allow liquidations
        (, uint256 _exchangeRate) = updateExchangeRate();
        accrue();

        AccrueInfo memory _accrueInfo = accrueInfo;

        uint256 allCollateralShare;
        uint256 allDebtAmount;
        uint256 allDebtPart;
        Rebase memory _totalDebt = totalDebt;
        Rebase memory bentoBoxTotals = bentoBox.totals(collateral);

        for (uint256 i = 0; i < borrowers.length; i++) {
            // TODO: Find a way to not have it here; only for stack reasons
            address borrower = borrowers[i];
            // If we set an expiration at all, then by the above check it is
            // now past and every borrower can be liquidated at the current
            // price:
            if (
                block.timestamp >= accrueInfo.EXPIRATION ||
                !_isSolvent(borrower)
            ) {
                uint256 debtPart;
                {
                    uint256 availableDebtPart = borrowerDebtPart[borrower];
                    debtPart = maxDebtParts[i] > availableDebtPart
                        ? availableDebtPart
                        : maxDebtParts[i];
                    // No underflow: ensured by definition of debtPart
                    borrowerDebtPart[borrower] = availableDebtPart - debtPart;
                }
                uint256 debtAmount = _totalDebt.toElastic(debtPart, false);
                // No overflow (inner): debtAmount <= totalDebt.elastic < 2^128.
                // The exchange rate need not be reasonable: with an expiration
                // time set there is no _isSolvent() call.
                uint256 collateralShare = bentoBoxTotals.toBase(
                    (debtAmount * _accrueInfo.LIQUIDATION_MULTIPLIER_BPS).mul(
                        _exchangeRate
                    ) / (BPS * EXCHANGE_RATE_PRECISION),
                    false
                );

                // This needs to be updated here so that the same user cannot
                // be liquidated more than once. (Unless it adds up to one
                // "full" liquidation or less).
                // Underflow check is business logic: the liquidator can only
                // take enough to cover the loan (and bonus).
                userCollateralShare[borrower] = userCollateralShare[borrower]
                    .sub(collateralShare);

                if (_accrueInfo.LIQUIDATION_SEIZE_COLLATERAL) {
                    emit LogSeizeCollateral(
                        borrower,
                        collateralShare,
                        debtAmount,
                        debtPart
                    );
                } else {
                    emit LogRemoveCollateral(
                        borrower,
                        swapper == ISimpleSwapper(0) ? to : address(swapper),
                        collateralShare
                    );
                    emit LogRepay(
                        swapper == ISimpleSwapper(0)
                            ? msg.sender
                            : address(swapper),
                        borrower,
                        debtAmount,
                        debtPart
                    );
                }

                // No overflow in the below three:
                //
                // share(s) / amount(s) / part(s) involved in liquidation
                //      <= total share / amount / part
                //      <= (Bento).base / totalDebt.elastic / totalDebt.base
                //      <  2^128
                //
                // Collateral share and debt part have already been
                // successfully subtracted from some user's balance (and this
                // persists across loop runs); the calculation for debt amount
                // rounds down, so it fits if debtPart fits. It follows that
                // the condition holds for the accumulated sums.
                allCollateralShare += collateralShare;
                allDebtAmount += debtAmount;
                allDebtPart += debtPart;
            }
        }
        require(allDebtAmount != 0, "PrivatePool: all are solvent");
        // No overflow (both): (liquidated debt) <= (total debt).
        // Cast is safe (both): (liquidated debt) <= (total debt) < 2^128
        _totalDebt.elastic -= uint128(allDebtAmount);
        _totalDebt.base -= uint128(allDebtPart);
        totalDebt = _totalDebt;

        if (_accrueInfo.LIQUIDATION_SEIZE_COLLATERAL) {
            // Unlike normal liquidations, the liquidator and the lender share
            // the excess. This compensates the lender for agreeing to payment
            // in the collateral. The protocol gets a cut of the total excess.
            // So the final distribution is
            // - X% excess (configurable via LIQUIDATION_MULTIPLIER_BPS)
            // - (10% of X) protocol fee
            // - (45% of X) liquidator share of bonus
            // - 100% + (45% of X) debt + lender share of bonus
            // allCollateralShare already includes the bonus, which in turn
            // includes the protocol fee. We round the bonus down to favor the
            // lender, and the fee to favor the liquidator and lender:
            // Math: All collateral fits in 128 bits (BentoBox), so the
            // multiplications are safe:
            uint256 excessShare = (allCollateralShare *
                (_accrueInfo.LIQUIDATION_MULTIPLIER_BPS - BPS)) /
                _accrueInfo.LIQUIDATION_MULTIPLIER_BPS;
            uint256 feeShare = (excessShare * PROTOCOL_FEE_BPS) / BPS;
            uint256 liquidatorShare = (excessShare - feeShare) / 2;
            // We would add more variables for clarity, but stack depth:
            {
                CollateralBalance memory _collateralBalance = collateralBalance;
                // No underflow: All amounts fit in the collateral Bento total
                // The lender is also a "user", so only the fee and liquidator
                // share leave the user total "account":
                _collateralBalance.userTotalShare -= uint128(
                    feeShare + liquidatorShare
                );
                _collateralBalance.feesEarnedShare += uint128(feeShare);
                collateralBalance = _collateralBalance;
            }
            // The rest goes to the lender:
            userCollateralShare[lender] += (allCollateralShare -
                feeShare -
                liquidatorShare);
            // The liquidator gets the other half -- rounded in their favour,
            // if applicable:
            bentoBox.transfer(collateral, address(this), to, liquidatorShare);
        } else {
            // No underflow: allCollateralShare is the sum of quantities that
            //               have successfully been taken out of user balances.
            // Cast is safe: Above reason, and userTotalShare < 2^128
            collateralBalance.userTotalShare -= uint128(allCollateralShare);

            // Charge the protocol fee over the excess.
            // No overflow:
            //  allDebtAmount <= totalDebt.elastic < 2^128 (proof in loop)
            //  LIQUIDATION_MULTIPLIER_BPS < 2^16
            //  PROTOCOL_FEE_BPS <= 10k < 2^14 (or we have bigger problems)
            uint256 feeAmount = (allDebtAmount *
                (_accrueInfo.LIQUIDATION_MULTIPLIER_BPS - BPS) *
                PROTOCOL_FEE_BPS) / (BPS * BPS);

            // Swap using a swapper freely chosen by the caller
            // Open (flash) liquidation: get proceeds first and provide the
            // borrow after
            bentoBox.transfer(
                collateral,
                address(this),
                swapper == ISimpleSwapper(0) ? to : address(swapper),
                allCollateralShare
            );
            if (swapper != ISimpleSwapper(0)) {
                // TODO: Somehow split _receiveAsset to reduce loads?
                IERC20 _asset = asset;
                swapper.swap(
                    collateral,
                    _asset,
                    msg.sender,
                    bentoBox.toShare(
                        _asset,
                        allDebtAmount.add(feeAmount),
                        true
                    ),
                    allCollateralShare
                );
            }
            _receiveAsset(false, 0, allDebtAmount, feeAmount);
        }
    }

    /// @notice Withdraws the fees accumulated.
    function withdrawFees() public {
        accrue();
        address to = masterContract.feeTo();

        uint256 assetShare = assetBalance.feesEarnedShare;
        if (assetShare > 0) {
            bentoBox.transfer(asset, address(this), to, assetShare);
            assetBalance.feesEarnedShare = 0;
        }

        uint256 collateralShare = collateralBalance.feesEarnedShare;
        if (collateralShare > 0) {
            bentoBox.transfer(collateral, address(this), to, collateralShare);
            collateralBalance.feesEarnedShare = 0;
        }

        emit LogWithdrawFees(to, assetShare, collateralShare);
    }

    /// @notice Sets the beneficiary of fees accrued in liquidations.
    /// MasterContract Only Admin function.
    /// @param newFeeTo The address of the receiver.
    function setFeeTo(address newFeeTo) public onlyOwner {
        feeTo = newFeeTo;
        emit LogFeeTo(newFeeTo);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.12;
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";

interface ISimpleSwapper {
    /// @notice Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper.
    /// Swaps it for at least 'amountToMin' of token 'to'.
    /// Transfers the swapped tokens of 'to' into the BentoBox using a plain ERC20 transfer.
    /// Returns the amount of tokens 'to' transferred to BentoBox.
    /// (The BentoBox skim function will be used by the caller to get the swapped funds).
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) external returns (uint256 extraShare, uint256 shareReturned);
}

// SPDX-License-Identifier: CC-BY-4.0
pragma solidity 0.6.12;

// solhint-disable

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
    function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;
        require(h < d, "FullMath::mulDiv: overflow");
        return fullDiv(l, h, d);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;
import "./FullMath.sol";

// solhint-disable

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000;
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // multiply a UQ112x112 by a uint256, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, "FixedPoint::mul: overflow");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // lossy if either numerator or denominator is greater than 112 bits
    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint::fraction: div by 0");
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), "FixedPoint::fraction: overflow");
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), "FixedPoint::fraction: overflow");
            return uq112x112(uint224(result));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

// Audit on 5-Jan-2021 by Keno and BoringCrypto
// WARNING!!!
// Combining BoringBatchable with msg.value can cause double spending issues
// https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong/

import "./interfaces/IERC20.sol";

contract BaseBoringBatchable {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }
        }
    }
}

contract BoringBatchable is BaseBoringBatchable {
    /// @notice Call wrapper that performs `ERC20.permit` on `token`.
    /// Lookup `IERC20.permit`.
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@boringcrypto/boring-solidity/contracts/Domain.sol";
import "@boringcrypto/boring-solidity/contracts/ERC20.sol";
import "@boringcrypto/boring-solidity/contracts/BoringBatchable.sol";


// Staking in sSpell inspired by Chef Nomi's SushiBar - MIT license (originally WTFPL)
// modified by BoringCrypto for DictatorDAO

contract sSpell is IERC20, Domain {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringERC20 for IERC20;

    string public constant symbol = "sSPELL";
    string public constant name = "Staked Spell Tokens";
    uint8 public constant decimals = 18;
    uint256 public override totalSupply;
    uint256 private constant LOCK_TIME = 24 hours;

    IERC20 public immutable token;

    constructor(IERC20 _token) public {
        token = _token;
    }

    struct User {
        uint128 balance;
        uint128 lockedUntil;
    }

    /// @notice owner > balance mapping.
    mapping(address => User) public users;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public override allowance;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) public nonces;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function balanceOf(address user) public view override returns (uint256 balance) {
        return users[user].balance;
    }

    function _transfer(
        address from,
        address to,
        uint256 shares
    ) internal {
        User memory fromUser = users[from];
        require(block.timestamp >= fromUser.lockedUntil, "Locked");
        if (shares != 0) {
            require(fromUser.balance >= shares, "Low balance");
            if (from != to) {
                require(to != address(0), "Zero address"); // Moved down so other failed calls safe some gas
                User memory toUser = users[to];
                users[from].balance = fromUser.balance - shares.to128(); // Underflow is checked
                users[to].balance = toUser.balance + shares.to128(); // Can't overflow because totalSupply would be greater than 2^128-1;
            }
        }
        emit Transfer(from, to, shares);
    }

    function _useAllowance(address from, uint256 shares) internal {
        if (msg.sender == from) {
            return;
        }
        uint256 spenderAllowance = allowance[from][msg.sender];
        // If allowance is infinite, don't decrease it to save on gas (breaks with EIP-20).
        if (spenderAllowance != type(uint256).max) {
            require(spenderAllowance >= shares, "Low allowance");
            allowance[from][msg.sender] = spenderAllowance - shares; // Underflow is checked
        }
    }

    /// @notice Transfers `shares` tokens from `msg.sender` to `to`.
    /// @param to The address to move the tokens.
    /// @param shares of the tokens to move.
    /// @return (bool) Returns True if succeeded.
    function transfer(address to, uint256 shares) public returns (bool) {
        _transfer(msg.sender, to, shares);
        return true;
    }

    /// @notice Transfers `shares` tokens from `from` to `to`. Caller needs approval for `from`.
    /// @param from Address to draw tokens from.
    /// @param to The address to move the tokens.
    /// @param shares The token shares to move.
    /// @return (bool) Returns True if succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 shares
    ) public returns (bool) {
        _useAllowance(from, shares);
        _transfer(from, to, shares);
        return true;
    }

    /// @notice Approves `amount` from sender to be spend by `spender`.
    /// @param spender Address of the party that can draw from msg.sender's account.
    /// @param amount The maximum collective amount that `spender` can draw.
    /// @return (bool) Returns True if approved.
    function approve(address spender, uint256 amount) public override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparator();
    }

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant PERMIT_SIGNATURE_HASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice Approves `value` from `owner_` to be spend by `spender`.
    /// @param owner_ Address of the owner.
    /// @param spender The address of the spender that gets approved to draw from `owner_`.
    /// @param value The maximum collective amount that `spender` can draw.
    /// @param deadline This permit must be redeemed before this deadline (UTC timestamp in seconds).
    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(owner_ != address(0), "Zero owner");
        require(block.timestamp < deadline, "Expired");
        require(
            ecrecover(_getDigest(keccak256(abi.encode(PERMIT_SIGNATURE_HASH, owner_, spender, value, nonces[owner_]++, deadline))), v, r, s) ==
                owner_,
            "Invalid Sig"
        );
        allowance[owner_][spender] = value;
        emit Approval(owner_, spender, value);
    }

    /// math is ok, because amount, totalSupply and shares is always 0 <= amount <= 100.000.000 * 10^18
    /// theoretically you can grow the amount/share ratio, but it's not practical and useless
    function mint(uint256 amount) public returns (bool) {
        require(msg.sender != address(0), "Zero address");
        User memory user = users[msg.sender];

        uint256 totalTokens = token.balanceOf(address(this));
        uint256 shares = totalSupply == 0 ? amount : (amount * totalSupply) / totalTokens;
        user.balance += shares.to128();
        user.lockedUntil = (block.timestamp + LOCK_TIME).to128();
        users[msg.sender] = user;
        totalSupply += shares;

        token.safeTransferFrom(msg.sender, address(this), amount);

        emit Transfer(address(0), msg.sender, shares);
        return true;
    }

    function _burn(
        address from,
        address to,
        uint256 shares
    ) internal {
        require(to != address(0), "Zero address");
        User memory user = users[from];
        require(block.timestamp >= user.lockedUntil, "Locked");
        uint256 amount = (shares * token.balanceOf(address(this))) / totalSupply;
        users[from].balance = user.balance.sub(shares.to128()); // Must check underflow
        totalSupply -= shares;

        token.safeTransfer(to, amount);

        emit Transfer(from, address(0), shares);
    }

    function burn(address to, uint256 shares) public returns (bool) {
        _burn(msg.sender, to, shares);
        return true;
    }

    function burnFrom(
        address from,
        address to,
        uint256 shares
    ) public returns (bool) {
        _useAllowance(from, shares);
        _burn(from, to, shares);
        return true;
    }
}

// SPDX-License-Identifier: MIT

// Spell

// Special thanks to:
// @BoringCrypto for his great libraries

pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/ERC20.sol";
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";

/// @title Spell
/// @author 0xMerlin
/// @dev This contract allows contract calls to any contract (except BentoBox)
/// from arbitrary callers thus, don't trust calls from this contract in any circumstances.
contract Spell is ERC20, BoringOwnable {
    using BoringMath for uint256;
    // ERC20 'variables'
    string public constant symbol = "SPELL";
    string public constant name = "Spell Token";
    uint8 public constant decimals = 18;
    uint256 public override totalSupply;
    uint256 public constant MAX_SUPPLY = 420 * 1e27;

    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "SPELL: no mint to zero address");
        require(MAX_SUPPLY >= totalSupply.add(amount), "SPELL: Don't go over MAX");

        totalSupply = totalSupply + amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED

// Private Pool (NFT collateral)

//    (                (   (
//    )\      )    (   )\  )\ )  (
//  (((_)  ( /(   ))\ ((_)(()/(  )(    (    (
//  )\___  )(_)) /((_) _   ((_))(()\   )\   )\ )
// ((/ __|((_)_ (_))( | |  _| |  ((_) ((_) _(_/(
//  | (__ / _` || || || |/ _` | | '_|/ _ \| ' \))
//   \___|\__,_| \_,_||_|\__,_| |_|  \___/|_||_|

// Copyright (c) 2021 BoringCrypto - All rights reserved
// Twitter: @Boring_Crypto

// Special thanks to:
// @0xKeno - for all his invaluable contributions
// @burger_crypto - for the idea of trying to let the LPs benefit from liquidations

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@boringcrypto/boring-solidity/contracts/Domain.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IMasterContract.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "./interfaces/IERC721.sol";

struct TokenLoanParams {
    uint128 valuation; // How much will you get? OK to owe until expiration.
    uint64 duration; // Length of loan in seconds
    uint16 annualInterestBPS; // Variable cost of taking out the loan
}

interface ILendingClub {
    // Per token settings.
    function willLend(uint256 tokenId, TokenLoanParams memory params)
        external
        view
        returns (bool);

    function lendingConditions(address nftPair, uint256 tokenId)
        external
        view
        returns (TokenLoanParams memory);
}

interface INFTPair {
    function collateral() external view returns (IERC721);

    function asset() external view returns (IERC20);

    function masterContract() external view returns (address);

    function bentoBox() external view returns (IBentoBoxV1);

    function removeCollateral(uint256 tokenId, address to) external;
}

/// @title NFTPair
/// @dev This contract allows contract calls to any contract (except BentoBox)
/// from arbitrary callers thus, don't trust calls from this contract in any circumstances.
contract NFTPair is BoringOwnable, Domain, IMasterContract {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;

    event LogRequestLoan(
        address indexed borrower,
        uint256 indexed tokenId,
        uint128 valuation,
        uint64 duration,
        uint16 annualInterestBPS
    );
    event LogUpdateLoanParams(
        uint256 indexed tokenId,
        uint128 valuation,
        uint64 duration,
        uint16 annualInterestBPS
    );
    // This automatically clears the associated loan, if any
    event LogRemoveCollateral(uint256 indexed tokenId, address recipient);
    // Details are in the loan request
    event LogLend(address indexed lender, uint256 indexed tokenId);
    event LogRepay(address indexed from, uint256 indexed tokenId);
    event LogFeeTo(address indexed newFeeTo);
    event LogWithdrawFees(address indexed feeTo, uint256 feeShare);

    // Immutables (for MasterContract and all clones)
    IBentoBoxV1 public immutable bentoBox;
    NFTPair public immutable masterContract;

    // MasterContract variables
    address public feeTo;

    // Per clone variables
    // Clone init settings
    IERC721 public collateral;
    IERC20 public asset;

    // A note on terminology:
    // "Shares" are BentoBox shares.

    // Track assets we own. Used to allow skimming the excesss.
    uint256 public feesEarnedShare;

    // Per token settings.
    mapping(uint256 => TokenLoanParams) public tokenLoanParams;

    uint8 private constant LOAN_INITIAL = 0;
    uint8 private constant LOAN_REQUESTED = 1;
    uint8 private constant LOAN_OUTSTANDING = 2;
    struct TokenLoan {
        address borrower;
        address lender;
        uint64 startTime;
        uint8 status;
    }
    mapping(uint256 => TokenLoan) public tokenLoan;

    // Do not go over 100% on either of these..
    uint256 private constant PROTOCOL_FEE_BPS = 1000;
    uint256 private constant OPEN_FEE_BPS = 100;
    uint256 private constant BPS = 10_000;
    uint256 private constant YEAR_BPS = 3600 * 24 * 365 * 10_000;

    // Highest order term in the Maclaurin series for exp used by
    // `calculateIntest`.
    // Intuitive interpretation: interest continuously accrues on the principal.
    // That interest, in turn, earns "second-order" interest-on-interest, which
    // itself earns "third-order" interest, etc. This constant determines how
    // far we take this until we stop counting.
    //
    // The error, in terms of the interest rate, is at least
    //
    //            ----- n                        ----- Infinity
    //             \           x^k                \              x^k
    //      e^x -   )          ---   , which is    )             --- ,
    //             /            k!                /               k!
    //            ----- k = 1       k            ----- k = n + 1
    //
    // where n = COMPOUND_INTEREST_TERMS, and x = rt is the total amount of
    // interest that is owed at rate r over time t. It makes no difference if
    // this is, say, 5%/year for 10 years, or 50% in one year; the calculation
    // is the same. Why "at least"? There are also rounding errors. See
    // `calculateInterest` for more detail.
    // The factorial in the denominator "wins"; for all reasonable (and quite
    // a few unreasonable) interest rates, the lower-order terms contribute the
    // most to the total. The following table lists some of the calculated
    // approximations for different values of n, along with the "true" result:
    //
    // Total:         10%    20%    50%    100%    200%      500%       1000%
    // -----------------------------------------------------------------------
    // n = 1:         10.0%  20.0%  50.0%  100.0%  200.0%    500.0%     1000.0%
    // n = 2:         10.5%  22.0%  62.5%  150.0%  400.0%   1750.0%     6000.0%
    // n = 3:         10.5%  22.1%  64.6%  166.7%  533.3%   3833.3%    22666.7%
    // n = 4:         10.5%  22.1%  64.8%  170.8%  600.0%   6437.5%    64333.3%
    // n = 5:         10.5%  22.1%  64.9%  171.7%  626.7%   9041.7%   147666.7%
    // n = 6:         10.5%  22.1%  64.9%  171.8%  635.6%  11211.8%   286555.6%
    // n = 7:         10.5%  22.1%  64.9%  171.8%  638.1%  12761.9%   484968.3%
    // n = 8:         10.5%  22.1%  64.9%  171.8%  638.7%  13730.7%   732984.1%
    // n = 9:         10.5%  22.1%  64.9%  171.8%  638.9%  14268.9%  1008557.3%
    // n = 10:        10.5%  22.1%  64.9%  171.8%  638.9%  14538.1%  1284130.5%
    //
    // (n=Infinity):  10.5%  22.1%  64.9%  171.8%  638.9%  14741.3%  2202546.6%
    //
    // For instance, calculating the compounding effects of 200% in "total"
    // interest to the sixth order results in 635.6%, whereas the true result
    // is 638.9%.
    // At 500% that difference is a little more dramatic, but it is still in
    // the same ballpark -- and of little practical consequence unless the
    // collateral can be expected to go up more than 112 times in value.
    // Still, for volatile tokens, or an asset that is somehow known to be very
    // inflationary, use a different number.
    // Zero (no interest at all) is ignored and treated as one (linear only).
    uint8 private constant COMPOUND_INTEREST_TERMS = 6;

    // For signed lend / borrow requests:
    mapping(address => uint256) public nonces;

    /// @notice The constructor is only used for the initial master contract.
    /// @notice Subsequent clones are initialised via `init`.
    constructor(IBentoBoxV1 bentoBox_) public {
        bentoBox = bentoBox_;
        masterContract = this;
    }

    /// @notice De facto constructor for clone contracts
    function init(bytes calldata data) public payable override {
        require(
            address(collateral) == address(0),
            "NFTPair: already initialized"
        );
        (collateral, asset) = abi.decode(data, (IERC721, IERC20));
        require(address(collateral) != address(0), "NFTPair: bad pair");
    }

    function updateLoanParams(uint256 tokenId, TokenLoanParams memory params)
        public
    {
        TokenLoan memory loan = tokenLoan[tokenId];
        if (loan.status == LOAN_OUTSTANDING) {
            // The lender can change terms so long as the changes are strictly
            // the same or better for the borrower:
            require(msg.sender == loan.lender, "NFTPair: not the lender");
            TokenLoanParams memory cur = tokenLoanParams[tokenId];
            require(
                params.duration >= cur.duration &&
                    params.valuation <= cur.valuation &&
                    params.annualInterestBPS <= cur.annualInterestBPS,
                "NFTPair: worse params"
            );
        } else if (loan.status == LOAN_REQUESTED) {
            // The borrower has already deposited the collateral and can
            // change whatever they like
            require(msg.sender == loan.borrower, "NFTPair: not the borrower");
        } else {
            // The loan has not been taken out yet; the borrower needs to
            // provide collateral.
            revert("NFTPair: no collateral");
        }
        tokenLoanParams[tokenId] = params;
        emit LogUpdateLoanParams(
            tokenId,
            params.valuation,
            params.duration,
            params.annualInterestBPS
        );
    }

    function _requestLoan(
        address collateralProvider,
        uint256 tokenId,
        TokenLoanParams memory params,
        address to,
        bool skim
    ) private {
        // Edge case: valuation can be zero. That effectively gifts the NFT and
        // is therefore a bad idea, but does not break the contract.
        require(
            tokenLoan[tokenId].status == LOAN_INITIAL,
            "NFTPair: loan exists"
        );
        if (skim) {
            require(
                collateral.ownerOf(tokenId) == address(this),
                "NFTPair: skim failed"
            );
        } else {
            collateral.transferFrom(collateralProvider, address(this), tokenId);
        }
        TokenLoan memory loan;
        loan.borrower = to;
        loan.status = LOAN_REQUESTED;
        tokenLoan[tokenId] = loan;
        tokenLoanParams[tokenId] = params;

        emit LogRequestLoan(
            to,
            tokenId,
            params.valuation,
            params.duration,
            params.annualInterestBPS
        );
    }

    /// @notice Deposit an NFT as collateral and request a loan against it
    /// @param tokenId ID of the NFT
    /// @param to Address to receive the loan, or option to withdraw collateral
    /// @param params Loan conditions on offer
    /// @param skim True if the token has already been transfered
    function requestLoan(
        uint256 tokenId,
        TokenLoanParams memory params,
        address to,
        bool skim
    ) public {
        _requestLoan(msg.sender, tokenId, params, to, skim);
    }

    /// @notice Removes `tokenId` as collateral and transfers it to `to`.
    /// @notice This destroys the loan.
    /// @param tokenId The token
    /// @param to The receiver of the token.
    function removeCollateral(uint256 tokenId, address to) public {
        TokenLoan memory loan = tokenLoan[tokenId];
        if (loan.status == LOAN_REQUESTED) {
            // We are withdrawing collateral that is not in use:
            require(msg.sender == loan.borrower, "NFTPair: not the borrower");
        } else if (loan.status == LOAN_OUTSTANDING) {
            // We are seizing collateral as the lender. The loan has to be
            // expired and not paid off:
            require(msg.sender == loan.lender, "NFTPair: not the lender");
            require(
                // Addition is safe: both summands are smaller than 256 bits
                uint256(loan.startTime) + tokenLoanParams[tokenId].duration <=
                    block.timestamp,
                "NFTPair: not expired"
            );
        }
        // If there somehow is collateral but no accompanying loan, then anyone
        // can claim it by first requesting a loan with `skim` set to true, and
        // then withdrawing. So we might as well allow it here..
        delete tokenLoan[tokenId];
        collateral.transferFrom(address(this), to, tokenId);
        emit LogRemoveCollateral(tokenId, to);
    }

    // Assumes the lender has agreed to the loan.
    function _lend(
        address lender,
        uint256 tokenId,
        TokenLoanParams memory accepted,
        bool skim
    ) internal {
        TokenLoan memory loan = tokenLoan[tokenId];
        require(loan.status == LOAN_REQUESTED, "NFTPair: not available");
        TokenLoanParams memory params = tokenLoanParams[tokenId];

        // Valuation has to be an exact match, everything else must be at least
        // as good for the lender as `accepted`.
        require(
            params.valuation == accepted.valuation &&
                params.duration <= accepted.duration &&
                params.annualInterestBPS >= accepted.annualInterestBPS,
            "NFTPair: bad params"
        );

        uint256 totalShare = bentoBox.toShare(asset, params.valuation, false);
        // No overflow: at most 128 + 16 bits (fits in BentoBox)
        uint256 openFeeShare = (totalShare * OPEN_FEE_BPS) / BPS;
        uint256 protocolFeeShare = (openFeeShare * PROTOCOL_FEE_BPS) / BPS;

        if (skim) {
            require(
                bentoBox.balanceOf(asset, address(this)) >=
                    (totalShare -
                        openFeeShare +
                        protocolFeeShare +
                        feesEarnedShare),
                "NFTPair: skim too much"
            );
        } else {
            bentoBox.transfer(
                asset,
                lender,
                address(this),
                totalShare - openFeeShare + protocolFeeShare
            );
        }
        // No underflow: follows from OPEN_FEE_BPS <= BPS
        uint256 borrowerShare = totalShare - openFeeShare;
        bentoBox.transfer(asset, address(this), loan.borrower, borrowerShare);
        // No overflow: addends (and result) must fit in BentoBox
        feesEarnedShare += protocolFeeShare;

        loan.lender = lender;
        loan.status = LOAN_OUTSTANDING;
        loan.startTime = uint64(block.timestamp); // Do not use in 12e10 years..
        tokenLoan[tokenId] = loan;

        emit LogLend(lender, tokenId);
    }

    /// @notice Lends with the parameters specified by the borrower.
    /// @param tokenId ID of the token that will function as collateral
    /// @param accepted Loan parameters as the lender saw them, for security
    /// @param skim True if the funds have been transfered to the contract
    function lend(
        uint256 tokenId,
        TokenLoanParams memory accepted,
        bool skim
    ) public {
        _lend(msg.sender, tokenId, accepted, skim);
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparator();
    }

    // NOTE on signature hashes: the domain separator only guarantees that the
    // chain ID and master contract are a match, so we explicitly include the
    // clone address (and the asset/collateral addresses):

    // keccak256("Lend(address contract,uint256 tokenId,bool anyTokenId,uint128 valuation,uint64 duration,uint16 annualInterestBPS,uint256 nonce,uint256 deadline)")
    bytes32 private constant LEND_SIGNATURE_HASH =
        0x06bcca6f35b7c1b98f11abbb10957d273a681069ba90358de25404f49e2430f8;

    // keccak256("Borrow(address contract,uint256 tokenId,uint128 valuation,uint64 duration,uint16 annualInterestBPS,uint256 nonce,uint256 deadline)")
    bytes32 private constant BORROW_SIGNATURE_HASH =
        0xf2c9128b0fb8406af3168320897e5ff08f3bb536dd5f804c29ed276e93ec4336;

    /// @notice Request and immediately borrow from a pre-committed lender

    /// @notice Caller provides collateral; loan can go to a different address.
    /// @param tokenId ID of the token that will function as collateral
    /// @param lender Lender, whose BentoBox balance the funds will come from
    /// @param recipient Address to receive the loan.
    /// @param params Loan parameters requested, and signed by the lender
    /// @param skimCollateral True if the collateral has already been transfered
    /// @param anyTokenId Set if lender agreed to any token. Must have tokenId 0 in signature.
    function requestAndBorrow(
        uint256 tokenId,
        address lender,
        address recipient,
        TokenLoanParams memory params,
        bool skimCollateral,
        bool anyTokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        if (v == 0 && r == bytes32(0) && s == bytes32(0)) {
            require(
                ILendingClub(lender).willLend(tokenId, params),
                "NFTPair: LendingClub does not like you"
            );
        } else {
            require(block.timestamp <= deadline, "NFTPair: signature expired");
            uint256 nonce = nonces[lender]++;
            bytes32 dataHash = keccak256(
                abi.encode(
                    LEND_SIGNATURE_HASH,
                    address(this),
                    anyTokenId ? 0 : tokenId,
                    anyTokenId,
                    params.valuation,
                    params.duration,
                    params.annualInterestBPS,
                    nonce,
                    deadline
                )
            );
            require(
                ecrecover(_getDigest(dataHash), v, r, s) == lender,
                "NFTPair: signature invalid"
            );
        }
        _requestLoan(msg.sender, tokenId, params, recipient, skimCollateral);
        _lend(lender, tokenId, params, false);
    }

    /// @notice Take collateral from a pre-commited borrower and lend against it
    /// @notice Collateral must come from the borrower, not a third party.
    /// @param tokenId ID of the token that will function as collateral
    /// @param borrower Address that provides collateral and receives the loan
    /// @param params Loan terms offered, and signed by the borrower
    /// @param skimFunds True if the funds have been transfered to the contract
    function takeCollateralAndLend(
        uint256 tokenId,
        address borrower,
        TokenLoanParams memory params,
        bool skimFunds,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(block.timestamp <= deadline, "NFTPair: signature expired");
        uint256 nonce = nonces[borrower]++;
        bytes32 dataHash = keccak256(
            abi.encode(
                BORROW_SIGNATURE_HASH,
                address(this),
                tokenId,
                params.valuation,
                params.duration,
                params.annualInterestBPS,
                nonce,
                deadline
            )
        );
        require(
            ecrecover(_getDigest(dataHash), v, r, s) == borrower,
            "NFTPair: signature invalid"
        );
        _requestLoan(borrower, tokenId, params, borrower, false);
        _lend(msg.sender, tokenId, params, skimFunds);
    }

    /// Approximates continuous compounding. Uses Horner's method to evaluate
    /// the truncated Maclaurin series for exp - 1, accumulating rounding
    /// errors along the way. The following is always guaranteed:
    ///
    ///   principal * time * apr <= result <= principal * (e^(time * apr) - 1),
    ///
    /// where time = t/YEAR, up to at most the rounding error obtained in
    /// calculating linear interest.
    ///
    /// If the theoretical result that we are approximating (the rightmost part
    /// of the above inquality) fits in 128 bits, then the function is
    /// guaranteed not to revert (unless n > 250, which is way too high).
    /// If even the linear interest (leftmost part of the inequality) does not
    /// the function will revert.
    /// Otherwise, the function may revert, return a reasonable result, or
    /// return a very inaccurate result. Even then the above inequality is
    /// respected.
    function calculateInterest(
        uint256 principal,
        uint64 t,
        uint16 aprBPS
    ) public pure returns (uint256 interest) {
        // (NOTE: n is hardcoded as COMPOUND_INTEREST_TERMS)
        //
        // We calculate
        //
        //  ----- n                                       ----- n
        //   \           principal * (t * aprBPS)^k        \
        //    )          --------------------------   =:    )          term_k
        //   /                k! * YEAR_BPS^k              /
        //  ----- k = 1                                   ----- k = 1
        //
        // which approaches, but never exceeds the "theoretical" result,
        //
        //          M := principal * [ exp (t * aprBPS / YEAR_BPS) - 1
        //
        // as n goes to infinity. We use the fact that
        //
        //               principal * (t * aprBPS)^(k-1) * (t * aprBPS)
        //      term_k = ---------------------------------------------
        //                  (k-1)! * k * YEAR_BPS^(k-1) * YEAR_BPS
        //
        //                             t * aprBPS
        //             = term_{k-1} * ------------                          (*)
        //                            k * YEAR_BPS
        //
        // to calculate the terms one by one. The principal affords us the
        // precision to carry out the division without resorting to fixed-point
        // math. Any rounding error is downward, which we consider acceptable.
        //
        // Since all numbers involved are positive, each term is certainly
        // bounded above by M. From (*) we see that any intermediate results
        // are at most
        //
        //                      denom_k := k * YEAR_BPS.
        //
        // times M. Since YEAR_BPS fits in 38 bits, denom_k fits in 46 bits,
        // which proves that all calculations will certainly not overflow if M
        // fits in 128 bits.
        //
        // If M does not fit, then the intermediate results for some term may
        // eventually overflow, but this cannot happen at the first term, and
        // neither can the total overflow because it uses checked math.
        //
        // This constitutes a guarantee of specified behavior when M >= 2^128.
        uint256 x = uint256(t) * aprBPS;
        uint256 term_k = (principal * x) / YEAR_BPS;
        uint256 denom_k = YEAR_BPS;

        interest = term_k;
        for (uint256 k = 2; k <= COMPOUND_INTEREST_TERMS; k++) {
            denom_k += YEAR_BPS;
            term_k = (term_k * x) / denom_k;
            interest = interest.add(term_k); // <- Only overflow check we need
        }

        if (interest >= 2**128) {
            revert();
        }
    }

    function repay(uint256 tokenId, bool skim) public returns (uint256 amount) {
        TokenLoan memory loan = tokenLoan[tokenId];
        require(loan.status == LOAN_OUTSTANDING, "NFTPair: no loan");
        TokenLoanParams memory loanParams = tokenLoanParams[tokenId];
        require(
            // Addition is safe: both summands are smaller than 256 bits
            uint256(loan.startTime) + loanParams.duration > block.timestamp,
            "NFTPair: loan expired"
        );

        uint128 principal = loanParams.valuation;

        // No underflow: loan.startTime is only ever set to a block timestamp
        // Cast is safe: if this overflows, then all loans have expired anyway
        uint256 interest = calculateInterest(
            principal,
            uint64(block.timestamp - loan.startTime),
            loanParams.annualInterestBPS
        ).to128();
        uint256 fee = (interest * PROTOCOL_FEE_BPS) / BPS;
        amount = principal + interest;

        uint256 totalShare = bentoBox.toShare(asset, amount, false);
        uint256 feeShare = bentoBox.toShare(asset, fee, false);

        address from;
        if (skim) {
            require(
                bentoBox.balanceOf(asset, address(this)) >=
                    (totalShare + feesEarnedShare),
                "NFTPair: skim too much"
            );
            from = address(this);
            // No overflow: result fits in BentoBox
        } else {
            bentoBox.transfer(asset, msg.sender, address(this), feeShare);
            from = msg.sender;
        }
        // No underflow: PROTOCOL_FEE_BPS < BPS by construction.
        feesEarnedShare += feeShare;
        delete tokenLoan[tokenId];

        bentoBox.transfer(asset, from, loan.lender, totalShare - feeShare);
        collateral.transferFrom(address(this), loan.borrower, tokenId);

        emit LogRepay(from, tokenId);
    }

    uint8 internal constant ACTION_REPAY = 2;
    uint8 internal constant ACTION_REMOVE_COLLATERAL = 4;

    uint8 internal constant ACTION_REQUEST_LOAN = 12;
    uint8 internal constant ACTION_LEND = 13;

    // Function on BentoBox
    uint8 internal constant ACTION_BENTO_DEPOSIT = 20;
    uint8 internal constant ACTION_BENTO_WITHDRAW = 21;
    uint8 internal constant ACTION_BENTO_TRANSFER = 22;
    uint8 internal constant ACTION_BENTO_TRANSFER_MULTIPLE = 23;
    uint8 internal constant ACTION_BENTO_SETAPPROVAL = 24;

    // Any external call (except to BentoBox)
    uint8 internal constant ACTION_CALL = 30;

    // Signed requests
    uint8 internal constant ACTION_REQUEST_AND_BORROW = 40;
    uint8 internal constant ACTION_TAKE_COLLATERAL_AND_LEND = 41;

    int256 internal constant USE_VALUE1 = -1;
    int256 internal constant USE_VALUE2 = -2;

    /// @dev Helper function for choosing the correct value (`value1` or `value2`) depending on `inNum`.
    function _num(
        int256 inNum,
        uint256 value1,
        uint256 value2
    ) internal pure returns (uint256 outNum) {
        outNum = inNum >= 0
            ? uint256(inNum)
            : (inNum == USE_VALUE1 ? value1 : value2);
    }

    /// @dev Helper function for depositing into `bentoBox`.
    function _bentoDeposit(
        bytes memory data,
        uint256 value,
        uint256 value1,
        uint256 value2
    ) internal returns (uint256, uint256) {
        (IERC20 token, address to, int256 amount, int256 share) = abi.decode(
            data,
            (IERC20, address, int256, int256)
        );
        amount = int256(_num(amount, value1, value2)); // Done this way to avoid stack too deep errors
        share = int256(_num(share, value1, value2));
        return
            bentoBox.deposit{value: value}(
                token,
                msg.sender,
                to,
                uint256(amount),
                uint256(share)
            );
    }

    /// @dev Helper function to withdraw from the `bentoBox`.
    function _bentoWithdraw(
        bytes memory data,
        uint256 value1,
        uint256 value2
    ) internal returns (uint256, uint256) {
        (IERC20 token, address to, int256 amount, int256 share) = abi.decode(
            data,
            (IERC20, address, int256, int256)
        );
        return
            bentoBox.withdraw(
                token,
                msg.sender,
                to,
                _num(amount, value1, value2),
                _num(share, value1, value2)
            );
    }

    /// @dev Helper function to perform a contract call and eventually extracting revert messages on failure.
    /// Calls to `bentoBox` or `collateral` are not allowed for security reasons.
    /// This also means that calls made from this contract shall *not* be trusted.
    function _call(
        uint256 value,
        bytes memory data,
        uint256 value1,
        uint256 value2
    ) internal returns (bytes memory, uint8) {
        (
            address callee,
            bytes memory callData,
            bool useValue1,
            bool useValue2,
            uint8 returnValues
        ) = abi.decode(data, (address, bytes, bool, bool, uint8));

        if (useValue1 && !useValue2) {
            callData = abi.encodePacked(callData, value1);
        } else if (!useValue1 && useValue2) {
            callData = abi.encodePacked(callData, value2);
        } else if (useValue1 && useValue2) {
            callData = abi.encodePacked(callData, value1, value2);
        }

        require(
            callee != address(bentoBox) &&
                callee != address(collateral) &&
                callee != address(this),
            "NFTPair: can't call"
        );

        (bool success, bytes memory returnData) = callee.call{value: value}(
            callData
        );
        require(success, "NFTPair: call failed");
        return (returnData, returnValues);
    }

    /// @notice Executes a set of actions and allows composability (contract calls) to other contracts.
    /// @param actions An array with a sequence of actions to execute (see ACTION_ declarations).
    /// @param values A one-to-one mapped array to `actions`. ETH amounts to send along with the actions.
    /// Only applicable to `ACTION_CALL`, `ACTION_BENTO_DEPOSIT`.
    /// @param datas A one-to-one mapped array to `actions`. Contains abi encoded data of function arguments.
    /// @return value1 May contain the first positioned return value of the last executed action (if applicable).
    /// @return value2 May contain the second positioned return value of the last executed action which returns 2 values (if applicable).
    function cook(
        uint8[] calldata actions,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external payable returns (uint256 value1, uint256 value2) {
        for (uint256 i = 0; i < actions.length; i++) {
            uint8 action = actions[i];
            if (action == ACTION_REPAY) {
                (uint256 tokenId, bool skim) = abi.decode(
                    datas[i],
                    (uint256, bool)
                );
                repay(tokenId, skim);
            } else if (action == ACTION_REMOVE_COLLATERAL) {
                (uint256 tokenId, address to) = abi.decode(
                    datas[i],
                    (uint256, address)
                );
                removeCollateral(tokenId, to);
            } else if (action == ACTION_REQUEST_LOAN) {
                (
                    uint256 tokenId,
                    TokenLoanParams memory params,
                    address to,
                    bool skim
                ) = abi.decode(
                        datas[i],
                        (uint256, TokenLoanParams, address, bool)
                    );
                requestLoan(tokenId, params, to, skim);
            } else if (action == ACTION_LEND) {
                (
                    uint256 tokenId,
                    TokenLoanParams memory params,
                    bool skim
                ) = abi.decode(datas[i], (uint256, TokenLoanParams, bool));
                lend(tokenId, params, skim);
            } else if (action == ACTION_BENTO_SETAPPROVAL) {
                (
                    address user,
                    address _masterContract,
                    bool approved,
                    uint8 v,
                    bytes32 r,
                    bytes32 s
                ) = abi.decode(
                        datas[i],
                        (address, address, bool, uint8, bytes32, bytes32)
                    );
                bentoBox.setMasterContractApproval(
                    user,
                    _masterContract,
                    approved,
                    v,
                    r,
                    s
                );
            } else if (action == ACTION_BENTO_DEPOSIT) {
                (value1, value2) = _bentoDeposit(
                    datas[i],
                    values[i],
                    value1,
                    value2
                );
            } else if (action == ACTION_BENTO_WITHDRAW) {
                (value1, value2) = _bentoWithdraw(datas[i], value1, value2);
            } else if (action == ACTION_BENTO_TRANSFER) {
                (IERC20 token, address to, int256 share) = abi.decode(
                    datas[i],
                    (IERC20, address, int256)
                );
                bentoBox.transfer(
                    token,
                    msg.sender,
                    to,
                    _num(share, value1, value2)
                );
            } else if (action == ACTION_BENTO_TRANSFER_MULTIPLE) {
                (
                    IERC20 token,
                    address[] memory tos,
                    uint256[] memory shares
                ) = abi.decode(datas[i], (IERC20, address[], uint256[]));
                bentoBox.transferMultiple(token, msg.sender, tos, shares);
            } else if (action == ACTION_CALL) {
                (bytes memory returnData, uint8 returnValues) = _call(
                    values[i],
                    datas[i],
                    value1,
                    value2
                );

                if (returnValues == 1) {
                    (value1) = abi.decode(returnData, (uint256));
                } else if (returnValues == 2) {
                    (value1, value2) = abi.decode(
                        returnData,
                        (uint256, uint256)
                    );
                }
            } else if (action == ACTION_REQUEST_AND_BORROW) {
                (
                    uint256 tokenId,
                    address lender,
                    address recipient,
                    TokenLoanParams memory params,
                    bool skimCollateral,
                    bool anyTokenId,
                    uint256 deadline,
                    uint8 v,
                    bytes32 r,
                    bytes32 s
                ) = abi.decode(
                        datas[i],
                        (
                            uint256,
                            address,
                            address,
                            TokenLoanParams,
                            bool,
                            bool,
                            uint256,
                            uint8,
                            bytes32,
                            bytes32
                        )
                    );
                requestAndBorrow(
                    tokenId,
                    lender,
                    recipient,
                    params,
                    skimCollateral,
                    anyTokenId,
                    deadline,
                    v,
                    r,
                    s
                );
            } else if (action == ACTION_TAKE_COLLATERAL_AND_LEND) {
                (
                    uint256 tokenId,
                    address borrower,
                    TokenLoanParams memory params,
                    bool skimFunds,
                    uint256 deadline,
                    uint8 v,
                    bytes32 r,
                    bytes32 s
                ) = abi.decode(
                        datas[i],
                        (
                            uint256,
                            address,
                            TokenLoanParams,
                            bool,
                            uint256,
                            uint8,
                            bytes32,
                            bytes32
                        )
                    );
                takeCollateralAndLend(
                    tokenId,
                    borrower,
                    params,
                    skimFunds,
                    deadline,
                    v,
                    r,
                    s
                );
            }
        }
    }

    /// @notice Withdraws the fees accumulated.
    function withdrawFees() public {
        address to = masterContract.feeTo();

        uint256 _share = feesEarnedShare;
        if (_share > 0) {
            bentoBox.transfer(asset, address(this), to, _share);
            feesEarnedShare = 0;
        }

        emit LogWithdrawFees(to, _share);
    }

    /// @notice Sets the beneficiary of fees accrued in liquidations.
    /// MasterContract Only Admin function.
    /// @param newFeeTo The address of the receiver.
    function setFeeTo(address newFeeTo) public onlyOwner {
        feeTo = newFeeTo;
        emit LogFeeTo(newFeeTo);
    }
}

// SPDX-License-Identifier: MIT
// Taken from OpenZeppelin contracts v3

pragma solidity >=0.6.2 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
// Taken from OpenZeppelin contracts v3

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";

interface IYearnVault {
    function deposit(uint256 amount, address recipient) external returns (uint256 shares);
}

contract YearnLiquidityMigrationHelper {
    using BoringMath for uint256;
    using BoringERC20 for IERC20;

    // Local variables
    IBentoBoxV1 public immutable bentoBox;

    constructor(IBentoBoxV1 bentoBox_) public {
        bentoBox = bentoBox_;
    }

    function migrate(
        IERC20 token,
        IYearnVault vault,
        uint256 amount,
        address recipient
    ) external {
        token.approve(address(vault), amount);
        uint256 shares = vault.deposit(amount, address(bentoBox));
        bentoBox.deposit(token, address(bentoBox), recipient, shares, 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@sushiswap/bentobox-sdk/contracts/IStrategy.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";

// solhint-disable not-rely-on-time

contract SimpleStrategyMock is IStrategy {
    using BoringMath for uint256;
    using BoringERC20 for IERC20;

    IERC20 private immutable token;
    address private immutable bentoBox;

    modifier onlyBentoBox() {
        require(msg.sender == bentoBox, "Ownable: caller is not the owner");
        _;
    }

    constructor(address bentoBox_, IERC20 token_) public {
        bentoBox = bentoBox_;
        token = token_;
    }

    // Send the assets to the Strategy and call skim to invest them
    function skim(uint256) external override onlyBentoBox {
        // Leave the tokens on the contract
        return;
    }

    // Harvest any profits made converted to the asset and pass them to the caller
    function harvest(uint256 balance, address) external override onlyBentoBox returns (int256 amountAdded) {
        amountAdded = int256(token.balanceOf(address(this)).sub(balance));
        token.safeTransfer(bentoBox, uint256(amountAdded)); // Add as profit
    }

    // Withdraw assets. The returned amount can differ from the requested amount due to rounding or if the request was more than there is.
    function withdraw(uint256 amount) external override onlyBentoBox returns (uint256 actualAmount) {
        token.safeTransfer(bentoBox, uint256(amount)); // Add as profit
        actualAmount = amount;
    }

    // Withdraw all assets in the safest way possible. This shouldn't fail.
    function exit(uint256 balance) external override onlyBentoBox returns (int256 amountAdded) {
        amountAdded = 0;
        token.safeTransfer(bentoBox, balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "../interfaces/IOracle.sol";

// WARNING: This oracle is only for testing, please use PeggedOracle for a fixed value oracle
contract OracleMock is IOracle {
    using BoringMath for uint256;

    uint256 public rate;
    bool public success;

    constructor() public {
        success = true;
    }

    function set(uint256 rate_) public {
        // The rate can be updated.
        rate = rate_;
    }

    function setSuccess(bool val) public {
        success = val;
    }

    function getDataParameter() public pure returns (bytes memory) {
        return abi.encode("0x0");
    }

    // Get the latest exchange rate
    function get(bytes calldata) public override returns (bool, uint256) {
        return (success, rate);
    }

    // Check the last exchange rate without any state changes
    function peek(bytes calldata) public view override returns (bool, uint256) {
        return (success, rate);
    }

    function peekSpot(bytes calldata) public view override returns (uint256) {
        return rate;
    }

    function name(bytes calldata) public view override returns (string memory) {
        return "Test";
    }

    function symbol(bytes calldata) public view override returns (string memory) {
        return "TEST";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";

contract ExternalFunctionMock {
    using BoringMath for uint256;

    event Result(uint256 output);

    function sum(uint256 a, uint256 b) external returns (uint256 c) {
        c = a.add(b);
        emit Result(c);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./libraries/BoringAddress.sol";
import "./libraries/BoringMath.sol";
import "./interfaces/IERC721TokenReceiver.sol";

// solhint-disable avoid-low-level-calls

abstract contract BoringMultipleNFT {
    /// This contract is an EIP-721 compliant contract with enumerable support
    /// To optimize for gas, tokenId is sequential and start at 0. Also, tokens can't be removed/burned.
    using BoringAddress for address;
    using BoringMath for uint256;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    uint256 public totalSupply = 0;

    struct TokenInfo {
        address owner;
        uint24 index; // index in the tokensOf array, one address can hold a maximum of 16,777,216 tokens
        uint72 data; // data field can be usse to store traits
    }

    // operator mappings as per usual
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    mapping(address => uint256[]) public tokensOf; // Array of tokens owned by
    mapping(uint256 => TokenInfo) internal _tokens; // The index in the tokensOf array for the token, needed to remove tokens from tokensOf
    mapping(uint256 => address) internal _approved; // keep track of approved nft

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return
            interfaceID == this.supportsInterface.selector || // EIP-165
            interfaceID == 0x80ac58cd; // EIP-721
    }

    function approve(address approved, uint256 tokenId) public payable {
        address owner = _tokens[tokenId].owner;
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "Not allowed");
        _approved[tokenId] = approved;
        emit Approval(owner, approved, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address approved) {
        require(tokenId < totalSupply, "Invalid tokenId");
        return _approved[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokens[tokenId].owner;
        require(owner != address(0), "No owner");
        return owner;
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "No 0 owner");
        return tokensOf[owner].length;
    }

    function _transferBase(
        uint256 tokenId,
        address from,
        address to,
        uint72 data
    ) internal {
        address owner = _tokens[tokenId].owner;
        require(from == owner, "From not owner");

        uint24 index;
        // Remove the token from the current owner's tokensOf array
        if (from != address(0)) {
            index = _tokens[tokenId].index; // The index of the item to remove in the array
            data = _tokens[tokenId].data;
            uint256 last = tokensOf[from].length - 1;
            uint256 lastTokenId = tokensOf[from][last];
            tokensOf[from][index] = lastTokenId; // Copy the last item into the slot of the one to be removed
            _tokens[lastTokenId].index = index; // Update the token index for the last item that was moved
            tokensOf[from].pop(); // Delete the last item
        }

        index = uint24(tokensOf[to].length);
        tokensOf[to].push(tokenId);
        _tokens[tokenId] = TokenInfo({owner: to, index: index, data: data});

        // EIP-721 seems to suggest not to emit the Approval event here as it is indicated by the Transfer event.
        _approved[tokenId] = address(0);
        emit Transfer(from, to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(msg.sender == from || msg.sender == _approved[tokenId] || isApprovedForAll[from][msg.sender], "Transfer not allowed");
        require(to != address(0), "No zero address");
        // check for owner == from is in base
        _transferBase(tokenId, from, to, 0);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable {
        _transfer(from, to, tokenId);
        if (to.isContract()) {
            require(
                IERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data) ==
                    bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")),
                "Wrong return value"
            );
        }
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(tokenId < totalSupply, "Not minted");
        return _tokenURI(tokenId);
    }

    function _tokenURI(uint256 tokenId) internal view virtual returns (string memory);

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply, "Out of bounds");
        return index; // This works due the optimization of sequential tokenIds and no burning
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
        return tokensOf[owner][index];
    }

    function _mint(address owner, uint72 data) internal {
        _transferBase(totalSupply, address(0), owner, data);
        totalSupply++;
    }
}

// SPDX-License-Identifier: MIT

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

// solhint-disable no-inline-assembly

library BoringAddress {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC721TokenReceiver {
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/BoringMultipleNFT.sol";

contract ERC721Mock is BoringMultipleNFT {
    function mint(address owner) public returns (uint256 id) {
        id = totalSupply;
        _mint(owner, 0);
    }

    function _tokenURI(uint256) internal view override returns (string memory) {
        return "";
    }
}

// SPDX-License-Identifier: UNLICENSED

// Cauldron

//    (                (   (
//    )\      )    (   )\  )\ )  (
//  (((_)  ( /(   ))\ ((_)(()/(  )(    (    (
//  )\___  )(_)) /((_) _   ((_))(()\   )\   )\ )
// ((/ __|((_)_ (_))( | |  _| |  ((_) ((_) _(_/(
//  | (__ / _` || || || |/ _` | | '_|/ _ \| ' \))
//   \___|\__,_| \_,_||_|\__,_| |_|  \___/|_||_|

// Copyright (c) 2021 BoringCrypto - All rights reserved
// Twitter: @Boring_Crypto

// Special thanks to:
// @0xKeno - for all his invaluable contributions
// @burger_crypto - for the idea of trying to let the LPs benefit from liquidations

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@boringcrypto/boring-solidity/contracts/ERC20.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IMasterContract.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "./MagicInternetMoney.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/ISwapper.sol";

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

/// @title Cauldron
/// @dev This contract allows contract calls to any contract (except BentoBox)
/// from arbitrary callers thus, don't trust calls from this contract in any circumstances.
contract CauldronV2MultiChain is BoringOwnable, IMasterContract {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;

    event LogExchangeRate(uint256 rate);
    event LogAccrue(uint128 accruedAmount);
    event LogAddCollateral(address indexed from, address indexed to, uint256 share);
    event LogRemoveCollateral(address indexed from, address indexed to, uint256 share);
    event LogBorrow(address indexed from, address indexed to, uint256 amount, uint256 part);
    event LogRepay(address indexed from, address indexed to, uint256 amount, uint256 part);
    event LogFeeTo(address indexed newFeeTo);
    event LogWithdrawFees(address indexed feeTo, uint256 feesEarnedFraction);

    // Immutables (for MasterContract and all clones)
    IBentoBoxV1 public immutable bentoBox;
    CauldronV2MultiChain public immutable masterContract;
    IERC20 public immutable magicInternetMoney;

    // MasterContract variables
    address public feeTo;

    // Per clone variables
    // Clone init settings
    IERC20 public collateral;
    IOracle public oracle;
    bytes public oracleData;

    // Total amounts
    uint256 public totalCollateralShare; // Total collateral supplied
    Rebase public totalBorrow; // elastic = Total token amount to be repayed by borrowers, base = Total parts of the debt held by borrowers

    // User balances
    mapping(address => uint256) public userCollateralShare;
    mapping(address => uint256) public userBorrowPart;

    /// @notice Exchange and interest rate tracking.
    /// This is 'cached' here because calls to Oracles can be very expensive.
    uint256 public exchangeRate;

    struct AccrueInfo {
        uint64 lastAccrued;
        uint128 feesEarned;
        uint64 INTEREST_PER_SECOND;
    }

    AccrueInfo public accrueInfo;

    // Settings
    uint256 public COLLATERIZATION_RATE;
    uint256 private constant COLLATERIZATION_RATE_PRECISION = 1e5; // Must be less than EXCHANGE_RATE_PRECISION (due to optimization in math)

    uint256 private constant EXCHANGE_RATE_PRECISION = 1e18;

    uint256 public LIQUIDATION_MULTIPLIER; 
    uint256 private constant LIQUIDATION_MULTIPLIER_PRECISION = 1e5;

    uint256 public BORROW_OPENING_FEE;
    uint256 private constant BORROW_OPENING_FEE_PRECISION = 1e5;

    uint256 private constant DISTRIBUTION_PART = 10;
    uint256 private constant DISTRIBUTION_PRECISION = 100;

    /// @notice The constructor is only used for the initial master contract. Subsequent clones are initialised via `init`.
    constructor(IBentoBoxV1 bentoBox_, IERC20 magicInternetMoney_) public {
        bentoBox = bentoBox_;
        magicInternetMoney = magicInternetMoney_;
        masterContract = this;
    }

    /// @notice Serves as the constructor for clones, as clones can't have a regular constructor
    /// @dev `data` is abi encoded in the format: (IERC20 collateral, IERC20 asset, IOracle oracle, bytes oracleData)
    function init(bytes calldata data) public payable override {
        require(address(collateral) == address(0), "Cauldron: already initialized");
        (collateral, oracle, oracleData, accrueInfo.INTEREST_PER_SECOND, LIQUIDATION_MULTIPLIER, COLLATERIZATION_RATE, BORROW_OPENING_FEE) = abi.decode(data, (IERC20, IOracle, bytes, uint64, uint256, uint256, uint256));
        require(address(collateral) != address(0), "Cauldron: bad pair");
    }

    /// @notice Accrues the interest on the borrowed tokens and handles the accumulation of fees.
    function accrue() public {
        AccrueInfo memory _accrueInfo = accrueInfo;
        // Number of seconds since accrue was called
        uint256 elapsedTime = block.timestamp - _accrueInfo.lastAccrued;
        if (elapsedTime == 0) {
            return;
        }
        _accrueInfo.lastAccrued = uint64(block.timestamp);

        Rebase memory _totalBorrow = totalBorrow;
        if (_totalBorrow.base == 0) {
            accrueInfo = _accrueInfo;
            return;
        }

        // Accrue interest
        uint128 extraAmount = (uint256(_totalBorrow.elastic).mul(_accrueInfo.INTEREST_PER_SECOND).mul(elapsedTime) / 1e18).to128();
        _totalBorrow.elastic = _totalBorrow.elastic.add(extraAmount);

        _accrueInfo.feesEarned = _accrueInfo.feesEarned.add(extraAmount);
        totalBorrow = _totalBorrow;
        accrueInfo = _accrueInfo;

        emit LogAccrue(extraAmount);
    }

    /// @notice Concrete implementation of `isSolvent`. Includes a third parameter to allow caching `exchangeRate`.
    /// @param _exchangeRate The exchange rate. Used to cache the `exchangeRate` between calls.
    function _isSolvent(address user, uint256 _exchangeRate) internal view returns (bool) {
        // accrue must have already been called!
        uint256 borrowPart = userBorrowPart[user];
        if (borrowPart == 0) return true;
        uint256 collateralShare = userCollateralShare[user];
        if (collateralShare == 0) return false;

        Rebase memory _totalBorrow = totalBorrow;

        return
            bentoBox.toAmount(
                collateral,
                collateralShare.mul(EXCHANGE_RATE_PRECISION / COLLATERIZATION_RATE_PRECISION).mul(COLLATERIZATION_RATE),
                false
            ) >=
            // Moved exchangeRate here instead of dividing the other side to preserve more precision
            borrowPart.mul(_totalBorrow.elastic).mul(_exchangeRate) / _totalBorrow.base;
    }

    /// @dev Checks if the user is solvent in the closed liquidation case at the end of the function body.
    modifier solvent() {
        _;
        require(_isSolvent(msg.sender, exchangeRate), "Cauldron: user insolvent");
    }

    /// @notice Gets the exchange rate. I.e how much collateral to buy 1e18 asset.
    /// This function is supposed to be invoked if needed because Oracle queries can be expensive.
    /// @return updated True if `exchangeRate` was updated.
    /// @return rate The new exchange rate.
    function updateExchangeRate() public returns (bool updated, uint256 rate) {
        (updated, rate) = oracle.get(oracleData);

        if (updated) {
            exchangeRate = rate;
            emit LogExchangeRate(rate);
        } else {
            // Return the old rate if fetching wasn't successful
            rate = exchangeRate;
        }
    }

    /// @dev Helper function to move tokens.
    /// @param token The ERC-20 token.
    /// @param share The amount in shares to add.
    /// @param total Grand total amount to deduct from this contract's balance. Only applicable if `skim` is True.
    /// Only used for accounting checks.
    /// @param skim If True, only does a balance check on this contract.
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    function _addTokens(
        IERC20 token,
        uint256 share,
        uint256 total,
        bool skim
    ) internal {
        if (skim) {
            require(share <= bentoBox.balanceOf(token, address(this)).sub(total), "Cauldron: Skim too much");
        } else {
            bentoBox.transfer(token, msg.sender, address(this), share);
        }
    }

    /// @notice Adds `collateral` from msg.sender to the account `to`.
    /// @param to The receiver of the tokens.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.x
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    /// @param share The amount of shares to add for `to`.
    function addCollateral(
        address to,
        bool skim,
        uint256 share
    ) public {
        userCollateralShare[to] = userCollateralShare[to].add(share);
        uint256 oldTotalCollateralShare = totalCollateralShare;
        totalCollateralShare = oldTotalCollateralShare.add(share);
        _addTokens(collateral, share, oldTotalCollateralShare, skim);
        emit LogAddCollateral(skim ? address(bentoBox) : msg.sender, to, share);
    }

    /// @dev Concrete implementation of `removeCollateral`.
    function _removeCollateral(address to, uint256 share) internal {
        userCollateralShare[msg.sender] = userCollateralShare[msg.sender].sub(share);
        totalCollateralShare = totalCollateralShare.sub(share);
        emit LogRemoveCollateral(msg.sender, to, share);
        bentoBox.transfer(collateral, address(this), to, share);
    }

    /// @notice Removes `share` amount of collateral and transfers it to `to`.
    /// @param to The receiver of the shares.
    /// @param share Amount of shares to remove.
    function removeCollateral(address to, uint256 share) public solvent {
        // accrue must be called because we check solvency
        accrue();
        _removeCollateral(to, share);
    }

    /// @dev Concrete implementation of `borrow`.
    function _borrow(address to, uint256 amount) internal returns (uint256 part, uint256 share) {
        uint256 feeAmount = amount.mul(BORROW_OPENING_FEE) / BORROW_OPENING_FEE_PRECISION; // A flat % fee is charged for any borrow
        (totalBorrow, part) = totalBorrow.add(amount.add(feeAmount), true);
        accrueInfo.feesEarned = accrueInfo.feesEarned.add(uint128(feeAmount));
        userBorrowPart[msg.sender] = userBorrowPart[msg.sender].add(part);

        // As long as there are tokens on this contract you can 'mint'... this enables limiting borrows
        share = bentoBox.toShare(magicInternetMoney, amount, false);
        bentoBox.transfer(magicInternetMoney, address(this), to, share);

        emit LogBorrow(msg.sender, to, amount.add(feeAmount), part);
    }

    /// @notice Sender borrows `amount` and transfers it to `to`.
    /// @return part Total part of the debt held by borrowers.
    /// @return share Total amount in shares borrowed.
    function borrow(address to, uint256 amount) public solvent returns (uint256 part, uint256 share) {
        accrue();
        (part, share) = _borrow(to, amount);
    }

    /// @dev Concrete implementation of `repay`.
    function _repay(
        address to,
        bool skim,
        uint256 part
    ) internal returns (uint256 amount) {
        (totalBorrow, amount) = totalBorrow.sub(part, true);
        userBorrowPart[to] = userBorrowPart[to].sub(part);

        uint256 share = bentoBox.toShare(magicInternetMoney, amount, true);
        bentoBox.transfer(magicInternetMoney, skim ? address(bentoBox) : msg.sender, address(this), share);
        emit LogRepay(skim ? address(bentoBox) : msg.sender, to, amount, part);
    }

    /// @notice Repays a loan.
    /// @param to Address of the user this payment should go.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    /// @param part The amount to repay. See `userBorrowPart`.
    /// @return amount The total amount repayed.
    function repay(
        address to,
        bool skim,
        uint256 part
    ) public returns (uint256 amount) {
        accrue();
        amount = _repay(to, skim, part);
    }

    // Functions that need accrue to be called
    uint8 internal constant ACTION_REPAY = 2;
    uint8 internal constant ACTION_REMOVE_COLLATERAL = 4;
    uint8 internal constant ACTION_BORROW = 5;
    uint8 internal constant ACTION_GET_REPAY_SHARE = 6;
    uint8 internal constant ACTION_GET_REPAY_PART = 7;
    uint8 internal constant ACTION_ACCRUE = 8;

    // Functions that don't need accrue to be called
    uint8 internal constant ACTION_ADD_COLLATERAL = 10;
    uint8 internal constant ACTION_UPDATE_EXCHANGE_RATE = 11;

    // Function on BentoBox
    uint8 internal constant ACTION_BENTO_DEPOSIT = 20;
    uint8 internal constant ACTION_BENTO_WITHDRAW = 21;
    uint8 internal constant ACTION_BENTO_TRANSFER = 22;
    uint8 internal constant ACTION_BENTO_TRANSFER_MULTIPLE = 23;
    uint8 internal constant ACTION_BENTO_SETAPPROVAL = 24;

    // Any external call (except to BentoBox)
    uint8 internal constant ACTION_CALL = 30;

    int256 internal constant USE_VALUE1 = -1;
    int256 internal constant USE_VALUE2 = -2;

    /// @dev Helper function for choosing the correct value (`value1` or `value2`) depending on `inNum`.
    function _num(
        int256 inNum,
        uint256 value1,
        uint256 value2
    ) internal pure returns (uint256 outNum) {
        outNum = inNum >= 0 ? uint256(inNum) : (inNum == USE_VALUE1 ? value1 : value2);
    }

    /// @dev Helper function for depositing into `bentoBox`.
    function _bentoDeposit(
        bytes memory data,
        uint256 value,
        uint256 value1,
        uint256 value2
    ) internal returns (uint256, uint256) {
        (IERC20 token, address to, int256 amount, int256 share) = abi.decode(data, (IERC20, address, int256, int256));
        amount = int256(_num(amount, value1, value2)); // Done this way to avoid stack too deep errors
        share = int256(_num(share, value1, value2));
        return bentoBox.deposit{value: value}(token, msg.sender, to, uint256(amount), uint256(share));
    }

    /// @dev Helper function to withdraw from the `bentoBox`.
    function _bentoWithdraw(
        bytes memory data,
        uint256 value1,
        uint256 value2
    ) internal returns (uint256, uint256) {
        (IERC20 token, address to, int256 amount, int256 share) = abi.decode(data, (IERC20, address, int256, int256));
        return bentoBox.withdraw(token, msg.sender, to, _num(amount, value1, value2), _num(share, value1, value2));
    }

    /// @dev Helper function to perform a contract call and eventually extracting revert messages on failure.
    /// Calls to `bentoBox` are not allowed for obvious security reasons.
    /// This also means that calls made from this contract shall *not* be trusted.
    function _call(
        uint256 value,
        bytes memory data,
        uint256 value1,
        uint256 value2
    ) internal returns (bytes memory, uint8) {
        (address callee, bytes memory callData, bool useValue1, bool useValue2, uint8 returnValues) =
            abi.decode(data, (address, bytes, bool, bool, uint8));

        if (useValue1 && !useValue2) {
            callData = abi.encodePacked(callData, value1);
        } else if (!useValue1 && useValue2) {
            callData = abi.encodePacked(callData, value2);
        } else if (useValue1 && useValue2) {
            callData = abi.encodePacked(callData, value1, value2);
        }

        require(callee != address(bentoBox) && callee != address(this), "Cauldron: can't call");

        (bool success, bytes memory returnData) = callee.call{value: value}(callData);
        require(success, "Cauldron: call failed");
        return (returnData, returnValues);
    }

    struct CookStatus {
        bool needsSolvencyCheck;
        bool hasAccrued;
    }

    /// @notice Executes a set of actions and allows composability (contract calls) to other contracts.
    /// @param actions An array with a sequence of actions to execute (see ACTION_ declarations).
    /// @param values A one-to-one mapped array to `actions`. ETH amounts to send along with the actions.
    /// Only applicable to `ACTION_CALL`, `ACTION_BENTO_DEPOSIT`.
    /// @param datas A one-to-one mapped array to `actions`. Contains abi encoded data of function arguments.
    /// @return value1 May contain the first positioned return value of the last executed action (if applicable).
    /// @return value2 May contain the second positioned return value of the last executed action which returns 2 values (if applicable).
    function cook(
        uint8[] calldata actions,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external payable returns (uint256 value1, uint256 value2) {
        CookStatus memory status;
        for (uint256 i = 0; i < actions.length; i++) {
            uint8 action = actions[i];
            if (!status.hasAccrued && action < 10) {
                accrue();
                status.hasAccrued = true;
            }
            if (action == ACTION_ADD_COLLATERAL) {
                (int256 share, address to, bool skim) = abi.decode(datas[i], (int256, address, bool));
                addCollateral(to, skim, _num(share, value1, value2));
            } else if (action == ACTION_REPAY) {
                (int256 part, address to, bool skim) = abi.decode(datas[i], (int256, address, bool));
                _repay(to, skim, _num(part, value1, value2));
            } else if (action == ACTION_REMOVE_COLLATERAL) {
                (int256 share, address to) = abi.decode(datas[i], (int256, address));
                _removeCollateral(to, _num(share, value1, value2));
                status.needsSolvencyCheck = true;
            } else if (action == ACTION_BORROW) {
                (int256 amount, address to) = abi.decode(datas[i], (int256, address));
                (value1, value2) = _borrow(to, _num(amount, value1, value2));
                status.needsSolvencyCheck = true;
            } else if (action == ACTION_UPDATE_EXCHANGE_RATE) {
                (bool must_update, uint256 minRate, uint256 maxRate) = abi.decode(datas[i], (bool, uint256, uint256));
                (bool updated, uint256 rate) = updateExchangeRate();
                require((!must_update || updated) && rate > minRate && (maxRate == 0 || rate > maxRate), "Cauldron: rate not ok");
            } else if (action == ACTION_BENTO_SETAPPROVAL) {
                (address user, address _masterContract, bool approved, uint8 v, bytes32 r, bytes32 s) =
                    abi.decode(datas[i], (address, address, bool, uint8, bytes32, bytes32));
                bentoBox.setMasterContractApproval(user, _masterContract, approved, v, r, s);
            } else if (action == ACTION_BENTO_DEPOSIT) {
                (value1, value2) = _bentoDeposit(datas[i], values[i], value1, value2);
            } else if (action == ACTION_BENTO_WITHDRAW) {
                (value1, value2) = _bentoWithdraw(datas[i], value1, value2);
            } else if (action == ACTION_BENTO_TRANSFER) {
                (IERC20 token, address to, int256 share) = abi.decode(datas[i], (IERC20, address, int256));
                bentoBox.transfer(token, msg.sender, to, _num(share, value1, value2));
            } else if (action == ACTION_BENTO_TRANSFER_MULTIPLE) {
                (IERC20 token, address[] memory tos, uint256[] memory shares) = abi.decode(datas[i], (IERC20, address[], uint256[]));
                bentoBox.transferMultiple(token, msg.sender, tos, shares);
            } else if (action == ACTION_CALL) {
                (bytes memory returnData, uint8 returnValues) = _call(values[i], datas[i], value1, value2);

                if (returnValues == 1) {
                    (value1) = abi.decode(returnData, (uint256));
                } else if (returnValues == 2) {
                    (value1, value2) = abi.decode(returnData, (uint256, uint256));
                }
            } else if (action == ACTION_GET_REPAY_SHARE) {
                int256 part = abi.decode(datas[i], (int256));
                value1 = bentoBox.toShare(magicInternetMoney, totalBorrow.toElastic(_num(part, value1, value2), true), true);
            } else if (action == ACTION_GET_REPAY_PART) {
                int256 amount = abi.decode(datas[i], (int256));
                value1 = totalBorrow.toBase(_num(amount, value1, value2), false);
            }
        }

        if (status.needsSolvencyCheck) {
            require(_isSolvent(msg.sender, exchangeRate), "Cauldron: user insolvent");
        }
    }

    /// @notice Handles the liquidation of users' balances, once the users' amount of collateral is too low.
    /// @param users An array of user addresses.
    /// @param maxBorrowParts A one-to-one mapping to `users`, contains maximum (partial) borrow amounts (to liquidate) of the respective user.
    /// @param to Address of the receiver in open liquidations if `swapper` is zero.
    function liquidate(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        address to,
        ISwapper swapper
    ) public {
        // Oracle can fail but we still need to allow liquidations
        (, uint256 _exchangeRate) = updateExchangeRate();
        accrue();

        uint256 allCollateralShare;
        uint256 allBorrowAmount;
        uint256 allBorrowPart;
        Rebase memory _totalBorrow = totalBorrow;
        Rebase memory bentoBoxTotals = bentoBox.totals(collateral);
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (!_isSolvent(user, _exchangeRate)) {
                uint256 borrowPart;
                {
                    uint256 availableBorrowPart = userBorrowPart[user];
                    borrowPart = maxBorrowParts[i] > availableBorrowPart ? availableBorrowPart : maxBorrowParts[i];
                    userBorrowPart[user] = availableBorrowPart.sub(borrowPart);
                }
                uint256 borrowAmount = _totalBorrow.toElastic(borrowPart, false);
                uint256 collateralShare =
                    bentoBoxTotals.toBase(
                        borrowAmount.mul(LIQUIDATION_MULTIPLIER).mul(_exchangeRate) /
                            (LIQUIDATION_MULTIPLIER_PRECISION * EXCHANGE_RATE_PRECISION),
                        false
                    );

                userCollateralShare[user] = userCollateralShare[user].sub(collateralShare);
                emit LogRemoveCollateral(user, to, collateralShare);
                emit LogRepay(msg.sender, user, borrowAmount, borrowPart);

                // Keep totals
                allCollateralShare = allCollateralShare.add(collateralShare);
                allBorrowAmount = allBorrowAmount.add(borrowAmount);
                allBorrowPart = allBorrowPart.add(borrowPart);
            }
        }
        require(allBorrowAmount != 0, "Cauldron: all are solvent");
        _totalBorrow.elastic = _totalBorrow.elastic.sub(allBorrowAmount.to128());
        _totalBorrow.base = _totalBorrow.base.sub(allBorrowPart.to128());
        totalBorrow = _totalBorrow;
        totalCollateralShare = totalCollateralShare.sub(allCollateralShare);

        // Apply a percentual fee share to sSpell holders
        
        {
            uint256 distributionAmount = (allBorrowAmount.mul(LIQUIDATION_MULTIPLIER) / LIQUIDATION_MULTIPLIER_PRECISION).sub(allBorrowAmount).mul(DISTRIBUTION_PART) / DISTRIBUTION_PRECISION; // Distribution Amount
            allBorrowAmount = allBorrowAmount.add(distributionAmount);
            accrueInfo.feesEarned = accrueInfo.feesEarned.add(distributionAmount.to128());
        }

        uint256 allBorrowShare = bentoBox.toShare(magicInternetMoney, allBorrowAmount, true);

        // Swap using a swapper freely chosen by the caller
        // Open (flash) liquidation: get proceeds first and provide the borrow after
        bentoBox.transfer(collateral, address(this), to, allCollateralShare);
        if (swapper != ISwapper(0)) {
            swapper.swap(collateral, magicInternetMoney, msg.sender, allBorrowShare, allCollateralShare);
        }

        bentoBox.transfer(magicInternetMoney, msg.sender, address(this), allBorrowShare);
    }

    /// @notice Withdraws the fees accumulated.
    function withdrawFees() public {
        accrue();
        address _feeTo = masterContract.feeTo();
        uint256 _feesEarned = accrueInfo.feesEarned;
        uint256 share = bentoBox.toShare(magicInternetMoney, _feesEarned, false);
        bentoBox.transfer(magicInternetMoney, address(this), _feeTo, share);
        accrueInfo.feesEarned = 0;

        emit LogWithdrawFees(_feeTo, _feesEarned);
    }

    /// @notice Sets the beneficiary of interest accrued.
    /// MasterContract Only Admin function.
    /// @param newFeeTo The address of the receiver.
    function setFeeTo(address newFeeTo) public onlyOwner {
        feeTo = newFeeTo;
        emit LogFeeTo(newFeeTo);
    }

    /// @notice reduces the supply of MIM
    /// @param amount amount to reduce supply by
    function reduceSupply(uint256 amount) public {
        require(msg.sender == masterContract.owner(), "Caller is not the owner");
        bentoBox.withdraw(magicInternetMoney, address(this), masterContract.owner(), amount, 0);
    }
}

// SPDX-License-Identifier: UNLICENSED

// Cauldron

//    (                (   (
//    )\      )    (   )\  )\ )  (
//  (((_)  ( /(   ))\ ((_)(()/(  )(    (    (
//  )\___  )(_)) /((_) _   ((_))(()\   )\   )\ )
// ((/ __|((_)_ (_))( | |  _| |  ((_) ((_) _(_/(
//  | (__ / _` || || || |/ _` | | '_|/ _ \| ' \))
//   \___|\__,_| \_,_||_|\__,_| |_|  \___/|_||_|

// Copyright (c) 2021 BoringCrypto - All rights reserved
// Twitter: @Boring_Crypto

// Special thanks to:
// @0xKeno - for all his invaluable contributions
// @burger_crypto - for the idea of trying to let the LPs benefit from liquidations

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@boringcrypto/boring-solidity/contracts/ERC20.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IMasterContract.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "./MagicInternetMoney.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/ISwapper.sol";
import "./interfaces/ICheckpointToken.sol";

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

/// @title Cauldron
/// @dev This contract allows contract calls to any contract (except BentoBox)
/// from arbitrary callers thus, don't trust calls from this contract in any circumstances.
contract CauldronV2Checkpoint is BoringOwnable, IMasterContract {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;

    event LogExchangeRate(uint256 rate);
    event LogAccrue(uint128 accruedAmount);
    event LogAddCollateral(address indexed from, address indexed to, uint256 share);
    event LogRemoveCollateral(address indexed from, address indexed to, uint256 share);
    event LogBorrow(address indexed from, address indexed to, uint256 amount, uint256 part);
    event LogRepay(address indexed from, address indexed to, uint256 amount, uint256 part);
    event LogFeeTo(address indexed newFeeTo);
    event LogWithdrawFees(address indexed feeTo, uint256 feesEarnedFraction);

    // Immutables (for MasterContract and all clones)
    IBentoBoxV1 public immutable bentoBox;
    CauldronV2Checkpoint public immutable masterContract;
    IERC20 public immutable magicInternetMoney;

    // MasterContract variables
    address public feeTo;

    // Per clone variables
    // Clone init settings
    IERC20 public collateral;
    IOracle public oracle;
    bytes public oracleData;

    // Total amounts
    uint256 public totalCollateralShare; // Total collateral supplied
    Rebase public totalBorrow; // elastic = Total token amount to be repayed by borrowers, base = Total parts of the debt held by borrowers

    // User balances
    mapping(address => uint256) public userCollateralShare;
    mapping(address => uint256) public userBorrowPart;

    /// @notice Exchange and interest rate tracking.
    /// This is 'cached' here because calls to Oracles can be very expensive.
    uint256 public exchangeRate;

    struct AccrueInfo {
        uint64 lastAccrued;
        uint128 feesEarned;
        uint64 INTEREST_PER_SECOND;
    }

    AccrueInfo public accrueInfo;

    // Settings
    uint256 public COLLATERIZATION_RATE;
    uint256 private constant COLLATERIZATION_RATE_PRECISION = 1e5; // Must be less than EXCHANGE_RATE_PRECISION (due to optimization in math)

    uint256 private constant EXCHANGE_RATE_PRECISION = 1e18;

    uint256 public LIQUIDATION_MULTIPLIER; 
    uint256 private constant LIQUIDATION_MULTIPLIER_PRECISION = 1e5;

    uint256 public BORROW_OPENING_FEE;
    uint256 private constant BORROW_OPENING_FEE_PRECISION = 1e5;

    uint256 private constant DISTRIBUTION_PART = 10;
    uint256 private constant DISTRIBUTION_PRECISION = 100;

    /// @notice The constructor is only used for the initial master contract. Subsequent clones are initialised via `init`.
    constructor(IBentoBoxV1 bentoBox_, IERC20 magicInternetMoney_) public {
        bentoBox = bentoBox_;
        magicInternetMoney = magicInternetMoney_;
        masterContract = this;
    }

    /// @notice Serves as the constructor for clones, as clones can't have a regular constructor
    /// @dev `data` is abi encoded in the format: (IERC20 collateral, IERC20 asset, IOracle oracle, bytes oracleData)
    function init(bytes calldata data) public payable override {
        require(address(collateral) == address(0), "Cauldron: already initialized");
        (collateral, oracle, oracleData, accrueInfo.INTEREST_PER_SECOND, LIQUIDATION_MULTIPLIER, COLLATERIZATION_RATE, BORROW_OPENING_FEE) = abi.decode(data, (IERC20, IOracle, bytes, uint64, uint256, uint256, uint256));
        require(address(collateral) != address(0), "Cauldron: bad pair");
    }

    /// @notice Accrues the interest on the borrowed tokens and handles the accumulation of fees.
    function accrue() public {
        AccrueInfo memory _accrueInfo = accrueInfo;
        // Number of seconds since accrue was called
        uint256 elapsedTime = block.timestamp - _accrueInfo.lastAccrued;
        if (elapsedTime == 0) {
            return;
        }
        _accrueInfo.lastAccrued = uint64(block.timestamp);

        Rebase memory _totalBorrow = totalBorrow;
        if (_totalBorrow.base == 0) {
            accrueInfo = _accrueInfo;
            return;
        }

        // Accrue interest
        uint128 extraAmount = (uint256(_totalBorrow.elastic).mul(_accrueInfo.INTEREST_PER_SECOND).mul(elapsedTime) / 1e18).to128();
        _totalBorrow.elastic = _totalBorrow.elastic.add(extraAmount);

        _accrueInfo.feesEarned = _accrueInfo.feesEarned.add(extraAmount);
        totalBorrow = _totalBorrow;
        accrueInfo = _accrueInfo;

        emit LogAccrue(extraAmount);
    }

    /// @notice Concrete implementation of `isSolvent`. Includes a third parameter to allow caching `exchangeRate`.
    /// @param _exchangeRate The exchange rate. Used to cache the `exchangeRate` between calls.
    function _isSolvent(address user, uint256 _exchangeRate) internal view returns (bool) {
        // accrue must have already been called!
        uint256 borrowPart = userBorrowPart[user];
        if (borrowPart == 0) return true;
        uint256 collateralShare = userCollateralShare[user];
        if (collateralShare == 0) return false;

        Rebase memory _totalBorrow = totalBorrow;

        return
            bentoBox.toAmount(
                collateral,
                collateralShare.mul(EXCHANGE_RATE_PRECISION / COLLATERIZATION_RATE_PRECISION).mul(COLLATERIZATION_RATE),
                false
            ) >=
            // Moved exchangeRate here instead of dividing the other side to preserve more precision
            borrowPart.mul(_totalBorrow.elastic).mul(_exchangeRate) / _totalBorrow.base;
    }

    /// @dev Checks if the user is solvent in the closed liquidation case at the end of the function body.
    modifier solvent() {
        _;
        require(_isSolvent(msg.sender, exchangeRate), "Cauldron: user insolvent");
    }

    /// @notice Gets the exchange rate. I.e how much collateral to buy 1e18 asset.
    /// This function is supposed to be invoked if needed because Oracle queries can be expensive.
    /// @return updated True if `exchangeRate` was updated.
    /// @return rate The new exchange rate.
    function updateExchangeRate() public returns (bool updated, uint256 rate) {
        (updated, rate) = oracle.get(oracleData);

        if (updated) {
            exchangeRate = rate;
            emit LogExchangeRate(rate);
        } else {
            // Return the old rate if fetching wasn't successful
            rate = exchangeRate;
        }
    }

    /// @dev Helper function to move tokens.
    /// @param token The ERC-20 token.
    /// @param share The amount in shares to add.
    /// @param total Grand total amount to deduct from this contract's balance. Only applicable if `skim` is True.
    /// Only used for accounting checks.
    /// @param skim If True, only does a balance check on this contract.
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    function _addTokens(
        IERC20 token,
        uint256 share,
        uint256 total,
        bool skim
    ) internal {
        if (skim) {
            require(share <= bentoBox.balanceOf(token, address(this)).sub(total), "Cauldron: Skim too much");
        } else {
            bentoBox.transfer(token, msg.sender, address(this), share);
        }
    }

    /// @notice Adds `collateral` from msg.sender to the account `to`.
    /// @param to The receiver of the tokens.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.x
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    /// @param share The amount of shares to add for `to`.
    function addCollateral(
        address to,
        bool skim,
        uint256 share
    ) public {
        //checkpoint before userCollateralShare is changed
        ICheckpointToken(address(collateral)).user_checkpoint([to,address(0)]);

        userCollateralShare[to] = userCollateralShare[to].add(share);
        uint256 oldTotalCollateralShare = totalCollateralShare;
        totalCollateralShare = oldTotalCollateralShare.add(share);
        _addTokens(collateral, share, oldTotalCollateralShare, skim);
        emit LogAddCollateral(skim ? address(bentoBox) : msg.sender, to, share);
    }

    /// @dev Concrete implementation of `removeCollateral`.
    function _removeCollateral(address to, uint256 share) internal {
        //checkpoint before userCollateralShare is changed
        ICheckpointToken(address(collateral)).user_checkpoint([address(msg.sender),address(0)]);

        userCollateralShare[msg.sender] = userCollateralShare[msg.sender].sub(share);
        totalCollateralShare = totalCollateralShare.sub(share);
        emit LogRemoveCollateral(msg.sender, to, share);
        bentoBox.transfer(collateral, address(this), to, share);
    }

    /// @notice Removes `share` amount of collateral and transfers it to `to`.
    /// @param to The receiver of the shares.
    /// @param share Amount of shares to remove.
    function removeCollateral(address to, uint256 share) public solvent {
        // accrue must be called because we check solvency
        accrue();
        _removeCollateral(to, share);
    }

    /// @dev Concrete implementation of `borrow`.
    function _borrow(address to, uint256 amount) internal returns (uint256 part, uint256 share) {
        uint256 feeAmount = amount.mul(BORROW_OPENING_FEE) / BORROW_OPENING_FEE_PRECISION; // A flat % fee is charged for any borrow
        (totalBorrow, part) = totalBorrow.add(amount.add(feeAmount), true);
        accrueInfo.feesEarned = accrueInfo.feesEarned.add(uint128(feeAmount));
        userBorrowPart[msg.sender] = userBorrowPart[msg.sender].add(part);

        // As long as there are tokens on this contract you can 'mint'... this enables limiting borrows
        share = bentoBox.toShare(magicInternetMoney, amount, false);
        bentoBox.transfer(magicInternetMoney, address(this), to, share);

        emit LogBorrow(msg.sender, to, amount.add(feeAmount), part);
    }

    /// @notice Sender borrows `amount` and transfers it to `to`.
    /// @return part Total part of the debt held by borrowers.
    /// @return share Total amount in shares borrowed.
    function borrow(address to, uint256 amount) public solvent returns (uint256 part, uint256 share) {
        accrue();
        (part, share) = _borrow(to, amount);
    }

    /// @dev Concrete implementation of `repay`.
    function _repay(
        address to,
        bool skim,
        uint256 part
    ) internal returns (uint256 amount) {
        (totalBorrow, amount) = totalBorrow.sub(part, true);
        userBorrowPart[to] = userBorrowPart[to].sub(part);

        uint256 share = bentoBox.toShare(magicInternetMoney, amount, true);
        bentoBox.transfer(magicInternetMoney, skim ? address(bentoBox) : msg.sender, address(this), share);
        emit LogRepay(skim ? address(bentoBox) : msg.sender, to, amount, part);
    }

    /// @notice Repays a loan.
    /// @param to Address of the user this payment should go.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    /// @param part The amount to repay. See `userBorrowPart`.
    /// @return amount The total amount repayed.
    function repay(
        address to,
        bool skim,
        uint256 part
    ) public returns (uint256 amount) {
        accrue();
        amount = _repay(to, skim, part);
    }

    // Functions that need accrue to be called
    uint8 internal constant ACTION_REPAY = 2;
    uint8 internal constant ACTION_REMOVE_COLLATERAL = 4;
    uint8 internal constant ACTION_BORROW = 5;
    uint8 internal constant ACTION_GET_REPAY_SHARE = 6;
    uint8 internal constant ACTION_GET_REPAY_PART = 7;
    uint8 internal constant ACTION_ACCRUE = 8;

    // Functions that don't need accrue to be called
    uint8 internal constant ACTION_ADD_COLLATERAL = 10;
    uint8 internal constant ACTION_UPDATE_EXCHANGE_RATE = 11;

    // Function on BentoBox
    uint8 internal constant ACTION_BENTO_DEPOSIT = 20;
    uint8 internal constant ACTION_BENTO_WITHDRAW = 21;
    uint8 internal constant ACTION_BENTO_TRANSFER = 22;
    uint8 internal constant ACTION_BENTO_TRANSFER_MULTIPLE = 23;
    uint8 internal constant ACTION_BENTO_SETAPPROVAL = 24;

    // Any external call (except to BentoBox)
    uint8 internal constant ACTION_CALL = 30;

    int256 internal constant USE_VALUE1 = -1;
    int256 internal constant USE_VALUE2 = -2;

    /// @dev Helper function for choosing the correct value (`value1` or `value2`) depending on `inNum`.
    function _num(
        int256 inNum,
        uint256 value1,
        uint256 value2
    ) internal pure returns (uint256 outNum) {
        outNum = inNum >= 0 ? uint256(inNum) : (inNum == USE_VALUE1 ? value1 : value2);
    }

    /// @dev Helper function for depositing into `bentoBox`.
    function _bentoDeposit(
        bytes memory data,
        uint256 value,
        uint256 value1,
        uint256 value2
    ) internal returns (uint256, uint256) {
        (IERC20 token, address to, int256 amount, int256 share) = abi.decode(data, (IERC20, address, int256, int256));
        amount = int256(_num(amount, value1, value2)); // Done this way to avoid stack too deep errors
        share = int256(_num(share, value1, value2));
        return bentoBox.deposit{value: value}(token, msg.sender, to, uint256(amount), uint256(share));
    }

    /// @dev Helper function to withdraw from the `bentoBox`.
    function _bentoWithdraw(
        bytes memory data,
        uint256 value1,
        uint256 value2
    ) internal returns (uint256, uint256) {
        (IERC20 token, address to, int256 amount, int256 share) = abi.decode(data, (IERC20, address, int256, int256));
        return bentoBox.withdraw(token, msg.sender, to, _num(amount, value1, value2), _num(share, value1, value2));
    }

    /// @dev Helper function to perform a contract call and eventually extracting revert messages on failure.
    /// Calls to `bentoBox` are not allowed for obvious security reasons.
    /// This also means that calls made from this contract shall *not* be trusted.
    function _call(
        uint256 value,
        bytes memory data,
        uint256 value1,
        uint256 value2
    ) internal returns (bytes memory, uint8) {
        (address callee, bytes memory callData, bool useValue1, bool useValue2, uint8 returnValues) =
            abi.decode(data, (address, bytes, bool, bool, uint8));

        if (useValue1 && !useValue2) {
            callData = abi.encodePacked(callData, value1);
        } else if (!useValue1 && useValue2) {
            callData = abi.encodePacked(callData, value2);
        } else if (useValue1 && useValue2) {
            callData = abi.encodePacked(callData, value1, value2);
        }

        require(callee != address(bentoBox) && callee != address(this), "Cauldron: can't call");

        (bool success, bytes memory returnData) = callee.call{value: value}(callData);
        require(success, "Cauldron: call failed");
        return (returnData, returnValues);
    }

    struct CookStatus {
        bool needsSolvencyCheck;
        bool hasAccrued;
    }

    /// @notice Executes a set of actions and allows composability (contract calls) to other contracts.
    /// @param actions An array with a sequence of actions to execute (see ACTION_ declarations).
    /// @param values A one-to-one mapped array to `actions`. ETH amounts to send along with the actions.
    /// Only applicable to `ACTION_CALL`, `ACTION_BENTO_DEPOSIT`.
    /// @param datas A one-to-one mapped array to `actions`. Contains abi encoded data of function arguments.
    /// @return value1 May contain the first positioned return value of the last executed action (if applicable).
    /// @return value2 May contain the second positioned return value of the last executed action which returns 2 values (if applicable).
    function cook(
        uint8[] calldata actions,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external payable returns (uint256 value1, uint256 value2) {
        CookStatus memory status;
        for (uint256 i = 0; i < actions.length; i++) {
            uint8 action = actions[i];
            if (!status.hasAccrued && action < 10) {
                accrue();
                status.hasAccrued = true;
            }
            if (action == ACTION_ADD_COLLATERAL) {
                (int256 share, address to, bool skim) = abi.decode(datas[i], (int256, address, bool));
                addCollateral(to, skim, _num(share, value1, value2));
            } else if (action == ACTION_REPAY) {
                (int256 part, address to, bool skim) = abi.decode(datas[i], (int256, address, bool));
                _repay(to, skim, _num(part, value1, value2));
            } else if (action == ACTION_REMOVE_COLLATERAL) {
                (int256 share, address to) = abi.decode(datas[i], (int256, address));
                _removeCollateral(to, _num(share, value1, value2));
                status.needsSolvencyCheck = true;
            } else if (action == ACTION_BORROW) {
                (int256 amount, address to) = abi.decode(datas[i], (int256, address));
                (value1, value2) = _borrow(to, _num(amount, value1, value2));
                status.needsSolvencyCheck = true;
            } else if (action == ACTION_UPDATE_EXCHANGE_RATE) {
                (bool must_update, uint256 minRate, uint256 maxRate) = abi.decode(datas[i], (bool, uint256, uint256));
                (bool updated, uint256 rate) = updateExchangeRate();
                require((!must_update || updated) && rate > minRate && (maxRate == 0 || rate > maxRate), "Cauldron: rate not ok");
            } else if (action == ACTION_BENTO_SETAPPROVAL) {
                (address user, address _masterContract, bool approved, uint8 v, bytes32 r, bytes32 s) =
                    abi.decode(datas[i], (address, address, bool, uint8, bytes32, bytes32));
                bentoBox.setMasterContractApproval(user, _masterContract, approved, v, r, s);
            } else if (action == ACTION_BENTO_DEPOSIT) {
                (value1, value2) = _bentoDeposit(datas[i], values[i], value1, value2);
            } else if (action == ACTION_BENTO_WITHDRAW) {
                (value1, value2) = _bentoWithdraw(datas[i], value1, value2);
            } else if (action == ACTION_BENTO_TRANSFER) {
                (IERC20 token, address to, int256 share) = abi.decode(datas[i], (IERC20, address, int256));
                bentoBox.transfer(token, msg.sender, to, _num(share, value1, value2));
            } else if (action == ACTION_BENTO_TRANSFER_MULTIPLE) {
                (IERC20 token, address[] memory tos, uint256[] memory shares) = abi.decode(datas[i], (IERC20, address[], uint256[]));
                bentoBox.transferMultiple(token, msg.sender, tos, shares);
            } else if (action == ACTION_CALL) {
                (bytes memory returnData, uint8 returnValues) = _call(values[i], datas[i], value1, value2);

                if (returnValues == 1) {
                    (value1) = abi.decode(returnData, (uint256));
                } else if (returnValues == 2) {
                    (value1, value2) = abi.decode(returnData, (uint256, uint256));
                }
            } else if (action == ACTION_GET_REPAY_SHARE) {
                int256 part = abi.decode(datas[i], (int256));
                value1 = bentoBox.toShare(magicInternetMoney, totalBorrow.toElastic(_num(part, value1, value2), true), true);
            } else if (action == ACTION_GET_REPAY_PART) {
                int256 amount = abi.decode(datas[i], (int256));
                value1 = totalBorrow.toBase(_num(amount, value1, value2), false);
            }
        }

        if (status.needsSolvencyCheck) {
            require(_isSolvent(msg.sender, exchangeRate), "Cauldron: user insolvent");
        }
    }

    /// @notice Handles the liquidation of users' balances, once the users' amount of collateral is too low.
    /// @param users An array of user addresses.
    /// @param maxBorrowParts A one-to-one mapping to `users`, contains maximum (partial) borrow amounts (to liquidate) of the respective user.
    /// @param to Address of the receiver in open liquidations if `swapper` is zero.
    function liquidate(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        address to,
        ISwapper swapper
    ) public {
        // Oracle can fail but we still need to allow liquidations
        (, uint256 _exchangeRate) = updateExchangeRate();
        accrue();

        uint256 allCollateralShare;
        uint256 allBorrowAmount;
        uint256 allBorrowPart;
        Rebase memory _totalBorrow = totalBorrow;
        Rebase memory bentoBoxTotals = bentoBox.totals(collateral);
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (!_isSolvent(user, _exchangeRate)) {
                uint256 borrowPart;
                {
                    uint256 availableBorrowPart = userBorrowPart[user];
                    borrowPart = maxBorrowParts[i] > availableBorrowPart ? availableBorrowPart : maxBorrowParts[i];
                    userBorrowPart[user] = availableBorrowPart.sub(borrowPart);
                }
                uint256 borrowAmount = _totalBorrow.toElastic(borrowPart, false);
                uint256 collateralShare =
                    bentoBoxTotals.toBase(
                        borrowAmount.mul(LIQUIDATION_MULTIPLIER).mul(_exchangeRate) /
                            (LIQUIDATION_MULTIPLIER_PRECISION * EXCHANGE_RATE_PRECISION),
                        false
                    );

                //checkpoint before userCollateralShare is changed
                ICheckpointToken(address(collateral)).user_checkpoint([user,address(0)]);
                userCollateralShare[user] = userCollateralShare[user].sub(collateralShare);
                emit LogRemoveCollateral(user, to, collateralShare);
                emit LogRepay(msg.sender, user, borrowAmount, borrowPart);

                // Keep totals
                allCollateralShare = allCollateralShare.add(collateralShare);
                allBorrowAmount = allBorrowAmount.add(borrowAmount);
                allBorrowPart = allBorrowPart.add(borrowPart);
            }
        }
        require(allBorrowAmount != 0, "Cauldron: all are solvent");
        _totalBorrow.elastic = _totalBorrow.elastic.sub(allBorrowAmount.to128());
        _totalBorrow.base = _totalBorrow.base.sub(allBorrowPart.to128());
        totalBorrow = _totalBorrow;
        totalCollateralShare = totalCollateralShare.sub(allCollateralShare);

        // Apply a percentual fee share to sSpell holders
        
        {
            uint256 distributionAmount = (allBorrowAmount.mul(LIQUIDATION_MULTIPLIER) / LIQUIDATION_MULTIPLIER_PRECISION).sub(allBorrowAmount).mul(DISTRIBUTION_PART) / DISTRIBUTION_PRECISION; // Distribution Amount
            allBorrowAmount = allBorrowAmount.add(distributionAmount);
            accrueInfo.feesEarned = accrueInfo.feesEarned.add(distributionAmount.to128());
        }

        uint256 allBorrowShare = bentoBox.toShare(magicInternetMoney, allBorrowAmount, true);

        // Swap using a swapper freely chosen by the caller
        // Open (flash) liquidation: get proceeds first and provide the borrow after
        bentoBox.transfer(collateral, address(this), to, allCollateralShare);
        if (swapper != ISwapper(0)) {
            swapper.swap(collateral, magicInternetMoney, msg.sender, allBorrowShare, allCollateralShare);
        }

        bentoBox.transfer(magicInternetMoney, msg.sender, address(this), allBorrowShare);
    }

    /// @notice Withdraws the fees accumulated.
    function withdrawFees() public {
        accrue();
        address _feeTo = masterContract.feeTo();
        uint256 _feesEarned = accrueInfo.feesEarned;
        uint256 share = bentoBox.toShare(magicInternetMoney, _feesEarned, false);
        bentoBox.transfer(magicInternetMoney, address(this), _feeTo, share);
        accrueInfo.feesEarned = 0;

        emit LogWithdrawFees(_feeTo, _feesEarned);
    }

    /// @notice Sets the beneficiary of interest accrued.
    /// MasterContract Only Admin function.
    /// @param newFeeTo The address of the receiver.
    function setFeeTo(address newFeeTo) public onlyOwner {
        feeTo = newFeeTo;
        emit LogFeeTo(newFeeTo);
    }

    /// @notice reduces the supply of MIM
    /// @param amount amount to reduce supply by
    function reduceSupply(uint256 amount) public {
        require(msg.sender == masterContract.owner(), "Caller is not the owner");
        bentoBox.withdraw(magicInternetMoney, address(this), address(this), amount, 0);
        MagicInternetMoney(address(magicInternetMoney)).burn(amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ICheckpointToken {
    /// @notice checkpoint rewards for given accounts. needs to be called before any balance change
    function user_checkpoint(address[2] calldata _accounts) external returns(bool);
}

// SPDX-License-Identifier: UNLICENSED

// Cauldron

//    (                (   (
//    )\      )    (   )\  )\ )  (
//  (((_)  ( /(   ))\ ((_)(()/(  )(    (    (
//  )\___  )(_)) /((_) _   ((_))(()\   )\   )\ )
// ((/ __|((_)_ (_))( | |  _| |  ((_) ((_) _(_/(
//  | (__ / _` || || || |/ _` | | '_|/ _ \| ' \))
//   \___|\__,_| \_,_||_|\__,_| |_|  \___/|_||_|

// Copyright (c) 2021 BoringCrypto - All rights reserved
// Twitter: @Boring_Crypto

// Special thanks to:
// @0xKeno - for all his invaluable contributions
// @burger_crypto - for the idea of trying to let the LPs benefit from liquidations

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@boringcrypto/boring-solidity/contracts/ERC20.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IMasterContract.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "./MagicInternetMoney.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/ISwapper.sol";

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

/// @title Cauldron
/// @dev This contract allows contract calls to any contract (except BentoBox)
/// from arbitrary callers thus, don't trust calls from this contract in any circumstances.
contract CauldronV2 is BoringOwnable, IMasterContract {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;

    event LogExchangeRate(uint256 rate);
    event LogAccrue(uint128 accruedAmount);
    event LogAddCollateral(address indexed from, address indexed to, uint256 share);
    event LogRemoveCollateral(address indexed from, address indexed to, uint256 share);
    event LogBorrow(address indexed from, address indexed to, uint256 amount, uint256 part);
    event LogRepay(address indexed from, address indexed to, uint256 amount, uint256 part);
    event LogFeeTo(address indexed newFeeTo);
    event LogWithdrawFees(address indexed feeTo, uint256 feesEarnedFraction);

    // Immutables (for MasterContract and all clones)
    IBentoBoxV1 public immutable bentoBox;
    CauldronV2 public immutable masterContract;
    IERC20 public immutable magicInternetMoney;

    // MasterContract variables
    address public feeTo;

    // Per clone variables
    // Clone init settings
    IERC20 public collateral;
    IOracle public oracle;
    bytes public oracleData;

    // Total amounts
    uint256 public totalCollateralShare; // Total collateral supplied
    Rebase public totalBorrow; // elastic = Total token amount to be repayed by borrowers, base = Total parts of the debt held by borrowers

    // User balances
    mapping(address => uint256) public userCollateralShare;
    mapping(address => uint256) public userBorrowPart;

    /// @notice Exchange and interest rate tracking.
    /// This is 'cached' here because calls to Oracles can be very expensive.
    uint256 public exchangeRate;

    struct AccrueInfo {
        uint64 lastAccrued;
        uint128 feesEarned;
        uint64 INTEREST_PER_SECOND;
    }

    AccrueInfo public accrueInfo;

    // Settings
    uint256 public COLLATERIZATION_RATE;
    uint256 private constant COLLATERIZATION_RATE_PRECISION = 1e5; // Must be less than EXCHANGE_RATE_PRECISION (due to optimization in math)

    uint256 private constant EXCHANGE_RATE_PRECISION = 1e18;

    uint256 public LIQUIDATION_MULTIPLIER; 
    uint256 private constant LIQUIDATION_MULTIPLIER_PRECISION = 1e5;

    uint256 public BORROW_OPENING_FEE;
    uint256 private constant BORROW_OPENING_FEE_PRECISION = 1e5;

    uint256 private constant DISTRIBUTION_PART = 10;
    uint256 private constant DISTRIBUTION_PRECISION = 100;

    /// @notice The constructor is only used for the initial master contract. Subsequent clones are initialised via `init`.
    constructor(IBentoBoxV1 bentoBox_, IERC20 magicInternetMoney_) public {
        bentoBox = bentoBox_;
        magicInternetMoney = magicInternetMoney_;
        masterContract = this;
    }

    /// @notice Serves as the constructor for clones, as clones can't have a regular constructor
    /// @dev `data` is abi encoded in the format: (IERC20 collateral, IERC20 asset, IOracle oracle, bytes oracleData)
    function init(bytes calldata data) public payable override {
        require(address(collateral) == address(0), "Cauldron: already initialized");
        (collateral, oracle, oracleData, accrueInfo.INTEREST_PER_SECOND, LIQUIDATION_MULTIPLIER, COLLATERIZATION_RATE, BORROW_OPENING_FEE) = abi.decode(data, (IERC20, IOracle, bytes, uint64, uint256, uint256, uint256));
        require(address(collateral) != address(0), "Cauldron: bad pair");
    }

    /// @notice Accrues the interest on the borrowed tokens and handles the accumulation of fees.
    function accrue() public {
        AccrueInfo memory _accrueInfo = accrueInfo;
        // Number of seconds since accrue was called
        uint256 elapsedTime = block.timestamp - _accrueInfo.lastAccrued;
        if (elapsedTime == 0) {
            return;
        }
        _accrueInfo.lastAccrued = uint64(block.timestamp);

        Rebase memory _totalBorrow = totalBorrow;
        if (_totalBorrow.base == 0) {
            accrueInfo = _accrueInfo;
            return;
        }

        // Accrue interest
        uint128 extraAmount = (uint256(_totalBorrow.elastic).mul(_accrueInfo.INTEREST_PER_SECOND).mul(elapsedTime) / 1e18).to128();
        _totalBorrow.elastic = _totalBorrow.elastic.add(extraAmount);

        _accrueInfo.feesEarned = _accrueInfo.feesEarned.add(extraAmount);
        totalBorrow = _totalBorrow;
        accrueInfo = _accrueInfo;

        emit LogAccrue(extraAmount);
    }

    /// @notice Concrete implementation of `isSolvent`. Includes a third parameter to allow caching `exchangeRate`.
    /// @param _exchangeRate The exchange rate. Used to cache the `exchangeRate` between calls.
    function _isSolvent(address user, uint256 _exchangeRate) internal view returns (bool) {
        // accrue must have already been called!
        uint256 borrowPart = userBorrowPart[user];
        if (borrowPart == 0) return true;
        uint256 collateralShare = userCollateralShare[user];
        if (collateralShare == 0) return false;

        Rebase memory _totalBorrow = totalBorrow;

        return
            bentoBox.toAmount(
                collateral,
                collateralShare.mul(EXCHANGE_RATE_PRECISION / COLLATERIZATION_RATE_PRECISION).mul(COLLATERIZATION_RATE),
                false
            ) >=
            // Moved exchangeRate here instead of dividing the other side to preserve more precision
            borrowPart.mul(_totalBorrow.elastic).mul(_exchangeRate) / _totalBorrow.base;
    }

    /// @dev Checks if the user is solvent in the closed liquidation case at the end of the function body.
    modifier solvent() {
        _;
        require(_isSolvent(msg.sender, exchangeRate), "Cauldron: user insolvent");
    }

    /// @notice Gets the exchange rate. I.e how much collateral to buy 1e18 asset.
    /// This function is supposed to be invoked if needed because Oracle queries can be expensive.
    /// @return updated True if `exchangeRate` was updated.
    /// @return rate The new exchange rate.
    function updateExchangeRate() public returns (bool updated, uint256 rate) {
        (updated, rate) = oracle.get(oracleData);

        if (updated) {
            exchangeRate = rate;
            emit LogExchangeRate(rate);
        } else {
            // Return the old rate if fetching wasn't successful
            rate = exchangeRate;
        }
    }

    /// @dev Helper function to move tokens.
    /// @param token The ERC-20 token.
    /// @param share The amount in shares to add.
    /// @param total Grand total amount to deduct from this contract's balance. Only applicable if `skim` is True.
    /// Only used for accounting checks.
    /// @param skim If True, only does a balance check on this contract.
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    function _addTokens(
        IERC20 token,
        uint256 share,
        uint256 total,
        bool skim
    ) internal {
        if (skim) {
            require(share <= bentoBox.balanceOf(token, address(this)).sub(total), "Cauldron: Skim too much");
        } else {
            bentoBox.transfer(token, msg.sender, address(this), share);
        }
    }

    /// @notice Adds `collateral` from msg.sender to the account `to`.
    /// @param to The receiver of the tokens.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.x
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    /// @param share The amount of shares to add for `to`.
    function addCollateral(
        address to,
        bool skim,
        uint256 share
    ) public {
        userCollateralShare[to] = userCollateralShare[to].add(share);
        uint256 oldTotalCollateralShare = totalCollateralShare;
        totalCollateralShare = oldTotalCollateralShare.add(share);
        _addTokens(collateral, share, oldTotalCollateralShare, skim);
        emit LogAddCollateral(skim ? address(bentoBox) : msg.sender, to, share);
    }

    /// @dev Concrete implementation of `removeCollateral`.
    function _removeCollateral(address to, uint256 share) internal {
        userCollateralShare[msg.sender] = userCollateralShare[msg.sender].sub(share);
        totalCollateralShare = totalCollateralShare.sub(share);
        emit LogRemoveCollateral(msg.sender, to, share);
        bentoBox.transfer(collateral, address(this), to, share);
    }

    /// @notice Removes `share` amount of collateral and transfers it to `to`.
    /// @param to The receiver of the shares.
    /// @param share Amount of shares to remove.
    function removeCollateral(address to, uint256 share) public solvent {
        // accrue must be called because we check solvency
        accrue();
        _removeCollateral(to, share);
    }

    /// @dev Concrete implementation of `borrow`.
    function _borrow(address to, uint256 amount) internal returns (uint256 part, uint256 share) {
        uint256 feeAmount = amount.mul(BORROW_OPENING_FEE) / BORROW_OPENING_FEE_PRECISION; // A flat % fee is charged for any borrow
        (totalBorrow, part) = totalBorrow.add(amount.add(feeAmount), true);
        accrueInfo.feesEarned = accrueInfo.feesEarned.add(uint128(feeAmount));
        userBorrowPart[msg.sender] = userBorrowPart[msg.sender].add(part);

        // As long as there are tokens on this contract you can 'mint'... this enables limiting borrows
        share = bentoBox.toShare(magicInternetMoney, amount, false);
        bentoBox.transfer(magicInternetMoney, address(this), to, share);

        emit LogBorrow(msg.sender, to, amount.add(feeAmount), part);
    }

    /// @notice Sender borrows `amount` and transfers it to `to`.
    /// @return part Total part of the debt held by borrowers.
    /// @return share Total amount in shares borrowed.
    function borrow(address to, uint256 amount) public solvent returns (uint256 part, uint256 share) {
        accrue();
        (part, share) = _borrow(to, amount);
    }

    /// @dev Concrete implementation of `repay`.
    function _repay(
        address to,
        bool skim,
        uint256 part
    ) internal returns (uint256 amount) {
        (totalBorrow, amount) = totalBorrow.sub(part, true);
        userBorrowPart[to] = userBorrowPart[to].sub(part);

        uint256 share = bentoBox.toShare(magicInternetMoney, amount, true);
        bentoBox.transfer(magicInternetMoney, skim ? address(bentoBox) : msg.sender, address(this), share);
        emit LogRepay(skim ? address(bentoBox) : msg.sender, to, amount, part);
    }

    /// @notice Repays a loan.
    /// @param to Address of the user this payment should go.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    /// @param part The amount to repay. See `userBorrowPart`.
    /// @return amount The total amount repayed.
    function repay(
        address to,
        bool skim,
        uint256 part
    ) public returns (uint256 amount) {
        accrue();
        amount = _repay(to, skim, part);
    }

    // Functions that need accrue to be called
    uint8 internal constant ACTION_REPAY = 2;
    uint8 internal constant ACTION_REMOVE_COLLATERAL = 4;
    uint8 internal constant ACTION_BORROW = 5;
    uint8 internal constant ACTION_GET_REPAY_SHARE = 6;
    uint8 internal constant ACTION_GET_REPAY_PART = 7;
    uint8 internal constant ACTION_ACCRUE = 8;

    // Functions that don't need accrue to be called
    uint8 internal constant ACTION_ADD_COLLATERAL = 10;
    uint8 internal constant ACTION_UPDATE_EXCHANGE_RATE = 11;

    // Function on BentoBox
    uint8 internal constant ACTION_BENTO_DEPOSIT = 20;
    uint8 internal constant ACTION_BENTO_WITHDRAW = 21;
    uint8 internal constant ACTION_BENTO_TRANSFER = 22;
    uint8 internal constant ACTION_BENTO_TRANSFER_MULTIPLE = 23;
    uint8 internal constant ACTION_BENTO_SETAPPROVAL = 24;

    // Any external call (except to BentoBox)
    uint8 internal constant ACTION_CALL = 30;

    int256 internal constant USE_VALUE1 = -1;
    int256 internal constant USE_VALUE2 = -2;

    /// @dev Helper function for choosing the correct value (`value1` or `value2`) depending on `inNum`.
    function _num(
        int256 inNum,
        uint256 value1,
        uint256 value2
    ) internal pure returns (uint256 outNum) {
        outNum = inNum >= 0 ? uint256(inNum) : (inNum == USE_VALUE1 ? value1 : value2);
    }

    /// @dev Helper function for depositing into `bentoBox`.
    function _bentoDeposit(
        bytes memory data,
        uint256 value,
        uint256 value1,
        uint256 value2
    ) internal returns (uint256, uint256) {
        (IERC20 token, address to, int256 amount, int256 share) = abi.decode(data, (IERC20, address, int256, int256));
        amount = int256(_num(amount, value1, value2)); // Done this way to avoid stack too deep errors
        share = int256(_num(share, value1, value2));
        return bentoBox.deposit{value: value}(token, msg.sender, to, uint256(amount), uint256(share));
    }

    /// @dev Helper function to withdraw from the `bentoBox`.
    function _bentoWithdraw(
        bytes memory data,
        uint256 value1,
        uint256 value2
    ) internal returns (uint256, uint256) {
        (IERC20 token, address to, int256 amount, int256 share) = abi.decode(data, (IERC20, address, int256, int256));
        return bentoBox.withdraw(token, msg.sender, to, _num(amount, value1, value2), _num(share, value1, value2));
    }

    /// @dev Helper function to perform a contract call and eventually extracting revert messages on failure.
    /// Calls to `bentoBox` are not allowed for obvious security reasons.
    /// This also means that calls made from this contract shall *not* be trusted.
    function _call(
        uint256 value,
        bytes memory data,
        uint256 value1,
        uint256 value2
    ) internal returns (bytes memory, uint8) {
        (address callee, bytes memory callData, bool useValue1, bool useValue2, uint8 returnValues) =
            abi.decode(data, (address, bytes, bool, bool, uint8));

        if (useValue1 && !useValue2) {
            callData = abi.encodePacked(callData, value1);
        } else if (!useValue1 && useValue2) {
            callData = abi.encodePacked(callData, value2);
        } else if (useValue1 && useValue2) {
            callData = abi.encodePacked(callData, value1, value2);
        }

        require(callee != address(bentoBox) && callee != address(this), "Cauldron: can't call");

        (bool success, bytes memory returnData) = callee.call{value: value}(callData);
        require(success, "Cauldron: call failed");
        return (returnData, returnValues);
    }

    struct CookStatus {
        bool needsSolvencyCheck;
        bool hasAccrued;
    }

    /// @notice Executes a set of actions and allows composability (contract calls) to other contracts.
    /// @param actions An array with a sequence of actions to execute (see ACTION_ declarations).
    /// @param values A one-to-one mapped array to `actions`. ETH amounts to send along with the actions.
    /// Only applicable to `ACTION_CALL`, `ACTION_BENTO_DEPOSIT`.
    /// @param datas A one-to-one mapped array to `actions`. Contains abi encoded data of function arguments.
    /// @return value1 May contain the first positioned return value of the last executed action (if applicable).
    /// @return value2 May contain the second positioned return value of the last executed action which returns 2 values (if applicable).
    function cook(
        uint8[] calldata actions,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external payable returns (uint256 value1, uint256 value2) {
        CookStatus memory status;
        for (uint256 i = 0; i < actions.length; i++) {
            uint8 action = actions[i];
            if (!status.hasAccrued && action < 10) {
                accrue();
                status.hasAccrued = true;
            }
            if (action == ACTION_ADD_COLLATERAL) {
                (int256 share, address to, bool skim) = abi.decode(datas[i], (int256, address, bool));
                addCollateral(to, skim, _num(share, value1, value2));
            } else if (action == ACTION_REPAY) {
                (int256 part, address to, bool skim) = abi.decode(datas[i], (int256, address, bool));
                _repay(to, skim, _num(part, value1, value2));
            } else if (action == ACTION_REMOVE_COLLATERAL) {
                (int256 share, address to) = abi.decode(datas[i], (int256, address));
                _removeCollateral(to, _num(share, value1, value2));
                status.needsSolvencyCheck = true;
            } else if (action == ACTION_BORROW) {
                (int256 amount, address to) = abi.decode(datas[i], (int256, address));
                (value1, value2) = _borrow(to, _num(amount, value1, value2));
                status.needsSolvencyCheck = true;
            } else if (action == ACTION_UPDATE_EXCHANGE_RATE) {
                (bool must_update, uint256 minRate, uint256 maxRate) = abi.decode(datas[i], (bool, uint256, uint256));
                (bool updated, uint256 rate) = updateExchangeRate();
                require((!must_update || updated) && rate > minRate && (maxRate == 0 || rate > maxRate), "Cauldron: rate not ok");
            } else if (action == ACTION_BENTO_SETAPPROVAL) {
                (address user, address _masterContract, bool approved, uint8 v, bytes32 r, bytes32 s) =
                    abi.decode(datas[i], (address, address, bool, uint8, bytes32, bytes32));
                bentoBox.setMasterContractApproval(user, _masterContract, approved, v, r, s);
            } else if (action == ACTION_BENTO_DEPOSIT) {
                (value1, value2) = _bentoDeposit(datas[i], values[i], value1, value2);
            } else if (action == ACTION_BENTO_WITHDRAW) {
                (value1, value2) = _bentoWithdraw(datas[i], value1, value2);
            } else if (action == ACTION_BENTO_TRANSFER) {
                (IERC20 token, address to, int256 share) = abi.decode(datas[i], (IERC20, address, int256));
                bentoBox.transfer(token, msg.sender, to, _num(share, value1, value2));
            } else if (action == ACTION_BENTO_TRANSFER_MULTIPLE) {
                (IERC20 token, address[] memory tos, uint256[] memory shares) = abi.decode(datas[i], (IERC20, address[], uint256[]));
                bentoBox.transferMultiple(token, msg.sender, tos, shares);
            } else if (action == ACTION_CALL) {
                (bytes memory returnData, uint8 returnValues) = _call(values[i], datas[i], value1, value2);

                if (returnValues == 1) {
                    (value1) = abi.decode(returnData, (uint256));
                } else if (returnValues == 2) {
                    (value1, value2) = abi.decode(returnData, (uint256, uint256));
                }
            } else if (action == ACTION_GET_REPAY_SHARE) {
                int256 part = abi.decode(datas[i], (int256));
                value1 = bentoBox.toShare(magicInternetMoney, totalBorrow.toElastic(_num(part, value1, value2), true), true);
            } else if (action == ACTION_GET_REPAY_PART) {
                int256 amount = abi.decode(datas[i], (int256));
                value1 = totalBorrow.toBase(_num(amount, value1, value2), false);
            }
        }

        if (status.needsSolvencyCheck) {
            require(_isSolvent(msg.sender, exchangeRate), "Cauldron: user insolvent");
        }
    }

    /// @notice Handles the liquidation of users' balances, once the users' amount of collateral is too low.
    /// @param users An array of user addresses.
    /// @param maxBorrowParts A one-to-one mapping to `users`, contains maximum (partial) borrow amounts (to liquidate) of the respective user.
    /// @param to Address of the receiver in open liquidations if `swapper` is zero.
    function liquidate(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        address to,
        ISwapper swapper
    ) public {
        // Oracle can fail but we still need to allow liquidations
        (, uint256 _exchangeRate) = updateExchangeRate();
        accrue();

        uint256 allCollateralShare;
        uint256 allBorrowAmount;
        uint256 allBorrowPart;
        Rebase memory _totalBorrow = totalBorrow;
        Rebase memory bentoBoxTotals = bentoBox.totals(collateral);
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (!_isSolvent(user, _exchangeRate)) {
                uint256 borrowPart;
                {
                    uint256 availableBorrowPart = userBorrowPart[user];
                    borrowPart = maxBorrowParts[i] > availableBorrowPart ? availableBorrowPart : maxBorrowParts[i];
                    userBorrowPart[user] = availableBorrowPart.sub(borrowPart);
                }
                uint256 borrowAmount = _totalBorrow.toElastic(borrowPart, false);
                uint256 collateralShare =
                    bentoBoxTotals.toBase(
                        borrowAmount.mul(LIQUIDATION_MULTIPLIER).mul(_exchangeRate) /
                            (LIQUIDATION_MULTIPLIER_PRECISION * EXCHANGE_RATE_PRECISION),
                        false
                    );

                userCollateralShare[user] = userCollateralShare[user].sub(collateralShare);
                emit LogRemoveCollateral(user, to, collateralShare);
                emit LogRepay(msg.sender, user, borrowAmount, borrowPart);

                // Keep totals
                allCollateralShare = allCollateralShare.add(collateralShare);
                allBorrowAmount = allBorrowAmount.add(borrowAmount);
                allBorrowPart = allBorrowPart.add(borrowPart);
            }
        }
        require(allBorrowAmount != 0, "Cauldron: all are solvent");
        _totalBorrow.elastic = _totalBorrow.elastic.sub(allBorrowAmount.to128());
        _totalBorrow.base = _totalBorrow.base.sub(allBorrowPart.to128());
        totalBorrow = _totalBorrow;
        totalCollateralShare = totalCollateralShare.sub(allCollateralShare);

        // Apply a percentual fee share to sSpell holders
        
        {
            uint256 distributionAmount = (allBorrowAmount.mul(LIQUIDATION_MULTIPLIER) / LIQUIDATION_MULTIPLIER_PRECISION).sub(allBorrowAmount).mul(DISTRIBUTION_PART) / DISTRIBUTION_PRECISION; // Distribution Amount
            allBorrowAmount = allBorrowAmount.add(distributionAmount);
            accrueInfo.feesEarned = accrueInfo.feesEarned.add(distributionAmount.to128());
        }

        uint256 allBorrowShare = bentoBox.toShare(magicInternetMoney, allBorrowAmount, true);

        // Swap using a swapper freely chosen by the caller
        // Open (flash) liquidation: get proceeds first and provide the borrow after
        bentoBox.transfer(collateral, address(this), to, allCollateralShare);
        if (swapper != ISwapper(0)) {
            swapper.swap(collateral, magicInternetMoney, msg.sender, allBorrowShare, allCollateralShare);
        }

        bentoBox.transfer(magicInternetMoney, msg.sender, address(this), allBorrowShare);
    }

    /// @notice Withdraws the fees accumulated.
    function withdrawFees() public {
        accrue();
        address _feeTo = masterContract.feeTo();
        uint256 _feesEarned = accrueInfo.feesEarned;
        uint256 share = bentoBox.toShare(magicInternetMoney, _feesEarned, false);
        bentoBox.transfer(magicInternetMoney, address(this), _feeTo, share);
        accrueInfo.feesEarned = 0;

        emit LogWithdrawFees(_feeTo, _feesEarned);
    }

    /// @notice Sets the beneficiary of interest accrued.
    /// MasterContract Only Admin function.
    /// @param newFeeTo The address of the receiver.
    function setFeeTo(address newFeeTo) public onlyOwner {
        feeTo = newFeeTo;
        emit LogFeeTo(newFeeTo);
    }

    /// @notice reduces the supply of MIM
    /// @param amount amount to reduce supply by
    function reduceSupply(uint256 amount) public {
        require(msg.sender == masterContract.owner(), "Caller is not the owner");
        bentoBox.withdraw(magicInternetMoney, address(this), address(this), amount, 0);
        MagicInternetMoney(address(magicInternetMoney)).burn(amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "../NFTPair.sol";

// Minimal implementation to set up some tests.
contract LendingClubMock {
    INFTPair private immutable nftPair;
    address private immutable investor;

    constructor(INFTPair _nftPair, address _investor) public {
        nftPair = _nftPair;
        investor = _investor;
    }

    function init() public {
        nftPair.bentoBox().setMasterContractApproval(
            address(this),
            address(nftPair.masterContract()),
            true,
            0,
            bytes32(0),
            bytes32(0)
        );
    }

    function willLend(uint256 tokenId, TokenLoanParams memory requested)
        external
        view
        returns (bool)
    {
        if (msg.sender != address(nftPair)) {
            return false;
        }
        TokenLoanParams memory accepted = _lendingConditions(tokenId);
        // Valuation has to be an exact match, everything else must be at least
        // as good for the lender as `accepted`.

        return
            requested.valuation == accepted.valuation &&
            requested.duration <= accepted.duration &&
            requested.annualInterestBPS >= accepted.annualInterestBPS;
    }

    function _lendingConditions(uint256 tokenId)
        private
        pure
        returns (TokenLoanParams memory)
    {
        TokenLoanParams memory conditions;
        // No specific conditions given, but we'll take all even-numbered
        // ones at 100% APY:
        if (tokenId % 2 == 0) {
            // 256-bit addition fits by the above check.
            // Cast is.. relatively safe: this is a mock implementation,
            // production use is unlikely to follow this pattern for valuing
            // loans, and manipulating the token ID can only break the logic by
            // making the loan "safer" for the lender.
            conditions.valuation = uint128((tokenId + 1) * 10**18);
            conditions.duration = 365 days;
            conditions.annualInterestBPS = 10_000;
        }
        return conditions;
    }

    function lendingConditions(address _nftPair, uint256 tokenId)
        external
        view
        returns (TokenLoanParams memory)
    {
        if (_nftPair != address(nftPair)) {
            TokenLoanParams memory empty;
            return empty;
        } else {
            return _lendingConditions(tokenId);
        }
    }

    function seizeCollateral(uint256 tokenId) external {
        nftPair.removeCollateral(tokenId, investor);
    }

    function withdrawFunds(uint256 bentoShares) external {
        nftPair.bentoBox().transfer(
            nftPair.asset(),
            address(this),
            investor,
            bentoShares
        );
    }
}

//SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";

// Modified from https://etherscan.io/address/0x6d903f6003cca6255d85cca4d3b5e5146dc33925#code and https://github.com/boringcrypto/dictator-dao/blob/main/contracts/DictatorDAO.sol#L225
contract MinimalTimeLock is BoringOwnable {    
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint256 value, bytes data, uint256 eta);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint256 value, bytes data);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint256 value, bytes data);

    uint256 public constant GRACE_PERIOD = 14 days;
    uint256 public constant DELAY = 2 days;
    mapping(bytes32 => uint256) public queuedTransactions;

    function queueTransaction(
        address target,
        uint256 value,
        bytes memory data
    ) public onlyOwner returns (bytes32) {

        bytes32 txHash = keccak256(abi.encode(target, value, data));
        uint256 eta = block.timestamp + DELAY;
        queuedTransactions[txHash] = eta;

        emit QueueTransaction(txHash, target, value, data, eta);
        return txHash;
    }

    function cancelTransaction(
        address target,
        uint256 value,
        bytes memory data
    ) public onlyOwner {

        bytes32 txHash = keccak256(abi.encode(target, value, data));
        queuedTransactions[txHash] = 0;

        emit CancelTransaction(txHash, target, value, data);
    }

    function executeTransaction(
        address target,
        uint256 value,
        bytes memory data
    ) public onlyOwner payable returns (bytes memory) {

        bytes32 txHash = keccak256(abi.encode(target, value, data));
        uint256 eta = queuedTransactions[txHash];
        require(block.timestamp >= eta, "Too early");
        require(block.timestamp <= eta + GRACE_PERIOD, "Tx stale");

        queuedTransactions[txHash] = 0;

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(data);
        require(success, "Tx reverted :(");

        emit ExecuteTransaction(txHash, target, value, data);

        return returnData;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/ERC20.sol";

contract ERC20Mock is ERC20 {
    uint256 public override totalSupply;

    constructor(uint256 _initialAmount) public {
        // Give the creator all initial tokens
        balanceOf[msg.sender] = _initialAmount;
        // Update total supply
        totalSupply = _initialAmount;
    }
}