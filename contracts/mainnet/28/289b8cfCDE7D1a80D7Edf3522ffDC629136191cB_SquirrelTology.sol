pragma solidity 0.8.15;
// SPDX-License-Identifier: MIT
import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract SquirrelTology is ERC721A, Ownable {
    mapping(address => uint256) public whitelistClaimed;
    string public baseURI;
    uint256 public whitelistCost = 0;
    uint256 public publicCost = 0.04 ether;
    bool public whitelistEnabled = true;
    bool public paused = false;
    bytes32 public merkleRoot;
    uint256 public maxWhitelist = 5;
    uint256 public maxPublic = 5;

    constructor() ERC721A("Squirreltology", "SQT") {
        setBaseURI("ipfs://QmZ7K3f21xfbobLtSzTt3sEPUhHV5o4qpgcKhmH3sJmcLZ/");
    }

    function whitelistMint(uint256 quantity, bytes32[] calldata _merkleProof)
        public
        payable
    {
        require(quantity > 0, "Quantity Must Be Higher Than Zero");
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
        require(!paused, "The contract is paused!");
        require(quantity > 0, "Quantity Must Be Higher Than Zero");

        if (msg.sender != owner()) {
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


    function setCost(uint256 _whitelistCost, uint256 _publicCost)
        public
        onlyOwner
    {
        whitelistCost = _whitelistCost;
        publicCost = _publicCost;
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

    function burn(uint256 tokenId) public {
        _burn(tokenId, true);
    }

    function withdraw() public onlyOwner {
        (bool ts, ) = payable(owner()).call{value: address(this).balance}("");
        require(ts);
    }
}