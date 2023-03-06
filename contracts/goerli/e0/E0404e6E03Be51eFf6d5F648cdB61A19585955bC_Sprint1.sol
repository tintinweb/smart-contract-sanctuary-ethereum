// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.1;

contract Sprint1  {

	mapping(address => string) private registro;
	
	uint256 public cantidadEntradas = 0;

    function setKeyWord(string memory key) public {
        registro[msg.sender] = key; // guardo el key recibido en el map
		cantidadEntradas++;
	}

    function getKeyWord(address key) public view returns (string memory){
        return (registro[key]); // retorno palabra clave, si exite el sender ( si no existe valor por defecto uint256).
    }

}