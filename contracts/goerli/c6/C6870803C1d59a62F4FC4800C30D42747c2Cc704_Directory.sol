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

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDirectory.sol";

contract Directory is IDirectory, Ownable {
    address public service;

    struct ContractInfo {
        address addr;
        ContractType contractType;
        string description;
    }

    mapping(uint256 => ContractInfo) public contractRecordAt;

    uint256 public lastContractRecordIndex;

    mapping(address => uint256) public indexOfContract;

    struct ProposalInfo {
        address pool;
        uint256 proposalId;
        string description;
    }

    mapping(uint256 => ProposalInfo) public proposalRecordAt;

    uint256 public lastProposalRecordIndex;

    // EVENTS

    event ContractRecordAdded(
        uint256 index,
        address addr,
        ContractType contractType
    );

    event ProposalRecordAdded(uint256 index, address pool, uint256 proposalId);

    event ServiceSet(address service);

    event ContractDescriptionSet(uint256 index, string description);

    event ProposalDescriptionSet(uint256 index, string description);

    // PUBLIC FUNCTIONS

    function addContractRecord(address addr, ContractType contractType)
        external
        override
        onlyService
        returns (uint256 index)
    {
        index = ++lastContractRecordIndex;
        contractRecordAt[index] = ContractInfo({
            addr: addr,
            contractType: contractType,
            description: ""
        });
        indexOfContract[addr] = index;

        emit ContractRecordAdded(index, addr, contractType);
    }

    function addProposalRecord(address pool, uint256 proposalId)
        external
        override
        onlyService
        returns (uint256 index)
    {
        index = ++lastProposalRecordIndex;
        proposalRecordAt[index] = ProposalInfo({
            pool: pool,
            proposalId: proposalId,
            description: ""
        });

        emit ProposalRecordAdded(index, pool, proposalId);
    }

    function setService(address service_) external onlyOwner {
        service = service_;
        emit ServiceSet(service_);
    }

    function setContractDescription(uint256 index, string memory description)
        external
        onlyOwner
    {
        contractRecordAt[index].description = description;
        emit ContractDescriptionSet(index, description);
    }

    function setProposalDescription(uint256 index, string memory description)
        external
        onlyOwner
    {
        proposalRecordAt[index].description = description;
        emit ProposalDescriptionSet(index, description);
    }

    // PUBLIC VIEW FUNCTIONS

    function typeOf(address addr)
        external
        view
        override
        returns (ContractType)
    {
        return contractRecordAt[indexOfContract[addr]].contractType;
    }

    // MODIFIERS

    modifier onlyService() {
        require(msg.sender == service, "Not service");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IDirectory {
    enum ContractType {
        None,
        Pool,
        GovernanceToken,
        TGE
    }

    function addContractRecord(address addr, ContractType contractType)
        external
        returns (uint256 index);

    function addProposalRecord(address pool, uint256 proposalId)
        external
        returns (uint256 index);

    function typeOf(address addr) external view returns (ContractType);
}