// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol"; 

//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract BM is ERC721A, Ownable{
    using Strings for uint256;

    // 0 = pub, 1 = wl, 2 = vip
    uint256[3] public mintPrices = [0.1 ether, 0.08 ether, 0.05 ether];
    uint256[3] public maxMints = [1, 1, 1]; 

    //0 = wl, 1 = vip
    bytes32[2] public merkleRoots;

    uint256 public MAX_SUPPLY = 8887;

    string public baseURI = "ipfs://revealedURI/";
    string public unrevealedBaseURI = "ipfs://unrevealed.json";
    bool public isRevealed = false;

    bool public isPublicSale = false;
    bool public isWLSale = false;
    bool public isVIPSale = false;

    constructor() ERC721A("Blockchain Maidens", "BM"){}

    modifier onlyUser(){
        require(tx.origin == _msgSender(), "Not a user");
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

    function _baseURI() internal view virtual override returns(string memory){
        return baseURI;
    }

    function setBaseURI(string memory newURI) public onlyOwner{
        baseURI = newURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns(string memory){
        require(_exists(tokenId), "Non-existant token URI Query");
        uint256 trueId = tokenId + 1;

        if(!isRevealed){
            return unrevealedBaseURI;
        }

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, trueId.toString(), ".json")) : "";
    }


    //IMPORTANT!!!
    //each entered value is divided by 100, so to get
    //0.01 eth, you input 1
    //0.1 eth, you input 10
    //1 eth, you input 100
    function ChangePricing(uint256 pubMintPrice, uint256 wlMintPrice, uint256 vipMintPrice) external onlyOwner{
        mintPrices[0] = (pubMintPrice * (10**18) / 100);
        mintPrices[1] = (wlMintPrice * (10**18) / 100);
        mintPrices[2] = (vipMintPrice * (10**18) / 100);
    }

    function ChangeMaxMints(uint256 pubMaxMints, uint256 wlMaxMints, uint256 vipMaxMints) external onlyOwner{
        maxMints[0] = pubMaxMints;
        maxMints[1] = wlMaxMints;
        maxMints[2] = vipMaxMints;
    }

    function AddSupply(uint256 increaseSupply) external onlyOwner{
        MAX_SUPPLY += increaseSupply;
    }

    function SetRoots(bytes32 wlRoot, bytes32 vipRoot) external onlyOwner{
        merkleRoots[0] = wlRoot;
        merkleRoots[1] = vipRoot;
    }

    function Reveal(bool shouldReveal) external onlyOwner{
        isRevealed = shouldReveal;
    }

    function OpenPublicSale(bool shouldOpen) external onlyOwner{
        isPublicSale = shouldOpen;
    }

    function OpenWhitelistSale(bool shouldOpen) external onlyOwner{
        isWLSale = shouldOpen;
    }

    function OpenVIPSale(bool shouldOpen) external onlyOwner{
        isVIPSale = shouldOpen;
    }

    function withdraw() external onlyOwner{
        (bool payer1, ) = payable(owner()).call{value: address(this).balance}("");
        require(payer1, "Failed");
    }

    function PublicMint(uint256 amount) external payable{
        require(isPublicSale);
        require(_numberMinted(_msgSender()) + amount <= maxMints[0]);
        require(msg.value >= mintPrices[0]);
        require(totalSupply() + amount <= MAX_SUPPLY);
        _safeMint(_msgSender(), amount);
    }

    function WhiteListMint(uint256 amount, bytes32[] calldata proof) external isValidMerkleProof(proof, merkleRoots[0]) payable{
        require(isWLSale);
        require(_numberMinted(_msgSender()) + amount <= maxMints[1]);
        require(msg.value >= mintPrices[1]);
        require(totalSupply() + amount <= MAX_SUPPLY);
        _safeMint(_msgSender(), amount);
    }

    function VIPMint(uint256 amount, bytes32[] calldata proof) external isValidMerkleProof(proof, merkleRoots[1]) payable{
        require(isVIPSale);
        require(_numberMinted(_msgSender()) + amount <= maxMints[2]);
        require(msg.value >= mintPrices[2]);
        require(totalSupply() + amount <= MAX_SUPPLY);
        _safeMint(_msgSender(), amount);
    }
}