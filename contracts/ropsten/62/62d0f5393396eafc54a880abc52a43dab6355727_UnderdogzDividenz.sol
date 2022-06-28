/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/UnderdogzDividens.sol



pragma solidity >=0.7.0 <0.9.0;


contract UnderdogzDividenz is Ownable {

    //Dividen Groups: ------------------------------------------------------------------------- 
    address payable[] dividenGroup1;
    address payable[] dividenGroup2;
    address payable[] dividenGroup3; 
    address payable[] dividenGroup4;
    address payable[] dividenGroup5; 

    //Deposit ether into contract: ------------------------------------------------------------
    function depositDividenPool() external payable onlyOwner {  //Treasury Wallet Deposit 
        if(msg.value < 1 ether) { //Must send at least 1 ether or deposit is cancelled
            revert(); 
        }
    }

    //Return the balance of contract: ----------------------------------------------------------
    function getDividenPool() external view returns(uint) { 
        return address(this).balance; 
    }


    //Send Dividens: 
    function payDividenGroup1() public payable onlyOwner{
        for (uint i = 0; i < dividenGroup1.length; i++) {
            dividenGroup1[i].transfer(msg.value); 
        }
    }

    function payDividenGroup2() public payable onlyOwner{
        for (uint i = 0; i < dividenGroup2.length; i++) {
            dividenGroup2[i].transfer(msg.value); 
        }
    }

    function payDividenGroup3() public payable onlyOwner{
        for (uint i = 0; i < dividenGroup3.length; i++) {
            dividenGroup3[i].transfer(msg.value); 
        }
    }

    function payDividenGroup4() public payable onlyOwner{
        for (uint i = 0; i < dividenGroup4.length; i++) {
            dividenGroup4[i].transfer(msg.value); 
        }
    }

    function payDividenGroup5() public payable onlyOwner{
        for (uint i = 0; i < dividenGroup1.length; i++) {
            dividenGroup5[i].transfer(msg.value); 
        }
    }

   





}