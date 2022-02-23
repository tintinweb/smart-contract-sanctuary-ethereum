/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

// File: contracts/IverseToken.sol


pragma solidity ^0.8.4;

contract IverseToken {
    string  public name = "Iverse Token";
    string  public symbol = "IVF";
    uint256 public totalSupply = 1000000000000000000000000000; // 1 billion tokens
    uint8   public decimals = 18;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}
// File: contracts/Staking.sol

/*
SPDX-License-Identifier: UNLICENSED 
*/

pragma solidity ^0.8.4;



contract Staking{
  string public name = "Staking";
  address public owner;
  IverseToken public iverseToken;



  address[] public stakers;

  mapping(address => uint) public stakingBalance;
  mapping(address => bool) public hasStaked;
  mapping(address => bool) public isStaking;

constructor(IverseToken _iverse) payable {

    iverseToken = _iverse;
    owner = msg.sender;
 
}


  // staking function   
function depositTokens(uint _amount) public {

  // require staking amount to be greater than zero
    require(_amount > 0, "amount cannot be 0");
  
  // Transfer tether tokens to this contract address for staking
  iverseToken.transferFrom(msg.sender, address(this), _amount);

  // Update Staking Balance
  stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;

  if(!hasStaked[msg.sender]) {
    stakers.push(msg.sender);
  }

  // Update Staking Balance
    isStaking[msg.sender] = true;
    hasStaked[msg.sender] = true;
}

  // unstake tokens
  function unstakeTokens() public {
    uint balance = stakingBalance[msg.sender]  ;
    // require the amount to be greater than zero
    require(balance > 0, "staking balance cannot be less than zero");
    
    // transfer the tokens to the specified contract address from our bank
    iverseToken.transfer(msg.sender, balance);

    // reset staking balance
    stakingBalance[msg.sender] = 0;

    // Update Staking Status
    isStaking[msg.sender] = false;

  }

  // issue rewards
        function issueTokens() public {
            // Only owner can call this function
            require(msg.sender == owner, "caller must be the owner");

            // issue tokens to all stakers
            for (uint i=0; i<stakers.length; i++) {
                address recipient = stakers[i]; 
                uint balance = stakingBalance[recipient];
                if(balance > 0) {
                iverseToken.transfer(recipient, balance);
            }
       }
       }
}