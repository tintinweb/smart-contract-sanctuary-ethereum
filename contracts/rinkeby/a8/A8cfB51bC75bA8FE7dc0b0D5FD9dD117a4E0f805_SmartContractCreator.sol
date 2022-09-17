// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "NewContract.sol";

interface ContactsDBinterface {
    function CanUserCreate(address) external view returns (bool);

    function IsAddressRole(address _Address, uint8 _Role)
        external
        view
        returns (bool);
}

contract SmartContractCreator {
    address internal owner;
    address public constant ContactsDBAddress =
        0x0d7ca9650cb26DD9EE96c3d0bfa04cFc7F7e0C12;

    address[] internal contracts;
    string[] internal contractname;
    mapping(address => address) public ContractToAdmin;
    mapping(address => uint256) public ContractToDate;
    mapping(address => address[]) public PartyContract;
    mapping(string => address) public NameToAddress;
    /////////////////////////////
    ContactsDBinterface ContactDBcontact =
        ContactsDBinterface(ContactsDBAddress);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    NewContract public newcontract;

    function CreateContract(
        address _CustomerAddress,
        address _ProducerAddress,
        address _ShipperAddress,
        string memory _Shipping_Contract,
        string memory _ContractBody,
        string memory _contractname,
        string memory _Country_from,
        string memory _Country_to
    ) public {
        bool test_value = false;
        for (uint256 i; i < contractname.length; i++) {
            if (
                keccak256(abi.encodePacked(contractname[i])) ==
                keccak256(abi.encodePacked(_contractname))
            ) {
                test_value = true;
            }
        }
        require(test_value == false, "Contract name is already exist!");
        require(
            ContactDBcontact.CanUserCreate(msg.sender) == true,
            "you have no right to create new contract!"
        );
        require(
            ContactDBcontact.IsAddressRole(_CustomerAddress, 1) == true,
            "Customer not allowed!"
        );
        require(
            ContactDBcontact.IsAddressRole(_ProducerAddress, 2) == true,
            "Producer not allowed!"
        );
        if (_ShipperAddress != address(0)) {
            require(
                ContactDBcontact.IsAddressRole(_ShipperAddress, 4) == true,
                "Shipper not allowed!"
            );
        }

        newcontract = new NewContract(
            _CustomerAddress,
            _ProducerAddress,
            _ShipperAddress,
            _Shipping_Contract,
            _ContractBody,
            _Country_from,
            _Country_to
        );
        if (_CustomerAddress > address(0)) {
            PartyContract[_CustomerAddress].push(address(newcontract));
        }
        if (_ProducerAddress > address(0)) {
            PartyContract[_ProducerAddress].push(address(newcontract));
        }
        if (_ShipperAddress > address(0)) {
            PartyContract[_ShipperAddress].push(address(newcontract));
        }
        contracts.push(address(newcontract));
        ContractToDate[address(newcontract)] = block.timestamp;
        contractname.push(_contractname);
    }

    function retrieve_contracts_address()
        public
        view
        returns (address[] memory)
    {
        return contracts;
    }

    function retrieve_contracts_names() public view returns (string[] memory) {
        return contractname;
    }

    function retrieve_name_to_add(string memory _con_add)
        public
        view
        returns (address)
    {
        return NameToAddress[_con_add];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract NewContract {
    mapping(uint8 => bytes32) internal RolesName;
    mapping(address => uint8) internal RolesAddress;
    mapping(uint8 => address) internal AddressRoles;

    //////////////////////////////////////////////////
    mapping(uint256 => string) internal ShippingContractName;
    uint256 internal Shipping_Contract;
    string public Shipping_Contract_Name;
    string public ContractBody;
    string public Country_from;
    string public Country_to;
    uint8 public Current_Step = 1;
    address public CustomerAddress;
    address public ProducerAddress;
    address public CustomerBankAddress;
    address public ProducerBankAddress;
    address public InspectionAddress;
    address public ShipperAddress;
    address public CustomsClearanceAddress;

    constructor(
        address _CustomerAddress,
        address _ProducerAddress,
        address _ShipperAddress,
        string memory _Shipping_Contract_Name,
        string memory _ContractBody,
        string memory _Country_from,
        string memory _Country_to
    ) {
        CustomerAddress = _CustomerAddress;
        RolesAddress[_CustomerAddress] = 1;
        ProducerAddress = _ProducerAddress;
        RolesAddress[_ProducerAddress] = 2;
        ShipperAddress = _ShipperAddress;
        RolesAddress[_ShipperAddress] = 3;
        Shipping_Contract_Name = _Shipping_Contract_Name;
        ContractBody = _ContractBody;
        /////////////////
        RolesName[1] = "CUSTOMER";
        RolesName[2] = " PRODUCER";
        RolesName[3] = "SHIPPER";
        ////////////////////////////////
        Country_from = _Country_from;
        Country_to = _Country_to;
        CreateSteps();
    }

    /////////////////////////// Items Struct /////////////////////////////////////
    uint256[] internal itemIds;
    mapping(uint256 => itemInfo) items;
    struct itemInfo {
        string ItemName;
        string ItemSpecs;
        uint16 ItemWidth;
        uint16 ItemHeight;
        uint16 ItemLength;
        uint32 ItemWeight;
        uint32 ItemPrice;
    }

    /////////////////////////// Steps Struct /////////////////////////////////////
    uint256[] public StepIds;
    mapping(uint256 => string) public StepName;
    mapping(uint256 => mapping(uint8 => uint8)) public StepSort_Role;
    mapping(uint256 => mapping(uint8 => bool)) public StepIdsRole_Sign;
    mapping(uint256 => mapping(uint8 => uint256)) public StepIdsRole_SignTime;

    /////////////////////////// Create Step /////////////////////////////////////

    function CreateSteps() internal {
        uint8 SID = 1;
        StepIds.push(SID);
        StepName[SID] = "Contracting";
        StepSort_Role[SID][1] = 2;
        StepSort_Role[SID][2] = 1;
        ///////////////////////////////
        SID = 2;
        StepIds.push(SID);
        StepName[SID] = "First Payment";
        StepSort_Role[SID][1] = 1;
        StepSort_Role[SID][2] = 2;
        ///////////////////////////////
        SID = 3;
        StepIds.push(SID);
        StepName[SID] = "Manufacturing";
        StepSort_Role[SID][1] = 2;
        ///////////////////////////////
        SID = 4;
        StepIds.push(SID);
        StepName[SID] = "Second Payment";
        StepSort_Role[SID][1] = 1;
        StepSort_Role[SID][2] = 2;
        ///////////////////////////////
        SID = 5;
        StepIds.push(SID);
        StepName[SID] = "Shipping";
        StepSort_Role[SID][1] = 2;
        StepSort_Role[SID][2] = 3;
        ///////////////////////////////
        SID = 6;
        StepIds.push(SID);
        StepName[SID] = "Delivered";
        StepSort_Role[SID][1] = 3;
        StepSort_Role[SID][2] = 1;
        ///////////////////////////////
        SID = 7;
        StepIds.push(SID);
        StepName[SID] = "Done";
        ///////////////////////////////
    }

    /////////////////////////// Get Steps ////////////////////////////////////
    function get_steps()
        public
        view
        returns (
            uint8[] memory,
            uint8[] memory,
            uint8[] memory,
            bool[] memory
        )
    {
        uint256 array_size = 0;
        for (uint8 i = 0; i < StepIds.length; i++) {
            for (uint8 i2 = 1; StepSort_Role[StepIds[i]][i2] > 0; i2++) {
                array_size++;
            }
        }
        uint8[] memory _Step = new uint8[](array_size);
        uint8[] memory _order = new uint8[](array_size);
        uint8[] memory _Role = new uint8[](array_size);
        bool[] memory _Signed = new bool[](array_size);

        uint256 _temp_Counter = 0;
        for (uint8 i = 0; i < StepIds.length; i++) {
            for (uint8 i2 = 1; StepSort_Role[StepIds[i]][i2] > 0; i2++) {
                _Step[_temp_Counter] = uint8(StepIds[i]);
                _order[_temp_Counter] = i2;
                _Role[_temp_Counter] = StepSort_Role[StepIds[i]][i2];
                _Signed[_temp_Counter] = StepIdsRole_Sign[StepIds[i]][
                    StepSort_Role[StepIds[i]][i2]
                ];
                _temp_Counter++;
            }
        }
        return (_Step, _order, _Role, _Signed);
    }

    /////////////////////////// Get Item /////////////////////////////////////

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

    /////////////////////////// Approve /////////////////////////////////////

    function Approve_Step(uint8 _role) public {
        if (_role == 1) {
            require(
                msg.sender == CustomerAddress,
                "You dont't have the right to approve"
            );
        }
        if (_role == 2) {
            require(
                msg.sender == ProducerAddress,
                "You dont't have the right to approve"
            );
        }
        if (_role == 3) {
            require(
                msg.sender == CustomerBankAddress,
                "You dont't have the right to approve"
            );
        }
        if (_role == 4) {
            require(
                msg.sender == ProducerBankAddress,
                "You dont't have the right to approve"
            );
        }
        if (_role == 5) {
            require(
                msg.sender == ShipperAddress,
                "You dont't have the right to approve"
            );
        }
        if (_role == 6) {
            require(
                msg.sender == CustomsClearanceAddress,
                "You dont't have the right to approve"
            );
        }
        if (_role == 7) {
            require(
                msg.sender == InspectionAddress,
                "You dont't have the right to approve"
            );
        }
        for (uint8 i = 1; StepSort_Role[Current_Step][i] != _role; i++) {
            require(
                StepIdsRole_Sign[Current_Step][
                    StepSort_Role[Current_Step][i]
                ] == true,
                "You Can't sign yet!"
            );
        }
        StepIdsRole_Sign[Current_Step][_role] = true;
        StepIdsRole_SignTime[Current_Step][_role] = block.timestamp;
        bool final_step = false;
        for (uint8 i2 = 1; uint8(StepSort_Role[Current_Step][i2]) > 0; i2++) {
            final_step = StepIdsRole_Sign[Current_Step][
                StepSort_Role[Current_Step][i2]
            ];
        }
        if (final_step == true) {
            Current_Step++;
        }
    }
    ////////////////////////////////////////////////////////////////
}