//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;


import "./ERC721.sol";
import "./metadataLib.sol";
import "./ERC721Holder.sol";

contract m_06122046 is ERC721{
    address private owner = address(0x9B2f5909EC0F559dE12948E4cb963838C7bEeFf2);
    address private owner2 = address(0x5601613b1D2871ed28E3Af31AC9E41DC4A4e8016);
    address private owner3 = address(0x93f9A66023f5F79C81297A90d380ce78973EFc3B);
   // string baseURI = "";
    uint public price = 1 wei;

//metadata
    string private description = "descriptiondescriptiondescription";
    string private tokenName   = "n";

    mapping(uint => metadataLib.LayerInfo) ImageLayers;

    // mapping(string => bool)isExist;
    mapping(string => uint)IDofTheCombination;

    mapping(uint => bool) public minted;
    mapping(address => uint)public haveTokens;
    mapping(address => mapping(uint=>uint))public IDList;
    mapping(address => bool)private ItemList;
    bool UseItemList = true;
    mapping(address => bool)private interfaceList;

    //layer別URImap
    mapping(uint => string)private layerURIs;

    uint256 mintedCount = 0;
    
    //引き出し用許可リスト
    mapping(address => bool)private permission;

    modifier onlyOwner(){
        require( _msgSender() == owner  || _msgSender() == owner2 || _msgSender() == owner3 );
        _;
    } 
    
    constructor() ERC721("m_06122046" , "m_06122046" ) {
    }
    
    function _inMint(address _sender,metadataLib.LayerInfo memory _imageInfo ,string memory _layerURIs)
    public
    {
        require(interfaceList[msg.sender],"not allowed address");
        //string memory _layerInfo= string(abi.encodePacked(_Layer3,_Layer6,_Layer7,_Layer8) );
        _mint(_sender, mintedCount);
        minted[mintedCount] = true;
        //metadataLib.LayerInfo memory imageInfo = metadataLib.LayerInfo(_Layer1,_Layer2,_Layer3,_Layer4,_Layer5,_Layer6,_Layer7,_Layer8,_Image);
        layerURIs[mintedCount] = _layerURIs;
        _setTokenURI( mintedCount,_imageInfo );
        mintedCount++;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override{
        if(from != address(0))
        {
            IDList[from][haveTokens[from]] = 0;
            haveTokens[from]--;
        }
        if(to != address(0))
        {        
            haveTokens[to]++;
            IDList[to][haveTokens[to]] = tokenId;
        }
    }

    function getLayerURI(uint _tokenId)public view returns(string memory){
        return layerURIs[_tokenId];
    }

//tokenIDが0じゃなくなるまで回せば取得できる
    function getTokenID(uint _index,address _address)public view returns(uint){
        return (IDList[_address][_index]);
    }

    function manageInterfaceList(address _address,bool _state)public onlyOwner{
        interfaceList[_address] = _state;
    }

    function getMintedNFT()public view returns(uint256){
        return mintedCount;
    }

    function getIDFromCombination(string memory _combination)public view returns(uint){
        return IDofTheCombination[_combination];
    }

    function setTokenURI(uint256 _tokenID,string memory _imageIPFS ,string memory _Layer1,string memory _Layer2,string memory _Layer3,string memory _Layer4,string memory _Layer5,string memory _Layer6,string memory _Layer7,string memory _Layer8 ) public onlyOwner{
        require(tx.origin == msg.sender, "The caller is another contract");
        _setTokenURI(_tokenID ,metadataLib.LayerInfo(_Layer1,_Layer2,_Layer3,_Layer4,_Layer5,_Layer6,_Layer7,_Layer8,_imageIPFS) );
    }

    function _setTokenURI( uint256 _tokenID ,metadataLib.LayerInfo memory _layerInfo ) private {
        require(minted[_tokenID]);
        metadataLib.changeMetadataStruct memory _changeMetadataStruct = metadataLib._setTokenMetadata_Exist(ImageLayers[_tokenID],_layerInfo);
        // isExist[_changeMetadataStruct.old] = false;
        // isExist[_changeMetadataStruct.changed] = true;
        IDofTheCombination[_changeMetadataStruct.old] = 0;
        IDofTheCombination[_changeMetadataStruct.changed] = _tokenID+1;
        ImageLayers[_tokenID] = _layerInfo;
    }

    function tokenURI(uint256 _tokenID)public view override returns (string memory) {
        return metadataLib._tokenMetadata(_tokenID,tokenName,description,ImageLayers[_tokenID]);
    }

    // function getIsExist(string memory _onlyLayerInfo)public view returns(bool){
    //     return isExist[_onlyLayerInfo];
    // }

    function manageItemList(address _address,bool _state)public onlyOwner{
        ItemList[_address] = _state;
    }

    function getItemState(address _itemAddress)public view returns(bool){
        return ItemList[_itemAddress] || !UseItemList;
    }

    function useItemList(bool _state)public onlyOwner{
        UseItemList = _state;
    }

    function getImageInfo(uint _id )public view returns(metadataLib.LayerInfo memory) {
        return ImageLayers[_id] ;
    }

    function chengeForm(uint _id,metadataLib.LayerInfo memory _layerInfo,string memory _layerURIs) external{
        require(ItemList[_msgSender()] || !UseItemList);
        require(ownerOf(_id) == tx.origin);
        ImageLayers[_id] = _layerInfo;
        layerURIs[_id] = _layerURIs;
    }
}