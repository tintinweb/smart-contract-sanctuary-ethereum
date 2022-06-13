//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../interfaces/IBentoBoxV1.sol";
import "../interfaces/IKashiPairMediumRiskV1.sol";
import "../libraries/Boring.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IUniswapV2Router02.sol";

contract KashiPairWrapperLogic is Initializable, IFlashBorrower{
    using SafeERC20 for IERC20;
    using RebaseLibrary for Rebase;

    struct FeeInfo {
        // Need a known instance of UniV2 that is guaranteed to have the token
        // that the default fee is paid in, along with enough liquidity, since
        // an arbitrary instance of UniV2 is passed to fcns in this contract
        IUniswapV2Router02 uni;
        address[] path;
        // Whether or not the fee token is AUTO, because that needs to
        // get sent to the user, since `transferFrom` is used from them directly
        // in the Registry to charge the fee
        bool isAUTO;
    }

    /// @dev Address of User wallet, who actually use this contract for borrow/repay
    address public owner;

    /// @dev Autonomy Registry related params
    address payable public registry; 
    address public userVeriForwarder;
    address public userFeeVeriForwarder;
    FeeInfo public defaultFeeInfo;

    /// @dev internal settings of KashiPairMediumRiskV1
    IBentoBoxV1 public bentoBox;

    address public WETH;
    address public AUTO;

    enum SolvencyStatus {
        YES,
        NO,
        REPAID
    }

    uint256 internal constant CLOSED_COLLATERIZATION_RATE = 75000; // 75%
    uint256 internal constant OPEN_COLLATERIZATION_RATE = 77000; // 77%
    uint256 internal constant COLLATERIZATION_RATE_PRECISION = 1e5; // Must be less than EXCHANGE_RATE_PRECISION (due to optimization in math)
    uint256 internal constant EXCHANGE_RATE_PRECISION = 1e18;

    uint256 internal constant MAX_UINT = type(uint256).max;
    uint256 internal constant DEADLINE = 2429913600;

    IERC20 internal constant USE_ETHEREUM = IERC20(address(0));
    int256 internal constant USE_VALUE1 = -1;
    int256 internal constant USE_VALUE2 = -2;

    /**
        @dev one time initializer, only called from factory.

        addrParams has the following addresses in order to fix stack-too-deep issue.
        [0] owner_,
        [1] bentoBox_,
        [2] registry_,
        [3] userVeriForwarder_,
        [4] userFeeVeriForwarder_,
        [5] WETH_,
        [6] AUTO_
     */
    function initialize(
        address[7] calldata addrParams_,
        bytes calldata defaultFeeInfo_,
        bytes calldata initialTxnData_
    ) payable external initializer {
        owner = addrParams_[0];

        bentoBox = IBentoBoxV1(addrParams_[1]);

        registry = payable(addrParams_[2]);
        userVeriForwarder = addrParams_[3];
        userFeeVeriForwarder = addrParams_[4];
        defaultFeeInfo = abi.decode(defaultFeeInfo_, (FeeInfo));

        WETH = addrParams_[5];
        AUTO = addrParams_[6];

        /// @dev after initialize proxy, it will execute 1st transaction, just deposit, and borrow etc.
        (address position, uint8[] memory actions, uint256[] memory values, bytes[] memory datas) = 
            abi.decode(initialTxnData_, (address, uint8[], uint256[], bytes[]));
        _cook(
            IKashiPairMediumRiskV1(position),
            actions,
            values,
            datas,
            addrParams_[0]
        );
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////                                                                    ////
    ////--------------------- Kashi Pair Cook Part ------------------------////
    ////                                                                    ////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    /// @dev All user's assets will be flown through this contract to and from Kashi Pair
    /// And that will be stored into storage.

    /// @dev action identifiers of original cook(), from KashiPairMediumRiskV1
    uint8 internal constant ACTION_REPAY = 2;
    uint8 internal constant ACTION_REMOVE_COLLATERAL = 4;
    uint8 internal constant ACTION_BORROW = 5;
    uint8 internal constant ACTION_GET_REPAY_SHARE = 6;
    uint8 internal constant ACTION_GET_REPAY_PART = 7;
    uint8 internal constant ACTION_ACCRUE = 8;
    uint8 internal constant ACTION_ADD_COLLATERAL = 10;
    uint8 internal constant ACTION_UPDATE_EXCHANGE_RATE = 11;
    uint8 internal constant ACTION_BENTO_DEPOSIT = 20;
    uint8 internal constant ACTION_BENTO_WITHDRAW = 21;

    function userCollateralShare(IKashiPairMediumRiskV1 position) external view returns (uint256 collateralShare) {
        collateralShare = position.userCollateralShare(address(this));
    }

    function userBorrowPart(IKashiPairMediumRiskV1 position) external view returns (uint256 borrowPart) {
        borrowPart = position.userBorrowPart(address(this));
    }

    /// @notice Adds `collateral` from msg.sender to the account `to`.
    /// @param to The receiver of the tokens.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    /// @param share The amount of shares to add for `to`.
    function _addCollateral(
        IKashiPairMediumRiskV1 position,
        address to,
        bool skim,
        uint256 share
    ) internal {
        IERC20 _collateral = position.collateral();

        /// @dev it means, user already moved collateral into position in bentoBox inside
        if (!skim) {
            /// @dev contract accounts can not approve KashiPair to transfer own balance in bentoBox
            /// so it transfers balance first, and make skim as true
            bentoBox.transfer(_collateral, address(this), address(position), share);
        }
        position.addCollateral(to, true, share);
    }

    /// @notice Removes `share` amount of collateral and transfers it to `to`.
    /// @param to The receiver of the shares.
    /// @param share Amount of shares to remove.
    function _removeCollateral(
        IKashiPairMediumRiskV1 position,
        address to,
        uint256 share
    ) internal {
        position.removeCollateral(to, share);
    }

    /// @notice Sender borrows `amount` and transfers it to `to`.
    /// @return part Total part of the debt held by borrowers.
    /// @return share Total amount in shares borrowed.
    function _borrow(
        IKashiPairMediumRiskV1 position,
        address to,
        uint256 amount
    ) internal returns (uint256 part, uint256 share) {
        (part, share) = position.borrow(to, amount);
    }

    /// @notice Repays a loan.
    /// @param to Address of the user this payment should go.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    /// @param amount The amount to repay.
    /// @return amount repaid amount.
    function _repay(
        IKashiPairMediumRiskV1 position,
        address to,
        bool skim,
        uint256 part
    ) internal returns (uint256 amount) {
        amount = position.totalBorrow().toElastic(part, true);
        IERC20 _asset = position.asset();
        uint256 share = bentoBox.toShare(_asset, amount, true);

        /// @dev it means, user already moved collateral into position in bentoBox inside
        if (!skim) {
            /// @dev this can not approve KashiPair to transfer balance in bentoBox
            /// so it transfers balance first, and make skim as true
            bentoBox.transfer(_asset, address(this), address(position), share);
        }
        position.repay(to, true, part);
    }

    /// @dev to avoid stack-too-deep issue
    function _getRepayShare(IKashiPairMediumRiskV1 position, uint256 part)
        internal
        view
        returns (uint256 share)
    {
        share = bentoBox.toShare(
            position.asset(),
            position.totalBorrow().toElastic(part, true),
            true
        );
    }

    /// @notice It will deposit any token(from user wallet) into BentoBox under this account, not user's.
    /// It has the same format, with the same function in Kashi Pair.
    /// @dev End users can deposit into BentoBox, through Kashi Pair contract, with his approval to master contract.
    /// But Contract account can not deposit any token into BentoBox through Kashi Pair.
    /// So it moves user's token amount into this, and deposits into BentoBox directly, and save the amount into internal status.
    function _execBentoDeposit(
        IERC20 token,
        address to,
        int256 amount,
        uint256 value,
        int256 share,
        address from
    ) internal returns (uint256 amountOut, uint256 shareOut) {
        Rebase memory total = bentoBox.totals(token);
        // get amount from share in bentoBox
        if (share != 0) {
            amount = int256(total.toElastic(uint256(share), true));
        }

        if (token != USE_ETHEREUM) {
            // move token from msg.sender to this, and approve into BentoBox
            uint256 prevBalance = token.balanceOf(address(this));
            transferApproveUnapproved(
                address(bentoBox),
                address(token),
                uint256(amount),
                from
            );
            uint256 newBalance = token.balanceOf(address(this));
            require(
                (newBalance - prevBalance) == uint256(amount),
                "Invalid amount"
            );
        } else {
            require(value == uint256(amount), "Invalid amount");
        }

        (amountOut, shareOut) = bentoBox.deposit{value: value}(
            token,
            address(this),
            to,
            uint256(amount),
            uint256(share)
        );
    }

    function _bentoDeposit(
        bytes memory data,
        uint256 value,
        uint256 value1,
        uint256 value2,
        address from
    ) internal returns (uint256 amountOut, uint256 shareOut) {
        // decode call data
        (IERC20 token, address to, int256 amount, int256 share) = abi.decode(
            data,
            (IERC20, address, int256, int256)
        );
        amount = int256(_num(amount, value1, value2)); // Done this way to avoid stack too deep errors
        share = int256(_num(share, value1, value2));

        return _execBentoDeposit(token, to, amount, value, share, from);
    }

    /// @notice It will withdraw any token from BentoBox, under this account, and transfer into user wallet.
    /// It has the same format, with the same function in Kashi Pair.
    /// @dev End users can withdraw from BentoBox, through Kashi Pair contract, with his approval to master contract.
    /// But Contract account can not withdraw any token from BentoBox through Kashi Pair.
    /// So it withdraws from BentoBox directly, and returns the token amount into user wallet.
    function _execBentoWithdraw(
        IERC20 token_,
        address to,
        uint256 amount,
        uint256 share
    ) internal returns (uint256 amountOut, uint256 shareOut) {
        IERC20 token = token_ == USE_ETHEREUM ? IERC20(WETH) : token_;
        uint256 prevBalance;
        uint256 newBalance;

        prevBalance = token_ != USE_ETHEREUM ? token.balanceOf(address(this)) : address(this).balance;
        (amountOut, shareOut) = bentoBox.withdraw(
            token_,
            address(this),
            address(this),
            amount,
            share
        );

        newBalance = token_ != USE_ETHEREUM ? token.balanceOf(address(this)) : address(this).balance;
        require((newBalance - prevBalance) >= amountOut, "Invalid amount");

        if (token_ == USE_ETHEREUM) {
            payable(to).transfer(amountOut);
        } else {
            token.transfer(to, amountOut);
        }
    }

    function _bentoWithdraw(
        bytes memory data,
        uint256 value1,
        uint256 value2
    ) internal returns (uint256 amountOut, uint256 shareOut) {
        // decode call data
        (IERC20 token, address to, int256 amount, int256 share) = abi.decode(
            data,
            (IERC20, address, int256, int256)
        );

        return
            _execBentoWithdraw(
                token,
                to,
                _num(amount, value1, value2),
                _num(share, value1, value2)
            );
    }

    struct CookStatus {
        bool needsSolvencyCheck;
        bool hasAccrued;
    }

    /// @dev It is forked from cook() in Kashi, and implemented subset actions for mainly borrow & repay features.
    ///      And unnecessary actions were removed.
    /// @notice Executes a set of actions and allows composability (contract calls) to other contracts.
    /// @param actions An array with a sequence of actions to execute (see ACTION_ declarations).
    /// @param values A one-to-one mapped array to `actions`. ETH amounts to send along with the actions.
    /// Only applicable to `ACTION_CALL`, `ACTION_BENTO_DEPOSIT`.
    /// @param datas A one-to-one mapped array to `actions`. Contains abi encoded data of function arguments.
    /// @return value1 May contain the first positioned return value of the last executed action (if applicable).
    /// @return value2 May contain the second positioned return value of the last executed action which returns 2 values (if applicable).
    function cook(
        IKashiPairMediumRiskV1 position,
        uint8[] memory actions,
        uint256[] memory values,
        bytes[] memory datas
    ) external payable onlyOwner returns (uint256 value1, uint256 value2) {
        (value1, value2) = _cook(position, actions, values, datas, msg.sender);
    }

    function _cook(
        IKashiPairMediumRiskV1 position,
        uint8[] memory actions,
        uint256[] memory values,
        bytes[] memory datas,
        address from
    ) internal returns (uint256 value1, uint256 value2) {
        CookStatus memory status;

        for (uint256 i = 0; i < actions.length; i++) {
            uint8 action = actions[i];
            if (!status.hasAccrued && action < 10) {
                position.accrue();
                status.hasAccrued = true;
            }
            if (action == ACTION_ADD_COLLATERAL) {
                (int256 share, address to, bool skim) = abi.decode(
                    datas[i],
                    (int256, address, bool)
                );
                _addCollateral(position, to, skim, _num(share, value1, value2));
            } else if (action == ACTION_REMOVE_COLLATERAL) {
                (int256 share, address to) = abi.decode(
                    datas[i],
                    (int256, address)
                );
                _removeCollateral(position, to, _num(share, value1, value2));
                status.needsSolvencyCheck = true;
            } else if (action == ACTION_REPAY) {
                (int256 part, address to, bool skim) = abi.decode(
                    datas[i],
                    (int256, address, bool)
                );
                _repay(position, to, skim, _num(part, value1, value2));
            } else if (action == ACTION_BORROW) {
                (int256 amount, address to) = abi.decode(
                    datas[i],
                    (int256, address)
                );
                (value1, value2) = _borrow(
                    position,
                    to,
                    _num(amount, value1, value2)
                );
                status.needsSolvencyCheck = true;
            } else if (action == ACTION_UPDATE_EXCHANGE_RATE) {
                position.updateExchangeRate();
            } else if (action == ACTION_BENTO_DEPOSIT) {
                (value1, value2) = _bentoDeposit(
                    datas[i],
                    values[i],
                    value1,
                    value2,
                    from
                );
            } else if (action == ACTION_BENTO_WITHDRAW) {
                (value1, value2) = _bentoWithdraw(datas[i], value1, value2);
            } else if (action == ACTION_GET_REPAY_SHARE) {
                int256 part = abi.decode(datas[i], (int256));
                value1 = _getRepayShare(position, _num(part, value1, value2));
            } else if (action == ACTION_GET_REPAY_PART) {
                int256 amount = abi.decode(datas[i], (int256));
                value1 = position.totalBorrow().toBase(
                    _num(amount, value1, value2),
                    false
                );
            } else {
                /*
                - ACTION_ADD_ASSET
                - ACTION_REMOVE_ASSET
                - ACTION_CALL
                - ACTION_BENTO_TRANSFER
                - ACTION_BENTO_TRANSFER_MULTIPLE
                - ACTION_BENTO_SETAPPROVAL
                */
                revert("Not allowed actions");
            }
        }

        if (status.needsSolvencyCheck) {
            require(
                solvency(position, false, 0) != SolvencyStatus.NO,
                "User insolvent"
            );
        }
    }

    /// @dev Forked from _isSolvent() in KashiPairMediumRiskV1.sol
    /// @notice Checks if the user is solvent.
    /// @param bufferLimit Marginal percentage that will be added to the borrowed amount
    /// @return SolvencyStatus
    /// if SolvencyStatus.YES, it means user is solvent
    /// if SolvencyStatus.NO, it means insolvent
    /// if SolvencyStatus.REPAID, it means user fully repaid, and has no debt
    function solvency(
        IKashiPairMediumRiskV1 position,
        bool open,
        uint256 bufferLimit
    ) public view returns (SolvencyStatus) {
        uint256 borrowPart = position.userBorrowPart(address(this));
        if (borrowPart == 0) return SolvencyStatus.REPAID;

        uint256 collateralShare = position.userCollateralShare(address(this));
        if (collateralShare == 0) return SolvencyStatus.NO;

        Rebase memory _totalBorrow = position.totalBorrow();
        uint256 _exchangeRate = position.exchangeRate();

        // borrowAmount: actual asset amount that user should repay
        uint256 borrowAmount = (borrowPart * _totalBorrow.elastic) /
            _totalBorrow.base;

        return
            bentoBox.toAmount(
                position.collateral(),
                collateralShare *
                    (EXCHANGE_RATE_PRECISION / COLLATERIZATION_RATE_PRECISION) *
                    (
                        open
                            ? OPEN_COLLATERIZATION_RATE
                            : CLOSED_COLLATERIZATION_RATE
                    ),
                false
            ) <=
                // Moved exchangeRate here instead of dividing the other side to preserve more precision
                ((borrowAmount * _exchangeRate) * (100 + bufferLimit)) / 100
                ? SolvencyStatus.NO
                : SolvencyStatus.YES;
    }

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

    function getRepayPart(
        IKashiPairMediumRiskV1 position,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256) {
        return position.totalBorrow().toBase(
            amount,
            roundUp
        );
    }

    function getRepayAmount(
        IKashiPairMediumRiskV1 position,
        uint256 part,
        bool roundUp
    ) external view returns (uint256) {
        return position.totalBorrow().toElastic(
            part,
            roundUp
        );
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////                                                                    ////
    ////------------------------ Liquidation Part --------------------------////
    ////                                                                    ////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    struct KashiArgs {
        IKashiPairMediumRiskV1 position; // kashi lending pair's position address, e.g. WETH / USDT
        uint256 bufferLimit; // liquidation margin percentage
    }

    function selfLiquidate(address user, KashiArgs calldata kashiArgs)
        external
        userVerified
    {
        _selfLiquidatePaySpecific(user, 0, defaultFeeInfo, kashiArgs);
    }

    function selfLiquidatePayDefault(
        address user,
        uint256 feeAmount,
        KashiArgs calldata kashiArgs
    ) external userFeeVerified {
        FeeInfo memory feeInfo = defaultFeeInfo;

        _selfLiquidatePaySpecific(user, feeAmount, feeInfo, kashiArgs);
    }

    function selfLiquidatePaySpecific(
        address user,
        uint256 feeAmount,
        KashiArgs calldata kashiArgs,
        FeeInfo calldata feeInfo
    ) external userFeeVerified {
        _selfLiquidatePaySpecific(user, feeAmount, feeInfo, kashiArgs);
    }

    function _selfLiquidatePaySpecific(
        address user,
        uint256 feeAmount,
        FeeInfo memory feeInfo,
        KashiArgs memory kashiArgs
    ) internal {
        require(user == owner, "Only owner");

        SolvencyStatus _solvencyStatus = solvency(
            kashiArgs.position, 
            false, 
            kashiArgs.bufferLimit
        );

        // If REPAID already, then remove the request from registry
        require(_solvencyStatus != SolvencyStatus.REPAID, "Invalid job");
        // if still solvent status, then reject the job.
        require(_solvencyStatus == SolvencyStatus.NO, "Repay later");

        IERC20 asset = kashiArgs.position.asset();
        IERC20 collateral = kashiArgs.position.collateral();

        // get amount of borrowed asset
        uint256 _borrowedPart = kashiArgs.position.userBorrowPart(address(this));
        uint256 _borrowedAmount = kashiArgs.position.totalBorrow().toElastic(
            _borrowedPart,
            true
        );

        // Requests flashloan, in order to repay asset and remove collateral
        // Internally {onFlashLoan} will be called back from the BentoBox
        bentoBox.flashLoan(
            IFlashBorrower(this),
            address(this),
            asset,
            _borrowedAmount * 1000000 / 999999, // compensation of the rounding difference
            abi.encode(
                kashiArgs.position,
                collateral,
                _borrowedPart
            )
        );

        uint256 _leftCollateralAmount = collateral.balanceOf(address(this));

        // pay fee
        if (feeAmount > 0) {
            address[] memory routePath = new address[](3);

            _leftCollateralAmount -= _processFee(
                user,
                address(collateral), 
                _leftCollateralAmount,
                feeAmount,
                feeInfo,
                routePath
            );
        }

        // return left collateral into user wallet
        if (collateral != IERC20(WETH)) {
            collateral.transfer(user, _leftCollateralAmount);
        } else {
            IWETH(WETH).withdraw(_leftCollateralAmount);
            payable(user).transfer(_leftCollateralAmount);
        }
    }

    // swap input asset into fee token, and transfer to user or registry.
    // if fee is AUTO(ERC20), then transfer the swapped fee into user address(registry will take from user wallet later)
    // if fee is ETH, then transfer the swapped fee into registry directly.
    // returns the spent asset amount
    function _processFee(
        address user,
        address assetAddr,
        uint256 assetAmount,
        uint256 feeAmount,
        FeeInfo memory feeInfo,
        address[] memory routePath
    ) internal returns (uint256) {
        feeInfo.path[0] = assetAddr;
        // approve asset to uni
        approveUnapproved(address(feeInfo.uni), assetAddr, assetAmount);

        if (feeInfo.isAUTO) {
            if (assetAddr == WETH) {
                // feeInfo.path[1] = AUTO;
                // swap WETH to AUTO
                return
                    feeInfo.uni.swapTokensForExactTokens(
                        feeAmount,
                        assetAmount,
                        feeInfo.path,
                        user,
                        DEADLINE
                    )[0];
            } else {
                // if asset is general token, swap asset into AUTO through WETH
                routePath[0] = assetAddr;
                routePath[1] = WETH;
                routePath[2] = AUTO;
                return
                    feeInfo.uni.swapTokensForExactTokens(
                        feeAmount,
                        assetAmount,
                        routePath,
                        user,
                        DEADLINE
                    )[0];
            }
        } else {
            if (assetAddr == WETH) {
                IWETH(WETH).withdraw(feeAmount);
                registry.transfer(feeAmount);
                return feeAmount;
            } else {
                // feeInfo.path[1] = WETH;
                return
                    feeInfo.uni.swapTokensForExactETH(
                        feeAmount,
                        assetAmount,
                        feeInfo.path,
                        registry,
                        DEADLINE
                    )[0];
            }
        }
    }

    /// @dev flashloan callback, being called from BentoBox
    //  It will repay the user's borrowed asset(from Kashi) entirely using the flashloan,
    //    and remove collateral(from Kashi), and swap collateral into asset(by Uniswap), and 
    //    repay asset with fee into flashloan
    function onFlashLoan(
        address sender,
        IERC20 asset,   // user borrowed from Kashi
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override {
        require(msg.sender == address(bentoBox), "Only BentoBox allowed");
        require(sender == address(this), "Invalid sender");
        // require(token.balanceOf(address(this)) >= amount, "Not flashloaned");

        (IKashiPairMediumRiskV1 position, IERC20 collateral, uint256 _borrowedPart) = abi.decode(
            data,
            (IKashiPairMediumRiskV1, IERC20, uint256)
        );

        // deposit asset (that was borrowed from flashloan) into bentoBox, and repay to Kashi
        approveUnapproved(address(bentoBox), address(asset), amount);
        (uint256 assetAmountIn, ) = bentoBox.deposit(
            asset,
            address(this),
            address(position),
            amount,
            0
        );
        require(amount == assetAmountIn, "Invalid amount");
        position.repay(address(this), true, _borrowedPart);

        // remove all collateral, and withdraw from bentoBox
        uint256 collateralShare = position.userCollateralShare(address(this));
        position.removeCollateral(address(this), collateralShare);
        (uint256 collateralAmountOut, ) = bentoBox.withdraw(
            collateral,
            address(this),
            address(this),
            0,
            collateralShare
        );

        // swap collateral into asset, and repay asset back with fee into bentoBox(repay flashloan)
        address[] memory _path;
        if (collateral == IERC20(WETH) || asset == IERC20(WETH)) {
            _path = new address[](2);
            _path[0] = address(collateral);
            _path[1] = address(asset);
        } else {
            _path = new address[](3);
            _path[0] = address(collateral);
            _path[1] = WETH;
            _path[2] = address(asset);
        }
        approveUnapproved(address(defaultFeeInfo.uni), address(collateral), collateralAmountOut);
        defaultFeeInfo.uni.swapTokensForExactTokens(
            amount + fee,
            collateralAmountOut, 
            _path, 
            address(this), 
            DEADLINE
        );
        asset.transfer(address(bentoBox), amount + fee);
    }

    struct KashiPairPoll {
        IERC20 collateral;
        IERC20 asset;
        IOracle oracle;
        bytes oracleData;
        uint256 totalCollateralShare;
        uint256 userCollateralShare;
        Rebase totalAsset;
        uint256 userAssetFraction;
        Rebase totalBorrow;
        uint256 userBorrowPart;
        uint256 currentExchangeRate;
        uint256 spotExchangeRate;
        uint256 oracleExchangeRate;
        AccrueInfo accrueInfo;
    }

    /// @dev It is forked from Sushi BoringHelperV1
    function pollKashiPairs(IKashiPairMediumRiskV1[] calldata pairsIn) external view returns (KashiPairPoll[] memory) {
        uint256 len = pairsIn.length;
        KashiPairPoll[] memory pairs = new KashiPairPoll[](len);

        for (uint256 i = 0; i < len; i++) {
            IKashiPairMediumRiskV1 pair = pairsIn[i];
            pairs[i].collateral = pair.collateral();
            pairs[i].asset = pair.asset();
            pairs[i].oracle = pair.oracle();
            pairs[i].oracleData = pair.oracleData();
            pairs[i].totalCollateralShare = pair.totalCollateralShare();
            pairs[i].totalAsset = pair.totalAsset();
            pairs[i].userAssetFraction = pair.balanceOf(address(this));
            pairs[i].totalBorrow = pair.totalBorrow();

            pairs[i].userCollateralShare = pair.userCollateralShare(address(this));
            pairs[i].userBorrowPart = pair.userBorrowPart(address(this));

            pairs[i].currentExchangeRate = pair.exchangeRate();
            (, pairs[i].oracleExchangeRate) = pair.oracle().peek(pair.oracleData());
            pairs[i].spotExchangeRate = pair.oracle().peekSpot(pair.oracleData());
            pairs[i].accrueInfo = pair.accrueInfo();
        }

        return pairs;
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////                                                                    ////
    ////------------------------------Helpers-------------------------------////
    ////                                                                    ////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    function approveUnapproved(
        address target,
        address tokenAddr,
        uint256 amount
    ) internal returns (IERC20 token) {
        token = IERC20(tokenAddr);
        uint256 currentAllowance = token.allowance(address(this), target);
        if (currentAllowance == 0) {
            token.safeApprove(target, MAX_UINT);
        } else if (token.allowance(address(this), target) < amount) {
            token.safeIncreaseAllowance(target, MAX_UINT - currentAllowance);
        }
    }

    function transferApproveUnapproved(
        address target,
        address tokenAddr,
        uint256 amount,
        address user
    ) internal {
        IERC20 token = approveUnapproved(target, tokenAddr, amount);
        token.safeTransferFrom(user, address(this), amount);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier userVerified() {
        require(msg.sender == userVeriForwarder, "selfLiquidate: not userForw");
        _;
    }

    modifier userFeeVerified() {
        require(
            msg.sender == userFeeVeriForwarder,
            "selfLiquidate: not userFeeForw"
        );
        _;
    }

    // It can receive ETH from Kashi, while borrowing asset or removing collateral.
    receive() external payable {}
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Rebase.sol";

interface IBentoBoxV1 {
    function balanceOf(IERC20, address) external view returns (uint256);

    function deposit(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function flashLoan(
        IFlashBorrower borrower,
        address receiver,
        IERC20 token,
        uint256 amount,
        bytes calldata data
    ) external;

    function toAmount(
        IERC20 token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    function toShare(
        IERC20 token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function totals(IERC20) external view returns (Rebase memory totals_);

    function transfer(
        IERC20 token,
        address from,
        address to,
        uint256 share
    ) external;

    function transferMultiple(
        IERC20 token,
        address from,
        address[] calldata tos,
        uint256[] calldata shares
    ) external;

    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    // parts of MasterContractManager
    function registerProtocol() external;

    function nonces(address user) external view returns (uint256);
}

interface IFlashBorrower {
    /// @notice The flashloan callback. `amount` + `fee` needs to repayed to msg.sender before this call returns.
    /// @param sender The address of the invoker of this flashloan.
    /// @param token The address of the token that is loaned.
    /// @param amount of the `token` that is loaned.
    /// @param fee The fee that needs to be paid on top for this loan. Needs to be the same as `token`.
    /// @param data Additional data that was passed to the flashloan function.
    function onFlashLoan(
        address sender,
        IERC20 token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Rebase.sol";
import "./IBentoBoxV1.sol";


struct AccrueInfo {
  uint64 interestPerSecond;
  uint64 lastAccrued;
  uint128 feesEarnedFraction;
}

interface IOracle {
    function get(bytes calldata data) external returns (bool success, uint256 rate);

    function peek(bytes calldata data) external view returns (bool success, uint256 rate);

    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    function symbol(bytes calldata data) external view returns (string memory);

    function name(bytes calldata data) external view returns (string memory);
}


interface IKashiPairMediumRiskV1 {
  function masterContract() external view returns (address);
  function bentoBox() external view returns (IBentoBoxV1);

  function collateral() external view returns (IERC20);
  function asset() external view returns (IERC20);
  function oracleData() external view returns (bytes memory);
  function oracle() external view returns (IOracle);
  
  function totalCollateralShare() external view returns (uint256);
  function totalAsset() external view returns (Rebase memory); // elastic = BentoBox shares held by the KashiPair, base = Total fractions held by asset suppliers
  function totalBorrow() external view returns (Rebase memory); // elastic = Total token amount to be repayed by borrowers, base = Total parts of the debt held by borrowers

  // User balances
  function userCollateralShare(address) external view returns (uint256);
  // userAssetFraction is called balanceOf for ERC20 compatibility (it's in ERC20.sol)
  function userBorrowPart(address) external view returns (uint256);

  function exchangeRate() external view returns (uint256);
  function accrueInfo() external view returns (AccrueInfo memory);

  function accrue() external;

  function balanceOf(address) external view returns (uint256);

  /// @notice Gets the exchange rate. I.e how much collateral to buy 1e18 asset.
  /// This function is supposed to be invoked if needed because Oracle queries can be expensive.
  /// @return updated True if `exchangeRate` was updated.
  /// @return rate The new exchange rate.
  function updateExchangeRate() external returns (bool updated, uint256 rate);

  /// @notice Adds `collateral` from msg.sender to the account `to`.
  /// @param to The receiver of the tokens.
  /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
  /// False if tokens from msg.sender in `bentoBox` should be transferred.
  /// @param share The amount of shares to add for `to`.
  function addCollateral(address to, bool skim, uint256 share) external;

  /// @notice Removes `share` amount of collateral and transfers it to `to`.
  /// @param to The receiver of the shares.
  /// @param share Amount of shares to remove.
  function removeCollateral(address to, uint256 share) external;

  /// @notice Adds assets to the lending pair.
  /// @param to The address of the user to receive the assets.
  /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
  /// False if tokens from msg.sender in `bentoBox` should be transferred.
  /// @param share The amount of shares to add.
  /// @return fraction Total fractions added.
  function addAsset(address to, bool skim, uint256 share) external returns (uint256 fraction);

  /// @notice Removes an asset from msg.sender and transfers it to `to`.
  /// @param to The user that receives the removed assets.
  /// @param fraction The amount/fraction of assets held to remove.
  /// @return share The amount of shares transferred to `to`.
  function removeAsset(address to, uint256 fraction) external returns (uint256 share);

  /// @notice Sender borrows `amount` and transfers it to `to`.
  /// @return part Total part of the debt held by borrowers.
  /// @return share Total amount in shares borrowed.
  function borrow(address to, uint256 amount) external returns (uint256 part, uint256 share);

  /// @notice Repays a loan.
  /// @param to Address of the user this payment should go.
  /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
  /// False if tokens from msg.sender in `bentoBox` should be transferred.
  /// @param part The amount to repay. See `userBorrowPart`.
  /// @return amount The total amount repayed.
  function repay(address to, bool skim, uint256 part) external returns (uint256 amount);

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
  ) external payable returns (uint256 value1, uint256 value2);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "../interfaces/Rebase.sol";

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = elastic * total.base / total.elastic;
            if (roundUp && base * total.elastic / total.base < elastic) {
                base = base + 1;
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
            elastic = base * total.elastic / total.base;
            if (roundUp && elastic * total.base / total.elastic < base) {
                elastic = elastic + 1;
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
        total.elastic = total.elastic + uint128(elastic);
        total.base = total.base + uint128(base);
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
        total.elastic = total.elastic - uint128(elastic);
        total.base = total.base - uint128(base);
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = total.elastic + uint128(elastic);
        total.base = total.base + uint128(base);
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = total.elastic - uint128(elastic);
        total.base = total.base - uint128(base);
        return total;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

struct Rebase {
  uint128 elastic;
  uint128 base;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}