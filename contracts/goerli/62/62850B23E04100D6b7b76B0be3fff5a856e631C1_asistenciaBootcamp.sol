/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// File: contracts/asistenciaBootcamp.sol

//SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;


    //Los usuarios han de poder marcar que han asistido a una clase, cada clase tendrá un id ( numero )
    //El smart contract tendrá que guardar el propietario del mismo
    //función privada
    //función de crear nueva clase que solo pueda llamar el owner ( modificador )
    //contador de clases


    //Modificaciones 28/02/22 para añadir funcionalidades:
    //- Lista de alumnos verificados (validados por el owner)
    //- Modifier para que haya que ser alumno verificado para apuntarse a clase
    //- Creación de pseudotoken
    //- Aumentar el saldo de token de los alumnos cuando se apuntan a una clase
    //- Añadir una función para canjear los tokens


contract asistenciaBootcamp {


    //Definición de variables
    //Value types
    uint256 public contadorClases;
    uint256 public Disrup3TSupply;
    address public owner;
    //Mappings
    mapping(uint256 => mapping(address => bool)) public listaAsistencia;
    mapping(address => bool) public listaAlumnos;
    mapping(address => uint256) public saldoAlumnos;
    //String
    string private mensaje_canjear;
    string private mensaje_error_canjear;


    //Modificadores
    //Verificar que msg.sender es el owner
    modifier esPropietario ()
    {
        require (msg.sender == owner, "No eres el propietario del contrato");
        _;
    }
    //Verificar que msg.sender es alumno
    modifier esAlumno ()
    {
        require (listaAlumnos[msg.sender] == true, "No eres alumno del bootcamp");
        _;
    }


    //Constructor del contrato
    constructor (){
        owner = msg.sender;
        mensaje_canjear = "Token canjeado, Alexfu te debe una cerveza";
        mensaje_error_canjear = "No tienes suficiente saldo, no puedes canjear tu cerveza";
        //Se crea un pseudotoken, se "mintean" 10 tokens/clase (cantidad estimada en base al # de alumnos)
        Disrup3TSupply = 10;
    }


    //Funcion para añadir una clase
    function addClase () external esPropietario{
        //Incrementamos el contador de la clase en 1
        contadorClases++;
        //Incrementamos el supply del token en 10
        Disrup3TSupply+=10;
    }
   
    //Funcion para añadir un alumno a la lista de alumnos verificados
    function verificarAlumno (address direccionalumno) external esPropietario{
        listaAlumnos[direccionalumno]=true;
        //Creo que es necesario actualizar el mapeo de cada clase individualmente (puede ser que no)
        for (uint i=0; i<=contadorClases;i++){
            listaAsistencia[i][direccionalumno]=false;
        }
    }
    //Funcion para apuntarte a una clase
    function apuntarseClase () public esAlumno{
        //Comprobación para que un alumno no pueda apuntarse 2 veces a la misma clase (y no reciba tokens de más).
        if (listaAsistencia[contadorClases][msg.sender]==false){
            listaAsistencia[contadorClases][msg.sender]=true;
            saldoAlumnos[msg.sender]++;
        }
        else {
            revert ("Ya estas dado de alta en la clase");
            }
    }


    //Funcion para convertir tokens en cervezas
    function canjearToken () public esAlumno returns (string memory){
        if (saldoAlumnos[msg.sender]>0){
            saldoAlumnos[msg.sender]--;
            //No consigo mostrar el mensaje en el frontend :(
            return mensaje_canjear;
        }
        //No consigo mostrar el mensaje en el frontend :(
        return mensaje_error_canjear;
    }
}