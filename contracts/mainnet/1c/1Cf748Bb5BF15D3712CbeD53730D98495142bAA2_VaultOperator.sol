// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Common} from "./libraries/Common.sol";
import {IBribeVault} from "./interfaces/IBribeVault.sol";
import {IRewardDistributor} from "./interfaces/IRewardDistributor.sol";

contract VaultOperator is Ownable {
    IBribeVault public immutable bribeVault;
    IRewardDistributor public immutable rewardDistributor;
    address public operator;

    error NotAuthorized();
    error ZeroAddress();

    constructor(address _bribeVault, address _rewardDistributor) {
        bribeVault = IBribeVault(_bribeVault);
        rewardDistributor = IRewardDistributor(_rewardDistributor);

        // Default to the deployer
        operator = msg.sender;
    }

    modifier onlyOperator() {
        if (msg.sender != operator) revert NotAuthorized();
        _;
    }

    /**
        @notice Set the operator
        @param  _operator  address  Operator address
     */
    function setOperator(address _operator) external onlyOwner {
        if (_operator == address(0)) revert ZeroAddress();

        operator = _operator;
    }

    /**
        @notice Redirect transferBribes call to the bribeVault for approved operator
        @param  rewardIdentifiers  bytes32[]  List of rewardIdentifiers
     */
    function transferBribes(bytes32[] calldata rewardIdentifiers)
        external
        onlyOperator
    {
        bribeVault.transferBribes(rewardIdentifiers);
    }

    /**
        @notice Redirect updateRewardsMetadata call to the rewardDistributor for approved operator
        @param  distributions  Distribution[]  List of reward distribution details
     */
    function updateRewardsMetadata(Common.Distribution[] calldata distributions)
        external
        onlyOperator
    {
        rewardDistributor.updateRewardsMetadata(distributions);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
pragma solidity ^0.8.0;

library Common {
    struct Distribution {
        bytes32 identifier;
        address token;
        bytes32 merkleRoot;
        bytes32 proof;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IBribeVault {
    function depositBribeERC20(
        bytes32 bribeIdentifier,
        bytes32 rewardIdentifier,
        address token,
        uint256 amount,
        address briber
    ) external;

    function getBribe(bytes32 bribeIdentifier)
        external
        view
        returns (address token, uint256 amount);

    function depositBribe(
        bytes32 bribeIdentifier,
        bytes32 rewardIdentifier,
        address briber
    ) external payable;

    function transferBribes(bytes32[] calldata rewardIdentifiers) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Common} from "../libraries/Common.sol";

interface IRewardDistributor {
    function updateRewardsMetadata(Common.Distribution[] calldata distributions)
        external;
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