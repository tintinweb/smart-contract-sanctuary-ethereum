/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
  * @title PokemonFactory
  * @dev Reto Solidity Smart Contract del Platzi Ethereum Developer Program, by Carlos J. Ramirez 
  * @custom:dev-run-script file_path
  */

contract PokemonFactory {

    // Enum and Structures definition

    enum PokemonType {
      NoWeakness,
      Normal,
      Fire,
      Water,
      Grass,
      Electric,
      Ice,
      Fighting,
      Poison,
      Ground,
      Flying,
      Psychic,
      Bug,
      Rock,
      Ghost,
      Dark,
      Dragon,
      Steel,
      Fairy
    }

    struct Ability {
      string name;
      string description;
    }

    struct Pokemon {
      uint id;
      string name;
    }

    // Events definition
    
    event eventNewPokemon(
        Pokemon _pokemon,
        uint pokemonIndex
    );
    // Si se hubiese agregado el resto de la data, daria error de compilacion:
    // `CompilerError: Stack too deep, try removing local variables.`
    // Ability _ability,
    // PokemonType _type,
    // PokemonType _weakness

    // State variables definition

    Pokemon[] private pokemons;

    mapping (uint => address) public pokemonToOwner;
    mapping (address => uint) ownerPokemonCount;

    mapping (uint => uint) idToPokemonIndex;
    mapping (uint => Ability[]) private pokemonToAbility;
    mapping (uint => PokemonType[]) private pokemonToType;
    mapping (uint => PokemonType[]) private pokemonToWeakness;
    mapping (uint => string[]) private pokemonToImage;

    // Validations definition

    modifier abilityMustBeSpecified(string memory _abilityName, string memory _abilityDescription) {
      require(bytes(_abilityName).length > 0, "Ability name must be specified");
      require(bytes(_abilityDescription).length > 0, "Ability description must be specified");
      _;
    }

    modifier idGreaterThanZero(uint _id) {
      require(_id > 0, "Id must be greater than zero");
      _;
    }

    modifier validName(string memory _name) {
      require(bytes(_name).length > 2, "Name cannot be empty and must be greater than 2 characters");
      _;
    }

    modifier isAuthor(uint _id) {
      require(msg.sender == pokemonToOwner[_id], "You cannot modify this Pokemon's data because you are not the original author");
      _;
    }

    // Pokemon Functions

    function createPokemon (
        string memory _name,
        uint _id,
        string memory _abilityName,
        string memory _abilityDescription,
        PokemonType _type,
        PokemonType _weakness,
        string memory _image
      ) public
        idGreaterThanZero(_id)
        validName(_name)
        abilityMustBeSpecified(_abilityName, _abilityDescription)
      {
        Pokemon memory pokemon = Pokemon(_id, _name);
        pokemons.push(pokemon);
        pokemonToOwner[_id] = msg.sender;
        ownerPokemonCount[msg.sender]++;
        idToPokemonIndex[_id] = pokemons.length-1;
        pokemonToAbility[_id].push(Ability(_abilityName, _abilityDescription));
        pokemonToType[_id].push(_type);
        pokemonToWeakness[_id].push(_weakness);
        pokemonToImage[_id].push(_image);
        // emit eventNewPokemon(pokemon, idToPokemonIndex[_id], pokemonToAbility[_id][0], pokemonToType[_id][0], pokemonToWeakness[_id][0]);
        emit eventNewPokemon(pokemon, idToPokemonIndex[_id]);
    }

    function getAllPokemons() public view returns (Pokemon[] memory) {
      return pokemons;
    }

    function getPokemonById(uint _id) public view returns (Pokemon memory) {
      return pokemons[idToPokemonIndex[_id]];
    }

    // Pokemon Ability Functions

    function addAbilityToPokemon(
      uint _id,
      string memory _abilityName,
      string memory _abilityDescription
    ) public 
      isAuthor(_id)
    {
      pokemonToAbility[_id].push(Ability(_abilityName, _abilityDescription));
    }

    function removeAbilityFromPokemon(
      uint _id,
      uint _index
    ) public 
      isAuthor(_id)
    {
      delete pokemonToAbility[_id][_index];
    }

    function getPokemonAbilities(uint _id) public view returns (Ability[] memory) {
      return pokemonToAbility[_id];
    }

    // Pokemon Types Functions

    function addTypeToPokemon(
      uint _id,
      PokemonType _type
    ) public 
      isAuthor(_id)
    {
      pokemonToType[_id].push(_type);
    }

    function removeTypeFromPokemon(
      uint _id,
      uint _index
    ) public 
      isAuthor(_id)
    {
      delete pokemonToType[_id][_index];
    }

    function getPokemonTypes(uint _id) public view returns (PokemonType[] memory) {
      return pokemonToType[_id];
    }

    // Pokemon Weaknesses Functions

    function addWeaknessToPokemon(
      uint _id,
      PokemonType _type
    ) public 
      isAuthor(_id)
    {
      pokemonToWeakness[_id].push(_type);
    }

    function removeWeaknessFromPokemon(
      uint _id,
      uint _index
    ) public 
      isAuthor(_id)
    {
      delete pokemonToWeakness[_id][_index];
    }

    function getPokemonWeaknesses(uint _id) public view returns (PokemonType[] memory) {
      return pokemonToWeakness[_id];
    }

    // Image Functions

    function addImageToPokemon(
      uint _id,
      string memory _image
    ) public 
      isAuthor(_id)
    {
      pokemonToImage[_id].push(_image);
    }

    function removeImageFromPokemon(
      uint _id,
      uint _index
    ) public 
      isAuthor(_id)
    {
      delete pokemonToImage[_id][_index];
    }

    function getPokemonImages(uint _id) public view returns (string[] memory) {
      return pokemonToImage[_id];
    }

    // Other functions

    function getResult() public pure returns(uint product, uint sum){
      uint a = 1; 
      uint b = 2;
      product = a * b;
      sum = a + b; 
   }

}