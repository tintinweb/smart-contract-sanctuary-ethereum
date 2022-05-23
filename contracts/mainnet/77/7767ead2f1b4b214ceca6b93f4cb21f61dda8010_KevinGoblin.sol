//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@##@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@*  %@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@  @@@@    *@@@@@@@@@@@@@@  @@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@   [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@# %@@@@@@@@@   @@ /@@@@@@@@@@  @@@@@@@@@@@@  @@@@@@@@@@@@@ /@  /@@  @@@@@ @@@@@   @@@@@@@@ @@@@@@@@@@@@@@@@@@@@./@*         [email protected]@@@@@@@@@@@@@
//@@@@@@@@@@* @@@@@@@@@@@@  @@ @@@@@@@@@@@@ (@%   &@@@@@@  @@@,@@@@@@@ #@@@@%   @@@@@@ #@@@@         @@  @@@@@@@@@@@@@@@@. @/ @@@@@@@@@@@@  @@@@@@@@@@@@
//@@@@@@@@@@ /@@@@@@@@@@@@@      @  @@@    # @@@@@@@@@. @@ (@@@ @@@@@  @@@@@@@  @@@@@@  @@ &@@@@@@@@@  @ @@@@@@@  @@@@@@@/ @  @@@@@@@@@@@@@  @@@@@@@@@@@
//@@@@@@@@@@  @@@@@@@@@@@@    @@@@@@@@@@@@@   @@@@@@@@@@ @/ @@@& @@@/ @@@@@@@@  @@@@@@@   [email protected]@@@@@@@@@@@ & @@@@@@  (@@@@@@  @  &@@@@@@@@@@@@@( @@@@@@@@@@
//@@@@@@@@@@@  [email protected]@@@@.  ,@@@   @@@@@@@@@@@@   @@@@@@@@@  @@ [email protected]@@  @@@ @@@@@@@@  @@@@@@@@ # @@@@@@@@@@@@@   @@@@@   @@@@@  @@@  @@@@@@@@@@@@@@  @@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@%  @@@@@@@@@@@@@  %    ,@@  @@@  @@@@ @@@@ &@@@@@  (@@@@@@@@/   @@@@@@@@@@@* @  @@@* @ @@@@. @@@@# @@@@@@@@@@@@@@@  @@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@  @ ,@@@@@@@@@@@@ *@@@@@ @@@@@@@@@@@@@@@@@@@@@@  @ %@@@@@@@  @@@@, @@ @@  @@  @@@@@@ @@@@@@@@@@@@@@@  @@@@@@@@
//@@@@@@@@@@ %@@@@@@@@@@@@@@ *@  @@@@@@@  &@@( @@@@@@@@@@@@ %@@@@@@@@@@@@@@@@@@@@@@@@@@@@* @@@@   @@@@@@@@@@@@@@@@# @  @@@@@@@ @@@@@@@@@@@@@@@  @@@@@@@@
//@@@@@@@@@@@@      [email protected]@@@@@  @@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@*   %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract KevinGoblin is ERC721A, Ownable {
    using Strings for uint256;

    string public baseURI;
    uint256 public price = 0.008 ether;
    uint256 public maxPerTx = 2;
    uint256 public maxSupply = 1500;
    uint256 public maxPerWallet = 50;
    uint256 public maxFreePerWallet = 2;
    uint256 public nextOwnerToExplicitlySet;
    bool public mintEnabled;
    mapping(address => uint256) private _mintedFreeAmount;

    constructor() ERC721A("Kevin Goblins", "KGB") {
        _safeMint(msg.sender, 20);
    }

    function mint(uint256 amt) external payable {
        uint256 cost = price;
        bool isFree = _mintedFreeAmount[msg.sender] + amt <= maxFreePerWallet;
        if (isFree) {
            cost = 0;
        }
        require(msg.sender == tx.origin, "...");
        require(msg.value >= amt * cost, "Please send the exact amount.");
        require(totalSupply() + amt < maxSupply + 1, "No more Kevin Goblins");
        require(mintEnabled, "Minting is not live yet, hold on Kevin Goblins.");
        require(amt < maxPerTx + 1, "Max per TX reached.");
        require(
            _numberMinted(msg.sender) + amt <= maxPerWallet,
            "Too many per wallet!"
        );

        if (isFree) {
            _mintedFreeAmount[msg.sender] += amt;
        }

        _safeMint(msg.sender, amt);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function flipSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}