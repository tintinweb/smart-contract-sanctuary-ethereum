//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;


import "./ERC721.sol";
import "./metadataLib.sol";
import "./ERC721Holder.sol";

contract m_0530 is ERC721{
    address private owner = address(0x9B2f5909EC0F559dE12948E4cb963838C7bEeFf2);
    address private owner2 = address(0x5601613b1D2871ed28E3Af31AC9E41DC4A4e8016);
    address private owner3 = address(0x93f9A66023f5F79C81297A90d380ce78973EFc3B);

    address private wallet;
    address private account0;
    address private account1;
   // string baseURI = "";

    uint public price = 1 wei;

//metadata
    string private description = "descriptiondescriptiondescription";
    string private tokenName = "n";

    mapping(uint => metadataLib.LayerInfo) ImageLayers;

    mapping(string => bool)isExist;
    mapping(string => uint)IDofTheCombination;

    mapping(uint => bool) public minted;
    mapping(address => uint)public haveTokens;

    mapping(address => bool)private ItemList;
    bool UseItemList = true;
    mapping(address => bool)private interfaceList;

    uint256 mintedCount = 0;

    //引き出し用許可リスト
    mapping(address => bool)private permission;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier allowedInterfaceContract(){
        require(interfaceList[msg.sender],"not allowed address");
        _;
    }

    modifier onlyOwner(){
        require( _msgSender() == owner  || _msgSender() == owner2 || _msgSender() == owner3 );
        _;
    } 

    event transactionReceived(string _message);
    event mintEvent(string _message);
    
    constructor() ERC721("m_0530" , "m_0530" ) {

    }

   //function _inMint(address _sender,metadataLib.LayerInfo memory _imageInfo)public allowedInterfaceContract returns(bool){
    function _inMint(address _sender,string memory _Layer1,string memory _Layer2,string memory _Layer3,string memory _Layer4,string memory _Layer5,string memory _Layer6,string memory _Layer7,string memory _Layer8,string memory _Image)public allowedInterfaceContract{
        emit transactionReceived("received");
        string memory _layerInfo= string(abi.encodePacked(_Layer3,_Layer6,_Layer7,_Layer8) );
        metadataLib.LayerInfo memory _imageInfo = metadataLib.LayerInfo(_Layer1,_Layer2,_Layer3,_Layer4,_Layer5,_Layer6,_Layer7,_Layer8,_Image);
        require(!isExist[_layerInfo]);
        uint256 tokenID = mintedCount;
        emit mintEvent("mint");
       // _mint(_sender, tokenID);
        _setTokenURI( tokenID,_imageInfo );
        minted[tokenID] = true;
        haveTokens[_sender]++;
        mintedCount++;
       // periodOfContinuedPossession[_tokenID] = block.timestamp;
    }

    function manageInterfaceList(address _address,bool _state)public onlyOwner{
        interfaceList[_address] = _state;
    }

    function getIsMinted(uint256 _id) public view returns(bool){
        return minted[_id];
    }

    function getHaveTokens(address _address)public view returns(uint){
        return haveTokens[_address];
    }

    function getMintedNFT()public view returns(uint256){
        return mintedCount;
    }

    function getIDFromCombination(string memory _combination)public view returns(uint){
        return IDofTheCombination[_combination];
    }

    function setTokenURI(uint256 _tokenID,string memory _imageIPFS ,string memory _Layer1,string memory _Layer2,string memory _Layer3,string memory _Layer4,string memory _Layer5,string memory _Layer6,string memory _Layer7,string memory _Layer8 ) public onlyOwner callerIsUser{
        require(minted[_tokenID]);
        metadataLib.changeMetadataStruct memory _changeMetadataStruct = metadataLib._setTokenMetadata_Exist(ImageLayers[_tokenID], metadataLib.LayerInfo(_Layer1,_Layer2,_Layer3,_Layer4,_Layer5,_Layer6,_Layer7,_Layer8,_imageIPFS) );

        isExist[_changeMetadataStruct.old] = false;
        isExist[_changeMetadataStruct.changed] = true;
        IDofTheCombination[_changeMetadataStruct.old] = 0;
        IDofTheCombination[_changeMetadataStruct.changed] = _tokenID;
        ImageLayers[_tokenID] = metadataLib.LayerInfo(_Layer1,_Layer2,_Layer3,_Layer4,_Layer5,_Layer6,_Layer7,_Layer8,_imageIPFS);
    }
//metadataLib.LayerInfo(_Layer1,_Layer2,_Layer3,_Layer4,_Layer5,_Layer6,_Layer7,_Layer8)
    function _setTokenURI( uint256 _tokenID ,metadataLib.LayerInfo memory _layerInfo ) private {
        require(minted[_tokenID]);
        metadataLib.changeMetadataStruct memory _changeMetadataStruct = metadataLib._setTokenMetadata_Exist(ImageLayers[_tokenID],_layerInfo);
        isExist[_changeMetadataStruct.old] = false;
        isExist[_changeMetadataStruct.changed] = true;
        IDofTheCombination[_changeMetadataStruct.old] = 0;
        IDofTheCombination[_changeMetadataStruct.changed] = _tokenID;
        ImageLayers[_tokenID] = _layerInfo;
    }


    function tokenURI(uint256 _tokenID)public view override returns (string memory) {
        return metadataLib._tokenMetadata(_tokenID,tokenName,description,ImageLayers[_tokenID]);
    }


    function getIsExist(string memory _onlyLayerInfo)public view returns(bool){
        return isExist[_onlyLayerInfo];
    }

    function manageItemList(address _address,bool _state)public onlyOwner{
        ItemList[_address] = _state;
    }

    function getItemState(address _stoneAddress)public view returns(bool){
        return ItemList[_stoneAddress];
    }

    function useItemList(bool _state)public onlyOwner{
        UseItemList = _state;
    }
    

    // 仮実装
    //リスト内のみ許可→リスト外も許可を切り替えられるように
    //アイテムの変更は一か所まで
    function chengeForm(address _sender,uint _id,string memory _imageIPFS,string memory _Layer1,string memory _Layer2,string memory _Layer3,string memory _Layer4,string memory _Layer5,string memory _Layer6,string memory _Layer7,string memory _Layer8) external{
        require(ItemList[msg.sender] || !UseItemList,"not allowed address");
        require(ownerOf(_id) == _sender);
        //ishiの戻り値を利用してそのままsetTokenURIを行う
        _setTokenURI( _id,metadataLib.LayerInfo(_Layer1,_Layer2,_Layer3,_Layer4,_Layer5,_Layer6,_Layer7,_Layer8,_imageIPFS) );
    }
}