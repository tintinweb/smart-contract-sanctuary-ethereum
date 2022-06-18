pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract DiminishingBulls is Ownable, ERC721A {

    using MerkleProof for bytes32[];

    uint256 public _price = 0.0077 ether;

    bytes32 public _root;

    uint256 public constant MAX_SUPPLY = 2086;

    uint256 public constant FREE_MINT_SUPPLY = 666;

    string public baseTokenURI;

    bool  public _freeMintActive = false;

    bool  public _publicMintActive = false;

    mapping(address => bool) public _whitelistMinted;

    uint256 public _totalFreeMint;


    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    constructor(
    ) ERC721A("Diminishing bulls", "DBULLS") {

    }

    modifier contractCheck() {
        require(tx.origin == msg.sender, "beep boop");
        _;
    }

    modifier checkMaxSupply(uint256 _amount) {
        require(totalSupply() + _amount <= MAX_SUPPLY, "exceeds total supply");
        _;
    }

    modifier checkTxnValue(uint256 quantity) {
        require(msg.value == _price * quantity, "invalid transaction value");
        _;
    }

    modifier validateProof(bytes32[] calldata _proof) {
        require(
            MerkleProof.verify(
                _proof,
                _root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "wallet not allowed"
        );

        _;
    }

    function setRoot(bytes32 _newRoot) public onlyOwner {
        _root = _newRoot;
    }

    function setPublicMintActive(bool active) public onlyOwner {
        _publicMintActive = active;
    }

    function setFreeMintActive(bool active) public onlyOwner {
        _freeMintActive = active;
    }


    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner {
        (bool success,) = payable(msg.sender).call{value : address(this).balance}("");
        require(success);
    }

    function freeMint(bytes32[] calldata _proof, uint256 quantity)
    public
    contractCheck
    checkMaxSupply(quantity)
    validateProof(_proof)
    {
        require(_freeMintActive, "Free mint not started");
        require(quantity == 1, "Invalid quantity");
        require(_totalFreeMint + quantity <= FREE_MINT_SUPPLY, "exceeds free supply");
        require(_whitelistMinted[msg.sender] == false, "Wallet already claimed");
        _safeMint(msg.sender, 1);
        _totalFreeMint = _totalFreeMint + 1;
        _whitelistMinted[msg.sender] = true;
    }


    function mint(uint256 quantity)
    public
    payable
    contractCheck
    checkMaxSupply(quantity)
    checkTxnValue(quantity)
    {
        require(_publicMintActive, "Public mint not started");
        require(quantity <= 10, "Invalid quantity");
        _safeMint(msg.sender, quantity);
    }


}