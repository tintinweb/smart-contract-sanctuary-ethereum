// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract N2WERC20 {
  using SafeMath for uint256;

  string public name = "nice2win";
  string public symbol = "n2w";
  uint256 public totalSupply;
  uint256 public decimals = 18;
  uint256 public mintingReductionInterval = 7776000; // 3 months would be approximately 3 * 30 * 24 * 60 * 60 = 7776000 seconds.
  uint256 public currentMintingRate = 100;
  uint256 public lastReductionTimestamp;

  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) public allowed;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Burn(address indexed burner, uint256 value);

  constructor ( uint256 initialSupply ) {
    totalSupply = initialSupply * 10 ** uint256(decimals);
    balances[msg.sender] = totalSupply;
  }

  function transfer(address recipient, uint256 amount) public {
    require(recipient != address(0), "can't transfer to 0x0");
    require(amount > 0, "amount must be more than 0");
    require(balances[msg.sender] >= amount, "Not enough balance.");
    require(balances[recipient] + amount >= balances[recipient], "Overflow.");

    balances[msg.sender] = balances[msg.sender].sub(amount);
    balances[recipient] = balances[msg.sender].add(amount);

    emit Transfer(msg.sender, recipient, amount);
  }

  function approve(address spender, uint256 amount) public returns (bool success) {
    require(amount > 0, "amount must be more than 0");
    allowed[msg.sender][spender] = amount;
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public {
    require(recipient != address(0), "can't transfer to 0x0");
    require(amount > 0, "amount must be more than 0");
    require(balances[sender] >= amount, "Not enough balance.");
    require(balances[recipient] + amount >= balances[recipient], "Overflow.");
    require(allowed[sender][msg.sender] >= amount, "Not enough allowance.");

    balances[sender] = balances[sender].sub(amount);
    balances[recipient] = balances[msg.sender].add(amount);
    allowed[sender][msg.sender] = allowed[sender][msg.sender].sub(amount);

    emit Transfer(sender, recipient, amount);
  }

  function mint(address account, uint256 amount) public returns (bool success) {
    require(account != address(0));

    totalSupply = totalSupply.add(amount);
    balances[msg.sender] = balances[msg.sender].add(amount);

    emit Transfer(address(0), msg.sender, amount);

    return true;
  }

  // call burn function through the house edge reduction function LINE: 59
  function burn(uint256 amount) public returns (bool success) {
    require(balances[msg.sender] >= amount, "Not enough balance.");
    require(amount > 0, "amount must be more than 0");

    balances[msg.sender] = balances[msg.sender].add(amount);
    totalSupply = totalSupply.sub(amount);

    emit Burn(msg.sender, amount);

    return true;
  }



  // function reduceMinting() public {
  //   require(now >= lastReductionTimestamp + mintingReductionInterval, "Minting rate reduction interval not reached.");
  //   // Implement the logic for reducing the amount of tokens minted when users place bets


  //   // create proxy and point to minting reduction algorithm 


  //   currentMintingRate -= 5;
  //   lastReductionTimestamp = now;

  //   // Mint the reduced amount of tokens

  //   totalSupply += amount * currentMintingRate / 100;
  //   balances[msg.sender] += amount * currentMintingRate / 100;
  // }

  // function N2WStake() public{ 

  //   // Staking Pool:
  //   //▪ 25% of house edge revenues to stakers
  //   // ▪ ETH staked will be utilized for bankroll if necessary, or used to farm on a trustworthy DeFi protocol.

  // }

  // add presale functionalities 

}