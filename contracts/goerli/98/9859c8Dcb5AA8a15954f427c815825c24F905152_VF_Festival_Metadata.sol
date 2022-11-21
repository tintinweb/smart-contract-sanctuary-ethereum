// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract VF_Festival_Metadata {
    function data(address filmNftAddr) public pure returns (bytes memory) {
        if (false)
            return "";
//***ITEM DATA SEPARATOR BEGIN
        //1
        else if (filmNftAddr==address(0xB0E7383011835a54ab6ce44719e1f4fc32C4cDB9))
            return
        '"_note":"..500 bytes festival metadata",\n'
        '"image":"ipfs://QmX9NWkDGFi78p7PwreuDbv3kRD1vFRrnaPcnePhEp3Xiu",\n'
        '"external_link":"https://vertifilms.com/78001",\n'
        '"animation_sha256":"d6e5b12542c44fbdbe791e5ba1aa0c8af81cf9113efa9b6a92ecbf329070827b",\n'
        '"attributes":[{"trait_type":"Minted at Festival","value":"Vertifilms Demo Festival 2022"}]';
//***ITEM DATA SEPARATOR END

        return "";
    }

    function data_not_revealed(address filmNftAddr) public pure returns (bytes memory) {
        if (false)
            return "";
//***ITEM DATA-NOT-REVEALED SEPARATOR BEGIN
        //1
        else if (filmNftAddr==address(0xB0E7383011835a54ab6ce44719e1f4fc32C4cDB9))
            return
        '"animation_url":"ipfs://QmRsUBqvKUf8p4xkjDkKK1PXCB4H5QCHfiWT3UjPiCfW23"';
//***ITEM DATA-NOT-REVEALED SEPARATOR END

        return "";
    }

    function data_revealed(address filmNftAddr) public pure returns (bytes memory) {
        if (false)
            return "";
//***ITEM DATA-REVEALED SEPARATOR BEGIN
        //1
        else if (filmNftAddr==address(0xB0E7383011835a54ab6ce44719e1f4fc32C4cDB9))
            return
        '"animation_url":"ipfs://QmbnTp9HVvLNLz2uDkC3x4Rh4uuxMzrXw2vvWLgrAGu7ed/film.mp4"';
//***ITEM DATA-REVEALED SEPARATOR END

        return "";
    }

}