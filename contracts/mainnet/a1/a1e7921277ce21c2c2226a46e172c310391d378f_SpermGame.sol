// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./ERC721ABurnable.sol";

contract SpermGame is ERC721ABurnable, Ownable {
    using Strings for uint;
    using ECDSA for bytes32;

    string public constant PROVENANCE_HASH = "50AE2B106A55D253EBFBEF735551BF3E4FE3F78C9618204CF3BE677595B30768";

    uint public collectionSupply;
    uint public freeMintLimit = 10;
    uint public freeMintSupply = 2222;
    uint public mintPrice = 20000000000000000; // 0.02 ETH

    bool public isRevealed;
    bool public mintAllowed;

    uint[] public wrappedTokenIds;

    string private baseURI;
    string private wrappedBaseURI;

    address private operatorAddress;

    uint internal immutable MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    constructor(
        string memory initialURI,
        uint _MAX_TOKENS)
    ERC721A("Sperm Game", "SG") {
        collectionSupply = _MAX_TOKENS;
        isRevealed = false;
        mintAllowed = false;
        wrappedTokenIds = new uint[]((_MAX_TOKENS / 256) + 1);
        baseURI = initialURI;
        operatorAddress = msg.sender;
    }

    function mint(uint num) external payable ensureAvailabilityForMint(num) {
        require(mintAllowed, "Minting is not open yet");
        require(msg.value >= (num * mintPrice), "Insufficient payment amount");

        _safeMint(msg.sender, num);
    }

    function freeMint(uint num) external ensureAvailabilityForFreeMint(num) {
        require(mintAllowed, "Minting is not open yet");
        require((_numberMinted(msg.sender) + num) <= freeMintLimit, "Reached free mint limit for this wallet");

        _safeMint(msg.sender, num);
    }

    function wrapTokens(uint[] calldata tokenIds, bytes[] calldata signatures) external {
        require(tokenIds.length == signatures.length, "Must have one signature per tokenId");
        for (uint i = 0; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "Must be owner of the token to wrap it");
            verifyTokenInFallopianPool(tokenIds[i], signatures[i]);
            setWrapped(tokenIds[i]);
        }
    }

    function unwrapTokens(uint[] calldata tokenIds) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "Must be owner of the token to unwrap");
            unsetWrapped(tokenIds[i]);
        }
    }

    function isValidSignature(bytes32 hash, bytes calldata signature) internal view returns (bool isValid) {
        bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        return signedHash.recover(signature) == operatorAddress;
    }

    function verifyTokenInFallopianPool(uint tokenId, bytes calldata signature) internal view {
        bytes32 msgHash = keccak256(abi.encodePacked(tokenId));
        require(isValidSignature(msgHash, signature), "Invalid signature");
    }

    function tokenURI(uint tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (isRevealed && !isWrapped(tokenId)) {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        } else if (isRevealed && isWrapped(tokenId)) {
            return string(abi.encodePacked(wrappedBaseURI, tokenId.toString()));
        } else {
            return string(abi.encodePacked(baseURI));
        }
    }

    function setTokenURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setWrappedBaseTokenURI(string calldata _wrappedBaseURI) external onlyOwner {
        wrappedBaseURI = _wrappedBaseURI;
    }

    function setOperatorAddress(address _address) external onlyOwner {
        operatorAddress = _address;
    }

    function setCollectionSupply(uint _supply) external onlyOwner {
        require(_supply >= freeMintSupply, "Cannot set collection supply to be lower than free mint supply");
        collectionSupply = _supply;
    }

    function setFreeMintLimit(uint _limit) external onlyOwner {
        freeMintLimit = _limit;
    }

    function setFreeMintSupply(uint _supply) external onlyOwner {
        require(_supply <= collectionSupply, "Cannot set free mint supply to be higher than collection supply");
        freeMintSupply = _supply;
    }

    function setMintPrice(uint _price) external onlyOwner {
        mintPrice = _price;
    }

    function toggleMintingAllowed() external onlyOwner {
        mintAllowed = !mintAllowed;
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function burn(uint tokenId) public override onlyOwner {
        super.burn(tokenId);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function isWrapped(uint tokenId) public view returns (bool) {
        uint[] memory bitMapList = wrappedTokenIds;
        uint partitionIndex = tokenId / 256;
        uint partition = bitMapList[partitionIndex];
        if (partition == MAX_INT) {
            return true;
        }
        uint bitIndex = tokenId % 256;
        uint bit = partition & (1 << bitIndex);
        return (bit != 0);
    }

    function setWrapped(uint tokenId) internal {
        uint[] storage bitMapList = wrappedTokenIds;
        uint partitionIndex = tokenId / 256;
        uint partition = bitMapList[partitionIndex];
        uint bitIndex = tokenId % 256;
        bitMapList[partitionIndex] = partition | (1 << bitIndex);
    }

    function unsetWrapped(uint tokenId) internal {
        uint[] storage bitMapList = wrappedTokenIds;
        uint partitionIndex = tokenId / 256;
        uint partition = bitMapList[partitionIndex];
        uint bitIndex = tokenId % 256;
        bitMapList[partitionIndex] = partition & (0 << bitIndex);
    }

    function resetWrapped() external onlyOwner {
        wrappedTokenIds = new uint[]((collectionSupply / 256) + 1);
    }

    modifier ensureAvailabilityForMint(uint num) {
        require((totalSupply() + num) <= collectionSupply, "Insufficient tokens remaining in collection");
        _;
    }

    modifier ensureAvailabilityForFreeMint(uint num) {
        require((totalSupply() + num) <= freeMintSupply, "Insufficient free mints remaining in collection");
        _;
    }
}