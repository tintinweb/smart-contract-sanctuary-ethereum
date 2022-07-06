//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;

import "./ERC721.sol";
import "./m_.sol";
import "./metadataLib.sol";
import "./ERC721Holder.sol";

contract ChangeItem_3_BLACK_BAR is ERC721{
    address private owner = address(0x9B2f5909EC0F559dE12948E4cb963838C7bEeFf2);
    address private owner2 = address(0x5601613b1D2871ed28E3Af31AC9E41DC4A4e8016);
    address private owner3 = address(0x93f9A66023f5F79C81297A90d380ce78973EFc3B);

    address private wallet;
    address private account0;
    address private account1;
   // string baseURI = "";

    uint public price = 1 wei;
//metadata
    string tokenURIs ="https://ipfs.io/ipfs/QmTMCVxq2ZofyPAyjra8aKunTaG7AbtM5coSzZUMMXoKjE";
    string layerImage ="https://ipfs.io/ipfs/QmasnBGky4fiAHs7XA5ZDH3N6AZ7ehDMSirTB5KTmvp5nL";
    string property = "BLACK BAR";
    uint layer = 3;

   // mapping(uint => string)private tokenURIs;
    
    mapping(address => mapping(uint=>uint))public IDList;

    //mapping(uint => bool) public minted;
    mapping(address => uint)public haveTokens;

    uint256 mintedCount = 0;

    uint limit = 100;

    bool mintStarted = true;

    // //引き出し用許可リスト
    mapping(address => bool)private permission;

    modifier onlyOwner(){
        require( _msgSender() == owner  || _msgSender() == owner2 || _msgSender() == owner3 );
        _;
    } 

    m_0624 mainContract = m_0624(0xe98283d239d8857B5F5B151459023dd1Fe72D537);
    
    constructor() ERC721("CHANGEITEM_BLACK_BAR_3" , "CHANGEITEM_BLACK_BAR_3" ) {
    }

    function getLayerInfo()public view returns(uint,string memory , string memory){
        return (layer,property,layerImage);
    }

    function getPrice()public view returns(uint) {
        return price;
    }

    function getTokenID(uint _index,address _address)public view returns(uint){
        return IDList[_address][_index];
    }

    function mint(uint256 _tokenID) external payable{
        require(tx.origin == msg.sender, "The caller is another contract");
        require(mintStarted);
        require(_tokenID < limit);
        require(msg.value == getPrice());
        //require(minted[nftid] == false);
        _safeMint( _msgSender() , _tokenID);
        //minted[_tokenID] = true;
        // _setTokenURI( _tokenID , baseURI);
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

    function getHaveTokens(address _address)public view returns(uint){
        return haveTokens[_address];
    }

    function getMintedNFT()public view returns(uint256){
        return mintedCount;
    }

    // function _setTokenURI(uint _tokenID,string memory _uri)private{
    //     tokenURIs[_tokenID] = _uri;
    // }

    function tokenURI(uint256 _tokenID)public view override returns (string memory) {
        //return tokenURIs[_tokenID];
        return tokenURIs;
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

    function changeForm(uint _changeItemID,uint _id,string memory _imageIPFS,string memory _layerURIs) external{
        require( ownerOf(_changeItemID) == _msgSender() ,"owner");
        metadataLib.LayerInfo memory _layerInfo = mainContract.getImageInfo(_id);
        _layerInfo.Layer3 = property;
        _layerInfo.Image = _imageIPFS;
        mainContract.chengeForm(_id,_layerInfo,_layerURIs);
        _burn(_changeItemID);
    }
}