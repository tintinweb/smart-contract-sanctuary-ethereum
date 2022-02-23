/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

pragma solidity ^0.4.18;

//Attribute-based Access Control model
contract ABAC {

	/*
		Define struct to represent role based token data.
	*/
	struct AccessAttribute{
						
		string attribute;	
        	bool isValid;			
	}
	struct vnAttribute
	{
		string virtualNetwork;
		string attribute;
		
	}
	vnAttribute[] public tab;

	mapping(uint => AccessAttribute) AccessAttributes;
    	

	// Set role call function
	function setAttribute(uint id, string attribute) public  {
			AccessAttributes[id].attribute = attribute;
            AccessAttributes[id].isValid=true;
}
		
	
	function getAttribute(uint id,string attribute) public view returns (bool) {

			return keccak256(bytes(AccessAttributes[id].attribute))== keccak256(bytes(attribute));
			
	}
function addAttributeToVN(string vn,string attribute) public
{
    vnAttribute memory vna = vnAttribute(vn,attribute);
         tab.push(vna);
}
	function getAccess(string vn,string attribute) public view returns (bool) {
		for ( uint i=0; i<tab.length;i++){

		
			if (keccak256(bytes(tab[i].attribute))== keccak256(bytes(attribute)) 
			&& keccak256(bytes(tab[i].virtualNetwork))== keccak256(bytes(vn)))
			return true ;
		}
    }
		
	
}