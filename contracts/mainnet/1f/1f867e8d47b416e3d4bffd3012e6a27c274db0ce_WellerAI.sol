// Created by aashiriftikhar


pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";


contract WellerAI is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;
    uint256 public cost = 0.22 ether;
    uint256 public whiteListCost = 0.20 ether;
    uint256 public maxSupply = 999;
    uint256 public maxMintAmount = 5;
    uint256 public nftPerAddressLimit = 1;
    bool public paused = true;
    bool public revealed = true;

    bool public whiteListPaused = true;


    mapping(address => uint256) public addressMintedBalance;


    mapping(address => uint256) public whiteListMintedBalance;

    //// Merkle Tree Root Address  - Gas Optimisation
    bytes32 public whitelistMerkleRoot;



    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        require(!paused, "the public mint is paused");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(
            _mintAmount <= maxMintAmount,
            "max mint amount per session exceeded"
        );
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount, "insufficient funds");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, supply + i);
        }
    }


    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    function mintWhitelist(bytes32[] calldata merkleProof)
        public
        payable
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        isCorrectPayment(whiteListCost, 1)
    {
        require(!whiteListPaused, "WL sale is not allowed");
        uint256 supply = totalSupply();
        require(supply + 1 <= maxSupply, "max NFT limit exceeded");
        require(whiteListMintedBalance[msg.sender]<1,"No more mints are allowed.");
        whiteListMintedBalance[msg.sender]+=1;
        _safeMint(msg.sender, supply + 1);
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
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

        if (revealed == false) {
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

    //only owner
    function reveal() public onlyOwner {
        revealed = true;
    }


    function devMint(uint256 quantity) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply+quantity<=maxSupply,"Collection is Sold out");
        for (uint256 i = 1; i <= quantity; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, supply + i);
        }
    }

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function triggerWhiteList(bool state) public onlyOwner{
        whiteListPaused = state;
    }

    function setWhitelistCost(uint256 _newCost) public onlyOwner {
        whiteListCost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
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

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function publicPause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}