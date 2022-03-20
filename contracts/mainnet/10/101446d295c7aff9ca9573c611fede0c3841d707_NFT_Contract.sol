pragma solidity 0.8.12;
// SPDX-License-Identifier: MIT
import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./RandomlyAssigned.sol";

contract NFT_Contract is ERC721, Ownable, RandomlyAssigned {
    using Strings for uint256;
    mapping(address => uint256) public whitelistClaimed;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public whitelistCost = 0.08 ether;
    uint256 public publicCost = 0.16 ether;
    uint256 public PresaleCost = 0.1 ether;
    uint256 Cost;
    bool public whitelistEnabled = false;

    string public UnrevealedURI;
    bool public revealed = false;
    bool public paused = true;
    bytes32 public merkleRoot;
    uint256 public maxWhitelist = 3;
    uint256 public maxPublic = 3;
    uint256 public maxSupply = 20401;

    uint256 whitelistTimstamp = 1647742200;
    uint256 publicSaleTimestamp = 1648785600;
    uint256 PresaleTimestamp = 1648699200;

    uint256 whitelistCap = 6401;
    uint256 presaleCap = 10401;
    uint256 publicCap = 20401;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _UnrevealedURI
    ) ERC721(_name, _symbol) RandomlyAssigned(maxSupply, 1) {
        setBaseURI(_initBaseURI);
        setUnrevealedUri(_UnrevealedURI);
    }

    function whitelistMint(uint256 quantity, bytes32[] calldata _merkleProof)
        public
        payable
        ensureAvailability
    {
        require(quantity > 0, "Quantity Must Be Higher Than Zero");
        require(whitelistEnabled, "The whitelist sale is not enabled!");
        require(tokenCount() <= whitelistCap , "Whitelist Amount Reached");
        require(
            whitelistClaimed[msg.sender] + quantity <= maxWhitelist,
            "You're not allowed to mint this Much!"
        );
        require(msg.value >= whitelistCost * quantity, "Insufficient Funds");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

        whitelistClaimed[msg.sender] += quantity;

        for (uint256 i = 1; i <= quantity; i++) {
            _safeMint(msg.sender, nextToken());
        }
    }

    function mint(uint256 quantity) external payable ensureAvailability {
        require(!paused, "The contract is paused!");
        require(quantity > 0, "Quantity Must Be Higher Than Zero");

        if (msg.sender != owner()) {
            require(
                quantity <= maxPublic,
                "You're Not Allowed To Mint more than maxMint Amount"
            );
            if(block.timestamp >= PresaleTimestamp && block.timestamp <= publicSaleTimestamp){
                Cost = PresaleCost;
                require(tokenCount() <= presaleCap , "Preslae Amount Reached");
            }else if(block.timestamp >= publicSaleTimestamp){
                Cost = publicCost;
                require(tokenCount() <= publicCap , "Public Amount Reached");
            }else{
                revert("");
            }

            require(msg.value >= Cost * quantity, "Insufficient Funds");
        }
        for (uint256 i = 1; i <= quantity; i++) {
            _safeMint(msg.sender, nextToken());
        }
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

    function setCost(uint256 _whitelistCost, uint256 _publicCost , uint256 _presaleCost)
        public
        onlyOwner
    {
        whitelistCost = _whitelistCost;
        publicCost = _publicCost;
        PresaleCost = _presaleCost;
    }

    function setTimestamp(uint256 _whitelist , uint256 _public , uint256 _presale) public onlyOwner {
        whitelistTimstamp = _whitelist;
        publicSaleTimestamp = _public;
        PresaleTimestamp = _presale;
    }

    function setCaps(uint256 _whitelist , uint256 _presale , uint256 _public) public onlyOwner {
        whitelistCap = _whitelist;
        presaleCap = _presale;
        publicCap = _public;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setUnrevealedUri(string memory _UnrevealedUri) public onlyOwner {
        UnrevealedURI = _UnrevealedUri;
    }

    function setMax(uint256 _whitelist, uint256 _public) public onlyOwner {
        maxWhitelist = _whitelist;
        maxPublic = _public;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWhitelistEnabled(bool _state) public onlyOwner {
        whitelistEnabled = _state;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
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

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}