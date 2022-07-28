/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]


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


// File contracts/lib/interfaces/IERC20.sol


pragma solidity ^0.8.0;

interface IERC20 is IERC20Upgradeable{
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


// File contracts/lib/interfaces/ComptrollerInterface.sol


pragma solidity ^0.8.0;

interface ComptrollerInterface {

    function isComptroller() external view returns(bool);
    function oracle() external view returns(address);
    function distributioner() external view returns(address);
    function closeFactorMantissa() external view returns(uint);
    function liquidationIncentiveMantissa() external view returns(uint);
    function maxAssets() external view returns(uint);
    function accountAssets(address account,uint index) external view returns(address);
    function markets(address market) external view returns(bool,uint);

    function pauseGuardian() external view returns(address);
    function paused() external view returns(bool);
    function marketMintPaused(address market) external view returns(bool);
    function marketRedeemPaused(address market) external view returns(bool);
    function marketBorrowPaused(address market) external view returns(bool);
    function marketRepayBorrowPaused(address market) external view returns(bool);
    function marketTransferPaused(address market) external view returns(bool);
    function marketSeizePaused(address market) external view returns(bool);
    function borrowCaps(address market) external view returns(uint);
    function supplyCaps(address market) external view returns(uint);
    function liquidateWhiteAddresses(uint index) external view returns(address);

    function enterMarkets(address[] calldata marketTokens) external returns (uint[] memory);
    function exitMarket(address marketToken) external returns (uint);

    function mintAllowed(address marketToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(address marketToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address marketToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address marketToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address marketToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowVerify(address marketToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address marketToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);
    function repayBorrowVerify(
        address marketToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) external;

    function liquidateBorrowAllowed(
        address marketTokenBorrowed,
        address marketTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);
    function liquidateBorrowVerify(
        address marketTokenBorrowed,
        address marketTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external;

    function seizeAllowed(
        address marketTokenCollateral,
        address marketTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);
    function seizeVerify(
        address marketTokenCollateral,
        address marketTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address marketToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(address marketToken, address src, address dst, uint transferTokens) external;

    function liquidateCalculateSeizeTokens(
        address marketTokenBorrowed,
        address marketTokenCollateral,
        uint repayAmount) external view returns (uint, uint);

    function getHypotheticalAccountLiquidity(
        address account,
        address marketTokenModify,
        uint redeemTokens,
        uint borrowAmount) external view returns (uint, uint, uint);

    function getAssetsIn(address account) external view returns (address[] memory);
    function checkMembership(address account, address marketToken) external view returns (bool) ;
    function getAccountLiquidity(address account) external view returns (uint, uint, uint) ;
    function getAllMarkets() external view returns (address[] memory);
    function isDeprecated(address marketToken) external view returns (bool);
    function isMarketListed(address marketToken) external view returns (bool);

    
}


// File contracts/lib/interfaces/DistributionerInterface.sol


pragma solidity ^0.8.0;

interface DistributionerInterface {

    function _initializeMarket(address marketToken) external;

    function distributeMintReward(address marketToken, address minter) external;
    function distributeRedeemReward(address marketToken, address redeemer) external;
    function distributeBorrowReward(address marketToken, address borrower) external;
    function distributeRepayBorrowReward(address marketToken, address borrower) external;
    function distributeSeizeReward(address marketTokenCollateral, address borrower, address liquidator) external;
    function distributeTransferReward(address marketToken, address src, address dst) external;

    function rewardSupplySpeeds(address marketToken) external view returns(uint);
    function rewardBorrowSpeeds(address marketToken) external view returns(uint);
    function rewardAccrued(address account) external view returns(uint);
    function rewardToken() external view returns(address);

    function claimRewardToken(address holder) external;
    function claimRewardToken(address holder, address[] memory marketTokens) external;
    function claimRewardToken(address[] memory holders, address[] memory marketTokens, bool borrowers, bool suppliers) external;


}

interface DistributionerManagerInterface {
    function getDistributioners() external view returns(address[] memory);
}


// File contracts/lib/interfaces/MarketTokenInterface.sol


pragma solidity ^0.8.0;

interface MarketTokenInterface {
    function isMarketToken() external view returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function underlying() external view returns (address);
    function reserveFactorMantissa() external view returns (uint256);
    function accrualBlockTimestamp() external view returns (uint256);
    function borrowIndex() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function totalReserves() external view returns (uint256);
    function accountTokens(address account) external view returns (uint256);
    function accountBorrows(address account) external view returns (uint256,uint256);
    function protocolSeizeShareMantissa() external view returns (uint256);
    function comptroller() external view returns (address);
    function interestRateModel() external view returns (address);

    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerSecond() external view returns (uint);
    function supplyRatePerSecond() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);

    function _setComptroller(address newComptroller) external returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) external  returns (uint);
    function _reduceReserves(uint reduceAmount) external  returns (uint);
    function _setInterestRateModel(address newInterestRateModel) external  returns (uint);



    
}

interface MarketTokenEtherInterface is MarketTokenInterface{

    function mint() external payable;
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow() external payable;
    function repayBorrowBehalf(address borrower) external payable;
    function liquidateBorrow(address borrower, address marketTokenCollateral) external payable;

    function _addReserves() external payable returns (uint);

}

interface MarketTokenERC20Interface is MarketTokenInterface{

    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, address marketTokenCollateral) external returns (uint);
    function sweepToken(address token) external ;

    function _addReserves(uint addAmount) external returns (uint);

}


// File contracts/lib/interfaces/PriceOracle.sol


pragma solidity ^0.8.0;

interface PriceOracle {
    /**
      * @notice Get the underlying price of a marketToken asset
      * @param marketToken The marketToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e(36-decimals)).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(MarketTokenInterface marketToken) external view returns (uint);
}


interface PriceSource {
    /**
     * @notice Get the price of an token asset.
     * @param token The token asset to get the price of.
     * @return The token asset price in USD as a mantissa (scaled by 1e8).
    */
    function getPrice(address token) external view returns (uint);
}


// File contracts/lib/interfaces/JumpRateModelInterface.sol


pragma solidity ^0.8.0;


interface JumpRateModelInterface{

    function getBorrowRate(uint cash, uint borrows, uint reserves) external  view returns (uint);
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view returns (uint);
    function secondsPerYear() external view returns (uint);
    function multiplierPerSecond() external view returns (uint);
    function baseRatePerSecond() external view returns (uint);
    function jumpMultiplierPerSecond() external view returns (uint);
    function kink() external view returns (uint);

}


// File contracts/view/ProtocolDataView.sol


pragma solidity ^0.8.0;






contract ProtocolDataView {

    string public nativeSymbol;
    string public nativeName;
    address public owner;


    constructor(string memory _nativeSymbol, string memory _nativeName) {
    
        nativeSymbol = _nativeSymbol;
        nativeName = _nativeName;

        owner = msg.sender;
    }

    function getAllMarkets(ComptrollerInterface comptroller) public view returns (MarketTokenInterface[] memory){

        address[] memory _markets = comptroller.getAllMarkets();
        uint count = _markets.length;
        MarketTokenInterface[] memory markets = new MarketTokenInterface[](count);
        for(uint i =0; i < count; i++){
            markets[i] = MarketTokenInterface(_markets[i]);
        }
        return markets;
    }

    struct Rewards{
        address[] distributioners;
        address[] rewardTokens;
        uint[] supplySpeeds;
        uint[] borrowSpeeds;
    }

    struct PendingRewards {
        address[] rewardTokens;
        uint[] pendings;
    }

    struct Paused{
        bool mintPaused;
        bool redeemPaused;
        bool borrowPaused;
        bool repayBorrowPaused;
        bool transferPaused;
        bool seizePaused;
    }

    struct MarketMetadata {
        address marketAddress;
        uint marketDecimals;
        string marketSymbol;
        string marketName;
        address underlyingAddress;
        uint underlyingDecimals;
        string underlyingSymbol;
        string underlyingName;
        uint exchangeRateCurrent;
        uint supplyRatePerSecond;
        uint borrowRatePerSecond;
        uint reserveFactorMantissa;
        uint collateralFactorMantissa;
        uint totalBorrows;
        uint totalReserves;
        uint totalSupply;
        uint totalCash;
        uint price;
        uint accrualBlockTime;
        uint borrowIndex;
        uint supplyCaps;
        uint borrowCaps;
        Rewards rewards;
        Paused paused;
        bool isListed;
        bool deprecated;
        address interestRateModel;
    }

    function marketTokenMetadata(ComptrollerInterface comptroller, MarketTokenInterface marketToken) public returns (MarketMetadata memory){

        (bool isListed, uint collateralFactorMantissa) = comptroller.markets(address(marketToken));

        address underlyingAddress = marketToken.underlying();
        uint underlyingDecimals;
        string memory underlyingSymbol;
        string memory underlyingName;
        if ( underlyingAddress== 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE ) {
            underlyingDecimals = 18;
            underlyingSymbol = nativeSymbol;
            underlyingName = nativeName;
        } else {
            underlyingDecimals = IERC20(underlyingAddress).decimals();
            underlyingSymbol = IERC20(underlyingAddress).symbol();
            underlyingName = IERC20(underlyingAddress).name();
        }

        Rewards memory rewards = _getRewards(comptroller, address(marketToken));
        
        return MarketMetadata({
            marketAddress: address(marketToken),
            marketDecimals: marketToken.decimals(),
            marketSymbol: marketToken.symbol(),
            marketName: marketToken.name(),
            underlyingAddress: underlyingAddress,
            underlyingDecimals: underlyingDecimals,
            underlyingSymbol: underlyingSymbol,
            underlyingName: underlyingName,
            exchangeRateCurrent: marketToken.exchangeRateCurrent(),
            supplyRatePerSecond: marketToken.supplyRatePerSecond(),
            borrowRatePerSecond: marketToken.borrowRatePerSecond(),
            reserveFactorMantissa: marketToken.reserveFactorMantissa(),
            collateralFactorMantissa: collateralFactorMantissa,
            totalBorrows: marketToken.totalBorrows(),
            totalReserves: marketToken.totalReserves(),
            totalSupply: marketToken.totalSupply(),
            totalCash: marketToken.getCash(),
            price: PriceOracle(comptroller.oracle()).getUnderlyingPrice(marketToken),
            accrualBlockTime: marketToken.accrualBlockTimestamp(),
            borrowIndex: marketToken.borrowIndex(),
            supplyCaps: comptroller.supplyCaps(address(marketToken)),
            borrowCaps: comptroller.borrowCaps(address(marketToken)),
            rewards: rewards,
            paused: Paused({
                mintPaused: comptroller.marketMintPaused(address(marketToken)),
                redeemPaused: comptroller.marketRedeemPaused(address(marketToken)),
                borrowPaused: comptroller.marketBorrowPaused(address(marketToken)),
                repayBorrowPaused: comptroller.marketRepayBorrowPaused(address(marketToken)),
                transferPaused: comptroller.marketTransferPaused(address(marketToken)),
                seizePaused: comptroller.marketSeizePaused(address(marketToken))
            }),
            isListed: isListed,
            deprecated: comptroller.isDeprecated(address(marketToken)),
            interestRateModel: marketToken.interestRateModel()
        });
    }

    function allMarketTokenMetadata(ComptrollerInterface comptroller, MarketTokenInterface[] memory marketTokens) public returns (MarketMetadata[] memory){
        uint count = marketTokens.length;
        MarketMetadata[] memory res = new MarketMetadata[](count);
        for (uint i = 0; i < count; i++) {
            res[i] = marketTokenMetadata(comptroller, marketTokens[i]);
        }
        return res;
    }

    struct MarketTokenBalances {
        address marketToken;
        uint balanceOf;
        uint balanceOfUnderlying;
        uint borrowBalanceCurrent;
        uint tokenBalance;
        uint tokenAllowance;
    }

    function marketTokenBalances(MarketTokenInterface marketToken, address payable account) public returns (MarketTokenBalances memory) {
        uint balanceOf = marketToken.balanceOf(account);
        uint borrowBalanceCurrent = marketToken.borrowBalanceCurrent(account);
        uint balanceOfUnderlying = marketToken.balanceOfUnderlying(account);
        uint tokenBalance;
        uint tokenAllowance;

        address underlyingAddress = marketToken.underlying();
         if (underlyingAddress== 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE ) {
            tokenBalance = account.balance;
            tokenAllowance = account.balance;
        } else {
            tokenBalance = IERC20(underlyingAddress).balanceOf(account);
            tokenAllowance = IERC20(underlyingAddress).allowance(account, address(marketToken));
        }

        return MarketTokenBalances({
            marketToken: address(marketToken),
            balanceOf: balanceOf,
            borrowBalanceCurrent: borrowBalanceCurrent,
            balanceOfUnderlying: balanceOfUnderlying,
            tokenBalance: tokenBalance,
            tokenAllowance: tokenAllowance
        });
    }

    function allMarketTokenBalances(MarketTokenInterface[] memory marketTokens, address payable account) public returns (MarketTokenBalances[] memory){
        uint count = marketTokens.length;
        MarketTokenBalances[] memory res = new MarketTokenBalances[](count);
        for (uint i = 0; i < count; i++) {
            res[i] = marketTokenBalances(marketTokens[i],account);
        }
        return res;
    }


    struct InterestRateModel {
        MarketTokenInterface market;
        uint secondsPerYear;
        uint multiplierPerSecond;
        uint baseRatePerSecond;
        uint jumpMultiplierPerSecond;
        uint kink;
        JumpRateModelInterface interestRateModel;
    }


    function getInterestRateModel(MarketTokenInterface market) public view returns (InterestRateModel memory){
        JumpRateModelInterface interestRateModel = JumpRateModelInterface(market.interestRateModel());

        return InterestRateModel({
        market : market,
        secondsPerYear : interestRateModel.secondsPerYear(),
        multiplierPerSecond : interestRateModel.multiplierPerSecond(),
        baseRatePerSecond : interestRateModel.baseRatePerSecond(),
        jumpMultiplierPerSecond : interestRateModel.jumpMultiplierPerSecond(),
        kink : interestRateModel.kink(),
        interestRateModel: interestRateModel
        });
    }

    function getInterestRateModels(MarketTokenInterface[] memory markets) public view returns (InterestRateModel[] memory){
        uint count = markets.length;
        InterestRateModel[] memory res = new InterestRateModel[](count);
        for (uint i = 0; i < count; i++) {
            res[i] = getInterestRateModel(markets[i]);
        }
        return res;
    }

    struct AccountLimits {
        MarketTokenInterface[] markets;
        uint liquidity;
        uint shortfall;
    }


    function getAccountLimits(ComptrollerInterface comptroller, address payable account) public view returns (AccountLimits memory) {

        (uint errorCode, uint liquidity, uint shortfall) = comptroller.getAccountLiquidity(account);
        require(errorCode == 0);

        address[] memory assetsIn = comptroller.getAssetsIn(account);
        MarketTokenInterface[] memory markets = new MarketTokenInterface[](assetsIn.length);
        for(uint i = 0; i < assetsIn.length; i++){
            markets[i] = MarketTokenInterface(assetsIn[i]);
        }

        return AccountLimits({
        markets : markets,
        liquidity : liquidity,
        shortfall : shortfall
        });
    }
    

    function accountAllMarkets(ComptrollerInterface comptroller, address payable account) public view returns(MarketTokenInterface[] memory){
        MarketTokenInterface[] memory markets = getAllMarkets(comptroller);

        MarketTokenInterface[] memory _markets = new MarketTokenInterface[](markets.length);
        uint count = 0;
        for(uint i = 0; i < markets.length; i++){
            MarketTokenInterface market = markets[i];
            (,uint TokenBalance, uint borrowBalance,) = market.getAccountSnapshot(account);
            if(TokenBalance > 0 || borrowBalance > 0){
               _markets[count] = market;
               count = count + 1;
            }
        }

        MarketTokenInterface[] memory accountMarkets = new MarketTokenInterface[](count);
        for(uint i = 0; i < count; i++){
            accountMarkets[i] = _markets[i];
        }
        return accountMarkets;
    }


    function allMarketInfo(ComptrollerInterface comptroller) external returns ( MarketMetadata[] memory, InterestRateModel[] memory){

        MarketTokenInterface[] memory markets = getAllMarkets(comptroller);
        MarketMetadata[] memory metaData = allMarketTokenMetadata(comptroller, markets);
        InterestRateModel[] memory rateModels = getInterestRateModels(markets);

        return (metaData, rateModels);
    }


    function accountAssetsInMarketInfo(ComptrollerInterface comptroller, address payable account) external returns (AccountLimits memory, MarketTokenBalances[] memory, MarketMetadata[] memory){

        AccountLimits memory accountLimits = getAccountLimits(comptroller,account);
        MarketMetadata[] memory metaData = allMarketTokenMetadata(comptroller, accountLimits.markets);
        MarketTokenBalances[] memory balances = allMarketTokenBalances(accountLimits.markets, account);
        
        return (accountLimits, balances, metaData);
    }

    function accountAllMarketInfo(ComptrollerInterface comptroller, address payable account) external returns (AccountLimits memory, MarketTokenBalances[] memory, MarketMetadata[] memory){
        
        MarketTokenInterface[] memory accountMarkets = accountAllMarkets(comptroller,account);
    
        AccountLimits memory accountLimits = getAccountLimits(comptroller,account);
        MarketTokenBalances[] memory balances = allMarketTokenBalances(accountMarkets, account);
        MarketMetadata[] memory metaData = allMarketTokenMetadata(comptroller,accountMarkets);

        return (accountLimits, balances, metaData);
    }


    function pendingReward(ComptrollerInterface comptroller, address account) external returns (PendingRewards memory pendingRewards){

        address distributioner = comptroller.distributioner();

        if(distributioner == address(0)){
            return pendingRewards;
        }

        {
            (bool success, bytes memory returndata) = distributioner.staticcall(abi.encodeWithSignature("isDistributionerManager()"));
            if(success){
                bool isDistributionerManager = abi.decode(returndata,(bool));
                if(isDistributionerManager){
                    address[] memory distributioners = DistributionerManagerInterface(distributioner).getDistributioners();
                    pendingRewards = _getPendingReward(distributioners, account);
                }
                return pendingRewards;
            }
        }

        {
            (bool success, bytes memory returndata) = distributioner.staticcall(abi.encodeWithSignature("isDistributioner()"));
            if(success){
                bool isDistributioner = abi.decode(returndata,(bool));
                if(isDistributioner){
                    address[] memory distributioners = new address[](1);
                    distributioners[0] = distributioner;
                    pendingRewards = _getPendingReward(distributioners, account);
                }
                return pendingRewards;
            }
        }
    }

    function _getRewards(ComptrollerInterface comptroller, address marketToken) internal view returns(Rewards memory rewards) {

        address distributioner = comptroller.distributioner();

        if(distributioner == address(0)){
            return rewards;
        }

        {
            (bool success, bytes memory returndata) = distributioner.staticcall(abi.encodeWithSignature("isDistributionerManager()"));
            if(success){
                bool isDistributionerManager = abi.decode(returndata,(bool));
                if(isDistributionerManager){
                    address[] memory distributioners = DistributionerManagerInterface(distributioner).getDistributioners();
                    rewards = _getDistributionerInfo(distributioners, marketToken);
                }
                return rewards;
            }
        }

        {
            (bool success, bytes memory returndata) = distributioner.staticcall(abi.encodeWithSignature("isDistributioner()"));
            if(success){
                bool isDistributioner = abi.decode(returndata,(bool));
                if(isDistributioner){
                    address[] memory distributioners = new address[](1);
                    distributioners[0] = distributioner;
                    rewards = _getDistributionerInfo(distributioners, marketToken);
                }
                return rewards;
            }
        }

    
    }

    function _getDistributionerInfo(address[] memory distributioners, address marketToken) internal view returns(Rewards memory){

        address[] memory rewardTokens = new address[](distributioners.length);
        uint[] memory supplySpeeds = new uint[](distributioners.length);
        uint[] memory borrowSpeeds = new uint[](distributioners.length);

        for(uint i = 0; i < distributioners.length; i++){
            try DistributionerInterface(distributioners[i]).rewardToken() returns(address _rewardToken){
                rewardTokens[i] = _rewardToken;
            }catch {
                rewardTokens[i] = address(0);
            }

            try DistributionerInterface(distributioners[i]).rewardSupplySpeeds(marketToken) returns(uint _supplySpeed){
                supplySpeeds[i] = _supplySpeed;
            }catch {
                supplySpeeds[i] = 0;
            }

            try DistributionerInterface(distributioners[i]).rewardBorrowSpeeds(marketToken) returns(uint _borrowSpeed){
                borrowSpeeds[i] = _borrowSpeed;
            }catch {
                borrowSpeeds[i] = 0;
            }
        }
        
        return Rewards({
            distributioners: distributioners,
            rewardTokens: rewardTokens,
            supplySpeeds: supplySpeeds,
            borrowSpeeds: borrowSpeeds
        });

    }

    function _getPendingReward(address[] memory distributioners, address account) internal returns(PendingRewards memory){

        address[] memory rewardTokens = new address[](distributioners.length);
        uint[] memory pendings = new uint[](distributioners.length);

        for(uint i = 0; i < distributioners.length; i++){

           DistributionerInterface distributioner = DistributionerInterface(distributioners[i]);
           address _rewardToken = distributioner.rewardToken();

            if ( _rewardToken == address(0)) {
               rewardTokens[i] = address(0);
               pendings[i] = 0;
               continue;
            }

            IERC20 rewardToken = IERC20(_rewardToken); 
            uint balance = rewardToken.balanceOf(account);
            distributioner.claimRewardToken(account);
            uint newBalance = rewardToken.balanceOf(account);
            uint accrued = distributioner.rewardAccrued(account);
            uint total = accrued + newBalance;
            uint allocated = total - balance;

            rewardTokens[i] = _rewardToken;
            pendings[i] = allocated;
        }

        return PendingRewards({
            rewardTokens: rewardTokens,
            pendings: pendings
        });

    }


}