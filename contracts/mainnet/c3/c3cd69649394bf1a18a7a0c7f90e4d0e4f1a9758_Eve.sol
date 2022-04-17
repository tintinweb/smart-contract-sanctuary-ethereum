// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

import { ERC721ALowCap } from "./ERC721ALowCap.sol";
import { ERC721A } from "./ERC721A.sol";
import { Strings } from "./Strings.sol";
import { ECDSA } from "./ECDSA.sol";
import { Ownable } from "./Ownable.sol";

contract Eve is ERC721A, ERC721ALowCap, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    modifier directOnly {
        require(msg.sender == tx.origin);
        _;
    }

    enum SaleStatus {
        CLOSED,
        WHITELIST,
        PUBLIC
    }

    struct AirdropData {
        address to;
        uint96 amount;
    }

    // Supply constants
    uint public constant MaxSupply = 10777;
    uint public constant ReservedSupply = 4407;
    uint public constant PublicSupply = MaxSupply - ReservedSupply;

    // Mint Settings
    uint public constant MintPassWhitelistMintPrice =  0.049 ether;
    uint public constant WhitelistMintPrice =  0.06 ether;
    uint public constant PublicMintPrice =  0.07 ether;
    uint constant maxMintsPerPublicTX = 7;

    // Sha-256 provenance
    bytes32 public constant provenanceHash = 0x0f3ca15e7fa2310a264187a0541bea543c0109ee43414f6bccdbfda35feb2de0;

    // Muttable state
    uint public reservedMinted;
    uint public randomStartingIndex;

    SaleStatus public saleStatus;

    string baseURI = "";

    address public signer = 0x6BFe1678260eAE70bD571997F4fDa7B731a155fD;

    constructor() ERC721A("The Sevens Eve", "EVE") {}

    // Minting

    function mintPublic(uint amount) external payable directOnly {
        // Check for sale status
        require(saleStatus == SaleStatus.PUBLIC, "Sale is not active");

        // Make sure mint doesn't go over total supply
        require(_totalMinted() + amount <= PublicSupply + reservedMinted, "Mint would go over max supply");

        // Verify the ETH amount sent
        require(msg.value == amount * PublicMintPrice, "Invalid ETH sent");

        // Mints per public transaction are limited to 7
        require(amount > 0 && amount <= maxMintsPerPublicTX, "Invalid amount");

        // Mint the token(s)
        _mint(msg.sender, amount, false, false);

        // If maximum public supply is reached, close the saleStatus
        if(_totalMinted() == PublicSupply + reservedMinted) {
            saleStatus = SaleStatus.CLOSED;
        }
    }

    function mintWhitelist(uint amount, uint mintPassAmount, uint maxAmount, uint maxMintPassAmount, bytes calldata signature) external payable directOnly {
        // Check for sale status
        require(saleStatus == SaleStatus.WHITELIST, "Sale is not active");

        // Make sure mint doesn't go over total supply
        require(_totalMinted() + amount + mintPassAmount <= PublicSupply + reservedMinted, "Mint would go over max supply");

        // Fetch amount minted for sender
        (uint whitelistMinted, uint mintPassMinted) = getWhitelistMintedData(msg.sender);

        // Verify sender isn't minting over maximum allowed for both whitelist minting and mint pass whitelist minting
        require(amount + whitelistMinted <= maxAmount, "Invalid amount");
        require(mintPassAmount + mintPassMinted <= maxMintPassAmount, "Invalid amount");

        // Verify the ETH amount sent
        require(msg.value == (amount * WhitelistMintPrice) + (mintPassAmount * MintPassWhitelistMintPrice), "Invalid ETH sent");

        // Verify the ECDSA signature
        require(verifySignature(keccak256(abi.encode(msg.sender, maxAmount, maxMintPassAmount)), signature));
        
        /*
         * Mint the token(s)
         * while splitting mints in batches of 7
         * this will help with gas consuming loops when transferring or selling tokens
         */ 
        if(amount > 0) {
            uint mintedSoFar = 0;
            do {
                uint batchAmount = min(amount - mintedSoFar, 7);
                mintedSoFar += batchAmount;
                _mint(msg.sender, batchAmount, true, false);
            } while(mintedSoFar < amount);
        }

        if(mintPassAmount > 0) {
            uint mintedSoFar = 0;
            do {
                uint batchAmount = min(mintPassAmount - mintedSoFar, 7);
                mintedSoFar += batchAmount;
                _mint(msg.sender, batchAmount, false, true);
            } while(mintedSoFar < mintPassAmount);
        }
    }

    // View Only

    function tokenURI(uint tokenId) public view override returns(string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString(), '.json'));
    }

    // Internal

    function verifySignature(bytes32 hash, bytes calldata signature) internal view returns(bool) {
        return hash.toEthSignedMessageHash().recover(signature) == signer;
    }

    // Only Owner

    function airdrop(AirdropData[] calldata airdropData) external onlyOwner {
        uint totalDropped = 0;
        unchecked {
            uint len = airdropData.length;
            for(uint i = 0; i < len; i++) {
                totalDropped += airdropData[i].amount;
                _airdropMint(airdropData[i].to, airdropData[i].amount);
            }
        }
        require((reservedMinted += totalDropped) <= ReservedSupply, "OVER_SUPPLY");
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function rollRandomStartingIndex() external onlyOwner {
        require(provenanceHash != bytes32(0), "PROVENANCE_HASH_NOT_SET");
        require(randomStartingIndex == 0, "RSI_SET");

        uint random = uint(keccak256(abi.encode(block.timestamp, block.difficulty, totalSupply())));
        randomStartingIndex = (random % MaxSupply);

        /* 
         * The first token in the collection(which starts from 1) will have the metadata of `randomStartingIndex`
         * for that reason it must not be the same to avoid default order
         */
        if(randomStartingIndex == 1) randomStartingIndex++;
    }

    // 0: CLOSED
    // 1: WHITELIST
    // 2: PUBLIC
    function setSaleStatus(SaleStatus _saleStatus) external onlyOwner {
        saleStatus = _saleStatus;
    }

    function withdraw(address to) external onlyOwner {
        (bool success, ) = to.call{ value: address(this).balance }("");
        require(success, "Transfer failed");
    }

    // Utils

    function min(uint a, uint b) internal pure returns(uint) {
        return(a < b ? a : b);
    }

}