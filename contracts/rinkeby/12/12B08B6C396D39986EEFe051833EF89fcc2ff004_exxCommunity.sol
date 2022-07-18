// SPDX-License-Identifier: MIT
// @author: Exotic Technology LTD




pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ownable.sol";
import "./ERC721enumerable.sol";
import "./merkle.sol";





contract exxCommunity is Ownable, ERC721, ERC721Enumerable {
    
    
    
    bool public saleIsActive = false;

    uint256 public  MAX_TOKEN = 100;

    uint256 MAX_PUBLIC_MINT = 2; 
    
    uint256  public royalty = 100;

    uint256 public SALE_START = 0;

    bool Merkle = true;

    bytes32 public MerkleRoot = 0x6ee8bee8c77b05f5cf46ea9f7c98b6e3571366d95ccdb3f96be8640e43b6ec21;

    string private _baseURIextended;

    string public PROVENANCE;
 

    mapping(address => bool) public minters;
    
    mapping(address => bool) private senders;
    
  

    
    constructor() ERC721("EXX", "EX") {
       

        _baseURIextended = "ipfs://QmYpTwhjtVBQL8AvxJGj7bRBsd19sZpiYLemPRhU8h52L1/"; //cover

        senders[msg.sender] = true; // add owner

    }

     
    function updateMerkle(bytes32  _root)public {
       require(senders[_msgSender()]);
       MerkleRoot = _root;
    }

    function updateSupply(uint _supply)public {
       require(senders[_msgSender()]);
       
       require(_supply > 0,"cannot be 0");

       uint256 ts = totalSupply();
       
       require(_supply >= ts, "lower than minted!");

       MAX_TOKEN = _supply;
    }

    function updateMaxMint(uint _supply)public {
       require(senders[_msgSender()]);
       
       require(_supply > 0,"cannot be 0");

       MAX_PUBLIC_MINT = _supply;

    }

 
   
    function prooveMerkle(bytes32[] calldata _merkleProof, bytes32 _merkleRoot)private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

        require(MerkleProof.verify(_merkleProof, _merkleRoot, leaf),"merkle");

        return true;
    }
    


   function addSender(address _address) public onlyOwner  {
        
        require(_address != address(0));
        senders[_address] = true;
       
    }
    
    function removeSender(address _address) public onlyOwner {
        require(_address != address(0));
        senders[_address] = false;
        
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

    function flipMerkle() public  {
        require(senders[_msgSender()]);
        Merkle = !Merkle;
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

  


    function launchSale() public  {
        require(senders[_msgSender()]);
        require(SALE_START == 0 );

        SALE_START = 1;
        saleIsActive = true;
        
    }


    function _confirmMint(uint _amount) private view returns (bool) {
        
        require(saleIsActive, "sale closed");
        require(_amount > 0,"amount");
        require(!minters[_msgSender()],"already minted");

        uint256 ts = totalSupply();
        uint256 msBalance = balanceOf(_msgSender()); 

        require(msBalance < MAX_PUBLIC_MINT, "max public");
        
        require(ts + _amount <= MAX_TOKEN, "max tokens");
        

        return true;
    }

    function _doMint(uint numberOfTokens, address _target)private {
        
            minters[_msgSender()]= true;   

            uint256 t = totalSupply();

            for (uint256 i = 0; i < numberOfTokens; i++) {
                    _safeMint(_target, t + i);
                    
              }

    }
    
    function ClaimMint(uint _amount, bytes32[] calldata _proof) public {
        

        if(Merkle){
           require(prooveMerkle(_proof,MerkleRoot),"Merkle");
        }

       require(_confirmMint(_amount), "confirm");

       _doMint(_amount, _msgSender());

        
     

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