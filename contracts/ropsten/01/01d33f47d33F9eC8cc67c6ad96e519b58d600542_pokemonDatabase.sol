/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.3;

contract pokemonDatabase{

    uint public totalPokemonCount;
    uint public randNonce;

    struct Pokemon{
        string name;
        uint id;
        uint stars;
    }

    string[] public begginerPokemon = ["pikachu","charmander","squirtle","bulbasaur"];

    Pokemon[] public pokemons;

    mapping (uint => address) public pokemonToOwner;
    mapping (address => uint) ownerPokemonCount;

    function createNewPokemon() public {
        pokemonToOwner[totalPokemonCount] = msg.sender;
        totalPokemonCount++;
        pokemons.push(Pokemon(begginerPokemon[_generateRandom()],totalPokemonCount,1));
        ownerPokemonCount[msg.sender] += 1;
        
    }

    function _generateRandom() private returns (uint) {
        randNonce++;
        uint rand = uint(keccak256(abi.encodePacked(msg.sender))) + totalPokemonCount + randNonce;
        return rand % begginerPokemon.length;
    }

    function getPokemonCountByOwner(address _owner) public view returns(uint){
        return uint(ownerPokemonCount[_owner]);
    }

    function getPokemonByOwner(address _owner) external view returns(uint[] memory){
        uint[] memory result = new uint[](ownerPokemonCount[_owner]);
        uint counter = 0;
        for (uint i=0; i<totalPokemonCount ; i++){
            if(pokemonToOwner[i] == msg.sender){
                result[counter] = (i);
                counter++;
            }
        }
        return result;
    }

}