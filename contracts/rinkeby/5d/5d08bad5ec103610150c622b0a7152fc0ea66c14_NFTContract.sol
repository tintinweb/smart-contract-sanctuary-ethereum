/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Strings.sol";
import "./Shareholders.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";

contract NFTContract is ERC721A, Shareholders {
    using Strings for uint;
    string public _baseTokenURI;
    uint public maxPerPresaleMint;
    uint public maxPerMint;
    uint public maxPerWallet;
    uint public cost;
    uint public presaleCost;
    uint public maxSupply;
    bool public revealed;
    bool public presaleOnly;
    bytes32 public merkleRoot;
    address payable[] startingShareholders;
    uint256[] startingShares;

  constructor(
        string memory name_,
        string memory symbol_,
        string memory baseUri_,
        uint maxPerPresaleMint_,
        uint maxPerMint_,
        uint maxSupply_,
        uint cost_,
        uint presaleCost_,
        address newOwner_,
        bool presaleOnly_,
        bytes32 merkleRoot_
    ) ERC721A(name_, symbol_)payable{
        maxPerPresaleMint = maxPerPresaleMint_;
        maxPerMint = maxPerMint_;
        maxSupply = maxSupply_;
        cost = cost_;
        presaleOnly = presaleOnly_;
        merkleRoot = merkleRoot_;
        presaleCost = presaleCost_;
        _baseTokenURI = baseUri_;
        transferOwnership(newOwner_);
    }

    function publicMint(uint256 quantity) external payable
    {
        require(presaleOnly == false);
        require(totalSupply() + quantity <= maxSupply, "Cannot exceed max supply");
        require(msg.value >= cost * quantity, "Amount of Ether sent too small");
        require(tx.origin == msg.sender, "No contracts!");
        _mint(msg.sender, quantity);
    }

    function preSaleMint(uint256 quantity, bytes32[] calldata proof) external payable
    {
        // overflow checks here
        require(totalSupply() + quantity <= maxSupply, "Cannot exceed max supply");
        require(msg.value >= presaleCost * quantity, "Amount of Ether sent too small");
        require(tx.origin == msg.sender, "No contracts!");

        // Prove to contract that sender was in snapshot
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid Merkle Tree proof supplied");

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
    function reveal(bool _state) external onlyOwner 
    {
    revealed = _state;
    }

}

contract DevBot9000 is Ownable {
    uint public deployFee = 0.33 ether;
    address public payee = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    IERC721A public labAccessPass;
    mapping(address => mapping(uint => address)) public userToContractByIndex;
    mapping(address => uint) public contractsDeployed;
  
    function Deploy(
        string memory name_,
        string memory symbol_,
        string memory baseUri_,
        uint maxPerPresaleMint_,
        uint maxPerMint_,
        uint maxSupply_,
        uint cost_,
        uint presaleCost_,
        bool presaleOnly_,
        bytes32 merkleRoot_
        ) public payable {
            if (labAccessPass == ERC721A(0x0000000000000000000000000000000000000000)) {
                require(msg.value >= deployFee, "You need to pay to deploy this contract.");
                address newOwner_ = msg.sender;
                address contractAddress = address(new NFTContract(name_, symbol_, baseUri_, maxPerPresaleMint_, maxPerMint_, maxSupply_, cost_, presaleCost_, newOwner_, presaleOnly_, merkleRoot_));
                contractsDeployed[msg.sender]++;
                userToContractByIndex[msg.sender][contractsDeployed[msg.sender]] = contractAddress;
            } else {
                 if (labAccessPass.balanceOf(msg.sender) < 1) {
                    require(msg.value >= deployFee, "You need to pay to deploy this contract.");
                }
                address newOwner_ = msg.sender;
                address contractAddress = address(new NFTContract(name_, symbol_, baseUri_, maxPerPresaleMint_, maxPerMint_, maxSupply_, cost_, presaleCost_, newOwner_, presaleOnly_, merkleRoot_));
                contractsDeployed[msg.sender]++;
                userToContractByIndex[msg.sender][contractsDeployed[msg.sender]] = contractAddress;
            }
            
        

    }

    function updateDeployFee(uint _newFee) external onlyOwner {
        deployFee = _newFee;
    }

    function setLabAccessPass(address _contractAddress) external onlyOwner {
        labAccessPass = ERC721A(_contractAddress);
    }

    function updatePayee(address _payeeAddress) external onlyOwner {
        payee = _payeeAddress;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payee.call{value: address(this).balance}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

}