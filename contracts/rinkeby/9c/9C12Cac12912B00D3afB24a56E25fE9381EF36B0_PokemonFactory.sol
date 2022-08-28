// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract PokemonFactory {
    address owner;
    Pokemon[] pokemonsArray;
    mapping(string => uint) pokemonNameToPowerMap;

    struct Pokemon {
        string name;
        uint256 power;
    }

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function createPokemon(Pokemon memory _pokemon) public onlyOwner {
        pokemonsArray.push(_pokemon);
        pokemonNameToPowerMap[_pokemon.name] = _pokemon.power;
    }

    function getPokemonAtIndex(uint256 _index)
        public
        view
        returns (Pokemon memory)
    {
        return pokemonsArray[_index];
    }
}