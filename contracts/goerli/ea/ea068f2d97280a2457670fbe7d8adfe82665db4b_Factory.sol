// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract Admin {
    mapping(address => bool) public admins;

    error NotAdmin(address);
    error ZeroAddress(address);

    event NewAdminAdded(address);
    event AdminRemoved(address);

    modifier onlyAdmin() {
        if (!admins[msg.sender]) revert NotAdmin(msg.sender);
        _;
    }

    constructor() {
        admins[msg.sender] = true;
    }

    function setAdmin(address _newAdmin) public onlyAdmin {
        if (_newAdmin == address(0)) revert ZeroAddress(msg.sender);

        admins[_newAdmin] = true;
        emit NewAdminAdded(_newAdmin);
    }

    function removeAdmin(address _addr) public onlyAdmin {
        if (_addr == address(0)) revert ZeroAddress(msg.sender);

        admins[_addr] = false;
        emit AdminRemoved(_addr);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IWallet{

    /**
     * Function to Facilitate Ether Claims
     */
    function claimEthers(uint256 _amount) external  returns(bool success);

    /**
     * @notice Function to facilitate ERC20 withdrawal
     * @param _ERC20 ERC20 Token to be withdrawn
     * @param _amount Amount of Token to  be withdrawn
     */
    function claimTokens(address _ERC20, uint256 _amount) external  returns(bool success);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Wallet {

    uint256 public unlockAt;
    address public factory;

    address payable immutable owner;
    
    error InvalidAccess(address);
    error TokensLocked(uint);
    error InvalidToken(address);

    event TokenDeposited(address, address, uint);
    event EtherReceived(address, uint);
    event TokenClaimed(address, uint);
    event EtherClaimed(uint);

    constructor(address _owner,
                uint256 _unlockAt){

        factory = msg.sender;
        owner = payable(_owner);
        unlockAt = _unlockAt;
    }

    modifier onlyFactory(){
        if(msg.sender != factory) revert InvalidAccess(msg.sender);
        _;
    }

    /**
     * @notice Function to facilitate ERC20 deposit
     * @param _ERC20 ERC20 Token to be deposited
     * @param _amount Amount of Token to  be deposited
     */
    function deposit(address _ERC20, uint256 _amount) external returns(bool success){

        IERC20(_ERC20).transferFrom(msg.sender, address(this), _amount);
        emit TokenDeposited(msg.sender, _ERC20, _amount);
        success = true;
        
    }
    
    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    /**
     * Function to Facilitate Ether Claims
     */
    function claimEthers(uint256 _amount) public onlyFactory returns(bool success){

        if(block.timestamp < unlockAt) revert TokensLocked(unlockAt);

        owner.transfer(_amount);
        emit EtherClaimed(_amount);
        success = true;
    }

    /**
     * @notice Function to facilitate ERC20 withdrawal
     * @param _ERC20 ERC20 Token to be withdrawn
     * @param _amount Amount of Token to  be withdrawn
     */
    function claimTokens(address _ERC20, uint256 _amount) public onlyFactory returns(bool success){
        
        if(block.timestamp < unlockAt) revert TokensLocked(unlockAt);
        if(_ERC20 == address(0)) revert InvalidToken(_ERC20);

        IERC20(_ERC20).transfer(owner, _amount);
        emit TokenClaimed(_ERC20, _amount);
        success =  true;

    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {Admin} from './Admin.sol';
import {Wallet} from "./TimeLockedSCW.sol";
import {IWallet} from "./ITimeLockedWallet.sol";

contract Factory is  ERC2771Context, Admin {

    uint256 public lockDuration = 5 minutes;

    error WalletAlreadyExists(address);
    error NotForwarder(address);

    mapping(address => address) public registry;

    constructor(address _forwarder) Admin() ERC2771Context(_forwarder){

    }

    modifier onlyTrustedForwarder(){
        if(!(isTrustedForwarder(msg.sender))) revert NotForwarder(msg.sender);
        _;
    }

    /**
     * Public API to fetch wallet address
     */
    function getWallet() public view returns (address) {

        return registry[msg.sender];
    }

    /**
     * Funciton to Create New smart contract Wallets belonging to the sender
     * FLow :
     * 1) Check if the Wallet Exists or not
     * 2) If not, then deploy a new wallet. 
     */
    function createTLSCW() public {

        if(registry[msg.sender] !=address(0))
        {
            revert WalletAlreadyExists(registry[msg.sender]);
        }

        Wallet newWallet = new Wallet(msg.sender, block.timestamp + lockDuration);
        registry[msg.sender] = address(newWallet);

    }

    /**
     * Function to Facilitate Ether Claims
     */
    function claimEthers(uint256 _amount) external onlyTrustedForwarder returns(bool success){

        if(registry[_msgSender()]!= address(0)){
            success = IWallet(registry[_msgSender()]).claimEthers(_amount);
        }
        
    }

    /**
     * @notice Function to facilitate ERC20 withdrawal
     * @param _ERC20 ERC20 Token to be withdrawn
     * @param _amount Amount of Token to  be withdrawn
     */
    function claimTokens(address _ERC20, uint256 _amount) external onlyTrustedForwarder returns(bool success){
        
        if(registry[_msgSender()]!= address(0)){
            success = IWallet(registry[_msgSender()]).claimTokens(_ERC20, _amount);
        }

    }

}