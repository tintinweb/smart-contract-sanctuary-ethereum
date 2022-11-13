// SPDX-License-Identifier: MIT

//Developer : FazelPejmanfar , Twitter :@Pejmanfarfazel

pragma solidity >=0.7.0 <0.9.0;

contract Escrow {

    enum State { 
        AWAITING_PAYMENT, 
        AWAITING_DELIVERY, 
        COMPLETE 
        }
    
    State public CurrentState;
    
    address public Client;
    address payable public Seller;
    
    modifier onlyClient() {
        require(msg.sender == Client, "Only Client can call this method");
        _;
    }

    modifier onlySeller() {
    require(msg.sender == Seller, "Only seller can call this method");
    _;
    }

    function ContractBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    constructor(address _Client, address payable _Seller)
    {
        Client = _Client;
        Seller = _Seller;
    }

    function ChangeClient(address _newClient) external onlySeller {
        require(CurrentState == State.COMPLETE, "Previous Payment Need to Be Made");
        Client = _newClient;
        CurrentState = State.AWAITING_PAYMENT;
    }

    function renewCurrentClient() external onlySeller {
        require(CurrentState == State.COMPLETE, "Previous Payment Need to Be Made");
        CurrentState = State.AWAITING_PAYMENT;
    }
    
    function deposit() onlyClient external payable {
        require(CurrentState == State.AWAITING_PAYMENT, "Already paid");
        CurrentState = State.AWAITING_DELIVERY;
    }
    
    function confirmDelivery() onlyClient external {
        require(CurrentState == State.AWAITING_DELIVERY, "Cannot confirm delivery");
        Seller.transfer(address(this).balance);
        CurrentState = State.COMPLETE;
    }
}