// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(0x74DcB9344393dCDA0Fa3E4349D34149AEeE617F6);
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

contract PibesSplitter is Ownable {
    address public first = 0xdBC522931928F8ff7784c84E5fCEc4fFDCd6E9eB;
    address public second = 0x46a3299b465Dfb25dBD0A30052c8576B7d85A9Dd;
    address public third = 0xe9863A4139Ff869A17A38749CEeEdb2E55721637;

    function setFirst(address _first) public onlyStaff {
        first = _first;
    }

    function setSecond(address _second) public onlyStaff {
        second = _second;
    }

    function setThird(address _third) public onlyStaff {
        third = _third;
    }

    receive() external payable {}

    modifier onlyStaff() {
        require(
            msg.sender == owner() ||
                msg.sender == first ||
                msg.sender == second ||
                msg.sender == third
        );
        _;
    }

    function release() public onlyStaff {
        uint256 payout = address(this).balance / 3;
        payable(first).transfer(payout);
        payable(second).transfer(payout);
        payable(third).transfer(payout);
    }
}