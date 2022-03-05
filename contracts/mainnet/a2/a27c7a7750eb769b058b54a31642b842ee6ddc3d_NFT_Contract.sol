pragma solidity 0.8.11;
// SPDX-License-Identifier: MIT
import "./ERC721A.sol";
import "./Ownable.sol";
contract NFT_Contract is ERC721A, Ownable {
    using Strings for uint256;
    string public baseURI;
    string public UnrevealedURI;
    string public baseExtension = ".json";
    uint256 public PresaleCost = 0.1 ether;
    uint256 public PublicCost = 0.15 ether;
    uint256 private Cost;
    uint256 public maxMint = 10;
    uint256 public maxSupply = 5000;
    bool public PresaleStatus = true;
    bool public revealed = false;
    address private wallet1;
    address private wallet2;
    constructor(
        string memory _initBaseURI,
        string memory _UnrevealedURI,
        address _wallet1,
        address _wallet2
    ) ERC721A("Mad Giraffe Gang", "MGG") {
        setBaseURI(_initBaseURI);
        setUnrevealedUri(_UnrevealedURI);
        setWallets(_wallet1,_wallet2);
    }
    function mint(uint256 quantity) external payable {
        uint256 supply = totalSupply();
        require(quantity > 0, "Quantity Must Be Higher Than Zero");
        require(quantity <= maxMint , "You're Not Allowed To Mint more than maxMint Amount");
        require(supply + quantity <= maxSupply, "Max Supply Reached");
        if (msg.sender != owner() && PresaleStatus) {
            require(msg.value >= PresaleCost * quantity, "Insufficient Funds");
        }else if(msg.sender != owner() && !PresaleStatus){
            require(msg.value >= PublicCost * quantity, "Insufficient Funds");
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
        if (revealed == false) {
      return UnrevealedURI;
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
    function setCost(uint256 _Presale , uint256 _Public) public onlyOwner {
        PresaleCost = _Presale;
        PublicCost = _Public;
    }
    function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

    function SetPresaleStatus(bool _TrueOrFalse) public onlyOwner {
        PresaleStatus = _TrueOrFalse;
    }
    function setMaxMint(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    function setUnrevealedUri(string memory _UnrevealedUri) public onlyOwner {
    UnrevealedURI = _UnrevealedUri;
  }
    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }
    function setWallets(address _wallet1 , address _wallet2) public onlyOwner {
        wallet1 = _wallet1;
        wallet2 = _wallet2;
    }
    function withdraw() public onlyOwner {
        (bool ts, ) = payable(wallet1).call{value: address(this).balance / 2}("");
        require(ts);
        (bool os, ) = payable(wallet2).call{value: address(this).balance}("");
        require(os);
    }
}