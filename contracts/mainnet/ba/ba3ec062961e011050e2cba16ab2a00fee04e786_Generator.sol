// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "src/interfaces/IGenerator.sol";

contract Generator is IGenerator {
    using Strings for uint256;
    string public constant BLUE = "#29335c";
    string public constant RED = "#DB2B39";
    string public constant YELLOW = "#F3A712";

    constructor() payable {}

    function generateSVG(
        uint256 _gameId,
        uint8 _row,
        uint8 _col,
        uint8[COL][ROW] memory _board
    ) external pure returns (string memory svg) {
        string memory board = _generateBoard();
        (string memory base, string memory player1, string memory player2) = _getPalette(_gameId);
        for (uint8 y; y < COL; ++y) {
            board = string.concat(board, _generateGrid(y));
            for (uint8 x; x < ROW; ++x) {
                string memory cell;
                if (_board[x][y] == PLAYER_1) {
                    cell = _generateCell(x, y, _row, _col, player1);
                } else if (_board[x][y] == PLAYER_2) {
                    cell = _generateCell(x, y, _row, _col, player2);
                }
                board = string.concat(board, cell);
            }
            board = string.concat(board, _generateBase(base));
        }
        svg = string.concat(board, "</svg>");
    }

    function getCheckers(
        uint256 _gameId
    ) external pure returns (string memory checker1, string memory checker2) {
        (, string memory player1, string memory player2) = _getPalette(_gameId);
        checker1 = _getColor(player1);
        checker2 = _getColor(player2);
    }

    function getStatus(State _state) external pure returns (string memory status) {
        if (_state == State.INACTIVE) status = "Inactive";
        else if (_state == State.ACTIVE) status = "Active";
        else if (_state == State.SUCCESS) status = "Success";
        else status = "Draw";
    }

    function _generateBoard() internal pure returns (string memory) {
        return
            "<svg viewBox='0 0 700 600' xmlns='http://www.w3.org/2000/svg'><defs><pattern id='cell-pattern' patternUnits='userSpaceOnUse' width='100' height='100'><circle cx='50' cy='50' r='45' fill='black'></circle></pattern><mask id='cell-mask'><rect width='100' height='600' fill='white'></rect><rect width='100' height='600' fill='url(#cell-pattern)'></rect></mask></defs>";
    }

    function _generateGrid(uint256 _col) internal pure returns (string memory) {
        uint256 x = _col * 100;
        string[3] memory grid;
        grid[0] = "<svg x='";
        grid[1] = x.toString();
        grid[2] = "' y='0'>";

        return string(abi.encodePacked(grid[0], grid[1], grid[2]));
    }

    function _generateCell(
        uint256 _x,
        uint256 _y,
        uint8 _row,
        uint8 _col,
        string memory _checker
    ) internal pure returns (string memory cell) {
        uint256 cy = 550 - (_x * 100);
        if (_x == _row && _y == _col) {
            cell = _animateCell(cy, _checker);
        } else {
            cell = _staticCell(cy, _checker);
        }
    }

    function _animateCell(
        uint256 _cy,
        string memory _checker
    ) internal pure returns (string memory) {
        uint256 duration = (_cy / 100 == 0) ? 1 : _cy / 100;
        string memory secs = string.concat(duration.toString(), "s");
        string[7] memory cell;
        cell[0] = "<circle cx='50' r='45' fill='";
        cell[1] = _checker;
        cell[2] = "'><animate attributeName='cy' from='0' to='";
        cell[3] = _cy.toString();
        cell[4] = "' dur='";
        cell[5] = secs;
        cell[6] = "' begin='2s' fill='freeze'></animate></circle>";

        return string(abi.encodePacked(cell[0], cell[1], cell[2], cell[3], cell[4], cell[5], cell[6]));
    }

    function _staticCell(
        uint256 _cy,
        string memory _checker
    ) internal pure returns (string memory) {
        string[5] memory cell;
        cell[0] = "<circle cx='50' cy='";
        cell[1] = _cy.toString();
        cell[2] = "' r='45' fill='";
        cell[3] = _checker;
        cell[4] = "'></circle>";

        return string(abi.encodePacked(cell[0], cell[1], cell[2], cell[3], cell[4]));
    }

    function _generateBase(string memory _base) internal pure returns (string memory) {
        string[3] memory base;
        base[0] = "<rect width='100' height='600' fill='";
        base[1] = _base;
        base[2] = "' mask='url(#cell-mask)'></rect></svg>";

        return string(abi.encodePacked(base[0], base[1], base[2]));
    }

    function _getPalette(
        uint256 _gameId
    ) internal pure returns (string memory base, string memory player1, string memory player2) {
        if (_gameId % 3 == 0) {
            base = RED;
            if (_gameId % 2 == 0) {
                player1 = BLUE;
                player2 = YELLOW;
            } else {
                player1 = YELLOW;
                player2 = BLUE;
            }
        } else if (_gameId % 3 == 1) {
            base = YELLOW;
            if (_gameId % 2 == 0) {
                player1 = RED;
                player2 = BLUE;
            } else {
                player1 = BLUE;
                player2 = RED;
            }
        } else if (_gameId % 3 == 2) {
            base = BLUE;
            if (_gameId % 2 == 0) {
                player1 = RED;
                player2 = YELLOW;
            } else {
                player1 = YELLOW;
                player2 = RED;
            }
        }
    }

    function _getColor(string memory _player) internal pure returns (string memory checker) {
        if (_hashStr(_player) == _hashStr(BLUE)) checker = "Blue";
        else if (_hashStr(_player) == _hashStr(RED)) checker = "Red";
        else checker = "Yellow";
    }

    function _hashStr(string memory _value) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_value));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

uint8 constant COL = 7;
uint8 constant ROW = 6;
uint8 constant PLAYER_1 = 1;
uint8 constant PLAYER_2 = 2;

enum State {
    INACTIVE,
    ACTIVE,
    SUCCESS,
    DRAW
}

struct Game {
    State state;
    uint8 row;
    uint8 col;
    uint8 moves;
    uint8 turn;
    address player1;
    address player2;
    uint8[COL][ROW] board;
}

interface IConnectors {
    error InsufficientSupply();
    error InvalidGame();
    error InvalidMatchup();
    error InvalidMove();
    error InvalidPayment();
    error InvalidState();
    error NotAuthorized();
    error TransferFailed();

    event Challenge(uint256 indexed _gameId, address indexed _player1, address indexed _player2);

    event Begin(uint256 indexed _gameId, address indexed _player2, State indexed _state);

    event Move(
        uint256 indexed _gameId,
        address indexed _player,
        uint8 _moves,
        uint8 _row,
        uint8 _col
    );

    event Result(
        uint256 indexed _gameId,
        address indexed _winner,
        State indexed _state,
        uint8[COL][ROW] _board
    );

    function MAX_SUPPLY() external view returns (uint16);

    function challenge(address _opponent) external payable;

    function begin(uint256 _gameId, uint8 _col) external payable;

    function fee() external view returns (uint64);

    function generator() external view returns (address);

    function getColumn(uint256 _gameId, uint8 _row) external view returns (uint8[COL] memory);

    function getNextRow(uint8[COL][ROW] memory _board, uint8 _col) external view returns (uint8);

    function move(uint256 _gameId, uint8 _col) external returns (bool);

    function setFee(uint64 _fee) external payable;

    function totalSupply() external view returns (uint16);

    function withdraw(address payable _to) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {COL, ROW, PLAYER_1, PLAYER_2, State} from "src/interfaces/IConnectors.sol";

interface IGenerator {
    function BLUE() external view returns (string memory);

    function RED() external view returns (string memory);

    function YELLOW() external view returns (string memory);

    function generateSVG(
        uint256 _gameId,
        uint8 _row,
        uint8 _col,
        uint8[COL][ROW] memory _board
    ) external pure returns (string memory);

    function getCheckers(uint256 _gameId) external pure returns (string memory, string memory);

    function getStatus(State _state) external view returns (string memory);
}