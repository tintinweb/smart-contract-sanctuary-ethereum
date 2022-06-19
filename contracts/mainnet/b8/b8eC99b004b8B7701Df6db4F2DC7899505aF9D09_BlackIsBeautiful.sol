// SPDX-License-Identifier: GPL-3.0

// HOFHOFHOFHOFHOFHOFHOFHOFHOFHOFHHOFHOFHOFHOF
// HOFHOFHOFHOF      HOFHOFH      HOFHOFHOFHOF
// HOFHOFHOFHOF      HOFHF        HOFHOFHOFHOF
// HOFHOFHOFHOF      HOF          HOFHOFHOFHOF
// HOFHOFHOFHOF      HOFHOFH      HOFHOFHOFHOF
// HOFHOFHOFHOF                   HOFHOFHOFHOF
// HOFHOFHOFHOF                   HOFHOFHOFHOF
// HOFHOFHOFHOF      HOFHOFH      HOFHOFHOFHOF
// HOFHOFHOFHOF      HOFHOFH      HOFHOFHOFHOF
// HOFHOFHOFHOF      HOFHOFH      HOFHOFHOFHOF
// HOFHOFHOFHOF      HOFHOFH      HOFHOFHOFHOF
// HOFHOFHOFHOFHOFHOFHOFHOFHOFHOFHHOFHOFHOFHOF

// -----------    House Of First   -----------
// ---   Black is Beautiful - Nick Davis   ---

pragma solidity ^0.8.10;
import "./ERC721Enum.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import {MerkleProof} from "./MerkleProof.sol";

contract OwnableDelegateProxy {}

/**
 * used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract BlackIsBeautiful is ERC721Enum, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using MerkleProof for bytes32[];
    string public baseURI;
    
    //sale settings
    uint256 public SALE_START_TIMESTAMP = 1659142800; // time when sale starts - NOT FINAL VALUE - TBC
    uint256 public SALE_END_TIMESTAMP = SALE_START_TIMESTAMP + (86400 * 10); // time when sale ends - NOT FINAL VALUE - TBC
    uint256 public price = 0.06 ether; // NOT FINAL VALUE - TBC
    uint256 public maxSupply = 1000; // max supply
    uint256 public reserved = 100; // 300 NFTs reserved for vault - NOT FINAL VALUE - TBC
    uint256 public maxPerTx = 2; // max per transaction - NOT FINAL VALUE - TBC
    uint256 public ambassadorAllowance = 2; // max per ambassador
    uint256 public allowancePerWallet = 2; // max mintable per wallet - NOT FINAL VALUE - TBC
    mapping(address => uint256) public purchases; // mapping of mints per address
    mapping(address => uint256) public ambassadorPurchases; // mapping of ambassador mints per address
    bool public signatureMode = false; // enable allowlist minting via signature
    bool public salePaused = false;
    bool public enableAmbassadorSale = false;
    bool public enableAllowlistSale = false;
    bool public enablePublicSale = false;

    // allowlist
    address public constant ALLOWLIST_SIGNER = 0x8430e0B7be3315735C303b82E4471D59AC152Aa5;
    
    string _name = "Black is Beautiful";
    string _symbol = "BlackIsBeautiful";
    string _initBaseURI = "https://houseoffirst.com:1335/blackisbeautiful/opensea/";

    bytes32 merkleRoot;

    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1; // OpenSea Mainnet Proxy Registry address
    
    constructor() ERC721P(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    function getPurchases(address addr) external view returns (uint256) {
        return purchases[addr];
    }

    function getAmbassadorPurchases(address addr) external view returns (uint256) {
        return ambassadorPurchases[addr];
    }

    function getTotalPurchases(address addr) external view returns (uint256) {
        return purchases[addr] + ambassadorPurchases[addr];
    }
    
    function mintingHasStarted() public view returns (bool) {
        return block.timestamp > SALE_START_TIMESTAMP;
    }

    function mintingHasEnded() public view returns (bool) {
        return block.timestamp > SALE_END_TIMESTAMP;
    }

    function getMaxSupply() public view returns (uint256) {
        return maxSupply;
    }

    function getAvailableMaxSupply() public view returns (uint256) {
        return maxSupply - reserved;
    }

    function mintingIsActive() public view returns (bool) {
        bool timeOk = mintingHasStarted() && !mintingHasEnded();
        bool notSoldOut = _owners.length <= getAvailableMaxSupply();
        return timeOk && notSoldOut;
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

    function _leaf(string memory allowance, string memory payload) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(payload, allowance));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function getAllowance(string memory allowance, bytes32[] calldata proof) public view returns (string memory) {
        string memory payload = string(abi.encodePacked(msg.sender));
        require(_verify(_leaf(allowance, payload), proof), "Invalid Merkle Tree proof supplied.");
        return allowance;
    }

    /**
     * public mint nfts (no signature required)
     */
    function mintNFT(uint256 numberOfNfts) public payable nonReentrant {
        require(!salePaused && enablePublicSale, "Sale paused or public sale disabled");
        require(block.timestamp > SALE_START_TIMESTAMP, "Sale has not started");
        require(block.timestamp < SALE_END_TIMESTAMP, "Sale has ended");
        uint256 s = _owners.length;
        require(numberOfNfts > 0 && numberOfNfts <= maxPerTx, "Invalid numberOfNfts");
        require((s + numberOfNfts) <= (maxSupply - reserved), "Exceeds Max Supply");
        require(msg.value >= price * numberOfNfts, "Not Enough ETH");
        require(purchases[msg.sender] + numberOfNfts <= allowancePerWallet, "Exceeds Allocation");
        purchases[msg.sender] += numberOfNfts;
        for (uint256 i = 0; i < numberOfNfts; ++i) {
            _mint(msg.sender, s + i);
        }
        delete s;
    }

    /**
     * allowlist mint nfts (signature required)
     */
    function allowlistMintNFT(uint256 numberOfNfts, uint256 allowance, bytes32[] memory proof, bytes memory signature) public payable nonReentrant {
        require(!salePaused && enableAllowlistSale, "Sale Paused");
        require(block.timestamp > SALE_START_TIMESTAMP, "Sale has not started");
        require(block.timestamp < SALE_END_TIMESTAMP, "Sale has ended");
        require(msg.value >= price * numberOfNfts, "Not Enough ETH");
        if(signatureMode) {
            // use signature for allowlist validation
            allowance = allowancePerWallet;
            require(isAllowlisted(msg.sender, signature), "Address not allowlisted");
        }
        else {
            // use merkle tree for allowlist validation
            string memory payload = string(abi.encodePacked(msg.sender));
            require(_verify(_leaf(Strings.toString(allowance), payload), proof), "Address not allowlisted");
            delete payload;
        }
        uint256 s = _owners.length;
        require(numberOfNfts > 0 && numberOfNfts <= maxPerTx, "Invalid numberOfNfts");
        require((s + numberOfNfts) <= (maxSupply - reserved), "Exceeds Max Supply");
        require(purchases[msg.sender] + numberOfNfts <= allowance, "Exceeds Allocation");
        purchases[msg.sender] += numberOfNfts;
        for (uint256 i = 0; i < numberOfNfts; ++i) {
            _mint(msg.sender, s + i);
        }
        delete s;
    }

    /**
     * ambassador mint nfts (signature required)
     */
    function ambassadorMintNFT(uint256 numberOfNfts, bytes memory signature) public payable nonReentrant {
        require(!salePaused && enableAmbassadorSale, "Sale Paused");
        require(isAllowlisted(msg.sender, signature), "Address not allowlisted");
        uint256 s = _owners.length;
        require(numberOfNfts > 0 && numberOfNfts <= maxPerTx, "Invalid numberOfNfts");
        require((s + numberOfNfts) <= (maxSupply - reserved), "Exceeds Max Supply");
        require(ambassadorPurchases[msg.sender] + numberOfNfts <= ambassadorAllowance, "Exceeds Allocation");
        ambassadorPurchases[msg.sender] += numberOfNfts;
        for (uint256 i = 0; i < numberOfNfts; ++i) {
            _mint(msg.sender, s + i);
        }
        delete s;
    }

    /**
     * admin minting for reserved nfts (callable by Owner only)
     */
    function giftNFT(uint256[] calldata quantity, address[] calldata recipient) external onlyOwner {
        require(quantity.length == recipient.length, "Invalid quantities and recipients (length mismatch)");
        uint256 totalQuantity = 0;
        uint256 s = _owners.length;
        for (uint256 i = 0; i < quantity.length; ++i) {
            totalQuantity += quantity[i];
        }
        require(s + totalQuantity <= maxSupply, "Exceeds Max Supply");
        require(totalQuantity <= reserved, "Exceeds Max Reserved");
        // update remaining reserved count
        reserved -= totalQuantity;
        delete totalQuantity;
        for (uint256 i = 0; i < recipient.length; ++i) {
            for (uint256 j = 0; j < quantity[i]; ++j) {
                _mint(recipient[i], s++);
            }
        }
        delete s;
    }

    /**
     * admin minting for reserved nfts - sets purchases[recipient] (callable by Owner only)
     */
    function giftNFTPurchases(uint256[] calldata quantity, address[] calldata recipient) external onlyOwner {
        require(quantity.length == recipient.length, "Invalid quantities and recipients (length mismatch)");
        uint256 totalQuantity = 0;
        uint256 s = _owners.length;
        for (uint256 i = 0; i < quantity.length; ++i) {
            totalQuantity += quantity[i];
        }
        require(s + totalQuantity <= maxSupply, "Exceeds Max Supply");
        require(totalQuantity <= reserved, "Exceeds Max Reserved");
        // update remaining reserved count
        reserved -= totalQuantity;
        delete totalQuantity;
        for (uint256 i = 0; i < recipient.length; ++i) {
            purchases[recipient[i]] += quantity[i];
            for (uint256 j = 0; j < quantity[i]; ++j) {
                _mint(recipient[i], s++);
            }
        }
        delete s;
    }

    /**
     * admin ambassador minting for reserved nfts (callable by Owner only)
     */
    function airdropToAmbassador(uint256 quantity, address recipient) external onlyOwner {
        require(ambassadorPurchases[recipient] + quantity <= ambassadorAllowance, "Exceeds ambassador allowance");
        uint256 s = _owners.length;
        require(s + quantity <= maxSupply, "Exceeds Max Supply");
        require(quantity <= reserved, "Exceeds Max Reserved");
        // update remaining reserved count
        reserved -= quantity;
        ambassadorPurchases[recipient] += quantity;
        for (uint256 i = 0; i < quantity; ++i) {
            _mint(recipient, s++);
        }
        delete s;
    }
    
    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }

    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function multiTransfer(uint256[] calldata tokenIds, address[] calldata recipient) external onlyOwner {
        require(tokenIds.length == recipient.length, "Invalid tokenIds and recipients (length mismatch)");
        for (uint256 i = 0; i < recipient.length; ++i) {
            for (uint256 j = 0; j < tokenIds[i]; ++j) {
                transferFrom(msg.sender, recipient[i], tokenIds[i]);
            }
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
    }

    function setMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    function setPurchases(address _addr, uint256 _purchases) public onlyOwner {
        purchases[_addr] = _purchases;
    }

    function setAmbassadorPurchases(address _addr, uint256 _purchases) public onlyOwner {
        ambassadorPurchases[_addr] = _purchases;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setReserved(uint256 _reserved) public onlyOwner {
        reserved = _reserved;
    }

    function setMaxPerTx(uint256 _maxPerTx) public onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setAmbassadorAllowance(uint256 _newAllowance) public onlyOwner {
        ambassadorAllowance = _newAllowance;
    }

    function setAllowancePerWallet(uint256 _allowancePerWallet) public onlyOwner {
        allowancePerWallet = _allowancePerWallet;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    /**
     * adjusts number of reserved nfts to psuedo limit supply (callable by Owner only)
     * example: if maxSupply = 10000 & supplyCap = 4000 then set reserved = 6000 (maxSupply - supplyCap)
     */
    function setSupplyCap(uint256 _supplyCap) public onlyOwner {
        require(_supplyCap <= maxSupply, "Supply cap exceeds max supply");
        reserved = maxSupply - _supplyCap;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setSalePaused(bool _salePaused) public onlyOwner {
        salePaused = _salePaused;
    }

    function setEnablePublicSale(bool _enablePublicSale) public onlyOwner {
        enablePublicSale = _enablePublicSale;
    }

    function setEnableAllowlistSale(bool _enableAllowlistSale) public onlyOwner {
        enableAllowlistSale = _enableAllowlistSale;
    }

    function setEnableAmbassadorSale(bool _enableAmbassadorSale) public onlyOwner {
        enableAmbassadorSale = _enableAmbassadorSale;
    }

    function setSignatureMode(bool _mode) public onlyOwner {
        signatureMode = _mode;
    }

    function setSaleStartTimestamp(uint256 _timestamp) public onlyOwner {
        SALE_START_TIMESTAMP = _timestamp;
    }

    function setSaleEndTimestamp(uint256 _timestamp) public onlyOwner {
        SALE_END_TIMESTAMP = _timestamp;
    }

    function setSaleStartEndTimestamp(uint256 _startTimestamp, uint256 _endTimestamp) public onlyOwner {
        setSaleStartTimestamp(_startTimestamp);
        setSaleEndTimestamp(_endTimestamp);
    }

    function setPhaseConfig(uint256 _startTimestamp, uint256 _endTimestamp, uint256 _maxPerTx, uint256 _allowancePerWallet, uint256 _supplyCap) public onlyOwner {
        setSaleStartEndTimestamp(_startTimestamp, _endTimestamp);
        setMaxPerTx(_maxPerTx);
        setAllowancePerWallet(_allowancePerWallet);
        setSupplyCap(_supplyCap);
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
    /**
     * whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) override public view returns (bool) {
        // whitelist opensea proxy contract for easy trading
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }
}