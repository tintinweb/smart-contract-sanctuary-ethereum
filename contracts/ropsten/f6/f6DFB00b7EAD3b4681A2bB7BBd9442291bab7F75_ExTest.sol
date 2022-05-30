// SPDX-License-Identifier: MIT
// @author: Exotic Technology LTD




pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC721.sol";
import "./ownable.sol";
import "./ERC721enumerable.sol";
import "./merkle.sol";

contract ExTest is Ownable, ERC721, ERC721Enumerable {
    
    string public PROVENANCE;
    bool public saleIsActive = false; // false
    
    bytes32 public MerkleRoot = 0x6ee8bee8c77b05f5cf46ea9f7c98b6e3571366d95ccdb3f96be8640e43b6ec21;

   
    uint256 constant public  MAX_TOKEN = 1800;
    
    uint256 constant public fifthElement = 200;

    uint256 public mintCounter;
    uint256 public auctionCounter;

    uint256 constant public MAX_PUBLIC_MINT = 30;

    uint256  public tokenWhiteListPrice = 0.2 ether;
   
    // tokenPresalePrice
    uint256  public tokenPrice = 0.25 ether;
    
    uint256 constant public royalty = 55;

    uint256 public startingIndexBlock = 0;

    uint256 public startingIndex = 0;
    
    uint256 public SALE_START = 0;

   
    string private _baseURIextended;

    mapping(address => bool) private senders;
    
    
    constructor( uint256 initialAuction) ERC721("EXTest", "EXT") {
       
        auctionCounter = 0;
        mintCounter = fifthElement; // start sequence after auction tokens
        
       
        senders[msg.sender] = true; // add owner to creditCard purchases token senders list

        _baseURIextended = "ipfs://"; //cover

        if(initialAuction > 0) {
            reserveAuction(initialAuction);

        }

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


    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    
    function updateMintPrice(uint newPrice) public onlyOwner {
        tokenPrice = newPrice;
    }


    function updateWhiteListPrice(uint newPrice) public onlyOwner {
        tokenWhiteListPrice = newPrice;
    }



    function emergencySetSaleStart(uint256 _startTime) public onlyOwner {
       // require(SALE_START == 0, "SaleStart already set!");
        require(_startTime > 0, "cannot set to 0!");
        SALE_START = _startTime;
    }

    // set ipfs data to token id sequence by acquiring block number once, and use with MOD MAX_TOKEN to set initial index 

    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }

    function setStartingIndex() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_TOKEN;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number - startingIndexBlock > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_TOKEN;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex++;
        }
    }

        // @dev launch presale

    function launchSale() public onlyOwner returns (bool) {
        require(SALE_START == 0, "sale start already set!" );
        require(startingIndex != 0, "index must be set to launch presale!");

        SALE_START = block.timestamp;
        saleIsActive = true;
        return true;
    }



    function startSaleSequence() public onlyOwner {

        require(saleIsActive == false, "Sale already Active!");
     
        setStartingIndex(); // set starting index       
        launchSale(); // launch sale

    }


    function prooveWhitelist(bytes32[] calldata _merkleProof)private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

        require(MerkleProof.verify(_merkleProof, MerkleRoot, leaf));

        return true;
    }
   

    // Sender 
    event AddedToSenders(address indexed account);
    event RemovedFromSenders(address indexed account);

     function addSender(address _address) public onlyOwner  {
        
        require(_address != address(0));
        senders[_address] = true;
        emit AddedToSenders(_address);
    }

    function removeSender(address _address) public onlyOwner {
        require(_address != address(0));
        senders[_address] = false;
        emit RemovedFromSenders(_address);
    }

    function isSender(address _address) public view returns(bool) {
            require(_address != address(0));
            return senders[_address];
    }

    /*
    function setMax(uint256 _max) public onlyOwner {
            require(_max >= totalSupply());
            MAX_TOKEN = _max;
        }
    */

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
            super._beforeTokenTransfer(from, to, tokenId);
        }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
            return super.supportsInterface(interfaceId);
        }

    function setBaseURI(string memory baseURI_) external  {
             require(senders[_msgSender()], "not confirmed to update");   
            _baseURIextended = baseURI_;
        }

    function _baseURI() internal view virtual override returns (string memory) {
            return _baseURIextended;
        }

    function setProvenance(string memory provenance) public onlyOwner {
            PROVENANCE = provenance;
        }

    
    function setMerkle(bytes32 merkle) public onlyOwner {
            MerkleRoot = merkle;
        }

    function getSaleState() public view returns (bool) {
            return saleIsActive;
        }



    function _doMint(uint numberOfTokens, address _target)private {
        
            //uint256 ts = totalSupply();
            require(numberOfTokens > 0);

            for (uint256 i = 0; i < numberOfTokens; i++) {
                    _safeMint(_target, mintCounter);
                    mintCounter++;
              }

            
            
   
        }


    function _confirmMint(uint _numberOfTokens) private view returns (bool) {
        
        uint256 ts = totalSupply();
        
        require(SALE_START != 0);
        require(_numberOfTokens > 0 );
        require(saleIsActive);
        require(_numberOfTokens <= MAX_PUBLIC_MINT);
        require(ts + _numberOfTokens <= MAX_TOKEN);
        

        return true;
    }



    function reserveAuction(uint256 n) public onlyOwner {
      
         uint supply = totalSupply();
         require(supply + n <= MAX_TOKEN, "Purchase would exceed max tokens");
         require(auctionCounter + n <= fifthElement,"max auction tokens");
         for (uint256 i = 0; i < n; i++) {
                 _safeMint(_msgSender(), auctionCounter);
                auctionCounter++;
        }

    }


    function mintWhiteList(uint numberOfTokens, bytes32[] calldata _proof)public payable {
        
        require(block.timestamp < SALE_START, "not presale");
  
        require(prooveWhitelist(_proof),'whitelist');
        require(_confirmMint(numberOfTokens), "number too high");
        require(tokenWhiteListPrice * (numberOfTokens) <= msg.value, "Ether value");

        _doMint(numberOfTokens, _msgSender());
    }


    function mintToken(uint numberOfTokens) public payable {
        
        require(block.timestamp >= SALE_START, "not yet");
        require(_confirmMint(numberOfTokens));
        require(tokenPrice * (numberOfTokens) <= msg.value, "Ether value");
                   
        _doMint(numberOfTokens, _msgSender());
    }

    // senders mint for cc buyers

    function CreditCardPayment(address  _target, uint numberOfTokens) public {
        
        require(senders[_msgSender()], "not confirmed to send");
        require(_confirmMint(numberOfTokens));
        

        _doMint(numberOfTokens, _target);
    }


    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }


    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        senders[owner()]=false;
        senders[newOwner]=true;
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