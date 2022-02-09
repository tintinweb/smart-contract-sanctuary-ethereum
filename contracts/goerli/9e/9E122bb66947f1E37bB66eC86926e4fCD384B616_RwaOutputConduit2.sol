/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/RwaOutputConduit2.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.12 <0.7.0;

////// src/RwaOutputConduit2.sol
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

/* pragma solidity ^0.6.12; */

/**
 * @author Lev Livnev <[email protected]>
 * @author Kaue Cano <[email protected]>
 * @author Henrique Barcelos <[email protected]>
 * @title An Output Conduit for real-world assets (RWA).
 * @dev This contract differs from the original [RwaOutputConduit](https://github.com/makerdao/MIP21-RWA-Example/blob/fce06885ff89d10bf630710d4f6089c5bba94b4d/src/RwaConduit.sol#L41-L118):
 *  - The caller of `push()` is not required to hold MakerDAO governance tokens.
 *  - The `push()` method is permissioned.
 *  - `push()` permissions are managed by `mate()`/`hate()` methods.
 */
contract RwaOutputConduit2 {
    /// @notice Dai token contract address
    DSTokenLike_3 public immutable dai;
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
     * @notice `usr` was granted permission to be `pick`ed as the recipient .
     * @param who The user address.
     */
    event Kiss(address indexed who);
    /**
     * @notice `usr` permission to be `pick`ed as the recipient was revoked.
     * @param who The user address.
     */
    event Diss(address indexed who);
    /**
     * @notice `who` address was picked as the recipient.
     * @param who The user address.
     */
    event Pick(address indexed who);
    /**
     * @notice `wad` amount of Dai was pushed to the recipient `to`.
     * @param to The Dai recipient address
     * @param wad The amount of Dai
     */
    event Push(address indexed to, uint256 wad);

    /**
     * @notice Defines Dai address and gives `msg.sender` admin access.
     * @param _dai Dai address.
     */
    constructor(address _dai) public {
        dai = DSTokenLike_3(_dai);
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    modifier auth() {
        require(wards[msg.sender] == 1, "RwaOutputConduit2/not-authorized");
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
     * @notice Grants `who` permission to be `pick`ed as the recipient.
     * @param who The user address.
     */
    function kiss(address who) public auth {
        bud[who] = 1;
        emit Kiss(who);
    }

    /**
     * @notice Revokes `who` permission to be `pick`ed as the recipient.
     * @dev Resets `to` to `address(0)` if `who` is current `to` target.
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
     * @notice Sets `who` address as the recipient.
     * @dev `who` address must either be `address(0)` or have been `kiss`ed before.
     * @param who Recipient Dai address.
     */
    function pick(address who) public {
        require(can[msg.sender] == 1, "RwaOutputConduit2/not-operator");
        require(bud[who] == 1 || who == address(0), "RwaOutputConduit2/not-bud");
        to = who;
        emit Pick(who);
    }

    /**
     * @notice Pushes contract Dai balance to the recipient address.
     * @dev `msg.sender` must have been `mate`d and `to` must have been `pick`ed.
     */
    function push() external {
        require(may[msg.sender] == 1, "RwaOutputConduit2/not-mate");
        require(to != address(0), "RwaOutputConduit2/to-not-picked");
        uint256 balance = dai.balanceOf(address(this));
        address recipient = to;
        // sets `to` to address(0) so the flow is restarted
        to = address(0);

        dai.transfer(recipient, balance);
        emit Push(recipient, balance);
    }
}

/**
 * @title A subset of `DSToken` containing only the methods required in this file.
 */
interface DSTokenLike_3 {
    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external returns (uint256);
}