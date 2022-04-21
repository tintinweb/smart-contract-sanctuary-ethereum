/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @chainlink/contracts/src/v0.8/[email protected]

pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]

pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}


// File @chainlink/contracts/src/v0.8/[email protected]

pragma solidity ^0.8.0;


abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}


// File contracts/MovingLeverageBaseOracle.sol

/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.8.4;

interface IConvexBooster {
    function calculateTokenAmount(
        uint256 _pid,
        uint256 _tokens,
        int128 _curveCoinId
    ) external view returns (uint256);
}

interface IMovingLeverageBase {
    function setOriginMovingLeverageBatch(
        uint256 _total,
        uint256[] calldata _pids,
        int128[] calldata _curveCoinIds,
        uint256[] calldata _origins
    ) external;
}

contract MovingLeverageBaseOracle is KeeperCompatibleInterface {
    address public convexBooster = 0xAD870CB0084B1C12a037C30De886EBfFc672Cac4;
    address public originMovingLeverage =
        0x52896e6A240630c266e6E842429a0F61A86ab325;

    uint256 public immutable interval;
    uint256 public lastTimeStamp;
    uint256 public pullCounter;
    uint256 public pushCounter;
    uint256 public averageSize = 3;
    address public owner;

    struct Swap {
        bool enabled;
        uint256 tokens;
        uint256 pid;
        int128 coinId;
    }

    struct Result {
        uint256 pid;
        int128 coinId;
        uint256 leverage;
    }

    struct Average {
        uint256 total;
        uint256[] pids;
        int128[] coinIds;
        uint256[] leverages;
        uint256 createdAt;
    }

    Swap[] public swaps;
    mapping(uint256 => Result[]) public histories;
    mapping(uint256 => Average) public averages;

    event SetOwner(address owner);

    modifier onlyOwner() {
        require(
            owner == msg.sender,
            "MovingLeverageBaseOracle: caller is not the owner"
        );
        _;
    }

    constructor(uint256 updateInterval) {
        interval = updateInterval;
        lastTimeStamp = block.timestamp;
        owner = msg.sender;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;

        emit SetOwner(_owner);
    }

    function _Swap(
        uint256 _tokens,
        uint256 _pid,
        int128 _coinId
    ) internal {
        swaps.push(Swap(true, _tokens, _pid, _coinId));
    }

    function _Swap(uint256 _pid, int128 _coinId) internal {
        _Swap(1000000000000000000, _pid, _coinId);
    }

    function setSwaps() external onlyOwner {
        _Swap(1, 1);
        _Swap(1, 0);
        _Swap(2, 1);
        _Swap(3, 1);
        _Swap(4, 1);
        _Swap(5, 0);
        _Swap(6, 0);
        _Swap(7, 0);
        _Swap(8, 0);
        _Swap(9, 1);
        _Swap(9, 0);
        _Swap(10, 2);
        _Swap(10, 1);
        _Swap(11, 2);
        _Swap(11, 1);
        _Swap(12, 2);
        _Swap(12, 1);
        _Swap(13, 2);
        _Swap(14, 2);
        _Swap(14, 1);
        _Swap(15, 2);
        _Swap(15, 1);
        _Swap(16, 2);
        _Swap(16, 1);
        _Swap(17, 2);
        _Swap(17, 1);
        _Swap(18, 2);
        _Swap(18, 1);
        _Swap(19, 2);
        _Swap(19, 1);
        _Swap(20, 2);
        _Swap(20, 1);
        _Swap(21, 2);
        _Swap(21, 1);
        _Swap(22, 2);
        _Swap(22, 1);
        _Swap(23, 2);
        _Swap(23, 1);
        _Swap(24, 2);
        _Swap(25, 2);
        _Swap(26, 2);
        _Swap(27, 2);
    }

    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata) external override {
        if ((block.timestamp - lastTimeStamp) > interval) {
            lastTimeStamp = block.timestamp;

            pullCounter++;

            Result memory result;

            for (uint256 i = 0; i < swaps.length; i++) {
                Swap storage swap = swaps[i];

                if (swap.enabled) {
                    uint256 swapTokens = calculateTokenAmount(
                        i,
                        swap.tokens,
                        swap.coinId
                    );

                    result.pid = i;
                    result.coinId = swap.coinId;
                    result.leverage = swapTokens;

                    histories[pullCounter].push(result);
                }
            }

            if (pullCounter == 2) {
                setAverage();
            }
        }
    }

    function setAverage() public {
        Average memory average;

        uint256[] memory pids = new uint256[](swaps.length);
        int128[] memory coinIds = new int128[](swaps.length);
        uint256[] memory leverages = new uint256[](swaps.length);

        for (uint256 i = 0; i < averageSize; i++) {
            Result[] storage results = histories[pullCounter - i];

            for (uint256 j = 0; j < results.length; j++) {
                if (i == 0) {
                    pids[j] = results[j].pid;
                    coinIds[j] = results[j].coinId;
                    average.total++;
                }

                leverages[j] = leverages[j] + results[j].leverage;

                if (i == averageSize - 1) {
                    leverages[j] = (leverages[j] * 1e18) / averageSize / 1e18;
                }
            }
        }

        average.pids = pids;
        average.coinIds = coinIds;
        average.leverages = leverages;
        average.createdAt = block.timestamp;

        averages[++pushCounter] = average;
    }

    function calculateTokenAmount(
        uint256 _pid,
        uint256 _tokens,
        int128 _coinId
    ) public view returns (uint256) {
        return
            IConvexBooster(convexBooster).calculateTokenAmount(
                _pid,
                _tokens,
                _coinId
            );
    }
}