// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./erc721AA.sol";

contract sac is ERC721A, Ownable{
    using Strings for uint256;

    uint public tokenPrice = 0.085 ether;
    uint constant maxSupply = 7000;
    uint public presale_price = 0.075 ether;
    bool public raffle_status = false;
    bool public Presale_status = false;
    bool public public_sale_status = false;
    bytes32 public whitelistMerkleRoot;
    bytes32 public RafflelistMerkleRoot;
    
    mapping(address => bool) private presaleList;
    string public baseURI;
    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalWhitelistMint;
    uint public maxPerTransaction = 2;  //Max Limit Per TX
    uint public maxPerWalletPresale = 2; //Max Limit for Presale
             
    constructor() ERC721A("sac", "sac"){}

    function buy(uint _count) public payable{
        require(public_sale_status == true, "Sale is Paused.");
        require(_count > 0, "mint at least one token");
        require(_count <= maxPerTransaction, "max per transaction 2");
        require(totalSupply() + _count <= maxSupply, "Not enough tokens left");
        require(msg.value >= tokenPrice * _count, "incorrect ether amount");

            totalPublicMint[msg.sender] += _count;
            _safeMint(msg.sender, _count);
   }

    function Whitelist_mint(uint _count, bytes32[] calldata merkleProof) external payable{ 
        require(Presale_status == true, "Sale is Paused.");
        require(MerkleProof.verify(merkleProof,whitelistMerkleRoot,keccak256(abi.encodePacked(msg.sender))),"You are not in Presale List.");
        require(_count <= maxPerTransaction, "max per transaction 2");
        require(totalSupply() + _count<= maxSupply, "Not enough tokens left");
        require(msg.value >= presale_price, "incorrect ether amount");
        require((totalWhitelistMint[msg.sender] +_count) <= maxPerWalletPresale, "2 tokens per wallet allowed in pre sale");
      
            totalWhitelistMint[msg.sender] += _count;
            _safeMint(msg.sender, _count);
    }

     function Raffle_mint(uint _count, bytes32[] calldata merkleProof) external payable{ 
        require(raffle_status == true, "Sale is Paused.");
        require(MerkleProof.verify(merkleProof,whitelistMerkleRoot,keccak256(abi.encodePacked(msg.sender))),"You are not in Presale List.");
        require(_count <= maxPerTransaction, "max per transaction 2");
        require(totalSupply() + _count<= maxSupply, "Not enough tokens left");
        require(msg.value >= presale_price, "incorrect ether amount");
        require((totalWhitelistMint[msg.sender] +_count) <= maxPerWalletPresale, "2 tokens per wallet allowed in pre sale");
      
            totalWhitelistMint[msg.sender] += _count;
            _safeMint(msg.sender, _count);
    }

    function adminMint(uint _count) external onlyOwner{
        require(_count > 0, "mint at least one token");
        require(totalSupply() + _count <= maxSupply, "Not enough tokens left");
        _safeMint(msg.sender, _count);
    }

    function sendGifts(address[] memory _wallets, uint _count) external onlyOwner{
        require(_wallets.length > 0, "mint at least one token");
        require(totalSupply() + _wallets.length <= maxSupply, "not enough tokens left");
        _safeMint(msg.sender, _count);
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    /// @dev walletOf() function shouldn't be called on-chain due to gas consumption
    function walletOf() external view returns(uint256[] memory){
        address _owner = msg.sender;
        uint256 numberOfOwnedNFT = balanceOf(_owner);
        uint256[] memory ownerIds = new uint256[](numberOfOwnedNFT);

        for(uint256 index = 0; index < numberOfOwnedNFT; index++){
            ownerIds[index] = tokenOfOwnerByIndex(_owner, index);
        }

        return ownerIds;
    }
    function is_presale_active() public view returns(uint){
        require(Presale_status == true,"Pre Sale not Started Yet.");
        return 1;
     }
      function is_sale_active() public view returns(uint){
      require(public_sale_status == true,"Public Sale not Started Yet.");
        return 1;
     }
     function checkPresale() public view returns(bool){
        return presaleList[msg.sender];
    }
    function setBaseUri(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }
     function pre_Sale_status(bool temp) external onlyOwner {
        Presale_status = temp;
    }
     function raffleStatus(bool temp) external onlyOwner {
        raffle_status = temp;
    }
    function publicSale_status(bool temp) external onlyOwner {
        public_sale_status = temp;
    }
     function update_public_price(uint price) external onlyOwner {
        tokenPrice = price;
    }
       function update_preSale_price(uint price) external onlyOwner {
        presale_price = price;
    }

    function setWhiteListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
		whitelistMerkleRoot = merkleRoot;
	}

    function withdraw() external onlyOwner {
         uint _balance = address(this).balance;
        payable(owner()).transfer(_balance * 190 / 1000);        //Project Wallet
        
    }
}