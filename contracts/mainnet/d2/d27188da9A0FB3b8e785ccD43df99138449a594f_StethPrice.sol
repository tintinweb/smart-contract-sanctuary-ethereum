/**
 *Submitted for verification at Etherscan.io on 2022-03-07
*/

// SPDX-License-Identifier: GPL-3.0-or-later

/// StethPrice.sol

// Copyright (C) 2021 Dai Foundation

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.11;

interface OracleLike {
    function peek() external view returns (uint256, bool);
    function read() external view returns (uint256);
}

interface StethLike {
    function getPooledEthByShares(uint256) external view returns (uint256);
}

// Implements a Median interface but is a pass-through to the wstETH Median.
contract StethPrice {
    uint256 constant WAD = 10**18;

    StethLike immutable STETH;
    OracleLike immutable WSTETH_ORACLE;

    mapping(address => uint256) public wards;
    function rely(address usr) external auth {wards[usr] = 1; emit Rely(usr);}
    function deny(address usr) external auth {wards[usr] = 0; emit Deny(usr);}
    modifier auth {
      require(wards[msg.sender] == 1, "StethPrice/not-authorized");
      _;
    }

    mapping (address => uint256) public bud;
    modifier toll {
        require(bud[msg.sender] == 1, "StethPrice/not-whitelisted");
        _;
    }

    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Kiss(address a);
    event Diss(address a);

    constructor(address _steth, address _wstETHOracle) {
        STETH = StethLike(_steth);
        WSTETH_ORACLE = OracleLike(_wstETHOracle);
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    function peek() external view toll returns (uint256 val, bool has) {
        (val, has) = WSTETH_ORACLE.peek();
        val = val * WAD / STETH.getPooledEthByShares(1 ether);
    }

    function read() external view toll returns (uint256 price) {
        price = WSTETH_ORACLE.read() * WAD / STETH.getPooledEthByShares(1 ether);
    }

    function kiss(address _a) external auth {
        require(_a != address(0), "StethPrice/no-contract-0");
        bud[_a] = 1;
        emit Kiss(_a);
    }

    function diss(address _a) external auth {
        bud[_a] = 0;
        emit Diss(_a);
    }

    function kiss(address[] calldata _a) external auth {
        for(uint256 i = 0; i < _a.length;) {
            require(_a[i] != address(0), "StethPrice/no-contract-0");
            bud[_a[i]] = 1;
            emit Kiss(_a[i]);
            unchecked { i++; }
        }
    }

    function diss(address[] calldata _a) external auth {
        for(uint256 i = 0; i < _a.length;) {
            bud[_a[i]] = 0;
            emit Diss(_a[i]);
            unchecked { i++; }
        }
    }
}