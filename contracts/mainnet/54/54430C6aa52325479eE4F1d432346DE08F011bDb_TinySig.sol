// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {IPuzzle} from "../interfaces/IPuzzle.sol";

/// @title TinySig
/// @author Riley Holterhus
contract TinySig is IPuzzle {

    // This is the address you get by using the private key 0x1.
    // For this challenge, make sure you do not use *your own* private key
    // (other than to initiate the `solve` transaction of course). You only
    // need to use the private key 0x1 for signing things.
    address constant SIGNER = 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf;

    /// @inheritdoc IPuzzle
    function name() external pure returns (string memory) {
        return "TinySig";
    }

    /// @inheritdoc IPuzzle
    function generate(address _seed) external view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_seed)));
    }

    /// @inheritdoc IPuzzle
    function verify(uint256 _start, uint256 _solution) external returns (bool) {
        address target = address(new Deployer(abi.encodePacked(_solution)));
        (, bytes memory ret) = target.staticcall("");
        (bytes32 h, uint8 v, bytes32 r) = abi.decode(ret, (bytes32, uint8, bytes32));
        return (
            r < bytes32(uint256(1 << 184)) &&
            ecrecover(h, v, r, bytes32(_start)) == SIGNER
        );
    }
}

contract Deployer {
    constructor(bytes memory code) { assembly { return (add(code, 0x20), mload(code)) } }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title The interface for a puzzle on Curta
/// @notice The goal of players is to view the source code of the puzzle (may
/// range from just the bytecode to Solidity—whatever the author wishes to
/// provide), interpret the code, solve it as if it was a regular puzzle, then
/// verify the solution on-chain.
/// @dev Since puzzles are on-chain, everyone can view everyone else's
/// submissions. The generative aspect prevents front-running and allows for
/// multiple winners: even if players view someone else's solution, they still
/// have to figure out what the rules/constraints of the puzzle are and apply
/// the solution to their respective starting position.
interface IPuzzle {
    /// @notice Returns the puzzle's name.
    /// @return The puzzle's name.
    function name() external pure returns (string memory);

    /// @notice Generates the puzzle's starting position based on a seed.
    /// @dev The seed is intended to be `msg.sender` of some wrapper function or
    /// call.
    /// @param _seed The seed to use to generate the puzzle.
    /// @return The puzzle's starting position.
    function generate(address _seed) external returns (uint256);

    /// @notice Verifies that a solution is valid for the puzzle.
    /// @dev `_start` is intended to be an output from {IPuzzle-generate}.
    /// @param _start The puzzle's starting position.
    /// @param _solution The solution to the puzzle.
    /// @return Whether the solution is valid.
    function verify(uint256 _start, uint256 _solution) external returns (bool);
}