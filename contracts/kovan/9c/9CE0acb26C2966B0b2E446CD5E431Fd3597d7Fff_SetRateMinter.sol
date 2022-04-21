pragma solidity ^0.5.0;

import "Ownable.sol";

//import "Ownable.sol";
import "IManager.sol";
import "INetAssetValueUSD.sol";

/**
 * @title SetRateMinter
 * @dev Serves as proxy (manager) for SRC20 minting/burning.
 */
contract SetRateMinter is Ownable {
    IManager public _registry;

    constructor(address registry) public {
        _registry = IManager(registry);
    }

    /**
     *  This proxy function calls the SRC20Registry function that will do two things
     *  Note: prior to this, the msg.sender has to call approve() on the SWM ERC20 contract
     *        and allow the Manager to withdraw SWM tokens
     *  1. Withdraw the SWM tokens that are required for staking
     *  2. Mint the SRC20 tokens
     *  Only the Owner of the SRC20 token can call this function
     *
     * @param src20 SRC20 token address.
     * @param swmAccount SWM ERC20 account holding enough SWM tokens (>= swmValue)
     * with manager contract address approved to transferFrom.
     * @param swmValue SWM stake value.
     * @param src20Value SRC20 tokens to mint
     * @return true on success
     */
    function mintSupply(address src20, address swmAccount, uint256 swmValue, uint256 src20Value)
    external
    onlyOwner
    returns (bool)
    {
        require(_registry.mintSupply(src20, swmAccount, swmValue, src20Value), 'supply minting failed');

        return true;
    }
}

pragma solidity ^0.5.0;

import "Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Manager handles SRC20 burn/mint in relation to
 * SWM token staking.
 */
interface IManager {
 
    event SRC20SupplyMinted(address src20, address swmAccount, uint256 swmValue, uint256 src20Value);
    event SRC20StakeIncreased(address src20, address swmAccount, uint256 swmValue);
    event SRC20StakeDecreased(address src20, address swmAccount, uint256 swmValue);

    function mintSupply(address src20, address swmAccount, uint256 swmValue, uint256 src20Value) external returns (bool);
    function increaseSupply(address src20, address swmAccount, uint256 srcValue) external returns (bool);
    function decreaseSupply(address src20, address swmAccount, uint256 srcValue) external returns (bool);
    function renounceManagement(address src20) external returns (bool);
    function transferManagement(address src20, address newManager) external returns (bool);
    function calcTokens(address src20, uint256 swmValue) external view returns (uint256);

    function getStake(address src20) external view returns (uint256);
    function swmNeeded(address src20, uint256 srcValue) external view returns (uint256);
    function getSrc20toSwmRatio(address src20) external returns (uint256);
    function getTokenOwner(address src20) external view returns (address);
}

pragma solidity ^0.5.0;

/**
 * @dev Interface for the AssetRegistry contract
 */
interface INetAssetValueUSD {

    function getNetAssetValueUSD(address src20) external view returns (uint256);
}