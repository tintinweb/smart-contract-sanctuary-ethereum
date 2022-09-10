// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Register is Ownable{
//определение id компании по адресу 
mapping (address => uint256) public Connect;

//определение количества игр в компании по адресу 
mapping (address => uint256) public num_Game;


//поиск аккаунтов  по id 
mapping (uint256 => Struct_A) public Account;

//поиск по id студии + id игры
mapping (uint256 => mapping (uint256 => Struct_G)) public AccountGame;

uint256 public Commission_A = 1000000000000;
uint256 public Com_Rename_A = 1000000000000;  

uint256 public Commission_G = 1000000000000;

struct Struct_A{
address payable Address;
string NameStudio;
string SiteStudio; 
uint256 TotalGames;
}

//Blockchain (1.Etherium) (2.BSC) (3.Poligon) (4.Optimism) (5.Solana) (6.Tron) (7.Cosmos)
//Category (1.Action)(2.Arcade)(3.Strategy)(4.Adventure)(5.Educational)(6.Quest)(7.Interactive Fiction)(8.RPG)(9.Fighting)(10.Racing)(11.Simulation)(12.Sports)(13.Puzzle)(14.Tabletop)(15.Other)

struct Struct_G{
address payable Address;
string Name_Game;
string Description_Game;
uint256 Blockchain; 
uint256 Category;
}

uint256 public ID;


function Create_Studio (string memory _NameStudio, string memory _SiteStudio) payable public {
    require(msg.value >= Commission_A,"Incorrect ticket price");
    require ( Connect[msg.sender] <= 0,"There is already a company at this address");
ID++;
Struct_A memory newAccount;
newAccount.Address = payable(msg.sender);
newAccount.NameStudio = _NameStudio;
newAccount.SiteStudio = _SiteStudio;

Account[ID] = newAccount;

Connect[payable(msg.sender)] = ID;
}

function Create_Game (
string memory _NameGame,
string memory _Description_Game, 
uint256 _Blockchain,
uint256 _Category) payable public {
    require ( Connect[msg.sender] > 0,"no company");
    require(msg.value >= Commission_G,"Incorrect ticket price");


num_Game[msg.sender] = num_Game[msg.sender]+ 1;

Account[Connect[msg.sender]].TotalGames = num_Game[msg.sender];

Struct_G memory newGame;
newGame.Address = payable(msg.sender);
newGame.Name_Game = _NameGame;
newGame.Description_Game = _Description_Game;
newGame.Blockchain = _Blockchain;
newGame.Category = _Category;

AccountGame[Connect[msg.sender]][num_Game[msg.sender]] = newGame;
}

//Set studio-------------------------------------------------------

function setNameStudio (string memory newName) payable public{
    require(msg.value >= Com_Rename_A,"Incorrect ticket price");
Account[Connect[msg.sender]].NameStudio = newName;
}

function setSiteStudio (string memory newSite) payable public{
    require(msg.value >= Com_Rename_A,"Incorrect ticket price");
Account[Connect[msg.sender]].SiteStudio = newSite;
}


//only owner---------------------------------------------------------

function setCommission_A(uint256 _newCommission) public  onlyOwner{
    Commission_A = _newCommission;
}

function setCom_Rename_A(uint256 _Com_Rename_A) public  onlyOwner{
    Com_Rename_A = _Com_Rename_A;
}

function setCommission_G(uint256 _newCommission) public onlyOwner {
    Commission_G = _newCommission;
}

function withdraw() public payable onlyOwner{
(bool hs, ) = payable(msg.sender).call{value: address(this).balance}("");
require(hs);
}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}