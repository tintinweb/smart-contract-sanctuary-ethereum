// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract HermitCrabsNFT is ERC721, ERC721Enumerable, Ownable {
    string public PROVENANCE;
    string private _baseURIextended;
    mapping (address => uint) index;
    mapping (address => string) names;
    uint256 public constant MAX_SUPPLY = 262;
    uint256 public constant MAX_PUBLIC_MINT = 1;
    bool public REVEALED = false;
    
    //Base Extension
    string public constant baseExtension = ".json";
    ERC721 nft;
    // Array with address 
    address[] public nftAddresses;
    constructor() ERC721("HermitCrabs", "HC") {

    }

    function addAddress(address newAddress, string memory name) external onlyOwner() {
        nftAddresses.push(newAddress);
        index[newAddress] = nftAddresses.length - 1;
        names[newAddress] = name;
    }

    function setRevealed() external onlyOwner {
        REVEALED = true;
    }

    function remove(address newAddress) external onlyOwner {
        uint indexNumber = index[newAddress];
        if (indexNumber >= nftAddresses.length) return;

        for (uint i = indexNumber; i<nftAddresses.length-1; i++){
            nftAddresses[i] = nftAddresses[i+1];
            index[nftAddresses[i + 1]] = i;
        }
        nftAddresses.pop();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        for(uint i = 0; i < nftAddresses.length; i++) {
            nft = ERC721(nftAddresses[i]);
            require(nft.balanceOf(to) == 0, string(abi.encodePacked("Hermits don't want to be with ", names[nftAddresses[i]])));
        }
        require(balanceOf(to) == 0, "Hermits like to be alone");
        super._beforeTokenTransfer(from, to, tokenId);

    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function reserve(uint256 n) public onlyOwner {
      uint supply = totalSupply();
      uint i;
      for (i = 0; i < n; i++) {
          _safeMint(msg.sender, supply + i);
      }
    }

    function mint(uint numberOfTokens) public {
        uint256 ts = totalSupply();
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        ); 
        if (!REVEALED) return _baseURIextended;
        return
            string(
                abi.encodePacked(
                    _baseURIextended,
                    Strings.toString(_tokenId),
                    baseExtension
                )
            );
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}