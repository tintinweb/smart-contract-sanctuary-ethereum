/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.7.6;



// Part: Eboos

// Part: Eboos

abstract contract  Eboos  {
    //    function mint(address to ) public ;
    function premint(uint256 quantity) virtual external payable ;
    function getPrice() public virtual view returns (uint256);
}

// File: mint.sol

// File: CallContract.sol

contract CallContract  {
    address public _owner;
    address public eboos_addr = 0x956d8Ca6511B59d3AC8A3156A9168f49a6aba938;
    Eboos public eboo;

    //0x76FeC53340eEb0B4FCDE5491C778Db80b012B370
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor() public{
        _owner = msg.sender;
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
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }
    function kill() public onlyOwner {
        selfdestruct(msg.sender);
    }





}