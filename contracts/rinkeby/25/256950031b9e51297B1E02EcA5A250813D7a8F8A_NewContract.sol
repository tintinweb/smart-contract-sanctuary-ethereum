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
    address public InspectionAddress;
    address public ShipperAddress;
    address public CustomsClearanceAddress;

    constructor(address _contractadmin) public {
        ContractAdmin = _contractadmin;
        current_contract_state = CSTATES.CONTRACTING;
    }

    function set_Addresses(
        address _CustomerAddress,
        address _ProducerAddress,
        address _CustomerBankAddress,
        address _ProducerBankAddress,
        address _InspectionAddress
    ) public {
        require(
            msg.sender == ContractAdmin,
            "You don't have permision to set the addresses!"
        );
        require(CustomerAddress == address(0), "CustomerAddress already set!");
        require(ProducerAddress == address(0), "ProducerAddress already set!");
        require(
            CustomerBankAddress == address(0),
            "CustomerBankAddress already set!"
        );
        require(
            ProducerBankAddress == address(0),
            "ProducerBankAddress already set!"
        );
        require(
            InspectionAddress == address(0),
            "InspectionAddress already set!"
        );
        ///////////////////////////////////////////////////////////////////////////////
        require(
            _CustomerAddress != address(0),
            "CustomerAddress couldn't be 0!"
        );
        require(
            _ProducerAddress != address(0),
            "ProducerAddress couldn't be 0!"
        );
        require(
            _CustomerBankAddress != address(0),
            "CustomerBankAddress couldn't be 0!"
        );
        require(
            _ProducerBankAddress != address(0),
            "ProducerBankAddress couldn't be 0!"
        );
        require(
            _InspectionAddress != address(0),
            "InspectionAddress couldn't be 0!"
        );
        ///////////////////////////////////////////////////////////////////////////////
        CustomerAddress = _CustomerAddress;
        ProducerAddress = _ProducerAddress;
        CustomerBankAddress = _CustomerBankAddress;
        ProducerBankAddress = _ProducerBankAddress;
        InspectionAddress = _InspectionAddress;
    }

    function set_ShipperAddress(address _ShipperAddress) public {
        require(
            msg.sender == ContractAdmin,
            "You don't have permision to set the shipper's address!"
        );
        require(
            ShipperAddress == address(0),
            "Customer's address already set!"
        );
        require(
            _ShipperAddress != address(0),
            "Customer's address already set!"
        );
        require(_ShipperAddress != address(0), "ShipperAddress couldn't be 0!");
        ShipperAddress = _ShipperAddress;
    }
}