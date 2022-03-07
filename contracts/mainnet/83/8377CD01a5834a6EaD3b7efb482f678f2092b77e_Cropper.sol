/**
 *Submitted for verification at Etherscan.io on 2022-03-07
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
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

pragma solidity 0.6.12;

interface VatLike {
    function live() external view returns (uint256);
    function wards(address) external view returns (uint256);
    function urns(bytes32, address) external view returns (uint256, uint256);
    function dai(address) external view returns (uint256);
    function fork(bytes32, address, address, int256, int256) external;
    function frob(bytes32, address, address, address, int256, int256) external;
    function flux(bytes32, address, address, uint256) external;
    function move(address, address, uint256) external;
    function hope(address) external;
    function nope(address) external;
}

interface CropLike {
    function gem() external view returns (GemLike);
    function ilk() external view returns (bytes32);
    function join(address, address, uint256) external;
    function exit(address, address, uint256) external;
    function tack(address, address, uint256) external;
    function flee(address, address, uint256) external;
}

interface GemLike {
    function approve(address, uint256) external;
    function transferFrom(address, address, uint256) external;
}

contract UrnProxy {
    address immutable public usr;

    constructor(address vat_, address usr_) public {
        usr = usr_;
        VatLike(vat_).hope(msg.sender);
    }
}

contract Cropper {
    address public implementation;
    mapping (address => uint256) public wards;

    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event SetImplementation(address indexed);

    modifier auth {
        require(wards[msg.sender] == 1, "Cropper/not-authed");
        _;
    }

    constructor() public {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    function setImplementation(address implementation_) external auth {
        implementation = implementation_;
        emit SetImplementation(implementation_);
    }

    fallback() external {
        address _impl = implementation;
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}

contract CropperImp {
    bytes32 slot0;
    bytes32 slot1;
    mapping (address => address) public proxy; // UrnProxy per user
    mapping (address => mapping (address => uint256)) public can;

    event Hope(address indexed from, address indexed to);
    event Nope(address indexed from, address indexed to);
    event NewProxy(address indexed usr, address indexed urp);

    address public immutable vat;
    constructor(address vat_) public {
        vat = vat_;
    }

    modifier allowed(address usr) {
        require(msg.sender == usr || can[usr][msg.sender] == 1, "Cropper/not-allowed");
        _;
    }

    function hope(address usr) external {
        can[msg.sender][usr] = 1;
        emit Hope(msg.sender, usr);
    }

    function nope(address usr) external {
        can[msg.sender][usr] = 0;
        emit Nope(msg.sender, usr);
    }

    function getOrCreateProxy(address usr) public returns (address urp) {
        urp = proxy[usr];
        if (urp == address(0)) {
            urp = proxy[usr] = address(new UrnProxy(address(vat), usr));
            emit NewProxy(usr, urp);
        }
    }

    function join(address crop, address usr, uint256 val) external {
        require(VatLike(vat).wards(crop) == 1, "Cropper/crop-not-authorized");

        GemLike gem = CropLike(crop).gem();
        gem.transferFrom(msg.sender, address(this), val);
        gem.approve(crop, val);
        CropLike(crop).join(getOrCreateProxy(usr), usr, val);
    }

    function exit(address crop, address usr, uint256 val) external {
        require(VatLike(vat).wards(crop) == 1, "Cropper/crop-not-authorized");

        address urp = proxy[msg.sender];
        require(urp != address(0), "Cropper/non-existing-urp");
        CropLike(crop).exit(urp, usr, val);
    }

    function flee(address crop, address usr, uint256 val) external {
        require(VatLike(vat).wards(crop) == 1, "Cropper/crop-not-authorized");

        address urp = proxy[msg.sender];
        require(urp != address(0), "Cropper/non-existing-urp");
        CropLike(crop).flee(urp, usr, val);
    }

    function move(address u, address dst, uint256 rad) external allowed(u) {
        address urp = proxy[u];
        require(urp != address(0), "Cropper/non-existing-urp");

        VatLike(vat).move(urp, dst, rad);
    }

    function frob(bytes32 ilk, address u, address v, address w, int256 dink, int256 dart) external allowed(u) allowed(w) {
        // The u == v requirement can never be relaxed as otherwise tack() can lose track of the rewards
        require(u == v, "Cropper/not-matching");
        address urp = getOrCreateProxy(u);

        VatLike(vat).frob(ilk, urp, urp, w, dink, dart);
    }

    function flux(address crop, address src, address dst, uint256 wad) external allowed(src) {
        require(VatLike(vat).wards(crop) == 1, "Cropper/crop-not-authorized");

        address surp = proxy[src];
        require(surp != address(0), "Cropper/non-existing-surp");
        address durp = getOrCreateProxy(dst);

        VatLike(vat).flux(CropLike(crop).ilk(), surp, durp, wad);
        CropLike(crop).tack(surp, durp, wad);
    }

    function onLiquidation(address crop, address usr, uint256 wad) external {
        // NOTE - this is not permissioned so be careful with what is done here
        // Send any outstanding rewards to usr and tack to the clipper
        address urp = proxy[usr];
        require(urp != address(0), "Cropper/non-existing-urp");
        CropLike(crop).join(urp, usr, 0);
        CropLike(crop).tack(urp, msg.sender, wad);
    }

    function onVatFlux(address crop, address from, address to, uint256 wad) external {
        // NOTE - this is not permissioned so be careful with what is done here
        CropLike(crop).tack(from, to, wad);
    }

    function quit(bytes32 ilk, address u, address dst) external allowed(u) allowed(dst) {
        require(VatLike(vat).live() == 0, "Cropper/vat-still-live");

        address urp = proxy[u];
        require(urp != address(0), "Cropper/non-existing-urp");

        (uint256 ink, uint256 art) = VatLike(vat).urns(ilk, urp);
        require(int256(ink) >= 0, "Cropper/overflow");
        require(int256(art) >= 0, "Cropper/overflow");
        VatLike(vat).fork(
            ilk,
            urp,
            dst,
            int256(ink),
            int256(art)
        );
    }
}