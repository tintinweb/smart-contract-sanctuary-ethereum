/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract ERC20 {
  
  // 1. First state variables

  uint256 public totalSupply;
  string public name;
  string public symbol;

  //12.
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  //4. Befrore transfering we need way to store balances
  mapping (address => uint256) public balanceOf;

  //7. Allowance mapping - owner address to the spender address to the allowance valuer
  mapping(address => mapping(address => uint256)) public allowance;


  // 2. Second things constructor
  constructor(string memory _name, string memory _symbol) public {
    name = _name;
    symbol = _symbol;

    //11.  contract has 18 decimasl 100 eth minted to deployer
    _mint(msg.sender, 100e18);
  }

  function decimals() external pure returns (uint8) {
    return 18; // cheaper in terms of gas instead of using a state variable for decimals
  }

  // change compiler in truffle config

  // zoshto koristime memory vo consructor zatoa shto e se po reference
  // i mora da napravime kopija 
  // for example if we have memory to memory assignment nothing is copied
  // we are only changing the reference

  // poly hacks had to do with function signatures using bruth force for collision
  // to have different outputs bytes for the same function

  //3. Transfer function - allow anyone to transfer our token to someone elses ethereum address
  //5. 
  function transfer(address recipient, uint256 amount) external returns(bool) {
  /*   require(recipient != address(0), "ERC20: transfer to the zero address");
    
    uint256 senderBalance = balanceOf[msg.sender];

    require(senderBalance >= amount, "ERC20: transfer amount exeeeds balance");

    balanceOf[msg.sender] = senderBalance - amount;
    balanceOf[recipient] += amount;

    return true; */
    
    // call newly created transfer
    return _transfer(msg.sender, recipient, amount);

    //after this function anyone who owns the token will be able to send the token to another address
    // fudamentally erc20 tokens are nothing more than this
  }

  function transferFrom(address sender, address recipient, uint256 amount) external returns(bool) {
    uint256 currentAllowance = allowance[sender][msg.sender];

    require(currentAllowance >= amount, "ERC20: transfer exceeds allowance");

    allowance[sender][msg.sender] = currentAllowance - amount;

    // the last things missing - the owner to allow some address to spend the tokens on their behalf - apporve function

    // sender is another contract address
    return _transfer(sender, recipient, amount);
  }

  //9. Approve functon 
  function approve(address spender, uint256 amount) external returns(bool) {
    //first dont allow approving to the zero address cause nobody use it
    require(spender != address(0), "ERC20: approve to the zero address");

    allowance[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);

    return true;
  }


  //6. transfer tokens on behalf on someone else (other smart contract)
  // with approve function we can set an allowance for out tokens for someone else to transfer (someone we really trust)
  //typically some smart contract
  //8. copy paste na transfer and make it private
  function _transfer(address sender, address recipient, uint256 amount) private returns(bool) {
    // add sender parameter, change msg.sender to sender
    require(recipient != address(0), "ERC20: transfer to the zero address");
    
    uint256 senderBalance = balanceOf[sender];

    require(senderBalance >= amount, "ERC20: transfer amount exeeeds balance");

    balanceOf[sender] = senderBalance - amount;
    balanceOf[recipient] += amount;

    emit Transfer(sender, recipient, amount);

    return true;

    //after this function anyone who owns the token will be able to send the token to another address
    // fudamentally erc20 tokens are nothing more than this
  }


  // 10. dodavame funkicja mint tokens i ja povikuvame vo konstruktorot i mu mintame tokeni na toj shto go deplojnuva kontrakttot u consturctor
  function _mint(address to, uint256 amount) internal {
    require(to != address(0), "ERC20: mint to the zero address");

    totalSupply += amount;
    balanceOf[to] = amount;

    // when minting the
    emit Transfer(address(0), to, amount);
  }
}