// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "./ERC721.sol";
import "./m_.sol";
import "./strings_.sol";
import "./str_uint_convert.sol";
import "./metadataLib.sol";
import "./ERC721Holder.sol";
//import "./metadataLib.sol";
contract interface_06122046 is ERC721{
    using strings for *;

    address private owner  = address(0x9B2f5909EC0F559dE12948E4cb963838C7bEeFf2);
    address private owner2 = address(0x5601613b1D2871ed28E3Af31AC9E41DC4A4e8016);
    address private owner3 = address(0x93f9A66023f5F79C81297A90d380ce78973EFc3B);

    address private wallet;
    address private account0;
    address private account1;

    mapping(address=>bool)private mintableList;
   // string baseURI = "";

    uint public price = 1 wei;

    //metadata
    string private description = "descriptiondescriptiondescription";
    string private tokenName = "n";
    string private delimSTR = "24519134421";

    //mapping(uint => metadataLib.LayerInfo) ImageLayers;
    mapping(bytes => bool)isExist;
    mapping(uint => string) ImageIPFS;
    
    mapping(uint256 => mapping(uint256 => string))private uintTo_StringNumToStringLayerName;
    mapping(uint256 => uint) layerCount;

    //for allow list
    //ID->mintable counts
    struct allowlistElement{
        uint remaining;
        uint price;
    }

    bool private mintStarted = true;
    bool private allowlistMintStarted = true;
    mapping(address => allowlistElement)public allowlist;
    
    //miss count
    mapping(address => uint)private missList;

    uint256 mintedCount = 0;
    uint256 limit = 100;
    
    mapping(address => bool)private permission;

    // modifier callerIsUser() {
    //     require(tx.origin == msg.sender, "The caller is another contract");
    //     _;
    // }

    modifier onlyOwner(){
        require( _msgSender() == owner  || _msgSender() == owner2 || _msgSender() == owner3 );
        _;
    } 

    event transactionSend(string _message);

    m_06122046 mainContract = m_06122046(0x8565DDf9a1f63c17730B19C084E44A0f0D5a6E5B);
    
    constructor() ERC721("interface_06122046" , "interface_06122046" ) {
        
        wallet = address(0x779B9947266ab8515CEd43b2e509122f00c59309);
        //awai san wallet
        account0 = address(0x9B2f5909EC0F559dE12948E4cb963838C7bEeFf2);
        //tonoshake_test mainno
        account1 = address(0x5601613b1D2871ed28E3Af31AC9E41DC4A4e8016);
    }

    // function setMainContruct(address _address)public onlyOwner{
    //     mainContract = m_06081839(_address);
    // }

    function setDelim(string memory _delim)public onlyOwner{
        delimSTR = _delim;
    }

    function addLayers(string memory _layerInfo)public onlyOwner{
        strings.slice memory s = _layerInfo.toSlice();
        //strings.slice[] memory parts = new strings.slice[](s.count(":".toSlice()) +1 );
        strings.slice memory part;
        string[] memory layer = new string[](2);
        uint counts = s.count(":".toSlice()) + 1;
        for (uint i = 0; i <  counts ; i++) {
            part = s.split( ":".toSlice() );
            for(uint h = 0 ; h < 2 ; h++)
            {
                layer[h] = part.split( "/".toSlice() ).toString();
            }
            uintTo_StringNumToStringLayerName[su.str2uint(layer[0])][layerCount[su.str2uint(layer[0])]] = layer[1];
            layerCount[su.str2uint(layer[0])]++;
        }
    }

    function getLayersInfo(uint256 _layer)public view returns(string memory,uint){
        string memory out = "";
        for(uint i = 0;i<layerCount[_layer];i++){
            out = out.toSlice().concat(su.uint2str(i).toSlice()).toSlice().concat(":".toSlice()).toSlice().concat(uintTo_StringNumToStringLayerName[_layer][i].toSlice()).toSlice().concat("|".toSlice()) ;
            //out = out.toSlice().concat(uint2str(i).toSlice());
        }
        return (out,layerCount[_layer]);
    }

    // function getLayerInfo(uint256 _layer,uint256 _index)public view returns(string memory){
    //     return uintTo_StringNumToStringLayerName[_layer][_index];
    // }

    function getExist(string memory _layerInfo)public view returns(bool){
        return (mainContract.getIDFromCombination(_layerInfo) < 1);
    }

    function getIDFromCombination_1Added(string memory _layerInfo)public view returns(uint){
        return mainContract.getIDFromCombination(_layerInfo);
    }

    function setLimit(uint256 _limit)public onlyOwner{
        limit = _limit;
        mintedCount = 0;
    }

    function getlimitInfo()public view returns(uint256,uint256){
        return (mintedCount,limit);
    }

    function getMintStarted_public_allowlist()public view returns(bool,bool){
        return (mintStarted,allowlistMintStarted);
    }

    // function getAllowlistMintStarted()public view returns(bool){
    //     return allowlistMintStarted;
    // }

    function getPrice()public view returns(uint){
        return price;
    }

    function getMissList(address _address)public view returns(uint){
        return missList[_address];
    }

    function sendMint(string memory _layerInfo,string memory _onlyLayerInfo,string memory _imageIPFS,string memory _LayersIPFS)public payable {
        //m_ mainContract = m_(0x2711334f66F9F075028727793EA17c6fFe5FAF7C);
        require(mintedCount < limit,"limit");
        require(!getExist(_onlyLayerInfo),"Exist");
        require(missList[_msgSender()] < 1,"miss");
        {
            uint256 in_price = price;
            if( allowlistMintStarted && allowlist[_msgSender()].remaining > 0){
                in_price = allowlist[_msgSender()].price;
            }
            require((allowlistMintStarted && allowlist[_msgSender()].remaining > 0) || mintStarted,"mintable");
            require(msg.value == in_price,"price");
        }
        metadataLib.LayerInfo memory imageInfo;
        //24519134421 区切り文字
        {
            string[] memory parts = new string[](_layerInfo.toSlice().count(delimSTR.toSlice()) +1 );
            strings.slice memory slice_info = _layerInfo.toSlice();
            string memory part ="";
            //layer 1~ 8 + imageipfs= 9
            require(parts.length == 8,"length");
            for (uint i = 0; i < 8 ; i++) {
                part = slice_info.split( delimSTR.toSlice() ).toString();
                parts[i] = uintTo_StringNumToStringLayerName[i+1][su.str2uint(part)];
                //mapping string の初期値は""
                if(strings.equals( parts[i].toSlice() ,"".toSlice() )){
                    missList[_msgSender()]++;
                    require(false,string(abi.encodePacked("check",su.uint2str(i),parts[i] )) );
                }
            }
            imageInfo = metadataLib.LayerInfo(
                parts[0],parts[1],parts[2],parts[3],parts[4],parts[5],parts[6],parts[7],_imageIPFS
                );
            require(!getExist(string(abi.encodePacked(parts[2],parts[5],parts[6],parts[7]) )),"parts" );
        }
        {
            if(allowlistMintStarted && allowlist[msg.sender].remaining > 0 ){
                allowlist[_msgSender()].remaining--;
            }
            mintedCount++;
            //mainContract._inMint(msg.sender,imageInfo) ;
            //emit transactionSend("send");
            mainContract._inMint(_msgSender(),metadataLib.LayerInfo( imageInfo.Layer1,imageInfo.Layer2,imageInfo.Layer3,imageInfo.Layer4,imageInfo.Layer5,imageInfo.Layer6,imageInfo.Layer7,imageInfo.Layer8,imageInfo.Image),_LayersIPFS ) ;
        }
    }

    // function test(string memory _layerInfo)public view returns(string memory,string memory)
    // {
    //     string memory out ="";
    //     string memory uint_string = "";
    //     {
    //         metadataLib.LayerInfo memory imageInfo;
    //         //24519134421 区切り文字
    //         {
    //             string[] memory parts = new string[](_layerInfo.toSlice().count(delimSTR.toSlice()) +1 );
    //             strings.slice memory slice_info = _layerInfo.toSlice();
    //             strings.slice memory delimSlice = delimSTR.toSlice();
    //             string memory part ="";
    //             //layer 1~ 8 + imageipfs= 9
    //             require(parts.length == 8,"length");
    //             for (uint i = 0; i < 8 ; i++) {
    //                 part = slice_info.split( delimSlice ).toString();
    //                 uint_string = string(abi.encodePacked(uint_string,"_",part));
    //                 parts[i] = uintTo_StringNumToStringLayerName[i+1][su.str2uint(part)];
    //                 out = string(abi.encodePacked(out,"|",parts[i]) );
    //                 //mapping string の初期値は""
    //                 if(strings.equals( parts[i].toSlice() ,"".toSlice() )){
    //                     require(false,string(abi.encodePacked("check",su.uint2str(i),parts[i] )) );
    //                 }
    //             }
    //             imageInfo = metadataLib.LayerInfo(
    //                 parts[0],parts[1],parts[2],parts[3],parts[4],parts[5],parts[6],parts[7],"null"
    //                 );
    //         }
    //     }
    //     return (string(abi.encodePacked("mint Completed","|",out)) , uint_string );
    // }

    function addAllowlist(address _address , uint256 _mintableCount,uint _price)public  onlyOwner{
        allowlist[_address] = allowlistElement(_mintableCount,_price);
    }
    
    function removeAllowlist(address _address)public onlyOwner{
        allowlist[_address].remaining = 0;
        allowlist[_address].price = price;
    }

    function getAllowListInfo(address _address)public view returns(uint,uint){
        return (allowlist[_address].remaining,allowlist[_address].price );
    }
    
    function mintManage(bool _mintStarted)public onlyOwner{
        mintStarted = _mintStarted;
    }

    function allowlistMintManage(bool _mintStarted)public onlyOwner{
        allowlistMintStarted = _mintStarted;
    }

    function manageMissList(address _address,uint256 _count)public onlyOwner{
        missList[_address] = _count;
    }

    function permitWithDraw()public{
        require(_msgSender() == account0 || _msgSender() == account1);
        permission[_msgSender()] = true;
    }

    function withDraw() public onlyOwner{
        require(permission[account0]&&permission[account1]);
        payable(wallet).transfer(address(this).balance);
        permission[account0] = false;
        permission[account1] = false;
    }
}