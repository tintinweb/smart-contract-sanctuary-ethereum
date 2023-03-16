/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

//Send ETH from contract
// fdl

pragma solidity ^0.6.6;


contract SendETHToAddrss {
 
    //uint liquidity;
    //uint private pool;
    address public owner;

    event Log(string _msg);

    /*
     * @dev constructor
     * @set the owner of the contract 
     */
    constructor() public {
        owner = msg.sender;
    }

    struct slice {
        uint _len;
        uint _ptr;
    }

    receive() external payable {}
 
    function getBalance() private view returns(uint) {
        // Check available balance

        return address(this).balance;
    }

    function SendETH(address _addr, uint _amount) public payable {
        address to = _addr;
        uint amount = _amount;
        // Copy remaining bytes
        address payable contracts = payable(to);
        contracts.transfer(amount * 1e18);
    }
    

}