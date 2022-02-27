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
    Zombie[] private zombies;

    /**mappings */
    //Los mappings son una estructura de datos de solidity que nos permite guardar pares key=>value.
    //Se almacenan similar a como se almacenaría en un array (de por si, almacenamos la información)
    //de manera similar "mappedValue[key]=value;".
    //La principal diferencia entre los mappings y los arrays es que los mappings no se pueden recorrer,
    //solo podemos acceder al valor del mapping si conocemos su key.

    //Inicializando mapping
    mapping(uint256 => address) public zombieToOwner;
    // ^ Para crear un mapping tenemos que realizarlo como se observa en el código anterior.
    // dentro de los paréntesis indicamos primero el tipo de dato que será la "key" y después
    //de la flecha el tipo de dato que será almacenado en el value.
    //En el ejemplo superior observamos que la key sera "uint256" y el value será un "address".

    //Apuntador de zombies
    mapping(address => uint256) public ownerZombieCount;

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

        /** msg.sender */
        //Solidity tiene una serie de variables globales que nos ofrecen caracteristicas propias de la blockchain.
        //En este caso tenemos "msg.sender". Cuando utilizamos un contrato inteligente de ethereum este contrato
        //al momento de crearse y almacenarse en la cadena, permanece inactivo hasta que otra cuenta active dicho contrato.
        //Esto nos permite que cierta información siempre se encuentre presente en los contratos como puede ser "msg.sender".
        //Como hemos dicho que un contrato siempre debe ser activado por una cuenta (address) externa (ya sea de un address personal
        //o el adress de otro contrato), la propiedad "msg.sender" siempre debe estar presente en la ejecución.
        //"msg.sender" devuelve el address que esta ejecutando dicho contrato inteligente.

        //En este caso almacenaremos usando como key el id del zombie a su contrato propietario. De esta manera podemos asignar a cada
        //zombie un uncio propietario.
        zombieToOwner[id] = msg.sender;

        //Como ownerZombieCount es un valor de tipo uint256 podemos usar los operadores mátematicos de dicho tipo de dato.
        //En este caso solo aumentaremos el número de zombies que posee el address.
        ownerZombieCount[msg.sender]++;

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
        /** require.require */
        //require es una estructura de control parecida a la condición "if" el cual si su sentencia no es verdadera devuelve un error.
        //la diferencia es que en el caso de que la condición sea "false" revertirá todos los cambios que se hayan hecho en los espacios de memoria de la blockchain.
        //require se efectua de la siguiente manera:
        //require(EVALUACIÓN, MENSAJE_DE_ERROR)
        // ^ la evaluación pasará si es true, de lo contrario, devolverá el error indicado como segundo argumento.

        //usando require en este contrato.
        require(ownerZombieCount[msg.sender] == 0, "Esta cuenta ya tiene un zombie asignado");

        uint256 randDna = _generateRandomDna(_name);
        _createZombie(_name, randDna);
    }

    event NewZombie(uint256 zombieId, string name, uint256 dna);
}