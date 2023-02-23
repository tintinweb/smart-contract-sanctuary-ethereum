// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../libraries/FixedPointMathLib.sol";
import "../interfaces/IMetaAlgorithm.sol";

/// @title ExponentialAlgorithm Algorithm to calculate trade prices
/// @author JorgeLpzGnz & CarlosMario714
/// @notice Algorithm to calculate the price exponentially
contract ExponentialAlgorithm is IMetaAlgorithm {

    /*

      In the Exponential Algorithm the Start Price will be multiplied 
      or Divided by the multiplier to calculate the trade price

    */

    /// @notice See [ FixedPointMathLib ] for more info
    using FixedPointMathLib for uint256;

    /// @notice the minimum start price
    uint32 public constant MIN_PRICE = 1 gwei; 

    /// @notice the minimum multiplier
    uint public constant MIN_MULTIPLIER = 1e18; 

    /// @return name Name of the Algorithm 
    function name() external pure override returns( string memory ) {

        return "Exponential";

    }

    /// @notice It validates the start price
    /// @dev The start price have to be grater than 1 gwei
    /// this to handel possible dividing errors
    function validateStartPrice( uint _startPrice ) external pure override returns( bool ) {

        return _startPrice >= MIN_PRICE;

    }

    /// @notice It validates the multiplier
    /// @dev The multiplier should be greater than 1e18 that
    function validateMultiplier( uint _multiplier ) external pure override returns( bool ) {

        return _multiplier > MIN_MULTIPLIER;

    }

    /// @notice Returns the info to Buy NFTs in a Exponential market
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

        if( _numItems == 0 ) return (false, 0, 0, 0, 0);

        // multiplierPow = multiplier ^ number of items

        uint multiplierPow = uint( _multiplier ).fpow( _numItems, FixedPointMathLib.WAD );

        uint _newStartPrice = uint( _startPrice ).fmul( multiplierPow, FixedPointMathLib.WAD);
        
        // handle possible overflow errors

        if( _newStartPrice > type( uint128 ).max ) return ( false, 0, 0, 0, 0);

        newStartPrice = uint128( _newStartPrice );

        // buy price = startPrice * multiplier

        uint buyPrice = uint( _startPrice ).fmul( _multiplier, FixedPointMathLib.WAD );

        // inputValue = buyPrice * ( multiplierPow - 1) / ( multiplier - 1)

        inputValue = buyPrice.fmul( 
            ( multiplierPow - FixedPointMathLib.WAD ).fdiv( 
                _multiplier - FixedPointMathLib.WAD, FixedPointMathLib.WAD
            ), FixedPointMathLib.WAD);

        uint poolFee = inputValue.fmul( _poolFee, FixedPointMathLib.WAD );

        protocolFee = inputValue.fmul( _protocolFee, FixedPointMathLib.WAD );

        // adding fees

        inputValue += ( protocolFee + poolFee );

        // update start price

        newStartPrice = uint128( _newStartPrice );

        // keep multiplier the same

        newMultiplier = _multiplier;

        isValid = true;

    }

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

        if( _numItems == 0 ) return (false, 0, 0, 0, 0);

        uint invMultiplier = FixedPointMathLib.WAD.fdiv( _multiplier, FixedPointMathLib.WAD );

        // invMultiplierPow = ( 1 / multiplier ) ^ number of items

        uint invMultiplierPow = invMultiplier.fpow( _numItems, FixedPointMathLib.WAD );

        // update start price

        newStartPrice = uint128(
            uint256( _startPrice ).fmul( invMultiplierPow, FixedPointMathLib.WAD )
        );

        // newStartPrice should be > 1 gwei ( 1e9 )

        if( newStartPrice < MIN_PRICE ) newStartPrice = MIN_PRICE;

        // outputValue = spotPrice * ( 1 - invMultiplierPow ) / ( 1 - invMultiplier )

        outputValue = uint256( _startPrice ).fmul(
            ( FixedPointMathLib.WAD - invMultiplierPow ).fdiv(
                FixedPointMathLib.WAD - invMultiplier,
                FixedPointMathLib.WAD
            ),
            FixedPointMathLib.WAD
        );

        uint poolFee = outputValue.fmul( _poolFee, FixedPointMathLib.WAD );

        protocolFee = outputValue.fmul( _protocolFee, FixedPointMathLib.WAD );

        // adding fees

        outputValue -= ( protocolFee + poolFee );

        // keeps multiplier the same

        newMultiplier = _multiplier;

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