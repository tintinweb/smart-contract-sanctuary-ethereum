// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import './Ownable.sol';
import './ERC721A.sol';

contract RedTest is ERC721A, Ownable {

    uint256 MAX_MINT = 3;
    uint256 PROFIT = 10;
    uint256 public MAX_TOTAL = 1000;
    uint256 public price = 0.1 ether;
    uint256 public mintTime = 1647226820;

    bool public mintOpen;

    string baseTokenURI;

    address withdrawAddress;
    address stevenAddress = 0xAc4Ff7E04ce061826AAD93f826509D3d9E96682D;

    constructor() ERC721A("RedTest", "RTN")  {
        withdrawAddress = msg.sender;
        setBaseURI("https://badgameshow/");
    }

    function mint(uint256 num) public payable {
        uint256 supply = totalSupply();
        require(mintOpen, "no mint time");
        require(num <= MAX_MINT, "You can adopt a maximum of MAX_MINT Cats");
        require(supply + num <= MAX_TOTAL, "Exceeds maximum Cats supply");
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

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function withdrawAll() public onlyOwner {
        uint one = address(this).balance * (100 - PROFIT) / 100;
        uint two = address(this).balance * PROFIT / 100;
        require(payable(withdrawAddress).send(one));
        require(payable(stevenAddress).send(two));
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