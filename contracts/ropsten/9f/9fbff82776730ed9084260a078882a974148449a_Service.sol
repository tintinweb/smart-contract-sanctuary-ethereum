/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

pragma solidity ^0.5.0;
interface IERC20 {
    function withDraw(uint256 _value,address payable coin_receiver) external returns(bool success);
}

contract Service {
    address payable owner;
    constructor() public{
        owner=msg.sender;
    }
    IERC20 token = IERC20(address(0xd76c64574484bB9a39BB8fc88D4871729187Ecee));
    mapping (uint256 => uint256)private service;

    function withDraw(uint256 _value) external returns(bool success){// 這個合約的balance只能提款到owner 帳戶
        token.withDraw(_value,owner);
        return true;
    }

    function setTheServicePrice(uint256 serviceId, uint256 price) external returns(bool success)
    {
        require(msg.sender==owner,"only Owner");
        service[serviceId]=price;
        return true;
    }

    function getTheServicePrice(uint256 serviceId)external view returns(uint256 price)
    {
        return service[serviceId];
    }
}