/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title SoulMinter
/// @author Miguel Piedrafita
/// @notice Barebones contract to mint Soulbound NFTs
contract SoulMinter {
    /// @notice Thrown when trying to transfer a Soulbound token
    error Soulbound();

    /// @notice Emitted when minting a Soulbound NFT
    /// @param from Who the token comes from. Will always be address(0)
    /// @param to The token recipient
    /// @param id The ID of the minted token
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    /// @notice The symbol for the token
    string public constant symbol = "SOUL";

    /// @notice The name for the token
    string public constant name = "Soulbound NFT";

    /// @notice The owner of this contract (set to the deployer)
    address public immutable owner = msg.sender;

    /// @notice Get the metadata URI for a certain tokenID
    mapping(uint256 => string) public tokenURI;

    /// @notice Get the owner of a certain tokenID
    mapping(uint256 => address) public ownerOf;

    /// @notice Get how many SoulMinter NFTs a certain user owns
    mapping(address => uint256) public balanceOf;

    /// @dev Counter for the next tokenID, defaults to 1 for better gas on first mint
    uint256 internal nextTokenId = 1;

    constructor() payable {}

    /// @notice This function was disabled to make the token Soulbound. Calling it will revert
    function approve(address, uint256) public virtual {
        revert Soulbound();
    }

    /// @notice This function was disabled to make the token Soulbound. Calling it will revert
    function isApprovedForAll(address, address) public pure {
        revert Soulbound();
    }

    /// @notice This function was disabled to make the token Soulbound. Calling it will revert
    function getApproved(uint256) public pure {
        revert Soulbound();
    }

    /// @notice This function was disabled to make the token Soulbound. Calling it will revert
    function setApprovalForAll(address, bool) public virtual {
        revert Soulbound();
    }

    /// @notice This function was disabled to make the token Soulbound. Calling it will revert
    function transferFrom(
        address,
        address,
        uint256
    ) public virtual {
        revert Soulbound();
    }

    /// @notice This function was disabled to make the token Soulbound. Calling it will revert
    function safeTransferFrom(
        address,
        address,
        uint256
    ) public virtual {
        revert Soulbound();
    }

    /// @notice This function was disabled to make the token Soulbound. Calling it will revert
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual {
        revert Soulbound();
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /// @notice Mint a new Soulbound NFT to `to`
    /// @param to The recipient of the NFT
    /// @param metaURI The URL to the token metadata
    function mint(address to, string calldata metaURI) public payable {
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[nextTokenId] = to;
        tokenURI[nextTokenId] = metaURI;

        emit Transfer(address(0), to, nextTokenId++);
    }
}