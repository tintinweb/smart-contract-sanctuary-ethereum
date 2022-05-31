/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;



// Part: Math

library Math {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
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

//import "./libraries/MCR.sol";

contract Test {
    uint256[] public policy;
    uint256[] public leverage;
    uint256[] public corr;
    uint256 public square;
    uint256 public mcr;
    uint256 public beforeGas;
    uint256 public afterGas;
    uint256 public computeGas;

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

    function computeMCRSquare(uint256 length) public  {
        square = compute(length);
    }

    function computeMCR(uint256 length) external  {
        uint256 _before = gasleft();
        uint256 _square = compute(length);
        uint256 _mcr =  Math.sqrt(_square);
        uint256 _after = gasleft();
        square = _square;
        mcr = _mcr;
        beforeGas = _before;
        afterGas = _after;
        computeGas = _before - _after;
    }

    function compute(uint256 length) internal returns (uint256) {
        uint256 square = 0;
        if (length == 0) {
            return square;
        }
        require(length == policy.length, "!policy.length");
        require(length == leverage.length, "!leverage.length");
        require(length * (length - 1) / 2 == corr.length, "!corr.length");

        uint256[] memory leverPolicy = new uint256[](length);
        for (uint256 id = 0; id < length; ++id) {
            leverPolicy[id] = policy[id] * leverage[id];
            square += leverPolicy[id] * leverPolicy[id] * 1000000;
        }

        uint256 corrID = 0;
        for (uint256 id1 = 0; id1 < length - 1; ++id1) {
            for (uint256 id2 = id1 + 1 ; id2 < length; ++id2) {
                square += corr[corrID++] * 2 * leverPolicy[id1] * leverPolicy[id2];
            }
        }

        square /= 1000000000000000000;
        return square;
    }

}