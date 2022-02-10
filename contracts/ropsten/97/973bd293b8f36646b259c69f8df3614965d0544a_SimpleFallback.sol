/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

pragma solidity 0.8.7;

contract SimpleFallback{
    mapping (address => uint256) balances;
    event FallbackCalledEvent(bytes data);
    event DepositEvent(address src, uint amount);
    event AddEvent(uint a, uint b, uint result);

    fallback() external{
        emit FallbackCalledEvent(msg.data);
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
        //return balances[msg.sender];
    }

    function withdraw(address to, uint256 amount) public {
        require(balances[msg.sender] > amount, "error1");
        require(address(this).balance > amount, "error2");
        
        to.call{value: amount}("");

        balances[msg.sender] -= amount;
    }

    function wallet() view public returns (uint) {
        return address(this).balance;
    }

    function balanceOf(address addr) view public returns (uint256) {
        return balances[addr];
    }
}