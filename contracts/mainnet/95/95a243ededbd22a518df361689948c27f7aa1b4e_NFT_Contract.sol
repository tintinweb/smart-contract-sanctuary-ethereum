pragma solidity 0.8.11;
// SPDX-License-Identifier: MIT
import "./ERC721A.sol";
import "./Ownable.sol";

contract NFT_Contract is ERC721A, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.035 ether;
    uint256 public maxMint = 20;
    uint256 public maxSupply = 3535;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    function mint(uint256 quantity) external payable {
        uint256 supply = totalSupply();
        require(quantity > 0, "Quantity Must Be Higher Than Zero");
        require(quantity <= maxMint , "You're Not Allowed To Mint more than maxMint Amount");
        require(supply + quantity <= maxSupply, "Max Supply Reached");

        if (msg.sender != owner()) {
            require(msg.value >= cost * quantity, "Insufficient Funds");
        }
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

    function setMaxMint(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
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
}