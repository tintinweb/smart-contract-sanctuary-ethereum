//SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";

pragma solidity >=0.7.0 <0.9.0;

interface ICairoVerifier {
    function isValid(bytes32) external view returns (bool);
}

interface IStreamer {
    function token() external view returns (IERC20);

    function streamToStart(bytes32) external view returns (uint256);

    function withdraw(address from, address to, uint216 amountPerSec) external;

    function getStreamId(
        address from,
        address to,
        uint216 amountPerSec
    ) external view returns (bytes32);
}

contract DebtAllocator is Ownable {
    using SafeERC20 for IERC20;

    uint256 PRECISION = 10 ** 18;

    ICairoVerifier public cairoVerifier = ICairoVerifier(address(0));
    bytes32 public cairoProgramHash = 0x0;

    struct PackedStrategies {
        address[] addresses;
        uint256[] callLen;
        address[] contracts;
        bytes[] checkdata;
        uint256[] offset;
        uint256[] calculationsLen;
        uint256[] calculations;
        uint256[] conditionsLen;
        uint256[] conditions;
    }

    struct StrategyParam {
        uint256 callLen;
        address[] contracts;
        bytes[] checkdata;
        uint256[] offset;
        uint256 calculationsLen;
        uint256[] calculations;
        uint256 conditionsLen;
        uint256[] conditions;
    }

    uint256[] public targetAllocation;

    // Everyone is free to propose a new solution, the address is stored so the user can get rewarded
    address public proposer;
    uint256 public lastUpdate;
    uint256 public strategiesHash;
    uint256 public inputHash;
    mapping(uint256 => uint256) public snapshotTimestamp;

    uint256 public staleSnapshotPeriod = 24 * 3600;

    // Rewards config
    address public rewardsPayer;
    address public rewardsStreamer;
    uint216 public rewardsPerSec;

    // 100% APY = 10^27, minimum increased = 10^23 = 0,01%
    uint256 public minimumApyIncreaseForNewSolution = 100000000000000000000000;

    constructor(address _cairoVerifier, bytes32 _cairoProgramHash) payable {
        updateCairoVerifier(_cairoVerifier);
        updateCairoProgramHash(_cairoProgramHash);
    }

    event StrategyAdded(
        address[] Strategies,
        uint256[] StrategiesCallLen,
        address[] Contracts,
        bytes4[] Checkdata,
        uint256[] Offset,
        uint256[] CalculationsLen,
        uint256[] Calculations,
        uint256[] ConditionsLen,
        uint256[] Conditions
    );
    event StrategyUpdated(
        address[] Strategies,
        uint256[] StrategiesCallLen,
        address[] Contracts,
        bytes4[] Checkdata,
        uint256[] Offset,
        uint256[] CalculationsLen,
        uint256[] Calculations,
        uint256[] ConditionsLen,
        uint256[] Conditions
    );
    event StrategyRemoved(
        address[] Strategies,
        uint256[] StrategiesCallLen,
        address[] Contracts,
        bytes4[] Checkdata,
        uint256[] Offset,
        uint256[] CalculationsLen,
        uint256[] Calculations,
        uint256[] ConditionsLen,
        uint256[] Conditions
    );

    event NewSnapshot(
        uint256[] dataStrategies,
        uint256[] calculation,
        uint256[] condition,
        uint256[] targetAllocations
    );
    event NewSolution(
        uint256 newApy,
        uint256[] newTargetAllocation,
        address proposer,
        uint256 timestamp
    );

    event NewCairoProgramHash(bytes32 newCairoProgramHash);
    event NewCairoVerifier(address newCairoVerifier);
    event NewStalePeriod(uint256 newStalePeriod);
    event NewStaleSnapshotPeriod(uint256 newStaleSnapshotPeriod);
    event targetAllocationForced(uint256[] newTargetAllocation);

    function updateRewardsConfig(
        address _rewardsPayer,
        address _rewardsStreamer,
        uint216 _rewardsPerSec
    ) external onlyOwner {
        bytes32 streamId = IStreamer(_rewardsStreamer).getStreamId(
            _rewardsPayer,
            address(this),
            _rewardsPerSec
        );
        require(
            IStreamer(_rewardsStreamer).streamToStart(streamId) > 0,
            "STREAM"
        );
        rewardsPayer = _rewardsPayer;
        rewardsStreamer = _rewardsStreamer;
        rewardsPerSec = _rewardsPerSec;
    }

    function updateCairoProgramHash(
        bytes32 _cairoProgramHash
    ) public onlyOwner {
        cairoProgramHash = _cairoProgramHash;
        emit NewCairoProgramHash(_cairoProgramHash);
    }

    function updateCairoVerifier(address _cairoVerifier) public onlyOwner {
        cairoVerifier = ICairoVerifier(_cairoVerifier);
        emit NewCairoVerifier(_cairoVerifier);
    }

    function updateStaleSnapshotPeriod(
        uint256 _staleSnapshotPeriod
    ) external onlyOwner {
        staleSnapshotPeriod = _staleSnapshotPeriod;
        emit NewStaleSnapshotPeriod(_staleSnapshotPeriod);
    }

    function forceTargetAllocation(
        uint256[] calldata _newTargetAllocation
    ) public onlyOwner {
        require(strategiesHash != 0, "NO_STRATEGIES");
        require(
            _newTargetAllocation.length == targetAllocation.length,
            "LENGTH"
        );
        for (uint256 j; j < _newTargetAllocation.length; j++) {
            targetAllocation[j] = _newTargetAllocation[j];
        }
        emit targetAllocationForced(_newTargetAllocation);
    }

    function saveSnapshot(
        PackedStrategies calldata _packedStrategies
    ) external {
        // Checks at least one strategy is registered
        require(strategiesHash != 0, "NO_STRATEGIES");

        bytes4[] memory checkdata = castCheckdataToBytes4(
            _packedStrategies.checkdata
        );

        // Checks strategies data is valid
        checkStrategyHash(_packedStrategies, checkdata);

        uint256[] memory dataStrategies = getStrategiesData(
            _packedStrategies.contracts,
            _packedStrategies.checkdata,
            _packedStrategies.offset
        );

        inputHash = uint256(
            keccak256(
                abi.encodePacked(
                    dataStrategies,
                    _packedStrategies.calculations,
                    _packedStrategies.conditions
                )
            )
        );

        snapshotTimestamp[inputHash] = block.timestamp;
        // TODO: do we need current debt in each strategy? (to be able to take into account withdrawals)
        emit NewSnapshot(
            dataStrategies,
            _packedStrategies.calculations,
            _packedStrategies.conditions,
            targetAllocation
        );
    }

    function verifySolution(
        uint256[] calldata programOutput
    ) external returns (bytes32) {
        // NOTE: Check current snapshot not stale
        uint256 _inputHash = inputHash;
        uint256 _snapshotTimestamp = snapshotTimestamp[_inputHash];

        require(
            _snapshotTimestamp + staleSnapshotPeriod > block.timestamp,
            "STALE_SNAPSHOT"
        );

        // NOTE: We get the data from parsing the program output
        (
            uint256 inputHash_,
            uint256[] memory currentTargetAllocation,
            uint256[] memory newTargetAllocation,
            uint256 currentSolution,
            uint256 newSolution
        ) = parseProgramOutput(programOutput);

        // check inputs
        require(inputHash_ == _inputHash, "HASH");

        // check target allocation len
        require(
            targetAllocation.length == currentTargetAllocation.length &&
                targetAllocation.length == newTargetAllocation.length,
            "TARGET_ALLOCATION_LENGTH"
        );

        // check if the new solution better than previous one
        require(
            newSolution - minimumApyIncreaseForNewSolution >= currentSolution,
            "TOO_BAD"
        );

        // Check with cairoVerifier
        bytes32 outputHash = keccak256(abi.encodePacked(programOutput));
        bytes32 fact = keccak256(
            abi.encodePacked(cairoProgramHash, outputHash)
        );

        require(cairoVerifier.isValid(fact), "MISSING_PROOF");

        targetAllocation = newTargetAllocation;
        lastUpdate = block.timestamp;

        sendRewardsToCurrentProposer();
        proposer = msg.sender;

        emit NewSolution(
            newSolution,
            newTargetAllocation,
            msg.sender,
            block.timestamp
        );
        return (fact);
    }

    // =============== REWARDS =================
    function sendRewardsToCurrentProposer() internal {
        IStreamer _rewardsStreamer = IStreamer(rewardsStreamer);
        if (address(_rewardsStreamer) == address(0)) {
            return;
        }
        bytes32 streamId = _rewardsStreamer.getStreamId(
            rewardsPayer,
            address(this),
            rewardsPerSec
        );
        if (_rewardsStreamer.streamToStart(streamId) == 0) {
            // stream does not exist
            return;
        }
        IERC20 _rewardsToken = IERC20(_rewardsStreamer.token());
        // NOTE: if the stream does not have enough to pay full amount, it will pay less than expected
        // WARNING: if this happens and the proposer is changed, the old proposer will lose the rewards
        // TODO: create a way to ensure previous proposer gets the rewards even when payers balance is not enough (by saving how much he's owed)
        _rewardsStreamer.withdraw(rewardsPayer, address(this), rewardsPerSec);
        uint256 rewardsBalance = _rewardsToken.balanceOf(address(this));
        _rewardsToken.safeTransfer(proposer, rewardsBalance);
    }

    function claimRewards() external {
        require(msg.sender == proposer, "NOT_ALLOWED");
        sendRewardsToCurrentProposer();
    }

    // ============== STRATEGY MANAGEMENT ================
    function addStrategy(
        PackedStrategies calldata _packedStrategies,
        address _newStrategy,
        StrategyParam calldata _newStrategyParam
    ) external onlyOwner {
        // Checks previous strategies data valid
        bytes4[] memory checkdata = castCheckdataToBytes4(
            _packedStrategies.checkdata
        );

        if (strategiesHash != 0) {
            checkStrategyHash(_packedStrategies, checkdata);
        } else {
            require(_packedStrategies.addresses.length == 0, "FIRST_DATA");
        }

        for (uint256 i = 0; i < _packedStrategies.addresses.length; i++) {
            if (_packedStrategies.addresses[i] == _newStrategy) {
                revert("STRATEGY_EXISTS");
            }
        }

        // Checks call data valid
        checkValidityOfData(_newStrategyParam);

        // Build new arrays for the Strategy Hash and the Event
        address[] memory strategies = new address[](
            _packedStrategies.addresses.length + 1
        );
        for (uint256 i = 0; i < _packedStrategies.addresses.length; i++) {
            strategies[i] = _packedStrategies.addresses[i];
        }
        strategies[_packedStrategies.addresses.length] = _newStrategy;

        uint256[] memory strategiesCallLen = appendUint256ToArray(
            _packedStrategies.callLen,
            _newStrategyParam.callLen
        );

        address[] memory contracts = new address[](
            _packedStrategies.contracts.length + _newStrategyParam.callLen
        );
        for (uint256 i = 0; i < _packedStrategies.contracts.length; i++) {
            contracts[i] = _packedStrategies.contracts[i];
        }
        for (uint256 i = 0; i < _newStrategyParam.callLen; i++) {
            contracts[
                i + _packedStrategies.contracts.length
            ] = _newStrategyParam.contracts[i];
        }

        checkdata = new bytes4[](
            _packedStrategies.checkdata.length + _newStrategyParam.callLen
        );
        for (uint256 i = 0; i < _packedStrategies.checkdata.length; i++) {
            checkdata[i] = bytes4(_packedStrategies.checkdata[i]);
        }

        for (uint256 i = 0; i < _newStrategyParam.callLen; i++) {
            checkdata[i + _packedStrategies.checkdata.length] = bytes4(
                _newStrategyParam.checkdata[i]
            );
        }

        uint256[] memory offset = concatenateUint256ArrayToUint256Array(
            _packedStrategies.offset,
            _newStrategyParam.offset
        );

        uint256[] memory calculationsLen = appendUint256ToArray(
            _packedStrategies.calculationsLen,
            _newStrategyParam.calculationsLen
        );

        uint256[] memory calculations = concatenateUint256ArrayToUint256Array(
            _packedStrategies.calculations,
            _newStrategyParam.calculations
        );

        uint256[] memory conditionsLen = appendUint256ToArray(
            _packedStrategies.conditionsLen,
            _newStrategyParam.conditionsLen
        );

        uint256[] memory conditions = concatenateUint256ArrayToUint256Array(
            _packedStrategies.conditions,
            _newStrategyParam.conditions
        );

        strategiesHash = uint256(
            keccak256(
                abi.encodePacked(
                    strategies,
                    strategiesCallLen,
                    contracts,
                    checkdata,
                    offset,
                    calculationsLen,
                    calculations,
                    conditionsLen,
                    conditions
                )
            )
        );

        // New strategy allocation always set to 0, people can then send new solution
        targetAllocation.push(0);

        emit StrategyAdded(
            strategies,
            strategiesCallLen,
            contracts,
            checkdata,
            offset,
            calculationsLen,
            calculations,
            conditionsLen,
            conditions
        );
    }

    // TODO: use utils functions
    function updateStrategy(
        PackedStrategies memory _packedStrategies,
        uint256 indexStrategyToUpdate,
        StrategyParam memory _newStrategyParam
    ) external onlyOwner {
        // Checks at least one strategy is registered
        require(strategiesHash != 0, "NO_STRATEGIES");

        // Checks strategies data is valid
        bytes4[] memory checkdata = castCheckdataToBytes4(
            _packedStrategies.checkdata
        );

        checkStrategyHash(_packedStrategies, checkdata);

        // Checks index in range
        require(
            indexStrategyToUpdate < _packedStrategies.addresses.length,
            "INDEX_OUT_OF_RANGE"
        );

        // Checks call data valid
        checkValidityOfData(_newStrategyParam);

        // Build new arrays for the Strategy Hash and the Event
        uint256[] memory strategiesCallLen = new uint256[](
            _packedStrategies.callLen.length
        );
        uint256[] memory calculationsLen = new uint256[](
            _packedStrategies.calculationsLen.length
        );
        uint256[] memory conditionsLen = new uint256[](
            _packedStrategies.conditionsLen.length
        );
        address[] memory contracts = new address[](
            _packedStrategies.contracts.length -
                _packedStrategies.callLen[indexStrategyToUpdate] +
                _newStrategyParam.callLen
        );
        checkdata = new bytes4[](
            _packedStrategies.checkdata.length -
                _packedStrategies.callLen[indexStrategyToUpdate] +
                _newStrategyParam.callLen
        );
        uint256[] memory offset = new uint256[](
            _packedStrategies.offset.length -
                _packedStrategies.callLen[indexStrategyToUpdate] +
                _newStrategyParam.callLen
        );
        uint256[] memory calculations = new uint256[](
            _packedStrategies.calculations.length -
                _packedStrategies.calculationsLen[indexStrategyToUpdate] +
                _newStrategyParam.calculationsLen
        );
        uint256[] memory conditions = new uint256[](
            _packedStrategies.conditions.length -
                _packedStrategies.conditionsLen[indexStrategyToUpdate] +
                _newStrategyParam.conditionsLen
        );
        uint256 offsetCalldata = indexStrategyToUpdate;
        if (indexStrategyToUpdate == _packedStrategies.addresses.length - 1) {
            for (uint256 i = 0; i < offsetCalldata; i++) {
                strategiesCallLen[i] = _packedStrategies.callLen[i];
            }
            strategiesCallLen[offsetCalldata] = _newStrategyParam.callLen;
            for (uint256 i = 0; i < offsetCalldata; i++) {
                calculationsLen[i] = _packedStrategies.calculationsLen[i];
            }
            calculationsLen[offsetCalldata] = _newStrategyParam.calculationsLen;
            for (uint256 i = 0; i < offsetCalldata; i++) {
                conditionsLen[i] = _packedStrategies.conditionsLen[i];
            }
            conditionsLen[offsetCalldata] = _newStrategyParam.conditionsLen;

            offsetCalldata = 0;
            for (uint256 i = 0; i < indexStrategyToUpdate; i++) {
                offsetCalldata += _packedStrategies.callLen[i];
            }
            for (uint256 i = 0; i < offsetCalldata; i++) {
                contracts[i] = _packedStrategies.contracts[i];
            }
            for (uint256 i = 0; i < _newStrategyParam.callLen; i++) {
                contracts[i + offsetCalldata] = _newStrategyParam.contracts[i];
            }
            for (uint256 i = 0; i < offsetCalldata; i++) {
                checkdata[i] = bytes4(_packedStrategies.checkdata[i]);
            }
            for (uint256 i = 0; i < _newStrategyParam.callLen; i++) {
                checkdata[i + offsetCalldata] = bytes4(
                    _newStrategyParam.checkdata[i]
                );
            }
            for (uint256 i = 0; i < offsetCalldata; i++) {
                offset[i] = _packedStrategies.offset[i];
            }
            for (uint256 i = 0; i < _newStrategyParam.callLen; i++) {
                offset[i + offsetCalldata] = _newStrategyParam.offset[i];
            }

            offsetCalldata = 0;
            for (uint256 i = 0; i < indexStrategyToUpdate; i++) {
                offsetCalldata += _packedStrategies.calculationsLen[i];
            }
            for (uint256 i = 0; i < offsetCalldata; i++) {
                calculations[i] = _packedStrategies.calculations[i];
            }
            for (uint256 i = 0; i < _newStrategyParam.calculationsLen; i++) {
                calculations[i + offsetCalldata] = _newStrategyParam
                    .calculations[i];
            }

            offsetCalldata = 0;
            for (uint256 i = 0; i < indexStrategyToUpdate; i++) {
                offsetCalldata += _packedStrategies.conditionsLen[i];
            }
            for (uint256 i = 0; i < offsetCalldata; i++) {
                conditions[i] = _packedStrategies.conditions[i];
            }
            for (uint256 i = 0; i < _newStrategyParam.conditionsLen; i++) {
                conditions[i + offsetCalldata] = _newStrategyParam.conditions[
                    i
                ];
            }
        } else {
            for (uint256 i = 0; i < offsetCalldata; i++) {
                strategiesCallLen[i] = _packedStrategies.callLen[i];
            }
            strategiesCallLen[offsetCalldata] = _newStrategyParam.callLen;
            for (
                uint256 i = offsetCalldata + 1;
                i < _packedStrategies.callLen.length;
                i++
            ) {
                strategiesCallLen[i] = _packedStrategies.callLen[i];
            }
            for (uint256 i = 0; i < offsetCalldata; i++) {
                calculationsLen[i] = _packedStrategies.calculationsLen[i];
            }
            calculationsLen[offsetCalldata] = _newStrategyParam.calculationsLen;
            for (
                uint256 i = offsetCalldata + 1;
                i < _packedStrategies.calculationsLen.length;
                i++
            ) {
                calculationsLen[i] = _packedStrategies.calculationsLen[i];
            }
            for (uint256 i = 0; i < offsetCalldata; i++) {
                conditionsLen[i] = _packedStrategies.conditionsLen[i];
            }
            conditionsLen[offsetCalldata] = _newStrategyParam.conditionsLen;
            for (
                uint256 i = offsetCalldata + 1;
                i < _packedStrategies.conditionsLen.length;
                i++
            ) {
                conditionsLen[i] = _packedStrategies.conditionsLen[i];
            }

            uint256 totalCallLen = 0;
            offsetCalldata = 0;
            for (uint256 i = 0; i < _packedStrategies.addresses.length; i++) {
                if (i == indexStrategyToUpdate) {
                    offsetCalldata = totalCallLen;
                }
                totalCallLen += _packedStrategies.callLen[i];
            }
            uint256 offsetCalldataAfter = offsetCalldata +
                _packedStrategies.callLen[indexStrategyToUpdate];
            for (uint256 i = 0; i < offsetCalldata; i++) {
                contracts[i] = _packedStrategies.contracts[i];
            }
            for (uint256 i = 0; i < _newStrategyParam.callLen; i++) {
                contracts[i + offsetCalldata] = _newStrategyParam.contracts[i];
            }
            for (uint256 i = 0; i < totalCallLen - offsetCalldataAfter; i++) {
                contracts[
                    i + offsetCalldata + _newStrategyParam.callLen
                ] = _packedStrategies.contracts[offsetCalldataAfter + i];
            }
            for (uint256 i = 0; i < offsetCalldata; i++) {
                checkdata[i] = bytes4(_packedStrategies.checkdata[i]);
            }
            for (uint256 i = 0; i < _newStrategyParam.callLen; i++) {
                checkdata[i + offsetCalldata] = bytes4(
                    _newStrategyParam.checkdata[i]
                );
            }
            for (uint256 i = 0; i < totalCallLen - offsetCalldataAfter; i++) {
                checkdata[
                    i + offsetCalldata + _newStrategyParam.callLen
                ] = bytes4(
                    _packedStrategies.checkdata[offsetCalldataAfter + i]
                );
            }
            for (uint256 i = 0; i < offsetCalldata; i++) {
                offset[i] = _packedStrategies.offset[i];
            }
            for (uint256 i = 0; i < _newStrategyParam.callLen; i++) {
                offset[i + offsetCalldata] = _newStrategyParam.offset[i];
            }
            for (uint256 i = 0; i < totalCallLen - offsetCalldataAfter; i++) {
                offset[
                    i + offsetCalldata + _newStrategyParam.callLen
                ] = _packedStrategies.offset[offsetCalldataAfter + i];
            }

            totalCallLen = 0;
            offsetCalldata = 0;
            for (uint256 i = 0; i < _packedStrategies.addresses.length; i++) {
                if (i == indexStrategyToUpdate) {
                    offsetCalldata = totalCallLen;
                }
                totalCallLen += _packedStrategies.calculationsLen[i];
            }
            offsetCalldataAfter =
                offsetCalldata +
                _packedStrategies.calculationsLen[indexStrategyToUpdate];
            for (uint256 i = 0; i < offsetCalldata; i++) {
                calculations[i] = _packedStrategies.calculations[i];
            }
            for (uint256 i = 0; i < _newStrategyParam.calculationsLen; i++) {
                calculations[i + offsetCalldata] = _newStrategyParam
                    .calculations[i];
            }
            for (uint256 i = 0; i < totalCallLen - offsetCalldataAfter; i++) {
                calculations[
                    i + offsetCalldata + _newStrategyParam.calculationsLen
                ] = _packedStrategies.calculations[offsetCalldataAfter + i];
            }

            totalCallLen = 0;
            offsetCalldata = 0;
            for (uint256 i = 0; i < _packedStrategies.addresses.length; i++) {
                if (i == indexStrategyToUpdate) {
                    offsetCalldata = totalCallLen;
                }
                totalCallLen += _packedStrategies.conditionsLen[i];
            }
            offsetCalldataAfter =
                offsetCalldata +
                _packedStrategies.conditionsLen[indexStrategyToUpdate];
            for (uint256 i = 0; i < offsetCalldata; i++) {
                conditions[i] = _packedStrategies.conditions[i];
            }
            for (uint256 i = 0; i < _newStrategyParam.conditionsLen; i++) {
                conditions[i + offsetCalldata] = _newStrategyParam.conditions[
                    i
                ];
            }
            for (uint256 i = 0; i < totalCallLen - offsetCalldataAfter; i++) {
                conditions[
                    i + offsetCalldata + _newStrategyParam.conditionsLen
                ] = _packedStrategies.conditions[offsetCalldataAfter + i];
            }
        }

        strategiesHash = uint256(
            keccak256(
                abi.encodePacked(
                    _packedStrategies.addresses,
                    strategiesCallLen,
                    contracts,
                    checkdata,
                    offset,
                    calculationsLen,
                    calculations,
                    conditionsLen,
                    conditions
                )
            )
        );

        emit StrategyUpdated(
            _packedStrategies.addresses,
            strategiesCallLen,
            contracts,
            checkdata,
            offset,
            calculationsLen,
            calculations,
            conditionsLen,
            conditions
        );
    }

    function removeStrategy(
        PackedStrategies memory _packedStrategies,
        uint256 indexStrategyToRemove
    ) external onlyOwner {
        // Checks at least one strategy is registered
        require(strategiesHash != 0, "NO_STRATEGIES");

        bytes4[] memory checkdata = castCheckdataToBytes4(
            _packedStrategies.checkdata
        );

        // Checks strategies data is valid
        checkStrategyHash(_packedStrategies, checkdata);

        // Checks index in range
        require(indexStrategyToRemove < _packedStrategies.addresses.length);

        // Build new arrays for the Strategy Hash and the Event
        uint256[] memory strategiesCallLen = new uint256[](
            _packedStrategies.callLen.length - 1
        );
        uint256[] memory calculationsLen = new uint256[](
            _packedStrategies.calculationsLen.length - 1
        );
        uint256[] memory conditionsLen = new uint256[](
            _packedStrategies.conditionsLen.length - 1
        );
        address[] memory contracts = new address[](
            _packedStrategies.contracts.length -
                _packedStrategies.callLen[indexStrategyToRemove]
        );
        checkdata = new bytes4[](
            _packedStrategies.checkdata.length -
                _packedStrategies.callLen[indexStrategyToRemove]
        );
        uint256[] memory offset = new uint256[](
            _packedStrategies.offset.length -
                _packedStrategies.callLen[indexStrategyToRemove]
        );
        uint256[] memory calculations = new uint256[](
            _packedStrategies.calculations.length -
                _packedStrategies.calculationsLen[indexStrategyToRemove]
        );
        uint256[] memory conditions = new uint256[](
            _packedStrategies.conditions.length -
                _packedStrategies.conditionsLen[indexStrategyToRemove]
        );
        uint256 offsetCalldata = indexStrategyToRemove;
        for (uint256 i = 0; i < offsetCalldata; i++) {
            strategiesCallLen[i] = _packedStrategies.callLen[i];
        }
        for (
            uint256 i = 0;
            i < _packedStrategies.addresses.length - (offsetCalldata + 1);
            i++
        ) {
            strategiesCallLen[offsetCalldata + i] = _packedStrategies.callLen[
                offsetCalldata + 1 + i
            ];
        }
        for (uint256 i = 0; i < offsetCalldata; i++) {
            calculationsLen[i] = _packedStrategies.calculationsLen[i];
        }
        for (
            uint256 i = 0;
            i < _packedStrategies.addresses.length - (offsetCalldata + 1);
            i++
        ) {
            calculationsLen[offsetCalldata + i] = _packedStrategies
                .calculationsLen[offsetCalldata + 1 + i];
        }
        for (uint256 i = 0; i < offsetCalldata; i++) {
            conditionsLen[i] = _packedStrategies.conditionsLen[i];
        }
        for (
            uint256 i = 0;
            i < _packedStrategies.addresses.length - (offsetCalldata + 1);
            i++
        ) {
            conditionsLen[offsetCalldata + i] = _packedStrategies.conditionsLen[
                offsetCalldata + 1 + i
            ];
        }

        uint256 totalCallLen = 0;
        offsetCalldata = 0;
        for (uint256 i = 0; i < _packedStrategies.addresses.length; i++) {
            if (i == indexStrategyToRemove) {
                offsetCalldata = totalCallLen;
            }
            totalCallLen += _packedStrategies.callLen[i];
        }

        for (uint256 i = 0; i < offsetCalldata; i++) {
            contracts[i] = _packedStrategies.contracts[i];
        }
        for (
            uint256 i = 0;
            i <
            totalCallLen -
                (offsetCalldata +
                    _packedStrategies.callLen[indexStrategyToRemove]);
            i++
        ) {
            contracts[i + offsetCalldata] = _packedStrategies.contracts[
                offsetCalldata +
                    _packedStrategies.callLen[indexStrategyToRemove] +
                    i
            ];
        }
        for (uint256 i = 0; i < offsetCalldata; i++) {
            checkdata[i] = bytes4(_packedStrategies.checkdata[i]);
        }
        for (
            uint256 i = 0;
            i <
            totalCallLen -
                (offsetCalldata +
                    _packedStrategies.callLen[indexStrategyToRemove]);
            i++
        ) {
            checkdata[i + offsetCalldata] = bytes4(
                _packedStrategies.checkdata[
                    offsetCalldata +
                        _packedStrategies.callLen[indexStrategyToRemove] +
                        i
                ]
            );
        }
        for (uint256 i = 0; i < offsetCalldata; i++) {
            offset[i] = _packedStrategies.offset[i];
        }
        for (
            uint256 i = 0;
            i <
            totalCallLen -
                (offsetCalldata +
                    _packedStrategies.callLen[indexStrategyToRemove]);
            i++
        ) {
            offset[i + offsetCalldata] = _packedStrategies.offset[
                offsetCalldata +
                    _packedStrategies.callLen[indexStrategyToRemove] +
                    i
            ];
        }

        totalCallLen = 0;
        offsetCalldata = 0;
        for (uint256 i = 0; i < _packedStrategies.addresses.length; i++) {
            if (i == indexStrategyToRemove) {
                offsetCalldata = totalCallLen;
            }
            totalCallLen += _packedStrategies.calculationsLen[i];
        }
        for (uint256 i = 0; i < offsetCalldata; i++) {
            calculations[i] = _packedStrategies.calculations[i];
        }
        for (
            uint256 i = 0;
            i <
            totalCallLen -
                (offsetCalldata +
                    _packedStrategies.calculationsLen[indexStrategyToRemove]);
            i++
        ) {
            calculations[i + offsetCalldata] = _packedStrategies.calculations[
                offsetCalldata +
                    _packedStrategies.calculationsLen[indexStrategyToRemove] +
                    i
            ];
        }
        totalCallLen = 0;
        offsetCalldata = 0;
        for (uint256 i = 0; i < _packedStrategies.addresses.length; i++) {
            if (i == indexStrategyToRemove) {
                offsetCalldata = totalCallLen;
            }
            totalCallLen += _packedStrategies.conditionsLen[i];
        }
        for (uint256 i = 0; i < offsetCalldata; i++) {
            conditions[i] = _packedStrategies.conditions[i];
        }
        for (
            uint256 i = 0;
            i <
            totalCallLen -
                (offsetCalldata +
                    _packedStrategies.conditionsLen[indexStrategyToRemove]);
            i++
        ) {
            conditions[i + offsetCalldata] = _packedStrategies.conditions[
                offsetCalldata +
                    _packedStrategies.conditionsLen[indexStrategyToRemove] +
                    i
            ];
        }

        strategiesHash = uint256(
            keccak256(
                abi.encodePacked(
                    _packedStrategies.addresses,
                    strategiesCallLen,
                    contracts,
                    checkdata,
                    offset,
                    calculationsLen,
                    calculations,
                    conditionsLen,
                    conditions
                )
            )
        );
        emit StrategyRemoved(
            _packedStrategies.addresses,
            strategiesCallLen,
            contracts,
            checkdata,
            offset,
            calculationsLen,
            calculations,
            conditionsLen,
            conditions
        );
    }

    //Can't set only view, .call potentially modify state (should not arrive)
    function getStrategiesData(
        address[] calldata contracts,
        bytes[] calldata checkdata,
        uint256[] calldata offset
    ) public returns (uint256[] memory dataStrategies) {
        uint256[] memory dataStrategies_ = new uint256[](contracts.length);
        for (uint256 j; j < contracts.length; j++) {
            (, bytes memory data) = contracts[j].call(checkdata[j]);
            dataStrategies_[j] = uint256(bytesToBytes32(data, offset[j]));
        }
        return (dataStrategies_);
    }

    //     function updateTargetAllocation(address[] memory strategies) internal {
    //         uint256[] memory realAllocations = new uint256[](strategies.length);
    //         uint256 cumulativeAmountRealAllocations = 0;
    //         uint256 cumulativeAmountTargetAllocations = 0;
    //         for (uint256 j; j < strategies.length; j++) {
    //             realAllocations[j] = IStrategy(strategies[j]).totalAssets();
    //             cumulativeAmountRealAllocations += realAllocations[j];
    //             cumulativeAmountTargetAllocations += targetAllocation[j];
    //         }
    //
    //         if (cumulativeAmountTargetAllocations == 0) {
    //             targetAllocation = realAllocations;
    //         } else {
    //             if (
    //                 cumulativeAmountTargetAllocations <=
    //                 cumulativeAmountRealAllocations
    //             ) {
    //                 uint256 diff = cumulativeAmountRealAllocations -
    //                     cumulativeAmountTargetAllocations;
    //                 // We need to add this amount respecting the different strategies allocation ratio
    //                 for (uint256 i = 0; i < strategies.length; i++) {
    //                     uint256 strategyAllocationRatio = (PRECISION *
    //                         targetAllocation[i]) /
    //                         cumulativeAmountTargetAllocations;
    //                     targetAllocation[i] +=
    //                         (strategyAllocationRatio * diff) /
    //                         PRECISION;
    //                 }
    //             } else {
    //                 uint256 diff = cumulativeAmountTargetAllocations -
    //                     cumulativeAmountRealAllocations;
    //                 // We need to substract this amount respecting the different strategies allocation ratio
    //                 for (uint256 i = 0; i < strategies.length; i++) {
    //                     uint256 strategyAllocationRatio = (PRECISION *
    //                         targetAllocation[i]) /
    //                         cumulativeAmountTargetAllocations;
    //                     targetAllocation[i] -=
    //                         (strategyAllocationRatio * diff) /
    //                         PRECISION;
    //                 }
    //             }
    //         }
    //     }
    //
    // UTILS
    function checkStrategyHash(
        PackedStrategies memory _packedStrategies,
        bytes4[] memory checkdata
    ) internal view {
        require(
            strategiesHash ==
                uint256(
                    keccak256(
                        abi.encodePacked(
                            _packedStrategies.addresses,
                            _packedStrategies.callLen,
                            _packedStrategies.contracts,
                            checkdata,
                            _packedStrategies.offset,
                            _packedStrategies.calculationsLen,
                            _packedStrategies.calculations,
                            _packedStrategies.conditionsLen,
                            _packedStrategies.conditions
                        )
                    )
                ),
            "DATA"
        );
    }

    function parseProgramOutput(
        uint256[] calldata programOutput
    )
        public
        pure
        returns (
            uint256 _inputHash,
            uint256[] memory _currentTargetAllocation,
            uint256[] memory _newTargetAllocation,
            uint256 _currentSolution,
            uint256 _newSolution
        )
    {
        _inputHash = programOutput[0] << 128;
        _inputHash += programOutput[1];

        _currentTargetAllocation = new uint256[](programOutput[2]);

        _newTargetAllocation = new uint256[](programOutput[2]);

        for (uint256 i = 0; i < programOutput[2]; i++) {
            // NOTE: skip the 2 first value + array len
            _currentTargetAllocation[i] = programOutput[i + 3];
            _newTargetAllocation[i] = programOutput[i + 4 + programOutput[2]];
        }
        return (
            _inputHash,
            _currentTargetAllocation,
            _newTargetAllocation,
            programOutput[programOutput.length - 2],
            programOutput[programOutput.length - 1]
        );
    }

    function bytesToBytes32(
        bytes memory b,
        uint offset
    ) private pure returns (bytes32 result) {
        offset += 32;
        assembly {
            result := mload(add(b, offset))
        }
    }

    function castCheckdataToBytes4(
        bytes[] memory oldCheckdata
    ) internal view returns (bytes4[] memory checkdata) {
        checkdata = new bytes4[](oldCheckdata.length);
        for (uint256 i = 0; i < oldCheckdata.length; i++) {
            checkdata[i] = bytes4(oldCheckdata[i]);
        }
    }

    function checkValidityOfData(
        StrategyParam memory _newStrategyParam
    ) internal {
        // check lengths
        require(
            _newStrategyParam.callLen == _newStrategyParam.contracts.length &&
                _newStrategyParam.callLen ==
                _newStrategyParam.checkdata.length &&
                _newStrategyParam.callLen == _newStrategyParam.offset.length &&
                _newStrategyParam.calculationsLen ==
                _newStrategyParam.calculations.length &&
                _newStrategyParam.conditionsLen ==
                _newStrategyParam.conditions.length,
            "ARRAY_LEN"
        );

        // check success of calls
        for (uint256 i = 0; i < _newStrategyParam.callLen; i++) {
            (bool success, ) = _newStrategyParam.contracts[i].call(
                _newStrategyParam.checkdata[i]
            );
            require(success == true, "CALLDATA");
            // Should we check for offset?
        }
    }

    function appendUint256ToArray(
        uint256[] memory array,
        uint256 newItem
    ) internal pure returns (uint256[] memory newArray) {
        newArray = new uint256[](array.length + 1);
        for (uint256 i = 0; i < array.length; i++) {
            newArray[i] = array[i];
        }
        newArray[array.length] = newItem;
    }

    function concatenateUint256ArrayToUint256Array(
        uint256[] memory arrayA,
        uint256[] memory arrayB
    ) internal pure returns (uint256[] memory newArray) {
        newArray = new uint256[](arrayA.length + arrayB.length);
        for (uint256 i = 0; i < arrayA.length; i++) {
            newArray[i] = arrayA[i];
        }
        uint256 lenA = arrayA.length;
        for (uint256 i = 0; i < arrayB.length; i++) {
            newArray[i + lenA] = arrayB[i];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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