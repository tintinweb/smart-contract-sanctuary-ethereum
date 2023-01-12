// SPDX-License-Identifier: AGPL-3.0-or-later

/// flip.sol -- Collateral auction

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

pragma solidity 0.5.15;

import "./lib.sol";

interface VatLike {
    function move(address,address,uint256) external;
    function flux(bytes32,address,address,uint256) external;
}

interface CatLike {
    function claw(uint256) external;
}

/*
   This thing lets you flip some gems for a given amount of dai.
   Once the given amount of dai is raised, gems are forgone instead.

 - `lot` gems in return for bid
 - `tab` total dai wanted
 - `bid` dai paid
 - `gal` receives dai income
 - `usr` receives gem forgone
 - `ttl` single bid lifetime
 - `beg` minimum bid increase
 - `end` max auction duration
*/

contract Flipper is LibNote {
    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external note auth { wards[usr] = 1; }
    function deny(address usr) external note auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Flipper/not-authorized");
        _;
    }

    // --- Data ---
    struct Bid {
        uint256 bid;  // dai paid                 [rad]
        uint256 lot;  // gems in return for bid   [wad]
        address guy;  // high bidder
        uint48  tic;  // bid expiry time          [unix epoch time]
        uint48  end;  // auction expiry time      [unix epoch time]
        address usr;
        address gal;
        uint256 tab;  // total dai wanted         [rad]
    }

    mapping (uint256 => Bid) public bids;

    VatLike public   vat;            // CDP Engine
    bytes32 public   ilk;            // collateral type

    uint256 public   ONE;
    uint256 public   beg;  // 5% minimum bid increase
    uint48  public   ttl;  // 3 hours bid duration         [seconds]
    uint48  public   tau;   // 2 days total auction length  [seconds]
    uint256 public kicks = 0;
    CatLike public   cat;            // cat liquidation module
    bool     initSta;
    mapping(uint256 => uint256) public daiById;
    
    // --- Events ---
    event Kick(
      uint256 id,
      uint256 lot,
      uint256 bid,
      uint256 tab,
      address indexed usr,
      address indexed gal
    );

    // --- Init ---
    function init(address vat_, address cat_, bytes32 ilk_) public {
        require(!initSta, "inited");
        initSta = true;
        ONE = 1.00E18;
        beg = 1.05E18;
        ttl = 3 hours;
        tau = 2 days;
        kicks = 0;
        vat = VatLike(vat_);
        cat = CatLike(cat_);
        ilk = ilk_;
        wards[msg.sender] = 1;
    }

    // --- Math ---
    function add(uint48 x, uint48 y) internal pure returns (uint48 z) {
        require((z = x + y) >= x, "Flipper/add-overflow");
    }
    function addUint256(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "Flipper/mul-overflow");
    }

    // --- Admin ---
    function file(bytes32 what, uint256 data) external note auth {
        if (what == "beg") beg = data;
        else if (what == "ttl") ttl = uint48(data);
        else if (what == "tau") tau = uint48(data);
        else revert("Flipper/file-unrecognized-param");
    }
    function file(bytes32 what, address data) external note auth {
        if (what == "cat") cat = CatLike(data);
        else revert("Flipper/file-unrecognized-param");
    }

    // --- Auction ---
    function kick(address usr, address gal, uint256 tab, uint256 lot, uint256 bid)
        public auth returns (uint256 id)
    {
        require(kicks < uint256(-1), "Flipper/overflow");
        id = ++kicks;

        bids[id].bid = bid;
        bids[id].lot = lot;
        bids[id].guy = msg.sender;  // configurable??
        bids[id].end = add(uint48(now), tau);
        bids[id].usr = usr;
        bids[id].gal = gal;
        bids[id].tab = tab;

        vat.flux(ilk, msg.sender, address(this), lot);

        emit Kick(id, lot, bid, tab, usr, gal);
    }
    function tick(uint256 id) external note {
        require(bids[id].guy != address(0), "Flipper/guy-not-set");
        require(bids[id].end < now, "Flipper/not-finished");
        require(bids[id].tic == 0, "Flipper/bid-already-placed");
        bids[id].end = add(uint48(now), tau);
    }
    function tend(uint256 id, uint256 lot, uint256 bid) external note {
        require(bids[id].guy != address(0), "Flipper/guy-not-set");
        require(bids[id].tic > now || bids[id].tic == 0, "Flipper/already-finished-tic");
        require(bids[id].end > now, "Flipper/already-finished-end");

        require(lot == bids[id].lot, "Flipper/lot-not-matching");
//        require(bid <= bids[id].tab, "Flipper/higher-than-tab");
        require(bid >  bids[id].bid, "Flipper/bid-not-higher");
        require(mul(bid, ONE) >= mul(beg, bids[id].bid) || bid == bids[id].tab, "Flipper/insufficient-increase");

        if (msg.sender != bids[id].guy) {
            vat.move(msg.sender, bids[id].guy, bids[id].bid);
            bids[id].guy = msg.sender;
        }
//        vat.move(msg.sender, bids[id].gal, bid - bids[id].bid);
        if(bids[id].bid <= bids[id].tab){
            if(bid <= bids[id].tab){
                vat.move(msg.sender, bids[id].gal, bid - bids[id].bid);
            }else {
                vat.move(msg.sender, bids[id].gal, bids[id].tab - bids[id].bid);
                vat.move(msg.sender, bids[id].usr, bid - bids[id].tab);
            }
        }else {
            vat.move(msg.sender, bids[id].usr, bid - bids[id].bid);
        }
        bids[id].bid = bid;
        bids[id].tic = add(uint48(now), ttl);
    }

    //    function tend(uint256 id, uint256 lot, uint256 bid) external note {
    //     require(bids[id].guy != address(0), "Flipper/guy-not-set");
    //     require(bids[id].tic > now || bids[id].tic == 0, "Flipper/already-finished-tic");
    //     require(bids[id].end > now, "Flipper/already-finished-end");

    //     require(lot == bids[id].lot, "Flipper/lot-not-matching");
    //     require(bid >  bids[id].bid, "Flipper/bid-not-higher");
    //     require(mul(bid, ONE) >= mul(beg, bids[id].bid) || bid == bids[id].tab, "Flipper/insufficient-increase");

    //     if (msg.sender != bids[id].guy) {
    //         vat.move(msg.sender, bids[id].guy, bids[id].bid);
    //         bids[id].guy = msg.sender;
    //     }
    //     if(bids[id].bid <= bids[id].tab){
    //         if(bid <= bids[id].tab){
    //             vat.move(msg.sender, bids[id].gal, sub(bid, bids[id].bid));
    //         }else {
    //             vat.move(msg.sender, bids[id].gal, sub(bids[id].tab, bids[id].bid));
    //             uint256 num = sub(bid, bids[id].tab);
    //             daiById[id] = addUint256(daiById[id], num);
    //             vat.move(msg.sender, address(this), num);
    //         }
    //     }else {
    //         uint256 num = sub(bid, bids[id].bid);
    //         daiById[id] = addUint256(daiById[id], num);
    //         vat.move(msg.sender, address(this), num);
    //     }
    //     bids[id].bid = bid;
    //     bids[id].tic = add(uint48(now), ttl);
    // }

    function deal(uint256 id) external note {
        require(bids[id].tic != 0 && (bids[id].tic < now || bids[id].end < now), "Flipper/not-finished");
        cat.claw(bids[id].tab);
        vat.flux(ilk, address(this), bids[id].guy, bids[id].lot);
        delete bids[id];
    }

    function yank(uint256 id) external note auth {
        require(bids[id].guy != address(0), "Flipper/guy-not-set");
        require(bids[id].bid < bids[id].tab, "Flipper/already-dent-phase");
        cat.claw(bids[id].tab);
        vat.flux(ilk, address(this), msg.sender, bids[id].lot);
        vat.move(msg.sender, bids[id].guy, bids[id].bid);
        delete bids[id];
    }
}