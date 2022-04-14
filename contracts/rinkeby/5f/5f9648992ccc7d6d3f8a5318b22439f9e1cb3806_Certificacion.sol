/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Certificacion {
    address owner;
    constructor(){
        owner=msg.sender;
    }

    modifier restringido() {
    if (msg.sender == owner) _;}

    struct Certificate {
        string nombre_candidato;
        string nombre_organizacion;
        string nombre_curso;
        uint256 fecha_expiracion;
    }

    mapping(bytes32 => Certificate) public certificados;

    event certificadoGenerado(bytes32 _certificateId);

    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
                result := mload(add(source, 32))
        }
    }

    function generarCertificado(
        string memory _id,
        string memory _nombre_candidato,
        string memory _nombre_organizacion, 
        string memory _nombre_curso, 
        uint256 _fecha_expiracion) public restringido {
        bytes32 byte_id = stringToBytes32(_id);
        require(certificados[byte_id].fecha_expiracion == 0, "El certificado con la id especificada ya existe");
        certificados[byte_id] = Certificate(_nombre_candidato, _nombre_organizacion, _nombre_curso, _fecha_expiracion);
        emit certificadoGenerado(byte_id);
    }

    function obtenerDatos(string memory _id) public view returns(string memory, string memory, string memory, uint256) {
        bytes32 byte_id = stringToBytes32(_id);
        Certificate memory temp = certificados[byte_id];
        require(temp.fecha_expiracion != 0, "No existe");
        return (temp.nombre_candidato, temp.nombre_organizacion, temp.nombre_curso, temp.fecha_expiracion);
    }
}