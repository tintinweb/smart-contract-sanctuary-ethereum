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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

error DefiContribute__NoAdminFound();
error DefiContribute__NotEligibleToDoneeRequest();
error DefiContribute__NotDonee();
error DefiContribute__NotInPendingStatus();
error DefiContribute__NotAcceptedAsDonee();
error DefiContribute__NotTheDonee();
error DefiContribute__NotElegibleDueYourRole();
error DefiContribute__NotEligibleToRemoval();
error DefiContribute__NotEligibleToWithdraw();

contract DefiContribute is Ownable {
    enum doneeRequestStatus {
        Rejected,
        Pending,
        Accepted,
        Canceled
    }

    struct Donee {
    string cause;
    uint256 id;
    uint256 proceeds;
    address payable wallet;
    string message;    
}

    mapping (address => bool) public admin;
    mapping (address => bool) public toNewDonee;
    mapping (address => doneeRequestStatus) public doneeToStatus;
    mapping (address => uint8) public addressToRequestsSent;
    mapping (address => uint256) public doneeCandidateToFreezeTime;
    mapping (uint256 => Donee) public idToDonee;
    mapping (address => uint256) addressToDoneeId;
    mapping (uint256 => uint256) public doneeToWithdrawalFreeze;
    mapping (uint256 => uint8) public idToRedFlags;

    uint256 public doneesId = 0;
    uint256 public randomDonationPool;

    event NewAdmin(address indexed admin);
    event AdminRevoke(address indexed admin);
    event NewDoneeRequest(address indexed donee, string message);
    event DoneeRequestCanceled(address indexed donee);
    event ApprovedDonee(address indexed donee);
    event RejectedDonee(address indexed donee);
    event NewDonee(string cause, uint256 indexed doneeId, address indexed donee,  string message);
    event EliminatedDonee(string cause, uint256 indexed doneeId, address indexed donee);
    event Donation(address indexed to, address indexed from, uint indexed amount);
    event RedFlag(string cause, uint256 indexed doneeId, address donee, address indexed admin);
    event ReadyToRemove(string cause, uint256 indexed id, address indexed wallet);
    event SummedToThePool(uint256 indexed amount);
    event Withdrawal(uint256 indexed doneeId, address indexed donee,  uint256 indexed proceeds);

    modifier onlyAdmin() {
        if (admin[msg.sender] == true) {
            _;
        } else {
            revert DefiContribute__NoAdminFound();
        }
    }

    modifier onlyAcceptedDonee() {
        if (doneeToStatus[msg.sender] == doneeRequestStatus(2)) {
            _;
        } else {
            revert DefiContribute__NotAcceptedAsDonee();
        }
    }

    modifier onlyDonee() {
        if (idToDonee[addressToDoneeId[msg.sender]].wallet == msg.sender ) {
            _;
        } else {
            revert DefiContribute__NotDonee();
        }
    }

    modifier notRulers() {
        if ((owner() == msg.sender) || admin[msg.sender] == true) {
            revert DefiContribute__NotElegibleDueYourRole();
        }
        _;
    }

    modifier doneeRemovalRequirements(uint256 _id, address _wallet) {
        if (_id <= doneesId && _wallet == idToDonee[_id].wallet && idToRedFlags[_id] >= 3) {
            _;
        } else {
            revert DefiContribute__NotEligibleToRemoval();
        }
    }

    constructor() Ownable() {

    }


    function addAdmin(address _newAdmin) public onlyOwner() {
        admin[_newAdmin] = true;
        emit NewAdmin(_newAdmin);
    }

    function revokeAdmin (address _admin) public onlyOwner() {
        if (admin[_admin] == true) {
            admin[_admin] = false;
            emit AdminRevoke(_admin);
        } else {
            revert DefiContribute__NoAdminFound();
        }
    }

    /**
     * @notice Sends a petition to be confirmed as donee, first needs to be accepted and then finished by each donee in case.
     * It is verified that the address has not send more than 3 attempts and that if it was freezed, the time has already passed...
     */
    function doneePetition(string memory _message) public notRulers() returns (bool success) {
        if (addressToRequestsSent[msg.sender] < 3 && doneeCandidateToFreezeTime[msg.sender] <= block.timestamp) {
            addressToRequestsSent[msg.sender]++;
            doneeToStatus[msg.sender] = doneeRequestStatus(1);
            emit NewDoneeRequest(msg.sender, _message);
            return true;
        } else {
            revert DefiContribute__NotEligibleToDoneeRequest();
        }
    }

    /**
     * @notice Cancell the donee petition but does not decrease the <addressToRequestSent> for the address, also freeze the address to be able to apply again to donee for a while.
     */
    function cancelDoneePetition() public {
        if (doneeToStatus[msg.sender] == doneeRequestStatus.Pending) {
            doneeCandidateToFreezeTime[msg.sender] = block.timestamp + 4 weeks;
            doneeToStatus[msg.sender] = doneeRequestStatus(3);
            emit DoneeRequestCanceled(msg.sender);
        } else {
            revert DefiContribute__NotInPendingStatus();
        }
    }

    /**
     * @notice Approves donee to be able to finish the process to make it's profile 
     */
    function approveDonee(address payable _donee) public onlyAdmin() {
        if (doneeToStatus[_donee] == doneeRequestStatus(1)) {
            doneeToStatus[_donee] = doneeRequestStatus(2);
            emit ApprovedDonee(_donee);
        } else {
            revert DefiContribute__NotTheDonee();
        }
    }

    function rejectDonee(address payable _donee) public onlyAdmin() {
        if (doneeToStatus[_donee] == doneeRequestStatus(1)) {
            doneeCandidateToFreezeTime[_donee] = block.timestamp + 12 weeks;
            doneeToStatus[_donee] = doneeRequestStatus(0);
            emit RejectedDonee(_donee);
        } else {
            revert DefiContribute__NotInPendingStatus();
        }
    }

    function becomeDonee(string memory _cause, string memory _message) public onlyAcceptedDonee() {
        idToDonee[doneesId] = Donee(_cause, doneesId, 0, payable(msg.sender), _message);
        doneeToWithdrawalFreeze[doneesId] = block.timestamp + 4 weeks;
        emit NewDonee(_cause, doneesId, msg.sender, _message);
        doneesId++;
    }

    /**
     * @notice Admins can add a red flag to a donee for the sake of setting them to removal by admins for bad behaviour and giving
     * them time to withdraw funds
     */
    function addRedFlag(uint256 _doneeId, address _wallet) public onlyAdmin() {
        if (_doneeId <= doneesId && idToDonee[_doneeId]. wallet == _wallet) {
            idToRedFlags[_doneeId]++;
            emit RedFlag(idToDonee[_doneeId].cause, _doneeId, _wallet, msg.sender);
        } else {
            revert DefiContribute__NotDonee();
        }
    }

    /**
     * @notice Admins can only remove a donee after 3 red flags
     */
    function removeDonee(uint256 _doneeId, address payable _wallet) public onlyAdmin() doneeRemovalRequirements(_doneeId, _wallet) {
        string memory cause = idToDonee[_doneeId].cause;
        address wallet = idToDonee[_doneeId].wallet;
        uint256 proceeds = idToDonee[_doneeId].proceeds;
        delete idToDonee[_doneeId];
        if (proceeds > 0) {
            randomDonationPool += proceeds;
            emit SummedToThePool(proceeds);
        }
        emit EliminatedDonee(cause, _doneeId, wallet);
    }

    function donate(uint256 _doneeId, address payable _wallet) public payable {
        if ((idToDonee[_doneeId].wallet != 0x0000000000000000000000000000000000000000) && (idToDonee[_doneeId].wallet == _wallet)) {
            idToDonee[_doneeId].proceeds += msg.value;
            emit Donation(_wallet, msg.sender, msg.value);
        } else {
            revert DefiContribute__NotTheDonee();
        }
    }

    function withdraw() public onlyDonee() {
        if (doneeToWithdrawalFreeze[addressToDoneeId[msg.sender]] <= block.timestamp) {
            uint256 proceeds = idToDonee[addressToDoneeId[msg.sender]].proceeds;
            idToDonee[addressToDoneeId[msg.sender]].proceeds = 0;
            (bool success, ) = msg.sender.call{value: proceeds}("");
            require (success, "Could not withdraw proceeds...");
            emit Withdrawal(addressToDoneeId[msg.sender], msg.sender, proceeds);
        } else {
            revert DefiContribute__NotEligibleToWithdraw();
        }
    }

}