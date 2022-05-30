/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;



// Part: MCR

library MCR {
    function compute(uint256 length, uint256[] storage policy, uint256[] storage leverage, uint256[] storage corr) internal returns (uint256 square) {
        square = 0;
        if (length == 0) {
            return square;
        }
        require(length == policy.length, "!policy.length");
        require(length == leverage.length, "!leverage.length");
        require(length * (length - 1) / 2 == corr.length, "!corr.length");

        uint256[] memory leverPolicy = new uint256[](length);
        for (uint256 id = 0; id < length; ++id) {
            leverPolicy[id] = policy[id] * leverage[id] / 1000000;
            square += leverPolicy[id] * leverPolicy[id];
        }

        uint256 id3 = 0;
        for (uint256 id1 = 0; id1 < length - 1; ++id1) {
            for (uint256 id2 = id1 + 1 ; id2 < length; ++id2) {
                square += corr[id3++] * leverPolicy[id1] * leverPolicy[id2]  / 500000;
            }
        }
    }
}

// Part: Math

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// File: Test.sol

contract Test {
    uint256[] public policy;
    uint256[] public leverage;
    uint256[] public corr;
    uint256 public square;
    uint256 public mcr;

    /*
    constructor(uint256 length)  public {
        policy = new uint256[](length);
        leverage = new uint256[](length);
        corr = new uint256[](length * (length - 1) / 2);

    }
    */

    function addPolicy(uint256[] memory _policy) external {
        policy = new uint256[](_policy.length);
        for (uint256 id = 0; id < _policy.length; ++id) {
            policy[id] = _policy[id];
        }
    }

    function addLeverage(uint256[] memory _leverage) external {
        leverage = new uint256[](_leverage.length);
        for (uint256 id = 0; id < _leverage.length; ++id) {
            leverage[id] = _leverage[id];
        }
    }

    function addCorr(uint256[] memory _corr) external {
        corr = new uint256[](_corr.length);
        for (uint256 id = 0; id < _corr.length; ++id) {
            corr[id] = _corr[id];
        }
    }

    function policyLength() public view returns (uint256) {
        return policy.length;
    }

    function leverageLength() public view returns (uint256) {
        return leverage.length;
    }

    function corrLength() public view returns (uint256) {
        return corr.length;
    }

    function computeMCRSquare(uint256 length) public {
        square = MCR.compute(length, policy, leverage, corr);
    }

    function computeMCR(uint256 length) external {
        computeMCRSquare(length);
        mcr = Math.sqrt(square);
    }

}