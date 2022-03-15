/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.7.6;



// Part: Eboos

//import "E:\\package\\node_modules\\@openzeppelin\\contracts\\token\\ERC721\\IERC721Receiver.sol"
//interface ERC721TokenReceiver{
//    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external payable returns(bytes4);
//}
abstract contract  Eboos  {
//    function mint(address to ) public ;
    function premint(uint256 quantity) virtual external payable ;
    function getPrice() public virtual view returns (uint256);
}

// File: CallContract.sol

contract CallContract  {

    address public eboos_addr = 0x956d8Ca6511B59d3AC8A3156A9168f49a6aba938;
    Eboos public eboo;

    //0x76FeC53340eEb0B4FCDE5491C778Db80b012B370

    constructor() public{
//        _registerInterface(IERC721Receiver.onERC721Received.selector);
        eboo = Eboos(eboos_addr);
    }
    function mintfrom() payable  public  {
        eboo.premint{value:msg.value}(1);
    }
    function getPrice() public view returns (uint256){
        return eboo.getPrice();
    }
    receive() external payable{}
    function deposit() public payable{
    }

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data)
    public payable
    returns(bytes4)
    {
        bytes4 return_val =
        bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
        return return_val;
    }


}