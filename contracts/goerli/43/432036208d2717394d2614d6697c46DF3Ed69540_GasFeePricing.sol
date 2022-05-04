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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-4.5.0/access/Ownable.sol";

contract GasFeePricing is Ownable {
    // DstChainId => The estimated current gas price in wei of the destination chain
    mapping(uint256 => uint256) public dstGasPriceInWei;
    // DstChainId => USD gas ratio of dstGasToken / srcGasToken
    mapping(uint256 => uint256) public dstGasTokenRatio;

    constructor() {}

    /**
     * @notice Permissioned method to allow an off-chain party to set what each dstChain's
     * gas cost is priced in the srcChain's native gas currency.
     * Example: call on ETH, setCostPerChain(43114, 30000000000, 25180000000000000)
     * chain ID 43114
     * Average of 30 gwei cost to transaction on 43114
     * AVAX/ETH = 0.02518, scaled to gas in wei = 25180000000000000
     * @param _dstChainId The destination chain ID - typically, standard EVM chain ID, but differs on nonEVM chains
     * @param _gasUnitPrice The estimated current gas price in wei of the destination chain
     * @param _gasTokenPriceRatio USD gas ratio of dstGasToken / srcGasToken
     */
    function setCostPerChain(
        uint256 _dstChainId,
        uint256 _gasUnitPrice,
        uint256 _gasTokenPriceRatio
    ) external onlyOwner {
        dstGasPriceInWei[_dstChainId] = _gasUnitPrice;
        dstGasTokenRatio[_dstChainId] = _gasTokenPriceRatio;
    }

    /**
     * @notice Returns srcGasToken fee to charge in wei for the cross-chain message based on the gas limit
     * @param _options Versioned struct used to instruct relayer on how to proceed with gas limits. Contains data on gas limit to submit tx with.
     */
    function estimateGasFee(uint256 _dstChainId, bytes memory _options)
        external
        view
        returns (uint256)
    {
        uint256 gasLimit;
        // temporary gas limit set
        if (_options.length != 0) {
            (
                uint16 _txType,
                uint256 _gasLimit,
                uint256 _dstAirdrop,
                bytes32 _dstAddress
            ) = decodeOptions(_options);
            gasLimit = _gasLimit;
        } else {
            gasLimit = 200000;
        }

        uint256 minFee = ((dstGasPriceInWei[_dstChainId] *
            dstGasTokenRatio[_dstChainId] *
            gasLimit) / 10**18);

        return minFee;
    }

    function encodeOptions(uint16 txType, uint256 gasLimit)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(txType, gasLimit);
    }

    function encodeOptions(
        uint16 txType,
        uint256 gasLimit,
        uint256 dstNativeAmt,
        bytes32 dstAddress
    ) public pure returns (bytes memory) {
        return abi.encodePacked(txType, gasLimit, dstNativeAmt, dstAddress);
    }

    function decodeOptions(bytes memory _options)
        public
        pure
        returns (
            uint16,
            uint256,
            uint256,
            bytes32
        )
    {
        // decoding the _options - reverts if type 2 and there is no dstNativeAddress
        require(
            _options.length == 34 || _options.length > 66,
            "Wrong _adapterParameters size"
        );
        uint16 txType;
        uint256 gasLimit;
        uint256 dstNativeAmt;
        bytes32 dstNativeAddress;
        assembly {
            txType := mload(add(_options, 2))
            gasLimit := mload(add(_options, 34))
        }

        if (txType == 2) {
            assembly {
                dstNativeAmt := mload(add(_options, 66))
                dstNativeAddress := mload(add(_options, 98))
            }
            require(dstNativeAmt != 0, "dstNativeAmt empty");
            require(dstNativeAddress != bytes32(0), "dstNativeAddress empty");
        }

        return (txType, gasLimit, dstNativeAmt, dstNativeAddress);
    }
}