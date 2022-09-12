// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/INonfungiblePlanManager.sol";
import "./interfaces/INonfungibleTokenPlanDescriptor.sol";
import "./interfaces/IERC20Metadata.sol";
import "./libraries/PoolAddress.sol";
import "./libraries/NFTDescriptor.sol";
import "./libraries/SafeERC20Namer.sol";

contract NonfungibleTokenPlanDescriptor is INonfungibleTokenPlanDescriptor {
    address public immutable WETH9;

    constructor(address _WETH9) {
        WETH9 = _WETH9;
    }

    function tokenURI(INonfungiblePlanManager planManager, uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        (
            INonfungiblePlanManager.Plan memory plan,
            INonfungiblePlanManager.PlanStatistics memory statistics
        ) = planManager.getPlan(tokenId);

        address pool = PoolAddress.computeAddress(
            planManager.factory(),
            PoolAddress.getPoolInfo(plan.token0, plan.token1, plan.frequency)
        );

        address tokenAddress = plan.token1;
        address stableCoinAddress = plan.token0;
        return
            NFTDescriptor.constructTokenURI(
                NFTDescriptor.ConstructTokenURIParams({
                    tokenId: tokenId,
                    stableCoinAddress: stableCoinAddress,
                    stableCoinSymbol: SafeERC20Namer.tokenSymbol(
                        stableCoinAddress
                    ),
                    tokenAddress: tokenAddress,
                    tokenSymbol: tokenAddress == WETH9
                        ? "ETH"
                        : SafeERC20Namer.tokenSymbol(tokenAddress),
                    tokenDecimals: IERC20Metadata(tokenAddress).decimals(),
                    frequency: plan.frequency,
                    poolAddress: pool,
                    tickAmount: plan.tickAmount,
                    ongoing: plan.tickAmount * statistics.remainingTicks,
                    invested: statistics.swapAmount1,
                    withdrawn: statistics.withdrawnAmount1,
                    ticks: statistics.ticks,
                    remainingTicks: statistics.remainingTicks
                })
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PoolAddress.sol";

interface INonfungiblePlanManager {
    struct Plan {
        uint96 nonce;
        address operator;
        address investor;
        address token0;
        address token1;
        uint8 frequency;
        uint256 index;
        uint256 tickAmount;
        uint256 createdTime;
    }
    struct PlanStatistics {
        uint256 swapAmount1;
        uint256 withdrawnAmount1;
        uint256 ticks;
        uint256 remainingTicks;
        uint256 startedTime;
        uint256 endedTime;
        uint256 lastTriggerTime;
    }

    function factory() external view returns (address);

    function plansOf(address) external view returns (uint256[] memory);

    function getPlan(uint256 tokenId)
        external
        view
        returns (Plan memory plan, PlanStatistics memory statistics);

    function createPoolIfNecessary(PoolAddress.PoolInfo calldata poolInfo)
        external
        payable
        returns (address pool);

    struct MintParams {
        address investor;
        address token0;
        address token1;
        uint8 frequency;
        uint256 tickAmount;
        uint256 periods;
    }

    function mint(MintParams calldata params)
        external
        payable
        returns (uint256 tokenId, uint256 planIndex);

    function extend(uint256 id, uint256 periods) external payable;

    function burn(uint256 id)
        external
        returns (uint256 received0, uint256 received1);

    function withdraw(uint256 id) external returns (uint256 received1);

    function claimReward(uint256 id)
        external
        returns (
            address token,
            uint256 unclaimedAmount,
            uint256 claimedAmount
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INonfungiblePlanManager.sol";

interface INonfungibleTokenPlanDescriptor {
    function tokenURI(INonfungiblePlanManager planManager, uint256 tokenId)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IERC20Metadata
/// @title Interface for ERC20 Metadata
/// @notice Extension to IERC20 that includes token metadata
interface IERC20Metadata is IERC20 {
    /// @return The name of the token
    function name() external view returns (string memory);

    /// @return The symbol of the token
    function symbol() external view returns (string memory);

    /// @return The number of decimal places the token has
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH =
        0x098c345b264007f76b7c7fbf78386734ff3f88b2d0f278f42c3d88de8d5287ac;

    struct PoolInfo {
        address token0;
        address token1;
        uint8 frequency;
    }

    function getPoolInfo(
        address token0,
        address token1,
        uint8 frequency
    ) internal pure returns (PoolInfo memory) {
        return PoolInfo({token0: token0, token1: token1, frequency: frequency});
    }

    function computeAddress(address factory, PoolInfo memory poolInfo)
        internal
        pure
        returns (address pool)
    {
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(
                                abi.encode(
                                    poolInfo.token0,
                                    poolInfo.token1,
                                    poolInfo.frequency
                                )
                            ),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";
import "./HexStrings.sol";
import "./NFTSVG.sol";

// import "hardhat/console.sol";

library NFTDescriptor {
    using Strings for uint256;
    using HexStrings for uint256;
    struct ConstructTokenURIParams {
        uint256 tokenId;
        address stableCoinAddress;
        address tokenAddress;
        string stableCoinSymbol;
        string tokenSymbol;
        uint8 tokenDecimals;
        uint8 frequency;
        address poolAddress;
        uint256 tickAmount;
        uint256 ongoing;
        uint256 invested;
        uint256 withdrawn;
        uint256 ticks;
        uint256 remainingTicks;
    }

    function constructTokenURI(ConstructTokenURIParams memory params)
        internal
        pure
        returns (string memory)
    {
        string memory namePartOne = generateNamePartOne(params);
        string memory namePartTwo = generateNamePartTwo(params);
        string memory descriptionPartOne = generateDescriptionPartOne(
            escapeQuotes(params.stableCoinSymbol),
            escapeQuotes(params.tokenSymbol),
            addressToString(params.poolAddress)
        );
        string memory descriptionPartTwo = generateDescriptionPartTwo(
            params.tokenId.toString(),
            escapeQuotes(params.stableCoinSymbol),
            addressToString(params.stableCoinAddress),
            addressToString(params.tokenAddress),
            Strings.toString(params.frequency)
        );
        string memory image = Base64.encode(bytes(generateSVGImage(params)));

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                namePartOne,
                                namePartTwo,
                                '", "description":"',
                                descriptionPartOne,
                                descriptionPartTwo,
                                '","image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function escapeQuotes(string memory symbol)
        internal
        pure
        returns (string memory)
    {
        bytes memory symbolBytes = bytes(symbol);
        uint8 quotesCount = 0;
        for (uint8 i = 0; i < symbolBytes.length; i++) {
            if (symbolBytes[i] == '"') {
                quotesCount++;
            }
        }
        if (quotesCount > 0) {
            bytes memory escapedBytes = new bytes(
                symbolBytes.length + (quotesCount)
            );
            uint256 index;
            for (uint8 i = 0; i < symbolBytes.length; i++) {
                if (symbolBytes[i] == '"') {
                    escapedBytes[index++] = "\\";
                }
                escapedBytes[index++] = symbolBytes[i];
            }
            return string(escapedBytes);
        }
        return symbol;
    }

    function decimalString(
        uint256 number,
        uint8 decimals,
        bool isPercent
    ) private pure returns (string memory) {
        uint8 percentBufferOffset = isPercent ? 1 : 0;
        uint256 tenPowDecimals = 10**decimals;

        uint256 temp = number;
        uint8 digits;
        uint8 numSigfigs;
        while (temp != 0) {
            if (numSigfigs > 0) {
                // count all digits preceding least significant figure
                numSigfigs++;
            } else if (temp % 10 != 0) {
                numSigfigs++;
            }
            digits++;
            temp /= 10;
        }
        DecimalStringParams memory params;
        params.isPercent = isPercent;
        if ((digits - numSigfigs) >= decimals) {
            // no decimals, ensure we preserve all trailing zeros
            params.sigfigs = number / tenPowDecimals;
            params.sigfigIndex = digits - decimals;
            params.bufferLength = params.sigfigIndex + percentBufferOffset;
        } else {
            // chop all trailing zeros for numbers with decimals
            params.sigfigs = number / (10**(digits - numSigfigs));
            if (tenPowDecimals > number) {
                // number is less tahn one
                // in this case, there may be leading zeros after the decimal place
                // that need to be added

                // offset leading zeros by two to account for leading '0.'
                params.zerosStartIndex = 2;
                params.zerosEndIndex = decimals - digits + 2;
                params.sigfigIndex = numSigfigs + params.zerosEndIndex;
                params.bufferLength = params.sigfigIndex + percentBufferOffset;
                params.isLessThanOne = true;
            } else {
                // In this case, there are digits before and
                // after the decimal place
                params.sigfigIndex = numSigfigs + 1;
                params.decimalIndex = digits - decimals + 1;
            }
        }
        params.bufferLength = params.sigfigIndex + percentBufferOffset;
        return generateDecimalString(params);
    }

    struct DecimalStringParams {
        // significant figures of decimal
        uint256 sigfigs;
        // length of decimal string
        uint8 bufferLength;
        // ending index for significant figures (funtion works backwards when copying sigfigs)
        uint8 sigfigIndex;
        // index of decimal place (0 if no decimal)
        uint8 decimalIndex;
        // start index for trailing/leading 0's for very small/large numbers
        uint8 zerosStartIndex;
        // end index for trailing/leading 0's for very small/large numbers
        uint8 zerosEndIndex;
        // true if decimal number is less than one
        bool isLessThanOne;
        // true if string should include "%"
        bool isPercent;
    }

    function generateDecimalString(DecimalStringParams memory params)
        private
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(params.bufferLength);
        if (params.isPercent) {
            buffer[buffer.length - 1] = "%";
        }
        if (params.isLessThanOne) {
            buffer[0] = "0";
            buffer[1] = ".";
        }

        // add leading/trailing 0's
        for (
            uint256 zerosCursor = params.zerosStartIndex;
            zerosCursor < params.zerosEndIndex + 1;
            zerosCursor++
        ) {
            buffer[zerosCursor] = bytes1(uint8(48));
        }
        // add sigfigs
        while (params.sigfigs > 0) {
            if (
                params.decimalIndex > 0 &&
                params.sigfigIndex == params.decimalIndex
            ) {
                buffer[--params.sigfigIndex] = ".";
            }
            buffer[--params.sigfigIndex] = bytes1(
                uint8(uint256(48) + (params.sigfigs % 10))
            );
            params.sigfigs /= 10;
        }
        return string(buffer);
    }

    function addressToString(address addr)
        internal
        pure
        returns (string memory)
    {
        return (uint256(uint160(addr))).toHexString(20);
    }

    function generateDescriptionPartOne(
        string memory stableCoinSymbol,
        string memory tokenSymbol,
        string memory poolAddress
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "This NFT represents an auto investment plan in an AIP ",
                    tokenSymbol,
                    "/",
                    stableCoinSymbol,
                    " pool. ",
                    "The owner of this NFT can end the plan and withdraw all remaining tokens.\\n",
                    "\\nPool Address: ",
                    poolAddress,
                    "\\n",
                    tokenSymbol
                )
            );
    }

    function generateDescriptionPartTwo(
        string memory tokenId,
        string memory stableCoinSymbol,
        string memory stableCoinAddress,
        string memory tokenAddress,
        string memory frequency
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    " Address: ",
                    tokenAddress,
                    "\\n",
                    stableCoinSymbol,
                    " Address: ",
                    stableCoinAddress,
                    "\\nFrequency: ",
                    frequency,
                    " days",
                    "\\nToken ID: ",
                    tokenId,
                    "\\n\\n",
                    unicode"⚠️ DISCLAIMER: Due diligence is imperative when assessing this NFT. Make sure token addresses match the expected tokens, as token symbols may be imitated."
                )
            );
    }

    function generateNamePartOne(ConstructTokenURIParams memory params)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "AIP - Invest ",
                    escapeQuotes(params.tokenSymbol),
                    " with ",
                    decimalString(
                        params.tickAmount,
                        params.tokenDecimals,
                        false
                    ),
                    " ",
                    escapeQuotes(params.stableCoinSymbol),
                    " every ",
                    Strings.toString(params.frequency),
                    params.frequency == 1 ? " day and " : " days and ",
                    Strings.toString(params.ticks),
                    params.ticks > 1 ? " periods" : " period"
                )
            );
    }

    function generateNamePartTwo(ConstructTokenURIParams memory params)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    " - Invested: ",
                    params.invested == 0
                        ? "0"
                        : decimalString(
                            params.invested,
                            params.tokenDecimals,
                            false
                        ),
                    " ",
                    escapeQuotes(params.tokenSymbol),
                    ". Ongoing: ",
                    params.ongoing == 0
                        ? "0"
                        : decimalString(params.ongoing, 18, false),
                    " ",
                    escapeQuotes(params.stableCoinSymbol)
                )
            );
    }

    function tokenToColorHex(uint256 token, uint256 offset)
        internal
        pure
        returns (string memory str)
    {
        return string((token >> offset).toHexStringNoPrefix(3));
    }

    function generateSVGImage(ConstructTokenURIParams memory params)
        internal
        pure
        returns (string memory svg)
    {
        NFTSVG.SVGParams memory svgParams = NFTSVG.SVGParams({
            tokenId: params.tokenId,
            stableCoin: addressToString(params.stableCoinAddress),
            token: addressToString(params.tokenAddress),
            stableCoinSymbol: params.stableCoinSymbol,
            tokenSymbol: params.tokenSymbol,
            color0: tokenToColorHex(
                uint256(uint160(params.stableCoinAddress)),
                136
            ),
            color1: tokenToColorHex(uint256(uint160(params.tokenAddress)), 136),
            frequency: Strings.toString(params.frequency),
            tickAmount: decimalString(params.tickAmount, 18, false),
            ongoing: params.ongoing == 0
                ? "0"
                : decimalString(params.ongoing, 18, false),
            invested: params.invested == 0
                ? "0"
                : decimalString(params.invested, params.tokenDecimals, false),
            withdrawn: params.withdrawn == 0
                ? "0"
                : decimalString(params.withdrawn, params.tokenDecimals, false),
            ticks: params.ticks,
            currentTicks: params.ticks - params.remainingTicks
        });

        return NFTSVG.generateSVG(svgParams);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./AddressStringUtil.sol";

// produces token descriptors from inconsistent or absent ERC20 symbol implementations that can return string or bytes32
// this library will always produce a string symbol to represent the token
library SafeERC20Namer {
    function bytes32ToString(bytes32 x) private pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint256 charCount = 0;
        for (uint256 j = 0; j < 32; j++) {
            bytes1 char = x[j];
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    // assumes the data is in position 2
    function parseStringData(bytes memory b)
        private
        pure
        returns (string memory)
    {
        uint256 charCount = 0;
        // first parse the charCount out of the data
        for (uint256 i = 32; i < 64; i++) {
            charCount <<= 8;
            charCount += uint8(b[i]);
        }

        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 i = 0; i < charCount; i++) {
            bytesStringTrimmed[i] = b[i + 64];
        }

        return string(bytesStringTrimmed);
    }

    // uses a heuristic to produce a token name from the address
    // the heuristic returns the full hex of the address string in upper case
    function addressToName(address token) private pure returns (string memory) {
        return AddressStringUtil.toAsciiString(token, 40);
    }

    // uses a heuristic to produce a token symbol from the address
    // the heuristic returns the first 6 hex of the address string in upper case
    function addressToSymbol(address token)
        private
        pure
        returns (string memory)
    {
        return AddressStringUtil.toAsciiString(token, 6);
    }

    // calls an external view token contract method that returns a symbol or name, and parses the output into a string
    function callAndParseStringReturn(address token, bytes4 selector)
        private
        view
        returns (string memory)
    {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(selector)
        );
        // if not implemented, or returns empty data, return empty string
        if (!success || data.length == 0) {
            return "";
        }
        // bytes32 data always has length 32
        if (data.length == 32) {
            bytes32 decoded = abi.decode(data, (bytes32));
            return bytes32ToString(decoded);
        } else if (data.length > 64) {
            return abi.decode(data, (string));
        }
        return "";
    }

    // attempts to extract the token symbol. if it does not implement symbol, returns a symbol derived from the address
    function tokenSymbol(address token) internal view returns (string memory) {
        // 0x95d89b41 = bytes4(keccak256("symbol()"))
        string memory symbol = callAndParseStringReturn(token, 0x95d89b41);
        if (bytes(symbol).length == 0) {
            // fallback to 6 uppercase hex of address
            return addressToSymbol(token);
        }
        return symbol;
    }

    // attempts to extract the token name. if it does not implement name, returns a name derived from the address
    function tokenName(address token) internal view returns (string memory) {
        // 0x06fdde03 = bytes4(keccak256("name()"))
        string memory name = callAndParseStringReturn(token, 0x06fdde03);
        if (bytes(name).length == 0) {
            // fallback to full hex of address
            return addressToName(token);
        }
        return name;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library HexStrings {
    bytes16 internal constant ALPHABET = "0123456789abcdef";

    function toHexStringNoPrefix(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

/// @title NFTSVG
/// @notice Provides a function for generating an SVG associated with a Uniswap NFT
library NFTSVG {
    using Strings for uint256;

    struct SVGParams {
        uint256 tokenId;
        string stableCoin;
        string token;
        string stableCoinSymbol;
        string tokenSymbol;
        string color0;
        string color1;
        string frequency;
        string tickAmount;
        string ongoing;
        string invested;
        string withdrawn;
        uint256 ticks;
        uint256 currentTicks;
    }

    function generateSVG(SVGParams memory params)
        internal
        pure
        returns (string memory svg)
    {
        /*
        address: "0xe8ab59d3bcde16a29912de83a90eb39628cfc163",
        msg: "Forged in SVG for Uniswap in 2021 by 0xe8ab59d3bcde16a29912de83a90eb39628cfc163",
        sig: "0x2df0e99d9cbfec33a705d83f75666d98b22dea7c1af412c584f7d626d83f02875993df740dc87563b9c73378f8462426da572d7989de88079a382ad96c57b68d1b",
        version: "2"
        */
        return
            string(
                abi.encodePacked(
                    generateSVGDefs(),
                    generateSVGFooter(
                        params.stableCoin,
                        params.stableCoinSymbol,
                        params.token,
                        params.tokenSymbol
                    ),
                    generateSVGBody(params),
                    generateSVGTitle(
                        params.stableCoinSymbol,
                        params.tokenSymbol,
                        params.tickAmount,
                        params.frequency
                    ),
                    generateSVGProgress(params.ticks, params.currentTicks),
                    "</svg>"
                )
            );
    }

    function generateSVGDefs() private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<svg width="400" height="500" viewBox="0 0 400 500" xmlns="http://www.w3.org/2000/svg"',
                ' xmlns:xlink="http://www.w3.org/1999/xlink">'
            )
        );
    }

    function generateSVGTitle(
        string memory stableCoinSymbol,
        string memory tokenSymbol,
        string memory tickAmount,
        string memory frequency
    ) private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<rect fill="#030303" width="400" height="167"/>',
                '<text transform="matrix(1 0 0 1 20 46)" font-size="36px" fill="white" font-family="\'Courier New\', monospace">',
                tokenSymbol,
                unicode"•",
                frequency,
                "D</text>",
                '<text transform="matrix(1 0 0 1 20 82)" fill="#B1B5C4" font-size="18px" font-family="\'Courier New\', monospace">',
                tickAmount,
                " ",
                stableCoinSymbol,
                " per period</text>"
            )
        );
    }

    function generateSVGProgress(uint256 ticks, uint256 currentTicks)
        private
        pure
        returns (string memory svg)
    {
        svg = string(
            abi.encodePacked(
                '<rect x="20" y="108" fill="white" width="360" height="6"/>',
                '<rect x="20" y="108" fill="#B1E846" width="',
                ((360 * currentTicks) / ticks).toString(),
                '" height="6"/>',
                '<text transform="matrix(1 0 0 1 20 142)" font-size="18px" fill="#B1E846" font-family="\'Courier New\', monospace">',
                currentTicks.toString(),
                "/",
                ticks.toString(),
                " Periods</text>"
            )
        );
    }

    function generateSVGBody(SVGParams memory params)
        private
        pure
        returns (string memory svg)
    {
        svg = string(
            abi.encodePacked(
                generateBodyBackground(params.color0, params.color1),
                generateBodyInfo(
                    "Invested",
                    params.invested,
                    params.tokenSymbol,
                    "276"
                ),
                generateBodyInfo(
                    "Withdrawn",
                    params.withdrawn,
                    params.tokenSymbol,
                    "329"
                ),
                generateBodyInfo(
                    "Ongoing",
                    params.ongoing,
                    params.stableCoinSymbol,
                    "381"
                ),
                generateSVGTokenId(params.tokenId)
            )
        );
    }

    function generateBodyInfo(
        string memory title,
        string memory amount,
        string memory symbol,
        string memory pos
    ) private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<text transform="matrix(1 0 0 1 32 ',
                pos,
                ')" fill="#B1B5C4" font-size="18px" font-family="\'Courier New\', monospace">',
                title,
                ":</text>",
                '<text transform="matrix(1 0 0 1 150 ',
                pos,
                ')" font-size="18px"  fill="white" font-family="\'Courier New\', monospace">',
                amount,
                " ",
                symbol,
                "</text>"
            )
        );
    }

    function generateBodyBackground(string memory color0, string memory color1)
        private
        pure
        returns (string memory svg)
    {
        svg = string(
            abi.encodePacked(
                '<linearGradient id="SVGID_1_" gradientUnits="userSpaceOnUse" x1="-17.7126" y1="34.2906" x2="272.5754" y2="381.9086">',
                '<stop offset="0" style="stop-color:#',
                color0,
                '"/>',
                '<stop offset="1" style="stop-color:#',
                color1,
                '"/>',
                "</linearGradient>",
                '<rect y="167" fill="url(#SVGID_1_)" width="400" height="256"/>',
                '<path fill="#23262F" opacity="0.68" d="M380,349.9H20v39c0,6.6,5.4,12,12,12h336c6.6,0,12-5.4,12-12V349.9z"/>',
                '<path fill="#23262F" opacity="0.68" d="M368,245H32c-6.6,0-12,5.4-12,12v39h360v-39C380,250.4,374.6,245,368,245z"/>'
                '<rect x="20" y="297.3" fill="#23262F" opacity="0.68" width="360" height="51"/>',
                '<path fill="#23262F" opacity="0.68" d="M364.8,187.5H35.2c-8.4,0-15.2,6.8-15.2,15.2v20.7c0,8.4,6.8,15.2,15.2,15.2',
                'h329.7c8.4,0,15.2-6.8,15.2-15.2v-20.7C380,194.3,373.2,187.5,364.8,187.5z"/>'
            )
        );
    }

    function generateSVGTokenId(uint256 tokenId)
        private
        pure
        returns (string memory svg)
    {
        svg = string(
            abi.encodePacked(
                '<path fill="white" d="M50.9,205c-4.3,0-7.7,3.7-7.7,8C47.5,213,50.9,209.3,50.9,205z"/>',
                '<path fill="white" d="M51,205c0,4.3,3.3,8,7.7,8C58.6,208.7,55.3,205,51,205z"/>',
                '<path fill="white" d="M58.6,213c-4.2,0.2-7.5,3.6-7.5,8C55.2,220.9,58.6,217.3,58.6,213z"/>',
                '<path fill="white" d="M50.9,221c0.1,0,0.1,0,0.2,0c-0.2-4.3-3.5-7.8-7.8-8C43.3,217.5,46.6,221,50.9,221z"/>',
                '<path fill="white" d="M51.2,214.3L51.2,214.3L51.2,214.3L51.2,214.3z"/>',
                '<rect x="39" y="201" transform="matrix(0.7071 -0.7071 0.7071 0.7071 -135.6834 98.4286)" fill="none" ',
                'stroke="#E6E8EC" stroke-width="0.25" width="24" height="24"/>',
                '<text transform="matrix(1 0 0 1 80 217)" fill="#B1B5C4" font-size="18px" font-family="\'Courier New\', monospace">ID:</text>',
                '<text transform="matrix(1 0 0 1 128 217)" font-size="18px"  fill="white" font-family="\'Courier New\', monospace">',
                tokenId.toString(),
                "</text>"
            )
        );
    }

    function generateSVGFooter(
        string memory stableCoin,
        string memory stableCoinSymbol,
        string memory token,
        string memory tokenSymbol
    ) private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<rect y="423" fill="#030303" width="400" height="78"/>',
                '<text transform="matrix(1 0 0 1 20 480)" font-size="11px" fill="white" font-family="\'Courier New\', monospace">',
                tokenSymbol,
                unicode" • ",
                token,
                "</text>",
                '<text transform="matrix(1 0 0 1 20 450)" font-size="11px" fill="white" font-family="\'Courier New\', monospace">',
                stableCoinSymbol,
                unicode" • ",
                stableCoin,
                "</text>"
            )
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

library AddressStringUtil {
    // converts an address to the uppercase hex string, extracting only len bytes (up to 20, multiple of 2)
    function toAsciiString(address addr, uint256 len)
        internal
        pure
        returns (string memory)
    {
        require(
            len % 2 == 0 && len > 0 && len <= 40,
            "AddressStringUtil: INVALID_LEN"
        );

        bytes memory s = new bytes(len);
        uint256 addrNum = uint256(uint160(addr));
        for (uint256 i = 0; i < len / 2; i++) {
            // shift right and truncate all but the least significant byte to extract the byte at position 19-i
            uint8 b = uint8(addrNum >> (8 * (19 - i)));
            // first hex character is the most significant 4 bits
            uint8 hi = b >> 4;
            // second hex character is the least significant 4 bits
            uint8 lo = b - (hi << 4);
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    // hi and lo are only 4 bits and between 0 and 16
    // this method converts those values to the unicode/ascii code point for the hex representation
    // uses upper case for the characters
    function char(uint8 b) private pure returns (bytes1 c) {
        if (b < 10) {
            return bytes1(b + 0x30);
        } else {
            return bytes1(b + 0x37);
        }
    }
}