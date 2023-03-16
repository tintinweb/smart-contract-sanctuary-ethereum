// SPDX-License-Identifier: AGPL-3.0-or-later

/// LineMom -- governance interface for setting a debt ceiling to zero

// Copyright (C) 2023 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.16;

interface AuthorityLike {
    function canCall(address src, address dst, bytes4 sig) external view returns (bool);
}

interface VatLike {
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function file(bytes32 ilk, bytes32 what, uint256 data) external;
}

interface AutoLineLike {
    function remIlk(bytes32 ilk) external;
}

contract LineMom {
    address public owner;
    address public authority;
    address public autoLine;

    mapping (bytes32 => uint256) public ilks;

    address public immutable vat;

    event SetOwner(address indexed owner);
    event SetAuthority(address indexed authority);
    event File(bytes32 indexed what, address data);
    event AddIlk(bytes32 indexed ilk);
    event DelIlk(bytes32 indexed ilk);
    event Wipe(bytes32 indexed ilk, uint256 line);

    modifier onlyOwner {
        require(msg.sender == owner, "LineMom/only-owner");
        _;
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "LineMom/not-authorized");
        _;
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

    constructor(address vat_) {
        vat = vat_;
        owner = msg.sender;
        emit SetOwner(msg.sender);
    }

    function setOwner(address owner_) external onlyOwner {
        owner = owner_;
        emit SetOwner(owner_);
    }

    function setAuthority(address authority_) external onlyOwner {
        authority = authority_;
        emit SetAuthority(authority_);
    }

    function file(bytes32 what, address data) external onlyOwner {
        if (what == "autoLine") autoLine = data;
        else revert("LineMom/file-unrecognized-param");
        emit File(what, data);
    }

    function addIlk(bytes32 ilk) external onlyOwner {
        ilks[ilk] = 1;
        emit AddIlk(ilk);
    }

    function delIlk(bytes32 ilk) external onlyOwner {
        ilks[ilk] = 0;
        emit DelIlk(ilk);
    }

    function wipe(bytes32 ilk) external auth returns (uint256 line) {
        require(ilks[ilk] == 1, "LineMom/ilk-not-added");
        (,,, line,) = VatLike(vat).ilks(ilk);
        AutoLineLike(autoLine).remIlk(ilk);
        VatLike(vat).file(ilk, "line", 0);
        emit Wipe(ilk, line);
    }
}