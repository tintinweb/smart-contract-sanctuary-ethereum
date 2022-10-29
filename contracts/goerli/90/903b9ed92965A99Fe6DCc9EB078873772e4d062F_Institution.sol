// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./IInstitution.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error InvalidProgram();
error InvalidSession();
error InvalidVerifier();
error InvalidApplicationId();
error ApplicationLimitExceeded();
error ValueCanNotBeZero();
error InvalidAddress();
error InvalidIssuer();
error AlreadyVerified();

contract Institution is IInstitution, Ownable {
    modifier validAddress(address _address) {
        if (_address == address(0) || _address == address(this)) {
            revert InvalidAddress();
        }
        _;
    }

    modifier notZero(uint256 amount) {
        if (amount == 0) {
            revert ValueCanNotBeZero();
        }
        _;
    }

    modifier validVarifier(address _address) {
        if (!institutionVerifiers[_address]) {
            revert InvalidVerifier();
        }
        _;
    }

    modifier onlyIssuer(address _address) {
        if (_address != controllerContractAddress) {
            revert InvalidVerifier();
        }
        _;
    }

    struct Certificate {
        string name;
        uint256 roll;
        uint256 registrationNo;
        uint256 sessionId;
        uint256 programId;
        string ipfsUrl;
        address owner;
    }

    struct Application {
        uint256 id;
        string name;
        uint256 roll;
        uint256 registrationNo;
        uint256 sessionId;
        uint256 programId;
        string ipfsUrl;
        address applicant;
        bool verified;
    }

    struct Program {
        string name;
        uint256 duration;
    }

    struct Session {
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    mapping(address => bool) public institutionVerifiers;

    address payable public institutionWallet;
    address public controllerContractAddress;

    uint256 public totalProgram = 0;
    uint256 public totalSession = 0;
    uint256 public totalCertificate = 0;
    uint256 public totalApplication = 0;

    uint256 public applicationperWallet = 10;

    mapping(uint256 => Session) public sessions;

    mapping(uint256 => Application) public applications;
    mapping(uint256 => Certificate) public certificates;

    mapping(uint256 => Program) public programs;

    mapping(address => uint256) public applicationPerWalletMapping;

    constructor(
        address _issuerContractAddress,
        address payable _institutionWallet
    ) {
        institutionWallet = payable(_institutionWallet);
        controllerContractAddress = _issuerContractAddress;
    }

    function applyForCertificate(
        string memory _name,
        uint256 _roll,
        uint256 _registrationNo,
        uint256 _sessionId,
        uint256 _programId,
        string memory _ipfsUrl
    ) external {
        if (_programId < 1 || _programId > totalProgram) {
            revert InvalidProgram();
        }

        if (_sessionId < 1 || _sessionId > totalSession) {
            revert InvalidSession();
        }

        if (applicationPerWalletMapping[msg.sender] == applicationperWallet) {
            revert ApplicationLimitExceeded();
        }

        applicationPerWalletMapping[msg.sender]++;
        totalApplication++;

        applications[totalApplication] = Application(
            totalApplication,
            _name,
            _roll,
            _registrationNo,
            _sessionId,
            _programId,
            _ipfsUrl,
            msg.sender,
            false
        );
    }

    function verifyCertificate(uint256 _applicationId)
        external
        validVarifier(msg.sender)
        notZero(_applicationId)
    {
        if (_applicationId < 1 || _applicationId > totalApplication) {
            revert InvalidApplicationId();
        }

        Application memory application = applications[_applicationId];

        if (application.verified == true) {
            revert AlreadyVerified();
        }

        totalCertificate++;
        applicationPerWalletMapping[application.applicant]--;
        applications[_applicationId].verified = true;
        certificates[totalCertificate] = Certificate(
            application.name,
            application.roll,
            application.registrationNo,
            application.sessionId,
            application.programId,
            application.ipfsUrl,
            application.applicant
        );
    }

    function addSessions(uint256 _startTimestamp, uint256 _endTimestamp)
        external
        onlyIssuer(msg.sender)
    {
        if (_startTimestamp >= _endTimestamp) {
            revert InvalidSession();
        }
        totalSession++;

        sessions[totalSession] = Session(_startTimestamp, _endTimestamp);
    }

    function addProgram(string memory _name, uint256 _duration)
        external
        onlyIssuer(msg.sender)
        notZero(_duration)
    {
        totalProgram++;

        programs[totalProgram] = Program(_name, _duration);
    }

    function addVerifier(address _verifier)
        external
        validAddress(_verifier)
        onlyIssuer(msg.sender)
    {
        institutionVerifiers[_verifier] = true;
    }

    function removeVerifier(address _verifier)
        external
        validAddress(_verifier)
        onlyIssuer(msg.sender)
    {
        institutionVerifiers[_verifier] = false;
    }

    function resetIssuerContractAddress(address _address)
        external
        onlyOwner
        validAddress(_address)
    {
        controllerContractAddress = _address;
    }

    function resetInstitutionWallet(address _address)
        external
        onlyOwner
        validAddress(_address)
    {
        institutionWallet = payable(_address);
    }

    function unverifiedApplications()
        public
        view
        returns (Application[] memory data)
    {
        Application[] memory tmp = new Application[](totalApplication);

        uint256 count = 0;
        for (uint256 i = 1; i <= totalApplication; i++) {
            Application memory application = applications[i];
            if (application.verified == false) {
                tmp[count] = application;
                count += 1;
            }
        }
        Application[] memory data = new Application[](count);
        for (uint256 i = 0; i < count; i++) {
            data[i] = tmp[i];
        }
        return data;
    }

    function ownerOfCertificates(address _address)
        public
        view
        returns (Certificate[] memory data)
    {
        Certificate[] memory tmp = new Certificate[](totalCertificate);

        uint256 count = 0;
        for (uint256 i = 1; i <= totalCertificate; i++) {
            Certificate memory certificate = certificates[i];
            if (certificate.owner == _address) {
                tmp[count] = certificate;
                count += 1;
            }
        }
        Certificate[] memory data = new Certificate[](count);
        for (uint256 i = 0; i < count; i++) {
            data[i] = tmp[i];
        }
        return data;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.15;

interface IInstitution {
    function addSessions(uint256 _startTimestamp, uint256 _endTimestamp)
        external;

    function addProgram(string memory _name, uint256 _duration) external;

    function addVerifier(address _verifier) external;

    function removeVerifier(address _verifier) external;

    function applyForCertificate(
        string memory _name,
        uint256 _roll,
        uint256 _registrationNo,
        uint256 _sessionId,
        uint256 _programId,
        string memory _ipfsUrl
    ) external;

    function verifyCertificate(uint256 _applicationId) external;

    function resetIssuerContractAddress(address _address) external;

    function resetInstitutionWallet(address _address) external;
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