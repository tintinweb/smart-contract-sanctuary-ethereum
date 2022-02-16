// SPDX-License-Identifier: GPL-3.0

// -----------    House Of First   -----------
// - Remarkable Women - Transfer Contract V2 -

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";

pragma solidity ^0.8.10;

contract RWtransferV2 is Ownable, ReentrancyGuard {
    uint256 public price = 0.036 * (10 ** 18);
    uint256 public supply = 0; // nfts purchased
    uint256 public maxSupply = 200; // nfts available for purchase
    uint256 public nftsTransferred = 0;
    uint256 public maxMint = 1;
    uint256 public allowancePerAddress = 1;
    bool public salePaused = false;
    address public vaultAddress = 0xb2C7c59fB26932A673993a85D0FA66c6298f8F01;
    address public rwAddress = 0x3e69BaAb7A742c83499661C5Db92386B2424df11;
    address public constant WHITELIST_SIGNER = 0x8430e0B7be3315735C303b82E4471D59AC152Aa5; // MM signer

    mapping(address => uint256) public whitelistPurchases;
    mapping(address => uint256) public owedNfts;
    address[] internal _addressesToMonitor;
    uint256[] internal _mintedNftIds;

    function getMintedNftIds() external view returns (uint256[] memory) {
        return _mintedNftIds;
    }

    function getAddressesToMonitor() external view returns (address[] memory) {
        return _addressesToMonitor;
    }

    function getNftsTransferred() public view returns (uint256) {
        return nftsTransferred;
    }

    function needToTransfer() public view returns (bool) {
        return supply != nftsTransferred;
    }

    function totalSupply() public view returns (uint256) {
        return supply;
    }

    function totalAvailable() public view returns (uint256) {
        return maxSupply - supply;
    }

    function toggleSalePause(bool _salePaused) onlyOwner external {
       salePaused = _salePaused;
    }

    function setWhitelistPurchases(uint256[] calldata quantity, address[] calldata recipient) external onlyOwner {
        require(quantity.length == recipient.length, "Invalid quantities and recipients (length mismatch)");
        for (uint256 i = 0; i < recipient.length; ++i) {
            whitelistPurchases[recipient[i]] = quantity[i];
        }
    }

    function setWhitelistPurchasesSimple(uint256 quantity, address[] calldata recipient) external onlyOwner {
        for (uint256 i = 0; i < recipient.length; ++i) {
            whitelistPurchases[recipient[i]] = quantity;
        }
    }

    function setMintedNftIds(uint256[] calldata nftIds) external onlyOwner {
        delete _mintedNftIds;
        for (uint256 i = 0; i < nftIds.length; ++i) {
            _mintedNftIds.push(nftIds[i]);
        }
    }

    function setPrice(uint256 _price) onlyOwner external {
        price = _price;
    }

    function setNftsTransferred(uint256 _transferred) onlyOwner external {
        nftsTransferred = _transferred;
    }

    function setSupply(uint256 _supply) onlyOwner external {
        supply = _supply;
    }

    function setMaxSupply(uint256 _maxSupply) onlyOwner external {
        maxSupply = _maxSupply;
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

    function getNFTPrice() public view returns (uint256) {
        return price;
    }
    
    function getTokensAvailable() public view returns (uint256) {
        return totalAvailable();
    }

    function getWhitelistPurchases(address addr) external view returns (uint256) {
        return whitelistPurchases[addr];
    }

    function getOwedNfts(address addr) external view returns (uint256) {
        return owedNfts[addr];
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
        require(msg.value >= price * numberOfNfts, "Not Enough ETH");
        require(isWhitelisted(msg.sender, signature), "Address not whitelisted");
        require(numberOfNfts > 0 && numberOfNfts <= allowancePerAddress, "Invalid numberOfNfts");
        require(supply + numberOfNfts <= maxSupply, "Exceeds max supply");
        require(whitelistPurchases[msg.sender] + numberOfNfts <= allowancePerAddress, "Exceeds Allocation");

        whitelistPurchases[msg.sender] += numberOfNfts;
        owedNfts[msg.sender] += numberOfNfts;
        _addressesToMonitor.push(msg.sender);
        supply += numberOfNfts;
    }

    function transferOwedNfts(address recipient, uint256[] calldata nftTokenIds) onlyOwner external returns (uint256) {
        uint256 transferCount = nftTokenIds.length;
        require(owedNfts[recipient] >= transferCount, "More nfts than owed");
        for (uint256 i = 0; i < transferCount; ++i) {
            IERC721(rwAddress).safeTransferFrom(vaultAddress, recipient, nftTokenIds[i]);
            _mintedNftIds.push(nftTokenIds[i]);
        }
        owedNfts[recipient] -= transferCount;
        nftsTransferred += transferCount;
        delete transferCount;
        return owedNfts[recipient];
    }

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