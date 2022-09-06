// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./NormalizingOracleAdapter.sol";
import "../../interfaces/IChainlinkV3Aggregator.sol";

contract ChainlinkUSDAdapter is NormalizingOracleAdapter {
    /// @notice chainlink aggregator with price in USD
    IChainlinkV3Aggregator public immutable aggregator;

    constructor(
        string memory _assetName,
        string memory _assetSymbol,
        address _asset,
        IChainlinkV3Aggregator _aggregator
    ) NormalizingOracleAdapter(_assetName, _assetSymbol, _asset, 8, 8) {
        require(address(_aggregator) != address(0), "invalid aggregator");

        aggregator = _aggregator;
    }

    /// @dev returns price of asset in 1e8
    function latestAnswer() external view override returns (int256) {
        (, int256 price, , , ) = aggregator.latestRoundData();
        return int256(_normalize(uint256(price)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "./AssetOracleAdapter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../token/IERC20Details.sol";

abstract contract NormalizingOracleAdapter is AssetOracleAdapter, Ownable {
    uint256 public _inputDecimals;
    uint256 public _outputDecimals;

    constructor(
        string memory _assetName,
        string memory _assetSymbol,
        address _asset,
        uint256 __inputDecimals,
        uint256 __outputDecimlas
    ) AssetOracleAdapter(_assetName, _assetSymbol, _asset) {
        _inputDecimals = __inputDecimals;
        _outputDecimals = __outputDecimlas;
    }

    function getInputDecimals() public view returns (uint256) {
        return _inputDecimals;
    }

    function setInputDecimals(uint256 __inputDecimals) public onlyOwner {
        _inputDecimals = __inputDecimals;
    }

    function getOutputDecimals() public view returns (uint256) {
        return _outputDecimals;
    }

    function setOutputDecimals(uint256 __outputDecimals) public onlyOwner {
        _outputDecimals = __outputDecimals;
    }

    /// @dev scales the input to from `_inputDecimals` to `_outputDecimals` decimal places
    function _normalize(uint256 _amount) internal view returns (uint256) {
        if (_inputDecimals >= _outputDecimals) {
            return _amount / 10**(_inputDecimals - _outputDecimals);
        } else {
            return _amount * (10**(_outputDecimals - _inputDecimals));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IChainlinkV3Aggregator {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "../../interfaces/IOracle.sol";

abstract contract AssetOracleAdapter is IOracle {
    string public assetName;
    /// @dev asset symbol
    string public assetSymbol;
    /// @dev admin allowed to update price oracle
    /// @notice the asset with the price oracle
    address public immutable asset;

    constructor(
        string memory _assetName,
        string memory _assetSymbol,
        address _asset
    ) {
        require(_asset != address(0), "invalid asset");
        assetName = _assetName;
        assetSymbol = _assetSymbol;
        asset = _asset;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IERC20Details {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IOracle {
    /// @notice Price update event
    /// @param asset the asset
    /// @param newPrice price of the asset
    event PriceUpdated(address asset, uint256 newPrice);

    /// @dev returns latest answer
    function latestAnswer() external view returns (int256);

}

// SPDX-License-Identifier: MIT

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