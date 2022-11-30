/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

pragma solidity 0.8.17;

contract ForceHelper
{
    address payable public forceAddress = payable(0xf79a50d2e6Dc1Caae39955c7B8224dCB588530B1);
    address public owner;

    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }

    constructor()
    {
        owner = msg.sender;
    }

    function sendMoney() public payable 
    {
        
    }

    function setForceAddress(uint160 _address) public
    {
        forceAddress = payable(address(_address));
    }

    function destroy() public onlyOwner
    {
        selfdestruct(forceAddress);
    }
}