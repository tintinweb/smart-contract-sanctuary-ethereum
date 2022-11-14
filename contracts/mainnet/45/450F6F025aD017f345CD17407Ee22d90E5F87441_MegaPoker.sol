/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// SPDX-License-Identifier: AGPL-3.0
// The MegaPoker
//
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
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

pragma solidity ^0.6.12;

contract PokingAddresses {
    // OSMs and Spotter addresses
    address constant eth            = 0x81FE72B5A8d1A857d176C3E7d5Bd2679A9B85763;
    address constant btc            = 0xf185d0682d50819263941e5f4EacC763CC5C6C42;
    address constant mana           = 0x8067259EA630601f319FccE477977E55C6078C13;
    address constant link           = 0x9B0C694C6939b5EA9584e9b61C7815E8d97D9cC7;
    address constant yfi            = 0x5F122465bCf86F45922036970Be6DD7F58820214;
    address constant univ2usdceth   = 0xf751f24DD9cfAd885984D1bA68860F558D21E52A;
    address constant univ2daiusdc   = 0x25D03C2C928ADE19ff9f4FFECc07d991d0df054B;
    address constant matic          = 0x8874964279302e6d4e523Fb1789981C39a1034Ba;
    address constant wsteth         = 0xFe7a2aC0B945f12089aEEB6eCebf4F384D9f043F;
    address constant crvv1ethsteth  = 0xEa508F82728927454bd3ce853171b0e2705880D4;
    address constant guniv3daiusdc1 = 0x7F6d78CC0040c87943a0e0c140De3F77a273bd58;
    address constant guniv3daiusdc2 = 0xcCBa43231aC6eceBd1278B90c3a44711a00F4e93;
    address constant spotter        = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant reth           = 0xeE7F0b350aA119b3d05DC733a4621a81972f7D47;
}

contract MegaPoker is PokingAddresses {

    uint256 public last;

    function poke() external {
        bool ok;

        // poke() = 0x18178358
        (ok,) = eth.call(abi.encodeWithSelector(0x18178358));
        (ok,) = btc.call(abi.encodeWithSelector(0x18178358));
        (ok,) = mana.call(abi.encodeWithSelector(0x18178358));
        (ok,) = link.call(abi.encodeWithSelector(0x18178358));
        (ok,) = yfi.call(abi.encodeWithSelector(0x18178358));
        (ok,) = univ2usdceth.call(abi.encodeWithSelector(0x18178358));
        (ok,) = univ2daiusdc.call(abi.encodeWithSelector(0x18178358));
        (ok,) = matic.call(abi.encodeWithSelector(0x18178358));
        (ok,) = wsteth.call(abi.encodeWithSelector(0x18178358));
        (ok,) = crvv1ethsteth.call(abi.encodeWithSelector(0x18178358));
        (ok,) = reth.call(abi.encodeWithSelector(0x18178358));


        // poke(bytes32) = 0x1504460f
        (ok,) = spotter.call(abi.encodeWithSelector(0x1504460f, bytes32("ETH-A")));
        (ok,) = spotter.call(abi.encodeWithSelector(0x1504460f, bytes32("WBTC-A")));
        (ok,) = spotter.call(abi.encodeWithSelector(0x1504460f, bytes32("MANA-A")));
        (ok,) = spotter.call(abi.encodeWithSelector(0x1504460f, bytes32("LINK-A")));
        (ok,) = spotter.call(abi.encodeWithSelector(0x1504460f, bytes32("ETH-B")));
        (ok,) = spotter.call(abi.encodeWithSelector(0x1504460f, bytes32("YFI-A")));
        (ok,) = spotter.call(abi.encodeWithSelector(0x1504460f, bytes32("RENBTC-A")));
        (ok,) = spotter.call(abi.encodeWithSelector(0x1504460f, bytes32("UNIV2USDCETH-A")));
        (ok,) = spotter.call(abi.encodeWithSelector(0x1504460f, bytes32("UNIV2DAIUSDC-A")));
        (ok,) = spotter.call(abi.encodeWithSelector(0x1504460f, bytes32("ETH-C")));
        (ok,) = spotter.call(abi.encodeWithSelector(0x1504460f, bytes32("MATIC-A")));
        (ok,) = spotter.call(abi.encodeWithSelector(0x1504460f, bytes32("WSTETH-A")));
        (ok,) = spotter.call(abi.encodeWithSelector(0x1504460f, bytes32("WSTETH-B")));
        (ok,) = spotter.call(abi.encodeWithSelector(0x1504460f, bytes32("CRVV1ETHSTETH-A")));
        (ok,) = spotter.call(abi.encodeWithSelector(0x1504460f, bytes32("WBTC-B")));
        (ok,) = spotter.call(abi.encodeWithSelector(0x1504460f, bytes32("WBTC-C")));
        (ok,) = spotter.call(abi.encodeWithSelector(0x1504460f, bytes32("RETH-A")));


        // Daily pokes
        //  Reduced cost pokes
        if (last <= block.timestamp - 1 days) {

            // The GUINIV3DAIUSDCX Oracles are very expensive to poke, and the price should not
            //  change frequently, so they are getting poked only once a day.
            (ok,) = guniv3daiusdc1.call(abi.encodeWithSelector(0x18178358));
            (ok,) = guniv3daiusdc2.call(abi.encodeWithSelector(0x18178358));


            (ok,) = spotter.call(abi.encodeWithSelector(0x1504460f, bytes32("GUNIV3DAIUSDC1-A")));
            (ok,) = spotter.call(abi.encodeWithSelector(0x1504460f, bytes32("GUNIV3DAIUSDC2-A")));

            last = block.timestamp;
        }
    }
}