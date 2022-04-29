/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Strings.sol";
import "./Shareholders.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";

contract NFTContract is ERC721A, Shareholders {
    using Strings for uint;
    uint private maxPerPresaleMint;
    uint private maxPerMint;
    uint private maxPerWallet;
    uint public cost;//amount in wei
    uint public maxSupply;

    bool revealed = false;
    bool public presaleOnly = false;

    bytes32 private merkleRoot = 0x53c4e5e25bcbb26b82784b9793d8a74a02719aabab34c2d0358b26231e2f4bbe;

  constructor(string memory name_, string memory symbol_, uint maxPerPresaleMint_, uint maxPerMint_, uint maxPerWallet_, uint maxSupply_, uint cost_, address newOwner_)
  ERC721A(name_, symbol_)payable{
      maxPerPresaleMint = maxPerPresaleMint_;
      maxPerMint = maxPerMint_;
      maxPerWallet = maxPerWallet_;
      maxSupply = maxSupply_;
      cost = cost_;
      transferOwnership(newOwner_);


  }

  function publicMint(uint256 quantity) external payable
    {
        require(presaleOnly == false);
        // overflow checks here
        require(_totalMinted() + quantity <= maxSupply, "Cannot exceed max supply");
        require(msg.value >= cost * quantity, "Amount of Ether sent too small");
        require(tx.origin == msg.sender, "No contracts!");
      
        _mint(msg.sender, quantity,"",true);
    }

    function preSaleMint(uint256 quantity, bytes32[] calldata proof) external payable
    {
        // overflow checks here
        require(_totalMinted() + quantity <= maxSupply, "Cannot exceed max supply");
        require(msg.value >= cost * quantity, "Amount of Ether sent too small");
        require(tx.origin == msg.sender, "No contracts!");

        // Prove to contract that sender was in snapshot
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid Merkle Tree proof supplied");

                _mint(msg.sender, quantity,"",true);
             
        
    }

}

contract ContractFactory {
    mapping(address => address) public userToContract;
  
  function Deploy(
      string memory name_,
      string memory symbol_,
      uint maxPerPresaleMint_,
      uint maxPerMint_,
      uint maxPerWallet_,
      uint maxSupply_,
      uint cost_
      ) public {
        address newOwner_ = msg.sender;
        address contractAddress = address(new NFTContract(name_, symbol_, maxPerPresaleMint_, maxPerMint_, maxPerWallet_, maxSupply_, cost_, newOwner_));
        userToContract[msg.sender] = contractAddress;
  }

}