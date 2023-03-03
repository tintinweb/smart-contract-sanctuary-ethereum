/**
 *Submitted for verification at Etherscan.io on 2023-03-02
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;




abstract contract ITrigger {
    function isTriggered(bytes memory, bytes memory) public virtual returns (bool);
    function isChangeable() public virtual returns (bool);
    function changedSubData(bytes memory) public virtual returns (bytes memory);
}





contract TransientStorage {
    mapping (string => bytes32) public tempStore;

    /// @notice Set a bytes32 value by a string key
    /// @dev Anyone can add a value because it's only used per tx
    function setBytes32(string memory _key, bytes32 _value) public {
        tempStore[_key] = _value;
    }


    /// @dev Can't enforce per tx usage so caller must be careful reading the value
    function getBytes32(string memory _key) public view returns (bytes32) {
        return tempStore[_key];
    }
}




library Types {
    /// ENUMS ///

    enum PositionType {
        SUPPLIERS_IN_P2P,
        SUPPLIERS_ON_POOL,
        BORROWERS_IN_P2P,
        BORROWERS_ON_POOL
    }

    /// STRUCTS ///

    struct SupplyBalance {
        uint256 inP2P; // In peer-to-peer supply scaled unit, a unit that grows in underlying value, to keep track of the interests earned by suppliers in peer-to-peer. Multiply by the peer-to-peer supply index to get the underlying amount.
        uint256 onPool; // In pool supply scaled unit. Multiply by the pool supply index to get the underlying amount.
    }

    struct BorrowBalance {
        uint256 inP2P; // In peer-to-peer borrow scaled unit, a unit that grows in underlying value, to keep track of the interests paid by borrowers in peer-to-peer. Multiply by the peer-to-peer borrow index to get the underlying amount.
        uint256 onPool; // In pool borrow scaled unit, a unit that grows in value, to keep track of the debt increase when borrowers are on Aave. Multiply by the pool borrow index to get the underlying amount.
    }

    struct Indexes {
        uint256 p2pSupplyIndex; // The peer-to-peer supply index (in ray), used to multiply the scaled peer-to-peer supply balance and get the peer-to-peer supply balance (in underlying).
        uint256 p2pBorrowIndex; // The peer-to-peer borrow index (in ray), used to multiply the scaled peer-to-peer borrow balance and get the peer-to-peer borrow balance (in underlying).
        uint256 poolSupplyIndex; // The pool supply index (in ray), used to multiply the scaled pool supply balance and get the pool supply balance (in underlying).
        uint256 poolBorrowIndex; // The pool borrow index (in ray), used to multiply the scaled pool borrow balance and get the pool borrow balance (in underlying).
    }

    // Max gas to consume during the matching process for supply, borrow, withdraw and repay functions.
    struct MaxGasForMatching {
        uint64 supply;
        uint64 borrow;
        uint64 withdraw;
        uint64 repay;
    }

    struct Delta {
        uint256 p2pSupplyDelta; // Difference between the stored peer-to-peer supply amount and the real peer-to-peer supply amount (in pool supply unit).
        uint256 p2pBorrowDelta; // Difference between the stored peer-to-peer borrow amount and the real peer-to-peer borrow amount (in pool borrow unit).
        uint256 p2pSupplyAmount; // Sum of all stored peer-to-peer supply (in peer-to-peer supply unit).
        uint256 p2pBorrowAmount; // Sum of all stored peer-to-peer borrow (in peer-to-peer borrow unit).
    }

    struct AssetLiquidityData {
        uint256 decimals; // The number of decimals of the underlying token.
        uint256 tokenUnit; // The token unit considering its decimals.
        uint256 liquidationThreshold; // The liquidation threshold applied on this token (in basis point).
        uint256 ltv; // The LTV applied on this token (in basis point).
        uint256 underlyingPrice; // The price of the token (in ETH).
        uint256 collateralEth; // The collateral value of the asset (in ETH).
        uint256 debtEth; // The debt value of the asset (in ETH).
    }

    struct LiquidityData {
        uint256 collateralEth; // The collateral value (in ETH).
        uint256 borrowableEth; // The maximum debt value allowed to borrow (in ETH).
        uint256 maxDebtEth; // The maximum debt value allowed before being liquidatable (in ETH).
        uint256 debtEth; // The debt value (in ETH).
    }

    // Variables are packed together to save gas (will not exceed their limit during Morpho's lifetime).
    struct PoolIndexes {
        uint32 lastUpdateTimestamp; // The last time the local pool and peer-to-peer indexes were updated.
        uint112 poolSupplyIndex; // Last pool supply index. Note that for the stEth market, the pool supply index is tweaked to take into account the staking rewards.
        uint112 poolBorrowIndex; // Last pool borrow index. Note that for the stEth market, the pool borrow index is tweaked to take into account the staking rewards.
    }

    struct Market {
        address underlyingToken; // The address of the market's underlying token.
        uint16 reserveFactor; // Proportion of the additional interest earned being matched peer-to-peer on Morpho compared to being on the pool. It is sent to the DAO for each market. The default value is 0. In basis point (100% = 10 000).
        uint16 p2pIndexCursor; // Position of the peer-to-peer rate in the pool's spread. Determine the weights of the weighted arithmetic average in the indexes computations ((1 - p2pIndexCursor) * r^S + p2pIndexCursor * r^B) (in basis point).
        bool isCreated; // Whether or not this market is created.
        bool isPaused; // Deprecated.
        bool isPartiallyPaused; // Deprecated.
        bool isP2PDisabled; // Whether the peer-to-peer market is open or not.
    }

    struct MarketPauseStatus {
        bool isSupplyPaused; // Whether the supply is paused or not.
        bool isBorrowPaused; // Whether the borrow is paused or not
        bool isWithdrawPaused; // Whether the withdraw is paused or not. Note that a "withdraw" is still possible using a liquidation (if not paused).
        bool isRepayPaused; // Whether the repay is paused or not. Note that a "repay" is still possible using a liquidation (if not paused).
        bool isLiquidateCollateralPaused; // Whether the liquidation on this market as collateral is paused or not.
        bool isLiquidateBorrowPaused; // Whether the liquidatation on this market as borrow is paused or not.
        bool isDeprecated; // Whether a market is deprecated or not.
    }
}




interface IMorphoAaveV2Lens {
    /// STORAGE ///

    function DEFAULT_LIQUIDATION_CLOSE_FACTOR() external view returns (uint16);

    function HEALTH_FACTOR_LIQUIDATION_THRESHOLD() external view returns (uint256);

    function ST_ETH() external view returns (address);

    function ST_ETH_BASE_REBASE_INDEX() external view returns (uint256);

    function morpho() external view returns (address);

    function addressesProvider() external view returns (address);

    function pool() external view returns (address);

    /// GENERAL ///

    function getTotalSupply()
        external
        view
        returns (
            uint256 p2pSupplyAmount,
            uint256 poolSupplyAmount,
            uint256 totalSupplyAmount
        );

    function getTotalBorrow()
        external
        view
        returns (
            uint256 p2pBorrowAmount,
            uint256 poolBorrowAmount,
            uint256 totalBorrowAmount
        );

    /// MARKETS ///

    function isMarketCreated(address _poolToken) external view returns (bool);

    /// @dev Deprecated.
    function isMarketCreatedAndNotPaused(address _poolToken) external view returns (bool);

    /// @dev Deprecated.
    function isMarketCreatedAndNotPausedNorPartiallyPaused(address _poolToken)
        external
        view
        returns (bool);

    function getAllMarkets() external view returns (address[] memory marketsCreated_);

    function getMainMarketData(address _poolToken)
        external
        view
        returns (
            uint256 avgSupplyRatePerYear,
            uint256 avgBorrowRatePerYear,
            uint256 p2pSupplyAmount,
            uint256 p2pBorrowAmount,
            uint256 poolSupplyAmount,
            uint256 poolBorrowAmount
        );

    function getAdvancedMarketData(address _poolToken)
        external
        view
        returns (
            Types.Indexes memory indexes,
            uint32 lastUpdateTimestamp,
            uint256 p2pSupplyDelta,
            uint256 p2pBorrowDelta
        );

    function getMarketConfiguration(address _poolToken)
        external
        view
        returns (
            address underlying,
            bool isCreated,
            bool isP2PDisabled,
            bool isPaused,
            bool isPartiallyPaused,
            uint16 reserveFactor,
            uint16 p2pIndexCursor,
            uint256 loanToValue,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 decimals
        );

    function getMarketPauseStatus(address _poolToken)
        external
        view
        returns (Types.MarketPauseStatus memory);

    function getTotalMarketSupply(address _poolToken)
        external
        view
        returns (uint256 p2pSupplyAmount, uint256 poolSupplyAmount);

    function getTotalMarketBorrow(address _poolToken)
        external
        view
        returns (uint256 p2pBorrowAmount, uint256 poolBorrowAmount);

    /// INDEXES ///

    function getCurrentP2PSupplyIndex(address _poolToken) external view returns (uint256);

    function getCurrentP2PBorrowIndex(address _poolToken) external view returns (uint256);

    function getIndexes(address _poolToken) external view returns (Types.Indexes memory indexes);

    /// USERS ///

    function getEnteredMarkets(address _user)
        external
        view
        returns (address[] memory enteredMarkets);

    function getUserHealthFactor(address _user) external view returns (uint256 healthFactor);

    function getUserBalanceStates(address _user)
        external
        view
        returns (Types.LiquidityData memory assetData);

    function getCurrentSupplyBalanceInOf(address _poolToken, address _user)
        external
        view
        returns (
            uint256 balanceInP2P,
            uint256 balanceOnPool,
            uint256 totalBalance
        );

    function getCurrentBorrowBalanceInOf(address _poolToken, address _user)
        external
        view
        returns (
            uint256 balanceInP2P,
            uint256 balanceOnPool,
            uint256 totalBalance
        );

    function getUserMaxCapacitiesForAsset(address _user, address _poolToken)
        external
        view
        returns (uint256 withdrawable, uint256 borrowable);

    function getUserHypotheticalBalanceStates(
        address _user,
        address _poolToken,
        uint256 _withdrawnAmount,
        uint256 _borrowedAmount
    ) external view returns (Types.LiquidityData memory assetData);

    function getUserHypotheticalHealthFactor(
        address _user,
        address _poolToken,
        uint256 _withdrawnAmount,
        uint256 _borrowedAmount
    ) external view returns (uint256 healthFactor);

    function getUserLiquidityDataForAsset(
        address _user,
        address _poolToken,
        address _oracle
    ) external view returns (Types.AssetLiquidityData memory assetData);

    function isLiquidatable(address _user) external view returns (bool);

    function isLiquidatable(address _user, address _poolToken) external view returns (bool);

    function computeLiquidationRepayAmount(
        address _user,
        address _poolTokenBorrowed,
        address _poolTokenCollateral
    ) external view returns (uint256 toRepay);

    /// RATES ///

    function getNextUserSupplyRatePerYear(
        address _poolToken,
        address _user,
        uint256 _amount
    )
        external
        view
        returns (
            uint256 nextSupplyRatePerYear,
            uint256 balanceInP2P,
            uint256 balanceOnPool,
            uint256 totalBalance
        );

    function getNextUserBorrowRatePerYear(
        address _poolToken,
        address _user,
        uint256 _amount
    )
        external
        view
        returns (
            uint256 nextBorrowRatePerYear,
            uint256 balanceInP2P,
            uint256 balanceOnPool,
            uint256 totalBalance
        );

    function getCurrentUserSupplyRatePerYear(address _poolToken, address _user)
        external
        view
        returns (uint256);

    function getCurrentUserBorrowRatePerYear(address _poolToken, address _user)
        external
        view
        returns (uint256);

    function getAverageSupplyRatePerYear(address _poolToken)
        external
        view
        returns (
            uint256 avgSupplyRatePerYear,
            uint256 p2pSupplyAmount,
            uint256 poolSupplyAmount
        );

    function getAverageBorrowRatePerYear(address _poolToken)
        external
        view
        returns (
            uint256 avgBorrowRatePerYear,
            uint256 p2pBorrowAmount,
            uint256 poolBorrowAmount
        );

    function getRatesPerYear(address _poolToken)
        external
        view
        returns (
            uint256 p2pSupplyRate,
            uint256 p2pBorrowRate,
            uint256 poolSupplyRate,
            uint256 poolBorrowRate
        );
}




contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x - y;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}




contract MainnetMorphoAddresses {
    address public constant MORPHO_TOKEN_ADDR = 0x9994E35Db50125E0DF82e4c2dde62496CE330999;
    address public constant MORPHO_AAVEV2_ADDR = 0x777777c9898D384F785Ee44Acfe945efDFf5f3E0;
    address public constant MORPHO_AAVEV2_LENS_ADDR = 0x507fA343d0A90786d86C7cd885f5C49263A91FF4;
    address public constant REWARDS_DISTRIBUTOR_ADDR = 0x3B14E5C73e0A56D607A8688098326fD4b4292135;
    address public constant DEFAULT_MARKET_DATA_PROVIDER = 0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d;
    address public constant TRANSIENT_STORAGE = 0x2F7Ef2ea5E8c97B8687CA703A0e50Aa5a49B7eb2;
}







contract MorphoHelper is MainnetMorphoAddresses, DSMath {
    function getSafetyRatio(address _usr) internal view returns (uint256) {
        Types.LiquidityData memory liqData = IMorphoAaveV2Lens(MORPHO_AAVEV2_LENS_ADDR).getUserHypotheticalBalanceStates(_usr, address(0), 0, 0);
        return wdiv(liqData.borrowableEth, liqData.debtEth);
    }
}








contract MorphoAaveV2RatioTrigger is ITrigger, MorphoHelper {

    enum RatioState { OVER, UNDER }
    
    /// @param user address of the user whose position we check
    /// @param ratio ratio that represents the triggerable point
    /// @param state represents if we want the current state to be higher or lower than ratio param
    struct SubParams {
        address user;
        uint256 ratio;
        uint8 state;
    }
    
    function isTriggered(bytes memory, bytes memory _subData)
        public
        override
        returns (bool)
    {
        SubParams memory triggerSubData = parseInputs(_subData);
        uint256 currRatio = getSafetyRatio(triggerSubData.user);
        
        if (currRatio == 0) return false;

        TransientStorage(TRANSIENT_STORAGE).setBytes32("MORPHO_AAVEV2_RATIO", bytes32(currRatio));
        
        if (RatioState(triggerSubData.state) == RatioState.OVER) {
            if (currRatio > triggerSubData.ratio) return true;
        }
        
        if (RatioState(triggerSubData.state) == RatioState.UNDER) {
            if (currRatio < triggerSubData.ratio) return true;
        }
        
        return false;
    }

    function parseInputs(bytes memory _subData) internal pure returns (SubParams memory params) {
        params = abi.decode(_subData, (SubParams));
    }
    function changedSubData(bytes memory _subData) public pure override  returns (bytes memory) {
    }
    
    function isChangeable() public pure override returns (bool){
        return false;
    }

}