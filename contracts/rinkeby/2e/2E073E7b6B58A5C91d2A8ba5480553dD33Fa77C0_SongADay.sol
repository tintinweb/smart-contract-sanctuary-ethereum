// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;


/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                                                             //
//     ░██████╗░█████╗░███╗░░██╗░██████╗░░█████╗░██████╗░░█████╗░██╗░░░██╗     //
//     ██╔════╝██╔══██╗████╗░██║██╔════╝░██╔══██╗██╔══██╗██╔══██╗╚██╗░██╔╝     //
//     ╚█████╗░██║░░██║██╔██╗██║██║░░██╗░███████║██║░░██║███████║░╚████╔╝░     //
//     ░╚═══██╗██║░░██║██║╚████║██║░░╚██╗██╔══██║██║░░██║██╔══██║░░╚██╔╝░░     //
//     ██████╔╝╚█████╔╝██║░╚███║╚██████╔╝██║░░██║██████╔╝██║░░██║░░░██║░░░     //
//     ╚═════╝░░╚════╝░╚═╝░░╚══╝░╚═════╝░╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░░░╚═╝░░░     //
//                                                                             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./MerkleProof.sol";

import "./IOpenStore.sol";

/**
 * @title ERC721 token for SongADay by Jonathan Mann
 *
 * @author swaHili
 */
contract SongADay is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    // -- Counters --
    Counters.Counter private _totalClaimed;
    Counters.Counter private _totalPublicMinted;
    Counters.Counter private _totalDailyMinted;

    // Address of interface identifier for royalty standard
    bytes4 private constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    // -- Accounts --
    address private constant ARTIST   = 0x3d9456Ad6463a77bD77123Cb4836e463030bfAb4;
    address private constant TREASURY = 0x2a2C412c440Dfb0E7cae46EFF581e3E26aFd1Cd0;
    address private constant VAULT    = 0x40b8992e107718c8d8ED892854Dd7a42470f3248;

    // -- Magic Numbers --
    uint256 private constant LIMIT  = 6;
    uint256 private constant OFFSET = 731;
    uint256 private constant SUPPLY = 4019;

    // Address of interface contract for OpenSea Shared Storefront (OPENSTORE)
    IOpenStore private openStoreContract;

    // Hash of merkle root for public claim
    bytes32 private merkleRoot;

    // IPFS CID hash of metadata folder (2009-2021)
    string private ipfsMetadataHash;

    // Magical array of integers used to generate token IDs
    uint16[] private magicalArr = new uint16[](SUPPLY-1);

    // Status of public mint
    bool public publicSale;

    // Timestamp of most recent treasury mint
    uint256 public previousTreasuryMint;

    // Price of public sale (0.2 ETH)
    uint256 public priceAmount = 200000000000000000;

    // Frequency of each randomized treasury mint (10 days)
    uint256 public frequency = 864000;

    /**
     * @notice Initializes contract and sets state variables.
     * @param _ipfsMetadataHash IPFS CID hash of metadata folder
     * @param _contractAddress Address of OpenStore contract
     */
    constructor(string memory _ipfsMetadataHash, IOpenStore _contractAddress) ERC721("SongADay", "SAD") {
        ipfsMetadataHash = _ipfsMetadataHash;
        openStoreContract = _contractAddress;
        previousTreasuryMint = block.timestamp;
    }

    /**
     * @notice Owner randomizes daily mint based on frequency timeframe.
     * @param _tokenId ID of token
     * @param _ipfsMetadataHash IPFS CID hash of metadata file
     */
    function dailyMint(uint256 _tokenId, string memory _ipfsMetadataHash) external onlyOwner {
        uint256 randInt = uint256(keccak256(abi.encodePacked(block.timestamp, _ipfsMetadataHash)));

        if (randInt % 10 == 0 && previousTreasuryMint + frequency <= block.timestamp) {
            _mintSong(_tokenId, _ipfsMetadataHash, TREASURY);
            previousTreasuryMint = block.timestamp;
        } else {
            _mintSong(_tokenId, _ipfsMetadataHash, _msgSender());
        }

        _totalDailyMinted.increment();
    }

    /**
     * @notice Owner batch mints tokens to list of addresses.
     * @param _tokenIds List of token IDs
     * @param _owners List of owner addresses
     */
    function batchMint(uint256[] calldata _tokenIds, address[] calldata _owners) external onlyOwner {
        uint256 tokenId;
        string memory tokenURI;

        for (uint256 i; i < _tokenIds.length; i++) {
            tokenId = _tokenIds[i] + OFFSET;
            _shrinkArr(_tokenIds[i]);

            tokenURI = string(abi.encodePacked(ipfsMetadataHash, "/", tokenId.toString()));
            _mintSong(tokenId, tokenURI, _owners[i]);
            _totalPublicMinted.increment();
        }
    }

    /**
     * @notice Public randomly mints tokens.
     * @param _amount Number of tokens being minted
     *
     * Requirements:
     *
     * - `publicSale` must be active.
     * - `amount` must be less than transaction limit.
     * - `totalMinted` plus `amount` must be less than max supply.
     * - `priceAmount` times `amount` must be equal to `msg.value`.
     */
    function publicMint(uint256 _amount) payable external nonReentrant {
        uint256 totalMinted = _totalPublicMinted.current();
        require(publicSale == true, "PublicMint: Sale is not active");
        require(_amount < LIMIT, "PublicMint: Amount exceeds transaction limit");
        require(totalMinted + _amount < SUPPLY, "PublicMint: Amount exceeds max supply");
        require(priceAmount * _amount == msg.value, "PublicMint: Incorrect payment amount");

        uint256 tokenId;
        string memory tokenURI;
        address owner = _msgSender();
        uint256 randInt = uint256(keccak256(abi.encodePacked(block.timestamp, owner, totalMinted)));

        for (uint256 i; i < _amount; i++) {
            tokenId = _generateId(randInt);
            tokenURI = string(abi.encodePacked(ipfsMetadataHash, "/", tokenId.toString()));
            _mintSong(tokenId, tokenURI, owner);

            _totalPublicMinted.increment();
            randInt >>= 8;
        }
    }

    /**
     * @notice Public batch claims tokens.
     * @param _openStoreIds List of OpenStore IDs
     * @param _tokenIds List of token IDs
     * @param _proofs Lists of merkle proofs
     */
    function publicClaim(
        uint256[] calldata _openStoreIds,
        uint256[] calldata _tokenIds,
        bytes32[][] calldata _proofs
    ) external nonReentrant {
        address owner = _msgSender();
        for (uint256 i; i < _openStoreIds.length; i++) {
            _claim(_openStoreIds[i], _tokenIds[i], _proofs[i], owner);
        }
    }

    /**
     * @notice Claims token and burns ERC1155 token stored on OpenStore contract.
     * @dev Checking ownership and existence is not required due to _safeTransferFrom and _mint.
     *
     * Requirements:
     *
     * - merkle proof must be valid.
     */
    function _claim(uint256 _openStoreId, uint256 _tokenId, bytes32[] calldata _proof, address _owner) private {
        bytes32 leaf = keccak256(abi.encodePacked(_openStoreId, _tokenId));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "Claim: Invalid merkle proof");

        string memory tokenURI = string(abi.encodePacked(ipfsMetadataHash, "/", _tokenId.toString()));
        openStoreContract.safeTransferFrom(_owner, VAULT, _openStoreId, 1, "");
        _mintSong(_tokenId, tokenURI, _owner);
        _totalClaimed.increment();
    }

    /**
     * @notice Sets tokenURI and transfers token to owner.
     */
    function _mintSong(uint256 _tokenId, string memory _tokenURI, address _to) private {
        _safeMint(_to, _tokenId, "");
        _setTokenURI(_tokenId, _tokenURI);
    }

    /**
     * @notice Generates randomly unique token ID.
     * @dev Thank you @xtremetom https://xtremetom.medium.com/solidity-random-numbers-f54e1272c7dd
     */
    function _generateId(uint256 _randInt) private returns(uint256 tokenId) {
        uint256 randIndex = _randInt % magicalArr.length;
        tokenId = (magicalArr[randIndex] != 0) ? magicalArr[randIndex] + OFFSET : randIndex + OFFSET;
        _shrinkArr(randIndex);
    }

    /**
     * @notice Replaces index value and shrinks array size.
     */
    function _shrinkArr(uint256 _randIdex) private {
        uint256 maxIndex = magicalArr.length - 1;
        magicalArr[_randIdex] = (magicalArr[maxIndex] == 0) ? uint16(maxIndex) : uint16(magicalArr[maxIndex]);
        magicalArr.pop();
    }

    /**
     * @notice Returns total supply of tokens existing on contract.
     */
    function totalSupply() public view returns (uint256) {
        return _totalClaimed.current() + _totalPublicMinted.current() + _totalDailyMinted.current();
    }

    /**
     * @notice Returns total remaining tokens from public mint.
     */
    function totalRemaining() public view returns (uint256) {
        return (SUPPLY-1) - _totalPublicMinted.current();
    }

    /**
     * @notice Updates frequency of randomized treasury mint.
     */
    function setFrequency(uint256 _seconds) external onlyOwner {
        frequency = _seconds;
    }

    /**
     * @notice Sets hash of merkle root for public claim.
     */
    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    /**
     * @dev Updates price of token for public mint.
     */
    function setPrice(uint256 _wei) external onlyOwner {
        priceAmount = _wei;
    }

    /**
     * @notice Toggles sale for public mint.
     */
    function toggleSale() external onlyOwner {
        publicSale = !publicSale;
    }

    /**
     * @notice Withdraws funds from contract.
     */
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(ARTIST).transfer(balance);
    }

    /**
     * @notice Repairs metadata for list of tokens.
     */
    function repairMetadata(uint256[] calldata _tokenIds, string[] calldata _tokenURIs) external onlyOwner {
        for (uint256 i; i < _tokenIds.length; i++) {
            _setTokenURI(_tokenIds[i], _tokenURIs[i]);
        }
    }

    /**
     * @notice See {ERC721-baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return "ipfs://";
    }

    /**
     * @notice See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256 /* _tokenId */, uint256 _salePrice) external pure returns (address, uint256 royaltyAmount) {
        royaltyAmount = (_salePrice * 10) / 100;

        return (TREASURY, royaltyAmount);
    }

    /**
     * @notice See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return interfaceId == INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
    }
}