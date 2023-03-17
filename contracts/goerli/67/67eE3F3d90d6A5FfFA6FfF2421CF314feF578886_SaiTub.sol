/**
 *Submitted for verification at Etherscan.io on 2017-12-18
*/

// hevm: flattened sources of src/tub.sol
pragma solidity ^0.4.18;

////// lib/ds-guard/lib/ds-auth/src/auth.sol
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

/* pragma solidity ^0.4.13; */

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    function DSAuth() public {
        owner = msg.sender;
        LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}

////// lib/ds-spell/lib/ds-note/src/note.sol
/// note.sol -- the `note' modifier, for logging calls as events

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

/* pragma solidity ^0.4.13; */

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint              wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
}

////// lib/ds-thing/lib/ds-math/src/math.sol
/// math.sol -- mixin for inline numerical wizardry

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

/* pragma solidity ^0.4.13; */

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

////// lib/ds-thing/src/thing.sol
// thing.sol - `auth` with handy mixins. your things should be DSThings

// Copyright (C) 2017  DappHub, LLC

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

/* pragma solidity ^0.4.13; */

/* import 'ds-auth/auth.sol'; */
/* import 'ds-note/note.sol'; */
/* import 'ds-math/math.sol'; */

contract DSThing is DSAuth, DSNote, DSMath {

    function S(string s) internal pure returns (bytes4) {
        return bytes4(keccak256(s));
    }

}

////// lib/ds-token/lib/ds-stop/src/stop.sol
/// stop.sol -- mixin for enable/disable functionality

// Copyright (C) 2017  DappHub, LLC

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

/* pragma solidity ^0.4.13; */

/* import "ds-auth/auth.sol"; */
/* import "ds-note/note.sol"; */

contract DSStop is DSNote, DSAuth {

    bool public stopped;

    modifier stoppable {
        require(!stopped);
        _;
    }
    function stop() public auth note {
        stopped = true;
    }
    function start() public auth note {
        stopped = false;
    }

}

////// lib/ds-token/lib/erc20/src/erc20.sol
/// erc20.sol -- API for the ERC20 token standard

// See <https://github.com/ethereum/EIPs/issues/20>.

// This file likely does not meet the threshold of originality
// required for copyright to apply.  As a result, this is free and
// unencumbered software belonging to the public domain.

/* pragma solidity ^0.4.8; */

contract ERC20Events {
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
}

contract ERC20 is ERC20Events {
    function totalSupply() public view returns (uint);
    function balanceOf(address guy) public view returns (uint);
    function allowance(address src, address guy) public view returns (uint);

    function approve(address guy, uint wad) public returns (bool);
    function transfer(address dst, uint wad) public returns (bool);
    function transferFrom(
        address src, address dst, uint wad
    ) public returns (bool);
}

////// lib/ds-token/src/base.sol
/// base.sol -- basic ERC20 implementation

// Copyright (C) 2015, 2016, 2017  DappHub, LLC

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

/* pragma solidity ^0.4.13; */

/* import "erc20/erc20.sol"; */
/* import "ds-math/math.sol"; */

contract DSTokenBase is ERC20, DSMath {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;

    function DSTokenBase(uint supply) public {
        _balances[msg.sender] = supply;
        _supply = supply;
    }

    function totalSupply() public view returns (uint) {
        return _supply;
    }
    function balanceOf(address src) public view returns (uint) {
        return _balances[src];
    }
    function allowance(address src, address guy) public view returns (uint) {
        return _approvals[src][guy];
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        if (src != msg.sender) {
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        }

        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        Transfer(src, dst, wad);

        return true;
    }

    function approve(address guy, uint wad) public returns (bool) {
        _approvals[msg.sender][guy] = wad;

        Approval(msg.sender, guy, wad);

        return true;
    }
}

////// lib/ds-token/src/token.sol
/// token.sol -- ERC20 implementation with minting and burning

// Copyright (C) 2015, 2016, 2017  DappHub, LLC

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

/* pragma solidity ^0.4.13; */

/* import "ds-stop/stop.sol"; */

/* import "./base.sol"; */

contract DSToken is DSTokenBase(0), DSStop {

    bytes32  public  symbol;
    uint256  public  decimals = 18; // standard token precision. override to customize

    function DSToken(bytes32 symbol_) public {
        symbol = symbol_;
    }

    event Mint(address indexed guy, uint wad);
    event Burn(address indexed guy, uint wad);

    function approve(address guy) public stoppable returns (bool) {
        return super.approve(guy, uint(-1));
    }

    function approve(address guy, uint wad) public stoppable returns (bool) {
        return super.approve(guy, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        stoppable
        returns (bool)
    {
        if (src != msg.sender && _approvals[src][msg.sender] != uint(-1)) {
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        }

        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        Transfer(src, dst, wad);

        return true;
    }

    function push(address dst, uint wad) public {
        transferFrom(msg.sender, dst, wad);
    }
    function pull(address src, uint wad) public {
        transferFrom(src, msg.sender, wad);
    }
    function move(address src, address dst, uint wad) public {
        transferFrom(src, dst, wad);
    }

    function mint(uint wad) public {
        mint(msg.sender, wad);
    }
    function burn(uint wad) public {
        burn(msg.sender, wad);
    }
    function mint(address guy, uint wad) public auth stoppable {
        _balances[guy] = add(_balances[guy], wad);
        _supply = add(_supply, wad);
        Mint(guy, wad);
    }
    function burn(address guy, uint wad) public auth stoppable {
        if (guy != msg.sender && _approvals[guy][msg.sender] != uint(-1)) {
            _approvals[guy][msg.sender] = sub(_approvals[guy][msg.sender], wad);
        }

        _balances[guy] = sub(_balances[guy], wad);
        _supply = sub(_supply, wad);
        Burn(guy, wad);
    }

    // Optional token name
    bytes32   public  name = "";

    function setName(bytes32 name_) public auth {
        name = name_;
    }
}

////// lib/ds-value/src/value.sol
/// value.sol - a value is a simple thing, it can be get and set

// Copyright (C) 2017  DappHub, LLC

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

/* pragma solidity ^0.4.13; */

/* import 'ds-thing/thing.sol'; */

contract DSValue is DSThing {
    bool    has;
    bytes32 val;
    function peek() public view returns (bytes32, bool) {
        return (val,has);
    }
    function read() public view returns (bytes32) {
        var (wut, haz) = peek();
        assert(haz);
        return wut;
    }
    function poke(bytes32 wut) public note auth {
        val = wut;
        has = true;
    }
    function void() public note auth {  // unset the value
        has = false;
    }
}

////// src/vox.sol
/// vox.sol -- target price feed

// Copyright (C) 2016, 2017  Nikolai Mushegian <[email protected]>
// Copyright (C) 2016, 2017  Daniel Brockman <[email protected]>
// Copyright (C) 2017        Rain Break <[email protected]>

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

/* pragma solidity ^0.4.18; */

/* import "ds-thing/thing.sol"; */

contract SaiVox is DSThing {
    uint256  _par;
    uint256  _way;

    uint256  public  fix;
    uint256  public  how;
    uint256  public  tau;

    function SaiVox(uint par_) public {
        _par = fix = par_;
        _way = RAY;
        tau  = era();
    }

    function era() public view returns (uint) {
        return block.timestamp;
    }

    function mold(bytes32 param, uint val) public note auth {
        if (param == 'way') _way = val;
    }

    // Dai Target Price (ref per dai)
    function par() public returns (uint) {
        prod();
        return _par;
    }
    function way() public returns (uint) {
        prod();
        return _way;
    }

    function tell(uint256 ray) public note auth {
        fix = ray;
    }
    function tune(uint256 ray) public note auth {
        how = ray;
    }

    function prod() public note {
        var age = era() - tau;
        if (age == 0) return;  // optimised
        tau = era();

        if (_way != RAY) _par = rmul(_par, rpow(_way, age));  // optimised

        if (how == 0) return;  // optimised
        var wag = int128(how * age);
        _way = inj(prj(_way) + (fix < _par ? wag : -wag));
    }

    function inj(int128 x) internal pure returns (uint256) {
        return x >= 0 ? uint256(x) + RAY
            : rdiv(RAY, RAY + uint256(-x));
    }
    function prj(uint256 x) internal pure returns (int128) {
        return x >= RAY ? int128(x - RAY)
            : int128(RAY) - int128(rdiv(RAY, x));
    }
}

////// src/tub.sol
/// tub.sol -- simplified CDP engine (baby brother of `vat')

// Copyright (C) 2017  Nikolai Mushegian <[email protected]>
// Copyright (C) 2017  Daniel Brockman <[email protected]>
// Copyright (C) 2017  Rain Break <[email protected]>

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

/* pragma solidity ^0.4.18; */

/* import "ds-thing/thing.sol"; */
/* import "ds-token/token.sol"; */
/* import "ds-value/value.sol"; */

/* import "./vox.sol"; */

contract SaiTubEvents {
    event LogNewCup(address indexed lad, bytes32 cup);
}

contract SaiTub is DSThing, SaiTubEvents {
    DSToken  public  sai;  // Stablecoin
    DSToken  public  sin;  // Debt (negative sai)

    DSToken  public  skr;  // Abstracted collateral
    ERC20    public  gem;  // Underlying collateral

    DSToken  public  gov;  // Governance token

    SaiVox   public  vox;  // Target price feed
    DSValue  public  pip;  // Reference price feed
    DSValue  public  pep;  // Governance price feed

    address  public  tap;  // Liquidator
    address  public  pit;  // Governance Vault

    uint256  public  axe;  // Liquidation penalty
    uint256  public  cap;  // Debt ceiling
    uint256  public  mat;  // Liquidation ratio
    uint256  public  tax;  // Stability fee
    uint256  public  fee;  // Governance fee
    uint256  public  gap;  // Join-Exit Spread

    bool     public  off;  // Cage flag
    bool     public  out;  // Post cage exit

    uint256  public  fit;  // REF per SKR (just before settlement)

    uint256  public  rho;  // Time of last drip
    uint256         _chi;  // Accumulated Tax Rates
    uint256         _rhi;  // Accumulated Tax + Fee Rates
    uint256  public  rum;  // Total normalised debt

    uint256                   public  cupi;
    mapping (bytes32 => Cup)  public  cups;

    struct Cup {
        address  lad;      // CDP owner
        uint256  ink;      // Locked collateral (in SKR)
        uint256  art;      // Outstanding normalised debt (tax only)
        uint256  ire;      // Outstanding normalised debt
    }

    function lad(bytes32 cup) public view returns (address) {
        return cups[cup].lad;
    }
    function ink(bytes32 cup) public view returns (uint) {
        return cups[cup].ink;
    }
    function tab(bytes32 cup) public returns (uint) {
        return rmul(cups[cup].art, chi());
    }
    function rap(bytes32 cup) public returns (uint) {
        return sub(rmul(cups[cup].ire, rhi()), tab(cup));
    }

    // Total CDP Debt
    function din() public returns (uint) {
        return rmul(rum, chi());
    }
    // Backing collateral
    function air() public view returns (uint) {
        return skr.balanceOf(this);
    }
    // Raw collateral
    function pie() public view returns (uint) {
        return gem.balanceOf(this);
    }

    //------------------------------------------------------------------

    function SaiTub(
        DSToken  sai_,
        DSToken  sin_,
        DSToken  skr_,
        ERC20    gem_,
        DSToken  gov_,
        DSValue  pip_,
        DSValue  pep_,
        SaiVox   vox_,
        address  pit_
    ) public {
        gem = gem_;
        skr = skr_;

        sai = sai_;
        sin = sin_;

        gov = gov_;
        pit = pit_;

        pip = pip_;
        pep = pep_;
        vox = vox_;

        axe = RAY;
        mat = RAY;
        tax = RAY;
        fee = RAY;
        gap = WAD;

        _chi = RAY;
        _rhi = RAY;

        rho = era();
    }

    function era() public constant returns (uint) {
        return block.timestamp;
    }

    //--Risk-parameter-config-------------------------------------------

    function mold(bytes32 param, uint val) public note auth {
        if      (param == 'cap') cap = val;
        else if (param == 'mat') { require(val >= RAY); mat = val; }
        else if (param == 'tax') { require(val >= RAY); drip(); tax = val; }
        else if (param == 'fee') { require(val >= RAY); drip(); fee = val; }
        else if (param == 'axe') { require(val >= RAY); axe = val; }
        else if (param == 'gap') { require(val >= WAD); gap = val; }
        else return;
    }

    //--Price-feed-setters----------------------------------------------

    function setPip(DSValue pip_) public note auth {
        pip = pip_;
    }
    function setPep(DSValue pep_) public note auth {
        pep = pep_;
    }
    function setVox(SaiVox vox_) public note auth {
        vox = vox_;
    }

    //--Tap-setter------------------------------------------------------
    function turn(address tap_) public note {
        require(tap  == 0);
        require(tap_ != 0);
        tap = tap_;
    }

    //--Collateral-wrapper----------------------------------------------

    // Wrapper ratio (gem per skr)
    function per() public view returns (uint ray) {
        return skr.totalSupply() == 0 ? RAY : rdiv(pie(), skr.totalSupply());
    }
    // Join price (gem per skr)
    function ask(uint wad) public view returns (uint) {
        return rmul(wad, wmul(per(), gap));
    }
    // Exit price (gem per skr)
    function bid(uint wad) public view returns (uint) {
        return rmul(wad, wmul(per(), sub(2 * WAD, gap)));
    }
    function join(uint wad) public note {
        require(!off);
        require(ask(wad) > 0);
        require(gem.transferFrom(msg.sender, this, ask(wad)));
        skr.mint(msg.sender, wad);
    }
    function exit(uint wad) public note {
        require(!off || out);
        require(gem.transfer(msg.sender, bid(wad)));
        skr.burn(msg.sender, wad);
    }

    //--Stability-fee-accumulation--------------------------------------

    // Accumulated Rates
    function chi() public returns (uint) {
        drip();
        return _chi;
    }
    function rhi() public returns (uint) {
        drip();
        return _rhi;
    }
    function drip() public note {
        if (off) return;

        var rho_ = era();
        var age = rho_ - rho;
        if (age == 0) return;    // optimised
        rho = rho_;

        var inc = RAY;

        if (tax != RAY) {  // optimised
            var _chi_ = _chi;
            inc = rpow(tax, age);
            _chi = rmul(_chi, inc);
            sai.mint(tap, rmul(sub(_chi, _chi_), rum));
        }

        // optimised
        if (fee != RAY) inc = rmul(inc, rpow(fee, age));
        if (inc != RAY) _rhi = rmul(_rhi, inc);
    }


    //--CDP-risk-indicator----------------------------------------------

    // Abstracted collateral price (ref per skr)
    function tag() public view returns (uint wad) {
        return off ? fit : wmul(per(), uint(pip.read()));
    }
    // Returns true if cup is well-collateralized
    function safe(bytes32 cup) public returns (bool) {
        var pro = rmul(tag(), ink(cup));
        var con = rmul(vox.par(), tab(cup));
        var min = rmul(con, mat);
        return pro >= min;
    }


    //--CDP-operations--------------------------------------------------

    function open() public note returns (bytes32 cup) {
        require(!off);
        cupi = add(cupi, 1);
        cup = bytes32(cupi);
        cups[cup].lad = msg.sender;
        LogNewCup(msg.sender, cup);
    }
    function give(bytes32 cup, address guy) public note {
        require(msg.sender == cups[cup].lad);
        require(guy != 0);
        cups[cup].lad = guy;
    }

    function lock(bytes32 cup, uint wad) public note {
        require(!off);
        cups[cup].ink = add(cups[cup].ink, wad);
        skr.pull(msg.sender, wad);
        require(cups[cup].ink == 0 || cups[cup].ink > 0.005 ether);
    }
    function free(bytes32 cup, uint wad) public note {
        require(msg.sender == cups[cup].lad);
        cups[cup].ink = sub(cups[cup].ink, wad);
        skr.push(msg.sender, wad);
        require(safe(cup));
        require(cups[cup].ink == 0 || cups[cup].ink > 0.005 ether);
    }

    function draw(bytes32 cup, uint wad) public note {
        require(!off);
        require(msg.sender == cups[cup].lad);
        require(rdiv(wad, chi()) > 0);

        cups[cup].art = add(cups[cup].art, rdiv(wad, chi()));
        rum = add(rum, rdiv(wad, chi()));

        cups[cup].ire = add(cups[cup].ire, rdiv(wad, rhi()));
        sai.mint(cups[cup].lad, wad);

        require(safe(cup));
        require(sai.totalSupply() <= cap);
    }
    function wipe(bytes32 cup, uint wad) public note {
        require(!off);

        var owe = rmul(wad, rdiv(rap(cup), tab(cup)));

        cups[cup].art = sub(cups[cup].art, rdiv(wad, chi()));
        rum = sub(rum, rdiv(wad, chi()));

        cups[cup].ire = sub(cups[cup].ire, rdiv(add(wad, owe), rhi()));
        sai.burn(msg.sender, wad);

        var (val, ok) = pep.peek();
        if (ok && val != 0) gov.move(msg.sender, pit, wdiv(owe, uint(val)));
    }

    function shut(bytes32 cup) public note {
        require(!off);
        require(msg.sender == cups[cup].lad);
        if (tab(cup) != 0) wipe(cup, tab(cup));
        if (ink(cup) != 0) free(cup, ink(cup));
        delete cups[cup];
    }

    function bite(bytes32 cup) public note {
        require(!safe(cup) || off);

        // Take on all of the debt, except unpaid fees
        var rue = tab(cup);
        sin.mint(tap, rue);
        rum = sub(rum, cups[cup].art);
        cups[cup].art = 0;
        cups[cup].ire = 0;

        // Amount owed in SKR, including liquidation penalty
        var owe = rdiv(rmul(rmul(rue, axe), vox.par()), tag());

        if (owe > cups[cup].ink) {
            owe = cups[cup].ink;
        }

        skr.push(tap, owe);
        cups[cup].ink = sub(cups[cup].ink, owe);
    }

    //------------------------------------------------------------------

    function cage(uint fit_, uint jam) public note auth {
        require(!off && fit_ != 0);
        off = true;
        axe = RAY;
        gap = WAD;
        fit = fit_;         // ref per skr
        require(gem.transfer(tap, jam));
    }
    function flow() public note auth {
        require(off);
        out = true;
    }
}