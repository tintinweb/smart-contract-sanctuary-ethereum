//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "./TransferHelper.sol";

interface IERC20 {
    function balanceOf(address owner) external returns(uint256 balance);
    function allowance(address owner, address spender) external returns(uint256 remaining);
}

contract Legacies is KeeperCompatible {
    Legacy[] public legacies;
    mapping(address=>uint256) public legacyIndexes;

    struct Legacy {
        address owner;
        address legatee;
        address[] tokens;
        uint256 lastSeen;
        uint256 checkInterval;
        bool fulfilled;
    }

    constructor() {
        //Create dummy legacy to occupy index 0
        create(address(0), 0);
    }

    function create(address _legatee, uint256 _checkInterval) public {
        uint256 _index = legacies.length;
        // Revert if msg.sender already has an active legacy!
        require(legacyIndexes[msg.sender] == 0, "Legacy exist!");
        legacies.push(Legacy(msg.sender, _legatee, new address[](0), block.timestamp, _checkInterval, false));
        legacyIndexes[msg.sender] = _index;
    }

    function cancel() public {
        uint256 _index = legacyIndexes[msg.sender];
        require(legacies[_index].owner == msg.sender, "not owner!");
        delete legacies[_index];
        legacyIndexes[msg.sender] = 0;
    }

    function updateCheckInterval(uint256 _checkInterval) public {
        uint256 _index = legacyIndexes[msg.sender];
        require(legacies[_index].owner == msg.sender, "not owner!");
        legacies[_index].checkInterval = _checkInterval;
    }

    function updateLegatee(address _legatee) public {
        uint256 _index = legacyIndexes[msg.sender];
        require(legacies[_index].owner == msg.sender, "not owner!");
        legacies[_index].legatee = _legatee;
    }

    function checkIn() public {
        uint256 _index = legacyIndexes[msg.sender];
        require(legacies[_index].owner == msg.sender, "not owner!");
        legacies[_index].lastSeen = block.timestamp;
    }

    function getLegacyTokens(uint256 _index) public view returns(address[] memory) {
        return legacies[_index].tokens;
    }

    function addTokens(address[] memory _tokens) public {
	uint256 _index = legacyIndexes[msg.sender];
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 _token = IERC20(_tokens[i]);
            //Confirm token approval
            require(_token.allowance(msg.sender, address(this)) == type(uint256).max, "not approved!");
            legacies[_index].tokens.push(_tokens[i]);
        }
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData ) {
        upkeepNeeded = false;
        //Get 10 legacies due for fulfillment
        for (uint256 i = 0; i < legacies.length; i++) {
            Legacy memory _legacy = legacies[i];
            if (!_legacy.fulfilled && block.timestamp - _legacy.lastSeen > _legacy.checkInterval) {
                upkeepNeeded = true;
                performData = abi.encode(i);
                break;
            }
        }

    }

    function performUpkeep(bytes calldata performData ) external override {
        //Decode perfromData
        uint256 index = abi.decode(performData, (uint256));

        Legacy memory _legacy = legacies[index];    
        //Confirm performData
        require(block.timestamp - _legacy.lastSeen > _legacy.checkInterval, "not due!" );
        legacies[index].fulfilled = true;

        //Transfer tokens to legatee
        for (uint256 i = 0; i < _legacy.tokens.length; i++) {
  		    address _token = _legacy.tokens[i];
            uint256 _allowed = IERC20(_token).allowance(_legacy.owner, address(this));
            uint256 _balance = IERC20(_token).balanceOf(_legacy.owner);
            // Skip tokens not approved
            if (_allowed < _balance) {
                continue;
            }
            TransferHelper.safeTransferFrom(
                _token,
                _legacy.owner,
                _legacy.legatee,
                _balance
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

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