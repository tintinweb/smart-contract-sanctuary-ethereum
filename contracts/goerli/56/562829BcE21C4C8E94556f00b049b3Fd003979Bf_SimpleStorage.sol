/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: MIT

// EVM significa, Ethereum Virtual Machine. Hay otras Layer 2 blockchain que permiten EVM por lo que podemos compliar Solidity
// en estas layers. Por ejemplo: Avalanche, Fantom, Polygon

pragma solidity ^0.8.7; // The newst is 0.8.12, but more stable 0.8.7

/*contract TypesofSolidity {
    // Types of solidity
    //Boolean, uint, int, address, bytes
    // Usamos estos types para crear variables.
    //Por ejemplo-->

    bool hasFavoriteNumber = true;
    uint256 favoriteNumber = 5; // uint se presenta en bits y va de 8 a 256 bits. Si no especificamos irá a 256
    int8 Number = -10; //
    string favoriteNumberInText = "Hola socio";
    address myAdress = 0xB227673c8Fb86B8a9178d9E42A22fCF9321aFBBF;
    bytes32 favoriteBytes = "cat"; // Bytes el máximo es 32, pues es igual a 256 bits.
}*/

contract SimpleStorage {
    uint256 favoriteNumber; //Si no ponemos nada , será igual a 0.

    //Arrays and Struc

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People public person = People({favoriteNumber: 2, name: "Perez"});

    People person2 = People({favoriteNumber: 4, name: "Ali"});
    People person3 = People({favoriteNumber: 7, name: "Paum"});

    // Crear una lista de struct People persons like that is not worth it. Better crear un array

    People[] public people; // Ahora gente es un array

    // Vamos a crear a function para meter gente al array

    function addPeople(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        //Añadimos aqui el mapping nameToFavoriteNumber
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    //creemos una function

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //Hay varios estados ya sean Public, Private, Intern or Extern

    //Hay otros como son view y pure que se utilizan solo para ver algo del contrato y no gastan GAS
    // Solo las functions qe cambian la Bolckchain de algún modo, cuestan dinero.por eso view no cuesta.

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //There are 6 places where you can store information n solidity: Stack, Memory, Storage, Calldata, Code, Logs

    //Para comenzar nos vamos a centrar en 3 de ellas--> calldata, memory y storage

    // Calldata se usa para variables en funciones concretas y no permanentes y que no se pueden variar.
    // Memory se usa para variables que si se pueden modificar y que son temporales.
    // Storage se usa para variables que se estipulan a nivel global, no intrinsecas a una funcion concreta.
    // La teoria nos dice que debemos especificar donde se guarda la informcaion para Struct, Mapping y Arrays.
    // ¿Por qué debemos poner memory para String y no para uint256? Porque un string alfinal es un array de bits, por lo que debemos poner el memory

    //Hay una funcionalidad muy importante que son el mapping. Nos sirve para introducir solo un parametro del array y que nos saque su asociado
    // Mapping es como un diccionario, buscas la palabra(o lo que sea) y te dice lo que significa(en este caso un uint256, string, etc..)
    mapping(string => uint256) public nameToFavoriteNumber;
}