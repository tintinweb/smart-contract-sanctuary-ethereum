/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

// SPDX-License-Identifier: OSL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract VocabularyGame
{
 // private states
 //
 enum UserState {None, Playing, Win, Lose}
 struct UserData
 {
  UserState state;
  uint16 nth_guess;
  uint256 nletters;
  string answer;
  mapping(bytes1 => bool) alphabeta_answer;
  mapping(bytes1 => bool) alphabeta_input;
 }

 uint16 max_tries = 5;
 uint256 constant game_answer_size = 107;
 mapping(address => UserData) games;
 string[game_answer_size] game_answer_list = [
  "game", "rent", "compare", "red", "develop", "publicity", "round", "deep", "annoy", "fortunate",
  "seat", "excellent", "knotty", "roof", "sudden", "meeting", "aboriginal", "multiply", "keen", "snake",
  "imminent", "small", "stereotyped", "rock", "approval", "lyrical", "coordinated", "outgoing", "spiteful", "incandescent",
  "frog", "team", "psychedelic", "irritating", "fertile", "irritate", "low", "observation", "bouncy", "water",
  "complete", "fear", "beneficial", "page", "shocking", "face", "fact", "ruin", "four", "puzzled",
  "zoom", "laughable", "tacky", "remarkable", "satisfying", "vigorous", "tight", "voracious", "afterthought","melted",
  "land", "wrathful", "face", "look", "trouble", "vagabond", "hand", "compete", "obey", "cemetery",
  "deliver", "alleged", "list", "join", "depend", "credit", "order", "zinc", "overrated", "squeeze",
  "silk", "preach", "floor", "lumpy", "eye", "changeable", "scale", "fasten", "produce", "sophisticated",
  "protest", "found", "massive", "match", "discreet", "tire", "cooing", "crash", "bore", "frail",
  "lock", "striped", "tremendous", "ugliest", "intelligent", "resolute", "plantation"
 ];

 address public admin;

 event InitGame(string message, uint256 N);
 event PlayerState(address player, uint16 nth_guess, UserState player_state, string message);
 event Hint(string message, uint8 N1, uint8 N2);
 event Win(string message, uint256 tokens);
 event Lose(string message, string answer);

 constructor()
 {
  admin = msg.sender;
 }


 // internal utility function
 function reset_alphabeta_mapping(mapping(bytes1 => bool) storage ref_map) private
 {
  bytes1 ichar;
  for (uint8 iascii=97; iascii<=122; iascii++)
  {
   ichar = bytes1(iascii);
   ref_map[ichar] = false;
  }
 }

 function count_coincidental_alphabeta(mapping(bytes1 => bool) storage ref_map1, mapping(bytes1 => bool) storage ref_map2) private view returns (uint8)
 {
  uint8 res = 0;

  bytes1 ichar;
  for (uint8 iascii=97; iascii<=122; iascii++)
  {
   ichar = bytes1(iascii);
   if (ref_map1[ichar] && ref_map2[ichar])
    res++;
  }

  return res;
 }




 // public functions
 function Get_State() public view returns (UserState)
 {
  return games[msg.sender].state;
 }

 function Emit_PlayerState(string memory message) public
 {
  emit PlayerState(msg.sender, games[msg.sender].nth_guess, games[msg.sender].state, message);
 }




 // internal functions
 function Init_Game() public
 {
  require(games[msg.sender].state != UserState.Playing);

  string memory word = pick_word(msg.sender);
  UserData storage user_data = games[msg.sender];

  user_data.state = UserState.Playing;
  user_data.nth_guess = 0;
  user_data.answer = word;
  user_data.nletters = bytes(word).length;

  reset_alphabeta_mapping(user_data.alphabeta_answer);
  reset_alphabeta_mapping(user_data.alphabeta_input);

  bytes memory raw_answer = abi.encodePacked(user_data.answer);
  for(uint idx = 0; idx < raw_answer.length; idx++)
   user_data.alphabeta_answer[raw_answer[idx]] = true;

  emit InitGame("Guess a N-Letter Word", user_data.nletters);
 }

 function pick_word(address sender) private view returns (string memory)
 {
  string memory res;

  uint256 ts_o = block.timestamp;
  uint256 n_o = block.number;
  uint256 gas_left = gasleft();
  uint256 balance = sender.balance;
  bytes memory packed = abi.encodePacked(ts_o/1000000, n_o, gas_left, balance/1000000000);
  uint256 chksum = uint256(keccak256(packed));
  uint256 index = chksum % game_answer_size;
  res = game_answer_list[index];

  return res;
 }

 function Guess(string memory input) public
 {
  bool res;
  require(games[msg.sender].state == UserState.Playing);

  UserData storage user_data = games[msg.sender];
  require(user_data.nletters == bytes(input).length);
  user_data.nth_guess++;
  bytes memory raw_input = abi.encodePacked(input);
  bytes memory raw_answer = abi.encodePacked(user_data.answer);
  bytes32 hash_inp = keccak256(raw_input);
  bytes32 hash_answer = keccak256(raw_answer);
  res = hash_inp==hash_answer;
  if (res)
   user_data.state = UserState.Win;
  else
  {
   if (user_data.nth_guess >= max_tries)
    user_data.state = UserState.Lose;

   generate_hints(raw_answer, raw_input);
  }
 }

 function generate_hints(bytes memory answer, bytes memory input) public
 {
  uint8 res1 = 0;
  uint8 res2 = 0;
  UserData storage user_data = games[msg.sender];
  mapping(bytes1 => bool) storage alphabeta_input = user_data.alphabeta_input;
  mapping(bytes1 => bool) storage alphabeta_answer = user_data.alphabeta_answer;

  reset_alphabeta_mapping(alphabeta_input);
  for(uint idx = 0; idx < input.length; idx++)
   alphabeta_input[input[idx]] = true;

  res1 = count_coincidental_alphabeta(alphabeta_answer, alphabeta_input);

  for(uint idx = 0; idx < answer.length; idx++)
   if (answer[idx] == input[idx])
    res2++;

  emit Hint("There are N1 correct alphabetas and N2 correct positions from your answer.", res1, res2);
 }

 function Gen_Result(uint256 tokens) external returns (UserState)
 {
  UserState game_state = Get_State();
  string memory message;

  if (game_state == UserState.Win)
  {
   message = "Correct ! You win SMILE!";
   emit Win(message, tokens);
  }
  else if (game_state == UserState.Lose)
  {
   message = "Game Over";
   emit Lose("answer is ", games[msg.sender].answer);
  }
  else if (game_state == UserState.Playing)
   message = "Incorrect. Check Event:Hint for more details.";
  else
   message = "None";

  Emit_PlayerState(message);

  return game_state;
 }
}