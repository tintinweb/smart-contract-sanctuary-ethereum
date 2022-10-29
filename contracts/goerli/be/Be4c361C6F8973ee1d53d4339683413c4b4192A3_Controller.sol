// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IInstitution.sol";

error ValueCanNotBeZero();
error InvalidAddress();
error InvalidModerator();

contract Controller is Ownable {
    modifier validAddress(address _address) {
        if (_address == address(0) || _address == address(this)) {
            revert InvalidAddress();
        }
        _;
    }

    modifier validInstitutionAddress(address _address) {
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

    modifier validModerator(address _address) {
        if (!moderators[_address]) {
            revert InvalidModerator();
        }
        _;
    }

    struct InstitutionInfo {
        uint256 id;
        address contractAddres;
        string name;
    }

    IInstitution public institutionSc;
    uint256 public totalInstitution = 0;

    address payable public withdrawalWallet;

    mapping(address => bool) public moderators;

    mapping(uint256 => InstitutionInfo) public institutionInfos;

    constructor() {
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

    function addInstitution(address contractAddres, string memory name)
        external
        validModerator(msg.sender)
        validAddress(contractAddres)
    {
        unchecked {
            totalInstitution++;
        }
        institutionInfos[totalInstitution] = InstitutionInfo(
            totalInstitution,
            contractAddres,
            name
        );
    }

    function addSessions(
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        address _scAddress
    ) external validModerator(msg.sender) validAddress(_scAddress) {
        institutionSc = IInstitution(_scAddress);
        institutionSc.addSessions(_startTimestamp, _endTimestamp);
    }

    function addProgram(
        string memory _name,
        uint256 _duration,
        address _scAddress
    ) external validModerator(msg.sender) validAddress(_scAddress) {
        institutionSc = IInstitution(_scAddress);
        institutionSc.addProgram(_name, _duration);
    }

    function addVerifier(address _verifier, address _scAddress)
        external
        validModerator(msg.sender)
        validAddress(_scAddress)
    {
        institutionSc = IInstitution(_scAddress);
        institutionSc.addVerifier(_verifier);
    }

    function removeVerifier(address _verifier, address _scAddress)
        external
        validModerator(msg.sender)
        validAddress(_scAddress)
    {
        institutionSc = IInstitution(_scAddress);
        institutionSc.removeVerifier(_verifier);
    }

    function addModerator(address _moderator)
        external
        onlyOwner
        validAddress(_moderator)
    {
        moderators[_moderator] = true;
    }

    function removeModerator(address _moderator)
        external
        onlyOwner
        validAddress(_moderator)
    {
        moderators[_moderator] = false;
    }

    function getinstitutions()
        public
        view
        returns (InstitutionInfo[] memory datas)
    {
        InstitutionInfo[] memory datas = new InstitutionInfo[](
            totalInstitution
        );

        for (uint256 i = 0; i < totalInstitution; i++) {
            InstitutionInfo memory data = institutionInfos[i+1];
            datas[i] = data;
        }
        return datas;
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