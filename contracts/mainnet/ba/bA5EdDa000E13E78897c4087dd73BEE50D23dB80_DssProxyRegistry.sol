/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Copyright (C) 2017 DappHub, LLC
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

pragma solidity ^0.8.13;

interface AuthorityLike {
    function canCall(address src, address dst, bytes4 sig) external view returns (bool);
}

contract DssProxy {
    address public owner;
    address public authority;

    event SetOwner(address indexed owner);
    event SetAuthority(address indexed authority);

    constructor(address owner_) {
        owner = owner_;
        emit SetOwner(owner_);
    }

    receive() external payable {
    }

    modifier auth {
        require(
            msg.sender == owner ||
            authority != address(0) && AuthorityLike(authority).canCall(msg.sender, address(this), msg.sig),
            "DssProxy/not-authorized"
        );
        _;
    }

    function setOwner(address owner_) external auth {
        owner = owner_;
        emit SetOwner(owner_);
    }

    function setAuthority(address authority_) external auth {
        authority = authority_;
        emit SetAuthority(authority_);
    }

    function execute(address target_, bytes memory data_) external auth payable returns (bytes memory response) {
        require(target_ != address(0), "DssProxy/target-address-required");

        assembly {
            let succeeded := delegatecall(gas(), target_, add(data_, 0x20), mload(data_), 0, 0)
            let size := returndatasize()

            response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch succeeded
            case 0 {
                revert(add(response, 0x20), size)
            }
        }
    }
}

contract DssProxyRegistry {
    mapping (address => uint256) public seed;
    mapping (address => address) public proxies;
    mapping (address => uint256) public isProxy;

    function build(address usr) external returns (address payable proxy) {
        proxy = payable(proxies[usr]);
        if (proxy != address(0)) {
            (, bytes memory owner) = proxy.call(abi.encodeWithSignature("owner()")); // Using low level call in case proxy was self destructed
            require(owner.length != 32 || abi.decode(owner, (address)) != usr, "DssProxyRegistry/proxy-already-registered-to-user"); // Not allow new proxy if the user already has one and remains being the owner
        }

        uint256 salt = uint256(keccak256(abi.encode(usr, ++seed[usr])));
        bytes memory code = abi.encodePacked(type(DssProxy).creationCode, abi.encode(usr));
        assembly {
            proxy := create2(0, add(code, 0x20), mload(code), salt)
        }
        require(proxy != address(0), "DssProxyRegistry/creation-failed");

        proxies[usr] = proxy;
        isProxy[proxy] = 1;
    }

    // This function needs to be used carefully, you should only claim a proxy you trust on.
    // A proxy might be set up with an authority or just simple allowances that might make an
    // attacker to take funds that are sitting in the proxy.
    function claim(address proxy) external {
        require(isProxy[proxy] != 0, "DssProxyRegistry/not-proxy-from-this-registry");
        address owner = DssProxy(payable(proxy)).owner();
        require(owner == msg.sender, "DssProxyRegistry/only-owner-can-claim");
        proxies[owner] = proxy;
    }
}