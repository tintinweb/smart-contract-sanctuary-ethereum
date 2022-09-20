/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// SPDX-License-Identifier: GPL-3.0
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////                                                                                                                                             /////////////////////
//   ███████╗ ██████╗ █████╗ ██████╗ ██╗   ██╗███████╗██╗    ██╗ █████╗ ██████╗ ███╗   ███╗ █████╗ ██████╗ ██╗  ██╗███████╗████████╗██████╗ ██╗      █████╗  ██████╗███████╗   ////////
//   ██╔════╝██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝██╔════╝██║    ██║██╔══██╗██╔══██╗████╗ ████║██╔══██╗██╔══██╗██║ ██╔╝██╔════╝╚══██╔══╝██╔══██╗██║     ██╔══██╗██╔════╝██╔════╝   ////////
//   ███████╗██║     ███████║██████╔╝ ╚████╔╝ ███████╗██║ █╗ ██║███████║██████╔╝██╔████╔██║███████║██████╔╝█████╔╝ █████╗     ██║   ██████╔╝██║     ███████║██║     █████╗     ////////
//   ╚════██║██║     ██╔══██║██╔══██╗  ╚██╔╝  ╚════██║██║███╗██║██╔══██║██╔═══╝ ██║╚██╔╝██║██╔══██║██╔══██╗██╔═██╗ ██╔══╝     ██║   ██╔═══╝ ██║     ██╔══██║██║     ██╔══╝     ////////
//   ███████║╚██████╗██║  ██║██║  ██║   ██║   ███████║╚███╔███╔╝██║  ██║██║     ██║ ╚═╝ ██║██║  ██║██║  ██║██║  ██╗███████╗   ██║   ██║     ███████╗██║  ██║╚██████╗███████╗   ////////
//   ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝     ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝     ╚══════╝╚═╝  ╚═╝ ╚═════╝╚══════╝   ////////
/////////////////////                                                                                                                                             /////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


pragma solidity ^0.8.0;

contract Marketplace {
  address public  Seller =  0x0aD08eA00ceFd05f7ff89543C51a41F72D773165;
  string public name;
  uint256 public gameCount = 0;
  uint256 public contractCnt = 0;
  mapping(uint256 => BoughtContract) public boughtContracts;
  mapping(uint256 => Game) public games;

  struct BoughtContract {
    uint256 id;
    uint256 gameId;
    address owner;
  }

  struct Game {
    uint256 id;
    string name;
    string description;
    string photo;
    string file;
    uint256 price;
  }

  struct ReadGame {
    uint256 id;
    string name;
    string description;
    string photo;
    uint256 price;
  }

  event CreateGame(
    uint256 id,
    string name,
    string description,
    string photo,
    string file,
    uint256 price
  );

  event UpdateGame(
    uint256 id,
    string name,
    string description,
    string photo,
    string file,
    uint256 price
  );

  event RemoveGame(
    uint256 id
  );

  event SoldGame(
    uint256 id,
    uint256 gameId,
    address owner
  );
  

  constructor() {
    name = "Scary Swap Marketplace";
  }

  function getWalletAddress() external view returns(address) {
    return msg.sender;
  }

  function getGame() public view returns(Game[] memory) {
    Game[] memory _games = new Game[](gameCount);
    for(uint256 i=0; i < gameCount; i++) {
      _games[i] = games[i];
    }
    return _games;
  }

  function getGameList() external view returns(Game[] memory){
    if(msg.sender == Seller) return getGame();
    else {
       bool[] memory _boughtCts = new bool[](gameCount);
      Game[] memory _games = new Game[](gameCount);
      for(uint256 i=0; i < contractCnt; i++) {
        if(boughtContracts[i].owner == msg.sender){
          _boughtCts[boughtContracts[i].gameId] = true;
        }
      }
      for(uint i=0; i < gameCount; i++) {
        if(_boughtCts[i]){
          _games[i] = games[i];
        } else {
          _games[i] = games[i];
          _games[i].file = "";
        }
      }
      return _games;
    }
  }

  // function setSeller(address) public ownable {

  // }

  function createGame(string memory _name, string memory _description, string memory _photo, string memory _file, uint256 _price) external {
    // Require a valid name
    require(bytes(_name).length > 0);
    // Require a valid price
    require(_price > 0);
    // Require a description
    require(bytes(_description).length > 0);
    // Require a photo url
    require(bytes(_photo).length > 0);
    // require seller
    require(msg.sender == Seller);
    
    games[gameCount] = Game(
      gameCount,
      _name,
      _description,
      _photo,
      _file,
      _price
    );
    gameCount++;
    //  Trigger an event buy
    emit CreateGame(
      gameCount,
      _name,
      _description,
      _photo,
      _file,
      _price
    );
  }
  function updateGame(uint256 _gameId, string memory _name, string memory _description, string memory _photo, string memory _file, uint _price) public {
    // Require a game ID
    require(_gameId >= 0);
    // Require a valid name
    require(bytes(_name).length > 0);
    // Require a valid price
    require(_price > 0);
    // Require a description
    require((bytes(_description).length > 0));
    // require seller
    require(msg.sender == Seller);
    
    games[_gameId] = Game(
      _gameId,
      _name,
      _description,
      _photo,
      _file,
      _price
    );
    //  Trigger an event buy
    emit UpdateGame(
      _gameId,
      _name,
      _description,
      _photo,
      _file,
      _price
    );
  }
  function removeGame(uint256 _gameId) public {
    // Requre a game ID
    require(_gameId >= 0 && _gameId < gameCount);

    for(uint256 i=_gameId; i<gameCount;i++){
      games[i] = games[i+1];
    }
    delete games[gameCount-1];
    gameCount--;
    emit RemoveGame(_gameId);
  }
  function buyGame(uint256 _gameId) payable external returns(string memory){
    // Require a valid name
    require(_gameId >= 0);
    uint256 _price = games[_gameId].price;
    // Increment contract Cnt
    require(Seller != msg.sender);
    // value should be bigger than price
    require(msg.value >= _price);

    boughtContracts[contractCnt] = BoughtContract(
      contractCnt,
      _gameId,
      msg.sender
    );
    contractCnt++;
    // Pay the seller by sending them Ether
    payable(Seller).transfer(msg.value);
    //  Trigger an event buy
    emit SoldGame(
      contractCnt,
      _gameId,
      msg.sender
    );
    return games[_gameId].file;
  }
}