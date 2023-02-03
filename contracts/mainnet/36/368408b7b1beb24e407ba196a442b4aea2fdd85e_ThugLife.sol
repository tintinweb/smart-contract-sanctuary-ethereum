// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC721AQueryable.sol';
import './Ownable.sol';
import './Strings.sol';
import './MerkleProof.sol';

contract ThugLife is  ERC721AQueryable,Ownable {
    using Strings for uint256;

    bytes32 public saleMerkleRoot;

    bool public active = true;
    bool public open = false;

    uint256 public mintTime = 1675436400;

    uint256 public waitMintTime = 3600 * 3;

    string baseURI; 
    string public baseExtension = ".json"; 

    string public NotRevealedUri = "https://cdn.thuglife.world/meta/848123b850a1439211fddcebae/json/";


    uint256 public constant MAX_SUPPLY = 3333; 
    uint256 public maxMintAmountPerTx = 5; 
    uint256 public whitelistPrice = 0.0085 ether; 

    uint256 public price = 0.0125 ether; 

    mapping(address => uint256) public _mintQuantity;
    mapping(uint256 => string) private _tokenURIs;

    address public OD = 0xb4d7F92D02477AE93c2f8a3285b1f5c02a59Fd4F;

    event CostLog(address indexed _from,uint256 indexed _amount, uint256 indexed _payment);

    constructor()
        ERC721A("Thuglife", "Thuglife")
    {
        setNotRevealedURI(NotRevealedUri);
    }                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (open == false) {
            return
            string(abi.encodePacked(NotRevealedUri, tokenId.toString(), baseExtension));
        }

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

       
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        
        return
            string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        NotRevealedUri = _notRevealedURI;
    }

    
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function flipOpen() public onlyOwner {
        open = !open;
    }

    function flipActive() public onlyOwner {
        active = !active;
    }

    function claim(uint256 _amount,bytes32[] calldata _merkleProof) external payable{
        require(active && block.timestamp >= mintTime, "Minting has not started");
        require(totalSupply() + _amount <= MAX_SUPPLY, "Exceeded maximum supply");
        require(_amount <= maxMintAmountPerTx, "xceeds max per transaction");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(!MerkleProof.verify(_merkleProof, saleMerkleRoot, leaf), "Invalid proof!");
        require(_amount * whitelistPrice <= msg.value,"Not enough ether sent");
      
        _mintQuantity[msg.sender] += _amount;
        require(_mintQuantity[msg.sender] <= maxMintAmountPerTx,"Exceeds max  mint");

        _safeMint(msg.sender, _amount);
        emit CostLog(msg.sender, _amount, msg.value);
    }

    function mint(uint256 _amount) external payable{
        require(active && block.timestamp >= mintTime + waitMintTime, "Minting has not started");
        require(totalSupply() + _amount <= MAX_SUPPLY, "Exceeded maximum supply");
        require(_amount <= maxMintAmountPerTx, "xceeds max per transaction");
        require(_amount * price <= msg.value,"Not enough ether sent");
     
        _mintQuantity[msg.sender] += _amount;
        require(_mintQuantity[msg.sender] <= maxMintAmountPerTx,"Exceeds max  mint");

        _safeMint(msg.sender, _amount);
        emit CostLog(msg.sender, _amount, msg.value);
    }

    function ownerMint(uint256 _amount) external onlyOwner{
        _safeMint(msg.sender, _amount);
    }

    function setSaleMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        saleMerkleRoot = merkleRoot;
    }

    function setPrice(uint256 _amount) public onlyOwner {
        price = _amount;
    } 
    
    function getTime() public view returns(uint256){
        return block.timestamp;
    }

    function setMintTime(uint256 _mintTime) public onlyOwner {
        mintTime = _mintTime;
    }

    function setwhitelistPrice(uint256 _amount) public onlyOwner {
        whitelistPrice = _amount;
    } 

    function setPerCostMint(uint256 _amount) public onlyOwner {
        maxMintAmountPerTx = _amount;
    }    

 
 
    function withdraw() public onlyOwner {
        (bool success, ) = payable(OD).call{value: address(this).balance}('');
        require(success);
    }

}