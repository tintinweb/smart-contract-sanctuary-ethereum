pragma solidity ^0.8.10;

/**
selfdestructedでtargetの残りのetherを強制的に送る

address(this).balanceがダメらしい
 */

/**
手元にそんなないけど、、、
 */
contract EtherGame {
  uint public targetAmount = 7 ether;
  address public winner;

  function deposit() public payable {
    require(msg.value == 1 ether, "You can only send 1 Ether");

    /**
    このbalanceはコントラクトのもの？
     */
    uint balance = address(this).balance; 
    require(balance <= targetAmount, "Game Over");

    if( balance == targetAmount ) {
      winner = msg.sender;
    }
  }

  function climeReward() public {
    require(msg.sender == winner, "Not winner");
    (bool sent, ) = msg.sender.call{value: address(this).balance}("");
    require(sent, "Failed to send Ether");
  }
}