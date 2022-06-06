/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

// SPDX-License-Identifier: MIT
// File @openzeppelin/contracts/utils/[email protected]
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

// File @openzeppelin/contracts/access/[email protected]

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

// File contracts/interfaces/IOracle.sol

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

interface IOracle {
    function consult() external view returns (uint256);
}

// File contracts/interfaces/IPairOracle.sol

pragma solidity 0.8.4;

interface IPairOracle {
    function consult(address token, uint256 amountIn) external view returns (uint256 amountOut);

    function update() external;
}

// File contracts/oracle/TokenOracle.sol

pragma solidity 0.8.4;

contract TokenOracle is Ownable, IOracle {
    address public oracleTokenStable;
    address public oracleStable;
    address public token;

    uint256 public missingDecimals;
    uint256 private constant PRICE_PRECISION = 1e6;

    constructor(
        address _token,
        address _oracleTokenStable,
        address _oracleStable,
        uint256 _missingDecimals
    ) {
        token = _token;
        oracleTokenStable = _oracleTokenStable;
        oracleStable = _oracleStable;
        missingDecimals = _missingDecimals;
    }

    function consult() external view override returns (uint256) {
        uint256 _priceTokenToStable = IPairOracle(oracleTokenStable).consult(token, (PRICE_PRECISION * (10**missingDecimals)));
        uint256 _priceStableToUsd = IOracle(oracleStable).consult();
        return _priceTokenToStable * _priceStableToUsd / PRICE_PRECISION;
    }

    function setOracleTokenStable(address _oracleTokenStable) external onlyOwner {
        oracleTokenStable = _oracleTokenStable;
    }

    function setOracleStable(address _oracleStable) external onlyOwner {
        oracleStable = _oracleStable;
    }
    
}