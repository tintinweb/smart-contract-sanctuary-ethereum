// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
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

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// AutomationCompatible.sol imports the functions from both ./AutomationBase.sol and
// ./interfaces/AutomationCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "./TransferHelper.sol";

interface IERC20 {
    function balanceOf(address owner) external returns (uint256 balance);

    function allowance(address owner, address spender)
        external
        returns (uint256 remaining);
}

contract Legacy is AutomationCompatibleInterface {
    LEGACY[] private legacies;
    mapping(address => uint256) private legacyId;

    struct LEGACY {
        address owner;
        address legatee;
        address[] tokens;
        uint256 lastSeen;
        uint256 checkInterval;
        bool fulfilled;
    }

    constructor() {
        create(address(0), 0);
    }

    modifier hasActiveLegacy(address _owner) {
        uint256 _index = legacyId[msg.sender];
        require(_index != 0, "You do not have an active legacy!");
        _;
    }

    function create(address _legatee, uint256 _checkInterval) public {
        uint256 _index = legacies.length;
        // Revert if msg.sender already has an active legacy!
        require(legacyId[msg.sender] == 0, "Legacy exist!");
        legacies.push(
            LEGACY(
                msg.sender,
                _legatee,
                new address[](0),
                block.timestamp,
                _checkInterval,
                false
            )
        );
        legacyId[msg.sender] = _index;
    }

    function cancel() public hasActiveLegacy(msg.sender) {
        delete legacies[legacyId[msg.sender]];
        legacyId[msg.sender] = 0;
    }

    function update(address _legatee, uint256 _checkInterval)
        public
        hasActiveLegacy(msg.sender)
    {
        uint256 _index = legacyId[msg.sender];
        legacies[_index].checkInterval = _checkInterval;
        legacies[_index].legatee = _legatee;
    }

    function checkIn() public hasActiveLegacy(msg.sender) {
        uint256 _index = legacyId[msg.sender];
        legacies[_index].lastSeen = block.timestamp;
    }

    function addTokens(address[] memory _tokens) public {
        uint256 _index = legacyId[msg.sender];
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 _token = IERC20(_tokens[i]);
            //Confirm token approval
            require(
                _token.allowance(msg.sender, address(this)) ==
                    type(uint256).max,
                "token not approved!"
            );
            legacies[_index].tokens.push(_tokens[i]);
        }
    }

    function updateCheckInterval(uint256 _checkInterval)
        public
        hasActiveLegacy(msg.sender)
    {
        uint256 _index = legacyId[msg.sender];
        legacies[_index].checkInterval = _checkInterval;
    }

    function updateHeir(address _legatee) public hasActiveLegacy(msg.sender) {
        uint256 _index = legacyId[msg.sender];
        legacies[_index].legatee = _legatee;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        uint256 _nextDueLegacy = _getNextDueLegacy();
        if (_nextDueLegacy == 0) {
            upkeepNeeded = false;
        } else {
            upkeepNeeded = true;
            performData = abi.encode(_nextDueLegacy);
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        //Decode perfromData
        uint256 _id = abi.decode(performData, (uint256));
        _fufillLegacy(_id);
    }

    // Getters

    function getLegacy(address _owner) public view returns (LEGACY memory) {
        return legacies[legacyId[_owner]];
    }

    function getLegacyTokens(address _owner)
        public
        view
        returns (address[] memory)
    {
        return legacies[legacyId[_owner]].tokens;
    }

    function hasLegacy(address _owner) public view returns (bool) {
        if (legacyId[_owner] == 0) {
            return false;
        } else {
            return true;
        }
    }

    // Internal functions
    function _getNextDueLegacy() internal view returns (uint256) {
        for (uint256 i = 1; i < legacies.length; i++) {
            LEGACY memory _legacy = legacies[i];
            if (
                !_legacy.fulfilled &&
                block.timestamp - _legacy.lastSeen > _legacy.checkInterval
            ) {
                return i;
            }
        }
        return 0;
    }

    function _fufillLegacy(uint256 _id) internal {
        LEGACY memory _legacy = legacies[_id];
        //Confirm legacy is due
        require(
            block.timestamp - _legacy.lastSeen > _legacy.checkInterval,
            "not due!"
        );
        legacies[_id].fulfilled = true;

        //Transfer tokens to legatee
        for (uint256 i = 0; i < _legacy.tokens.length; i++) {
            address _token = _legacy.tokens[i];
            uint256 _allowed = IERC20(_token).allowance(
                _legacy.owner,
                address(this)
            );
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