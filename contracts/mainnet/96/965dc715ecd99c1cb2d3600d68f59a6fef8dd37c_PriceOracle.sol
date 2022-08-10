/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @title Represents an ownable resource.
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
     * Constructor
     * @param addr The owner of the smart contract
     */
    constructor (address addr) {
        require(addr != address(0), "non-zero address required");
        require(addr != address(1), "ecrecover address not allowed");
        owner = addr;
        emit OwnershipTransferred(address(0), addr);
    }

    /**
     * @notice This modifier indicates that the function can only be called by the owner.
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner requirement");
        _;
    }

    /**
     * @notice Transfers ownership to the address specified.
     * @param addr Specifies the address of the new owner.
     * @dev Throws if called by any account other than the owner.
     */
    function transferOwnership (address addr) public virtual onlyOwner {
        require(addr != address(0), "non-zero address required");
        emit OwnershipTransferred(owner, addr);
        owner = addr;
    }
}

/**
 * @title Defines the interface of a basic pricing oracle.
 * @dev All prices are expressed in USD, with 6 decimal positions.
 */
interface IBasicPriceOracle {
    function updateTokenPrice (address tokenAddr, uint256 valueInUSD) external;
    function bulkUpdate (address[] memory tokens, uint256[] memory prices) external;
    function getTokenPrice (address tokenAddr) external view returns (uint256);
}

/**
 * @title Implements a basic price oracle.
 * @dev All prices are expressed in USD, with 6 decimal positions.
 */
contract PriceOracle is IBasicPriceOracle, Ownable {
    // The price of each token, expressed in USD
    mapping (address => uint256) internal _tokenPrice;

    /**
     * @notice Constructor.
     * @param ownerAddr The address of the owner
     */
    constructor (address ownerAddr) Ownable (ownerAddr) { // solhint-disable-line no-empty-blocks
    }

    /**
     * @notice Updates the price of the token specified.
     * @dev Throws if the sender is not the owner of this contract.
     * @param tokenAddr The address of the token
     * @param newTokenPrice The new price of the token, expressed in USD with 6 decimal positions
     */
    function updateTokenPrice (address tokenAddr, uint256 newTokenPrice) external override onlyOwner {
        require(tokenAddr != address(0), "Token address required");
        require(newTokenPrice > 0, "Token price required");        
        _tokenPrice[tokenAddr] = newTokenPrice;
    }

    /**
     * @notice Updates the price of multiple tokens.
     * @dev Throws if the sender is not the owner of this contract.
     * @param tokens The address of each token
     * @param prices The new price of each token, expressed in USD with 6 decimal positions
     */
    function bulkUpdate (address[] memory tokens, uint256[] memory prices) external override onlyOwner {
        require(tokens.length > 0 && tokens.length <= 30, "Too many tokens");
        require(tokens.length == prices.length, "Invalid array length");
        for (uint256 i = 0; i < tokens.length; i++) {
            address tokenAddr = tokens[i];
            uint256 newTokenPrice = prices[i];
            require(tokenAddr != address(0), "Token address required");
            require(newTokenPrice > 0, "Token price required");        
            _tokenPrice[tokenAddr] = newTokenPrice;
        }
    }

    /**
     * @notice Gets the price of the token specified.
     * @param tokenAddr The address of the token
     * @return Returns the token price
     */
    function getTokenPrice (address tokenAddr) external view override returns (uint256) {
        return _tokenPrice[tokenAddr];
    }
}