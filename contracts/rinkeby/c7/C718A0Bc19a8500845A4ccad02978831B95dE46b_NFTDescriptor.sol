// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.9;

library NFTDescriptor {
    function constructTokenURI(string memory name, string memory image)
        public
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;",
                    abi.encodePacked(
                        "{'name':'",
                        name,
                        "', 'description': Simple Arch Portfolio NFT'",
                        "', 'image': '",
                        "data:image/url;",
                        image,
                        "'}"
                    )
                )
            );
    }
}