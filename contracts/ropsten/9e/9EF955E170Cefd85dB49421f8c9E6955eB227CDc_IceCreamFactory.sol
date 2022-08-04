// Contract which makes new virtual icecreams on demand.

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.10;

contract IceCreamFactory{
    // tested
    uint256 public totalContributions;
    address payable admin;
    uint256 public price;
    mapping(address=>uint256) public basket;
    mapping(address=>uint256) public reward;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );
    // tested
    constructor(uint256 _price){
        admin = payable(msg.sender);
        price = _price;
    }
    // default tested
    function mul(uint x,uint y) internal pure returns(uint z){
        require( y == 0 || ( z = x * y ) / y == x,"ds-math-mul-overflow");
    }
    // tested
    function contribute(uint256 _value) public payable{
        require(msg.value == mul(_value,price));
        require(basket[msg.sender]>0);
        totalContributions += _value;
        reward[msg.sender]+=_value;
    }
    // tested
    function getEther() public{
        require(msg.sender == admin);
        admin.transfer(address(this).balance);
    }
    // tested
    function buyIceCreams(uint256 _value) public payable{
        require(msg.value == mul(_value,price));
        basket[msg.sender] += _value;
    }
    // tested
    function sendIceCreams(address _to,uint256 _value) public returns(bool sucess){
        require(basket[msg.sender]>=_value);
        basket[msg.sender]-=_value;
        basket[_to]+=_value;
        emit Transfer(msg.sender,_to,_value);
        return true;
    }
    // tested
    function eatIceCreams(uint256 _value) public returns(bool){
        require(basket[msg.sender]>=_value);
        basket[msg.sender]-=_value;
        return true;
    }
    // tested
    function destroyFactory() public{
        require(msg.sender == admin);
        admin.transfer(address(this).balance);
        selfdestruct(admin);
    }
    // tested
    function contractExists(address _contract) public view returns(bool){
        uint _size;
        assembly {
            _size := extcodesize(_contract)
        }
        return _size > 0;
    }
}