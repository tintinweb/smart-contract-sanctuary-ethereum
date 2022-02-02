/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

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
pragma solidity ^0.6.12;

/**
 * @title An subset of `DSToken` containing only the methods required in this file.
 */
interface DSTokenLike {
    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external returns (uint256);
}

/**
 * @author Lev Livnev <[email protected]>
 * @author Kaue Cano <[email protected]>
 * @title An Input Conduit for real-world assets (RWA).
 * @dev After the deploy the owner must call `mate()` for the DIIS Group wallet.
 */
contract RwaInputConduit {
    /// @notice Dai token contract address
    DSTokenLike public immutable dai;
    /// @notice RwaUrn contract address
    address public immutable to;

    /// @notice Addresses with admin access on this contract. `wards[usr]`
    mapping(address => uint256) public wards;
    /// @notice Addresses with push access on this contract. `may[usr]`
    mapping(address => uint256) public may;

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
     * @notice Define addresses and gives `msg.sender` admin access.
     * @param _dai Dai token contract address.
     * @param _to RwaUrn contract address.
     */
    constructor(address _dai, address _to) public {
        dai = DSTokenLike(_dai);
        to = _to;

        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    modifier auth() {
        require(wards[msg.sender] == 1, "RwaInputConduit/not-authorized");
        _;
    }

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

    /**
     * @notice Pushes contract Dai balance into RwaUrn address.
     * @dev `msg.sender` must first receive push acess through mate().
     */
    function push() external {
        require(may[msg.sender] == 1, "RwaInputConduit/not-mate");

        uint256 balance = dai.balanceOf(address(this));
        dai.transfer(to, balance);

        emit Push(to, balance);
    }
}

/**
 * @author Lev Livnev <[email protected]>
 * @author Kaue Cano <[email protected]>
 * @title An Output Conduit for real-world assets (RWA).
 */
contract RwaOutputConduit {
    /// @notice Dai token contract address
    DSTokenLike public immutable dai;
    /// @notice Dai output address
    address public to;

    /// @notice Addresses with admin access on this contract. `wards[usr]`
    mapping(address => uint256) public wards;
    /// @notice Addresses with push access on this contract. `may[usr]`
    mapping(address => uint256) public may;
    /// @notice Addresses with operator access on this contract. `can[usr]`
    mapping(address => uint256) public can;
    /// @notice Addresses with kiss permissions on this contract. `bud[who]`
    mapping(address => uint256) public bud;

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
     * @notice `usr` was granted kiss permissions.
     * @param who The user address.
     */
    event Kiss(address indexed who);
    /**
     * @notice `usr` kiss permissions were revoked.
     * @param who The user address.
     */
    event Diss(address indexed who);
    /**
     * @notice `who` address was picked as output of push()
     * @param who The user address.
     */
    event Pick(address indexed who);
    /**
     * @notice `wad` amount of Dai was pushed to `to`
     * @param to The Dai output address
     * @param wad The amount of Dai
     */
    event Push(address indexed to, uint256 wad);

    /**
     * @notice Defines Dai address and gives `msg.sender` admin access.
     * @param _dai Dai address.
     */
    constructor(address _dai) public {
        dai = DSTokenLike(_dai);
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    modifier auth() {
        require(wards[msg.sender] == 1, "RwaOutputConduit/not-authorized");
        _;
    }

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
     * @notice Grants `who` kiss permissions to this contract.
     * @param who The user address.
     */
    function kiss(address who) public auth {
        bud[who] = 1;
        emit Kiss(who);
    }

    /**
     * @notice Revokes `who` kiss permissions to this contract.
     * @dev Resets `to` to address(0) if `who` is current `to` target.
     * @param who The user address.
     */
    function diss(address who) public auth {
        if (to == who) {
            to = address(0);
        }
        bud[who] = 0;
        emit Diss(who);
    }

    /**
     * @notice Sets `who` address as `to` output target.
     * @dev `who` address must receive kiss() permissions by auth before this funcion is called.
     * @param who Output Dai address.
     */
    function pick(address who) public {
        require(can[msg.sender] == 1, "RwaOutputConduit/not-operator");
        require(bud[who] == 1 || who == address(0), "RwaOutputConduit/not-bud");
        to = who;
        emit Pick(who);
    }

    /**
     * @notice Pushes contract Dai balance into `to` address.
     * @dev `msg.sender` must first receive push acess through mate() and also kiss() + pick() a `to` address.
     */
    function push() external {
        require(may[msg.sender] == 1, "RwaOutputConduit/not-mate");
        require(to != address(0), "RwaOutputConduit/to-not-picked");
        uint256 balance = dai.balanceOf(address(this));
        address recipient = to;
        /// defaults `to` to address(0) fo flow is restarted
        to = address(0);

        dai.transfer(recipient, balance);
        emit Push(recipient, balance);
    }
}