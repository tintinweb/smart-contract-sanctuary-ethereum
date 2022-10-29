// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IChallenge {
    /// Execute a given solution, using the seed to generate inputs. The actual
    /// implementation is specific to the challenge.
    /// @return The amount of gas consumed by the solution.
    function run(address target, uint256 seed) external view returns (uint32);

    /// @return An SVG snippet, which is embedded in the main NFT.
    function svg(uint256 tokenId) external view returns (string memory);

    /// @return The name of the challenge.
    function name() external view returns (string memory);

    /// @return The description of the challenge.
    /// @notice Should not have line breaks.
    function description() external view returns (string memory);
}

// SPADIX-License-Identifier: MIT
pragma solidity ^0.8.17;

type Fixed18 is uint256;

uint256 constant FIXED18BASE = 10 ** 18;

function add(Fixed18 a, Fixed18 b) pure returns (Fixed18) {
    return Fixed18.wrap(Fixed18.unwrap(a) + Fixed18.unwrap(b));
}

function sub(Fixed18 a, Fixed18 b) pure returns (Fixed18) {
    return Fixed18.wrap(Fixed18.unwrap(a) - Fixed18.unwrap(b));
}

function mul(Fixed18 a, Fixed18 b) pure returns (Fixed18) {
    return Fixed18.wrap((Fixed18.unwrap(a) * Fixed18.unwrap(b)) / FIXED18BASE);
}

function div(Fixed18 a, Fixed18 b) pure returns (Fixed18) {
    return Fixed18.wrap((Fixed18.unwrap(a) * FIXED18BASE) / Fixed18.unwrap(b));
}

function distance(Fixed18 a, Fixed18 b) pure returns (Fixed18) {
    uint256 _a = Fixed18.unwrap(a);
    uint256 _b = Fixed18.unwrap(b);
    unchecked {
        if (_a < _b) {
            return Fixed18.wrap(_b - _a);
        } else {
            return Fixed18.wrap(_a - _b);
        }
    }
}

function lt(Fixed18 a, Fixed18 b) pure returns (bool) {
    return Fixed18.unwrap(a) < Fixed18.unwrap(b);
}

function le(Fixed18 a, Fixed18 b) pure returns (bool) {
    return Fixed18.unwrap(a) <= Fixed18.unwrap(b);
}

function gt(Fixed18 a, Fixed18 b) pure returns (bool) {
    return Fixed18.unwrap(a) > Fixed18.unwrap(b);
}

function bit_and(Fixed18 a, Fixed18 b) pure returns (Fixed18) {
    return Fixed18.wrap(Fixed18.unwrap(a) & Fixed18.unwrap(b));
}

function bit_xor(Fixed18 a, Fixed18 b) pure returns (Fixed18) {
    return Fixed18.wrap(Fixed18.unwrap(a) ^ Fixed18.unwrap(b));
}

using {add, sub, mul, div, distance, lt, le, gt, bit_and, bit_xor} for Fixed18 global;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IChallenge} from "../IChallenge.sol";

import {Fixed18} from "./Fixed18.sol";

uint256 constant INPUT_SIZE = 5;

// Expecting 5 decimal places of precision.
Fixed18 constant EPSILON = Fixed18.wrap(0.0001 * 10 ** 18);

interface ISqrt {
    function sqrt(Fixed18[INPUT_SIZE] calldata) external view returns (Fixed18[INPUT_SIZE] memory);
}

function random_fixed18(uint256 seed) pure returns (Fixed18) {
    return Fixed18.wrap(uint256(random_uint64(seed)));
}

function random_uint64(uint256 seed) pure returns (uint64) {
    return uint64(uint256(keccak256(abi.encodePacked(seed))));
}

contract SqrtChallenge is IChallenge {
    error DoesNotSatisfyTolerance(uint256 input, uint256 output);

    function run(address target, uint256 seed) external view override returns (uint32) {
        // Generate inputs.
        Fixed18[INPUT_SIZE] memory inputs;
        unchecked {
            for (uint256 i = 0; i < INPUT_SIZE; ++i) {
                inputs[i] = random_fixed18(seed);
                seed = Fixed18.unwrap(inputs[i]);
            }
        }

        uint256 preGas = gasleft();
        Fixed18[INPUT_SIZE] memory outputs = ISqrt(target).sqrt(inputs);
        uint256 usedGas;
        unchecked {
            usedGas = preGas - gasleft();
        }

        verify(inputs, outputs);

        return uint32(usedGas);
    }

    // Reverts if invalid
    function verify(Fixed18[INPUT_SIZE] memory inputs, Fixed18[INPUT_SIZE] memory outputs) internal pure {
        unchecked {
            for (uint256 i = 0; i < INPUT_SIZE; ++i) {
                verify(inputs[i], outputs[i]);
            }
        }
    }

    // Reverts if invalid
    function verify(Fixed18 input, Fixed18 output) internal pure {
        // Checks
        //       | output * output - input |
        //       --------------------------  < EPSILON
        //       |        output           |
        if (!output.mul(output).distance(input).div(output).lt(EPSILON)) {
            revert DoesNotSatisfyTolerance(Fixed18.unwrap(input), Fixed18.unwrap(output));
        }
    }

    function name() external pure override returns (string memory) {
        return "SQRT";
    }

    function description() external pure override returns (string memory) {
        return "Calculating the square root of an array of Fixed18 numbers";
    }

    function svg(uint256 tokenId) external pure returns (string memory art) {
        uint32 level = uint32(tokenId);
        if (level == 0) {
            return '<rect width="230" height="230" rx="18px" ry="18px" fill="rgba(0,0,0,0.1)" />';
        }
        if (level == 1) {
            return
            '<rect width="230" height="230" rx="18px" ry="18px" fill="rgba(0,0,0,0.1)" /><polygon points="115,115 144,115 144,144" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon>';
        }
        if (level == 2) {
            return
            '<rect width="230" height="230" rx="18px" ry="18px" fill="rgba(0,0,0,0.1)" /><polygon points="115,115 144,115 144,144" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 144,144 123,164" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon>';
        }
        if (level == 3) {
            return
            '<rect width="230" height="230" rx="18px" ry="18px" fill="rgba(0,0,0,0.1)" /><polygon points="115,115 144,115 144,144" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 144,144 123,164" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 123,164 95,169" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon>';
        }
        if (level == 4) {
            return
            '<rect width="230" height="230" rx="18px" ry="18px" fill="rgba(0,0,0,0.1)" /><polygon points="115,115 144,115 144,144" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 144,144 123,164" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 123,164 95,169" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 95,169 68,159" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon>';
        }
        if (level == 5) {
            return
            '<rect width="230" height="230" rx="18px" ry="18px" fill="rgba(0,0,0,0.1)" /><polygon points="115,115 144,115 144,144" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 144,144 123,164" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 123,164 95,169" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 95,169 68,159" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 68,159 48,138" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon>';
        }
        if (level == 6) {
            return
            '<rect width="230" height="230" rx="18px" ry="18px" fill="rgba(0,0,0,0.1)" /><polygon points="115,115 144,115 144,144" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 144,144 123,164" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 123,164 95,169" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 95,169 68,159" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 68,159 48,138" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 48,138 39,111" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon>';
        }
        if (level == 7) {
            return
            '<rect width="230" height="230" rx="18px" ry="18px" fill="rgba(0,0,0,0.1)" /><polygon points="115,115 144,115 144,144" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 144,144 123,164" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 123,164 95,169" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 95,169 68,159" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 68,159 48,138" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 48,138 39,111" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 39,111 41,82" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon>';
        }
        if (level == 8) {
            return
            '<rect width="230" height="230" rx="18px" ry="18px" fill="rgba(0,0,0,0.1)" /><polygon points="115,115 144,115 144,144" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 144,144 123,164" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 123,164 95,169" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 95,169 68,159" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 68,159 48,138" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 48,138 39,111" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 39,111 41,82" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 41,82 52,56" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon>';
        }
        if (level == 9) {
            return
            '<rect width="230" height="230" rx="18px" ry="18px" fill="rgba(0,0,0,0.1)" /><polygon points="115,115 144,115 144,144" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 144,144 123,164" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 123,164 95,169" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 95,169 68,159" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 68,159 48,138" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 48,138 39,111" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 39,111 41,82" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 41,82 52,56" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 52,56 72,35" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon>';
        }
        if (level == 10) {
            return
            '<rect width="230" height="230" rx="18px" ry="18px" fill="rgba(0,0,0,0.1)" /><polygon points="115,115 144,115 144,144" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 144,144 123,164" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 123,164 95,169" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 95,169 68,159" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 68,159 48,138" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 48,138 39,111" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 39,111 41,82" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 41,82 52,56" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 52,56 72,35" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 72,35 97,21" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon>';
        }
        if (level == 11) {
            return
            '<rect width="230" height="230" rx="18px" ry="18px" fill="rgba(0,0,0,0.1)" /><polygon points="115,115 144,115 144,144" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 144,144 123,164" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 123,164 95,169" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 95,169 68,159" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 68,159 48,138" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 48,138 39,111" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 39,111 41,82" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 41,82 52,56" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 52,56 72,35" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 72,35 97,21" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 97,21 126,16" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon>';
        }
        if (level == 12) {
            return
            '<rect width="230" height="230" rx="18px" ry="18px" fill="rgba(0,0,0,0.1)" /><polygon points="115,115 144,115 144,144" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 144,144 123,164" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 123,164 95,169" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 95,169 68,159" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 68,159 48,138" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 48,138 39,111" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 39,111 41,82" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 41,82 52,56" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 52,56 72,35" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 72,35 97,21" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 97,21 126,16" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 126,16 154,19" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon>';
        } else {
            return
            '<rect width="230" height="230" rx="18px" ry="18px" fill="rgba(0,0,0,0.1)" /><polygon points="115,115 144,115 144,144" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 144,144 123,164" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 123,164 95,169" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 95,169 68,159" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 68,159 48,138" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 48,138 39,111" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 39,111 41,82" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 41,82 52,56" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 52,56 72,35" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 72,35 97,21" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 97,21 126,16" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 126,16 154,19" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon><polygon points="115,115 154,19 181,30" fill="none" stroke="white" stroke-linejoin="round" stroke-width="2"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 115 115" to="360 115 115" dur="10s" repeatCount="indefinite"/></polygon>';
        }
    }
}