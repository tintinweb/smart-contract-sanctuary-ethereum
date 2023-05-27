/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

pragma solidity 0.5.8;

/**
 *
 * SOLD TOO EARLY $REEE AAaaAAaaAAAaAAAAaAAAAaAAaAaAaAaAAaaAaAaaAAAaAaAaAAAAaAaAaAAAAaAaAaAAAAaaAAAAAaAaAaAaAAAAaAaAaAAaAaAAAAaA
 * 
 * WEBSITE: soldearly.gg
 * TWITTER: twitter.com/soldearlygg
 * TG: t.me/soldearly
 *
 */


interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SOLD_EARLY is ERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    mapping(address => psale) private burns;

    string public constant name  = "SOLD EARLY";
    string public constant symbol = "REEE";
    uint8 public constant decimals = 18;
    uint256 constant MAX_SUPPLY = 200000000000 * (10 ** 18);

    struct psale {
        uint256 amountBurnt;
        uint256 unlockTime;
    }

    constructor() public {
        balances[address(this)] = MAX_SUPPLY;
        emit Transfer(address(0), address(this), MAX_SUPPLY);
        transferInternal(address(this), msg.sender, MAX_SUPPLY - 69420000000 * (10 ** 18));
    }

    function totalSupply() public view returns (uint256) {
        return MAX_SUPPLY;
    }

    function balanceOf(address player) public view returns (uint256) {
        return balances[player];
    }

    function allowance(address player, address spender) public view returns (uint256) {
        return allowed[player][spender];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0));
        transferInternal(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(to != address(0));
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        transferInternal(from, to, amount);
        return true;
    }

    function transferInternal(address from, address to, uint256 amount) internal {
        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(from, to, amount);
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }


    // Can burn PSALE token to claim $REEE 1:1 after 12 hours, must hold some $REEE strong hands only!
    function burnPSALE(uint256 amount) external {
      require(balances[msg.sender] > 0); // MUST BE $REEE BULL
      require(burns[msg.sender].unlockTime == 0);
      ERC20 psaleToken = ERC20(0xBAcaCD83b68C92Ae07eF382d0c0277D1Bd1c7C4D);
      psaleToken.transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), amount);
      burns[msg.sender] = psale(amount, now + 12 hours);
    }

    function claimPSALE() external {
      psale memory burnt = burns[msg.sender];
      require(burnt.unlockTime < now);
      transferInternal(address(this), msg.sender, burnt.amountBurnt);
      delete burns[msg.sender];
    }

}


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}