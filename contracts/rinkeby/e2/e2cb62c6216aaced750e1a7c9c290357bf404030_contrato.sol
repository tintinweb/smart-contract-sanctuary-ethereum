/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;

contract contrato {

    uint tareaId;

    struct Tarea {
        uint id;
        string nombre;
        string descripcion;
    }

    Tarea[] tareas;

    function crearTarea(string memory _nombre, string memory _descripcion) public {
        tareas.push(Tarea(tareaId, _nombre, _descripcion));
        tareaId++;
    }

    function buscarId(uint _id) internal view returns(uint) {
        for (uint i=0; i< tareas.length; i++){
            if (tareas[i].id == _id){
                return i;
            }
        }
        revert('Tarea no encontrada');
    }

    function leerTarea(uint _id) public view returns(uint, string memory, string memory) {
        uint indice = buscarId(_id);
        return (tareas[indice].id, tareas[indice].nombre, tareas[indice].descripcion);
    }

    function actualizarTarea(uint _id, string memory _nombre, string memory _descripcion) public {
        uint indice = buscarId(_id);
        tareas[indice].nombre = _nombre;
        tareas[indice].descripcion = _descripcion;
    }
}