/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


interface IEIP20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function transfer(address dst, uint256 amount) external returns (bool success);

    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    function approve(address spender, uint256 amount) external returns (bool success);

    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

interface PriceOracleInterface {
    function getUnderlyingPrice(address _pToken) external view returns (uint);
}

interface ComptrollerInterface {

    function getAllMarkets() external view returns (MarketTokenInterface[] memory);

    function markets(address) external view returns (bool, uint);

    function oracle() external view returns (PriceOracleInterface);

    function getAccountLiquidity(address) external view returns (uint, uint, uint);

    function checkMembership(address account, MarketTokenInterface marketToken) external view returns (bool);
    
    function accountAssets(address account, uint index) external view returns (address);
    
    

}

interface MarketTokenInterface {

    function interestRateModel() external view returns (address);

    function exchangeRateStored() external view returns (uint256);

    function comptroller() external view returns (address);

    function supplyRatePerBlock() external view returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function reserveFactorMantissa() external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function totalReserves() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getCash() external view returns (uint256);

    function borrowIndex() external view returns (uint256);

    function accrualBlockTime() external view returns (uint256);

    function underlying() external view returns (address);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function getAccountSnapshot(address account) external virtual view returns (uint256, uint256, uint256, uint256);
}

interface InterestRateModelInterface {
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns (uint);

    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view returns (uint);
}

interface DistributionLensInterface {
    function rewardBorrowerIndex(address marketToken, address borrower) external view returns(uint);
    function rewardBorrowState(address marketToken) external view returns(uint,uint);
    function rewardBorrowSpeeds(address marketToken) external view returns(uint);
    function phaseIIRewardAccrued(address holder) external view returns(uint);
    function phaseIRewardAccrued(address holder) external view returns(uint);
    function rewardSupplierIndex(address marketToken,address supplier) external view returns(uint);
    function rewardInitialIndex() external view returns(uint);
     function rewardSupplyState(address marketToken) external view returns(uint,uint);
    function rewardSupplySpeeds(address marketToken) external view returns(uint);
}

contract CoslendLens {

    ComptrollerInterface public comptroller;
    DistributionLensInterface public distributionII;
    DistributionLensInterface public distributionI;
    
    string  public nativeMarketToken;
    string public nativeToken;
    string public nativeName;
    address public owner;

    constructor(ComptrollerInterface _comptroller, 
        string  memory _nativeMarketToken, string  memory _nativeToken, string memory _nativeName) public {
        comptroller = _comptroller;
        
        nativeMarketToken = _nativeMarketToken;
        nativeToken = _nativeToken;
        nativeName = _nativeName;

        owner = msg.sender;
    }

    function updateProperties(ComptrollerInterface _comptroller, 
        string  memory _nativeMarketToken, string  memory _nativeToken, string memory _nativeName) public {

        require(msg.sender == owner, "sender is not owner");

        comptroller = _comptroller;
        
        nativeMarketToken = _nativeMarketToken;
        nativeToken = _nativeToken;
        nativeName = _nativeName;
    }

    function getAllMarkets() external view returns (MarketTokenInterface[] memory){
        return comptroller.getAllMarkets();
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
        uint supplyRatePerBlock;
        uint borrowRatePerBlock;
        uint reserveFactorMantissa;
        uint collateralFactorMantissa;
        uint totalBorrows;
        uint totalReserves;
        uint totalSupply;
        uint totalCash;
        uint price;
        bool isListed;
        uint blockTime;
        uint accrualBlockTime;
        uint borrowIndex;
    }

    // 获得市场的属性
    function marketTokenMetadata(MarketTokenInterface marketToken) public view returns (MarketMetadata memory){

        (bool isListed, uint collateralFactorMantissa) = comptroller.markets(address(marketToken));

        address underlyingAddress;
        uint underlyingDecimals;
        string memory underlyingSymbol;
        string memory underlyingName;
        if (compareStrings(marketToken.symbol(), nativeMarketToken)) {
            underlyingAddress = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
            underlyingDecimals = 18;
            underlyingSymbol = nativeToken;
            underlyingName = nativeName;
        } else {
            underlyingAddress = marketToken.underlying();
            underlyingDecimals = IEIP20(marketToken.underlying()).decimals();
            underlyingSymbol = IEIP20(marketToken.underlying()).symbol();
            underlyingName = IEIP20(marketToken.underlying()).name();
        }

        uint price = PriceOracleInterface(comptroller.oracle()).getUnderlyingPrice(address(marketToken));

        return MarketMetadata({
        marketAddress : address(marketToken),
        marketDecimals : marketToken.decimals(),
        marketSymbol : marketToken.symbol(),
        marketName : marketToken.name(), 
        underlyingAddress : underlyingAddress,
        underlyingDecimals : underlyingDecimals,
        underlyingSymbol : underlyingSymbol,
        underlyingName : underlyingName,
        exchangeRateCurrent : marketToken.exchangeRateStored(),
        supplyRatePerBlock : marketToken.supplyRatePerBlock(),
        borrowRatePerBlock : marketToken.borrowRatePerBlock(),
        reserveFactorMantissa : marketToken.reserveFactorMantissa(),
        collateralFactorMantissa : collateralFactorMantissa,
        totalBorrows : marketToken.totalBorrows(),
        totalReserves : marketToken.totalReserves(),
        totalSupply : marketToken.totalSupply(),
        totalCash : marketToken.getCash(),
        price : price,
        isListed : isListed,
        blockTime : block.timestamp,
        accrualBlockTime : marketToken.accrualBlockTime(),
        borrowIndex : marketToken.borrowIndex()
        });

    }

    function marketTokenMetadataAll(MarketTokenInterface[] memory marketTokens) public view returns (MarketMetadata[] memory) {
        uint count = marketTokens.length;
        MarketMetadata[] memory res = new MarketMetadata[](count);
        for (uint i = 0; i < count; i++) {
            res[i] = marketTokenMetadata(marketTokens[i]);
        }
        return res;
    }

    struct MarketTokenBalances {
        address marketToken;
        uint balance;
        uint borrowBalance; //用户的借款
        uint exchangeRateMantissa;
    }

    // 获得用户的市场金额
    function marketBalances(MarketTokenInterface marketToken, address payable account) public view returns (MarketTokenBalances memory) {

        (, uint tokenBalance, uint borrowBalance, uint exchangeRateMantissa) = marketToken.getAccountSnapshot(account);

        return MarketTokenBalances({
        marketToken : address(marketToken),
        balance : tokenBalance,
        borrowBalance : borrowBalance,
        exchangeRateMantissa : exchangeRateMantissa
        });

    }

    // 获得用户有每个市场的金额(抵押、借贷)
    function marketBalancesAll(MarketTokenInterface[] memory marketTokens, address payable account) public view returns (MarketTokenBalances[] memory) {
        uint count = marketTokens.length;
        MarketTokenBalances[] memory res = new MarketTokenBalances[](count);
        for (uint i = 0; i < count; i++) {
            res[i] = marketBalances(marketTokens[i], account);
        }
        return res;
    }

    struct AccountLimits {
        MarketTokenInterface[] markets;
        uint liquidity;
        uint shortfall;
    }

    // 获得用户有哪些市场、流动性
    function getAccountLimits(address payable account) public view returns (AccountLimits memory) {

        (uint errorCode, uint liquidity, uint shortfall) = comptroller.getAccountLiquidity(account);
        require(errorCode == 0);


        MarketTokenInterface[] memory marketTokens = comptroller.getAllMarkets();
        uint count = 0;
        for (uint256 i = 0; i < marketTokens.length; i++){
            bool flag = comptroller.checkMembership(account, marketTokens[i]);
            if (flag){
                count = count + 1;
            }
        }

        MarketTokenInterface[] memory markets = new MarketTokenInterface[](count);
        for (uint256 i = 0; i < count; i++){
            address market = comptroller.accountAssets(account, i);
            markets[i] = MarketTokenInterface(market);
        }

        return AccountLimits({
        markets : markets,
        liquidity : liquidity,
        shortfall : shortfall
        });
    }


    function allMarkets() external view returns (MarketMetadata[] memory){

        MarketTokenInterface[] memory marketTokens = comptroller.getAllMarkets();
        MarketMetadata[] memory metaData = marketTokenMetadataAll(marketTokens);

        return (metaData);
    }


    function allMarketsForAccount(address payable account) external view returns (AccountLimits memory, MarketTokenBalances[] memory, MarketMetadata[] memory){

        AccountLimits memory accountLimits = getAccountLimits(account);

        MarketTokenInterface[] memory marketTokens = comptroller.getAllMarkets();
        MarketTokenBalances[] memory balances = marketBalancesAll(marketTokens, account);
        MarketMetadata[] memory metaData = marketTokenMetadataAll(marketTokens);

        return (accountLimits, balances, metaData);
    }
    
    function allForAccountInMarkets(address payable account) external view returns (MarketMetadata[] memory, AccountLimits memory, MarketTokenBalances[] memory){

        AccountLimits memory accountLimits = getAccountLimits(account);
        MarketMetadata[] memory metaData = marketTokenMetadataAll(accountLimits.markets);
        MarketTokenBalances[] memory balances = marketBalancesAll(accountLimits.markets, account);
        
        return ( metaData, accountLimits, balances);
    }


    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }


    function pendingRewardAccruedI(address holder, bool borrowers, bool suppliers) public view returns (uint256){
       
        uint256 pendingReward = distributionI.phaseIIRewardAccrued(holder);

        MarketTokenInterface[] memory marketTokens = comptroller.getAllMarkets();
        for (uint i = 0; i < marketTokens.length; i++) {
            address marketToken = address(marketTokens[i]);
            uint tmp = 0;
            if (borrowers == true) {
                tmp = pendingRewardBorrowInternal(distributionI,holder, marketToken);
                pendingReward = pendingReward  + tmp;
            }
            if (suppliers == true) {
                tmp = pendingRewardSupplyInternal(distributionI,holder, marketToken);
                pendingReward = pendingReward + tmp;
            }
        }

        return pendingReward ; 

    }

    function pendingRewardAccruedII(address holder, bool borrowers, bool suppliers) public view returns (uint256){
       
        uint256 pendingReward = distributionII.phaseIIRewardAccrued(holder);

        MarketTokenInterface[] memory marketTokens = comptroller.getAllMarkets();
        for (uint i = 0; i < marketTokens.length; i++) {
            address marketToken = address(marketTokens[i]);
            uint tmp = 0;
            if (borrowers == true) {
                tmp = pendingRewardBorrowInternal(distributionII,holder, marketToken);
                pendingReward = pendingReward  + tmp;
            }
            if (suppliers == true) {
                tmp = pendingRewardSupplyInternal(distributionII,holder, marketToken);
                pendingReward = pendingReward + tmp;
            }
        }

        return pendingReward ; 

    }


    function pendingRewardBorrowInternal(DistributionLensInterface distribution,address borrower, address marketToken) internal view returns (uint256){


        MarketMetadata memory marketMetadata = marketTokenMetadata(MarketTokenInterface(marketToken));
        uint marketBorrowIndex = marketMetadata.borrowIndex;
        (uint borrowIndex,) = pendingRewardBorrowIndex(distribution,marketToken,marketBorrowIndex);
        uint borrowerIndex = distribution.rewardBorrowerIndex(marketToken,borrower);
        if(borrowerIndex > 0){
            uint deltaIndex = borrowIndex - borrowerIndex;
            MarketTokenBalances memory mtb = marketBalances(MarketTokenInterface(marketToken),payable(borrower));
            uint borrowerAmount = mtb.borrowBalance / marketBorrowIndex;
            uint borrowerDelta = borrowerAmount * deltaIndex;
            return borrowerDelta;
        }

        return 0;
    }

    function pendingRewardBorrowIndex(DistributionLensInterface distribution,address marketToken, uint marketBorrowIndex) internal view returns (uint,uint){

        (uint index,uint _block) = distribution.rewardBorrowState(marketToken);
        uint borrowSpeed = distribution.rewardBorrowSpeeds(marketToken);
        uint blockTime = block.timestamp;
        uint deltaBlocks = blockTime - _block;
        if(deltaBlocks > 0 && borrowSpeed > 0){
            uint borrowAmount = marketTokenMetadata(MarketTokenInterface(marketToken)).totalBorrows / marketBorrowIndex;
            uint rewardAccrued = deltaBlocks * borrowSpeed;
            uint ratio = borrowAmount > 0 ? 1e36*rewardAccrued/borrowAmount : 0;
            index = index + ratio;
            return (index,blockTime);
        }else{
            return (index,blockTime);
        }

    }

    function pendingRewardSupplyInternal(DistributionLensInterface distribution,address supplier, address marketToken) internal view returns (uint256){

        MarketMetadata memory marketMetadata = marketTokenMetadata(MarketTokenInterface(marketToken));
        (uint supplyIndex,) = pendingRewardSupplyIndex(distribution,marketToken);
        uint supplierIndex = distribution.rewardSupplierIndex(marketToken,supplier);
        if(supplierIndex == 0 && supplyIndex > 0){
            supplierIndex = distribution.rewardInitialIndex();
        }
        uint deltaIndex = supplyIndex - supplierIndex;
        uint supplierTokens = marketBalances(MarketTokenInterface(marketToken),payable(supplier)).balance;
        uint supplierDelta = supplierTokens * deltaIndex;

        return supplierDelta;
    }


    function pendingRewardSupplyIndex(DistributionLensInterface distribution, address marketToken) internal view returns (uint256,uint){

        (uint index,uint _block) = distribution.rewardSupplyState(marketToken);
        uint supplySpeed = distribution.rewardSupplySpeeds(marketToken);
        uint blockTime = block.timestamp;
        uint deltaBlocks = blockTime - _block;
        if(supplySpeed > 0 && deltaBlocks > 0){
            uint supplyTokens = marketTokenMetadata(MarketTokenInterface(marketToken)).totalSupply;
            uint rewardAccrued = deltaBlocks * supplySpeed;
            uint ratio = supplyTokens > 0 ? 1e36*rewardAccrued/supplyTokens : 0;
            index = index + ratio;      
            return (index,blockTime);
        }else{
            return (index,blockTime);
        }

    }






}