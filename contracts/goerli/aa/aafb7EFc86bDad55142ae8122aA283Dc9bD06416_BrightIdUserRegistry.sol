// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

import './IUserRegistry.sol';
import './BrightIdSponsor.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract BrightIdUserRegistry is Ownable, IUserRegistry {
    string private constant ERROR_NEWER_VERIFICATION = 'NEWER VERIFICATION REGISTERED BEFORE';
    string private constant ERROR_NOT_AUTHORIZED = 'NOT AUTHORIZED';
    string private constant ERROR_INVALID_VERIFIER = 'INVALID VERIFIER';
    string private constant ERROR_INVALID_CONTEXT = 'INVALID CONTEXT';
    string private constant ERROR_INVALID_SPONSOR = 'INVALID SPONSOR';
    string private constant ERROR_INVALID_REGISTRATION_PERIOD = 'INVALID REGISTRATION PERIOD';
    string private constant ERROR_EXPIRED_VERIFICATION = 'EXPIRED VERIFICATION';
    string private constant ERROR_REGISTRATION_CLOSED = 'REGISTRATION CLOSED';

    bytes32 public context;
    address public verifier;
    BrightIdSponsor public brightIdSponsor;

    // Only register a verified user during this period
    uint256 public registrationStartTime;
    uint256 public registrationDeadline;

    struct Verification {
        uint256 time;
    }
    mapping(address => Verification) public verifications;

    event SetBrightIdSettings(bytes32 context, address verifier);

    event Registered(address indexed addr, uint256 timestamp);
    event RegistrationPeriodChanged(uint256 startTime, uint256 deadline);
    event SponsorChanged(address sponsor);

    /**
     * @param _context BrightID context used for verifying users
     * @param _verifier BrightID verifier address that signs BrightID verifications
     * @param _sponsor Contract address that emits BrightID sponsor event
     */
    constructor(bytes32 _context, address _verifier, address _sponsor) public {
        // ecrecover returns zero on error
        require(_verifier != address(0), ERROR_INVALID_VERIFIER);
        require(_sponsor != address(0), ERROR_INVALID_SPONSOR);

        context = _context;
        verifier = _verifier;
        brightIdSponsor = BrightIdSponsor(_sponsor);
    }

    /**
     * @notice Sponsor a BrightID user by context id
     * @param addr BrightID context id
     */
    function sponsor(address addr) public {
        brightIdSponsor.sponsor(addr);
    }

    /**
     * @notice Set BrightID settings
     * @param _context BrightID context used for verifying users
     * @param _verifier BrightID verifier address that signs BrightID verifications
     */
    function setSettings(bytes32 _context, address _verifier) external onlyOwner {
        // ecrecover returns zero on error
        require(_verifier != address(0), ERROR_INVALID_VERIFIER);

        context = _context;
        verifier = _verifier;
        emit SetBrightIdSettings(_context, _verifier);
    }

    /**
     * @notice Set BrightID sponsor
     * @param _sponsor Contract address that emits BrightID sponsor event
     */
    function setSponsor(address _sponsor) external onlyOwner {
        require(_sponsor != address(0), ERROR_INVALID_SPONSOR);

        brightIdSponsor = BrightIdSponsor(_sponsor);
        emit SponsorChanged(_sponsor);
    }

    /**
     * @notice Set the registration period for verified users
     * @param _startTime Registration start time
     * @param _deadline Registration deadline
     */
    function setRegistrationPeriod(uint256 _startTime, uint256 _deadline) external onlyOwner {
        require(_startTime <= _deadline, ERROR_INVALID_REGISTRATION_PERIOD);

        registrationStartTime = _startTime;
        registrationDeadline = _deadline;
        emit RegistrationPeriodChanged(_startTime, _deadline);
    }

    /**
     * @notice Check a user is verified or not
     * @param _user BrightID context id used for verifying users
     */
    function isVerifiedUser(address _user)
      override
      external
      view
      returns (bool)
    {
        Verification memory verification = verifications[_user];
        return canRegister(verification.time);
    }

    /**
     * @notice check if the registry is open for registration
     * @param _timestamp timestamp
     */
    function canRegister(uint256 _timestamp)
      public
      view
      returns (bool)
    {
        return _timestamp > 0
            && _timestamp >= registrationStartTime 
            && _timestamp < registrationDeadline;
    }

    /**
     * @notice Register a user by BrightID verification
     * @param _context The context used in the users verification
     * @param _addr The address used by this user in this context
     * @param _verificationHash sha256 of the verification expression
     * @param _timestamp The BrightID node's verification timestamp
     * @param _v Component of signature
     * @param _r Component of signature
     * @param _s Component of signature
     */
    function register(
        bytes32 _context,
        address _addr,
        bytes32 _verificationHash,
        uint _timestamp,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(context == _context, ERROR_INVALID_CONTEXT);
        require(verifications[_addr].time < _timestamp, ERROR_NEWER_VERIFICATION);
        require(canRegister(block.timestamp), ERROR_REGISTRATION_CLOSED);
        require(canRegister(_timestamp), ERROR_EXPIRED_VERIFICATION);

        bytes32 message = keccak256(abi.encodePacked(_context, _addr, _verificationHash, _timestamp));
        address signer = ecrecover(message, _v, _r, _s);
        require(verifier == signer, ERROR_NOT_AUTHORIZED);

        verifications[_addr].time = _timestamp;

        emit Registered(_addr, _timestamp);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

/**
 * @dev Interface of the registry of verified users.
 */
interface IUserRegistry {

  function isVerifiedUser(address _user) external view returns (bool);

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

contract BrightIdSponsor {
    event Sponsor(address indexed addr);

    /**
     * @dev sponsor a BrightId user by emitting an event
     * that a BrightId node is listening for
     */
    function sponsor(address addr) public {
        emit Sponsor(addr);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}