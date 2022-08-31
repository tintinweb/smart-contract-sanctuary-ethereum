/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Strings.sol";
import "./Shareholders.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./accessPassInterface.sol";


contract NFTContract is ERC721A, Shareholders {
    using Strings for uint;
    string public _baseTokenURI;
    uint public maxPerWallet;
    uint public cost;
    uint public maxSupply;
    bool public revealed;
    bool public presaleOnly;
    bool public paused = true;
    bytes32 public merkleRoot;
    mapping(address => uint) addressMintedBalance;
  constructor(
        string memory name_,
        string memory symbol_,
        string memory baseUri_,
        uint maxPerWallet_,
        uint maxSupply_,
        uint cost_,
        address newOwner_,
        bool presaleOnly_,
        bytes32 merkleRoot_
    ) ERC721A(name_, symbol_)payable{
        maxPerWallet = maxPerWallet_;
        maxSupply = maxSupply_;
        cost = cost_;
        presaleOnly = presaleOnly_;
        merkleRoot = merkleRoot_;
        _baseTokenURI = baseUri_;
        transferOwnership(newOwner_);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


    modifier mintCompliance(uint256 quantity) {
        require(paused == false, "Contract is paused.");
        require(addressMintedBalance[msg.sender] + quantity <= maxPerWallet, "You can't mint this many.");
        require(_totalMinted() + quantity <= maxSupply, "Cannot exceed max supply");
        require(msg.value >= cost * quantity, "Amount of Ether sent too small");
        require(tx.origin == msg.sender, "No contracts!");
        addressMintedBalance[msg.sender] += quantity;
        _;
    }

    function publicMint(uint256 quantity) mintCompliance(quantity) external payable
    {
        require(presaleOnly == false, "Presale Only");
        _mint(msg.sender, quantity);
    }

    function preSaleMint(uint256 quantity, bytes32[] calldata proof) mintCompliance(quantity) external payable
    {
        require(presaleOnly == true, "Presale has ended.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid Merkle Tree proof supplied");
        _mint(msg.sender, quantity);
    }

    function ownerMint(uint256 quantity) external payable onlyOwner
    {
        require(_totalMinted() + quantity <= maxSupply, "Cannot exceed max supply");
        _mint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) 
    {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner 
    {
        _baseTokenURI = baseURI;
    }

    function exists(uint256 tokenId) public view returns (bool) 
    {
        return _exists(tokenId);
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) 
    {
    string memory currentBaseURI = _baseURI();
    if(revealed == true) {
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
        : "";
    } else {
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI))
        : "";
    }
    
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner 
    {
    merkleRoot = _newMerkleRoot;
    }

    function setPresaleOnly(bool _state) external onlyOwner 
    {
    presaleOnly = _state;//set to false for main mint
    }

    function reveal(bool _state, string memory baseURI) external onlyOwner 
    {
    revealed = _state;
    _baseTokenURI = baseURI;
    }

    function pause(bool _state) external onlyOwner 
    {
    paused = _state;
    }

}

contract DevBot9000 is Ownable {
    uint public deployFee = 0.33 ether;
    accessPassInterface public labAccessPass;
    mapping(address => mapping(uint => address)) public userToContractByIndex;
    mapping(address => uint) public contractsDeployed;
  
    function Deploy(
        string memory name_, //need
        string memory symbol_, //need
        string memory baseUri_, //need
        uint maxPerWallet_,
        uint maxSupply_, //need
        uint cost_,
        bool presaleOnly_, //need
        bytes32 merkleRoot_ //need
        ) public payable {
            if (labAccessPass == accessPassInterface(0x0000000000000000000000000000000000000000)) {
                require(msg.value >= deployFee, "You need to pay to deploy this contract.");
            } else {
                 if (labAccessPass.balanceOfAll(msg.sender) < 1) {
                    require(msg.value >= deployFee, "You need to pay to deploy this contract.");
                }
            }
            address contractAddress = address(new NFTContract(name_, symbol_, baseUri_, maxPerWallet_, maxSupply_, cost_, msg.sender, presaleOnly_, merkleRoot_));
            contractsDeployed[msg.sender]++;
            userToContractByIndex[msg.sender][contractsDeployed[msg.sender]] = contractAddress;
    }

    function updateDetails(uint _newFee, address _accessPass) external onlyOwner {
        deployFee = _newFee;
        labAccessPass = accessPassInterface(_accessPass);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

}