/**
 *Submitted for verification at Etherscan.io on 2022-08-23
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

// File: userStorage.sol


pragma solidity 0.8.11;


contract UserStorage is Ownable {
    struct User {
        address addrs;
        string userType;
        string uri;
        bool accepted;
    }
    uint public gs;
    // mapping key to specific value;
    mapping(address => User) public _applied;
    //mapping for check if profession exist or not
    mapping(string => bool) public _profession;
    // user registered with profession
    mapping(address => string) private index;
    // store all profession type
    string[] public profession;

    //profession are only created by only admin
    // give error if profession already existed
    function createProfession(string [] memory _professions) public onlyOwner {
       for(uint i =0 ; i < _professions.length ; i++){
        require(
            _profession[_professions[i]] == false,
            "profession already existed"
        );
        _profession[_professions[i]] = true;
        profession.push(_professions[i]);
    }
   
 }

    // show all available profession that a user can apply
    function showProfession() public view returns (string[] memory) {
        return profession;
    }

    // user enter type and uri to apply for a profession
    function applyUser(string memory UserType, string memory uri)
        public
        virtual
    {
        require(
            _applied[msg.sender].addrs != msg.sender,
            " Waiting for admin approval"
        );
        require(_profession[UserType] == true, "profession type not available");
        require(
            _applied[msg.sender].accepted == false,
           " User already assigned a profession"
        );
        _applied[msg.sender].userType = UserType;
        _applied[msg.sender].addrs = msg.sender;
        _applied[msg.sender].uri = uri;
    }

    // admin check if user is elgible
    // only admin can assigned  profession to a user
    // if rejected user detail will delete
    function approveUser(address addr, bool approve) public onlyOwner {
        require(
            _applied[addr].addrs ==addr,
            "User not found "
        );
        require(
            _applied[addr].accepted != true,
            " User already assigned a profession ."
        );
        if (approve == true) {
             //  approve address.
            _applied[addr].accepted = true;
             // using mapping to assigned address to the profession.
            index[addr] = _applied[addr].userType;
        }
         //delete profile if not approved
          else {
            delete _applied[addr].userType;
            delete _applied[addr].addrs;
            delete _applied[addr].uri;
        }
    }

    // checking the value bound with the address .
    function userType(address addr) public view returns (string memory) {
        // return value from (users)array => (index)mapping => (addr) specific address -1{(array start from 0)}
        return index[addr];
    }

    // delete existing user
    function deleteUser() public {
         require(
            _applied[msg.sender].accepted == true,
            "No user exist"
        );
        delete index[msg.sender];
        delete _applied[msg.sender];  
    }
}
// ["eclectrician","plumber","escrow Agent","inspector"]