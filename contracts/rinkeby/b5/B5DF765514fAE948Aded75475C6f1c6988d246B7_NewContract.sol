// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract NewContract {
    mapping(uint8 => string) internal RolesName;
    mapping(address => uint8) internal RolesAddress;
    mapping(uint8 => address) internal AddressRoles;

    //////////////////////////////////////////////////
    mapping(uint256 => string) internal ShippingContractName;
    uint256 internal Shipping_Contract;
    string public Shipping_Contract_Name;
    string public ContractBody;
    string public Country_from;
    string public Country_to;
    string public contractname;
    uint8 public Current_Step = 1;
    address public CustomerAddress;
    address public ProducerAddress;
    address public ShipperAddress;

    constructor(
        address _CustomerAddress,
        address _ProducerAddress,
        address _ShipperAddress,
        string memory _Shipping_Contract_Name,
        string memory _ContractBody,
        string memory _Country_from,
        string memory _Country_to,
        string memory _contractname
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
        contractname = _contractname;
        CreateSteps();
    }

    /////////////////////////// Steps Struct /////////////////////////////////////
    uint256[] public StepIds;
    mapping(uint256 => string) public StepName;
    mapping(uint256 => mapping(uint8 => uint8)) public StepSort_Role;
    mapping(uint256 => mapping(uint8 => bool)) public StepIdsRole_Sign;
    mapping(uint256 => mapping(uint8 => uint256)) public StepIdsRole_SignTime;

    /////////////////////////// Docs Struct /////////////////////////////////////
    uint256[] public DocIds;
    mapping(uint256 => string) public DocID_Name;
    mapping(uint256 => string) public DocID_Link;
    mapping(uint256 => bool) public DocID_Sent;
    mapping(uint256 => uint256) public DocID_Sent_Time;
    mapping(uint256 => bool) public DocID_Approved;
    mapping(uint256 => uint256) public DocID_Approved_Time;
    mapping(uint256 => uint256) public DocID_Step;
    mapping(uint256 => uint8) public DocID_Role_From;
    mapping(uint256 => uint8) public DocID_Role_To;

    /////////////////////////// Create Step /////////////////////////////////////

    function CreateSteps() internal {
        ///////////////////////////////
        uint8 SID = 1;
        uint8 DOC;
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

        DOC = 1;
        DocIds.push(DOC);
        DocID_Name[DOC] = "First Payment document";
        DocID_Step[DOC] = SID;
        DocID_Role_From[DOC] = 1;
        DocID_Role_To[DOC] = 2;
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

        DOC = 2;
        DocIds.push(DOC);
        DocID_Name[DOC] = "Second Payment document";
        DocID_Step[DOC] = SID;
        DocID_Role_From[DOC] = 1;
        DocID_Role_To[DOC] = 2;

        ///////////////////////////////
        SID = 5;
        StepIds.push(SID);
        StepName[SID] = "Shipping";
        StepSort_Role[SID][1] = 2;
        StepSort_Role[SID][2] = 3;
        ///////////////////////////////
        SID = 6;
        StepIds.push(SID);
        StepName[SID] = "Delivering";
        StepSort_Role[SID][1] = 3;
        StepSort_Role[SID][2] = 1;

        DOC = 3;
        DocIds.push(DOC);
        DocID_Name[DOC] = "Bill of Lading";
        DocID_Step[DOC] = SID;
        DocID_Role_From[DOC] = 3;
        DocID_Role_To[DOC] = 1;
        ///////////////////////////////
        SID = 7;
        StepIds.push(SID);
        StepName[SID] = "Done";
        ///////////////////////////////
    }

    /////////////////////////// Get Contract Data ////////////////////////////////////
    function get_data()
        public
        view
        returns (
            uint8[] memory,
            uint8[] memory,
            uint8[] memory,
            string[] memory,
            bool[] memory,
            uint8,
            uint8,
            string[5] memory
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
        string[] memory _RoleName = new string[](array_size);
        bool[] memory _Signed = new bool[](array_size);

        uint256 _temp_Counter = 0;
        for (uint8 i = 0; i < StepIds.length; i++) {
            for (uint8 i2 = 1; StepSort_Role[StepIds[i]][i2] > 0; i2++) {
                _Step[_temp_Counter] = uint8(StepIds[i]);
                _order[_temp_Counter] = i2;
                _Role[_temp_Counter] = StepSort_Role[StepIds[i]][i2];
                _RoleName[_temp_Counter] = string(
                    RolesName[_Role[_temp_Counter]]
                );
                _Signed[_temp_Counter] = StepIdsRole_Sign[StepIds[i]][
                    StepSort_Role[StepIds[i]][i2]
                ];
                _temp_Counter++;
            }
        }
        string[] memory names_data = new string[](5);
        names_data[0] = contractname;
        names_data[1] = Shipping_Contract_Name;
        names_data[2] = ContractBody;
        names_data[3] = Country_from;
        names_data[4] = Country_to;
        return (
            _Step,
            _order,
            _Role,
            _RoleName,
            _Signed,
            Current_Step,
            RolesAddress[msg.sender],
            [
                contractname,
                Shipping_Contract_Name,
                ContractBody,
                Country_from,
                Country_to
            ]
        );
    }

    /////////////////////////// get documents ////////////////////////////////////

    function get_documents()
        public
        view
        returns (
            uint256[] memory,
            string[] memory,
            bool[] memory,
            uint8[] memory
        )
    {
        uint256[] memory _DocIds_ST_AT_S = new uint256[](DocIds.length * 4);
        string[] memory _DocID_Name_Link = new string[](DocIds.length * 2);
        bool[] memory _DocID_Sent_Approved = new bool[](DocIds.length * 2);
        uint8[] memory _DocID_Role_From_to = new uint8[](DocIds.length * 2);

        for (uint256 i = 0; i < DocIds.length; i++) {
            _DocIds_ST_AT_S[(i * 4)] = DocIds[i];
            _DocIds_ST_AT_S[(i * 4) + 1] = DocID_Sent_Time[DocIds[i]];
            _DocIds_ST_AT_S[(i * 4) + 2] = DocID_Approved_Time[DocIds[i]];
            _DocIds_ST_AT_S[(i * 4) + 3] = DocID_Step[DocIds[i]];
            _DocID_Name_Link[(i * 2)] = DocID_Name[DocIds[i]];
            _DocID_Name_Link[(i * 2) + 1] = DocID_Link[DocIds[i]];
            _DocID_Sent_Approved[(i * 2)] = DocID_Sent[DocIds[i]];
            _DocID_Sent_Approved[(i * 2) + 1] = DocID_Approved[DocIds[i]];
            _DocID_Role_From_to[(i * 2)] = DocID_Role_From[DocIds[i]];
            _DocID_Role_From_to[(i * 2) + 1] = DocID_Role_To[DocIds[i]];
        }
        return (
            _DocIds_ST_AT_S,
            _DocID_Name_Link,
            _DocID_Sent_Approved,
            _DocID_Role_From_to
        );
    }

    /////////////////////////// Approve /////////////////////////////////////

    function Approve_Step(uint8 _role) public returns (string memory) {
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
                msg.sender == ShipperAddress,
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
        ///////// Docs
        for (uint8 i3 = 0; i3 < DocIds.length; i3++) {
            require(
                !(DocID_Role_From[DocIds[i3]] == _role &&
                    DocID_Step[DocIds[i3]] == Current_Step &&
                    DocID_Sent[DocIds[i3]] == false),
                "There are pending files to be sent!"
            );
            require(
                !(DocID_Role_To[DocIds[i3]] == _role &&
                    DocID_Step[DocIds[i3]] == Current_Step &&
                    DocID_Approved[DocIds[i3]] == false),
                "There are pending files to be approved!"
            );
        }
        //////////////
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
        return "Action Signed";
    }

    /////////////////////////// AddDocs /////////////////////////////////////

    function AddDocs(uint256[] memory _DocIds, string[] memory _DocID_Link)
        public
    {
        require(
            _DocIds.length == _DocID_Link.length,
            "Documents IDs, names, and links are not equal!"
        );
        bool DocsCounter = false;
        for (uint8 i = 0; i < _DocIds.length; i++) {
            DocsCounter = false;
            for (uint8 i2 = 0; i2 < DocIds.length; i2++) {
                if (DocIds[i2] == _DocIds[i]) {
                    DocsCounter = true;
                    require(
                        DocID_Role_From[DocIds[i2]] == RolesAddress[msg.sender],
                        "You don't have permission to add this file!"
                    );
                }
            }
            require(DocsCounter == true, "Document Id not exist!");
        }
        for (uint8 i = 0; i < _DocIds.length; i++) {
            DocID_Link[_DocIds[i]] = _DocID_Link[i];
            DocID_Sent[_DocIds[i]] = true;
            DocID_Sent_Time[_DocIds[i]] = block.timestamp;
        }
    }

    /////////////////////////// ApproveDocs /////////////////////////////////////

    function ApproveDocs(uint256[] memory _DocIds) public {
        bool DocsCounter = false;
        for (uint8 i = 0; i < _DocIds.length; i++) {
            DocsCounter = false;
            for (uint8 i2 = 0; i2 < DocIds.length; i2++) {
                if (DocIds[i2] == _DocIds[i]) {
                    DocsCounter = true;
                    require(
                        DocID_Role_To[DocIds[i2]] == RolesAddress[msg.sender],
                        "You don't have permission to approve this file!"
                    );
                    require(
                        DocID_Sent[DocIds[i2]] == true,
                        "File not added yet!"
                    );
                }
            }
            require(DocsCounter == true, "Document Id not exist!");
        }
        for (uint8 i = 0; i < _DocIds.length; i++) {
            DocID_Approved[_DocIds[i]] = true;
            DocID_Approved_Time[_DocIds[i]] = block.timestamp;
        }
    }
}