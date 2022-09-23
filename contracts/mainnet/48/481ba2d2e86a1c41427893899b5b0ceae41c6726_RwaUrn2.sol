// Copyright (C) 2020, 2021 Lev Livnev <[email protected]>
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;

import {VatAbstract} from "dss-interfaces/dss/VatAbstract.sol";
import {JugAbstract} from "dss-interfaces/dss/JugAbstract.sol";
import {DSTokenAbstract} from "dss-interfaces/dapp/DSTokenAbstract.sol";
import {GemJoinAbstract} from "dss-interfaces/dss/GemJoinAbstract.sol";
import {DaiJoinAbstract} from "dss-interfaces/dss/DaiJoinAbstract.sol";
import {DaiAbstract} from "dss-interfaces/dss/DaiAbstract.sol";

/**
 * @author Lev Livnev <[email protected]>
 * @author Kaue Cano <[email protected]>
 * @author Henrique Barcelos <[email protected]>
 * @title RwaUrn2: A vault for Real-World Assets (RWA).
 * @dev `quit()` can be called before emergency shutdown by an operator.
 * Dai balance from it into the output conduit.
 */
contract RwaUrn2 {
    /// @notice Addresses with admin access on this contract. `wards[usr]`
    mapping(address => uint256) public wards;
    /// @notice Addresses with operator access on this contract. `can[usr]`
    mapping(address => uint256) public can;

    /// @notice Core module address.
    VatAbstract public vat;
    /// @notice The stability fee management module.
    JugAbstract public jug;
    /// @notice The GemJoin adapter for the gem in this urn.
    GemJoinAbstract public gemJoin;
    /// @notice The adapter to mint/burn Dai tokens.
    DaiJoinAbstract public daiJoin;
    /// @notice The destination of Dai drawn from this urn.
    address public outputConduit;

    /**
     * @notice `usr` was granted admin access.
     * @param usr The user address.
     */
    event Rely(address indexed usr);
    /**
     * @notice `usr` admin access was revoked.
     * @param usr The user address.
     */
    event Deny(address indexed usr);
    /**
     * @notice `usr` was granted operator access.
     * @param usr The user address.
     */
    event Hope(address indexed usr);
    /**
     * @notice `usr` operator address was revoked.
     * @param usr The user address.
     */
    event Nope(address indexed usr);
    /**
     * @notice A contract parameter was updated.
     * @param what The changed parameter name. Currently the supported values are: "outputConduit" and "jug".
     * @param data The new value of the parameter.
     */
    event File(bytes32 indexed what, address data);
    /**
     * @notice `wad` amount of the gem was locked in the contract by `usr`.
     * @param usr The operator address.
     * @param wad The amount locked.
     */
    event Lock(address indexed usr, uint256 wad);
    /**
     * @notice `wad` amount of the gem was freed the contract by `usr`.
     * @param usr The operator address.
     * @param wad The amount freed.
     */
    event Free(address indexed usr, uint256 wad);
    /**
     * @notice `wad` amount of Dai was drawn by `usr` into `outputConduit`.
     * @param usr The operator address.
     * @param wad The amount drawn.
     */
    event Draw(address indexed usr, uint256 wad);
    /**
     * @notice `wad` amount of Dai was repaid by `usr`.
     * @param usr The operator address.
     * @param wad The amount repaid.
     */
    event Wipe(address indexed usr, uint256 wad);

    /**
     * @notice The urn outstanding balance was flushed out to `outputConduit`.
     * @dev This can happen only after `cage()` has been called on the `Vat`.
     * @param usr The operator address.
     * @param wad The amount flushed out.
     */
    event Quit(address indexed usr, uint256 wad);

    modifier auth() {
        require(wards[msg.sender] == 1, "RwaUrn2/not-authorized");
        _;
    }

    modifier operator() {
        require(can[msg.sender] == 1, "RwaUrn2/not-operator");
        _;
    }

    /**
     * @param vat_ Core module address.
     * @param jug_ GemJoin adapter for the gem in this urn.
     * @param gemJoin_ Adapter to mint/burn Dai tokens.
     * @param daiJoin_ Stability fee management module.
     * @param outputConduit_ Destination of Dai drawn from this urn.
     */
    constructor(
        address vat_,
        address jug_,
        address gemJoin_,
        address daiJoin_,
        address outputConduit_
    ) public {
        require(outputConduit_ != address(0), "RwaUrn2/invalid-conduit");

        vat = VatAbstract(vat_);
        jug = JugAbstract(jug_);
        gemJoin = GemJoinAbstract(gemJoin_);
        daiJoin = DaiJoinAbstract(daiJoin_);
        outputConduit = outputConduit_;

        wards[msg.sender] = 1;

        DSTokenAbstract(GemJoinAbstract(gemJoin_).gem()).approve(gemJoin_, type(uint256).max);
        DaiAbstract(DaiJoinAbstract(daiJoin_).dai()).approve(daiJoin_, type(uint256).max);
        VatAbstract(vat_).hope(daiJoin_);

        emit Rely(msg.sender);
        emit File("outputConduit", outputConduit_);
        emit File("jug", jug_);
    }

    /*//////////////////////////////////
               Authorization
    //////////////////////////////////*/

    /**
     * @notice Grants `usr` admin access to this contract.
     * @param usr The user address.
     */
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    /**
     * @notice Revokes `usr` admin access from this contract.
     * @param usr The user address.
     */
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    /**
     * @notice Grants `usr` operator access to this contract.
     * @param usr The user address.
     */
    function hope(address usr) external auth {
        can[usr] = 1;
        emit Hope(usr);
    }

    /**
     * @notice Revokes `usr` operator access from this contract.
     * @param usr The user address.
     */
    function nope(address usr) external auth {
        can[usr] = 0;
        emit Nope(usr);
    }

    /*//////////////////////////////////
               Administration
    //////////////////////////////////*/

    /**
     * @notice Updates a contract parameter.
     * @param what The changed parameter name. `"outputConduit" | "jug"`
     * @param data The new value of the parameter.
     */
    function file(bytes32 what, address data) external auth {
        if (what == "outputConduit") {
            require(data != address(0), "RwaUrn2/invalid-conduit");
            outputConduit = data;
        } else if (what == "jug") {
            jug = JugAbstract(data);
        } else {
            revert("RwaUrn2/unrecognised-param");
        }

        emit File(what, data);
    }

    /*//////////////////////////////////
              Vault Operation
    //////////////////////////////////*/

    /**
     * @notice Locks `wad` amount of the gem in the contract.
     * @param wad The amount to lock.
     */
    function lock(uint256 wad) external operator {
        require(wad <= 2**255 - 1, "RwaUrn2/overflow");

        DSTokenAbstract(gemJoin.gem()).transferFrom(msg.sender, address(this), wad);
        // join with this contract's address
        gemJoin.join(address(this), wad);
        vat.frob(gemJoin.ilk(), address(this), address(this), address(this), int256(wad), 0);

        emit Lock(msg.sender, wad);
    }

    /**
     * @notice Frees `wad` amount of the gem from the contract.
     * @param wad The amount to free.
     */
    function free(uint256 wad) external operator {
        require(wad <= 2**255, "RwaUrn2/overflow");

        vat.frob(gemJoin.ilk(), address(this), address(this), address(this), -int256(wad), 0);
        gemJoin.exit(msg.sender, wad);

        emit Free(msg.sender, wad);
    }

    /**
     * @notice Draws `wad` amount of Dai from the contract.
     * @param wad The amount to draw.
     */
    function draw(uint256 wad) external operator {
        bytes32 ilk = gemJoin.ilk();
        jug.drip(ilk);
        (, uint256 rate, , , ) = vat.ilks(ilk);

        uint256 dart = divup(rad(wad), rate);
        require(dart <= 2**255 - 1, "RwaUrn2/overflow");

        vat.frob(ilk, address(this), address(this), address(this), 0, int256(dart));
        daiJoin.exit(outputConduit, wad);
        emit Draw(msg.sender, wad);
    }

    /**
     * @notice Repays `wad` amount of Dai to the contract.
     * @param wad The amount to wipe.
     */
    function wipe(uint256 wad) external {
        daiJoin.join(address(this), wad);

        bytes32 ilk = gemJoin.ilk();
        jug.drip(ilk);

        (, uint256 rate, , , ) = vat.ilks(ilk);
        uint256 dart = rad(wad) / rate;
        require(dart <= 2**255, "RwaUrn2/overflow");

        vat.frob(ilk, address(this), address(this), address(this), 0, -int256(dart));
        emit Wipe(msg.sender, wad);
    }

    /**
     * @notice Flushes out any outstanding Dai balance to `outputConduit` address.
     * @dev Can only be called by an operator or after `cage()` has been called on the Vat.
     */
    function quit() external {
        require(can[msg.sender] == 1 || vat.live() == 0, "RwaUrn2/not-operator-or-still-live");

        DSTokenAbstract dai = DSTokenAbstract(daiJoin.dai());
        uint256 wad = dai.balanceOf(address(this));

        dai.transfer(outputConduit, wad);
        emit Quit(msg.sender, wad);
    }

    /*//////////////////////////////////
                    Math
    //////////////////////////////////*/

    uint256 internal constant RAY = 10**27;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "Math/add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "Math/sub-overflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "Math/mul-overflow");
    }

    /**
     * @dev Divides x/y, but rounds it up.
     */
    function divup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(x, sub(y, 1)) / y;
    }

    /**
     * @dev Converts `wad` (10^18) into a `rad` (10^45) by multiplying it by RAY (10^27).
     */
    function rad(uint256 wad) internal pure returns (uint256 z) {
        return mul(wad, RAY);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

// https://github.com/makerdao/dss/blob/master/src/vat.sol
interface VatAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function can(address, address) external view returns (uint256);
    function hope(address) external;
    function nope(address) external;
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function urns(bytes32, address) external view returns (uint256, uint256);
    function gem(bytes32, address) external view returns (uint256);
    function dai(address) external view returns (uint256);
    function sin(address) external view returns (uint256);
    function debt() external view returns (uint256);
    function vice() external view returns (uint256);
    function Line() external view returns (uint256);
    function live() external view returns (uint256);
    function init(bytes32) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function cage() external;
    function slip(bytes32, address, int256) external;
    function flux(bytes32, address, address, uint256) external;
    function move(address, address, uint256) external;
    function frob(bytes32, address, address, address, int256, int256) external;
    function fork(bytes32, address, address, int256, int256) external;
    function grab(bytes32, address, address, address, int256, int256) external;
    function heal(uint256) external;
    function suck(address, address, uint256) external;
    function fold(bytes32, address, int256) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

// https://github.com/makerdao/dss/blob/master/src/jug.sol
interface JugAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function ilks(bytes32) external view returns (uint256, uint256);
    function vat() external view returns (address);
    function vow() external view returns (address);
    function base() external view returns (uint256);
    function init(bytes32) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, uint256) external;
    function file(bytes32, address) external;
    function drip(bytes32) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

// https://github.com/dapphub/ds-token/blob/master/src/token.sol
interface DSTokenAbstract {
    function name() external view returns (bytes32);
    function symbol() external view returns (bytes32);
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function approve(address) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function push(address, uint256) external;
    function pull(address, uint256) external;
    function move(address, address, uint256) external;
    function mint(uint256) external;
    function mint(address,uint) external;
    function burn(uint256) external;
    function burn(address,uint) external;
    function setName(bytes32) external;
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

// https://github.com/makerdao/dss/blob/master/src/join.sol
interface GemJoinAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function ilk() external view returns (bytes32);
    function gem() external view returns (address);
    function dec() external view returns (uint256);
    function live() external view returns (uint256);
    function cage() external;
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

// https://github.com/makerdao/dss/blob/master/src/join.sol
interface DaiJoinAbstract {
    function wards(address) external view returns (uint256);
    function rely(address usr) external;
    function deny(address usr) external;
    function vat() external view returns (address);
    function dai() external view returns (address);
    function live() external view returns (uint256);
    function cage() external;
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

// https://github.com/makerdao/dss/blob/master/src/dai.sol
interface DaiAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function version() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function nonces(address) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function approve(address, uint256) external returns (bool);
    function push(address, uint256) external;
    function pull(address, uint256) external;
    function move(address, address, uint256) external;
    function permit(address, address, uint256, uint256, bool, uint8, bytes32, bytes32) external;
}