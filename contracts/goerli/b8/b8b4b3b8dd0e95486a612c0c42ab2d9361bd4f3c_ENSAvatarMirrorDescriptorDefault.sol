// SPDX-License-Identifier: CC0-1.0

/// @title ENS Avatar Mirror Token Descriptor Default Values

/**
 *        ><<    ><<<<< ><<    ><<      ><<
 *      > ><<          ><<      ><<      ><<
 *     >< ><<         ><<       ><<      ><<
 *   ><<  ><<        ><<        ><<      ><<
 *  ><<<< >< ><<     ><<        ><<      ><<
 *        ><<        ><<       ><<<<    ><<<<
 */

pragma solidity ^0.8.17;

contract ENSAvatarMirrorDescriptorDefault {
    string public constant IMAGE_UNINITIALIZED =
        "https://avatar-mirror.infura-ipfs.io/ipfs/QmT89YMj7S9bM7t4i6JoaYqgMuRMrMys2xGtgoBLioGfCM";
    string public constant IMAGE_ERROR =
        "https://avatar-mirror.infura-ipfs.io/ipfs/QmP4jH3hfU6CWh9hPxoDk93SVYrHCjQwHoNdHoRPWskpoW";

    function buildTokenURI(string memory domain, string memory image) external pure returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;charset=utf-8,{\"name\": \"ENS Avatar Mirror [",
                domain,
                "]\", \"description\": \"Mirrors an ERC721 or ERC1155 token referenced in the avatar field on an ENS node. Useful for hot wallet accounts that want to show the same avatar as their cold wallet otherwise would.\", \"image\": \"",
                image,
                "\"}"
            )
        );
    }
}