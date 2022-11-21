// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.17;

import "./Firn.sol";

contract FirnReader {
    Firn immutable _firn;

    constructor(address firn_) {
        _firn = Firn(firn_); // actually pass the address of the proxy
    }

    function sampleAnonset(bytes32 seed, uint32 amount) external view returns (bytes32[N] memory result) {
        uint256 successes = 0;
        uint256 attempts = 0;
        while (successes < N) {
            attempts++;
            if (attempts > 50) {
                amount >>= 1;
                attempts = 0;
            }
            seed = keccak256(abi.encode(seed));
            uint256 entropy = uint256(seed);
            uint256 layer = (entropy & 0xFFFFFFFF) % _firn.blackHeight();
            entropy >>= 32;
            uint64 cursor = _firn.root();
            bool red = false; // avoid a "shadowing" warning
            for (uint256 i = 0; i < layer; i++) {
                // inv: at the beginning of the loop, it points to the index-ith black node in the rightmost path.
                (, , cursor, ) = _firn.nodes(cursor); // _firn.nodes[cursor].right
                (, , , red) = _firn.nodes(cursor); // if (_firn.nodes[cursor].red)
                if (red) (, , cursor, ) = _firn.nodes(cursor);
            }
            uint256 subLayer; // (weighted) random element of {0, ..., blackHeight - 1 - layer}, low more likely.
            while (true) {
                bool found = false;
                for (uint256 i = 0; i < _firn.blackHeight() - layer; i++) {
                    if (entropy & 0x01 == 0x01) {
                        subLayer = i;
                        found = true;
                        break;
                    }
                    entropy >>= 1;
                }
                if (found) break;
            }
            entropy >>= 1; // always a 1 here. get rid of it.
            for (uint256 i = 0; i < _firn.blackHeight() - 1 - layer - subLayer; i++) {
                // at beginning of loop, points to the layer + ith black node down _random_ path...
                if (entropy & 0x01 == 0x01) (, , cursor, ) = _firn.nodes(cursor); // cursor = _firn.nodes[cursor].right
                else (, cursor, , ) = _firn.nodes(cursor); // cursor = _firn.nodes[cursor].left
                entropy >>= 1;
                (, , , red) = _firn.nodes(cursor); // if (_firn.nodes[cursor].red)
                if (red) {
                    if (entropy & 0x01 == 0x01) (, , cursor, ) = _firn.nodes(cursor);
                    else (, cursor, , ) = _firn.nodes(cursor);
                    entropy >>= 1;
                }
            }
            (, , uint64 right, ) = _firn.nodes(cursor);
            (, , , red) = _firn.nodes(right);
            if (entropy & 0x01 == 0x01 && red) {
                (, , cursor, ) = _firn.nodes(cursor);
            }
            else if (entropy & 0x02 == 0x02) {
                (, uint64 left, , ) = _firn.nodes(cursor);
                (, , , red) = _firn.nodes(left);
                if (red) (, cursor, , ) = _firn.nodes(cursor);
            }
            entropy >>= 2;
            uint256 length = _firn.lengths(cursor);
            bytes32 account = _firn.lists(cursor, entropy % length);
            (, uint64 candidate, ) = _firn.info(account); // what is the total amount this person has deposited?
            if (candidate < amount) continue; // skip them for now
            bool duplicate = false;
            for (uint256 i = 0; i < successes; i++) {
                if (result[i] == account) {
                    duplicate = true;
                    break;
                }
            }
            if (duplicate) continue;
            attempts = 0;
            result[successes++] = account;
        }
    }
}