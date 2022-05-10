pragma solidity>0.8.0;//SPDX-License-Identifier:None
/*
Only getting the essentials
*/
interface IERC721{
    function ownerOf(uint256 tokenId)external view returns(address owner);
    function getApproved(uint256 tokenId)external view returns(address operator);
    function transferFrom(address from,address to,uint256 tokenId)external;
    function tokenURI(uint256 tokenId)external view returns(string memory);
}
contract agora{
    struct List{
        address contractAddr;
        uint tokenId;
        uint price;
    }
    mapping(uint=>List)public list;
    mapping(address=>mapping(uint=>address))public existed;
    address private _admin;
    uint public Listed;
    uint public Sold;
    constructor(){
        _admin=msg.sender;
    }
    /*  Listing the nft into our marketplace.
        Using Listed to keep track of the number of nfts
        Only approved, owner and not existed able to proceed  */
    function Sell(address _contractAddr,uint _tokenId,uint _price)external{unchecked{
        require(IERC721(_contractAddr).getApproved(_tokenId)==address(this));
        require(IERC721(_contractAddr).ownerOf(_tokenId)==msg.sender);
        require(existed[_contractAddr][_tokenId]!=msg.sender);
        (list[Listed].contractAddr,list[Listed].tokenId,list[Listed].price)=(_contractAddr,_tokenId,_price);
        existed[_contractAddr][_tokenId]=msg.sender;
        Listed++;
    }}
    /*  As long as the price is right, this transaction will go through
        Have to transfer to contract first before executing another transfer out
        Pay previous owner and 1% to admin
    */
    function Buy(uint _id)external payable{unchecked{
        (uint _tokenId,uint _price)=(list[_id].tokenId,list[_id].price);
        require(msg.value>=_price);
        address _ca=list[_id].contractAddr;
        address _previousOwner=IERC721(_ca).ownerOf(_tokenId);
        IERC721(_ca).transferFrom(_previousOwner,address(this),_tokenId);
        IERC721(_ca).transferFrom(address(this),msg.sender,_tokenId);
        (bool s,)=payable(payable(_previousOwner)).call{value:_price*99/100}("");
        (s,)=payable(payable(_admin)).call{value:_price*99/100}("");
        Sold++;
        delete existed[_ca][_tokenId];
        delete list[_id];
    }}
    /*  Only show the batch number of nfts e.g. 20 per page to prevent overloading
        Usng while loop to get the batch number and break at 0
        Skip listing that no longer have allowance to us
    */
    function Show(uint batch, uint offset)external view returns(
      string[]memory tu,uint[]memory price,uint[]memory listId){unchecked{
        (tu,price,listId) = (new string[](batch),new uint[](batch),new uint[](batch));
        uint b;
        uint i=Listed-offset;
        while (b<batch&&i>0){
            uint j=i-1;
            if(IERC721(list[j].contractAddr).getApproved(list[j].tokenId)==address(this)){
                (tu[b],price[b],listId[b])=
                (IERC721(list[j].contractAddr).tokenURI(list[j].tokenId),list[j].price,list[j].tokenId);
                b++;
            }
            i--;
        }
    }}
}