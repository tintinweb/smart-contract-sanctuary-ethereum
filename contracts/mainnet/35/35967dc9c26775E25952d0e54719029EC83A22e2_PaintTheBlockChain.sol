// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";

contract PaintTheBlockChain is ERC721, Ownable {
    address public creator;
    uint256 public mintPrice = .05 ether;
    uint256 public canvasBlockSize = 100;
    uint256 public canvasSize = 1*10**6;
    uint256 public maxSupply = canvasSize/canvasBlockSize;
    string _baseURIString = "https://painttheblockchain.com/json/";

    constructor() ERC721("CanvasBlocks", "CVSB") {
        creator = owner();
    }
 
    function purchaseBlock(address to, uint256 tokenId) public payable {
        uint256 value = msg.value;
        require(value >= mintPrice, "youre poor...not enough funds");
        require(tokenId < maxSupply, "TokenId too big");
        _safeMint(to, tokenId);
    }

    function setMintPrice(uint256 newMintPrice) public onlyOwner {
        mintPrice = newMintPrice;
    }

    function changeCreator(address newCreator) public onlyOwner {
        creator = newCreator;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(creator).send(balance), "address not payable");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIString;
    } 

    function changeBaseURI(string calldata _newURI) public onlyOwner {
        _baseURIString = _newURI;
    }
















    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}