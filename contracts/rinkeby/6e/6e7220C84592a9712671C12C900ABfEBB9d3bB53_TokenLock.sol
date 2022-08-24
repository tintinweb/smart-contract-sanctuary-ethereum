// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract TokenLock {
    string public name = "TokenLock";

    address public owner;

    struct lock {
      uint id;
      address sender;
      address token;
      uint qty;
      bool active;
      uint end_date;
    }

    uint last_lock_id = 0;
    uint commission = 500000000000000000;

    mapping(uint => lock) public locks;
    mapping(address => uint) public token_qty;

    constructor() {
        owner = msg.sender;
    }

    modifier authorized() {
        require(owner==msg.sender, "403");
        _;
    }

    ///@dev Deposit farmable tokens in the contract
    function deposit(uint _qty, uint _end_date, address _token) public payable returns (bool)  {
      require(msg.value >= commission, "needs to be higher");
      // require(_end_date > block.timestamp, "Timestamp higher");
      require(IERC20(_token).balanceOf(msg.sender) >= _qty, "Needs more tokens");
      uint id = last_lock_id;

      locks[id].id = id;
      locks[id].sender = msg.sender;
      locks[id].token = _token;
      locks[id].qty = _qty;
      locks[id].active = true;
      locks[id].end_date = _end_date;

      bool transfer_done = IERC20(_token).transferFrom(msg.sender, address(this), _qty);
      require(transfer_done, "transfer need to be done");

      bool success;
      (success,) = owner.call{value: commission}("");

      token_qty[_token] += _qty;

      last_lock_id++;
      return true;
    }

    function manualDeposit(uint _qty, uint _end_date, address _token, address sender) public authorized returns (bool)  {
      uint id = last_lock_id;

      locks[id].id = id;
      locks[id].sender = sender;
      locks[id].token = _token;
      locks[id].qty = _qty;
      locks[id].active = true;
      locks[id].end_date = _end_date;

      token_qty[_token] += _qty;

      last_lock_id++;
      return true;
    }

    function withdraw(uint id) public returns (bool)  {
      require(locks[id].active, "Needs to be active");
      require(locks[id].end_date < block.timestamp, "Not ending yet");
      require(locks[id].sender == msg.sender || msg.sender == owner, "Not sender");

      bool transfer_done = IERC20(locks[id].token).transferFrom(address(this), msg.sender, locks[id].qty);
      require(transfer_done, "transfer need to be done");

      locks[id].active = false;

      token_qty[locks[id].token] -= locks[id].qty;

      return transfer_done;
    }

    function get_lock_ids_by_sender(address sender) public view returns (uint[] memory) {
      uint[] memory lockIds = new uint[](last_lock_id);
      uint numberOfAvailableLocks = 0;

      // Iterate over all bets
      for(uint i = 0; i < last_lock_id; i++) {
        // Keep the ID if the bet is still available
      
        if(locks[i].sender == sender) {
          lockIds[numberOfAvailableLocks] = locks[i].id;
          numberOfAvailableLocks++;
        }
      }

      uint[] memory availableLocks = new uint[](numberOfAvailableLocks);

      // Copy the lockIds array into a smaller availableLocks array to get rid of empty indexes
      for(uint j = 0; j < numberOfAvailableLocks; j++) {
        availableLocks[j] = lockIds[j];
      }

      return availableLocks;
    }


    ///@notice Private functions

    function unstuck_tokens(address tkn) public authorized {
      require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens");
      uint amount = IERC20(tkn).balanceOf(address(this));
      IERC20(tkn).transfer(msg.sender, amount);
    }

    // withdraw
    function unstuck_etc() public authorized {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function set_commission(uint _commision) public authorized {
      commission = _commision;
    }
  

    // receive() external payable {}
    // fallback() external payable {}
}