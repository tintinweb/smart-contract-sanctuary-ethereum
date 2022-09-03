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

import {DSTokenAbstract} from "dss-interfaces/dapp/DSTokenAbstract.sol";
import {PsmAbstract} from "dss-interfaces/dss/PsmAbstract.sol";
import {GemJoinAbstract} from "dss-interfaces/dss/GemJoinAbstract.sol";

/**
 * @author Lev Livnev <[email protected]>
 * @author Nazar Duchak <[email protected]>
 * @title An Input Conduit for real-world assets (RWA).
 * @dev This contract differs from the original [RwaInputConduit](https://github.com/makerdao/MIP21-RWA-Example/blob/fce06885ff89d10bf630710d4f6089c5bba94b4d/src/RwaConduit.sol#L20-L39):
 *  - The caller of `push()` is not required to hold MakerDAO governance tokens.
 *  - The `push()` method is permissioned.
 *  - `push()` permissions are managed by `mate()`/`hate()` methods.
 *  - Require PSM address in constructor
 *  - The `push()` method swaps GEM to DAI using PSM
 *  - THe `push()` method with `amount` argument swaps specified amount of GEM to DAI using PSM
 *  - The `quit` method allows moving outstanding GEM balance to `quitTo`. It can be called only by the admin.
 *  - The `quit` method with `amount` argument allows moving specified amount of GEM balance to `quitTo`.
 *  - The `file` method allows updating `quitTo`, `to` addresses. It can be called only by the admin.
 */
contract RwaInputConduit3 {
    /// @notice PSM GEM token contract address
    DSTokenAbstract public immutable gem;
    /// @notice PSM contract address
    PsmAbstract public immutable psm;

    /// @dev This is declared here so the storage layout lines up with RwaInputConduit.
    DSTokenAbstract private __unused_gov;
    /// @notice Dai token contract address
    DSTokenAbstract public dai;
    /// @notice RWA urn contract address
    address public to;

    /// @notice Addresses with admin access on this contract. `wards[usr]`
    mapping(address => uint256) public wards;
    /// @notice Addresses with push access on this contract. `may[usr]`
    mapping(address => uint256) public may;

    /// @notice Exit address
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
     * @notice `wad` amount of Dai was pushed to `to`
     * @param to The RwaUrn address
     * @param wad The amount of Dai
     */
    event Push(address indexed to, uint256 wad);
    /**
     * @notice A contract parameter was updated.
     * @param what The changed parameter name. Currently the supported values are: "quitTo", "to".
     * @param data The new value of the parameter.
     */
    event File(bytes32 indexed what, address data);
    /**
     * @notice The conduit outstanding gem balance was flushed out to `exitAddress`.
     * @param quitTo The quitTo address.
     * @param wad The amount flushed out.
     */
    event Quit(address indexed quitTo, uint256 wad);

    modifier auth() {
        require(wards[msg.sender] == 1, "RwaInputConduit3/not-authorized");
        _;
    }

    modifier isMate() {
        require(may[msg.sender] == 1, "RwaInputConduit3/not-mate");
        _;
    }

    /**
     * @notice Define addresses and gives `msg.sender` admin access.
     * @param _psm PSM contract address.
     * @param _to RwaUrn contract address.
     * @param _quitTo Address to where outstanding GEM balance will go after `quit`
     */
    constructor(
        address _psm,
        address _to,
        address _quitTo
    ) public {
        DSTokenAbstract _gem = DSTokenAbstract(GemJoinAbstract(PsmAbstract(_psm).gemJoin()).gem());
        psm = PsmAbstract(_psm);
        dai = DSTokenAbstract(PsmAbstract(_psm).dai());
        gem = _gem;
        to = _to;
        quitTo = _quitTo;

        // Give unlimited approve to PSM gemjoin
        _gem.approve(address(PsmAbstract(_psm).gemJoin()), type(uint256).max);

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
     * @param what The changed parameter name. `"quitTo", "to"`
     * @param data The new value of the parameter.
     */
    function file(bytes32 what, address data) external auth {
        if (what == "quitTo") {
            require(data != address(0), "RwaInputConduit3/invalid-quit-to-address");
            quitTo = data;
        } else if (what == "to") {
            require(data != address(0), "RwaInputConduit3/invalid-to-address");
            to = data;
        } else {
            revert("RwaInputConduit3/unrecognised-param");
        }

        emit File(what, data);
    }

    /*//////////////////////////////////
               Operations
    //////////////////////////////////*/

    /**
     * @notice Swaps the GEM balance of this contract into DAI through the PSM and push it into the `to` address.
     * @dev `msg.sender` must have received push access through `mate()`.
     */
    function push() external isMate {
        _doPush(gem.balanceOf(address(this)), 0);
    }

    /**
     * @notice Swaps the specified amount of GEM into DAI through the PSM and push it into the `to` address.
     * @dev `msg.sender` must have received push access through `mate()`.
     * @param amt Gem amount.
     */
    function push(uint256 amt) external isMate {
        _doPush(amt, dai.balanceOf(address(this)));
    }

    /**
     * @notice Flushes out any GEM balance to `quitTo` address.
     * @dev `msg.sender` must have received push access through `mate()`.
     */
    function quit() external isMate {
        _doQuit(gem.balanceOf(address(this)));
    }

    /**
     * @notice Flushes out specific amount of GEM balance to `quitTo` address.
     * @dev `msg.sender` must have received push access through `mate()`.
     * @param amt Gem amount.
     */
    function quit(uint256 amt) external isMate {
        _doQuit(amt);
    }

    /**
     * @notice Swaps the specified amount of GEM into DAI through the PSM and push it into the `to` address.
     * @param amt GEM amount.
     * @param prevDaiBalance Previous DAI balance used to track exact amount of GEM swapped for DAI in the PSM. Set to `0` if you want to get all outstanding DAI balance.
     */
    function _doPush(uint256 amt, uint256 prevDaiBalance) internal {
        psm.sellGem(address(this), amt);

        uint256 daiBalance = dai.balanceOf(address(this));
        uint256 daiPushAmt = sub(daiBalance, prevDaiBalance);
        dai.transfer(to, daiPushAmt);

        emit Push(to, daiPushAmt);
    }

    /**
     * @notice Flushes out the specified amount of GEM to the `quitTo` address.
     * @param amt GEM amount.
     */
    function _doQuit(uint256 amt) internal {
        gem.transfer(quitTo, amt);
        emit Quit(quitTo, amt);
    }

    /*//////////////////////////////////
                    Math
    //////////////////////////////////*/

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "Math/sub-overflow");
    }
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