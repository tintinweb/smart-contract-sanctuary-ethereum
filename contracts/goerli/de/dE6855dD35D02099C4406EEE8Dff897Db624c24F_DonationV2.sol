// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
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

contract DonationV2 is Ownable {

    uint256 public _totalProjectNumber;
    uint256 public _totalDonationNumber;
    mapping(address => bool) private _adminList;
    mapping(uint256 => string) public _projectList;
    mapping (uint256 => mapping (bytes32 => uint256)) public _donationList;

    struct DonationInfo {
        uint256 _donationID;
        string _donator;
        uint256 donationAmount;
    }

    event AdminChanged(address indexed admin, bool indexed status);
    event Donated(uint256 projectID, bytes32 donorEmail, uint256 donationAmount);
    event ProjectAdded(uint256 projectID, string indexed projectName);
    event ProjectUpdated(uint256 projectID, string indexed projectName);

    modifier onlyAdmin() {
        require(_adminList[msg.sender] == true, "Donation: Caller is not admin");
        _;
    }

    constructor() {
        _adminList[_msgSender()] = true;
    }

    /**
     * @dev Register Donation
     * 
     */
    function registerDonation(uint256 projectID, bytes32 donorEmail, uint256 donationAmount) external onlyAdmin {
        // Checking duplication
        if(_donationList[projectID][donorEmail] != 0) {
            revert("This donation has already been registered");
        }
        _donationList[projectID][donorEmail] = block.timestamp;
        emit Donated(projectID, donorEmail, donationAmount);
    }

    /**
     * @dev Get Donation
     * 
     */
    function getDonation(uint256 projectID, string memory donorEmail) external view returns (uint256) {
        bytes32 emailHash = keccak256(abi.encodePacked(donorEmail));
        return _donationList[projectID][emailHash];
    }

    /**
     * @dev Add project to _projectList
     */
    function addProject(string memory _projectName) external onlyAdmin {
        _totalProjectNumber++;
        _projectList[_totalProjectNumber] = _projectName;
        emit ProjectAdded(_totalProjectNumber, _projectName);
    }

    /**
     * @dev Update the projectName of the projectID.
     */
    function updateProject(uint256 projectID, string memory _projectName) external onlyAdmin {
        _projectList[projectID] = _projectName;
        emit ProjectUpdated(projectID, _projectName);
    }

    /**
     * @dev Add `_admin` to the _adminList.
     */
    function addAdmin(address _admin) external onlyOwner {
        _adminList[_admin] = true;
        emit AdminChanged(_admin, true);
    }

    /**
     * @dev Revoke `_admin` from the _adminList.
     */
    function removeAdmin(address _admin) external onlyOwner {
        _adminList[_admin] = false;
        emit AdminChanged(_admin, false);
    }

}