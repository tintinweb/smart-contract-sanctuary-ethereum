// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title PoS V2 Factory
/// @author Stephen Chen

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-0.8/access/Ownable.sol";

import "./PoSV2Factory.sol";
import "./PoSV2Impl.sol";

contract PoSV2FactoryImpl is Ownable, PoSV2Factory {
    /// @param _ctsiAddress address of token instance being used
    /// @param _stakingAddress address of StakingInterface
    /// @param _workerAuthAddress address of worker manager contract
    /// @param _difficultyAdjustmentParameter how quickly the difficulty gets updated
    /// @param _targetInterval how often we want to elect a block producer
    /// @param _rewardValue reward that reward manager contract pays
    /// @param _rewardDelay number of blocks confirmation before a reward can be claimed
    /// @param _version protocol version of PoS
    function createNewChain(
        address _ctsiAddress,
        address _stakingAddress,
        address _workerAuthAddress,
        // DifficultyManager constructor parameters
        uint128 _initialDifficulty,
        uint64 _minDifficulty,
        uint32 _difficultyAdjustmentParameter,
        uint32 _targetInterval,
        // RewardManager constructor parameters
        uint256 _rewardValue,
        uint32 _rewardDelay,
        uint32 _version
    ) external override onlyOwner returns (address) {
        PoSV2Impl pos = new PoSV2Impl(
            _ctsiAddress,
            _stakingAddress,
            _workerAuthAddress,
            _initialDifficulty,
            _minDifficulty,
            _difficultyAdjustmentParameter,
            _targetInterval,
            _rewardValue,
            _rewardDelay,
            _version
        );

        emit NewChain(
            address(pos),
            _ctsiAddress,
            _stakingAddress,
            _workerAuthAddress,
            _initialDifficulty,
            _minDifficulty,
            _difficultyAdjustmentParameter,
            _targetInterval,
            _rewardValue,
            _rewardDelay,
            _version
        );

        pos.transferOwnership(msg.sender);

        return address(pos);
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

// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity >=0.8.0;

interface PoSV2Factory {
    /// @notice Creates a new chain pos contract
    /// emits NewChain with the parameters of the new chain
    /// @return new chain address
    function createNewChain(
        address _ctsiAddress,
        address _stakingAddress,
        address _workerAuthAddress,
        uint128 _initialDifficulty,
        uint64 _minDifficulty,
        uint32 _difficultyAdjustmentParameter,
        uint32 _targetInterval,
        uint256 _rewardValue,
        uint32 _rewardDelay,
        uint32 _version
    ) external returns (address);

    /// @notice Event emmited when a new chain is created
    /// @param pos address of the new chain
    event NewChain(
        address indexed pos,
        address ctsiAddress,
        address stakingAddress,
        address workerAuthAddress,
        uint128 initialDifficulty,
        uint64 minDifficulty,
        uint32 difficultyAdjustmentParameter,
        uint32 targetInterval,
        uint256 rewardValue,
        uint32 rewardDelay,
        uint32 version
    );
}

// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Proof of Stake V2
/// @author Stephen Chen

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "@cartesi/util/contracts/IWorkerAuthManager.sol";

import "./IPoSV2.sol";
import "./DifficultyManagerImpl.sol";
import "./EligibilityCalImpl.sol";
import "./HistoricalDataImpl.sol";
import "./RewardManagerV2Impl.sol";
import "../IStaking.sol";

contract PoSV2Impl is
    IPoSV2,
    Ownable,
    DifficultyManagerImpl,
    EligibilityCalImpl,
    HistoricalDataImpl
{
    uint32 public immutable version;
    IStaking public immutable staking;
    RewardManagerV2Impl public immutable rewardManager;
    IWorkerAuthManager public immutable workerAuth;
    address public immutable factory;

    bool public active;

    /// @param _ctsiAddress address of token instance being used
    /// @param _stakingAddress address of StakingInterface
    /// @param _workerAuthAddress address of worker manager contract
    /// @param _difficultyAdjustmentParameter how quickly the difficulty gets updated
    /// @param _targetInterval how often we want to elect a block producer
    /// @param _rewardValue reward that reward manager contract pays
    /// @param _rewardDelay number of blocks confirmation before a reward can be claimed
    /// @param _version protocol version of PoS
    constructor(
        address _ctsiAddress,
        address _stakingAddress,
        address _workerAuthAddress,
        // DifficultyManager constructor parameters
        uint128 _initialDifficulty,
        uint64 _minDifficulty,
        uint32 _difficultyAdjustmentParameter,
        uint32 _targetInterval,
        // RewardManager constructor parameters
        uint256 _rewardValue,
        uint32 _rewardDelay,
        uint32 _version
    )
        DifficultyManagerImpl(
            _initialDifficulty,
            _minDifficulty,
            _difficultyAdjustmentParameter,
            _targetInterval
        )
    {
        factory = msg.sender;
        version = _version;
        staking = IStaking(_stakingAddress);
        workerAuth = IWorkerAuthManager(_workerAuthAddress);

        rewardManager = new RewardManagerV2Impl(
            _ctsiAddress,
            address(this),
            _rewardValue,
            _rewardDelay
        );

        active = true;
        historicalCtx.latestCtx.ethBlockStamp = uint32(block.number);
    }

    // legacy methods from V1 chains for staking pool V1 compatibility
    /// @notice Produce a block in V1 chains
    /// @dev this function can only be called by a worker, user never calls it directly
    function produceBlock(uint256) external returns (bool) {
        require(version == 1, "protocol has to be V1");

        address user = _produceBlock();

        uint32 sidechainBlockNumber = historicalCtx
            .latestCtx
            .sidechainBlockCount;

        emit BlockProduced(user, msg.sender, sidechainBlockNumber, "");

        HistoricalDataImpl.updateLatest(user, sidechainBlockNumber + 1);
        rewardManager.reward(sidechainBlockNumber, user);

        return true;
    }

    /// @notice Produce a block in V2 chains
    /// @param _parent the parent block that current block appends to
    /// @param _data the data to store in the block
    /// @dev this function can only be called by a worker, user never calls it directly
    function produceBlock(uint32 _parent, bytes calldata _data)
        external
        override
        returns (bool)
    {
        require(version == 2, "protocol has to be V2");

        address user = _produceBlock();

        emit BlockProduced(
            user,
            msg.sender,
            uint32(
                HistoricalDataImpl.recordBlock(
                    _parent,
                    user,
                    keccak256(abi.encodePacked(_data))
                )
            ),
            _data
        );

        return true;
    }

    /// @notice Check if address is allowed to produce block
    function canProduceBlock(address _user)
        external
        view
        override
        returns (bool)
    {
        return
            EligibilityCalImpl.canProduceBlock(
                difficulty,
                historicalCtx.latestCtx.ethBlockStamp,
                _user,
                staking.getStakedBalance(_user)
            );
    }

    /// @notice Get when _user is allowed to produce a sidechain block
    /// @return uint256 mainchain block number when the user can produce a sidechain block
    function whenCanProduceBlock(address _user)
        external
        view
        override
        returns (uint256)
    {
        return
            EligibilityCalImpl.whenCanProduceBlock(
                difficulty,
                historicalCtx.latestCtx.ethBlockStamp,
                _user,
                staking.getStakedBalance(_user)
            );
    }

    function getSelectionBlocksPassed() external view returns (uint256) {
        return
            EligibilityCalImpl.getSelectionBlocksPassed(
                historicalCtx.latestCtx.ethBlockStamp
            );
    }

    // legacy methods from V1 chains for staking pool V1 compatibility
    /// @notice Get reward manager address
    /// @return address of instance's RewardManager
    function getRewardManagerAddress(uint256) external view returns (address) {
        return address(rewardManager);
    }

    function terminate() external override onlyOwner {
        require(
            rewardManager.getCurrentReward() == 0,
            "RewardManager still holds funds"
        );

        active = false;
    }

    function _produceBlock() internal returns (address) {
        require(
            workerAuth.isAuthorized(msg.sender, factory) ||
                workerAuth.isAuthorized(msg.sender, address(this)),
            "msg.sender is not authorized"
        );

        address user = workerAuth.getOwner(msg.sender);
        uint32 ethBlockStamp = historicalCtx.latestCtx.ethBlockStamp;

        require(
            EligibilityCalImpl.canProduceBlock(
                difficulty,
                ethBlockStamp,
                user,
                staking.getStakedBalance(user)
            ),
            "User couldnt produce a block"
        );

        // difficulty
        DifficultyManagerImpl.adjustDifficulty(block.number - ethBlockStamp);

        return user;
    }
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

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title WorkerAuthManager
/// @author Danilo Tuler
pragma solidity >=0.7.0;

interface IWorkerAuthManager {
    /// @notice Gives worker permission to act on a DApp
    /// @param _workerAddress address of the worker node to given permission
    /// @param _dappAddress address of the dapp that permission will be given to
    function authorize(address _workerAddress, address _dappAddress) external;

    /// @notice Removes worker's permission to act on a DApp
    /// @param _workerAddress address of the proxy that will lose permission
    /// @param _dappAddresses addresses of dapps that will lose permission
    function deauthorize(address _workerAddress, address _dappAddresses) external;

    /// @notice Returns is the dapp is authorized to be called by that worker
    /// @param _workerAddress address of the worker
    /// @param _dappAddress address of the DApp
    function isAuthorized(address _workerAddress, address _dappAddress) external view returns (bool);

    /// @notice Get the owner of the worker node
    /// @param workerAddress address of the worker node
    function getOwner(address workerAddress) external view returns (address);

    /// @notice A DApp has been authorized by a user for a worker
    event Authorization(address indexed user, address indexed worker, address indexed dapp);

    /// @notice A DApp has been deauthorized by a user for a worker
    event Deauthorization(address indexed user, address indexed worker, address indexed dapp);
}

// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Interface PoSV2

pragma solidity >=0.8.0;

interface IPoSV2 {
    event BlockProduced(
        address indexed user,
        address indexed worker,
        uint32 sidechainBlockNumber,
        bytes data
    );

    /// @notice Produce a block in V2 chains
    /// @param _parent the parent block that current block appends to
    /// @param _data the data to store in the block
    /// @dev this function can only be called by a worker, user never calls it directly
    function produceBlock(uint32 _parent, bytes calldata _data)
        external
        returns (bool);

    /// @notice Check if address is allowed to produce block
    function canProduceBlock(address _user) external view returns (bool);

    /// @notice Get when _user is allowed to produce a sidechain block
    /// @return uint256 mainchain block number when the user can produce a sidechain block
    function whenCanProduceBlock(address _user) external view returns (uint256);

    function terminate() external;
}

// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Block Selector V2 Implementation

pragma solidity ^0.8.0;

import "./Difficulty.sol";
import "./abstracts/ADifficultyManager.sol";

contract DifficultyManagerImpl is ADifficultyManager {
    // lower bound for difficulty
    uint64 immutable minDifficulty;
    // 4 bytes constants
    // how fast the difficulty gets adjusted to reach the desired interval, number * 1000000
    uint32 immutable difficultyAdjustmentParameter;
    // desired block selection interval in ethereum blocks
    uint32 immutable targetInterval;
    // difficulty parameter defines how big the interval will be
    uint256 difficulty;

    constructor(
        uint128 _initialDifficulty,
        uint64 _minDifficulty,
        uint32 _difficultyAdjustmentParameter,
        uint32 _targetInterval
    ) {
        minDifficulty = _minDifficulty;
        difficulty = _initialDifficulty;
        difficultyAdjustmentParameter = _difficultyAdjustmentParameter;
        targetInterval = _targetInterval;
    }

    /// @notice Adjust difficulty based on new block production
    function adjustDifficulty(uint256 _blockPassed) internal override {
        difficulty = Difficulty.getNewDifficulty(
            minDifficulty,
            difficulty,
            difficultyAdjustmentParameter,
            targetInterval,
            _blockPassed
        );

        emit DifficultyUpdated(difficulty);
    }
}

// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Eligibility Calculator Implementation

pragma solidity ^0.8.0;

import "./Eligibility.sol";
import "./abstracts/AEligibilityCal.sol";

contract EligibilityCalImpl is AEligibilityCal {
    /// @notice Check if address is allowed to produce block
    /// @param _user the address that is gonna get checked
    /// @param _weight number that will weight the random number, most likely will be the number of staked tokens
    function canProduceBlock(
        uint256 _difficulty,
        uint256 _ethBlockStamp,
        address _user,
        uint256 _weight
    ) internal view override returns (bool) {
        return
            block.number >=
            Eligibility.whenCanProduceBlock(
                _difficulty,
                _ethBlockStamp,
                _user,
                _weight
            );
    }

    /// @notice Check when address is allowed to produce block
    /// @param _user the address that is gonna get checked
    /// @param _weight number that will weight the random number, most likely will be the number of staked tokens
    function whenCanProduceBlock(
        uint256 _difficulty,
        uint256 _ethBlockStamp,
        address _user,
        uint256 _weight
    ) internal view override returns (uint256) {
        return
            Eligibility.whenCanProduceBlock(
                _difficulty,
                _ethBlockStamp,
                _user,
                _weight
            );
    }

    function getSelectionBlocksPassed(uint256 _ethBlockStamp)
        internal
        view
        override
        returns (uint256)
    {
        return Eligibility.getSelectionBlocksPassed(_ethBlockStamp);
    }
}

// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title HistoricalData

pragma solidity ^0.8.0;

import "@cartesi/tree/contracts/Tree.sol";
import "./abstracts/AHistoricalData.sol";

contract HistoricalDataImpl is AHistoricalData {
    using Tree for Tree.TreeCtx;

    struct LatestCtx {
        address lastProducer;
        uint32 ethBlockStamp;
        uint32 sidechainBlockCount;
    }

    struct HistoricalCtx {
        Tree.TreeCtx tree;
        LatestCtx latestCtx;
        mapping(uint256 => BlockData) blockData;
    }

    HistoricalCtx historicalCtx;

    /// @notice Get mainchain block number of last sidechain block
    function getEthBlockStamp() external view override returns (uint256) {
        return historicalCtx.latestCtx.ethBlockStamp;
    }

    /// @notice Get the producer of last sidechain block
    function getLastProducer() external view override returns (address) {
        return historicalCtx.latestCtx.lastProducer;
    }

    /// @notice Get sidechain block count
    function getSidechainBlockCount() external view override returns (uint256) {
        return historicalCtx.latestCtx.sidechainBlockCount;
    }

    /// @notice Get a V2 sidechain block
    function getSidechainBlock(uint256 _number)
        external
        view
        override
        returns (BlockData memory)
    {
        return historicalCtx.blockData[_number];
    }

    /// @notice Validate a V2 sidechain block
    /// @param _sidechainBlockNumber the sidechain block number to validate
    /// @param _depthDiff the minimal depth diff to validate sidechain block
    /// @return bool is the sidechain block valid
    /// @return address the producer of the sidechain block
    function isValidBlock(uint32 _sidechainBlockNumber, uint32 _depthDiff)
        external
        view
        override
        returns (bool, address)
    {
        uint256 blockDepth = historicalCtx.tree.getDepth(_sidechainBlockNumber);
        (uint256 deepestBlock, uint256 deepestDepth) = historicalCtx
            .tree
            .getDeepest();

        if (
            historicalCtx.tree.getAncestorAtDepth(deepestBlock, blockDepth) !=
            _sidechainBlockNumber
        ) {
            return (false, address(0));
        } else if (deepestDepth - blockDepth >= _depthDiff) {
            return (
                true,
                historicalCtx.blockData[_sidechainBlockNumber].producer
            );
        } else {
            return (false, address(0));
        }
    }

    /// @notice Record block data produced from PoS contract
    /// @param _parent the parent block that current block appends to
    /// @param _producer the producer of the sidechain block
    /// @param _dataHash hash of the data held by the block
    function recordBlock(
        uint256 _parent,
        address _producer,
        bytes32 _dataHash
    ) internal override returns (uint256) {
        uint256 sidechainBlockNumber = historicalCtx.tree.insertVertex(_parent);

        historicalCtx.blockData[sidechainBlockNumber] = BlockData(
            _producer,
            uint32(block.number),
            _dataHash
        );

        updateLatest(_producer, sidechainBlockNumber + 1);

        return sidechainBlockNumber;
    }

    /// @notice Record information about the latest sidechain block
    /// @param _producer the producer of the sidechain block
    /// @param _sidechainBlockCount count of total sidechain blocks
    function updateLatest(address _producer, uint256 _sidechainBlockCount)
        internal
        virtual
        override
    {
        historicalCtx.latestCtx = LatestCtx(
            _producer,
            uint32(block.number),
            uint32(_sidechainBlockCount)
        );
    }
}

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title RewardManager V2
/// @author Stephen Chen

pragma solidity ^0.8.0;

import "@cartesi/util/contracts/Bitmask.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/utils/SafeERC20.sol";

import "./IHistoricalData.sol";
import "./IRewardManagerV2.sol";

contract RewardManagerV2Impl is IRewardManagerV2 {
    using Bitmask for mapping(uint256 => uint256);
    using SafeERC20 for IERC20;

    mapping(uint256 => uint256) internal rewarded;
    uint256 immutable rewardValue;
    uint32 immutable rewardDelay;
    IERC20 immutable ctsi;
    address public immutable pos;

    /// @notice Creates contract
    /// @param _ctsiAddress address of token instance being used
    /// @param _posAddress address of the sidechain
    /// @param _rewardValue reward that this contract pays
    /// @param _rewardDelay number of blocks confirmation before a reward can be claimed
    constructor(
        address _ctsiAddress,
        address _posAddress,
        uint256 _rewardValue,
        uint32 _rewardDelay
    ) {
        ctsi = IERC20(_ctsiAddress);
        //slither-disable-next-line  missing-zero-check
        pos = _posAddress;

        rewardValue = _rewardValue;
        rewardDelay = _rewardDelay;
    }

    /// @notice Rewards sidechain block for V1 chains
    /// @param _sidechainBlockNumber sidechain block number
    /// @param _address address to be rewarded
    function reward(uint32 _sidechainBlockNumber, address _address) external {
        require(msg.sender == pos, "Only the pos contract can call");

        uint256 cReward = currentReward();

        emit Rewarded(_sidechainBlockNumber, cReward);

        ctsi.safeTransfer(_address, cReward);
    }

    /// @notice Rewards sidechain blocks for V2 chains
    /// @param _sidechainBlockNumbers array of sidechain block numbers
    function reward(uint32[] calldata _sidechainBlockNumbers)
        external
        override
    {
        for (uint256 i = 0; i < _sidechainBlockNumbers.length; ) {
            require(
                !rewarded.getBit(_sidechainBlockNumbers[i]),
                "The block has been rewarded"
            );

            //slither-disable-next-line  calls-loop
            (bool isValid, address producer) = IHistoricalData(pos)
                .isValidBlock(_sidechainBlockNumbers[i], rewardDelay);

            require(isValid, "Invalid block");

            uint256 cReward = currentReward();

            require(cReward > 0, "RewardManager has no funds");

            emit Rewarded(_sidechainBlockNumbers[i], cReward);

            ctsi.safeTransfer(producer, cReward);
            setRewarded(_sidechainBlockNumbers[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Get RewardManager's balance
    function getBalance() external view override returns (uint256) {
        return balance();
    }

    /// @notice Get current reward amount
    function getCurrentReward() external view override returns (uint256) {
        return currentReward();
    }

    /// @notice Check if a sidechain block reward is claimed
    function isRewarded(uint32 _sidechainBlockNumber)
        external
        view
        override
        returns (bool)
    {
        return rewarded.getBit(_sidechainBlockNumber);
    }

    function setRewarded(uint32 _sidechainBlockNumber) private {
        rewarded.setBit(_sidechainBlockNumber, true);
    }

    function balance() private view returns (uint256) {
        //slither-disable-next-line  calls-loop
        return ctsi.balanceOf(address(this));
    }

    function currentReward() private view returns (uint256) {
        return rewardValue > balance() ? balance() : rewardValue;
    }
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Interface Staking
pragma solidity >=0.7.0 <0.9.0;

interface IStaking {
    /// @notice Returns total amount of tokens counted as stake
    /// @param _userAddress user to retrieve staked balance from
    /// @return finalized staked of _userAddress
    function getStakedBalance(address _userAddress)
        external
        view
        returns (uint256);

    /// @notice Returns the timestamp when next deposit can be finalized
    /// @return timestamp of when finalizeStakes() is callable
    function getMaturingTimestamp(address _userAddress)
        external
        view
        returns (uint256);

    /// @notice Returns the timestamp when next withdraw can be finalized
    /// @return timestamp of when finalizeWithdraw() is callable
    function getReleasingTimestamp(address _userAddress)
        external
        view
        returns (uint256);

    /// @notice Returns the balance waiting/ready to be matured
    /// @return amount that will get staked after finalization
    function getMaturingBalance(address _userAddress)
        external
        view
        returns (uint256);

    /// @notice Returns the balance waiting/ready to be released
    /// @return amount that will get withdrew after finalization
    function getReleasingBalance(address _userAddress)
        external
        view
        returns (uint256);

    /// @notice Deposit CTSI to be staked. The money will turn into staked
    ///         balance after timeToStake days
    /// @param _amount The amount of tokens that are gonna be deposited.
    function stake(uint256 _amount) external;

    /// @notice Remove tokens from staked balance. The money can
    ///         be released after timeToRelease seconds, if the
    ///         function withdraw is called.
    /// @param _amount The amount of tokens that are gonna be unstaked.
    function unstake(uint256 _amount) external;

    /// @notice Transfer tokens to user's wallet.
    /// @param _amount The amount of tokens that are gonna be transferred.
    function withdraw(uint256 _amount) external;

    // events
    /// @notice CTSI tokens were deposited, they count as stake after _maturationDate
    /// @param user address of msg.sender
    /// @param amount amount deposited for staking
    /// @param maturationDate date when the stake can be finalized
    event Stake(address indexed user, uint256 amount, uint256 maturationDate);

    /// @notice Unstake tokens, moving them to releasing structure
    /// @param user address of msg.sender
    /// @param amount amount of tokens to be released
    /// @param maturationDate date when the tokens can be withdrew
    event Unstake(address indexed user, uint256 amount, uint256 maturationDate);

    /// @notice Withdraw process was finalized
    /// @param user address of msg.sender
    /// @param amount amount of tokens withdrawn
    event Withdraw(address indexed user, uint256 amount);
}

// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Difficulty Library

pragma solidity ^0.8.0;

library Difficulty {
    uint32 constant ADJUSTMENT_BASE = 1e6; // 1M

    /// @notice Calculates new difficulty parameter
    function getNewDifficulty(
        uint256 _minDifficulty,
        uint256 _difficulty,
        uint256 _difficultyAdjustmentParameter,
        uint256 _targetInterval,
        uint256 _blocksPassed
    ) external pure returns (uint256) {
        uint256 adjustment = (_difficulty * _difficultyAdjustmentParameter) /
            ADJUSTMENT_BASE +
            1;

        // @dev to save gas on evaluation, instead of returning the _oldDiff when the target
        // was exactly matched - we increase the difficulty.
        if (_blocksPassed <= _targetInterval) {
            return _difficulty + adjustment;
        }

        uint256 newDiff = _difficulty - adjustment;

        return newDiff > _minDifficulty ? newDiff : _minDifficulty;
    }
}

// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Abstract Difficulty Manager

pragma solidity ^0.8.0;

abstract contract ADifficultyManager {
    event DifficultyUpdated(uint256 difficulty);

    /// @notice Adjust difficulty based on new block production
    function adjustDifficulty(uint256 _blockPassed) internal virtual;
}

// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Block Selector Library

pragma solidity ^0.8.0;

import "@cartesi/util/contracts/UnrolledCordic.sol";

library Eligibility {
    uint256 constant C_40 = 40; // 40 blocks
    uint256 constant C_256 = 256; // 256 blocks
    uint256 constant DIFFICULTY_BASE_MULTIPLIER = 256 * 1e18; //256 M
    uint256 constant UINT256_MAX = 2**256 - 1;

    /// @notice Check when address is allowed to produce block
    /// @param _ethBlockStamp ethereum block number when current selection started
    /// @param _difficulty ethereum block number when current selection started
    /// @param _user the address that is gonna get checked
    /// @param _weight number that will weight the random number, most likely will be the number of staked tokens
    function whenCanProduceBlock(
        uint256 _difficulty,
        uint256 _ethBlockStamp,
        address _user,
        uint256 _weight
    ) external view returns (uint256) {
        // cannot produce if block selector goal hasnt been decided yet
        // goal is defined the block after selection was reset
        // cannot produce if weight is zero
        //slither-disable-next-line  incorrect-equality
        if (getSelectionBlocksPassed(_ethBlockStamp) == 0 || _weight == 0) {
            return UINT256_MAX;
        }

        uint256 multiplier = 0;
        // we want overflow and underflow on purpose
        unchecked {
            multiplier =
                DIFFICULTY_BASE_MULTIPLIER -
                getLogOfRandom(_user, _ethBlockStamp);
        }

        uint256 blocksToWait = (_difficulty * multiplier) / (_weight * 1e12);

        unchecked {
            return blocksToWait + _ethBlockStamp + C_40;
        }
    }

    /// @notice Calculates the log of the random number between the goal and callers address
    /// @param _user address to calculate log of random
    /// @param _ethBlockStamp main chain block number of last sidechain block
    /// @return log of random number between goal and callers address * 1M
    function getLogOfRandom(address _user, uint256 _ethBlockStamp)
        internal
        view
        returns (uint256)
    {
        // seed for goal takes a block in the future (+40) so it is harder to manipulate
        bytes32 currentGoal = blockhash(getSeed(_ethBlockStamp + C_40));
        bytes32 hashedAddress = keccak256(abi.encodePacked(_user));
        uint256 distance = uint256(
            keccak256(abi.encodePacked(hashedAddress, currentGoal))
        );

        return UnrolledCordic.log2Times1e18(distance);
    }

    function getSeed(uint256 _previousTarget) internal view returns (uint256) {
        uint256 diff = block.number - _previousTarget;
        //slither-disable-next-line  divide-before-multiply
        uint256 res = diff / C_256;

        // if difference is multiple of 256 (256, 512, 1024)
        // preserve old target
        //slither-disable-next-line  incorrect-equality
        if (diff % C_256 == 0) {
            return _previousTarget + ((res - 1) * C_256);
        }

        //slither-disable-next-line  divide-before-multiply
        return _previousTarget + (res * C_256);
    }

    /// @notice Returns the duration in blocks of current selection proccess
    /// @param _ethBlockStamp ethereum block number of last sidechain block
    /// @return number of ethereum blocks passed since last selection goal was defined
    /// @dev blocks passed resets when target resets
    function getSelectionBlocksPassed(uint256 _ethBlockStamp)
        internal
        view
        returns (uint256)
    {
        unchecked {
            // new goal block is decided 40 blocks after sidechain block is created
            uint256 goalBlock = _ethBlockStamp + C_40;

            // target hasnt been set
            if (goalBlock >= block.number) return 0;

            uint256 blocksPassed = block.number - goalBlock;

            // if blocksPassed is multiple of 256, 256 blocks have passed
            // this avoids blocksPassed going to zero right before target change
            //slither-disable-next-line  incorrect-equality
            if (blocksPassed % C_256 == 0) return C_256;

            return blocksPassed % C_256;
        }
    }
}

// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Abstract Eligibility Calculator

pragma solidity ^0.8.0;

abstract contract AEligibilityCal {
    /// @notice Check if _user is allowed to produce a sidechain block
    /// @param _ethBlockStamp ethereum block number when current selection started
    /// @param _difficulty ethereum block number when current selection started
    /// @param _user the address that is gonna get checked
    /// @param _weight number that will weight the random number, most likely will be the number of staked tokens
    function canProduceBlock(
        uint256 _difficulty,
        uint256 _ethBlockStamp,
        address _user,
        uint256 _weight
    ) internal view virtual returns (bool);

    /// @notice Get when _user is allowed to produce a sidechain block
    /// @param _ethBlockStamp ethereum block number when current selection started
    /// @param _difficulty ethereum block number when current selection started
    /// @param _user the address that is gonna get checked
    /// @param _weight number that will weight the random number, most likely will be the number of staked tokens
    /// @return uint256 mainchain block number when the user can produce a sidechain block
    function whenCanProduceBlock(
        uint256 _difficulty,
        uint256 _ethBlockStamp,
        address _user,
        uint256 _weight
    ) internal view virtual returns (uint256);

    /// @notice Returns the duration in blocks of current selection proccess
    /// @param _ethBlockStamp ethereum block number of last sidechain block
    /// @return number of ethereum blocks passed since last selection goal was defined
    function getSelectionBlocksPassed(uint256 _ethBlockStamp)
        internal
        view
        virtual
        returns (uint256);
}

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

///@title UnrolledCordic.sol
///@author Gabriel Barros, Diego Nehab
pragma solidity ^0.8.0;

library UnrolledCordic {
    uint256 constant one = 0x8000000000000000000000000000000000000000000000000000000000000000;
    uint256 constant log2_e = 0xb8aa3b295c17f0bbbe87fed0691d3e88eb577aa8dd695a588b25166cd1a13248;

    uint64 constant N = 64;
    uint256 constant log2_ks0 = 0xb31fb7d64898b3e15c01a39fbd687a02934f0979a3715fd4ae00d1cfdeb43d0;
    uint256 constant log2_ks1 = 0xb84e236bd563ba016fe50b6ef0851802dcf2d0b85a453105aeb4dd63bf61cc;
    uint256 constant log2_ks2 = 0xb8a476150dfe4001713d62f7957c3002e24ca6e87e8a8005c3e0ffc29d593;
    uint256 constant log2_ks3 = 0xb8a9ded47c110001715305002e4b0002e2a32762fa6c0005c53ac47e94d9;
    uint256 constant log2_ks4 = 0xb8aa35640a80000171545f3d72b00002e2a8905062300005c55067f6e59;
    uint256 constant log2_ks5 = 0xb8aa3acd07000001715474e164000002e2a8e6e01f000005c551c2359a;

    function log2m64(uint256 x) internal pure returns (uint256) {
        uint256 y = 0;
        uint256 t;

        unchecked {
            // round(log_2(1+1/2^i)*2^64) for i = 1..4 packed into 64bits each
            t = x + (x >> 1);
            if (t < one) {
                x = t;
                y += log2_ks0 << 192;
            }
            t = x + (x >> 2);
            if (t < one) {
                x = t;
                y += (log2_ks0 >> 64) << 192;
            }
            t = x + (x >> 3);
            if (t < one) {
                x = t;
                y += (log2_ks0 >> 128) << 192;
            }
            t = x + (x >> 4);
            if (t < one) {
                x = t;
                y += (log2_ks0 >> 192) << 192;
            }
            // round(log_2(1+1/2^i)*2^64) for i = 5..8 packed into 64bits each
            t = x + (x >> 5);
            if (t < one) {
                x = t;
                y += log2_ks1 << 192;
            }
            t = x + (x >> 6);
            if (t < one) {
                x = t;
                y += (log2_ks1 >> 64) << 192;
            }
            t = x + (x >> 7);
            if (t < one) {
                x = t;
                y += (log2_ks1 >> 128) << 192;
            }
            t = x + (x >> 8);
            if (t < one) {
                x = t;
                y += (log2_ks1 >> 192) << 192;
            }
            // round(log_2(1+1/2^i)*2^64) for i = 9..12 packed into 64bits each
            t = x + (x >> 9);
            if (t < one) {
                x = t;
                y += log2_ks2 << 192;
            }
            t = x + (x >> 10);
            if (t < one) {
                x = t;
                y += (log2_ks2 >> 64) << 192;
            }
            t = x + (x >> 11);
            if (t < one) {
                x = t;
                y += (log2_ks2 >> 128) << 192;
            }
            t = x + (x >> 12);
            if (t < one) {
                x = t;
                y += (log2_ks2 >> 192) << 192;
            }
            // round(log_2(1+1/2^i)*2^64) for i = 13..16 packed into 64bits each
            t = x + (x >> 13);
            if (t < one) {
                x = t;
                y += log2_ks3 << 192;
            }
            t = x + (x >> 14);
            if (t < one) {
                x = t;
                y += (log2_ks3 >> 64) << 192;
            }
            t = x + (x >> 15);
            if (t < one) {
                x = t;
                y += (log2_ks3 >> 128) << 192;
            }
            t = x + (x >> 16);
            if (t < one) {
                x = t;
                y += (log2_ks3 >> 192) << 192;
            }
            // round(log_2(1+1/2^i)*2^64) for i = 17..20 packed into 64bits each
            t = x + (x >> 17);
            if (t < one) {
                x = t;
                y += log2_ks4 << 192;
            }
            t = x + (x >> 18);
            if (t < one) {
                x = t;
                y += (log2_ks4 >> 64) << 192;
            }
            t = x + (x >> 19);
            if (t < one) {
                x = t;
                y += (log2_ks4 >> 128) << 192;
            }
            t = x + (x >> 20);
            if (t < one) {
                x = t;
                y += (log2_ks4 >> 192) << 192;
            }
            // round(log_2(1+1/2^i)*2^64) for i = 21..24 packed into 64bits each
            t = x + (x >> 21);
            if (t < one) {
                x = t;
                y += log2_ks5 << 192;
            }
            t = x + (x >> 22);
            if (t < one) {
                x = t;
                y += (log2_ks5 >> 64) << 192;
            }
            t = x + (x >> 23);
            if (t < one) {
                x = t;
                y += (log2_ks5 >> 128) << 192;
            }
            t = x + (x >> 24);
            if (t < one) {
                x = t;
                y += (log2_ks5 >> 192) << 192;
            }

            uint256 r = one - x;
            y += mulhi128(log2_e, mulhi128(r, one + (r >> 1)) << 1) << 1;
            return y >> (255 - 64);
        }
    }

    function log2Times1e18(uint256 val) external pure returns (uint256) {
        int256 il = ilog2(val);
        uint256 skewedRes;
        unchecked {
            if (il + 1 <= 255) {
                skewedRes = (uint256(il + 1) << N) - log2m64(val << (255 - uint256(il + 1)));
            } else {
                skewedRes = (uint256(il + 1) << N) - log2m64(val >> uint256((il + 1) - 255));
            }
            return (skewedRes * 1e18) >> N;
        }
    }

    function mulhi128(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return (a >> 128) * (b >> 128);
        }
    }

    function ilog2(uint256 val) internal pure returns (int256) {
        require(val > 0, "must be greater than zero");
        unchecked {
            return 255 - int256(clz(val));
        }
    }

    /// @notice count leading zeros
    /// @param _num number you want the clz of
    /// @dev this a binary search implementation
    function clz(uint256 _num) internal pure returns (uint256) {
        if (_num == 0) return 256;
        unchecked {
            uint256 n = 0;
            if (_num & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000 == 0) {
                n = n + 128;
                _num = _num << 128;
            }
            if (_num & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 == 0) {
                n = n + 64;
                _num = _num << 64;
            }
            if (_num & 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000 == 0) {
                n = n + 32;
                _num = _num << 32;
            }
            if (_num & 0xFFFF000000000000000000000000000000000000000000000000000000000000 == 0) {
                n = n + 16;
                _num = _num << 16;
            }
            if (_num & 0xFF00000000000000000000000000000000000000000000000000000000000000 == 0) {
                n = n + 8;
                _num = _num << 8;
            }
            if (_num & 0xF000000000000000000000000000000000000000000000000000000000000000 == 0) {
                n = n + 4;
                _num = _num << 4;
            }
            if (_num & 0xC000000000000000000000000000000000000000000000000000000000000000 == 0) {
                n = n + 2;
                _num = _num << 2;
            }
            if (_num & 0x8000000000000000000000000000000000000000000000000000000000000000 == 0) {
                n = n + 1;
            }

            return n;
        }
    }
}

// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Tree Library

pragma solidity ^0.8.0;

library Tree {
    // The tree can store up to UINT32_MAX vertices, the type uses uint256 for gas optimization purpose.
    // It's the library caller's responsibility to check the input arguments are within the proper range
    uint256 constant UINT32_MAX = 2**32 - 1;
    // count of trailing ones for [0:256)
    // each number takes one byte
    bytes constant trailing1table =
        hex"00010002000100030001000200010004000100020001000300010002000100050001000200010003000100020001000400010002000100030001000200010006000100020001000300010002000100040001000200010003000100020001000500010002000100030001000200010004000100020001000300010002000100070001000200010003000100020001000400010002000100030001000200010005000100020001000300010002000100040001000200010003000100020001000600010002000100030001000200010004000100020001000300010002000100050001000200010003000100020001000400010002000100030001000200010008";

    struct TreeCtx {
        uint32 deepestVertex;
        uint32 deepestDepth;
        uint32 verticesLength;
        mapping(uint256 => Vertex) vertices;
    }

    struct Vertex {
        uint32 depth; // depth of the vertex in the tree
        uint32 ancestorsLength;
        // Each uint256 value stores 8 ancestors, each takes a uint32 slot,
        // the key used to access the value should be preprocessed,
        // 0 => uint32[7],uint32[6],uint32[5],uint32[4],uint32[3],uint32[2],uint32[1],uint32[0]
        // 1 => uint32[15],uint32[14],uint32[13],uint32[12],uint32[11],uint32[10],uint32[9],uint32[8]
        // A vertex can have up to 32 ancestors
        mapping(uint256 => uint256) ancestors; // pointers to ancestors' indices in the vertices map (tree)
    }

    event VertexInserted(uint256 _parent);

    /// @notice Insert a vertex to the tree
    /// @param _tree pointer to the tree storage
    /// @param _parent the index of parent vertex in the vertices map (tree)
    /// @return index of the inserted vertex
    /// @dev the tree can hold up to UINT32_MAX vertices, if the insertVertex is called when tree is full, the transaction will be reverted
    function insertVertex(TreeCtx storage _tree, uint256 _parent)
        external
        returns (uint256)
    {
        uint256 treeSize = _tree.verticesLength;

        _tree.verticesLength++;
        Vertex storage v = _tree.vertices[treeSize];

        if (treeSize == 0) {
            // insert the very first vertex into the tree
            // v is initialized with zeros already
        } else {
            // insert vertex to the tree attaching to another vertex
            require(_parent < treeSize, "parent index exceeds tree size");

            uint256 parentDepth = _tree.vertices[_parent].depth;

            // construct the ancestors map in batch
            batchSetAncestors(v, parentDepth);
        }

        uint256 depth = v.depth;
        if (depth > _tree.deepestDepth) {
            _tree.deepestDepth = uint32(depth);
            _tree.deepestVertex = uint32(treeSize);
        }

        emit VertexInserted(_parent);

        return treeSize;
    }

    /// @notice Set ancestors in batches, each of which has up to 8 ancestors
    /// @param _v pointer to the vertex storage
    /// @param _parentDepth the parent depth
    function batchSetAncestors(Vertex storage _v, uint256 _parentDepth)
        private
    {
        // calculate all ancestors' depths of the new vertex
        uint256[] memory requiredDepths = getRequiredDepths(_parentDepth + 1);
        uint256 batchPointer; // point to the beginning of a batch

        while (batchPointer < requiredDepths.length) {
            uint256 ancestorsBatch; // stores up to 8 ancestors
            uint256 offset; // 0~8
            while (
                offset < 8 && batchPointer + offset < requiredDepths.length
            ) {
                ancestorsBatch =
                    ancestorsBatch |
                    (requiredDepths[batchPointer + offset] << (offset * 32));

                ++offset;
            }
            _v.ancestors[batchPointer / 8] = ancestorsBatch;

            batchPointer += offset;
        }

        _v.depth = uint32(_parentDepth + 1);
        _v.ancestorsLength = uint32(requiredDepths.length);
    }

    /// @notice Get an ancestor of a vertex from its ancestor cache by offset
    /// @param _tree pointer to the tree storage
    /// @param _vertex the index of the vertex in the vertices map (tree)
    /// @param _ancestorOffset the offset of the ancestor in ancestor cache
    /// @return index of ancestor vertex in the tree
    function getAncestor(
        TreeCtx storage _tree,
        uint256 _vertex,
        uint256 _ancestorOffset
    ) public view returns (uint256) {
        require(
            _vertex < _tree.verticesLength,
            "vertex index exceeds tree size"
        );

        Vertex storage v = _tree.vertices[_vertex];

        require(_ancestorOffset < v.ancestorsLength, "offset exceeds cache size");

        uint256 key = _ancestorOffset / 8;
        uint256 offset = _ancestorOffset % 8;
        uint256 ancestor = (v.ancestors[key] >> (offset * 32)) & 0xffffffff;

        return ancestor;
    }

    /// @notice Search an ancestor of a vertex in the tree at a certain depth
    /// @param _tree pointer to the tree storage
    /// @param _vertex the index of the vertex in the vertices map (tree)
    /// @param _depth the depth of the ancestor
    /// @return index of ancestor at depth of _vertex
    function getAncestorAtDepth(
        TreeCtx storage _tree,
        uint256 _vertex,
        uint256 _depth
    ) external view returns (uint256) {
        require(
            _vertex < _tree.verticesLength,
            "vertex index exceeds tree size"
        );
        require(
            _depth <= _tree.vertices[_vertex].depth,
            "search depth > vertex depth"
        );

        uint256 vertex = _vertex;

        while (_depth != _tree.vertices[vertex].depth) {
            Vertex storage v = _tree.vertices[vertex];
            uint256 ancestorsLength = v.ancestorsLength;
            // start searching from the oldest ancestor (smallest depth)
            // example: search ancestor at depth d(20, b'0001 0100) from vertex v at depth (176, b'1011 0000)
            //    b'1011 0000 -> b'1010 0000 -> b'1000 0000
            // -> b'0100 0000 -> b'0010 0000 -> b'0001 1000
            // -> b'0001 0100

            // given that ancestorsOffset is unsigned, when -1 at 0, it'll underflow and become UINT32_MAX
            // so the continue condition has to be ancestorsOffset < ancestorsLength,
            // can't be ancestorsOffset >= 0
            uint256 temp_v = vertex;
            for (
                uint256 ancestorsOffset = ancestorsLength - 1;
                ancestorsOffset < ancestorsLength;

            ) {
                vertex = getAncestor(_tree, temp_v, ancestorsOffset);

                // stop at the ancestor who's closest to the target depth
                if (_tree.vertices[vertex].depth >= _depth) {
                    break;
                }

                unchecked {
                    --ancestorsOffset;
                }
            }
        }

        return vertex;
    }

    /// @notice Get depth of vertex
    /// @param _tree pointer to the tree storage
    /// @param _vertex the index of the vertex in the vertices map (tree)
    function getDepth(TreeCtx storage _tree, uint256 _vertex)
        external
        view
        returns (uint256)
    {
        return getVertex(_tree, _vertex).depth;
    }

    /// @notice Get vertex from the tree
    /// @param _tree pointer to the tree storage
    /// @param _vertex the index of the vertex in the vertices map (tree)
    function getVertex(TreeCtx storage _tree, uint256 _vertex)
        public
        view
        returns (Vertex storage)
    {
        require(
            _vertex < _tree.verticesLength,
            "vertex index exceeds tree size"
        );

        return _tree.vertices[_vertex];
    }

    /// @notice Get current tree size
    /// @param _tree pointer to the tree storage
    function getTreeSize(TreeCtx storage _tree)
        external
        view
        returns (uint256)
    {
        return _tree.verticesLength;
    }

    /// @notice Get current tree size
    /// @param _tree pointer to the tree storage
    /// @return index number and depth of the deepest vertex
    function getDeepest(TreeCtx storage _tree)
        external
        view
        returns (uint256, uint256)
    {
        return (_tree.deepestVertex, _tree.deepestDepth);
    }

    function getRequiredDepths(uint256 _depth)
        private
        pure
        returns (uint256[] memory)
    {
        // parent is always included in the ancestors
        uint256 depth = _depth - 1;
        uint256 count = 1;

        // algorithm 1
        // get count of trailing ones of _depth from trailing1table
        for (uint256 i = 0; i < 4; ) {
            uint256 partialCount = uint8(
                trailing1table[(depth >> (i * 8)) & 0xff]
            );
            count = count + partialCount;
            if (partialCount != 8) {
                break;
            }

            unchecked {
                ++i;
            }
        }

        // algorithm 2
        // get count of trailing ones by counting them
        // {
        //     while (depth & 1 > 0) {
        //         depth = depth >> 1;
        //         ++count;
        //     }

        //     depth = _depth - 1;
        // }

        uint256[] memory depths = new uint256[](count);

        // construct the depths array by removing the trailing ones from lsb one by one
        // example _depth = b'1100 0000: b'1011 1111 -> b'1011 1110 -> b'1011 1100
        //                            -> b'1011 1000 -> b'1011 0000 -> b'1010 0000
        //                            -> b'1000 0000
        for (uint256 i = 0; i < count; ) {
            depths[i] = depth;
            depth = depth & (UINT32_MAX << (i + 1));

            unchecked {
                ++i;
            }
        }

        return depths;
    }
}

// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Abstract HistoricalData

pragma solidity ^0.8.0;

import "../IHistoricalData.sol";

abstract contract AHistoricalData is IHistoricalData {
    event VertexInserted(uint256 _parent);

    /// @notice Record block data produced from PoS contract
    /// @param _parent the parent block that current block appends to
    /// @param _producer the producer of the sidechain block
    /// @param _dataHash hash of the data held by the block
    function recordBlock(
        uint256 _parent,
        address _producer,
        bytes32 _dataHash
    ) internal virtual returns (uint256);

    /// @notice Record information about the latest sidechain block
    /// @param _producer the producer of the sidechain block
    /// @param _sidechainBlockCount count of total sidechain blocks
    function updateLatest(
        address _producer,
        uint256 _sidechainBlockCount
    ) internal virtual;
}

// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Interface HistoricalData

pragma solidity >=0.8.0;

interface IHistoricalData {
    struct BlockData {
        address producer;
        uint32 mainchainBlockNumber;
        bytes32 dataHash;
    }

    /// @notice Validate a V2 sidechain block
    /// @param _sidechainBlockNumber the sidechain block number to validate
    /// @param _depthDiff the minimal depth diff to validate sidechain block
    /// @return bool is the sidechain block valid
    /// @return address the producer of the sidechain block
    function isValidBlock(uint32 _sidechainBlockNumber, uint32 _depthDiff)
        external
        view
        returns (bool, address);

    /// @notice Get mainchain block number of last sidechain block
    function getEthBlockStamp() external view returns (uint256);

    /// @notice Get the producer of last sidechain block
    function getLastProducer() external view returns (address);

    /// @notice Get sidechain block count
    function getSidechainBlockCount() external view returns (uint256);

    /// @notice Get a V2 sidechain block
    function getSidechainBlock(uint256)
        external
        view
        returns (BlockData memory);
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.0;

/// @title Bit Mask Library
/// @author Stephen Chen
/// @notice Implements bit mask with dynamic array
library Bitmask {
    /// @notice Set a bit in the bit mask
    function setBit(
        mapping(uint256 => uint256) storage bitmask,
        uint256 _bit,
        bool _value
    ) public {
        // calculate the number of bits has been store in bitmask now
        uint256 positionOfMask = uint256(_bit / 256);
        uint256 positionOfBit = _bit % 256;

        if (_value) {
            bitmask[positionOfMask] =
                bitmask[positionOfMask] |
                (1 << positionOfBit);
        } else {
            bitmask[positionOfMask] =
                bitmask[positionOfMask] &
                ~(1 << positionOfBit);
        }
    }

    /// @notice Get a bit in the bit mask
    function getBit(mapping(uint256 => uint256) storage bitmask, uint256 _bit)
        public
        view
        returns (bool)
    {
        // calculate the number of bits has been store in bitmask now
        uint256 positionOfMask = uint256(_bit / 256);
        uint256 positionOfBit = _bit % 256;

        return ((bitmask[positionOfMask] & (1 << positionOfBit)) != 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Interface RewardManagerV2

pragma solidity >=0.8.0;

interface IRewardManagerV2 {
    event Rewarded(uint32 indexed sidechainBlockNumber, uint256 reward);

    /// @notice Rewards sidechain blocks for V2 chains
    /// @param _sidechainBlockNumbers array of sidechain block numbers
    function reward(uint32[] calldata _sidechainBlockNumbers) external;

    /// @notice Check if a sidechain block reward is claimed
    function isRewarded(uint32 _sidechainBlockNumber)
        external
        view
        returns (bool);

    /// @notice Get RewardManager's balance
    function getBalance() external view returns (uint256);

    /// @notice Get current reward amount
    function getCurrentReward() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}