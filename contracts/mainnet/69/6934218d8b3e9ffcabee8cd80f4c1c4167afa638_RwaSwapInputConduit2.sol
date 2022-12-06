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

import {GemAbstract} from "dss-interfaces/ERC/GemAbstract.sol";
import {DaiAbstract} from "dss-interfaces/dss/DaiAbstract.sol";
import {PsmAbstract} from "dss-interfaces/dss/PsmAbstract.sol";
import {GemJoinAbstract} from "dss-interfaces/dss/GemJoinAbstract.sol";

/**
 * @author Lev Livnev <[email protected]>
 * @author Nazar Duchak <[email protected]>
 * @title An Input Conduit for real-world assets (RWA).
 * @dev This contract differs from the original [RwaInputConduit](https://github.com/makerdao/MIP21-RWA-Example/blob/fce06885ff89d10bf630710d4f6089c5bba94b4d/src/RwaConduit.sol#L20-L39):
 *  - Requires DAI, GEM and PSM addresses in the constructor.
 *      - DAI and GEM are immutable, PSM can be replaced as long as it uses the same DAI and GEM.
 *  - The caller of `push()` is not required to hold MakerDAO governance tokens.
 *  - The `push()` method is permissionless.
 *  - The `push()` method swaps entire GEM balance to DAI using PSM.
 *  - The `push(uint256)` method swaps specified amount of GEM to DAI using PSM.
 *  - The `quit()` method allows moving outstanding GEM balance to `quitTo`. It can be called only by `mate`d addresses.
 *  - The `quit(uint256)` method allows moving the specified amount of GEM balance to `quitTo`. It can be called only by `mate`d addresses.
 *  - The `file(bytes32, address)` method allows updating `quitTo`, `to`, `psm` addresses. It can be called only by the admin.
 */
contract RwaSwapInputConduit2 {
    /// @notice PSM GEM token contract address.
    GemAbstract public immutable gem;
    /// @notice DAI token contract address.
    DaiAbstract public immutable dai;
    /// @dev DAI/GEM resolution difference.
    uint256 private immutable to18ConversionFactor;

    /// @notice Addresses with admin access on this contract. `wards[usr]`
    mapping(address => uint256) public wards;
    /// @notice Addresses with quit access on this contract. `may[usr]`
    mapping(address => uint256) public may;

    /// @notice PSM contract address.
    PsmAbstract public psm;
    /// @notice Recipient address for DAI.
    address public to;
    /// @notice Destination address for GEM after calling `quit`.
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
     * @notice `wad` amount of Dai was pushed to `to`.
     * @param to Recipient address for DAI.
     * @param wad The amount of DAI.
     */
    event Push(address indexed to, uint256 wad);
    /**
     * @notice A contract parameter was updated.
     * @param what The changed parameter name. Currently the supported values are: "quitTo", "to", "psm".
     * @param data The new value of the parameter.
     */
    event File(bytes32 indexed what, address data);
    /**
     * @notice The conduit outstanding GEM balance was flushed out to `quitTo`.
     * @param quitTo The quitTo address.
     * @param wad The amount of GEM flushed out.
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
        require(wards[msg.sender] == 1, "RwaSwapInputConduit2/not-authorized");
        _;
    }

    modifier onlyMate() {
        require(may[msg.sender] == 1, "RwaSwapInputConduit2/not-mate");
        _;
    }

    /**
     * @notice Defines addresses and gives `msg.sender` admin access.
     * @param _psm PSM contract address.
     * @param _dai DAI contract address.
     * @param _gem GEM contract address.
     * @param _to RwaUrn contract address.
     */
    constructor(
        address _dai,
        address _gem,
        address _psm,
        address _to
    ) public {
        require(_to != address(0), "RwaSwapInputConduit2/invalid-to-address");
        require(PsmAbstract(_psm).dai() == _dai, "RwaSwapInputConduit2/wrong-dai-for-psm");
        require(GemJoinAbstract(PsmAbstract(_psm).gemJoin()).gem() == _gem, "RwaSwapInputConduit2/wrong-gem-for-psm");

        // We assume that DAI will alway have 18 decimals
        to18ConversionFactor = 10**_sub(18, GemAbstract(_gem).decimals());

        psm = PsmAbstract(_psm);
        dai = DaiAbstract(_dai);
        gem = GemAbstract(_gem);

        to = _to;

        // Give unlimited approval to PSM gemjoin
        GemAbstract(_gem).approve(address(psm.gemJoin()), type(uint256).max);

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

    /*//////////////////////////////////
               Administration
    //////////////////////////////////*/

    /**
     * @notice Updates a contract parameter.
     * @dev `to` and `quitTo` can be set to `address(0)` to disable `push` and `quit` respectively.
     * @param what The changed parameter name. `"to", "quitTo", "psm"`
     * @param data The new value of the parameter.
     */
    function file(bytes32 what, address data) external auth {
        if (what == "quitTo") {
            quitTo = data;
        } else if (what == "to") {
            to = data;
        } else if (what == "psm") {
            require(PsmAbstract(data).dai() == address(dai), "RwaSwapInputConduit2/wrong-dai-for-psm");
            require(
                GemJoinAbstract(PsmAbstract(data).gemJoin()).gem() == address(gem),
                "RwaSwapInputConduit2/wrong-gem-for-psm"
            );

            // Revoke approval for the old PSM gemjoin
            gem.approve(address(psm.gemJoin()), 0);
            // Give unlimited approval to the new PSM gemjoin
            gem.approve(address(PsmAbstract(data).gemJoin()), type(uint256).max);

            psm = PsmAbstract(data);
        } else {
            revert("RwaSwapInputConduit2/unrecognised-param");
        }

        emit File(what, data);
    }

    /*//////////////////////////////////
               Operations
    //////////////////////////////////*/

    /**
     * @notice Swaps the GEM balance of this contract into DAI through the PSM and push it into the recipient address.
     */
    function push() external {
        _doPush(gem.balanceOf(address(this)));
    }

    /**
     * @notice Swaps the specified amount of GEM into DAI through the PSM and push it into the recipient address.
     * @param amt Gem amount.
     */
    function push(uint256 amt) external {
        _doPush(amt);
    }

    /**
     * @notice Flushes out any GEM balance to `quitTo` address.
     * @dev `msg.sender` must have received push access through `mate()`.
     */
    function quit() external onlyMate {
        _doQuit(gem.balanceOf(address(this)));
    }

    /**
     * @notice Flushes out the specified amount of GEM balance to `quitTo` address.
     * @dev `msg.sender` must have received push access through `mate()`.
     * @param amt Gem amount.
     */
    function quit(uint256 amt) external onlyMate {
        _doQuit(amt);
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
     * @notice Calculates the amount of DAI received for swapping `amt` of GEM.
     * @param amt GEM amount.
     * @return wad Expected DAI amount.
     */
    function expectedDaiWad(uint256 amt) public view returns (uint256 wad) {
        uint256 amt18 = _mul(amt, to18ConversionFactor);
        uint256 fee = _mul(amt18, psm.tin()) / WAD;
        return _sub(amt18, fee);
    }

    /**
     * @notice Calculates the required amount of GEM to get `wad` amount of DAI.
     * @param wad DAI amount.
     * @return amt Required GEM amount.
     */
    function requiredGemAmt(uint256 wad) external view returns (uint256 amt) {
        return _mul(wad, WAD) / _mul(_sub(WAD, psm.tin()), to18ConversionFactor);
    }

    /**
     * @notice Swaps the specified amount of GEM into DAI through the PSM and push it into the recipient address.
     * @dev If `to` is set to `address(0)`, if effectively means this methos is currently disabled.
     * @param amt GEM amount.
     */
    function _doPush(uint256 amt) internal {
        require(to != address(0), "RwaSwapInputConduit2/invalid-to-address");

        psm.sellGem(to, amt);
        emit Push(to, expectedDaiWad(amt));
    }

    /**
     * @notice Flushes out the specified amount of GEM to the `quitTo` address.
     * @dev If `quitTo` is set to `address(0)`, if effectively means this method is currently disabled.
     * @param amt GEM amount.
     */
    function _doQuit(uint256 amt) internal {
        require(quitTo != address(0), "RwaSwapInputConduit2/invalid-quit-to-address");

        gem.transfer(quitTo, amt);
        emit Quit(quitTo, amt);
    }

    /*//////////////////////////////////
                    Math
    //////////////////////////////////*/

    uint256 internal constant WAD = 10**18;

    function _sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "Math/sub-overflow");
    }

    function _mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "Math/mul-overflow");
    }
}