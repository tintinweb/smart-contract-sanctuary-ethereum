/**
 *Submitted for verification at Etherscan.io on 2022-12-30
*/

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

// File: dKYC.sol


pragma solidity ^0.8.7;


contract dKYC is Ownable{
    // no need to use AccessControl since essentially the same functionality can be done using whitelisting as shown below

    // counter to record the number of users that have completed KYC
    uint256 private counter = 0;

    // mapping to denote addresses that can call the function
    mapping(address => bool) private isWhitelisted;

    // mapping to access KYC data using 'int' identifiers
    mapping(uint256 => KycData) private d_identities;

    struct Tradeline{
        bytes32 accountNumber;
        uint256 amountPastDue;
        uint256 balanceAmount;
        bytes32 lastPaymentDate;
        bytes32 maxDelinquencyDate;
        bytes32 openDate;
        bytes32 openOrClosed;
        string subscriberName;
    }

    struct LoanInquiry{
        uint256 amount;
        string subscriberName;
        bytes32 terms;
        string typeOfInquiry;
    }

    struct CreditSummary{
        uint256 openCount;
        uint256 openPastDue;
        uint256 liabilityBankruptcyCount;
        uint256 inquiryCount;
    }

    struct Model{
        bytes32 typeOfScore;
        uint256 score;
        uint256 scorePercentile;
    }

    struct KycData {
        bytes32 refNumber;
        string name;
        uint256 ssn;
        Tradeline[] creditAccounts;
        LoanInquiry[] inquiries;
        CreditSummary derogatorySummary;
        Model[3] riskModelScores;
    }

    // event to denote completion of KYC
    event kycDone(address indexed, bytes32, uint256 indexed);

    // 1-level access control
    modifier onlyWhitelisted() {
        require(isWhitelisted[msg.sender], "Caller is not whitelisted!");
        _;
    }

    // function to create the KYC dataset for a single user
    function storeKycData(
        bytes32 refNumber,
        string calldata name,
        uint256 ssn,
        Tradeline[] calldata creditAccounts,
        LoanInquiry[] calldata inquiries,
        CreditSummary calldata derogatorySummary,
        Model[] calldata riskModelScores) external onlyWhitelisted returns (uint256) {

        KycData storage newKycDataset = d_identities[counter];

        newKycDataset.refNumber = refNumber;
        newKycDataset.name = name;
        newKycDataset.ssn = ssn;

        uint256 caLength = creditAccounts.length;
        uint256 iLength = inquiries.length;

        for (uint256 i = 0; i < caLength; i++) {
            newKycDataset.creditAccounts.push(creditAccounts[i]);
        }

        for (uint256 i = 0; i < iLength; i++) {
            newKycDataset.inquiries.push(inquiries[i]);
        }

        newKycDataset.derogatorySummary = derogatorySummary;

        for (uint256 i = 0; i < 3; i++) {
            newKycDataset.riskModelScores[i] = riskModelScores[i];
        }

        // emit event
        emit kycDone(msg.sender, "KYC COMPLETED", block.timestamp);

        counter++;
        return (counter - 1);
    }

    function whitelist(address whitelistAddress) external onlyOwner {
        isWhitelisted[whitelistAddress] = true;
    }

    function getIsWhitelisted(address caller) external view returns (bool) {
        return isWhitelisted[caller];
    }

    function getCounter() external view returns (uint256) {
        return counter;
    }
}