pragma solidity 0.8.11;
// SPDX-License-Identifier: MIT
import "./ERC721A.sol";
import "./Ownable.sol";

contract IFgirl is ERC721A, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.01 ether;
    uint256 public maxSupply = 5000;
    bool public delayedReveal = false;
    string public notRevealedUri;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _notRevealedURI
    ) ERC721A(_name, _symbol, 10) {
        notRevealedUri = _notRevealedURI;
        setBaseURI(_initBaseURI);
    }

    function mint(uint256 quantity) external payable {
        uint256 supply = totalSupply();
        require(quantity > 0, "Quantity Must Be Higher Than Zero");
        require(supply + quantity <= maxSupply, "Max Supply Reached");

        _safeMint(msg.sender, quantity);
    }

    // internal
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

        if (_revealTime[tokenId] > block.timestamp && delayedReveal) {
            return
                bytes(notRevealedUri).length > 0
                    ? string(
                        abi.encodePacked(
                            notRevealedUri,
                            tokenId.toString(),
                            baseExtension
                        )
                    )
                    : "";
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }


    function setRevealPeriod(uint256 RevealPeriod) public onlyOwner {
        revealPeriod = RevealPeriod;
    }

    function setDelayedReveal(bool _delayedReveal) public onlyOwner {
        delayedReveal = _delayedReveal;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setnotRevealedURI(string memory _newBaseURI) public onlyOwner {
        notRevealedUri = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance should be more then zero");
        payable(address(msg.sender)).transfer(balance);
    }
    function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }
}