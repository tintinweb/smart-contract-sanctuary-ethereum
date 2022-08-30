// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract NewContract {
    enum CSTATES {
        CONTRACTING,
        PROCESSING,
        CANCELED,
        DONE
    }
    CSTATES public current_contract_state;
    address public ContractAdmin;
    address public CustomerAddress;
    address public ProducerAddress;
    address public CustomerBankAddress;
    address public ProducerBankAddress;
    address public ShipperAddress;
    address public CustomsClearanceAddress;
    address public InspectionAddress;

    constructor(address _contractadmin) public {
        ContractAdmin = _contractadmin;
        current_contract_state = CSTATES.CONTRACTING;
    }

    function set_CustomerAddress(address _CustomerAddress) public {
        require(
            msg.sender == ContractAdmin,
            "You don't have permision to set the customer's address!"
        );
        CustomerAddress = _CustomerAddress;
    }

    function retrieve_CustomerAddress() public view returns (address) {
        return CustomerAddress;
    }
}