/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// PixelMapHelpver 0.9.0
//
// https://github.com/bokkypoobah/TokenToolz
//
// Deployed to Mainnet 0xe2d7e63957FD75D93EFf2edBA1B96c7759e9a0c7
//
// SPDX-License-Identifier: MIT
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2022. The MIT Licence.
// ----------------------------------------------------------------------------

interface PixelMap {
    function getTile(uint location) external view returns (address owner, string memory image, string memory url, uint price);
}

contract PixelMapHelper {
    address public constant PIXELMAPADDRESS = 0x015A06a433353f8db634dF4eDdF0C109882A15AB;

    function getTiles(uint[] memory locations) public view returns (
        address[] memory owners,
        string[] memory images,
        string[] memory urls,
        uint[] memory prices
    ) {
        uint length = locations.length;
        owners = new address[](length);
        images = new string[](length);
        urls = new string[](length);
        prices = new uint[](length);
        for (uint i = 0; i < length;) {
            (owners[i], images[i], urls[i], prices[i]) = PixelMap(PIXELMAPADDRESS).getTile(locations[i]);
            unchecked {
                i++;
            }
        }
    }
}