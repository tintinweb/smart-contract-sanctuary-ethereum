// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
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

pragma solidity ^0.7.6;

interface AuthorityLike {
    function canCall(address src, address dst, bytes4 sig) external view returns (bool);
}

interface EscrowLike {
  function approve(address token, address spender, uint256 value) external;
}

// Bypass governance delay to disable a L1Escrow
contract L1EscrowMom {
    address public owner;
    address public authority;

    address public immutable escrow;
    address public immutable token;

    event SetOwner(address indexed oldOwner, address indexed newOwner);
    event SetAuthority(address indexed oldAuthority, address indexed newAuthority);
    event Refuse(address indexed escrow, address token, address spender);

    modifier onlyOwner {
        require(msg.sender == owner, "L1EscrowMom/only-owner");
        _;
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "L1EscrowMom/not-authorized");
        _;
    }

    constructor(address escrow_, address token_) {
        owner = msg.sender;
        escrow = escrow_;
        token = token_;
        emit SetOwner(address(0), msg.sender);
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
        emit SetOwner(owner, owner_);
        owner = owner_;
    }

    function setAuthority(address authority_) external onlyOwner {
        emit SetAuthority(authority, authority_);
        authority = authority_;
    }

    // Governance action without delay
    function refuse(address spender) external auth {
        emit Refuse(escrow, token, spender);
        EscrowLike(escrow).approve(token, spender, 0);
    }
}