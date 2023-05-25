// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {IZoraUniversalMinter} from "./IZoraUniversalMinter.sol";
import {IMinterAgent} from "./IMinterAgent.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/// @title Zora Universal Minter.
/// @notice Immutable contract that mints tokens on behalf of an account on any standard ER721 or ERC1155 contract, and collects fees for Zora and optionally a rewards for a finder.
contract ZoraUniversalMinter is IZoraUniversalMinter {
    /// @dev Default fee zora collects per token minted
    uint256 constant ZORA_FEE_PER_TOKEN = 0.000222 ether;
    /// @dev Default reward finder collects per token minted
    uint256 constant FINDER_REWARD_PER_TOKEN = 0.000555 ether;
    /// @dev default fee zora collects per token minted when no finder is specified
    uint256 constant ZORA_FEE_PER_TOKEN_WHEN_NO_FINDER = ZORA_FEE_PER_TOKEN + FINDER_REWARD_PER_TOKEN;
    /// @dev Rewards allocated to addresses that can be withdran from later
    mapping(address => uint256) rewardAllocations;
    /// @dev How much has been withdrawn so far by each address
    mapping(address => uint256) withdrawn;

    /// @dev The address of the Protocol's fee recipient
    address public immutable zoraFeeRecipient;
    /// @dev The address of the minter agent implementation, which is cloned for each EOA
    address public immutable agentImpl;

    constructor(address _minterAgentImpl, address _zoraFeeRecipient) {
        zoraFeeRecipient = _zoraFeeRecipient;
        agentImpl = _minterAgentImpl;
    }

    /// Executes mint calls on a series of target ERC721 or ERC1155 contracts, then transfers the minted tokens to the calling account.
    /// Adds a mint fee to the msg.value sent to the contract.
    /// Assumes that the mint function for each target follows the ERC721 or ERC1155 standard for minting - which is that
    /// the a safe transfer is used to transfer tokens - and the corresponding safeTransfer callbacks on the receiving account are called AFTER minting the tokens.
    /// The value sent must include all the values to send to the minting contracts and the fees + reward amount.
    /// This can be determined by calling `fee`, and getting the requiredToSend parameter.
    /// @param _targets Addresses of contracts to call
    /// @param _calldatas Data to pass to the mint functions for each target
    /// @param _values Value to send to each target - must match the value required by the target's mint function.
    /// @param _tokensMinted Total number of tokens minted across all targets, used to calculate fees
    /// @param _finder Optional - address of finder that will receive a portion of the fees
    function mintBatch(
        address[] calldata _targets,
        bytes[] calldata _calldatas,
        uint256[] calldata _values,
        uint256 _tokensMinted,
        address _finder
    ) external payable {
        uint256 totalValue = _uncheckedSum(_values);

        // calculate fees
        (uint256 zoraFee, uint256 finderReward, uint256 totalWithFees) = fee(totalValue, _tokensMinted, _finder);

        emit MintedBatch(_targets, _values, _tokensMinted, _finder, msg.sender, totalWithFees, zoraFee, finderReward);

        // allocate the fees to the mint fee receiver and finder, which can be withdrawn against later.  Validates
        // that proper value has been sent.
        _allocateFeesAndRewards(zoraFee, finderReward, totalWithFees, _finder);

        _mintAll(msg.sender, totalValue, _targets, _calldatas, _values);
    }

    /// @notice Executes mint calls on a series of target ERC721 or ERC1155 contracts, then transfers the minted tokens to the calling account.
    /// Does not add a mint feee
    /// Assumes that the mint function for each target follows the ERC721 or ERC1155 standard for minting - which is that
    /// the a safe transfer is used to transfer tokens - and the corresponding safeTransfer callbacks on the receiving account are called AFTER minting the tokens.
    /// The value sent must equal the total values to send to the minting contracts.
    /// @param _targets Addresses of contracts to call
    /// @param _calldatas Data to pass to the mint functions for each target
    /// @param _values Value to send to each target - must match the value required by the target's mint function.
    function mintBatchWithoutFees(address[] calldata _targets, bytes[] calldata _calldatas, uint256[] calldata _values) external payable {
        uint256 totalValue = _uncheckedSum(_values);

        // make sure that enough value was sent to cover the fees + values needed to be sent to the contracts
        // Cannot realistically overflow
        if (totalValue != msg.value) {
            revert INSUFFICIENT_VALUE(totalValue, msg.value);
        }

        emit MintedBatch(_targets, _values, 0, address(0), msg.sender, 0, 0, 0);

        _mintAll(msg.sender, totalValue, _targets, _calldatas, _values);
    }

    /// Execute a mint call on a series a target ERC721 or ERC1155 contracts, then transfers the minted tokens to the calling account.
    /// Adds a mint fee to the msg.value sent to the contract.
    /// Assumes that the mint function for each target follows the ERC721 or ERC1155 standard for minting - which is that
    /// the a safe transfer is used to transfer tokens - and the corresponding safeTransfer callbacks on the receiving account are called AFTER minting the tokens.
    /// The value sent must include the value to send to the minting contract and the universal minter fee + finder reward amount.
    /// This can be determined by calling `fee`, and getting the requiredToSend parameter.
    /// @param _target Addresses of contract to call
    /// @param _calldata Data to pass to the mint function for the target
    /// @param _value Value to send to the target - must match the value required by the target's mint function.
    /// @param _tokensMinted Total number of tokens minted across all targets, used to calculate fees
    /// @param _finder Optional - address of finder that will receive a portion of the fees
    function mint(address _target, bytes calldata _calldata, uint256 _value, uint256 _tokensMinted, address _finder) external payable {
        IMinterAgent agent = _getOrCloneAgent(msg.sender);

        (uint256 zoraFee, uint256 finderReward, uint256 totalWithFees) = fee(_value, _tokensMinted, _finder);

        emit Minted(_target, _value, _tokensMinted, _finder, msg.sender, totalWithFees, zoraFee, finderReward);

        // allocate the fees to the mint fee receiver and rewards to the finder, which can be withdrawn against later
        _allocateFeesAndRewards(zoraFee, finderReward, totalWithFees, _finder);

        // mint the fokens for each target contract.  These will be transferred to the msg.caller.
        _mint(agent, _target, _calldata, _value);
    }

    /// Withdraws any fees that have been allocated to the caller's address to a specified address.
    /// @param to The address to withdraw to
    function withdraw(address to) external {
        uint256 feeAllocation = rewardAllocations[msg.sender];

        uint256 withdrawnSoFar = withdrawn[msg.sender];

        if (feeAllocation <= withdrawnSoFar) {
            revert NOTHING_TO_WITHDRAW();
        }

        uint256 toWithdraw = feeAllocation - withdrawnSoFar;

        withdrawn[msg.sender] = withdrawnSoFar + toWithdraw;

        _safeSend(toWithdraw, to);
    }

    /// Calculates the fees that will be collected for a given mint, based on the value and tokens minted.
    /// @param _mintValue Total value of the mint
    /// @param _tokensMinted Quantity of tokens minted
    /// @param _finderAddress Address of the finder, if any.  If the finder is the zora fee recipient, then the finder fee is 0.
    /// @return zoraFee The fee that will be allocated to the zora fee recipient
    /// @return finderReward The reward that will be allcoated to the finder
    /// @return requiredToSend The total value that must be sent to the contract, including fees
    function fee(
        uint256 _mintValue,
        uint256 _tokensMinted,
        address _finderAddress
    ) public view returns (uint256 zoraFee, uint256 finderReward, uint256 requiredToSend) {
        if (_finderAddress == address(0) || _finderAddress == zoraFeeRecipient) {
            unchecked {
                zoraFee = ZORA_FEE_PER_TOKEN_WHEN_NO_FINDER * _tokensMinted;
                requiredToSend = zoraFee + _mintValue;
            }
        } else {
            unchecked {
                zoraFee = ZORA_FEE_PER_TOKEN * _tokensMinted;
                finderReward = FINDER_REWARD_PER_TOKEN * _tokensMinted;
                requiredToSend = zoraFee + finderReward + _mintValue;
            }
        }
    }

    /// Has a minter agent execute a transaction on behalf of the calling acccount.  The minter
    /// agent's address will be the same for the calling account as the address that was
    /// used to mint the tokens.  Can be used to recover tokens that may get accidentally locked in
    /// the minter agent's contract address.
    /// @param _target Address of contract to call
    /// @param _calldata Calldata for arguments to call.
    function forwardCallFromAgent(address _target, bytes calldata _calldata, uint256 _additionalValue) external payable {
        IMinterAgent agent = _getOrCloneAgent(msg.sender);

        (bool success, bytes memory result) = agent.forwardCall{value: msg.value}(_target, _calldata, msg.value + _additionalValue);

        if (!success) {
            _handleForwardCallFail(result);
        }
    }

    /// @dev Unwraps a forward call failure to return the original error.  Useful
    /// for debugging failed minting calls.
    function _handleForwardCallFail(bytes memory result) private pure {
        // source: https://yos.io/2022/07/16/bubbling-up-errors-in-solidity/#:~:text=An%20inline%20assembly%20block%20is,object%20is%20returned%20in%20result%20.
        // if no error message, revert with generic error
        if (result.length == 0) {
            revert FORWARD_CALL_FAILED();
        }
        assembly {
            // We use Yul's revert() to bubble up errors from the target contract.
            revert(add(32, result), mload(result))
        }
    }

    /// Gets the deterministic address of the MinterAgent clone that gets created for a given recipient.
    /// @param recipient The account that the agent is cloned on behalf of.
    function agentAddress(address recipient) public view returns (address) {
        return Clones.predictDeterministicAddress(agentImpl, _agentSalt(recipient));
    }

    /// Creates a clone of an agent contract, which mints tokens on behalf of the msg.sender.  If a clone has already been created
    /// for that account, returns it.  Clone address is deterministic based on the recipient's address.
    /// Sends all tokens received as a result of minting to the recipient.
    /// @param callingAccount the account to receive tokens minted by this cloned agent.
    /// @return agent the created agent
    function _getOrCloneAgent(address callingAccount) private returns (IMinterAgent agent) {
        address targetAddress = agentAddress(callingAccount);
        if (targetAddress.code.length > 0) {
            return IMinterAgent(targetAddress);
        }

        address cloneAddress = Clones.cloneDeterministic(agentImpl, _agentSalt(callingAccount));
        agent = IMinterAgent(cloneAddress);
        agent.initialize(address(this), callingAccount);
    }

    /// @dev Unique salt generated from an address for a callingAccount that a MinterAgent is create for.
    function _agentSalt(address callingAccount) private pure returns (bytes32) {
        return bytes32(uint256(uint160(callingAccount)) << 96);
    }

    function _mint(IMinterAgent _agent, address _target, bytes calldata _calldata, uint256 _value) private {
        (bool success, bytes memory result) = _agent.forwardCall{value: _value}(_target, _calldata, _value);

        if (!success) {
            _handleForwardCallFail(result);
        }
    }

    /// @dev Iterates through minting calls and calls them each via a IMinterAgent.
    function _mintAll(
        address callingAccount,
        uint256 totalValueToSend,
        address[] calldata _targets,
        bytes[] calldata _calldatas,
        uint256[] calldata _values
    ) private {
        IMinterAgent _agent = _getOrCloneAgent(callingAccount);

        (bool success, bytes memory result) = _agent.forwardCallBatch{value: totalValueToSend}(_targets, _calldatas, _values);

        if (!success) {
            _handleForwardCallFail(result);
        }
    }

    /// Allocates fees and rewards which can be withdrawn against later.
    /// Validates that the proper value has been sent by the calling account.
    function _allocateFeesAndRewards(uint256 zoraFee, uint256 finderReward, uint256 requiredToBeSent, address finder) private {
        // make sure that the correct amount was sent
        if (requiredToBeSent != msg.value) {
            revert INSUFFICIENT_VALUE(requiredToBeSent, msg.value);
        }

        rewardAllocations[zoraFeeRecipient] += zoraFee;
        if (finderReward > 0) {
            rewardAllocations[finder] += finderReward;
        }
    }

    function _safeSend(uint256 amount, address to) private {
        (bool success, ) = to.call{value: amount}("");

        if (!success) revert FAILED_TO_SEND();
    }

    function _uncheckedSum(uint256[] calldata _values) private pure returns (uint256 totalValue) {
        unchecked {
            for (uint256 i = 0; i < _values.length; i++) {
                totalValue += _values[i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Zora Universal Minter
/// @notice Mints tokens on behalf of an account on any standard ER721 or ERC1155 contract, and collects fees for Zora and optionally a rewards for a finder
interface IZoraUniversalMinter {
    error MINT_EXECUTION_FAILED();
    error NOTHING_TO_WITHDRAW();
    error FORWARD_CALL_FAILED();
    error FAILED_TO_SEND();
    error INSUFFICIENT_VALUE(uint256 expectedValue, uint256 actualValue);

    event MintedBatch(
        address[] indexed targets,
        uint256[] values,
        uint256 tokensMinted,
        address finder,
        address indexed minter,
        uint256 indexed totalWithFees,
        uint256 zoraFee,
        uint256 finderFee
    );

    event Minted(
        address indexed target,
        uint256 value,
        uint256 tokensMinted,
        address finder,
        address indexed minter,
        uint256 indexed totalWithFees,
        uint256 zoraFee,
        uint256 finderFee
    );

    enum MintableTypes {
        NONE,
        ERC721,
        ERC1155,
        ERC1155_BATCH
    }

    /// Executes mint calls on a series of target ERC721 or ERC1155 contracts, then transfers the minted tokens to the calling account.
    /// Adds a mint fee to the msg.value sent to the contract.
    /// Assumes that the mint function for each target follows the ERC721 or ERC1155 standard for minting - which is that
    /// the a safe transfer is used to transfer tokens - and the corresponding safeTransfer callbacks on the receiving account are called AFTER minting the tokens.
    /// The value sent must include all the values to send to the minting contracts and the fees + reward amount.
    /// This can be determined by calling `fee`, and getting the requiredToSend parameter.
    /// @param _targets Addresses of contracts to call
    /// @param _calldatas Data to pass to the mint functions for each target
    /// @param _values Value to send to each target - must match the value required by the target's mint function.
    /// @param _tokensMinted Total number of tokens minted across all targets, used to calculate fees
    /// @param _finder Optional - address of finder that will receive a portion of the fees
    function mintBatch(
        address[] calldata _targets,
        bytes[] calldata _calldatas,
        uint256[] calldata _values,
        uint256 _tokensMinted,
        address _finder
    ) external payable;

    /// @notice Executes mint calls on a series of target ERC721 or ERC1155 contracts, then transfers the minted tokens to the calling account.
    /// Does not add a mint feee
    /// Assumes that the mint function for each target follows the ERC721 or ERC1155 standard for minting - which is that
    /// the a safe transfer is used to transfer tokens - and the corresponding safeTransfer callbacks on the receiving account are called AFTER minting the tokens.
    /// The value sent must equal the total values to send to the minting contracts.
    /// @param _targets Addresses of contracts to call
    /// @param _calldatas Data to pass to the mint functions for each target
    /// @param _values Value to send to each target - must match the value required by the target's mint function.
    function mintBatchWithoutFees(address[] calldata _targets, bytes[] calldata _calldatas, uint256[] calldata _values) external payable;

    /// Execute a mint call on a series a target ERC721 or ERC1155 contracts, then transfers the minted tokens to the calling account.
    /// Adds a mint fee to the msg.value sent to the contract.
    /// Assumes that the mint function for each target follows the ERC721 or ERC1155 standard for minting - which is that
    /// the a safe transfer is used to transfer tokens - and the corresponding safeTransfer callbacks on the receiving account are called AFTER minting the tokens.
    /// The value sent must include the value to send to the minting contract and the universal minter fee + finder reward amount.
    /// This can be determined by calling `fee`, and getting the requiredToSend parameter.
    /// @param _target Addresses of contract to call
    /// @param _calldata Data to pass to the mint function for the target
    /// @param _value Value to send to the target - must match the value required by the target's mint function.
    /// @param _tokensMinted Total number of tokens minted across all targets, used to calculate fees
    /// @param _finder Optional - address of finder that will receive a portion of the fees
    function mint(address _target, bytes calldata _calldata, uint256 _value, uint256 _tokensMinted, address _finder) external payable;

    /// Has a minter agent execute a transaction on behalf of the calling acccount.  The minter
    /// agent's address will be the same for the calling account as the address that was
    /// used to mint the tokens.  Can be used to recover tokens that may get accidentally locked in
    /// the minter agent's contract address.
    /// @param _target Address of contract to call
    /// @param _calldata Calldata for arguments to call.
    function forwardCallFromAgent(address _target, bytes calldata _calldata, uint256 _additionalValue) external payable;

    /// Withdraws any fees or rewards that have been allocated to the caller's address.  Fees can be withdrawn to any other specified address.
    /// @param to The address to withdraw to
    function withdraw(address to) external;

    /// Calculates the fees that will be collected for a given mint, based on the value and tokens minted.
    /// @param _mintValue Total value of the mint that is to be sent to external minting contracts
    /// @param _tokensMinted Quantity of tokens minted
    /// @param _finderAddress Address of the finder, if any.  If the finder is the zora fee recipient, then the finder fee is 0.
    /// @return zoraFee The fee that will be sent to the zora fee recipient
    /// @return finderReward The fee that will be sent to the finder
    /// @return requiredToSend The total value that must be sent to the contract, including fees
    function fee(
        uint256 _mintValue,
        uint256 _tokensMinted,
        address _finderAddress
    ) external view returns (uint256 zoraFee, uint256 finderReward, uint256 requiredToSend);

    /// Gets the deterministic address of the MinterAgent clone that gets created for a given recipient.
    /// @param recipient The account that the agent is cloned on behalf of.
    function agentAddress(address recipient) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMinterAgent {
    error ALREADY_INITIALIZED();
    error ONLY_OWNER();
    error ARRAY_LENGTH_MISMATCH();

    function initialize(address _owner, address _receiver) external;

    function forwardCall(address _target, bytes calldata _cd, uint256 _value) external payable returns (bool success, bytes memory data);

    function forwardCallBatch(
        address[] calldata _targets,
        bytes[] calldata _calldatas,
        uint256[] calldata _values
    ) external payable returns (bool success, bytes memory data);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}