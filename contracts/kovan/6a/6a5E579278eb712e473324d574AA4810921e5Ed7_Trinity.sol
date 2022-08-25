// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

// Import 3P libraries here
import "@openzeppelin/contracts/access/Ownable.sol";

// Using errors is cheaper than storing strings
error Trinity__NotEnoughStakeSupplied();
error Trinity__InvalidEmployer();
error Trinity__InvalidValidator();
error Trinity__FlushFailed();

contract Trinity is Ownable {
    // Out of Scope:
    // - We assume a validator can verify for any skill
    // - Use SBT instead of NFT
    // - Have a governance vote to add validator

    // Contract work:
    // - Employers pay to enlist to the contract by paying 0.01 ETH
    // - Validators are added by the owner of the contract
    // - Issue NFT for each skill a candidate has by the validator
    // - Candidates are hidden from the public
    // - Payout on end of interview called

    // FE:
    // - Candidate information and indexing
    //   - Skills submission portal
    //   - Use magic for login for candidates?
    // - Validator login
    //   - Ability to get candidates and schedule interview
    //   - Track process
    // - Employee login
    //   - Ability to get candidates and schedule interview
    //   - Track process
    // BE:
    // - Module for tracking interviews
    // - Module for indexing candidates
    // - Module to call endInterview

    // State
    uint256 private immutable i_entranceFee;

    address payable[] private s_employers;
    mapping(address => uint256) private s_employersStake;

    address payable[] private s_validators;
    mapping(address => uint8) private s_validatorsList;

    // Off-chain events
    event ValidatorAdded(address payable indexed validator);
    event EmployerEnlisted(address indexed employer);
    event SkillCertificateIssued(address indexed candidate, string indexed skill, address indexed validator);


    constructor(uint256 _entranceFee) {
        i_entranceFee = _entranceFee;
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function isValidator(address _validator) public view returns (bool) {
        return s_validatorsList[_validator] != 0;
    }

    function addValidator(address _validator) public onlyOwner {
        s_validators.push(payable(_validator));

        // This is used to check validators
        s_validatorsList[_validator] = 1;

        // TODO: Issue NFT to validators?

        // Emit an event for the new validator
        emit ValidatorAdded(payable(_validator));
    }

    // Check if a given address is an employer or not
    function isEmployer(address _employer) public view returns (bool) {
        return s_employersStake[_employer] != 0;
    }

    // Return the amount staked by an employer, only a valid employer
    // can call this function
    function getEmployerStake(address _employer) public view returns (uint256) {
        if (!isEmployer(_employer)) {
            revert Trinity__InvalidEmployer();
        }

        return s_employersStake[_employer];
    }

    function enlistEmployer() public payable {
        if (msg.value < i_entranceFee) {
            revert Trinity__NotEnoughStakeSupplied();
        }

        // TODO: Should we also keep track of candidates they have?
        // Off-chain, Update count of candidates in consideration and ensure it's only 1 per 0.01 ETH

        // Keep track of all employers and also keep track of their state
        s_employers.push(payable(msg.sender));
        s_employersStake[payable(msg.sender)] += msg.value;

        // Emit the event for off-chain consumption
        emit EmployerEnlisted(msg.sender);
    }

    // TODO: Limit validators to only certain skills and not all skills
    function issueSkillCertificate(address candidate, string memory skill) public {
        // Ensure that only a valid validator can call this
        if (!isValidator(msg.sender)) {
            revert Trinity__InvalidValidator();
        }

        // FIXME: Issue NFT to candidate
        // NFT will have details of the validator as well.

        // Offchain events
        emit SkillCertificateIssued(candidate, skill, msg.sender);
    }

    // TODO: The owner should be a multisign or a DAO which
    // controls all the funds
    // Transfer all the stake amount to the owner to be redistributed
    function killSwitch() onlyOwner public {
        address payable receiver = payable(owner());

        // Transfer all the staked amount in the contract to the
        // owner of the contract
        bool success = receiver.send(address(this).balance);
        if (!success) {
            revert Trinity__FlushFailed();
        }

        // Zero out all the stakes of the employers and remove
        // all employers from the list
        for (uint256 i = 0; i < s_employers.length; i++) {
            s_employersStake[s_employers[i]] = 0;
        }
        s_employers = new address payable[](0);
    }

    // FIXME: Write this function
    function endInterview() public onlyOwner view {
        // This function will just throw an error
        // It will be called by the validator when the interview is over
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