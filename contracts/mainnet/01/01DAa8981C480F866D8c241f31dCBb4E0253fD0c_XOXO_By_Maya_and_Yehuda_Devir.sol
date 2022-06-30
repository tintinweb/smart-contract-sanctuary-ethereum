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



contract XOXO_By_Maya_and_Yehuda_Devir is Ownable, ERC721, ERC721Enumerable {
    
    
    
    bool public saleIsActive = false;

    bool public claim = false;

    uint256 constant public claimToken = 101;

    uint256 public claimed = 0;

    uint256 constant public  MAX_TOKEN = 10000;
    

    uint256 constant public MAX_PUBLIC_MINT = 4;
    
    uint256  public royalty = 80;

    uint256 public ogPrice = 0.05 ether;

    uint256 public lvPrice = 0.075 ether;

    uint256 public tokenPrice = 0.101 ether;

    uint256 public startingIndex  = 0;

    uint256 public startingIndexBlock  = 0;

    uint256 public SALE_START = 0;

    address LVScontract;

    bytes32 public ogMerkle = 0x6ee8bee8c77b05f5cf46ea9f7c98b6e3571366d95ccdb3f96be8640e43b6ec21;
    
    bytes32 public lvMerkle = 0x6ee8bee8c77b05f5cf46ea9f7c98b6e3571366d95ccdb3f96be8640e43b6ec21;

    string private _baseURIextended;

    string public PROVENANCE;

    mapping(address => uint) public minters;
    
    mapping(address => bool) private senders;
    
    mapping(uint => bool) private claimedTokens;
   

    
    constructor() ERC721("XOXONFT", "XOXO") {
       

        _baseURIextended = "ipfs://QmXHCA7TxrroX3ghThz3XB4DYJJXWtjd2Eym7jSUvweWL7/"; //cover

        senders[msg.sender] = true; // add owner
        
        SetStartingIndexBlock();
        //setStartingIndex();
        //launchSale();

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

    function updateOgMerkle(bytes32  _root)public {
       require(senders[_msgSender()]);
       ogMerkle = _root;
    }

    function updateLvMerkle(bytes32  _root)public{
        require(senders[_msgSender()]);
       lvMerkle = _root;
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

  
 

     function prooveMerkle(bytes32[] calldata _merkleProof, bytes32 _merkleRoot)private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

        require(MerkleProof.verify(_merkleProof, _merkleRoot, leaf));

        return true;
    }


    function launchSale() public  {
        require(senders[_msgSender()]);
        require(SALE_START == 0 );
        require(startingIndex != 0);

        SALE_START = block.timestamp + (101*60); // first 101 minutes for og and wl
        saleIsActive = true;
        claim = true;
        
    }


    
    function _confirmMint(uint _tokenNumber, uint _claim) private view returns (bool) {
        
        uint256 ts = totalSupply();
        uint256 msBalance = balanceOf(_msgSender());
        uint256 totalMinted = minters[_msgSender()];

        if(_claim == 0){
            require(_tokenNumber <= MAX_PUBLIC_MINT,"max!");
            require(totalMinted + _tokenNumber <= MAX_PUBLIC_MINT,"4!");
            require(msBalance + _tokenNumber <= MAX_PUBLIC_MINT, "4");

        }
       
        require(!Address.isContract(_msgSender()),"contract");
        require(saleIsActive, "closed!");
        require(ts + _tokenNumber <= MAX_TOKEN, "max");
        
        if(claim == true){
            require(ts + _tokenNumber <= MAX_TOKEN - claimToken + claimed, "max");

        }

        return true;
    }



    function _doMint(uint numberOfTokens, address _target)private {
        
            minters[_msgSender()]++;   

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


    function LoveStoryClaim()public{
        

        require(claim == true, "claim");

        uint ownerBalance =  LVS(LVScontract).balanceOf(_msgSender()); // check LVS balance for owner

        require(ownerBalance > 0,"balance");

        for (uint i = 0; i < ownerBalance; i++){ // add token to claimed list
            uint claimedToken = LVS(LVScontract).tokenOfOwnerByIndex(_msgSender(),i);
            require(claimedTokens[claimedToken] == false, "claimed");
            claimedTokens[claimedToken] = true;
        }

        
        require(_confirmMint(ownerBalance,1));

        claimed = claimed + ownerBalance;

        _doMint(ownerBalance, _msgSender());
           
    }

    
     //og mint
    function OGMint(uint numberOfTokens, bytes32[] calldata _proof)public payable {
        
        require(block.timestamp < SALE_START, "presale");
  
        require(prooveMerkle(_proof, ogMerkle),"whitelist");
        require(_confirmMint(numberOfTokens,0));
        require(ogPrice * (numberOfTokens) <= msg.value, "Ether");

        _doMint(numberOfTokens, _msgSender());
    }

    
    // Love Story mint
    function LoveListMint(uint numberOfTokens, bytes32[] calldata _proof)public payable {
        
        require(block.timestamp < SALE_START, "presale");
  
        require(prooveMerkle(_proof, lvMerkle ),"whitelist");
        require(_confirmMint(numberOfTokens,0), "failed");
        require(lvPrice * (numberOfTokens) <= msg.value, "Ether");

        _doMint(numberOfTokens, _msgSender());
    }

    // Public Mint
    function XOXOMint(uint256  _amount) public payable {
        require(block.timestamp >= SALE_START, "not yet");
        require(tokenPrice * (_amount) <= msg.value, "Ether");
        require(_confirmMint(_amount,0), "closed");
                  
        _doMint(_amount, _msgSender());
    
    }
    
    function CreditCardMint(address  _target, uint numberOfTokens) public {
        
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