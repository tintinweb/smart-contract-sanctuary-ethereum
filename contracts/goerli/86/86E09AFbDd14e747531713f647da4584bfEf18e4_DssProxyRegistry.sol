// SPDX-License-Identifier: AGPL-3.0-or-later
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

pragma solidity ^0.8.0;

import "./DssProxy.sol";

contract DssProxyRegistry {
    mapping (address => uint256) public seed;

    function _salt(address owner_) internal view returns (uint256 salt) {
        salt = uint256(keccak256(abi.encode(owner_, seed[owner_])));
    }

    function _code(address owner_) internal pure returns (bytes memory code) {
        code = abi.encodePacked(type(DssProxy).creationCode, abi.encode(owner_));
    }

    function proxies(address owner_) public view returns (address proxy) {
        proxy = seed[owner_] == 0
            ? address(0)
            : address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                address(this),
                                _salt(owner_),
                                keccak256(_code(owner_))
                            )
                        )
                    )
                )
            );
    }

    function build(address owner_) external returns (address payable proxy) {
        address payable proxy_ = payable(proxies(owner_));
        require(proxy_ == address(0) || DssProxy(proxy_).owner() != owner_); // Not allow new proxy if the user already has one and remains being the owner
        seed[owner_]++;
        uint256 salt = _salt(owner_);
        bytes memory code = _code(owner_);
        assembly {
            proxy := create2(0, add(code, 0x20), mload(code), salt)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
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

pragma solidity ^0.8.0;

interface AuthorityLike {
    function canCall(address src, address dst, bytes4 sig) external view returns (bool);
}

contract DssProxy {
    address public owner;
    address public authority;

    event SetOwner(address indexed owner_);
    event SetAuthority(address indexed authority_);

    constructor(address owner_) {
        owner = owner_;
    }

    receive() external payable {
    }

    modifier onlyOwner {
        require(msg.sender == owner, "DssProxy/not-owner");
        _;
    }

    modifier auth {
        require(
            msg.sender == owner ||
            authority != address(0) && AuthorityLike(authority).canCall(msg.sender, address(this), msg.sig),
            "DssProxy/not-authorized"
        );
        _;
    }

    function setOwner(address owner_) external onlyOwner {
        owner = owner_;
        emit SetOwner(owner_);
    }

    function setAuthority(address authority_) external onlyOwner {
        authority = authority_;
        emit SetAuthority(authority_);
    }

    function execute(address _target, bytes memory _data) external auth payable returns (bytes memory response) {
        require(_target != address(0), "DssProxy/target-address-required");
        address owner_ = owner;

        assembly {
            let succeeded := delegatecall(gas(), _target, add(_data, 0x20), mload(_data), 0, 0)
            let size := returndatasize()

            response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
            case 1 {
                revert(add(response, 0x20), size)
            }
        }

        require(owner == owner_, "DssProxy/owner-can-not-be-changed");
    }
}