/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

/// Shared public library for on-chain NFT functions
interface IPublicSharedMetadata {
    /// @param unencoded bytes to base64-encode
    function base64Encode(bytes memory unencoded)
        external
        pure
        returns (string memory);

    /// Encodes the argument json bytes into base64-data uri format
    /// @param json Raw json to base64 and turn into a data-uri
    function encodeMetadataJSON(bytes memory json)
        external
        pure
        returns (string memory);

    /// Proxy to openzeppelin's toString function
    /// @param value number to return as a string
    function numberToString(uint256 value)
        external
        pure
        returns (string memory);
}

interface IMetadataRenderer {
    function tokenURI(uint256) external view returns (string memory);
    function contractURI() external view returns (string memory);
    function initializeWithData(bytes memory initData) external;
}

interface IOwnable {
    function owner() external view returns (address);
}

/// @notice Custom on-chain renderer for Ken Knowlton
/// @author (artist) Ken Knowlton kenknowlton.com
/// @author (preservation) Jim Boulton digital-archaeology.org
/// @author (smart contract) Iain Nash iain.in
/// @author (coordinator) Rhizome
contract KenKnowltonJulieMartinRenderer is IMetadataRenderer {
    /// @notice Textual representation of artwork
    bytes private constant portrait =
        "7f7f7f6e6e5c3b5e6f7f7f6e6f6d6e7f7f7f"
        "f7f7f7e6e5c3a3d5d5d5e6e6e7e5c5c7f7f7"
        "7f7f7d5d5c3b3d4d6e6d5d6e6e7e4c4c7f7f"
        "f7f7e4d5d4b3d6f7f7f7e5e6e6e6e5c4e7f7"
        "7f7f7c4d5c3c7f7f7f7f7e6e6e6e5e5c5f7f"
        "f7f7e5e6d4c7f7f7f7f7f7f6e6d5c5d3c7f7"
        "7d6d6e5d3b6f7f7f7f7f7f7f6e6d4c5c3d7f"
        "f6d4d4c3b5f7f7f7f7f7f7f7f6d6c3b4b3f7"
        "7e5d4c3a5f7f7f7f7f7f7f7f7e6d5c2b3b6f"
        "f6e5c3a3f7f7f7f7f7f7f7f7f7e5e592a3d7"
        "5d4b2a2d7f7f7f7f7f7f7f7f7f7e6d292a3f"
        "c2a2a3b5e7f7f7f7f7f7f7f7f7f7e5b1a297"
        "2a4c3c4d6f7f7f7f7f7f7f7f7f7e7d49191e"
        "b3b3c4c5e6f6d5c5e7f7f7f5b4c5e5b291a7"
        "291b4c4d6d5d5b2a3e7f7e4a1a3c4d3a292f"
        "81a2c4c5a3c4b291a4e7e4a3a1a3a192a1a7"
        "191b4b4a4d5d6d5c2b6f6b2d5d3b4b393a1c"
        "81a3b2b3d5c3a2c5c2c7c1c6c3b3b3c293a3"
        "2a2a291e6d3a193b4c1b2a4c291a3c4c1b2a"
        "d2a291a7e5b5e6e5d495a3c5d5d3b4d591b3"
        "59190b2f6d6f7f6e7b3f4a4d6f7f6c4d192c"
        "d291a496e7f7e6e7f1e7e1d6d6e7d6e49195"
        "6b193d3c7f7f7f7f4b7f7b3f7f7f7f7b2a1d"
        "f291b4c2f7f7f7f5a5f7f5a5f7f7f6e1a285"
        "7b193a4b3e6f6e4a4e7f7e3a3d6e5e3a2a1e"
        "f291a1c4b3c4c4d4f6e7f6d292a2a3b3a2a7"
        "7b19194c5e7f7f4c4b2b4b2a2e6e4a3b1a2f"
        "f4a292c5d6f7e4b6b292a2a3c3e5c3a392c7"
        "7e3b1a4d5d5d4a4f7d3a2a3c5a3c3a2b1a6f"
        "f7d492c4c4b292e7f7e4b3c5c292a2a392f7"
        "7f6d3a4b3b391a4d5e6d3b3b291a2a2b2b7f"
        "f7f5c3b3b3c39181b3c4c3b181b3a2a3a4f7"
        "7f7e5d4b3b4c3c5c6f7f7d492b6d3a2a2d7f"
        "f7f7d5d3b4c5d7f7c4d5e494c4e5c3a2c7f7"
        "7f7f7c3d3c5d5e6f7f4b3c5d4c5c5b4c7f7f"
        "f7f7f7f7c3d4d6d5e6e6e6d3b3c3c4f7f7f7"
        "7f7f7f7f5b4c4d5c3b3b3b2a3b3b3e7f7f7f"
        "f7f7f7f7d3b4c5e4b2a2a292c3a4b7f7f7f7"
        "7f7f7f7f5b4c3c5e5c4b3a2c3b2b5f7f7f7f"
        "f7f7f7f7e3b4a2c6e6e6d4c4a1a2e7f7f7f7"
        "7f7f7f7f6a3b292c5d5d4c4a192a7f7f7f7f"
        "f7f7f7f7e2b3b281a3b4b2a191a2f7f7f7f7"
        "7f7f7f7f6b3b4b28191919191a2a7f7f7f7f"
        "f7f7f7f7e2a3c3b1819191919192f7f7f7f7";

    /// @notice License for the artwork within
    function license() public pure returns (string memory) {
        return
            "Zora Labs, Inc acknowledges and agrees that Ken Knowlton owns certain Intellectual Property rights related to the Julie Martin portrait (the rendered output image, input symbols and algorithm). Only the rights to the portrait (the rendered output image) may be used by Zora for the purposes of listing, promoting, and maintaining the auction. The input symbols and algorithm will remain the property of Ken Knowlton. Zora Labs, Inc further acknowledge and agree that Ken Knowlton owns certain Intellectual Property rights related to the Knowlton & Harmon Computer Nude (the image, non-generic symbols, and algorithm) and that Ken Knowlton is not transferring any such rights to Zora Labs, Inc.";
    }

    /// @dev Rendering utility
    IPublicSharedMetadata private immutable sharedMetadata;

    /// @dev Bound (owner) for contract. Binds to drops contract upon init.
    address public bound;

    /// @notice constructor that saves the metadata renderer reference
    /// @dev Deploy with the bound as the deployer of the final metadata contract
    constructor(IPublicSharedMetadata _sharedMetadata, address _bound) {
        sharedMetadata = _sharedMetadata;
        bound = _bound;
    }

    /// @notice Initializer for final recipient contract user
    function initializeWithData(bytes memory) external {
        address owner = IOwnable(msg.sender).owner();
        if (owner == bound) {
            bound = msg.sender;
        } else {
            revert();
        }
    }

    /// @notice Get template for image as text rendering proper style tags for SVG
    /// @return string memory text spans
    function getTemplate() private pure returns (bytes memory) {
        bytes memory parts;
        for (uint256 i = 0; i < portrait.length / 36; ++i) {
            bytes memory chars;
            for (uint256 k = 0; k < 36; ++k) {
                chars = abi.encodePacked(chars, portrait[i + k]);
            }
            parts = abi.encodePacked(
                parts,
                '<tspan x="0" dy="10px">',
                chars,
                "</tspan>"
            );
        }
        return parts;
    }

    /// @notice Getter for the final SVG image result
    /// @return string memory image as svg raw text
    function getImage() private pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<svg viewBox="0 0 360 440" width="100%" height="100%" preserveAspectRatio="xMidYMid meet" xmlns="http://www.w3.org/2000/svg"><style>@font-face {font-family: A; src: url(\'',
                "data:font/woff;base64,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"
                "')} text{font-family:A;font-size: 8px;fill: white;}</style><text x='-10'>",
                getTemplate(),
                "</text></svg>"
            );
    }

    /// @notice Getter for contract uri
    function contractURI() public pure returns (string memory) {
        revert();
        return "ipfs://CID_EXAMPLE";
    }

    /// @notice Token URI for the contract, only renders 1 token.
    /// @dev gated by msg.sender and tokenId for only one token
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(tokenId == 1, "only one token");
        // require(bound == msg.sender, "no destiny for content");

        return
            sharedMetadata.encodeMetadataJSON(
                abi.encodePacked(
                    '{"name": "'
                    "Studies in Perception: Julie Martin"
                    '", "description": "',
                    unicode'This portrait of Julie Martin, director of Experiments in Art and Technology (E.A.T.), was created in 2022 by Ken Knowlton and Jim Boulton. It utilizes a reconstruction of the algorithm Knowlton and Leon Harmon used to create the 1966 Studies in Perception artwork, known as Computer Nude. Inspiring Robert Rauschenberg to describe computer code as “the new artistic material,” Computer Nude was the backdrop to the press launch for E.A.T., held on October 10th 1967 at Rauschenberg’s Lafayette Street studio. © Ken Knowlton 2022.',
                    license(),
                    '", "image": "data:image/svg+xml;base64,',
                    sharedMetadata.base64Encode(getImage()),
                    '"}"'
                )
            );
    }
}