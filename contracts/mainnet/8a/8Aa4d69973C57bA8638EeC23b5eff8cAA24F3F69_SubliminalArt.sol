// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "ERC721.sol";
import {DefaultOperatorFilterer} from "DefaultOperatorFilterer.sol";
import {Ownable} from "Ownable.sol";
import "Strings.sol";
import "ERC2981.sol";

/**
 * @title  ExampleERC721
 * @notice This example contract is configured to use the DefaultOperatorFilterer, which automatically registers the
 *         token and subscribes it to OpenSea's curated filters.
 *         Adding the onlyAllowedOperator modifier to the transferFrom and both safeTransferFrom methods ensures that
 *         the msg.sender (operator) is allowed by the OperatorFilterRegistry. Adding the onlyAllowedOperatorApproval
 *         modifier to the approval methods ensures that owners do not approve operators that are not allowed.
 */
contract SubliminalArt is ERC721, DefaultOperatorFilterer, Ownable, ERC2981 {
    using Strings for uint256;

    string private baseURI;
    uint96 royaltyFeesInBips;
    address royaltyAddress;

    string public baseExtension = ".json";
    bool public paused = false;
    string public notRevealedUri;
    bool public revealed = true;

    uint256 MAX_SUPPLY = 1000;
    uint256 public publicSaleCost;
    uint256 public max_per_wallet = 1000;
    string public contractURI;  

    uint256 public price1 = 5 ether;
    uint256 public price2 = 15 ether;
    uint256 public price3 = 45 ether;
    uint256 public price4 = 75 ether;
   
    uint256 public totalSupply;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        string memory _contractURI
      //  uint96 _royaltyFeesInBips
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        contractURI = _contractURI;
        royaltyAddress = owner();
        setRoyaltyInfo(owner(),250);
    }

     function mint(uint256 tokenId) public payable  {

        require(totalSupply + 1 <= MAX_SUPPLY,"No More NFTs to Mint");
        require(!_exists(tokenId),"Token already minted");

        if (msg.sender != owner()) {

            require(!paused, "The contract is paused");
            uint256 nft_value = 0;          
           								
								if (tokenId >= 0 && tokenId < 250) {
									nft_value = price1;
								} else if (tokenId >= 250 && tokenId < 500) {
									nft_value = price2;
								} else if (tokenId >= 500 && tokenId < 750) {
									nft_value = price3;
								} else if (tokenId >= 750 && tokenId < 1000) {
									nft_value = price4;
                                }

            publicSaleCost = nft_value;
            require(msg.value >= (publicSaleCost * 1), "Not Enough ETH Sent");  
                    
        }

        totalSupply++;
        _safeMint(msg.sender, tokenId);
        
    }

    function getTokenStatus(uint256 tokenID) external view returns(bool) {
        return _exists(tokenID);        

    }

    function withdraw() public payable onlyOwner {
        (bool main, ) = payable(owner()).call{value: address(this).balance}("");
        require(main);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, tokenId.toString(), baseExtension)
                )
                : "";
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips)
        public
        onlyOwner
    {
        royaltyAddress = _receiver;
        royaltyFeesInBips = _royaltyFeesInBips;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function getBaseURI() external view onlyOwner returns (string memory) {
        return baseURI;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        virtual
        override
        returns (address, uint256)
    {
        return (royaltyAddress, calculateRoyalty(_salePrice));
    }


    function calculateRoyalty(uint256 _salePrice)
        public
        view
        returns (uint256)
    {
        return (_salePrice / 10000) * royaltyFeesInBips;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setPause(bool _state) external onlyOwner {
        paused = _state;
    }

    function setBaseExtension(string memory _newBaseExtension)
        external
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function toggleReveal() external onlyOwner {
        if (revealed == false) {
            revealed = true;
        } else {
            revealed = false;
        }
    }

    function setMAX_SUPPLY(uint256 _MAX_SUPPLY) external onlyOwner {
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function setMax_per_wallet(uint256 _max_per_wallet) external onlyOwner {
        max_per_wallet = _max_per_wallet;
    }

    function setPrice1(uint256 _price1) external onlyOwner {
        price1 = _price1;
    }

    function setPrice2(uint256 _price2) external onlyOwner {
        price2 = _price2;
    }

    function setPrice3(uint256 _price3) external onlyOwner {
        price3 = _price3;
    }

    function setPrice4(uint256 _price4) external onlyOwner {
        price4 = _price4;
    }

    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
    }
    
    function setContractURI(string calldata _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }
}