// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./Pokemon.sol";
import "./ERC1155.sol";
import "./Player.sol";

interface IGame{

    event TransferSingle(address indexed operator, address indexed from, address indexed to, address addressPokemon, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, address[] addressesPokemon, uint256[] values );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    function donate() external payable;
    function addPlayer() external;
    function checkData(address _clientAddress, string memory _nickname, string memory _password) external view returns(bool);
    function buyPokeballs(uint256 amount) external;
    function mintPokemon(address to, address addressPokemon, uint256 amount) external;
    function mintBatchPokemon(address to, address[] memory addressesPokemon, uint256[] memory amounts) external;
    function getPokemonPlayer(address addressPokemon) external view returns (address);
    function transferPokemon(address from, address to, address addressPokemon, uint256 amount, bytes calldata data) external;
    function transferBatchPokemon(address from, address to, address[] calldata addressesPokemon, uint256[] calldata amounts, bytes calldata data) external;
}

contract Game{
    address public owner;
    ERC1155 public token;

    mapping(address => address) owners;
    mapping(address => uint256) balancePokeballs;
    mapping(address => uint256) balance;
    mapping(address => mapping(string => mapping(string => bool))) isCorrectData;

    address[] public players;

    constructor(address ercAddress){
        owner = msg.sender;
        token = ERC1155(ercAddress);
    }

    function checkData(address _clientAddress, string memory _nickname, string memory _password) external view returns(bool){
        return isCorrectData[_clientAddress][_nickname][_password];
    }

    function addPlayer(address _clientAddress, string memory _nickname, string memory _password) external{
        players.push(msg.sender);
        isCorrectData[_clientAddress][_nickname][_password] = true;
    }

    function donate() external payable{
        balance[msg.sender] += msg.value;
    }

    function buyPokeballs(uint256 amount) external{
        require(balance[msg.sender] > 1000 * amount, "You don't have enough funds on the balance");
        balance[msg.sender] -= 1000 * amount;
        balancePokeballs[msg.sender] += amount;
    }

    function getPokemonPlayer(address addressPokemon) external view returns (address){
        return owners[addressPokemon];
    }

    function mintPokemon(address to, address addressPokemon, uint256 amount) external {
        require(balancePokeballs[msg.sender] >= amount, "You don't have enough pokeballs");
        owners[addressPokemon] = msg.sender;
        token.mint(Player(to).clientAddress(), IPokemon(addressPokemon).pokemonId(), amount);
        //emit TransferSingle(msg.sender, address(0), to, addressPokemon, amount);
    }

    function mintBatchPokemon(address to, address[] memory addressesPokemon, uint256[] memory amounts) external {
        //require(msg.sender == owner, "ERC1155: You are not owner");
        require(addressesPokemon.length == amounts.length, "The length of the tokenIds array is not equal to the length of the amounts array");
        uint256 sumAmouncts = 0;
        for(uint256 i = 0; i < amounts.length; i++)
            sumAmouncts += amounts[i];
        require(balancePokeballs[to] >= sumAmouncts, "You don't have enough pokeballs");
        uint256[] memory _tokenIds = new uint256[](amounts.length);
        for(uint256 i = 0; i < addressesPokemon.length; i++){
            uint256 _tokenId = IPokemon(addressesPokemon[i]).pokemonId();
            _tokenIds[i] = _tokenId;
            owners[addressesPokemon[i]] = to;

        }
        token.mintBatch(Player(to).clientAddress(), _tokenIds, amounts);
        //emit TransferBatch(msg.sender, address(0), to, addressesPokemon, amounts);
    }

    function transferPokemon(
        address from,
        address to,
        address addressPokemon,
        uint256 amount,
        bytes memory data
    ) external {
        uint256 _tokenId = IPokemon(addressPokemon).pokemonId();
        token.safeTransferFrom(Player(from).clientAddress(), Player(to).clientAddress(), _tokenId, amount, data);
        owners[addressPokemon] = to;
        //emit TransferSingle(msg.sender, from, to, addressPokemon, amount);
    }

    function transferBatchPokemon(
        address from,
        address to,
        address[] memory addressesPokemon,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        uint256[] memory _tokenIds = new uint256[](amounts.length);
        for(uint256 i = 0; i < addressesPokemon.length; i++){
            uint256 _tokenId = IPokemon(addressesPokemon[i]).pokemonId();
            _tokenIds[i] = _tokenId;
            owners[addressesPokemon[i]] = to;
        }
        token.safeBatchTransferFrom(Player(from).clientAddress(), Player(to).clientAddress(), _tokenIds, amounts, data);

        //emit TransferBatch(msg.sender, from, to, addressesPokemon, amounts);
    }

}