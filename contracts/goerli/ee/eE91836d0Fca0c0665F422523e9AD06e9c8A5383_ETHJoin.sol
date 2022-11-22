/**
 *Submitted for verification at Etherscan.io on 2019-11-14
 */

// hevm: flattened sources of /nix/store/8xb41r4qd0cjb63wcrxf1qmfg88p0961-dss-6fd7de0/src/join.sol
pragma solidity >=0.4.12;

////// /nix/store/8xb41r4qd0cjb63wcrxf1qmfg88p0961-dss-6fd7de0/src/lib.sol
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

/* pragma solidity 0.5.12; */

////// /nix/store/8xb41r4qd0cjb63wcrxf1qmfg88p0961-dss-6fd7de0/src/join.sol
/// join.sol -- Basic token adapters

// Copyright (C) 2018 Rain <[email protected]>
//
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

/* pragma solidity 0.5.12; */

/* import "./lib.sol"; */

interface DSTokenLike {
    function mint(address, uint256) external;

    function burn(address, uint256) external;
}

interface VatLike {
    function slip(
        bytes32,
        address,
        int256
    ) external;

    function move(
        address,
        address,
        uint256
    ) external;
}

/*
    Here we provide *adapters* to connect the Vat to arbitrary external
    token implementations, creating a bounded context for the Vat. The
    adapters here are provided as working examples:

      - `GemJoin`: For well behaved ERC20 tokens, with simple transfer
                   semantics.

      - `ETHJoin`: For native Ether.

      - `DaiJoin`: For connecting internal Dai balances to an external
                   `DSToken` implementation.

    In practice, adapter implementations will be varied and specific to
    individual collateral types, accounting for different transfer
    semantics and token standards.

    Adapters need to implement two basic methods:

      - `join`: enter collateral into the system
      - `exit`: remove collateral from the system

*/

contract ETHJoin {
    // ---  ---
    mapping(address => uint256) public wards;

    function rely(address usr) external {
        wards[usr] = 1;
    }

    function deny(address usr) external {
        wards[usr] = 0;
    }

    VatLike public vat;
    bytes32 public ilk;
    uint256 public live; // Access Flag

    constructor(address vat_, bytes32 ilk_) public {
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike(vat_);
        ilk = ilk_;
    }

    function cage() external {
        live = 0;
    }

    function join(address usr) external payable {
        require(live == 1, "ETHJoin/not-live");
        require(int256(msg.value) >= 0, "ETHJoin/overflow");
        vat.slip(ilk, usr, int256(msg.value));
    }

    function exit(address payable usr, uint256 wad) external {
        require(int256(wad) >= 0, "ETHJoin/overflow");
        vat.slip(ilk, msg.sender, -int256(wad));
        usr.transfer(wad);
    }
}