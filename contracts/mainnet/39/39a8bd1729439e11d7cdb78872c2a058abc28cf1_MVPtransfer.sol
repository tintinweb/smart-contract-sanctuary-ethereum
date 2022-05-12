// SPDX-License-Identifier: GPL-3.0

// ------------    House Of First   -------------
// --- Metaverse Players - Transfer Contract  ---

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";

pragma solidity ^0.8.10;

contract MVPtransfer is Ownable, ReentrancyGuard {
    uint256 public price = 0.045 * (10 ** 18);
    uint256 public currentId = 2000;
    uint256 public maxAvailableId = 3000;
    uint256 public initialSupply = maxAvailableId - currentId;
    uint256 public maxPerTx = 2; // max per transaction - NOT FINAL VALUE - TBC
    uint256 public allowancePerWallet = 2; // max mintable per wallet - NOT FINAL VALUE - TBC
    bool public salePaused = false;
    address public vaultAddress = 0xb2C7c59fB26932A673993a85D0FA66c6298f8F01;
    address public mvpAddress = 0x4819dAB28d11de83c20c75C7Fa2A6EAC9dC948D4;
    address public constant ALLOWLIST_SIGNER = 0x303B711240cF0C4ec9903DF6410B904E0f8E67e9; // MVP signer
    //uint256 public currentId = 10; // rinkeby
    //uint256 public maxAvailableId = 33; // rinkeby
    //address public vaultAddress = 0x63810EA234955414cD9Ed7C3ff3C9Ae2eE7C0595; // rinkeby
    //address public mvpAddress = 0x986cE329cF2B038910A79c873526C73D7C17e424; // rinkeby

    mapping(address => uint256) public purchases;

    function totalSupply() public view returns (uint256) {
        return initialSupply - totalAvailable();
    }

    function totalAvailable() public view returns (uint256) {
        uint256 available = maxAvailableId - currentId;
        return available;
    }

    function toggleSalePause(bool _salePaused) onlyOwner external {
       salePaused = _salePaused;
    }

    function setPrice(uint256 _price) onlyOwner external {
        price = _price;
    }

    function setInitialSupply(uint256 _supply) onlyOwner external {
        initialSupply = _supply;
    }

    function setMaxPerTx(uint256 _maxPerTx) onlyOwner external {
        maxPerTx = _maxPerTx;
    }

    function setAllowancePerWallet(uint256 _allowancePerWallet) onlyOwner external {
        allowancePerWallet = _allowancePerWallet;
    }

    function setVaultAddress(address _vaultAddress) onlyOwner external {
        vaultAddress = _vaultAddress;
    }
    
    function setMvpAddress(address _mvpAddress) onlyOwner external {
        mvpAddress = _mvpAddress;
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
    
    function getTokensAvailable() public view returns (uint256) {
        return maxAvailableId - currentId;
    }

    function canMintToken(uint256 tokenId) public view returns (bool){
        return tokenId < maxAvailableId && IERC721(mvpAddress).ownerOf(tokenId) == vaultAddress;
    }

    function getPurchases(address addr) external view returns (uint256) {
        return purchases[addr];
    }

    function getAllowancePerWallet() public view returns (uint256) {
        return allowancePerWallet;
    }
    
    function getNFTPrice() public view returns (uint256) {
        return price;
    }
    
    /* allowlist */
    function isAllowlisted(address user, bytes memory signature) public pure returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(user));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        return recoverSigner(ethSignedMessageHash, signature) == ALLOWLIST_SIGNER;
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

    function allowlistMintNFT(uint256 numberOfNfts, bytes memory signature) public payable nonReentrant {
        require(!salePaused, "Sale Paused");
        uint256 proposedId = currentId + numberOfNfts;
        require(proposedId < maxAvailableId, "Exceeds Max Available Supply");
        require(msg.value >= price * numberOfNfts, "Not Enough ETH");
        require(isAllowlisted(msg.sender, signature), "Address not whitelisted");
        require(numberOfNfts > 0 && numberOfNfts <= allowancePerWallet, "Invalid numberOfNfts");
        require(purchases[msg.sender] + numberOfNfts <= allowancePerWallet, "Exceeds Allocation");
        require(numberOfNfts <= maxPerTx, "Exceeds Max Per TX");

        purchases[msg.sender] += numberOfNfts;

        for (uint256 i = currentId; i < proposedId; i++) {
            IERC721(mvpAddress).safeTransferFrom(vaultAddress, msg.sender, i);
            currentId++;
        }
        delete proposedId;
    }

    //function testXfer(address recipientAddr, uint256 tokenId) public payable returns (uint256) {
    //    IERC721(mvpAddress).safeTransferFrom(vaultAddress, recipientAddr, tokenId);
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