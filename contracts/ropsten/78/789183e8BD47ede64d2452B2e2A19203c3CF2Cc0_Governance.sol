// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

pragma solidity 0.8.10;

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

contract Governance is Ownable {

    enum Roles {notRegistered, stakeHolder}
    mapping(address => Roles) public roles;

    uint256 public totalAmount;

    struct OnboardingProposal {
        address proposer;
        address candidate;
        Roles role;
        uint256 amount;
    }

    struct StakeHolderAssets {
        uint256 amount;
    }

    mapping(address => StakeHolderAssets) public stakeHolderAssets;

    mapping(address => OnboardingProposal) public onboardingProposals;

    constructor(uint threshold_, address[] memory owners_, uint chainId) {
        require(owners_.length <= 10 && threshold_ <= owners_.length && threshold_ > 0);
        require(chainId > 0);
        for (uint i = 0; i < owners_.length; i++) {
            roles[owners_[i]] = Roles.stakeHolder;
            stakeHolderAssets[owners_[i]].amount = 1;
        }
    }

    function addOnboardingProposal(address id, address candidate, Roles role, uint256 amount) public payable {
        require(onboardingProposals[id].amount == 0, "Already registered proposal");
        onboardingProposals[id] = OnboardingProposal({ proposer: msg.sender, candidate: candidate,
                    role: role, amount: amount});
    }

    function approveOnboardingProposal(address id) public payable {
        require(onboardingProposals[id].amount > 0, "Proposal does not exist");
        require(stakeHolderAssets[msg.sender].amount > 0, "Stakeholder does not have enough amount");
        require(roles[msg.sender] == Roles.stakeHolder, "Sender is not stakeholder");
    }

}