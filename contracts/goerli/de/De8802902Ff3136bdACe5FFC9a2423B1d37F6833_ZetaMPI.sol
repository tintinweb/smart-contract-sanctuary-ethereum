/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// File: contracts/zetalock.sol


pragma solidity >=0.8.0;



interface ISupplyOracle {
    function getSupplyAndLocked() external view returns (uint, uint);
}

interface ZetaMPIReceiver {
	function uponZetaMessage(
		address sender, string calldata destChainID, address destContract, uint zetaAmount,
		uint gasLimit, bytes calldata message, bytes32 messageID) external; 
}

contract ZetaMPI {
    IERC20 zeta; // the Zeta token contract
    ISupplyOracle oracle; // the supply oracle contract

    // TSSAddress is the TSS address collectively possessed by Zeta blockchain validators. 
    // It's the only address that can mint. 
    // Threshold Signature Scheme (TSS) [GG20] is a multi-sig ECDSA/EdDSA protocol. 
    address public TSSAddress; 
    // The TSSAddressUpdater can change the TSSAddress, in case Zeta blockchain node churn
    // changes the TSS key pairs. 
    // At launch, TSSAddressUpdater is controlled by multi-sig wallet;
    // Eventually, TSSAddressUpdater will be the same as TSSAddress, via renounceTSSAddressUpdater()
    address public TSSAddressUpdater;
    // OracleUpdater can update the supply oracle address
    // This address is controlled by multi-sig wallet
    // Supply oracle is used for last-resort protection against arbitrary mint
    // in the unlikely case the Zeta blockchain is compromised or exploited. 
    address public OracleUpdater; 

    // deviation parameter for supply check
    // due to non-realtime supply oracle updates, burn may not propagate fast enough
    // we will allow certain percentage of flexibility to temporarily "exceed" total supply
    uint8 flexibility; 

    // event LockSend(address indexed sender, string receiver, uint amount, uint wanted, string chainid, bytes message); 
    // event Unlock(address indexed receiver, uint256 amount, bytes32 indexed sendHash); 
    event ZetaMessageSendEvent(address sender, string destChainID, string  destContract, uint zetaAmount, uint gasLimit, bytes message, bytes32 messageID); 
    event ZetaMessageReceiveEvent(address sender, string destChainID, address  destContract, uint zetaAmount, uint gasLimit, bytes message, bytes32 messageID, bytes32 indexed utxoHash); 


    constructor(address zetaAddress, address oracleAddress, address _TSSAddress, address _TSSAddressUpdater, address _OracleUpdater) {       
        zeta = IERC20(zetaAddress); 
        oracle = ISupplyOracle(oracleAddress); 
        TSSAddress = _TSSAddress; 
        TSSAddressUpdater = _TSSAddressUpdater; 
        OracleUpdater = _OracleUpdater; 
        flexibility = 102; 
    }

    // update the TSSAddress in case of Zeta blockchain validator nodes churn
    function updateTSSAddress(address _address) external {
        require(msg.sender == TSSAddressUpdater, "updateTSSAddress: need TSSAddressUpdater permission");
        require(_address != address(0)); 
        TSSAddress = _address;
    }

    // Change the ownership of TSSAddressUpdater to the Zeta blockchain TSS nodes. 
    // Effectively, only Zeta blockchain validators collectively can update TSSAddress afterwards. 
    function renounceTSSAddressUpdater() external {
        require(msg.sender == TSSAddressUpdater, "renounceTSSAddressUpdater: need TSSAddressUpdater permission");
        require(TSSAddress != address(0)); 
        TSSAddressUpdater = TSSAddress;
    }

    function changeOracle(address newOracleAddres) external {
        require(msg.sender == OracleUpdater, "changeOracle: need OracleUpdater permission");
        oracle = ISupplyOracle(newOracleAddres); 
    }

    function updateSupplyOracleFlexibility(uint8 newFlexibility) external {
        require(msg.sender == OracleUpdater, "updateSupplyOracleFlexibility: need OracleUpdater permission");
        require(newFlexibility >= 100 && newFlexibility <= 110);
        flexibility = newFlexibility;
    }

    function getLockedAmount() public view returns (uint) {
        return zeta.balanceOf(address(this));
    }

    // Needs to ERC20.approve this contract to lock the sender's M token. 
    function zetaMessageSend(address sender, string calldata destChainID, string calldata  destContract, uint zetaAmount, uint gasLimit, bytes calldata message, bytes32 messageID) external {
        bool success = zeta.transferFrom(msg.sender, address(this), zetaAmount); 
        require(success == true, "zetaMessageSend: transfer fails"); 
        emit ZetaMessageSendEvent(sender, destChainID, destContract, zetaAmount, gasLimit, message, messageID); 
    }

    function zetaMessageReceive(address sender, string calldata destChainID, address destContract, uint zetaAmount, uint gasLimit, bytes calldata message, bytes32 messageID, bytes32 sendHash) external {
        require(msg.sender == TSSAddress, "zetaMessageReceive: permission error"); 
        uint lockedAmount = getLockedAmount();
        // supply: the total supply of ZETA on all chains except Ethereum; locked: the total ZETA locked in this contract
        (uint supply,) = oracle.getSupplyAndLocked();
        // make sure that mint does not inflate supply of ZETA: unlock() must be after a commensurate burn on other chains. 
        // Because supply oracle is not real time, we allow 2% flexibility. 
        require(supply + zetaAmount <= lockedAmount * flexibility / 100, "total supply exceeded");
        bool success = zeta.transfer(destContract, zetaAmount);
        require(success == true, "zetaMessageReceive: transfer failed"); 

        ZetaMPIReceiver(destContract).uponZetaMessage(sender, destChainID, destContract, zetaAmount, gasLimit, message, messageID);
        emit ZetaMessageReceiveEvent(sender, destChainID, destContract, zetaAmount, gasLimit, message, messageID, sendHash);
    }
}