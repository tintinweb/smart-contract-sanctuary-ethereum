// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './Ownable.sol';
import './ERC721A.sol';

contract NFTTemplate is ERC721A, Ownable {

    uint256 public maxMint;
    uint256 public porfit;
    uint256 public maxTotal;
    uint256 public price;
    uint256 public mintTime;

    bool public mintOpen;
    string baseTokenURI;
    address public withdrawAddress;

    constructor(string memory name, string memory symbol, uint _maxMint, uint _porfit, uint _maxTotal, uint _price, uint _mintTime, string memory _baseTokenURI) ERC721A(name, symbol)  {
        maxMint = _maxMint;
        porfit = _porfit;
        maxTotal = _maxTotal;
        price = _price;
        mintTime = _mintTime;
        baseTokenURI = _baseTokenURI;

        withdrawAddress = tx.origin;
    }

    function mint(uint256 num) public payable {
        uint256 supply = totalSupply();
        require(mintOpen, "no mint time");
        require(num <= maxMint, "You can adopt a maximum of MAX_MINT Cats");
        require(supply + num <= maxTotal, "Exceeds maximum Cats supply");
        require(msg.value >= price * num, "Ether sent is not correct");
        require(block.timestamp >= mintTime, "no mint time");

        _safeMint(msg.sender, num);
    }

    function setWithdrawAddress(address _newAddress) public onlyOwner {
        withdrawAddress = _newAddress;
    }

    function setMintOpen() public onlyOwner {
        mintOpen = !mintOpen;
    }

    function setMintTime(uint256 _mintTime) public onlyOwner {
        mintTime = _mintTime;
    }

    function setPorfit(uint256 _porfit) public onlySteven {
        porfit = _porfit;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function withdrawAll() public onlyOwner {
        uint one = address(this).balance * (100 - porfit) / 100;
        uint two = address(this).balance * porfit / 100;
        require(payable(withdrawAddress).send(one));
        require(payable(steven()).send(two));
    }

    function walletOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}