// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;
pragma abicoder v2;

import {IIchiVaultSettingsV1} from "./IIchiVaultSettingsV1.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract IchiVaultSettingsV1 is IIchiVaultSettingsV1, Ownable {

    // wait time after a rebalance has been initiated before the actual rebalance is executed
    uint256 public override executionDelay; // for example, 300 = 5 minutes

    // TWAPs used for measuring volatility
    uint32 public override twapSlow; // for example, 3600 = 1 hour
    uint32 public override twapFast; // for example, 300 = 5 minutes

    // rebalance actions volatility thresholds
    uint256 public override extremeVolatility; // for example, 10 * ONE_PCT;
    uint256 public override highVolatility; // for example, 5 * ONE_PCT;
    uint256 public override someVolatility; // for example, ONE_PCT;
    uint256 public override dtrDelta; // for example, 5 * ONE_PCT;
    uint256 public override priceChange; // for example, 2 * ONE_PCT;
    uint256 public override gasTolerance; // for example, 40 gwei;

    /// @param _executionDelay wait time after a rebalance has been initiated before the actual rebalance is executed (for example, 300 = 5 minutes)
    /// @param _twapSlow slow TWAP used for measuring volatility (for example, 3600 = 1 hour)
    /// @param _twapFast fast TWAPs used for measuring volatility (for example, 300 = 5 minutes)
    /// @param _extremeVolatility price move that causes the strategy to lock up (for example, 1000 = 10%)
    /// @param _highVolatility price move that causes the strategy to go defensive (for example, 500 = 5%)
    /// @param _someVolatility price move that causes the strategy to delay rebalance (for example, 100 = 1%)
    /// @param _dtrDelta max tolerated change in DTR of an under inventory vault without a rebalance (for example, 500 = 5%)
    /// @param _priceChange change in price that may indicate a need for rebalance (for example, 200 = 2%)
    /// @param _gasTolerance gas tolerance threshold for the rebalance transaction (for example, 40 gwei)
    constructor(
        uint256 _executionDelay,
        uint32 _twapSlow,
        uint32 _twapFast,
        uint256 _extremeVolatility,
        uint256 _highVolatility,
        uint256 _someVolatility,
        uint256 _dtrDelta,
        uint256 _priceChange,
        uint256 _gasTolerance
    ) {
        require(_twapSlow >= 300 && _twapFast <= 3600 && _twapSlow > _twapFast, "invalid twaps");
        require(_executionDelay <= 3600, "invalid delayed execution setting");
        require(_extremeVolatility >= _highVolatility && _highVolatility > _someVolatility, "invalid volatility settings");
        require(_dtrDelta <= 10000, "invalid DTR delta");
        require(_gasTolerance > 0, "invalid gasTolerance");

        twapSlow = _twapSlow;
        twapFast = _twapFast;

        executionDelay = _executionDelay;

        extremeVolatility = _extremeVolatility;
        highVolatility = _highVolatility;
        someVolatility = _someVolatility;
        dtrDelta = _dtrDelta;
        priceChange = _priceChange;
        gasTolerance = _gasTolerance;

        emit DeploySettings(
            msg.sender,
            _executionDelay,
            _twapSlow,
            _twapFast,
            _extremeVolatility,
            _highVolatility,
            _someVolatility,
            _dtrDelta,
            _priceChange,
            _gasTolerance
        );
    }

    /// Sets executionDelay
    /// @param _executionDelay wait time after a rebalance has been initiated before the actual rebalance is executed (for example, 300 = 5 minutes)
    function setExecutionDelay(uint256 _executionDelay) external override onlyOwner {
        require(_executionDelay <= 3600, "invalid delayed execution setting");
        executionDelay = _executionDelay;
        emit SetExecutionDelay(msg.sender, executionDelay);
    }

    /// Sets twapSlow
    /// @param _twapSlow slow TWAP used for measuring volatility (for example, 3600 = 1 hour)
    function setTwapSlow(uint32 _twapSlow) external override onlyOwner {
        require(_twapSlow >= 300 && _twapSlow > twapFast, "invalid twaps");
        twapSlow = _twapSlow;
        emit SetTwapSlow(msg.sender, twapSlow);
    }

    /// Sets twapFast
    /// @param _twapFast fast TWAPs used for measuring volatility (for example, 300 = 5 minutes)
    function setTwapFast(uint32 _twapFast) external override onlyOwner {
        require(_twapFast <= 3600 && twapSlow > _twapFast, "invalid twaps");
        twapFast = _twapFast;
        emit SetTwapFast(msg.sender, twapFast);
    }

    /// Sets extremeVolatility
    /// @param _extremeVolatility price move that causes the strategy to lock up (for example, 1000 = 10%)
    function setExtremeVolatility(uint256 _extremeVolatility) external override onlyOwner {
        require(_extremeVolatility >= highVolatility, "invalid volatility settings");
        extremeVolatility = _extremeVolatility;
        emit SetExecutionDelay(msg.sender, executionDelay);
    }

    /// Sets highVolatility
    /// @param _highVolatility price move that causes the strategy to go defensive (for example, 500 = 5%)
    function setHighVolatility(uint256 _highVolatility) external override onlyOwner {
        require(extremeVolatility >= _highVolatility && _highVolatility > someVolatility, "invalid volatility settings");
        highVolatility = _highVolatility;
        emit SetHighVolatility(msg.sender, highVolatility);
    }

    /// Sets someVolatility
    /// @param _someVolatility price move that causes the strategy to delay rebalance (for example, 100 = 1%)
    function setSomeVolatility(uint256 _someVolatility) external override onlyOwner {
        require(highVolatility > _someVolatility, "invalid volatility settings");
        someVolatility = _someVolatility;
        emit SetSomeVolatility(msg.sender, someVolatility);
    }

    /// Sets dtrDelta
    /// @param _dtrDelta max tolerated change in DTR of an under inventory vault without a ebalance (for example, 500 = 5%)
    function setDtrDelta(uint256 _dtrDelta) external override onlyOwner {
        require(_dtrDelta <= 10000, "invalid DTR delta");
        dtrDelta = _dtrDelta;
        emit SetDtrDelta(msg.sender, dtrDelta);
    }

    /// Sets priceChange
    /// @param _priceChange change in price that may indicate a need for rebalance (for example, 200 = 2%)
    function setPriceChange(uint256 _priceChange) external override onlyOwner {
        priceChange = _priceChange;
        emit SetPriceChange(msg.sender, priceChange);
    }

    /// Sets the gas tolerance threshold for the rebalance transaction
    /// @param _gasTolerance gas tolerance threshold in gwei
    function setGasTolerance(uint256 _gasTolerance) external override onlyOwner {
        require(_gasTolerance > 0, "invalid gasTolerance");
        gasTolerance = _gasTolerance;
        emit SetGasTolerance(msg.sender, _gasTolerance);
    }

    /// Sets all the settings in one go
    /// @param _executionDelay wait time after a rebalance has been initiated before the actual rebalance is executed (for example, 300 = 5 minutes)
    /// @param _twapSlow slow TWAP used for measuring volatility (for example, 3600 = 1 hour)
    /// @param _twapFast fast TWAPs used for measuring volatility (for example, 300 = 5 minutes)
    /// @param _extremeVolatility price move that causes the strategy to lock up (for example, 1000 = 10%)
    /// @param _highVolatility price move that causes the strategy to go defensive (for example, 500 = 5%)
    /// @param _someVolatility price move that causes the strategy to delay rebalance (for example, 100 = 1%)
    /// @param _dtrDelta max tolerated change in DTR of an under inventory vault without a rebalance (for example, 500 = 5%)
    /// @param _priceChange change in price that may indicate a need for rebalance (for example, 200 = 2%)
    /// @param _gasTolerance gas tolerance threshold for the rebalance transaction (for example, 40 gwei)
    function setAll(
        uint256 _executionDelay,
        uint32 _twapSlow,
        uint32 _twapFast,
        uint256 _extremeVolatility,
        uint256 _highVolatility,
        uint256 _someVolatility,
        uint256 _dtrDelta,
        uint256 _priceChange,
        uint256 _gasTolerance
    ) external override onlyOwner {
        require(_twapSlow >= 300 && _twapFast <= 3600 && _twapSlow > _twapFast, "invalid twaps");
        require(_executionDelay <= 3600, "invalid delayed execution setting");
        require(_extremeVolatility >= _highVolatility && _highVolatility > _someVolatility, "invalid volatility settings");
        require(_dtrDelta <= 10000, "invalid DTR delta");
        require(_gasTolerance > 0, "invalid gasTolerance");

        twapSlow = _twapSlow;
        twapFast = _twapFast;

        executionDelay = _executionDelay;

        extremeVolatility = _extremeVolatility;
        highVolatility = _highVolatility;
        someVolatility = _someVolatility;
        dtrDelta = _dtrDelta;
        priceChange = _priceChange;
        gasTolerance = _gasTolerance;

        emit SetAll(
            msg.sender,
            _executionDelay,
            _twapSlow,
            _twapFast,
            _extremeVolatility,
            _highVolatility,
            _someVolatility,
            _dtrDelta,
            _priceChange,
            _gasTolerance
        );
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IIchiVaultSettingsV1 {

    function executionDelay() external view returns(uint256);
    function twapSlow() external view returns(uint32);
    function twapFast() external view returns(uint32);
    function extremeVolatility() external view returns(uint256);
    function highVolatility() external view returns(uint256);
    function someVolatility() external view returns(uint256);
    function dtrDelta() external view returns(uint256);
    function priceChange() external view returns(uint256);
    function gasTolerance() external view returns(uint256);

    function setExecutionDelay(uint256 _executionDelay) external;
    function setTwapSlow(uint32 _twapSlow) external;
    function setTwapFast(uint32 _twapFast) external;
    function setExtremeVolatility(uint256 _extremeVolatility) external;
    function setHighVolatility(uint256 _highVolatility) external;
    function setSomeVolatility(uint256 _someVolatility) external;
    function setDtrDelta(uint256 _dtrDelta) external;
    function setPriceChange(uint256 _priceChange) external;
    function setGasTolerance(uint256 _gasTolerance) external;

    function setAll(
        uint256 _executionDelay,
        uint32 _twapSlow,
        uint32 _twapFast,
        uint256 _extremeVolatility,
        uint256 _highVolatility,
        uint256 _someVolatility,
        uint256 _dtrDelta,
        uint256 _priceChange,
        uint256 _gasTolerance
    ) external;

    event DeploySettings(
        address indexed sender, 
        uint256 executionDelay,
        uint32 twapSlow,
        uint32 twapFast,
        uint256 extremeVolatility,
        uint256 highVolatility,
        uint256 someVolatility,
        uint256 dtrDelta,
        uint256 priceChange,
        uint256 gasTolerance
    );

    event SetAll(
        address indexed sender, 
        uint256 executionDelay,
        uint32 twapSlow,
        uint32 twapFast,
        uint256 extremeVolatility,
        uint256 highVolatility,
        uint256 someVolatility,
        uint256 dtrDelta,
        uint256 priceChange,
        uint256 gasTolerance
    );

    event SetExecutionDelay(
        address indexed sender, 
        uint256 executionDelay
    );

    event SetTwapSlow(
        address indexed sender, 
        uint32 twapSlow
    );

    event SetTwapFast(
        address indexed sender, 
        uint32 twapFast
    );

    event SetExtremeVolatility(
        address indexed sender, 
        uint256 extremeVolatility
    );

    event SetHighVolatility(
        address indexed sender, 
        uint256 highVolatility
    );

    event SetSomeVolatility(
        address indexed sender, 
        uint256 someVolatility
    );

    event SetDtrDelta(
        address indexed sender, 
        uint256 dtrDelta
    );

    event SetPriceChange(
        address indexed sender, 
        uint256 priceChange
    );

    event SetGasTolerance(
        address indexed sender, 
        uint256 gasTolerance
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}