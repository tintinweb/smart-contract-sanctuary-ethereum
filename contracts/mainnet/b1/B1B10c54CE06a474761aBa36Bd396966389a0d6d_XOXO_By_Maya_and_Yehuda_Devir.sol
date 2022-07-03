// SPDX-License-Identifier: MIT
// @author: Exotic Technology LTD




pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ownable.sol";
import "./ERC721enumerable.sol";
import "./merkle.sol";

interface LVS{

    function balanceOf(address owner) external view  returns (uint256);

    function  tokenOfOwnerByIndex(address owner, uint256 index) external view  returns (uint256);

}

interface XOXO{

    function balanceOf(address owner) external view  returns (uint256);

    function  tokenOfOwnerByIndex(address owner, uint256 index) external view  returns (uint256);

}




contract XOXO_By_Maya_and_Yehuda_Devir is Ownable, ERC721, ERC721Enumerable {
    
    
    
    bool public saleIsActive = false;

    bool public claim = true;

    uint256 public claimed = 0;

    uint256 constant public  MAX_TOKEN = 10000;
    
             
    uint claimToken = 1956;

    uint teamReserve = 1000;

    uint256 constant public MAX_PUBLIC_MINT = 2;
    
    uint256  public royalty = 100;

    uint256 public startingIndex  = 0;

    uint256 public startingIndexBlock  = 0;

    uint256 public SALE_START = 0;

    uint256 public PRE_SALE = 0;

    address LVScontract;

    address XOXOcontract;

    string private _baseURIextended;

    string public PROVENANCE;

    bytes32 public ogMerkle = 0x7af3b037c04981e71e6eca7e4a19623558e2093363388a98d6622b17916520c8;
    

    mapping(address => uint) public minters;
    
    mapping(address => bool) private senders;
    
    mapping(uint => bool) private claimedLvs;
    mapping(uint => bool) private claimedXoxo;

    
    constructor() ERC721("XOXONFT", "XOXO") {
       

        _baseURIextended = "ipfs://QmYpTwhjtVBQL8AvxJGj7bRBsd19sZpiYLemPRhU8h52L1/"; //cover

        senders[msg.sender] = true; // add owner
        
        SetStartingIndexBlock();
        //setStartingIndex();
        //launchSale();

    }


    function updateOgMerkle(bytes32  _root)public {
       require(senders[_msgSender()]);
       ogMerkle = _root;
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

    function SetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0);
        
        startingIndexBlock = block.number;
    }

    function setStartingIndex() public onlyOwner {
        require(startingIndex == 0);
        require(startingIndexBlock != 0);
        
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


     function updateLvsAddress(address _contract)public {
        require(senders[_msgSender()]);
        LVScontract = _contract;
    }

    function updateXoXoAddress(address _contract)public {
        require(senders[_msgSender()]);
        XOXOcontract = _contract;
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

    function flipclaim() public  {
        require(senders[_msgSender()]);
        claim = !claim;
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

  


    function launchPreSale() public  {
        require(senders[_msgSender()]);
        require(SALE_START == 0 );
        require(PRE_SALE == 0 );
        require(startingIndex != 0);

        PRE_SALE = 1 ; // 
        saleIsActive = true;
        claim = true;
        
    }

    function launchSale() public  {
        require(senders[_msgSender()]);
        require(SALE_START == 0 );

        PRE_SALE = 0 ; // 
        SALE_START = 1;
        saleIsActive = true;
        claim = true;
        
    }


    
    function _confirmMint(uint _tokenNumber, uint _claim) private view returns (bool) {
        
        uint256 ts = totalSupply();
        uint256 msBalance = minters[_msgSender()];
       

        if(_claim == 1){
            require(_tokenNumber <= MAX_PUBLIC_MINT,"max!");
            require(msBalance + _tokenNumber <= MAX_PUBLIC_MINT, "2");
            if(claim == true){
                 require(ts + _tokenNumber <= MAX_TOKEN - (claimToken + teamReserve) + claimed, "maxClaim");
            }

        }
       
        require(!Address.isContract(_msgSender()),"contract");
        require(saleIsActive, "closed!");
        require(ts + _tokenNumber <= MAX_TOKEN, "maxTotal");
        

       

        return true;
    }



    function _doMint(uint numberOfTokens, address _target)private {
        
            minters[_msgSender()]++;   

            uint256 t = totalSupply();

            for (uint256 i = 0; i < numberOfTokens; i++) {
                    _safeMint(_target, t + i);
                    
              }


               
   
    }


    function TeamReserve(uint _amount, address _target)public onlyOwner{
        
        require(_amount >0);
        uint256 ts = totalSupply();
        require(ts + _amount <= MAX_TOKEN);
        claimed += _amount; 

        _doMint(_amount,_target);
           
    }


    function XOXOMint( bytes32[] calldata _proof )public{
        
        
        if(PRE_SALE == 1){
             require(prooveMerkle(_proof, ogMerkle),"whitelist");


        }
        
        uint LvsBalance =  LVS(LVScontract).balanceOf(_msgSender()); // check LVS balance for owner
        uint xoxoBalance =  XOXO(XOXOcontract).balanceOf(_msgSender()); // check LVS balance for owner

      

        uint ownerBalance = LvsBalance*4 + xoxoBalance;

        if(ownerBalance > 0 && claim){
            
         if(LvsBalance > 0){
            for (uint i = 0; i < LvsBalance; i++){ // add token to claimed list
               
                    uint claimedLvsToken = LVS(LVScontract).tokenOfOwnerByIndex(_msgSender(),i);
                    require(claimedLvs[claimedLvsToken] == false, "claimed");
                    claimedLvs[claimedLvsToken] = true;

               
                }
         }
          if(xoxoBalance > 0){
             for (uint i = 0; i < xoxoBalance; i++){ // add token to claimed list
              
                    uint claimedxoToken = XOXO(XOXOcontract).tokenOfOwnerByIndex(_msgSender(),i);
                    require(claimedXoxo[claimedxoToken] == false, "claimed");
                    claimedXoxo[claimedxoToken] = true;

               
              }
            }

            

              if(xoxoBalance > 0){
                  xoxoBalance = 4; // 4 free for xoxo holder
             }

           ownerBalance = LvsBalance*4 + xoxoBalance;

           require(_confirmMint(ownerBalance,0),"confirm");

           claimed += ownerBalance;

           _doMint(ownerBalance, _msgSender());
           
          
        }
        else{

            uint ts = totalSupply();
            uint amountMint = 2;
            if(ts == MAX_TOKEN - 1){
                amountMint = 1;
            }

            require(_confirmMint(amountMint,1),"confirmNon");
            _doMint(amountMint, _msgSender());
        }

        
      
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