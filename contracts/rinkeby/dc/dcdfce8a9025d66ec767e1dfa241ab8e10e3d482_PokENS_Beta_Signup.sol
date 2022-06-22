/**
 *Submitted for verification at Etherscan.io on 2022-06-22
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

// File: contracts/pokENS/BetaSignup.sol



pragma solidity 0.8.14;


// <3 ho-oh

contract PokENS_Beta_Signup is Ownable {

    // Starting $POKENS reward = 69,420
    // Bonus $POKENS reward lowers by 5% for each new beta tester added until reward reaches < 1
    bool public betaOpen = false;
    uint256 public currentBonusReward = 69420;
    uint256 masterKey = 0;

    struct BetaTester {
        string favMon;          // Favorite Pokémon
        uint reward;            // Bonus reward for tester
        bool active;            // Is tester registered?
        bool participant;       // Did tester participate?
        uint256 rounds;         // How many rounds?
    }

    mapping(address => BetaTester) public betaTester;       // Can check the status of a specific tester here
    address[] public betaTesterIds;                         // Can check the addresses of testers here

    // Can register for beta until full, then registering becomes locked
    function registerForBeta(string memory favMon) public {
        require(currentBonusReward >= 1, "Sorry, this round of beta testing is full");
        require(betaTester[msg.sender].active != true, "Tester already registered");
        betaTesterIds.push(msg.sender);
        BetaTester storage newTester = betaTester[msg.sender];
        newTester.active = true;
        newTester.participant = false;
        newTester.rounds = 0;
        newTester.favMon = favMon;
        newTester.reward = currentBonusReward;
        currentBonusReward = currentBonusReward - (currentBonusReward / 20);        
    }

    // Will get participant key from beta testing logins
    function addParticipant(uint256 participantKey) public {
        require(betaOpen == true, "Beta testing is not open");
        require(masterKey != 0 && masterKey == participantKey, "Keys do not match! ...I smell funny business.");
        require(betaTester[msg.sender].active == true, "Tester must be registered for beta");
        require(betaTester[msg.sender].participant != true, "Participation is already confirmed");
        BetaTester storage newTester = betaTester[msg.sender];
        newTester.participant = true;
        newTester.rounds++;
    }

    // See how many testers have signed up
    function getNumTesters() public view returns (uint256) {
        uint256 num = betaTesterIds.length;
        return num;
    }

    // Game master to set beta to open and master key for each round of beta.
    function setMasterKey(uint256 _masterKey, bool _openStatus) public onlyOwner {
        masterKey = _masterKey;
        betaOpen = _openStatus;
    }

}