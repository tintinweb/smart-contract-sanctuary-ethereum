/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

// SPDX-License-Identifier: UNLICENSED
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

// File: Solidity/course/4.Function_types,_modifiers/FunctionTypesPracticeInput.sol


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

contract First is IFirst, Ownable{
    uint256 public ePublic;
    uint256 private ePrivate;
    uint256 internal eInternal;

    function setPublic(uint256 num) external onlyOwner{
        ePublic = num;
    }

    function setPrivate(uint256 num) external onlyOwner{
        ePrivate = num;
    }

    function setInternal(uint256 num) external onlyOwner{
        eInternal = num;
    }

    function sum() external view virtual returns (uint256){
        return ePublic + ePrivate + eInternal;
    }

    function sumFromSecond(address contractAddress) external returns (uint256){
        (, bytes memory data) = contractAddress.call(abi.encodeWithSignature("sum()"));
        return uint256(bytes32(data));
    }

    function callExternalReceive(address payable contractAddress) external payable{
        (bool success, ) = contractAddress.call{value: 0.0001 ether}("");
        require(success);
    }
    function callExternalFallback(address payable contractAddress) external payable{
        (bool success, ) = contractAddress.call{value: 0.0002 ether}("sampletext");
        require(success);
    }
    function getSelector() external pure returns (bytes memory){
        return abi.encodePacked(this.setPublic.selector,
        this.setPrivate.selector,
        this.setInternal.selector,
        this.sum.selector,
        this.sumFromSecond.selector,
        this.callExternalReceive.selector,
        this.callExternalFallback.selector,
        this.getSelector.selector,
        this.ePublic.selector);
    }
}

contract Second is First{
    mapping(address => uint256) public balance;

    function sum() external view override returns (uint256){
        return ePublic + eInternal;
    }

    receive() external payable{
        balance[tx.origin] += msg.value;
    }

    fallback() external payable{
        balance[msg.sender] += msg.value;
    }
}