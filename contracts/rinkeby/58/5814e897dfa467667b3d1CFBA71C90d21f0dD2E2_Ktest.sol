// SPDX-License-Identifier: MIT
// @author: Exotic Technology LTD




pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ownable.sol";
import "./ERC721enumerable.sol";


contract Ktest is Ownable, ERC721, ERC721Enumerable {
    
    string public PROVENANCE;
    bool public saleIsActive = false; 

    uint256 constant public  MAX_TOKEN = 101;
    

    uint256 constant public MAX_PUBLIC_MINT = 30;
    
    uint256  public royalty = 55;

    uint256 public startingIndex  = 0;

    uint256 public startingIndexBlock  = 0;
   
    string private _baseURIextended;

    mapping(address => bool) private minters;
    
   

    
    constructor() ERC721("Ktest", "KKT") {
       
         
        _doMint(1, msg.sender);

        _baseURIextended = "ipfs://Qmact5RDcmfLizG4HY1t2uZPeDNLnSiyAYrDL8rQoZiTwH/"; //cover

    }


     function SetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }

    function setStartingIndex() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % (MAX_TOKEN);
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number - startingIndexBlock > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % (MAX_TOKEN);
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex++;
        }
    }
    
    function getStartingIndex() public view returns(uint){

        return startingIndex;

    }

    function getStartingblock() public view returns(uint){

        return startingIndexBlock;

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


    function updateRoyalty(uint newRoyalty) public onlyOwner {
        royalty = newRoyalty ;
    }




    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
            super._beforeTokenTransfer(from, to, tokenId);
        }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
            return super.supportsInterface(interfaceId);
        }

    function setBaseURI(string memory baseURI_)  external onlyOwner  {
              
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



    function _doMint(uint numberOfTokens, address _target)private {
        
            minters[_msgSender()]= true;   

            uint256 t = totalSupply();

            for (uint256 i = 0; i < numberOfTokens; i++) {
                    _safeMint(_target, t + i);
                    
              }


               
   
        }


    function _confirmMint() private view returns (bool) {
        
        uint256 ts = totalSupply();
        uint256 msBalance = balanceOf(_msgSender());

        require(!minters[_msgSender()],"already minted");
        require(!Address.isContract(_msgSender()),"no contract");
        require(msBalance == 0, "only 1");
        require(saleIsActive, "sale closed");
        require(ts + 1 <= MAX_TOKEN, "max tokens");
        

        return true;
    }



    function AnotherStoryBorn() public payable {
        
        require(_confirmMint(), "sale closed");
                  
        _doMint(1, _msgSender());
    
    }


    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }


    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
       
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