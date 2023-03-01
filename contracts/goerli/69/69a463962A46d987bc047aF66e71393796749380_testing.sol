/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// File: cnw.sol

/**
 *Submitted for verification at Etherscan.io on 2023-02-18
*/

// File: ownable.sol

pragma solidity ^0.8.2;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}
// File: wtest.sol

/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

pragma solidity ^0.8.2;


contract testing is Ownable{

    mapping(address => uint) public balances;

    bool flag = false;

    function setPublicSaleStatus(bool _publicSaleActive) public {
        flag = _publicSaleActive;
    }

    function publicMint(uint256 _amount) public payable {
        require(flag ==true, "public is not started yet.");
        balances[msg.sender] += msg.value;
        
    }
    function setPhaseId(uint _phase) public {
    }
    function chiwawakawaii(uint _phase) public {
    }

    function withdraw() public {
        payable(msg.sender).transfer(balances[msg.sender]);
        balances[msg.sender] = 0;
    }
    function withdrawAll() public onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }
}