// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {IConfigProvider} from "../../interfaces/IConfigProvider.sol";
import {IReserveOracleGetter} from "../../interfaces/IReserveOracleGetter.sol";
import {INFTOracleGetter} from "../../interfaces/INFTOracleGetter.sol";
import {IShopLoan} from "../../interfaces/IShopLoan.sol";

import {GenericLogic} from "./GenericLogic.sol";
import {ValidationLogic} from "./ValidationLogic.sol";

import {ShopConfiguration} from "../configuration/ShopConfiguration.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {Errors} from "../helpers/Errors.sol";
import {TransferHelper} from "../helpers/TransferHelper.sol";
import {DataTypes} from "../types/DataTypes.sol";

import {IERC20Upgradeable} from "../../openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "../../openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC721Upgradeable} from "../../openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * @title LiquidateLogic library
 * @notice Implements the logic to liquidate feature
 */
library LiquidateLogic {
    using PercentageMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ShopConfiguration for DataTypes.ShopConfiguration;

    /**
     * @dev Emitted when a borrower's loan is auctioned.
     * @param user The address of the user initiating the auction
     * @param reserve The address of the underlying asset of the reserve
     * @param bidPrice The price of the underlying reserve given by the bidder
     * @param nftAsset The address of the underlying NFT used as collateral
     * @param nftTokenId The token id of the underlying NFT used as collateral
     * @param onBehalfOf The address that will be getting the NFT
     * @param loanId The loan ID of the NFT loans
     **/
    event Auction(
        address user,
        address indexed reserve,
        uint256 bidPrice,
        address indexed nftAsset,
        uint256 nftTokenId,
        address onBehalfOf,
        address indexed borrower,
        uint256 loanId
    );

    /**
     * @dev Emitted on redeem()
     * @param user The address of the user initiating the redeem(), providing the funds
     * @param reserve The address of the underlying asset of the reserve
     * @param repayPrincipal The borrow amount repaid
     * @param interest interest
     * @param fee fee
     * @param fineAmount penalty amount
     * @param nftAsset The address of the underlying NFT used as collateral
     * @param nftTokenId The token id of the underlying NFT used as collateral
     * @param loanId The loan ID of the NFT loans
     **/
    event Redeem(
        address user,
        address indexed reserve,
        uint256 repayPrincipal,
        uint256 interest,
        uint256 fee,
        uint256 fineAmount,
        address indexed nftAsset,
        uint256 nftTokenId,
        address indexed borrower,
        uint256 loanId
    );

    /**
     * @dev Emitted when a borrower's loan is liquidated.
     * @param user The address of the user initiating the auction
     * @param reserve The address of the underlying asset of the reserve
     * @param repayAmount The amount of reserve repaid by the liquidator
     * @param remainAmount The amount of reserve received by the borrower
     * @param loanId The loan ID of the NFT loans
     **/
    event Liquidate(
        address user,
        address indexed reserve,
        uint256 repayAmount,
        uint256 remainAmount,
        uint256 feeAmount,
        address indexed nftAsset,
        uint256 nftTokenId,
        address indexed borrower,
        uint256 loanId
    );

    struct AuctionLocalVars {
        address loanAddress;
        address reserveOracle;
        address nftOracle;
        address initiator;
        uint256 loanId;
        uint256 thresholdPrice;
        uint256 liquidatePrice;
        uint256 totalDebt;
        uint256 auctionEndTimestamp;
        uint256 minBidDelta;
    }

    /**
     * @notice Implements the auction feature. Through `auction()`, users auction assets in the protocol.
     * @dev Emits the `Auction()` event.
     * @param reservesData The state of all the reserves
     * @param nftsData The state of all the nfts
     * @param params The additional parameters needed to execute the auction function
     */
    function executeAuction(
        IConfigProvider configProvider,
        mapping(address => DataTypes.ReservesInfo) storage reservesData,
        mapping(address => DataTypes.NftsInfo) storage nftsData,
        DataTypes.ExecuteAuctionParams memory params
    ) external {
        require(
            params.onBehalfOf != address(0),
            Errors.VL_INVALID_ONBEHALFOF_ADDRESS
        );
        AuctionLocalVars memory vars;
        vars.initiator = params.initiator;

        vars.loanAddress = configProvider.loanManager();
        vars.reserveOracle = configProvider.reserveOracle();
        vars.nftOracle = configProvider.nftOracle();

        vars.loanId = params.loanId;
        require(vars.loanId != 0, Errors.LP_NFT_IS_NOT_USED_AS_COLLATERAL);

        DataTypes.LoanData memory loanData = IShopLoan(vars.loanAddress)
            .getLoan(vars.loanId);

        DataTypes.ReservesInfo storage reserveData = reservesData[
            loanData.reserveAsset
        ];
        DataTypes.NftsInfo storage nftData = nftsData[loanData.nftAsset];

        ValidationLogic.validateAuction(
            reserveData,
            nftData,
            loanData,
            params.bidPrice
        );

        (
            vars.totalDebt,
            vars.thresholdPrice,
            vars.liquidatePrice,

        ) = GenericLogic.calculateLoanLiquidatePrice(
            configProvider,
            vars.loanId,
            loanData.reserveAsset,
            reserveData,
            loanData.nftAsset
        );
        // first time bid need to burn debt tokens and transfer reserve to bTokens
        if (loanData.state == DataTypes.LoanState.Active) {
            // loan's accumulated debt must exceed threshold (heath factor below 1.0)
            require(
                vars.totalDebt > vars.thresholdPrice ||
                    loanData.expiredAt < block.timestamp,
                Errors.LP_BORROW_NOT_EXCEED_LIQUIDATION_THRESHOLD_OR_EXPIRED
            );
            // bid price must greater than liquidate price
            require(
                params.bidPrice >= vars.liquidatePrice,
                Errors.LPL_BID_PRICE_LESS_THAN_LIQUIDATION_PRICE
            );
            // bid price must greater than borrow debt
            require(
                params.bidPrice >= vars.totalDebt,
                Errors.LPL_BID_PRICE_LESS_THAN_BORROW
            );
        } else {
            // bid price must greater than borrow debt
            require(
                params.bidPrice >= vars.totalDebt,
                Errors.LPL_BID_PRICE_LESS_THAN_BORROW
            );

            vars.auctionEndTimestamp =
                loanData.bidStartTimestamp +
                configProvider.auctionDuration();
            require(
                block.timestamp <= vars.auctionEndTimestamp,
                Errors.LPL_BID_AUCTION_DURATION_HAS_END
            );

            // bid price must greater than highest bid + delta
            vars.minBidDelta = vars.totalDebt.percentMul(
                configProvider.minBidDeltaPercentage()
            );
            require(
                params.bidPrice >= (loanData.bidPrice + vars.minBidDelta),
                Errors.LPL_BID_PRICE_LESS_THAN_HIGHEST_PRICE
            );
        }

        IShopLoan(vars.loanAddress).auctionLoan(
            vars.initiator,
            vars.loanId,
            params.onBehalfOf,
            params.bidPrice,
            vars.totalDebt
        );

        // lock highest bidder bid price amount to lend pool
        if (
            GenericLogic.isWETHAddress(configProvider, loanData.reserveAsset) &&
            params.isNative
        ) {
            //auction by eth, already convert to weth in factory
            //do nothing
        } else {
            IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(
                vars.initiator,
                address(this),
                params.bidPrice
            );
        }

        // transfer (return back) last bid price amount to previous bidder from lend pool
        if (loanData.bidderAddress != address(0)) {
            if (
                GenericLogic.isWETHAddress(
                    configProvider,
                    loanData.reserveAsset
                )
            ) {
                // transfer (return back eth)  last bid price amount from lend pool to bidder
                TransferHelper.transferWETH2ETH(
                    loanData.reserveAsset,
                    loanData.bidderAddress,
                    loanData.bidPrice
                );
            } else {
                IERC20Upgradeable(loanData.reserveAsset).safeTransfer(
                    loanData.bidderAddress,
                    loanData.bidPrice
                );
            }
        }
        emit Auction(
            vars.initiator,
            loanData.reserveAsset,
            params.bidPrice,
            loanData.nftAsset,
            loanData.nftTokenId,
            params.onBehalfOf,
            loanData.borrower,
            vars.loanId
        );
    }

    struct RedeemLocalVars {
        address initiator;
        address poolLoan;
        address reserveOracle;
        address nftOracle;
        uint256 loanId;
        uint256 borrowAmount;
        uint256 repayAmount;
        uint256 minRepayAmount;
        uint256 maxRepayAmount;
        uint256 bidFine;
        uint256 redeemEndTimestamp;
        uint256 minBidFinePct;
        uint256 minBidFine;
    }

    /**
     * @notice Implements the redeem feature. Through `redeem()`, users redeem assets in the protocol.
     * @dev Emits the `Redeem()` event.
     * @param reservesData The state of all the reserves
     * @param nftsData The state of all the nfts
     * @param params The additional parameters needed to execute the redeem function
     */
    function executeRedeem(
        IConfigProvider configProvider,
        mapping(address => DataTypes.ReservesInfo) storage reservesData,
        mapping(address => DataTypes.NftsInfo) storage nftsData,
        DataTypes.ExecuteRedeemParams memory params
    )
        external
        returns (
            uint256 remainAmount,
            uint256 repayPrincipal,
            uint256 interest,
            uint256 fee
        )
    {
        RedeemLocalVars memory vars;
        vars.initiator = params.initiator;

        vars.poolLoan = configProvider.loanManager();
        vars.reserveOracle = configProvider.reserveOracle();
        vars.nftOracle = configProvider.nftOracle();

        vars.loanId = params.loanId;
        require(vars.loanId != 0, Errors.LP_NFT_IS_NOT_USED_AS_COLLATERAL);

        DataTypes.LoanData memory loanData = IShopLoan(vars.poolLoan).getLoan(
            vars.loanId
        );

        DataTypes.ReservesInfo storage reserveData = reservesData[
            loanData.reserveAsset
        ];
        DataTypes.NftsInfo storage nftData = nftsData[loanData.nftAsset];

        ValidationLogic.validateRedeem(
            reserveData,
            nftData,
            loanData,
            params.amount
        );

        vars.redeemEndTimestamp = (loanData.bidStartTimestamp +
            configProvider.redeemDuration());
        require(
            block.timestamp <= vars.redeemEndTimestamp,
            Errors.LPL_BID_REDEEM_DURATION_HAS_END
        );

        (vars.borrowAmount, , , ) = GenericLogic.calculateLoanLiquidatePrice(
            configProvider,
            vars.loanId,
            loanData.reserveAsset,
            reserveData,
            loanData.nftAsset
        );

        // check bid fine in min & max range
        (, vars.bidFine) = GenericLogic.calculateLoanBidFine(
            configProvider,
            loanData.reserveAsset,
            reserveData,
            loanData.nftAsset,
            loanData,
            vars.poolLoan,
            vars.reserveOracle
        );

        // check bid fine is enough
        require(vars.bidFine == params.bidFine, Errors.LPL_INVALID_BID_FINE);

        // check the minimum debt repay amount, use redeem threshold in config
        vars.repayAmount = params.amount;
        vars.minRepayAmount = vars.borrowAmount.percentMul(
            configProvider.redeemThreshold()
        );
        require(
            vars.repayAmount >= vars.minRepayAmount,
            Errors.LP_AMOUNT_LESS_THAN_REDEEM_THRESHOLD
        );

        // // check the maxinmum debt repay amount, 90%?
        // vars.maxRepayAmount = vars.borrowAmount.percentMul(
        //     PercentageMath.PERCENTAGE_FACTOR - PercentageMath.TEN_PERCENT
        // );
        // require(
        //     vars.repayAmount <= vars.maxRepayAmount,
        //     Errors.LP_AMOUNT_GREATER_THAN_MAX_REPAY
        // );

        (remainAmount, repayPrincipal, interest, fee) = IShopLoan(vars.poolLoan)
            .redeemLoan(vars.initiator, vars.loanId, vars.repayAmount);

        if (
            GenericLogic.isWETHAddress(configProvider, loanData.reserveAsset) &&
            params.isNative
        ) {
            // transfer repayAmount - fee from factory to shopCreator
            IERC20Upgradeable(loanData.reserveAsset).safeTransfer(
                params.shopCreator,
                vars.repayAmount - fee
            );

            if (fee > 0) {
                // transfer platform fee from factory
                IERC20Upgradeable(loanData.reserveAsset).safeTransfer(
                    configProvider.platformFeeReceiver(),
                    fee
                );
            }
        } else {
            // transfer repayAmount - fee from borrower to shopCreator
            IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(
                vars.initiator,
                params.shopCreator,
                vars.repayAmount - fee
            );
            if (fee > 0) {
                // transfer platform fee
                IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(
                    vars.initiator,
                    configProvider.platformFeeReceiver(),
                    fee
                );
            }
        }

        if (loanData.bidderAddress != address(0)) {
            if (
                GenericLogic.isWETHAddress(
                    configProvider,
                    loanData.reserveAsset
                )
            ) {
                // transfer (return back) last bid price amount from lend pool to bidder
                TransferHelper.transferWETH2ETH(
                    loanData.reserveAsset,
                    loanData.bidderAddress,
                    loanData.bidPrice
                );

                if (params.isNative) {
                    // transfer bid penalty fine amount(eth) from contract to borrower
                    TransferHelper.transferWETH2ETH(
                        loanData.reserveAsset,
                        loanData.firstBidderAddress,
                        vars.bidFine
                    );
                } else {
                    // transfer bid penalty fine amount(weth) from borrower this contract
                    IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(
                        vars.initiator,
                        address(this),
                        vars.bidFine
                    );
                    // transfer bid penalty fine amount(eth) from contract to borrower
                    TransferHelper.transferWETH2ETH(
                        loanData.reserveAsset,
                        loanData.firstBidderAddress,
                        vars.bidFine
                    );
                }
            } else {
                // transfer (return back) last bid price amount from lend pool to bidder
                IERC20Upgradeable(loanData.reserveAsset).safeTransfer(
                    loanData.bidderAddress,
                    loanData.bidPrice
                );

                // transfer bid penalty fine amount from borrower to the first bidder
                IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(
                    vars.initiator,
                    loanData.firstBidderAddress,
                    vars.bidFine
                );
            }
        }

        if (remainAmount == 0) {
            // transfer erc721 to borrower
            IERC721Upgradeable(loanData.nftAsset).safeTransferFrom(
                address(this),
                loanData.borrower,
                loanData.nftTokenId
            );
        }

        emit Redeem(
            vars.initiator,
            loanData.reserveAsset,
            repayPrincipal,
            interest,
            fee,
            vars.bidFine,
            loanData.nftAsset,
            loanData.nftTokenId,
            loanData.borrower,
            vars.loanId
        );
    }

    struct LiquidateLocalVars {
        address initiator;
        uint256 loanId;
        uint256 borrowAmount;
        uint256 feeAmount;
        uint256 remainAmount;
        uint256 auctionEndTimestamp;
    }

    /**
     * @notice Implements the liquidate feature. Through `liquidate()`, users liquidate assets in the protocol.
     * @dev Emits the `Liquidate()` event.
     * @param reservesData The state of all the reserves
     * @param nftsData The state of all the nfts
     * @param params The additional parameters needed to execute the liquidate function
     */
    function executeLiquidate(
        IConfigProvider configProvider,
        mapping(address => DataTypes.ReservesInfo) storage reservesData,
        mapping(address => DataTypes.NftsInfo) storage nftsData,
        DataTypes.ExecuteLiquidateParams memory params
    ) external {
        LiquidateLocalVars memory vars;
        vars.initiator = params.initiator;

        vars.loanId = params.loanId;
        require(vars.loanId != 0, Errors.LP_NFT_IS_NOT_USED_AS_COLLATERAL);

        DataTypes.LoanData memory loanData = IShopLoan(
            configProvider.loanManager()
        ).getLoan(vars.loanId);

        DataTypes.ReservesInfo storage reserveData = reservesData[
            loanData.reserveAsset
        ];
        DataTypes.NftsInfo storage nftData = nftsData[loanData.nftAsset];

        ValidationLogic.validateLiquidate(reserveData, nftData, loanData);

        vars.auctionEndTimestamp =
            loanData.bidStartTimestamp +
            configProvider.auctionDuration();
        require(
            block.timestamp > vars.auctionEndTimestamp,
            Errors.LPL_BID_AUCTION_DURATION_NOT_END
        );

        (vars.borrowAmount, , , vars.feeAmount) = GenericLogic
            .calculateLoanLiquidatePrice(
                configProvider,
                vars.loanId,
                loanData.reserveAsset,
                reserveData,
                loanData.nftAsset
            );

        if (loanData.bidPrice > vars.borrowAmount) {
            vars.remainAmount = loanData.bidPrice - vars.borrowAmount;
        }

        IShopLoan(configProvider.loanManager()).liquidateLoan(
            loanData.bidderAddress,
            vars.loanId,
            vars.borrowAmount
        );

        // transfer borrow_amount - fee from shopFactory to shop creator
        if (vars.borrowAmount > 0) {
            IERC20Upgradeable(loanData.reserveAsset).safeTransfer(
                params.shopCreator,
                vars.borrowAmount - vars.feeAmount
            );
        }

        // transfer fee platform receiver
        if (vars.feeAmount > 0) {
            if (configProvider.platformFeeReceiver() != address(this)) {
                IERC20Upgradeable(loanData.reserveAsset).safeTransfer(
                    configProvider.platformFeeReceiver(),
                    vars.feeAmount
                );
            }
        }

        // transfer remain amount to borrower
        if (vars.remainAmount > 0) {
            if (
                GenericLogic.isWETHAddress(
                    configProvider,
                    loanData.reserveAsset
                )
            ) {
                // transfer (return back) last bid price amount from lend pool to bidder
                TransferHelper.transferWETH2ETH(
                    loanData.reserveAsset,
                    loanData.borrower,
                    vars.remainAmount
                );
            } else {
                IERC20Upgradeable(loanData.reserveAsset).safeTransfer(
                    loanData.borrower,
                    vars.remainAmount
                );
            }
        }

        // transfer erc721 to bidder
        IERC721Upgradeable(loanData.nftAsset).safeTransferFrom(
            address(this),
            loanData.bidderAddress,
            loanData.nftTokenId
        );

        emit Liquidate(
            vars.initiator,
            loanData.reserveAsset,
            vars.borrowAmount,
            vars.remainAmount,
            vars.feeAmount,
            loanData.nftAsset,
            loanData.nftTokenId,
            loanData.borrower,
            vars.loanId
        );
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

library DataTypes {
    struct ShopData {
        uint256 id;
        address creator;
    }

    struct ReservesInfo {
        uint8 id;
        address contractAddress;
        bool active;
        string symbol;
        uint256 decimals;
    }
    struct NftsInfo {
        uint8 id;
        bool active;
        address contractAddress;
        string collection;
        uint256 maxSupply;
    }

    enum LoanState {
        // We need a default that is not 'Created' - this is the zero value
        None,
        // The loan data is stored, but not initiated yet.
        Created,
        // The loan has been initialized, funds have been delivered to the borrower and the collateral is held.
        Active,
        // The loan is in auction, higest price liquidator will got chance to claim it.
        Auction,
        // The loan has been repaid, and the collateral has been returned to the borrower. This is a terminal state.
        Repaid,
        // The loan was delinquent and collateral claimed by the liquidator. This is a terminal state.
        Defaulted
    }
    struct LoanData {
        uint256 shopId;
        //the id of the nft loan
        uint256 loanId;
        //the current state of the loan
        LoanState state;
        //address of borrower
        address borrower;
        //address of nft asset token
        address nftAsset;
        //the id of nft token
        uint256 nftTokenId;
        //address of reserve asset token
        address reserveAsset;
        //borrow amount
        uint256 borrowAmount;
        //start time of first bid time
        uint256 bidStartTimestamp;
        //bidder address of higest bid
        address bidderAddress;
        //price of higest bid
        uint256 bidPrice;
        //borrow amount of loan
        uint256 bidBorrowAmount;
        //bidder address of first bid
        address firstBidderAddress;
        uint256 createdAt;
        uint256 updatedAt;
        uint256 lastRepaidAt;
        uint256 expiredAt;
        uint256 interestRate;
    }

    struct GlobalConfiguration {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32: Active
        uint256 data;
    }

    struct ShopConfiguration {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32: Active
        uint256 data;
    }

    struct ExecuteLendPoolStates {
        uint256 pauseStartTime;
        uint256 pauseDurationTime;
    }

    struct ExecuteBorrowParams {
        address initiator;
        address asset;
        uint256 amount;
        address nftAsset;
        uint256 nftTokenId;
        address onBehalfOf;
        bool isNative;
    }
    struct ExecuteBatchBorrowParams {
        address initiator;
        address[] assets;
        uint256[] amounts;
        address[] nftAssets;
        uint256[] nftTokenIds;
        address onBehalfOf;
        bool isNative;
    }
    struct ExecuteRepayParams {
        address initiator;
        uint256 loanId;
        uint256 amount;
        address shopCreator;
        bool isNative;
    }

    struct ExecuteBatchRepayParams {
        address initiator;
        uint256[] loanIds;
        uint256[] amounts;
        address shopCreator;
        bool isNative;
    }
    struct ExecuteAuctionParams {
        address initiator;
        uint256 loanId;
        uint256 bidPrice;
        address onBehalfOf;
        bool isNative;
    }

    struct ExecuteRedeemParams {
        address initiator;
        uint256 loanId;
        uint256 amount;
        uint256 bidFine;
        address shopCreator;
        bool isNative;
    }

    struct ExecuteLiquidateParams {
        address initiator;
        uint256 loanId;
        address shopCreator;
    }

    struct ShopConfigParams {
        address reserveAddress;
        address nftAddress;
        uint256 interestRate;
        uint256 ltvRate;
        bool active;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {Errors} from "../helpers/Errors.sol";

/**
 * @title PercentageMath library
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
    uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
    uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;
    uint256 constant ONE_PERCENT = 1e2; //100, 1%
    uint256 constant TEN_PERCENT = 1e3; //1000, 10%
    uint256 constant ONE_THOUSANDTH_PERCENT = 1e1; //10, 0.1%
    uint256 constant ONE_TEN_THOUSANDTH_PERCENT = 1; //1, 0.01%

    /**
     * @dev Executes a percentage multiplication
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The percentage of value
     **/
    function percentMul(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        if (value == 0 || percentage == 0) {
            return 0;
        }

        require(
            value <= (type(uint256).max - HALF_PERCENT) / percentage,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        );

        return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
    }

    /**
     * @dev Executes a percentage division
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The value divided the percentage
     **/
    function percentDiv(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        require(percentage != 0, Errors.MATH_DIVISION_BY_ZERO);
        uint256 halfPercentage = percentage / 2;

        require(
            value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        );

        return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {PercentageMath} from "../math/PercentageMath.sol";
import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {IShopLoan} from "../../interfaces/IShopLoan.sol";

import {IERC20Upgradeable} from "../../openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "../../openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {ShopConfiguration} from "../configuration/ShopConfiguration.sol";
import {IConfigProvider} from "../../interfaces/IConfigProvider.sol";

/**
 * @title ValidationLogic library
 * @notice Implements functions to validate the different actions of the protocol
 */
library ValidationLogic {
    using PercentageMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ShopConfiguration for DataTypes.ShopConfiguration;
    struct ValidateBorrowLocalVars {
        uint256 currentLtv;
        uint256 currentLiquidationThreshold;
        uint256 amountOfCollateralNeeded;
        uint256 userCollateralBalance;
        uint256 userBorrowBalance;
        uint256 availableLiquidity;
        uint256 healthFactor;
        bool isActive;
        address loanReserveAsset;
        address loanBorrower;
    }

    /**
     * @dev Validates a borrow action
     * @param reserveAsset The address of the asset to borrow
     * @param amount The amount to be borrowed
     * @param reserveData The reserve state from which the user is borrowing
     */
    function validateBorrow(
        IConfigProvider provider,
        DataTypes.ShopConfiguration storage config,
        address user,
        address reserveAsset,
        uint256 amount,
        DataTypes.ReservesInfo storage reserveData,
        address nftAsset,
        address loanAddress,
        uint256 loanId,
        address reserveOracle,
        address nftOracle
    ) external view {
        ValidateBorrowLocalVars memory vars;

        require(amount > 0, Errors.VL_INVALID_AMOUNT);

        if (loanId != 0) {
            DataTypes.LoanData memory loanData = IShopLoan(loanAddress).getLoan(
                loanId
            );

            require(
                loanData.state == DataTypes.LoanState.Active,
                Errors.LPL_INVALID_LOAN_STATE
            );
            require(
                reserveAsset == loanData.reserveAsset,
                Errors.VL_SPECIFIED_RESERVE_NOT_BORROWED_BY_USER
            );
            require(
                user == loanData.borrower,
                Errors.VL_SPECIFIED_LOAN_NOT_BORROWED_BY_USER
            );
        }

        vars.isActive = config.getActive();
        require(vars.isActive, Errors.VL_NO_ACTIVE_RESERVE);

        vars.currentLtv = config.getLtv();
        vars.currentLiquidationThreshold = provider.liquidationThreshold();
        (
            vars.userCollateralBalance,
            vars.userBorrowBalance,
            vars.healthFactor
        ) = GenericLogic.calculateLoanData(
            provider,
            config,
            reserveAsset,
            reserveData,
            nftAsset,
            loanAddress,
            loanId,
            reserveOracle,
            nftOracle
        );

        require(
            vars.userCollateralBalance > 0,
            Errors.VL_COLLATERAL_BALANCE_IS_0
        );

        require(
            vars.healthFactor >
                GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
            Errors.VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
        );

        //add the current already borrowed amount to the amount requested to calculate the total collateral needed.
        //LTV is calculated in percentage
        vars.amountOfCollateralNeeded = (vars.userBorrowBalance + amount)
            .percentDiv(vars.currentLtv);

        require(
            vars.amountOfCollateralNeeded <= vars.userCollateralBalance,
            Errors.VL_COLLATERAL_CANNOT_COVER_NEW_BORROW
        );
    }

    /**
     * @dev Validates a repay action
     * @param reserveData The reserve state from which the user is repaying
     * @param amountSent The amount sent for the repayment. Can be an actual value or uint(-1)
     * @param borrowAmount The borrow balance of the user
     */
    function validateRepay(
        DataTypes.ReservesInfo storage reserveData,
        DataTypes.LoanData memory loanData,
        uint256 amountSent,
        uint256 borrowAmount
    ) external view {
        require(
            reserveData.contractAddress != address(0),
            Errors.VL_INVALID_RESERVE_ADDRESS
        );

        require(amountSent > 0, Errors.VL_INVALID_AMOUNT);

        require(borrowAmount > 0, Errors.VL_NO_DEBT_OF_SELECTED_TYPE);

        require(
            loanData.state == DataTypes.LoanState.Active,
            Errors.LPL_INVALID_LOAN_STATE
        );
    }

    /**
     * @dev Validates the auction action
     * @param reserveData The reserve data of the principal
     * @param nftData The nft data of the underlying nft
     * @param bidPrice Total variable debt balance of the user
     **/
    function validateAuction(
        DataTypes.ReservesInfo storage reserveData,
        DataTypes.NftsInfo storage nftData,
        DataTypes.LoanData memory loanData,
        uint256 bidPrice
    ) internal view {
        require(reserveData.active, Errors.VL_NO_ACTIVE_RESERVE);

        require(nftData.active, Errors.VL_NO_ACTIVE_NFT);

        require(
            loanData.state == DataTypes.LoanState.Active ||
                loanData.state == DataTypes.LoanState.Auction,
            Errors.LPL_INVALID_LOAN_STATE
        );

        require(bidPrice > 0, Errors.VL_INVALID_AMOUNT);
    }

    /**
     * @dev Validates a redeem action
     * @param reserveData The reserve state
     * @param nftData The nft state
     */
    function validateRedeem(
        DataTypes.ReservesInfo storage reserveData,
        DataTypes.NftsInfo storage nftData,
        DataTypes.LoanData memory loanData,
        uint256 amount
    ) external view {
        require(reserveData.active, Errors.VL_NO_ACTIVE_RESERVE);

        require(nftData.active, Errors.VL_NO_ACTIVE_NFT);

        require(
            loanData.state == DataTypes.LoanState.Auction,
            Errors.LPL_INVALID_LOAN_STATE
        );

        require(
            loanData.bidderAddress != address(0),
            Errors.LPL_INVALID_BIDDER_ADDRESS
        );

        require(amount > 0, Errors.VL_INVALID_AMOUNT);
    }

    /**
     * @dev Validates the liquidation action
     * @param reserveData The reserve data of the principal
     * @param nftData The data of the underlying NFT
     * @param loanData The loan data of the underlying NFT
     **/
    function validateLiquidate(
        DataTypes.ReservesInfo storage reserveData,
        DataTypes.NftsInfo storage nftData,
        DataTypes.LoanData memory loanData
    ) internal view {
        // require(
        //     nftData.bNftAddress != address(0),
        //     Errors.LPC_INVALIED_BNFT_ADDRESS
        // );
        // require(
        //     reserveData.bTokenAddress != address(0),
        //     Errors.VL_INVALID_RESERVE_ADDRESS
        // );

        require(reserveData.active, Errors.VL_NO_ACTIVE_RESERVE);

        require(nftData.active, Errors.VL_NO_ACTIVE_NFT);

        require(
            loanData.state == DataTypes.LoanState.Auction,
            Errors.LPL_INVALID_LOAN_STATE
        );

        require(
            loanData.bidderAddress != address(0),
            Errors.LPL_INVALID_BIDDER_ADDRESS
        );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {IShopLoan} from "../../interfaces/IShopLoan.sol";
import {INFTOracleGetter} from "../../interfaces/INFTOracleGetter.sol";
import {IReserveOracleGetter} from "../../interfaces/IReserveOracleGetter.sol";
import {IBNFTRegistry} from "../../interfaces/IBNFTRegistry.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {SafeMath} from "../math/SafeMath.sol";
import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

import {ShopConfiguration} from "../configuration/ShopConfiguration.sol";
import {IConfigProvider} from "../../interfaces/IConfigProvider.sol";

/**
 * @title GenericLogic library
 * @notice Implements protocol-level logic to calculate and validate the state of a user
 */
library GenericLogic {
    using PercentageMath for uint256;
    using SafeMath for uint256;
    using ShopConfiguration for DataTypes.ShopConfiguration;
    uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1 ether;

    struct CalculateLoanDataVars {
        uint256 reserveUnitPrice;
        uint256 reserveUnit;
        uint256 reserveDecimals;
        uint256 healthFactor;
        uint256 totalCollateralInETH;
        uint256 totalCollateralInReserve;
        uint256 totalDebtInETH;
        uint256 totalDebtInReserve;
        uint256 nftLtv;
        uint256 nftLiquidationThreshold;
        address nftAsset;
        uint256 nftTokenId;
        uint256 nftUnitPrice;
    }

    /**
     * @dev Calculates the nft loan data.
     * this includes the total collateral/borrow balances in Reserve,
     * the Loan To Value, the Liquidation Ratio, and the Health factor.
     * @param reserveData Data of the reserve
     * @param reserveOracle The price oracle address of reserve
     * @param nftOracle The price oracle address of nft
     * @return The total collateral and total debt of the loan in Reserve, the ltv, liquidation threshold and the HF
     **/
    function calculateLoanData(
        IConfigProvider provider,
        DataTypes.ShopConfiguration storage config,
        address reserveAddress,
        DataTypes.ReservesInfo storage reserveData,
        address nftAddress,
        address loanAddress,
        uint256 loanId,
        address reserveOracle,
        address nftOracle
    ) internal view returns (uint256, uint256, uint256) {
        CalculateLoanDataVars memory vars;

        vars.nftLtv = config.getLtv();
        vars.nftLiquidationThreshold = provider.liquidationThreshold();

        // calculate total borrow balance for the loan
        if (loanId != 0) {
            (
                vars.totalDebtInETH,
                vars.totalDebtInReserve
            ) = calculateNftDebtData(
                reserveAddress,
                reserveData,
                loanAddress,
                loanId,
                reserveOracle
            );
        }

        // calculate total collateral balance for the nft
        (
            vars.totalCollateralInETH,
            vars.totalCollateralInReserve
        ) = calculateNftCollateralData(
            reserveAddress,
            reserveData,
            nftAddress,
            reserveOracle,
            nftOracle
        );

        // calculate health by borrow and collateral
        vars.healthFactor = calculateHealthFactorFromBalances(
            vars.totalCollateralInReserve,
            vars.totalDebtInReserve,
            vars.nftLiquidationThreshold
        );

        return (
            vars.totalCollateralInReserve,
            vars.totalDebtInReserve,
            vars.healthFactor
        );
    }

    function calculateNftDebtData(
        address reserveAddress,
        DataTypes.ReservesInfo storage reserveData,
        address loanAddress,
        uint256 loanId,
        address reserveOracle
    ) internal view returns (uint256, uint256) {
        CalculateLoanDataVars memory vars;

        // all asset price has converted to ETH based, unit is in WEI (18 decimals)

        vars.reserveDecimals = reserveData.decimals;
        vars.reserveUnit = 10 ** vars.reserveDecimals;

        vars.reserveUnitPrice = IReserveOracleGetter(reserveOracle)
            .getAssetPrice(reserveAddress);

        (, uint256 borrowAmount, , uint256 interest, uint256 fee) = IShopLoan(
            loanAddress
        ).totalDebtInReserve(loanId, 0);
        vars.totalDebtInReserve = borrowAmount + interest + fee;
        vars.totalDebtInETH =
            (vars.totalDebtInReserve * vars.reserveUnitPrice) /
            vars.reserveUnit;

        return (vars.totalDebtInETH, vars.totalDebtInReserve);
    }

    function calculateNftCollateralData(
        address reserveAddress,
        DataTypes.ReservesInfo storage reserveData,
        address nftAddress,
        address reserveOracle,
        address nftOracle
    ) internal view returns (uint256, uint256) {
        CalculateLoanDataVars memory vars;

        vars.nftUnitPrice = INFTOracleGetter(nftOracle).getAssetPrice(
            nftAddress
        );
        vars.totalCollateralInETH = vars.nftUnitPrice;

        if (reserveAddress != address(0)) {
            vars.reserveDecimals = reserveData.decimals;
            vars.reserveUnit = 10 ** vars.reserveDecimals;

            vars.reserveUnitPrice = IReserveOracleGetter(reserveOracle)
                .getAssetPrice(reserveAddress);

            vars.totalCollateralInReserve =
                (vars.totalCollateralInETH * vars.reserveUnit) /
                vars.reserveUnitPrice;
        }

        return (vars.totalCollateralInETH, vars.totalCollateralInReserve);
    }

    /**
     * @dev Calculates the health factor from the corresponding balances
     * @param totalCollateral The total collateral
     * @param totalDebt The total debt
     * @param liquidationThreshold The avg liquidation threshold
     * @return The health factor calculated from the balances provided
     **/
    function calculateHealthFactorFromBalances(
        uint256 totalCollateral,
        uint256 totalDebt,
        uint256 liquidationThreshold
    ) internal pure returns (uint256) {
        if (totalDebt == 0) return type(uint256).max;

        return (totalCollateral.percentMul(liquidationThreshold)) / totalDebt;
    }

    struct CalculateInterestInfoVars {
        uint256 lastRepaidAt;
        uint256 borrowAmount;
        uint256 interestRate;
        uint256 repayAmount;
        uint256 platformFeeRate;
        uint256 interestDuration;
    }

    function calculateInterestInfo(
        CalculateInterestInfoVars memory vars
    )
        internal
        view
        returns (
            uint256 totalDebt,
            uint256 repayPrincipal,
            uint256 interest,
            uint256 platformFee
        )
    {
        if (vars.interestDuration == 0) {
            vars.interestDuration = 86400; //1day
        }
        uint256 sofarLoanDay = (
            (block.timestamp - vars.lastRepaidAt).div(vars.interestDuration)
        ).add(1);
        interest = vars
            .borrowAmount
            .mul(vars.interestRate)
            .mul(sofarLoanDay)
            .div(uint256(10000))
            .div(uint256(365 * 86400) / vars.interestDuration);
        platformFee = vars.borrowAmount.mul(vars.platformFeeRate).div(10000);
        if (vars.repayAmount > 0) {
            require(
                vars.repayAmount > interest,
                Errors.LP_REPAY_AMOUNT_NOT_ENOUGH
            );
            repayPrincipal = vars.repayAmount - interest;
            if (repayPrincipal > vars.borrowAmount.add(platformFee)) {
                repayPrincipal = vars.borrowAmount;
            } else {
                repayPrincipal = repayPrincipal.mul(10000).div(
                    10000 + vars.platformFeeRate
                );
                platformFee = repayPrincipal.mul(vars.platformFeeRate).div(
                    10000
                );
            }
        }
        totalDebt = vars.borrowAmount.add(interest).add(platformFee);
        return (totalDebt, repayPrincipal, interest, platformFee);
    }

    struct CalcLiquidatePriceLocalVars {
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
        uint256 nftPriceInETH;
        uint256 nftPriceInReserve;
        uint256 reserveDecimals;
        uint256 reservePriceInETH;
        uint256 thresholdPrice;
        uint256 liquidatePrice;
        uint256 totalDebt;
        uint256 repayPrincipal;
        uint256 interest;
        uint256 platformFee;
    }

    function calculateLoanLiquidatePrice(
        IConfigProvider provider,
        uint256 loanId,
        address reserveAsset,
        DataTypes.ReservesInfo storage reserveData,
        address nftAsset
    ) internal view returns (uint256, uint256, uint256, uint256) {
        CalcLiquidatePriceLocalVars memory vars;

        /*
         * 0                   CR                  LH                  100
         * |___________________|___________________|___________________|
         *  <       Borrowing with Interest        <
         * CR: Callteral Ratio;
         * LH: Liquidate Threshold;
         * Liquidate Trigger: Borrowing with Interest > thresholdPrice;
         * Liquidate Price: (100% - BonusRatio) * NFT Price;
         */

        vars.reserveDecimals = reserveData.decimals;

        // TODO base theo pawnshop
        DataTypes.LoanData memory loan = IShopLoan(provider.loanManager())
            .getLoan(loanId);
        (
            vars.totalDebt,
            ,
            vars.interest,
            vars.platformFee
        ) = calculateInterestInfo(
            CalculateInterestInfoVars({
                lastRepaidAt: loan.lastRepaidAt,
                borrowAmount: loan.borrowAmount,
                interestRate: loan.interestRate,
                repayAmount: 0,
                platformFeeRate: provider.platformFeePercentage(),
                interestDuration: provider.interestDuration()
            })
        );

        //does not calculate interest after auction
        if (
            loan.state == DataTypes.LoanState.Auction &&
            loan.bidBorrowAmount > 0
        ) {
            vars.totalDebt = loan.bidBorrowAmount;
        }

        vars.liquidationThreshold = provider.liquidationThreshold();
        vars.liquidationBonus = provider.liquidationBonus();

        require(
            vars.liquidationThreshold > 0,
            Errors.LP_INVALID_LIQUIDATION_THRESHOLD
        );

        vars.nftPriceInETH = INFTOracleGetter(provider.nftOracle())
            .getAssetPrice(nftAsset);
        vars.reservePriceInETH = IReserveOracleGetter(provider.reserveOracle())
            .getAssetPrice(reserveAsset);

        vars.nftPriceInReserve =
            ((10 ** vars.reserveDecimals) * vars.nftPriceInETH) /
            vars.reservePriceInETH;

        vars.thresholdPrice = vars.nftPriceInReserve.percentMul(
            vars.liquidationThreshold
        );

        vars.liquidatePrice = vars.nftPriceInReserve.percentMul(
            PercentageMath.PERCENTAGE_FACTOR - vars.liquidationBonus
        );

        return (
            vars.totalDebt,
            vars.thresholdPrice,
            vars.liquidatePrice,
            vars.platformFee
        );
    }

    struct CalcLoanBidFineLocalVars {
        uint256 reserveDecimals;
        uint256 reservePriceInETH;
        uint256 baseBidFineInReserve;
        uint256 minBidFinePct;
        uint256 minBidFineInReserve;
        uint256 bidFineInReserve;
        uint256 debtAmount;
    }

    function calculateLoanBidFine(
        IConfigProvider provider,
        address reserveAsset,
        DataTypes.ReservesInfo storage reserveData,
        address nftAsset,
        DataTypes.LoanData memory loanData,
        address poolLoan,
        address reserveOracle
    ) internal view returns (uint256, uint256) {
        nftAsset;

        if (loanData.bidPrice == 0) {
            return (0, 0);
        }

        CalcLoanBidFineLocalVars memory vars;

        vars.reserveDecimals = reserveData.decimals;
        vars.reservePriceInETH = IReserveOracleGetter(reserveOracle)
            .getAssetPrice(reserveAsset);
        vars.baseBidFineInReserve =
            (1 ether * 10 ** vars.reserveDecimals) /
            vars.reservePriceInETH;

        vars.minBidFinePct = provider.minBidFine();
        vars.minBidFineInReserve = vars.baseBidFineInReserve.percentMul(
            vars.minBidFinePct
        );

        (, uint256 borrowAmount, , uint256 interest, uint256 fee) = IShopLoan(
            poolLoan
        ).totalDebtInReserve(loanData.loanId, 0);

        vars.debtAmount = borrowAmount + interest + fee;

        vars.bidFineInReserve = vars.debtAmount.percentMul(
            provider.redeemFine()
        );
        if (vars.bidFineInReserve < vars.minBidFineInReserve) {
            vars.bidFineInReserve = vars.minBidFineInReserve;
        }

        return (vars.minBidFineInReserve, vars.bidFineInReserve);
    }

    function calculateLoanAuctionEndTimestamp(
        IConfigProvider provider,
        uint256 bidStartTimestamp
    )
        internal
        view
        returns (uint256 auctionEndTimestamp, uint256 redeemEndTimestamp)
    {
        auctionEndTimestamp = bidStartTimestamp + provider.auctionDuration();

        redeemEndTimestamp = bidStartTimestamp + provider.redeemDuration();
    }

    /**
     * @dev Calculates the equivalent amount that an user can borrow, depending on the available collateral and the
     * average Loan To Value
     * @param totalCollateral The total collateral
     * @param totalDebt The total borrow balance
     * @param ltv The average loan to value
     * @return the amount available to borrow for the user
     **/

    function calculateAvailableBorrows(
        uint256 totalCollateral,
        uint256 totalDebt,
        uint256 ltv
    ) internal pure returns (uint256) {
        uint256 availableBorrows = totalCollateral.percentMul(ltv);

        if (availableBorrows < totalDebt) {
            return 0;
        }

        availableBorrows = availableBorrows - totalDebt;
        return availableBorrows;
    }

    function getBNftAddress(
        IConfigProvider provider,
        address nftAsset
    ) internal view returns (address bNftAddress) {
        IBNFTRegistry bnftRegistry = IBNFTRegistry(provider.bnftRegistry());
        bNftAddress = bnftRegistry.getBNFTAddresses(nftAsset);
        return bNftAddress;
    }

    function isWETHAddress(
        IConfigProvider provider,
        address asset
    ) internal view returns (bool) {
        return asset == IReserveOracleGetter(provider.reserveOracle()).weth();
    }

    function getWETHAddress(
        IConfigProvider provider
    ) internal view returns (address) {
        return IReserveOracleGetter(provider.reserveOracle()).weth();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import {IWETH} from "./../../interfaces/IWETH.sol";

library TransferHelper {
    //
    function safeTransferERC20(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)'))) -> 0xa9059cbb
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "safeTransferERC20: transfer failed"
        );
    }

    //
    function safeTransferETH(address weth, address to, uint256 value) internal {
        (bool success, ) = address(to).call{value: value, gas: 30000}("");
        if (!success) {
            IWETH(weth).deposit{value: value}();
            safeTransferERC20(weth, to, value);
        }
    }

    function convertETHToWETH(address weth, uint256 value) internal {
        IWETH(weth).deposit{value: value}();
    }

    // Will attempt to transfer ETH, but will transfer WETH instead if it fails.
    function transferWETH2ETH(
        address weth,
        address to,
        uint256 value
    ) internal {
        if (value > 0) {
            IWETH(weth).withdraw(value);
            safeTransferETH(weth, to, value);
        }
    }

    // convert eth to weth and transfer to toAddress
    function transferWETHFromETH(
        address weth,
        address toAddress,
        uint256 value
    ) internal {
        if (value > 0) {
            IWETH(weth).deposit{value: value}();
            safeTransferERC20(weth, toAddress, value);
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @title Errors library
 */
library Errors {
    enum ReturnCode {
        SUCCESS,
        FAILED
    }

    string public constant SUCCESS = "0";

    //common errors
    string public constant CALLER_NOT_POOL_ADMIN = "100"; // 'The caller must be the pool admin'
    string public constant CALLER_NOT_ADDRESS_PROVIDER = "101";
    string public constant INVALID_FROM_BALANCE_AFTER_TRANSFER = "102";
    string public constant INVALID_TO_BALANCE_AFTER_TRANSFER = "103";
    string public constant CALLER_NOT_ONBEHALFOF_OR_IN_WHITELIST = "104";

    //math library erros
    string public constant MATH_MULTIPLICATION_OVERFLOW = "200";
    string public constant MATH_ADDITION_OVERFLOW = "201";
    string public constant MATH_DIVISION_BY_ZERO = "202";

    //validation & check errors
    string public constant VL_INVALID_AMOUNT = "301"; // 'Amount must be greater than 0'
    string public constant VL_NO_ACTIVE_RESERVE = "302"; // 'Action requires an active reserve'
    string public constant VL_RESERVE_FROZEN = "303"; // 'Action cannot be performed because the reserve is frozen'
    string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = "304"; // 'User cannot withdraw more than the available balance'
    string public constant VL_BORROWING_NOT_ENABLED = "305"; // 'Borrowing is not enabled'
    string public constant VL_COLLATERAL_BALANCE_IS_0 = "306"; // 'The collateral balance is 0'
    string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD =
        "307"; // 'Health factor is lesser than the liquidation threshold'
    string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = "308"; // 'There is not enough collateral to cover a new borrow'
    string public constant VL_NO_DEBT_OF_SELECTED_TYPE = "309"; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
    string public constant VL_NO_ACTIVE_NFT = "310";
    string public constant VL_NFT_FROZEN = "311";
    string public constant VL_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "312"; // 'User did not borrow the specified currency'
    string public constant VL_INVALID_HEALTH_FACTOR = "313";
    string public constant VL_INVALID_ONBEHALFOF_ADDRESS = "314";
    string public constant VL_INVALID_TARGET_ADDRESS = "315";
    string public constant VL_INVALID_RESERVE_ADDRESS = "316";
    string public constant VL_SPECIFIED_LOAN_NOT_BORROWED_BY_USER = "317";
    string public constant VL_SPECIFIED_RESERVE_NOT_BORROWED_BY_USER = "318";
    string public constant VL_HEALTH_FACTOR_HIGHER_THAN_LIQUIDATION_THRESHOLD =
        "319";
    string public constant VL_CONFIGURATION_LTV_RATE_INVALID = "320";
    string public constant VL_CONFIGURATION_INTEREST_RATE_INVALID = "321";

    //lend pool errors
    string public constant LP_CALLER_NOT_LEND_POOL_CONFIGURATOR = "400"; // 'The caller of the function is not the lending pool configurator'
    string public constant LP_IS_PAUSED = "401"; // 'Pool is paused'
    string public constant LP_NO_MORE_RESERVES_ALLOWED = "402";
    string public constant LP_NOT_CONTRACT = "403";
    string
        public constant LP_BORROW_NOT_EXCEED_LIQUIDATION_THRESHOLD_OR_EXPIRED =
        "404";
    string public constant LP_BORROW_IS_EXCEED_LIQUIDATION_PRICE = "405";
    string public constant LP_NO_MORE_NFTS_ALLOWED = "406";
    string public constant LP_INVALIED_USER_NFT_AMOUNT = "407";
    string public constant LP_INCONSISTENT_PARAMS = "408";
    string public constant LP_NFT_IS_NOT_USED_AS_COLLATERAL = "409";
    string public constant LP_CALLER_MUST_BE_AN_BTOKEN = "410";
    string public constant LP_INVALIED_NFT_AMOUNT = "411";
    string public constant LP_NFT_HAS_USED_AS_COLLATERAL = "412";
    string public constant LP_DELEGATE_CALL_FAILED = "413";
    string public constant LP_AMOUNT_LESS_THAN_EXTRA_DEBT = "414";
    string public constant LP_AMOUNT_LESS_THAN_REDEEM_THRESHOLD = "415";
    string public constant LP_AMOUNT_GREATER_THAN_MAX_REPAY = "416";
    string public constant LP_NFT_TOKEN_ID_EXCEED_MAX_LIMIT = "417";
    string public constant LP_NFT_SUPPLY_NUM_EXCEED_MAX_LIMIT = "418";
    string public constant LP_CALLER_NOT_SHOP_CREATOR = "419";
    string public constant LP_INVALID_LIQUIDATION_THRESHOLD = "420";
    string public constant LP_REPAY_AMOUNT_NOT_ENOUGH = "421";
    string public constant LP_NFT_ALREADY_INITIALIZED = "422"; // 'Nft has already been initialized'
    string public constant LP_INVALID_ETH_AMOUNT = "423";
    string public constant LP_INVALID_REPAY_AMOUNT = "424";

    //lend pool loan errors
    string public constant LPL_INVALID_LOAN_STATE = "480";
    string public constant LPL_INVALID_LOAN_AMOUNT = "481";
    string public constant LPL_INVALID_TAKEN_AMOUNT = "482";
    string public constant LPL_AMOUNT_OVERFLOW = "483";
    string public constant LPL_BID_PRICE_LESS_THAN_LIQUIDATION_PRICE = "484";
    string public constant LPL_BID_PRICE_LESS_THAN_HIGHEST_PRICE = "485";
    string public constant LPL_BID_REDEEM_DURATION_HAS_END = "486";
    string public constant LPL_BID_USER_NOT_SAME = "487";
    string public constant LPL_BID_REPAY_AMOUNT_NOT_ENOUGH = "488";
    string public constant LPL_BID_AUCTION_DURATION_HAS_END = "489";
    string public constant LPL_BID_AUCTION_DURATION_NOT_END = "490";
    string public constant LPL_BID_PRICE_LESS_THAN_BORROW = "491";
    string public constant LPL_INVALID_BIDDER_ADDRESS = "492";
    string public constant LPL_AMOUNT_LESS_THAN_BID_FINE = "493";
    string public constant LPL_INVALID_BID_FINE = "494";

    //common token errors
    string public constant CT_CALLER_MUST_BE_LEND_POOL = "500"; // 'The caller of this function must be a lending pool'
    string public constant CT_INVALID_MINT_AMOUNT = "501"; //invalid amount to mint
    string public constant CT_INVALID_BURN_AMOUNT = "502"; //invalid amount to burn
    string public constant CT_BORROW_ALLOWANCE_NOT_ENOUGH = "503";

    //reserve logic errors
    string public constant RL_RESERVE_ALREADY_INITIALIZED = "601"; // 'Reserve has already been initialized'
    string public constant RL_LIQUIDITY_INDEX_OVERFLOW = "602"; //  Liquidity index overflows uint128
    string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = "603"; //  Variable borrow index overflows uint128
    string public constant RL_LIQUIDITY_RATE_OVERFLOW = "604"; //  Liquidity rate overflows uint128
    string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = "605"; //  Variable borrow rate overflows uint128

    //configure errors
    string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = "700"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_CONFIGURATION = "701"; // 'Invalid risk parameters for the reserve'
    string public constant LPC_CALLER_NOT_EMERGENCY_ADMIN = "702"; // 'The caller must be the emergency admin'
    string public constant LPC_INVALIED_BNFT_ADDRESS = "703";
    string public constant LPC_INVALIED_LOAN_ADDRESS = "704";
    string public constant LPC_NFT_LIQUIDITY_NOT_0 = "705";

    //reserve config errors
    string public constant RC_INVALID_LTV = "730";
    string public constant RC_INVALID_LIQ_THRESHOLD = "731";
    string public constant RC_INVALID_LIQ_BONUS = "732";
    string public constant RC_INVALID_DECIMALS = "733";
    string public constant RC_INVALID_RESERVE_FACTOR = "734";
    string public constant RC_INVALID_REDEEM_DURATION = "735";
    string public constant RC_INVALID_AUCTION_DURATION = "736";
    string public constant RC_INVALID_REDEEM_FINE = "737";
    string public constant RC_INVALID_REDEEM_THRESHOLD = "738";
    string public constant RC_INVALID_MIN_BID_FINE = "739";
    string public constant RC_INVALID_MAX_BID_FINE = "740";
    string public constant RC_NOT_ACTIVE = "741";
    string public constant RC_INVALID_INTEREST_RATE = "742";

    //address provider erros
    string public constant LPAPR_PROVIDER_NOT_REGISTERED = "760"; // 'Provider is not registered'
    string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = "761";
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

library ShopConfiguration {
    uint256 constant LTV_MASK =                   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
    uint256 constant ACTIVE_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant INTEREST_RATE_MASK =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

    /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
    uint256 constant IS_ACTIVE_START_BIT_POSITION = 56;
    uint256 constant INTEREST_RATE_POSITION = 128;

    uint256 constant MAX_VALID_LTV = 8000;
    uint256 constant MAX_VALID_INTEREST_RATE = 65535;

    /**
     * @dev Sets the Loan to Value of the NFT
     * @param self The NFT configuration
     * @param ltv the new ltv
     **/
    function setLtv(DataTypes.ShopConfiguration memory self, uint256 ltv)
        internal
        pure
    {
        require(ltv <= MAX_VALID_LTV, Errors.RC_INVALID_LTV);

        self.data = (self.data & LTV_MASK) | ltv;
    }

    /**
     * @dev Gets the Loan to Value of the NFT
     * @param self The NFT configuration
     * @return The loan to value
     **/
    function getLtv(DataTypes.ShopConfiguration storage self)
        internal
        view
        returns (uint256)
    {
        return self.data & ~LTV_MASK;
    }

    /**
     * @dev Sets the active state of the NFT
     * @param self The NFT configuration
     * @param active The active state
     **/
    function setActive(DataTypes.ShopConfiguration memory self, bool active)
        internal
        pure
    {
        self.data =
            (self.data & ACTIVE_MASK) |
            (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
    }

    /**
     * @dev Gets the active state of the NFT
     * @param self The NFT configuration
     * @return The active state
     **/
    function getActive(DataTypes.ShopConfiguration storage self)
        internal
        view
        returns (bool)
    {
        return (self.data & ~ACTIVE_MASK) != 0;
    }

    /**
     * @dev Sets the min & max threshold of the NFT
     * @param self The NFT configuration
     * @param interestRate The interestRate
     **/
    function setInterestRate(
        DataTypes.ShopConfiguration memory self,
        uint256 interestRate
    ) internal pure {
        require(
            interestRate <= MAX_VALID_INTEREST_RATE,
            Errors.RC_INVALID_INTEREST_RATE
        );

        self.data =
            (self.data & INTEREST_RATE_MASK) |
            (interestRate << INTEREST_RATE_POSITION);
    }

    /**
     * @dev Gets interate of the NFT
     * @param self The NFT configuration
     * @return The interest
     **/
    function getInterestRate(DataTypes.ShopConfiguration storage self)
        internal
        view
        returns (uint256)
    {
        return ((self.data & ~INTEREST_RATE_MASK) >> INTEREST_RATE_POSITION);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;

    function approve(address guy, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {DataTypes} from "../libraries/types/DataTypes.sol";

interface IShopLoan {
    /**
     * @dev Emitted on initialization to share location of dependent notes
     * @param pool The address of the associated lend pool
     */
    event Initialized(address indexed pool);

    /**
     * @dev Emitted when a loan is created
     * @param user The address initiating the action
     */
    event LoanCreated(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        address reserveAsset,
        uint256 amount
    );

    /**
     * @dev Emitted when a loan is updated
     * @param user The address initiating the action
     */
    event LoanPartialRepay(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        address reserveAsset,
        uint256 repayAmount,
        uint256 currentInterest
    );

    /**
     * @dev Emitted when a loan is repaid by the borrower
     * @param user The address initiating the action
     */
    event LoanRepaid(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        address reserveAsset,
        uint256 amount
    );

    /**
     * @dev Emitted when a loan is auction by the liquidator
     * @param user The address initiating the action
     */
    event LoanAuctioned(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        uint256 amount,
        address bidder,
        uint256 price,
        address previousBidder,
        uint256 previousPrice
    );

    /**
     * @dev Emitted when a loan is redeemed
     * @param user The address initiating the action
     */
    event LoanRedeemed(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        address reserveAsset,
        uint256 amountTaken
    );

    /**
     * @dev Emitted when a loan is liquidate by the liquidator
     * @param user The address initiating the action
     */
    event LoanLiquidated(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        address reserveAsset,
        uint256 amount
    );

    function initNft(address nftAsset) external;

    /**
     * @dev Create store a loan object with some params
     * @param initiator The address of the user initiating the borrow
     */
    function createLoan(
        uint256 shopId,
        address initiator,
        address nftAsset,
        uint256 nftTokenId,
        address reserveAsset,
        uint256 amount,
        uint256 interestRate
    ) external returns (uint256);

    /**
     * @dev Update the given loan with some params
     *
     * Requirements:
     *  - The caller must be a holder of the loan
     *  - The loan must be in state Active
     * @param initiator The address of the user initiating the borrow
     */
    function partialRepayLoan(
        address initiator,
        uint256 loanId,
        uint256 repayAmount
    ) external;

    /**
     * @dev Repay the given loan
     *
     * Requirements:
     *  - The caller must be a holder of the loan
     *  - The caller must send in principal + interest
     *  - The loan must be in state Active
     *
     * @param initiator The address of the user initiating the repay
     * @param loanId The loan getting burned
     */
    function repayLoan(
        address initiator,
        uint256 loanId,
        uint256 amount
    ) external;

    /**
     * @dev Auction the given loan
     *
     * Requirements:
     *  - The price must be greater than current highest price
     *  - The loan must be in state Active or Auction
     *
     * @param initiator The address of the user initiating the auction
     * @param loanId The loan getting auctioned
     * @param bidPrice The bid price of this auction
     */
    function auctionLoan(
        address initiator,
        uint256 loanId,
        address onBehalfOf,
        uint256 bidPrice,
        uint256 borrowAmount
    ) external;

    // /**
    //  * @dev Redeem the given loan with some params
    //  *
    //  * Requirements:
    //  *  - The caller must be a holder of the loan
    //  *  - The loan must be in state Auction
    //  * @param initiator The address of the user initiating the borrow
    //  */
    function redeemLoan(
        address initiator,
        uint256 loanId,
        uint256 amountTaken
    )
        external
        returns (
            uint256 remainAmount,
            uint256 repayPrincipal,
            uint256 interest,
            uint256 fee
        );

    /**
     * @dev Liquidate the given loan
     *
     * Requirements:
     *  - The caller must send in principal + interest
     *  - The loan must be in state Active
     *
     * @param initiator The address of the user initiating the auction
     * @param loanId The loan getting burned
     */
    function liquidateLoan(
        address initiator,
        uint256 loanId,
        uint256 borrowAmount
    ) external;

    function borrowerOf(uint256 loanId) external view returns (address);

    function getCollateralLoanId(address nftAsset, uint256 nftTokenId)
        external
        view
        returns (uint256);

    function getLoan(uint256 loanId)
        external
        view
        returns (DataTypes.LoanData memory loanData);

    function totalDebtInReserve(uint256 loanId, uint256 repayAmount)
        external
        view
        returns (
            address asset,
            uint256 borrowAmount,
            uint256 repayPrincipal,
            uint256 interest,
            uint256 fee
        );

    function getLoanHighestBid(uint256 loanId)
        external
        view
        returns (address, uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/************
@title IReserveOracleGetter interface
@notice Interface for getting Reserve price oracle.*/
interface IReserveOracleGetter {
    // @returns address of WETH
    function weth() external view returns (address);

    /* CAUTION: Price uint is ETH based (WEI, 18 decimals) */
    /***********
    @dev returns the asset price in ETH
     */
    function getAssetPrice(address asset) external view returns (uint256);

    // get twap price depending on _period
    function getTwapPrice(
        address _priceFeedKey,
        uint256 _interval
    ) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/************
@title INFTOracleGetter interface
@notice Interface for getting NFT price oracle.*/
interface INFTOracleGetter {
    /* CAUTION: Price uint is ETH based (WEI, 18 decimals) */
    /***********
    @dev returns the asset price in ETH
     */
    function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @title IConfigProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 **/
interface IConfigProvider {
    function owner() external view returns (address);

    /// @notice nftOracle
    function nftOracle() external view returns (address);

    /// @notice reserveOracle
    function reserveOracle() external view returns (address);

    function userClaimRegistry() external view returns (address);

    function bnftRegistry() external view returns (address);

    function shopFactory() external view returns (address);

    function loanManager() external view returns (address);

    //tien phat toi thieu theo % reserve price (ex : vay eth, setup 2% => phat 1*2/100 = 0.02 eth, 1 la ty le giua dong vay voi ETH) khi redeem nft bi auction
    function minBidFine() external view returns (uint256);

    //tien phat toi thieu theo % khoan vay khi redeem nft bi auction ex: vay 10 ETH, setup 5% => phat 10*5/100=0.5 ETH
    function redeemFine() external view returns (uint256);

    //thoi gian co the redeem nft sau khi bi auction tinh = hour
    function redeemDuration() external view returns (uint256);

    function auctionDuration() external view returns (uint256);

    function liquidationThreshold() external view returns (uint256);

    //% giam gia khi thanh ly tai san
    function liquidationBonus() external view returns (uint256);

    function redeemThreshold() external view returns (uint256);

    function maxLoanDuration() external view returns (uint256);

    function platformFeeReceiver() external view returns (address);

    //platform fee tinh theo pricipal
    function platformFeePercentage() external view returns (uint256);

    function interestDuration() external view returns (uint256);

    function minBidDeltaPercentage() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IBNFTRegistry {
    event Initialized(string namePrefix, string symbolPrefix);
    event BNFTCreated(
        address indexed nftAsset,
        address bNftProxy,
        uint256 totals
    );
    event CustomeSymbolsAdded(address[] nftAssets, string[] symbols);
    event ClaimAdminUpdated(address oldAdmin, address newAdmin);

    function getBNFTAddresses(address nftAsset)
        external
        view
        returns (address bNftProxy);

    function getBNFTAddressesByIndex(uint16 index)
        external
        view
        returns (address bNftProxy);

    function getBNFTAssetList() external view returns (address[] memory);

    function allBNFTAssetLength() external view returns (uint256);

    function initialize(
        address genericImpl,
        string memory namePrefix_,
        string memory symbolPrefix_
    ) external;

    /**
     * @dev Create bNFT proxy and implement, then initialize it
     * @param nftAsset The address of the underlying asset of the BNFT
     **/
    function createBNFT(address nftAsset) external returns (address bNftProxy);

    /**
     * @dev Adding custom symbol for some special NFTs like CryptoPunks
     * @param nftAssets_ The addresses of the NFTs
     * @param symbols_ The custom symbols of the NFTs
     **/
    function addCustomeSymbols(
        address[] memory nftAssets_,
        string[] memory symbols_
    ) external;
}