// SPDX-License-Identifier: MIT
//pragma solidity 0.8.8;

pragma solidity ^0.8.7;

contract SimpleStorage {
    //<tipo> <visibilidad> <nombre de variable>
    uint256 favoriteNumber;

    //mapping (entrego un string y me devuelve un numero)
    //nameToFavoriteNumber es un array (un estilo de diccionario) con key = string y value = uint256
    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //People public person = People({favoriteNumber:8, name:"Jorge"});
    //People en mayuscula es el tipo de dato, people en minuscula es la variable en si
    //[] indica array dinamico (sin tamaño especificado)  [3] indica un array de hay 3 elementos.
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //hay 2 maneras de crear una persona
        //1A==> creando una variable con la instancia del objeto
        // Esta opcion es con los {} y especificando como asignar cada variable
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        people.push(newPerson);

        //1B==> creando una variable con la instancia del objeto
        // Esta opcion es sin los {} pero los parametros deben estar en orden
        //People memory newPerson = People({_favoriteNumber,_name});
        //people.push(newPerson);

        //2==> dinamicamente
        //people.push(People(_favoriteNumber,_name));

        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}