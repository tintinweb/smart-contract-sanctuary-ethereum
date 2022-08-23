/**
 *Submitted for verification at Etherscan.io on 2022-08-22
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

// File: walifyFinal.sol


pragma solidity ^0.8.4;


contract walifyRegistry is Ownable{

mapping (address => address) public proxy_to_root;

mapping (address => address) public root_to_proxy;

mapping (address => address) public root_to_proxy_proofs;

uint256 public registration_fee = 0;

event Register(address root, address proxy);

event Proved(address root,address proxy);

    function register(address proxy_address) public payable{

        require(registration_fee <= msg.value, "not enough value");

        require(proxy_to_root[proxy_address] == 0x0000000000000000000000000000000000000000, "proxy already registered");

        proxy_to_root[proxy_address] = msg.sender;
        // todo clear previous proxy_to_root
        root_to_proxy[msg.sender] = proxy_address; 

        emit Register(msg.sender, proxy_address);

    }

    function registerWithProof( address proxy_address) public payable{

        require(registration_fee <= msg.value, "not enough value");

        require(root_to_proxy_proofs[msg.sender] == proxy_address, "proof invalid");

        proxy_to_root[proxy_address] = msg.sender;

        root_to_proxy[msg.sender] = proxy_address; 

         emit Register(msg.sender, proxy_address);

    }

    function prooveProxy(address root) public{
        root_to_proxy_proofs[root] = msg.sender;

        emit Proved(root, msg.sender);
    }


    function verify(address root, address proxy) public view returns(bool) {

        return proxy_to_root[proxy] == root;

    }

    function giveRoot(address proxy) public view returns(address) {

        return proxy_to_root[proxy];

    }

    function giveProxy(address root) public view returns(address) {

        return root_to_proxy[root];

    }

    function setFee(uint256 fee) public onlyOwner(){

        registration_fee = fee;

    }

    function getFee() public view returns(uint256){

        return registration_fee;

    }




}