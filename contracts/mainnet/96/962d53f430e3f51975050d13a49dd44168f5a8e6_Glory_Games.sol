pragma solidity 0.8.14;
// SPDX-License-Identifier: MIT
import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

interface ticket {
    function Cmint(
        address account,
        uint256 _id,
        uint256 _amount
    ) external;

    function balanceOf(address account, uint256 id) external returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

contract Glory_Games is ERC721A, Ownable {
    using Strings for uint256;
    mapping(address => uint256) public whitelistClaimed;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public whitelistCost = 0.07 ether;
    uint256 public publicCost = 0.07 ether;
    bool public whitelistEnabled = false;

    string public UnrevealedURI;
    bool public revealed = false;
    bool public paused = true;
    bytes32 public merkleRoot;
    uint256 public maxWhitelist = 10;
    uint256 public maxPublic = 10;
    uint256 public maxSupply = 5000;
    ticket ticketContract;
    address Contract;
    bool FreeMint = true; // with tickets

    constructor(
        address _ticket
    ) ERC721A("Glory Games Gen 0 Pet NFT", "#GLORYGEN0PET") {
        setBaseURI("ipfs://QmWTCZaX3vN74tuTXU2R9dXNJ5dwWo1pPFLAA32ThBX7sd/");
        setUnrevealedUri("ipfs://QmcaXNYvU8TyvCMRCUd6RS3kZ7Y8a9GNAcH111H2Th8cdN/");
        ticketContract = ticket(_ticket);
    }

    function whitelistMint(uint256 quantity, bytes32[] calldata _merkleProof)
        public
        payable
    {
        uint256 supply = totalSupply();
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
        uint256 supply = totalSupply();
        require(!paused, "The contract is paused!");
        require(quantity > 0, "Quantity Must Be Higher Than Zero");
        require(supply + quantity <= maxSupply, "Max Supply Reached");

        if (msg.sender != owner()) {
            require(
                quantity <= maxPublic,
                "You're Not Allowed To Mint more than maxMint Amount"
            );
            require(msg.value >= publicCost * quantity, "Insufficient Funds");
        }
        _safeMint(msg.sender, quantity);
    }

    modifier onlyAdmin() {
        require(Contract == _msgSender(), "Ownable: caller is not the Admin");
        _;
    }

    // for future use
    function avatar(
        address _from,
        uint256 _id,
        uint256 quantity
    ) external onlyAdmin {
        ticketContract.safeTransferFrom(_from, owner(), _id, quantity, "");
    }

    function freeMint(uint256 quantity, uint256 _id) public {
        require(FreeMint, "Free/Tickets Mint isn't enabled");
        uint256 supply = totalSupply();
        require(quantity != 0, "Quantity Must Be Higher Than Zero");
        require(supply + quantity <= maxSupply, "Max Supply Reached");
        require(
            ticketContract.balanceOf(msg.sender, _id) >= quantity,
            "you dont have enough tickets to mint this much"
        );
        ticketContract.safeTransferFrom(msg.sender, owner(), _id, quantity, "");
        if (_id == 2 || _id == 3) {
            // premium ticket
            ticketContract.Cmint(msg.sender, 4, quantity); // airdrop avatar ticket
        }
        _safeMint(msg.sender, quantity);
    }

    function setContracts(address _avatar, address _ticket) public onlyOwner {
        Contract = _avatar;
        ticketContract = ticket(_ticket);
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
            return bytes(UnrevealedURI).length > 0
                ? string(
                    abi.encodePacked(
                        UnrevealedURI,
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

    function setCost(uint256 _whitelistCost, uint256 _publicCost)
        public
        onlyOwner
    {
        whitelistCost = _whitelistCost;
        publicCost = _publicCost;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function setMintStatus(bool _state, bool _freemint) public onlyOwner {
        paused = _state;
        FreeMint = _freemint;
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