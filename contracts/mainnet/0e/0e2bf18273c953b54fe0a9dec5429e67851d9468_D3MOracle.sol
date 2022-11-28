/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

// hevm: flattened sources of src/D3MOracle.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.14 <0.9.0;

////// src/D3MOracle.sol
// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
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

/* pragma solidity ^0.8.14; */

interface VatLike_2 {
    function live() external view returns (uint256);
}

interface HubLike {
    function culled(bytes32) external view returns (uint256);
}

contract D3MOracle {
    // --- Auth ---
    /**
        @notice Maps address that have permission in the Pool.
        @dev 1 = allowed, 0 = no permission
        @return authorization 1 or 0
    */
    mapping (address => uint256) public wards;
    address public hub;

    address public immutable vat;
    bytes32 public immutable ilk;

    uint256 internal constant WAD = 10 ** 18;

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event File(bytes32 indexed what, address data);

    constructor(address vat_, bytes32 ilk_) {
        vat = vat_;
        ilk = ilk_;

        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    /// @notice Modifier will revoke if msg.sender is not authorized.
    modifier auth {
        require(wards[msg.sender] == 1, "D3MOracle/not-authorized");
        _;
    }

    // --- Administration ---
    /**
        @notice Makes an address authorized to perform auth'ed functions.
        @dev msg.sender must be authorized.
        @param usr address to be authorized
    */
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    /**
        @notice De-authorizes an address from performing auth'ed functions.
        @dev msg.sender must be authorized.
        @param usr address to be de-authorized
    */
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    /**
        @notice update an address.
        @dev msg.sender must be authorized.
        @param what name of what we are updating.
        @param data address we are setting it to
    */
    function file(bytes32 what, address data) external auth {
        require(VatLike_2(vat).live() == 1, "D3MOracle/no-file-during-shutdown");

        if (what == "hub") hub = data;
        else revert("D3MOracle/file-unrecognized-param");
        emit File(what, data);
    }

    /**
        @notice Return value and status of the oracle
        @return val always 1 WAD
        @return ok true if vat is live or ilk is not culled
    */
    function peek() public view returns (uint256 val, bool ok) {
        val = WAD;
        ok = VatLike_2(vat).live() == 1 || HubLike(hub).culled(ilk) == 0;
    }

    /**
        @notice Return value
        @dev vat must be live or ilk must not be culled  in hub.
        @return val always 1 WAD value
    */
    function read() external view returns (uint256 val) {
        bool ok;
        (val, ok) = peek();
        require(ok, "D3MOracle/ilk-culled-in-shutdown"); // In order to stop end.cage(ilk) until is unculled
    }
}