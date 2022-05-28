//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;


import "./ERC721.sol";
import "./metadataLib.sol";

contract m_0528 is ERC721{
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
    mapping(uint => string) ImageIPFS;

    mapping(uint => bool) public minted;
    mapping(address => uint)public haveTokens;

    mapping(address => bool)private allowStoneList;
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
    
    constructor() ERC721("n_0528" , "n_0528" ) {

        wallet = address(0x779B9947266ab8515CEd43b2e509122f00c59309);
        //awai san wallet
        account0 = address(0x9B2f5909EC0F559dE12948E4cb963838C7bEeFf2);
        //tonoshake_test mainno
        account1 = address(0x5601613b1D2871ed28E3Af31AC9E41DC4A4e8016);
    }

    function _inMint(address _sender,string memory _imageIPFS ,string memory _Layer1,string memory _Layer2,string memory _Layer3,string memory _Layer4,string memory _Layer5,string memory _Layer6,string memory _Layer7,string memory _Layer8)public allowedInterfaceContract returns(bool){
        string memory _layerInfo= string(abi.encodePacked(_Layer1,_Layer2,_Layer3,_Layer4,_Layer5,_Layer6,_Layer7,_Layer8) );
        require(isExist[_layerInfo] = false);
        // require(_tokenID < max);
        // require(_tokenID >= min);
        // require(msg.value == allowlistPrice_public );
        metadataLib.LayerInfo memory _metadataStruct = metadataLib.LayerInfo(_Layer1,_Layer2,_Layer3,_Layer4,_Layer5,_Layer6,_Layer7,_Layer8);
        
        uint256 tokenID = mintedCount;
        _safeMint( _msgSender() , tokenID);
        _setTokenURI( tokenID,_imageIPFS,_metadataStruct );
        minted[tokenID] = true;
        haveTokens[_sender]++;
        mintedCount++;

        return true;
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

    function setTokenURI(uint256 _tokenID,string memory _imageIPFS ,string memory _Layer1,string memory _Layer2,string memory _Layer3,string memory _Layer4,string memory _Layer5,string memory _Layer6,string memory _Layer7,string memory _Layer8 ) public onlyOwner callerIsUser{
        require(minted[_tokenID]);
        metadataLib.changeMetadataStruct memory _changeMetadataStruct = metadataLib._setTokenMetadata_Exist(ImageLayers[_tokenID], metadataLib.LayerInfo(_Layer1,_Layer2,_Layer3,_Layer4,_Layer5,_Layer6,_Layer7,_Layer8) );

        isExist[_changeMetadataStruct.old] = false;
        isExist[_changeMetadataStruct.changed] = true;
        ImageLayers[_tokenID] = metadataLib.LayerInfo(_Layer1,_Layer2,_Layer3,_Layer4,_Layer5,_Layer6,_Layer7,_Layer8);
        ImageIPFS[_tokenID] = _imageIPFS;
    }
//metadataLib.LayerInfo(_Layer1,_Layer2,_Layer3,_Layer4,_Layer5,_Layer6,_Layer7,_Layer8)
    function _setTokenURI( uint256 _tokenID,string memory _imageIPFS ,metadataLib.LayerInfo memory _layerInfo ) private {
        require(minted[_tokenID]);
        metadataLib.changeMetadataStruct memory _changeMetadataStruct = metadataLib._setTokenMetadata_Exist(ImageLayers[_tokenID],_layerInfo);
        isExist[_changeMetadataStruct.old] = false;
        isExist[_changeMetadataStruct.changed] = true;
        ImageLayers[_tokenID] = _layerInfo;
        ImageIPFS[_tokenID] = _imageIPFS;
    }


    function tokenURI(uint256 _tokenID)public view override returns (string memory) {
        return metadataLib._tokenMetadata(_tokenID,tokenName,description,ImageIPFS[_tokenID],ImageLayers[_tokenID]);
    }

    function getPrice() public view returns(uint){
        return price;
    }

    function setPrice(uint _price) public onlyOwner{
        price = _price;
    }

    function getIsExist(string memory _onlyLayerInfo)public view returns(bool){
        return isExist[_onlyLayerInfo];
    }

    function permitWithDraw()public{
        require(_msgSender() == account0 || _msgSender() == account1);
        permission[msg.sender] = true;
    }

    function withDraw() public onlyOwner{
        require(permission[account0] == true);
        require(permission[account1] == true);
        uint balance = address(this).balance;
        payable(wallet).transfer(balance);
        permission[account0] = false;
        permission[account1] = false;
    }

    function manageStoneList(address _address,bool _state)public onlyOwner{
        allowStoneList[_address] = _state;
    }

    function getAllowStone(address _stoneAddress)public view returns(bool){
        return allowStoneList[_stoneAddress];
    }

    // 仮実装
    function chengeForm(address _sender,uint _id,string memory _imageIPFS,string memory _Layer1,string memory _Layer2,string memory _Layer3,string memory _Layer4,string memory _Layer5,string memory _Layer6,string memory _Layer7,string memory _Layer8) external{
        require(allowStoneList[msg.sender],"not allowed address");
        require(ownerOf(_id) == _sender);
        //ishiの戻り値を利用してそのままsetTokenURIを行う
        _setTokenURI( _id,_imageIPFS,metadataLib.LayerInfo(_Layer1,_Layer2,_Layer3,_Layer4,_Layer5,_Layer6,_Layer7,_Layer8) );
    }
}