pragma solidity ^0.7.6;

contract Faucet {
  //state variable to keep track of owner and amount of ETHER to dispense
  address public owner;
  uint256 public amountAllowed = 1000000000000000000;

  //mapping to keep track of requested rokens
  //Address and blocktime + 1 day is saved in TimeLock
  mapping(address => uint256) public lockTime;

  //constructor to set the owner
  constructor() {
    owner = msg.sender;
  }

  //function modifier
  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can call this function.");
    _;
  }

  //function to change the owner.  Only the owner of the contract can call this function
  function setOwner(address newOwner) external onlyOwner {
    owner = newOwner;
  }

  //function to set the amount allowable to be claimed. Only the owner can call this function
  function setAmountallowed(uint256 newAmountAllowed) external onlyOwner {
    amountAllowed = newAmountAllowed;
  }

  function rugPull() external onlyOwner {
    (bool sent, bytes memory data) = payable(owner).call{
      value: address(this).balance
    }("");
    require(sent, "Failed to send Ether");
  }

  //function to donate funds to the faucet contract
  function donateTofaucet() public payable {}

  receive() external payable {}

  //function to send tokens from faucet to an address
  function requestTokens(address payable _requestor) external {
    //perform a few checks to make sure function can execute
    require(
      block.timestamp >= lockTime[msg.sender],
      "lock time has not expired. Please try again later"
    );
    require(
      address(this).balance >= amountAllowed,
      "Not enough funds in the faucet. Please donate"
    );
    lockTime[msg.sender] = block.timestamp + 2 hours;

    //if the balance of this contract is greater then the requested amount send funds
    (bool sent, bytes memory data) = _requestor.call{ value: amountAllowed }(
      ""
    );
    require(sent, "Failed to send Ether");
    //updates locktime 1 day from now
  }
}