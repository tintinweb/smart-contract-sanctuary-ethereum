pragma solidity 0.8.17;
// SPDX-License-Identifier: MIT
import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract DUCKZILLAS is ERC721A, Ownable {
    mapping(address => uint256) public whitelistClaimed;
    mapping(address => uint256) public publicClaimed;
    mapping(address => uint256) public freeClaimed;


    string public baseURI;
    string public baseExtension = ".json";
    uint256 public whitelistCost = 0.00911 ether;
    uint256 public publicCost = 0.03 ether;
    uint256 public whitelistTimestamp = 1667325600; // 1-Nov 2:00 PM ETC
    uint256 public publicTimestamp = 1667336400;    // 1-Nov 5:00 PM ETC
    uint256 public freeTimestamp = 1667343600;      // 1-Nov 7:00 PM ETC
    bytes32 public merkleRoot;
    uint256 public maxWhitelist = 5;
    uint256 public maxPublic = 10;
    uint256 public maxFree = 1;
    uint256 public maxSupply = 8888;
    bool public freeMintEnabled = true;
    uint256 mintCap = 7777;

    constructor() ERC721A("DUCKZILLAS", "DUCKZILLA") {
        setBaseURI("ipfs://bafybeidrhx75skm3h2zsnxmzn4k5fbyivhtdf5nhbzht2djg6n23n4proi/");
        ownerMint(1);
    }

    function whitelistMint(uint256 quantity, bytes32[] calldata _merkleProof)
        public
        payable
    {
        uint256 supply = totalSupply();
        require(supply + quantity <= maxSupply, "Max Supply Reached");
        require(block.timestamp >= whitelistTimestamp && block.timestamp <= publicTimestamp, "Whitelist Sale Didn't Started Yet!");
        require(whitelistClaimed[msg.sender] + quantity <= maxWhitelist, "You're not allowed to mint this Much!");
        require(msg.value >= whitelistCost * quantity, "Insufficient Funds");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "You're Not Whitelisted!");
        whitelistClaimed[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external payable {
        uint256 supply = totalSupply();
        require(block.timestamp >= publicTimestamp && block.timestamp <= freeTimestamp, "Public Sale Didn't Started Yet!");
        require(supply <= mintCap, "Can't Mint, Please Try Again");
        require(supply + quantity <= maxSupply, "Max Supply Reached");
        require(publicClaimed[msg.sender] + quantity <= maxPublic, "You're not allowed to mint this Much!");
        require(quantity <= maxPublic, "You're Not Allowed To Mint more than maxMint Amount");
        require(msg.value >= publicCost * quantity, "Insufficient Funds");
        publicClaimed[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }
    function freeMint(uint256 quantity) public {
        uint256 supply = totalSupply();
        require(block.timestamp >= freeTimestamp && freeMintEnabled, "Sale Not Started!");
        require(supply + quantity <= maxSupply, "Max Supply Reached");
        require(freeClaimed[msg.sender] + quantity <= maxFree, "You're not allowed to mint this Much!");
        freeClaimed[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function ownerMint(uint256 quantity) public onlyOwner {
        uint256 supply = totalSupply();
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

    function setCost(uint256 _whitelistCost, uint256 _publicCost)
        public
        onlyOwner
    {
        whitelistCost = _whitelistCost;
        publicCost = _publicCost;
    }

    function setMax(uint256 _whitelist, uint256 _public ,uint256 _maxFree , uint256 _mintCap) public onlyOwner {
        maxWhitelist = _whitelist;
        maxPublic = _public;
        maxFree = _maxFree;
        mintCap = _mintCap;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setFreeMintStat(bool _freeMintEnabled) public onlyOwner {
        freeMintEnabled = _freeMintEnabled;
    }


    function setTime(uint256 _publicTimestamp,uint256 _freeTimestamp , uint256 _whitelistTimestamp) public onlyOwner {
        publicTimestamp = _publicTimestamp;
        freeTimestamp = _freeTimestamp;
        whitelistTimestamp = _whitelistTimestamp;
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