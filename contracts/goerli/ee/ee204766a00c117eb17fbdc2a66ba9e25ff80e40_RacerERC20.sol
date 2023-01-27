/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: contracts/RacerERC20.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17; 



interface IERC20 {

    //ERC20 Standard Functions: 
    function totalSupply() external view returns (uint); 

    function balanceOf(address account) external view returns (uint); 

    function transfer(address recipient, uint amount) external returns (bool); 

    function allowance(address owner, address spender) external view returns (uint); 

    function approve(address spender, uint amount) external returns (bool); 

    function transferFrom (
        address spender,
        address recipient,
        uint amount

    ) external returns (bool); 

    //Events:
    event Transfer (
        address indexed sender, 
        address indexed reciever, 
        uint amount
    ); 

    event Approval (
        address indexed owner,
        address indexed spender, 
        uint amount
    ); 
}


contract RacerERC20 is IERC20, Ownable {
    
    //State: ----------------------------------------------------

    address public racerNodeAddr; 

    string public name = "RACER";
    string public symbol = "RCR";

    uint public totalSupply; 
    uint8 public decimals = 18; //(10^18 = 1 RACER)

    uint256 public price = 0.01 ether; //Matic
    uint256 public airdrop = 10; //Amount of tokens airdropped on chainlink mint

    //Mappings: 
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance; 


    //ERC20 Functions: ----------------------------------------------------

    //Transfers RACER from msg.sender to recipient
    function transfer(address recipient, uint amount) external returns (bool) {

        require(balanceOf[msg.sender] >= amount, "Not enough RACER"); 

        balanceOf[msg.sender] -= amount; //Decrement msg.sender amount
        balanceOf[recipient] += amount; //Increment msg.sender amount

        emit Transfer(msg.sender, recipient, amount);
        return true;  
    }

    //Approve a spender: 
    function approve(address spender, uint amount) external returns (bool) {

        allowance[msg.sender][spender] = amount; 

        emit Approval(msg.sender, spender, amount); 
        return true; 
    } 

    //Transfers RACER from msg.sender to recipient
    function transferFrom (address sender, address recipient, uint amount) external returns (bool) {

        require(balanceOf[msg.sender] >= amount, "Not enough RACER"); 

        allowance[sender][msg.sender] -= amount;

        balanceOf[sender] -= amount; 
        balanceOf[recipient] += amount; 

        emit Transfer(sender, recipient, amount); 
        return true; 
    }

    //Minting: ----------------------------------------------------

    function mint (address minter, uint amount) external payable {

        //Only allowing the node to mint free calls 
        if (minter != msg.sender && msg.sender != racerNodeAddr) {
            require (minter == msg.sender, "Personal mints only");
            require(msg.value >= amount * price, "Insufficient Matic");

        }  

        totalSupply += amount;  
        balanceOf[minter] += amount; 
        
        emit Transfer(address(0), minter, amount); 
    }

    
    //Burning: 
    function burn (uint amount) external {

        balanceOf[msg.sender] -= amount; 
        totalSupply -= amount; 

        emit Transfer(msg.sender, address(0), amount); 
    }


    //Setters: ----------------------------------------------------

    function setPrice (uint256 _price) public onlyOwner { //ERC20    
        price = _price; 
    } 

    function setDecimals (uint8 _decimals) public onlyOwner { //ERC20
        decimals = _decimals; 
    }


}