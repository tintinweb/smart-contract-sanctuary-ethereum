// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './Renderer.sol';
import './base64.sol';
/// @title Spherical GeNFTs
/// @author espina (modified from Miguel Piedrafita's SoulMinter)
/// @notice contract to mint Soulbound NFTs with onchain generative SVGs

contract Spherical is Renderer {
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
    string public constant symbol = "OOOO";

    /// @notice The name for the token
    string public constant name = "Spherical";

    /// @notice The owner of this contract (set to the deployer)
    address public immutable owner = msg.sender;
    address public admin = address(0x5706542bb1e2eA5A10f820eA9E23AEfCe4858629);

    address payable public constant sphereAdr = payable(0x2ac85F79d0FBE628594F7BC1d2311cDF700EF57A);
    address payable public constant espinaAdr = payable(0x5706542bb1e2eA5A10f820eA9E23AEfCe4858629);

    /// @notice Get the owner of a certain tokenID
    mapping(uint256 => address) public ownerOf;

    /// @notice Get how many SoulMinter NFTs a certain user owns
    mapping(address => uint256) public balanceOf;

    /// @notice Get birthdate of tokenID
    mapping(uint256 => uint256) public birthOf;

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

    /// @notice Withdraw function to transfer funds from mints
    function withdraw() public {
        uint256 espinaShare = address(this).balance / 10;
        uint256 sphereShare = address(this).balance - espinaShare;
        payable(espinaAdr).transfer(espinaShare);
        payable(sphereAdr).transfer(sphereShare);
    }

    /// @notice Mint a new Soulbound NFT to `to`
    /// @param to The recipient of the NFT
    function mint(address to) external payable {
        // Check to make sure 0.25 ether was sent to the function call:
        require(msg.value == 0.25 ether, 'Wrong amount of ETH sent');
        require(balanceOf[to] == 0, 'You can only mint one');

        // If so, some logic to transfer the digital item to the caller of the function:
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[nextTokenId] = to;
        birthOf[nextTokenId] = block.timestamp;

        emit Transfer(address(0), to, nextTokenId++);
    }

    /// @dev Returns an URI for a given token ID
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(ownerOf[_tokenId] != address(0), 'Token does not exist');
        address tokenOwner = ownerOf[_tokenId];
        uint birthdate = birthOf[_tokenId];
        string memory svgString = _render(_tokenId, tokenOwner, birthdate);
        return _metadata(_tokenId, svgString);
    }

    /// @dev Returns metadata as a json
    function _metadata(uint256 _tokenId, string memory _svgString) internal pure returns (string memory) {
        string memory tokenName = string(abi.encodePacked('Spherical #', utils.uint2str(_tokenId)));
        string memory tokenDescription = "The Sphere is a research-creation project developing new ecologies of funding for the performing arts. We envisage a world in which audiences co-own the artworks they love together with the artists, collectors and other stakeholders of a given project.\\nWebsite: [thesphere.as](https://thesphere.as)  Twitter: [@thesphere_as](https://twitter.com/thesphere_as)\\n\\nThe Spherical GeNFTs are dynamic on-chain generative artworks that evolve over time as an expression of membership in The Sphere. The particularities of the holder's wallet become the seed for an ongoing creation.";
        string memory json = string(
            abi.encodePacked('{"name":"', 
            tokenName, '","description":"', 
            tokenDescription, '","image": "data:image/svg+xml;base64,', 
            Base64.encode(bytes(_svgString)), '"}')
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /// @notice Airdrop NFTs to an array of addresses
    /// @param _recipients The recipients of the NFTs
    function airdrop(address[] calldata _recipients) public {
        require(msg.sender == admin, 'Not allowed to airdop');

        for (uint i = 0; i< _recipients.length; i++){
            
            unchecked {
                balanceOf[_recipients[i]]++;
            }

            ownerOf[nextTokenId] = _recipients[i];
            birthOf[nextTokenId] = block.timestamp;

            emit Transfer(address(0), _recipients[i], nextTokenId++);
        }
    }

    /// @notice Change the admin of the contract
    /// @param _newAdmin The admin that permission will be transferred to
    function changeAdmin(address _newAdmin) public {
        require(msg.sender == admin, 'Only admin can change');
        admin = _newAdmin;
    }

    function burn(uint256 _tokenId) public {
        require(msg.sender == ownerOf[_tokenId], 'Only owner can burn');
        balanceOf[msg.sender] = 0;
        ownerOf[_tokenId] = address(0);
        birthOf[_tokenId] = block.timestamp;

        emit Transfer(msg.sender, address(0), _tokenId);
    }
}