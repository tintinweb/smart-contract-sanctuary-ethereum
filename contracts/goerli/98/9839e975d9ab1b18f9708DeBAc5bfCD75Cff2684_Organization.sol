/**
 *Submitted for verification at Etherscan.io on 2023-03-15
*/

// SPDX-License-Identifier: MIT
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

contract Organization is Ownable {
    uint256 public minTransaction = 100 wei;

    event MemberAccountSaved(
        address indexed userAddress,
        string userName,
        string imgUrl,
        string description,
        uint256 expirationDate,
        string organizationKey
    );

    event OrganizationSaved(string name, string key, string supportUrl, address manager, uint256 pricePerDay);

    event MemberAccountAdded(
        address indexed userAddress,
        string userName,
        string imgUrl,
        string description,
        uint256 expirationDate
    );

    event MemberAccountEdited(address indexed userAddress, string userName, string imgUrl, string description);

    event MemberAccountDeleted(address indexed userAddress);

    event OrganizationAdded(string name, string key, string supportUrl, address manager, uint256 pricePerDay);

    event OrganizationEdited(string name, string key, string supportUrl, address manager, uint256 pricePerDay);

    event OrganizationDeleted(string key);

    event Transfer(address indexed from, address indexed to, uint256 value);

    struct MemberAccount {
        address userAddress;
        string userName;
        string imgUrl;
        string description;
        uint256 expirationDate;
    }

    struct OrganizationData {
        string name;
        string key;
        string supportUrl;
        address manager;
        mapping(address => MemberAccount) accounts;
        uint256 pricePerDay;
    }

    mapping(string => OrganizationData) public organizations;

    modifier organizationNotNull(string memory _key) {
        require(organizations[_key].manager != address(0), "Organization key does not exist.");
        _;
    }

    modifier organizationManager(string memory _key) {
        require(
            organizations[_key].manager == _msgSender(),
            "Only the manager has permission to edit an organization."
        );
        _;
    }

    modifier accountOwner(string memory _key) {
        require(organizations[_key].accounts[_msgSender()].userAddress == _msgSender(), "Not authorized");
        _;
    }

    modifier validateOrganizationParams(
        string memory _name,
        string memory _key,
        string memory _supportUrl
    ) {
        require(bytes(_name).length > 0, "Name is required.");
        require(bytes(_key).length > 0, "Key is required.");
        require(bytes(_supportUrl).length > 0, "Support URL is required.");
        _;
    }

    modifier memberAccountAlreadyExists(string memory _key) {
        require(
            organizations[_key].accounts[_msgSender()].userAddress != _msgSender(),
            "Member account already exists."
        );
        _;
    }

    modifier minTranaction(uint256 _amount) {
        require(_amount >= minTransaction, "Minimum transaction must be greater than 100 wei");
        _;
    }

    function addOrganization(
        string memory _name,
        string memory _key,
        string memory _supportUrl,
        uint256 _pricePerDay
    ) public validateOrganizationParams(_name, _key, _supportUrl) {
        require(organizations[_key].manager == address(0), "Organization key already exists.");
        emit OrganizationAdded(_name, _key, _supportUrl, _msgSender(), _pricePerDay);
        emit OrganizationSaved(_name, _key, _supportUrl, _msgSender(), _pricePerDay);
        organizations[_key].name = _name;
        organizations[_key].key = _key;
        organizations[_key].supportUrl = _supportUrl;
        organizations[_key].manager = _msgSender();
        organizations[_key].pricePerDay = _pricePerDay;
    }

    function getOrganizationByManagerAndKey(
        address _manager,
        string memory _key
    ) public view organizationNotNull(_key) returns (string memory, string memory, string memory, address, uint256) {
        require(organizations[_key].manager == _manager, "Organization not found.");
        return (
            organizations[_key].name,
            organizations[_key].key,
            organizations[_key].supportUrl,
            organizations[_key].manager,
            organizations[_key].pricePerDay
        );
    }

    function editOrganization(
        string memory _key,
        string memory _name,
        string memory _supportUrl,
        uint256 _pricePerDay
    ) public organizationNotNull(_key) organizationManager(_key) {
        emit OrganizationEdited(_name, _key, _supportUrl, _msgSender(), _pricePerDay);
        emit OrganizationSaved(_name, _key, _supportUrl, _msgSender(), _pricePerDay);
        organizations[_key].name = _name;
        organizations[_key].supportUrl = _supportUrl;
        organizations[_key].manager = _msgSender();
        organizations[_key].pricePerDay = _pricePerDay;
    }

    function deleteOrganization(string memory _key) public organizationNotNull(_key) organizationManager(_key) {
        emit OrganizationSaved(
            organizations[_key].name,
            organizations[_key].key,
            organizations[_key].supportUrl,
            _msgSender(),
            0
        );
        emit OrganizationDeleted(_key);
        delete organizations[_key];
    }

    function addAccount(
        string memory _organizationKey,
        string memory _userName,
        string memory _imgUrl,
        string memory _description
    )
        public
        payable
        organizationNotNull(_organizationKey)
        memberAccountAlreadyExists(_organizationKey)
        minTranaction(msg.value)
    {
        uint256 pricePerDay = organizations[_organizationKey].pricePerDay;
        require(msg.value >= pricePerDay, "Not enough ETH sent.");
        uint256 availableDays = msg.value / pricePerDay;
        uint256 expirationDate = block.timestamp + availableDays * 1 days;
        emit MemberAccountAdded(_msgSender(), _userName, _imgUrl, _description, expirationDate);
        emit MemberAccountSaved(_msgSender(), _userName, _imgUrl, _description, expirationDate, _organizationKey);
        emit Transfer(_msgSender(), owner(), msg.value / 1000);
        emit Transfer(_msgSender(), organizations[_organizationKey].manager, msg.value - msg.value / 1000);
        organizations[_organizationKey].accounts[_msgSender()].userAddress = _msgSender();
        organizations[_organizationKey].accounts[_msgSender()].userName = _userName;
        organizations[_organizationKey].accounts[_msgSender()].imgUrl = _imgUrl;
        organizations[_organizationKey].accounts[_msgSender()].description = _description;
        organizations[_organizationKey].accounts[_msgSender()].expirationDate = expirationDate;
        payable(owner()).transfer(msg.value / 1000);
        payable(organizations[_organizationKey].manager).transfer(msg.value - msg.value / 1000);
    }

    function addAmountToAccount(
        string memory _organizationKey
    ) public payable organizationNotNull(_organizationKey) accountOwner(_organizationKey) minTranaction(msg.value) {
        uint256 pricePerDay = organizations[_organizationKey].pricePerDay;
        require(msg.value >= pricePerDay, "Not enough ETH sent.");
        uint256 availableDays = msg.value / pricePerDay;
        uint256 expirationDate = organizations[_organizationKey].accounts[_msgSender()].expirationDate +
            availableDays *
            1 days;
        organizations[_organizationKey].accounts[_msgSender()].expirationDate = expirationDate;
        emit Transfer(_msgSender(), owner(), msg.value / 1000);
        emit Transfer(_msgSender(), organizations[_organizationKey].manager, msg.value - msg.value / 1000);
        emit MemberAccountSaved(
            _msgSender(),
            organizations[_organizationKey].accounts[_msgSender()].userName,
            organizations[_organizationKey].accounts[_msgSender()].imgUrl,
            organizations[_organizationKey].accounts[_msgSender()].description,
            expirationDate,
            _organizationKey
        );
        payable(owner()).transfer(msg.value / 1000);
        payable(organizations[_organizationKey].manager).transfer(msg.value - msg.value / 1000);
    }

    function getAccountByOrganizationAndUserAddress(
        string memory _organizationKey,
        address _userAddress
    )
        public
        view
        organizationNotNull(_organizationKey)
        returns (address, string memory, string memory, string memory, uint256)
    {
        require(
            organizations[_organizationKey].accounts[_userAddress].userAddress == _userAddress,
            "Member account not found."
        );
        return (
            organizations[_organizationKey].accounts[_userAddress].userAddress,
            organizations[_organizationKey].accounts[_userAddress].userName,
            organizations[_organizationKey].accounts[_userAddress].imgUrl,
            organizations[_organizationKey].accounts[_userAddress].description,
            organizations[_organizationKey].accounts[_userAddress].expirationDate
        );
    }

    function editAccount(
        string memory _organizationKey,
        string memory _userName,
        string memory _imgUrl,
        string memory _description
    ) public organizationNotNull(_organizationKey) accountOwner(_organizationKey) {
        emit MemberAccountEdited(_msgSender(), _userName, _imgUrl, _description);
        emit MemberAccountSaved(
            _msgSender(),
            _userName,
            _imgUrl,
            _description,
            organizations[_organizationKey].accounts[_msgSender()].expirationDate,
            _organizationKey
        );
        organizations[_organizationKey].accounts[_msgSender()].userName = _userName;
        organizations[_organizationKey].accounts[_msgSender()].imgUrl = _imgUrl;
        organizations[_organizationKey].accounts[_msgSender()].description = _description;
    }

    function deleteMyAccount(
        string memory _organizationKey
    ) public organizationNotNull(_organizationKey) accountOwner(_organizationKey) {
        emit MemberAccountDeleted(_msgSender());
        emit MemberAccountSaved(
            _msgSender(),
            organizations[_organizationKey].accounts[_msgSender()].userName,
            organizations[_organizationKey].accounts[_msgSender()].imgUrl,
            organizations[_organizationKey].accounts[_msgSender()].description,
            block.timestamp,
            _organizationKey
        );
        delete organizations[_organizationKey].accounts[_msgSender()];
    }
}