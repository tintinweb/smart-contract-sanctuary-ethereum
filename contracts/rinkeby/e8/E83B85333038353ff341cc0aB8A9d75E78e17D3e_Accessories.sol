// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;


import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./ERC1155URIStorage.sol";


contract Accessories is Ownable,Pausable,ERC1155,ERC1155URIStorage,ERC1155Supply{

 
    mapping(uint256 => string)  public asset;
    mapping(uint256 => uint256) public AssetPrice;

    uint assetId;
    uint assetpid;
       
    constructor() ERC1155("[email protected]{id}.json") {

        Feereceiver=msg.sender;
        excludedList[msg.sender] = true; 
        asset[0] = "candle";   
        asset[1] = "coldrink";  
        asset[2] = "flower";   
        assetId = 3;
        AssetPrice[0]=10000000000000;
        AssetPrice[1]=10000000000000;
        AssetPrice[2]=10000000000000;
        assetpid=3;

    }


    // anyone can mint the ids by selecting the id and amount to be mint
    
    function mint(uint256 _amount,uint256 id,string memory _uri) public payable whenNotPaused{

        require(id <= assetId,"invalid id!");
        require(msg.value >= AssetPrice[id],"Not Enough Balance");
        _mint(msg.sender,id,_amount,"");
        _setTokenURI(id, _uri);

    }


    //  owner can register new  ids
    function registerIDs(string memory name,uint256 price) public onlyOwner whenNotPaused{

        asset[assetId]=name;
        AssetPrice[assetpid]=price;
        assetId++;
        assetpid;        
    }
    
    // owner can updates the price for each id
    function changePice(uint256 id,uint256 price) public onlyOwner whenNotPaused{
        AssetPrice[id]=price;
    }

    // owner can pause the contract
    function pause() public onlyOwner whenNotPaused{
        _pause();
    }

    // Owner can unpause the contract

    function unpause() public onlyOwner whenPaused{
        _unpause();
    }

   
//    owner can batch mint the ids

    function mintBatch(address to, uint256[] memory ids,string[] memory _uri,uint256[] memory amounts, bytes memory data)
        public
        onlyOwner whenNotPaused
    {
        _mintBatch(to, ids, amounts, data);
       for(uint i = 0; i < ids.length; i++){
            _setTokenURI(ids[i], _uri[i]);
        }

    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    
    // give the metadata of token ids
    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function setTokenUri(uint256 _tokenId, string calldata _uri) external onlyOwner{
        _setTokenURI(_tokenId, _uri);
    }

    // owner can set the royality fee 
    function setRoyalityfee(uint256 _fee) public onlyOwner whenNotPaused{
        royalityfee=_fee;
    }

    // owner can updates the royality fee receiver address
    function updatefeereceiver(address _addr) public onlyOwner whenNotPaused{
        Feereceiver=_addr;
    }

    // artist can exclude the accounts from royality fee payer list

    function setExcluded(address excluded, bool status) external whenNotPaused{
    excludedList[excluded] = status;
  }

    // owner can withdraw ether stored on the contract

      function Withdraw() public onlyOwner whenNotPaused{
     require(address(this).balance > 0,"Balance is Zero");
      payable(owner()).transfer(address(this).balance);

    }

}