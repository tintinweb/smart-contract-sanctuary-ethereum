// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721OBI.sol";

//
//
//                              ///                                      
//                           ////////                                    
//                         /////////////                                 
//                     //////////////////                               
//                   ///////////////////////                            
//                ////////////////////////////                          
//    &&&&&&&&&     ////////////////////////     &&&&&&&&&&             
//                     ///////////////////                              
//      &&&&&&&&&&&      //////////////      &&&&&&&&&&&&               
//      &&&&&&&&&&&&&&      /////////     &&&&&&&&&&&&&&&               
//                &&&&&&      ////      &&&&&&&                         
//                  &&&&&&&          &&&&&&&                            
//            &&&&&    &&&&&&      &&&&&&&   &&&&&                      
//               &&&&&   &&&&&&&&&&&&&&    &&&&&                        
//                 &&&&&    &&&&&&&&&   &&&&&                           
//                    &&&&&   &&&&    &&&&&                             
//                      &&&&&      &&&&&                                
//                         &&&&& &&&&&                                  
//                           &&&&&&                                     
//                             &&                                       
//                                                                      
//                                                                      
//                      &&&     &&&&&    &&                             
//                    &&   &&   &&   &&  &&                             
//                   &&     &&  &&&&&&&  &&                             
//                    &&   &&   &&&   && &&                             
//                      &&&     &&&& &&  &&            
//
//========================================================================
//  ONCHAIN BLOCK INVADERS - Mint contract



interface IMotherShip  {
    function isMotherShip() external pure returns (bool);
    function launchPad(uint256 tokenId,uint8 idx1,uint8 idx2,uint8 cnt1,uint8 cnt2 ) external view returns (string memory);
}

contract BlockInvaders is ERC721OBI, Ownable, ReentrancyGuard {
    
    struct globalConfigStruct {
        uint8  skinIndex;
        uint8  colorIndex;
    }

    globalConfigStruct globalConfig;
    
    //Mint Related
    uint256 public constant MAX_PER_TX                   = 1;
    uint256 public FOUNDERS_RESERVE_AMOUNT               = 5999;
    uint256 public constant MAX_SUPPLY                   = 9750;
    uint256 private isMintPaused = 0;


    //Accountability 
    //Future Skin and color Morph Mint
    uint256 public MORPH_MINT_PRICE;
    address obiAccount;
    address artistAccount;
    uint256 artistPercentage;
    uint256 private morphMintPhase = 0;
   
    //white List
    bytes32 public whiteListRoot;
    mapping(address => uint256) private _addressToMinted; 
        
    
    //Mapping from token index to Address
    //this will give the Token Owner the ability to switch betwen upgradable Contracts
    mapping(uint256 =>address) private _tokenIndexToAddress;
    
    //Events 
    event ConnectedToMotherShip(address motherShipAddress);
    event ContractPaused();
    event ContractUnpaused();
    event MintNewSkinPaused();
    event MintNewSkinUnpaused();
    event whiteListRootSet();
    event mintPriceSet();


//Implementation
    constructor() ERC721OBI("coanaCHIRITA", "dsdsdsSd2") {
        //initialize the collection
        _mint(_msgSender(),0);
    } 

// deployment related 
//===============================   
    //Acknowledge contract is `BlockInvaders` :always true
    function isBlockInvaders() external pure returns (bool) {return true;}
    
    
    function setTeleporterAddress(address _motherShipAddress,uint8 _skinIndex,uint8 _indexColor) public onlyOwner {
        
        IMotherShip  motherShip = IMotherShip (_motherShipAddress);
        // Verify that we have the appropriate address
        require( motherShip.isMotherShip() );

        //prepare the new skin and/or color pallete for morph mint
        globalConfig.skinIndex    =  _skinIndex;
        globalConfig.colorIndex   =  _indexColor;

        //store the address of the mothership contract per skin
        _tokenIndexToAddress[globalConfig.skinIndex] =  _motherShipAddress;

        emit ConnectedToMotherShip(_tokenIndexToAddress[globalConfig.skinIndex]);
    } 

    function getRenderingContract(uint256 skinIdx) public view returns (address) {
        if (_tokenIndexToAddress[skinIdx] == address(0)) {
            return address(0);
        }
        return _tokenIndexToAddress[skinIdx];
    }

    function getGlobalConfig() public view returns (address,uint8,uint8) {
        return (_tokenIndexToAddress[globalConfig.skinIndex],globalConfig.skinIndex,globalConfig.colorIndex);
    }

// ERC721 related
//===============================   

    function tokenOfOwnerByIndex(address owner, uint256 index) public view  returns (uint256 tokenId) {
        require(index < balanceOf(owner), "ERC721: owner index out of bounds");
        uint count;
        for(uint i; i < _owners.length; i++){
            if(owner == _owners[i].account){
                if(count == index) return i;
                else count++;
            }
        }
        revert("ERC721: owner index out of bounds");
    }
    
    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool){
        for(uint256 i; i < _tokenIds.length; ++i ){
            if(_owners[_tokenIds[i]].account != account)
                return false;
        }

        return true;
    }
    
    function getOwnerTokens(address owner) public view  returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) return new uint256[](0);
  
        uint256[] memory tokensId = new uint256[](tokenCount);
     
        uint k;
        for(uint i; i < _owners.length; i++){
            if(owner == _owners[i].account){
                tokensId[k]=i;
                k++;
            }
        }
        return tokensId;
    }

    function totalSupply() public view  returns (uint256) {
        return _owners.length;
    }

// Contract Actions
//===============================   
   
    function unpauseMint(uint256 _mintType) public onlyOwner {
        isMintPaused = _mintType;
        emit ContractUnpaused();
    }

    function getMintPhase() public view returns (uint256) {
        return isMintPaused;
    }
    
    function unpauseMorph(uint256 _morphType) public onlyOwner {
        morphMintPhase = _morphType;
    }

    function getMorphPhase() public view returns (uint256) {
        return morphMintPhase;
    }

// merkleTree 
//===============================       
    function _leaf(string memory allowance, string memory payload) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(payload, allowance));
    }
    
    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, whiteListRoot, leaf);
    }

    function getAllowance(string memory allowance, bytes32[] calldata proof) public view returns (string memory) {
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(_verify(_leaf(allowance, payload), proof), "OBI: Merkle Tree proof supplied.");
        return allowance;
    }

    function setWhiteListRoot(bytes32 _whiteListRoot) external onlyOwner {
        whiteListRoot = _whiteListRoot;
        emit whiteListRootSet();
    }

// skins and chromas related
//===============================   
      
    //1.returns the total number of skins or color for a given skin or color index [flag = 0 - skin, 1 - color]
    function getMorphTotalSupply(uint8 id,uint256 flag) public view returns (uint256) {
        require((id >=0) && (id<32), "OBI: invalid ID.Should be [0-31].");
        uint256 k=0;
        for(uint256 tknID = 0; tknID < _owners.length; tknID++){
            uint32 bitmap = _owners[tknID].bitmap1;
            if (flag == 1){
                bitmap = _owners[tknID].bitmap2;
            }
            if( isBitSet(bitmap,id)==true ){
                k++;
            }
        }
        return k;
    }
    
    //2.returns the active index for skins or color for a token, [flag = 0 - skin, 1 - color]
    function getActiveMorphIdxByToken(uint256 tokenId,uint256 flag) public view returns (uint8){
        require(tokenId < _owners.length, "OBI: invalid token ID.");
        uint8 idx = _owners[tokenId].idx1;
        if (flag == 1){
                idx = _owners[tokenId].idx2;
        }
        return idx;
    }
    
    //3.returns a list of active index for skins or color for a token list, [flag = 0 - skin, 1 - color]
    function getActiveMorphIdxByTokenLst(uint256[] calldata tokensIdList,uint256 flag) public view returns (uint8[] memory){
        uint8[] memory activeIdxList = new uint8[](tokensIdList.length);
        for(uint256 id = 0; id < tokensIdList.length; id++){
            uint256 tokenId = tokensIdList[id];
            require(tokenId < _owners.length, "OBI: invalid token ID.");
            activeIdxList[id] =  _owners[tokenId].idx1;
            if (flag == 1){
                activeIdxList[id] =  _owners[tokenId].idx2;
            }
        }
        return activeIdxList;
    }
    
    //4.returns the map of skins or color for a token, [flag = 0 - skin, 1 - color]
    function getMorphMapByToken(uint256 tokenId,uint256 flag) public view returns (uint32){
        require(tokenId < _owners.length, "OBI: invalid token ID.");
        if (flag == 0){
        return _owners[tokenId].bitmap1;
        }
        else{
            return _owners[tokenId].bitmap2;
        }
    }
    
    //5.returns a list of tokens that have the selected skin or color for a token list, [flag = 0 - skin, 1 - color]
    function getOBIforIdx(uint256[] calldata tokensIdList,uint8 idx,uint256 flag) public view returns (uint256[] memory) {
        require((idx >=0) && (idx<32), "OBI: invalid IDX.Should be [0-31].");
        uint256 count=0;
        for(uint256 id = 0; id < tokensIdList.length; id++)
        {
            uint256 tokenID = tokensIdList[id];
            uint32 bitmap = _owners[tokenID].bitmap1;
            if (flag == 1){
                bitmap = _owners[tokenID].bitmap2;
            }
            if ( isBitSet(bitmap,idx) == true )
            {
                count ++;
            }
        }
        uint256 k=0;
        uint256[] memory tokenList = new uint256[](count);
        for(uint256 id = 0; id < tokensIdList.length; id++){
           uint256 tokenID = tokensIdList[id];
           uint32 bitmap = _owners[tokenID].bitmap1;
           if (flag == 1){
                bitmap = _owners[tokenID].bitmap2;
            }
           if(isBitSet(bitmap,idx) ){
                tokenList[k] = tokenID;
                k++;
           }
        }
        return tokenList;
    }

    //6.returns the list skins owned by token 
    function getOBISkinListByToken(uint256 tokenId) public view returns (uint8[] memory) {
        require(tokenId < _owners.length, "OBI: invalid token id.");
        uint32 count=countSetBits(_owners[tokenId].bitmap1);
        uint8[] memory skinList = new uint8[](count);
        uint8 k = 0;
        for(uint8 i=0; i <32; i++) {
            if(isBitSet(_owners[tokenId].bitmap1,i)){
                skinList[k] = i;
                k++;
            }
        }
        return skinList;
    }

    //7.returns the list of colors owned by token 
    function getOBIColorListByToken(uint256 tokenId) public view returns (uint8[] memory) {
        require(tokenId < _owners.length, "OBI: invalid token id.");
        uint32 count=countSetBits(_owners[tokenId].bitmap2);
        uint8[] memory colorList = new uint8[](count);
        uint8 k = 0;
        for(uint8 i=0; i <32; i++) {
            if(isBitSet(_owners[tokenId].bitmap2,i)){
                colorList[k] = i;
                k++;
            }
        }
        return colorList;
    }

    //Strict Validation for payed Mint
    function _validateMorphList(uint256[] calldata tokensIdList) internal view  {
        for(uint256 id; id < tokensIdList.length; id++){
            uint256 tokenID = tokensIdList[id];
            require(tokenID < _owners.length, "OBI: invalid token id");
            require(msg.sender == _owners[tokenID].account, "OBI: You are not the owner of one of the OBI.");
            
            bool hasSkin = isBitSet(_owners[tokenID].bitmap1,globalConfig.skinIndex);
            bool hasColor= isBitSet(_owners[tokenID].bitmap2,globalConfig.colorIndex);
            require( ( hasSkin == false) || (hasColor == false), "OBI: One of the OBI is already Morph Minted.");
        }
    }
    //Light Validation for free Mint,morph transform
    function _validateLightMorphList(uint256[] calldata tokensIdList) internal view  {
        uint256 count = 0;
        for(uint256 id; id < tokensIdList.length; id++){
            uint256 tokenID = tokensIdList[id];
            require(tokenID < _owners.length, "OBI: invalid token id");
            require(msg.sender == _owners[tokenID].account, "OBI: You are not the owner of one of the OBI.");

            bool hasSkin = isBitSet(_owners[tokenID].bitmap1,globalConfig.skinIndex);
            bool hasColor= isBitSet(_owners[tokenID].bitmap2,globalConfig.colorIndex);
            if ( ( hasSkin == true) && (hasColor == true))
            {
                count++;
            }
        }
        require(  count < tokensIdList.length , "OBI: All the OBIs are up to date");
    }

    function _updateMorphList(uint256[] calldata tokensIdList) internal   {
        for(uint256 id; id < tokensIdList.length; id++){
            uint256 tokenID = tokensIdList[id];
            //update skin if owner does not have it already
            if ( isBitSet(_owners[tokenID].bitmap1,globalConfig.skinIndex) == false ){
                _owners[tokenID].cnt1 ++;
                _owners[tokenID].bitmap1 = setBit(_owners[tokenID].bitmap1, globalConfig.skinIndex);
            }
                _owners[tokenID].idx1 =  globalConfig.skinIndex;
            //update skin if owner does not have it already
            if ( isBitSet(_owners[tokenID].bitmap2,globalConfig.colorIndex) == false ){
                _owners[tokenID].cnt2 ++;
                _owners[tokenID].bitmap2 = setBit(_owners[tokenID].bitmap2, globalConfig.colorIndex);
            }
               _owners[tokenID].idx2 = globalConfig.colorIndex;
        }
    }
   
    //change the owned Skins or owned Colors for OBI
    function morphOBI(uint256[] calldata tokensIdList,uint8 skinNr,uint8 colorNr) public {
       //validation
       require((skinNr >=0) && (skinNr<32), "OBI: invalid skinNr.Value must be between [0-31]");
       require((colorNr >=0) && (colorNr<32), "OBI: invalid colorNr.Value must be between [0-31]");
       
       //Validate Morph
       for(uint256 id; id < tokensIdList.length; id++){
        uint256 tokenID = tokensIdList[id];
        require(tokenID < _owners.length, "OBI: invalid token id");
        require(msg.sender == _owners[tokenID].account, "OBI: You ar e not the owner of one of the OBI");
       } 
       //Morph the OBIS
       for(uint256 id; id < tokensIdList.length; id++){
            uint256 tokenID = tokensIdList[id];
            //update skin if you own it
            if ( isBitSet(_owners[tokenID].bitmap1,skinNr) == true ){
                if ( _owners[tokenID].idx1 != skinNr){ //check if not already set,maybe save some gas
                  _owners[tokenID].idx1 =skinNr;
                }
            }
            //update color if you own it
            if ( isBitSet(_owners[tokenID].bitmap2,colorNr) == true ){
                if ( _owners[tokenID].idx2 != colorNr){ //check if not already set,maybe save some gas
                _owners[tokenID].idx2 = colorNr;
                }
            }
       }
    }
//OBI Mint
//=============================== 
    
    function mintWhitelist(uint256 _count, uint256 allowance, bytes32[] calldata proof) external nonReentrant {
        require(isMintPaused == 1, "OBI List Mint is not active");
        string memory payload = string(abi.encodePacked(_msgSender()));
        uint256 _totalSupply = totalSupply();
        require(_totalSupply + _count <= MAX_SUPPLY, "OBI: All OBIs have been minted.");
        require(_verify(_leaf(Strings.toString(allowance), payload), proof), "OBI:Your are not on the OBI List.");
        require(_count > 0 && _addressToMinted[_msgSender()] + _count <= allowance, "OBI:Exceeds OBIList supply"); 
        require(msg.sender == tx.origin);
        
        _addressToMinted[_msgSender()] += _count;

        for(uint i=0; i < _count; i++) { 
            _mint(_msgSender(), _totalSupply + i);
        }
    }
    
    //mint only 1 OBI per Wallet on Public Mint
    function mintPublic() external nonReentrant   {
        
        require(isMintPaused == 2, "OBI: Public Mint is not active");
        uint256 _totalSupply = totalSupply();
        require(_totalSupply + 1 <= MAX_SUPPLY, "OBI: All OBIs have been minted.");
        require(msg.sender == tx.origin); 
        
        uint256 _ownedCount = balanceOf(_msgSender());
        require(_ownedCount < ( _addressToMinted[_msgSender()]+ 1 ), "OBI: Exceeds max OBIs per wallet.");
             
        _mint(_msgSender(), _totalSupply);
        
    }

    //only allowed for OBI Founders to mint according to the FOUNDERS_RESERVE_AMOUNT
    //this supply will be allocated equaly to each OBI Founder
    //or some part of the supply will be used for giveaways
    function mintDev(uint256 tknQuantity)  external onlyOwner nonReentrant {
            require(tknQuantity <= FOUNDERS_RESERVE_AMOUNT, "OBI:more tokens requested than founders reserve");
            uint256 _totalSupply = totalSupply();
            FOUNDERS_RESERVE_AMOUNT -= tknQuantity;
            for(uint256 i=0; i < tknQuantity; i++)
                _mint(_msgSender(),_totalSupply + i);
    }

    
    //------------------------------------
    //The Mint and Morph can be called only by the owner of the token
    //------------------------------------
    
    //OBI 0 will be minted only by OBI Team.
    //And it is used to show case future skins and color palettes.
    function mintOBIZeroMorph() public onlyOwner {
            
            //update skin
            if ( isBitSet(_owners[0].bitmap1,globalConfig.skinIndex) == false ){
                _owners[0].cnt1 ++;
                _owners[0].bitmap1 = setBit(_owners[0].bitmap1, globalConfig.skinIndex);
            }
            _owners[0].idx1 = globalConfig.skinIndex;
            //update color 
            if ( isBitSet(_owners[0].bitmap1,globalConfig.colorIndex) == false ){
                _owners[0].cnt2 ++;
                _owners[0].bitmap2 = setBit(_owners[0].bitmap2, globalConfig.colorIndex);
            }
            _owners[0].idx2 = globalConfig.colorIndex;
    }
  
    //free Mint
    function mintFreeOBIMorph(uint256[] calldata tokenIdList) public  {
        require(msg.sender == tx.origin);
        require(morphMintPhase == 1, "OBI: Free OBI Morph is not active");

        _validateLightMorphList(tokenIdList);
        _updateMorphList(tokenIdList);
    }

    function mintFreeOBIListMorph(uint256[] calldata tokenIdList,bytes32[] calldata proof) public  {
        require(msg.sender == tx.origin);
        require(morphMintPhase == 2, "OBI: Free OBIList Morph is not active");
        bytes memory payload = abi.encodePacked(_msgSender());
        require(_verify(keccak256(payload), proof), "OBI: Your are not on the OBIList.");

        _validateLightMorphList(tokenIdList);
        _updateMorphList(tokenIdList);
    }

    function mintOBIMorph(uint256[] calldata tokenIdList) public payable  {
        require(msg.sender == tx.origin);
        require(morphMintPhase == 3, "OBI: OBI Morph is not active");
        require(tokenIdList.length * MORPH_MINT_PRICE == msg.value, "OBI: Invalid funds provided.");
         
         //avoid to pay in case Obi already minted 
        _validateMorphList(tokenIdList);    
        _updateMorphList(tokenIdList);
    }
    
    function mintOBIListMorph(uint256[] calldata tokenIdList,bytes32[] calldata proof) public payable  {
        require(msg.sender == tx.origin);
        require(morphMintPhase == 4, "OBI: OBILIST Morph is not active");
        require(tokenIdList.length * MORPH_MINT_PRICE == msg.value, "OBI: Invalid funds provided.");
        bytes memory payload = abi.encodePacked(_msgSender());
        require(_verify(keccak256(payload), proof), "OBI: Your are not on the OBIList.");
        
        //avoid to pay in case Obi already minted 
        _validateMorphList(tokenIdList);    
        _updateMorphList(tokenIdList);
    }
    
    //give a skin or pallete to a friend
    function mintGiveawayMorph(uint256[] calldata tokenIdList) public payable  {
        require(msg.sender == tx.origin);
        require(morphMintPhase == 5 , "OBI: OBI Giveaway Morph is not active");
        require(tokenIdList.length * MORPH_MINT_PRICE == msg.value, "OBI: Invalid funds provided.");
         
         //avoid to pay in case Obi already minted 
        for(uint256 id; id < tokenIdList.length; id++){
            uint256 tokenID = tokenIdList[id];
            require(tokenID < _owners.length, "OBI: invalid token id");

            bool hasSkin = isBitSet(_owners[tokenID].bitmap1,globalConfig.skinIndex);
            bool hasColor= isBitSet(_owners[tokenID].bitmap2,globalConfig.colorIndex);
            require( ( hasSkin == false) || (hasColor == false), "OBI: One of the OBI is already Morph Minted");
        }    
        
        for(uint256 id; id < tokenIdList.length; id++){
            uint256 tokenID = tokenIdList[id];
            //update skin if owner does not have it already
            if ( isBitSet(_owners[tokenID].bitmap1,globalConfig.skinIndex) == false ){
                _owners[tokenID].cnt1 ++;
                _owners[tokenID].bitmap1 = setBit(_owners[tokenID].bitmap1, globalConfig.skinIndex);
            }
            //update skin if owner does not have it already
            if ( isBitSet(_owners[tokenID].bitmap2,globalConfig.colorIndex) == false ){
                _owners[tokenID].cnt2 ++;
                _owners[tokenID].bitmap2 = setBit(_owners[tokenID].bitmap2, globalConfig.colorIndex);
            }
        }
    }

  //=============================== 
    receive() external payable {}
    
    function setupMorphMint(uint256 _price,address account1,address account2,uint256 percentage) public onlyOwner {
        obiAccount = account1;
        artistAccount = account2;
        artistPercentage = percentage;
        MORPH_MINT_PRICE = _price;
    }
    
    function getMorphMintConfig() public view onlyOwner returns (uint256,address,address,uint256){
        return (MORPH_MINT_PRICE,obiAccount,artistAccount,artistPercentage);
    }
    
    //function to return the price
    function getMintPrice() public view returns (uint256) {
        return MORPH_MINT_PRICE;
    }
   
    
    function withdrawAllAdmin() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function withdrawAll() public payable onlyOwner {
        uint256 totalBalance  = address(this).balance;
        uint256 _artistBalance = totalBalance * artistPercentage/100;
        uint256 _obiBalance = totalBalance - _artistBalance;
        require(payable(artistAccount).send(_artistBalance));
        require(payable(obiAccount).send(_obiBalance));
    }

//===============================   
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "OBI:URI query for nonexistent OBI.");
        if (_tokenIndexToAddress[_owners[_tokenId].idx1] == address(0)) {
            return '';
        }
        IMotherShip  motherShip = IMotherShip (_tokenIndexToAddress[_owners[_tokenId].idx1]);
        return motherShip.launchPad(_tokenId,_owners[_tokenId].idx1,_owners[_tokenId].idx2,_owners[_tokenId].cnt1,_owners[_tokenId].cnt2);     
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

//The ERC721OBI Contract is a modification of the ERC721 standard contract.
//Added features to the ERC721 contract :
//Support for upgradable and modular mint/render contracts
//Gas optimization for minting,skin mint,color pallets mint,color,pallets change

contract ERC721OBI is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    
   struct _contractStruct {
        uint8 idx1;
        uint8 idx2;
        uint8 cnt1;
        uint8 cnt2;
        uint32 bitmap1;
        uint32 bitmap2;
        address account;
    }
    
    string private _name;
    string private _symbol;

    

    //OBI: Mapping from token ID to owner address
    _contractStruct[] internal _owners;

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    // util
//===============================   

    function isBitSet( uint32 _packedBits,uint8 _bitPos) internal pure  returns (bool){
        uint32 flag = (_packedBits >> _bitPos) & uint32(1);
        return (flag == 1 ? true : false);
    }
    
    function setBit( uint32 _packedBits,uint8 _bitPos)  internal pure  returns (uint32){
        return _packedBits | uint32(1) << _bitPos;
    }

    function  countSetBits(uint32 _num)  internal pure  returns (uint32)
    {
     uint32 count = 0;
     while (_num > 0) {
            count = count + (_num & 1); // num&1 => it gives either 0 or 1
            _num = _num >> 1;	// bitwise rightshift 
        }
    return count;
}
    
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) 
        public 
        view 
        virtual 
        override 
        returns (uint) 
    {
        require(owner != address(0), "ERC721: balance query for the zero address");

        uint count;
        for( uint i; i < _owners.length; ++i ){
          if( owner == _owners[i].account )
            ++count;
        }
        return count;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId].account;
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

     /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721OBI.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < _owners.length && _owners[tokenId].account != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721OBI.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _contractStruct memory tokenData;
        tokenData.account = to;
        tokenData.idx1 = 0;
        tokenData.idx2 = 0;
        tokenData.bitmap1 = 1;
        tokenData.bitmap2 = 1;
        tokenData.cnt1 = 1;
        tokenData.cnt2 = 1;
        _owners.push(tokenData);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721OBI.ownerOf(tokenId);

        // Clear approvals
        _approve(address(0), tokenId);
        _owners[tokenId].account = address(0);
         delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721OBI.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _owners[tokenId].account = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721OBI.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}