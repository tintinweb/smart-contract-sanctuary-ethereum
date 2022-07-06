// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

library MWWStructs {
    struct Domain {
        address owner;
        uint256 planId;
        uint256 expiryTime; //valid until when
        string domain;
        string configIpfsHash;
        uint256 registeredAt;
    }
}

contract MWWDomain is Ownable {
    mapping(address => bool) private admins;
    mapping(string => MWWStructs.Domain) public domains;
    mapping(address => string[]) private accountDomains;
    mapping(string => address[]) private domainDelegates;

    address public registerContract;

    event MWWSubscribed(
        address indexed subscriber,
        uint256 planId,
        uint256 expiryTime,
        string domain
    );
    event MWWDomainChanged(
        address indexed subscriber,
        string originalDomain,
        string newDomain
    );

    constructor(address _registar) {
        admins[msg.sender] = true;
        registerContract = _registar;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admin can do it");
        _;
    }

    modifier onlyRegisterContract() {
        require(
            msg.sender == registerContract,
            "Only the register can call this"
        );
        _;
    }

    function setRegisterContract(address _address) public onlyOwner {
        registerContract = _address;
    }

    function removeAdmin(address admin) public onlyOwner {
        admins[admin] = false;
    }

    function addAdmin(address admin) public onlyAdmin {
        admins[admin] = true;
    }

    function isDelegate(string calldata domain) public view returns (bool) {
        address[] memory delegates = domainDelegates[domain];

        for (uint256 i = 0; i < delegates.length; i++) {
            if (delegates[i] == msg.sender) {
                return true;
            }
        }

        return false;
    }

    function isAllowedToManageDomain(string calldata domain)
        private
        view
        returns (bool)
    {
        return isDelegate(domain) || domains[domain].owner == msg.sender;
    }

    function addDelegate(string calldata domain, address delegate) public {
        require(
            domains[domain].owner == msg.sender,
            "You are not allowed to do this"
        );
        domainDelegates[domain].push(delegate);
    }

    function removeDelegate(string calldata domain, address delegate) public {
        require(
            domains[domain].owner == msg.sender,
            "You are not allowed to do this"
        );

        uint256 j = 0;
        uint256 size = domainDelegates[domain].length;
        address[] memory auxDelegates = new address[](
            size - 1
        );
        for (uint256 i = 0; i < size; i++) {
            if (domainDelegates[domain][i] != delegate) {
                auxDelegates[j] = domainDelegates[domain][i];
                j = j + 1;
            }
        }
        domainDelegates[domain] = auxDelegates;
    }

    function subscribe(
        address originalCaller,
        uint256 planId,
        address planOwner,
        uint256 duration,
        string calldata domain,
        string calldata ipfsHash
    ) public onlyRegisterContract returns (MWWStructs.Domain memory) {
        return
            _subscribe(
                originalCaller,
                planId,
                planOwner,
                duration,
                domain,
                ipfsHash
            );
    }

    function addDomains(
        MWWStructs.Domain[] calldata domainsToAdd
    ) public onlyAdmin returns (bool) {
            uint256 size = domainsToAdd.length;
        for (uint256 i = 0; i < size; i++) {
            MWWStructs.Domain calldata domain = domainsToAdd[i];
            _subscribe(
                address(0),
                domain.planId,
                domain.owner,
                domain.expiryTime - block.timestamp,
                domain.domain,
                domain.configIpfsHash
            );
        }
        return true;
    }

    function _subscribe(
        address originalCaller,
        uint256 planId,
        address planOwner,
        uint256 duration,
        string calldata domain,
        string calldata ipfsHash
    ) private returns (MWWStructs.Domain memory) {
        if (
            domains[domain].owner != address(0) &&
            domains[domain].expiryTime > block.timestamp
        ) {
            // check subscription exists and is not expired
            require(
                domains[domain].owner == planOwner,
                "Domain registered for someone else"
            );
            require(
                domains[domain].planId == planId,
                "Domain registered with another plan"
            );

            MWWStructs.Domain storage existingDomain = domains[domain];
            existingDomain.expiryTime = existingDomain.expiryTime + duration;

            return existingDomain;
        }

        MWWStructs.Domain memory _domain = MWWStructs.Domain({
            owner: planOwner,
            planId: planId,
            expiryTime: block.timestamp + duration,
            domain: domain,
            configIpfsHash: ipfsHash,
            registeredAt: block.timestamp
        });

        if (originalCaller != address(0) && planOwner != originalCaller) {
            domainDelegates[domain].push(originalCaller);
        }

        domains[domain] = _domain;

        accountDomains[planOwner].push(domain);

        emit MWWSubscribed(planOwner, planId, duration, domain);

        return _domain;
    }

    function changeDomain(string calldata domain, string calldata newDomain)
        public
        returns (MWWStructs.Domain memory)
    {
        require(
            isAllowedToManageDomain(domain),
            "Only the owner or delegates can manage the domain"
        );
        require(isSubscriptionActive(domain), "Subscription expired");
        require(
            !isSubscriptionActive(newDomain),
            "New Domain must be unregistered or expired."
        );

        MWWStructs.Domain memory subs = domains[domain];

        domains[newDomain] = MWWStructs.Domain({
            owner: subs.owner,
            planId: subs.planId,
            expiryTime: subs.expiryTime,
            domain: newDomain,
            configIpfsHash: subs.configIpfsHash,
            registeredAt: subs.registeredAt
        });

        delete domains[domain];

        string[] memory auxDomains = new string[](
            accountDomains[subs.owner].length
        );
        auxDomains[0] = newDomain;

        uint256 j = 1;
        bytes32 oldDomainHash = keccak256(bytes(domain));

        // TODO: same pattern can be used here (Check removePlan function comments in RegistarBase contract)
        for (uint256 i = 0; i < accountDomains[subs.owner].length; i++) {
            if (
                keccak256(bytes(accountDomains[subs.owner][i])) != oldDomainHash
            ) {
                auxDomains[j] = accountDomains[subs.owner][i];
                j++;
            }
        }

        accountDomains[subs.owner] = auxDomains;

        emit MWWDomainChanged(subs.owner, domain, newDomain);

        return domains[newDomain];
    }

    function changeDomainConfigHash(
        string calldata domain,
        string calldata ipfsHash
    ) public {
        require(
            isAllowedToManageDomain(domain),
            "Only the owner or delegates can manage the domain"
        );
        domains[domain].configIpfsHash = ipfsHash;
    }

    function isSubscriptionActive(string calldata domain)
        public
        view
        returns (bool)
    {
        return domains[domain].expiryTime > block.timestamp;
    }

    function getDomainsForAccount(address account)
        public
        view
        returns (string[] memory)
    {
        return accountDomains[account];
    }

    function getDelegatesForDomain(string memory domain)
        public
        view
        returns (address[] memory)
    {
        return domainDelegates[domain];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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