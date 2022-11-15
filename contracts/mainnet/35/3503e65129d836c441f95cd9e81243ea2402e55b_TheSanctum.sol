// SPDX-License-Identifier: MIT

/* _____ _            ____                   _                   
|_   _| |__   ___  / ___|  __ _ _ __   ___| |_ _   _ _ __ ___  
  | | | '_ \ / _ \ \___ \ / _` | '_ \ / __| __| | | | '_ ` _ \ 
  | | | | | |  __/  ___) | (_| | | | | (__| |_| |_| | | | | | |
  |_| |_| |_|\___| |____/ \__,_|_| |_|\___|\__|\__,_|_| |_| |_|
*/


pragma solidity ^0.8.7;
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";
import "./Markle.sol";


contract TheSanctum is ERC721A, Ownable{
    using Strings for uint256;
   
    uint public tokenPrice = 0.25 ether;
    uint constant maxSupply = 10000;
    uint public presale_price = 0.25 ether;
    bool public raffle_status = false;
    bool public Presale_status = false;
    bool public public_sale_status = false;
    bool public isBurnEnabled=false;
    bytes32 public whitelistMerkleRoot;
    bytes32 public raffleMerkleRoot;
    bytes32 public backupraffleMerkleRoot;
    
    mapping(address => bool) private presaleList;
    string public baseURI;
    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalWhitelistMint;
    mapping(address => uint256) public totalraffleMint;
    mapping(uint256 => address) public burnedby;
    uint public maxPerTransaction = 5;  //Max Limit Per TX
    uint public maxPerWalletPresale = 2; //Max Limit for Presale
             
    constructor() ERC721A("The Sanctum", "Sanctum"){}


    function Public_mint(uint _count) public payable{
        require(public_sale_status == true, "Sale is Paused.");
        require(_count > 0, "mint at least one token");
        require(totalSupply() + _count <= maxSupply, "Sold Out!");
        require(msg.value >= tokenPrice * _count, "incorrect ether amount");
        require(_count <= maxPerTransaction, "max per transaction 5");
            totalPublicMint[msg.sender] += _count;
            _safeMint(msg.sender, _count);
   }

    function Whitelist_mint(uint _count, bytes32[] calldata merkleProof) external payable{ 
        require(Presale_status == true, "Sale is Paused.");
        require(MerkleProof.verify(merkleProof,whitelistMerkleRoot,keccak256(abi.encodePacked(msg.sender))),"You are not in Presale List.");
        require(_count <= 2, "max per transaction 2");
        require(totalSupply() + _count <= maxSupply, "Sold Out!");
        require(msg.value >= presale_price * _count, "incorrect ether amount");
        require((totalWhitelistMint[msg.sender] +_count) <= maxPerWalletPresale, "2 tokens per wallet allowed in presale");
      
            totalWhitelistMint[msg.sender] += _count;
            _safeMint(msg.sender, _count);
    }

     function Raffle_mint(uint _count, bytes32[] calldata merkleProof) external payable{ 
        require(raffle_status == true, "Sale is Paused.");
        require(MerkleProof.verify(merkleProof,raffleMerkleRoot,keccak256(abi.encodePacked(msg.sender))) || MerkleProof.verify(merkleProof,backupraffleMerkleRoot,keccak256(abi.encodePacked(msg.sender))),"You are not in raffle List.");
        require(_count <= maxPerTransaction, "max per transaction 5");
        require(totalSupply() + _count<= maxSupply, "Not enough tokens left");
        require(msg.value >= presale_price * _count, "incorrect ether amount");
        
      
            totalraffleMint[msg.sender] += _count;
            _safeMint(msg.sender, _count);
    }

      function Whitelist_checker(address walletAddress, bytes32[] calldata merkleProof) public view returns (bool){ 
        if(MerkleProof.verify(merkleProof,whitelistMerkleRoot,keccak256(abi.encodePacked(walletAddress))))
        {
            return true;
        }
        else
        {return false;}
      
    }
      function Raffle_checker(address walletAddress, bytes32[] calldata merkleProof) public view returns (bool){ 
        if(MerkleProof.verify(merkleProof,raffleMerkleRoot,keccak256(abi.encodePacked(walletAddress))) || MerkleProof.verify(merkleProof,backupraffleMerkleRoot,keccak256(abi.encodePacked(walletAddress))))
        {
            return true;
        }
        else
        {return false;}
      
    }

    function adminMint(uint _count) external onlyOwner{
        require(_count > 0, "mint at least one token");
        require(totalSupply() + _count <= maxSupply, "Sold Out!");
        _safeMint(msg.sender, _count);
    }

    function sendGifts(address[] memory _wallets) public onlyOwner{
        require(totalSupply() + _wallets.length <= maxSupply, "Sold Out!");
        for(uint i = 0; i < _wallets.length; i++)
            _safeMint(_wallets[i], 1);
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function setBaseUri(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }
    function Presale_Status(bool status) external onlyOwner {
        Presale_status = status;
    }
    function Raffle_status(bool status) external onlyOwner {
        raffle_status = status;
    }
    function Public_status(bool status) external onlyOwner {
        public_sale_status = status;
    }
     function update_burning_status(bool status) external onlyOwner {
        isBurnEnabled = status;
    }

    function SetWhitelist(bytes32 merkleRoot) external onlyOwner {
		whitelistMerkleRoot = merkleRoot;
	}
    function SetRaffle(bytes32 merkleRoot) external onlyOwner {
		raffleMerkleRoot = merkleRoot;
	}
      function SetbackupRaffle(bytes32 merkleRoot) external onlyOwner {
		backupraffleMerkleRoot = merkleRoot;
	}
    function burn(uint256 tokenId) external 
    {
        require(isBurnEnabled, "burning disabled");
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "burn caller is not approved"
        );
        _burn(tokenId);
        burnedby[tokenId] = msg.sender;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}