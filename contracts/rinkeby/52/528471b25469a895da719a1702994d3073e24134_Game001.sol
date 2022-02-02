/**
 *Submitted for verification at Etherscan.io on 2022-02-02
*/

//請使用 Rinkeby 測試網測試，不能用單機 VM 測試

pragma solidity ^0.4.11;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
   constructor() public  {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

    // 遊戲主合約裡面已經有一些賭本，每次下注只能收取 0.1 ETH - require
    // 遊戲需要記錄，下注的人是誰？下注什麼(剪刀、石頭、布？) - 可以用兩個Mapping代表。
    // 亂數產生的方法為：Oraclize 回傳亂數string後，把它轉成1~3的亂數，1代表剪刀，2代表石頭...。
    // 再次判斷玩家是否贏錢。

contract Game001  {
    using SafeMath for uint;

    //result:
    //0:平台贏 1:玩家贏 2:平手 999:錯誤重來
    event bet_record(address _from, uint _playerbet, uint _dealerbet, uint _result);

    uint private max_bet = 0.1 ether;
    uint private win_money = 0.2 ether;
    uint private round_num = 0;
    mapping(uint => Game) public games_result;
    uint[] public queryIdsArray;

    //// 0:剪刀  1:石頭  2:布
    struct Game{
      address player;
      uint player_target;
      uint game_target;
      uint game_result;

    }


   constructor() payable public {
        
    }
    


    function add_game(uint queryId, address player, uint player_target, uint game_target, uint game_result) private{
        bool exist = false;
        for(uint i=0; i<queryIdsArray.length; i++){
            if(queryIdsArray[i]==queryId){
                exist = true;
            }
        }
        games_result[queryId] = Game(player, player_target, game_target,game_result );
        if(!exist){
            queryIdsArray.push(queryId);
        }
        
    }

    function get_game(uint queryId) view public returns(address, uint, uint, uint){
        return(games_result[queryId].player, games_result[queryId].player_target, games_result[queryId].game_target, games_result[queryId].game_result);
    }
    
    function run_game(uint player_target) payable public { 
        if (player_target<0 || player_target>=3) revert();
        require(
            max_bet <= msg.value,
            "need 0.1 ether"
        );
        address player = msg.sender;
        uint game_target = 999;
        uint game_result = 999;
        uint randomNumber = now % 3;

        game_target = randomNumber;
        if(game_target == player_target){
            //平手
            game_result = 2;
            player.transfer(max_bet);
        }else if(player_target.sub(game_target)==1 || (player_target == 0 && game_target==2)){
            //玩家贏
            game_result = 1;
            player.transfer(win_money);
        }else{
            game_result = 0;
        }
        add_game(round_num, player, player_target, game_target, game_result);
        emit bet_record(player,player_target,game_target ,game_result);
        round_num++;
    }
    
}