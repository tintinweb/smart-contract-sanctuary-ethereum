// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Strategies.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MainStrategies  is Ownable{
    struct strategy {
        address managger;
        address strategyAddress;
        uint id;
        bool state;
    }

    
    
    address[] public allStrategys;

    mapping ( address => strategy[] ) public myStrategy; //for mannagger => strategiesContracts;
    mapping ( address => uint[] ) public myFollowsStrategy; //for investors => id (read in contract is state(bool))
    mapping ( address => uint) public strategiesId;


    //Create new strategy
    function strategyFactory() public{
        address addressNewStrategy = address (new Strategies(msg.sender, owner()));
        uint id = allStrategys.length;
        strategy memory newStrategy = strategy(msg.sender, addressNewStrategy, id, true);

        allStrategys.push(addressNewStrategy);
        myStrategy[msg.sender].push(newStrategy);
        strategiesId[addressNewStrategy] = id;     
    }

    //Follow new strategy
    function follow(uint _id) public {
        Strategies  idStrategy = Strategies(allStrategys[_id]);
        idStrategy.follow(msg.sender);
        myFollowsStrategy[msg.sender].push(_id);
    }


    function getAllStrategies() public view returns (address[] memory){
        return allStrategys;
    }
    function getTotalStrategies() public view returns (uint){
        return allStrategys.length;
    }

    function getMyStrategies(address _manager) public view returns (strategy[] memory) {
        return myStrategy[_manager];
    }

    function getMyFollows() public view returns(uint[] memory){
        return myFollowsStrategy[msg.sender];
    }
    
    constructor() {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract Strategies  {
  // address router;
  address public managger;
  address public house;
  address public builder;
  bool public pause;
  uint public cantOfFollows;

  int public historicalProfits;
  mapping(address => int) public userProfits;
  mapping(address => bool) public follows;


  constructor(
    address _managger,
    address _house
  ) {
    house = _house;
    managger = _managger;
    builder = msg.sender;
  }

  function Stop() public {
    address sender = msg.sender;
    require((sender == managger) || (sender == house) || (sender == builder), "you do not have this permission" );
    pause = true;
  }

  function Play() public {
    address sender = msg.sender;
    require((sender == managger) || (sender == house) || (sender == builder), "you do not have this permission" );
    pause = false;
  }

  //only for testing facilities

  function setBalance(int _balance) public {
    historicalProfits = _balance;
  }

  function setUserProfits(int _balance) public {
    userProfits[msg.sender] = _balance;
  }

  function follow(address _newFollow) public {
    require(follows[_newFollow] == false, "Need dont follow this strategy" );
    follows[_newFollow] = true;
    cantOfFollows++;
  }

  function unFollow(address _unFollow) public {
    require(cantOfFollows > 0, "This strategy dont have any follow");
    // require(msg.sender = _unFollow)
    follows[_unFollow] = true;
    cantOfFollows--;
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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