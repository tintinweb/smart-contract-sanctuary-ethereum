// SPDX-License-Identifier: MIT

/***   
  _____                     _                __   _   _             _____                _ _                      
 |  __ \                   | |              / _| | | | |           / ____|              (_) |                     
 | |__) |_ _ _ __ _ __ ___ | |_ ___    ___ | |_  | |_| |__   ___  | |     __ _ _ __ _ __ _| |__   ___  __ _ _ __  
 |  ___/ _` | '__| '__/ _ \| __/ __|  / _ \|  _| | __| '_ \ / _ \ | |    / _` | '__| '__| | '_ \ / _ \/ _` | '_ \ 
 | |  | (_| | |  | | | (_) | |_\__ \ | (_) | |   | |_| | | |  __/ | |___| (_| | |  | |  | | |_) |  __/ (_| | | | |
 |_|   \__,_|_|  |_|  \___/ \__|___/  \___/|_|    \__|_| |_|\___|  \_____\__,_|_|  |_|  |_|_.__/ \___|\__,_|_| |_|                                                                                                                                                                                                            
*/

/// @title Parrots of the Carribean
/// @author rayne & jackparrot

pragma solidity >=0.8.13;

import "./ERC721.sol";
import "./Owned.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

/// @notice Thrown when attempting to mint while total supply has been minted.
error MintedOut();
/// @notice Thrown when minter does not have enough ether.
error NotEnoughFunds();
/// @notice Thrown when a public minter / whitelist minter has reached their mint capacity.
error AlreadyClaimed();
/// @notice Thrown when the jam sale is not active.
error JamSaleNotActive();
/// @notice Thrown when the public sale is not active.
error PublicSaleNotActive();
/// @notice Thrown when the msg.sender is not in the jam list.
error NotJamListed();
/// @notice Thrown when a signer is not authorized.
error NotAuthorized();

contract POTC is ERC721, Owned {
    using Strings for uint256;

    /// @notice The total supply of POTC.
    uint256 public constant MAX_SUPPLY = 555;
    /// @notice Mint price.
    uint256 public mintPrice = 0.1 ether;
    /// @notice The current supply starts at 25 due to the team minting from tokenID 0 to 14, and 15-24 reserved for legendaries.
    /// @dev Using total supply as naming to make the pre-reveal easier with a pre-deployed S3 script.
    uint256 public totalSupply = 25;

    /// @notice The base URI.
    string baseURI;

    /// @notice Returns true when the jam list sale is active, false otherwise.
    bool public jamSaleActive;
    /// @notice Returns true when the public sale is active, false otherwise.
    bool public publicSaleActive;

    /// @notice Keeps track of whether jamlist has already minted or not. Max 1 mint.
    mapping(address => bool) public whitelistClaimed;
    /// @notice Keeps track of whether a public minter has already minted or not. Max 1 mint.
    mapping(address => bool) public publicClaimed;

    /// @notice Merkle root hash for whitelist verification.
    /// @dev Set to immutable instead of hard-coded to prevent human-error when deploying.
    bytes32 public merkleRoot;
    /// @notice Address of the signer who is allowed to burn POTC.
    address private potcBurner;

    constructor(string memory _baseURI, bytes32 _merkleRoot)
        ERC721("Parrots of the Carribean", "POTC")
        Owned(msg.sender)
    {
        baseURI = _baseURI;
        merkleRoot = _merkleRoot;
        _balanceOf[msg.sender] = 25;
        unchecked {
            for (uint256 i = 0; i < 25; ++i) {
                _ownerOf[i] = msg.sender;
                emit Transfer(address(0), msg.sender, i);
            }
        }
    }

    /// @notice Allows the owner to change the base URI of POTC's corresponding metadata.
    /// @param _uri The new URI to set the base URI to.
    function setURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    /// @notice The URI pointing to the metadata of a specific assett.
    /// @param _id The token ID of the requested parrot. Hardcoded .json as suffix.
    /// @return The metadata URI.
    function tokenURI(uint256 _id)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, _id.toString(), ".json"));
    }

    /// @notice Public POTC mint.
    /// @dev Allows any non-contract signer to mint a single POTC. Capped by 1.
    /// @dev Jamlisted addresses can join mint both one POTC during jam sale & public sale.
    /// @dev Current supply addition can be unchecked, as it cannot overflow.
    /// TODO chain if statements to see if we can save gas?
    function publicMint() public payable {
        if (!publicSaleActive) revert PublicSaleNotActive();
        if (publicClaimed[msg.sender]) revert AlreadyClaimed();
        if (totalSupply + 1 > MAX_SUPPLY) revert MintedOut();
        if ((msg.value) < mintPrice) revert NotEnoughFunds();

        unchecked {
            publicClaimed[msg.sender] = true;
            _mint(msg.sender, totalSupply);
            ++totalSupply;
        }
    }

    /// @notice Mints a POTC for a signer on the jamlist. Gets the tokenID correspondign to the current supply.
    /// @dev We do not keep track of the whitelist supply, considering only a total of 444 addresses will be valid in the merkle tree.
    /// @dev This means that the maximum supply including full jamlist mint and team mint can be 459 at most, as each address can mint once.
    /// @dev Current supply addition can be unchecked, as it cannot overflow.
    /// @param _merkleProof The merkle proof based on the address of the signer as input.
    function jamListMint(bytes32[] calldata _merkleProof) public payable {
        if (!jamSaleActive) revert JamSaleNotActive();
        if (whitelistClaimed[msg.sender]) revert AlreadyClaimed();
        if (totalSupply + 1 > MAX_SUPPLY) revert MintedOut();
        if ((msg.value) < mintPrice) revert NotEnoughFunds();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf))
            revert NotJamListed();

        unchecked {
            whitelistClaimed[msg.sender] = true;
            _mint(msg.sender, totalSupply);
            ++totalSupply;
        }
    }

    /// @notice Authorize a specific address to serve as the POTC burner. For future use.
    /// @param _newBurner The address of the new burner.
    function setPOTCBurner(address _newBurner) public onlyOwner {
        potcBurner = _newBurner;
    }

    /// @notice Burn a POTC with a specific token id.
    /// @dev !NOTE: Both publicSale & jamSale should be inactive.
    /// @dev Unlikely that the totalSupply will be below 0. Hence, unchecked.
    /// @param tokenId The token ID of the parrot to burn.
    function burn(uint256 tokenId) public {
        if (msg.sender != potcBurner) revert NotAuthorized();
        unchecked {
            --totalSupply;
        }
        _burn(tokenId);
    }

    /// @notice Flip the jam sale state.
    function flipJamSaleState() public onlyOwner {
        jamSaleActive = !jamSaleActive;
    }

    /// @notice Flip the public sale state.
    function flipPublicSaleState() public onlyOwner {
        jamSaleActive = false;
        publicSaleActive = !publicSaleActive;
    }

    /// @notice Set the price of mint, in case there is no mint out.
    function setPrice(uint256 _targetPrice) public onlyOwner {
        mintPrice = _targetPrice;
    }

    /// @notice Transfer all funds from contract to the contract deployer address.
    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }

    /// @notice Set the merkle root.
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }
}