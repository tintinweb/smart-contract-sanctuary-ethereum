// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../libraries/FixedPointMathLib.sol";
import "../interfaces/IMetaAlgorithm.sol";

/// @title CPAlgorithm Algorithm to calculate trade prices
/// @author JorgeLpzGnz & CarlosMario714
/// @notice This Algorithm a Constant product Based on ( XY = K )
contract CPAlgorithm is IMetaAlgorithm {

    /*

      In the Constant Product Market Algorithm it needs the balances
      of two tokens to calculate the trade prices, is the formula XY = K
      in this protocol, X = balance of token 1, Y = balance of token 2,
      so in this algorithm those values are: 
      
      tokenBalance = startPrice;
      nftBalance = multiplier;

    */

    /// @notice See [ FixedPointMathLib ] for more info
    using FixedPointMathLib for uint256;

    /// @return name Name of the Algorithm 
    function name() external pure override returns( string memory ) {

        return "Constant Product";

    }

    /// @notice It validates the start price
    /// @dev In CP algorithm all values are valid 
    function validateStartPrice( uint ) external pure override returns( bool ) {

        return true;

    }

    /// @notice It validates the multiplier
    /// @dev In CP algorithm all values are valid 
    function validateMultiplier( uint ) external pure override returns( bool ) {        

        return true;

    }

    /// @notice Returns the info to Buy NFTs in Constant Product market
    /// @param _multiplier Pool multiplier
    /// @param _startPrice Pool Start price
    /// @param _numItems Number of Items to buy
    /// @param _protocolFee Protocol fee multiplier 
    /// @param _poolFee Pool fee multiplier  
    /// @return isValid True if the trade can be done
    /// @return newStartPrice New Pool Start Price
    /// @return newMultiplier New Pool Multiplier
    /// @return inputValue Amount to send to the pool 
    /// @return protocolFee Fee charged for the trade 
    function getBuyInfo( uint128 _multiplier, uint128 _startPrice, uint _numItems, uint128 _protocolFee, uint128 _poolFee ) external pure override 
        returns ( 
            bool isValid, 
            uint128 newStartPrice, 
            uint128 newMultiplier, 
            uint256 inputValue, 
            uint256 protocolFee 
        ) 
    {
        
        // num Items should be > 0

        if (_numItems == 0) return ( false, 0, 0, 0, 0);

        uint tokenBalance = _startPrice;

        uint nftBalance = _multiplier;

        // multiply the number of items by 1e18 because all the calculations are done in base 1e18

        uint numItems = _numItems * 1e18;

        // num Items should be < NFT balance ( multiplier = numItems  initial Price )

        if ( numItems >= nftBalance ) return ( false, 0, 0, 0, 0);

        // input value = ( tokenBalance * numItems ) / ( nftBalance - numItems )

        inputValue = tokenBalance.fmul( numItems, FixedPointMathLib.WAD ).fdiv( nftBalance - numItems , FixedPointMathLib.WAD );

        uint poolFee = inputValue.fmul( _poolFee, FixedPointMathLib.WAD );

        protocolFee = inputValue.fmul( _protocolFee, FixedPointMathLib.WAD );

        // adding fees

        inputValue += ( protocolFee + poolFee );

        // is needed a start Price and multiplier update

        newStartPrice = uint128( tokenBalance + inputValue );

        newMultiplier = uint128( nftBalance - numItems );

        isValid = true;

    }

    /// @notice Returns the info to Sell NFTs in Constant Product market
    /// @param _multiplier Pool multiplier
    /// @param _startPrice Pool Start price
    /// @param _numItems Number of Items to buy
    /// @param _protocolFee Protocol fee multiplier 
    /// @param _poolFee Pool fee multiplier  
    /// @return isValid True if the trade can be done
    /// @return newStartPrice New Pool Start Price
    /// @return newMultiplier New Pool Multiplier
    /// @return outputValue Amount to send to the user
    /// @return protocolFee Fee charged for the trade 
    function getSellInfo( uint128 _multiplier, uint128 _startPrice, uint _numItems, uint128 _protocolFee, uint128 _poolFee ) external pure override 
        returns ( 
            bool isValid, 
            uint128 newStartPrice, 
            uint128 newMultiplier, 
            uint256 outputValue, 
            uint256 protocolFee 
        ) 
    {
        
        // num Items should be > 0

        if ( _numItems == 0) return (false, 0, 0, 0, 0);

        uint tokenBalance = _startPrice;

        uint nftBalance = _multiplier;
        
        // multiply the number of items by 1e18 because all the calculations are done in base 1e18

        uint numItems = _numItems * 1e18;

        // num Items should be < NFT balance ( multiplier = numItems  initial Price )

        if ( numItems >= nftBalance ) return (false, 0, 0, 0, 0);

        // input value = ( tokenBalance * numItems ) / ( nftBalance + numItems )

        outputValue = ( tokenBalance.fmul( numItems, FixedPointMathLib.WAD ) ).fdiv( nftBalance + numItems, FixedPointMathLib.WAD );

        uint poolFee = outputValue.fmul( _poolFee, FixedPointMathLib.WAD );

        protocolFee = outputValue.fmul( _protocolFee, FixedPointMathLib.WAD );

        // adding fees

        outputValue -=  ( protocolFee + poolFee );

        // is needed a start Price and multiplier update

        newStartPrice = uint128( tokenBalance - outputValue );

        newMultiplier = uint128( nftBalance + numItems );

        isValid = true;

    }
    
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.9;

/// @title IMetaAlgorithm a interface to call algorithms contracts
/// @author JorgeLpzGnz & CarlosMario714
/// @dev the algorithm is responsible for calculating the prices see
interface IMetaAlgorithm {

    /// @dev See each algorithm to see how this values are calculated

    /// @notice it returns the name of the Algorithm
    function name() external pure returns( string memory );

    /// @notice it checks if the start price is valid 
    function validateStartPrice( uint _startPrice ) external pure returns( bool );

    /// @notice it checks if the multiplier is valid 
    function validateMultiplier( uint _multiplier ) external pure returns( bool );

    /// @notice in returns of the info needed to do buy NFTs
    /// @param _multiplier current multiplier used to calculate the price
    /// @param _startPrice current start price used to calculate the price
    /// @param _numItems number of NFTs to trade
    /// @param _protocolFee Fee multiplier to calculate the protocol fee
    /// @param _poolFee Fee multiplier to calculate the pool fee
    /// @return isValid true if trade can be performed
    /// @return newStartPrice new start price used to calculate the price
    /// @return newMultiplier new multiplier used to calculate the price
    /// @return inputValue amount to send to the pool
    /// @return protocolFee Amount to charged for the trade
    function getBuyInfo( uint128 _multiplier, uint128 _startPrice, uint _numItems, uint128 _protocolFee, uint128 _poolFee ) external pure 
        returns ( 
            bool isValid, 
            uint128 newStartPrice, 
            uint128 newMultiplier, 
            uint256 inputValue, 
            uint256 protocolFee 
        );

    /// @notice in returns of the info needed to do sell NFTs
    /// @param _multiplier current multiplier used to calculate the price
    /// @param _startPrice current start price used to calculate the price
    /// @param _numItems number of NFTs to trade
    /// @param _protocolFee Fee multiplier to calculate the protocol fee
    /// @param _poolFee Fee multiplier to calculate the pool fee
    /// @return isValid true if trade can be performed
    /// @return newStartPrice new start price used to calculate the price
    /// @return newMultiplier new multiplier used to calculate the price
    /// @return outputValue amount to send to the user
    /// @return protocolFee Amount to charged for the trade
    function getSellInfo( uint128 _multiplier, uint128 _startPrice, uint _numItems, uint128 _protocolFee, uint128 _poolFee ) external pure
        returns ( 
            bool isValid, 
            uint128 newStartPrice, 
            uint128 newMultiplier, 
            uint256 outputValue, 
            uint256 protocolFee 
        );

}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Modified from Dappsys V2 (https://github.com/dapp-org/dappsys-v2/blob/main/src/math.sol)
/// and ABDK (https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                            COMMON BASE UNITS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant YAD = 1e8;
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant RAD = 1e45;

    /*///////////////////////////////////////////////////////////////
                         FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

            // If baseUnit is zero this will return zero instead of reverting.
            z := div(z, baseUnit)
        }
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * baseUnit in z for now.
            z := mul(x, baseUnit)

            if or(
                // Revert if y is zero to ensure we don't divide by zero below.
                iszero(y),
                // Equivalent to require(x == 0 || (x * baseUnit) / x == baseUnit)
                iszero(or(iszero(x), eq(div(z, x), baseUnit)))
            ) {
                revert(0, 0)
            }

            // We ensure y is not zero above, so there is never division by zero here.
            z := div(z, y)
        }
    }

    function fpow(
        uint256 x,
        uint256 n,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    z := baseUnit
                }
                default {
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    z := baseUnit
                }
                default {
                    z := x
                }
                let half := div(baseUnit, 2)
                for {
                    n := div(n, 2)
                } n {
                    n := div(n, 2)
                } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) {
                        revert(0, 0)
                    }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }
                    x := div(xxRound, baseUnit)
                    if mod(n, 2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                            revert(0, 0)
                        }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }
                        z := div(zxRound, baseUnit)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) return 0;

        result = 1;

        uint256 xAux = x;

        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }

        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }

        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }

        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }

        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }

        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }

        if (xAux >= 0x8) result <<= 1;

        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;

            uint256 roundedDownResult = x / result;

            if (result > roundedDownResult) result = roundedDownResult;
        }
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x < y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x > y ? x : y;
    }
}