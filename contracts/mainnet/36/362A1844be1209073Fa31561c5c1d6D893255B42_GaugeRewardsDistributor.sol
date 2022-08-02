// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "solmate/src/utils/ReentrancyGuard.sol";

import "./IGaugeController.sol";
import {MiddlemanGauge} from "./MiddlemanGauge.sol";
import "../Staking/Owned.sol";

contract GaugeRewardsDistributor is Owned, ReentrancyGuard {
    using SafeTransferLib for ERC20;

    /* ========== STATE VARIABLES ========== */

    // Instances and addresses
    address public immutable reward_token_address;
    IGaugeController public gauge_controller;

    // Admin addresses
    address public timelock_address;
    address public curator_address;

    // Constants
    uint256 private constant MULTIPLIER_PRECISION = 1e18;
    uint256 private constant ONE_WEEK = 604800;

    // Gauge controller related
    mapping(address => bool) public gauge_whitelist;
    mapping(address => bool) public is_middleman; // For cross-chain farms, use a middleman contract to push to a bridge
    mapping(address => uint256) public last_time_gauge_paid;

    // Booleans
    bool public distributionsOn;

    // Uints
    uint256 public global_emission_rate;

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnGov() {
        require(
            msg.sender == owner || msg.sender == timelock_address,
            "Not owner or timelock"
        );
        _;
    }

    modifier onlyByOwnerOrCuratorOrGovernance() {
        require(
            msg.sender == owner ||
                msg.sender == curator_address ||
                msg.sender == timelock_address,
            "Not owner, curator, or timelock"
        );
        _;
    }

    modifier isDistributing() {
        require(distributionsOn == true, "Distributions are off");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner,
        address _timelock_address,
        address _curator_address,
        address _reward_token_address,
        address _gauge_controller_address,
        uint256 _global_emission_rate
    ) Owned(_owner) {
        curator_address = _curator_address;
        timelock_address = _timelock_address;

        reward_token_address = _reward_token_address;
        gauge_controller = IGaugeController(_gauge_controller_address);

        distributionsOn = true;

        global_emission_rate = _global_emission_rate;
    }

    /* ========== VIEWS ========== */

    // Current weekly reward amount
    function currentReward(address gauge_address)
        public
        view
        returns (uint256 reward_amount)
    {
        uint256 rel_weight = gauge_controller.gauge_relative_weight(
            gauge_address,
            block.timestamp
        );
        uint256 rwd_rate = (global_emission_rate * rel_weight) / 1e18;
        reward_amount = rwd_rate * ONE_WEEK;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // Callable by anyone
    function distributeReward(address gauge_address)
        public
        isDistributing
        nonReentrant
        returns (uint256 weeks_elapsed, uint256 reward_tally)
    {
        require(gauge_whitelist[gauge_address], "Gauge not whitelisted");

        // Calculate the elapsed time in weeks.
        uint256 last_time_paid = last_time_gauge_paid[gauge_address];

        // Edge case for first reward for this gauge
        if (last_time_paid == 0) {
            weeks_elapsed = 1;
        } else {
            // Truncation desired
            weeks_elapsed =
                (block.timestamp - last_time_gauge_paid[gauge_address]) /
                ONE_WEEK;

            // Return early here for 0 weeks instead of throwing, as it could have bad effects in other contracts
            if (weeks_elapsed == 0) {
                return (0, 0);
            }
        }

        // NOTE: This will always use the current global_emission_rate()
        reward_tally = 0;
        for (uint256 i = 0; i < (weeks_elapsed); i++) {
            uint256 rel_weight_at_week;
            if (i == 0) {
                // Mutative, for the current week. Makes sure the weight is checkpointed. Also returns the weight.
                rel_weight_at_week = gauge_controller
                    .gauge_relative_weight_write(
                        gauge_address,
                        block.timestamp
                    );
            } else {
                // View
                rel_weight_at_week = gauge_controller.gauge_relative_weight(
                    gauge_address,
                    block.timestamp - (ONE_WEEK * i)
                );
            }
            uint256 rwd_rate_at_week = (global_emission_rate *
                rel_weight_at_week) / 1e18;
            reward_tally = reward_tally + rwd_rate_at_week * ONE_WEEK;
        }

        // Update the last time paid
        last_time_gauge_paid[gauge_address] = block.timestamp;

        if (is_middleman[gauge_address]) {
            // Cross chain: Pay out the rewards to the middleman contract
            // Approve for the middleman first
            ERC20(reward_token_address).approve(gauge_address, reward_tally);

            // Trigger the middleman
            MiddlemanGauge(gauge_address).pullAndBridge(reward_tally);
        } else {
            // Mainnet: Pay out the rewards directly to the gauge
            ERC20(reward_token_address).safeTransfer(
                gauge_address,
                reward_tally
            );
        }

        emit RewardDistributed(gauge_address, reward_tally);
    }

    /* ========== RESTRICTED FUNCTIONS - Curator / migrator callable ========== */

    // For emergency situations
    function toggleDistributions() external onlyByOwnerOrCuratorOrGovernance {
        distributionsOn = !distributionsOn;

        emit DistributionsToggled(distributionsOn);
    }

    /* ========== RESTRICTED FUNCTIONS - Owner or timelock only ========== */

    // Added to support recovering LP Rewards and other mistaken tokens from other systems to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyByOwnGov
    {
        // Only the owner address can ever receive the recovery withdrawal
        ERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit RecoveredERC20(tokenAddress, tokenAmount);
    }

    function setGaugeState(
        address _gauge_address,
        bool _is_middleman,
        bool _is_active
    ) external onlyByOwnGov {
        is_middleman[_gauge_address] = _is_middleman;
        gauge_whitelist[_gauge_address] = _is_active;

        emit GaugeStateChanged(_gauge_address, _is_middleman, _is_active);
    }

    function setTimelock(address _new_timelock) external onlyByOwnGov {
        timelock_address = _new_timelock;
    }

    function setCurator(address _new_curator_address) external onlyByOwnGov {
        curator_address = _new_curator_address;
    }

    function setGaugeController(address _gauge_controller_address)
        external
        onlyByOwnGov
    {
        gauge_controller = IGaugeController(_gauge_controller_address);
    }

    function setGlobalEmissionRate(uint256 _global_emission_rate)
        external
        onlyByOwnGov
    {
        global_emission_rate = _global_emission_rate;
    }

    /* ========== EVENTS ========== */

    event RewardDistributed(
        address indexed gauge_address,
        uint256 reward_amount
    );
    event RecoveredERC20(address token, uint256 amount);
    event GaugeStateChanged(
        address gauge_address,
        bool is_middleman,
        bool is_active
    );
    event DistributionsToggled(bool distibutions_state);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

// https://github.com/swervefi/swerve/edit/master/packages/swerve-contracts/interfaces/IGaugeController.sol

interface IGaugeController {
    struct Point {
        uint256 bias;
        uint256 slope;
    }

    struct VotedSlope {
        uint256 slope;
        uint256 power;
        uint256 end;
    }

    // Public variables
    function admin() external view returns (address);

    function token() external view returns (address);

    function voting_escrow() external view returns (address);

    function n_gauge_types() external view returns (int128);

    function n_gauges() external view returns (int128);

    function gauge_type_names(int128) external view returns (string memory);

    function gauges(uint256) external view returns (address);

    function vote_user_slopes(address, address)
        external
        view
        returns (VotedSlope memory);

    function vote_user_power(address) external view returns (uint256);

    function last_user_vote(address, address) external view returns (uint256);

    function points_weight(address, uint256)
        external
        view
        returns (Point memory);

    function time_weight(address) external view returns (uint256);

    function points_sum(int128, uint256) external view returns (Point memory);

    function time_sum(uint256) external view returns (uint256);

    function points_total(uint256) external view returns (uint256);

    function time_total() external view returns (uint256);

    function points_type_weight(int128, uint256)
        external
        view
        returns (uint256);

    function time_type_weight(uint256) external view returns (uint256);

    // Getter functions
    function gauge_types(address) external view returns (int128);

    function gauge_relative_weight(address) external view returns (uint256);

    function gauge_relative_weight(address, uint256)
        external
        view
        returns (uint256);

    function get_gauge_weight(address) external view returns (uint256);

    function get_type_weight(int128) external view returns (uint256);

    function get_total_weight() external view returns (uint256);

    function get_weights_sum_per_type(int128) external view returns (uint256);

    // External functions
    function add_gauge(
        address,
        int128,
        uint256
    ) external;

    function checkpoint() external;

    function checkpoint_gauge(address) external;

    function gauge_relative_weight_write(address) external returns (uint256);

    function gauge_relative_weight_write(address, uint256)
        external
        returns (uint256);

    function add_type(string memory, uint256) external;

    function change_type_weight(int128, uint256) external;

    function change_gauge_weight(address, uint256) external;

    function vote_for_gauge_weights(address, uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IGaugeRewardsDistributor {
    function acceptOwnership() external;

    function curator_address() external view returns (address);

    function currentReward(address gauge_address)
        external
        view
        returns (uint256 reward_amount);

    function distributeReward(address gauge_address)
        external
        returns (uint256 weeks_elapsed, uint256 reward_tally);

    function distributionsOn() external view returns (bool);

    function gauge_whitelist(address) external view returns (bool);

    function is_middleman(address) external view returns (bool);

    function last_time_gauge_paid(address) external view returns (uint256);

    function nominateNewOwner(address _owner) external;

    function nominatedOwner() external view returns (address);

    function owner() external view returns (address);

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;

    function setCurator(address _new_curator_address) external;

    function setGaugeController(address _gauge_controller_address) external;

    function setGaugeState(
        address _gauge_address,
        bool _is_middleman,
        bool _is_active
    ) external;

    function setTimelock(address _new_timelock) external;

    function timelock_address() external view returns (address);

    function toggleDistributions() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "solmate/src/utils/ReentrancyGuard.sol";

import "./IGaugeRewardsDistributor.sol";
import "../Misc_AMOs/harmony/IERC20EthManager.sol";
import "../Misc_AMOs/polygon/IRootChainManager.sol";
import "../Misc_AMOs/solana/IWormhole.sol";
import "../Staking/Owned.sol";

contract MiddlemanGauge is Owned, ReentrancyGuard {
    using SafeTransferLib for ERC20;

    /* ========== STATE VARIABLES ========== */

    address public immutable reward_token_address;

    // Instances and addresses
    address public rewards_distributor_address;

    // Informational
    string public name;

    // Admin addresses
    address public timelock_address;

    // Tracking
    uint32 public fake_nonce;

    // Gauge-related
    uint32 public bridge_type;
    address public bridge_address;
    address public destination_address_override;
    string public non_evm_destination_address;

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnGov() {
        require(
            msg.sender == owner || msg.sender == timelock_address,
            "Not owner or timelock"
        );
        _;
    }

    modifier onlyRewardsDistributor() {
        require(
            msg.sender == rewards_distributor_address,
            "Not rewards distributor"
        );
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner,
        address _reward_token_address,
        address _timelock_address,
        address _rewards_distributor_address,
        address _bridge_address,
        uint32 _bridge_type,
        address _destination_address_override,
        string memory _non_evm_destination_address,
        string memory _name
    ) Owned(_owner) {
        reward_token_address = _reward_token_address;
        timelock_address = _timelock_address;

        rewards_distributor_address = _rewards_distributor_address;

        bridge_address = _bridge_address;
        bridge_type = _bridge_type;
        destination_address_override = _destination_address_override;
        non_evm_destination_address = _non_evm_destination_address;

        name = _name;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // Callable only by the rewards distributor
    function pullAndBridge(uint256 reward_amount)
        external
        onlyRewardsDistributor
        nonReentrant
    {
        require(bridge_address != address(0), "Invalid bridge address");

        // Pull in the rewards from the rewards distributor
        ERC20(reward_token_address).safeTransferFrom(
            rewards_distributor_address,
            address(this),
            reward_amount
        );

        address address_to_send_to = address(this);
        if (destination_address_override != address(0))
            address_to_send_to = destination_address_override;

        if (bridge_type == 0) {
            // Avalanche [Anyswap]
            ERC20(reward_token_address).safeTransfer(
                bridge_address,
                reward_amount
            );
        } else if (bridge_type == 1) {
            // BSC
            ERC20(reward_token_address).safeTransfer(
                bridge_address,
                reward_amount
            );
        } else if (bridge_type == 2) {
            // Fantom [Multichain / Anyswap]
            // Bridge is 0xC564EE9f21Ed8A2d8E7e76c085740d5e4c5FaFbE
            ERC20(reward_token_address).safeTransfer(
                bridge_address,
                reward_amount
            );
        } else if (bridge_type == 3) {
            // Polygon
            // Bridge is 0xA0c68C638235ee32657e8f720a23ceC1bFc77C77
            // Interesting info https://blog.cryption.network/cryption-network-launches-cross-chain-staking-6cf000c25477

            // Approve
            IRootChainManager rootChainMgr = IRootChainManager(bridge_address);
            bytes32 tokenType = rootChainMgr.tokenToType(reward_token_address);
            address predicate = rootChainMgr.typeToPredicate(tokenType);
            ERC20(reward_token_address).approve(predicate, reward_amount);

            // DepositFor
            bytes memory depositData = abi.encode(reward_amount);
            rootChainMgr.depositFor(
                address_to_send_to,
                reward_token_address,
                depositData
            );
        } else if (bridge_type == 4) {
            // Solana
            // Wormhole Bridge is 0xf92cD566Ea4864356C5491c177A430C222d7e678

            revert("Not supported yet");

            // // Approve
            // ERC20(reward_token_address).approve(bridge_address, reward_amount);

            // // lockAssets
            // require(non_evm_destination_address != 0, "Invalid destination");
            // // non_evm_destination_address = base58 -> hex
            // // https://www.appdevtools.com/base58-encoder-decoder
            // IWormhole(bridge_address).lockAssets(
            //     reward_token_address,
            //     reward_amount,
            //     non_evm_destination_address,
            //     1,
            //     fake_nonce,
            //     false
            // );
        } else if (bridge_type == 5) {
            // Harmony
            // Bridge is at 0x2dccdb493827e15a5dc8f8b72147e6c4a5620857

            // Approve
            ERC20(reward_token_address).approve(bridge_address, reward_amount);

            // lockToken
            IERC20EthManager(bridge_address).lockToken(
                reward_token_address,
                reward_amount,
                address_to_send_to
            );
        }

        // fake_nonce += 1;
    }

    /* ========== RESTRICTED FUNCTIONS - Owner or timelock only ========== */

    // Added to support recovering LP Rewards and other mistaken tokens from other systems to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyByOwnGov
    {
        // Only the owner address can ever receive the recovery withdrawal
        ERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit RecoveredERC20(tokenAddress, tokenAmount);
    }

    // Generic proxy
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyByOwnGov returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        return (success, result);
    }

    function setTimelock(address _new_timelock) external onlyByOwnGov {
        timelock_address = _new_timelock;
    }

    function setBridgeInfo(
        address _bridge_address,
        uint32 _bridge_type,
        address _destination_address_override,
        string memory _non_evm_destination_address
    ) external onlyByOwnGov {
        bridge_address = _bridge_address;

        // 0: Avalanche
        // 1: BSC
        // 2: Fantom
        // 3: Polygon
        // 4: Solana
        // 5: Harmony
        bridge_type = _bridge_type;

        // Overridden cross-chain destination address
        destination_address_override = _destination_address_override;

        // Set bytes32 / non-EVM address on the other chain, if applicable
        non_evm_destination_address = _non_evm_destination_address;

        emit BridgeInfoChanged(
            _bridge_address,
            _bridge_type,
            _destination_address_override,
            _non_evm_destination_address
        );
    }

    function setRewardsDistributor(address _rewards_distributor_address)
        external
        onlyByOwnGov
    {
        rewards_distributor_address = _rewards_distributor_address;
    }

    /* ========== EVENTS ========== */

    event RecoveredERC20(address token, uint256 amount);
    event BridgeInfoChanged(
        address bridge_address,
        uint256 bridge_type,
        address destination_address_override,
        string non_evm_destination_address
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;
pragma experimental ABIEncoderV2;

interface IERC20EthManager {
    function lockToken(
        address ethTokenAddr,
        uint256 amount,
        address recipient
    ) external;

    function lockTokenFor(
        address ethTokenAddr,
        address userAddr,
        uint256 amount,
        address recipient
    ) external;

    function unlockToken(
        address ethTokenAddr,
        uint256 amount,
        address recipient,
        bytes32 receiptId
    ) external;

    function usedEvents_(bytes32) external view returns (bool);

    function wallet() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;
pragma experimental ABIEncoderV2;

interface IRootChainManager {
    function depositFor(
        address user,
        address rootToken,
        bytes memory depositData
    ) external;

    function tokenToType(address) external view returns (bytes32);

    function typeToPredicate(bytes32) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;
pragma experimental ABIEncoderV2;

interface IWormhole {
    function guardian_set_expirity() external view returns (uint32);

    function guardian_set_index() external view returns (uint32);

    function guardian_sets(uint32)
        external
        view
        returns (uint32 expiration_time);

    function isWrappedAsset(address) external view returns (bool);

    function lockAssets(
        address asset,
        uint256 amount,
        bytes32 recipient,
        uint8 target_chain,
        uint32 nonce,
        bool refund_dust
    ) external;

    function lockETH(
        bytes32 recipient,
        uint8 target_chain,
        uint32 nonce
    ) external;

    function wrappedAssetMaster() external view returns (address);

    function wrappedAssets(bytes32) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

// https://docs.synthetix.io/contracts/Owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(
            msg.sender == nominatedOwner,
            "You must be nominated before you can accept ownership"
        );
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner may perform this action"
        );
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}