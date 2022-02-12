/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

// SPDX-License-Identifier: GPL-3.0
// Author: Gerardo Alberto Cataño Cañizales
// version: 0.1
pragma solidity >=0.7.0 <0.9.0;

/* Prueba de concepto de smart contract para el registro de mascotas 
    y su posterior seguimiento en un evento de adopcion */
contract EventoAdopcion {

//modelo de datos de la mascota
struct Mascota {
    uint8 id;
    address dueno;      //propiedad actualizable
    string nombre;      //propiedad actualizable
    string especie;
    string raza;
    string genero;
    string color;
    uint8 edad;          //propiedad actualizable
    bool esterilizada;  //propiedad actualizable
}

//se define al responsable del evento
address administradorEvento = msg.sender;
//se define lista y contador de mascotas
mapping(uint8 => Mascota) public mascotas;
uint8 public contadorMascotas;

//se añade la lista de mascotas al inicializar el evento
constructor () {
    anadirMascotaEnAdopcion("Tito", "perro", "schnauzer", "macho", "gris plata", 9);    
    anadirMascotaEnAdopcion("Pelusa", "gato", "persa", "hembra", "beige", 5);
    anadirMascotaEnAdopcion("Layla", "perro", "chihuahua", "hembra", "negro", 6);
    anadirMascotaEnAdopcion("Morgan", "gato", "criollo", "macho", "blanco", 2);
}

//funcion interna de apoyo para inicializar lista y contador de mascotas
function anadirMascotaEnAdopcion(string memory _nombre, string memory _especie, string memory _raza,
                                string memory _genero, string memory _color, uint8 _edad) private {
    contadorMascotas++;
    mascotas[contadorMascotas] = 
    Mascota(contadorMascotas, address(0), _nombre, _especie, _raza, _genero, _color, _edad, false);
}

//funcion interna de apoyo para validar que el identificador de la mascota
//  este dentro del rango de la lista
function validaIdentificadorMascota(uint8 _idMascota) private view {
    require(mascotas[_idMascota].id >= 1 && mascotas[_idMascota].id <= contadorMascotas, 
        "El identificador de mascota introducido no esta registrado");
}

//funcion interna de apoyo para validar que solo el administrador o el
//  dueno de la mascota puedan realizar una operacion del contrato
function validaAdministradorODueno(uint8 _idMascota) private view {
    if (msg.sender != administradorEvento && msg.sender != mascotas[_idMascota].dueno) {
        revert("Solo el administrador del evento o el dueno pueden realizar esta accion");
    }
}

//funcion publica para realizar el cambio de dueno de una mascota, tras haber validado requisitos
function cambiaDuenoMascota(uint8 _idMascota, address _nuevoDueno) public returns (string memory){
    validaIdentificadorMascota(_idMascota);
    validaAdministradorODueno(_idMascota);
    mascotas[_idMascota].dueno = _nuevoDueno;
    return "El dueno de la mascota fue actualizada";
}

//funcion publica para realizar el cambio de nombre de una mascota, tras haber validado requisitos
function cambiaNombreMascota(uint8 _idMascota, string memory _nuevoNombre) public returns (string memory){
    validaIdentificadorMascota(_idMascota);
    validaAdministradorODueno(_idMascota);
    mascotas[_idMascota].nombre = _nuevoNombre;
    return "El nombre de la mascota fue actualizada";
}

//funcion publica para realizar el cambio de edad de una mascota, tras haber validado requisitos
function cambiaEdadMascota(uint8 _idMascota, uint8 _nuevaEdad) public returns (string memory){
    validaIdentificadorMascota(_idMascota); 
    validaAdministradorODueno(_idMascota);
    //adicionalmente, la edad no debe ser menor a la ya definida y tendra un limite de 25
    if (_nuevaEdad <= mascotas[_idMascota].edad || _nuevaEdad > 25) {
        revert("La edad introducida no es valida");
    }
    mascotas[_idMascota].edad = _nuevaEdad;
    return "La edad de la mascota fue actualizada";
}

//funcion publica para actualizar el estado de esterilizacion de una mascota, 
//  tras haber validado requisitos
function esterilizaMascota(uint8 _idMascota) public returns (string memory){
    validaIdentificadorMascota(_idMascota);
    validaAdministradorODueno(_idMascota);
    //adicionalmente, el estado solo podra ser actualizado a verdadero una vez
    require(!mascotas[_idMascota].esterilizada, "La mascota ya esta esterilizada");    
    mascotas[_idMascota].esterilizada = true;
    return "La mascota fue esterilizada";
}

}