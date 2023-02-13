//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./ERC721A.sol";

contract Chods is ERC721A, Ownable {
    using ECDSA for bytes32;
    
    uint256 public mintedTotal;
    uint256 private price = 0.02 ether;
    string public baseURI = "https://chods.xyz/tokens/";
    string public finalHash;

    address private signer = 0xA00410A68eBB3308B53549Bb9338d41035E7ea28;
    mapping(uint32 => bool) private usedSigs;
    
    constructor() ERC721A("Chods", "CHODS") {
        _mint(msg.sender, 1000);
        mintedTotal = 1000;
    }

    function mint(uint256 quantity) external payable {
        require(quantity <= 20);
        require(mintedTotal + quantity <= 10000);
        require(msg.value == price * quantity);
        _mint(msg.sender, quantity);
        mintedTotal += quantity;
    }
    
    function verify(uint32 sigId, uint64 timestamp, bytes memory sig) private view returns(bool) {
        bytes32 hash = keccak256(abi.encode(sigId, timestamp));
        return signer == hash.toEthSignedMessageHash().recover(sig);
    }
    
    function freemint(uint32 sigId, uint64 timestamp, bytes memory sig) external {
        require(verify(sigId, timestamp, sig));
        require(block.timestamp < timestamp + 600);
        require(!usedSigs[sigId]);
        require(mintedTotal < 10000);
        _mint(msg.sender, 1);
        usedSigs[sigId] = true;
        ++mintedTotal;
    }

    function setSigner(address newSigner) external onlyOwner {
        signer = newSigner;
    }
    
    function empty() external onlyOwner {
        payable(msg.sender).call{value: address(this).balance}("");
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string.concat(baseURI, Strings.toString(tokenId));
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    function setFinalHash(string calldata hash) external onlyOwner {
        require(bytes(finalHash).length == 0);
        finalHash = hash;
    }
}