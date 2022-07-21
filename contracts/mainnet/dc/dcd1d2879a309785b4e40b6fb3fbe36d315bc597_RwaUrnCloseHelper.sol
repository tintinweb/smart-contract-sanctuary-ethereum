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
import {GemJoinAbstract} from "dss-interfaces/dss/GemJoinAbstract.sol";
import {DaiJoinAbstract} from "dss-interfaces/dss/DaiJoinAbstract.sol";
import {DaiAbstract} from "dss-interfaces/dss/DaiAbstract.sol";
import {DSTokenAbstract} from "dss-interfaces/dapp/DSTokenAbstract.sol";

/**
 * @author Henrique Barcelos <[email protected]>
 * @title Simplifies the interaction with vaults for Real-World Assets.
 */
contract RwaUrnCloseHelper {
    /**
     * @notice Wipes all the outstanding debt from the `urn` and transfers the collateral tokens to the caller.
     * @dev It requires that enough Dai to repay the debt is already deposited into the `urn`.
     * @dev Any remaining Dai balance is sent back to the output conduit when possible.
     * @param urn The RwaUrn vault targeted by the repayment.
     */
    function close(address urn) external {
        uint256 wad = _estimateWipeAllWad(urn, block.timestamp);
        require(RwaUrnLike(urn).can(msg.sender) == 1, "RwaUrnCloseHelper/not-operator");

        RwaUrnLike(urn).wipe(wad);

        GemJoinAbstract gemJoin = RwaUrnLike(urn).gemJoin();

        VatAbstract vat = RwaUrnLike(urn).vat();
        bytes32 ilk = gemJoin.ilk();
        (uint256 ink, ) = vat.urns(ilk, urn);
        RwaUrnLike(urn).free(ink);

        DSTokenAbstract gem = DSTokenAbstract(gemJoin.gem());
        gem.transfer(msg.sender, ink);

        // By using try..catch we make this method compatible with implementations of
        // `RwaUrn` whose `quit()` method can only be called after Emergency Shutdown.
        try RwaUrnLike(urn).quit() {} catch {}
    }

    /**
     * @notice Estimates the amount of Dai required to fully repay a loan at `when` given time.
     * @dev It assumes there will be no changes in the base fee or the ilk stability fee between now and `when`.
     * @param urn The RwaUrn vault targeted by the repayment.
     * @param when The unix timestamp by which the repayment will be made. It must NOT be in the past.
     * @return wad The amount of Dai required to make a full repayment.
     */
    function estimateWipeAllWad(address urn, uint256 when) external view returns (uint256 wad) {
        require(when >= block.timestamp, "RwaUrnCloseHelper/invalid-date");
        return _estimateWipeAllWad(urn, when);
    }

    /**
     * @notice Estimates the amount of Dai required to fully repay a loan at `when` given time.
     * @dev It assumes there will be no changes in the base fee or the ilk stability fee between now and `when`.
     * @param urn The RwaUrn vault targeted by the repayment.
     * @param when The unix timestamp by which the repayment will be made.
     * @return wad The amount of Dai required to make a full repayment.
     */
    function _estimateWipeAllWad(address urn, uint256 when) internal view returns (uint256 wad) {
        // Law of Demeter anybody? https://en.wikipedia.org/wiki/Law_of_Demeter
        bytes32 ilk = RwaUrnLike(urn).gemJoin().ilk();
        VatAbstract vat = RwaUrnLike(urn).vat();
        JugAbstract jug = RwaUrnLike(urn).jug();

        (uint256 duty, uint256 rho) = jug.ilks(ilk);
        (, uint256 curr, , , ) = vat.ilks(ilk);
        // This was adapted from how the Jug calculates the rate on drip().
        // https://github.com/makerdao/dss/blob/master/src/jug.sol#L125
        uint256 rate = rmul(rpow(add(jug.base(), duty), when - rho), curr);

        (, uint256 art) = vat.urns(ilk, urn);

        wad = rmulup(art, rate);
    }

    /*//////////////////////////////////
                    Math
    //////////////////////////////////*/

    uint256 internal constant WAD = 10**18;
    uint256 internal constant RAY = 10**27;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "DSMath/add-overflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "DSMath/mul-overflow");
    }

    /**
     * @dev Multiplies a WAD `x` by a `RAY` `y` and returns the WAD `z`.
     * Rounds up if the rad precision dust >0.5 or down if <=0.5.
     * Rounds to zero if `x`*`y` < WAD / 2.
     */
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    /**
     * @dev Multiplies a WAD `x` by a `RAY` `y` and returns the WAD `z`.
     * Rounds up if the rad precision has some dust.
     */
    function rmulup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY - 1) / RAY;
    }

    /**
     * @dev This famous algorithm is called "exponentiation by squaring"
     * and calculates x^n with x as fixed-point and n as regular unsigned.
     *
     * It's O(log n), instead of O(n) for naive repeated multiplication.
     *
     * These facts are why it works:
     *
     *  If n is even, then x^n = (x^2)^(n/2).
     *  If n is odd,  then x^n = x * x^(n-1),
     *   and applying the equation for even x gives
     *    x^n = x * (x^2)^((n-1) / 2).
     *
     *  Also, EVM division is flooring and
     *    floor[(n-1) / 2] = floor[n / 2].
     */
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

interface RwaUrnLike {
    function can(address usr) external view returns (uint256);

    function vat() external view returns (VatAbstract);

    function jug() external view returns (JugAbstract);

    function daiJoin() external view returns (DaiJoinAbstract);

    function gemJoin() external view returns (GemJoinAbstract);

    function wipe(uint256 wad) external;

    function free(uint256 wad) external;

    function quit() external;
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
    function transfer(address, uint256) external;
    function transferFrom(address, address, uint256) external returns (bool);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function approve(address, uint256) external returns (bool);
    function push(address, uint256) external;
    function pull(address, uint256) external;
    function move(address, address, uint256) external;
    function permit(address, address, uint256, uint256, bool, uint8, bytes32, bytes32) external;
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