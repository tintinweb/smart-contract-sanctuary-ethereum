/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Copyright (C) 2022 Dai Foundation
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

pragma solidity 0.6.12;

interface ChainlogAbstract {
    function getAddress(bytes32) external view returns (address);
}

interface OsmMomAbstract {
    function stop(bytes32) external;
}

contract DssSpell {
    // This address should correspond to the latest MCD Chainlog contract; verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/active/contracts.json
    ChainlogAbstract constant CHANGELOG =
        ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    uint256          public expiration;
    bool             public done;

    // Provides a descriptive tag for bot consumption
    string constant public description = "Emergency Spell: Pause CRVV1ETHSTETH Osm";

    constructor() public {
        expiration = block.timestamp + 30 days;
    }

    function schedule() external {
        require(!done, "spell-already-schedule");
        require(block.timestamp <= expiration, "This contract has expired");
        done = true;

        OsmMomAbstract(CHANGELOG.getAddress("OSM_MOM")).stop("CRVV1ETHSTETH-A");
    }

    function cast() external pure {
    }
}