/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

//SPDX-License-Identifier: UNLICENSED

//version del contrato
pragma solidity ^0.8.14;

//declaración del contrato (no es necesario que se llame igual que el archivo)s

contract Contador {

	//declaración de variables
	uint256 count;

	//contructor
	constructor(uint256 _count) {
		count = _count;
	}


	function setCount(uint256 _count) public{
		count = _count;
	}

	function incrementCount() public{
		count++;
	}


	//esta funcion no modifica el estado, solo muestra el valor de la variable, no consume gas
	function getCount() public view returns (uint256){
		return count;
	}

	//esta variable ni escribe ni lee el estado, no consume gas
	function getNumber() public pure returns (uint256){
		return 34;
	}



}