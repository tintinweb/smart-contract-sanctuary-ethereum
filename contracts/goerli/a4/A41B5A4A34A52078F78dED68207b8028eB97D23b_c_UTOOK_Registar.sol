// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.17;
 
contract c_UTOOK_Registar
{
    struct Member
    {
        string Name;
        uint Member_Of;
        uint8 Access;
    }

    struct LocalDAO
    {
        string Name;
        address LocalDAO_Owner; //Used during setup, assumed it will typically be turned over to the contract once setup is complete.
        uint24[] Members;
        uint24[] Plots;

        string[] Laws;
    }
    
    uint public Member_Current_ID;
    uint public LocalDAO_Current_ID;
    uint public Objects_ID;

    //Maps to the index in the Members_I array.
    mapping (address => uint) public Members;
    mapping (string => uint) public Member_Names;
    mapping (uint => Member) public Members_I;

    //bytes32 for the Objects ID is determiened by the msg.sended hashed with the description & timestamp.
    mapping (bytes32 => uint) public Objects;
    mapping (uint => string) public Object_Description;
    mapping (uint => bytes32) public Objects_I;

    mapping (string => LocalDAO) public LocalDAOs;
    mapping (string => uint) public LocalDAO_Names;
    mapping (uint => LocalDAO) public LocalDAOs_I;

    //The coordinates of the plot are stored as X.Z.
    //For example, if UTOOK claims a plot at 500 X & 500 Y then the mapping would be Plots["500.500"] = "UTOOK"
    mapping (string => string) public Plots;

	constructor() 
	{
        Member memory tmp_Member;
        tmp_Member.Name = "NULL";
        tmp_Member.Member_Of = 0;
        tmp_Member.Access = 0;

        Members_I[0] = tmp_Member;
        Member_Names[""] = 0;
        Members[address(0)] = 0;
        

        Member_Current_ID = 1;

        tmp_Member.Name = "batchman";
        tmp_Member.Member_Of = 0;
        tmp_Member.Access = 1;

        Members_I[Member_Current_ID] = tmp_Member;
        Member_Names["batchman"] = Member_Current_ID;
        Members[address(0)] = Member_Current_ID;

        Member_Current_ID++;
	}

    function new_Member(string memory p_Name) public
    {
        require (Member_Names[p_Name] == 0);

        Members_I[Member_Current_ID].Name = p_Name;
        Members_I[Member_Current_ID].Member_Of = 0;
        Members_I[Member_Current_ID].Access = 0;
        Members[msg.sender] = Member_Current_ID;
        Member_Names[p_Name] = Member_Current_ID;
        Member_Current_ID++;

    }

    function new_LocalDAO(string memory p_Name) public
    {
        require(LocalDAOs[p_Name].LocalDAO_Owner == address(0));

        LocalDAOs_I[LocalDAO_Current_ID].Name = p_Name;
        LocalDAOs_I[LocalDAO_Current_ID].LocalDAO_Owner = msg.sender;
        LocalDAOs[p_Name] = LocalDAOs_I[LocalDAO_Current_ID];
        LocalDAO_Current_ID++;
    }

    // Function adding values to 
    // the mapping
    function claim_Plot(string memory p_COORD, string memory p_Organization) public 
    {
        require (bytes(Plots[p_COORD]).length == 0);
        
        Plots[p_COORD] = p_Organization;
        
    }

    function remove_Plot(string memory p_COORD) public
    {
        require (Members_I[Members[msg.sender]].Access == 1);

        Plots[p_COORD] = "";
    }

    function add_Admin(string memory p_Username) public
    {
        require (Members_I[Members[msg.sender]].Access == 1);

        Members_I[Member_Names[p_Username]].Access = 0;
    }
}