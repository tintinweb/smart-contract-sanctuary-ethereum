/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// Pledge Mint contract by Culture Cubs
// pledgemint.io

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IERC721Pledge {
    function pledgeMint(address to, uint8 quantity)
        external
        payable;
}

contract PledgeMint is Ownable, ReentrancyGuard {
    // Phases allow to have different cohorts of pledgers, with different contracts, prices and limits.
    struct PhaseConfig {
        address admin;
        IERC721Pledge mintContract;
        uint256 mintPrice;
        uint8 maxPerWallet;
        // When locked, the contract on which the mint happens cannot ever be changed again
        bool mintContractLocked;
        // Can only be set to true if mint contract is locked, which is irreversible.
        // Owner of the contract can still trigger refunds - but not access anyone's funds.
        bool pledgesLocked;
    }


    mapping(uint16 => address[]) public pledgers;
    mapping(uint16 => mapping(address => bool)) public allowlists;
    mapping(uint16 => mapping(address => uint8)) public pledges;

    PhaseConfig[] public phases;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _; 
    }

    modifier onlyAdminOrOwner(uint16 phaseId) {
        require(owner() == _msgSender() || phases[phaseId].admin == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor() {}

    function addPhase(address admin, IERC721Pledge mintContract, uint256 mintPrice, uint8 maxPerWallet) external onlyOwner {
        phases.push(PhaseConfig(admin, mintContract, mintPrice, maxPerWallet, false, false));
    }

    function allowAddresses(uint16 phaseId, address[] calldata allowlist_) external onlyAdminOrOwner(phaseId) {
        mapping(address => bool) storage _allowlist = allowlists[phaseId];
        for (uint i=0; i < allowlist_.length; i++) {
            _allowlist[allowlist_[i]] = true;
        }
    }

    function pledge(uint16 phaseId, uint8 number) external payable callerIsUser {
        PhaseConfig memory phase = phases[phaseId];
        require(number <= phase.maxPerWallet, "Cannot buy that many NFTs");
        require(number > 0, "Need to buy at least one");
        require(msg.value == phase.mintPrice * number, "Amount mismatch");
        require(pledges[phaseId][msg.sender] == 0, "Already pledged");
        pledgers[phaseId].push(msg.sender);
        pledges[phaseId][msg.sender] = number;
    }

    function unpledge(uint16 phaseId) external nonReentrant callerIsUser {
        require(phases[phaseId].pledgesLocked == false, "Pledges are locked for this phase");

        uint nbPledged = pledges[phaseId][msg.sender];
        require(nbPledged > 0, "Nothing pledged");
        pledges[phaseId][msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: phases[phaseId].mintPrice * nbPledged}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function lockPhase(uint16 phaseId) external onlyAdminOrOwner(phaseId) {
        require(phases[phaseId].mintContractLocked == true, "Cannot lock pledges without locking the mint contract");
        phases[phaseId].pledgesLocked = true;
    }

    function unlockPhase(uint16 phaseId) external onlyAdminOrOwner(phaseId) {
        phases[phaseId].pledgesLocked = false;
    }

    // mint for all participants
    function mintPhase(uint16 phaseId) external onlyAdminOrOwner(phaseId) {
        address[] memory _addresses = pledgers[phaseId];
        _mintPhase(phaseId, _addresses, 0, _addresses.length);
    }

    // mint for all participants, paginated
    function mintPhase(uint16 phaseId, uint startIdx, uint length) external onlyAdminOrOwner(phaseId) {
        address[] memory _addresses = pledgers[phaseId];
        _mintPhase(phaseId, _addresses, startIdx, length);
    }

    // mint for select participants
    // internal function checks eligibility and pledged number.
    function mintPhase(uint16 phaseId, address[] calldata selectPledgers) external onlyAdminOrOwner(phaseId) {
        _mintPhase(phaseId, selectPledgers, 0, selectPledgers.length);
    }

    function _mintPhase(uint16 phaseId, address[] memory addresses, uint startIdx, uint count) internal {
        PhaseConfig memory _phase = phases[phaseId];
        require(_phase.mintContractLocked == true, "Cannot launch the mint without locking the contract");
        mapping(address => uint8) storage _pledges = pledges[phaseId];
        mapping(address => bool) storage _allowlist = allowlists[phaseId];
        for (uint i = startIdx; i < count; i++) {
            address addy = addresses[i];
            uint8 quantity = _pledges[addy];

            // Any address not allowed will have to withdraw their pledge manually. We skip them here.
            if (_allowlist[addy] && quantity > 0) {
                _pledges[addy] = 0;
                _phase.mintContract.pledgeMint{ value: _phase.mintPrice * quantity }(addy, quantity);
            }
        }
    }

    function refundPhase(uint16 phaseId) external onlyAdminOrOwner(phaseId) nonReentrant {
        _refundPhase(phaseId);
    }

    function refundAll() external onlyOwner nonReentrant {
        for (uint8 i=0; i < phases.length; i++) {
            _refundPhase(i);
        }
    }

    function refundPhasePledger(uint16 phaseId, address pledger) external onlyAdminOrOwner(phaseId) nonReentrant {
        uint amount = pledges[phaseId][pledger] * phases[phaseId].mintPrice;
        pledges[phaseId][pledger] = 0;
        (bool success, ) = pledger.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function _refundPhase(uint16 phaseId) internal {
        PhaseConfig memory _phase = phases[phaseId];
        address[] storage _addresses = pledgers[phaseId];
        for (uint8 i = 0; i < _addresses.length; i++) {
            address addy = _addresses[i];
            uint8 quantity = pledges[phaseId][addy];
            pledges[phaseId][addy] = 0;
            (bool success, ) = addy.call{value: _phase.mintPrice * quantity}("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }
    }

    function emergencyRefund(uint16 phaseId, uint startIdx, uint count) external onlyOwner {
        PhaseConfig memory _phase = phases[phaseId];
        for (uint i = startIdx; i < count; i++) {
            address addy = pledgers[phaseId][i];
            uint8 quantity = pledges[phaseId][addy];

            (bool success, ) = addy.call{value: _phase.mintPrice * quantity}("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }
    }

    function setMintContract(uint16 phaseId, IERC721Pledge mintContract_) external onlyOwner {
        require(phases[phaseId].mintContractLocked != true, "Cannot change the contract anymore");
        phases[phaseId].mintContract = mintContract_;
    }

    // there is no unlock function. Once this is locked, funds pledged can only be used to mint on this contract, or refunded.
    function lockMintContract(uint16 phaseId) external onlyOwner {
        phases[phaseId].mintContractLocked = true;
    }
}