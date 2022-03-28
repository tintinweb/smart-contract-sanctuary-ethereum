// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./MerkleProof.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

contract DG is ERC721A, Ownable {
    using Strings for uint256;

    // constants
    uint256 public constant PRE_SALE_PRICE = 0.001 ether;
    uint256 public constant PUBLIC_MINT_PRICE = 0.002 ether;
    uint256 public constant MINT_MAX_PER_TX = 10;
    uint256 public constant MAX_SUPPLY = 30;
    address private constant VAULT_ADDRESS =
        0x7A3e05F4dcdcaE0e9ed683516465e7a217583115;

    // global
    bool public saleActivated = false;
    bool public revealed = false;
    uint256 public saleRound = 0;
    uint256 public tierSupply = 5;
    string[] private _baseURIs;
    string private _notRevealedURI;
    string private baseExtension = ".json";

    // team claim
    uint256 public teamClaimStartTime;
    uint256 public teamClaimEndTime;
    bytes32 private _teamClaimMerkleRoot;

    // pre-sale
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    bytes32 private _preSaleMerkleRoot;

    // public mint
    uint256 public publicMintStartTime;
    uint256 public publicMintEndTime;

    constructor() ERC721A("DG", "DG", MINT_MAX_PER_TX, MAX_SUPPLY) {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "caller should not be a contract");
        _;
    }

    function teamClaim(bytes32[] memory proof, uint256 quantity)
        external
        payable
        callerIsUser
    {
        require(
            saleActivated &&
                block.timestamp >= teamClaimStartTime &&
                block.timestamp <= teamClaimEndTime,
            "not in team claim time"
        );
        require(
            _isWhitelisted(_teamClaimMerkleRoot, proof, msg.sender),
            "not in team claim whitelist"
        );
        require(
            quantity > 0,
            "quantity of tokens cannot be less than or equal to 0"
        );
        require(
            quantity <= MINT_MAX_PER_TX,
            "quantity of tokens cannot exceed max per mint"
        );
        require(
            totalSupply() + quantity <= tierSupply * (saleRound + 1),
            "the purchase would exceed tier supply of tokens"
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "the purchase would exceed max supply of tokens"
        );
        _safeMint(msg.sender, quantity);
    }

    function preSale(bytes32[] memory proof, uint256 quantity)
        external
        payable
        callerIsUser
    {
        require(
            saleActivated &&
                block.timestamp >= preSaleStartTime &&
                block.timestamp <= preSaleEndTime,
            "not in pre-sale time"
        );
        require(
            _isWhitelisted(_preSaleMerkleRoot, proof, msg.sender),
            "not in pre-sale whitelist"
        );
        require(
            quantity > 0,
            "quantity of tokens cannot be less than or equal to 0"
        );
        require(
            quantity <= MINT_MAX_PER_TX,
            "quantity of tokens cannot exceed max per mint"
        );
        require(
            totalSupply() + quantity <= tierSupply * (saleRound + 1),
            "the purchase would exceed tier supply of tokens"
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "the purchase would exceed max supply of tokens"
        );
        require(
            msg.value >= PRE_SALE_PRICE * quantity,
            "insufficient ether value"
        );
        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external payable callerIsUser {
        require(
            saleActivated &&
                block.timestamp >= publicMintStartTime &&
                block.timestamp <= publicMintEndTime,
            "not in mint time"
        );
        require(
            quantity > 0,
            "quantity of tokens cannot be less than or equal to 0"
        );
        require(
            quantity <= MINT_MAX_PER_TX,
            "quantity of tokens cannot exceed max per mint"
        );
        require(
            totalSupply() + quantity <= tierSupply * (saleRound + 1),
            "the purchase would exceed tier supply of tokens"
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "the purchase would exceed max supply of tokens"
        );
        require(
            msg.value >= PUBLIC_MINT_PRICE * quantity,
            "insufficient ether value"
        );
        _safeMint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenID)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenID),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false && (tokenID / tierSupply == saleRound)) {
            return _notRevealedURI;
        }

        string memory base = _baseURIs[tokenID / tierSupply];
        require(bytes(base).length > 0, "baseURI not set");
        return
            string(abi.encodePacked(base, tokenID.toString(), baseExtension));
    }

    /* ****************** */
    /* EXTERNAL FUNCTIONS */
    /* ****************** */

    function _isWhitelisted(
        bytes32 root,
        bytes32[] memory proof,
        address account
    ) public pure returns (bool) {
        return
            MerkleProof.verify(
                proof,
                root,
                keccak256(abi.encodePacked(address(account)))
            );
    }

    /* *************** */
    /* ADMIN FUNCTIONS */
    /* *************** */

    function setURIs(string[] memory baseURIs, string memory notRevealedURI)
        external
        onlyOwner
    {
        _baseURIs = baseURIs;
        _notRevealedURI = notRevealedURI;
    }

    function setBaseExtension(string memory extension) external onlyOwner {
        baseExtension = extension;
    }

    function setSaleRound(uint256 round) external onlyOwner {
        saleRound = round;
    }

    function setTierSupply(uint256 supply) external onlyOwner {
        tierSupply = supply;
    }

    function flipSaleActivated() external onlyOwner {
        saleActivated = !saleActivated;
    }

    function flipRevealed() external onlyOwner {
        revealed = !revealed;
    }

    function setTeamClaimTime(uint256 start, uint256 end) external onlyOwner {
        teamClaimStartTime = start;
        teamClaimEndTime = end;
    }

    function setTeamClaimMerkleRoot(bytes32 root) external onlyOwner {
        _teamClaimMerkleRoot = root;
    }

    function setPreSaleTime(uint256 start, uint256 end) external onlyOwner {
        preSaleStartTime = start;
        preSaleEndTime = end;
    }

    function setPreSaleMerkleRoot(bytes32 root) external onlyOwner {
        _preSaleMerkleRoot = root;
    }

    function setPublicMintTime(uint256 start, uint256 end) external onlyOwner {
        publicMintStartTime = start;
        publicMintEndTime = end;
    }

    function preserve(address to, uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "the purchase would exceed max supply of tokens"
        );
        _safeMint(to, quantity);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(VAULT_ADDRESS).transfer(balance);
    }
}