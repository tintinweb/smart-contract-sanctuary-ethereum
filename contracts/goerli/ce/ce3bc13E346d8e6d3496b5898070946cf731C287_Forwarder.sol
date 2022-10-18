pragma solidity ^0.4.18;
import "./ERC20Interface.sol";
/**
 * Contract that will forward any incoming Ether to the creator of the contract
 */
contract Forwarder {
  // Address to which any funds sent to this contract will be forwarded
  address public parentAddress;
  event ForwarderDeposited(address from, uint value, bytes data);

  /**
   * Create the contract, and sets the destination address to that of the creator
   */
  function Forwarder(address _owner) public {
    parentAddress = _owner;
  }

  /**
   * Modifier that will execute internal code block only if the sender is the parent address
   */
  modifier onlyParent {
    if (msg.sender != parentAddress) {
      revert();
    }
    _;
  }

  /**
   * Default function; Gets called when Ether is deposited, and forwards it to the parent address
   */
  function() public payable {
    // throws on failure
    parentAddress.transfer(msg.value);
    // Fire off the deposited event if we can forward it
    ForwarderDeposited(msg.sender, msg.value, msg.data);
  }

  /**
   * Execute a token transfer of the full balance from the forwarder token to the parent address
   * @param tokenContractAddress the address of the erc20 token contract
   */
  function flushTokens(address tokenContractAddress) public onlyParent {
    ERC20Interface instance = ERC20Interface(tokenContractAddress);
    var forwarderAddress = address(this);
    var forwarderBalance = instance.balanceOf(forwarderAddress);
    if (forwarderBalance == 0) {
      return;
    }
    if (!instance.transfer(parentAddress, forwarderBalance)) {
      revert();
    }
  }

  /**
   * It is possible that funds were sent to this address before the contract was deployed.
   * We can flush those funds to the parent address.
   */
  function flush() public {
    // throws on failure
    parentAddress.transfer(this.balance);
  }
}