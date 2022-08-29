/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: MIT
// File: contracts/interfaces/IBridgeFeeOracle.sol



pragma solidity 0.8.0;

interface IBridgeFeeOracle {
    event OracleCallerUpdated(address indexed oracleCaller);
    event TokenBridgeAmountUpdate(address indexed tokenAddress);
    event TokenBridgeAmountUpdated(address indexed tokenAddress);

    function getBridgeAmount(address tokenAddress)
        external
        view
        returns (uint256, uint256);
}
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.0/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.0/contracts/access/Ownable.sol



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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/BridgeFeeOracle.sol



pragma solidity 0.8.0;



/// @title Bridge Fee Oracle
/// @notice This contract is to store min/max amounts of tokens that can be bridged
contract BridgeFeeOracle is Ownable, IBridgeFeeOracle {
    mapping(address => uint256) private minimumAmounts;

    mapping(address => uint256) private maximumAmounts;

    address public nativeCoinRouter;

    /// @notice The address that can set min/max values
    address public oracleCaller;

    modifier onlyAllowed() {
        require(
            msg.sender == owner() || msg.sender == oracleCaller,
            "no permission"
        );
        _;
    }

    constructor(address _oracleCaller) {
        require(_oracleCaller != address(0), "!zero address");
        oracleCaller = _oracleCaller;
    }

    /// @notice A function to set the oracle caller
    /// @param _oracleCaller The oracle caller address
    function setOracleCaller(address _oracleCaller) external onlyOwner {
        require(_oracleCaller != address(0), "invalid address");
        oracleCaller = _oracleCaller;
        emit OracleCallerUpdated(oracleCaller);
    }

    /// @notice A function to trigger bridge oracle backend to set the fee amounts
    /// @param tokenAddress the token address that gonna be bridged
    function updateBridgeAmount(address tokenAddress) external {
        emit TokenBridgeAmountUpdate(tokenAddress);
    }

    /// @notice A function sets the bridge min/max amounts of a token
    /// @param tokenAddress the token address
    /// @param min the minimum amount of token that can be bridged
    /// @param max the maximum amount of token that can be bridged
    function setBridgeAmount(
        address tokenAddress,
        uint256 min,
        uint256 max
    ) external onlyAllowed {
        require(max >= min, "max should be bigger than min");

        minimumAmounts[tokenAddress] = min;
        maximumAmounts[tokenAddress] = max;

        emit TokenBridgeAmountUpdated(tokenAddress);
    }

    /// @notice A function to get the min/max amounts of a token
    /// @param tokenAddress the token address
    function getBridgeAmount(address tokenAddress)
        external
        view
        override
        returns (uint256, uint256)
    {
        return (minimumAmounts[tokenAddress], maximumAmounts[tokenAddress]);
    }
}