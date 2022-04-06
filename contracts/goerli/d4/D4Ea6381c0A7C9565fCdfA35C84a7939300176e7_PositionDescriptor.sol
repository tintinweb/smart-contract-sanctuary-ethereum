// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@primitivefi/rmm-core/contracts/interfaces/engine/IPrimitiveEngineView.sol";
import "base64-sol/base64.sol";
import "./interfaces/IPositionRenderer.sol";
import "./interfaces/external/IERC20WithMetadata.sol";
import "./interfaces/IPositionDescriptor.sol";

/// @title   PositionDescriptor contract
/// @author  Primitive
/// @notice  Manages the metadata of the Primitive protocol position tokens
contract PositionDescriptor is IPositionDescriptor {
    using Strings for uint256;

    /// STATE VARIABLES ///

    /// @inheritdoc IPositionDescriptor
    address public override positionRenderer;

    /// EFFECT FUNCTIONS ///

    /// @param positionRenderer_  Address of the PositionRenderer contract
    constructor(address positionRenderer_) {
        positionRenderer = positionRenderer_;
    }

    /// VIEW FUNCTIONS ///

    /// @inheritdoc IPositionDescriptor
    function getMetadata(address engine, uint256 tokenId) external view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                getName(IPrimitiveEngineView(engine)),
                                '","image":"',
                                IPositionRenderer(positionRenderer).render(engine, tokenId),
                                '","license":"MIT","creator":"primitive.eth",',
                                '"description":"Concentrated liquidity tokens of a two-token AMM",',
                                '"properties":{',
                                getProperties(IPrimitiveEngineView(engine), tokenId),
                                "}}"
                            )
                        )
                    )
                )
            );
    }

    /// @dev           Returns the name of a position token
    /// @param engine  Address of the PrimitiveEngine contract
    /// @return        Name of the position token as a string
    function getName(IPrimitiveEngineView engine) private view returns (string memory) {
        address risky = engine.risky();
        address stable = engine.stable();

        return
            string(
                abi.encodePacked(
                    "Primitive RMM-01 LP ",
                    IERC20WithMetadata(risky).symbol(),
                    "-",
                    IERC20WithMetadata(stable).symbol()
                )
            );
    }

    /// @dev            Returns the properties of a position token
    /// @param engine   Address of the PrimitiveEngine contract
    /// @param tokenId  Id of the position token (pool id)
    /// @return         Properties of the position token as a JSON object
    function getProperties(IPrimitiveEngineView engine, uint256 tokenId) private view returns (string memory) {
        int128 invariant = engine.invariantOf(bytes32(tokenId));

        return
            string(
                abi.encodePacked(
                    '"factory":"',
                    uint256(uint160(engine.factory())).toHexString(),
                    '",',
                    getTokenMetadata(engine.risky(), true),
                    ",",
                    getTokenMetadata(engine.stable(), false),
                    ',"invariant":"',
                    invariant < 0 ? "-" : "",
                    uint256((uint128(invariant < 0 ? ~invariant + 1 : invariant))).toString(),
                    '",',
                    getCalibration(engine, tokenId),
                    ",",
                    getReserve(engine, tokenId),
                    ',"chainId":',
                    block.chainid.toString(),
                    ''
                )
            );
    }

    /// @dev            Returns the metadata of an ERC20 token
    /// @param token    Address of the ERC20 token
    /// @param isRisky  True if the token is the risky
    /// @return         Metadata of the ERC20 token as a JSON object
    function getTokenMetadata(address token, bool isRisky) private view returns (string memory) {
        string memory prefix = isRisky ? "risky" : "stable";
        string memory metadata;

        {
            metadata = string(
                abi.encodePacked(
                    '"',
                    prefix,
                    'Name":"',
                    IERC20WithMetadata(token).name(),
                    '","',
                    prefix,
                    'Symbol":"',
                    IERC20WithMetadata(token).symbol(),
                    '","',
                    prefix,
                    'Decimals":"',
                    uint256(IERC20WithMetadata(token).decimals()).toString(),
                    '"'
                )
            );
        }

        return
            string(abi.encodePacked(metadata, ',"', prefix, 'Address":"', uint256(uint160(token)).toHexString(), '"'));
    }

    /// @dev            Returns the calibration of a pool
    /// @param engine   Address of the PrimitiveEngine contract
    /// @param tokenId  Id of the position token (pool id)
    /// @return         Calibration of the pool as a JSON object
    function getCalibration(IPrimitiveEngineView engine, uint256 tokenId) private view returns (string memory) {
        (uint128 strike, uint64 sigma, uint32 maturity, uint32 lastTimestamp, uint32 gamma) = engine.calibrations(
            bytes32(tokenId)
        );

        return
            string(
                abi.encodePacked(
                    '"strike":"',
                    uint256(strike).toString(),
                    '","sigma":"',
                    uint256(sigma).toString(),
                    '","maturity":"',
                    uint256(maturity).toString(),
                    '","lastTimestamp":"',
                    uint256(lastTimestamp).toString(),
                    '","gamma":"',
                    uint256(gamma).toString(),
                    '"'
                )
            );
    }

    /// @notice         Returns the reserves of a pool
    /// @param engine   Address of the PrimitiveEngine contract
    /// @param tokenId  Id of the position token (pool id)
    /// @return         Reserves of the pool as a JSON object
    function getReserve(IPrimitiveEngineView engine, uint256 tokenId) private view returns (string memory) {
        (
            uint128 reserveRisky,
            uint128 reserveStable,
            uint128 liquidity,
            uint32 blockTimestamp,
            uint256 cumulativeRisky,
            uint256 cumulativeStable,
            uint256 cumulativeLiquidity
        ) = engine.reserves(bytes32(tokenId));

        return
            string(
                abi.encodePacked(
                    '"reserveRisky":"',
                    uint256(reserveRisky).toString(),
                    '","reserveStable":"',
                    uint256(reserveStable).toString(),
                    '","liquidity":"',
                    uint256(liquidity).toString(),
                    '","blockTimestamp":"',
                    uint256(blockTimestamp).toString(),
                    '","cumulativeRisky":"',
                    uint256(cumulativeRisky).toString(),
                    '","cumulativeStable":"',
                    uint256(cumulativeStable).toString(),
                    '","cumulativeLiquidity":"',
                    uint256(cumulativeLiquidity).toString(),
                    '"'
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.5.0;

/// @title  View functions of the Primitive Engine contract
/// @author Primitive
interface IPrimitiveEngineView {
    // ===== View =====

    /// @notice             Fetches the current invariant, notation is usually `k`, based on risky and stable token reserves of pool with `poolId`
    /// @param  poolId      Keccak256 hash of the engine address, strike, sigma, maturity, and gamma
    /// @return invariant   Signed fixed point 64.64 number, invariant of `poolId`
    function invariantOf(bytes32 poolId) external view returns (int128 invariant);

    // ===== Constants =====

    /// @return Precision units to scale to when doing token related calculations
    function PRECISION() external view returns (uint256);

    /// @return Amount of seconds after pool expiry which allows swaps, no swaps after buffer
    function BUFFER() external view returns (uint256);

    // ===== Immutables =====

    /// @return Amount of liquidity burned on `create()` calls
    function MIN_LIQUIDITY() external view returns (uint256);

    //// @return Factory address which deployed this engine contract
    function factory() external view returns (address);

    //// @return Risky token address, a more accurate name is the underlying token
    function risky() external view returns (address);

    /// @return Stable token address, a more accurate name is the quote token
    function stable() external view returns (address);

    /// @return Multiplier to scale amounts to/from, equal to 10^(18 - riskyDecimals)
    function scaleFactorRisky() external view returns (uint256);

    /// @return Multiplier to scale amounts to/from, equal to 10^(18 - stableDecimals)
    function scaleFactorStable() external view returns (uint256);

    // ===== Pool State =====

    /// @notice                      Fetches the global reserve state for a pool with `poolId`
    /// @param  poolId               Keccak256 hash of the engine address, strike, sigma, maturity, and gamma
    /// @return reserveRisky         Risky token balance in the reserve
    /// @return reserveStable        Stable token balance in the reserve
    /// @return liquidity            Total supply of liquidity for the curve
    /// @return blockTimestamp       Timestamp when the cumulative reserve values were last updated
    /// @return cumulativeRisky      Cumulative sum of risky token reserves of the previous update
    /// @return cumulativeStable     Cumulative sum of stable token reserves of the previous update
    /// @return cumulativeLiquidity  Cumulative sum of total supply of liquidity of the previous update
    function reserves(bytes32 poolId)
        external
        view
        returns (
            uint128 reserveRisky,
            uint128 reserveStable,
            uint128 liquidity,
            uint32 blockTimestamp,
            uint256 cumulativeRisky,
            uint256 cumulativeStable,
            uint256 cumulativeLiquidity
        );

    /// @notice                 Fetches `Calibration` pool parameters
    /// @param  poolId          Keccak256 hash of the engine address, strike, sigma, maturity, and gamma
    /// @return strike          Marginal price of the pool's risky token at maturity, with the same decimals as the stable token, valid [0, 2^128-1]
    /// @return sigma           AKA Implied Volatility in basis points, determines the price impact of swaps, valid for (1, 10_000_000)
    /// @return maturity        Timestamp which starts the BUFFER countdown until swaps will cease, in seconds, valid for (block.timestamp, 2^32-1]
    /// @return lastTimestamp   Last timestamp used to calculate time until expiry, aka "tau"
    /// @return gamma           Multiplied against swap in amounts to apply fee, equal to 1 - fee % but units are in basis points, valid for (9_000, 10_000)
    function calibrations(bytes32 poolId)
        external
        view
        returns (
            uint128 strike,
            uint32 sigma,
            uint32 maturity,
            uint32 lastTimestamp,
            uint32 gamma
        );

    /// @notice             Fetches position liquidity an account address and poolId
    /// @param  poolId      Keccak256 hash of the engine address, strike, sigma, maturity, and gamma
    /// @return liquidity   Liquidity owned by `account` in `poolId`
    function liquidity(address account, bytes32 poolId) external view returns (uint256 liquidity);

    /// @notice                 Fetches the margin balances of `account`
    /// @param  account         Margin account to fetch
    /// @return balanceRisky    Balance of the risky token
    /// @return balanceStable   Balance of the stable token
    function margins(address account) external view returns (uint128 balanceRisky, uint128 balanceStable);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.6;

/// @title   Interface of PositionRenderer contract
/// @author  Primitive
interface IPositionRenderer {
    /// @notice         Returns a SVG representation of a position token
    /// @param engine   Address of the PrimitiveEngine contract
    /// @param tokenId  Id of the position token (pool id)
    /// @return         SVG image as a base64 encoded string
    function render(address engine, uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.6;

import "./IERC20.sol";

/// @title   ERC20 Interface with metadata
/// @author  Primitive
interface IERC20WithMetadata is IERC20 {
    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.6;

/// @title   Interface of PositionDescriptor contract
/// @author  Primitive
interface IPositionDescriptor {
    /// VIEW FUNCTIONS ///

    /// @notice  Returns the address of the PositionRenderer contract
    function positionRenderer() external view returns (address);

    /// @notice         Returns the metadata of a position token
    /// @param engine   Address of the PrimitiveEngine contract
    /// @param tokenId  Id of the position token (pool id)
    /// @return         Metadata as a base64 encoded JSON string
    function getMetadata(address engine, uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.6;

/// @title   ERC20 Interface
/// @author  Primitive
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}