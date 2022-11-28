/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

// hevm: flattened sources of src/D3MMom.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.14 <0.9.0;

////// src/D3MMom.sol
// SPDX-FileCopyrightText: © 2021 Dai Foundation <www.daifoundation.org>
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

interface DisableLike {
    function disable() external;
}

interface AuthorityLike {
    function canCall(address src, address dst, bytes4 sig) external view returns (bool);
}

// Bypass governance delay to disable a direct deposit module
contract D3MMom {
    address public owner;
    address public authority;

    event SetOwner(address indexed newOwner);
    event SetAuthority(address indexed newAuthority);
    event Disable(address indexed who);

    modifier onlyOwner {
        require(msg.sender == owner, "D3MMom/only-owner");
        _;
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "D3MMom/not-authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
        emit SetOwner(msg.sender);
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == address(0)) {
            return false;
        } else {
            return AuthorityLike(authority).canCall(src, address(this), sig);
        }
    }

    // Governance actions with delay
    function setOwner(address owner_) external onlyOwner {
        owner = owner_;
        emit SetOwner(owner_);
    }

    function setAuthority(address authority_) external onlyOwner {
        authority = authority_;
        emit SetAuthority(authority_);
    }

    // Governance action without delay
    function disable(address who) external auth {
        DisableLike(who).disable();
        emit Disable(who);
    }
}