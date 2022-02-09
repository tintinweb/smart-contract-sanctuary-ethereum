/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

pragma solidity 0.8.10;

/// @title   On Chain Payroll
/// @author  0xMarty
/// @notice  Owner pays payee
contract OnChainPayroll {

    /// STATE VARIABLES ///

    /// @notice Payer of contact 
    address immutable public owner;
    /// @notice Total amount of eth owner paid
    uint public ethPayed;
    /// @notice Amount of eth address has recieved
    mapping(address => uint) public addressToPaid;

    /// CONSTRUCTOR ///

    /// @param _owner  Address that pays eth
    constructor (address _owner) {
        owner = _owner;
    }

     /// PAY FUNCTION ///

    /// @notice        Owner pays specified address
    /// @param _payee  Address of who is being paid
    function pay(address payable _payee) external payable {
        require(msg.sender == owner, "not owner");
        
        ethPayed += msg.value;
        addressToPaid[_payee] += msg.value;
        _payee.transfer(msg.value); 
    }
}