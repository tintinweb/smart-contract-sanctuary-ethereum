// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity 0.8.16;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
        // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

        // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

        // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
            // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

            // To write each character, shift the 3 bytes (18 bits) chunk
            // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
            // and apply logical AND with 0x3F which is the number of
            // the previous character in the ASCII table prior to the Base64 Table
            // The result is then added to the table to get the character to write,
            // and finally write it in the result pointer but with a left shift
            // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

        // When data `bytes` is not exactly 3 bytes long
        // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.16;

import "base64/Base64.sol";
import "solmate/tokens/ERC20.sol";

import "./interfaces/IOptionSettlementEngine.sol";
import "./interfaces/ITokenURIGenerator.sol";

/// @title Library to dynamically generate Valorem token URIs
/// @author Thal0x
/// @author Flip-Liquid
/// @author neodaoist
/// @author 0xAlcibiades
contract TokenURIGenerator is ITokenURIGenerator {
    /// @inheritdoc ITokenURIGenerator
    function constructTokenURI(TokenURIParams memory params) public view returns (string memory) {
        string memory svg = generateNFT(params);

        /* solhint-disable quotes */
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"',
                        generateName(params),
                        '", "description": "',
                        generateDescription(params),
                        '", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '"}'
                    )
                )
            )
        );
        /* solhint-enable quotes */
    }

    /// @inheritdoc ITokenURIGenerator
    function generateName(TokenURIParams memory params) public pure returns (string memory) {
        (uint256 month, uint256 day, uint256 year) = _getDateUnits(params.expiryTimestamp);

        bytes memory yearDigits = bytes(_toString(year));
        bytes memory monthDigits = bytes(_toString(month));
        bytes memory dayDigits = bytes(_toString(day));

        return string(
            abi.encodePacked(
                _escapeQuotes(params.underlyingSymbol),
                _escapeQuotes(params.exerciseSymbol),
                yearDigits[2],
                yearDigits[3],
                monthDigits.length == 2 ? monthDigits[0] : bytes1(uint8(48)),
                monthDigits.length == 2 ? monthDigits[1] : monthDigits[0],
                dayDigits.length == 2 ? dayDigits[0] : bytes1(uint8(48)),
                dayDigits.length == 2 ? dayDigits[1] : dayDigits[0],
                "C"
            )
        );
    }

    /// @inheritdoc ITokenURIGenerator
    function generateDescription(TokenURIParams memory params) public pure returns (string memory) {
        return string(
            abi.encodePacked(
                "NFT representing a Valorem options contract. ",
                params.underlyingSymbol,
                " Address: ",
                addressToString(params.underlyingAsset),
                ". ",
                params.exerciseSymbol,
                " Address: ",
                addressToString(params.exerciseAsset),
                "."
            )
        );
    }

    /// @inheritdoc ITokenURIGenerator
    function generateNFT(TokenURIParams memory params) public view returns (string memory) {
        uint8 underlyingDecimals = ERC20(params.underlyingAsset).decimals();
        uint8 exerciseDecimals = ERC20(params.exerciseAsset).decimals();

        return string(
            abi.encodePacked(
                "<svg width='400' height='300' viewBox='0 0 400 300' xmlns='http://www.w3.org/2000/svg'>",
                "<rect width='100%' height='100%' rx='12' ry='12'  fill='#3E5DC7' />",
                "<g transform='scale(5), translate(25, 18)' fill-opacity='0.15'>",
                "<path xmlns='http://www.w3.org/2000/svg' d='M69.3577 14.5031H29.7265L39.6312 0H0L19.8156 29L29.7265 14.5031L39.6312 29H19.8156H0L19.8156 58L39.6312 29L49.5421 43.5031L69.3577 14.5031Z' fill='white'/>",
                "</g>",
                _generateHeaderSection(params.underlyingSymbol, params.exerciseSymbol, params.tokenType),
                _generateAmountsSection(
                    params.underlyingAmount,
                    params.underlyingSymbol,
                    underlyingDecimals,
                    params.exerciseAmount,
                    params.exerciseSymbol,
                    exerciseDecimals
                ),
                _generateDateSection(params),
                "</svg>"
            )
        );
    }

    function _generateHeaderSection(
        string memory _underlyingSymbol,
        string memory _exerciseSymbol,
        IOptionSettlementEngine.TokenType _tokenType
    ) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                abi.encodePacked(
                    "<text x='16px' y='55px' font-size='32px' fill='#fff' font-family='Helvetica'>",
                    _underlyingSymbol,
                    " / ",
                    _exerciseSymbol,
                    "</text>"
                ),
                _tokenType == IOptionSettlementEngine.TokenType.Option
                    ?
                    "<text x='16px' y='80px' font-size='16' fill='#fff' font-family='Helvetica' font-weight='300'>Long Call</text>"
                    :
                    "<text x='16px' y='80px' font-size='16' fill='#fff' font-family='Helvetica' font-weight='300'>Short Call</text>"
            )
        );
    }

    function _generateAmountsSection(
        uint256 _underlyingAmount,
        string memory _underlyingSymbol,
        uint8 _underlyingDecimals,
        uint256 _exerciseAmount,
        string memory _exerciseSymbol,
        uint8 _exerciseDecimals
    ) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                "<text x='16px' y='116px' font-size='14' letter-spacing='0.01em' fill='#fff' font-family='Helvetica'>UNDERLYING ASSET</text>",
                _generateAmountString(_underlyingAmount, _underlyingDecimals, _underlyingSymbol, 16, 140),
                "<text x='16px' y='176px' font-size='14' letter-spacing='0.01em' fill='#fff' font-family='Helvetica'>EXERCISE ASSET</text>",
                _generateAmountString(_exerciseAmount, _exerciseDecimals, _exerciseSymbol, 16, 200)
            )
        );
    }

    function _generateDateSection(TokenURIParams memory params) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                "<text x='16px' y='236px' font-size='14' letter-spacing='0.01em' fill='#fff' font-family='Helvetica'>EXERCISE DATE</text>",
                _generateTimestampString(params.exerciseTimestamp, 16, 260),
                "<text x='200px' y='236px' font-size='14' letter-spacing='0.01em' fill='#fff' font-family='Helvetica'>EXPIRY DATE</text>",
                _generateTimestampString(params.expiryTimestamp, 200, 260)
            )
        );
    }

    function _generateAmountString(uint256 _amount, uint8 _decimals, string memory _symbol, uint256 _x, uint256 _y)
        internal
        pure
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                "<text x='",
                _toString(_x),
                "px' y='",
                _toString(_y),
                "px' font-size='18' fill='#fff' font-family='Helvetica' font-weight='300'>",
                _decimalString(_amount, _decimals, false),
                " ",
                _symbol,
                "</text>"
            )
        );
    }

    function _generateTimestampString(uint256 _timestamp, uint256 _x, uint256 _y)
        internal
        pure
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                "<text x='",
                _toString(_x),
                "px' y='",
                _toString(_y),
                "px' font-size='18' fill='#fff' font-family='Helvetica' font-weight='300'>",
                _generateDateString(_timestamp),
                "</text>"
            )
        );
    }

    /// @notice Utilities
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

    function _generateDecimalString(DecimalStringParams memory params) internal pure returns (string memory) {
        bytes memory buffer = new bytes(params.bufferLength);
        if (params.isPercent) {
            buffer[buffer.length - 1] = "%";
        }
        if (params.isLessThanOne) {
            buffer[0] = "0";
            buffer[1] = ".";
        }

        // add leading/trailing 0's
        for (uint256 zerosCursor = params.zerosStartIndex; zerosCursor < params.zerosEndIndex; zerosCursor++) {
            buffer[zerosCursor] = bytes1(uint8(48));
        }
        // add sigfigs
        while (params.sigfigs > 0) {
            if (params.decimalIndex > 0 && params.sigfigIndex == params.decimalIndex) {
                buffer[--params.sigfigIndex] = ".";
            }
            buffer[--params.sigfigIndex] = bytes1(uint8(uint256(48) + (params.sigfigs % 10)));
            params.sigfigs /= 10;
        }
        return string(buffer);
    }

    function _decimalString(uint256 number, uint8 decimals, bool isPercent) internal pure returns (string memory) {
        uint8 percentBufferOffset = isPercent ? 1 : 0;
        uint256 tenPowDecimals = 10 ** decimals;

        uint256 temp = number;
        uint8 digits = 0;
        uint8 numSigfigs = 0;
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

        DecimalStringParams memory params = DecimalStringParams({
            sigfigs: uint256(0),
            bufferLength: uint8(0),
            sigfigIndex: uint8(0),
            decimalIndex: uint8(0),
            zerosStartIndex: uint8(0),
            zerosEndIndex: uint8(0),
            isLessThanOne: false,
            isPercent: false
        });
        params.isPercent = isPercent;
        if ((digits - numSigfigs) >= decimals) {
            // no decimals, ensure we preserve all trailing zeros
            params.sigfigs = number / tenPowDecimals;
            params.sigfigIndex = digits - decimals;
            params.bufferLength = params.sigfigIndex + percentBufferOffset;
        } else {
            // chop all trailing zeros for numbers with decimals
            params.sigfigs = number / (10 ** (digits - numSigfigs));
            if (tenPowDecimals > number) {
                // number is less tahn one
                // in this case, there may be leading zeros after the decimal place
                // that need to be added

                // offset leading zeros by two to account for leading '0.'
                params.zerosStartIndex = 2;
                params.zerosEndIndex = decimals - digits + 2;
                // params.zerosStartIndex = 4;
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
        return _generateDecimalString(params);
    }

    function _getDateUnits(uint256 _timestamp) internal pure returns (uint256 month, uint256 day, uint256 year) {
        int256 z = int256(_timestamp) / 86400 + 719468;
        int256 era = (z >= 0 ? z : z - 146096) / 146097;
        int256 doe = z - era * 146097;
        int256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
        int256 y = yoe + era * 400;
        int256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
        int256 mp = (5 * doy + 2) / 153;
        int256 d = doy - (153 * mp + 2) / 5 + 1;
        int256 m = mp + (mp < 10 ? int256(3) : -9);

        if (m <= 2) {
            y += 1;
        }

        month = uint256(m);
        day = uint256(d);
        year = uint256(y);
    }

    function _generateDateString(uint256 _timestamp) internal pure returns (string memory) {
        int256 z = int256(_timestamp) / 86400 + 719468;
        int256 era = (z >= 0 ? z : z - 146096) / 146097;
        int256 doe = z - era * 146097;
        int256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
        int256 y = yoe + era * 400;
        int256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
        int256 mp = (5 * doy + 2) / 153;
        int256 d = doy - (153 * mp + 2) / 5 + 1;
        int256 m = mp + (mp < 10 ? int256(3) : -9);

        if (m <= 2) {
            y += 1;
        }

        string memory s = "";

        if (m < 10) {
            s = _toString(0);
        }

        s = string(abi.encodePacked(s, _toString(uint256(m)), bytes1(0x2F)));

        if (d < 10) {
            s = string(abi.encodePacked(s, bytes1(0x30)));
        }

        s = string(abi.encodePacked(s, _toString(uint256(d)), bytes1(0x2F), _toString(uint256(y))));

        return string(s);
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        // This is borrowed from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol#L16

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

    function _escapeQuotes(string memory symbol) internal pure returns (string memory) {
        bytes memory symbolBytes = bytes(symbol);
        uint8 quotesCount = 0;
        for (uint8 i = 0; i < symbolBytes.length; i++) {
            // solhint-disable quotes
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
                // solhint-disable quotes
                if (symbolBytes[i] == '"') {
                    escapedBytes[index++] = "\\";
                }
                escapedBytes[index++] = symbolBytes[i];
            }
            return string(escapedBytes);
        }
        return symbol;
    }

    bytes16 internal constant ALPHABET = "0123456789abcdef";

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function addressToString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), 20);
    }
}

// SPDX-License-Identifier: BUSL 1.1
// Valorem Labs Inc. (c) 2022
pragma solidity 0.8.16;

import "./ITokenURIGenerator.sol";

interface IOptionSettlementEngine {
    /*//////////////////////////////////////////////////////////////
    //  Events
    //////////////////////////////////////////////////////////////*/

    //
    // Write/Redeem events
    //

    // TODO(Do we need exercise and underlying asset here?)
    /**
     * @notice Emitted when a claim is redeemed.
     * @param optionId The token id of the option type of the claim being redeemed.
     * @param claimId The token id of the claim being redeemed.
     * @param redeemer The address redeeming the claim.
     * @param exerciseAmountRedeemed The amount of the option.exerciseAsset redeemed.
     * @param underlyingAmountRedeemed The amount of option.underlyingAsset redeemed.
     */
    event ClaimRedeemed(
        uint256 indexed claimId,
        uint256 indexed optionId,
        address indexed redeemer,
        uint256 exerciseAmountRedeemed,
        uint256 underlyingAmountRedeemed
    );

    /**
     * @notice Emitted when a new option type is created.
     * @param optionId The token id of the new option type created.
     * @param exerciseAsset The ERC20 contract address of the exercise asset.
     * @param underlyingAsset The ERC20 contract address of the underlying asset.
     * @param exerciseAmount The amount, in wei, of the exercise asset required to exercise each contract.
     * @param underlyingAmount The amount, in wei of the underlying asset in each contract.
     * @param exerciseTimestamp The timestamp after which this option type can be exercised.
     * @param expiryTimestamp The timestamp before which this option type can be exercised.
     */
    event NewOptionType(
        uint256 optionId,
        address indexed exerciseAsset,
        address indexed underlyingAsset,
        uint96 exerciseAmount,
        uint96 underlyingAmount,
        uint40 exerciseTimestamp,
        uint40 indexed expiryTimestamp
    );

    //
    // Exercise events
    //

    /**
     * @notice Emitted when option contract(s) is(are) exercised.
     * @param optionId The token id of the option type exercised.
     * @param exerciser The address that exercised the option contract(s).
     * @param amount The amount of option contracts exercised.
     */
    event OptionsExercised(uint256 indexed optionId, address indexed exerciser, uint112 amount);

    /**
     * @notice Emitted when new options contracts are written.
     * @param optionId The token id of the option type written.
     * @param writer The address of the writer.
     * @param claimId The claim token id of the new or existing short position written against.
     * @param amount The amount of options contracts written.
     */
    event OptionsWritten(uint256 indexed optionId, address indexed writer, uint256 indexed claimId, uint112 amount);

    //
    // Fee events
    //

    /**
     * @notice Emitted when protocol fees are accrued for a given asset.
     * @dev Emitted on write() when fees are accrued on the underlying asset,
     * or exercise() when fees are accrued on the exercise asset.
     * Will not be emitted when feesEnabled is false.
     * @param optionId The token id of the option type being written or exercised.
     * @param asset The ERC20 asset in which fees were accrued.
     * @param payer The address paying the fee.
     * @param amount The amount, in wei, of fees accrued.
     */
    event FeeAccrued(uint256 indexed optionId, address indexed asset, address indexed payer, uint256 amount);

    /**
     * @notice Emitted when accrued protocol fees for a given ERC20 asset are swept to the
     * feeTo address.
     * @param asset The ERC20 asset of the protocol fees swept.
     * @param feeTo The account to which fees were swept.
     * @param amount The total amount swept.
     */
    event FeeSwept(address indexed asset, address indexed feeTo, uint256 amount);

    /**
     * @notice Emitted when protocol fees are enabled or disabled.
     * @param feeTo The address which enabled or disabled fees.
     * @param enabled Whether fees are enabled or disabled.
     */
    event FeeSwitchUpdated(address feeTo, bool enabled);

    // Access control events

    /**
     * @notice Emitted when feeTo address is updated.
     * @param newFeeTo The new feeTo address.
     */
    event FeeToUpdated(address indexed newFeeTo);

    /**
     * @notice Emitted when TokenURIGenerator is updated.
     * @param newTokenURIGenerator The new TokenURIGenerator address.
     */
    event TokenURIGeneratorUpdated(address indexed newTokenURIGenerator);

    /*//////////////////////////////////////////////////////////////
    //  Errors
    //////////////////////////////////////////////////////////////*/

    //
    // Access control errors
    //

    /**
     * @notice The caller doesn't have permission to access that function.
     * @param accessor The requesting address.
     * @param permissioned The address which has the requisite permissions.
     */
    error AccessControlViolation(address accessor, address permissioned);

    // Input Errors

    /// @notice The amount of options contracts written must be greater than zero.
    error AmountWrittenCannotBeZero();

    /**
     * @notice This claim is not owned by the caller.
     * @param claimId Supplied claim ID.
     */
    error CallerDoesNotOwnClaimId(uint256 claimId);

    /**
     * @notice The caller does not have enough options contracts to exercise the amount
     * specified.
     * @param optionId The supplied option id.
     * @param amount The amount of options contracts which the caller attempted to exercise.
     */
    error CallerHoldsInsufficientOptions(uint256 optionId, uint112 amount);

    /**
     * @notice Claims cannot be redeemed before expiry.
     * @param claimId Supplied claim ID.
     * @param expiry timestamp at which the option type expires.
     */
    error ClaimTooSoon(uint256 claimId, uint40 expiry);

    /**
     * @notice This option cannot yet be exercised.
     * @param optionId Supplied option ID.
     * @param exercise The time after which the option optionId be exercised.
     */
    error ExerciseTooEarly(uint256 optionId, uint40 exercise);

    /**
     * @notice The option exercise window is too short.
     * @param exercise The timestamp supplied for exercise.
     */
    error ExerciseWindowTooShort(uint40 exercise);

    /**
     * @notice The optionId specified expired has already expired.
     * @param optionId The id of the expired option.
     * @param expiry The expiry time for the supplied option Id.
     */
    error ExpiredOption(uint256 optionId, uint40 expiry);

    /**
     * @notice The expiry timestamp is too soon.
     * @param expiry Timestamp of expiry.
     */
    error ExpiryWindowTooShort(uint40 expiry);

    /**
     * @notice Invalid (zero) address.
     * @param input The address input.
     */
    error InvalidAddress(address input);

    /**
     * @notice The assets specified are invalid or duplicate.
     * @param asset1 Supplied ERC20 asset.
     * @param asset2 Supplied ERC20 asset.
     */
    error InvalidAssets(address asset1, address asset2);

    /**
     * @notice The token specified is not a claim token.
     * @param token The supplied token id.
     */
    error InvalidClaim(uint256 token);

    /**
     * @notice The token specified is not an option token.
     * @param token The supplied token id.
     */
    error InvalidOption(uint256 token);

    /**
     * @notice This option contract type already exists and thus cannot be created.
     * @param optionId The token id of the option type which already exists.
     */
    error OptionsTypeExists(uint256 optionId);

    /**
     * @notice The requested token is not found.
     * @param token The token requested.
     */
    error TokenNotFound(uint256 token);

    /*//////////////////////////////////////////////////////////////
    //  Data structures
    //////////////////////////////////////////////////////////////*/

    /// @dev This enumeration is used to determine the type of an ERC1155 subtoken in the engine.
    enum TokenType {
        None,
        Option,
        Claim
    }

    /// @notice Data comprising the unique tuple of an option type associated with an ERC-1155 option token.
    struct Option {
        /// @custom:member underlyingAsset The underlying ERC20 asset which the option is collateralized with.
        address underlyingAsset;
        /// @custom:member underlyingAmount The amount of the underlying asset contained within an option contract of this type.
        uint96 underlyingAmount;
        /// @custom:member exerciseAsset The ERC20 asset which the option can be exercised using.
        address exerciseAsset;
        /// @custom:member exerciseAmount The amount of the exercise asset required to exercise each option contract of this type.
        uint96 exerciseAmount;
        /// @custom:member exerciseTimestamp The timestamp after which this option can be exercised.
        uint40 exerciseTimestamp;
        /// @custom:member expiryTimestamp The timestamp before which this option can be exercised.
        uint40 expiryTimestamp;
        /// @custom:member settlementSeed Deterministic seed used for option fair exercise assignment.
        uint160 settlementSeed;
        /// @custom:member nextClaimKey The next claim key available for this option type.
        uint96 nextClaimKey;
    }

    /// @notice The claim bucket information for a given option type.
    struct BucketInfo {
        /// @custom:member An array of buckets for a given option type.
        Bucket[] buckets;
        /// @custom:member An array of bucket indices with collateral available for exercise.
        uint16[] bucketsWithCollateral;
        /// @custom:member A mapping of bucket indices to a boolean indicating if the bucket has any collateral available for exercise.
        mapping(uint16 => bool) bucketHasCollateral;
    }

    /// @notice A storage container for the engine state of a given option type.
    struct OptionTypeState {
        /// @custom:member State for this option type.
        Option option;
        /// @custom:member State for assignment buckets on this option type.
        BucketInfo bucketInfo;
        /// @custom:member A mapping to an array of bucket indices per claim token for this option type.
        mapping(uint96 => ClaimIndex[]) claimIndices;
    }

    /**
     * @notice This struct contains the data about a claim to a short position written on an option type.
     * When writing an amount of options of a particular type, the writer will be issued an ERC 1155 NFT
     * that represents a claim to the underlying and exercise assets, to be claimed after
     * expiry of the option. The amount of each (underlying asset and exercise asset) paid to the claimant upon
     * redeeming their claim NFT depends on the option type, the amount of options written, represented in this struct,
     * and what portion of this claim was assigned exercise, if any, before expiry.
     */
    struct Claim {
        /// @custom:member amountWritten The number of option contracts written against this claim.
        uint256 amountWritten;
        /// @custom:member amountExercised The amount of option contracts exercised against this claim.
        uint256 amountExercised;
        /// @custom:member optionId The option ID of the option type this claim is for.
        uint256 optionId;
        /// @custom:member unredeemed Whether or not this claim has been redeemed.
        bool unredeemed;
    }

    /**
     * @notice Claims can be used to write multiple times. This struct is used to keep track
     * of how many options are written against a claim in each period, in order to
     * correctly perform fair exercise assignment.
     */
    struct ClaimIndex {
        /// @custom:member amountWritten The amount of option contracts written into claim for given period/bucket.
        uint112 amountWritten;
        /// @custom:member bucketIndex The index of the Bucket into which the options collateral was deposited.
        uint16 bucketIndex;
    }

    /**
     * @notice Represents the total amount of options written and exercised for a group of
     * claims bucketed by period. Used in fair assignment to calculate the ratio of
     * underlying to exercise assets to be transferred to claimants.
     */
    struct Bucket {
        /// @custom:member amountWritten The number of option contracts written into this bucket.
        uint112 amountWritten;
        /// @custom:member amountExercised The number of option contracts exercised from this bucket.
        uint112 amountExercised;
        /// @custom:member daysAfterEpoch Which period this bucket falls on, in offset from epoch.
        uint16 daysAfterEpoch;
    }

    /**
     * @notice Data about the ERC20 assets and liabilities for a given option (long) or claim (short) token,
     * in terms of the underlying and exercise ERC20 tokens.
     */
    struct Underlying {
        /// @custom:member underlyingAsset The address of the ERC20 underlying asset.
        address underlyingAsset;
        /// @custom:member underlyingPosition The amount, in wei, of the underlying asset represented by this position.
        int256 underlyingPosition;
        /// @custom:member exerciseAsset The address of the ERC20 exercise asset.
        address exerciseAsset;
        /// @custom:member exercisePosition The amount, in wei, of the exercise asset represented by this position.
        int256 exercisePosition;
    }

    /*//////////////////////////////////////////////////////////////
    //  Accessors
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets information for a given claim token id.
     * @param claimId The id of the claim
     * @return claimInfo The Claim struct for claimId if the tokenId is Type.Claim.
     */
    function claim(uint256 claimId) external view returns (Claim memory claimInfo);

    /**
     * @notice Gets option type information for a given tokenId.
     * @param tokenId The token id for which to get option inf.
     * @return optionInfo The Option struct for tokenId if the optionKey for tokenId is initialized.
     */
    function option(uint256 tokenId) external view returns (Option memory optionInfo);

    /**
     * @notice Gets the TokenType for a given tokenId.
     * @dev Option and claim token ids are encoded as follows:
     *
     *   MSb
     *   0000 0000   0000 0000   0000 0000   0000 0000 ┐
     *   0000 0000   0000 0000   0000 0000   0000 0000 │
     *   0000 0000   0000 0000   0000 0000   0000 0000 │ 160b option key, created Option struct hash.
     *   0000 0000   0000 0000   0000 0000   0000 0000 │
     *   0000 0000   0000 0000   0000 0000   0000 0000 │
     *   0000 0000   0000 0000   0000 0000   0000 0000 ┘
     *   0000 0000   0000 0000   0000 0000   0000 0000 ┐
     *   0000 0000   0000 0000   0000 0000   0000 0000 │ 96b auto-incrementing claim key.
     *   0000 0000   0000 0000   0000 0000   0000 0000 ┘
     *                                             LSb
     * This function accounts for that, and whether or not tokenId has been initialized/decommissioned yet.
     * @param tokenId The token id to get the TokenType of.
     * @return typeOfToken The enum TokenType of the tokenId.
     */
    function tokenType(uint256 tokenId) external view returns (TokenType typeOfToken);

    /**
     * @return uriGenerator the address of the URI generator contract.
     */
    function tokenURIGenerator() external view returns (ITokenURIGenerator uriGenerator);

    /**
     * @notice Gets information about the ERC20 token positions represented by a tokenId.
     * @param tokenId The token id for which to retrieve the Underlying position.
     * @return position The Underlying struct for the supplied tokenId.
     */
    function underlying(uint256 tokenId) external view returns (Underlying memory position);

    //
    // Fee Information
    //

    /**
     * @notice Gets the balance of protocol fees for a given token which have not been swept yet.
     * @param token The token for the un-swept fee balance.
     * @return The balance of un-swept fees.
     */
    function feeBalance(address token) external view returns (uint256);

    /**
     * @return fee The protocol fee, expressed in basis points.
     */
    function feeBps() external view returns (uint8 fee);

    /**
     * @notice Checks if protocol fees are enabled.
     * @return enabled Whether or not protocol fees are enabled.
     */
    function feesEnabled() external view returns (bool enabled);

    /**
     * @notice Returns the address which protocol fees are swept to.
     * @return The address which fees are swept to.
     */
    function feeTo() external view returns (address);

    /*//////////////////////////////////////////////////////////////
    //  Write Options/Claims
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates a new option contract type if it doesn't already exist.
     * @dev optionId can be precomputed using
     *  uint160 optionKey = uint160(
     *      bytes20(
     *          keccak256(
     *              abi.encode(
     *                  underlyingAsset,
     *                  underlyingAmount,
     *                  exerciseAsset,
     *                  exerciseAmount,
     *                  exerciseTimestamp,
     *                  expiryTimestamp,
     *                  uint160(0),
     *                  uint96(0)
     *              )
     *          )
     *      )
     *  );
     *  optionId = uint256(optionKey) << OPTION_ID_PADDING;
     * and then tokenType(optionId) == TokenType.Option if the option already exists.
     * @param underlyingAsset The contract address of the ERC20 underlying asset.
     * @param underlyingAmount The amount of underlyingAsset, in wei, collateralizing each option contract.
     * @param exerciseAsset The contract address of the ERC20 exercise asset.
     * @param exerciseAmount The amount of exerciseAsset, in wei, required to exercise each option contract.
     * @param exerciseTimestamp The timestamp after which this option can be exercised.
     * @param expiryTimestamp The timestamp before which this option can be exercised.
     * @return optionId The token id for the new option type created by this call.
     */
    function newOptionType(
        address underlyingAsset,
        uint96 underlyingAmount,
        address exerciseAsset,
        uint96 exerciseAmount,
        uint40 exerciseTimestamp,
        uint40 expiryTimestamp
    ) external returns (uint256 optionId);

    /**
     * @notice Writes a specified amount of the specified option, returning claim NFT id.
     * @param tokenId The desired token id to write against, input an optionId to get a new claim, or a claimId
     * to add to an existing claim.
     * @param amount The desired number of option contracts to write.
     * @return claimId The token id of the claim NFT which was input or created.
     */
    function write(uint256 tokenId, uint112 amount) external returns (uint256 claimId);

    /*//////////////////////////////////////////////////////////////
    //  Redeem Claims
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Redeems a claim NFT, transfers the underlying/exercise tokens to the caller.
     * Can be called after option expiry timestamp (inclusive).
     * @param claimId The ID of the claim to redeem.
     */
    function redeem(uint256 claimId) external;

    /*//////////////////////////////////////////////////////////////
    //  Exercise Options
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Exercises specified amount of optionId, transferring in the exercise asset,
     * and transferring out the underlying asset if requirements are met. Can be called
     * from exercise timestamp (inclusive), until option expiry timestamp (exclusive).
     * @param optionId The option token id of the option type to exercise.
     * @param amount The amount of option contracts to exercise.
     */
    function exercise(uint256 optionId, uint112 amount) external;

    /*//////////////////////////////////////////////////////////////
    //  Privileged Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Enables or disables protocol fees.
     * @param enabled Whether or not protocol fees should be enabled.
     */
    function setFeesEnabled(bool enabled) external;

    /**
     * @notice Updates the address fees are swept to.
     * @param newFeeTo The new address which fees are swept to.
     */
    function setFeeTo(address newFeeTo) external;

    /**
     * @notice Updates the contract address for generating token URIs for tokens.
     * @param newTokenURIGenerator The address of the new ITokenURIGenerator contract.
     */
    function setTokenURIGenerator(address newTokenURIGenerator) external;

    /**
     * @notice Sweeps fees to the feeTo address if there is more than 1 wei for
     * feeBalance for a given token.
     * @param tokens An array of tokens to sweep fees for.
     */
    function sweepFees(address[] memory tokens) external;
}

// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.16;

import "./IOptionSettlementEngine.sol";

interface ITokenURIGenerator {
    struct TokenURIParams {
        /// @param underlyingAsset The underlying asset to be received
        address underlyingAsset;
        /// @param underlyingSymbol The symbol of the underlying asset
        string underlyingSymbol;
        /// @param exerciseAsset The address of the asset needed for exercise
        address exerciseAsset;
        /// @param exerciseSymbol The symbol of the underlying asset
        string exerciseSymbol;
        /// @param exerciseTimestamp The timestamp after which this option may be exercised
        uint40 exerciseTimestamp;
        /// @param expiryTimestamp The timestamp before which this option must be exercised
        uint40 expiryTimestamp;
        /// @param underlyingAmount The amount of the underlying asset contained within an option contract of this type
        uint96 underlyingAmount;
        /// @param exerciseAmount The amount of the exercise asset required to exercise this option
        uint96 exerciseAmount;
        /// @param tokenType Option or Claim
        IOptionSettlementEngine.TokenType tokenType;
    }

    /**
     * @notice Constructs a URI for a claim NFT, encoding an SVG based on parameters of the claims lot.
     * @param params Parameters for the token URI.
     * @return A string with the SVG encoded in Base64.
     */
    function constructTokenURI(TokenURIParams memory params) external view returns (string memory);

    /**
     * @notice Generates a name for the NFT based on the supplied params.
     * @param params Parameters for the token URI.
     * @return A generated name for the NFT.
     */
    function generateName(TokenURIParams memory params) external pure returns (string memory);

    /**
     * @notice Generates a description for the NFT based on the supplied params.
     * @param params Parameters for the token URI.
     * @return A generated description for the NFT.
     */
    function generateDescription(TokenURIParams memory params) external pure returns (string memory);

    /**
     * @notice Generates a svg for the NFT based on the supplied params.
     * @param params Parameters for the token URI.
     * @return A generated svg for the NFT.
     */
    function generateNFT(TokenURIParams memory params) external view returns (string memory);
}