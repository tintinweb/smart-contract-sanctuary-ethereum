// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

library CryptoCocksLib {
    function getCid(uint id) external pure returns (string memory cid) {
        string memory batch;

        if (id <= 2000) {
            batch = "bafybeiesbbihtfdj3kqbah5642p7drsb6hrzwzksezbgb2t2ojjwgh2k5m";
        } else if (id <= 4000) {
            batch = "bafybeifclnruolpdcsouhmzhnardvpzroxk6qouc53drw4vh2f3zdoouya";
        } else if (id <= 6000) {
            batch = "bafybeihbeszvaoc3exx6ji77g74nyuqmoz2scdykudna3qd6xzgygn36ra";
        } else if (id <= 8000) {
            batch = "bafybeidl3uswhq65hnfvgj6bfahbvdb57y7cxiaelgct6q7raweubcms6u";
        } else {
            batch = "bafybeifx2hrh6mhbpcivo4z53l76uqwc6fth4nf4qah6aow7e62lcka3d4";
        }

        return string(abi.encodePacked("ipfs://", batch, "/"));
    }
}