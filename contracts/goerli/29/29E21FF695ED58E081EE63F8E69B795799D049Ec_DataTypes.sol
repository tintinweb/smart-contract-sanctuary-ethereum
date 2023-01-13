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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract A {
    uint256 public x;

    constructor(uint256 _x) {
        x = _x;
    }
}

enum Status {
    Accepted,
    Rejected,
    Canceled
}

struct Todo {
    string text;
    bool completed;
}

struct TodoWithMap {
    string text;
    bool completed;
    mapping(uint256 => uint256) map;
}

type CustomNumber is uint256;
error CustomErrorWithParameter(address test);

contract DataTypes is Ownable {
    uint256 public num;
    int256 private amount;
    bool internal _bool;
    address public addr = 0xb794F5eA0ba39494cE839613fffBA74279579268;
    bytes1 private _byte = 0xb5;
    string public str = "Hello";
    bytes32 public role = keccak256("admin");
    uint[] public arr;
    uint[5] public fixedSizeArr;
    uint256 public counter = 0;
    mapping(uint256 => A) public contracts;
    mapping(uint256 => mapping(uint256 => uint256)) public nestedMap;
    CustomNumber public customNum;
    Status public status;
    Todo[] public todos;
    TodoWithMap public myTodo;

    constructor() {
        contracts[counter++] = new A(15);
        customNum = CustomNumber.wrap(999);
        myTodo.text = "Hello World";
        myTodo.completed = true;
        myTodo.map[0] = 1;
    }

    function deployContract(uint256 x) public {
        contracts[counter++] = new A(x);
    }

    mapping(address => uint) public map;

    function setNum(uint256 newNum) public {
        num = newNum;
    }

    // function overloading
    function setNum(uint256 newNum, uint256 x) public {
        num = newNum + x;
    }

    function setAmount(int256 newAmount) external {
        amount = newAmount;
    }

    function setExternalBool(bool newBoo) external {
        setInternalBool(newBoo);
    }

    function setInternalBool(bool newBoo) internal {
        _bool = newBoo;
    }

    function getBool() public view returns (bool) {
        return _bool;
    }

    function getAddr() public view returns (address) {
        return (addr);
    }

    function getPure() external pure returns (uint16) {
        return (15 + 17);
    }

    function getStatus() public view returns (Status) {
        return status;
    }

    function setStatus(Status _status) public {
        status = _status;
    }

    function setByte(bytes1 newByt) private {
        _byte = newByt;
    }

    function setExternalByte(bytes1 newByt) external {
        setByte(newByt);
    }

    function push(uint i) public {
        arr.push(i);
    }

    function getArrSingle(uint i) public view returns (uint) {
        return arr[i];
    }

    function getArrDynamic() public view returns (uint[] memory) {
        return arr;
    }

    function getArr() public view returns (uint[5] memory) {
        return fixedSizeArr;
    }

    function concatStr(string memory newStr) external view returns (string memory) {
        return string.concat(str, newStr);
    }

    function createStruct(string calldata _text) public {
        todos.push(Todo(_text, false));
    }

    function getStruct(uint _index) public view returns (string memory text, bool completed) {
        Todo storage todo = todos[_index];
        return (todo.text, todo.completed);
    }

    function getMap(address _addr) public view returns (uint) {
        return map[_addr];
    }

    function setMap(address _addr, uint _i) public {
        map[_addr] = _i;
    }

    function allTodos() public view returns (Todo[] memory) {
        return todos;
    }

    function payMe(uint256 _x) public payable {
        num = _x;
        require(msg.value > 0, "You need to send some Ether");
        (bool success, ) = msg.sender.call{value: msg.value}("");
        assert(success);
    }

    function fail(Todo memory todo) public view {
        revert CustomErrorWithParameter(msg.sender);
    }
}