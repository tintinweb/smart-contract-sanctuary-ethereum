// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.17;
 
contract c_UTOOK_Registar
{
    //Humans are only needed until we code the parts to handle this.
    mapping (address => string) internal Admins;

    //The coordinates of the plot are stored as X.Z.
    //For example, if UTOOK claims a plot at 500 X & 500 Y then the mapping would be Plots["500.500"] = "UTOOK"
    mapping (string => string) public Plots;    

	constructor() 
	{
        Admins[msg.sender] = "BackMcRacken";
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
        require (bytes(Admins[msg.sender]).length > 0);

        Plots[p_COORD] = "";
    }

    function add_Admin(address p_Newblood, string memory p_Username) public
    {
        require (bytes(Admins[msg.sender]).length > 0);

        Admins[p_Newblood] = p_Username;
    }
}