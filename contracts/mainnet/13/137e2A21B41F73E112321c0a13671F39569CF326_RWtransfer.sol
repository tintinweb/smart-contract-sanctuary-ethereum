// SPDX-License-Identifier: GPL-3.0

// -----------    House Of First   -----------
// -- Remarkable Women - Transfer Contract  --

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";

pragma solidity ^0.8.10;

contract RWtransfer is Ownable, ReentrancyGuard {
    uint256 public price = 0.036 * (10 ** 18);
    uint256 public currentId = 2633; // 4800
    uint256 public maxAvailableId = 2832; // 4999
    uint256 public maxMint = 1;
    uint256 public allowancePerAddress = 1;
    bool public salePaused = false;
    address public vaultAddress = 0xb2C7c59fB26932A673993a85D0FA66c6298f8F01;
    address public rwAddress = 0x3e69BaAb7A742c83499661C5Db92386B2424df11;
    address public constant WHITELIST_SIGNER = 0x8430e0B7be3315735C303b82E4471D59AC152Aa5; // MM signer
    //uint256 public currentId = 10; // rinkeby
    //uint256 public maxAvailableId = 33; // rinkeby
    //address public vaultAddress = 0x63810EA234955414cD9Ed7C3ff3C9Ae2eE7C0595; // rinkeby
    //address public rwAddress = 0x986cE329cF2B038910A79c873526C73D7C17e424; // rinkeby

    mapping(address => uint256) public whitelistPurchases;

    function totalSupply() public view returns (uint256) {
        return 400 - totalAvailable();
    }

    function totalAvailable() public view returns (uint256) {
        uint256 available = maxAvailableId - currentId;
        if(maxAvailableId < 3000) {
            available += 200;
        }
        return available;
    }

    function toggleSalePause(bool _salePaused) onlyOwner external {
       salePaused = _salePaused;
    }

    function setPrice(uint256 _price) onlyOwner external {
        price = _price;
    }

    function setMaxMint(uint256 _maxMint) onlyOwner external {
        maxMint = _maxMint;
    }

    function setAllowancePerAddress(uint256 _allowancePerAddress) onlyOwner external {
        allowancePerAddress = _allowancePerAddress;
    }

    function setVaultAddress(address _vaultAddress) onlyOwner external {
        vaultAddress = _vaultAddress;
    }
    
    function setRWAddress(address _rwAddress) onlyOwner external {
        rwAddress = _rwAddress;
    }

    function setMaxAvailableId(uint256 _id) onlyOwner external {
        maxAvailableId = _id;
    }
    
    function setCurrentId(uint256 _id) onlyOwner external {
        currentId = _id;
    }

    function getCurrentId() public view returns (uint256) {
        return currentId;
    }

    function getMaxAvailableId() public view returns (uint256) {
        return maxAvailableId;
    }

    function getNFTPrice() public view returns (uint256) {
        return price;
    }
    
    function getTokensAvailable() public view returns (uint256) {
        return maxAvailableId - currentId;
    }

    function canMintToken(uint256 tokenId) public view returns (bool){
        return tokenId < maxAvailableId && IERC721(rwAddress).ownerOf(tokenId) == vaultAddress;
    }

    function getWhitelistPurchases(address addr) external view returns (uint256) {
        return whitelistPurchases[addr];
    }

    /* whitelist */
    function isWhitelisted(address user, bytes memory signature) public pure returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(user));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        return recoverSigner(ethSignedMessageHash, signature) == WHITELIST_SIGNER;
    }
    
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }
    
    function splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function whitelistMintNFT(uint256 numberOfNfts, bytes memory signature) public payable nonReentrant {
        require(!salePaused, "Sale Paused");
        uint256 proposedId = currentId + numberOfNfts;

        // change max available to the next batch
        if(proposedId > maxAvailableId && maxAvailableId < 3000) {
            currentId = 4800;
            maxAvailableId = 4999;
            proposedId = currentId + numberOfNfts;
        }
        require(proposedId < maxAvailableId, "Exceeds Max Available Supply");
        require(msg.value >= price * numberOfNfts, "Not Enough ETH");
        require(isWhitelisted(msg.sender, signature), "Address not whitelisted");
        require(numberOfNfts > 0 && numberOfNfts <= allowancePerAddress, "Invalid numberOfNfts");
        require(whitelistPurchases[msg.sender] + numberOfNfts <= allowancePerAddress, "Exceeds Allocation");

        whitelistPurchases[msg.sender] += numberOfNfts;

        for (uint256 i = currentId; i < proposedId; i++) {
            IERC721(rwAddress).safeTransferFrom(vaultAddress, msg.sender, i);
            currentId++;
        }
        delete proposedId;
    }

    //function testXfer(address recipientAddr, uint256 tokenId) public payable returns (uint256) {
    //    IERC721(rwAddress).safeTransferFrom(vaultAddress, recipientAddr, tokenId);
    //    return 0;
    //}

    // for transparency regarding ETH raised
    uint256 totalWithdrawn = 0;

    function getTotalWithdrawn() public view returns (uint256) {
        return totalWithdrawn;
    }

    function getTotalBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTotalRaised() public view returns (uint256) {
        return getTotalWithdrawn() + getTotalBalance();
    }

    /**
     * withdraw ETH from the contract (callable by Owner only)
     */
    function withdraw() public payable onlyOwner {
        uint256 val = address(this).balance;
        (bool success, ) = payable(msg.sender).call{
            value: val
        }("");
        require(success);
        totalWithdrawn += val;
        delete val;
    }
}