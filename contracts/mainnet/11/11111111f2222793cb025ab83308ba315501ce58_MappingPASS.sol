// SPDX-License-Identifier: Apache-2.0
pragma solidity =0.8.15;

import "./ERC721.sol";
import "./IERC721Metadata.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721Royalty.sol";
import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";

contract MappingPASS is ERC721Royalty, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct Mapping {
        address nft;
        uint256 tokenId;
        address owner;
    }

    uint16  constant  private CAP_TOTAL_SUPPLY = 4096;
    uint16  immutable private CAP_MINT_TEAM;
    uint16  immutable private CAP_MINT_WL;
    uint16  immutable private CAP_MINT_PARTNER;
    uint16            private _cap_mint_public;

    uint16            private _mintedWhitelist;
    uint16            private _mintedPartner;
    uint16            private _mintedTeam;
    uint16            private _mintedPublic;

    uint32            private _timestampWhitelistStart;
    uint32            private _timestampWhitelistEnd;
    uint32            private _timestampPublicStart;
    uint32            private _timestampPublicEnd;
    uint256           private _mintPricePublic;

    bytes32           private _merkleRootWhitelist;
    bytes32           private _merkleRootPartner;
    string            private _contractURI;

    mapping(uint256 => Mapping) private _mapping;
    mapping(address => bool)    private _claimed;
    mapping(address => bool)    private _claimedPartner;
    mapping(address => bool)    private _claimedPublic;
    mapping(uint256 => uint256) private _sinceBlock;
    mapping(uint256 => uint256) private _sinceTimestamp;

    event SetMapping(address indexed nft, uint256 tokenId, address indexed owner);

    constructor() ERC721("MappingPass", "MPP") {
        CAP_MINT_TEAM = CAP_TOTAL_SUPPLY / 16;
        CAP_MINT_WL = CAP_TOTAL_SUPPLY * 3 / 4;
        CAP_MINT_PARTNER = CAP_TOTAL_SUPPLY * 3 / 16;
    }

    function supportsInterface(bytes4 interfaceId_) public view override(ERC721Royalty, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId_);
    }

    function read(address account_) public view returns (
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256[16] memory integers,

        bool[3] memory claimed,
        bytes32[2] memory merkleRoot,
        address[2] memory creator,

        string memory contractMetadataURI
    ) {
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;

        integers[0]  = _allTokens.length;

        integers[1]  = _timestampWhitelistStart;
        integers[2]  = _timestampWhitelistEnd;
        integers[3]  = _timestampPublicStart;
        integers[4]  = _timestampPublicEnd;

        integers[5]  = _mintPricePublic;

        integers[6]  = CAP_TOTAL_SUPPLY;
        integers[7]  = CAP_MINT_WL;
        integers[8]  = CAP_MINT_TEAM;
        integers[9]  = CAP_MINT_PARTNER;
        integers[10] = _cap_mint_public;

        integers[11] = _mintedWhitelist;
        integers[12] = _mintedPartner;
        integers[13] = _mintedTeam;
        integers[14] = _mintedPublic;

        claimed[0] = _claimed[account_];
        claimed[1] = _claimedPartner[account_];
        claimed[2] = _claimedPublic[account_];

        merkleRoot[0] = _merkleRootWhitelist;
        merkleRoot[1] = _merkleRootPartner;

        creator[0] = _owner;
        creator[1] = _defaultRoyaltyInfo.receiver;

        integers[15] = _defaultRoyaltyInfo.royaltyFraction;

        contractMetadataURI = _contractURI;
    }

    function readERC721(address nft_) public view returns (string memory name, string memory symbol) {
        IERC721Metadata NFT = IERC721Metadata(nft_);
        name = NFT.name();
        symbol = NFT.symbol();
    }

    function getMapping(uint256 tokenId_) public view returns (address nft, uint256 tokenId, address owner) {
        Mapping memory m = _mapping[tokenId_];
        nft = m.nft;
        tokenId = m.tokenId;
        owner = m.owner;
    }

    function tokenURI(uint256 tokenId_) public view override(ERC721) returns (string memory) {
        Mapping memory m = _mapping[tokenId_];
        if (m.nft != address(0)) {
            IERC721Metadata NFT = IERC721Metadata(m.nft);
            if (m.owner == NFT.ownerOf(m.tokenId)) {
                return NFT.tokenURI(m.tokenId);
            }
        }

        return super.tokenURI(tokenId_);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function sinceOf(uint256 tokenId_) public view returns (uint256 blockNumber, uint256 timestamp) {
        blockNumber = _sinceBlock[tokenId_];
        timestamp = _sinceTimestamp[tokenId_];
    }

    function inWhitelist(address account_, bytes32[] calldata merkleProof_) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account_));
        return MerkleProof.verify(merkleProof_, _merkleRootWhitelist, leaf);
    }

    function inWhitelistPartner(address account_, uint8 amount_, bytes32[] calldata merkleProof_) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account_, amount_));
        return MerkleProof.verify(merkleProof_, _merkleRootPartner, leaf);
    }

    function whitelistMint(bytes32[] calldata merkleProof_) external payable {
        require(0 < _timestampWhitelistStart && _timestampWhitelistStart <= block.timestamp, "Whitelist mint is not started");
        if (0 < _timestampWhitelistEnd) {
            require(_timestampWhitelistEnd >= block.timestamp, "Whitelist mint is ended");
        }

        address account = _msgSender();
        require(!_claimed[account], "Already minted");
        require(_mintedWhitelist + 1 <= CAP_MINT_WL, "Minting exceeds the max supply");
        require(_allTokens.length + 1 <= CAP_TOTAL_SUPPLY, "Minting exceeds the max supply");
        require(inWhitelist(account, merkleProof_), "Not in whitelist");

        _mintedWhitelist += 1;
        _execMint(account, 1);
        _claimed[account] = true;
    }

    function publicMint() external payable {
        require(0 < _timestampPublicStart && _timestampPublicStart < block.timestamp, "Public mint is not started");
        if (0 < _timestampPublicEnd) {
            require(_timestampPublicEnd >= block.timestamp, "Public mint is ended");
        }
        require(msg.value >= _mintPricePublic, "Lower than mint price");

        address account = _msgSender();
        require(!_claimed[account], "Already minted");
        require(_mintedPublic + 1 <= _cap_mint_public, "Minting exceeds the max supply");
        require(_allTokens.length + 1 <= CAP_TOTAL_SUPPLY, "Minting exceeds the max supply");

        _mintedPublic += 1;
        _execMint(account, 1);
        _claimed[account] = true;
    }

    function partnerMint(uint8 amount_, bytes32[] calldata merkleProof_) external payable {
        address account = _msgSender();
        require(!_claimedPartner[account], "Already minted");
        require(_mintedPartner + amount_ <= CAP_MINT_PARTNER, "Minting exceeds the max supply");
        require(_allTokens.length + amount_ <= CAP_TOTAL_SUPPLY, "Minting exceeds the max supply");
        require(inWhitelistPartner(account, amount_, merkleProof_), "Not in partner whitelist");

        _mintedPartner += amount_;
        _execMint(account, amount_);
        _claimedPartner[account] = true;
    }

    function partnerMintTo(address[] calldata recipients_, uint8[] calldata amounts_) external onlyOwner {
        uint16 sum;
        for (uint256 i = 0; i < recipients_.length; i++) {
            sum += amounts_[i];
        }
        require(sum <= 30, "Mint exceeds 30");
        require(_mintedPartner + sum <= CAP_MINT_PARTNER, "Minting exceeds the max supply");
        require(_allTokens.length + sum <= CAP_TOTAL_SUPPLY, "Minting exceeds the max supply");

        _mintedPartner += sum;
        for (uint256 i = 0; i < recipients_.length; i++) {
            _execMint(recipients_[i], amounts_[i]);
        }
    }

    function teamMintTo(address[] calldata recipients_, uint8[] calldata amounts_) external onlyOwner {
        uint16 sum;
        for (uint256 i = 0; i < recipients_.length; i++) {
            sum += amounts_[i];
        }
        require(sum <= 30, "Mint exceeds 30");
        require(_mintedTeam + sum <= CAP_MINT_TEAM, "Minting exceeds the max supply");
        require(_allTokens.length + sum <= CAP_TOTAL_SUPPLY, "Minting exceeds the max supply");

        _mintedTeam += sum;
        for (uint256 i = 0; i < recipients_.length; i++) {
            _execMint(recipients_[i], amounts_[i]);
        }
    }

    function setMapping(uint256 tokenId_, address targetNFT_, uint256 targetTokenId_) external payable {
        require(targetNFT_ != address(this), "Mapping PASS: cannot dupl");
        address account = _msgSender();
        require(ownerOf(tokenId_) == account, "Mapping PASS: no permission");
        IERC721Metadata NFT = IERC721Metadata(targetNFT_);
        require(NFT.ownerOf(targetTokenId_) == account, "Target: no permission");

        emit SetMapping(targetNFT_, tokenId_, account);
        _mapping[tokenId_] = Mapping(targetNFT_, targetTokenId_, account);
    }

    function setWhitelistTimestamp(uint32 start_, uint32 end_) external onlyOwner {
        _timestampWhitelistStart = start_;
        _timestampWhitelistEnd = end_;
    }

    function setPublic(uint16 cap_, uint256 mintPrice_, uint32 start_, uint32 end_) external onlyOwner {
        _cap_mint_public = cap_;
        _mintPricePublic = mintPrice_;
        _timestampPublicStart = start_;
        _timestampPublicEnd = end_;
    }

    function setMerkleRootWhitelist(bytes32 merkleRoot_) external onlyOwner {
        _merkleRootWhitelist = merkleRoot_;
    }

    function setMerkleRootPartner(bytes32 merkleRoot_) external onlyOwner {
        _merkleRootPartner = merkleRoot_;
    }

    function setBaseURI(string memory uri_) external onlyOwner {
        _baseURI = uri_;
    }

    function setContractURI(string memory uri_) external onlyOwner {
        _contractURI = uri_;
    }

    function setDefaultRoyalty(address receiver_, uint16 feeNumerator_) external onlyOwner {
        _setDefaultRoyalty(receiver_, feeNumerator_);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    function _execMint(address recipient_, uint8 amount_) private {
        for (uint8 i = 0; i < amount_; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _safeMint(recipient_, newItemId);
        }
    }

    function _beforeTokenTransfer(address from_, address to_, uint256 tokenId_) internal override(ERC721, ERC721Enumerable) {
        _sinceBlock[tokenId_] = block.number;
        _sinceTimestamp[tokenId_] = block.timestamp;

        super._beforeTokenTransfer(from_, to_, tokenId_);
    }
}