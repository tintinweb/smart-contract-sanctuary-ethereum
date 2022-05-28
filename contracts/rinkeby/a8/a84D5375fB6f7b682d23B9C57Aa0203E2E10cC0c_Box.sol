// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Box {
    uint256 private value;

    event ValueChanged(uint256 newValue);

    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    function retrieve() public view returns (uint256) {
        return value;
    }
}

// EXPLICACIÃ“N CÃ“DIGO.

// LÃ­nea 12: Emitimos el cambio del newValue en el event: ValueChanged. Es decir, dejÃ¡mos contancia
// de que esto se presentÃ³ o ejecutÃ³.

// Una vez escrito tods el contrato, vamos a copiar tods el cÃ³digo, crear un nuevo contrato en la
// carpeta: contracts, llamado: BoxV2.sol, y pegar el cÃ³digo allÃ­.

//