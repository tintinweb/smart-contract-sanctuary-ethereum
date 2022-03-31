/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

//SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.9.2 https://hardhat.org

// File contracts/Votaciones.sol

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2; // Es necesaria para calcular los hashes

contract Votaciones {
    // Dirección del propietario del contrato
    address public owner;

    constructor () {
        owner = msg.sender; // Con este constructor tomamos la dirección del dueño que desplegó el contrato.
    }

    // Creamos una relación entre el nombre del candidato y un hash de los datos del usuario
    mapping (string => bytes32) id_candidato; // Que es un mapping: Es un tipo de declaración para crear asociaciones, lo que permite relacionar dos valores que serían la clave y el valor.

    // Relación entre el nombre del candidato y el número de votos.
    mapping (string => uint) votos_candidatos; 

    // Lista de los candidatos
    string [] candidatos;

    /* 
    * Almacenamos una listas de los votantes, considerando la provacidad y el anonimato de los votantes , para ello almacenaremos el hash de la dirección
    * con esto podremos identificar si el votante ya realizó el voto.
    */
    bytes32 [] votantes;

    // Esta función se encargará de postular a los candidatos.
    // ------
    /**
        Las variables de tipo string deben ser eliminadas de memoria al momento de ejecutarse. 
         por lo que es importante agregar el atributo memory, de esta forma le indicamos a solidity que se eliminará el 
        string de memoría y no tendremos errores al momento de compilar y desplegar nuestro contrato. 
        Otra forma declara nuestro parámetro en nuestra función son:

        - storage: la variable es una variable de estado (almacenada en blockchain) 
        - memory: la variable está en la memoria y existe mientras se llama a una función 
        - calldata: ubicación de datos especial que contiene argumentos de función
     */

    function Postular(string memory _nombreCandidato, uint _edadCandidato, string memory _idCandidato) public  {
        /**
            Calcularemos el hash de todos sus datos personales y los asociaremos al nombr4 del candidato,
            Recordaremos que el hash es un dato de tipo bytes.
         */
         bytes32 hash_candidato = keccak256(abi.encodePacked(_nombreCandidato, _edadCandidato, _idCandidato)); // Con esta librería podemos calcular el hash de nuestros datos.

         /**
            Almacenaremos el hash de los detos del candidato y los relacionaremos con el no bre del candidato.
            Para eso utilizaremos la variables que creamos de tipo mapping
          */

        id_candidato[_nombreCandidato] = hash_candidato;

        /**
            Ahora actualizaremos la lista de los candidatos 
            y para ello usaremos la variable de tipo array de string
         */

         candidatos.push(_nombreCandidato);
    }

     /**
        Crearemos una función que se encargará de poder mostrar los candidatos, esta debe ser pública para que
        cualquier pueda ver la función.

        Esta función será de tipo view y retornará un array de string y para ello agregaremos el atributo returns
        
      */
    function VerCandidatos() public view returns(string[] memory){
        //Devuelve la lista de los candidatos presentados
        return candidatos;
    }

    /**  
        Los votantes van a poder votar por el candidato, por lo cual, se declara esta función como publica para que pueda ser accedido 
        ademas esta no retornará nada por lo que no es necesario declarar la función como view.

    */

    function Votar(string memory _candidato) public {
        
        //Hash de la direccion de la persona que ejecuta esta funcion
        bytes32 hash_Votante = keccak256(abi.encodePacked(msg.sender));
        //Verificamos si el votante ya ha votado
        for(uint i = 0; i < votantes.length; i++){
            require(votantes[i] != hash_Votante, "Ya has votado previamente");
        }
        //Almacenamos el hash del votante dentro del array de votantes
        votantes.push(hash_Votante);
        //Añadimos un voto al candidato seleccionado
        votos_candidatos[_candidato]++;
    }

      //Dado el nombre de un candidato nos devuelve el numero de votos que tiene
    function VerVotos(string memory _candidato) public view returns(uint){
        //Devolviendo el numero de votos del candidato _candidato
        return votos_candidatos[_candidato];
    }

    //Funcion auxiliar que transforma un uint a un string
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    //Ver los votos de cada uno de los candidatos
    function VerResultados() public view returns(string memory){
        //Guardamos en una variable string los candidatos con sus respectivos votos
        string memory resultados = "";
        
        //Recorremos el array de candidatos para actualizar el string resultados
        for(uint i=0; i < candidatos.length; i++){
            //Actualizamos el string resultados y añadimos el candidato que ocupa la posicion "i" del array candidatos
            //y su numero de votos
            resultados = string(abi.encodePacked(resultados, "(", candidatos[i], ", ", uint2str(VerVotos(candidatos[i])), ") -----"));
        }
        
        //Devolvemos los resultados
        return resultados;
    }

    //Proporcionar el nombre del candidato ganador
    function Ganador() public view returns(string memory){
        
        //La variable ganador contendra el nombre del candidato ganador 
        string memory ganador= candidatos[0];
        bool flag;
        
        //Recorremos el array de candidatos para determinar el candidato con un numero de votos mayor
        for(uint i=1; i < candidatos.length; i++){
            
            if (votos_candidatos[ganador] < votos_candidatos[candidatos[i]]){
                ganador = candidatos[i];
                flag = false;
            } else {
                if(votos_candidatos[ganador] == votos_candidatos[candidatos[i]]){
                    flag=true;
                }
            }
        }
        
        if(flag == true){
            ganador = 'Hay empate entre los candidatos!';
            
        }
        return ganador;
    }

}