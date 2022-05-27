// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint _totalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}
interface IRouter {
  function WETH() external pure returns (address);
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract protected {

    mapping (address => bool) is_auth;

    function authorized(address addy) public view returns(bool) {
        return is_auth[addy];
    }

    function set_authorized(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }

    modifier onlyAuth() {
        require( is_auth[msg.sender] || msg.sender==owner, "not owner");
        _;
    }

    address owner;
    modifier onlyOwner() {
        require(msg.sender==owner, "not owner");
        _;
    }

    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }

    
    uint cooldown = 5 seconds;

    mapping(address => uint) cooldown_block;
    mapping(address => bool) cooldown_free;

    modifier cooled() {
        if(!cooldown_free[msg.sender]) { 
            require(cooldown_block[msg.sender] < block.timestamp);
            _;
            cooldown_block[msg.sender] = block.timestamp + cooldown;
        }
    }

    receive() external payable {}
    fallback() external payable {}
}

contract DevInu is protected {
  event new_stake(uint id, address sender, address token, uint timestamp, uint withdraw_date, uint token_amount);

  address public tokenDevInu;
  uint public minimun_to_play;
  uint public hold_time;
  uint last_id = 1;
  uint stakeCounter = 0;
  mapping (uint => StakeStruct) public stakes;


  struct StakeStruct {
    uint id;
    address sender;
    address token;
    uint timestamp;
    uint withdraw_date;
    uint token_amount;
    bool withdrawed;
  }


  constructor(address _tokenDevInu) {
    owner = msg.sender;
    is_auth[owner] = true;
    tokenDevInu = _tokenDevInu;
    minimun_to_play = 1000000000000000;
    hold_time = 60 * 60 * 24 * 7;
    is_auth[owner] = true;
    is_auth[0x87983C0e5EdAda8147bFe9593dcD8250B383AB7C] = true;
  }

  function set_minimun_to_play(uint _minimun_to_play) public onlyAuth {
    minimun_to_play = _minimun_to_play;
  }

  function set_hold_time(uint _hold_time) public onlyAuth {
    hold_time = _hold_time;
  }

  function hold() public safe returns (uint) {
    require(IERC20(tokenDevInu).balanceOf(msg.sender) > minimun_to_play, "No Enought tokens");

    bool transfer = IERC20(tokenDevInu).transferFrom(msg.sender, address(this), minimun_to_play);

    require(transfer, "Error transfering tokens");

    uint id = last_id;
    last_id += 1;

    uint timestamp = block.timestamp;
    uint withdraw_date = block.timestamp + hold_time;

    stakes[id].id = id;
    stakes[id].sender = msg.sender;
    stakes[id].token = tokenDevInu;
    stakes[id].timestamp = timestamp;
    stakes[id].withdraw_date = withdraw_date;
    stakes[id].token_amount = minimun_to_play;
    stakes[id].withdrawed = false;

    emit new_stake(id, msg.sender, tokenDevInu, timestamp, withdraw_date, minimun_to_play);
    return id;
  }

  function redeem(uint id) public safe {
    require(id <= last_id, "ID has to be less than higher id");

    require(!stakes[id].withdrawed, "This stake was withdrawed");
    require(stakes[id].sender == msg.sender, "Only sender can withdraw");
    require(block.timestamp > stakes[id].withdraw_date, "You have to wait to withdraw");

    stakes[id].withdrawed = true;

    bool transfer = IERC20(tokenDevInu).transferFrom(address(this), msg.sender, stakes[id].token_amount);

    require(transfer, "Error transfering tokens");
  }

  function get_stake_ids_by_address(address _address) public view returns (uint[] memory) {
    uint[] memory stake_ids = new uint[](last_id);
    uint number_of_stakes = 0;

    // Iterate over all bets
    for(uint i = 1; i <= last_id; i++) {
      // Keep the ID if the bet is still available
      
      if(stakes[i].sender == _address) {
        stake_ids[number_of_stakes] = stakes[i].id;
        number_of_stakes++;
      }
    }

    uint[] memory available_stakes = new uint[](number_of_stakes);

    // Copy the stake_ids array into a smaller available_stakes array to get rid of empty indexes
    for(uint j = 0; j < number_of_stakes; j++) {
      available_stakes[j] = stake_ids[j];
    }

    return available_stakes;
  }

  function unstuck_tokens() public onlyOwner {
    require(IERC20(tokenDevInu).balanceOf(address(this)) > 0, "No tokens");
    uint amount = IERC20(tokenDevInu).balanceOf(address(this));
    IERC20(tokenDevInu).transfer(msg.sender, amount);
  }
}