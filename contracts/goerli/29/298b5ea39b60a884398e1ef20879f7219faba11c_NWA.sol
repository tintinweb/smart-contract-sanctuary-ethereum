// SPDX-License-Identifier: GPL-3.0
/*
███╗░░██╗░██╗░░░░░░░██╗░█████╗░
████╗░██║░██║░░██╗░░██║██╔══██╗
██╔██╗██║░╚██╗████╗██╔╝███████║
██║╚████║░░████╔═████║░██╔══██║
██║░╚███║░░╚██╔╝░╚██╔╝░██║░░██║
╚═╝░░╚══╝░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝


█▀▀▄ █▀▀ ▀▀█▀▀ █▀▀ 　 █░░░█ ░▀░ ▀▀█▀▀ █░░█ 　 █▀▀█ ▀▀█▀▀ ▀▀█▀▀ ░▀░ ▀▀█▀▀ █░░█ █▀▀▄ █▀▀ 
█░░█ █▀▀ ░░█░░ ▀▀█ 　 █▄█▄█ ▀█▀ ░░█░░ █▀▀█ 　 █▄▄█ ░░█░░ ░░█░░ ▀█▀ ░░█░░ █░░█ █░░█ █▀▀ 
▀░░▀ ▀░░ ░░▀░░ ▀▀▀ 　 ░▀░▀░ ▀▀▀ ░░▀░░ ▀░░▀ 　 ▀░░▀ ░░▀░░ ░░▀░░ ▀▀▀ ░░▀░░ ░▀▀▀ ▀▀▀░ ▀▀▀
*/

pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./MerkleProof.sol";

import "./ERC721A.sol";

contract NWA is ERC721A, Ownable {

    string public PROVENANCE;

    bytes32 public merkleRoot = ""; // Construct this from (address, amount) tuple elements
    mapping(address => uint) public whitelistRemaining; // Maps user address to their remaining mints if they have minted some but not all of their allocation
    mapping(address => bool) public whitelistUsed; // Maps user address to bool, true if user has minted

    uint public presaleMintPrice;
    uint public dutchAuctionStart;
    uint public dutchAuctionEnd = 0.03 ether;
    uint public dutchAuctionIncrement = 0.03 ether;
    uint public dutchAuctionStepTime = 300; // 5 minutes
    uint public maxItems = 10000;
    uint public maxItemsPerTx = 5;
    address public recipient;
    string public _baseTokenURI;
    uint public startTimestamp;

    event Mint(address indexed owner, uint indexed tokenId);

    constructor(address _owner) ERC721A("NFTs With Attitude", "NWA", 420) {
        require(_owner != address(0x0), "Set owner");
        transferOwnership(_owner);
    }

    modifier mintingOpen() {
        require(startTimestamp != 0, "Start timestamp not set");
        require(block.timestamp >= startTimestamp, "Not open yet");
        _;
    }

    function dutchAuctionPrice() public view returns (uint) {
        if (startTimestamp == 0 || block.timestamp <= startTimestamp) {
            return dutchAuctionStart;
        } else {
            uint increments = (block.timestamp - startTimestamp) / dutchAuctionStepTime;
            if (increments * dutchAuctionIncrement >= dutchAuctionStart) {
                return dutchAuctionEnd;
            } else {
                return dutchAuctionStart - (increments * dutchAuctionIncrement);
            }
        }
    }

    function ownerMint(uint amount) external onlyOwner {
        _mintWithoutValidation(msg.sender, amount, true);
    }

    function publicMint(uint amount) external payable mintingOpen {
        // Require nonzero amount
        require(amount > 0, "Can't mint zero");

        // Check proper amount sent
        require(msg.value == amount * dutchAuctionPrice(), "Send proper ETH amount");

        _mintWithoutValidation(msg.sender, amount, false);
    }

    function whitelistMint(uint amount, uint totalAllocation, bytes32 leaf, bytes32[] memory proof) external payable {
        // Create storage element tracking user mints if this is the first mint for them
        if (!whitelistUsed[msg.sender]) {        
            // Verify that (msg.sender, amount) correspond to Merkle leaf
            require(keccak256(abi.encodePacked(msg.sender, totalAllocation)) == leaf, "Sender and amount don't match Merkle leaf");

            // Verify that (leaf, proof) matches the Merkle root
            require(verify(merkleRoot, leaf, proof), "Not a valid leaf in the Merkle tree");

            whitelistUsed[msg.sender] = true;
            whitelistRemaining[msg.sender] = totalAllocation;
        }

        // Require nonzero amount
        require(amount > 0, "Can't mint zero");

        // Check proper amount sent
        require(msg.value == amount * presaleMintPrice, "Send proper ETH amount");

        require(whitelistRemaining[msg.sender] >= amount, "Can't mint more than remaining allocation");

        whitelistRemaining[msg.sender] -= amount;
        _mintWithoutValidation(msg.sender, amount, false);
    }

    function _mintWithoutValidation(address to, uint amount, bool skipMaxItems) internal {
        uint _totalSupply = totalSupply(); // Cache variable after reading from storage
        require(_totalSupply + amount <= maxItems, "mintWithoutValidation: Sold out");
        require(skipMaxItems || amount <= maxItemsPerTx, "mintWithoutValidation: Surpasses maxItemsPerTx");
        _safeMint(to, amount);
    }

    function verify(bytes32 root, bytes32 leaf, bytes32[] memory proof) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    // ADMIN FUNCTIONALITY

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function setPresaleMintPrice(uint _presaleMintPrice) external onlyOwner {
        presaleMintPrice = _presaleMintPrice;
    }

    function setDutchAuctionStart(uint _dutchAuctionStart) external onlyOwner {
        dutchAuctionStart = _dutchAuctionStart;
    }

    function setDutchAuctionEnd(uint _dutchAuctionEnd) external onlyOwner {
        dutchAuctionEnd = _dutchAuctionEnd;
    }

    function setDutchAuctionIncrement(uint _dutchAuctionIncrement) external onlyOwner {
        dutchAuctionIncrement = _dutchAuctionIncrement;
    }

    function setDutchAuctionStepTime(uint _dutchAuctionStepTime) external onlyOwner {
        dutchAuctionStepTime = _dutchAuctionStepTime;
    }

    function setMaxItems(uint _maxItems) external onlyOwner {
        maxItems = _maxItems;
    }

    function setMaxItemsPerTx(uint _maxItemsPerTx) external onlyOwner {
        maxItemsPerTx = _maxItemsPerTx;
    }

    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    function setStartTimestamp(uint _startTimestamp) external onlyOwner {
        startTimestamp = _startTimestamp;
    }

    function setBaseTokenURI(string memory __baseTokenURI) public onlyOwner {
        _baseTokenURI = __baseTokenURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // WITHDRAWAL FUNCTIONALITY

    /**
     * @dev Withdraw the contract balance to the recipient address
     */
    function withdraw() external {
        require(recipient != address(0x0), "Set recipient first");
        uint amount = address(this).balance;
        (bool success,) = recipient.call{value: amount}("");
        require(success, "Failed to send ether");
    }

    // METADATA FUNCTIONALITY

    /**
     * @dev Returns a URI for a given token ID's metadata
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

}

//𝔫𝔣𝔱𝔰 𝔴𝔦𝔱𝔥 𝔞𝔱𝔱𝔦𝔱𝔲𝔡𝔢