pragma solidity 0.8.11;
// SPDX-License-Identifier: MIT
import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract NFT_Contract is ERC721A, Ownable {
    using Strings for uint256;
    mapping(address => uint256) public whitelistClaimed;

    string public baseURI;
    uint256 public whitelistCost = 0.28 ether;
    uint256 public publicCost = 0.38 ether;
    bool public whitelistEnabled = false;
    bool public paused = true;
    bytes32 public merkleRoot;
    uint256 public maxWhitelist = 3;
    uint256 public maxPublic = 10;
    uint256 public maxSupply = 888;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    function whitelistMint(uint256 quantity, bytes32[] calldata _merkleProof) public payable {
    uint256 supply = totalSupply();
    require(quantity > 0, "Quantity Must Be Higher Than Zero");
    require(supply + quantity <= maxSupply, "Max Supply Reached");
    require(whitelistEnabled, "The whitelist sale is not enabled!");
    require(whitelistClaimed[msg.sender] + quantity <= maxWhitelist, "You're not allowed to mint this Much!");
    require(msg.value >= whitelistCost * quantity, "Insufficient Funds");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");

    whitelistClaimed[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
  }

    function mint(uint256 quantity) external payable {
        uint256 supply = totalSupply();
        require(!paused, "The contract is paused!");
        require(quantity > 0, "Quantity Must Be Higher Than Zero");
        require(supply + quantity <= maxSupply, "Max Supply Reached");

        if (msg.sender != owner()) {
            require(balanceOf(msg.sender) <= maxPublic , "You're Not Allowed To Mint that much!");
            require(msg.value >= publicCost * quantity, "Insufficient Funds");
        }
        _safeMint(msg.sender, quantity);
    }

    function Giveaway(uint256 quantity, address _receiver) public onlyOwner {
        uint256 supply = totalSupply();
        require(quantity > 0, "Quantity Must Be Higher Than Zero");
        require(supply + quantity <= maxSupply, "Max Supply Reached");
        _safeMint(_receiver, quantity);
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
        
        return _baseURI();
            
    }

    function setCost(uint256 _whitelistCost , uint256 _publicCost) public onlyOwner {
        whitelistCost = _whitelistCost;
        publicCost = _publicCost;
    }

    function setMax(uint256 _whitelist , uint256 _public) public onlyOwner {
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

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance should be more then zero");
        payable(address(msg.sender)).transfer(balance);
    }
}