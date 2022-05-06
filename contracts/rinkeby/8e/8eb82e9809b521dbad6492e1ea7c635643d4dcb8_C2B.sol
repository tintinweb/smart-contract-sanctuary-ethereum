/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT // define la version del contrato inteligente 
pragma solidity ^0.8.6; //defino la version de solidity que vamos a utilizar

contract C2B // creo contrato y asigno nombre.
{
uint nextID; // Creo variable nextID.

struct Task //creo un tipo de dato "Task"
    //contenido del dato//      
   {
      uint id;
      string Nombre;
      string Asunto;
      string Descripcion;  
}
Task[] tasks; //genero un arreglo de tareas "tasks"

// Funcion para crear tareas // 
function CrearDocumento                                          //Habilito funcion para crear tareas.
(string memory _Nombre, string memory _Asunto, string memory _Descripcion) public //Indico que parametros se agregar al crear la funcion. 
  {
    tasks.push(Task(nextID, _Nombre, _Asunto, _Descripcion));       //al crear un task le ingreso los valores id,nombre,descripción.  
    nextID++;                                               //cada vez que creo task sumo 1 al valor del ID.
}

// Funcion para buscar el ID //
function ConsultarDocumento                                        //Habilito funcion para buscar id de la tarea creada
(uint _id) internal view returns (uint)                   // indico que tipo de dato y que dato busco. //indico que es una variable interna que se puede ver y que retorna un entero. 
{                                                         
   for (uint i=0; i< tasks.length; i++){                  
       if (tasks[i] .id == _id){                          // compara la id ingresada con la creada
           return i;                                      // si se cumple IF devulve i 
       }
   } 
    revert ('Task no encontrado');                         // en caso de cumplir funcion enviar error.
}
// Funcion para leer ID //
function LeerDocumento                                         //Habilito funcion para leer datos 
(uint _id) public view returns (uint, string memory, string memory, string memory)   // indico que dato y que dato busco // es publico se puede ver y retorna valor. 
 {
  uint index = ConsultarDocumento (_id);                            // Leo lo que encontre en FindIndex y lo guardo en index.
  return (tasks[index].id, tasks[index].Nombre, tasks[index].Asunto, tasks[index].Descripcion);                                         // retorno lo guardado en la variable index
}
// Funcion Update Contrato//
function ModificarDocumento                                       //Habilito funcion actualizar ID 
(uint _id, string memory _Nombre, string memory _Asunto, string memory _Descripcion) public  //indico tipo de dato y que dato actualizo
 {
   uint index = ConsultarDocumento(_id);                            // Leo lo que encontre en FindIndex y lo guardo en index.
   tasks [index].Nombre = _Nombre;                          // les listado segun el id encontrado me dejas actualizar nombre. 
   tasks [index].Asunto = _Asunto;
   tasks [index].Descripcion = _Descripcion;                 // les listado segun el id encontrado me dejas actualizar descripcion 
}

// Funcion Reset Values//
function ResetarDocumento                                         // Hablito funcion resetvalues
(uint _id) public                                             // indico ID donde vamos actuar y sera una funcion publica.
 {
  uint index = ConsultarDocumento (_id);                                // Leo lo que encontre en FindIndex y lo guardo en index.
  delete tasks [index];                                       // cero en cero los valores del ID selecionado.
}

}