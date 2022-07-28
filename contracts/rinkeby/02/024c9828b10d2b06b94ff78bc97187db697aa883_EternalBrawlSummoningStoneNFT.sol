// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
contract EternalBrawlSummoningStoneNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string baseURI;
    string public baseExtension = ".json";
    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmount = 1;
    uint256 public timeDeployed;
    uint256 public allowMintingAfter = 0;
    bool public isPaused = false;
    bool public isRevealed = true;
    address public official;
    string public notRevealedUri;
    event Sale(address from, address to, uint256 value);

    struct Item {
        uint256 id;
        address creator;
        uint256 memberId;
        uint256 price;
        uint256 createTime;
    }
    mapping(uint256 => Item) public Items;
    constructor(
        uint256 _cost,
        uint256 _maxSupply,
        string memory _initBaseURI,
        address _official,
        string memory _initNotRevealedUri
    ) ERC721('NFT','NFT') {

        cost = _cost*(10 ** 16);
        maxSupply = _maxSupply;
        timeDeployed = block.timestamp;
        official = _official;
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintAmount,uint256 _memberId) public payable  {
        require(
            block.timestamp >= timeDeployed + allowMintingAfter,
            "Minting has not been allowed yet"
        );

//        require(balanceOf(msg.sender) <6, "Only 5 mint per account");

        uint256 supply = totalSupply();
        require(!isPaused);
        require(_mintAmount > 0);
//        require(_mintAmount <= maxMintAmount);
        require(supply + _mintAmount <= maxSupply);
                if (msg.sender != owner()) {
                    require(msg.value >= cost * _mintAmount);
                }
        _payRoyality(cost * _mintAmount);
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
            uint256 newItemId=supply + i;
            Items[newItemId] = Item({
                id: newItemId,
                creator: msg.sender,
                memberId:_memberId,
                price:cost,
                createTime:block.timestamp
                });
        }
    }

    function changMemberId(uint256 id,uint256 _memberId) public{
        require(Items[id].id == id, "Could not find NFT");
        require(msg.sender == ownerOf(id),"You're not the owner!");
        Items[id].creator=msg.sender;
        Items[id].memberId=_memberId;
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
        if (isRevealed == false) {
            return notRevealedUri;
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
    function _payRoyality(uint256 _royalityFee) internal {
        (bool success1, ) = payable(official).call{value: _royalityFee}("");
        require(success1);
    }

    // Only Owner Functions
    function setIsRevealed(bool _state) public onlyOwner {
        isRevealed = _state;
    }
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost*(10 ** 16);
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }
    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    function setOfficial(address  _newOfficial) public onlyOwner {
        official = _newOfficial;
    }
    function setIsPaused(bool _state) public onlyOwner {
        isPaused = _state;
    }
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
}