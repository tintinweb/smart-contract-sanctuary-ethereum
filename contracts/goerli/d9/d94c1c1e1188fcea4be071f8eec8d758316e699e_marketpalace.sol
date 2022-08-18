/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// this contract can be use only for a specific NFT contract
contract marketpalace {

    address public immutable contractAddress;

    struct tokenDetails {
        address owner; // owner of token
        uint256 saleAmount; // amount set for sale
        address salerAddress; // address from which it has set for sale
    }

    //       tokenid to struct
    mapping (uint256 => tokenDetails) _saleToken;

    uint256 public TokensForSale; // default 0

    constructor(address _contractAddress){
        contractAddress = _contractAddress; // set contract address
    }

    // modifier to check token is for sale or not
    modifier isForSale(uint _tokenid){
        require(_saleToken[_tokenid].owner != address(0),"token is not for sale");
        _;
    }

    function _setForSale(uint _tokenId, uint amount) internal {
        require(_saleToken[_tokenId].owner == address(0),"already for sale");
        (bool success1, bytes memory data1) = contractAddress.call(abi.encodeWithSignature("ownerOf(uint256)",_tokenId));
        require(success1,"owner check : failed");
        address _owner = abi.decode(data1, (address));
        if(_owner != msg.sender){
            (bool success2, bytes memory data2) = contractAddress.call(abi.encodeWithSignature("isApprovedForAll(address,address)",_owner,msg.sender));
            require(success2,"approve for all : failed");
            bool check = abi.decode(data2,(bool));
            require(check,"sender is nor owner or approvedForAll !");
        }
        (bool success3, bytes memory data3) = contractAddress.call(abi.encodeWithSignature("getApproved(uint256)",_tokenId));
        require(success3,"check approve : failed");
        address approveAdd = abi.decode(data3,(address));
        require(address(this) == approveAdd,"Please approve the address of this contract");
        _saleToken[_tokenId].owner = _owner;
        _saleToken[_tokenId].saleAmount = amount;
        _saleToken[_tokenId].salerAddress = msg.sender;
        TokensForSale++;
    }

    function setForSale(uint _tokenId, uint amount) external returns(bool) {
        _setForSale(_tokenId, amount);
        return true;
    }

    // check token is for sale
    function saleTokenAmount(uint _tokenId) public view  isForSale(_tokenId) returns(uint256 saleAmount){
       saleAmount = _saleToken[_tokenId].saleAmount;
    }

    // remove token from sale
    function removeFromSale(uint256 _tokenId) external isForSale(_tokenId) returns(bool){
        require(msg.sender == _saleToken[_tokenId].owner || msg.sender == _saleToken[_tokenId].salerAddress,"sender is nor owner or approvedForAll !");
        delete _saleToken[_tokenId];
        TokensForSale--;
        return true;
    }

    // buy token which is for sale
    function BuyToken(uint256 _tokenId) external payable isForSale(_tokenId) returns(bool){
        address sender = msg.sender;
        require(msg.value >= saleTokenAmount(_tokenId),"insufficient amount");
        (bool success, ) = contractAddress.call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)",_saleToken[_tokenId].owner,sender,_tokenId));
        require(success,"Buy Token : SafeTransfer Call : failed");
        (bool success2,) = sender.call{value: msg.value}("");
        require(success2,"eth transfer failed");
        delete _saleToken[_tokenId];
        TokensForSale--;
        return true;
    }

    function BalanceOfContract() external view returns(uint){
        return address(this).balance;
    }
}