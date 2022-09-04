// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

contract NewContract {
    constructor(address _contractadmin) public {
        ContractAdmin = _contractadmin;
        current_contract_state = ContractStatus.CONTRACTING;
    }

    enum ContractStatus {
        CONTRACTING,
        PROCESSING,
        CANCELED,
        DONE
    }
    enum ItemTracking {
        MANUFACTURING,
        WAITING,
        COLLECTED,
        SHIPPED,
        DELIVERED
    }

    struct itemInfo {
        string ItemName;
        string ItemSpecs;
        uint16 ItemWidth;
        uint16 ItemHeight;
        uint16 ItemLength;
        uint32 ItemWeight;
        uint32 ItemPrice;
    }

    mapping(uint256 => itemInfo) items;
    uint256[] internal itemIds;

    function addItems(itemInfo[] memory _itemInfo) public {
        uint256 itemIdslength = itemIds.length;
        for (uint256 i = 0; i < _itemInfo.length; i++) {
            itemInfo storage newItem = items[itemIdslength + i];
            newItem.ItemName = _itemInfo[i].ItemName;
            newItem.ItemSpecs = _itemInfo[i].ItemSpecs;
            newItem.ItemWidth = _itemInfo[i].ItemWidth;
            newItem.ItemHeight = _itemInfo[i].ItemHeight;
            newItem.ItemLength = _itemInfo[i].ItemLength;
            newItem.ItemWeight = _itemInfo[i].ItemWeight;
            newItem.ItemPrice = _itemInfo[i].ItemPrice;
            itemIds.push(itemIdslength + i);
        }
    }

    function getItem(uint256 id)
        public
        view
        returns (
            string memory Name,
            string memory Specs,
            uint16 Width,
            uint16 Height,
            uint16 Length,
            uint32 Weight,
            uint32 Price
        )
    {
        itemInfo memory s = items[id];
        return (
            s.ItemName,
            s.ItemSpecs,
            s.ItemWidth,
            s.ItemHeight,
            s.ItemLength,
            s.ItemWeight,
            s.ItemPrice
        );
    }

    ContractStatus public current_contract_state;
    address public ContractAdmin;
    address public CustomerAddress;
    address public ProducerAddress;
    address public CustomerBankAddress;
    address public ProducerBankAddress;
    address public InspectionAddress;
    address public ShipperAddress;
    address public CustomsClearanceAddress;

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