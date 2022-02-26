// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.6.0 <=0.8.9;
pragma experimental ABIEncoderV2;
import "./interfaces/IParams.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Params is Ownable, IParams {
    uint256 public minimumSwapAmountForWBTC;
    uint256 public expirationTime;
    address public paraswapAddress;
    uint8 public nodeRewardsRatio;
    uint8 public depositFeesBPS;
    uint8 public withdrawalFeeBPS;
    uint8 public loopCount; //max loops when cleaning up expired SkyPools TXs

    constructor() {
        //Initialize minimumSwapAmountForWBTC
        minimumSwapAmountForWBTC = 24000;
        // Initialize expirationTime
        expirationTime = 172800; //2 days
        // Initialize paraswap address to current address
        paraswapAddress = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;
        // Initialize nodeRewardsRatio
        nodeRewardsRatio = 66;
        // Initialize withdrawalFeeBPS
        withdrawalFeeBPS = 20;
        // Initialize depositFeesBPS
        depositFeesBPS = 0;
        // Initialize loopCount
        loopCount = 10;
    }

    function setMinimumSwapAmountForWBTC(uint256 _minimumSwapAmountForWBTC)
        external
        onlyOwner
    {
        require(
            _minimumSwapAmountForWBTC > 0,
            "_minimumSwapAmountForWBTC can not be 0"
        );
        minimumSwapAmountForWBTC = _minimumSwapAmountForWBTC;
    }

    function setExpirationTime(uint256 _expirationTime) external onlyOwner {
        require(_expirationTime >= 0, "_expirationTime can not be 0");
        expirationTime = _expirationTime;
    }

    function setParaswapAddress(address _paraswapAddress) external onlyOwner {
        paraswapAddress = _paraswapAddress;
    }

    function setNodeRewardsRatio(uint8 _nodeRewardsRatio) external onlyOwner {
        require(
            _nodeRewardsRatio >= 0 && _nodeRewardsRatio <= 100,
            "_nodeRewardsRatio is not valid"
        );
        nodeRewardsRatio = _nodeRewardsRatio;
    }

    function setWithdrawalFeeBPS(uint8 _withdrawalFeeBPS) external onlyOwner {
        require(
            _withdrawalFeeBPS >= 0 && _withdrawalFeeBPS <= 100,
            "_withdrawalFeeBPS is invalid"
        );
        withdrawalFeeBPS = _withdrawalFeeBPS;
    }

    function setDepositFeesBPS(uint8 _depositFeesBPS) external onlyOwner {
        require(
            _depositFeesBPS >= 0 && _depositFeesBPS <= 100,
            "_depositFeesBPS is invalid"
        );
        depositFeesBPS = _depositFeesBPS;
    }

    function setLoopCount(uint8 _loopCount) external onlyOwner {
        require(_loopCount != 0, "_loopCount can not equal 0");
        loopCount = _loopCount;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.6.0 <=0.8.9;
pragma experimental ABIEncoderV2;

interface IParams {

    function minimumSwapAmountForWBTC() external view returns (uint256);
    function expirationTime() external view returns (uint256);
    function paraswapAddress() external view returns (address);
    function nodeRewardsRatio() external view returns (uint8);
    function depositFeesBPS() external view returns (uint8);
    function withdrawalFeeBPS() external view returns (uint8);
    function loopCount() external view returns (uint8);

    function setMinimumSwapAmountForWBTC(uint256 _minimumSwapAmountForWBTC) external;

    function setExpirationTime(uint256 _expirationTime) external;

    function setParaswapAddress(address _paraswapAddress) external;

    function setNodeRewardsRatio(uint8 _nodeRewardsRatio) external;

    function setWithdrawalFeeBPS(uint8 _withdrawalFeeBPS) external;

    function setDepositFeesBPS(uint8 _depositFeesBPS) external;

    function setLoopCount(uint8 _loopCount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.9;

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _onlyOwner() private view {
        require(msg.sender == _owner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        //require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _onlyOwner();
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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