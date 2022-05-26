// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IERC20} from "IERC20.sol";
import {IAPI} from "IAPI.sol";
import "Ownable.sol";
import "KeeperCompatible.sol";

error Transfer__Failed();

contract Sprint69 is Ownable, KeeperCompatibleInterface {
    IAPI private apiContract;
    IERC20 public paymentToken;

    uint256 public round;

    uint256 public lastTimeStamp;

    uint256 public constant roundDuration = 4 days;

    mapping(uint8 => string) public s_assetIdentifier;
    //rount info
    mapping(uint256 => Round) public s_roundInfo;

    // Total Staked
    uint256 public s_totalStaked;

    struct Round {
        uint256 startTime;
        uint256 endTime;
        uint256 pickEndTime;
        uint256 totalStaked;
        uint256 totalPlayers;
    }
    mapping(uint256 => uint8[]) public s_roundWinningOrder;

    mapping(uint256 => address[]) public s_roundWinners;

    mapping(uint256 => mapping(address => uint8[])) public s_addressPicks;

    constructor(address _paymentToken, address _api) {
        paymentToken = IERC20(_paymentToken);
        apiContract = IAPI(_api);
        round = 1;
        s_roundInfo[1] = Round(
            block.timestamp,
            (block.timestamp + 4 days),
            (block.timestamp + 72 hours),
            0,
            0
        );
        s_assetIdentifier[1] = "USDC";
        s_assetIdentifier[2] = "BNB";
        s_assetIdentifier[3] = "XRP";
        s_assetIdentifier[4] = "SOL";
        s_assetIdentifier[5] = "ADA";
        s_assetIdentifier[6] = "AVAX";
        s_assetIdentifier[7] = "DODGE";
        s_assetIdentifier[8] = "DOT";
        lastTimeStamp = block.timestamp;
    }

    function selectAssets(uint8[] memory _assets) external {
        bool success = paymentToken.transferFrom(
            msg.sender,
            address(this),
            10 ether
        );
        if (!success) {
            revert Transfer__Failed();
        }
        s_addressPicks[round][msg.sender] = _assets;
        s_roundInfo[round].totalPlayers += 1;
        s_roundInfo[round].totalStaked += 9 ether;
    }

    function setWinningOrder() private {
        uint256 usdcPrice = apiContract.USDC();
        uint256 bnbprice = apiContract.BNB();
        uint256 xrpPrice = apiContract.XRP();
        uint256 solPrice = apiContract.SOL();
        uint256 adaPrice = apiContract.AVAX();
        uint256 dodgePrice = apiContract.DODGE();
        uint256 dotPrice = apiContract.DOT();

        uint256[7] memory arrayed = [
            usdcPrice,
            bnbprice,
            xrpPrice,
            solPrice,
            adaPrice,
            dodgePrice,
            dotPrice
        ];
        uint256[] memory _winningOrder;
        for (uint8 i = 0; i < 8; i++) {
            if (arrayed[i] < arrayed[i + 1]) {
                s_roundWinningOrder[round][i] = i + 1;
            }
        }
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > roundDuration;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        if ((block.timestamp - lastTimeStamp) > roundDuration) {
            lastTimeStamp = block.timestamp;
            apiContract.requestMultipleParameters();
            setWinningOrder();
            distributeWinnigs();
        }
    }

    function distributeWinnigs() private {
        uint256 _round = round - 1;
        uint256 len = s_roundWinners[_round].length;
        Round storage roundInfo = s_roundInfo[_round];
        if (len == 1) {
            paymentToken.transfer(
                s_roundWinners[_round][0],
                roundInfo.totalStaked
            );
        }
        if (len > 1) {
            for (uint256 i = 0; i < len; i++) {
                paymentToken.transfer(
                    s_roundWinners[_round][i],
                    (roundInfo.totalStaked / len)
                );
            }
        }
    }

    function replaceAsset(
        uint256 _totalSupply,
        uint8 _id,
        string memory _symbol,
        string memory _shortUrl,
        string memory _url
    ) external onlyOwner {
        apiContract.addAssetUrl(_totalSupply, _symbol, _id, _shortUrl, _url);
        s_assetIdentifier[_id] = _symbol;
    }

    function claimWinning(uint256 _round) external {
        require(
            s_addressPicks[_round][msg.sender][0] ==
                s_roundWinningOrder[_round][0]
        );
        require(
            s_addressPicks[_round][msg.sender][2] ==
                s_roundWinningOrder[_round][2]
        );
        require(
            s_addressPicks[_round][msg.sender][3] ==
                s_roundWinningOrder[_round][3]
        );
        require(
            s_addressPicks[_round][msg.sender][4] ==
                s_roundWinningOrder[_round][4]
        );
        require(
            s_addressPicks[_round][msg.sender][5] ==
                s_roundWinningOrder[_round][5]
        );
        s_roundWinners[_round].push(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IERC20 {
    /// @param _owner The address from which the balance will be retrieved
    /// @return balance the balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IAPI {
    function addAssetUrl(
        uint256 _totalSupply,
        string memory _symbol,
        uint8 _assetId,
        string memory _short,
        string memory _url
    ) external;

    function s_assetUrl(uint8 _id)
        external
        view
        returns (
            uint256,
            string memory,
            string memory,
            string memory
        );

    function requestMultipleParameters() external;

    function USDC() external view returns (uint256);

    function BNB() external view returns (uint256);

    function XRP() external view returns (uint256);

    function SOL() external view returns (uint256);

    function ADA() external view returns (uint256);

    function AVAX() external view returns (uint256);

    function DODGE() external view returns (uint256);

    function DOT() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
pragma solidity ^0.8.0;

import "KeeperBase.sol";
import "KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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