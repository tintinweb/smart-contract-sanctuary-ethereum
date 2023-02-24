// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import {Relation} from "RelationModule.sol";
import {ICurve3Pool} from "ICurve3Pool.sol";

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs/GSquared
/// @title CurveOracle
/// @notice CurveOracle - Oracle defining a common denominator for the G3Crv tranche:
///     underlying tokens: G3crv - 3Crv
///     common denominator: 3Crv virtual price
///     tranche tokens priced in: 3Crv virtual price
contract CurveOracle is Relation {
    ICurve3Pool public constant curvePool =
        ICurve3Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);

    constructor() {}

    /// @notice Get curve pool virtual price
    /// @return Value of LP-token
    function getVirtualPrice() public view returns (uint256) {
        return curvePool.get_virtual_price();
    }

    /// @notice Get swapping price between the underlying assets in
    ///     the tranche
    /// @param _i token A
    /// @param _j token B
    /// @param _amount amount of token A to swap into token B
    /// @param _deposit is the swap triggered by a deposit or withdrawal
    /// @return amount of token B
    function getSwappingPrice(
        uint256 _i,
        uint256 _j,
        uint256 _amount,
        bool _deposit
    ) external pure override returns (uint256) {
        return _amount;
    }

    /// @notice Get price of an individual underlying token
    ///     (or its relation to the whole value of the tranche)
    /// @param _i token id
    /// @param _amount amount of yield token
    /// @param _deposit is the pricing triggered from a deposit or a withdrawal
    /// @return price of token amount
    function getSinglePrice(
        uint256 _i,
        uint256 _amount,
        bool _deposit
    ) external view override returns (uint256) {
        return (_amount * getVirtualPrice()) / DEFAULT_FACTOR;
    }

    /// @notice Get token amount from an amount of common denominator assets
    /// @param _i index of token
    /// @param _amount amount of common denominator asset
    /// @param _deposit is the pricing triggered from a deposit or a withdrawal
    /// @return get amount of yield tokens from amount
    function getTokenAmount(
        uint256 _i,
        uint256 _amount,
        bool _deposit
    ) external view override returns (uint256) {
        return (_amount * DEFAULT_FACTOR) / getVirtualPrice();
    }

    /// @notice Get value of all underlying tokens in common denominator
    /// @param _amounts amounts of yield tokens
    /// @return total value of tokens in common denominator
    function getTotalValue(uint256[] memory _amounts)
        external
        view
        override
        returns (uint256)
    {
        uint256 total;
        uint256 vp = getVirtualPrice();
        for (uint256 i; i < _amounts.length; ++i) {
            total += (_amounts[i] * vp) / DEFAULT_FACTOR;
        }
        return total;
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import {IOracle} from "IOracle.sol";

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs/GSquared

/// @title Relation
/// @notice Relation - Oracle defining relation between underlying tranche assets
///
///     ###############################################
///     Relation Specification
///     ###############################################
///
///     The Relation module is the second part of the GTranche building blocks,
///         it allows us to create a separate definition of how the underlying tranche
///         assets relate to one another without making changes to the core tranche logic.
///     By relation, we mean a common denominator between all the underlying assets that
///         will be used to price the tranche tokens. Generally speaking, its likely that
///         this will be a price oracle or bonding curve of some sort, but the choice
///         (and by extension) implementation is left as an exercise to the user ;)
///     This modularity exists in order to allow for the GTranche to fulfill different
///         requirements, as we can specify how we want to facilitate protection (tranching)
///         based on how we relate the underlying tokens to one another.
///
///     The following logic need to be implemented in the relation contract:
///         - Swapping price: How much of token x do I get for token y?
///         - Single price: What is the value of token x in a common denominator
///         - token amount: How much of token x do I get from common denominator y
///         - total value: What is the combined value of all underlying tokens in a common denominator
abstract contract Relation is IOracle {
    uint256 constant DEFAULT_FACTOR = 1_000_000_000_000_000_000;

    constructor() {}

    function getSwappingPrice(
        uint256 _i,
        uint256 _j,
        uint256 _amount,
        bool _deposit
    ) external view virtual override returns (uint256);

    function getSinglePrice(
        uint256 _i,
        uint256 _amount,
        bool _deposit
    ) external view virtual override returns (uint256);

    function getTokenAmount(
        uint256 _i,
        uint256 _amount,
        bool _deposit
    ) external view virtual override returns (uint256);

    function getTotalValue(uint256[] memory _amounts)
        external
        view
        virtual
        override
        returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

interface IOracle {
    function getSwappingPrice(
        uint256 _i,
        uint256 _j,
        uint256 _amount,
        bool _deposit
    ) external view returns (uint256);

    function getSinglePrice(
        uint256 _i,
        uint256 _amount,
        bool _deposit
    ) external view returns (uint256);

    function getTokenAmount(
        uint256 _i,
        uint256 _amount,
        bool _deposit
    ) external view returns (uint256);

    function getTotalValue(uint256[] memory _amount)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

/// Curve 3pool interface
interface ICurve3Pool {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(
        uint256[3] calldata _deposit_amounts,
        uint256 _min_mint_amount
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function balanceOf(address account) external view returns (uint256);
}