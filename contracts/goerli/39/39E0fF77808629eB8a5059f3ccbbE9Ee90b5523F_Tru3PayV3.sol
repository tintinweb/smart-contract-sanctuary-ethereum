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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.2;

library Array {

    function includesAddress(address[] memory wallets, address wallet) public pure returns(bool) {
        for (uint i=0; i < wallets.length; i++) {
            if(wallets[i] == wallet) return true;
        }
        return false;
    }

    function includesNumber(uint[] memory numbers, uint number) public pure returns(bool) {
        for (uint i=0; i < numbers.length; i++) {
            if(numbers[i] == number) return true;
        }
        return false;
    }

    function includesString(string[] memory strs, string memory str) public pure returns(bool) {
        for (uint i=0; i < strs.length; i++) {
            if(keccak256(bytes(strs[i])) == keccak256(bytes(str))) return true;
        }
        return false;
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ArrayUtility.sol";

struct Tru3Job {
    string id;
    uint paid;
    uint distributed;
    uint refunded;
    JobOptions options;
}

struct JobOptions {
    address[] owners;
    bool open;
}

contract Tru3PayV3 is Ownable, ReentrancyGuard {
    
    /* Public Variables */

    mapping(string => Tru3Job) public jobs;

    /* Private Variables */

    uint16 private constant _shareDenominator = 10000;
    uint16 private _fee = 100;
    address private _tru3mint = address(0);
    bool private _active = true;
    string[] private _jobIndex;

    /* Modifiers */

    modifier isActive() {
        require(_active == true, "Tru3Pay: contract is not active");
        _;
    }

    modifier onlyJobOwners(string memory id) {
        address[] memory owners = jobs[id].options.owners;
        require(owners.length > 0, "Tru3Pay: no owners to check");
        bool ownerIdentified = false;
        for (uint i = 0; i < owners.length; i++) {
            if(owners[i] == msg.sender) ownerIdentified = true;
        }
        require(ownerIdentified, "Tru3Pay: caller was not an owner");
        _;
    }

    modifier jobIsEmpty(string memory id) {
        require(jobs[id].options.owners.length ==  0, "Job already exists");
        _;
    }

    modifier jobExists(string memory id) {
        require(jobs[id].options.owners.length >  0, "Job does not exist");
        _;
    }

    modifier jobOpen(string memory id) {
        require(jobs[id].options.open == true, "Job is not open");
        _;
    }

    /* Events */

    event Payment(address indexed _from, string indexed _id, uint _value, uint _fee);
    event Distribution(string indexed _id, uint _value, address[] _payees, uint16[] _shares);
    event ShareDistribution(address indexed _from, uint _value, address[] _payees, uint16[] _shares);
    event ExactDistribution(address indexed _from, uint _value, address[] _payees, uint256[] _amounts);
    event Refund(string indexed _id, address indexed _from, address indexed _to, uint _value, uint _fee);

    /* Construction */

    constructor() {}

    /* Job Management */

    function createJob(string memory id, JobOptions memory options) external isActive jobIsEmpty(id) {
        _assignJob(id, options);
        _addToListingIndex(id);
    }

    function updateJob(string memory id, JobOptions memory options) external isActive onlyJobOwners(id) {
       _assignJob(id, options);
    }

    function closeJob(string memory id) external isActive onlyJobOwners(id) {
        _setJobState(id, false);
    }

    function openJob(string memory id) external isActive onlyJobOwners(id) {
        _setJobState(id, true);
    }

    function _assignJob(string memory id, JobOptions memory options) internal {
        require(options.owners.length > 0, "Must have owners");
        if(jobs[id].options.owners.length == 0) jobs[id] = Tru3Job(id, 0, 0, 0, options);
        else jobs[id].options = options;
    }

    function _setJobState(string memory id, bool open) internal {
        jobs[id].options.open = open;
    }

    /* Payable */

    function pay(string memory id) external payable nonReentrant isActive jobExists(id) jobOpen(id) {
        require(msg.value > 0, "No value sent in transaction.");
        uint fee = _processFee(msg.value);
        uint payment = (msg.value - fee);
        jobs[id].paid += payment;
        emit Payment(msg.sender, id, payment, fee);
    }

    function refund(string memory id, address refundee) external payable nonReentrant isActive onlyJobOwners(id) jobOpen(id) {
        require(msg.value > 0, "No value sent in transaction.");
        uint fee = _processFee(msg.value);
        uint refundValue = (msg.value - fee);
        (bool sent,) = payable(refundee).call{value : refundValue}("");
        require(sent, "Failed to distribute refund to refundee.");
        emit Refund(id, msg.sender, refundee, refundValue, fee);
        jobs[id].refunded += refundValue;
    }

    function _processFee(uint payableValue) private returns(uint) {
        uint fee = (_fee * payableValue) / _shareDenominator;
        (bool sent,) = payable(_tru3mint).call{value : fee}("");
        require(sent, "Failed to distribute fee to Tru3Mint.");
        return fee;
    }

    /* Distribution */

    function distribute(string memory id, address[] memory payees, uint16[] memory shares) external nonReentrant isActive onlyJobOwners(id) jobOpen(id)  {
        _distribute(id, payees, shares);
    }

    function _distribute(string memory id, address[] memory payees, uint16[] memory shares) internal {
        uint toPay = jobs[id].paid - jobs[id].distributed; 
        require(toPay > 0, "No funds to distribute for job.");
        
        require(payees.length == shares.length, "Payees and share lengths do not match.");
        uint16 totalShares = 0;
        for (uint i = 0; i < shares.length; i++) {
            totalShares += shares[i];
        }
        require(totalShares == _shareDenominator, "Shares do not add up to 100%");

        for (uint i=0; i < payees.length; i++) {
            uint16 share = shares[i];
            address payee = payees[i];
            if(share == 0) continue;
            uint shareValue = (share * toPay) / _shareDenominator;
            (bool sent,) = payable(payee).call{value : shareValue}("");
            require(sent, "Failed to distribute to payee.");
        }

        jobs[id].distributed += toPay;
        emit Distribution(id, toPay, payees, shares);
    }

    /* Jobless */

    function payShares(address[] memory payees, uint16[] memory shares) payable external nonReentrant isActive {
        require(msg.value > 0, "No funds to distribute");
        require(payees.length > 0, "No payees to distribute to.");
        require(payees.length == shares.length, "Payees and share lengths do not match.");
        uint16 totalShares = 0;
        for (uint i = 0; i < shares.length; i++) { totalShares += shares[i]; }
        require(totalShares == _shareDenominator, "Shares do not add up to 100%");

        uint fee = _processFee(msg.value);
        uint toPay = msg.value - fee;
        
        for (uint i=0; i < payees.length; i++) {
            uint16 share = shares[i];
            address payee = payees[i];
            if(share == 0) continue;
            uint shareValue = (share * toPay) / _shareDenominator;
            (bool sent,) = payable(payee).call{value : shareValue}("");
            require(sent, "Failed to distribute to payee.");
        }

        emit ShareDistribution(msg.sender, toPay, payees, shares);
    }

    function payExact(address[] memory payees, uint256[] memory amounts) payable external nonReentrant isActive {
        require(msg.value > 0, "No funds to distribute");
        require(payees.length > 0, "No payees to distribute to.");
        require(payees.length == amounts.length, "Payees and amount lengths do not match.");
        uint256 total = 0;
        for (uint i = 0; i < amounts.length; i++) { total += amounts[i]; }
        require(total == msg.value, "Amounts do not add up to total paid");

        uint fee = _processFee(msg.value);
        uint toPay = msg.value - fee;
        
        for (uint i=0; i < payees.length; i++) {
            uint256 amount = amounts[i];
            address payee = payees[i];
            if(amount == 0) continue;
            (bool sent,) = payable(payee).call{value : amount}("");
            require(sent, "Failed to distribute to payee.");
        }

        emit ExactDistribution(msg.sender, toPay, payees, amounts);
    }

    /* Index */

    function _addToListingIndex(string memory id) private {
        _jobIndex.push(id);
    }
    
    function _queryJobsByWallet(address wallet) private view returns(Tru3Job[] memory) {
        uint count = 0;
        for (uint i = 0; i < _jobIndex.length; i++) {
            Tru3Job memory job = getJob(_jobIndex[i]);
            if(Array.includesAddress(job.options.owners, wallet)) { count++; }
        }

        Tru3Job[] memory foundJobs = new Tru3Job[](count);
        uint ci = 0;
        for (uint i = 0; i < _jobIndex.length; i++) {
            Tru3Job memory job = getJob(_jobIndex[i]);
            if(Array.includesAddress(job.options.owners, wallet)) { foundJobs[ci] = job; ci++; }
        }
        return foundJobs;
    }

    function _queryJobsByIds(string[] memory ids) private view returns(Tru3Job[] memory) {
        uint count = 0;
        for (uint i = 0; i < _jobIndex.length; i++) {
            Tru3Job memory job = getJob(_jobIndex[i]);
            if(Array.includesString(ids, job.id)) { count++; }
        }

        Tru3Job[] memory foundJobs = new Tru3Job[](count);
        uint ci = 0;
        for (uint i = 0; i < _jobIndex.length; i++) {
            Tru3Job memory job = getJob(_jobIndex[i]);
            if(Array.includesString(ids, job.id)) { foundJobs[ci] = job; ci++; }
        }
        return foundJobs;
    }

    /* Getters/Search */

    function getFee() public view returns(uint16) {
        return _fee;
    }

    function getJob(string memory id) public view returns(Tru3Job memory) {
        return jobs[id];
    }

    function searchJobsByIds(string[] memory ids) public view returns(Tru3Job[] memory) {
        return _queryJobsByIds(ids);
    }

    function searchJobsByAddress(address wallet) external view returns(Tru3Job[] memory) {
        return _queryJobsByWallet(wallet);
    }

    /* Tru3Mint */

    function setTru3Mint(address tru3Mint) external onlyOwner {
        _tru3mint = tru3Mint;
    }

    function setActive(bool active) external onlyOwner {
        _active = active;
    }

    function refundOverride(string memory id, uint256 amount) external onlyOwner nonReentrant jobExists(id) {
        uint toPay = jobs[id].paid - jobs[id].distributed; 
        require(toPay > 0, "Job does not have any funds payable");
        if(amount > 0) require(toPay >= amount, "Job does not have enough funds payable");
        uint value = amount > 0 ? amount : toPay;
        (bool sent,) = payable(_tru3mint).call{value : value}("");
        require(sent, "Failed to refund listing to tru3mint");
        jobs[id].paid -= value;
    }

    function listingOverride(string memory id, uint256 amount) external onlyOwner nonReentrant jobExists(id) {
        uint toPay = jobs[id].paid - jobs[id].distributed; 
        require(toPay > 0, "Job does not have any funds payable");
        if(amount > 0) require(toPay >= amount, "Job does not have enough funds payable");
        uint value = amount > 0 ? amount : toPay;
        (bool sent,) = payable(_tru3mint).call{value : value}("");
        require(sent, "Failed to override listing to tru3mint");
    }

    
}