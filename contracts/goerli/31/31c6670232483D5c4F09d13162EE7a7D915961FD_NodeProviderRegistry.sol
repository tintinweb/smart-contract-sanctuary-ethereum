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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract NodeProviderRegistry is Ownable {
    
    event Approved(address provider);
    event Disapproved(address provider);
    event Registered(address provider, uint amount);
    event Exit(address provider, uint amount);

    // Basic information 
    struct NodeProvider {
        string rpc;
        uint balance;
        bool active;
    }

    // Node Providers that have staked on the contract
    mapping(address => NodeProvider) public registered; 

    // A hard-coded approve list -- only certain entities allowed to stake
    mapping(address => bool) public approvedList; 

    // Configuration details 
    uint public fixedDeposit; 

    constructor(uint _fixedDeposit) {
        fixedDeposit = _fixedDeposit;
    }

    // @dev Only active providers can call function
    modifier IsProvider() {
        require(registered[msg.sender].active, "Only active providers.");
        _;
    }

    // @dev Admin can approve new node providers 
    function approveProvider(address _provider) public onlyOwner() {
        approvedList[_provider] = true; 

        emit Approved(_provider);
    }

    // @dev Admin can disapprove existing node providers. It will not unstake.
    function disapproveProvider(address payable _provider) public onlyOwner() payable {
        approvedList[_provider] = false; 
        NodeProvider memory provider = registered[_provider];

        // Deactivate the provider
        if(provider.active) {
            registered[_provider].active = false;
        }

        emit Disapproved(_provider);
    }

    // @dev: Update details for a node provider. 
    function updateRPC(string memory _rpc) public IsProvider() {
        // A node provider can update the RPC URL. 
        registered[msg.sender].rpc = _rpc; 
    }

    // @dev: Node provider must stake a fixed quantity of coins
    function stake(string memory _rpc) public payable {
        // Minimum stake / deposit required 
        require(msg.value == fixedDeposit, "Fixed deposit is required.") ;
        
        // Prevents a provider who is not approved / disapprovied from staking & activating. 
        require(approvedList[msg.sender], "Provider must be pre-approved by owner.");
        require(registered[msg.sender].balance == 0, "Cannot add more stake."); 

        // Register the node provider 
        registered[msg.sender].active = true; 
        registered[msg.sender].rpc = _rpc; 
        registered[msg.sender].balance = msg.value;

        emit Registered(msg.sender, msg.value);
    }

    // @dev: Node provier can exit and withdraw their stake
    function unstake() public payable {
        // Check whether the caller has an active balance and should be allowed to unstake.
        require(registered[msg.sender].balance > 0, "Caller must have an active balance.");

        // keep track of balance owed and delete entry. 
        uint bal = registered[msg.sender].balance; 
        delete(registered[msg.sender]); 

        // Try to send the coins and revert if it fails. 
        address to = payable(msg.sender);
        (bool sent, ) = to.call{value: bal}("");
        require(sent, "Failed to send Ether");

        emit Exit(msg.sender, bal);
    }
}