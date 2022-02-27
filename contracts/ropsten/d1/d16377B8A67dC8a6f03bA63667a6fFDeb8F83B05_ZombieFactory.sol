/**
 *Submitted for verification at Etherscan.io on 2022-02-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

//solidity es un lenguaje de tipado estático.

/**
 *  Las primeras dos líneas del contrato constan de la licencia del contrato
 *  y de la versión del compilador que deseamos utilizar.
 */

/**
 * Luego se inicializa el contrato con la palabra clave "contract" y el namespace del mismo.
 */
contract ZombieFactory {
    /**
     * Variables de estado: Son las variables que se almacenan en la blockchain de manera
     *      predeterminada. Esto lo declaramos de dos formas: memory y storage, pero eso lo veremos más
     *      adelante. Lo que nos permiten esas kw es declarar si se va a almacenar en el momento de la
     *      ejecución o directamente en la blockchain.
     */
    uint256 dnaDigits = 16;
    /**
     * Operadores matemáticos: Similar a js. x - x, x + x, x **, etc...
     */

    uint256 dnaModulus = 10**dnaDigits;

    //strutcs: Las estructs son parecidas a las de typescrypt. Esto nos permite crear tipos de datos complejos.
    /**TIPOS DE DATOS */
    struct Zombie {
        string name;
        uint256 dna;
    }

    //arrays: Similar a trabajar con js o java. Una característica interesante es que podemos definir el tamaño de
    //un array declarandolo en el tipo ej: "uint[2] arrayLimitado;" con el anterior snippet declaramos un array de
    //limite 2 de length. Si no definimos ningún límite el array no tiene limites y podemos insertar todos los datos
    //que querramos.

    /**KW Públic */
    //la kw public permite que ese dato pueda ser accedido de manera pública y cualquier persona pueda interactuar con él.
    //Esta kw también funciona con las funciones declarando que esta pueda ser ejecutada desde cualquier lugar de la red.

    //arrays de structs: Podemos declarar arrays de los structs que hayamos definido
    Zombie[] public zombies;

    /**Functions */
    //Las funciones son similares a cualquier función de cualquier lenguaje  de programación pudiendo definir que argumentos
    //recibe y que valores retorna.

    //convención. Por convención no oficial pero como buena práctica, los parámetros de la función los definimos con un "_"
    //al inicio del namespace para diferenciar las variables propias de la función y las del contrato en sí.

    function _createZombie(string memory _name, uint256 _dna) private {
        //Insertar un zombie en el array de zombies
        zombies.push(Zombie(_name, _dna));
        //Como podemos observar en el código superior, usamos el struct enviandole los dos parámetros que necesita para crear el
        //dato. Luego esa struct la pusheamos en el array de zombies.

        // La propiedad array.length devuelve el tamaño total del array. Solidity también es de inicio de indice 0
        uint256 id = zombies.length - 1;

        //De esta manera lanzamos el evento que hemos declarado al final del contrato. Por lo que veo. Los contratos de solidity
        //también permite realizar el uso de los hoistings.
        emit NewZombie(id, _name, _dna);
    }

    function _generateRandomDna(string memory _str)
        private
        view
        returns (uint256)
    {
        //Para esta versión de solidity "0.8.12" para evitar el error usamos el método encode de abi.
        uint256 rand = uint256(keccak256(abi.encode(_str)));
        return rand % dnaModulus;
    }

    function createRandomZombie(string memory _name) public {
        uint256 randDna = _generateRandomDna(_name);
        _createZombie(_name, randDna);
    }

    event NewZombie(uint256 zombieId, string name, uint256 dna);
}