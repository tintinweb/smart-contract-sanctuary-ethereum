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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/AdminControl.sol

pragma solidity  ^0.8.17;


contract AdminControl is Ownable {
    
    enum Role {UNKNOWN, SUPER_ADMIN, ADMIN}

    struct Permissions {
        Role role;
        bool investorManagement;
        bool chainManagement;
        bool approveStake;
    }
    mapping(address => Permissions) adminPermissions;

    constructor() {
        adminPermissions[msg.sender] = Permissions({
            role: Role.SUPER_ADMIN,
            investorManagement: false,
            chainManagement: false,
            approveStake: false
        });
    }

    function getAdmin(address _address) public view returns(Permissions memory) {
        return adminPermissions[_address];
    }

    function addAdmin(address _address) public onlyOwner {
        adminPermissions[_address] = Permissions({
            role: Role.ADMIN,
            investorManagement: false,
            chainManagement: false,
            approveStake: false
        });
    }

    function deleteAdmin(address _address) public onlyOwner {
        delete adminPermissions[_address];
    }


    function hasInvestorManagement() public view returns(bool) {
        return adminPermissions[msg.sender].role == Role.SUPER_ADMIN ? true : adminPermissions[msg.sender].investorManagement;
    }

    function grantInvestorManagement(address _address) public onlyOwner {
        require(adminPermissions[_address].role == Role.ADMIN, "Address is not an admin"); {
            adminPermissions[_address].investorManagement = true;
        }
    }

    function revokeInvestorManagement(address _address) public onlyOwner {
        require(adminPermissions[_address].role == Role.ADMIN, "Address is not an admin"); {
            adminPermissions[_address].investorManagement = false;
        }
    }

    modifier onlyChainManager() {
        require(hasChainManagement(), "You do not have the access to Chain managment");
        _;
    }

    function hasChainManagement() public view returns(bool) {
        return adminPermissions[msg.sender].role == Role.SUPER_ADMIN ? true : adminPermissions[msg.sender].chainManagement;
    }

    function grantChainManagement(address _address) public onlyOwner {
        require(adminPermissions[_address].role == Role.ADMIN, "Address is not an admin"); {
            adminPermissions[_address].chainManagement = true;
        }
    }

    function revokeChainManagement(address _address) public onlyOwner {
        require(adminPermissions[_address].role == Role.ADMIN, "Address is not an admin"); {
            adminPermissions[_address].chainManagement = false;
        }
    }

    modifier onlyChainStake() {
        require(hasApproveStake(), "You do not have the access to Chain managment");
        _;
    }

    function hasApproveStake() public view returns(bool) {
        return adminPermissions[msg.sender].role == Role.SUPER_ADMIN ? true : adminPermissions[msg.sender].approveStake;
    }

    function grantApproveStake(address _address) public onlyOwner {
        require(adminPermissions[_address].role == Role.ADMIN, "Address is not an admin"); {
            adminPermissions[_address].approveStake = true;
        }
    }

    function revokeApproveStake(address _address) public onlyOwner {
        require(adminPermissions[_address].role == Role.ADMIN, "Address is not an admin"); {
            adminPermissions[_address].approveStake = false;
        }
    }



    


}
// File: contracts/ChainManagement.sol

//SPDX-License-Identifier: MIT

pragma solidity  ^0.8.17;


contract ChainManagement is AdminControl{
    
    enum Status {UNKNOWN, ENABLE, DISABLE}
    enum ComplianceStatus { COMFORTABLE, NOTCOMFORTABLE, QUESTIONABLE }

    struct ChainMetadata {
        address chainWalletAddress;
        uint coinAPY;
        uint commission;
        string description;
        uint withdrawalDays;
        Status status;
        ComplianceStatus compliance;
    }
    
    mapping (uint => ChainMetadata) chains;
    
    function addChainMetadata(address chainWalletAddress,
                                uint coinAPY, 
                                uint chainId, 
                                uint commission, 
                                uint withdrawalDays, 
                                ComplianceStatus compliance, 
                                string memory description) public onlyChainManager {
        chains[chainId] = ChainMetadata({
            chainWalletAddress : chainWalletAddress,
            coinAPY : coinAPY,
            commission: commission,
            withdrawalDays: withdrawalDays,
            compliance: compliance,
            description: description,
            status: Status.ENABLE
        });
    }

    function disableChain(uint chainId) public onlyChainManager returns (bool) {
        require(chains[chainId].status == Status.ENABLE, "The chain is not enabled");
        chains[chainId].status = Status.DISABLE;
        return true;
    }
    
    function getChainMetadata(uint chainId) public view returns (ChainMetadata memory) {
        return chains[chainId];
    }
    
    function updateChainMetadata(address chainWalletAddress,
                                    uint coinAPY, 
                                    uint chainId, 
                                    uint commission, 
                                    uint withdrawalDays, 
                                    ComplianceStatus compliance, 
                                    string memory description) public onlyChainManager {
        require(chains[chainId].status == Status.UNKNOWN, "Metadata does not exist for this chain ID");    
        chains[chainId] = ChainMetadata({
            chainWalletAddress : chainWalletAddress,
            coinAPY: coinAPY,
            commission: commission,
            withdrawalDays: withdrawalDays,
            compliance: compliance,
            description: description,
            status: chains[chainId].status
        });
    }
}