// SPDX-License-Identifier: AGPL-3.0-or-later

/// dss.sol -- Decentralized Summation System

// Copyright (C) 2022 Horsefacts <[email protected]>
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

pragma solidity ^0.8.15;

import {DSSProxy} from "./proxy/proxy.sol";

interface DSSLike {
    function sum() external view returns(address);
    function use() external;
    function see() external view returns (uint256);
    function hit() external;
    function dip() external;
    function nil() external;
    function hope(address) external;
    function nope(address) external;
    function bless() external;
    function build(bytes32 wit, address god) external returns (address);
    function scry(address guy, bytes32 wit, address god) external view returns (address);
}

interface SumLike {
    function hope(address) external;
    function nope(address) external;
}

interface UseLike {
    function use() external;
}

interface SpyLike {
    function see() external view returns (uint256);
}

interface HitterLike {
    function hit() external;
}

interface DipperLike {
    function dip() external;
}

interface NilLike {
    function nil() external;
}

contract DSS {
    // --- Data ---
    address immutable public sum;
    address immutable public _use;
    address immutable public _spy;
    address immutable public _hitter;
    address immutable public _dipper;
    address immutable public _nil;

    // --- Init ---
    constructor(
        address sum_,
        address use_,
        address spy_,
        address hitter_,
        address dipper_,
        address nil_)
    {
        sum     = sum_;     // Core ICV engine
        _use    = use_;     // Creation module
        _spy    = spy_;     // Read module
        _hitter = hitter_;  // Increment module
        _dipper = dipper_;  // Decrement module
        _nil    = nil_;     // Reset module
    }

    // --- DSS Operations ---
    function use() external {
        UseLike(_use).use();
    }

    function see() external view returns (uint256) {
        return SpyLike(_spy).see();
    }

    function hit() external {
        HitterLike(_hitter).hit();
    }

    function dip() external {
        DipperLike(_dipper).dip();
    }

    function nil() external {
        NilLike(_nil).nil();
    }

    function hope(address usr) external {
        SumLike(sum).hope(usr);
    }

    function nope(address usr) external {
        SumLike(sum).nope(usr);
    }

    function bless() external {
        SumLike(sum).hope(_use);
        SumLike(sum).hope(_hitter);
        SumLike(sum).hope(_dipper);
        SumLike(sum).hope(_nil);
    }

    function build(bytes32 wit, address god) external returns (address proxy) {
        proxy = address(new DSSProxy{ salt: wit }(address(this), msg.sender, god));
    }

    function scry(address guy, bytes32 wit, address god) external view returns (address) {
        address me = address(this);
        return address(uint160(uint256(keccak256(
            abi.encodePacked(
                bytes1(0xff),
                me,
                wit,
                keccak256(
                    abi.encodePacked(
                        type(DSSProxy).creationCode,
                        abi.encode(me),
                        abi.encode(guy),
                        abi.encode(god)
                    )
                )
            )
        ))));
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// proxy.sol -- Execute DSS actions through the proxy's identity

// Copyright (C) 2022 Horsefacts <[email protected]>
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

pragma solidity ^0.8.15;

import {DSAuth} from "ds-auth/auth.sol";
import {DSNote} from "ds-note/note.sol";

contract DSSProxy is DSAuth, DSNote {
    // --- Data ---
    address public dss;

    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth note { wards[usr] = 1; }
    function deny(address usr) external auth note { wards[usr] = 0; }
    modifier ward {
        require(wards[msg.sender] == 1, "DSSProxy/not-authorized");
        require(msg.sender != owner, "DSSProxy/owner-not-ward");
        _;
    }

    // --- Init ---
    constructor(address dss_, address usr, address god) {
        dss = dss_;
        wards[usr] = 1;
        setOwner(god);
    }

    // --- Upgrade ---
    function upgrade(address dss_) external auth note {
        dss = dss_;
    }

    // --- Proxy ---
    fallback() external ward note {
        address _dss = dss;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _dss, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: GNU-3
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.4.23;

interface DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) external view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(address(0))) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

/// note.sol -- the `note' modifier, for logging calls as events

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.4.23;

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint256           wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;
        uint256 wad;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            wad := callvalue()
        }

        _;

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);
    }
}