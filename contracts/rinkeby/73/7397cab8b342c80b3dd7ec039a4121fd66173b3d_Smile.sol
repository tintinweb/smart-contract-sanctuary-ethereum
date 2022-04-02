/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

// File: contracts/vocabulary.sol



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

// File: contracts/interface_ERC20.sol



pragma solidity >=0.7.0 <0.9.0;

interface ERC20Interface
{
 // Returns the name of the token - e.g. "MyToken".
 function name() external view returns (string memory);

 // Returns the symbol of the token. E.g. “HIX”.
 function symbol() external view returns (string memory);

 // Returns the number of decimals the token uses - e.g. 8, means to divide the token amount by 100000000 to get its user representation.
 function decimals() external view returns (uint8);

 // Returns the total token supply.
 function totalSupply() external view returns (uint256);

 // Returns the account balance of another account with address _owner.
 function balanceOf(address _owner) external view returns (uint256 balance);

 // Transfers _value amount of tokens to address _to, and MUST fire the Transfer event. The function SHOULD throw if the message caller’s account balance does not have enough tokens to spend.
 // Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
 function transfer(address _to, uint256 _value) external returns (bool success);

 // Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.
 // The transferFrom method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf.
 // This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in sub-currencies.
 // The function SHOULD throw unless the _from account has deliberately authorized the sender of the message via some mechanism.
 // Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
 function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

 // Allows _spender to withdraw from your account multiple times, up to the _value amount.
 // If this function is called again it overwrites the current allowance with _value.
 // NOTE: To prevent attack vectors like the one described here and discussed here,
 //        clients SHOULD make sure to create user interfaces in such a way
 //        that they set the allowance first to 0 before setting it to another value for the same spender.
 // THOUGH The contract itself shouldn’t enforce it, to allow backwards compatibility with contracts deployed before
 function approve(address _spender, uint256 _value) external returns (bool success);

 // Returns the amount which _spender is still allowed to withdraw from _owner.
 function allowance(address _owner, address _spender) external view returns (uint256 remaining);

 // MUST trigger when tokens are transferred, including zero value transfers.
 // A token contract which creates new tokens SHOULD trigger a Transfer event with the _from address set to 0x0 when tokens are created.
 event Transfer(address indexed _from, address indexed _to, uint256 _value);

 // MUST trigger on any successful call to approve(address _spender, uint256 _value).
 event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// File: contracts/smile.sol



pragma solidity >=0.7.0 <0.9.0;



contract Smile is ERC20Interface
{
 string token_name = "Smile";
 string token_symbol = "SMILE";

 uint256 init_time;
 uint256 halt_time;
 uint256 end_time;
 uint256 token_price = 1000000000 wei; // 1 ETH = 1 B SMILE =  1000 M SMILE
 uint256 total_supply = 0;
 uint256 min_payment = 0.000001 ether;
 uint256 max_payment = 1 ether;
 string admin_name;
 address payable deposit;
 mapping(address => uint256) balances;
 mapping(address => mapping(address => uint256)) allowed_allowance;
 enum State {None, Running, Halted, End}
 State state;
 event Buy(address buyer, uint256 value, uint256 tokens);
 event Sell(address seller, uint256 tokens, uint256 value);
 event TransferFromAdmin(string message, address indexed to, uint256 _value);

 uint8 public override decimals = 0;
 address public admin;
 VocabularyGame public game = new VocabularyGame();

 constructor(string memory val_admin_name, uint256 val_amount, address payable val_deposit)
 {
  init_time = block.timestamp;
  admin = msg.sender;
  admin_name = val_admin_name;
  total_supply = val_amount;
  balances[admin] = val_amount;
  deposit = val_deposit;
  state = State.Running;
 }

 modifier bAdmin()
 {
  require(admin==msg.sender);
  _;
 }

 modifier bRunning()
 {
  require(state==State.Running);
  _;
 }

 modifier notEnd()
 {
  require(state!=State.End);
  _;
 }

 function Check_name(string memory val_name) private view
 {
  bytes32 hash_inp = keccak256(abi.encodePacked(val_name));
  bytes32 hash_adminname = keccak256(abi.encodePacked(admin_name));
  require(hash_inp==hash_adminname);
 }




 // admin functions

 function halt(string memory val_name) bAdmin notEnd public
 {
  Check_name(val_name);

  halt_time = block.timestamp;
  state = State.Halted;
 }

 function resume(string memory val_name) bAdmin notEnd public
 {
  Check_name(val_name);

  state = State.Running;
 }

 function end(string memory val_name) bAdmin notEnd public
 {
  Check_name(val_name);

  state = State.End;
  balances[admin] = 0;
 }



 // public methods

 function name() public override view returns (string memory)
 {
  return token_name;
 }

 function symbol() public override view returns (string memory)
 {
  return token_symbol;
 }

 function totalSupply() public override view returns (uint256)
 {
  return total_supply;
 }

 function balanceOf(address owner) notEnd public override view returns (uint256 balance)
 {
  return balances[owner];
 }

 function get_current_state() public view returns (State)
 {
  return state;
 }



 // action functions

 function transfer(address to, uint256 tokens) bRunning public override returns (bool success)
 {
  require(balances[msg.sender]>=tokens);

  balances[to] += tokens;
  balances[msg.sender] -= tokens;

  emit Transfer(msg.sender, to, tokens);
  return true;
 }

 function allowance(address owner, address spender) bRunning public override view returns (uint256 remaining)
 {
  return allowed_allowance[owner][spender];
 }

 function approve(address spender, uint256 tokens) bRunning public override returns (bool success)
 {
  require(balances[msg.sender]>=tokens);
  require(allowed_allowance[msg.sender][spender]==0);
  require(tokens>0);

  allowed_allowance[msg.sender][spender] = tokens;

  emit Approval(msg.sender, spender, tokens);
  return true;
 }

 function transferFrom(address from, address to, uint256 tokens) bRunning public override returns (bool success)
 {
  require(allowed_allowance[from][to]>=tokens);
  require(balances[from]>=tokens);

  balances[to] += tokens;
  allowed_allowance[from][to] -= tokens;
  balances[from] -= tokens;

  emit Transfer(from, to, tokens);
  return true;
 }

 function transferFromAdmin(uint256 tokens) private
 {
  bool success = false;
  string memory message;
  if (balances[admin] > tokens)
  {
   success = true;
   message = "Tokens are transferred.";
   balances[msg.sender] += tokens;
   balances[admin] -= tokens;   
  }
  else
  {
   message = "Our SMILE are exhausted.";
   tokens = 0;
  }

  emit TransferFromAdmin(message, msg.sender, tokens);
 }




 // payment

 function buy() bRunning payable public returns(bool)
 {
  require(min_payment<=msg.value && msg.value<=max_payment);

  uint256 tokens = msg.value / token_price;

  require(balances[admin]>tokens);
  balances[msg.sender] += tokens;
  deposit.transfer(msg.value);
  balances[admin] -= tokens;

  emit Buy(msg.sender, msg.value, tokens);
  return true;
 }

 receive() bRunning payable external
 {
  buy();
 }

 fallback() payable external
 {
  get_current_state();
 }



 // Game UI public

 function VocabularyGame_Init() payable public
 {
  game.Init_Game();
 }

 function VocabularyGame_Guess(string memory input) payable public
 {
  uint256 reward = 1000;

  game.Guess(input);
  VocabularyGame.UserState game_state = game.Gen_Result(reward);
 
  if (game_state==VocabularyGame.UserState.Win)
   transferFromAdmin(reward);
    
 }
}