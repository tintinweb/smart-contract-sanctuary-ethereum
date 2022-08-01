/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
/*

            ██   ██  █████  ███    ███ ██                      
            ██  ██  ██   ██ ████  ████ ██                      
            █████   ███████ ██ ████ ██ ██                      
            ██  ██  ██   ██ ██  ██  ██ ██                      
            ██   ██ ██   ██ ██      ██ ██ 

 ██▀███  ▓█████  ▄▄▄▄    ▒█████   ██▀███   ███▄    █ 
▓██ ▒ ██▒▓█   ▀ ▓█████▄ ▒██▒  ██▒▓██ ▒ ██▒ ██ ▀█   █ 
▓██ ░▄█ ▒▒███   ▒██▒ ▄██▒██░  ██▒▓██ ░▄█ ▒▓██  ▀█ ██▒
▒██▀▀█▄  ▒▓█  ▄ ▒██░█▀  ▒██   ██░▒██▀▀█▄  ▓██▒  ▐▌██▒
░██▓ ▒██▒░▒████▒░▓█  ▀█▓░ ████▓▒░░██▓ ▒██▒▒██░   ▓██░
░ ▒▓ ░▒▓░░░ ▒░ ░░▒▓███▀▒░ ▒░▒░▒░ ░ ▒▓ ░▒▓░░ ▒░   ▒ ▒ 
  ░▒ ░ ▒░ ░ ░  ░▒░▒   ░   ░ ▒ ▒░   ░▒ ░ ▒░░ ░░   ░ ▒░
  ░░   ░    ░    ░    ░ ░ ░ ░ ▒    ░░   ░    ░   ░ ░ 
   ░        ░  ░ ░          ░ ░     ░              ░ 
                      ░               

Developed by Co-Labs. www.co-labs.studio*/


import "./Strings.sol";
import "./Shareholders.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";

contract KamiReborn is ERC721A, Shareholders {
    IERC721A public genesisContract = ERC721A(0x14C82e83490fE667cdDA3C31b3b9DB090899f87d); 
    IERC721A public mainContract = ERC721A(0xA3332d74bBF2a4B93d2Cac74A5573e105aE268C4); 
    using Strings for uint;
    string public _baseTokenURI = "ipfs://QmWXQSA1dgKrjnypvhdYLNmmDbJUGDZc5fS31ZoMxH1DBX/"; 
    uint public maxPerWallet = 5; 
    uint public cost = 0.02 ether; 
    uint public maxSupply = 10000;
    uint public unclaimedGenesis = 2898;
    uint public unclaimedMain = 4101;
    bool public revealed = false;
    bool public presaleOnly = true;
    bool public claimActive = true;
    bytes32 public merkleRoot; 

    mapping(uint => bool) public claimedGenesis;
    mapping(uint => bool) public claimedMain;
    mapping(address => uint) public addressMintedBalance;

  constructor( 
      address payable[] memory newShareholders,
      uint256[] memory newShares
    ) ERC721A("Kami Reborn", "RBRN")payable{
        _mint(msg.sender, 100);
        changeShareholders(newShareholders, newShares);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function genesisClaim(uint[] memory _tokenIds) external payable {
      uint length = _tokenIds.length;
      require(claimActive == true, "Claim is no longer active.");
      for(uint i = 0; i < length; i++) {
          require(msg.sender == genesisContract.ownerOf(_tokenIds[i]), "You don't own one or more of the NFTs you are trying to claim with.");
          require(claimedGenesis[_tokenIds[i]] == false, "One or more of the NFTs you are trying to claim have already been claimed.");
          claimedGenesis[_tokenIds[i]] = true;
      }
      _mint(msg.sender, length);
      unclaimedGenesis -= length;
  }

  function mainClaim(uint[] memory _tokenIds) external payable {
      uint length = _tokenIds.length;
      require(claimActive == true, "Claim is no longer active.");
      for(uint i = 0; i < length; i++) {
          require(msg.sender == mainContract.ownerOf(_tokenIds[i]), "You don't own one or more of the NFTs you are trying to claim with.");
          require(claimedMain[_tokenIds[i]] == false, "One or more of the NFTs you are trying to claim have already been claimed.");
          claimedMain[_tokenIds[i]] = true;
      }
      _mint(msg.sender, length);
      unclaimedMain -= length;
  }

    modifier mintCompliance(uint256 quantity) {
        require(claimActive == false, "Claim for Genesis and Main holders only right now.");
        require(msg.value >= cost * quantity, "Insufficient Funds.");
        require(tx.origin == msg.sender, "No contracts!");
        require(addressMintedBalance[msg.sender] + quantity <= maxPerWallet, "You minted as many as you can already.");
        require((totalSupply() + quantity) <= (maxSupply), "Cannot exceed max supply");   
        _;
    }

  function publicMint(uint256 quantity) mintCompliance(quantity) external payable
    {
        require(presaleOnly == false);
        _mint(msg.sender, quantity);
        addressMintedBalance[msg.sender] += quantity;
    }

  function preSaleMint(uint256 quantity, bytes32[] calldata proof) mintCompliance(quantity) external payable
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid Merkle Tree proof supplied");
        _mint(msg.sender, quantity);
        addressMintedBalance[msg.sender] += quantity;
    }

  


    function _baseURI() internal view virtual override returns (string memory) 
    {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner 
    {
        _baseTokenURI = baseURI;
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

    function setClaimActive(bool _state) external onlyOwner 
    {
    claimActive = _state;
    }

    function setPresaleOnly(bool _state) external onlyOwner 
    {
    presaleOnly = _state;
    }

    function reveal(bool _state) external onlyOwner 
    {
    revealed = _state;
    }

}