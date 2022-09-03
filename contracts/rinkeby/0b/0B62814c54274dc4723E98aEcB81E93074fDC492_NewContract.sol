// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract NewContract {
    enum CSTATES {
        CONTRACTING,
        PROCESSING,
        CANCELED,
        DONE
    }
    struct itemInfo {
        string name;
        uint16 width;
        uint16 height;
        uint16 length;
        string email;
        uint256 mobile_no;
    }

    mapping(uint256 => itemInfo) items;
    uint256[] public itemIds;

    function addItem(
        string memory name,
        uint16 width,
        uint16 height,
        uint16 length,
        string memory email,
        uint256 id,
        uint256 mobile_no
    ) public {
        itemInfo storage newItem = items[id];
        newItem.name = name;
        newItem.width = width;
        newItem.height = height;
        newItem.length = length;
        newItem.email = email;
        newItem.mobile_no = mobile_no;
        itemIds.push(id);
    }

    function addItems(
        string[] memory name,
        uint16[] memory width,
        uint16[] memory height,
        uint16[] memory length,
        string[] memory email,
        uint256[] memory id,
        uint256[] memory mobile_no
    ) public {
        for (uint256 i = 0; i < name.length; i++) {
            itemInfo storage newItem = items[itemIds.length + i];
            newItem.name = name[itemIds.length + i];
            newItem.width = width[itemIds.length + i];
            newItem.height = height[itemIds.length + i];
            newItem.length = length[itemIds.length + i];
            newItem.email = email[itemIds.length + i];
            newItem.mobile_no = mobile_no[itemIds.length + i];
            itemIds.push(itemIds.length + i);
        }
    }

    function getItem(uint256 id)
        public
        view
        returns (
            string memory,
            uint16,
            uint16,
            uint16,
            string memory,
            uint256
        )
    {
        itemInfo storage s = items[id];
        return (s.name, s.width, s.height, s.length, s.email, s.mobile_no);
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