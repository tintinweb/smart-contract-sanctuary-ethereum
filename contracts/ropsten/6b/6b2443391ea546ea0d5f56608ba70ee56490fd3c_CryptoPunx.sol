// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import './GuardedAgainstContracts.sol';
import './LockedPaymentSplitter.sol';

import {BooleanPacking} from './BooleanPacking.sol';


// ERC721A from Chiru Labs
import './ERC721A.sol';

// OZ Libraries
import './ReentrancyGuard.sol';
import './Ownable.sol';
import './PaymentSplitter.sol';

/**
 * @title CryptoPunx
 *    ______                 __        ____                  
 *   / ____/______  ______  / /_____  / __ \__  ______  _  __
 *  / /   / ___/ / / / __ \/ __/ __ \/ /_/ / / / / __ \| |/_/
 * / /___/ /  / /_/ / /_/ / /_/ /_/ / ____/ /_/ / / / />  <  
 * \____/_/   \__, / .___/\__/\____/_/    \__,_/_/ /_/_/|_|  
 *           /____/_/                                        
 * Credit to https://patorjk.com/ for text generator.
 */
contract CryptoPunx is
    ERC721A,
    Ownable,
    GuardedAgainstContracts,
    ReentrancyGuard,
    LockedPaymentSplitter
{
    using Strings for uint256;
    using BooleanPacking for uint256;

    uint256 private constant MAX_NFTS_FOR_SALE = 10000;
    uint256 private constant MAX_MINT_BATCH_SIZE = 20;

    uint256 public mintPricePerNft;
    bool public mintEnabled;

    string public baseURI;

    // BooleanPacking used on mintControlFlags
    uint256 private mintControlFlags;

    constructor(
        string memory __name,
        string memory __symbol,
        string memory __baseURI,
        address[] memory __addresses,
        uint256[] memory __splits
    ) ERC721A(__name, __symbol) SlimPaymentSplitter(__addresses, __splits) {
        baseURI = __baseURI;

        mintPricePerNft = 0.01 ether;
    }

    function setMintingState(
        bool __mintingActive,
        uint256 __mintPricePerNft
    ) external onlyOwner {
        mintEnabled = __mintingActive;

        if (__mintPricePerNft > 0) {
            mintPricePerNft = __mintPricePerNft;
        }
    }

    function isMintingActive() external view returns (bool) {
        return mintEnabled;
    }

    function maxSupply() external pure returns (uint256) {
        return MAX_NFTS_FOR_SALE;
    }

    function setBaseURI(string memory __baseUri) external onlyOwner {
        baseURI = __baseUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'No token');

        string memory base = _baseURI();
        require(bytes(base).length > 0, 'Base unset');

        return string(abi.encodePacked(base, _tokenFilename(tokenId)));
    }


    /**
     * @notice Mint CryptoPunx - purchase bound by terms & conditions of project.
     *
     * @param count the number of CryptoPunx to mint.
     */
    function mintPunxs(uint256 count) external payable nonReentrant onlyUsers {
        require(mintEnabled, 'Minting stopped');
        require(0 < count && count <= MAX_MINT_BATCH_SIZE, 'Invalid count');
        require(mintPricePerNft * count == msg.value, 'Invalid price');

        _internalMintTokens(_msgSender(), count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _tokenFilename(uint256 tokenId) internal view virtual returns (string memory) {
        return tokenId.toString();
    }

    function _internalMintTokens(address minter, uint256 count) internal {
        require(totalSupply() + count <= MAX_NFTS_FOR_SALE, 'Limit exceeded');

        _safeMint(minter, count);
    }
}