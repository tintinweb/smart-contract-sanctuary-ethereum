// SPDX-License-Identifier: MIT

/**
   _____                .__           _____                            __                           .__
  /     \ _____    ____ |__| ____   _/ ____\___________  ____   ______/  |_    ____   ____     _____|  |   ____  ____ ______
 /  \ /  \\__  \  / ___\|  |/ ___\  \   __\/  _ \_  __ \/ __ \ /  ___|   __\  /    \ /  _ \   /  ___/  | _/ __ \/ __ \\____ \
/    Y    \/ __ \/ /_/  >  \  \___   |  | (  <_> )  | \|  ___/ \___ \ |  |   |   |  (  <_> )  \___ \|  |_\  ___|  ___/|  |_> >
\____|__  (____  |___  /|__|\___  >  |__|  \____/|__|   \___  >____  >|__|   |___|  /\____/  /____  >____/\___  >___  >   __/ /\
________\/     \/_____/.__.__   \/                          \/     \/             \/              \/          \/    \/|__|    \/
\______   \____ ______ |__|  |
 |     ___/  _ \\____ \|  |  |
 |    |  (  <_> )  |_> >  |  |__
 |____|   \____/|   __/|__|____/ /\
   _____       .|__|______       \/_____ ___.        .___
  /  _  \    __| _|_____  \       /  _  \\_ |__    __| _/
 /  /_\  \  / __ |  _(__  <      /  /_\  \| __ \  / __ |
/    |    \/ /_/ | /       \    /    |    \ \_\ \/ /_/ |
\____|__  /\____ |/______  / /\ \____|__  /___  /\____ |
.____   \/      \/       \/  \/         \/    \/     _\/            __  .__                                                               .___ ___.                  __
|    |    _______  __ ____    ___.__. ____  __ __  _/  |_  ____   _/  |_|  |__   ____     _____   ____   ____   ____   _____    ____    __| _/ \_ |__ _____    ____ |  | __
|    |   /  _ \  \/ // __ \  <   |  |/  _ \|  |  \ \   __\/  _ \  \   __\  |  \_/ __ \   /     \ /  _ \ /  _ \ /    \  \__  \  /    \  / __ |   | __ \\__  \ _/ ___\|  |/ /
|    |__(  <_> )   /\  ___/   \___  (  <_> )  |  /  |  | (  <_> )  |  | |   Y  \  ___/  |  Y Y  (  <_> |  <_> )   |  \  / __ \|   |  \/ /_/ |   | \_\ \/ __ \\  \___|    <
|_______ \____/ \_/  \___  >  / ____|\____/|____/   |__|  \____/   |__| |___|  /\___  > |__|_|  /\____/ \____/|___|  / (____  /___|  /\____ |   |___  (____  /\___  >__|_ \ /\
        \/               \/   \/                                             \/     \/        \/                   \/       \/     \/      \/       \/     \/     \/     \/ \/

 @powered by: amadeus-nft.io
*/

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./ERC721A.sol";


library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

contract MagicForestNoSleep is Ownable, ERC721A, ReentrancyGuard, VRFConsumerBaseV2 {
    // ChainLink Verifiable Random Number Module
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 subscriptionId = 250;
    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    bytes32 keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  1;
    uint256 public randomRevealOffset;
    uint256 public s_requestId;

    function requestRandomWords() internal {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        randomRevealOffset = randomWords[0] % collectionSize;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString((tokenId + randomRevealOffset) % collectionSize))) : '';
    }

    constructor(
    ) ERC721A("MagicForestNoSleep", "MFNS") VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    }

    uint256 public collectionSize = 5000;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // For marketing etc.
    function reserveMintBatch(uint256[] calldata quantities, address[] calldata tos) external onlyOwner {
        for (uint256 i = 0; i < quantities.length; i++) {
            require(
                totalSupply() + quantities[i] <= collectionSize,
                "Too many already minted before dev mint."
            );
            _safeMint(tos[i], quantities[i]);
        }
    }

    // metadata URI
    string private _baseTokenURI = "ipfs://QmQ118EEiEM8LTD3bQxwguTdQQcxHmgPi87rKxddAoFoBe/";

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function reveal(string calldata baseURI) external onlyOwner {
        requestRandomWords();
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        address amadeusAddress = address(0x718a7438297Ac14382F25802bb18422A4DadD31b);
        uint256 royaltyForAmadeus = address(this).balance / 100 * 5;
        uint256 remain = address(this).balance - royaltyForAmadeus;
        (bool success, ) = amadeusAddress.call{value: royaltyForAmadeus}("");
        require(success, "Transfer failed.");
        (success, ) = msg.sender.call{value: remain}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }

    // White List Mint
    bool public whiteListStatus = false;
    bytes32 private whiteListRoot;

    function setWhiteListRoot(bytes32 root) external onlyOwner {
        whiteListRoot = root;
    }

    function setWhiteListStatus(bool status) external onlyOwner {
        whiteListStatus = status;
    }

    function isInWhiteList(address addr, bytes32[] memory proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(proof, whiteListRoot, leaf);
    }

    function whiteListMint(bytes32[] memory proof) external {
        require(whiteListStatus, "White List Mint Not Start");
        require(totalSupply() + 1 <= collectionSize, "Reached Max Supply");
        require(isInWhiteList(msg.sender, proof), "Invalid Merkle Proof.");
        require(_numberMinted(msg.sender) == 0, "Each Address Can Only Mint One.");
        _safeMint(msg.sender, 1);
    }

    // Allow List Mint
    bytes32 private allowListRoot;

    function setAllowListRoot(bytes32 root) external onlyOwner{
        allowListRoot = root;
    }

    function isInAllowList(address addr, bytes32[] memory proof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(proof, allowListRoot, leaf);
    }

    function allowListMint(bytes32[] memory proof) external {
        require(whiteListStatus, "White List Mint Not Start");
        require(totalSupply() + 1 <= collectionSize, "Reached Max Supply");
        require(isInAllowList(msg.sender, proof), "Invalid Merkle Proof.");
        require(_numberMinted(msg.sender) == 0, "Each Address Can Only Mint One.");
        _safeMint(msg.sender, 1);
    }

    // Public Sale Mint
    uint256 public publicSaleStartTime = 0;

    function publicSaleMint() external payable callerIsUser {
        require(publicSaleStartTime != 0, "Public Sale Mint Not Start.");
        require(totalSupply() + 1 <= collectionSize, "Reached Max Supply");
        require(_numberMinted(msg.sender) == 0, "Each Address Can Only Mint One.");
        refundIfOver(getPublicSalePrice());
        _safeMint(msg.sender, 1);
    }

    function setPublicSaleStatus(bool status) external onlyOwner {
        if (status) {
            publicSaleStartTime = block.timestamp;
        } else {
            publicSaleStartTime = 0;
        }
    }

    function getPublicSalePrice() public view returns (uint256) {
        if (publicSaleStartTime == 0) {
            return 0;
        }
        if (block.timestamp >= (publicSaleStartTime + 2 days)) {
            return 0.05 ether;
        }
        return 0;
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }
}