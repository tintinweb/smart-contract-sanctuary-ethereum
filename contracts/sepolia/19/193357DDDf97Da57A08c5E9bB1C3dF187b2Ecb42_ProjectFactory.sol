// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CloneFactory.sol";
import "./Project.sol";

// Factory contract to create Project contractsP
// Author: @hoafnguyeexn
contract ProjectFactory is Ownable, CloneFactory {

    address[] public deployedProjects;

    // Address of the template project contract
    address public libraryAddress;

    // Event to notify when a new project is created
    event ProjectCreated(address projectAddress);

    function setLibraryAddress(address _libraryAddress) public onlyOwner {
        libraryAddress = _libraryAddress;
    }

    // Create a new project contract
    function createProject(uint256 _fundingGoal) external {
        // Create a new project contract using the clone factory
        address clone = createClone(libraryAddress);

        // Set the project details
        Project(clone).init(payable(msg.sender), _fundingGoal);

        // Add the project to the list of deployed projects
        deployedProjects.push(clone);

        // Emit event
        emit ProjectCreated(clone);
    }

    // Get the number of deployed projects
    function getDeployedProjects() external view returns (address[] memory) {
        return deployedProjects;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

/*
The MIT License (MIT)

Copyright (c) 2018 Murray Software, LLC.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly
pragma solidity ^0.8.9;

contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
// Smart contract for a project
// Author: @hoafnguyeexn
contract Project {

    struct Backer {
        address backer;
        uint256 amount;
    }

    mapping (address => Backer) public backers;
    address payable public creator; // Creator address
    uint256 public fundingGoal; // Funding goal as wei
    bool public isGoalReached = false; // Whether the funding goal has been reached
    uint256 public totalCollected = 0; // Total amount collected

    event FundingGoalReached(uint256 totalCollected);
    event Payout(address payable recipient, uint256 amount);
    event Withdraw(address payable backer, uint256 amount);
    event Deduct(address payable creator, uint256 amount);

    function init(address payable _projectCreator, uint256 _goal) public {
        // This function is used to set the project details
        creator = _projectCreator;
        fundingGoal = _goal;
    }

    function pledge() external payable  {
        require(msg.sender != creator, "Creator cannot pledge"); // Creator cannot contribute to their own campaign
        require(msg.value > 0, "You must pledge some ETH");
        backers[msg.sender].backer = msg.sender;
        backers[msg.sender].amount += msg.value;
        totalCollected += msg.value;

        if (totalCollected >= fundingGoal) {
            isGoalReached = true; // Goal has been reached
        }
    }

    function deduct(uint256 value) external {
        // This function is used for transfering the deducted funds to the creator's wallet address
        require(msg.sender == creator, "Only the creator can deduct funds");
        require(value <= address(this).balance, "Cannot deduct more than the available balance");
        creator.transfer(value);
        emit Deduct(creator, value);
    }

    function payout() external  {
        // This function is used for paying out creator if the project is closed and the funding goal is reached AUTOMATICALLY
        require(isGoalReached, "The project did not reach its funding goal");
        require(msg.sender == creator, "Only the project creator can receive the funds");
        uint256 amount = address(this).balance;
        creator.transfer(amount);
        emit Payout(creator, amount);
    }

    function withdraw() external {
        // this function is used for contributors to withdraw their funds if the project is still live
        require(msg.sender != creator, "Creator cannot withdraw"); // Creator cannot contribute to their own campaign
        require(backers[msg.sender].amount > 0, "Backer did not pledge to the project");
        uint256 amount = backers[msg.sender].amount;
        backers[msg.sender].amount = 0;
        totalCollected -= amount;

        if (totalCollected < fundingGoal) {
            isGoalReached = false; // Goal has not been reached
        }

        payable(msg.sender).transfer(amount);
    }
}