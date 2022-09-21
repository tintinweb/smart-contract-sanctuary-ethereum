/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// hevm: flattened sources of src/DssProxyActionsCropper.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.6.12;

////// src/DssProxyActionsCropper.sol

/// DssProxyActionsCropper.sol

// Copyright (C) 2018-2020 Maker Ecosystem Growth Holdings, INC.

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

/* pragma solidity 0.6.12; */

interface GemLike_6 {
    function approve(address, uint256) external;
    function transfer(address, uint256) external;
    function transferFrom(address, address, uint256) external;
    function deposit() external payable;
    function withdraw(uint256) external;
    function balanceOf(address) external view returns (uint256);
}

interface CropperLike {
    function getOrCreateProxy(address) external returns (address);
    function join(address, address, uint256) external;
    function exit(address, address, uint256) external;
    function flee(address, address, uint256) external;
    function frob(bytes32, address, address, address, int256, int256) external;
    function quit(bytes32, address, address) external;
}

interface VatLike_16 {
    function can(address, address) external view returns (uint256);
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function dai(address) external view returns (uint256);
    function urns(bytes32, address) external view returns (uint256, uint256);
    function hope(address) external;
    function nope(address) external;
    function flux(bytes32, address, address, uint256) external;
}

interface GemJoinLike_2 {
    function dec() external returns (uint256);
    function gem() external returns (GemLike_6);
    function ilk() external returns (bytes32);
    function bonus() external returns (GemLike_6);
    function tack(address src, address dst, uint256 wad) external;
}

interface DaiJoinLike {
    function dai() external returns (GemLike_6);
    function join(address, uint256) external payable;
    function exit(address, uint256) external;
}

interface EndLike_3 {
    function fix(bytes32) external view returns (uint256);
    function cash(bytes32, uint256) external;
    function free(bytes32) external;
    function pack(uint256) external;
    function skim(bytes32, address) external;
}

interface JugLike {
    function drip(bytes32) external returns (uint256);
}

interface HopeLike_2 {
    function hope(address) external;
    function nope(address) external;
}

interface CdpRegistryLike {
    function owns(uint256) external view returns (address);
    function ilks(uint256) external view returns (bytes32);
    function open(bytes32, address) external returns (uint256);
}

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a DSProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

contract Common {
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;
    address immutable public vat;
    address immutable public cropper;
    address immutable public cdpRegistry;

    constructor(address vat_, address cropper_, address cdpRegistry_) public {
        vat = vat_;
        cropper = cropper_;
        cdpRegistry = cdpRegistry_;
    }

    // Internal functions

    function _mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "mul-overflow");
    }

    // Public functions

    function daiJoin_join(address daiJoin, address u, uint256 wad) public {
        GemLike_6 dai = DaiJoinLike(daiJoin).dai();
        // Gets DAI from the user's wallet
        dai.transferFrom(msg.sender, address(this), wad);
        // Approves adapter to take the DAI amount
        dai.approve(daiJoin, wad);
        // Joins DAI into the vat
        DaiJoinLike(daiJoin).join(u, wad);
    }
}


contract DssProxyActionsEndCropper is Common {

    constructor(address vat_, address cropper_, address cdpRegistry_) public Common(vat_, cropper_, cdpRegistry_) {}

    // Internal functions

    function _free(
        address end,
        address u,
        bytes32 ilk
    ) internal returns (uint256 ink) {
        address urp = CropperLike(cropper).getOrCreateProxy(u);
        uint256 art;
        (ink, art) = VatLike_16(vat).urns(ilk, urp);

        // If CDP still has debt, it needs to be paid
        if (art > 0) {
            EndLike_3(end).skim(ilk, urp);
            (ink,) = VatLike_16(vat).urns(ilk, urp);
        }
        // Approves the cropper to transfer the position to proxy's address in the vat
        VatLike_16(vat).hope(cropper);
        // Transfers position from CDP to the proxy address
        CropperLike(cropper).quit(ilk, u, address(this));
        // Denies cropper to access to proxy's position in the vat after execution
        VatLike_16(vat).nope(cropper);
        // Frees the position and recovers the collateral in the vat registry
        EndLike_3(end).free(ilk);
        // Fluxs to the proxy's cropper proxy, so it can be pulled out with the managed gem join
        VatLike_16(vat).flux(
            ilk,
            address(this),
            urp,
            ink
        );
    }

    // Public functions
    function freeETH(
        address ethJoin,
        address end,
        uint256 cdp
    ) external {
        // Frees the position through the end contract
        uint256 wad = _free(end, CdpRegistryLike(cdpRegistry).owns(cdp), CdpRegistryLike(cdpRegistry).ilks(cdp));
        // Exits WETH amount to proxy address as a token
        CropperLike(cropper).exit(ethJoin, address(this), wad);
        // Converts WETH to ETH
        GemJoinLike_2(ethJoin).gem().withdraw(wad);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(wad);
    }

    function freeGem(
        address gemJoin,
        address end,
        uint256 cdp
    ) external {
        // Frees the position through the end contract
        uint256 wad = _free(end, CdpRegistryLike(cdpRegistry).owns(cdp), CdpRegistryLike(cdpRegistry).ilks(cdp));
        // Exits token amount to the user's wallet as a token
        uint256 amt = wad / 10 ** (18 - GemJoinLike_2(gemJoin).dec());
        // Exits token amount to proxy address as a token
        CropperLike(cropper).exit(gemJoin, address(this), amt);
        // Exits token amount to the user's wallet as a token
        GemJoinLike_2(gemJoin).gem().transfer(msg.sender, amt);
    }

    function pack(
        address daiJoin,
        address end,
        uint256 wad
    ) external {
        // Joins DAI amount into the vat
        daiJoin_join(daiJoin, address(this), wad);
        // Approves the end to take out DAI from the proxy's balance in the vat
        if (VatLike_16(vat).can(address(this), address(end)) == 0) {
            VatLike_16(vat).hope(end);
        }
        EndLike_3(end).pack(wad);
    }

    function cashETH(
        address ethJoin,
        address end,
        uint256 wad
    ) external {
        bytes32 ilk = GemJoinLike_2(ethJoin).ilk();
        EndLike_3(end).cash(ilk, wad);
        uint256 wadC = _mul(wad, EndLike_3(end).fix(ilk)) / RAY;
        address urnProxy = CropperLike(cropper).getOrCreateProxy(address(this));
        // Flux to the proxy's UrnProxy in cropper, so it can be pulled out with the managed gem join
        VatLike_16(vat).flux(
            ilk,
            address(this),
            urnProxy,
            wadC
        );
        // Tack from the End to allow fleeing, assumes vaults' stakes were tacked to the End after skimming
        GemJoinLike_2(ethJoin).tack(end, urnProxy, wadC);
        // Exits WETH amount to proxy address as a token
        CropperLike(cropper).flee(ethJoin, address(this), wadC);
        // Converts WETH to ETH
        GemJoinLike_2(ethJoin).gem().withdraw(wadC);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(wadC);
    }

    function cashGem(
        address gemJoin,
        address end,
        uint256 wad
    ) external {
        bytes32 ilk = GemJoinLike_2(gemJoin).ilk();
        EndLike_3(end).cash(ilk, wad);
        uint256 wadC = _mul(wad, EndLike_3(end).fix(ilk)) / RAY;
        address urnProxy = CropperLike(cropper).getOrCreateProxy(address(this));
        // Flux to the proxy's UrnProxy in cropper, so it can be pulled out with the managed gem join
        VatLike_16(vat).flux(
            ilk,
            address(this),
            urnProxy,
            wadC
        );
        // Tack from the End to allow fleeing, assumes vaults' stakes were tacked to the End after skimming
        GemJoinLike_2(gemJoin).tack(end, urnProxy, wadC);
        // Exits token amount to the user's wallet as a token
        uint256 amt = wadC / 10 ** (18 - GemJoinLike_2(gemJoin).dec());
        CropperLike(cropper).flee(gemJoin, msg.sender, amt);
    }
}