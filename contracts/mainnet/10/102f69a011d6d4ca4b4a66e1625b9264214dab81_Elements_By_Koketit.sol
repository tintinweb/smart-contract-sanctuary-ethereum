// SPDX-License-Identifier: MIT
// @author: Exotic Technology LTD




pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IPaperKeyManager.sol";
import "./ownable.sol";
import "./ERC721enumerable.sol";
import "./merkle.sol";





contract Elements_By_Koketit is Ownable, ERC721, ERC721Enumerable {
    
    IPaperKeyManager paperKeyManager;
    
    bool public saleIsActive = false;

    bool public claim = false;

    uint256 public  MAX_TOKEN = 800;
    
    
    uint256  public royalty = 90;

    uint256 MAX_PUBLIC_MINT = 10;


    uint256 public salePrice = 0.15 ether;

    uint256 public preSalePrice = 0.1 ether;



    uint256 public SALE_START = 0;


    string private _baseURIextended;

    string public PROVENANCE;

    bytes32 public merkleRoot = 0x1b37dbe7f06ec1a780263e873304a99bd9264f9abf8598dc87a87e2c79e490ad;

    
    mapping(address => bool) private senders;
   

    
    constructor(address _paperKeyManagerAddress) ERC721("EBK", "EBK") {
       

        _baseURIextended = "ipfs://QmXZdTv4Q4q2QwRBi3W9aY4MF55BkFz1CjURGHCDLQDVbs/"; //cover

        senders[msg.sender] = true; // add owner

        paperKeyManager = IPaperKeyManager(_paperKeyManagerAddress);


    }

        // onlyPaper modifier 
    modifier onlyPaper(bytes32 _hash, bytes32 _nonce, bytes calldata _signature) {
        bool success = paperKeyManager.verify(_hash, _nonce, _signature);
        require(success, "Failed to verify signature");
        _;
    }


    function registerPaperKey(address _paperKey) external  {
        require(senders[_msgSender()]);

        require(paperKeyManager.register(_paperKey), "Error registering key");
    }



  

   function updateMerkle(bytes32 _merkle) public   {
        require(senders[_msgSender()]); 
       merkleRoot = _merkle;
       
    }


   function addSender(address _address) public onlyOwner  {
        
        require(_address != address(0));
        senders[_address] = true;
       
    }
    
    function removeSender(address _address) public onlyOwner {
        require(_address != address(0));
        senders[_address] = false;
        
    }

    function updateSaleStart(uint _start) public {
        require(senders[_msgSender()]);
        require(_start > 0,"zero");
        SALE_START = _start;
    }

    function updateMaxToken(uint _max) public {
        require(senders[_msgSender()]);

        require(_max > 0,"zero");
        uint256 ts = totalSupply();
        require(_max >= ts,"below supply");
        MAX_TOKEN = _max;
    }


    function updateSalePrice(uint _price) public {
        require(senders[_msgSender()]);

        salePrice = _price;
    }

    function updatePreSalePrice(uint _price) public {
        require(senders[_msgSender()]);

        preSalePrice = _price;
    }
    

    function updateMaxPublicMint(uint _max) public{
        require(senders[_msgSender()]);

        MAX_PUBLIC_MINT = _max;
    }

   function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override  returns (
        address receiver,
        uint256 royaltyAmount
    ){
        require(_exists(_tokenId));
        return (owner(), uint256(royalty * _salePrice / 1000));

    }


    function flipSaleState() public  {
        require(senders[_msgSender()]);
        saleIsActive = !saleIsActive;
    }



    function updateRoyalty(uint newRoyalty) public {
        require(senders[_msgSender()]);

        royalty = newRoyalty ;
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
            super._beforeTokenTransfer(from, to, tokenId);
        }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
            return super.supportsInterface(interfaceId);
        }

    function setBaseURI(string memory baseURI_)  external {
             require(senders[_msgSender()]);
            _baseURIextended = baseURI_;
        }

    function _baseURI() internal view virtual override returns (string memory) {
            return _baseURIextended;
        }

    function setProvenance(string memory provenance) public onlyOwner {
            PROVENANCE = provenance;
        }



    function getSaleState() public view returns (bool) {
            return saleIsActive;
    }

  

    
    function _confirmMint(uint _tokenNumber) private view returns (bool) {
        require(saleIsActive, "closed!");

        uint256 ts = totalSupply();
        require(_tokenNumber <= MAX_PUBLIC_MINT,"max public");
        require(ts + _tokenNumber <= MAX_TOKEN, "max total");
        
        

        return true;
    }



    function _doMint(uint numberOfTokens, address _target)private {
        

            uint256 t = totalSupply();

            for (uint256 i = 0; i < numberOfTokens; i++) {
                    _safeMint(_target, t + i);
                    
              }


               
   
    }

    function prooveMerkle(bytes32[] calldata _merkleProof, bytes32 _merkleRoot)private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

        require(MerkleProof.verify(_merkleProof, _merkleRoot, leaf));

        return true;
    }

    // paper
    function checkClaimEligibility(uint256 quantity) external view returns (string memory){
        if (!saleIsActive) {
            return "not live yet";
        } else if (quantity > MAX_PUBLIC_MINT) {
            return "max mint amount per transaction exceeded";
        } else if (totalSupply() + quantity > MAX_TOKEN) {
            return "not enough supply";
        }
        return "";
        }

    // paper mint
    function mintTo(address recipient, uint256 quantity,bytes32 _nonce, bytes calldata _signature) public payable 
    onlyPaper(keccak256(abi.encode(recipient,quantity)), _nonce, _signature){
        
        require(SALE_START > 0, "not yet");
        require(salePrice * (quantity) <= msg.value, "Ether");
        require(_confirmMint(quantity), "confirm");
                  
        _doMint(quantity,recipient);
    
    }

    function mintToWl(address recipient, uint256 quantity,bytes32 _nonce, bytes calldata _signature) public payable 
    onlyPaper(keccak256(abi.encode(recipient,quantity)), _nonce, _signature){
        
        require(SALE_START > 0, "not yet");
        require(preSalePrice * (quantity) <= msg.value, "Ether");
        require(_confirmMint(quantity), "confirm");
                  
        _doMint(quantity,recipient);
    
    }


    // team reserve
    function sendToken(uint _amount, address _target)public {
        require(senders[_msgSender()]);

        require(_amount >0);
        uint256 ts = totalSupply();
        require(ts + _amount <= MAX_TOKEN);
        

        _doMint(_amount,_target);
           
    }


    // Public Mint
    function publicMint(uint256  _amount) public payable {
        
        require(SALE_START > 0 && block.timestamp >= SALE_START, "not yet");
        require(salePrice * (_amount) <= msg.value, "Ether");
        require(_confirmMint(_amount), "confirm");
                  
        _doMint(_amount, _msgSender());
    
    }

    // Presale Mint
    function preSaleMint(uint256  _amount, bytes32[] calldata _proof) public payable {
      
       require(SALE_START > 0, "not yet");
       require(prooveMerkle(_proof, merkleRoot ),"whitelist");
       require(preSalePrice * (_amount) <= msg.value, "Ether");
       require(_confirmMint(_amount), "confirm");
                  
        _doMint(_amount, _msgSender());
    
    }
    
    function airdrop(address  _target, uint numberOfTokens) public {
        
        require(senders[_msgSender()]);
        require(numberOfTokens >0);
        uint256 ts = totalSupply();
        require(ts + numberOfTokens <= MAX_TOKEN, "max");
        
        _doMint(numberOfTokens, _target);
    }

    function burn(uint256 tokenId) external onlyOwner {
        require(ERC721.ownerOf(tokenId) == _msgSender(), "ERC721: transfer from incorrect owner");
        
        _burn(tokenId);
    }



    function withdraw(address _beneficiary) public onlyOwner {
        uint balance = address(this).balance;
        payable(_beneficiary).transfer(balance);
    }


    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "address");
       
        _transferOwnership(newOwner);

    }
    
}   

/*
                                                                                                                                                     
                                                                                
                               %%%%%*       /%%%%*                              
                         %%%                         %%                         
                     .%%                                 %%                     
                   %%                                       %                   
                 %%                                           %                 
               %%                                               %               
             .%     @@@@@@@@@@@@@@@@@@@@@               @@@@                    
            %%      @@@                @@@             @@@         ,            
            %       @@@                  @@@         @@@                        
           %%       &&&                   &@@@     @@@              %           
           %        &&&                     @@@@ @@@                            
          ,%        &&&&&&&&&&&&&&&&&&&%%(.   @@@@@                             
           %        %%%                      @@@@@@@                            
           %        %%%                    @@@@   @@@@                          
           %%       %%%                  @@@@       @@@             %           
            %%      %%%                 @@@           @@@          %            
             %%     %%%               @@@               @@@       %             
              %%    %%%%%%%%%%%%%%%%@@@                  @@@@    %              
                %%                                             %                
                  %%                                         %                  
                    %%                                     %                    
                       %%%                             %%                       
                            %%%                   %%#                           
                                    #%%%%%%%                 

*/