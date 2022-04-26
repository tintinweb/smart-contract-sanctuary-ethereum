/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.6;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
 
contract BILKENT is Ownable {
 
   string public name; // the name of the cryptocurrency
   string public symbol; // symbol of the cryptocurrency
   uint256 public decimals ;
   uint256 public totalSupply ;
  
   mapping(address => uint ) public balanceOf;
   mapping(address => mapping(address => uint)) public allowance;
  
   event transfer(address indexed from , address indexed to , uint256 value);
   event approval(address indexed owner , address indexed spender , uint256 value);
  
  
   constructor(string memory _name , string memory _symbol , uint _decimals , uint _totalsupply){
       name = _name;
       symbol = _symbol;
       decimals = _decimals;
       totalSupply = _totalsupply;
       balanceOf[msg.sender] = totalSupply;
   }
  
 
  
   function internalTransfer(address _from , address _to  , uint256 _value) internal  {
      
      
       require(_to != address(0));
       balanceOf[_from] = balanceOf[_from] - (_value);
       balanceOf[_to] = balanceOf[_to] + (_value);
       emit transfer(_from , _to , _value);
      
   }
  
  
   function Transfer(address _to , uint256 _value) external returns  (bool success){
    
     require(balanceOf[msg.sender] >= _value);
     internalTransfer(msg.sender , _to , _value);
     return true;
 }
 
   function approve(address _spender , uint256 _value ) external returns(bool){
    
     require(_spender != address(0));
    
     allowance[msg.sender][_spender] = _value;
     emit approval(msg.sender , _spender , _value);
     return true;
 }
    function transferFrom(address _from , address _to ,  uint256 _value) external returns (bool){
    
     require( _value  <= balanceOf[_from]);
     require( _value  <= allowance[_from][msg.sender] );
    
     allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
     internalTransfer(_from , _to , _value);
     return true;
    
 }
 
}