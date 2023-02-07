// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AggregatorInterface} from "../lib/chainlink/AggregatorInterface.sol";
import {IGasChecker} from "./IGasChecker.sol";

contract GasChecker is Ownable, IGasChecker {

    address immutable public override gasOracle; // chainlink fast gas oracle;
    uint256 public override gasTolerance; // for example, 40 gwei;

    /// @param _gasOracle chainlink gas oracle
    /// @param _gasTolerance gas tolerance threshold for transactions (for example, 40 gwei)
    constructor(
        address _gasOracle,
        uint256 _gasTolerance
    ) {
        require(_gasTolerance > 0, "invalid gasTolerance");

        gasTolerance = _gasTolerance;
        gasOracle = _gasOracle;

        emit DeployGasChecker(
            msg.sender,
            _gasOracle,
            _gasTolerance
        );
    }

    /// Sets the gas tolerance threshold for transactions
    /// @param _gasTolerance gas tolerance threshold in gwei
    function setGasTolerance(uint256 _gasTolerance) external override onlyOwner {
        require(_gasTolerance > 0, "invalid gasTolerance");
        gasTolerance = _gasTolerance;
        emit SetGasTolerance(msg.sender, _gasTolerance);
    }

    function checkGas() override external view
        returns (int256 gas)
    {
        gas = AggregatorInterface(gasOracle).latestAnswer();
    }

    function isGasAcceptable() override external view
        returns (bool isAcceptable)
    {
        int256 gas = AggregatorInterface(gasOracle).latestAnswer();
        isAcceptable = uint256(gas) <= gasTolerance * 10 ** 9;
    }

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
pragma solidity ^0.7.6;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IGasChecker {

    function gasOracle() external view returns(address);
    function gasTolerance() external view returns(uint256);
    function checkGas() external view returns(int256);
    function isGasAcceptable() external view returns(bool);

    function setGasTolerance(uint256 _gasTolerance) external;

    event DeployGasChecker(
        address indexed sender,
        address gasOracle, 
        uint256 gasTolerance
    );

    event SetGasTolerance(
        address indexed sender, 
        uint256 gasTolerance
    );
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