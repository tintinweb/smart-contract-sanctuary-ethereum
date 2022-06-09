/**
 *Submitted for verification at Etherscan.io on 2022-06-08
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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: nilli.sol


// We will be using Solidity version 0.8.14
pragma solidity 0.8.14;


contract nilli is Ownable {

    // State variables
    // Athlete -> School -> Contributor -> Amount
    mapping (string => mapping(string => mapping(address => uint))) public endowments;
    // Athlete -> School -> State
    // States => 5 = fundraising/default; 2 = successful/payout to athlete; 1 = expired/refund to contributors
    mapping (string => mapping(string => uint)) public endowment_state;
    // Athlete -> School -> Amt Raised
    mapping (string => mapping(string => uint)) public endowment_raise;
    // Athlete -> School -> Claimor (originally set to *empty*)
    mapping (string => mapping(string => address)) public claimor;
    // Athlete -> Amt Raised
    mapping (string => uint) public athlete_raise;
    // School -> Amt Raised
    mapping (string => uint) public school_raise;

    // Event that will be emitted whenever a new project is started
    event ProjectStarted(
        address projectStarter,
        string projectAthlete,
        string school
    );
    // Event that will be emitted whenever funding will be received
    event FundingReceived(address contributor, string athlete2contrib, string school2contrib, uint amount, uint currentTotal);
    // Event that will be emitted whenever the athlete has received the funds
    event AthletePaid(address recipient);
    // Event that will be emitted whenever refund has occurred
    event RefundPaid(address refundee, uint refundAmt, string athlete_refund, string school_refund);
    // Event that will be emitted whenever state changes
    event StateChange(string athleteChange, string schoolChange, uint newState);
    // Event that will be emitted whenever the athlete + school has been made claimable
    event MadeClaimable(string athlete, string school, uint amtClaimable);
    

    /** @dev Function to start a new project.
      */
    function startProject(
        string calldata athlete,
        string calldata school
    ) external onlyOwner {
        endowments[athlete][school][msg.sender] = 0;
        endowment_state[athlete][school] = 5;
        endowment_raise[athlete][school] = 0;
        athlete_raise[athlete] = 0;
        school_raise[school] = 0;
        emit ProjectStarted(msg.sender, athlete, school);
    }

    /** @dev Function to fund a certain project.
    */
    function contribute(string calldata athlete, string calldata school) external payable {
        require(endowment_state[athlete][school] == 5);
        uint256 contribAmt = 0;
        // uint256 feeAmt = 0;
        // feeAmt = msg.value.div(serviceFee);
        contribAmt = msg.value;
        endowments[athlete][school][msg.sender] += contribAmt;
        endowment_raise[athlete][school] += contribAmt;
        athlete_raise[athlete] += contribAmt;
        school_raise[school] += contribAmt;
        emit FundingReceived(msg.sender, athlete, school, contribAmt, endowment_raise[athlete][school]);
    }

    /** @dev Function expireEndowment force endowment to expire.
      */
    function expireEndowment(string calldata athlete, string calldata school) public onlyOwner returns (bool) {
        require(endowment_state[athlete][school] == 5);
        endowment_state[athlete][school] = 1;
        emit StateChange(athlete, school, 1);
        return true;
    }

    /** @dev Function successfulEndowment force endowment to success.
      */
    function successfulEndowment(string calldata athlete, string calldata school) public onlyOwner returns (bool) {
        require(endowment_state[athlete][school] == 5);
        endowment_state[athlete][school] = 2;
        emit StateChange(athlete, school, 2);
        return true;
    }

    /** @dev Function to give make successful endowment claimable by athlete.
    */
    function makeClaimable(string calldata athlete, string calldata school, address claimor_addr) public onlyOwner returns (bool) {
        require(endowment_state[athlete][school] == 2);
        claimor[athlete][school] = claimor_addr;
        emit MadeClaimable(athlete, school, endowment_raise[athlete][school]);
        return true;
    }

    /** @dev Function allows payout to endowment athlete.
    */
    function payOut(string calldata athlete, string calldata school) public returns (bool) {
        require(endowment_state[athlete][school] == 2);
        require(msg.sender == claimor[athlete][school]);
        uint256 payoutAmt = 0;
        payoutAmt = endowment_raise[athlete][school];
        endowment_raise[athlete][school] = 0;

        if (payable(msg.sender).send(payoutAmt)) {
            emit AthletePaid(msg.sender);
            return true;
        } else {
            endowment_state[athlete][school] = 2;
        }
        return false;
    }

    /** @dev Function getRefund to retrieve donated amount when a project expires.
      */
    function getRefund(string calldata athlete, string calldata school) public returns (bool) {
        require(endowment_state[athlete][school] == 1);
        require(endowments[athlete][school][msg.sender] > 0);
        uint256 payoutAmt = 0;
        uint amountToRefund = endowments[athlete][school][msg.sender];
        payoutAmt = amountToRefund;
        endowments[athlete][school][msg.sender] = 0;

        if (!payable(msg.sender).send(payoutAmt)) {
            endowments[athlete][school][msg.sender] = payoutAmt;
            return false;
        } else {
            emit RefundPaid(msg.sender, payoutAmt, athlete, school);
        }
        return true;
    }

}