//SPDX-License-Identifier: MIT

//  ██     ██ ███    ███  ██████   ██████  
//  ██     ██ ████  ████ ██    ██ ██    ██ 
//  ██  █  ██ ██ ████ ██ ██    ██ ██    ██ 
//  ██ ███ ██ ██  ██  ██ ██    ██ ██    ██ 
//   ███ ███  ██      ██  ██████   ██████  

pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721AQueryable.sol";
import "./DefaultOperatorFilterer.sol";

contract WMOO is
    ERC721A("WMOO", "WM"),
    ERC721AQueryable,
    Ownable,
    DefaultOperatorFilterer
{
    enum ContractStatus {
        PAUSED,
        WHITELIST_MINT,
        PUBLIC_MINT
    }

    // ------------------------------------------------------------------------
    // * Constants
    // ------------------------------------------------------------------------

    uint256 public constant MAX_SUPPLY = 9999;
    uint256 public constant MAX_WL_SUPPLY = 9000;

    // ------------------------------------------------------------------------
    // * Storage
    // ------------------------------------------------------------------------

    uint256 public price = 0.005 ether;
    uint256 public whitelistPrice = 0.003 ether;

    uint256 public maxFreePerWallet = 1;
    uint256 public maxPerWallet = 3;

    ContractStatus public contractStatus;
    bytes32 public merkleRoot;
    string public baseTokenURI;

    // ------------------------------------------------------------------------
    // * Modifiers
    // ------------------------------------------------------------------------

    modifier priceCompliance(uint256 quantity, bool isForWhitelist) {
        uint256 minted = _numberMinted(msg.sender);
        uint256 discount = quantity - 1;
        uint256 freeMintsLeft = maxFreePerWallet > minted ? maxFreePerWallet - minted : 0;
        uint256 paidCount = quantity > freeMintsLeft ? quantity - freeMintsLeft : 0;
        uint256 currentPrice = isForWhitelist ? whitelistPrice : price;
        uint256 totalCost = isForWhitelist ? paidCount * currentPrice : quantity == maxPerWallet ? discount * currentPrice : quantity * currentPrice;
        require(msg.value >= totalCost, "Insufficient funds");
        _;
    }

    modifier mintCompliance(uint256 quantity, bool isForWhitelist) {
        uint256 currentMaxSupply = isForWhitelist ? MAX_WL_SUPPLY : MAX_SUPPLY;
        require(tx.origin == msg.sender, "Invalid User");
        require(totalSupply() + quantity <= currentMaxSupply, "Exceeded max supply");
        require(
            _numberMinted(msg.sender) + quantity <= maxPerWallet,
            "Exceeded max per wallet"
        );
        _;
    }

    // ------------------------------------------------------------------------
    // * Frontend view helpers
    // ------------------------------------------------------------------------

    function getTotalMinted(address addr) external view returns (uint256) {
        return _numberMinted(addr);
    }

    // ------------------------------------------------------------------------
    // * Mint
    // ------------------------------------------------------------------------

    function mint(
        uint256 quantity
    ) external payable priceCompliance(quantity, false) mintCompliance(quantity, false) {
        require(
            contractStatus == ContractStatus.PUBLIC_MINT,
            "Contract is not open for public mint"
        );
        _mint(msg.sender, quantity);
    }

    function whitelistMint(
        uint256 quantity,
        bytes32[] memory proof
    ) external payable priceCompliance(quantity, true) mintCompliance(quantity, true) {
        require(
            contractStatus == ContractStatus.WHITELIST_MINT ||
                contractStatus == ContractStatus.PUBLIC_MINT,
            "Contract is not open for whitelist mint"
        );
        require(
            MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))),
            "Not in whitelist"
        );
        _mint(msg.sender, quantity);
    }

    // ------------------------------------------------------------------------
    // * Admin Functions
    // ------------------------------------------------------------------------

    function ownerMint(uint256 amount, address to) external onlyOwner {
        require(amount + totalSupply() <= MAX_SUPPLY, "Exceeded max supply");
        _safeMint(to, amount);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseTokenURI = uri;
    }

    function setStatus(ContractStatus status) external onlyOwner {
        contractStatus = status;
    }

    function setMerkleRoot(bytes32 newRoot) external onlyOwner {
        merkleRoot = newRoot;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{ value: address(this).balance }("");
        require(success, "Eth transfer failed");
    }

    // ------------------------------------------------------------------------
    // * Operator Filterer Overrides
    // ------------------------------------------------------------------------

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // ------------------------------------------------------------------------
    // * Internal Overrides
    // ------------------------------------------------------------------------

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}