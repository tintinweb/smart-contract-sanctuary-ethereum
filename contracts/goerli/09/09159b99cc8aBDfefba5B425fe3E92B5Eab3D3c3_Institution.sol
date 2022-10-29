// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./IInstitution.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @dev Revert transaction for non-existing programID
error InvalidProgram();

/// @dev Revert transaction for non-existing sessionId
error InvalidSession();

/// @dev Revert transaction If annonymous wallet try to verify certificate
error InvalidVerifier();

/// @dev Revert transaction for non-existing applicationId
error InvalidApplicationId();

/// @dev Revert transaction for zero as input value
error ValueCanNotBeZero();

/// @dev Revert transaction for zero address or the address is this current smart contract
error InvalidAddress();

/// @dev Revert transaction for zero address or the address is this current smart contract
error InvalidIssuer();

/// @dev Revert transaction for duplicate varification
error AlreadyVerified();

contract Institution is IInstitution, Ownable {
    /// @dev Revert transaction for zero address or the address is this current smart contract
    /// @param _address wallet address to verify
    modifier validAddress(address _address) {
        if (_address == address(0) || _address == address(this)) {
            revert InvalidAddress();
        }
        _;
    }

    /// @dev Revert transaction for zero as input value
    /// @param amount ammount to verify
    modifier notZero(uint256 amount) {
        if (amount == 0) {
            revert ValueCanNotBeZero();
        }
        _;
    }

    /// @dev Revert transaction If annonymous wallet try to verify certificate
    /// @param _address wallet address to verify
    modifier validVarifier(address _address) {
        if (!institutionVerifiers[_address]) {
            revert InvalidVerifier();
        }
        _;
    }

    /// @dev Revert transaction If annonymous wallet try to verify certificate
    /// @param _address wallet address to verify
    modifier onlyIssuer(address _address) {
        if (_address != controllerContractAddress) {
            revert InvalidVerifier();
        }
        _;
    }

    /// @dev Certificate data structure to store on chain
    struct Certificate {
        string name;
        uint256 roll;
        uint256 registrationNo;
        uint256 sessionId;
        uint256 programId;
        string ipfsUrl;
        address owner;
    }

    /// @dev Application data structure to store on chain
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

    /// @dev Program data structure to store on chain
    struct Program {
        string name;
        uint256 duration;
    }

    /// @dev Session data structure to store on chain
    struct Session {
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    /// @dev Map for keeping the verifier for this institution
    mapping(address => bool) public institutionVerifiers;

    address payable public institutionWallet;
    address payable public withdrawalWallet;

    address public controllerContractAddress;

    uint256 public constant APPLICATION_FEE = 0.0006 ether;

    uint256 public totalProgram = 0;
    uint256 public totalSession = 0;
    uint256 public totalCertificate = 0;
    uint256 public totalApplication = 0;

    mapping(uint256 => Session) public sessions;

    mapping(uint256 => Application) public applications;
    mapping(uint256 => Certificate) public certificates;

    mapping(uint256 => Program) public programs;

    event ApplyForCertificate(
        uint256 _id,
        string _name,
        uint256 _roll,
        uint256 _registrationNo,
        uint256 _sessionId,
        uint256 _programId,
        string _ipfsUrl,
        address _owner
    );

    event VerifyCertificate(
        uint256 _certificateId,
        uint256 _applicationId,
        address _verifier
    );

    constructor(
        address _issuerContractAddress,
        address payable _institutionWallet
    ) {
        institutionWallet = payable(_institutionWallet);
        controllerContractAddress = _issuerContractAddress;
        withdrawalWallet = payable(msg.sender);
    }

    /// @notice Transfer balance on this contract to withdrawal address
    function withdrawETH() external onlyOwner {
        withdrawalWallet.transfer(address(this).balance);
    }

    /// @notice Set wallet address that can withdraw the balance
    /// @dev Only owner of the contract can execute this function.
    ///      The address should not be 0x0 or contract address
    /// @param _wallet Any valid address
    function setWithdrawWallet(address _wallet)
        external
        onlyOwner
        validAddress(_wallet)
    {
        withdrawalWallet = payable(_wallet);
    }

    /// @notice Store application for certificate
    /// @dev Anyone can apply paying the required gas price
    /// @param _name Any valid address
    /// @param _roll Any valid address
    /// @param _registrationNo student registration no
    /// @param _sessionId Admission sessionId
    /// @param _programId program ID
    /// @param _ipfsUrl Certificate file URL
    function applyForCertificate(
        string memory _name,
        uint256 _roll,
        uint256 _registrationNo,
        uint256 _sessionId,
        uint256 _programId,
        string memory _ipfsUrl
    ) external payable {
        if (_programId < 1 || _programId > totalProgram) {
            revert InvalidProgram();
        }

        if (_sessionId < 1 || _sessionId > totalSession) {
            revert InvalidSession();
        }

        require(
            msg.value == APPLICATION_FEE,
            "insufficient or excess ETH provided."
        );

        unchecked {
            totalApplication++;
        }

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
        emit ApplyForCertificate(
            totalApplication,
            _name,
            _roll,
            _registrationNo,
            _sessionId,
            _programId,
            _ipfsUrl,
            msg.sender
        );
    }

    /// @notice Verify perticular application as certificate
    /// @dev Only whitelisted varifier will able to verify
    /// @param _applicationId Application Id to verify
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
        unchecked {
            totalCertificate++;
        }
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

        emit VerifyCertificate(totalCertificate, _applicationId, msg.sender);
    }

    /// @notice add new session for institute
    /// @dev Only whitelisted issuer will able to add Sessions
    /// @param _startTimestamp session start timestamp
    /// @param _endTimestamp session end timestamp
    function addSessions(uint256 _startTimestamp, uint256 _endTimestamp)
        external
        onlyIssuer(msg.sender)
    {
        if (_startTimestamp >= _endTimestamp) {
            revert InvalidSession();
        }
        unchecked {
            totalSession++;
        }

        sessions[totalSession] = Session(_startTimestamp, _endTimestamp);
    }

    /// @notice add new program for the institute
    /// @dev Only whitelisted issuer will able to add Sessions
    /// @param _name program name
    /// @param _duration program duration timestamp
    function addProgram(string memory _name, uint256 _duration)
        external
        onlyIssuer(msg.sender)
        notZero(_duration)
    {
        unchecked {
            totalProgram++;
        }

        programs[totalProgram] = Program(_name, _duration);
    }

    /// @notice whitelist new wallet as verifier
    /// @dev Only contract owner can add verifier
    /// @param _verifier varifier wallet address
    function addVerifier(address _verifier)
        external
        validAddress(_verifier)
        onlyIssuer(msg.sender)
    {
        institutionVerifiers[_verifier] = true;
    }

    /// @notice remove varifier from whitelist
    /// @dev Only contract owner can add verifier
    /// @param _verifier varifier wallet address
    function removeVerifier(address _verifier)
        external
        validAddress(_verifier)
        onlyIssuer(msg.sender)
    {
        institutionVerifiers[_verifier] = false;
    }

    /// @notice whitelist issuer address
    /// @dev Only contract owner can add verifier
    /// @param _address issuer address
    function resetIssuerContractAddress(address _address)
        external
        onlyOwner
        validAddress(_address)
    {
        controllerContractAddress = _address;
    }

    /// @notice remove varifier from whitelist
    /// @dev Only contract owner can add verifier
    /// @param _address issuer address
    function resetInstitutionWallet(address _address)
        external
        onlyOwner
        validAddress(_address)
    {
        institutionWallet = payable(_address);
    }

    /// @notice readonly method for getting application information information
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

    /// @notice readonly method for getting certificate information
    /// @param _address address to query certificate
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
    ) external payable;

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