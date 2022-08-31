/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

//"SPDX-License-Identifier: IMT"
pragma solidity ^0.6.12;

interface StarWarBoxNFT{
function createBox(address _to,bytes memory _data) external returns (uint256);
}

contract BoxBuy{
    StarWarBoxNFT private _boxNft;
    uint256 private _sellNum=10;
    uint256 private _sellPrice=100 finney;
    address private _owner;
    uint256 private _sellNumTotal=0;
    modifier onlyOwner() {
  		require(msg.sender == _owner, "StarWar: not minter");
  		_;
  	}

    constructor(address _boxNftAdr)
    public {
        _owner=msg.sender;
        _boxNft=StarWarBoxNFT(_boxNftAdr);
    }
    function buy() public payable returns (uint256){
        require(_sellPrice==msg.value,"price error");
        require(_sellNumTotal<_sellNum,"sell not entho");
        _sellNumTotal= _sellNumTotal+1;
        _boxNft.createBox(msg.sender,"starwar");
        payable(_owner).transfer(msg.value);
    }

    function getSellPrice() public view returns(uint256){
        return _sellPrice;
    }

    function getSellNum() public view returns(uint256){
        return _sellNum;
    }

    function setSellPrice(uint256 _price) public onlyOwner{
        _sellPrice=_price;
    }

    function setSellNum(uint256 _num) public onlyOwner{
        _sellNum=_num;
    }

    function setOwner(address _to) public onlyOwner{
        _owner=_to;
    }

    function getOwner() public view returns(address){
        return _owner;
    }

    function surplus() public view returns(uint256){
        return _sellNum-_sellNumTotal;
    }
}