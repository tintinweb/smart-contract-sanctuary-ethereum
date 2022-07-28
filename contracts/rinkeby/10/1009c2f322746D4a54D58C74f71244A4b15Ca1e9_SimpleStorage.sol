//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favoriteNumber;

    //struct comme en C
    struct People{
        uint256 favoriteNumber;
        string name;
    }

    //array dynamique (en faisant [N] on choisit un array de taille limité)
    People[] public people;

    //mapping
    mapping(string => uint256) public nameToFavoriteNumber;

    //On utilise "virtual" comme en C++  pour dire qu'une classe fille peut réecrire cette function
    //en utilisant override
    function store(uint256 _favoriteNulber) public virtual{
        favoriteNumber = _favoriteNulber;
        //if a view function is called on a gaz function then the gaz function will cost more
        //even if the view function don't modiy the BC (calling a pure function does not cost you more)
        retrieve();
    }

    //view don't mofify the BC it's just a getter
    function retrieve() public view returns(uint256){
        return favoriteNumber;
    }

    //pure don't mofify the BC but it's not a getter
    function add() public pure returns(uint256)
    {
        return (1+1);
    }

    //lorsque l'on passe un array, une struct ou un string (qui est juste un array) en paramètre d'une fonction
    // on utilise memory si on veut modifier le parametre
    // calldata si on veut ne pas pouvoir le modifier
    function addPerson(string memory _name, uint256 _favoriteNumber) public
    {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}