// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

// Prettier ignore to prevent buidler flatter bug
// prettier-ignore

import "../openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {IConfigProvider} from "../interfaces/IConfigProvider.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {IShop} from "../interfaces/IShop.sol";
import {IShopLoan} from "../interfaces/IShopLoan.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {ShopFactoryStorage} from "./ShopFactoryStorage.sol";
import {ERC721HolderUpgradeable} from "../openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import {IERC721Upgradeable} from "../openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {ERC20} from "../openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ShopConfiguration} from "../libraries/configuration/ShopConfiguration.sol";
import {BorrowLogic} from "../libraries/logic/BorrowLogic.sol";
import {LiquidateLogic} from "../libraries/logic/LiquidateLogic.sol";
import {GenericLogic} from "../libraries/logic/GenericLogic.sol";
import {Constants} from "../libraries/configuration/Constants.sol";
import {TransferHelper} from "../libraries/helpers/TransferHelper.sol";
import {IReserveOracleGetter} from "../interfaces/IReserveOracleGetter.sol";

contract ShopFactory is
    IShop,
    ShopFactoryStorage,
    ContextUpgradeable,
    ERC721HolderUpgradeable
{
    IConfigProvider public provider;

    using ShopConfiguration for DataTypes.ShopConfiguration;

    // ======== Constructor =========
    constructor() {}

    receive() external payable {}

    function initialize(IConfigProvider _provider) external initializer {
        __Context_init();
        __ERC721Holder_init();
        // provider
        provider = _provider;
    }

    // CONFIG FUNCTIONS

    // SHOP FUNCTIONS

    function create() external returns (uint256) {
        return _create(_msgSender());
    }

    function _create(address creator) internal returns (uint256) {
        require(creators[creator] == 0, "msg sender is created");
        shopCount++;
        //
        uint256 shopId = shopCount;

        DataTypes.ShopData memory shop = DataTypes.ShopData({
            id: shopCount,
            creator: creator
        });
        shops[shopId] = shop;
        creators[creator] = shopId;

        emit Created(creator, shopId);

        return shopId;
    }

    function shopOf(address creator) public view returns (uint256) {
        return creators[creator];
    }

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

    modifier whenNotPaused() {
        _whenNotPaused();
        _;
    }

    modifier onlyFactoryConfigurator() {
        _onlyFactoryConfigurator();
        _;
    }

    function _whenNotPaused() internal view {
        require(!_paused, Errors.LP_IS_PAUSED);
    }

    function _onlyFactoryConfigurator() internal view {
        require(
            IConfigProvider(provider).owner() == _msgSender(),
            Errors.LP_CALLER_NOT_LEND_POOL_CONFIGURATOR
        );
    }

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset
     * - E.g. User borrows 100 USDC, receiving the 100 USDC in his wallet
     *   and lock collateral asset in contract
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param nftAsset The address of the underlying nft used as collateral
     * @param nftTokenId The token ID of the underlying nft used as collateral
     **/
    function borrow(
        uint256 shopId,
        address asset,
        uint256 amount,
        address nftAsset,
        uint256 nftTokenId,
        address onBehalfOf
    ) external override nonReentrant whenNotPaused {
        _borrow(shopId, asset, amount, nftAsset, nftTokenId, onBehalfOf, false);
    }

    function borrowETH(
        uint256 shopId,
        uint256 amount,
        address nftAsset,
        uint256 nftTokenId,
        address onBehalfOf
    ) external override nonReentrant whenNotPaused {
        _borrow(
            shopId,
            GenericLogic.getWETHAddress(IConfigProvider(provider)),
            amount,
            nftAsset,
            nftTokenId,
            onBehalfOf,
            true
        );
    }

    function _borrow(
        uint256 shopId,
        address asset,
        uint256 amount,
        address nftAsset,
        uint256 nftTokenId,
        address onBehalfOf,
        bool isNative
    ) internal {
        DataTypes.ShopConfiguration storage shopConfig = shopsConfig[shopId][
            asset
        ][nftAsset];
        require(shopConfig.getActive(), Errors.RC_NOT_ACTIVE);
        BorrowLogic.executeBorrow(
            shops[shopId],
            shopConfig,
            IConfigProvider(provider),
            reservesInfo,
            nftsInfo,
            DataTypes.ExecuteBorrowParams({
                initiator: _msgSender(),
                asset: asset,
                amount: amount,
                nftAsset: nftAsset,
                nftTokenId: nftTokenId,
                onBehalfOf: onBehalfOf,
                isNative: isNative
            })
        );
    }

    function batchBorrow(
        uint256 shopId,
        address[] calldata assets,
        uint256[] calldata amounts,
        address[] calldata nftAssets,
        uint256[] calldata nftTokenIds,
        address onBehalfOf
    ) external override nonReentrant whenNotPaused {
        DataTypes.ExecuteBatchBorrowParams memory params;
        params.initiator = _msgSender();
        params.assets = assets;
        params.amounts = amounts;
        params.nftAssets = nftAssets;
        params.nftTokenIds = nftTokenIds;
        params.onBehalfOf = onBehalfOf;
        params.isNative = false;

        BorrowLogic.executeBatchBorrow(
            shops[shopId],
            shopsConfig,
            IConfigProvider(provider),
            reservesInfo,
            nftsInfo,
            params
        );
    }

    function batchBorrowETH(
        uint256 shopId,
        uint256[] calldata amounts,
        address[] calldata nftAssets,
        uint256[] calldata nftTokenIds,
        address onBehalfOf
    ) external override nonReentrant whenNotPaused {
        for (uint256 i = 0; i < nftAssets.length; i++) {
            _borrow(
                shopId,
                GenericLogic.getWETHAddress(IConfigProvider(provider)),
                amounts[i],
                nftAssets[i],
                nftTokenIds[i],
                onBehalfOf,
                true
            );
        }
    }

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent loan owned
     * - E.g. User repays 100 USDC, burning loan and receives collateral asset
     * @param amount The amount to repay
     **/
    function repay(
        uint256 loanId,
        uint256 amount
    )
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256, uint256, bool)
    {
        return _repay(loanId, amount, false);
    }

    function repayETH(
        uint256 loanId,
        uint256 amount
    )
        external
        payable
        override
        nonReentrant
        whenNotPaused
        returns (uint256, uint256, bool)
    {
        require(amount == msg.value, Errors.LP_INVALID_ETH_AMOUNT);
        //convert eth -> weth
        TransferHelper.convertETHToWETH(
            GenericLogic.getWETHAddress(IConfigProvider(provider)),
            msg.value
        );
        return _repay(loanId, amount, true);
    }

    function _repay(
        uint256 loanId,
        uint256 amount,
        bool isNative
    ) internal returns (uint256, uint256, bool) {
        DataTypes.LoanData memory loanData = IShopLoan(
            IConfigProvider(provider).loanManager()
        ).getLoan(loanId);
        DataTypes.ShopData storage shop = shops[loanData.shopId];
        return
            BorrowLogic.executeRepay(
                IConfigProvider(provider),
                reservesInfo,
                DataTypes.ExecuteRepayParams({
                    initiator: _msgSender(),
                    loanId: loanId,
                    amount: amount,
                    shopCreator: shop.creator,
                    isNative: isNative
                })
            );
    }

    function batchRepay(
        uint256 shopId,
        uint256[] calldata loanIds,
        uint256[] calldata amounts
    )
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256[] memory, uint256[] memory, bool[] memory)
    {
        return _batchRepay(shopId, loanIds, amounts, false);
    }

    function batchRepayETH(
        uint256 shopId,
        uint256[] calldata loanIds,
        uint256[] calldata amounts
    )
        external
        payable
        override
        nonReentrant
        whenNotPaused
        returns (uint256[] memory, uint256[] memory, bool[] memory)
    {
        uint256 val = 0;
        for (uint256 i = 0; i < loanIds.length; i++) {
            val += amounts[i];
        }
        require(val == msg.value, Errors.LP_INVALID_ETH_AMOUNT);
        //convert eth -> weth
        TransferHelper.convertETHToWETH(
            GenericLogic.getWETHAddress(IConfigProvider(provider)),
            msg.value
        );
        return _batchRepay(shopId, loanIds, amounts, true);
    }

    function _batchRepay(
        uint256 shopId,
        uint256[] calldata loanIds,
        uint256[] calldata amounts,
        bool isNative
    ) internal returns (uint256[] memory, uint256[] memory, bool[] memory) {
        DataTypes.ExecuteBatchRepayParams memory params;
        params.initiator = _msgSender();
        params.loanIds = loanIds;
        params.amounts = amounts;
        params.shopCreator = shops[shopId].creator;
        params.isNative = isNative;
        return
            BorrowLogic.executeBatchRepay(
                IConfigProvider(provider),
                reservesInfo,
                params
            );
    }

    /**
     * @dev Function to auction a non-healthy position collateral-wise
     * - The bidder want to buy collateral asset of the user getting liquidated
     **/
    function auction(
        uint256 loanId,
        uint256 bidPrice,
        address onBehalfOf
    ) external override nonReentrant whenNotPaused {
        _auction(loanId, bidPrice, onBehalfOf, false);
    }

    function auctionETH(
        uint256 loanId,
        uint256 bidPrice,
        address onBehalfOf
    ) external payable override nonReentrant whenNotPaused {
        require(bidPrice == msg.value, Errors.LP_INVALID_ETH_AMOUNT);
        //convert eth -> weth
        TransferHelper.convertETHToWETH(
            GenericLogic.getWETHAddress(IConfigProvider(provider)),
            msg.value
        );
        _auction(loanId, bidPrice, onBehalfOf, true);
    }

    function _auction(
        uint256 loanId,
        uint256 bidPrice,
        address onBehalfOf,
        bool isNative
    ) internal {
        LiquidateLogic.executeAuction(
            provider,
            reservesInfo,
            nftsInfo,
            DataTypes.ExecuteAuctionParams({
                initiator: _msgSender(),
                loanId: loanId,
                bidPrice: bidPrice,
                onBehalfOf: onBehalfOf,
                isNative: isNative
            })
        );
    }

    /**
     * @notice Redeem a NFT loan which state is in Auction
     * - E.g. User repays 100 USDC, burning loan and receives collateral asset
     * @param amount The amount to repay the debt
     * @param bidFine The amount of bid fine
     **/
    function redeem(
        uint256 loanId,
        uint256 amount,
        uint256 bidFine
    )
        external
        override
        nonReentrant
        whenNotPaused
        returns (
            uint256 remainAmount,
            uint256 repayPrincipal,
            uint256 interest,
            uint256 fee
        )
    {
        return _redeem(loanId, amount, bidFine, false);
    }

    function redeemETH(
        uint256 loanId,
        uint256 amount,
        uint256 bidFine
    )
        external
        payable
        override
        nonReentrant
        whenNotPaused
        returns (
            uint256 remainAmount,
            uint256 repayPrincipal,
            uint256 interest,
            uint256 fee
        )
    {
        require(amount + bidFine == msg.value, Errors.LP_INVALID_ETH_AMOUNT);

        //convert eth -> weth
        TransferHelper.convertETHToWETH(
            GenericLogic.getWETHAddress(IConfigProvider(provider)),
            msg.value
        );
        return _redeem(loanId, amount, bidFine, true);
    }

    function _redeem(
        uint256 loanId,
        uint256 amount,
        uint256 bidFine,
        bool isNative
    )
        internal
        returns (
            uint256 remainAmount,
            uint256 repayPrincipal,
            uint256 interest,
            uint256 fee
        )
    {
        DataTypes.LoanData memory loanData = IShopLoan(
            IConfigProvider(provider).loanManager()
        ).getLoan(loanId);
        return
            LiquidateLogic.executeRedeem(
                provider,
                reservesInfo,
                nftsInfo,
                DataTypes.ExecuteRedeemParams({
                    initiator: _msgSender(),
                    loanId: loanId,
                    amount: amount,
                    bidFine: bidFine,
                    shopCreator: shops[loanData.shopId].creator,
                    isNative: isNative
                })
            );
    }

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise
     * - The caller (liquidator) buy collateral asset of the user getting liquidated, and receives
     *   the collateral asset
     **/
    function liquidate(
        uint256 loanId
    ) external override nonReentrant whenNotPaused {
        DataTypes.LoanData memory loanData = IShopLoan(provider.loanManager())
            .getLoan(loanId);
        DataTypes.ShopData memory shop = shops[loanData.shopId];
        return
            LiquidateLogic.executeLiquidate(
                provider,
                reservesInfo,
                nftsInfo,
                DataTypes.ExecuteLiquidateParams({
                    initiator: _msgSender(),
                    loanId: loanId,
                    shopCreator: shop.creator
                })
            );
    }

    /**
     * @dev Returns the debt data of the NFT
     * @return nftAsset the address of the NFT
     * @return nftTokenId nft token ID
     * @return reserveAsset the address of the Reserve
     * @return totalCollateral the total power of the NFT
     * @return totalDebt the total debt of the NFT
     * @return healthFactor the current health factor of the NFT
     **/
    function getNftDebtData(
        uint256 loanId
    )
        external
        view
        override
        returns (
            address nftAsset,
            uint256 nftTokenId,
            address reserveAsset,
            uint256 totalCollateral,
            uint256 totalDebt,
            uint256 healthFactor
        )
    {
        if (loanId == 0) {
            return (address(0), 0, address(0), 0, 0, 0);
        }
        DataTypes.LoanData memory loanData = IShopLoan(
            IConfigProvider(provider).loanManager()
        ).getLoan(loanId);
        uint256 liquidationThreshold = provider.liquidationThreshold();

        DataTypes.LoanData memory loan = IShopLoan(provider.loanManager())
            .getLoan(loanId);

        reserveAsset = loan.reserveAsset;
        DataTypes.ReservesInfo storage reserveData = reservesInfo[reserveAsset];

        (, totalCollateral) = GenericLogic.calculateNftCollateralData(
            loanData.reserveAsset,
            reserveData,
            loanData.nftAsset,
            provider.reserveOracle(),
            provider.nftOracle()
        );

        (, totalDebt) = GenericLogic.calculateNftDebtData(
            reserveAsset,
            reserveData,
            provider.loanManager(),
            loanData.loanId,
            provider.reserveOracle()
        );
        if (loan.state == DataTypes.LoanState.Auction) {
            totalDebt = loan.bidBorrowAmount;
        }
        if (loan.state == DataTypes.LoanState.Active) {
            healthFactor = GenericLogic.calculateHealthFactorFromBalances(
                totalCollateral,
                totalDebt,
                liquidationThreshold
            );
        }
        nftAsset = loan.nftAsset;
        nftTokenId = loan.nftTokenId;
    }

    /**
     * @dev Returns the auction data of the NFT
     * @param loanId the loan id of the NFT
     * @return nftAsset The address of the NFT
     * @return nftTokenId The token id of the NFT
     * @return bidderAddress the highest bidder address of the loan
     * @return bidPrice the highest bid price in Reserve of the loan
     * @return bidBorrowAmount the borrow amount in Reserve of the loan
     * @return bidFine the penalty fine of the loan
     **/
    function getNftAuctionData(
        uint256 loanId
    )
        external
        view
        override
        returns (
            address nftAsset,
            uint256 nftTokenId,
            address bidderAddress,
            uint256 bidPrice,
            uint256 bidBorrowAmount,
            uint256 bidFine
        )
    {
        // DataTypes.NftsInfo storage nftData = nftsInfo[nftAsset];
        if (loanId != 0) {
            DataTypes.LoanData memory loan = IShopLoan(provider.loanManager())
                .getLoan(loanId);
            DataTypes.ReservesInfo storage reserveData = reservesInfo[
                loan.reserveAsset
            ];

            bidderAddress = loan.bidderAddress;
            bidPrice = loan.bidPrice;
            bidBorrowAmount = loan.bidBorrowAmount;

            (, bidFine) = GenericLogic.calculateLoanBidFine(
                provider,
                loan.reserveAsset,
                reserveData,
                nftAsset,
                loan,
                provider.loanManager(),
                provider.reserveOracle()
            );
            nftAsset = loan.nftAsset;
            nftTokenId = loan.nftTokenId;
        }
    }

    function getNftAuctionEndTime(
        uint256 loanId
    )
        external
        view
        override
        returns (
            address nftAsset,
            uint256 nftTokenId,
            uint256 bidStartTimestamp,
            uint256 bidEndTimestamp,
            uint256 redeemEndTimestamp
        )
    {
        if (loanId != 0) {
            DataTypes.LoanData memory loan = IShopLoan(provider.loanManager())
                .getLoan(loanId);

            nftAsset = loan.nftAsset;
            nftTokenId = loan.nftTokenId;
            bidStartTimestamp = loan.bidStartTimestamp;
            if (bidStartTimestamp > 0) {
                (bidEndTimestamp, redeemEndTimestamp) = GenericLogic
                    .calculateLoanAuctionEndTimestamp(
                        provider,
                        bidStartTimestamp
                    );
            }
        }
    }

    struct GetLiquidationPriceLocalVars {
        address poolLoan;
        uint256 loanId;
        uint256 thresholdPrice;
        uint256 liquidatePrice;
        uint256 paybackAmount;
        uint256 remainAmount;
    }

    function getNftLiquidatePrice(
        uint256 loanId
    )
        external
        view
        override
        returns (uint256 liquidatePrice, uint256 paybackAmount)
    {
        GetLiquidationPriceLocalVars memory vars;

        vars.poolLoan = provider.loanManager();
        vars.loanId = loanId;
        if (vars.loanId == 0) {
            return (0, 0);
        }

        DataTypes.LoanData memory loanData = IShopLoan(vars.poolLoan).getLoan(
            vars.loanId
        );

        DataTypes.ReservesInfo storage reserveData = reservesInfo[
            loanData.reserveAsset
        ];
        (
            vars.paybackAmount,
            vars.thresholdPrice,
            vars.liquidatePrice,

        ) = GenericLogic.calculateLoanLiquidatePrice(
            provider,
            vars.loanId,
            loanData.reserveAsset,
            reserveData,
            loanData.nftAsset
        );

        if (vars.liquidatePrice < vars.paybackAmount) {
            vars.liquidatePrice = vars.paybackAmount;
        }

        return (vars.liquidatePrice, vars.paybackAmount);
    }

    /**
     * @dev Returns the list of the initialized reserves
     **/
    function getReservesList()
        external
        view
        override
        returns (address[] memory)
    {
        return reserves;
    }

    /**
     * @dev Returns the list of the initialized nfts
     **/
    function getNftsList() external view override returns (address[] memory) {
        return nfts;
    }

    /**
     * @dev Set the _pause state of the pool
     * - Only callable by the LendPoolConfigurator contract
     * @param val `true` to pause the pool, `false` to un-pause it
     */
    function setPause(bool val) external override onlyFactoryConfigurator {
        if (_paused != val) {
            _paused = val;
            emit Paused();
        }
    }

    /**
     * @dev Returns if the LendPool is paused
     */
    function paused() external view override returns (bool) {
        return _paused;
    }

    /**
     * @dev Returns the cached LendPoolConfigProvider connected to this contract
     **/
    function getConfigProvider()
        external
        view
        override
        returns (IConfigProvider)
    {
        return IConfigProvider(provider);
    }

    function addReserve(
        address asset
    ) external override onlyFactoryConfigurator {
        require(AddressUpgradeable.isContract(asset), Errors.LP_NOT_CONTRACT);
        _addReserveToList(asset);
    }

    function _addReserveToList(address asset) internal {
        require(
            reservesInfo[asset].id == 0,
            Errors.RL_RESERVE_ALREADY_INITIALIZED
        );
        reservesInfo[asset] = DataTypes.ReservesInfo({
            id: uint8(reserves.length) + 1,
            contractAddress: asset,
            active: true,
            symbol: ERC20(asset).symbol(),
            decimals: ERC20(asset).decimals()
        });
        reserves.push(asset);
    }

    function addNftCollection(
        address nftAddress,
        string memory collection,
        uint256 maxSupply
    ) external override onlyFactoryConfigurator {
        require(
            AddressUpgradeable.isContract(nftAddress),
            Errors.LP_NOT_CONTRACT
        );
        _addNftToList(nftAddress, collection, maxSupply);
        IERC721Upgradeable(nftAddress).setApprovalForAll(
            provider.loanManager(),
            true
        );
        IShopLoan(provider.loanManager()).initNft(nftAddress);
    }

    function _addNftToList(
        address nftAddress,
        string memory collection,
        uint256 maxSupply
    ) internal {
        require(
            nftsInfo[nftAddress].id == 0,
            Errors.LP_NFT_ALREADY_INITIALIZED
        );
        nftsInfo[nftAddress] = DataTypes.NftsInfo({
            id: uint8(nfts.length) + 1,
            contractAddress: nftAddress,
            active: true,
            collection: collection,
            maxSupply: maxSupply
        });
        nfts.push(nftAddress);
    }

    function setShopConfigurations(
        DataTypes.ShopConfigParams[] memory params
    ) external {
        uint256 shopId = shopOf(_msgSender());
        if (shopId == 0) {
            shopId = _create(_msgSender());
        }
        // reserve => map(nft => config)
        mapping(address => mapping(address => DataTypes.ShopConfiguration))
            storage shopConfig = shopsConfig[shopId];

        for (uint256 i = 0; i < params.length; ++i) {
            mapping(address => DataTypes.ShopConfiguration)
                storage reserveConfig = shopConfig[params[i].reserveAddress];
            DataTypes.ShopConfiguration memory nftConfig = DataTypes
                .ShopConfiguration({data: 0});
            nftConfig.setActive(params[i].active);
            nftConfig.setLtv(params[i].ltvRate);
            nftConfig.setInterestRate(params[i].interestRate);
            reserveConfig[params[i].nftAddress] = nftConfig;
            emit ConfigurationUpdated(
                shopId,
                params[i].reserveAddress,
                params[i].nftAddress,
                params[i].interestRate,
                params[i].ltvRate,
                params[i].active
            );
        }
    }

    function _verifyCallResult(
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {DataTypes} from "../libraries/types/DataTypes.sol";
import {IConfigProvider} from "../interfaces/IConfigProvider.sol";

contract ShopFactoryStorage {
    uint256 public shopCount;
    /// shop
    mapping(uint256 => DataTypes.ShopData) public shops;
    mapping(address => uint256) public creators;
    //shopId => reserve => nft => config
    mapping(uint256 => mapping(address => mapping(address => DataTypes.ShopConfiguration)))
        public shopsConfig;

    // reserves
    address[] reserves;
    mapping(address => DataTypes.ReservesInfo) reservesInfo;

    //nfts
    address[] nfts;
    mapping(address => DataTypes.NftsInfo) nftsInfo;

    // count loan
    mapping(uint256 => DataTypes.LoanData) loans;
    //others
    bool internal _paused;
    uint256 internal constant _NOT_ENTERED = 0;
    uint256 internal constant _ENTERED = 1;
    uint256 internal _status;

    // For upgradable, add one new variable above, minus 1 at here
    uint256[47] private __gap;
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
        if (_initialized < type(uint8).max) {
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {IConfigProvider} from "../../interfaces/IConfigProvider.sol";

import {IShopLoan} from "../../interfaces/IShopLoan.sol";

import {PercentageMath} from "../math/PercentageMath.sol";

import {Errors} from "../helpers/Errors.sol";
import {TransferHelper} from "../helpers/TransferHelper.sol";
import {DataTypes} from "../types/DataTypes.sol";

import {IERC20Upgradeable} from "../../openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "../../openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {IERC721Upgradeable} from "../../openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../../openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

// import {ReserveLogic} from "./ReserveLogic.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {ValidationLogic} from "./ValidationLogic.sol";
import {ShopConfiguration} from "../configuration/ShopConfiguration.sol";
import {IReserveOracleGetter} from "../../interfaces/IReserveOracleGetter.sol";

/**
 * @title BorrowLogic library
 * @notice Implements the logic to borrow feature
 */
library BorrowLogic {
    using PercentageMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ShopConfiguration for DataTypes.ShopConfiguration;
    /**
     * @dev Emitted on borrow() when loan needs to be opened
     * @param user The address of the user initiating the borrow(), receiving the funds
     * @param reserve The address of the underlying asset being borrowed
     * @param amount The amount borrowed out
     * @param nftAsset The address of the underlying NFT used as collateral
     * @param nftTokenId The token id of the underlying NFT used as collateral
     **/
    event Borrow(
        address user,
        address indexed reserve,
        uint256 amount,
        address nftAsset,
        uint256 nftTokenId,
        address indexed onBehalfOf,
        uint256 borrowRate,
        uint256 loanId
    );

    /**
     * @dev Emitted on repay()
     * @param user The address of the user initiating the repay(), providing the funds
     * @param reserve The address of the underlying asset of the reserve
     * @param amount The amount repaid
     * @param nftAsset The address of the underlying NFT used as collateral
     * @param nftTokenId The token id of the underlying NFT used as collateral
     * @param borrower The beneficiary of the repayment, getting his debt reduced
     * @param loanId The loan ID of the NFT loans
     **/
    event Repay(
        address user,
        address indexed reserve,
        uint256 amount,
        uint256 interestAmount,
        uint256 feeAmount,
        address indexed nftAsset,
        uint256 nftTokenId,
        address indexed borrower,
        uint256 loanId
    );

    struct RepayLocalVars {
        address initiator;
        address loanManager;
        address onBehalfOf;
        uint256 loanId;
        bool isUpdate;
        uint256 borrowAmount;
        uint256 repayAmount;
        uint256 interestAmount;
        uint256 feeAmount;
    }

    struct ExecuteBorrowLocalVars {
        uint256 shopId;
        address initiator;
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
        uint256 loanId;
        address reserveOracle;
        address nftOracle;
        address loanAddress;
        uint256 totalSupply;
        uint256 interestRate;
    }

    /**
     * @notice Implements the borrow feature. Through `borrow()`, users borrow assets from the protocol.
     * @dev Emits the `Borrow()` event.
     * @param reservesData The state of all the reserves
     * @param nftsData The state of all the nfts
     * @param params The additional parameters needed to execute the borrow function
     */
    function executeBorrow(
        DataTypes.ShopData memory shop,
        DataTypes.ShopConfiguration storage config,
        IConfigProvider configProvider,
        mapping(address => DataTypes.ReservesInfo) storage reservesData,
        mapping(address => DataTypes.NftsInfo) storage nftsData,
        DataTypes.ExecuteBorrowParams memory params
    ) external {
        _borrow(shop, config, configProvider, reservesData, nftsData, params);
    }

    /**
     * @notice Implements the batch borrow feature. Through `batchBorrow()`, users repay borrow to the protocol.
     * @dev Emits the `Borrow()` event.
     * @param reservesData The state of all the reserves
     * @param nftsData The state of all the nfts
     * @param params The additional parameters needed to execute the batchBorrow function
     */
    function executeBatchBorrow(
        DataTypes.ShopData memory shop,
        mapping(uint256 => mapping(address => mapping(address => DataTypes.ShopConfiguration)))
            storage shopsConfig,
        IConfigProvider configProvider,
        mapping(address => DataTypes.ReservesInfo) storage reservesData,
        mapping(address => DataTypes.NftsInfo) storage nftsData,
        DataTypes.ExecuteBatchBorrowParams memory params
    ) external {
        require(
            params.nftAssets.length == params.assets.length,
            "inconsistent assets length"
        );
        require(
            params.nftAssets.length == params.amounts.length,
            "inconsistent amounts length"
        );
        require(
            params.nftAssets.length == params.nftTokenIds.length,
            "inconsistent tokenIds length"
        );

        for (uint256 i = 0; i < params.nftAssets.length; i++) {
            DataTypes.ShopConfiguration storage shopConfig = shopsConfig[
                shop.id
            ][params.assets[i]][params.nftAssets[i]];
            require(shopConfig.getActive(), Errors.RC_NOT_ACTIVE);
            _borrow(
                shop,
                shopConfig,
                configProvider,
                reservesData,
                nftsData,
                DataTypes.ExecuteBorrowParams({
                    initiator: params.initiator,
                    asset: params.assets[i],
                    amount: params.amounts[i],
                    nftAsset: params.nftAssets[i],
                    nftTokenId: params.nftTokenIds[i],
                    onBehalfOf: params.onBehalfOf,
                    isNative: params.isNative
                })
            );
        }
    }

    function _borrow(
        DataTypes.ShopData memory shop,
        DataTypes.ShopConfiguration storage config,
        IConfigProvider configProvider,
        mapping(address => DataTypes.ReservesInfo) storage reservesData,
        mapping(address => DataTypes.NftsInfo) storage nftsData,
        DataTypes.ExecuteBorrowParams memory params
    ) internal {
        require(
            params.onBehalfOf != address(0),
            Errors.VL_INVALID_ONBEHALFOF_ADDRESS
        );

        ExecuteBorrowLocalVars memory vars;
        vars.initiator = params.initiator;

        DataTypes.ReservesInfo storage reserveData = reservesData[params.asset];
        DataTypes.NftsInfo storage nftData = nftsData[params.nftAsset];

        // Convert asset amount to ETH
        vars.reserveOracle = configProvider.reserveOracle();
        vars.nftOracle = configProvider.nftOracle();
        vars.loanAddress = configProvider.loanManager();
        vars.loanId = IShopLoan(vars.loanAddress).getCollateralLoanId(
            params.nftAsset,
            params.nftTokenId
        );
        if (nftData.maxSupply > 0) {
            vars.totalSupply = IERC721EnumerableUpgradeable(params.nftAsset)
                .totalSupply();
            require(
                vars.totalSupply <= nftData.maxSupply,
                Errors.LP_NFT_SUPPLY_NUM_EXCEED_MAX_LIMIT
            );
            require(
                params.nftTokenId <= nftData.maxSupply,
                Errors.LP_NFT_TOKEN_ID_EXCEED_MAX_LIMIT
            );
        }
        vars.interestRate = config.getInterestRate();

        ValidationLogic.validateBorrow(
            configProvider,
            config,
            params.onBehalfOf,
            params.asset,
            params.amount,
            reserveData,
            params.nftAsset,
            vars.loanAddress,
            vars.loanId,
            vars.reserveOracle,
            vars.nftOracle
        );

        if (vars.loanId == 0) {
            IERC721Upgradeable(params.nftAsset).safeTransferFrom(
                vars.initiator,
                address(this), // shopFactory
                params.nftTokenId
            );
            vars.loanId = IShopLoan(vars.loanAddress).createLoan(
                shop.id,
                params.onBehalfOf,
                params.nftAsset,
                params.nftTokenId,
                params.asset,
                params.amount,
                vars.interestRate
            );
        } else {
            revert("not supported");
        }

        if (
            GenericLogic.isWETHAddress(configProvider, params.asset) &&
            params.isNative
        ) {
            //transfer weth from shop to contract
            IERC20Upgradeable(params.asset).transferFrom(
                shop.creator,
                address(this),
                params.amount
            );
            //convert weth to eth and transfer to borrower
            TransferHelper.transferWETH2ETH(
                GenericLogic.getWETHAddress(configProvider),
                vars.initiator,
                params.amount
            );
        } else {
            //transfer asset from shop to borrower
            IERC20Upgradeable(params.asset).transferFrom(
                shop.creator,
                vars.initiator,
                params.amount
            );
        }

        emit Borrow(
            vars.initiator,
            params.asset,
            params.amount,
            params.nftAsset,
            params.nftTokenId,
            params.onBehalfOf,
            config.getInterestRate(),
            vars.loanId
        );
    }

    /**
     * @notice Implements the borrow feature. Through `repay()`, users repay assets to the protocol.
     * @dev Emits the `Repay()` event.
     * @param reservesData The state of all the reserves
     * @param params The additional parameters needed to execute the repay function
     */
    function executeRepay(
        IConfigProvider configProvider,
        mapping(address => DataTypes.ReservesInfo) storage reservesData,
        DataTypes.ExecuteRepayParams memory params
    ) external returns (uint256, uint256, bool) {
        return _repay(configProvider, reservesData, params);
    }

    /**
     * @notice Implements the batch repay feature. Through `batchRepay()`, users repay assets to the protocol.
     * @dev Emits the `repay()` event.
     * @param reservesData The state of all the reserves
     * @param params The additional parameters needed to execute the batchRepay function
     */
    function executeBatchRepay(
        IConfigProvider configProvider,
        mapping(address => DataTypes.ReservesInfo) storage reservesData,
        DataTypes.ExecuteBatchRepayParams memory params
    ) external returns (uint256[] memory, uint256[] memory, bool[] memory) {
        require(
            params.loanIds.length == params.amounts.length,
            "inconsistent amounts length"
        );

        uint256[] memory repayAmounts = new uint256[](params.loanIds.length);
        uint256[] memory feeAmounts = new uint256[](params.loanIds.length);
        bool[] memory repayAlls = new bool[](params.loanIds.length);

        for (uint256 i = 0; i < params.loanIds.length; i++) {
            (repayAmounts[i], feeAmounts[i], repayAlls[i]) = _repay(
                configProvider,
                reservesData,
                DataTypes.ExecuteRepayParams({
                    initiator: params.initiator,
                    loanId: params.loanIds[i],
                    amount: params.amounts[i],
                    shopCreator: params.shopCreator,
                    isNative: params.isNative
                })
            );
        }

        return (repayAmounts, feeAmounts, repayAlls);
    }

    function _repay(
        IConfigProvider configProvider,
        mapping(address => DataTypes.ReservesInfo) storage reservesData,
        DataTypes.ExecuteRepayParams memory params
    )
        internal
        returns (uint256 repayAmount, uint256 feeAmount, bool isFullRepay)
    {
        RepayLocalVars memory vars;

        vars.initiator = params.initiator;
        vars.loanId = params.loanId;
        vars.loanManager = configProvider.loanManager();

        require(vars.loanId != 0, Errors.LP_NFT_IS_NOT_USED_AS_COLLATERAL);

        DataTypes.LoanData memory loanData = IShopLoan(vars.loanManager)
            .getLoan(vars.loanId);

        DataTypes.ReservesInfo storage reserveData = reservesData[
            loanData.reserveAsset
        ];

        vars.borrowAmount = loanData.borrowAmount;
        ValidationLogic.validateRepay(
            reserveData,
            loanData,
            params.amount,
            vars.borrowAmount
        );
        (, , uint256 currentInterest, uint256 platformFee) = GenericLogic
            .calculateInterestInfo(
                GenericLogic.CalculateInterestInfoVars({
                    lastRepaidAt: loanData.lastRepaidAt,
                    borrowAmount: loanData.borrowAmount,
                    interestRate: loanData.interestRate,
                    repayAmount: params.amount,
                    platformFeeRate: configProvider.platformFeePercentage(),
                    interestDuration: configProvider.interestDuration()
                })
            );

        vars.repayAmount = vars.borrowAmount + currentInterest + platformFee;
        vars.interestAmount = currentInterest;
        vars.feeAmount = platformFee;

        vars.isUpdate = false;
        if (params.amount < vars.repayAmount) {
            vars.isUpdate = true;
            vars.repayAmount = params.amount;
        }
        if (vars.isUpdate) {
            IShopLoan(vars.loanManager).partialRepayLoan(
                vars.initiator,
                vars.loanId,
                vars.repayAmount
            );
        } else {
            IShopLoan(vars.loanManager).repayLoan(
                vars.initiator,
                vars.loanId,
                vars.repayAmount
            );
        }
        if (
            GenericLogic.isWETHAddress(configProvider, loanData.reserveAsset) &&
            params.isNative
        ) {
            // transfer repayAmount - fee from factory to shopCreator
            IERC20Upgradeable(loanData.reserveAsset).safeTransfer(
                params.shopCreator,
                vars.repayAmount - vars.feeAmount
            );
            if (vars.feeAmount > 0) {
                // transfer platform fee from factory
                IERC20Upgradeable(loanData.reserveAsset).safeTransfer(
                    IConfigProvider(configProvider).platformFeeReceiver(),
                    vars.feeAmount
                );
            }
        } else {
            // transfer erc20 to shopCreator
            IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(
                vars.initiator,
                params.shopCreator,
                vars.repayAmount - vars.feeAmount
            );
            if (vars.feeAmount > 0) {
                // transfer platform fee
                if (configProvider.platformFeeReceiver() != address(this)) {
                    IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(
                        vars.initiator,
                        configProvider.platformFeeReceiver(),
                        vars.feeAmount
                    );
                }
            }
        }

        // transfer erc721 to borrower
        if (!vars.isUpdate) {
            IERC721Upgradeable(loanData.nftAsset).safeTransferFrom(
                address(this),
                loanData.borrower,
                loanData.nftTokenId
            );
        }

        emit Repay(
            vars.initiator,
            loanData.reserveAsset,
            vars.repayAmount,
            vars.interestAmount,
            vars.feeAmount,
            loanData.nftAsset,
            loanData.nftTokenId,
            loanData.borrower,
            vars.loanId
        );
        repayAmount = vars.repayAmount;
        feeAmount = vars.feeAmount;
        isFullRepay = !vars.isUpdate;
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

library Constants {
    // uint256 constant EXPIRE_LOAN = 5 seconds;
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

import {IConfigProvider} from "./IConfigProvider.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

interface IShop {
    //
    event Created(address indexed creator, uint256 id);
    /**
     * @dev Emitted on borrow() when loan needs to be opened
     * @param user The address of the user initiating the borrow(), receiving the funds
     * @param reserve The address of the underlying asset being borrowed
     * @param amount The amount borrowed out
     * @param nftAsset The address of the underlying NFT used as collateral
     * @param nftTokenId The token id of the underlying NFT used as collateral
     **/
    event Borrow(
        address user,
        address indexed reserve,
        uint256 amount,
        address nftAsset,
        uint256 nftTokenId,
        address indexed onBehalfOf,
        uint256 borrowRate,
        uint256 loanId
    );

    /**
     * @dev Emitted on repay()
     * @param user The address of the user initiating the repay(), providing the funds
     * @param reserve The address of the underlying asset of the reserve
     * @param amount The amount repaid
     * @param nftAsset The address of the underlying NFT used as collateral
     * @param nftTokenId The token id of the underlying NFT used as collateral
     * @param borrower The beneficiary of the repayment, getting his debt reduced
     * @param loanId The loan ID of the NFT loans
     **/
    event Repay(
        address user,
        address indexed reserve,
        uint256 amount,
        uint256 interestAmount,
        uint256 feeAmount,
        address indexed nftAsset,
        uint256 nftTokenId,
        address indexed borrower,
        uint256 loanId
    );

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
     * @param feeAmount The platform fee
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

    event ConfigurationUpdated(
        uint256 shopId,
        address reserveAddress,
        address nftAddress,
        uint256 interestRate,
        uint256 ltvRate,
        bool active
    );

    /**
     * @dev Emitted when the pause is triggered.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted.
     */
    event Unpaused();

    /**
     * @dev Emitted when the pause time is updated.
     */
    event PausedTimeUpdated(uint256 startTime, uint256 durationTime);

    /**
     * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
     * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
     * the event will actually be fired by the LendPool contract. The event is therefore replicated here so it
     * gets added to the LendPool ABI
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The new liquidity rate
     * @param variableBorrowRate The new variable borrow rate
     * @param liquidityIndex The new liquidity index
     * @param variableBorrowIndex The new variable borrow index
     **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral
     * - E.g. User borrows 100 USDC, receiving the 100 USDC in his wallet
     *   and lock collateral asset in contract
     * @param reserveAsset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param nftAsset The address of the underlying NFT used as collateral
     * @param nftTokenId The token ID of the underlying NFT used as collateral
     **/
    function borrow(
        uint256 shopId,
        address reserveAsset,
        uint256 amount,
        address nftAsset,
        uint256 nftTokenId,
        address onBehalfOf
    ) external;

    function borrowETH(
        uint256 shopId,
        uint256 amount,
        address nftAsset,
        uint256 nftTokenId,
        address onBehalfOf
    ) external;

    function batchBorrow(
        uint256 shopId,
        address[] calldata assets,
        uint256[] calldata amounts,
        address[] calldata nftAssets,
        uint256[] calldata nftTokenIds,
        address onBehalfOf
    ) external;

    function batchBorrowETH(
        uint256 shopId,
        uint256[] calldata amounts,
        address[] calldata nftAssets,
        uint256[] calldata nftTokenIds,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent loan owned
     * - E.g. User repays 100 USDC, burning loan and receives collateral asset
     * @param amount The amount to repay
     * @return The final amount repaid, loan is burned or not
     **/
    function repay(
        uint256 loanId,
        uint256 amount
    ) external returns (uint256, uint256, bool);

    function repayETH(
        uint256 loanId,
        uint256 amount
    ) external payable returns (uint256, uint256, bool);

    function batchRepay(
        uint256 shopId,
        uint256[] calldata loanIds,
        uint256[] calldata amounts
    ) external returns (uint256[] memory, uint256[] memory, bool[] memory);

    function batchRepayETH(
        uint256 shopId,
        uint256[] calldata loanIds,
        uint256[] calldata amounts
    )
        external
        payable
        returns (uint256[] memory, uint256[] memory, bool[] memory);

    /**
     * @dev Function to auction a non-healthy position collateral-wise
     * - The caller (liquidator) want to buy collateral asset of the user getting liquidated
     * @param bidPrice The bid price of the liquidator want to buy the underlying NFT
     **/

    function auction(
        uint256 loanId,
        uint256 bidPrice,
        address onBehalfOf
    ) external;

    function auctionETH(
        uint256 loanId,
        uint256 bidPrice,
        address onBehalfOf
    ) external payable;

    /**
     * @notice Redeem a NFT loan which state is in Auction
     * - E.g. User repays 100 USDC, burning loan and receives collateral asset
     * @param amount The amount to repay the debt
     * @param bidFine The amount of bid fine
     **/
    function redeem(
        uint256 loanId,
        uint256 amount,
        uint256 bidFine
    )
        external
        returns (
            uint256 remainAmount,
            uint256 repayPrincipal,
            uint256 interest,
            uint256 fee
        );

    function redeemETH(
        uint256 loanId,
        uint256 amount,
        uint256 bidFine
    )
        external
        payable
        returns (
            uint256 remainAmount,
            uint256 repayPrincipal,
            uint256 interest,
            uint256 fee
        );

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise
     * - The caller (liquidator) buy collateral asset of the user getting liquidated, and receives
     *   the collateral asset
     **/
    function liquidate(uint256 loanId) external;

    function getReservesList() external view returns (address[] memory);

    /**
     * @dev Returns the debt data of the NFT
     * @return nftAsset the address of the NFT
     * @return nftTokenId nft token ID
     * @return reserveAsset the address of the Reserve
     * @return totalCollateral the total power of the NFT
     * @return totalDebt the total debt of the NFT
     * @return healthFactor the current health factor of the NFT
     **/
    function getNftDebtData(
        uint256 loanId
    )
        external
        view
        returns (
            address nftAsset,
            uint256 nftTokenId,
            address reserveAsset,
            uint256 totalCollateral,
            uint256 totalDebt,
            uint256 healthFactor
        );

    /**
     * @dev Returns the auction data of the NFT
     * @param loanId the loan id of the NFT
     * @return nftAsset The address of the NFT
     * @return nftTokenId The token id of the NFT
     * @return bidderAddress the highest bidder address of the loan
     * @return bidPrice the highest bid price in Reserve of the loan
     * @return bidBorrowAmount the borrow amount in Reserve of the loan
     * @return bidFine the penalty fine of the loan
     **/
    function getNftAuctionData(
        uint256 loanId
    )
        external
        view
        returns (
            address nftAsset,
            uint256 nftTokenId,
            address bidderAddress,
            uint256 bidPrice,
            uint256 bidBorrowAmount,
            uint256 bidFine
        );

    function getNftAuctionEndTime(
        uint256 loanId
    )
        external
        view
        returns (
            address nftAsset,
            uint256 nftTokenId,
            uint256 bidStartTimestamp,
            uint256 bidEndTimestamp,
            uint256 redeemEndTimestamp
        );

    function getNftLiquidatePrice(
        uint256 loanId
    ) external view returns (uint256 liquidatePrice, uint256 paybackAmount);

    function getNftsList() external view returns (address[] memory);

    function setPause(bool val) external;

    function paused() external view returns (bool);

    function getConfigProvider() external view returns (IConfigProvider);

    function addReserve(address asset) external;

    function addNftCollection(
        address nftAddress,
        string memory collection,
        uint256 maxSupply
    ) external;
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