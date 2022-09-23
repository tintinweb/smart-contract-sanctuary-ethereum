// SPDX-FileCopyrightText: © 2021 Lev Livnev <[email protected]>
// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
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

import {DaiAbstract} from "dss-interfaces/dss/DaiAbstract.sol";
import {PsmAbstract} from "dss-interfaces/dss/PsmAbstract.sol";
import {GemAbstract} from "dss-interfaces/ERC/GemAbstract.sol";
import {GemJoinAbstract} from "dss-interfaces/dss/GemJoinAbstract.sol";

/**
 * @author Lev Livnev <[email protected]>
 * @author Nazar Duchak <[email protected]>
 * @title An Output Conduit for real-world assets (RWA).
 * @dev This contract differs from the original [RwaOutputConduit](https://github.com/makerdao/MIP21-RWA-Example/blob/fce06885ff89d10bf630710d4f6089c5bba94b4d/src/RwaConduit.sol#L41-L118):
 *  - The caller of `push()` is not required to hold MakerDAO governance tokens.
 *  - The `push()` method is permissioned.
 *  - `push()` permissions are managed by `mate()`/`hate()` methods.
 *  - Requires DAI, GEM and PSM addresses in the constructor.
 *      - DAI and GEM are immutable, PSM can be replaced as long as it uses the same DAI and GEM.
 *  - The `push()` method swaps entire DAI balance to GEM using PSM.
 *  - THe `push(uint256)` method swaps specified amount of DAI to GEM using PSM.
 *  - The `quit()` method allows moving outstanding DAI balance to `quitTo`. It can be called only by `mate`d addresses.
 *  - The `quit(uint256)` method allows moving the specified amount of DAI balance to `quitTo`. It can be called only by `mate`d addresses.
 *  - The `file` method allows updating `quitTo`, `psm` addresses. It can be called only by the admin.
 */
contract RwaOutputConduit3 {
    /// @notice PSM GEM token contract address.
    GemAbstract public immutable gem;
    /// @notice DAI token contract address.
    DaiAbstract public immutable dai;
    /// @dev DAI/GEM resolution difference.
    uint256 private immutable to18ConversionFactor;

    /// @notice Addresses with admin access on this contract. `wards[usr]`
    mapping(address => uint256) public wards;
    /// @dev Addresses with operator access on this contract. `can[usr]`
    mapping(address => uint256) public can;
    /// @notice Whitelist for addresses which can be picked. `bud[who]`
    mapping(address => uint256) public bud;
    /// @notice Addresses with push access on this contract. `may[usr]`
    mapping(address => uint256) public may;

    /// @notice PSM contract address.
    PsmAbstract public psm;
    /// @notice GEM Recipient address.
    address public to;
    /// @notice Destination address for DAI after calling `quit`.
    address public quitTo;

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
     * @notice `usr` operator access was revoked.
     * @param usr The user address.
     */
    event Nope(address indexed usr);
    /**
     * @notice `usr` was granted push access.
     * @param usr The user address.
     */
    event Mate(address indexed usr);
    /**
     * @notice `usr` push access was revoked.
     * @param usr The user address.
     */
    event Hate(address indexed usr);
    /**
     * @notice `who` address whitelisted for pick.
     * @param who The user address.
     */
    event Kiss(address indexed who);
    /**
     * @notice `who` address was removed from whitelist.
     * @param who The user address.
     */
    event Diss(address indexed who);
    /**
     * @notice `who` address was picked as the recipient.
     * @param who The user address.
     */
    event Pick(address indexed who);
    /**
     * @notice `amt` amount of GEM was pushed to the recipient `to`.
     * @param to Destination address for GEM.
     * @param amt The amount of GEM.
     */
    event Push(address indexed to, uint256 amt);
    /**
     * @notice A contract parameter was updated.
     * @param what The changed parameter name. Currently the supported values are: "quitTo", "psm".
     * @param data The new value of the parameter.
     */
    event File(bytes32 indexed what, address data);
    /**
     * @notice The conduit outstanding DAI balance was flushed out to `quitTo` address.
     * @param quitTo The quitTo address.
     * @param wad The amount of DAI flushed out.
     */
    event Quit(address indexed quitTo, uint256 wad);
    /**
     * @notice `amt` outstanding `token` balance was flushed out to `usr`.
     * @param token The token address.
     * @param usr The destination address.
     * @param amt The amount of `token` flushed out.
     */
    event Yank(address indexed token, address indexed usr, uint256 amt);

    modifier auth() {
        require(wards[msg.sender] == 1, "RwaOutputConduit3/not-authorized");
        _;
    }

    modifier onlyMate() {
        require(may[msg.sender] == 1, "RwaOutputConduit3/not-mate");
        _;
    }

    /**
     * @notice Defines addresses and gives `msg.sender` admin access.
     * @param _psm PSM contract address.
     * @param _dai DAI contract address.
     * @param _gem GEM contract address.
     */
    constructor(
        address _dai,
        address _gem,
        address _psm
    ) public {
        require(PsmAbstract(_psm).dai() == _dai, "RwaOutputConduit3/wrong-dai-for-psm");
        require(GemJoinAbstract(PsmAbstract(_psm).gemJoin()).gem() == _gem, "RwaOutputConduit3/wrong-gem-for-psm");

        // We assume that DAI will alway have 18 decimals
        to18ConversionFactor = 10**_sub(18, GemAbstract(_gem).decimals());

        psm = PsmAbstract(_psm);
        dai = DaiAbstract(_dai);
        gem = GemAbstract(_gem);

        // Give unlimited approval to PSM
        DaiAbstract(_dai).approve(_psm, type(uint256).max);

        wards[msg.sender] = 1;
        emit Rely(msg.sender);
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

    /**
     * @notice Grants `usr` push access to this contract.
     * @param usr The user address.
     */
    function mate(address usr) external auth {
        may[usr] = 1;
        emit Mate(usr);
    }

    /**
     * @notice Revokes `usr` push access from this contract.
     * @param usr The user address.
     */
    function hate(address usr) external auth {
        may[usr] = 0;
        emit Hate(usr);
    }

    /**
     * @notice Whitelist `who` address for `pick`.
     * @param who The user address.
     */
    function kiss(address who) external auth {
        bud[who] = 1;
        emit Kiss(who);
    }

    /**
     * @notice Remove `who` address from `pick` whitelist.
     * @param who The user address.
     */
    function diss(address who) external auth {
        if (to == who) to = address(0);
        bud[who] = 0;
        emit Diss(who);
    }

    /*//////////////////////////////////
               Administration
    //////////////////////////////////*/

    /**
     * @notice Updates a contract parameter.
     * @param what The changed parameter name. `"quitTo", "psm"`.
     * @param data The new value of the parameter.
     */
    function file(bytes32 what, address data) external auth {
        if (what == "quitTo") {
            quitTo = data;
        } else if (what == "psm") {
            require(PsmAbstract(data).dai() == address(dai), "RwaOutputConduit3/wrong-dai-for-psm");
            require(
                GemJoinAbstract(PsmAbstract(data).gemJoin()).gem() == address(gem),
                "RwaOutputConduit3/wrong-gem-for-psm"
            );

            // Revoke approval for the old PSM
            dai.approve(address(psm), 0);
            // Give unlimited approval to the new PSM
            dai.approve(data, type(uint256).max);

            psm = PsmAbstract(data);
        } else {
            revert("RwaOutputConduit3/unrecognised-param");
        }

        emit File(what, data);
    }

    /**
     * @notice Sets `who` address as the recipient.
     * @param who Recipient address.
     * @dev `who` address should have been whitelisted using `kiss`.
     */
    function pick(address who) external {
        require(can[msg.sender] == 1, "RwaOutputConduit3/not-operator");
        require(bud[who] == 1 || who == address(0), "RwaOutputConduit3/not-bud");
        to = who;
        emit Pick(who);
    }

    /*//////////////////////////////////
               Operations
    //////////////////////////////////*/

    /**
     * @notice Swaps the DAI balance of this contract into GEM through the PSM and push it into the recipient address.
     * @dev `msg.sender` must have received push access through `mate()`.
     */
    function push() external onlyMate {
        _doPush(dai.balanceOf(address(this)));
    }

    /**
     * @notice Swaps the specified amount of DAI into GEM through the PSM and push it to the recipient address.
     * @dev `msg.sender` must have received push access through `mate()`.
     * @param wad DAI amount.
     */
    function push(uint256 wad) external onlyMate {
        _doPush(wad);
    }

    /**
     * @notice Flushes out any DAI balance to `quitTo` address.
     * @dev `msg.sender` must have received push access through `mate()`.
     */
    function quit() external onlyMate {
        _doQuit(dai.balanceOf(address(this)));
    }

    /**
     * @notice Flushes out the specified amount of DAI to the `quitTo` address.
     * @dev `msg.sender` must have received push access through `mate()`.
     * @param wad DAI amount.
     */
    function quit(uint256 wad) external onlyMate {
        _doQuit(wad);
    }

    /**
     * @notice Flushes out `amt` of `token` sitting in this contract to `usr` address.
     * @dev Can only be called by the admin.
     * @param token Token address.
     * @param usr Destination address.
     * @param amt Token amount.
     */
    function yank(
        address token,
        address usr,
        uint256 amt
    ) external auth {
        GemAbstract(token).transfer(usr, amt);
        emit Yank(token, usr, amt);
    }

    /**
     * @notice Calculates the amount of GEM received for swapping `wad` of DAI.
     * @param wad DAI amount.
     * @return amt Expected GEM amount.
     */
    function expectedGemAmt(uint256 wad) public view returns (uint256 amt) {
        return _mul(wad, WAD) / _mul(_add(WAD, psm.tout()), to18ConversionFactor);
    }

    /**
     * @notice Calculates the required amount of DAI to get `amt` amount of GEM.
     * @param amt GEM amount.
     * @return wad Required DAI amount.
     */
    function requiredDaiWad(uint256 amt) external view returns (uint256 wad) {
        uint256 amt18 = _mul(amt, to18ConversionFactor);
        uint256 fee = _mul(amt18, psm.tout()) / WAD;
        return _add(amt18, fee);
    }

    /**
     * @notice Swaps the specified amount of DAI into GEM through the PSM and push it to the recipient address.
     * @param wad DAI amount.
     */
    function _doPush(uint256 wad) internal {
        require(to != address(0), "RwaOutputConduit3/to-not-picked");

        // We might lose some dust here because of rounding errors. I.e.: USDC has 6 dec and DAI has 18.
        uint256 gemAmt = expectedGemAmt(wad);
        require(gemAmt > 0, "RwaOutputConduit3/insufficient-swap-gem-amount");

        address recipient = to;
        to = address(0);

        psm.buyGem(recipient, gemAmt);
        emit Push(recipient, gemAmt);
    }

    /**
     * @notice Flushes out the specified amount of DAI to `quitTo` address.
     * @param wad The DAI amount.
     */
    function _doQuit(uint256 wad) internal {
        require(quitTo != address(0), "RwaOutputConduit3/invalid-quit-to-address");

        dai.transfer(quitTo, wad);
        emit Quit(quitTo, wad);
    }

    /*//////////////////////////////////
                    Math
    //////////////////////////////////*/

    uint256 internal constant WAD = 10**18;

    function _add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "Math/add-overflow");
    }

    function _sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "Math/sub-overflow");
    }

    function _mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "Math/mul-overflow");
    }
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

// https://github.com/makerdao/dss-psm/blob/master/src/psm.sol
interface PsmAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function gemJoin() external view returns (address);
    function dai() external view returns (address);
    function daiJoin() external view returns (address);
    function ilk() external view returns (bytes32);
    function vow() external view returns (address);
    function tin() external view returns (uint256);
    function tout() external view returns (uint256);
    function file(bytes32 what, uint256 data) external;
    function hope(address) external;
    function nope(address) external;
    function sellGem(address usr, uint256 gemAmt) external;
    function buyGem(address usr, uint256 gemAmt) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

// A base ERC-20 abstract class
// https://eips.ethereum.org/EIPS/eip-20
interface GemAbstract {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
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