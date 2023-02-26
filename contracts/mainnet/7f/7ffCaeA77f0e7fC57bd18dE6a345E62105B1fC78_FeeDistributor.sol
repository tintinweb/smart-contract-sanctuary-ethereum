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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

contract FeeDistributor is Ownable {
    address payable address1 = payable(0x9a1d70D69Fa9E6B48866f77265E7bc042B0ee862);
    address payable address2 = payable(0xA97Ba1bceF4DD65d69008429f4866c658f175160);
    address payable address3 = payable(0x678a2fc326dEE5d986C48Ee75992F784Ab3a561c);
    address payable address4 = payable(0x8406B19D6e8A39134723F023Cb75a6d21D02F919);
    uint256 percentage1 = 20;
    uint256 percentage2 = 50;
    uint256 percentage3 = 20;

    function setAddress1(address payable _address) public onlyOwner {
        address1 = payable(_address);
    }

    function setAddress2(address payable _address) public onlyOwner {
        address2 = payable(_address);
    }

    function setAddress3(address payable _address) public onlyOwner {
        address3 = payable(_address);
    }

    function setAddress4(address payable _address) public onlyOwner {
        address4 = payable(_address);
    }

    function setPercentage1(uint256 _percentage) public {
        percentage1 = _percentage;
    }

    function setPercentage2(uint256 _percentage) public {
        percentage2 = _percentage;
    }

    function setPercentage3(uint256 _percentage) public {
        percentage3 = _percentage;
    }

    function checkAddress1() public view returns(address, uint256) {
        return (address1, percentage1);
    }

    function checkAddress2() public view returns(address, uint256) {
        return (address2, percentage2);
    }

    function checkAddress3() public view returns(address, uint256) {
        return (address3, percentage3);
    }

    function checkAddress4() public view returns(address, uint256) {
        uint256 _address4Percentage = 100 - (percentage1 + percentage2 + percentage3);
        return (address4, _address4Percentage);
    }
    
    fallback() external payable {
        uint256 _address1Value = msg.value * percentage1 / 100;
        uint256 _address2Value = msg.value * percentage2 / 100;
        uint256 _address3Value = msg.value * percentage3 / 100;
        uint256 _address4Value = msg.value - _address1Value - _address2Value - _address3Value;
        address1.transfer(_address1Value);
        address2.transfer(_address2Value);
        address3.transfer(_address3Value);
        address4.transfer(_address4Value);
    }
    
    receive() external payable {
        uint256 _address1Value = msg.value * percentage1 / 100;
        uint256 _address2Value = msg.value * percentage2 / 100;
        uint256 _address3Value = msg.value * percentage3 / 100;
        uint256 _address4Value = msg.value - _address1Value - _address2Value - _address3Value;
        address1.transfer(_address1Value);
        address2.transfer(_address2Value);
        address3.transfer(_address3Value);
        address4.transfer(_address4Value);
    }
}