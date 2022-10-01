/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

// File: contracts/LNR_SWAP_V1.sol


// By Derp Herpenstein (https://www.derpnation.xyz, https://www.avime.com)

pragma solidity ^0.8.0;



interface ILNR {
   function owner(bytes32 _name) external view returns(address);
   function transfer(bytes32 _name, address _to) external;
}

contract LNR_SWAP_LIST_V1 is ReentrancyGuard , Ownable{

    event LNRListing(bytes32 indexed name, uint256 price);
    event LNRListingRemove(bytes32 indexed name, uint256 price);
    event LNRSale(bytes32 indexed name, uint256 price);

    struct Listing {
      address owner;
      uint256 price;
    }

    mapping(bytes32 => Listing) public currentListings;
    address public lnrAddress = address(0);   //0x5564886ca2C518d1964E5FCea4f423b41Db9F561;

   constructor() payable Ownable(){
    }

    function deposit() public payable {
    }

    function updateLNRAddress(address _addr) public onlyOwner {
      require(lnrAddress == address(0), 'Can only be changed once'); // this gets set one time, then can never be changed, contract is *paused* until this is set
      lnrAddress = _addr;
    }

    function withdraw(uint256 _value) public onlyOwner nonReentrant { // allows me to take any tips people send to the contract (buyItem has an option tip, but is otherwise free)
        (bool sent, bytes memory data) = payable(msg.sender).call{value: _value}("");
        require(sent, "FAILED");
    }

    function unstick(bytes32 _name, address _owner) public onlyOwner nonReentrant {    // contract is so old it has no approve function, requires 2 txs in correct order!
        require(lnrAddress != address(0), 'Paused');                                   // first you addListing, and then you use need to manually send your LNR over
        require(currentListings[_name].owner == address(0), "Token not stuck");        // if someone sends their LNR without making a listing first it will get stuck
        ILNR(lnrAddress).transfer(_name, _owner);                                      // if the contract holds any LNR that do not have a listing, they need to be manually unstuck
        require(ILNR(lnrAddress).owner(_name) == _owner,"Transfer Failed");
    }

    function removeListing(bytes32 _name) public nonReentrant{
      require(lnrAddress != address(0), 'Paused');
      if(ILNR(lnrAddress).owner(_name)  == address(this))                    // if the owner is this contract, enforce that the listed owner is the sender
        require(currentListings[_name].owner == msg.sender, "Not yours");    // otherwise, this will only succeed if the caller is the msg.sender
      else                                                                   // lnt transfer function doesnt revert no matter what, need to
        require(ILNR(lnrAddress).owner(_name) == msg.sender, "Not yours");   // use its owner function to verify final owner
      emit LNRListingRemove(_name,currentListings[_name].price);
      Listing memory newListing;
      newListing.owner = address(0);
      newListing.price = 0;
      currentListings[_name] = newListing;
      ILNR(lnrAddress).transfer(_name, msg.sender);
      require(ILNR(lnrAddress).owner(_name) == msg.sender,"Transfer Failed");
    }

    function addListing(bytes32 _name, uint256 _price) public nonReentrant { // must add a listing and THEN send your token to this contract!
        require(lnrAddress != address(0), 'Paused');                         // listing is a simple struct holding the owner and the price
        address currentOwner = ILNR(lnrAddress).owner(_name);
        require( currentOwner == msg.sender || ( ((currentListings[_name].owner) == msg.sender) && (currentOwner == address(this)) ) , "Not owner"); // only the token owner can add/update a listing
        Listing memory newListing;
        newListing.owner = msg.sender;
        newListing.price = _price;
        currentListings[_name] = newListing;
        emit LNRListing(_name,_price);
    }

    function buyItem(bytes32 _name, address _destination) public nonReentrant payable { // checks to see if the token is for sale, if it is, facilitaes the sale
      require(lnrAddress != address(0), 'Paused');
      require(currentListings[_name].owner != address(0), "Not for sale");
      require(msg.value >= currentListings[_name].price, "Incorrect Price"); //alows for a tip
      require(msg.value <= currentListings[_name].price*105/100, "Too generous"); //of up to 5%
      ILNR(lnrAddress).transfer(_name, _destination);
      require(ILNR(lnrAddress).owner(_name) == msg.sender,"Transfer Failed"); // will fail if this contract doesnt own the LNR
      (bool sent, bytes memory data) = payable(currentListings[_name].owner).call{value: (currentListings[_name].price)}("");
      require(sent, "Count not send funds");
      emit LNRSale(_name, currentListings[_name].price);
      Listing memory newListing;
      newListing.owner = address(0);
      newListing.price = 0;
      currentListings[_name] = newListing;
    }
}