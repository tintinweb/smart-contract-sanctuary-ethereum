//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//imports
import "./ERC1155.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

//import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
//import '@openzeppelin/contracts/utils/Strings.sol';
//import "@openzeppelin/contracts/access/Ownable.sol";

contract RFYT is ERC1155, Ownable{
    using Strings for uint256;

    uint256 MAX_SUPPLY_ALPHA = 500;
    uint256 MAX_SUPPLY_OBSIDIAN = 250;
    uint256 MAX_MINTS_ALPHA = 2;
    uint256 MAX_MINTS_OBSIDIAN = 1;
    uint256 public mintRate_Alpha = 0.15 ether;
    uint256 public mintRate_Obsidian = 0.25 ether;

    bool public isPublicSale = false; 
    bool public isWhiteListSale = false;
    bool public paused = true;

    string public baseURI = "ipfs://QmUhLK6qyR6E8S3Q6QuDELoTbiVwkgtXytqpvcDi9E13zT/";  //change

    bytes32 public whitelistMerkleRoot;
    mapping(address => bool) public teamAddresses;


    constructor() ERC1155(""){}

    modifier callerIsUser(){
        require(tx.origin == _msgSender(), "Only users can interact with this contract!");
        _;
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

    function publicMintAlpha(uint256 quantity) external payable callerIsUser{
        require(isPublicSale);
        require(!paused);
        require(quantity + _numberMinted(_msgSender(), 0) <= MAX_MINTS_ALPHA, "Exceeded max mints");
        require(totalSupply[0] + quantity <= MAX_SUPPLY_ALPHA, "Not enough Tokens");
        require(msg.value >= (mintRate_Alpha * quantity), "Not enough ether sent");
        _mint(_msgSender(), 0, quantity, '');
    }

    function publicMintObsidian(uint256 quantity) external payable callerIsUser{
        require(isPublicSale);
        require(!paused);
        require(quantity + _numberMinted(_msgSender(), 1) <= MAX_MINTS_OBSIDIAN, "Exceeded max mints");
        require(totalSupply[1] + quantity <= MAX_SUPPLY_OBSIDIAN, "Not enough Tokens");
        require(msg.value >= (mintRate_Obsidian * quantity), "Not enough ether sent");
        _mint(_msgSender(), 1, quantity, '');
    }


    function whiteListMintAlpha(uint256 quantity, bytes32[] calldata merkleProof) external payable callerIsUser 
    isValidMerkleProof(merkleProof, whitelistMerkleRoot)
    {
        require(!paused);
        require(isWhiteListSale);
        require(quantity + _numberMinted(_msgSender(), 0) <= MAX_MINTS_ALPHA, "Exceeded max mints");
        require(totalSupply[0] + quantity <= MAX_SUPPLY_ALPHA, "Not enough Tokens");
        require(msg.value >= (mintRate_Alpha * quantity), "Not enough ether sent");
        _mint(_msgSender(), 0, quantity, '');
    }

    function whiteListMintObsidian(uint256 quantity, bytes32[] calldata merkleProof) external payable callerIsUser 
    isValidMerkleProof(merkleProof, whitelistMerkleRoot)
    {
        require(!paused);
        require(isWhiteListSale);
        require(quantity + _numberMinted(_msgSender(), 1) <= MAX_MINTS_OBSIDIAN, "Exceeded max mints");
        require(totalSupply[0] + quantity <= MAX_SUPPLY_OBSIDIAN, "Not enough Tokens");
        require(msg.value >= (mintRate_Obsidian * quantity), "Not enough ether sent");
        _mint(_msgSender(), 1, quantity, '');
    }

    function withdraw() public onlyOwner{
        address address1;
        address address2;
        address address3;
        address address4;

        (bool payer1, ) = payable(address1).call{value: address(this).balance * 5 / 200}("");
        (bool payer2, ) = payable(address2).call{value: address(this).balance * 6 / 195}("");
        (bool payer3, ) = payable(address3).call{value: address(this).balance * 2 / 189}("");
        (bool payer4, ) = payable(address4).call{value: (address(this).balance * 15) / 187}("");
        (bool payer5, ) = payable(owner()).call{value: (address(this).balance)}("");
        require(payer1 && payer2 && payer3 && payer4 && payer5, "Nope");
    }

    function uri(uint256) public view virtual override returns(string memory){
        return baseURI;
    }

    function setBaseURI(string memory newURI) public onlyOwner{
        baseURI = newURI;
    }

    function tokenURI(uint256 tokenId) public view returns(string memory){
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }
    
    function pause(bool shouldPause) public onlyOwner{
        paused = shouldPause;
    }

    function setPublicSale(bool shouldStartPublicSale) public onlyOwner{
        isPublicSale = shouldStartPublicSale;
    }

    function setWhiteListSale(bool shouldStartWhiteListSale) public onlyOwner{
        isWhiteListSale = shouldStartWhiteListSale;
    }

    function burnToken(address from, uint256 id, uint256 amount) public onlyOwner{ // id is 0 for alpha, 1 for obsidian
        _burn(from, id, amount);
    }
}