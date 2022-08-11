//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721a.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract RPDFoundersPass is ERC721A, Ownable {

    using SafeMath for uint256;

    // Events
    event TokenMinted(address owner, uint256 quantity);

    // Max amount of token to purchase per account each time
    uint public MAX_PURCHASE = 1;

    // Max tokens supply
    uint256 public TOTAL_TOKENS = 1000;

    // Define if sale is active
    bool public saleIsActive = true;

    // Base URI
    string private baseURI;

    /**
     * Contract constructor
     */
    constructor(string memory name, string memory symbol, string memory uri) ERC721A(name, symbol) {
        setBaseURI(uri);
    }

    /*
     * Pause sale if active, make active if paused
     */
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    /*
     * Set max purchase
     */
    function setMaxPurchase(uint256 maxPurchase) public onlyOwner {
        MAX_PURCHASE = maxPurchase;
    }

    /**
     * Set Total Tokens Supply
     */
    function setTotalTokens(uint256 qty) public onlyOwner {
        TOTAL_TOKENS = qty;
    }

    /**
     * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
     */
    function setBaseURI(string memory BaseURI) onlyOwner public {
        baseURI = BaseURI;
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual override returns(string memory) {
        return baseURI;
    }

    /**
     * Withdraw
     */
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");

        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * Mint token for wallets.
     */
    function mintToWallets(address[] memory owners, uint256 qty) external onlyOwner {
        require(totalSupply().add(owners.length.mul(qty)) <= TOTAL_TOKENS, "Mint tokens to wallets would exceed max supply");
        
        for (uint i = 0; i < owners.length; i++) {
            _safeMint(owners[i], qty);
            emit TokenMinted(owners[i], qty);
        }
    }
    
    /**
     * Mint Tokens
     */
    function mint(uint qty) external {
        require(saleIsActive, "Mint is not available right now");
        require(qty > 0 && qty <= MAX_PURCHASE, "Can only mint 1 token at a time");
        require(totalSupply().add(qty) <= TOTAL_TOKENS, "Qty tokens would exceed max supply");
        uint balance = balanceOf(msg.sender);
        require(balance.add(qty) <= MAX_PURCHASE, "Limit exceed");

        _safeMint(msg.sender, qty);
        emit TokenMinted(msg.sender, qty);
    }

    /**
     * Get owner balance.
     */
    function getTokensOfOwner(address owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }

        return tokensId;
    }

    /**
     * Get owners list.
     */
    function getOwners(uint256 offset, uint256 limit) public view returns(address[] memory) {
        uint tokenCount = totalSupply();

        if (offset.add(limit) < tokenCount) {
            tokenCount = offset.add(limit);
        }

        address[] memory owners = new address[](tokenCount);
        for (uint i = offset; i < tokenCount; i++) {
            owners[i] = ownerOf(i);
        }

        return owners;
    }
}