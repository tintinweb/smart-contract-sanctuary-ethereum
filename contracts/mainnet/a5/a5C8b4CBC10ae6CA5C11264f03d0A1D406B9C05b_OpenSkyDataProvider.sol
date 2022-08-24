// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

import '../interfaces/IOpenSkySettings.sol';
import '../interfaces/IOpenSkyMoneyMarket.sol';
import '../interfaces/IOpenSkyDataProvider.sol';
import '../interfaces/IOpenSkyPool.sol';
import '../interfaces/IOpenSkyOToken.sol';
import '../interfaces/IOpenSkyLoan.sol';
import '../interfaces/IOpenSkyInterestRateStrategy.sol';

import '../libraries/math/WadRayMath.sol';
import '../libraries/math/MathUtils.sol';
import '../libraries/types/DataTypes.sol';

contract OpenSkyDataProvider is IOpenSkyDataProvider {
    using WadRayMath for uint256;

    IOpenSkySettings public immutable SETTINGS;

    constructor(IOpenSkySettings settings) {
        SETTINGS = settings;
    }

    function getReserveData(uint256 reserveId) external view override returns (ReserveData memory) {
        IOpenSkyPool pool = IOpenSkyPool(SETTINGS.poolAddress());
        DataTypes.ReserveData memory reserve = pool.getReserveData(reserveId);
        IERC20 oToken = IERC20(reserve.oTokenAddress);
        return
            ReserveData({
                reserveId: reserveId,
                underlyingAsset: reserve.underlyingAsset,
                oTokenAddress: reserve.oTokenAddress,
                TVL: pool.getTVL(reserveId),
                totalDeposits: oToken.totalSupply(),
                totalBorrowsBalance: pool.getTotalBorrowBalance(reserveId),
                supplyRate: getSupplyRate(reserveId),
                borrowRate: getBorrowRate(reserveId, 0, 0, 0, 0),
                availableLiquidity: pool.getAvailableLiquidity(reserveId)
            });
    }

    function getTVL(uint256 reserveId) external view override returns (uint256) {
        return IOpenSkyPool(SETTINGS.poolAddress()).getTVL(reserveId);
    }

    function getTotalBorrowBalance(uint256 reserveId) external view override returns (uint256) {
        return IOpenSkyPool(SETTINGS.poolAddress()).getTotalBorrowBalance(reserveId);
    }

    function getAvailableLiquidity(uint256 reserveId) external view override returns (uint256) {
        return IOpenSkyPool(SETTINGS.poolAddress()).getAvailableLiquidity(reserveId);
    }

    function getSupplyRate(uint256 reserveId) public view override returns (uint256) {
        DataTypes.ReserveData memory reserve = IOpenSkyPool(SETTINGS.poolAddress()).getReserveData(reserveId);

        uint256 tvl = IOpenSkyOToken(reserve.oTokenAddress).principleTotalSupply();

        (, uint256 utilizationRate) = MathUtils.calculateLoanSupplyRate(
            tvl,
            reserve.totalBorrows,
            getBorrowRate(reserveId, 0, 0, 0, 0)
        );

        return
            getLoanSupplyRate(reserveId) + ((WadRayMath.ray() - utilizationRate).rayMul(getMoneyMarketSupplyRateInstant(reserveId)));
    }

    function getLoanSupplyRate(uint256 reserveId) public view override returns (uint256) {
        DataTypes.ReserveData memory reserve = IOpenSkyPool(SETTINGS.poolAddress()).getReserveData(reserveId);
        uint256 tvl = IOpenSkyOToken(reserve.oTokenAddress).principleTotalSupply();
        (uint256 loanSupplyRate, ) = MathUtils.calculateLoanSupplyRate(
            tvl,
            reserve.totalBorrows,
            getBorrowRate(reserveId, 0, 0, 0, 0)
        );
        return loanSupplyRate;
    }

    function getMoneyMarketSupplyRateInstant(uint256 reserveId) public view override returns (uint256) {
        DataTypes.ReserveData memory reserve = IOpenSkyPool(SETTINGS.poolAddress()).getReserveData(reserveId);
        if (reserve.isMoneyMarketOn) {
            return IOpenSkyMoneyMarket(reserve.moneyMarketAddress).getSupplyRate(reserve.underlyingAsset);
        } else {
            return 0;
        }
    }

    function getBorrowRate(
        uint256 reserveId,
        uint256 liquidityAmountToAdd,
        uint256 liquidityAmountToRemove,
        uint256 borrowAmountToAdd,
        uint256 borrowAmountToRemove
    ) public view override returns (uint256) {
        DataTypes.ReserveData memory reserve = IOpenSkyPool(SETTINGS.poolAddress()).getReserveData(reserveId);
        return
            IOpenSkyInterestRateStrategy(reserve.interestModelAddress).getBorrowRate(
                reserveId,
                IOpenSkyOToken(reserve.oTokenAddress).totalSupply() + liquidityAmountToAdd - liquidityAmountToRemove,
                reserve.totalBorrows + borrowAmountToAdd - borrowAmountToRemove
            );
    }

    function getSupplyBalance(uint256 reserveId, address account) external view override returns (uint256) {
        DataTypes.ReserveData memory reserve = IOpenSkyPool(SETTINGS.poolAddress()).getReserveData(reserveId);
        return IERC20(reserve.oTokenAddress).balanceOf(account);
    }

    function getLoanData(uint256 loanId) external view override returns (LoanData memory) {
        IOpenSkyLoan loanNFT = IOpenSkyLoan(SETTINGS.loanAddress());
        DataTypes.LoanData memory loan = loanNFT.getLoanData(loanId);
        return
            LoanData({
                loanId: loanId,
                totalBorrows: loan.amount,
                borrowBalance: loanNFT.getBorrowBalance(loanId),
                borrowBegin: loan.borrowBegin,
                borrowDuration: loan.borrowDuration,
                borrowOverdueTime: loan.borrowOverdueTime,
                liquidatableTime: loan.liquidatableTime,
                extendableTime: loan.extendableTime,
                borrowRate: loan.borrowRate,
                interestPerSecond: loan.interestPerSecond,
                penalty: loanNFT.getPenalty(loanId),
                status: loan.status
            });
    }

    function getLoansByUser(address account) external view override returns (uint256[] memory) {
        IERC721Enumerable loanNFT = IERC721Enumerable(SETTINGS.loanAddress());
        uint256 amount = loanNFT.balanceOf(account);
        uint256[] memory ids = new uint256[](amount > 0 ? amount : 0);
        for (uint256 i = 0; i < amount; ++i) {
            ids[i] = loanNFT.tokenOfOwnerByIndex(account, i);
        }
        return ids;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import '../libraries/types/DataTypes.sol';

interface IOpenSkySettings {
    event InitPoolAddress(address operator, address address_);
    event InitLoanAddress(address operator, address address_);
    event InitVaultFactoryAddress(address operator, address address_);
    event InitIncentiveControllerAddress(address operator, address address_);
    event InitWETHGatewayAddress(address operator, address address_);
    event InitPunkGatewayAddress(address operator, address address_);
    event InitDaoVaultAddress(address operator, address address_);

    event AddToWhitelist(address operator, uint256 reserveId, address nft);
    event RemoveFromWhitelist(address operator, uint256 reserveId, address nft);
    event SetReserveFactor(address operator, uint256 factor);
    event SetPrepaymentFeeFactor(address operator, uint256 factor);
    event SetOverdueLoanFeeFactor(address operator, uint256 factor);
    event SetMoneyMarketAddress(address operator, address address_);
    event SetTreasuryAddress(address operator, address address_);
    event SetACLManagerAddress(address operator, address address_);
    event SetLoanDescriptorAddress(address operator, address address_);
    event SetNftPriceOracleAddress(address operator, address address_);
    event SetInterestRateStrategyAddress(address operator, address address_);
    event AddLiquidator(address operator, address address_);
    event RemoveLiquidator(address operator, address address_);

    function poolAddress() external view returns (address);

    function loanAddress() external view returns (address);

    function vaultFactoryAddress() external view returns (address);

    function incentiveControllerAddress() external view returns (address);

    function wethGatewayAddress() external view returns (address);

    function punkGatewayAddress() external view returns (address);

    function inWhitelist(uint256 reserveId, address nft) external view returns (bool);

    function getWhitelistDetail(uint256 reserveId, address nft) external view returns (DataTypes.WhitelistInfo memory);

    function reserveFactor() external view returns (uint256); // treasury ratio

    function MAX_RESERVE_FACTOR() external view returns (uint256);

    function prepaymentFeeFactor() external view returns (uint256);

    function overdueLoanFeeFactor() external view returns (uint256);

    function moneyMarketAddress() external view returns (address);

    function treasuryAddress() external view returns (address);

    function daoVaultAddress() external view returns (address);

    function ACLManagerAddress() external view returns (address);

    function loanDescriptorAddress() external view returns (address);

    function nftPriceOracleAddress() external view returns (address);

    function interestRateStrategyAddress() external view returns (address);
    
    function isLiquidator(address liquidator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IOpenSkyMoneyMarket {

    function depositCall(address asset, uint256 amount) external;

    function withdrawCall(address asset, uint256 amount, address to) external;

    function getMoneyMarketToken(address asset) external view returns (address);

    function getBalance(address asset, address account) external view returns (uint256);

    function getSupplyRate(address asset) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '../libraries/types/DataTypes.sol';

interface IOpenSkyDataProvider {
    struct ReserveData {
        uint256 reserveId;
        address underlyingAsset;
        address oTokenAddress;
        uint256 TVL;
        uint256 totalDeposits;
        uint256 totalBorrowsBalance;
        uint256 supplyRate;
        uint256 borrowRate;
        uint256 availableLiquidity;
    }

    struct LoanData {
        uint256 loanId;
        uint256 totalBorrows;
        uint256 borrowBalance;
        uint40 borrowBegin;
        uint40 borrowDuration;
        uint40 borrowOverdueTime;
        uint40 liquidatableTime;
        uint40 extendableTime;
        uint128 borrowRate;
        uint128 interestPerSecond;
        uint256 penalty;
        DataTypes.LoanStatus status;
    }

    function getReserveData(uint256 reserveId) external view returns (ReserveData memory);

    function getTVL(uint256 reserveId) external view returns (uint256);

    function getTotalBorrowBalance(uint256 reserveId) external view returns (uint256);

    function getAvailableLiquidity(uint256 reserveId) external view returns (uint256);

    function getSupplyRate(uint256 reserveId) external view returns (uint256);

    function getLoanSupplyRate(uint256 reserveId) external view returns (uint256);

    function getBorrowRate(
        uint256 reserveId,
        uint256 liquidityAmountToAdd,
        uint256 liquidityAmountToRemove,
        uint256 borrowAmountToAdd,
        uint256 borrowAmountToRemove
    ) external view returns (uint256);

    function getMoneyMarketSupplyRateInstant(uint256 reserveId) external view returns (uint256);

    function getSupplyBalance(uint256 reserveId, address account) external view returns (uint256);

    function getLoanData(uint256 loanId) external view returns (LoanData memory);

    function getLoansByUser(address account) external view returns (uint256[] memory arr);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '../libraries/types/DataTypes.sol';

/**
 * @title IOpenSkyPool
 * @author OpenSky Labs
 * @notice Defines the basic interface for an OpenSky Pool.
 **/

interface IOpenSkyPool {
    /*
     * @dev Emitted on create()
     * @param reserveId The ID of the reserve
     * @param underlyingAsset The address of the underlying asset
     * @param oTokenAddress The address of the oToken
     * @param name The name to use for oToken
     * @param symbol The symbol to use for oToken
     * @param decimals The decimals of the oToken
     */
    event Create(
        uint256 indexed reserveId,
        address indexed underlyingAsset,
        address indexed oTokenAddress,
        string name,
        string symbol,
        uint8 decimals
    );

    /*
     * @dev Emitted on setTreasuryFactor()
     * @param reserveId The ID of the reserve
     * @param factor The new treasury factor of the reserve
     */
    event SetTreasuryFactor(uint256 indexed reserveId, uint256 factor);

    /*
     * @dev Emitted on setInterestModelAddress()
     * @param reserveId The ID of the reserve
     * @param interestModelAddress The address of the interest model contract
     */
    event SetInterestModelAddress(uint256 indexed reserveId, address interestModelAddress);

    /*
     * @dev Emitted on openMoneyMarket()
     * @param reserveId The ID of the reserve
     */
    event OpenMoneyMarket(uint256 reserveId);

    /*
     * @dev Emitted on closeMoneyMarket()
     * @param reserveId The ID of the reserve
     */
    event CloseMoneyMarket(uint256 reserveId);

    /*
     * @dev Emitted on deposit()
     * @param reserveId The ID of the reserve
     * @param onBehalfOf The address that will receive the oTokens
     * @param amount The amount of ETH to be deposited
     * @param referralCode integrators are assigned a referral code and can potentially receive rewards
     * 0 if the action is executed directly by the user, without any intermediaries
     */
    event Deposit(uint256 indexed reserveId, address indexed onBehalfOf, uint256 amount, uint256 referralCode);

    /*
     * @dev Emitted on withdraw()
     * @param reserveId The ID of the reserve
     * @param onBehalfOf The address that will receive assets withdrawed
     * @param amount The amount to be withdrawn
     */
    event Withdraw(uint256 indexed reserveId, address indexed onBehalfOf, uint256 amount);

    /*
     * @dev Emitted on borrow()
     * @param reserveId The ID of the reserve
     * @param user The address initiating the withdrawal(), owner of oTokens
     * @param onBehalfOf The address that will receive the ETH and the loan NFT
     * @param loanId The loan ID
     */
    event Borrow(
        uint256 indexed reserveId,
        address user,
        address indexed onBehalfOf,
        uint256 indexed loanId
    );

    /*
     * @dev Emitted on repay()
     * @param reserveId The ID of the reserve
     * @param repayer The address initiating the repayment()
     * @param onBehalfOf The address that will receive the pledged NFT
     * @param loanId The ID of the loan
     * @param repayAmount The borrow balance of the loan when it was repaid
     * @param penalty The penalty of the loan for either early or overdue repayment
     */
    event Repay(
        uint256 indexed reserveId,
        address repayer,
        address indexed onBehalfOf,
        uint256 indexed loanId,
        uint256 repayAmount,
        uint256 penalty
    );

    /*
     * @dev Emitted on extend()
     * @param reserveId The ID of the reserve
     * @param onBehalfOf The owner address of loan NFT
     * @param oldLoanId The ID of the old loan
     * @param newLoanId The ID of the new loan
     */
    event Extend(uint256 indexed reserveId, address indexed onBehalfOf, uint256 oldLoanId, uint256 newLoanId);

    /*
     * @dev Emitted on startLiquidation()
     * @param reserveId The ID of the reserve
     * @param loanId The ID of the loan
     * @param nftAddress The address of the NFT used as collateral
     * @param tokenId The ID of the NFT used as collateral
     * @param operator The address initiating startLiquidation()
     */
    event StartLiquidation(
        uint256 indexed reserveId,
        uint256 indexed loanId,
        address indexed nftAddress,
        uint256 tokenId,
        address operator
    );

    /*
     * @dev Emitted on endLiquidation()
     * @param reserveId The ID of the reserve
     * @param loanId The ID of the loan
     * @param nftAddress The address of the NFT used as collateral
     * @param tokenId The ID of the NFT used as collateral
     * @param operator
     * @param repayAmount The amount used to repay, must be equal to or greater than the borrowBalance, excess part will be shared by all the lenders
     * @param borrowBalance The borrow balance of the loan
     */
    event EndLiquidation(
        uint256 indexed reserveId,
        uint256 indexed loanId,
        address indexed nftAddress,
        uint256 tokenId,
        address operator,
        uint256 repayAmount,
        uint256 borrowBalance
    );

    /**
     * @notice Creates a reserve
     * @dev Only callable by the pool admin role
     * @param underlyingAsset The address of the underlying asset
     * @param name The name of the oToken
     * @param symbol The symbol for the oToken
     * @param decimals The decimals of the oToken
     **/
    function create(
        address underlyingAsset,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external;

    /**
     * @notice Updates the treasury factor of a reserve
     * @dev Only callable by the pool admin role
     * @param reserveId The ID of the reserve
     * @param factor The new treasury factor of the reserve
     **/
    function setTreasuryFactor(uint256 reserveId, uint256 factor) external;

    /**
     * @notice Updates the interest model address of a reserve
     * @dev Only callable by the pool admin role
     * @param reserveId The ID of the reserve
     * @param interestModelAddress The new address of the interest model contract
     **/
    function setInterestModelAddress(uint256 reserveId, address interestModelAddress) external;

    /**
     * @notice Open the money market
     * @dev Only callable by the emergency admin role
     * @param reserveId The ID of the reserve
     **/
    function openMoneyMarket(uint256 reserveId) external;

    /**
     * @notice Close the money market
     * @dev Only callable by the emergency admin role
     * @param reserveId The ID of the reserve
     **/
    function closeMoneyMarket(uint256 reserveId) external;

    /**
     * @dev Deposits ETH into the reserve.
     * @param reserveId The ID of the reserve
     * @param referralCode integrators are assigned a referral code and can potentially receive rewards
     **/
    function deposit(uint256 reserveId, uint256 amount, address onBehalfOf, uint256 referralCode) external;

    /**
     * @dev withdraws the ETH from reserve.
     * @param reserveId The ID of the reserve
     * @param amount amount of oETH to withdraw and receive native ETH
     **/
    function withdraw(uint256 reserveId, uint256 amount, address onBehalfOf) external;

    /**
     * @dev Borrows ETH from reserve using an NFT as collateral and will receive a loan NFT as receipt.
     * @param reserveId The ID of the reserve
     * @param amount amount of ETH user will borrow
     * @param duration The desired duration of the loan
     * @param nftAddress The collateral NFT address
     * @param tokenId The ID of the NFT
     * @param onBehalfOf address of the user who will receive ETH and loan NFT.
     **/
    function borrow(
        uint256 reserveId,
        uint256 amount,
        uint256 duration,
        address nftAddress,
        uint256 tokenId,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @dev Repays a loan, as a result the corresponding loan NFT owner will receive the collateralized NFT.
     * @param loanId The ID of the loan the user will repay
     */
    function repay(uint256 loanId) external returns (uint256);

    /**
     * @dev Extends creates a new loan and terminates the old loan.
     * @param loanId The loan ID to extend
     * @param amount The amount of ERC20 token the user will borrow in the new loan
     * @param duration The selected duration the user will borrow in the new loan
     * @param onBehalfOf The address will borrow in the new loan
     **/
    function extend(
        uint256 loanId,
        uint256 amount,
        uint256 duration,
        address onBehalfOf
    ) external returns (uint256, uint256);

    /**
     * @dev Starts liquidation for a loan when it's in LIQUIDATABLE status
     * @param loanId The ID of the loan which will be liquidated
     */
    function startLiquidation(uint256 loanId) external;

    /**
     * @dev Completes liquidation for a loan which will be repaid.
     * @param loanId The ID of the liquidated loan that will be repaid.
     * @param amount The amount of the token that will be repaid.
     */
    function endLiquidation(uint256 loanId, uint256 amount) external;

    /**
     * @dev Returns the state of the reserve
     * @param reserveId The ID of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(uint256 reserveId) external view returns (DataTypes.ReserveData memory);

    /**
     * @dev Returns the normalized income of the reserve
     * @param reserveId The ID of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(uint256 reserveId) external view returns (uint256);

    /**
     * @dev Returns the remaining liquidity of the reserve
     * @param reserveId The ID of the reserve
     * @return The reserve's withdrawable balance
     */
    function getAvailableLiquidity(uint256 reserveId) external view returns (uint256);

    /**
     * @dev Returns the instantaneous borrow limit value of a special NFT
     * @param nftAddress The address of the NFT
     * @param tokenId The ID of the NFT
     * @return The NFT's borrow limit
     */
    function getBorrowLimitByOracle(
        uint256 reserveId,
        address nftAddress,
        uint256 tokenId
    ) external view returns (uint256);

    /**
     * @dev Returns the sum of all users borrow balances include borrow interest accrued
     * @param reserveId The ID of the reserve
     * @return The total borrow balance of the reserve
     */
    function getTotalBorrowBalance(uint256 reserveId) external view returns (uint256);

    /**
     * @dev Returns TVL (total value locked) of the reserve.
     * @param reserveId The ID of the reserve
     * @return The reserve's TVL
     */
    function getTVL(uint256 reserveId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IOpenSkyOToken is IERC20 {
    event Mint(address indexed account, uint256 amount, uint256 index);
    event Burn(address indexed account, uint256 amount, uint256 index);
    event MintToTreasury(address treasury, uint256 amount, uint256 index);
    event Deposit(uint256 amount);
    event Withdraw(uint256 amount);

    function mint(
        address account,
        uint256 amount,
        uint256 index
    ) external;

    function burn(
        address account,
        uint256 amount,
        uint256 index
    ) external;

    function mintToTreasury(uint256 amount, uint256 index) external;

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount, address to) external;

    function scaledBalanceOf(address account) external view returns (uint256);

    function principleBalanceOf(address account) external view returns (uint256);

    function scaledTotalSupply() external view returns (uint256);

    function principleTotalSupply() external view returns (uint256);

    function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

    function claimERC20Rewards(address token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '../libraries/types/DataTypes.sol';

/**
 * @title IOpenSkyLoan
 * @author OpenSky Labs
 * @notice Defines the basic interface for OpenSkyLoan.  This loan NFT is composable and can be used in other DeFi protocols 
 **/
interface IOpenSkyLoan is IERC721 {

    /**
     * @dev Emitted on mint()
     * @param tokenId The ID of the loan
     * @param recipient The address that will receive the loan NFT
     **/
    event Mint(uint256 indexed tokenId, address indexed recipient);

    /**
     * @dev Emitted on end()
     * @param tokenId The ID of the loan
     * @param onBehalfOf The address the repayer is repaying for
     * @param repayer The address of the user initiating the repayment()
     **/
    event End(uint256 indexed tokenId, address indexed onBehalfOf, address indexed repayer);

    /**
     * @dev Emitted on startLiquidation()
     * @param tokenId The ID of the loan
     * @param liquidator The address of the liquidator
     **/
    event StartLiquidation(uint256 indexed tokenId, address indexed liquidator);

    /**
     * @dev Emitted on endLiquidation()
     * @param tokenId The ID of the loan
     * @param liquidator The address of the liquidator
     **/
    event EndLiquidation(uint256 indexed tokenId, address indexed liquidator);

    /**
     * @dev Emitted on updateStatus()
     * @param tokenId The ID of the loan
     * @param status The status of loan
     **/
    event UpdateStatus(uint256 indexed tokenId, DataTypes.LoanStatus indexed status);

    /**
     * @dev Emitted on flashClaim()
     * @param receiver The address of the flash loan receiver contract
     * @param sender The address that will receive tokens
     * @param nftAddress The address of the collateralized NFT
     * @param tokenId The ID of collateralized NFT
     **/
    event FlashClaim(address indexed receiver, address sender, address indexed nftAddress, uint256 indexed tokenId);

    /**
     * @dev Emitted on claimERC20Airdrop()
     * @param token The address of the ERC20 token
     * @param to The address that will receive the ERC20 tokens
     * @param amount The amount of the tokens
     **/
    event ClaimERC20Airdrop(address indexed token, address indexed to, uint256 amount);

    /**
     * @dev Emitted on claimERC721Airdrop()
     * @param token The address of ERC721 token
     * @param to The address that will receive the eRC721 tokens
     * @param ids The ID of the token
     **/
    event ClaimERC721Airdrop(address indexed token, address indexed to, uint256[] ids);

    /**
     * @dev Emitted on claimERC1155Airdrop()
     * @param token The address of the ERC1155 token
     * @param to The address that will receive the ERC1155 tokens
     * @param ids The ID of the token
     * @param amounts The amount of the tokens
     * @param data packed params to pass to the receiver as extra information
     **/
    event ClaimERC1155Airdrop(address indexed token, address indexed to, uint256[] ids, uint256[] amounts, bytes data);

    /**
     * @notice Mints a loan NFT to user
     * @param reserveId The ID of the reserve
     * @param borrower The address of the borrower
     * @param nftAddress The contract address of the collateralized NFT 
     * @param nftTokenId The ID of the collateralized NFT
     * @param amount The amount of the loan
     * @param duration The duration of the loan
     * @param borrowRate The borrow rate of the loan
     * @return loanId and loan data
     **/
    function mint(
        uint256 reserveId,
        address borrower,
        address nftAddress,
        uint256 nftTokenId,
        uint256 amount,
        uint256 duration,
        uint256 borrowRate
    ) external returns (uint256 loanId, DataTypes.LoanData memory loan);

    /**
     * @notice Starts liquidation of the loan in default
     * @param tokenId The ID of the defaulted loan
     **/
    function startLiquidation(uint256 tokenId) external;

    /**
     * @notice Ends liquidation of a loan that is fully settled
     * @param tokenId The ID of the loan
     **/
    function endLiquidation(uint256 tokenId) external;

    /**
     * @notice Terminates the loan
     * @param tokenId The ID of the loan
     * @param onBehalfOf The address the repayer is repaying for
     * @param repayer The address of the repayer
     **/
    function end(uint256 tokenId, address onBehalfOf, address repayer) external;
    
    /**
     * @notice Returns the loan data
     * @param tokenId The ID of the loan
     * @return The details of the loan
     **/
    function getLoanData(uint256 tokenId) external view returns (DataTypes.LoanData calldata);

    /**
     * @notice Returns the status of a loan
     * @param tokenId The ID of the loan
     * @return The status of the loan
     **/
    function getStatus(uint256 tokenId) external view returns (DataTypes.LoanStatus);

    /**
     * @notice Returns the borrow interest of the loan
     * @param tokenId The ID of the loan
     * @return The borrow interest of the loan
     **/
    function getBorrowInterest(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Returns the borrow balance of a loan, including borrow interest
     * @param tokenId The ID of the loan
     * @return The borrow balance of the loan
     **/
    function getBorrowBalance(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Returns the penalty fee of the loan
     * @param tokenId The ID of the loan
     * @return The penalty fee of the loan
     **/
    function getPenalty(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Returns the ID of the loan
     * @param nftAddress The address of the collateralized NFT
     * @param tokenId The ID of the collateralized NFT
     * @return The ID of the loan
     **/
    function getLoanId(address nftAddress, uint256 tokenId) external view returns (uint256);

    /**
     * @notice Allows smart contracts to access the collateralized NFT within one transaction,
     * as long as the amount taken plus a fee is returned
     * @dev IMPORTANT There are security concerns for developers of flash loan receiver contracts that must be carefully considered
     * @param receiverAddress The address of the contract receiving the funds, implementing IOpenSkyFlashClaimReceiver interface
     * @param loanIds The ID of loan being flash-borrowed
     * @param params packed params to pass to the receiver as extra information
     **/
    function flashClaim(
        address receiverAddress,
        uint256[] calldata loanIds,
        bytes calldata params
    ) external;

    /**
     * @notice Claim the ERC20 token which has been airdropped to the loan contract
     * @param token The address of the airdropped token
     * @param to The address which will receive ERC20 token
     * @param amount The amount of the ERC20 token
     **/
    function claimERC20Airdrop(
        address token,
        address to,
        uint256 amount
    ) external;

    /**
     * @notice Claim the ERC721 token which has been airdropped to the loan contract
     * @param token The address of the airdropped token
     * @param to The address which will receive the ERC721 token
     * @param ids The ID of the ERC721 token
     **/
    function claimERC721Airdrop(
        address token,
        address to,
        uint256[] calldata ids
    ) external;

    /**
     * @notice Claim the ERC1155 token which has been airdropped to the loan contract
     * @param token The address of the airdropped token
     * @param to The address which will receive the ERC1155 tokens
     * @param ids The ID of the ERC1155 token
     * @param amounts The amount of the ERC1155 tokens
     * @param data packed params to pass to the receiver as extra information
     **/
    function claimERC1155Airdrop(
        address token,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @title IOpenSkyInterestRateStrategy
 * @author OpenSky Labs
 * @notice Interface for the calculation of the interest rates
 */
interface IOpenSkyInterestRateStrategy {
    /**
     * @dev Emitted on setBaseBorrowRate()
     * @param reserveId The id of the reserve
     * @param baseRate The base rate has been set
     **/
    event SetBaseBorrowRate(
        uint256 indexed reserveId,
        uint256 indexed baseRate
    );

    /**
     * @notice Returns the borrow rate of a reserve
     * @param reserveId The id of the reserve
     * @param totalDeposits The total deposits amount of the reserve
     * @param totalBorrows The total borrows amount of the reserve
     * @return The borrow rate, expressed in ray
     **/
    function getBorrowRate(uint256 reserveId, uint256 totalDeposits, uint256 totalBorrows) external view returns (uint256); 
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {Errors} from '../helpers/Errors.sol';

/**
 * @title WadRayMath library
 * @author Aave
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant halfWAD = WAD / 2;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant halfRAY = RAY / 2;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    /**
     * @return One ray, 1e27
     **/
    function ray() internal pure returns (uint256) {
        return RAY;
    }

    /**
     * @return One wad, 1e18
     **/

    function wad() internal pure returns (uint256) {
        return WAD;
    }

    /**
     * @return Half ray, 1e27/2
     **/
    function halfRay() internal pure returns (uint256) {
        return halfRAY;
    }

    /**
     * @return Half ray, 1e18/2
     **/
    function halfWad() internal pure returns (uint256) {
        return halfWAD;
    }

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a*b, in wad
     **/
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        require(a <= (type(uint256).max - halfWAD) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

        return (a * b + halfWAD) / WAD;
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a/b, in wad
     **/
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
        uint256 halfB = b / 2;

        require(a <= (type(uint256).max - halfB) / WAD, Errors.MATH_MULTIPLICATION_OVERFLOW);

        return (a * WAD + halfB) / b;
    }

    /**
     * @dev Multiplies two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a*b, in ray
     **/
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        require(a <= (type(uint256).max - halfRAY) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

        return (a * b + halfRAY) / RAY;
    }

    /**
     * @dev Multiplies two ray, truncating the mantissa
     * @param a Ray
     * @param b Ray
     * @return The result of a*b, in ray
     **/
    function rayMulTruncate(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        return (a * b) / RAY;
    }

    /**
     * @dev Divides two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a/b, in ray
     **/
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
        uint256 halfB = b / 2;

        require(a <= (type(uint256).max - halfB) / RAY, Errors.MATH_MULTIPLICATION_OVERFLOW);

        return (a * RAY + halfB) / b;
    }

    /**
     * @dev Divides two ray, truncating the mantissa
     * @param a Ray
     * @param b Ray
     * @return The result of a/b, in ray
     **/
    function rayDivTruncate(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
        return (a * RAY) / b;
    }

    /**
     * @dev Casts ray down to wad
     * @param a Ray
     * @return a casted to wad, rounded half up to the nearest wad
     **/
    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio = WAD_RAY_RATIO / 2;
        uint256 result = halfRatio + a;
        require(result >= halfRatio, Errors.MATH_ADDITION_OVERFLOW);

        return result / WAD_RAY_RATIO;
    }

    /**
     * @dev Converts wad up to ray
     * @param a Wad
     * @return a converted in ray
     **/
    function wadToRay(uint256 a) internal pure returns (uint256) {
        uint256 result = a * WAD_RAY_RATIO;
        require(result / WAD_RAY_RATIO == a, Errors.MATH_MULTIPLICATION_OVERFLOW);
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {WadRayMath} from './WadRayMath.sol';

library MathUtils {
    using WadRayMath for uint256;

    /// @dev Ignoring leap years
    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    /**
     * @dev Function to calculate the interest accumulated using a linear interest rate formula
     * @param rate The interest rate, in ray
     * @param lastUpdateTimestamp The timestamp of the last update of the interest
     * @return The interest rate linearly accumulated during the timeDelta, in ray
     **/

    function calculateLinearInterest(uint256 rate, uint40 lastUpdateTimestamp) external view returns (uint256) {
        //solium-disable-next-line
        uint256 timeDifference = block.timestamp - (uint256(lastUpdateTimestamp));

        return (rate * timeDifference) / SECONDS_PER_YEAR + WadRayMath.ray();
    }

    function calculateBorrowInterest(
        uint256 borrowRate,
        uint256 amount,
        uint256 duration
    ) external pure returns (uint256) {
        return amount.rayMul(borrowRate.rayMul(duration).rayDiv(SECONDS_PER_YEAR));
    }

    function calculateBorrowInterestPerSecond(uint256 borrowRate, uint256 amount) external pure returns (uint256) {
        return amount.rayMul(borrowRate).rayDiv(SECONDS_PER_YEAR);
    }

    function calculateLoanSupplyRate(
        uint256 availableLiquidity,
        uint256 totalBorrows,
        uint256 borrowRate
    ) external pure returns (uint256 loanSupplyRate, uint256 utilizationRate) {
        utilizationRate = (totalBorrows == 0 && availableLiquidity == 0)
            ? 0
            : totalBorrows.rayDiv(availableLiquidity + totalBorrows);
        loanSupplyRate = utilizationRate.rayMul(borrowRate);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library DataTypes {
    struct ReserveData {
        uint256 reserveId;
        address underlyingAsset;
        address oTokenAddress;
        address moneyMarketAddress;
        uint128 lastSupplyIndex;
        uint256 borrowingInterestPerSecond;
        uint256 lastMoneyMarketBalance;
        uint40 lastUpdateTimestamp;
        uint256 totalBorrows;
        address interestModelAddress;
        uint256 treasuryFactor;
        bool isMoneyMarketOn;
    }

    struct LoanData {
        uint256 reserveId;
        address nftAddress;
        uint256 tokenId;
        address borrower;
        uint256 amount;
        uint128 borrowRate;
        uint128 interestPerSecond;
        uint40 borrowBegin;
        uint40 borrowDuration;
        uint40 borrowOverdueTime;
        uint40 liquidatableTime;
        uint40 extendableTime;
        uint40 borrowEnd;
        LoanStatus status;
    }

    enum LoanStatus {
        NONE,
        BORROWING,
        EXTENDABLE,
        OVERDUE,
        LIQUIDATABLE,
        LIQUIDATING
    }

    struct WhitelistInfo {
        bool enabled;
        string name;
        string symbol;
        uint256 LTV;
        uint256 minBorrowDuration;
        uint256 maxBorrowDuration;
        uint256 extendableDuration;
        uint256 overdueDuration;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library Errors {
    // common
    string public constant MATH_MULTIPLICATION_OVERFLOW = '100';
    string public constant MATH_ADDITION_OVERFLOW = '101';
    string public constant MATH_DIVISION_BY_ZERO = '102';

    string public constant ETH_TRANSFER_FAILED = '110';
    string public constant RECEIVE_NOT_ALLOWED = '111';
    string public constant FALLBACK_NOT_ALLOWED = '112';
    string public constant APPROVAL_FAILED = '113';

    // setting/factor
    string public constant SETTING_ZERO_ADDRESS_NOT_ALLOWED = '115';
    string public constant SETTING_RESERVE_FACTOR_NOT_ALLOWED = '116';
    string public constant SETTING_WHITELIST_INVALID_RESERVE_ID = '117';
    string public constant SETTING_WHITELIST_NFT_ADDRESS_IS_ZERO = '118';
    string public constant SETTING_WHITELIST_NFT_DURATION_OUT_OF_ORDER = '119';
    string public constant SETTING_WHITELIST_NFT_NAME_EMPTY = '120';
    string public constant SETTING_WHITELIST_NFT_SYMBOL_EMPTY = '121';
    string public constant SETTING_WHITELIST_NFT_LTV_NOT_ALLOWED = '122';

    // settings/acl
    string public constant ACL_ONLY_GOVERNANCE_CAN_CALL = '200';
    string public constant ACL_ONLY_EMERGENCY_ADMIN_CAN_CALL = '201';
    string public constant ACL_ONLY_POOL_ADMIN_CAN_CALL = '202';
    string public constant ACL_ONLY_LIQUIDATOR_CAN_CALL = '203';
    string public constant ACL_ONLY_AIRDROP_OPERATOR_CAN_CALL = '204';
    string public constant ACL_ONLY_POOL_CAN_CALL = '205';

    // lending & borrowing
    // reserve
    string public constant RESERVE_DOES_NOT_EXIST = '300';
    string public constant RESERVE_LIQUIDITY_INSUFFICIENT = '301';
    string public constant RESERVE_INDEX_OVERFLOW = '302';
    string public constant RESERVE_SWITCH_MONEY_MARKET_STATE_ERROR = '303';
    string public constant RESERVE_TREASURY_FACTOR_NOT_ALLOWED = '304';
    string public constant RESERVE_TOKEN_CAN_NOT_BE_CLAIMED = '305';

    // token
    string public constant AMOUNT_SCALED_IS_ZERO = '310';
    string public constant AMOUNT_TRANSFER_OVERFLOW = '311';

    //deposit
    string public constant DEPOSIT_AMOUNT_SHOULD_BE_BIGGER_THAN_ZERO = '320';

    // withdraw
    string public constant WITHDRAW_AMOUNT_NOT_ALLOWED = '321';
    string public constant WITHDRAW_LIQUIDITY_NOT_SUFFICIENT = '322';

    // borrow
    string public constant BORROW_DURATION_NOT_ALLOWED = '330';
    string public constant BORROW_AMOUNT_EXCEED_BORROW_LIMIT = '331';
    string public constant NFT_ADDRESS_IS_NOT_IN_WHITELIST = '332';

    // repay
    string public constant REPAY_STATUS_ERROR = '333';
    string public constant REPAY_MSG_VALUE_ERROR = '334';

    // extend
    string public constant EXTEND_STATUS_ERROR = '335';
    string public constant EXTEND_MSG_VALUE_ERROR = '336';

    // liquidate
    string public constant START_LIQUIDATION_STATUS_ERROR = '360';
    string public constant END_LIQUIDATION_STATUS_ERROR = '361';
    string public constant END_LIQUIDATION_AMOUNT_ERROR = '362';

    // loan
    string public constant LOAN_DOES_NOT_EXIST = '400';
    string public constant LOAN_SET_STATUS_ERROR = '401';
    string public constant LOAN_REPAYER_IS_NOT_OWNER = '402';
    string public constant LOAN_LIQUIDATING_STATUS_CAN_NOT_BE_UPDATED = '403';
    string public constant LOAN_CALLER_IS_NOT_OWNER = '404';
    string public constant LOAN_COLLATERAL_NFT_CAN_NOT_BE_CLAIMED = '405';

    string public constant FLASHCLAIM_EXECUTOR_ERROR = '410';
    string public constant FLASHCLAIM_STATUS_ERROR = '411';

    // money market
    string public constant MONEY_MARKET_DEPOSIT_AMOUNT_NOT_ALLOWED = '500';
    string public constant MONEY_MARKET_WITHDRAW_AMOUNT_NOT_ALLOWED = '501';
    string public constant MONEY_MARKET_APPROVAL_FAILED = '502';
    string public constant MONEY_MARKET_DELEGATE_CALL_ERROR = '503';
    string public constant MONEY_MARKET_REQUIRE_DELEGATE_CALL = '504';
    string public constant MONEY_MARKET_WITHDRAW_AMOUNT_NOT_MATCH = '505';

    // price oracle
    string public constant PRICE_ORACLE_HAS_NO_PRICE_FEED = '600';
    string public constant PRICE_ORACLE_INCORRECT_TIMESTAMP = '601';
    string public constant PRICE_ORACLE_PARAMS_ERROR = '602';
}