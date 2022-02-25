/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/RwaInputConduit2.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.12 <0.7.0;

////// src/RwaInputConduit2.sol
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
 * @title An Input Conduit for real-world assets (RWA).
 * @dev This contract differs from the original [RwaInputConduit](https://github.com/makerdao/MIP21-RWA-Example/blob/fce06885ff89d10bf630710d4f6089c5bba94b4d/src/RwaConduit.sol#L20-L39):
 *  - The caller of `push()` is not required to hold MakerDAO governance tokens.
 *  - The `push()` method is permissioned.
 *  - `push()` permissions are managed by `mate()`/`hate()` methods.
 */
contract RwaInputConduit2 {
    /// @notice Dai token contract address
    DSTokenLike_2 public immutable dai;
    /// @notice RWA urn contract address
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
        dai = DSTokenLike_2(_dai);
        to = _to;

        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    modifier auth() {
        require(wards[msg.sender] == 1, "RwaInputConduit2/not-authorized");
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
        require(may[msg.sender] == 1, "RwaInputConduit2/not-mate");

        uint256 balance = dai.balanceOf(address(this));
        dai.transfer(to, balance);

        emit Push(to, balance);
    }
}

/**
 * @title A subset of `DSToken` containing only the methods required in this file.
 */
interface DSTokenLike_2 {
    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external returns (uint256);
}