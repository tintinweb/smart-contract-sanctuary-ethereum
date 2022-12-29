// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/interfaces/KeeperCompatibleInterface.sol";

interface IAnyCallProxy {
    function calcSrcFees(
        address _app,
        uint256 _toChainID,
        uint256 _dataLength
    ) external view returns (uint256);
}

interface ISubSchedule {
    function anyCallProxy() external view returns (address);

    function mainChainID() external view returns (uint256);

    function crossChainSync() external payable;
}

contract CrossChainSyncKeeperHelper is KeeperCompatibleInterface, Ownable {
    uint256 public constant DATA_LENGTH = 96; // abi.encode(uint256,uint256,uint256)

    ISubSchedule public immutable subSchedule;
    uint256 public immutable mainChainID;
    address public immutable anyCallProxy;

    uint256 public lastTimestamp;

    constructor(address subSchedule_) public {
        subSchedule = ISubSchedule(subSchedule_);
        mainChainID = ISubSchedule(subSchedule_).mainChainID();
        anyCallProxy = ISubSchedule(subSchedule_).anyCallProxy();
        _updateLastTimestamp(block.timestamp);
    }

    receive() external payable {}

    function withdraw(uint256 value) external onlyOwner {
        (bool success, ) = msg.sender.call{value: value}("");
        require(success, "ETH transfer failed");
    }

    function updateLastTimestamp(uint256 lastTimestamp_) external onlyOwner {
        _updateLastTimestamp(lastTimestamp_);
    }

    function checkUpkeep(bytes calldata)
        external
        override
        returns (bool upkeepNeeded, bytes memory)
    {
        upkeepNeeded = (block.timestamp > lastTimestamp + 1 weeks);
    }

    function performUpkeep(bytes calldata) external override {
        uint256 lastTimestamp_ = lastTimestamp;
        require(block.timestamp > lastTimestamp_ + 1 weeks, "Not yet");

        uint256 srcFees =
            IAnyCallProxy(anyCallProxy).calcSrcFees(address(subSchedule), mainChainID, DATA_LENGTH);
        require(address(this).balance >= srcFees, "Not enough balance");
        subSchedule.crossChainSync{value: srcFees}();

        // Always skip to the lastest week
        _updateLastTimestamp(
            lastTimestamp_ + ((block.timestamp - lastTimestamp_ - 1) / 1 weeks) * 1 weeks
        );
    }

    function _updateLastTimestamp(uint256 lastTimestamp_) private {
        lastTimestamp = lastTimestamp_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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
pragma solidity ^0.6.0;

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
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