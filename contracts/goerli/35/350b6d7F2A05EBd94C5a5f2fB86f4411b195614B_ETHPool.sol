/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IETHPool {
    struct Epoch {
        uint128 totalRewards;
        uint128 totalDeposits;
    }

    event AddedRewards(uint256 indexed epoch, uint256 amount);
    event Deposit(address indexed user, uint256 indexed epoch, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
}

error callFailed();
error depositZero();

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

contract ETHPool is IETHPool, Owned {
    ///Current epoch number
    uint256 public currentEpoch;
    ///mapping representing the total amount of deposits of a user per epoch
    ///wallet => epochNumber => amount
    mapping(address => mapping(uint256 => uint256)) public userDeposits;
    //Array of uint256 that represent a struct Epoch(totalRewards, totalDeposits).
    //Left 128 Bits are total rewards. Right 128 Bits are total deposits
    uint256[] public epochs;

    constructor() Owned(msg.sender) {
        //start the epoch
        epochs.push(0);
    }

    //************ * ฅ^•ﻌ•^ฅ  User Interface  ฅ^•ﻌ•^ฅ * ************//

    ///@notice Deposit funds into pool
    function deposit() external payable {
        if (msg.value == 0) revert depositZero();
        uint256 mCurrentEpoch = currentEpoch; //Save 1 sload
        userDeposits[msg.sender][mCurrentEpoch] += msg.value;
        uint256 epochUint = epochs[mCurrentEpoch];
        Epoch memory epoch = _getEpochData(epochUint);
        epoch.totalDeposits += uint128(msg.value);
        epochs[mCurrentEpoch] = _makeEpochStruct(
            epoch.totalRewards,
            epoch.totalDeposits
        );

        emit Deposit(msg.sender, mCurrentEpoch, msg.value);
    }

    /// @notice withdraw deposited amount + rewards
    /// @return totalUserBalance total amount withdrawn including rewards
    function withdraw() external returns (uint256 totalUserBalance) {
        uint256[] memory mEpochs = epochs;
        uint256 totalBalance;
        uint256 len = mEpochs.length;
        for (uint256 i; i < len; ) {
            Epoch memory epoch = _getEpochData(mEpochs[i]);
            uint256 userDeposit = userDeposits[msg.sender][i];
            //Add user deposit on epoch i
            totalUserBalance += userDeposit;
            //Add total deposits on epoch i
            totalBalance += epoch.totalDeposits;
            //Calculate rewards accrued for user on this epoch
            uint256 percent = (totalUserBalance * 1e18);
            if (totalBalance == 0) {
                unchecked {
                    ++i;
                }
                //To avoid division by 0 when not needed
                continue;
            }
            unchecked {
                //divisions can't overflow
                percent /= totalBalance;
            }
            uint256 epochRewards = epoch.totalRewards;
            uint256 userRewards = (epochRewards * percent);
            unchecked {
                //divisions can't overflow
                userRewards /= 1e18;
            }
            //add user rewards
            totalUserBalance += userRewards;
            //add total rewards to balance
            totalBalance += epochRewards;
            //substract user deposits and rewards for updating storage after looping
            epoch.totalRewards -= uint128(userRewards);
            //Write to storage only if user deposited on epoch i;
            if (userDeposit > 0) {
                epoch.totalDeposits -= uint128(userDeposit);
                userDeposits[msg.sender][i] = 0;
            }
            mEpochs[i] = _makeEpochStruct(
                epoch.totalRewards,
                epoch.totalDeposits
            );
            unchecked {
                ++i;
            }
        }

        epochs = mEpochs;
        (bool success, ) = payable(msg.sender).call{value: totalUserBalance}(
            ""
        );
        if (!success) revert callFailed();
        emit Withdraw(msg.sender, totalUserBalance);
    }

    //************ * ฅ^•ﻌ•^ฅ  Only Owner  ฅ^•ﻌ•^ฅ * ************//

    ///@notice Add Rewards to pool
    function addRewards() external payable onlyOwner {
        uint256 mCurrentEpoch = currentEpoch; //Save 1 sload
        uint256 epochUint = epochs[mCurrentEpoch];
        Epoch memory epoch = _getEpochData(epochUint);
        epoch.totalRewards += uint128(msg.value);
        epochs[mCurrentEpoch] = _makeEpochStruct(
            epoch.totalRewards,
            epoch.totalDeposits
        );
        epochs.push(0);
        ++currentEpoch;
        emit AddedRewards(mCurrentEpoch, msg.value);
    }

    //************ * ฅ^•ﻌ•^ฅ  Internal Struct Utils  ฅ^•ﻌ•^ฅ * ************//

    ///@notice convert a uint256 into an Epoch Struct
    ///@param _epoch uint to be converted
    function _getEpochData(uint256 _epoch)
        internal
        pure
        returns (Epoch memory)
    {
        return
            Epoch({
                totalRewards: uint128(_epoch >> 128),
                totalDeposits: uint128(_epoch)
            });
    }

    ///@notice convert epoch data into an epoch uint
    ///@param _totalRewards totalRewards of epoch
    ///@param _totalDeposits totalDeposits of epoch
    function _makeEpochStruct(uint256 _totalRewards, uint256 _totalDeposits)
        internal
        pure
        returns (uint256 epoch)
    {
        epoch = _totalDeposits;
        epoch |= _totalRewards << 128;
    }
}