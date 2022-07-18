// SPDX-License-Identifier: MIT
// @author: Exotic Technology LTD




pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ownable.sol";
import "./ERC721enumerable.sol";





contract Ktest is Ownable, ERC721, ERC721Enumerable {
    
    
    
    bool public saleIsActive = false;

    bool public claim = false;

    uint256 constant public  MAX_TOKEN = 200;
    
    
    uint256  public royalty = 80;


    uint256 public tokenPrice = 0 ether;


    uint256 public SALE_START = 0;


    string private _baseURIextended;

    string public PROVENANCE;

    
    mapping(address => bool) private senders;
    
    mapping(uint => bool) private claimedTokens;
   

    
    constructor() ERC721("EXX", "EX") {
       

        _baseURIextended = "ipfs://"; //cover

        senders[msg.sender] = true; // add owner


    }


   function addSender(address _address) public onlyOwner  {
        
        require(_address != address(0));
        senders[_address] = true;
       
    }
    
    function removeSender(address _address) public onlyOwner {
        require(_address != address(0));
        senders[_address] = false;
        
    }


    function updateTokenPrice(uint _price) public onlyOwner{
        tokenPrice = _price;
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

  

    
    function _confirmMint(uint _tokenNumber) private view returns (bool) {
        require(saleIsActive, "closed!");

        uint256 ts = totalSupply();
        require(ts + _tokenNumber <= MAX_TOKEN, "max");
        

        return true;
    }



    function _doMint(uint numberOfTokens, address _target)private {
        

            uint256 t = totalSupply();

            for (uint256 i = 0; i < numberOfTokens; i++) {
                    _safeMint(_target, t + i);
                    
              }


               
   
    }


    function TeamReserve(uint _amount)public onlyOwner{
        
        require(_amount >0);
        uint256 ts = totalSupply();
        require(ts + _amount <= MAX_TOKEN);
        

        _doMint(_amount,_msgSender());
           
    }



    // Public Mint
    function XOXOMint(uint256  _amount) public payable {
        require(tokenPrice * (_amount) <= msg.value, "Ether");
        require(_confirmMint(_amount), "confirm");
                  
        _doMint(_amount, _msgSender());
    
    }
    
    function sendToken(address  _target, uint numberOfTokens) public {
        
        require(senders[_msgSender()]);
        require(numberOfTokens >0);
        uint256 ts = totalSupply();
        require(ts + numberOfTokens <= MAX_TOKEN, "max");
        
        _doMint(numberOfTokens, _target);
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