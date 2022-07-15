pragma solidity 0.8.15;
// SPDX-License-Identifier: MIT
import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract FivedInfinities is ERC721A, Ownable {
    mapping(address => uint256) public whitelistClaimed;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public whitelistCost = 0.25 ether;
    uint256 public whitelistCostStageTwo = 0.29 ether;
    uint256 public publicCost = 0.33 ether;
    bool public whitelistEnabled = true;
    bool public paused = true;
    bool public SaleEnded = false;
    bytes32 public merkleRoot;
    uint256 public maxWhitelist = 1;
    uint256 public maxPublic = 3;
    uint256 public maxSupply = 200;

    constructor() ERC721A("Fived Infinities - Infinity Badge", "FIIB") {
        setBaseURI(
            "https://bafybeifwmy5v7vflb75voe7ty3gcle3di3677irpwsgssncrbvqazicq5q.ipfs.nftstorage.link/"
        );
    }

    function whitelistMint(uint256 quantity, bytes32[] calldata _merkleProof)
        public
        payable
    {
        require(!SaleEnded, "Sale Ended");
        uint256 supply = _totalMinted();
        require(quantity > 0, "Quantity Must Be Higher Than Zero");
        require(supply + quantity <= maxSupply, "Max Supply Reached");
        require(whitelistEnabled, "The whitelist sale is not enabled!");
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
        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external payable {
        require(!SaleEnded, "Sale Ended");
        uint256 supply = _totalMinted();
        require(quantity > 0, "Quantity Must Be Higher Than Zero");
        require(supply + quantity <= maxSupply, "Max Supply Reached");

        if (msg.sender != owner()) {
            require(!paused, "The contract is paused!");
            require(
                quantity <= maxPublic,
                "You're Not Allowed To Mint more than maxMint Amount"
            );
            require(msg.value >= publicCost * quantity, "Insufficient Funds");
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
                        _toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }

    function setCost(
        uint256 _whitelistCost,
        uint256 _WhitelistStageTwo,
        uint256 _publicCost
    ) public onlyOwner {
        whitelistCost = _whitelistCost;
        whitelistCostStageTwo = _WhitelistStageTwo;
        publicCost = _publicCost;
    }

    function StartWhitelistStageTwo(bytes32 _merkleRoot) public onlyOwner {
        whitelistEnabled = true;
        maxWhitelist = 2;
        whitelistCost = whitelistCostStageTwo;
        merkleRoot = _merkleRoot;

    }

    function EndSale() public onlyOwner {
        SaleEnded = true;
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId, true);
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function setMax(uint256 _whitelist, uint256 _public) public onlyOwner {
        maxWhitelist = _whitelist;
        maxPublic = _public;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setStatus(bool _Whitelist, bool _PublicSale) public onlyOwner {
        whitelistEnabled = _Whitelist;
        paused = _PublicSale;
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
        (bool ts, ) = payable(owner()).call{value: address(this).balance}("");
        require(ts);
    }
}