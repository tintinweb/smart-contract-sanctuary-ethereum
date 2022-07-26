//SPDX-License-Identifier: MIT
//https://rinkeby.etherscan.io/address/0x53904D61D437853f887c94a725D245207048654C#code
pragma solidity ^0.8.7;

contract PokemonFactory {
    struct Pokemon {
        uint256 id;
        string name;
        string image;
        Ability[] abilities;
        string[] types;
        string[] weaknesses;
    }

    struct Ability {
        string name;
        string description;
    }

    Pokemon[] public pokemons;
    string[] private types;

    mapping(uint256 => address) public pokemonToOwner;
    mapping(address => Pokemon[]) pokedex; //ownerToPokemons
    mapping(address => uint256) ownerPokemonCount;

    mapping(string => string[]) private typesToWeaknesses;

    event eventNewPokemon(Pokemon indexed eventNewPokemon);

    modifier isPokemonValid(uint256 _id, string calldata _name) {
        require(_id > 0, "Debe seleccionar un id valido para el pokemon");
        require(bytes(_name).length > 2, "El nombre debe ser mayor a 2 carateres");
        _;

        require(types.length > 0, "Debe insertar tipos de pokemon");
        _;
    }

    function createPokemon(
        uint256 _id,
        string calldata _name,
        string calldata _image,
        string[] calldata _namesAbility,
        string[] calldata _descripsAbility,
        string[] memory _types_name
    ) public isPokemonValid(_id, _name) {
        uint256 index = pokemons.length;
        pokemons.push();
        pokemons[index].id = _id;
        pokemons[index].name = _name;
        pokemons[index].image = _image;

        for (uint256 i = 0; i < _namesAbility.length; i++) {
            pokemons[index].abilities.push(Ability(_namesAbility[i], _descripsAbility[i]));
        }

        pokemons[index].types = _types_name;

        for (uint256 j = 0; j < _types_name.length; j++) {
            string[] memory weaknesses = typesToWeaknesses[_types_name[j]];
            pokemons[index].weaknesses = weaknesses;
        }

        pokedex[msg.sender].push(pokemons[index]);

        emit eventNewPokemon(pokemons[index]);
    }

    function createTypesToWeaknesses(string calldata _type, string[] memory _weaknesses) public {
        types.push(_type);
        typesToWeaknesses[_type] = _weaknesses;
    }

    function getAllTypes() public view returns (string[] memory) {
        return types;
    }

    function getWeaknessesByType(string memory _type) public view returns (string[] memory) {
        return typesToWeaknesses[_type];
    }

    function getMyPokemons() public view returns (Pokemon[] memory) {
        return pokedex[msg.sender];
    }

    function getAllPokemons() public view returns (Pokemon[] memory) {
        return pokemons;
    }
}