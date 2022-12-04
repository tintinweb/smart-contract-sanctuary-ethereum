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


contract TheSanctum_Neophytes is ERC721A, Ownable{
    using Strings for uint256;
   
    uint public tokenPrice = 0.01 ether;
    uint constant maxSupply = 10000;
    uint constant GenesismaxSupply = 2000;
    bool public Genesis_status = false;
    bool public Presale_status = false;
    bool public public_sale_status = false;
    bool public isBurnEnabled=false;
    bytes32 public whitelistMerkleRoot;
    bytes32 public GenesisMerkleRoot;
    
    mapping(address => bool) private presaleList;
    string public baseURI;
    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalWhitelistMint;
    mapping(address => uint256) public totalGenesisMint;
    mapping(uint256 => address) public burnedby;
    mapping(address => bool) public isclaimedbyaddress;
    mapping(uint => bool) public isclaimedbytoken;
    uint public maxPerTransaction = 5;  //Max Limit Per TX
    uint public maxPerWalletPresale = 2; //Max Limit for Presale
    uint public maxPerGenesis = 1;
             
    constructor() ERC721A("The Sanctum-Neophytes", "Neophytes"){}


    function Public_mint(uint _count) public payable{
        require(public_sale_status == true, "Sale is Paused.");
        require(_count > 0, "mint at least one token");
        require(totalSupply() + _count <= maxSupply, "Sold Out!");
        require(msg.value >= tokenPrice * _count, "incorrect ether amount");
        require(_count <= maxPerTransaction, "ONLY 5 NEOPHYTES ALLOWED PER TRANSACTION");
            totalPublicMint[msg.sender] += _count;
            _safeMint(msg.sender, _count);
   }

    function Whitelist_mint(uint _count,bytes32[] calldata merkleProof) external payable{ 
        uint genesis_token_id=Genesis_holders(msg.sender);
        require(Presale_status == true, "THE MAGIC MINT HAS NOT STARTED YET");
        require(MerkleProof.verify(merkleProof,whitelistMerkleRoot,keccak256(abi.encodePacked(msg.sender))),"YOUR WALLET IS NOT WHITELISTED");
        require(_count <= maxPerWalletPresale, "ONLY 2 NEOPHYTES ALLOWED PER TRANSACTION");
        require(totalSupply() + _count <= maxSupply, "Sold Out!");
         require((totalWhitelistMint[msg.sender] +_count) <= maxPerWalletPresale, "ONLY 2 NEOPHYTES ALLOWED PER WALLET");
        if(genesis_token_id==0)
        {
        require(msg.value >= tokenPrice * _count, "incorrect ether amount");
        _safeMint(msg.sender, _count);
        totalWhitelistMint[msg.sender] += _count;
        }
        else{
        require(msg.value >= (tokenPrice * _count)-(tokenPrice/10), "incorrect ether amount");
        _safeMint(msg.sender, _count);
        totalWhitelistMint[msg.sender] += _count;
        isclaimedbyaddress[msg.sender] = true;
        isclaimedbytoken[genesis_token_id] = true;

        }
    }

     function Genesis_mint(uint _count,bytes32[] calldata merkleProof) external{ 
        require(Genesis_status == true, "THE MAGIC MINT HAS NOT STARTED YET");
       require(MerkleProof.verify(merkleProof,GenesisMerkleRoot,keccak256(abi.encodePacked(msg.sender))),"YOUR WALLET IS NOT WHITELISTED");
        require(_count <= maxPerGenesis, "max per transaction 1");
        require(totalSupply() + _count<= GenesismaxSupply, "Genesis Collection Sold out");
         require((totalGenesisMint[msg.sender] +_count) <= maxPerGenesis, "ONLY 1 GENESIS NEOPHYTE ALLOWED PER WALLET");
      
            totalGenesisMint[msg.sender] += _count;
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
      function Genesis_checker(address walletAddress, bytes32[] calldata merkleProof) public view returns (bool){ 
        if(MerkleProof.verify(merkleProof,GenesisMerkleRoot,keccak256(abi.encodePacked(walletAddress))))
        {
            return true;
        }
        else
        {return false;}
      
    }
        function Genesis_holders(address walletAddress) public view returns (uint){ 
            uint value=0;
            uint maxlimit= GenesismaxSupply;
            if(totalSupply()<GenesismaxSupply){
               maxlimit=totalSupply();
            }
            for(uint i=1; i<=maxlimit; i++)
            {
              if(ownerOf(i)==walletAddress && !isclaimedbyaddress[walletAddress] && !isclaimedbytoken[i])
              {
                  value=i;
                  break;
              }
            }
        return value;
      
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
    function Genesis_status_update(bool status) external onlyOwner {
        Genesis_status = status;
    }
    function Public_status_update(bool status) external onlyOwner {
        public_sale_status = status;
    }
     function update_burning_status(bool status) external onlyOwner {
        isBurnEnabled = status;
    }

    function SetWhitelist(bytes32 merkleRoot) external onlyOwner {
		whitelistMerkleRoot = merkleRoot;
	}
    function SetGenesis(bytes32 merkleRoot) external onlyOwner {
		GenesisMerkleRoot = merkleRoot;
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
     function public_sale_price(uint pr) external onlyOwner {
        tokenPrice = pr;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}