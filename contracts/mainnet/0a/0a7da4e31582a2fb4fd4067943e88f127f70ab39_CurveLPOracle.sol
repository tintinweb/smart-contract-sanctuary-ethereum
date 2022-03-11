/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

// SPDX-License-Identifier: GPL-3.0-or-later

/// CurveLPOracle.sol

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

interface AddressProviderLike {
    function get_registry() external view returns (address);
}

interface CurveRegistryLike {
    function get_n_coins(address) external view returns (uint256[2] calldata);
}

interface CurvePoolLike {
    function coins(uint256) external view returns (address);
    function get_virtual_price() external view returns (uint256);
    function lp_token() external view returns (address);
}

interface OracleLike {
    function read() external view returns (uint256);
}

contract CurveLPOracleFactory {

    AddressProviderLike immutable ADDRESS_PROVIDER;

    event NewCurveLPOracle(address owner, address orcl, bytes32 wat, address pool);

    constructor(address addressProvider) {
        ADDRESS_PROVIDER = AddressProviderLike(addressProvider);
    }

    function build(
        address _owner,
        address _pool,
        bytes32 _wat,
        address[] calldata _orbs
    ) external returns (address orcl) {
        uint256 ncoins = CurveRegistryLike(ADDRESS_PROVIDER.get_registry()).get_n_coins(_pool)[1];
        require(ncoins == _orbs.length, "CurveLPOracleFactory/wrong-num-of-orbs");
        orcl = address(new CurveLPOracle(_owner, _pool, _wat, _orbs));
        emit NewCurveLPOracle(_owner, orcl, _wat, _pool);
    }
}

contract CurveLPOracle {

    // --- Auth ---
    mapping (address => uint256) public wards;                                       // Addresses with admin authority
    function rely(address _usr) external auth { wards[_usr] = 1; emit Rely(_usr); }  // Add admin
    function deny(address _usr) external auth { wards[_usr] = 0; emit Deny(_usr); }  // Remove admin
    modifier auth {
        require(wards[msg.sender] == 1, "CurveLPOracle/not-authorized");
        _;
    }

    address public immutable src;   // Price source, do not remove as needed for OmegaPoker

    // stopped, hop, and zph are packed into single slot to reduce SLOADs;
    // this outweighs the added bitmasking overhead.
    uint8   public stopped;        // Stop/start ability to update
    uint16  public hop = 1 hours;  // Minimum time in between price updates
    uint232 public zph;            // Time of last price update plus hop

    // --- Whitelisting ---
    mapping (address => uint256) public bud;
    modifier toll { require(bud[msg.sender] == 1, "CurveLPOracle/not-whitelisted"); _; }

    struct Feed {
        uint128 val;  // Price
        uint128 has;  // Is price valid
    }

    Feed internal cur;  // Current price (storage slot 0x3)
    Feed internal nxt;  // Queued price  (storage slot 0x4)

    address[] public orbs;  // array of price feeds for pool assets, same order as in the pool

    address public immutable pool;    // Address of underlying Curve pool
    bytes32 public immutable wat;     // Label of token whose price is being tracked
    uint256 public immutable ncoins;  // Number of tokens in underlying Curve pool

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Stop();
    event Start();
    event Step(uint256 hop);
    event Link(uint256 id, address orb);
    event Value(uint128 curVal, uint128 nxtVal);
    event Kiss(address a);
    event Diss(address a);

    // --- Init ---
    constructor(address _ward, address _pool, bytes32 _wat, address[] memory _orbs) {
        require(_pool != address(0), "CurveLPOracle/invalid-pool");
        uint256 _ncoins = _orbs.length;
        pool   = _pool;
        src    = CurvePoolLike(_pool).lp_token();
        wat    = _wat;
        ncoins = _ncoins;
        for (uint256 i = 0; i < _ncoins;) {
            require(_orbs[i] != address(0), "CurveLPOracle/invalid-orb");
            orbs.push(_orbs[i]);
            unchecked { i++; }
        }
        require(_ward != address(0), "CurveLPOracle/ward-0");
        wards[_ward] = 1;
        emit Rely(_ward);
    }

    function stop() external auth {
        stopped = 1;
        delete cur;
        delete nxt;
        zph = 0;
        emit Stop();
    }

    function start() external auth {
        stopped = 0;
        emit Start();
    }

    function step(uint16 _hop) external auth {
        uint16 old = hop;
        hop = _hop;
        if (zph > old) {  // if false, zph will be unset and no update is needed
            zph = (zph - old) + _hop;
        }
        emit Step(_hop);
    }

    function link(uint256 _id, address _orb) external auth {
        require(_orb != address(0), "CurveLPOracle/invalid-orb");
        require(_id < ncoins, "CurveLPOracle/invalid-orb-index");
        orbs[_id] = _orb;
        emit Link(_id, _orb);
    }

    // For consistency with other oracles
    function zzz() external view returns (uint256) {
        if (zph == 0) return 0;  // backwards compatibility
        return zph - hop;
    }

    function pass() external view returns (bool) {
        return block.timestamp >= zph;
    }

    // Marked payable to save gas. DO *NOT* send ETH to poke(), it will be lost permanently.
    function poke() external payable {

        // Ensure a single SLOAD while avoiding solc's excessive bitmasking bureaucracy.
        uint256 hop_;
        {

            // Block-scoping these variables saves some gas.
            uint256 stopped_;
            uint256 zph_;
            assembly {
                let slot1 := sload(1)
                stopped_  := and(slot1,         0xff  )
                hop_      := and(shr(8, slot1), 0xffff)
                zph_      := shr(24, slot1)
            }

            // When stopped, values are set to zero and should remain such; thus, disallow updating in that case.
            require(stopped_ == 0, "CurveLPOracle/is-stopped");

            // Equivalent to requiring that pass() returns true; logic repeated to save gas.
            require(block.timestamp >= zph_, "CurveLPOracle/not-passed");
        }

        uint256 val = type(uint256).max;
        for (uint256 i = 0; i < ncoins;) {
            uint256 price = OracleLike(orbs[i]).read();
            if (price < val) val = price;
            unchecked { i++; }
        }
        val = val * CurvePoolLike(pool).get_virtual_price() / 10**18;
        require(val != 0, "CurveLPOracle/zero-price");
        require(val <= type(uint128).max, "CurveLPOracle/price-overflow");
        Feed memory cur_ = nxt;
        cur = cur_;
        nxt = Feed(uint128(val), 1);

        // The below is equivalent to:
        //    zph = block.timestamp + hop
        // but ensures no extra SLOADs are performed.
        //
        // Even if _hop = (2^16 - 1), the maximum possible value, add(timestamp(), _hop)
        // will not overflow (even a 232 bit value) for a very long time.
        //
        // Also, we know stopped was zero, so there is no need to account for it explicitly here.
        assembly {
            sstore(
                1,
                add(
                    shl(24, add(timestamp(), hop_)),  // zph value starts 24 bits in
                    shl(8, hop_)                      // hop value starts 8 bits in
                )
            )
        }

        emit Value(cur_.val, uint128(val));

        // Safe to terminate immediately since no postfix modifiers are applied.
        assembly { stop() }
    }

    function peek() external view toll returns (bytes32,bool) {
        return (bytes32(uint256(cur.val)), cur.has == 1);
    }

    function peep() external view toll returns (bytes32,bool) {
        return (bytes32(uint256(nxt.val)), nxt.has == 1);
    }

    function read() external view toll returns (bytes32) {
        require(cur.has == 1, "CurveLPOracle/no-current-value");
        return (bytes32(uint256(cur.val)));
    }

    function kiss(address _a) external auth {
        require(_a != address(0), "CurveLPOracle/no-contract-0");
        bud[_a] = 1;
        emit Kiss(_a);
    }

    function kiss(address[] calldata _a) external auth {
        for(uint256 i = 0; i < _a.length;) {
            require(_a[i] != address(0), "CurveLPOracle/no-contract-0");
            bud[_a[i]] = 1;
            emit Kiss(_a[i]);
            unchecked { i++; }
        }
    }

    function diss(address _a) external auth {
        bud[_a] = 0;
        emit Diss(_a);
    }

    function diss(address[] calldata _a) external auth {
        for(uint256 i = 0; i < _a.length;) {
            bud[_a[i]] = 0;
            emit Diss(_a[i]);
            unchecked { i++; }
        }
    }
}