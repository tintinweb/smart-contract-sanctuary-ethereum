/**
 *Submitted for verification at Etherscan.io on 2023-01-15
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

// File: year/AntCTF.sol


pragma solidity ^0.8.17;


contract AttackToWin is Ownable {

  uint256 public winnerCount; 
  mapping(address => bool) public winnerSimple;
  address public winnerHard;
  mapping(address => uint256) public winnerId;
  bool public open = true;
  
  bytes32 public constant answerHash = 0x32cefdcd8e794145c9af8dd1f4b1fbd92d6e547ae855553080fc8bd19c4883a0;

  bytes3 public magic;

  event IdRegistry(address addr, uint256 id);
  event WinSimple(address addr);
  event WinHard(address addr);

//   constructor(address _factory, bytes memory rand) public {
//     factory = _factory;
//     address thisContractAddr = IFactoryV1(factory).createContract(rand);
//     bytes20 tmp = bytes20(abi.encodePacked(thisContractAddr));
//     magic = bytes3(tmp);
//   }

  modifier isOpen {
    require(open, "game is not open!");
    _;
  }

  function setOpen(bool _open) external onlyOwner{
      open = _open;
  }

  function guess(uint8 trial) external isOpen{
      require(!winnerSimple[msg.sender], "You are already a winner!"); 
      require(winnerCount < 10, "Too late! There are already 10 winners!");
      require(keccak256(abi.encodePacked(trial)) == answerHash, "Sorry, guess is wrong!");
 
      winnerSimple[msg.sender] = true;
      winnerCount++;
  }

  function setMagic(bytes3 _magic) external onlyOwner{
      magic = _magic;
  }

  function challenge(bytes calldata secret) external isOpen{
      require(winnerHard == address(0), "already have a winner!"); 
      require(verify(secret), "Sorry, challenge failed!");
      winnerHard = msg.sender; 
  }

  function verify(bytes calldata secret) public returns(bool) {
      if( keccak256(abi.encodePacked(magic, secret)) 
            == keccak256(abi.encodePacked(msg.sender))
            ){
        return true;
      }

      (bool state, bytes memory returndata) = address(this).call(
          abi.encodeWithSelector(bytes4(secret[0:4]), secret[4:]));
      
      if(state && abi.decode(returndata, (bool))) {
        return true;
      }
      return false;
  }

  function test(uint8 n) external pure returns(bytes32){
      return keccak256(abi.encodePacked(n));
  }
  
  function registry(uint256 id) external {
      require(winnerSimple[msg.sender] || winnerHard == msg.sender, "only winner is allowed to register");
      winnerId[msg.sender] = id;
      emit IdRegistry(msg.sender, id);
  }
}

interface IFactoryV1 {
    function createContract(bytes calldata input) external returns (address attackToWin);
}

contract FactoryV1 is IFactoryV1 {
    event logBytes20(bytes20);
    event logAddress(address);
    event logBytes3(bytes3);
    function createContract(bytes calldata input) external returns (address attackToWin) {
        bytes memory bytecode = type(AttackToWin).creationCode;
        attackToWin = address(new AttackToWin{salt: keccak256(abi.encodePacked(input))}());
        emit logAddress(attackToWin);
        bytes20 tmp = bytes20(abi.encodePacked(attackToWin));
        emit logBytes20(tmp);
        emit logBytes3(bytes3(tmp));
        (bool state, bytes memory returndata) = attackToWin.call(abi.encodeWithSignature("setMagic(bytes3)", bytes3(tmp)));
        require(state, "Factory set magic failed");
    }
}