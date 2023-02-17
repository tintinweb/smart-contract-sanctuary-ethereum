/**
 *     SPDX-License-Identifier: Apache License 2.0
 *
 *     Copyright 2018 Set Labs Inc.
 *     Copyright 2022 Smash Works Inc.
 *
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 *     NOTICE
 *
 *     This is a modified code from Set Labs Inc. found at
 *
 *     https://github.com/SetProtocol/set-protocol-contracts
 *
 *     All changes made by Smash Works Inc. are described and documented at
 *
 *     https://docs.arch.finance/chambers
 *
 *
 *             %@@@@@
 *          @@@@@@@@@@@
 *        #@@@@@     @@@           @@                   @@
 *       @@@@@@       @@@         @@@@                  @@
 *      @@@@@@         @@        @@  @@    @@@@@ @@@@@  @@@*@@
 *     [email protected]@@@@          @@@      @@@@@@@@   @@    @@     @@  @@
 *     @@@@@(       (((((      @@@    @@@  @@    @@@@@  @@  @@
 *    @@@@@@   (((((((
 *    @@@@@#(((((((
 *    @@@@@(((((
 *      @@@((
 */
pragma solidity ^0.8.17.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IChamber} from "./interfaces/IChamber.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {IStreamingFeeWizard} from "./interfaces/IStreamingFeeWizard.sol";

contract StreamingFeeWizard is IStreamingFeeWizard, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/
    uint256 private constant ONE_YEAR_IN_SECONDS = 365.25 days;
    uint256 private constant SCALE_UNIT = 1 ether;
    mapping(IChamber => FeeState) public feeStates;

    /*//////////////////////////////////////////////////////////////
                              FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * Sets the initial _feeState to the chamber. The chamber needs to exist beforehand.
     * Will revert if msg.sender is not a a manager from the _chamber. The feeState
     * is structured as:
     *
     * {
     *   feeRecipient:              address; [mandatory]
     *   maxStreamingFeePercentage: uint256; [mandatory] < 100%
     *   streamingFeePercentage:    address; [mandatory] <= maxStreamingFeePercentage
     *   lastCollectTimestamp:      address; [optional]  any value
     * }
     *
     * Consider [1 % = 10e18] for the fees
     *
     * @param _chamber  Chamber to enable
     * @param _feeState     First feeState of the Chamber
     */
    function enableChamber(IChamber _chamber, FeeState memory _feeState) external nonReentrant {
        require(IChamber(_chamber).isManager(msg.sender), "msg.sender is not chamber's manager");
        require(_feeState.feeRecipient != address(0), "Recipient cannot be null address");
        require(_feeState.maxStreamingFeePercentage <= 100 * SCALE_UNIT, "Max fee must be <= 100%");
        require(
            _feeState.streamingFeePercentage <= _feeState.maxStreamingFeePercentage,
            "Fee must be <= Max fee"
        );
        require(feeStates[_chamber].lastCollectTimestamp < 1, "Chamber already exists");

        _feeState.lastCollectTimestamp = block.timestamp;
        feeStates[_chamber] = _feeState;
    }

    /**
     * Calculates total inflation percentage. Mints new tokens in the Chamber for the
     * streaming fee recipient. Then calls the chamber to update its quantities.
     *
     * @param _chamber Chamber to acquire streaming fees from
     */
    function collectStreamingFee(IChamber _chamber) external nonReentrant {
        uint256 previousCollectTimestamp = feeStates[_chamber].lastCollectTimestamp;
        require(previousCollectTimestamp > 0, "Chamber does not exist");
        require(previousCollectTimestamp < block.timestamp, "Cannot collect twice");
        uint256 currentStreamingFeePercentage = feeStates[_chamber].streamingFeePercentage;
        require(currentStreamingFeePercentage > 0, "Chamber fee is zero");

        feeStates[_chamber].lastCollectTimestamp = block.timestamp;

        uint256 inflationQuantity =
            _collectStreamingFee(_chamber, previousCollectTimestamp, currentStreamingFeePercentage);

        emit FeeCollected(address(_chamber), currentStreamingFeePercentage, inflationQuantity);
    }

    /**
     * Will collect pending fees, and then update the streaming fee percentage for the Chamber
     * specified. Cannot be larger than the maximum fee. Will revert if msg.sender is not a
     * manager from the _chamber. To disable a chamber, set the streaming fee to zero.
     *
     * @param _chamber          Chamber to update streaming fee percentage
     * @param _newFeePercentage     New streaming fee in percentage [1 % = 10e18]
     */
    function updateStreamingFee(IChamber _chamber, uint256 _newFeePercentage)
        external
        nonReentrant
    {
        uint256 previousCollectTimestamp = feeStates[_chamber].lastCollectTimestamp;
        require(previousCollectTimestamp > 0, "Chamber does not exist");
        require(previousCollectTimestamp < block.timestamp, "Cannot update fee after collecting");
        require(IChamber(_chamber).isManager(msg.sender), "msg.sender is not chamber's manager");
        require(
            _newFeePercentage <= feeStates[_chamber].maxStreamingFeePercentage,
            "New fee is above maximum"
        );
        uint256 currentStreamingFeePercentage = feeStates[_chamber].streamingFeePercentage;

        feeStates[_chamber].lastCollectTimestamp = block.timestamp;
        feeStates[_chamber].streamingFeePercentage = _newFeePercentage;

        if (currentStreamingFeePercentage > 0) {
            uint256 inflationQuantity = _collectStreamingFee(
                _chamber, previousCollectTimestamp, currentStreamingFeePercentage
            );
            emit FeeCollected(address(_chamber), currentStreamingFeePercentage, inflationQuantity);
        }

        emit StreamingFeeUpdated(address(_chamber), _newFeePercentage);
    }

    /**
     * Will update the maximum streaming fee of a chamber. The _newMaxFeePercentage
     * can only be lower than the current maximum streaming fee, and cannot be greater
     * than the current streaming fee. Will revert if msg.sender is not a manager from
     * the _chamber.
     *
     * @param _chamber          Chamber to update max. streaming fee percentage
     * @param _newMaxFeePercentage  New max. streaming fee in percentage [1 % = 10e18]
     */
    function updateMaxStreamingFee(IChamber _chamber, uint256 _newMaxFeePercentage)
        external
        nonReentrant
    {
        require(feeStates[_chamber].lastCollectTimestamp > 0, "Chamber does not exist");
        require(IChamber(_chamber).isManager(msg.sender), "msg.sender is not chamber's manager");
        require(
            _newMaxFeePercentage <= feeStates[_chamber].maxStreamingFeePercentage,
            "New max fee is above maximum"
        );
        require(
            _newMaxFeePercentage >= feeStates[_chamber].streamingFeePercentage,
            "New max fee is below current fee"
        );

        feeStates[_chamber].maxStreamingFeePercentage = _newMaxFeePercentage;

        emit MaxStreamingFeeUpdated(address(_chamber), _newMaxFeePercentage);
    }

    /**
     * Update the streaming fee recipient for the Chamber specified. Will revert if msg.sender
     * is not a manager from the _chamber.
     *
     * @param _chamber          Chamber to update streaming fee recipient
     * @param _newFeeRecipient      New fee recipient address
     */
    function updateFeeRecipient(IChamber _chamber, address _newFeeRecipient)
        external
        nonReentrant
    {
        require(feeStates[_chamber].lastCollectTimestamp > 0, "Chamber does not exist");
        require(IChamber(_chamber).isManager(msg.sender), "msg.sender is not chamber's manager");
        require(_newFeeRecipient != address(0), "Recipient cannot be null address");
        feeStates[_chamber].feeRecipient = _newFeeRecipient;

        emit FeeRecipientUpdated(address(_chamber), _newFeeRecipient);
    }

    /**
     * Returns the streaming fee recipient of the AcrhChamber specified.
     *
     * @param _chamber Chamber to consult
     */
    function getStreamingFeeRecipient(IChamber _chamber) external view returns (address) {
        require(feeStates[_chamber].lastCollectTimestamp > 0, "Chamber does not exist");
        return feeStates[_chamber].feeRecipient;
    }

    /**
     * Returns the maximum streaming fee percetage of the AcrhChamber specified.
     * Consider [1 % = 10e18]
     *
     * @param _chamber Chamber to consult
     */
    function getMaxStreamingFeePercentage(IChamber _chamber) external view returns (uint256) {
        require(feeStates[_chamber].lastCollectTimestamp > 0, "Chamber does not exist");
        return feeStates[_chamber].maxStreamingFeePercentage;
    }

    /**
     * Returns the streaming fee percetage of the AcrhChamber specified.
     * Consider [1 % = 10e18]
     *
     * @param _chamber Chamber to consult
     */
    function getStreamingFeePercentage(IChamber _chamber) external view returns (uint256) {
        require(feeStates[_chamber].lastCollectTimestamp > 0, "Chamber does not exist");
        return feeStates[_chamber].streamingFeePercentage;
    }

    /**
     * Returns the last streaming fee timestamp of the AcrhChamber specified.
     *
     * @param _chamber Chamber to consult
     */
    function getLastCollectTimestamp(IChamber _chamber) external view returns (uint256) {
        require(feeStates[_chamber].lastCollectTimestamp > 0, "Chamber does not exist");
        return feeStates[_chamber].lastCollectTimestamp;
    }

    /**
     * Returns the fee state of a chamber as a tuple.
     *
     * @param _chamber Chamber to consult
     */
    function getFeeState(IChamber _chamber)
        external
        view
        returns (
            address feeRecipient,
            uint256 maxStreamingFeePercentage,
            uint256 streamingFeePercentage,
            uint256 lastCollectTimestamp
        )
    {
        require(feeStates[_chamber].lastCollectTimestamp > 0, "Chamber does not exist");

        feeRecipient = feeStates[_chamber].feeRecipient;
        maxStreamingFeePercentage = feeStates[_chamber].maxStreamingFeePercentage;
        streamingFeePercentage = feeStates[_chamber].streamingFeePercentage;
        lastCollectTimestamp = feeStates[_chamber].lastCollectTimestamp;
        return
            (feeRecipient, maxStreamingFeePercentage, streamingFeePercentage, lastCollectTimestamp);
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * Given the current supply of an Chamber, the last timestamp and the current streaming fee,
     * this function returns the inflation quantity to mint. The formula to calculate inflation quantity
     * is this:
     *
     * currentSupply * (streamingFee [10e18] / 100 [10e18]) * ((now [s] - last [s]) / one_year [s])
     *
     * @param _currentSupply            Chamber current supply
     * @param _lastCollectTimestamp     Last timestamp of collect
     * @param _streamingFeePercentage   Current streaming fee
     */
    function _calculateInflationQuantity(
        uint256 _currentSupply,
        uint256 _lastCollectTimestamp,
        uint256 _streamingFeePercentage
    ) internal view returns (uint256 inflationQuantity) {
        uint256 blockWindow = block.timestamp - _lastCollectTimestamp;
        uint256 inflation = _streamingFeePercentage * blockWindow;
        uint256 a = _currentSupply * inflation;
        uint256 b = ONE_YEAR_IN_SECONDS * (100 * SCALE_UNIT);
        return a / b;
    }

    /**
     * Performs the collect fee on the Chamber, considering the Chamber current supply,
     * the last collect timestamp and the streaming fee percentage provided. It calls the Chamber
     * to mint the inflation amount, and then calls it again so the Chamber can update its quantities.
     *
     * @param _chamber              Chamber to collect fees from
     * @param _lastCollectTimestamp     Last collect timestamp to consider
     * @param _streamingFeePercentage   Streaming fee percentage to consider
     */
    function _collectStreamingFee(
        IChamber _chamber,
        uint256 _lastCollectTimestamp,
        uint256 _streamingFeePercentage
    ) internal returns (uint256 inflationQuantity) {
        // Get chamber supply
        uint256 currentSupply = IERC20(address(_chamber)).totalSupply();

        // Calculate inflation quantity
        inflationQuantity = _calculateInflationQuantity(
            currentSupply, _lastCollectTimestamp, _streamingFeePercentage
        );

        // Mint the inlation quantity
        IChamber(_chamber).mint(feeStates[_chamber].feeRecipient, inflationQuantity);

        // Calculate chamber new quantities
        IChamber(_chamber).updateQuantities();

        // Return inflation quantity
        return inflationQuantity;
    }
}

/**
 *     SPDX-License-Identifier: Apache License 2.0
 *
 *     Copyright 2018 Set Labs Inc.
 *     Copyright 2022 Smash Works Inc.
 *
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 *     NOTICE
 *
 *     This is a modified code from Set Labs Inc. found at
 *
 *     https://github.com/SetProtocol/set-protocol-contracts
 *
 *     All changes made by Smash Works Inc. are described and documented at
 *
 *     https://docs.arch.finance/chambers
 *
 *
 *             %@@@@@
 *          @@@@@@@@@@@
 *        #@@@@@     @@@           @@                   @@
 *       @@@@@@       @@@         @@@@                  @@
 *      @@@@@@         @@        @@  @@    @@@@@ @@@@@  @@@*@@
 *     [email protected]@@@@          @@@      @@@@@@@@   @@    @@     @@  @@
 *     @@@@@(       (((((      @@@    @@@  @@    @@@@@  @@  @@
 *    @@@@@@   (((((((
 *    @@@@@#(((((((
 *    @@@@@(((((
 *      @@@((
 */
pragma solidity ^0.8.17.0;

interface IChamber {
    /*//////////////////////////////////////////////////////////////
                                 ENUMS
    //////////////////////////////////////////////////////////////*/

    enum ChamberState {
        LOCKED,
        UNLOCKED
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ManagerAdded(address indexed _manager);

    event ManagerRemoved(address indexed _manager);

    event ConstituentAdded(address indexed _constituent);

    event ConstituentRemoved(address indexed _constituent);

    event WizardAdded(address indexed _wizard);

    event WizardRemoved(address indexed _wizard);

    event AllowedContractAdded(address indexed _allowedContract);

    event AllowedContractRemoved(address indexed _allowedContract);

    /*//////////////////////////////////////////////////////////////
                               CHAMBER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function addConstituent(address _constituent) external;

    function removeConstituent(address _constituent) external;

    function isManager(address _manager) external view returns (bool);

    function isWizard(address _wizard) external view returns (bool);

    function isConstituent(address _constituent) external view returns (bool);

    function addManager(address _manager) external;

    function removeManager(address _manager) external;

    function addWizard(address _wizard) external;

    function removeWizard(address _wizard) external;

    function getConstituentsAddresses() external view returns (address[] memory);

    function getQuantities() external view returns (uint256[] memory);

    function getConstituentQuantity(address _constituent) external view returns (uint256);

    function getWizards() external view returns (address[] memory);

    function getManagers() external view returns (address[] memory);

    function getAllowedContracts() external view returns (address[] memory);

    function mint(address _recipient, uint256 _quantity) external;

    function burn(address _from, uint256 _quantity) external;

    function withdrawTo(address _constituent, address _recipient, uint256 _quantity) external;

    function updateQuantities() external;

    function lockChamber() external;

    function unlockChamber() external;

    function addAllowedContract(address target) external;

    function removeAllowedContract(address target) external;

    function isAllowedContract(address _target) external returns (bool);

    function executeTrade(
        address _sellToken,
        uint256 _sellQuantity,
        address _buyToken,
        uint256 _minBuyQuantity,
        bytes memory _data,
        address payable _target,
        address _allowanceTarget
    ) external returns (uint256 tokenAmountBought);
}

/**
 *     SPDX-License-Identifier: Apache License 2.0
 *
 *     Copyright 2018 Set Labs Inc.
 *     Copyright 2022 Smash Works Inc.
 *
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 *     NOTICE
 *
 *     This is a modified code from Set Labs Inc. found at
 *
 *     https://github.com/SetProtocol/set-protocol-contracts
 *
 *     All changes made by Smash Works Inc. are described and documented at
 *
 *     https://docs.arch.finance/chambers
 *
 *
 *             %@@@@@
 *          @@@@@@@@@@@
 *        #@@@@@     @@@           @@                   @@
 *       @@@@@@       @@@         @@@@                  @@
 *      @@@@@@         @@        @@  @@    @@@@@ @@@@@  @@@*@@
 *     [email protected]@@@@          @@@      @@@@@@@@   @@    @@     @@  @@
 *     @@@@@(       (((((      @@@    @@@  @@    @@@@@  @@  @@
 *    @@@@@@   (((((((
 *    @@@@@#(((((((
 *    @@@@@(((((
 *      @@@((
 */
pragma solidity ^0.8.17.0;

import {IChamber} from "./IChamber.sol";

interface IStreamingFeeWizard {
    /*//////////////////////////////////////////////////////////////
                              STRUCT
    //////////////////////////////////////////////////////////////*/

    struct FeeState {
        address feeRecipient;
        uint256 maxStreamingFeePercentage;
        uint256 streamingFeePercentage;
        uint256 lastCollectTimestamp;
    }

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event FeeCollected(
        address indexed _chamber, uint256 _streamingFeePercentage, uint256 _inflationQuantity
    );
    event StreamingFeeUpdated(address indexed _chamber, uint256 _newStreamingFee);
    event MaxStreamingFeeUpdated(address indexed _chamber, uint256 _newMaxStreamingFee);
    event FeeRecipientUpdated(address indexed _chamber, address _newFeeRecipient);

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function enableChamber(IChamber _chamber, FeeState memory _feeState) external;
    function collectStreamingFee(IChamber _chamber) external;
    function updateStreamingFee(IChamber _chamber, uint256 _newFeePercentage) external;
    function updateMaxStreamingFee(IChamber _chamber, uint256 _newMaxFeePercentage) external;
    function updateFeeRecipient(IChamber _chamber, address _newFeeRecipient) external;
    function getStreamingFeeRecipient(IChamber _chamber) external view returns (address);
    function getMaxStreamingFeePercentage(IChamber _chamber) external view returns (uint256);
    function getStreamingFeePercentage(IChamber _chamber) external view returns (uint256);
    function getLastCollectTimestamp(IChamber _chamber) external view returns (uint256);
    function getFeeState(IChamber _chamber)
        external
        view
        returns (
            address feeRecipient,
            uint256 maxStreamingFeePercentage,
            uint256 streamingFeePercentage,
            uint256 lastCollectTimestamp
        );
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}