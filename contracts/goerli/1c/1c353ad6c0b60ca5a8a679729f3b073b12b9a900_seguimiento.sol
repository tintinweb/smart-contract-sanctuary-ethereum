/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

contract seguimiento{	

	string[] ciudades;
    uint numCiudades;
    uint constant maxCiudades = 10;

	constructor(){
        numCiudades = 0;
		ciudades = new string[](maxCiudades);
	}

	function nuevaCiudad(string memory c) public {
		if (numCiudades < maxCiudades){
			ciudades.push(c);
            numCiudades++;
		}
	}

	function getCiudades() public view returns (string[] memory){
		return ciudades;
	}
}