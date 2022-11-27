// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Counters.sol";
import "./DefaultOperatorFilterer.sol";

contract QC is ERC721, DefaultOperatorFilterer, Ownable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");

    using Counters for Counters.Counter;

    string public baseURI;
    uint256 public maxSupply;
    uint256 public publicMint;
    bool public publicMintEnabled;
    mapping (address => bool) private minters;
    uint256 public cost;

    Counters.Counter private tokenIdCounter;

    constructor() payable
        ERC721("Queen Chamade", "QUEENCHAMADE")
    {
        baseURI = "https://ipfs.io/ipfs/QmeHtLMpUHKSFg2K5QukqyGs1AcEuyGEjqr3BeiJ8MRD7p/";
        maxSupply = 800;
        publicMint = 800;
        cost = 0.002 ether;
        publicMintEnabled = false;
    }

     // Operator Registry Controls
    function updateOperator(address _operator, bool _filtered) public onlyOwner {
        OPERATOR_FILTER_REGISTRY.updateOperator(address(this), _operator, _filtered);
    }

    // F2O
    function mint(uint256 amount)
        external payable
    {
        require(tokenIdCounter.current() < maxSupply, "QueenChamade: exceeds max supply");
        require(balanceOf(_msgSender()) == 0, "QueenChamade: exceeds mint limit");
        require(minters[_msgSender()] == false, "QueenChamade: exceeds mint limit");
        require(publicMintEnabled == true, "QueenChamade: public mint not enabled");
        require(publicMint > 0, "QueenChamade: no public mint allocation");
        require(tx.origin == _msgSender(), "QueenChamade: invalid eoa");
        require(amount <= 10, "QueenChamade: exceeds mint limit");
        require(amount > 0, "QueenChamade: invalid eoa");
        require((publicMint - amount) > 0, "QueenChamade: exceeds mint limit");
        require(msg.value == (amount * cost), "QueenChamade: invalid price");
        minters[_msgSender()] = true;
        
        
        publicMint -= amount;
        
        for(uint i = 0; i < amount; i++) {
            uint256 tokenId = tokenIdCounter.current();
            tokenIdCounter.increment();
            _safeMint(_msgSender(), tokenId);
        }
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }


    function setPublicMintEnabled(bool enabled)
        public
        onlyOwner
    {
        publicMintEnabled = enabled;
    }

    function setBaseURI(string calldata baseURI_)
        public 
        onlyOwner
    {
        baseURI = baseURI_;
    }

    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return baseURI;
    }


    function withdrawETH() external onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

     // Registry Validated Transfers 
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}