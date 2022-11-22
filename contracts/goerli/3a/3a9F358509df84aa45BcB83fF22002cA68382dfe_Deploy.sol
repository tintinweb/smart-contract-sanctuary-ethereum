pragma solidity >=0.5.12;

import {DSPause} from "./ds-pause/pause.sol";

import {Vat} from "./dss/vat.sol";
import {Jug} from "./dss/jug.sol";
import {Vow} from "./dss/vow.sol";
import {Cat} from "./dss/cat.sol";
import {Dog} from "./dss/dog.sol";
import {IRDTJoin} from "./dss/join.sol";
import {Flapper} from "./dss/flap.sol";
import {Flopper} from "./dss/flop.sol";
import {Flipper} from "./dss/flip.sol";
import {Clipper} from "./dss/clip.sol";
import {LinearDecrease, StairstepExponentialDecrease, ExponentialDecrease} from "./dss/abaci.sol";
import {IRDT} from "./dss/irdt.sol";
import {Cure} from "./dss/cure.sol";
import {End} from "./dss/end.sol";
import {ESM} from "./esm/esm.sol";
import {Pot} from "./dss/pot.sol";
import {Spotter} from "./dss/spot.sol";

contract VatFab {
    function newVat(address owner) public returns (Vat vat) {
        vat = new Vat();
        vat.rely(owner);
    }
}

contract JugFab {
    function newJug(address owner, address vat) public returns (Jug jug) {
        jug = new Jug(vat);
        jug.rely(owner);
    }
}

contract VowFab {
    function newVow(
        address owner,
        address vat,
        address flap,
        address flop
    ) public returns (Vow vow) {
        vow = new Vow(vat, flap, flop);
        vow.rely(owner);
    }
}

contract CatFab {
    function newCat(address owner, address vat) public returns (Cat cat) {
        cat = new Cat(vat);
        cat.rely(owner);
    }
}

contract DogFab {
    function newDog(address owner, address vat) public returns (Dog dog) {
        dog = new Dog(vat);
        dog.rely(owner);
    }
}

contract IRDTFab {
    function newirdt(address owner, uint256 chainId)
    public
    returns (IRDT irdt)
    {
        irdt = new IRDT(chainId);
        irdt.rely(owner);
    }
}

contract IRDTJoinFab {
    function newIRDTJoin(address vat, address irdt)
    public
    returns (IRDTJoin irdtJoin)
    {
        irdtJoin = new IRDTJoin(vat, irdt);
    }
}

contract FlapFab {
    function newFlap(
        address owner,
        address vat,
        address gov
    ) public returns (Flapper flap) {
        flap = new Flapper(vat, gov);
        flap.rely(owner);
    }
}

contract FlopFab {
    function newFlop(
        address owner,
        address vat,
        address gov
    ) public returns (Flopper flop) {
        flop = new Flopper(vat, gov);
        flop.rely(owner);
    }
}

contract FlipFab {
    function newFlip(
        address owner,
        address vat,
        address cat,
        bytes32 ilk
    ) public returns (Flipper flip) {
        flip = new Flipper(vat, cat, ilk);
        flip.rely(owner);
    }
}

contract ClipFab {
    function newClip(
        address owner,
        address vat,
        address spotter,
        address dog,
        bytes32 ilk
    ) public returns (Clipper clip) {
        clip = new Clipper(vat, spotter, dog, ilk);
        clip.rely(owner);
    }
}

contract CalcFab {
    function newLinearDecrease(address owner)
    public
    returns (LinearDecrease calc)
    {
        calc = new LinearDecrease();
        calc.rely(owner);
    }

    function newStairstepExponentialDecrease(address owner)
    public
    returns (StairstepExponentialDecrease calc)
    {
        calc = new StairstepExponentialDecrease();
        calc.rely(owner);
    }

    function newExponentialDecrease(address owner)
    public
    returns (ExponentialDecrease calc)
    {
        calc = new ExponentialDecrease();
        calc.rely(owner);
    }
}

contract SpotFab {
    function newSpotter(address owner, address vat)
    public
    returns (Spotter spotter)
    {
        spotter = new Spotter(vat);
        spotter.rely(owner);
    }
}

contract PotFab {
    function newPot(address owner, address vat) public returns (Pot pot) {
        pot = new Pot(vat);
        pot.rely(owner);
    }
}

contract CureFab {
    function newCure(address owner) public returns (Cure cure) {
        cure = new Cure();
        cure.rely(owner);
    }
}

contract EndFab {
    function newEnd(address owner) public returns (End end) {
        end = new End();
        end.rely(owner);
    }
}

contract ESMFab {
    function newESM(
        address gov,
        address end,
        address proxy,
        uint256 min
    ) public returns (ESM esm) {
        esm = new ESM(gov, end, proxy, min);
    }
}

contract PauseFab {
    function newPause(
        uint256 delay,
        address owner,
        address authority
    ) public returns (DSPause pause) {
        pause = new DSPause(delay, owner, authority);
    }
}

contract Deploy {
    VatFab public vatFab;
    JugFab public jugFab;
    VowFab public vowFab;
    CatFab public catFab;
    DogFab public dogFab;
    IRDTFab public irdtFab;
    IRDTJoinFab public irdtJoinFab;
    FlapFab public flapFab;
    FlopFab public flopFab;
    FlipFab public flipFab;
    ClipFab public clipFab;
    CalcFab public calcFab;
    SpotFab public spotFab;
    PotFab public potFab;
    CureFab public cureFab;
    EndFab public endFab;
    ESMFab public esmFab;
    PauseFab public pauseFab;

    Vat public vat;
    Jug public jug;
    Vow public vow;
    Cat public cat;
    Dog public dog;
    IRDT public irdt;
    IRDTJoin public irdtJoin;
    Flapper public flap;
    Flopper public flop;
    Spotter public spotter;
    Pot public pot;
    Cure public cure;
    End public end;
    ESM public esm;
    DSPause public pause;

    mapping(bytes32 => Ilk) public ilks;

    uint8 public step = 0;

    uint256 constant ONE = 10 ** 27;

    struct Ilk {
        Flipper flip;
        Clipper clip;
        address join;
    }

    function addFabsA(VatFab vatFab_, JugFab jugFab_) external {
        vatFab = vatFab_;
        jugFab = jugFab_;
    }

    function addFabsB(VowFab vowFab_, CatFab catFab_) external {
        vowFab = vowFab_;
        catFab = catFab_;
    }

    function addFabsC(
        DogFab dogFab_,
        IRDTFab irdtFab_,
        IRDTJoinFab irdtJoinFab_
    ) external {
        dogFab = dogFab_;
        irdtFab = irdtFab_;
        irdtJoinFab = irdtJoinFab_;
    }

    function addFabsD(
        FlapFab flapFab_,
        FlopFab flopFab_,
        FlipFab flipFab_
    ) external {
        flapFab = flapFab_;
        flopFab = flopFab_;
        flipFab = flipFab_;
    }

    function addFabsE(
        ClipFab clipFab_,
        CalcFab calcFab_,
        SpotFab spotFab_,
        PotFab potFab_
    ) external {
        clipFab = clipFab_;
        calcFab = calcFab_;
        spotFab = spotFab_;
        potFab = potFab_;
    }

    function addFabsF(
        CureFab cureFab_,
        EndFab endFab_,
        ESMFab esmFab_,
        PauseFab pauseFab_
    ) external {
        cureFab = cureFab_;
        endFab = endFab_;
        esmFab = esmFab_;
        pauseFab = pauseFab_;
    }

    function rad(uint256 wad) internal pure returns (uint256) {
        return wad * 10 ** 27;
    }

    function deployVat() public {
        require(address(vatFab) != address(0), "Missing Fabs 1");
        require(address(flapFab) != address(0), "Missing Fabs 2");
        require(address(vat) == address(0), "VAT already deployed");
        vat = vatFab.newVat(address(this));
        spotter = spotFab.newSpotter(address(this), address(vat));

        // Internal auth
        vat.rely(address(spotter));
    }

    function deployIRDT(uint256 chainId) public {
        require(address(vat) != address(0), "Missing previous step");

        irdt = irdtFab.newirdt(address(this), chainId);
        irdtJoin = irdtJoinFab.newIRDTJoin(address(vat), address(irdt));
        irdt.rely(address(irdtJoin));
    }

    function deployTaxation() public {
        require(address(vat) != address(0), "Missing previous step");

        // Deploy
        jug = jugFab.newJug(address(this), address(vat));
        pot = potFab.newPot(address(this), address(vat));

        // Internal auth
        vat.rely(address(jug));
        vat.rely(address(pot));
    }

    function deployAuctions(address gov) public {
        require(gov != address(0), "Missing GOV address");
        require(address(jug) != address(0), "Missing previous step");

        // Deploy
        flap = flapFab.newFlap(address(this), address(vat), gov);
        flop = flopFab.newFlop(address(this), address(vat), gov);
        vow = vowFab.newVow(
            address(this),
            address(vat),
            address(flap),
            address(flop)
        );

        // Internal references set up
        jug.file("vow", address(vow));
        pot.file("vow", address(vow));

        // Internal auth
        vat.rely(address(flop));
        flap.rely(address(vow));
        flop.rely(address(vow));
    }

    function deployLiquidator() public {
        require(address(vow) != address(0), "Missing previous step");

        // Deploy
        cat = catFab.newCat(address(this), address(vat));
        dog = dogFab.newDog(address(this), address(vat));

        // Internal references set up
        cat.file("vow", address(vow));
        dog.file("vow", address(vow));

        // Internal auth
        vat.rely(address(cat));
        vat.rely(address(dog));
        vow.rely(address(cat));
        vow.rely(address(dog));
    }

    function deployEnd() public {
        require(address(cat) != address(0), "Missing previous step");

        // Deploy
        cure = cureFab.newCure(address(this));
        end = endFab.newEnd(address(this));

        // Internal references set up
        end.file("vat", address(vat));
        end.file("cat", address(cat));
        end.file("dog", address(dog));
        end.file("vow", address(vow));
        end.file("pot", address(pot));
        end.file("spot", address(spotter));
        end.file("cure", address(cure));

        // Internal auth
        vat.rely(address(end));
        cat.rely(address(end));
        dog.rely(address(end));
        vow.rely(address(end));
        pot.rely(address(end));
        spotter.rely(address(end));
        cure.rely(address(end));
    }

    function deployPause(uint256 delay, address authority) public {
        require(address(irdt) != address(0), "Missing previous step");
        require(address(end) != address(0), "Missing previous step");

        pause = pauseFab.newPause(delay, msg.sender, authority);

        vat.rely(address(pause.proxy()));
        cat.rely(address(pause.proxy()));
        dog.rely(address(pause.proxy()));
        vow.rely(address(pause.proxy()));
        jug.rely(address(pause.proxy()));
        pot.rely(address(pause.proxy()));
        spotter.rely(address(pause.proxy()));
        flap.rely(address(pause.proxy()));
        flop.rely(address(pause.proxy()));
        cure.rely(address(pause.proxy()));
        end.rely(address(pause.proxy()));
    }

    function deployESM(address gov, uint256 min) public {
        require(address(pause) != address(0), "Missing previous step");

        // Deploy ESM
        esm = esmFab.newESM(gov, address(end), address(pause.proxy()), min);
        end.rely(address(esm));
        vat.rely(address(esm));
    }

    function deployCollateralFlip(
        bytes32 ilk,
        address join,
        address pip
    ) public {
        require(ilk != bytes32(""), "Missing ilk name");
        require(join != address(0), "Missing join address");
        require(pip != address(0), "Missing pip address");
        require(address(pause) != address(0), "Missing previous step");

        // Deploy
        ilks[ilk].flip = flipFab.newFlip(
            address(this),
            address(vat),
            address(cat),
            ilk
        );
        ilks[ilk].join = join;
        Spotter(spotter).file(ilk, "pip", address(pip));
        // Set pip

        // Internal references set up
        cat.file(ilk, "flip", address(ilks[ilk].flip));
        vat.init(ilk);
        jug.init(ilk);

        // Internal auth
        vat.rely(join);
        cat.rely(address(ilks[ilk].flip));
        ilks[ilk].flip.rely(address(cat));
        ilks[ilk].flip.rely(address(end));
        ilks[ilk].flip.rely(address(esm));
        ilks[ilk].flip.rely(address(pause.proxy()));
    }

    function deployCollateralClip(
        bytes32 ilk,
        address join,
        address pip,
        address calc
    ) public {
        require(ilk != bytes32(""), "Missing ilk name");
        require(join != address(0), "Missing join address");
        require(pip != address(0), "Missing pip address");
        require(address(pause) != address(0), "Missing previous step");

        // Deploy
        ilks[ilk].clip = clipFab.newClip(
            address(this),
            address(vat),
            address(spotter),
            address(dog),
            ilk
        );
        ilks[ilk].join = join;
        Spotter(spotter).file(ilk, "pip", address(pip));
        // Set pip

        // Internal references set up
        dog.file(ilk, "clip", address(ilks[ilk].clip));
        ilks[ilk].clip.file("vow", address(vow));

        // Use calc with safe default if not configured
        if (calc == address(0)) {
            calc = address(calcFab.newLinearDecrease(address(this)));
            LinearDecrease(calc).file(bytes32("tau"), 1 hours);
        }
        ilks[ilk].clip.file("calc", calc);
        vat.init(ilk);
        jug.init(ilk);

        // Internal auth
        vat.rely(join);
        vat.rely(address(ilks[ilk].clip));
        dog.rely(address(ilks[ilk].clip));
        ilks[ilk].clip.rely(address(dog));
        ilks[ilk].clip.rely(address(end));
        ilks[ilk].clip.rely(address(esm));
        ilks[ilk].clip.rely(address(pause.proxy()));
    }
}

// Copyright (C) 2019 David Terry <[email protected]>
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

pragma solidity >=0.5.12;

interface DSAuthority {
    function canCall(
        address src,
        address dst,
        bytes4 sig
    ) external view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);
}

contract DSAuth is DSAuthEvents {
    address public authority;
    address public owner;

    modifier auth() {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig)
        internal
        view
        returns (bool)
    {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == address(0)) {
            return false;
        } else {
            return DSAuthority(authority).canCall(src, address(this), sig);
        }
    }
}

contract DSPause is DSAuth {
    // --- admin ---

    modifier wait() {
        require(msg.sender == address(proxy), "ds-pause-undelayed-call");
        _;
    }

    function setOwner(address owner_) public wait {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(address authority_) public wait {
        authority = authority_;
        emit LogSetAuthority(authority);
    }

    function setDelay(uint256 delay_) public wait {
        delay = delay_;
    }

    // --- math ---

    function addd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
        require(z >= x, "ds-pause-addition-overflow");
    }

    // --- data ---

    mapping(bytes32 => bool) public plans;
    DSPauseProxy public proxy;
    uint256 public delay;

    // --- init ---

    constructor(
        uint256 delay_,
        address owner_,
        address authority_
    ) public {
        delay = delay_;
        owner = owner_;
        authority = authority_;
        proxy = new DSPauseProxy();
    }

    // --- util ---

    function hash(
        address usr,
        bytes32 tag,
        bytes memory fax,
        uint256 eta
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(usr, tag, fax, eta));
    }

    function soul(address usr) internal view returns (bytes32 tag) {
        assembly {
            tag := extcodehash(usr)
        }
    }

    // --- operations ---

    function plot(
        address usr,
        bytes32 tag,
        bytes memory fax,
        uint256 eta
    ) public {
        require(
            eta >= addd(block.timestamp, delay),
            "ds-pause-delay-not-respected"
        );
        plans[hash(usr, tag, fax, eta)] = true;
    }

    function drop(
        address usr,
        bytes32 tag,
        bytes memory fax,
        uint256 eta
    ) public {
        plans[hash(usr, tag, fax, eta)] = false;
    }

    function exec(
        address usr,
        bytes32 tag,
        bytes memory fax,
        uint256 eta
    ) public returns (bytes memory out) {
        require(plans[hash(usr, tag, fax, eta)], "ds-pause-unplotted-plan");
        require(soul(usr) == tag, "ds-pause-wrong-codehash");
        require(block.timestamp >= eta, "ds-pause-premature-exec");

        plans[hash(usr, tag, fax, eta)] = false;

        out = proxy.exec(usr, fax);
        require(
            proxy.owner() == address(this),
            "ds-pause-illegal-storage-change"
        );
    }
}

// plans are executed in an isolated storage context to protect the pause from
// malicious storage modification during plan execution
contract DSPauseProxy {
    address public owner;
    modifier auth() {
        require(msg.sender == owner, "ds-pause-proxy-unauthorized");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function exec(address usr, bytes memory fax)
        public
        returns (bytes memory out)
    {
        bool ok;
        (ok, out) = usr.delegatecall(fax);
        require(ok, "ds-pause-delegatecall-error");
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// abaci.sol -- price decrease functions for auctions

// Copyright (C) 2020-2022 IRDT Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
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

interface Abacus {
    // 1st arg: initial price               [ray]
    // 2nd arg: seconds since auction start [seconds]
    // returns: current auction price       [ray]
    function price(uint256, uint256) external view returns (uint256);
}

contract LinearDecrease is Abacus {
    // ---  ---
    mapping(address => uint256) public wards;

    function rely(address usr) external {
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external {
        wards[usr] = 0;
        emit Deny(usr);
    }

    // --- Data ---
    uint256 public tau; // Seconds after auction start when the price reaches zero [seconds]

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    event File(bytes32 indexed what, uint256 data);

    // --- Init ---
    constructor() public {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // --- Administration ---
    function file(bytes32 what, uint256 data) external {
        if (what == "tau") tau = data;
        else revert("LinearDecrease/file-unrecognized-param");
        emit File(what, data);
    }

    // --- Math ---
    uint256 constant RAY = 10**27;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
        require(y == 0 || z / y == x);
        z = z / RAY;
    }

    // Price calculation when price is decreased linearly in proportion to time:
    // tau: The number of seconds after the start of the auction where the price will hit 0
    // top: Initial price
    // dur: current seconds since the start of the auction
    //
    // Returns y = top * ((tau - dur) / tau)
    //
    // Note the internal call to mul multiples by RAY, thereby ensuring that the rmul calculation
    // which utilizes top and tau (RAY values) is also a RAY value.
    function price(uint256 top, uint256 dur)
        external
        view
        override
        returns (uint256)
    {
        if (dur >= tau) return 0;
        return rmul(top, mul(tau - dur, RAY) / tau);
    }
}

contract StairstepExponentialDecrease is Abacus {
    // ---  ---
    mapping(address => uint256) public wards;

    function rely(address usr) external {
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external {
        wards[usr] = 0;
        emit Deny(usr);
    }

    // --- Data ---
    uint256 public step; // Length of time between price drops [seconds]
    uint256 public cut; // Per-step multiplicative factor     [ray]

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    event File(bytes32 indexed what, uint256 data);

    // --- Init ---
    // @notice: `cut` and `step` values must be correctly set for
    //     this contract to return a valid price
    constructor() public {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // --- Administration ---
    function file(bytes32 what, uint256 data) external {
        if (what == "cut")
            require(
                (cut = data) <= RAY,
                "StairstepExponentialDecrease/cut-gt-RAY"
            );
        else if (what == "step") step = data;
        else revert("StairstepExponentialDecrease/file-unrecognized-param");
        emit File(what, data);
    }

    // --- Math ---
    uint256 constant RAY = 10**27;

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
        require(y == 0 || z / y == x);
        z = z / RAY;
    }

    // optimized version from dss PR #78
    function rpow(
        uint256 x,
        uint256 n,
        uint256 b
    ) internal pure returns (uint256 z) {
        assembly {
            switch n
            case 0 {
                z := b
            }
            default {
                switch x
                case 0 {
                    z := 0
                }
                default {
                    switch mod(n, 2)
                    case 0 {
                        z := b
                    }
                    default {
                        z := x
                    }
                    let half := div(b, 2) // for rounding.
                    for {
                        n := div(n, 2)
                    } n {
                        n := div(n, 2)
                    } {
                        let xx := mul(x, x)
                        if shr(128, x) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, b)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(
                                iszero(iszero(x)),
                                iszero(eq(div(zx, x), z))
                            ) {
                                revert(0, 0)
                            }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }
                            z := div(zxRound, b)
                        }
                    }
                }
            }
        }
    }

    // top: initial price
    // dur: seconds since the auction has started
    // step: seconds between a price drop
    // cut: cut encodes the percentage to decrease per step.
    //   For efficiency, the values is set as (1 - (% value / 100)) * RAY
    //   So, for a 1% decrease per step, cut would be (1 - 0.01) * RAY
    //
    // returns: top * (cut ^ dur)
    //
    //
    function price(uint256 top, uint256 dur)
        external
        view
        override
        returns (uint256)
    {
        return rmul(top, rpow(cut, dur / step, RAY));
    }
}

// While an equivalent function can be obtained by setting step = 1 in StairstepExponentialDecrease,
// this continous (i.e. per-second) exponential decrease has be implemented as it is more gas-efficient
// than using the stairstep version with step = 1 (primarily due to 1 fewer SLOAD per price calculation).
contract ExponentialDecrease is Abacus {
    // ---  ---
    mapping(address => uint256) public wards;

    function rely(address usr) external {
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external {
        wards[usr] = 0;
        emit Deny(usr);
    }

    // --- Data ---
    uint256 public cut; // Per-second multiplicative factor [ray]

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    event File(bytes32 indexed what, uint256 data);

    // --- Init ---
    // @notice: `cut` value must be correctly set for
    //     this contract to return a valid price
    constructor() public {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // --- Administration ---
    function file(bytes32 what, uint256 data) external {
        if (what == "cut")
            require((cut = data) <= RAY, "ExponentialDecrease/cut-gt-RAY");
        else revert("ExponentialDecrease/file-unrecognized-param");
        emit File(what, data);
    }

    // --- Math ---
    uint256 constant RAY = 10**27;

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
        require(y == 0 || z / y == x);
        z = z / RAY;
    }

    // optimized version from dss PR #78
    function rpow(
        uint256 x,
        uint256 n,
        uint256 b
    ) internal pure returns (uint256 z) {
        assembly {
            switch n
            case 0 {
                z := b
            }
            default {
                switch x
                case 0 {
                    z := 0
                }
                default {
                    switch mod(n, 2)
                    case 0 {
                        z := b
                    }
                    default {
                        z := x
                    }
                    let half := div(b, 2) // for rounding.
                    for {
                        n := div(n, 2)
                    } n {
                        n := div(n, 2)
                    } {
                        let xx := mul(x, x)
                        if shr(128, x) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, b)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(
                                iszero(iszero(x)),
                                iszero(eq(div(zx, x), z))
                            ) {
                                revert(0, 0)
                            }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }
                            z := div(zxRound, b)
                        }
                    }
                }
            }
        }
    }

    // top: initial price
    // dur: seconds since the auction has started
    // cut: cut encodes the percentage to decrease per second.
    //   For efficiency, the values is set as (1 - (% value / 100)) * RAY
    //   So, for a 1% decrease per second, cut would be (1 - 0.01) * RAY
    //
    // returns: top * (cut ^ dur)
    //
    function price(uint256 top, uint256 dur)
        external
        view
        override
        returns (uint256)
    {
        return rmul(top, rpow(cut, dur, RAY));
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// cat.sol -- IRDT liquidation module

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

pragma solidity >=0.5.12;

// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

interface Kicker {
    function kick(
        address urn,
        address gal,
        uint256 tab,
        uint256 lot,
        uint256 bid
    ) external returns (uint256);
}

interface VatLike {
    function ilks(bytes32)
        external
        view
        returns (
            uint256 Art, // [wad]
            uint256 rate, // [ray]
            uint256 spot, // [ray]
            uint256 line, // [rad]
            uint256 dust // [rad]
        );

    event Rely(address indexed usr);
    event Deny(address indexed usr);

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    event File(bytes32 indexed ilk, bytes32 indexed what, uint256 data);
    event File(bytes32 indexed ilk, bytes32 indexed what, address flip);

    event Bark(
        bytes32 indexed ilk,
        address indexed urn,
        uint256 ink,
        uint256 art,
        uint256 due,
        address clip,
        uint256 indexed id
    );
    event claw(uint256 indexed rad);

    function urns(bytes32, address)
        external
        view
        returns (
            uint256 ink, // [wad]
            uint256 art // [wad]
        );

    function grab(
        bytes32,
        address,
        address,
        address,
        int256,
        int256
    ) external;

    function hope(address) external;

    function nope(address) external;
}

interface VowLike {
    function fess(uint256) external;
}

contract Cat {
    // --- Auth ---
    mapping(address => uint256) public wards;

    function rely(address usr) external {
        wards[usr] = 1;
    }

    function deny(address usr) external {
        wards[usr] = 0;
    }

    // --- Data ---
    struct Ilk {
        address flip; // Liquidator
        uint256 chop; // Liquidation Penalty  [wad]
        uint256 dunk; // Liquidation Quantity [rad]
    }

    mapping(bytes32 => Ilk) public ilks;

    uint256 public live; // Active Flag
    VatLike public vat; // CDP Engine
    VowLike public vow; // Debt Engine
    uint256 public box; // Max IRDT out for liquidation        [rad]
    uint256 public litter; // Balance of IRDT out for liquidation [rad]

    // --- Events ---
    event Bite(
        bytes32 indexed ilk,
        address indexed urn,
        uint256 ink,
        uint256 art,
        uint256 tab,
        address flip,
        uint256 id
    );
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    event File(bytes32 indexed ilk, bytes32 indexed what, uint256 data);
    event File(bytes32 indexed ilk, bytes32 indexed what, address clip);

    event Bark(
        bytes32 indexed ilk,
        address indexed urn,
        uint256 ink,
        uint256 art,
        uint256 due,
        address clip,
        uint256 indexed id
    );
    event Claw(uint256 rad);
    event Cage();

    // --- Init ---
    constructor(address vat_) public {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
        live = 1;
    }

    // --- Math ---
    uint256 constant WAD = 10**18;

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (x > y) {
            z = y;
        } else {
            z = x;
        }
    }

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    // --- Administration ---
    function file(bytes32 what, address data) external {
        if (what == "vow") vow = VowLike(data);
        else revert("Cat/file-unrecognized-param");
        emit File(what, data);
    }

    function file(bytes32 what, uint256 data) external {
        if (what == "box") box = data;
        else revert("Cat/file-unrecognized-param");
        emit File(what, data);
    }

    function file(
        bytes32 ilk,
        bytes32 what,
        uint256 data
    ) external {
        if (what == "chop") ilks[ilk].chop = data;
        else if (what == "dunk") ilks[ilk].dunk = data;
        else revert("Cat/file-unrecognized-param");
        emit File(ilk, what, data);
    }

    function file(
        bytes32 ilk,
        bytes32 what,
        address flip
    ) external {
        if (what == "flip") {
            vat.nope(ilks[ilk].flip);
            ilks[ilk].flip = flip;
            vat.hope(flip);
        } else revert("Cat/file-unrecognized-param");
        emit File(ilk, what, flip);
    }

    // --- CDP Liquidation ---
    function bite(bytes32 ilk, address urn) external returns (uint256 id) {
        (, uint256 rate, uint256 spot, , uint256 dust) = vat.ilks(ilk);
        (uint256 ink, uint256 art) = vat.urns(ilk, urn);

        require(live == 1, "Cat/not-live");
        require(spot > 0 && mul(ink, spot) < mul(art, rate), "Cat/not-unsafe");

        Ilk memory milk = ilks[ilk];
        uint256 dart;
        {
            uint256 room = sub(box, litter);

            // test whether the remaining space in the litterbox is dusty
            require(litter < box && room >= dust, "Cat/liquidation-limit-hit");

            dart = min(art, mul(min(milk.dunk, room), WAD) / rate / milk.chop);
        }

        uint256 dink = min(ink, mul(ink, dart) / art);

        require(dart > 0 && dink > 0, "Cat/null-auction");
        require(dart <= 2**255 && dink <= 2**255, "Cat/overflow");

        // This may leave the CDP in a dusty state
        vat.grab(
            ilk,
            urn,
            address(this),
            address(vow),
            -int256(dink),
            -int256(dart)
        );
        vow.fess(mul(dart, rate));

        {
            // Avoid stack too deep
            // This calcuation will overflow if dart*rate exceeds ~10^14,
            // i.e. the maximum dunk is roughly 100 trillion IRDT.
            uint256 tab = mul(mul(dart, rate), milk.chop) / WAD;
            litter = add(litter, tab);

            id = Kicker(milk.flip).kick({
                urn: urn,
                gal: address(vow),
                tab: tab,
                lot: dink,
                bid: 0
            });
        }

        emit Bite(ilk, urn, dink, dart, mul(dart, rate), milk.flip, id);
    }

    function claw(uint256 rad) external {
        litter = sub(litter, rad);
        emit Claw(rad);
    }

    function cage() external {
        live = 0;
        emit Cage();
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// clip.sol -- IRDT auction module 2.0

// Copyright (C) 2020-2022 IRDT Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
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

interface VatLike {
    function move(
        address,
        address,
        uint256
    ) external;

    function flux(
        bytes32,
        address,
        address,
        uint256
    ) external;

    function ilks(bytes32)
        external
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function suck(
        address,
        address,
        uint256
    ) external;
}

interface PipLike {
    function peek() external returns (bytes32, bool);
}

interface SpotterLike {
    function par() external returns (uint256);

    function ilks(bytes32) external returns (PipLike, uint256);
}

interface DogLike {
    function chop(bytes32) external returns (uint256);

    function digs(bytes32, uint256) external;
}

interface ClipperCallee {
    function clipperCall(
        address,
        uint256,
        uint256,
        bytes calldata
    ) external;
}

interface AbacusLike {
    function price(uint256, uint256) external view returns (uint256);
}

contract Clipper {
    // --- Auth ---
    mapping(address => uint256) public wards;

    function rely(address usr) external {
        wards[usr] = 1;
    }

    // --- Data ---
    bytes32 public immutable ilk; // Collateral type of this Clipper
    VatLike public immutable vat; // Core CDP Engine

    DogLike public dog; // Liquidation module
    address public vow; // Recipient of IRDT raised in auctions
    SpotterLike public spotter; // Collateral price module
    AbacusLike public calc; // Current price calculator

    uint256 public buf; // Multiplicative factor to increase starting price                  [ray]
    uint256 public tail; // Time elapsed before auction reset                                 [seconds]
    uint256 public cusp; // Percentage drop before auction reset                              [ray]
    uint64 public chip; // Percentage of tab to suck from vow to incentivize keepers         [wad]
    uint192 public tip; // Flat fee to suck from vow to incentivize keepers                  [rad]
    uint256 public chost; // Cache the ilk dust times the ilk chop to prevent excessive SLOADs [rad]

    uint256 public kicks; // Total auctions
    uint256[] public active; // Array of active auction ids

    struct Sale {
        uint256 pos; // Index in active array
        uint256 tab; // IRDT to raise       [rad]
        uint256 lot; // collateral to sell [wad]
        address usr; // Liquidated CDP
        uint96 tic; // Auction start time
        uint256 top; // Starting price     [ray]
    }
    mapping(uint256 => Sale) public sales;

    uint256 internal locked;

    // Levels for circuit breaker
    // 0: no breaker
    // 1: no new kick()
    // 2: no new kick() or redo()
    // 3: no new kick(), redo(), or take()
    uint256 public stopped = 0;

    // --- Init ---
    constructor(
        address vat_,
        address spotter_,
        address dog_,
        bytes32 ilk_
    ) public {
        vat = VatLike(vat_);
        spotter = SpotterLike(spotter_);
        dog = DogLike(dog_);
        ilk = ilk_;
        buf = RAY;
        wards[msg.sender] = 1;
    }

    // --- Synchronization ---
    modifier lock() {
        require(locked == 0, "Clipper/system-locked");
        locked = 1;
        _;
        locked = 0;
    }

    modifier isStopped(uint256 level) {
        require(stopped < level, "Clipper/stopped-incorrect");
        _;
    }

    // --- Administration ---
    function file(bytes32 what, uint256 data) external lock {
        if (what == "buf") buf = data;
        else if (what == "tail")
            tail = data; // Time elapsed before auction reset
        else if (what == "cusp")
            cusp = data; // Percentage drop before auction reset
        else if (what == "chip")
            chip = uint64(data); // Percentage of tab to incentivize (max: 2^64 - 1 => 18.xxx WAD = 18xx%)
        else if (what == "tip")
            tip = uint192(data); // Flat fee to incentivize keepers (max: 2^192 - 1 => 6.277T RAD)
        else if (what == "stopped")
            stopped = data; // Set breaker (0, 1, 2, or 3)
        else revert("Clipper/file-unrecognized-param");
    }

    function file(bytes32 what, address data) external lock {
        if (what == "spotter") spotter = SpotterLike(data);
        else if (what == "dog") dog = DogLike(data);
        else if (what == "vow") vow = data;
        else if (what == "calc") calc = AbacusLike(data);
        else revert("Clipper/file-unrecognized-param");
    }

    // --- Math ---
    uint256 constant BLN = 10**9;
    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x <= y ? x : y;
    }

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, y) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, y) / RAY;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, RAY) / y;
    }

    // --- Auction ---

    // get the price directly from the OSM
    // Could get this from rmul(Vat.ilks(ilk).spot, Spotter.mat()) instead, but
    // if mat has changed since the last poke, the resulting value will be
    // incorrect.
    function getFeedPrice() internal returns (uint256 feedPrice) {
        (PipLike pip, ) = spotter.ilks(ilk);
        (bytes32 val, bool has) = pip.peek();
        require(has, "Clipper/invalid-price");
        feedPrice = rdiv(mul(uint256(val), BLN), spotter.par());
    }

    // start an auction
    // note: trusts the caller to transfer collateral to the contract
    // The starting price `top` is obtained as follows:
    //
    //     top = val * buf / par
    //
    // Where `val` is the collateral's unitary value in USD, `buf` is a
    // multiplicative factor to increase the starting price, and `par` is a
    // reference per IRDT.
    function kick(
        uint256 tab, // Debt                   [rad]
        uint256 lot, // Collateral             [wad]
        address usr, // Address that will receive any leftover collateral
        address kpr // Address that will receive incentives
    ) external lock isStopped(1) returns (uint256 id) {
        // Input validation
        require(tab > 0, "Clipper/zero-tab");
        require(lot > 0, "Clipper/zero-lot");
        require(usr != address(0), "Clipper/zero-usr");
        id = ++kicks;
        require(id > 0, "Clipper/overflow");

        active.push(id);

        sales[id].pos = active.length - 1;

        sales[id].tab = tab;
        sales[id].lot = lot;
        sales[id].usr = usr;
        sales[id].tic = uint96(block.timestamp);

        uint256 top;
        top = rmul(getFeedPrice(), buf);
        require(top > 0, "Clipper/zero-top-price");
        sales[id].top = top;

        // incentive to kick auction
        uint256 _tip = tip;
        uint256 _chip = chip;
        uint256 coin;
        if (_tip > 0 || _chip > 0) {
            coin = add(_tip, wmul(tab, _chip));
            vat.suck(vow, kpr, coin);
        }
    }

    // Reset an auction
    // See `kick` above for an explanation of the computation of `top`.
    function redo(
        uint256 id, // id of the auction to reset
        address kpr // Address that will receive incentives
    ) external lock isStopped(2) {
        // Read auction data
        address usr = sales[id].usr;
        uint96 tic = sales[id].tic;
        uint256 top = sales[id].top;

        require(usr != address(0), "Clipper/not-running-auction");

        // Check that auction needs reset
        // and compute current price [ray]
        (bool done, ) = status(tic, top);
        require(done, "Clipper/cannot-reset");

        uint256 tab = sales[id].tab;
        uint256 lot = sales[id].lot;
        sales[id].tic = uint96(block.timestamp);

        uint256 feedPrice = getFeedPrice();
        top = rmul(feedPrice, buf);
        require(top > 0, "Clipper/zero-top-price");
        sales[id].top = top;

        // incentive to redo auction
        uint256 _tip = tip;
        uint256 _chip = chip;
        uint256 coin;
        if (_tip > 0 || _chip > 0) {
            uint256 _chost = chost;
            if (tab >= _chost && mul(lot, feedPrice) >= _chost) {
                coin = add(_tip, wmul(tab, _chip));
                vat.suck(vow, kpr, coin);
            }
        }
    }

    // Buy up to `amt` of collateral from the auction indexed by `id`.
    //
    // Auctions will not collect more IRDT than their assigned IRDT target,`tab`;
    // thus, if `amt` would cost more IRDT than `tab` at the current price, the
    // amount of collateral purchased will instead be just enough to collect `tab` IRDT.
    //
    // To avoid partial purchases resulting in very small leftover auctions that will
    // never be cleared, any partial purchase must leave at least `Clipper.chost`
    // remaining IRDT target. `chost` is an asynchronously updated value equal to
    // (Vat.dust * Dog.chop(ilk) / WAD) where the values are understood to be determined
    // by whatever they were when Clipper.upchost() was last called. Purchase amounts
    // will be minimally decreased when necessary to respect this limit; i.e., if the
    // specified `amt` would leave `tab < chost` but `tab > 0`, the amount actually
    // purchased will be such that `tab == chost`.
    //
    // If `tab <= chost`, partial purchases are no longer possible; that is, the remaining
    // collateral can only be purchased entirely, or not at all.
    function take(
        uint256 id, // Auction id
        uint256 amt, // Upper limit on amount of collateral to buy  [wad]
        uint256 max, // Maximum acceptable price (IRDT / collateral) [ray]
        address who, // Receiver of collateral and external call address
        bytes calldata data // Data to pass in external call; if length 0, no call is done
    ) external lock isStopped(3) {
        address usr = sales[id].usr;
        uint96 tic = sales[id].tic;

        require(usr != address(0), "Clipper/not-running-auction");

        uint256 price;
        {
            bool done;
            (done, price) = status(tic, sales[id].top);

            // Check that auction doesn't need reset
            require(!done, "Clipper/needs-reset");
        }

        // Ensure price is acceptable to buyer
        require(max >= price, "Clipper/too-expensive");

        uint256 lot = sales[id].lot;
        uint256 tab = sales[id].tab;
        uint256 owe;

        {
            // Purchase as much as possible, up to amt
            uint256 slice = min(lot, amt); // slice <= lot

            // IRDT needed to buy a slice of this sale
            owe = mul(slice, price);

            // Don't collect more than tab of IRDT
            if (owe > tab) {
                // Total debt will be paid
                owe = tab; // owe' <= owe
                // Adjust slice
                slice = owe / price; // slice' = owe' / price <= owe / price == slice <= lot
            } else if (owe < tab && slice < lot) {
                // If slice == lot => auction completed => dust doesn't matter
                uint256 _chost = chost;
                if (tab - owe < _chost) {
                    // safe as owe < tab
                    // If tab <= chost, buyers have to take the entire lot.
                    require(tab > _chost, "Clipper/no-partial-purchase");
                    // Adjust amount to pay
                    owe = tab - _chost; // owe' <= owe
                    // Adjust slice
                    slice = owe / price; // slice' = owe' / price < owe / price == slice < lot
                }
            }

            // Calculate remaining tab after operation
            tab = tab - owe; // safe since owe <= tab
            // Calculate remaining lot after operation
            lot = lot - slice;

            // Send collateral to who
            vat.flux(ilk, address(this), who, slice);

            // Do external call (if data is defined) but to be
            // extremely careful we don't allow to do it to the two
            // contracts which the Clipper needs to be authorized
            DogLike dog_ = dog;
            if (
                data.length > 0 && who != address(vat) && who != address(dog_)
            ) {
                ClipperCallee(who).clipperCall(msg.sender, owe, slice, data);
            }

            // Get IRDT from caller
            vat.move(msg.sender, vow, owe);

            // Removes IRDT out for liquidation from accumulator
            dog_.digs(ilk, lot == 0 ? tab + owe : owe);
        }

        if (lot == 0) {
            _remove(id);
        } else if (tab == 0) {
            vat.flux(ilk, address(this), usr, lot);
            _remove(id);
        } else {
            sales[id].tab = tab;
            sales[id].lot = lot;
        }
    }

    function _remove(uint256 id) internal {
        uint256 _move = active[active.length - 1];
        if (id != _move) {
            uint256 _index = sales[id].pos;
            active[_index] = _move;
            sales[_move].pos = _index;
        }
        active.pop();
        delete sales[id];
    }

    // The number of active auctions
    function count() external view returns (uint256) {
        return active.length;
    }

    // Return the entire array of active auctions
    function list() external view returns (uint256[] memory) {
        return active;
    }

    // Externally returns boolean for if an auction needs a redo and also the current price
    function getStatus(uint256 id)
        external
        view
        returns (
            bool needsRedo,
            uint256 price,
            uint256 lot,
            uint256 tab
        )
    {
        // Read auction data
        address usr = sales[id].usr;
        uint96 tic = sales[id].tic;

        bool done;
        (done, price) = status(tic, sales[id].top);

        needsRedo = usr != address(0) && done;
        lot = sales[id].lot;
        tab = sales[id].tab;
    }

    // Internally returns boolean for if an auction needs a redo
    function status(uint96 tic, uint256 top)
        internal
        view
        returns (bool done, uint256 price)
    {
        price = calc.price(top, sub(block.timestamp, tic));
        done = (sub(block.timestamp, tic) > tail || rdiv(price, top) < cusp);
    }

    // Public function to update the cached dust*chop value.
    function upchost() external {
        (, , , , uint256 _dust) = VatLike(vat).ilks(ilk);
        chost = wmul(_dust, dog.chop(ilk));
    }

    // Cancel an auction during ES or via governance action.
    function yank(uint256 id) external lock {
        require(sales[id].usr != address(0), "Clipper/not-running-auction");
        dog.digs(ilk, sales[id].tab);
        vat.flux(ilk, address(this), msg.sender, sales[id].lot);
        _remove(id);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// cure.sol -- Debt Rectifier contract

// Copyright (C) 2022 IRDT Foundation
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

pragma solidity >=0.6.12;

interface SourceLike {
    function cure() external view returns (uint256);
}

contract Cure {
    mapping(address => uint256) public wards;
    uint256 public live;
    address[] public srcs;
    uint256 public wait;
    uint256 public when;
    mapping(address => uint256) public pos; // position in srcs + 1, 0 means a source does not exist
    mapping(address => uint256) public amt;
    mapping(address => uint256) public loaded;
    uint256 public lCount;
    uint256 public say;

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event File(bytes32 indexed what, uint256 data);
    event Lift(address indexed src);
    event Drop(address indexed src);
    event Load(address indexed src);
    event Cage();

    // --- Internal ---
    function _add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "Cure/add-overflow");
    }

    function _sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "Cure/sub-underflow");
    }

    constructor() public {
        live = 1;
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    function tCount() external view returns (uint256 count_) {
        count_ = srcs.length;
    }

    function list() external view returns (address[] memory) {
        return srcs;
    }

    function tell() external view returns (uint256) {
        require(
            live == 0 && (lCount == srcs.length || block.timestamp >= when),
            "Cure/missing-load-and-time-not-passed"
        );
        return say;
    }

    function rely(address usr) external {
        require(live == 1, "Cure/not-live");
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external {
        require(live == 1, "Cure/not-live");
        wards[usr] = 0;
        emit Deny(usr);
    }

    function file(bytes32 what, uint256 data) external {
        require(live == 1, "Cure/not-live");
        if (what == "wait") wait = data;
        else revert("Cure/file-unrecognized-param");
        emit File(what, data);
    }

    function lift(address src) external {
        require(live == 1, "Cure/not-live");
        require(pos[src] == 0, "Cure/already-existing-source");
        srcs.push(src);
        pos[src] = srcs.length;
        emit Lift(src);
    }

    function drop(address src) external {
        require(live == 1, "Cure/not-live");
        uint256 pos_ = pos[src];
        require(pos_ > 0, "Cure/non-existing-source");
        uint256 last = srcs.length;
        if (pos_ < last) {
            address move = srcs[last - 1];
            srcs[pos_ - 1] = move;
            pos[move] = pos_;
        }
        srcs.pop();
        delete pos[src];
        delete amt[src];
        emit Drop(src);
    }

    function cage() external {
        require(live == 1, "Cure/not-live");
        live = 0;
        when = _add(block.timestamp, wait);
        emit Cage();
    }

    function load(address src) external {
        require(live == 0, "Cure/still-live");
        require(pos[src] > 0, "Cure/non-existing-source");
        uint256 oldAmt_ = amt[src];
        uint256 newAmt_ = amt[src] = SourceLike(src).cure();
        say = _add(_sub(say, oldAmt_), newAmt_);
        if (loaded[src] == 0) {
            loaded[src] = 1;
            lCount++;
        }
        emit Load(src);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// dog.sol -- IRDT liquidation module 2.0

// Copyright (C) 2020-2022 IRDT Foundation
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

interface ClipperLike {
    function ilk() external view returns (bytes32);

    function kick(
        uint256 tab,
        uint256 lot,
        address usr,
        address kpr
    ) external returns (uint256);
}

interface VatLike {
    function ilks(bytes32)
        external
        view
        returns (
            uint256 Art, // [wad]
            uint256 rate, // [ray]
            uint256 spot, // [ray]
            uint256 line, // [rad]
            uint256 dust // [rad]
        );

    function urns(bytes32, address)
        external
        view
        returns (
            uint256 ink, // [wad]
            uint256 art // [wad]
        );

    function grab(
        bytes32,
        address,
        address,
        address,
        int256,
        int256
    ) external;

    function hope(address) external;

    function nope(address) external;
}

interface VowLike {
    function fess(uint256) external;
}

contract Dog {
    // --- Auth ---
    mapping(address => uint256) public wards;

    function rely(address usr) external {
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external {
        wards[usr] = 0;
        emit Deny(usr);
    }

    // --- Data ---
    struct Ilk {
        address clip; // Liquidator
        uint256 chop; // Liquidation Penalty                                          [wad]
        uint256 hole; // Max IRDT needed to cover debt+fees of active auctions per ilk [rad]
        uint256 dirt; // Amt IRDT needed to cover debt+fees of active auctions per ilk [rad]
    }

    VatLike public immutable vat; // CDP Engine

    mapping(bytes32 => Ilk) public ilks;

    VowLike public vow; // Debt Engine
    uint256 public live; // Active Flag
    uint256 public Hole; // Max IRDT needed to cover debt+fees of active auctions [rad]
    uint256 public Dirt; // Amt IRDT needed to cover debt+fees of active auctions [rad]

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    event File(bytes32 indexed ilk, bytes32 indexed what, uint256 data);
    event File(bytes32 indexed ilk, bytes32 indexed what, address clip);

    event Bark(
        bytes32 indexed ilk,
        address indexed urn,
        uint256 ink,
        uint256 art,
        uint256 due,
        address clip,
        uint256 indexed id
    );
    event Digs(bytes32 indexed ilk, uint256 rad);
    event Cage();

    // --- Init ---
    constructor(address vat_) public {
        vat = VatLike(vat_);
        live = 1;
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // --- Math ---
    uint256 constant WAD = 10**18;

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x <= y ? x : y;
    }

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    // --- Administration ---
    function file(bytes32 what, address data) external {
        if (what == "vow") vow = VowLike(data);
        else revert("Dog/file-unrecognized-param");
        emit File(what, data);
    }

    function file(bytes32 what, uint256 data) external {
        if (what == "Hole") Hole = data;
        else revert("Dog/file-unrecognized-param");
        emit File(what, data);
    }

    function file(
        bytes32 ilk,
        bytes32 what,
        uint256 data
    ) external {
        if (what == "chop") {
            require(data >= WAD, "Dog/file-chop-lt-WAD");
            ilks[ilk].chop = data;
        } else if (what == "hole") ilks[ilk].hole = data;
        else revert("Dog/file-unrecognized-param");
        emit File(ilk, what, data);
    }

    function file(
        bytes32 ilk,
        bytes32 what,
        address clip
    ) external {
        if (what == "clip") {
            require(
                ilk == ClipperLike(clip).ilk(),
                "Dog/file-ilk-neq-clip.ilk"
            );
            ilks[ilk].clip = clip;
        } else revert("Dog/file-unrecognized-param");
        emit File(ilk, what, clip);
    }

    function chop(bytes32 ilk) external view returns (uint256) {
        return ilks[ilk].chop;
    }

    // --- CDP Liquidation: all bark and no bite ---
    //
    // Liquidate a Vault and start a Dutch auction to sell its collateral for IRDT.
    //
    // The third argument is the address that will receive the liquidation reward, if any.
    //
    // The entire Vault will be liquidated except when the target amount of IRDT to be raised in
    // the resulting auction (debt of Vault + liquidation penalty) causes either Dirt to exceed
    // Hole or ilk.dirt to exceed ilk.hole by an economically significant amount. In that
    // case, a partial liquidation is performed to respect the global and per-ilk limits on
    // outstanding IRDT target. The one exception is if the resulting auction would likely
    // have too little collateral to be interesting to Keepers (debt taken from Vault < ilk.dust),
    // in which case the function reverts. Please refer to the code and comments within if
    // more detail is desired.
    function bark(
        bytes32 ilk,
        address urn,
        address kpr
    ) external returns (uint256 id) {
        require(live == 1, "Dog/not-live");

        (uint256 ink, uint256 art) = vat.urns(ilk, urn);
        Ilk memory milk = ilks[ilk];
        uint256 dart;
        uint256 rate;
        uint256 dust;
        {
            uint256 spot;
            (, rate, spot, , dust) = vat.ilks(ilk);
            require(
                spot > 0 && mul(ink, spot) < mul(art, rate),
                "Dog/not-unsafe"
            );

            // Get the minimum value between:
            // 1) Remaining space in the general Hole
            // 2) Remaining space in the collateral hole
            require(
                Hole > Dirt && milk.hole > milk.dirt,
                "Dog/liquidation-limit-hit"
            );
            uint256 room = min(Hole - Dirt, milk.hole - milk.dirt);

            // uint256.max()/(RAD*WAD) = 115,792,089,237,316
            dart = min(art, mul(room, WAD) / rate / milk.chop);

            // Partial liquidation edge case logic
            if (art > dart) {
                if (mul(art - dart, rate) < dust) {
                    // If the leftover Vault would be dusty, just liquidate it entirely.
                    // This will result in at least one of dirt_i > hole_i or Dirt > Hole becoming true.
                    // The amount of excess will be bounded above by ceiling(dust_i * chop_i / WAD).
                    // This deviation is assumed to be small compared to both hole_i and Hole, so that
                    // the extra amount of target IRDT over the limits intended is not of economic concern.
                    dart = art;
                } else {
                    // In a partial liquidation, the resulting auction should also be non-dusty.
                    require(
                        mul(dart, rate) >= dust,
                        "Dog/dusty-auction-from-partial-liquidation"
                    );
                }
            }
        }

        uint256 dink = mul(ink, dart) / art;

        require(dink > 0, "Dog/null-auction");
        require(dart <= 2**255 && dink <= 2**255, "Dog/overflow");

        vat.grab(
            ilk,
            urn,
            milk.clip,
            address(vow),
            -int256(dink),
            -int256(dart)
        );

        uint256 due = mul(dart, rate);
        vow.fess(due);

        {
            // Avoid stack too deep
            // This calcuation will overflow if dart*rate exceeds ~10^14
            uint256 tab = mul(due, milk.chop) / WAD;
            Dirt = add(Dirt, tab);
            ilks[ilk].dirt = add(milk.dirt, tab);

            id = ClipperLike(milk.clip).kick({
                tab: tab,
                lot: dink,
                usr: urn,
                kpr: kpr
            });
        }

        emit Bark(ilk, urn, dink, dart, due, milk.clip, id);
    }

    function digs(bytes32 ilk, uint256 rad) external {
        Dirt = sub(Dirt, rad);
        ilks[ilk].dirt = sub(ilks[ilk].dirt, rad);
        emit Digs(ilk, rad);
    }

    function cage() external {
        live = 0;
        emit Cage();
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// end.sol -- global settlement engine

// Copyright (C) 2018 Rain <[email protected]>
// Copyright (C) 2018 Lev Livnev <[email protected]>
// Copyright (C) 2020-2021 IRDT Foundation
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

interface VatLike {
    function irdt(address) external view returns (uint256);

    function ilks(bytes32 ilk)
        external
        returns (
            uint256 Art, // [wad]
            uint256 rate, // [ray]
            uint256 spot, // [ray]
            uint256 line, // [rad]
            uint256 dust // [rad]
        );

    function urns(bytes32 ilk, address urn)
        external
        returns (
            uint256 ink, // [wad]
            uint256 art // [wad]
        );

    function debt() external returns (uint256);

    function move(
        address src,
        address dst,
        uint256 rad
    ) external;

    function hope(address) external;

    function flux(
        bytes32 ilk,
        address src,
        address dst,
        uint256 rad
    ) external;

    function grab(
        bytes32 i,
        address u,
        address v,
        address w,
        int256 dink,
        int256 dart
    ) external;

    function suck(
        address u,
        address v,
        uint256 rad
    ) external;

    function cage() external;
}

interface CatLike {
    function ilks(bytes32)
        external
        returns (
            address flip,
            uint256 chop, // [ray]
            uint256 lump // [rad]
        );

    function cage() external;
}

interface DogLike {
    function ilks(bytes32)
        external
        returns (
            address clip,
            uint256 chop,
            uint256 hole,
            uint256 dirt
        );

    function cage() external;
}

interface PotLike {
    function cage() external;
}

interface VowLike {
    function cage() external;
}

interface FlipLike {
    function bids(uint256 id)
        external
        view
        returns (
            uint256 bid, // [rad]
            uint256 lot, // [wad]
            address guy,
            uint48 tic, // [unix epoch time]
            uint48 end, // [unix epoch time]
            address usr,
            address gal,
            uint256 tab // [rad]
        );

    function yank(uint256 id) external;
}

interface ClipLike {
    function sales(uint256 id)
        external
        view
        returns (
            uint256 pos,
            uint256 tab,
            uint256 lot,
            address usr,
            uint96 tic,
            uint256 top
        );

    function yank(uint256 id) external;
}

interface PipLike {
    function read() external view returns (bytes32);
}

interface SpotLike {
    function par() external view returns (uint256);

    function ilks(bytes32)
        external
        view
        returns (
            PipLike pip,
            uint256 mat // [ray]
        );

    function cage() external;
}

interface CureLike {
    function tell() external view returns (uint256);

    function cage() external;
}

/*
    This is the `End` and it coordinates Global Settlement. This is an
    involved, stateful process that takes place over nine steps.

    First we freeze the system and lock the prices for each ilk.

    1. `cage()`:
        - freezes user entrypoints
        - cancels flop/flap auctions
        - starts cooldown period
        - stops pot drips

    2. `cage(ilk)`:
       - set the cage price for each `ilk`, reading off the price feed

    We must process some system state before it is possible to calculate
    the final irdt / collateral price. In particular, we need to determine

      a. `gap`, the collateral shortfall per collateral type by
         considering under-collateralised CDPs.

      b. `debt`, the outstanding irdt supply after including system
         surplus / deficit

    We determine (a) by processing all under-collateralised CDPs with
    `skim`:

    3. `skim(ilk, urn)`:
       - cancels CDP debt
       - any excess collateral remains
       - backing collateral taken

    We determine (b) by processing ongoing irdt generating processes,
    i.e. auctions. We need to ensure that auctions will not generate any
    further irdt income.

    In the two-way auction model (Flipper) this occurs when
    all auctions are in the reverse (`dent`) phase. There are two ways
    of ensuring this:

    4a. i) `wait`: set the cooldown period to be at least as long as the
           longest auction duration, which needs to be determined by the
           cage administrator.

           This takes a fairly predictable time to occur but with altered
           auction dynamics due to the now varying price of irdt.

       ii) `skip`: cancel all ongoing auctions and seize the collateral.

           This allows for faster processing at the expense of more
           processing calls. This option allows irdt holders to retrieve
           their collateral faster.

           `skip(ilk, id)`:
            - cancel individual flip auctions in the `tend` (forward) phase
            - retrieves collateral and debt (including penalty) to owner's CDP
            - returns irdt to last bidder
            - `dent` (reverse) phase auctions can continue normally

    Option (i), `wait`, is sufficient (if all auctions were bidded at least
    once) for processing the system settlement but option (ii), `skip`,
    will speed it up. Both options are available in this implementation,
    with `skip` being enabled on a per-auction basis.

    In the case of the Dutch Auctions model (Clipper) they keep recovering
    debt during the whole lifetime and there isn't a max duration time
    guaranteed for the auction to end.
    So the way to ensure the protocol will not receive extra irdt income is:

    4b. i) `snip`: cancel all ongoing auctions and seize the collateral.

           `snip(ilk, id)`:
            - cancel individual running clip auctions
            - retrieves remaining collateral and debt (including penalty)
              to owner's CDP

    When a CDP has been processed and has no debt remaining, the
    remaining collateral can be removed.

    5. `free(ilk)`:
        - remove collateral from the caller's CDP
        - owner can call as needed

    After the processing period has elapsed, we enable calculation of
    the final price for each collateral type.

    6. `thaw()`:
       - only callable after processing time period elapsed
       - assumption that all under-collateralised CDPs are processed
       - fixes the total outstanding supply of irdt
       - may also require extra CDP processing to cover vow surplus

    7. `flow(ilk)`:
        - calculate the `fix`, the cash price for a given ilk
        - adjusts the `fix` in the case of deficit / surplus

    At this point we have computed the final price for each collateral
    type and irdt holders can now turn their irdt into collateral. Each
    unit irdt can claim a fixed basket of collateral.

    irdt holders must first `pack` some irdt into a `bag`. Once packed,
    irdt cannot be unpacked and is not transferrable. More irdt can be
    added to a bag later.

    8. `pack(wad)`:
        - put some irdt into a bag in preparation for `cash`

    Finally, collateral can be obtained with `cash`. The bigger the bag,
    the more collateral can be released.

    9. `cash(ilk, wad)`:
        - exchange some irdt from your bag for gems from a specific ilk
        - the number of gems is limited by how big your bag is
*/

contract End {
    // ---  ---
    mapping(address => uint256) public wards;

    function rely(address usr) external {
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external {
        wards[usr] = 0;
        emit Deny(usr);
    }

    // --- Data ---
    VatLike public vat; // CDP Engine
    CatLike public cat;
    DogLike public dog;
    VowLike public vow; // Debt Engine
    PotLike public pot;
    SpotLike public spot;
    CureLike public cure;

    uint256 public live; // Active Flag
    uint256 public when; // Time of cage                   [unix epoch time]
    uint256 public wait; // Processing Cooldown Length             [seconds]
    uint256 public debt; // Total outstanding irdt following processing [rad]

    mapping(bytes32 => uint256) public tag; // Cage price              [ray]
    mapping(bytes32 => uint256) public gap; // Collateral shortfall    [wad]
    mapping(bytes32 => uint256) public Art; // Total debt per ilk      [wad]
    mapping(bytes32 => uint256) public fix; // Final cash price        [ray]

    mapping(address => uint256) public bag; //    [wad]
    mapping(bytes32 => mapping(address => uint256)) public out; //    [wad]

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);

    event Cage();
    event Cage(bytes32 indexed ilk);
    event Snip(
        bytes32 indexed ilk,
        uint256 indexed id,
        address indexed usr,
        uint256 tab,
        uint256 lot,
        uint256 art
    );
    event Skip(
        bytes32 indexed ilk,
        uint256 indexed id,
        address indexed usr,
        uint256 tab,
        uint256 lot,
        uint256 art
    );
    event Skim(
        bytes32 indexed ilk,
        address indexed urn,
        uint256 wad,
        uint256 art
    );
    event Free(bytes32 indexed ilk, address indexed usr, uint256 ink);
    event Thaw();
    event Flow(bytes32 indexed ilk);
    event Pack(address indexed usr, uint256 wad);
    event Cash(bytes32 indexed ilk, address indexed usr, uint256 wad);

    // --- Init ---
    constructor() public {
        wards[msg.sender] = 1;
        live = 1;
        emit Rely(msg.sender);
    }

    // --- Math ---
    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
        require(z >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, y) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, WAD) / y;
    }

    // --- Administration ---
    function file(bytes32 what, address data) external {
        require(live == 1, "End/not-live");
        if (what == "vat") vat = VatLike(data);
        else if (what == "cat") cat = CatLike(data);
        else if (what == "dog") dog = DogLike(data);
        else if (what == "vow") vow = VowLike(data);
        else if (what == "pot") pot = PotLike(data);
        else if (what == "spot") spot = SpotLike(data);
        else if (what == "cure") cure = CureLike(data);
        else revert("End/file-unrecognized-param");
        emit File(what, data);
    }

    function file(bytes32 what, uint256 data) external {
        require(live == 1, "End/not-live");
        if (what == "wait") wait = data;
        else revert("End/file-unrecognized-param");
        emit File(what, data);
    }

    // --- Settlement ---
    function cage() external {
        require(live == 1, "End/not-live");
        live = 0;
        when = block.timestamp;
        vat.cage();
        cat.cage();
        dog.cage();
        vow.cage();
        spot.cage();
        pot.cage();
        cure.cage();
        emit Cage();
    }

    function cage(bytes32 ilk) external {
        require(live == 0, "End/still-live");
        require(tag[ilk] == 0, "End/tag-ilk-already-defined");
        (Art[ilk], , , , ) = vat.ilks(ilk);
        (PipLike pip, ) = spot.ilks(ilk);
        // par is a ray, pip returns a wad
        tag[ilk] = wdiv(spot.par(), uint256(pip.read()));
        emit Cage(ilk);
    }

    function snip(bytes32 ilk, uint256 id) external {
        require(tag[ilk] != 0, "End/tag-ilk-not-defined");

        (address _clip, , , ) = dog.ilks(ilk);
        ClipLike clip = ClipLike(_clip);
        (, uint256 rate, , , ) = vat.ilks(ilk);
        (, uint256 tab, uint256 lot, address usr, , ) = clip.sales(id);

        vat.suck(address(vow), address(vow), tab);
        clip.yank(id);

        uint256 art = tab / rate;
        Art[ilk] = add(Art[ilk], art);
        require(int256(lot) >= 0 && int256(art) >= 0, "End/overflow");
        vat.grab(
            ilk,
            usr,
            address(this),
            address(vow),
            int256(lot),
            int256(art)
        );
        emit Snip(ilk, id, usr, tab, lot, art);
    }

    function skip(bytes32 ilk, uint256 id) external {
        require(tag[ilk] != 0, "End/tag-ilk-not-defined");

        (address _flip, , ) = cat.ilks(ilk);
        FlipLike flip = FlipLike(_flip);
        (, uint256 rate, , , ) = vat.ilks(ilk);
        (uint256 bid, uint256 lot, , , , address usr, , uint256 tab) = flip
            .bids(id);

        vat.suck(address(vow), address(vow), tab);
        vat.suck(address(vow), address(this), bid);
        vat.hope(address(flip));
        flip.yank(id);

        uint256 art = tab / rate;
        Art[ilk] = add(Art[ilk], art);
        require(int256(lot) >= 0 && int256(art) >= 0, "End/overflow");
        vat.grab(
            ilk,
            usr,
            address(this),
            address(vow),
            int256(lot),
            int256(art)
        );
        emit Skip(ilk, id, usr, tab, lot, art);
    }

    function skim(bytes32 ilk, address urn) external {
        require(tag[ilk] != 0, "End/tag-ilk-not-defined");
        (, uint256 rate, , , ) = vat.ilks(ilk);
        (uint256 ink, uint256 art) = vat.urns(ilk, urn);

        uint256 owe = rmul(rmul(art, rate), tag[ilk]);
        uint256 wad = min(ink, owe);
        gap[ilk] = add(gap[ilk], sub(owe, wad));

        require(wad <= 2**255 && art <= 2**255, "End/overflow");
        vat.grab(
            ilk,
            urn,
            address(this),
            address(vow),
            -int256(wad),
            -int256(art)
        );
        emit Skim(ilk, urn, wad, art);
    }

    function free(bytes32 ilk) external {
        require(live == 0, "End/still-live");
        (uint256 ink, uint256 art) = vat.urns(ilk, msg.sender);
        require(art == 0, "End/art-not-zero");
        require(ink <= 2**255, "End/overflow");
        vat.grab(ilk, msg.sender, msg.sender, address(vow), -int256(ink), 0);
        emit Free(ilk, msg.sender, ink);
    }

    function thaw() external {
        require(live == 0, "End/still-live");
        require(debt == 0, "End/debt-not-zero");
        require(vat.irdt(address(vow)) == 0, "End/surplus-not-zero");
        require(block.timestamp >= add(when, wait), "End/wait-not-finished");
        debt = sub(vat.debt(), cure.tell());
        emit Thaw();
    }

    function flow(bytes32 ilk) external {
        require(debt != 0, "End/debt-zero");
        require(fix[ilk] == 0, "End/fix-ilk-already-defined");

        (, uint256 rate, , , ) = vat.ilks(ilk);
        uint256 wad = rmul(rmul(Art[ilk], rate), tag[ilk]);
        fix[ilk] = mul(sub(wad, gap[ilk]), RAY) / (debt / RAY);
        emit Flow(ilk);
    }

    function pack(uint256 wad) external {
        require(debt != 0, "End/debt-zero");
        vat.move(msg.sender, address(vow), mul(wad, RAY));
        bag[msg.sender] = add(bag[msg.sender], wad);
        emit Pack(msg.sender, wad);
    }

    function cash(bytes32 ilk, uint256 wad) external {
        require(fix[ilk] != 0, "End/fix-ilk-not-defined");
        vat.flux(ilk, address(this), msg.sender, rmul(wad, fix[ilk]));
        out[ilk][msg.sender] = add(out[ilk][msg.sender], wad);
        require(
            out[ilk][msg.sender] <= bag[msg.sender],
            "End/insufficient-bag-balance"
        );
        emit Cash(ilk, msg.sender, wad);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// flap.sol -- Surplus auction

// Copyright (C) 2018 Rain <[email protected]>
// Copyright (C) 2022 irdt Foundation
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

// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

interface VatLike {
    function move(
        address,
        address,
        uint256
    ) external;
}

interface GemLike {
    function move(
        address,
        address,
        uint256
    ) external;

    function burn(address, uint256) external;
}

/*
   This thing lets you sell some irdt in return for gems.

 - `lot` irdt in return for bid
 - `bid` gems paid
 - `ttl` single bid lifetime
 - `beg` minimum bid increase
 - `end` max auction duration
*/

contract Flapper {
    // --- Auth ---
    mapping(address => uint256) public wards;

    function rely(address usr) external {
        wards[usr] = 1;
    }

    function deny(address usr) external {
        wards[usr] = 0;
    }

    // --- Data ---
    struct Bid {
        uint256 bid; // gems paid               [wad]
        uint256 lot; // irdt in return for bid   [rad]
        address guy; // high bidder
        uint48 tic; // bid expiry time         [unix epoch time]
        uint48 end; // auction expiry time     [unix epoch time]
    }

    mapping(uint256 => Bid) public bids;

    VatLike public vat; // CDP Engine
    GemLike public gem;

    uint256 constant ONE = 1.00E18;
    uint256 public beg = 1.05E18; // 5% minimum bid increase
    uint48 public ttl = 3 hours; // 3 hours bid duration         [seconds]
    uint48 public tau = 2 days; // 2 days total auction length  [seconds]
    uint256 public kicks = 0;
    uint256 public live; // Active Flag
    uint256 public lid; // max irdt to be in auction at one time  [rad]
    uint256 public fill; // current irdt in auction                [rad]

    // --- Events ---

    event Kick(uint256 id, uint256 lot, uint256 bid);
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event File(bytes32 indexed what, uint256 data);
    event Tick(uint256 indexed id);

    event Tend(uint256 indexed id, uint256 lot, uint256 bid);

    event Deal(uint256 indexed id);

    event Cage();
    event Yank(uint256 indexed id);

    // --- Init ---
    constructor(address vat_, address gem_) public {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
        gem = GemLike(gem_);
        live = 1;
    }

    // --- Math ---
    function add(uint48 x, uint48 y) internal pure returns (uint48 z) {
        require((z = x + y) >= x);
    }

    function add256(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    // --- Admin ---
    function file(bytes32 what, uint256 data) external {
        if (what == "beg") beg = data;
        else if (what == "ttl") ttl = uint48(data);
        else if (what == "tau") tau = uint48(data);
        else if (what == "lid") lid = data;
        else revert("Flapper/file-unrecognized-param");
        emit File(what, data);
    }

    // --- Auction ---
    function kick(uint256 lot, uint256 bid) external returns (uint256 id) {
        require(live == 1, "Flapper/not-live");
        require(kicks < uint256(-1), "Flapper/overflow");
        fill = add256(fill, lot);
        require(fill <= lid, "Flapper/over-lid");
        id = ++kicks;

        bids[id].bid = bid;
        bids[id].lot = lot;
        bids[id].guy = msg.sender; // configurable??
        bids[id].end = add(uint48(now), tau);

        vat.move(msg.sender, address(this), lot);

        emit Kick(id, lot, bid);
    }

    function tick(uint256 id) external {
        require(bids[id].end < now, "Flapper/not-finished");
        require(bids[id].tic == 0, "Flapper/bid-already-placed");
        bids[id].end = add(uint48(now), tau);
        emit Tick(id);
    }

    function tend(
        uint256 id,
        uint256 lot,
        uint256 bid
    ) external {
        require(live == 1, "Flapper/not-live");
        require(bids[id].guy != address(0), "Flapper/guy-not-set");
        require(
            bids[id].tic > now || bids[id].tic == 0,
            "Flapper/already-finished-tic"
        );
        require(bids[id].end > now, "Flapper/already-finished-end");

        require(lot == bids[id].lot, "Flapper/lot-not-matching");
        require(bid > bids[id].bid, "Flapper/bid-not-higher");
        require(
            mul(bid, ONE) >= mul(beg, bids[id].bid),
            "Flapper/insufficient-increase"
        );

        if (msg.sender != bids[id].guy) {
            gem.move(msg.sender, bids[id].guy, bids[id].bid);
            bids[id].guy = msg.sender;
        }
        gem.move(msg.sender, address(this), bid - bids[id].bid);

        bids[id].bid = bid;
        bids[id].tic = add(uint48(now), ttl);
        emit Tend(id, lot, bid);
    }

    function deal(uint256 id) external {
        require(live == 1, "Flapper/not-live");
        require(
            bids[id].tic != 0 && (bids[id].tic < now || bids[id].end < now),
            "Flapper/not-finished"
        );
        uint256 lot = bids[id].lot;
        vat.move(address(this), bids[id].guy, lot);
        gem.burn(address(this), bids[id].bid);
        delete bids[id];
        fill = sub(fill, lot);
        emit Deal(id);
    }

    function cage(uint256 rad) external {
        live = 0;
        vat.move(address(this), msg.sender, rad);
        emit Cage();
    }

    function yank(uint256 id) external {
        require(live == 0, "Flapper/still-live");
        require(bids[id].guy != address(0), "Flapper/guy-not-set");
        gem.move(address(this), bids[id].guy, bids[id].bid);
        delete bids[id];
        emit Yank(id);
    }
}

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

pragma solidity >=0.5.12;

// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

interface VatLike {
    function move(
        address,
        address,
        uint256
    ) external;

    function flux(
        bytes32,
        address,
        address,
        uint256
    ) external;
}

interface CatLike {
    function claw(uint256) external;
}

/*
   This thing lets you flip some gems for a given amount of irdt.
   Once the given amount of irdt is raised, gems are forgone instead.

 - `lot` gems in return for bid
 - `tab` total irdt wanted
 - `bid` irdt paid
 - `gal` receives irdt income
 - `usr` receives gem forgone
 - `ttl` single bid lifetime
 - `beg` minimum bid increase
 - `end` max auction duration
*/

contract Flipper {
    // ---  ---
    mapping(address => uint256) public wards;

    function rely(address usr) external {
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external {
        wards[usr] = 0;
        emit Deny(usr);
    }

    // --- Data ---
    struct Bid {
        uint256 bid; // irdt paid                 [rad]
        uint256 lot; // gems in return for bid   [wad]
        address guy; // high bidder
        uint48 tic; // bid expiry time          [unix epoch time]
        uint48 end; // auction expiry time      [unix epoch time]
        address usr;
        address gal;
        uint256 tab; // total irdt wanted         [rad]
    }

    mapping(uint256 => Bid) public bids;

    VatLike public vat; // CDP Engine
    bytes32 public ilk; // collateral type

    uint256 constant ONE = 1.00E18;
    uint256 public beg = 1.05E18; // 5% minimum bid increase
    uint48 public ttl = 3 hours; // 3 hours bid duration         [seconds]
    uint48 public tau = 2 days; // 2 days total auction length  [seconds]
    uint256 public kicks = 0;
    CatLike public cat; // cat liquidation module

    // --- Events ---
    event Kick(
        uint256 id,
        uint256 lot,
        uint256 bid,
        uint256 tab,
        address indexed usr,
        address indexed gal
    );

    event Kick(uint256 id, uint256 lot, uint256 bid, address indexed gal);

    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event File(bytes32 indexed what, uint256 data);

    event File(bytes32 indexed what, address indexed data);

    event Tick(uint256 indexed id);
    event Tend(uint256 indexed id, uint256 lot, uint256 bid);

    event Dent(uint256 indexed id, uint256 lot, uint256 bid);

    event Deal(uint256 indexed id);

    event Yank(uint256 indexed id);

    // --- Init ---
    constructor(
        address vat_,
        address cat_,
        bytes32 ilk_
    ) public {
        vat = VatLike(vat_);
        cat = CatLike(cat_);
        ilk = ilk_;
        wards[msg.sender] = 1;
    }

    // --- Math ---
    function add(uint48 x, uint48 y) internal pure returns (uint48 z) {
        require((z = x + y) >= x);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    // --- Admin ---
    function file(bytes32 what, uint256 data) external {
        if (what == "beg") beg = data;
        else if (what == "ttl") ttl = uint48(data);
        else if (what == "tau") tau = uint48(data);
        else revert("Flipper/file-unrecognized-param");
        emit File(what, data);
    }

    function file(bytes32 what, address data) external {
        if (what == "cat") cat = CatLike(data);
        else revert("Flipper/file-unrecognized-param");
        emit File(what, data);
    }

    // --- Auction ---
    function kick(
        address usr,
        address gal,
        uint256 tab,
        uint256 lot,
        uint256 bid
    ) public returns (uint256 id) {
        require(kicks < uint256(-1), "Flipper/overflow");
        id = ++kicks;

        bids[id].bid = bid;
        bids[id].lot = lot;
        bids[id].guy = msg.sender; // configurable??
        bids[id].end = add(uint48(now), tau);
        bids[id].usr = usr;
        bids[id].gal = gal;
        bids[id].tab = tab;

        vat.flux(ilk, msg.sender, address(this), lot);

        emit Kick(id, lot, bid, tab, usr, gal);
    }

    function tick(uint256 id) external {
        require(bids[id].end < now, "Flipper/not-finished");
        require(bids[id].tic == 0, "Flipper/bid-already-placed");
        bids[id].end = add(uint48(now), tau);
        emit Tick(id);
    }

    function tend(
        uint256 id,
        uint256 lot,
        uint256 bid
    ) external {
        require(bids[id].guy != address(0), "Flipper/guy-not-set");
        require(
            bids[id].tic > now || bids[id].tic == 0,
            "Flipper/already-finished-tic"
        );
        require(bids[id].end > now, "Flipper/already-finished-end");

        require(lot == bids[id].lot, "Flipper/lot-not-matching");
        require(bid <= bids[id].tab, "Flipper/higher-than-tab");
        require(bid > bids[id].bid, "Flipper/bid-not-higher");
        require(
            mul(bid, ONE) >= mul(beg, bids[id].bid) || bid == bids[id].tab,
            "Flipper/insufficient-increase"
        );

        if (msg.sender != bids[id].guy) {
            vat.move(msg.sender, bids[id].guy, bids[id].bid);
            bids[id].guy = msg.sender;
        }
        vat.move(msg.sender, bids[id].gal, bid - bids[id].bid);

        bids[id].bid = bid;
        bids[id].tic = add(uint48(now), ttl);
        emit Tend(id, lot, bid);
    }

    function dent(
        uint256 id,
        uint256 lot,
        uint256 bid
    ) external {
        require(bids[id].guy != address(0), "Flipper/guy-not-set");
        require(
            bids[id].tic > now || bids[id].tic == 0,
            "Flipper/already-finished-tic"
        );
        require(bids[id].end > now, "Flipper/already-finished-end");

        require(bid == bids[id].bid, "Flipper/not-matching-bid");
        require(bid == bids[id].tab, "Flipper/tend-not-finished");
        require(lot < bids[id].lot, "Flipper/lot-not-lower");
        require(
            mul(beg, lot) <= mul(bids[id].lot, ONE),
            "Flipper/insufficient-decrease"
        );

        if (msg.sender != bids[id].guy) {
            vat.move(msg.sender, bids[id].guy, bid);
            bids[id].guy = msg.sender;
        }
        vat.flux(ilk, address(this), bids[id].usr, bids[id].lot - lot);

        bids[id].lot = lot;
        bids[id].tic = add(uint48(now), ttl);
        emit Dent(id, lot, bid);
    }

    function deal(uint256 id) external {
        require(
            bids[id].tic != 0 && (bids[id].tic < now || bids[id].end < now),
            "Flipper/not-finished"
        );
        cat.claw(bids[id].tab);
        vat.flux(ilk, address(this), bids[id].guy, bids[id].lot);
        delete bids[id];
    }

    function yank(uint256 id) external {
        require(bids[id].guy != address(0), "Flipper/guy-not-set");
        require(bids[id].bid < bids[id].tab, "Flipper/already-dent-phase");
        cat.claw(bids[id].tab);
        vat.flux(ilk, address(this), msg.sender, bids[id].lot);
        vat.move(msg.sender, bids[id].guy, bids[id].bid);
        delete bids[id];
        emit Yank(id);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// flop.sol -- Debt auction

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

pragma solidity ^0.6.12;

// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

interface VatLike {
    function move(
        address,
        address,
        uint256
    ) external;

    function suck(
        address,
        address,
        uint256
    ) external;
}

interface GemLike {
    function mint(address, uint256) external;
}

interface VowLike {
    function Ash() external returns (uint256);

    function kiss(uint256) external;
}

/*
   This thing creates gems on demand in return for irdt.

 - `lot` gems in return for bid
 - `bid` irdt paid
 - `gal` receives irdt income
 - `ttl` single bid lifetime
 - `beg` minimum bid increase
 - `end` max auction duration
*/

contract Flopper {
    // --- Auth ---
    mapping(address => uint256) public wards;

    function rely(address usr) external {
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external {
        wards[usr] = 0;
        emit Deny(usr);
        (usr);
    }

    // --- Data ---
    struct Bid {
        uint256 bid; // irdt paid                [rad]
        uint256 lot; // gems in return for bid  [wad]
        address guy; // high bidder
        uint48 tic; // bid expiry time         [unix epoch time]
        uint48 end; // auction expiry time     [unix epoch time]
    }

    mapping(uint256 => Bid) public bids;

    VatLike public vat; // CDP Engine
    GemLike public gem;

    uint256 constant ONE = 1.00E18;
    uint256 public beg = 1.05E18; // 5% minimum bid increase
    uint256 public pad = 1.50E18; // 50% lot increase for tick
    uint48 public ttl = 3 hours; // 3 hours bid lifetime         [seconds]
    uint48 public tau = 2 days; // 2 days total auction length  [seconds]
    uint256 public kicks = 0;
    uint256 public live; // Active Flag
    address public vow; // not used until shutdown

    // --- Events ---
    event Kick(uint256 id, uint256 lot, uint256 bid, address indexed gal);

    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event File(bytes32 indexed what, uint256 data);
    event Tick(uint256 indexed id);
    event Dent(uint256 indexed id, uint256 lot, uint256 bid);

    event Deal(uint256 indexed id);

    event Cage();
    event Yank(uint256 indexed id);

    // --- Init ---
    constructor(address vat_, address gem_) public {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
        gem = GemLike(gem_);
        live = 1;
    }

    // --- Math ---
    function add(uint48 x, uint48 y) internal pure returns (uint48 z) {
        require((z = x + y) >= x);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (x > y) {
            z = y;
        } else {
            z = x;
        }
    }

    // --- Admin ---
    function file(bytes32 what, uint256 data) external {
        if (what == "beg") beg = data;
        else if (what == "pad") pad = data;
        else if (what == "ttl") ttl = uint48(data);
        else if (what == "tau") tau = uint48(data);
        else revert("Flopper/file-unrecognized-param");
        emit File(what, data);
    }

    // --- Auction ---
    function kick(
        address gal,
        uint256 lot,
        uint256 bid
    ) external returns (uint256 id) {
        require(live == 1, "Flopper/not-live");
        require(kicks < uint256(-1), "Flopper/overflow");
        id = ++kicks;

        bids[id].bid = bid;
        bids[id].lot = lot;
        bids[id].guy = gal;
        bids[id].end = add(uint48(now), tau);

        emit Kick(id, lot, bid, gal);
    }

    function tick(uint256 id) external {
        require(bids[id].end < now, "Flopper/not-finished");
        require(bids[id].tic == 0, "Flopper/bid-already-placed");
        bids[id].lot = mul(pad, bids[id].lot) / ONE;
        bids[id].end = add(uint48(now), tau);
        emit Tick(id);
    }

    function dent(
        uint256 id,
        uint256 lot,
        uint256 bid
    ) external {
        require(live == 1, "Flopper/not-live");
        require(bids[id].guy != address(0), "Flopper/guy-not-set");
        require(
            bids[id].tic > now || bids[id].tic == 0,
            "Flopper/already-finished-tic"
        );
        require(bids[id].end > now, "Flopper/already-finished-end");

        require(bid == bids[id].bid, "Flopper/not-matching-bid");
        require(lot < bids[id].lot, "Flopper/lot-not-lower");
        require(
            mul(beg, lot) <= mul(bids[id].lot, ONE),
            "Flopper/insufficient-decrease"
        );

        if (msg.sender != bids[id].guy) {
            vat.move(msg.sender, bids[id].guy, bid);

            // on first dent, clear as much Ash as possible
            if (bids[id].tic == 0) {
                uint256 Ash = VowLike(bids[id].guy).Ash();
                VowLike(bids[id].guy).kiss(min(bid, Ash));
            }

            bids[id].guy = msg.sender;
        }

        bids[id].lot = lot;
        bids[id].tic = add(uint48(now), ttl);
        emit Dent(id, lot, bid);
    }

    function deal(uint256 id) external {
        require(live == 1, "Flopper/not-live");
        require(
            bids[id].tic != 0 && (bids[id].tic < now || bids[id].end < now),
            "Flopper/not-finished"
        );
        gem.mint(bids[id].guy, bids[id].lot);
        delete bids[id];
        emit Deal(id);
    }

    // --- Shutdown ---
    function cage() external {
        live = 0;
        vow = msg.sender;
        emit Cage();
    }

    function yank(uint256 id) external {
        require(live == 0, "Flopper/still-live");
        require(bids[id].guy != address(0), "Flopper/guy-not-set");
        vat.suck(vow, bids[id].guy, bids[id].bid);
        delete bids[id];
        emit Yank(id);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// irdt.sol -- IRDT Stablecoin ERC-20 Token

// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico

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

// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

contract IRDT {
    // --- Auth ---
    mapping(address => uint256) public wards;

    function rely(address guy) external {
        wards[guy] = 1;
    }

    function deny(address guy) external {
        wards[guy] = 0;
    }

    // --- ERC20 Data ---
    string public constant name = "IRDT Stablecoin";
    string public constant symbol = "IRDT";
    string public constant version = "1";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);

    // --- Math ---
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
    bytes32 public constant PERMIT_TYPEHASH =
        0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    constructor(uint256 chainId_) public {
        wards[msg.sender] = 1;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId_,
                address(this)
            )
        );
    }

    // --- Token ---
    function transfer(address dst, uint256 wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public returns (bool) {
        require(balanceOf[src] >= wad, "IRDT/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != uint256(-1)) {
            require(
                allowance[src][msg.sender] >= wad,
                "IRDT/insufficient-allowance"
            );
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }
        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);
        emit Transfer(src, dst, wad);
        return true;
    }

    function mint(address usr, uint256 wad) external {
        balanceOf[usr] = add(balanceOf[usr], wad);
        totalSupply = add(totalSupply, wad);
        emit Transfer(address(0), usr, wad);
    }

    function burn(address usr, uint256 wad) external {
        require(balanceOf[usr] >= wad, "IRDT/insufficient-balance");
        if (usr != msg.sender && allowance[usr][msg.sender] != uint256(-1)) {
            require(
                allowance[usr][msg.sender] >= wad,
                "IRDT/insufficient-allowance"
            );
            allowance[usr][msg.sender] = sub(allowance[usr][msg.sender], wad);
        }
        balanceOf[usr] = sub(balanceOf[usr], wad);
        totalSupply = sub(totalSupply, wad);
        emit Transfer(usr, address(0), wad);
    }

    function approve(address usr, uint256 wad) external returns (bool) {
        allowance[msg.sender][usr] = wad;
        emit Approval(msg.sender, usr, wad);
        return true;
    }

    // --- Alias ---
    function push(address usr, uint256 wad) external {
        transferFrom(msg.sender, usr, wad);
    }

    function pull(address usr, uint256 wad) external {
        transferFrom(usr, msg.sender, wad);
    }

    function move(
        address src,
        address dst,
        uint256 wad
    ) external {
        transferFrom(src, dst, wad);
    }

    // --- Approve by signature ---
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        holder,
                        spender,
                        nonce,
                        expiry,
                        allowed
                    )
                )
            )
        );

        require(holder != address(0), "IRDT/invalid-address-0");
        require(holder == ecrecover(digest, v, r, s), "IRDT/invalid-permit");
        require(expiry == 0 || now <= expiry, "IRDT/permit-expired");
        require(nonce == nonces[holder]++, "IRDT/invalid-nonce");
        uint256 wad = allowed ? uint256(-1) : 0;
        allowance[holder][spender] = wad;
        emit Approval(holder, spender, wad);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

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

pragma solidity ^0.6.12;

// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

interface GemLike {
    function decimals() external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
}

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

      - `IRDTJoin`: For connecting internal irdt balances to an external
                   `DSToken` implementation.

    In practice, adapter implementations will be varied and specific to
    individual collateral types, accounting for different transfer
    semantics and token standards.

    Adapters need to implement two basic methods:

      - `join`: enter collateral into the system
      - `exit`: remove collateral from the system

*/

contract GemJoin {
    // --- Auth ---
    mapping(address => uint256) public wards;

    function rely(address usr) external {
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external {
        wards[usr] = 0;
        emit Deny(usr);
    }

    VatLike public vat; // CDP Engine
    bytes32 public ilk; // Collateral Type
    GemLike public gem;
    uint256 public dec;
    uint256 public live; // Active Flag

    // Events
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Join(address indexed usr, uint256 wad);
    event Exit(address indexed usr, uint256 wad);
    event Cage();

    constructor(
        address vat_,
        bytes32 ilk_,
        address gem_
    ) public {
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike(vat_);
        ilk = ilk_;
        gem = GemLike(gem_);
        dec = gem.decimals();
        emit Rely(msg.sender);
    }

    function cage() external {
        live = 0;
        emit Cage();
    }

    function join(address usr, uint256 wad) external {
        require(live == 1, "GemJoin/not-live");
        require(int256(wad) >= 0, "GemJoin/overflow");
        vat.slip(ilk, usr, int256(wad));
        require(
            gem.transferFrom(msg.sender, address(this), wad),
            "GemJoin/failed-transfer"
        );
        emit Join(usr, wad);
    }

    function exit(address usr, uint256 wad) external {
        require(wad <= 2**255, "GemJoin/overflow");
        vat.slip(ilk, msg.sender, -int256(wad));
        require(gem.transfer(usr, wad), "GemJoin/failed-transfer");
        emit Exit(usr, wad);
    }
}

contract IRDTJoin {
    // --- Auth ---
    mapping(address => uint256) public wards;

    function rely(address usr) external {
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external {
        wards[usr] = 0;
        emit Deny(usr);
    }

    VatLike public vat; // CDP Engine
    DSTokenLike public irdt; // Stablecoin Token
    uint256 public live; // Active Flag

    // Events
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Join(address indexed usr, uint256 wad);
    event Exit(address indexed usr, uint256 wad);
    event Cage();

    constructor(address vat_, address irdt_) public {
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike(vat_);
        irdt = DSTokenLike(irdt_);
    }

    function cage() external {
        live = 0;
        emit Cage();
    }

    uint256 constant ONE = 10**27;

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function join(address usr, uint256 wad) external {
        vat.move(address(this), usr, mul(ONE, wad));
        irdt.burn(msg.sender, wad);
        emit Join(usr, wad);
    }

    function exit(address usr, uint256 wad) external {
        require(live == 1, "IRDTJoin/not-live");
        vat.move(msg.sender, address(this), mul(ONE, wad));
        irdt.mint(usr, wad);
        emit Exit(usr, wad);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// jug.sol -- irdt Lending Rate

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

pragma solidity ^0.6.12;

// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

interface VatLike {
    function ilks(bytes32)
        external
        returns (
            uint256 Art, // [wad]
            uint256 rate // [ray]
        );

    function fold(
        bytes32,
        address,
        int256
    ) external;
}

contract Jug {
    // --- Auth ---
    mapping(address => uint256) public wards;

    function rely(address usr) external {
        wards[usr] = 1;
    }

    function deny(address usr) external {
        wards[usr] = 0;
    }

    // --- Data ---
    struct Ilk {
        uint256 duty; // Collateral-specific, per-second stability fee contribution [ray]
        uint256 rho; // Time of last drip [unix epoch time]
    }

    mapping(bytes32 => Ilk) public ilks;
    VatLike public vat; // CDP Engine
    address public vow; // Debt Engine
    uint256 public base; // Global, per-second stability fee contribution [ray]

    event Init(bytes32 indexed ilk);

    event File(bytes32 indexed ilk, bytes32 indexed what, uint256 indexed data);

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);

    event Drip(bytes32 indexed ilk, uint256 indexed rate);

    // --- Init ---
    constructor(address vat_) public {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
    }

    // --- Math ---
    function _rpow(
        uint256 x,
        uint256 n,
        uint256 b
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    z := b
                }
                default {
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    z := b
                }
                default {
                    z := x
                }
                let half := div(b, 2) // for rounding.
                for {
                    n := div(n, 2)
                } n {
                    n := div(n, 2)
                } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) {
                        revert(0, 0)
                    }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }
                    x := div(xxRound, b)
                    if mod(n, 2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                            revert(0, 0)
                        }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }
                        z := div(zxRound, b)
                    }
                }
            }
        }
    }

    uint256 constant ONE = 10**27;

    function _add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
        require(z >= x);
    }

    function _diff(uint256 x, uint256 y) internal pure returns (int256 z) {
        z = int256(x) - int256(y);
        require(int256(x) >= 0 && int256(y) >= 0);
    }

    function _rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
        require(y == 0 || z / y == x);
        z = z / ONE;
    }

    // --- Administration ---
    function init(bytes32 ilk) external {
        Ilk storage i = ilks[ilk];
        require(i.duty == 0, "Jug/ilk-already-init");
        i.duty = ONE;
        i.rho = now;
        emit Init(ilk);
    }

    function file(
        bytes32 ilk,
        bytes32 what,
        uint256 data
    ) external {
        require(now == ilks[ilk].rho, "Jug/rho-not-updated");
        if (what == "duty") ilks[ilk].duty = data;
        else revert("Jug/file-unrecognized-param");
        emit File(ilk, what, data);
    }

    function file(bytes32 what, uint256 data) external {
        if (what == "base") base = data;
        else revert("Jug/file-unrecognized-param");
        emit File(what, data);
    }

    function file(bytes32 what, address data) external {
        if (what == "vow") vow = data;
        else revert("Jug/file-unrecognized-param");
        emit File(what, data);
    }

    // --- Stability Fee Collection ---
    function drip(bytes32 ilk) external returns (uint256 rate) {
        require(now >= ilks[ilk].rho, "Jug/invalid-now");
        (, uint256 prev) = vat.ilks(ilk);
        rate = _rmul(
            _rpow(_add(base, ilks[ilk].duty), now - ilks[ilk].rho, ONE),
            prev
        );
        vat.fold(ilk, vow, _diff(rate, prev));
        ilks[ilk].rho = now;
        emit Drip(ilk, rate);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// pot.sol -- IRDT Savings Rate

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

pragma solidity ^0.6.12;

// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

/*
   "Savings IRDT" is obtained when IRDT is deposited into
   this contract. Each "Savings IRDT" accrues IRDT interest
   at the "IRDT Savings Rate".

   This contract does not implement a user tradeable token
   and is intended to be used with adapters.

         --- `save` your `IRDT` in the `pot` ---

   - `dsr`: the IRDT Savings Rate
   - `pie`: user balance of Savings IRDT

   - `join`: start saving some IRDT
   - `exit`: remove some IRDT
   - `drip`: perform rate collection

*/

interface VatLike {
    function move(
        address,
        address,
        uint256
    ) external;

    function suck(
        address,
        address,
        uint256
    ) external;
}

contract Pot {
    // --- Auth ---
    mapping(address => uint256) public wards;

    function rely(address guy) external {
        wards[guy] = 1;

        emit Rely(guy);
    }

    function deny(address guy) external {
        wards[guy] = 0;
        emit Deny(guy);
    }

    // --- Data ---
    mapping(address => uint256) public pie; // Normalised Savings IRDT [wad]

    uint256 public Pie; // Total Normalised Savings IRDT  [wad]
    uint256 public dsr; // The IRDT Savings Rate          [ray]
    uint256 public chi; // The Rate Accumulator          [ray]

    VatLike public vat; // CDP Engine
    address public vow; // Debt Engine
    uint256 public rho; // Time of last drip     [unix epoch time]

    uint256 public live; // Active Flag

    event Rely(address indexed guy);
    event Deny(address indexed guy);

    event File(bytes32 what, address addr);
    event File(bytes32 what, uint256 data);
    event Cage();

    event Drip(uint256 tmp);
    event Join(uint256 wad);
    event Exit(uint256 wad);

    // --- Init ---
    constructor(address vat_) public {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
        dsr = ONE;
        chi = ONE;
        rho = now;
        live = 1;
    }

    // --- Math ---
    uint256 constant ONE = 10**27;

    function _rpow(
        uint256 x,
        uint256 n,
        uint256 base
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    z := base
                }
                default {
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    z := base
                }
                default {
                    z := x
                }
                let half := div(base, 2) // for rounding.
                for {
                    n := div(n, 2)
                } n {
                    n := div(n, 2)
                } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) {
                        revert(0, 0)
                    }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }
                    x := div(xxRound, base)
                    if mod(n, 2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                            revert(0, 0)
                        }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }

    function _rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = _mul(x, y) / ONE;
    }

    function _add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function _sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function _mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    // --- Administration ---
    function file(bytes32 what, uint256 data) external {
        require(live == 1, "Pot/not-live");
        require(now == rho, "Pot/rho-not-updated");
        if (what == "dsr") dsr = data;
        else revert("Pot/file-unrecognized-param");
        emit File(what, data);
    }

    function file(bytes32 what, address addr) external {
        if (what == "vow") vow = addr;
        else revert("Pot/file-unrecognized-param");
        emit File(what, addr);
    }

    function cage() external {
        live = 0;
        dsr = ONE;
        emit Cage();
    }

    // --- Savings Rate Accumulation ---
    function drip() external returns (uint256 tmp) {
        require(now >= rho, "Pot/invalid-now");
        tmp = _rmul(_rpow(dsr, now - rho, ONE), chi);
        uint256 chi_ = _sub(tmp, chi);
        chi = tmp;
        rho = now;
        vat.suck(address(vow), address(this), _mul(Pie, chi_));
        emit Drip(tmp);
    }

    // --- Savings IRDT Management ---
    function join(uint256 wad) external {
        require(now == rho, "Pot/rho-not-updated");
        pie[msg.sender] = _add(pie[msg.sender], wad);
        Pie = _add(Pie, wad);
        vat.move(msg.sender, address(this), _mul(chi, wad));
        emit Join(wad);
    }

    function exit(uint256 wad) external {
        pie[msg.sender] = _sub(pie[msg.sender], wad);
        Pie = _sub(Pie, wad);
        vat.move(address(this), msg.sender, _mul(chi, wad));
        emit Exit(wad);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// spot.sol -- Spotter

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

// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

interface VatLike {
    function file(
        bytes32,
        bytes32,
        uint256
    ) external;
}

interface PipLike {
    function peek() external returns (bytes32, bool);
}

contract Spotter {
    // ---  ---
    mapping(address => uint256) public wards;

    function rely(address guy) external {
        wards[guy] = 1;
    }

    function deny(address guy) external {
        wards[guy] = 0;
    }

    // --- Data ---
    struct Ilk {
        PipLike pip; // Price Feed
        uint256 mat; // Liquidation ratio [ray]
    }

    mapping(bytes32 => Ilk) public ilks;

    VatLike public vat; // CDP Engine
    uint256 public par; // ref per irdt [ray]

    uint256 public live;

    // --- Events ---
    event Poke(
        bytes32 ilk,
        bytes32 val, // [wad]
        uint256 spot // [ray]
    );

    event File(bytes32 indexed ilk, bytes32 indexed what, uint256 data);
    event File(bytes32 indexed ilk, bytes32 indexed what, address pip_);
    event File(bytes32 what, uint256 data);

    // --- Init ---
    constructor(address vat_) public {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
        par = ONE;
        live = 1;
    }

    // --- Math ---
    uint256 constant ONE = 10**27;

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, ONE) / y;
    }

    // --- Administration ---
    function file(
        bytes32 ilk,
        bytes32 what,
        address pip_
    ) external {
        require(live == 1, "Spotter/not-live");
        if (what == "pip") ilks[ilk].pip = PipLike(pip_);
        else revert("Spotter/file-unrecognized-param");
        emit File(ilk, what, pip_);
    }

    function file(bytes32 what, uint256 data) external {
        require(live == 1, "Spotter/not-live");
        if (what == "par") par = data;
        else revert("Spotter/file-unrecognized-param");
        emit File(what, data);
    }

    function file(
        bytes32 ilk,
        bytes32 what,
        uint256 data
    ) external {
        require(live == 1, "Spotter/not-live");
        if (what == "mat") ilks[ilk].mat = data;
        else revert("Spotter/file-unrecognized-param");
        emit File(ilk, what, data);
    }

    // --- Update value ---
    function poke(bytes32 ilk) external {
        (bytes32 val, bool has) = ilks[ilk].pip.peek();
        uint256 spot = has
            ? rdiv(rdiv(mul(uint256(val), 10**9), par), ilks[ilk].mat)
            : 0;
        vat.file(ilk, "spot", spot);
        emit Poke(ilk, val, spot);
    }

    function cage() external {
        live = 0;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// vat.sol -- IRDT CDP database

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

pragma solidity ^0.6.12;

// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

contract Vat {
    // --- Auth ---
    mapping(address => uint256) public wards;

    function rely(address usr) external {
        require(live == 1, "Vat/not-live");
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external {
        require(live == 1, "Vat/not-live");
        wards[usr] = 0;
        emit Deny(usr);
    }

    mapping(address => mapping(address => uint256)) public can;

    function hope(address usr) external {
        can[msg.sender][usr] = 1;
        emit Hope(usr);
    }

    function nope(address usr) external {
        can[msg.sender][usr] = 0;
        emit Nope(usr);
    }

    function wish(address bit, address usr) internal view returns (bool) {
        return either(bit == usr, can[bit][usr] == 1);
    }

    // --- Data ---
    struct Ilk {
        uint256 Art; // Total Normalised Debt     [wad]
        uint256 rate; // Accumulated Rates         [ray]
        uint256 spot; // Price with Safety Margin  [ray]
        uint256 line; // Debt Ceiling              [rad]
        uint256 dust; // Urn Debt Floor            [rad]
    }
    struct Urn {
        uint256 ink; // Locked Collateral  [wad]
        uint256 art; // Normalised Debt    [wad]
    }

    mapping(bytes32 => Ilk) public ilks;
    mapping(bytes32 => mapping(address => Urn)) public urns;
    mapping(bytes32 => mapping(address => uint256)) public gem; // [wad]
    mapping(address => uint256) public irdt; // [rad]
    mapping(address => uint256) public sin; // [rad]

    uint256 public debt; // Total IRDT Issued    [rad]
    uint256 public vice; // Total Unbacked IRDT  [rad]
    uint256 public Line; // Total Debt Ceiling  [rad]
    uint256 public live; // Active Flag

    event Rely(address indexed usr);
    event Deny(address indexed usr);

    event Hope(address indexed usr);
    event Nope(address indexed usr);

    event Init(bytes32 indexed ilk);

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed ilk, bytes32 indexed what, uint256 indexed data);
    event Cage();
    event Slip(bytes32 indexed ilk, address indexed usr, int256 indexed wad);
    event Flux(
        bytes32 indexed ilk,
        address indexed src,
        address indexed dst,
        uint256 wad
    );

    event Move(address indexed src, address indexed dst, uint256 rad);
    event Frob(
        bytes32 i,
        address indexed u,
        address indexed v,
        address indexed w,
        int256 dink,
        int256 dart
    );

    event Fork(
        bytes32 indexed ilk,
        address indexed src,
        address indexed dst,
        int256 dink,
        int256 dart
    );

    event Grab(
        bytes32 i,
        address indexed u,
        address indexed v,
        address indexed w,
        int256 dink,
        int256 dart
    );
    event Heal(uint256 indexed rad);

    event Suck(address indexed u, address indexed v, uint256 indexed rad);

    event Fess(uint256 indexed tab);
    event Flog(uint256 indexed era);

    event Kiss(uint256 indexed rad);
    event Flop(uint256 indexed id);
    event Flap(uint256 indexed id);
    event Fold(bytes32 indexed i, address indexed u, int256 indexed rate);

    // --- Init ---
    constructor() public {
        wards[msg.sender] = 1;
        live = 1;
    }

    // --- Math ---
    function _add(uint256 x, int256 y) internal pure returns (uint256 z) {
        z = x + uint256(y);
        require(y >= 0 || z <= x);
        require(y <= 0 || z >= x);
    }

    function _sub(uint256 x, int256 y) internal pure returns (uint256 z) {
        z = x - uint256(y);
        require(y <= 0 || z <= x);
        require(y >= 0 || z >= x);
    }

    function _mul(uint256 x, int256 y) internal pure returns (int256 z) {
        z = int256(x) * y;
        require(int256(x) >= 0);
        require(y == 0 || z / y == int256(x));
    }

    function _add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function _sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function _mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    // --- Administration ---
    function init(bytes32 ilk) external {
        require(ilks[ilk].rate == 0, "Vat/ilk-already-init");
        ilks[ilk].rate = 10**27;
    }

    function file(bytes32 what, uint256 data) external {
        require(live == 1, "Vat/not-live");
        if (what == "Line") Line = data;
        else revert("Vat/file-unrecognized-param");
    }

    function file(
        bytes32 ilk,
        bytes32 what,
        uint256 data
    ) external {
        require(live == 1, "Vat/not-live");
        if (what == "spot") ilks[ilk].spot = data;
        else if (what == "line") ilks[ilk].line = data;
        else if (what == "dust") ilks[ilk].dust = data;
        else revert("Vat/file-unrecognized-param");
    }

    function cage() external {
        live = 0;
        emit Cage();
    }

    // --- Fungibility ---
    function slip(
        bytes32 ilk,
        address usr,
        int256 wad
    ) external {
        gem[ilk][usr] = _add(gem[ilk][usr], wad);
        emit Slip(ilk, usr, wad);
    }

    function flux(
        bytes32 ilk,
        address src,
        address dst,
        uint256 wad
    ) external {
        require(wish(src, msg.sender), "Vat/not-allowed1");
        gem[ilk][src] = _sub(gem[ilk][src], wad);
        gem[ilk][dst] = _add(gem[ilk][dst], wad);
        emit Flux(ilk, src, dst, wad);
    }

    function move(
        address src,
        address dst,
        uint256 rad
    ) external {
        require(wish(src, msg.sender), "Vat/not-allowed2");
        irdt[src] = _sub(irdt[src], rad);
        irdt[dst] = _add(irdt[dst], rad);
        emit Move(src, dst, rad);
    }

    function either(bool x, bool y) internal pure returns (bool z) {
        assembly {
            z := or(x, y)
        }
    }

    function both(bool x, bool y) internal pure returns (bool z) {
        assembly {
            z := and(x, y)
        }
    }

    // --- CDP Manipulation ---
    function frob(
        bytes32 i,
        address u,
        address v,
        address w,
        int256 dink,
        int256 dart
    ) external {
        // system is live
        require(live == 1, "Vat/not-live");

        Urn memory urn = urns[i][u];
        Ilk memory ilk = ilks[i];
        // ilk has been initialised
        require(ilk.rate != 0, "Vat/ilk-not-init");

        urn.ink = _add(urn.ink, dink);
        urn.art = _add(urn.art, dart);
        ilk.Art = _add(ilk.Art, dart);

        int256 dtab = _mul(ilk.rate, dart);
        uint256 tab = _mul(ilk.rate, urn.art);
        debt = _add(debt, dtab);

        // either debt has decreased, or debt ceilings are not exceeded
        require(
            either(
                dart <= 0,
                both(_mul(ilk.Art, ilk.rate) <= ilk.line, debt <= Line)
            ),
            "Vat/ceiling-exceeded"
        );
        // urn is either less risky than before, or it is safe
        require(
            either(both(dart <= 0, dink >= 0), tab <= _mul(urn.ink, ilk.spot)),
            "Vat/not-safe"
        );

        // urn is either more safe, or the owner consents
        require(
            either(both(dart <= 0, dink >= 0), wish(u, msg.sender)),
            "Vat/not-allowed-u"
        );
        // collateral src consents
        require(either(dink <= 0, wish(v, msg.sender)), "Vat/not-allowed-v");
        // debt dst consents
        require(either(dart >= 0, wish(w, msg.sender)), "Vat/not-allowed-w");

        // urn has no debt, or a non-dusty amount
        require(either(urn.art == 0, tab >= ilk.dust), "Vat/dust");

        gem[i][v] = _sub(gem[i][v], dink);
        irdt[w] = _add(irdt[w], dtab);

        urns[i][u] = urn;
        ilks[i] = ilk;
        emit Frob(i, u, v, w, dink, dart);
    }

    // --- CDP Fungibility ---
    function fork(
        bytes32 ilk,
        address src,
        address dst,
        int256 dink,
        int256 dart
    ) external {
        Urn storage u = urns[ilk][src];
        Urn storage v = urns[ilk][dst];
        Ilk storage i = ilks[ilk];

        u.ink = _sub(u.ink, dink);
        u.art = _sub(u.art, dart);
        v.ink = _add(v.ink, dink);
        v.art = _add(v.art, dart);

        uint256 utab = _mul(u.art, i.rate);
        uint256 vtab = _mul(v.art, i.rate);

        // both sides consent
        require(
            both(wish(src, msg.sender), wish(dst, msg.sender)),
            "Vat/not-allowed3"
        );

        // both sides safe
        require(utab <= _mul(u.ink, i.spot), "Vat/not-safe-src");
        require(vtab <= _mul(v.ink, i.spot), "Vat/not-safe-dst");

        // both sides non-dusty
        require(either(utab >= i.dust, u.art == 0), "Vat/dust-src");
        require(either(vtab >= i.dust, v.art == 0), "Vat/dust-dst");
        emit Fork(ilk, src, dst, dink, dart);
    }

    // --- CDP Confiscation ---
    function grab(
        bytes32 i,
        address u,
        address v,
        address w,
        int256 dink,
        int256 dart
    ) external {
        Urn storage urn = urns[i][u];
        Ilk storage ilk = ilks[i];

        urn.ink = _add(urn.ink, dink);
        urn.art = _add(urn.art, dart);
        ilk.Art = _add(ilk.Art, dart);

        int256 dtab = _mul(ilk.rate, dart);

        gem[i][v] = _sub(gem[i][v], dink);
        sin[w] = _sub(sin[w], dtab);
        vice = _sub(vice, dtab);
        emit Grab(i, u, v, w, dink, dart);
    }

    // --- Settlement ---
    function heal(uint256 rad) external {
        address u = msg.sender;
        sin[u] = _sub(sin[u], rad);
        irdt[u] = _sub(irdt[u], rad);
        vice = _sub(vice, rad);
        debt = _sub(debt, rad);

        emit Heal(rad);
    }

    function suck(
        address u,
        address v,
        uint256 rad
    ) external {
        sin[u] = _add(sin[u], rad);
        irdt[v] = _add(irdt[v], rad);
        vice = _add(vice, rad);
        debt = _add(debt, rad);

        emit Suck(u, v, rad);
    }

    // --- Rates ---
    function fold(
        bytes32 i,
        address u,
        int256 rate
    ) external {
        require(live == 1, "Vat/not-live");
        Ilk storage ilk = ilks[i];
        ilk.rate = _add(ilk.rate, rate);
        int256 rad = _mul(ilk.Art, rate);
        irdt[u] = _add(irdt[u], rad);
        debt = _add(debt, rad);
        emit Fold(i, u, rate);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// vow.sol -- IRDT settlement module

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

pragma solidity ^0.6.12;

// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

interface FlopLike {
    function kick(
        address gal,
        uint256 lot,
        uint256 bid
    ) external returns (uint256);

    function cage() external;

    function live() external returns (uint256);
}

interface FlapLike {
    function kick(uint256 lot, uint256 bid) external returns (uint256);

    function cage(uint256) external;

    function live() external returns (uint256);
}

interface VatLike {
    function irdt(address) external view returns (uint256);

    function sin(address) external view returns (uint256);

    function heal(uint256) external;

    function hope(address) external;

    function nope(address) external;
}

contract Vow {
    // --- Auth ---
    mapping(address => uint256) public wards;

    function rely(address usr) external {
        require(live == 1, "Vow/not-live");
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external {
        wards[usr] = 0;
        emit Deny(usr);
    }

    // --- Data ---
    VatLike public vat; // CDP Engine
    FlapLike public flapper; // Surplus Auction House
    FlopLike public flopper; // Debt Auction House

    mapping(uint256 => uint256) public sin; // debt queue
    uint256 public Sin; // Queued debt            [rad]
    uint256 public Ash; // On-auction debt        [rad]

    uint256 public wait; // Flop delay             [seconds]
    uint256 public dump; // Flop initial lot size  [wad]
    uint256 public sump; // Flop fixed bid size    [rad]

    uint256 public bump; // Flap fixed lot size    [rad]
    uint256 public hump; // Surplus buffer         [rad]

    uint256 public live; // Active Flag

    event Rely(address indexed usr);
    event Deny(address indexed usr);

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    event Fess(uint256 indexed tab);
    event Flog(uint256 indexed era);
    event Heal(uint256 indexed rad);

    event Kiss(uint256 indexed rad);
    event Flop(uint256 indexed id);
    event Flap(uint256 indexed id);

    event Cage();

    // --- Init ---
    constructor(
        address vat_,
        address flapper_,
        address flopper_
    ) public {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
        flapper = FlapLike(flapper_);
        flopper = FlopLike(flopper_);
        vat.hope(flapper_);
        live = 1;
    }

    // --- Math ---
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    // --- Administration ---
    function file(bytes32 what, uint256 data) external {
        if (what == "wait") wait = data;
        else if (what == "bump") bump = data;
        else if (what == "sump") sump = data;
        else if (what == "dump") dump = data;
        else if (what == "hump") hump = data;
        else revert("Vow/file-unrecognized-param");
        emit File(what, data);
    }

    function file(bytes32 what, address data) external {
        if (what == "flapper") {
            vat.nope(address(flapper));
            flapper = FlapLike(data);
            vat.hope(data);
        } else if (what == "flopper") flopper = FlopLike(data);
        else revert("Vow/file-unrecognized-param");
        emit File(what, data);
    }

    // Push to debt-queue
    function fess(uint256 tab) external {
        sin[now] = add(sin[now], tab);
        Sin = add(Sin, tab);
        emit Fess(tab);
    }

    // Pop from debt-queue
    function flog(uint256 era) external {
        require(add(era, wait) <= now, "Vow/wait-not-finished");
        Sin = sub(Sin, sin[era]);
        sin[era] = 0;
        emit Flog(era);
    }

    // Debt settlement
    function heal(uint256 rad) external {
        require(rad <= vat.irdt(address(this)), "Vow/insufficient-surplus");
        require(
            rad <= sub(sub(vat.sin(address(this)), Sin), Ash),
            "Vow/insufficient-debt"
        );
        vat.heal(rad);
        emit Heal(rad);
    }

    function kiss(uint256 rad) external {
        require(rad <= Ash, "Vow/not-enough-ash");
        require(rad <= vat.irdt(address(this)), "Vow/insufficient-surplus");
        Ash = sub(Ash, rad);
        vat.heal(rad);

        emit Kiss(rad);
    }

    // Debt auction
    function flop() external returns (uint256 id) {
        require(
            sump <= sub(sub(vat.sin(address(this)), Sin), Ash),
            "Vow/insufficient-debt"
        );
        require(vat.irdt(address(this)) == 0, "Vow/surplus-not-zero");
        Ash = add(Ash, sump);
        id = flopper.kick(address(this), dump, sump);
        emit Flop(id);
    }

    // Surplus auction
    function flap() external returns (uint256 id) {
        require(
            vat.irdt(address(this)) >=
                add(add(vat.sin(address(this)), bump), hump),
            "Vow/insufficient-surplus"
        );
        require(
            sub(sub(vat.sin(address(this)), Sin), Ash) == 0,
            "Vow/debt-not-zero"
        );
        id = flapper.kick(bump, 0);
        emit Flap(id);
    }

    function cage() external {
        require(live == 1, "Vow/not-live");
        live = 0;
        Sin = 0;
        Ash = 0;
        flapper.cage(vat.irdt(address(flapper)));
        flopper.cage();
        vat.heal(min(vat.irdt(address(this)), vat.sin(address(this))));
        emit Cage();
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// ESM.sol

// Copyright (C) 2019-2022 Dai Foundation

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

pragma solidity >=0.6.12;

interface GemLike {
    function balanceOf(address) external view returns (uint256);

    function burn(uint256) external;

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
}

interface EndLike {
    function live() external view returns (uint256);

    function vat() external view returns (address);

    function cage() external;
}

interface DenyLike {
    function deny(address) external;
}

contract ESM {
    uint256 constant WAD = 10**18;

    GemLike public immutable gem; // collateral (MKR token)
    address public immutable proxy; // Pause proxy

    mapping(address => uint256) public wards; // auth
    mapping(address => uint256) public sum; // per-address balance

    uint256 public Sum; // total balance
    uint256 public min; // minimum activation threshold [wad]
    EndLike public end; // cage module
    uint256 public live; // active flag

    event Fire();
    event Join(address indexed usr, uint256 wad);
    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event DenyProxy(address indexed base, address indexed pause);

    constructor(
        address gem_,
        address end_,
        address proxy_,
        uint256 min_
    ) public {
        gem = GemLike(gem_);
        end = EndLike(end_);
        proxy = proxy_;
        min = min_;
        live = 1;

        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    function revokesGovernanceAccess() external view returns (bool ret) {
        ret = proxy != address(0);
    }

    // -- math --
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
        require(z >= x);
    }

    // --- Auth ---
    function rely(address usr) external auth {
        wards[usr] = 1;

        emit Rely(usr);
    }

    function deny(address usr) external auth {
        wards[usr] = 0;

        emit Deny(usr);
    }

    modifier auth() {
        require(wards[msg.sender] == 1, "ESM/not-authorized");
        _;
    }

    // -- admin --
    function file(bytes32 what, uint256 data) external auth {
        if (what == "min") {
            require(data > WAD, "ESM/min-too-small");
            min = data;
        } else {
            revert("ESM/file-unrecognized-param");
        }

        emit File(what, data);
    }

    function file(bytes32 what, address data) external auth {
        if (what == "end") {
            end = EndLike(data);
        } else {
            revert("ESM/file-unrecognized-param");
        }

        emit File(what, data);
    }

    function cage() external auth {
        live = 0;
    }

    function fire() external {
        require(live == 1, "ESM/permanently-disabled");
        require(Sum >= min, "ESM/min-not-reached");

        if (proxy != address(0)) {
            DenyLike(end.vat()).deny(proxy);
        }
        end.cage();

        emit Fire();
    }

    function denyProxy(address target) external {
        require(live == 1, "ESM/permanently-disabled");
        require(Sum >= min, "ESM/min-not-reached");

        DenyLike(target).deny(proxy);
        emit DenyProxy(target, proxy);
    }

    function join(uint256 wad) external {
        require(live == 1, "ESM/permanently-disabled");
        require(end.live() == 1, "ESM/system-already-shutdown");

        sum[msg.sender] = add(sum[msg.sender], wad);
        Sum = add(Sum, wad);

        require(
            gem.transferFrom(msg.sender, address(this), wad),
            "ESM/transfer-failed"
        );
        emit Join(msg.sender, wad);
    }

    function burn() external {
        gem.burn(gem.balanceOf(address(this)));
    }
}