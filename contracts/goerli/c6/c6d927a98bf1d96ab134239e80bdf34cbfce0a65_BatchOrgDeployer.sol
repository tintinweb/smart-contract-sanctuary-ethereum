// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

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
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x602d8060093d393df3363d3d373d3d3d363d7300000000000000000000000000)
            mstore(add(ptr, 0x13), shl(0x60, implementation))
            mstore(add(ptr, 0x27), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x36)
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
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x602d8060093d393df3363d3d373d3d3d363d7300000000000000000000000000)
            mstore(add(ptr, 0x13), shl(0x60, implementation))
            mstore(add(ptr, 0x27), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x36, salt)
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
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x602d8060093d393df3363d3d373d3d3d363d7300000000000000000000000000)
            mstore(add(ptr, 0x13), shl(0x60, implementation))
            mstore(add(ptr, 0x27), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x37), shl(0x60, deployer))
            mstore(add(ptr, 0x4b), salt)
            mstore(add(ptr, 0x6b), keccak256(ptr, 0x36))
            predicted := keccak256(add(ptr, 0x36), 0x55)
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

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

    /*///////////////////////////////////////////////////////////////
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

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

import {OrgFundFactory} from "./OrgFundFactory.sol";
import {Entity} from "./Entity.sol";
import {Org} from "./Org.sol";

/**
 * @notice Contract used to deploy a batch of Orgs at once, in case anyone wants to do
 * this in bulk instead of performing multiple single deploy transactions
 */
contract BatchOrgDeployer {
    /// @notice The OrgFundFactory contract we'll use to batch deploy
    OrgFundFactory public immutable orgFundFactory;

    /// @notice Emitted when a batch is deployed
    event EntityBatchDeployed(address indexed caller, uint8 indexed entityType, uint256 batchSize);

    constructor(OrgFundFactory _orgFundFactory) {
        orgFundFactory = _orgFundFactory;
    }

    /// @notice Deploys a batch of Orgs, given an array of orgIds
    /// @param _orgIds The array of orgIds to deploy
    /// @dev Function will throw in case an org with a same `orgId` already exists since factory uses determinist `create2`, so only pass org ids that have not yet been deployed
    function batchDeploy(bytes32[] calldata _orgIds) external {
        for (uint256 i = 0; i < _orgIds.length; i++) {
            orgFundFactory.deployOrg(_orgIds[i]);
        }
        emit EntityBatchDeployed(msg.sender, 1, _orgIds.length);
    }
}

//SPDX-License-Identifier: BSD 3-Clause
pragma solidity >=0.8.0;

import "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeTransferLib.sol";
import "./lib/ReentrancyGuard.sol";

import {Registry} from "./Registry.sol";
import {ISwapWrapper} from "./interfaces/ISwapWrapper.sol";
import {EndaomentAuth} from "./lib/auth/EndaomentAuth.sol";
import {Portfolio} from "./Portfolio.sol";
import {Math} from "./lib/Math.sol";

error EntityInactive();
error PortfolioInactive();
error InsufficientFunds();
error InvalidAction();
error BalanceMismatch();
error CallFailed(bytes response);

/**
 * @notice Entity contract inherited by Org and Fund contracts (and all future kinds of Entities).
 */
abstract contract Entity is EndaomentAuth, ReentrancyGuard {
    using Math for uint256;
    using SafeTransferLib for ERC20;

    /// @notice The base registry to which the entity is connected.
    Registry public registry;

    /// @notice The entity's manager.
    address public manager;

    // @notice The base token used for tracking the entity's fund balance.
    ERC20 public baseToken;

    /// @notice The current balance for the entity, denominated in the base token's units.
    uint256 public balance;

    /// @notice Placeholder address used in swapping method to denote usage of ETH instead of a token.
    address public constant ETH_PLACEHOLDER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice Emitted when manager is set.
    event EntityManagerSet(address indexed oldManager, address indexed newManager);

    /// @notice Emitted when a donation is made.
    event EntityDonationReceived(
        address indexed from,
        address indexed to,
        address indexed tokenIn,
        uint256 amountIn,
        uint256 amountReceived,
        uint256 amountFee
    );

    /// @notice Emitted when a payout is made from an entity.
    event EntityValuePaidOut(address indexed from, address indexed to, uint256 amountSent, uint256 amountFee);

    /// @notice Emitted when a transfer is made between entities.
    event EntityValueTransferred(address indexed from, address indexed to, uint256 amountReceived, uint256 amountFee);

    /// @notice Emitted when a base token reconciliation completes
    event EntityBalanceReconciled(address indexed entity, uint256 amountReceived, uint256 amountFee);

    /// @notice Emitted when a base token balance is used to correct the internal contract balance.
    event EntityBalanceCorrected(address indexed entity, uint256 newBalance);

    /// @notice Emitted when a portfolio deposit is made.
    event EntityDeposit(address indexed portfolio, uint256 baseTokenDeposited, uint256 sharesReceived);

    /// @notice Emitted when a portfolio share redemption is made.
    event EntityRedeem(address indexed portfolio, uint256 sharesRedeemed, uint256 baseTokenReceived);

    /// @notice Emitted when ether is received.
    event EntityEthReceived(address indexed sender, uint256 amount);

    /**
     * @notice Modifier for methods that require auth and that the manager can access.
     * @dev Uses the same condition as `requiresAuth` but with added manager access.
     */
    modifier requiresManager() {
        if (msg.sender != manager && !isAuthorized(msg.sender, msg.sig)) revert Unauthorized();
        _;
    }

    /// @notice Each entity will implement this function to allow a caller to interrogate what kind of entity it is.
    function entityType() public pure virtual returns (uint8);

    /**
     * @notice One time method to be called at deployment to configure the contract. Required so Entity
     * contracts can be deployed as minimal proxies (clones).
     * @param _registry The registry to host the Entity.
     * @param _manager The address of the Entity's manager.
     */
    function __initEntity(Registry _registry, address _manager) internal {
        // Call to EndaomentAuth's initialize function ensures that this can't be called again
        __initEndaomentAuth(_registry, bytes20(bytes.concat("entity", bytes1(entityType()))));
        __initReentrancyGuard();
        registry = _registry;
        manager = _manager;
        baseToken = _registry.baseToken();
    }

    /**
     * @notice Set a new manager for this entity.
     * @param _manager Address of new manager.
     * @dev Callable by current manager or permissioned role.
     */
    function setManager(address _manager) external virtual requiresManager {
        emit EntityManagerSet(manager, _manager);
        manager = _manager;
    }

    /**
     * @notice Receives a donated amount of base tokens to be added to the entity's balance. Transfers default fee to treasury.
     * @param _amount Amount donated in base token.
     * @dev Reverts if the donation fee percentage is larger than 100% (equal to 1e4 when represented as a zoc).
     * @dev Reverts if the token transfer fails.
     */
    function donate(uint256 _amount) external virtual {
        uint32 _feeMultiplier = registry.getDonationFee(this);
        _donateWithFeeMultiplier(_amount, _feeMultiplier);
    }

    /**
     * @notice Receives a donated amount of base tokens to be added to the entity's balance. Transfers default or overridden fee to treasury.
     * @param _amount Amount donated in base token.
     * @dev Reverts if the donation fee percentage is larger than 100% (equal to 1e4 when represented as a zoc).
     * @dev Reverts if the token transfer fails.
     */
    function donateWithOverrides(uint256 _amount) external virtual {
        uint32 _feeMultiplier = registry.getDonationFeeWithOverrides(this);
        _donateWithFeeMultiplier(_amount, _feeMultiplier);
    }

    /**
     * @notice Receives a donated amount of base tokens to be added to the entity's balance.
     * This method can be called by permissioned actors to make a donation with a manually specified fee.
     * @param _amount Amount donated in base token.
     * @param _feeOverride Fee percentage as zoc.
     * @dev Reverts if the transfer fee percentage is larger than 100% (equal to 1e4 when represented as a zoc).
     * @dev Reverts if the token transfer fails.
     * @dev Reverts with `Unauthorized` if the `msg.sender` is not a privileged role.
     */
    function donateWithAdminOverrides(uint256 _amount, uint32 _feeOverride) external virtual requiresAuth {
        _donateWithFeeMultiplier(_amount, _feeOverride);
    }

    /**
     * @notice Receives a donated amount of base tokens to be added to the entity's balance. Transfers fee calculated by fee multiplier to treasury.
     * @param _amount Amount donated in base token.
     * @param _feeMultiplier Value indicating the percentage of the Endaoment donation fee to go to the Endaoment treasury.
     * @dev Reverts if the donation fee percentage is larger than 100% (equal to 1e4 when represented as a zoc).
     * @dev Reverts if the token transfer fails.
     */
    function _donateWithFeeMultiplier(uint256 _amount, uint32 _feeMultiplier) internal virtual {
        (uint256 _netAmount, uint256 _fee) = _calculateFee(_amount, _feeMultiplier);
        baseToken.safeTransferFrom(msg.sender, registry.treasury(), _fee);
        baseToken.safeTransferFrom(msg.sender, address(this), _netAmount);

        unchecked {
            // unchecked as no possibility of overflow with baseToken precision
            balance += _netAmount;
        }
        emit EntityDonationReceived(msg.sender, address(this), address(baseToken), _amount, _amount, _fee);
    }

    /**
     * @notice Receive a donated amount of ETH or ERC20 tokens, swaps them to base tokens, and adds the output to the
     * entity's balance. Fee calculated using default rate and sent to treasury.
     * @param _swapWrapper The swap wrapper to use for the donation. Must be whitelisted on the Registry.
     * @param _tokenIn The address of the ERC20 token to swap and donate, or ETH_PLACEHOLDER if donating ETH.
     * @param _amountIn The amount of tokens or ETH being swapped and donated.
     * @param _data Additional call data required by the ISwapWrapper being used.
     */
    function swapAndDonate(ISwapWrapper _swapWrapper, address _tokenIn, uint256 _amountIn, bytes calldata _data)
        external
        payable
        virtual
    {
        uint32 _feeMultiplier = registry.getDonationFee(this);
        _swapAndDonateWithFeeMultiplier(_swapWrapper, _tokenIn, _amountIn, _data, _feeMultiplier);
    }

    /**
     * @notice Receive a donated amount of ETH or ERC20 tokens, swaps them to base tokens, and adds the output to the
     * entity's balance. Fee calculated using override rate and sent to treasury.
     * @param _swapWrapper The swap wrapper to use for the donation. Must be whitelisted on the Registry.
     * @param _tokenIn The address of the ERC20 token to swap and donate, or ETH_PLACEHOLDER if donating ETH.
     * @param _amountIn The amount of tokens or ETH being swapped and donated.
     * @param _data Additional call data required by the ISwapWrapper being used.
     */
    function swapAndDonateWithOverrides(
        ISwapWrapper _swapWrapper,
        address _tokenIn,
        uint256 _amountIn,
        bytes calldata _data
    ) external payable virtual {
        uint32 _feeMultiplier = registry.getDonationFeeWithOverrides(this);
        _swapAndDonateWithFeeMultiplier(_swapWrapper, _tokenIn, _amountIn, _data, _feeMultiplier);
    }

    /// @dev Internal helper implementing swap and donate functionality for any fee multiplier provided.
    function _swapAndDonateWithFeeMultiplier(
        ISwapWrapper _swapWrapper,
        address _tokenIn,
        uint256 _amountIn,
        bytes calldata _data,
        uint32 _feeMultiplier
    ) internal virtual nonReentrant {
        if (!registry.isSwapperSupported(_swapWrapper)) revert InvalidAction();

        // THINK: do we need a re-entrancy guard on this method?
        if (_tokenIn != ETH_PLACEHOLDER) {
            ERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
            ERC20(_tokenIn).safeApprove(address(_swapWrapper), 0);
            ERC20(_tokenIn).safeApprove(address(_swapWrapper), _amountIn);
        }

        uint256 _amountOut =
            _swapWrapper.swap{value: msg.value}(_tokenIn, address(baseToken), address(this), _amountIn, _data);

        (uint256 _netAmount, uint256 _fee) = _calculateFee(_amountOut, _feeMultiplier);

        baseToken.safeTransfer(registry.treasury(), _fee);

        unchecked {
            // unchecked as no possibility of overflow with baseToken precision
            balance += _netAmount;
        }

        if (balance > baseToken.balanceOf(address(this))) revert BalanceMismatch();

        emit EntityDonationReceived(msg.sender, address(this), _tokenIn, _amountIn, _amountOut, _fee);
    }

    /**
     * @notice Transfers an amount of base tokens from one entity to another. Transfers default fee to treasury.
     * @param _to The entity to receive the tokens.
     * @param _amount Contains the amount being donated (denominated in the base token's units).
     * @dev Reverts if the entity is inactive or if the token transfer fails.
     * @dev Reverts if the transfer fee percentage is larger than 100% (equal to 1e4 when represented as a zoc).
     * @dev Reverts with `Unauthorized` if the `msg.sender` is not the entity manager or a privileged role.
     * @dev Renamed from `transfer` to distinguish from ERC20 transfer in 3rd party tools.
     */
    function transferToEntity(Entity _to, uint256 _amount) external virtual requiresManager {
        uint32 _feeMultiplier = registry.getTransferFee(this, _to);
        _transferWithFeeMultiplier(_to, _amount, _feeMultiplier);
    }

    /**
     * @notice Transfers an amount of base tokens from one entity to another. Transfers default or overridden fee to treasury.
     * @param _to The entity to receive the tokens.
     * @param _amount Contains the amount being donated (denominated in the base token's units).
     * @dev Reverts if the entity is inactive or if the token transfer fails.
     * @dev Reverts if the transfer fee percentage is larger than 100% (equal to 1e4 when represented as a zoc).
     * @dev Reverts with `Unauthorized` if the `msg.sender` is not the entity manager or a privileged role.
     */
    function transferToEntityWithOverrides(Entity _to, uint256 _amount) external virtual requiresManager {
        uint32 _feeMultiplier = registry.getTransferFeeWithOverrides(this, _to);
        _transferWithFeeMultiplier(_to, _amount, _feeMultiplier);
    }

    /**
     * @notice Transfers an amount of base tokens from one entity to another. Transfers fee specified by a privileged role.
     * @param _to The entity to receive the tokens.
     * @param _amount Contains the amount being donated (denominated in the base token's units).
     * @param _feeOverride Admin override configured by an Admin
     * @dev Reverts if the entity is inactive or if the token transfer fails.
     * @dev Reverts if the transfer fee percentage is larger than 100% (equal to 1e4 when represented as a zoc).
     * @dev Reverts with `Unauthorized` if the `msg.sender` is not a privileged role.
     */
    function transferToEntityWithAdminOverrides(Entity _to, uint256 _amount, uint32 _feeOverride)
        external
        virtual
        requiresAuth
    {
        _transferWithFeeMultiplier(_to, _amount, _feeOverride);
    }

    /**
     * @notice Transfers an amount of base tokens from one entity to another. Transfers fee calculated by fee multiplier to treasury.
     * @param _to The entity to receive the tokens.
     * @param _amount Contains the amount being donated (denominated in the base token's units).
     * @param _feeMultiplier Value indicating the percentage of the Endaoment donation fee to go to the Endaoment treasury.
     * @dev Reverts with 'Inactive' if the entity sending the transfer or the entity receiving the transfer is inactive.
     * @dev Reverts if the transfer fee percentage is larger than 100% (equal to 1e4 when represented as a zoc).
     * @dev Reverts with `Unauthorized` if the `msg.sender` is not the entity manager or a privileged role.
     * @dev Reverts if the token transfer fails.
     */
    function _transferWithFeeMultiplier(Entity _to, uint256 _amount, uint32 _feeMultiplier) internal virtual {
        if (!registry.isActiveEntity(this) || !registry.isActiveEntity(_to)) revert EntityInactive();
        if (balance < _amount) revert InsufficientFunds();

        (uint256 _netAmount, uint256 _fee) = _calculateFee(_amount, _feeMultiplier);
        baseToken.safeTransfer(registry.treasury(), _fee);
        baseToken.safeTransfer(address(_to), _netAmount);

        unchecked {
            // unchecked as no possibility of overflow with baseToken precision
            balance -= _amount;
            _to.receiveTransfer(_netAmount);
        }
        emit EntityValueTransferred(address(this), address(_to), _amount, _fee);
    }

    /**
     * @notice Updates the receiving entity balance on a transfer.
     * @param _transferAmount The amount being received on the transfer.
     * @dev This function is external, but is restricted such that it can only be called by other entities.
     */
    function receiveTransfer(uint256 _transferAmount) external virtual {
        if (!registry.isActiveEntity(Entity(payable(msg.sender)))) revert EntityInactive();
        unchecked {
            // Cannot overflow with realistic balances.
            balance += _transferAmount;
        }
    }

    /**
     * @notice Deposits an amount of Entity's `baseToken` into an Endaoment-approved Portfolio.
     * @param _portfolio An Endaoment-approved portfolio.
     * @param _amount Amount of `baseToken` to deposit into the portfolio.
     * @param _data Data required by a portfolio to deposit.
     * @return _shares Amount of portfolio share tokens Entity received as a result of this deposit.
     */
    function portfolioDeposit(Portfolio _portfolio, uint256 _amount, bytes calldata _data)
        external
        virtual
        requiresManager
        returns (uint256)
    {
        if (!registry.isActivePortfolio(_portfolio)) revert PortfolioInactive();
        balance -= _amount;
        baseToken.safeApprove(address(_portfolio), _amount);
        uint256 _shares = _portfolio.deposit(_amount, _data);
        emit EntityDeposit(address(_portfolio), _amount, _shares);
        return _shares;
    }

    /**
     * @notice Redeems an amount of Entity's portfolio shares for an amount of `baseToken`.
     * @param _portfolio An Endaoment-approved portfolio.
     * @param _shares Amount of share tokens to redeem.
     * @param _data Data required by a portfolio to redeem.
     * @return _received Amount of `baseToken` Entity received as a result of this redemption.
     */
    function portfolioRedeem(Portfolio _portfolio, uint256 _shares, bytes calldata _data)
        external
        virtual
        requiresManager
        returns (uint256)
    {
        if (!registry.isActivePortfolio(_portfolio)) revert PortfolioInactive();
        uint256 _received = _portfolio.redeem(_shares, _data);
        // unchecked: a realistic balance can never overflow a uint256
        unchecked {
            balance += _received;
        }
        emit EntityRedeem(address(_portfolio), _shares, _received);
        return _received;
    }

    /**
     * @notice This method should be called to reconcile the Entity's internal baseToken accounting with the baseToken contract's accounting.
     * There are a 2 situations where calling this method is appropriate:
     * 1. To process amounts of baseToken that arrived at this Entity through methods besides Entity:donate or Entity:transfer. For example,
     * if this Entity receives a normal ERC20 transfer of baseToken, the amount received will be unavailable for Entity use until this method
     * is called to adjust the balance and process fees. OrgFundFactory.sol:_donate makes use of this method to do this as well.
     * 2. Unusually, the Entity's perspective of balance could be lower than `baseToken.balanceOf(this)`. This could happen if
     * Entity:callAsEntity is used to transfer baseToken. In this case, this method provides a way of correcting the Entity's internal balance.
     */
    function reconcileBalance() external virtual {
        uint256 _tokenBalance = baseToken.balanceOf(address(this));

        if (_tokenBalance >= balance) {
            uint256 _sweepAmount = _tokenBalance - balance;
            uint32 _feeMultiplier = registry.getDonationFeeWithOverrides(this);
            (uint256 _netAmount, uint256 _fee) = _calculateFee(_sweepAmount, _feeMultiplier);

            baseToken.safeTransfer(registry.treasury(), _fee);
            unchecked {
                balance += _netAmount;
            }
            emit EntityBalanceReconciled(address(this), _sweepAmount, _fee);
        } else {
            // Handle abnormal scenario where _tokenBalance < balance (see method docs)
            balance = _tokenBalance;
            emit EntityBalanceCorrected(address(this), _tokenBalance);
        }
    }

    /**
     * @notice Takes stray tokens or ETH sent directly to this Entity, swaps them for base token, then adds them to the
     * Entity's balance after paying the appropriate fee to the treasury.
     * @param _swapWrapper The swap wrapper to use to convert the assets. Must be whitelisted on the Registry.
     * @param _tokenIn The address of the ERC20 token to swap, or ETH_PLACEHOLDER if ETH.
     * @param _amountIn The amount of tokens or ETH being swapped and added to the balance.
     * @param _data Additional call data required by the ISwapWrapper being used.
     */
    function swapAndReconcileBalance(
        ISwapWrapper _swapWrapper,
        address _tokenIn,
        uint256 _amountIn,
        bytes calldata _data
    ) external virtual nonReentrant requiresManager {
        if (!registry.isSwapperSupported(_swapWrapper)) revert InvalidAction();

        uint32 _feeMultiplier = registry.getDonationFeeWithOverrides(this);

        if (_tokenIn != ETH_PLACEHOLDER) {
            ERC20(_tokenIn).safeApprove(address(_swapWrapper), 0);
            ERC20(_tokenIn).safeApprove(address(_swapWrapper), _amountIn);
        }

        // Send value only if token in is ETH
        uint256 _value = _tokenIn == ETH_PLACEHOLDER ? _amountIn : 0;

        uint256 _amountOut =
            _swapWrapper.swap{value: _value}(_tokenIn, address(baseToken), address(this), _amountIn, _data);

        (uint256 _netAmount, uint256 _fee) = _calculateFee(_amountOut, _feeMultiplier);
        baseToken.safeTransfer(registry.treasury(), _fee);

        unchecked {
            // unchecked as no possibility of overflow with baseToken precision
            balance += _netAmount;
        }

        if (balance > baseToken.balanceOf(address(this))) revert BalanceMismatch();

        emit EntityBalanceReconciled(address(this), _amountOut, _fee);
    }

    /**
     * @notice Permissioned method that allows Endaoment admin to make arbitrary calls acting as this Entity.
     * @param _target The address to which the call will be made.
     * @param _value The ETH value that should be forwarded with the call.
     * @param _data The calldata that will be sent with the call.
     * @return _return The data returned by the call.
     */
    function callAsEntity(address _target, uint256 _value, bytes memory _data)
        external
        payable
        virtual
        requiresAuth
        returns (bytes memory)
    {
        (bool _success, bytes memory _response) = payable(_target).call{value: _value}(_data);
        if (!_success) revert CallFailed(_response);
        return _response;
    }

    /**
     * @notice Pays out an amount of base tokens from the entity to an address. Transfers the fee calculated by the
     * default fee multiplier to the treasury.
     * @param _to The address to receive the tokens.
     * @param _amount Amount donated in base token.
     * @dev Reverts with `Unauthorized` if the `msg.sender` is not a privileged role.
     * @dev Reverts if the fee percentage is larger than 100% (equal to 1e4 when represented as a zoc).
     * @dev Reverts if the token transfer fails.
     */
    function payout(address _to, uint256 _amount) external virtual requiresAuth {
        uint32 _feeMultiplier = registry.getPayoutFee(this);
        _payoutWithFeeMultiplier(_to, _amount, _feeMultiplier);
    }

    /**
     * @notice Pays out an amount of base tokens from the entity to an address. Transfers the fee calculated by the
     * default fee multiplier to the treasury.
     * @param _amount Amount donated in base token.
     * @dev Reverts with `Unauthorized` if the `msg.sender` is not a privileged role.
     * @dev Reverts if the fee percentage is larger than 100% (equal to 1e4 when represented as a zoc).
     * @dev Reverts if the token transfer fails.
     */
    function payoutWithOverrides(address _to, uint256 _amount) external virtual requiresAuth {
        uint32 _feeMultiplier = registry.getPayoutFeeWithOverrides(this);
        _payoutWithFeeMultiplier(_to, _amount, _feeMultiplier);
    }

    /**
     * @notice Pays out an amount of base tokens from the entity to an address. Transfers fee specified by a privileged role.
     * @param _amount Amount donated in base token.
     * @param _feeOverride Payout override configured by an Admin
     * @dev Reverts with `Unauthorized` if the `msg.sender` is not a privileged role.
     * @dev Reverts if the fee percentage is larger than 100% (equal to 1e4 when represented as a zoc).
     * @dev Reverts if the token transfer fails.
     */
    function payoutWithAdminOverrides(address _to, uint256 _amount, uint32 _feeOverride)
        external
        virtual
        requiresAuth
    {
        _payoutWithFeeMultiplier(_to, _amount, _feeOverride);
    }

    /**
     * @notice Pays out an amount of base tokens from the entity to an address. Transfers the fee calculated by fee multiplier to the treasury.
     * @param _to The address to receive the tokens.
     * @param _amount Contains the amount being paid out (denominated in the base token's units).
     * @param _feeMultiplier Value indicating the percentage of the Endaoment fee to go to the Endaoment treasury.
     * @dev Reverts if the token transfer fails.
     * @dev Reverts if the fee percentage is larger than 100% (equal to 1e4 when represented as a zoc).
     */
    function _payoutWithFeeMultiplier(address _to, uint256 _amount, uint32 _feeMultiplier) internal virtual {
        if (balance < _amount) revert InsufficientFunds();

        (uint256 _netAmount, uint256 _fee) = _calculateFee(_amount, _feeMultiplier);
        baseToken.safeTransfer(registry.treasury(), _fee);
        baseToken.safeTransfer(address(_to), _netAmount);

        unchecked {
            // unchecked because we've already validated that amount is less than or equal to the balance
            balance -= _amount;
        }
        emit EntityValuePaidOut(address(this), _to, _amount, _fee);
    }

    /// @dev Internal helper method to calculate the fee on a base token amount for a given fee multiplier.
    function _calculateFee(uint256 _amount, uint256 _feeMultiplier)
        internal
        pure
        virtual
        returns (uint256 _netAmount, uint256 _fee)
    {
        if (_feeMultiplier > Math.ZOC) revert InvalidAction();
        unchecked {
            // unchecked as no possibility of overflow with baseToken precision
            _fee = _amount.zocmul(_feeMultiplier);
            // unchecked as the _feeMultiplier check with revert above protects against overflow
            _netAmount = _amount - _fee;
        }
    }

    receive() external payable virtual {
        emit EntityEthReceived(msg.sender, msg.value);
    }
}

//SPDX-License-Identifier: BSD 3-Clause
pragma solidity >=0.8.0;

import "./Registry.sol";
import "./Entity.sol";

/**
 * @notice EntityFactory contract inherited by OrgFundFactory and future factories.
 */
abstract contract EntityFactory {
    /// @notice _registry The registry to host the Entity.
    Registry public immutable registry;

    /// @notice Emitted when an Entity is deployed.
    event EntityDeployed(address indexed entity, uint8 indexed entityType, address indexed entityManager);

    /**
     * @param _registry The registry to host the Entity.
     */
    constructor(Registry _registry) {
        registry = _registry;
    }
}

//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

import {Registry} from "./Registry.sol";
import {Entity} from "./Entity.sol";

/**
 * @notice Fund entity
 */
contract Fund is Entity {
    /**
     * @notice One time method to be called at deployment to configure the contract. Required so Fund
     * contracts can be deployed as minimal proxies (clones).
     * @param _registry The registry to host the Fund Entity.
     * @param _manager The address of the Fund's manager.
     */
    function initialize(Registry _registry, address _manager) public {
        // Call to Entity's initialization function ensures this can only be called once
        __initEntity(_registry, _manager);
    }

    /**
     * @inheritdoc Entity
     */
    function entityType() public pure override returns (uint8) {
        return 2;
    }
}

//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

import {Registry} from "./Registry.sol";
import {Entity} from "./Entity.sol";

/**
 * @notice This contract controls the Org entity.
 */
contract Org is Entity {
    /// @notice Tax ID of org
    bytes32 public orgId;

    /**
     * @notice One time method to be called at deployment to configure the contract. Required so Org
     * contracts can be deployed as minimal proxies (clones).
     * @param _registry The registry to host the Org Entity.
     * @param _orgId The Org's ID for tax purposes.
     * @dev The `manager` of the Org is initially set to the zero address and will be updated by role pending an off-chain claim.
     */
    function initialize(Registry _registry, bytes32 _orgId) public {
        // Call to Entity's initializer ensures this can only be called once.
        __initEntity(_registry, address(0));
        orgId = _orgId;
    }

    function setOrgId(bytes32 _orgId) external requiresAuth {
        orgId = _orgId;
    }

    /**
     * @inheritdoc Entity
     */
    function entityType() public pure override returns (uint8) {
        return 1;
    }
}

//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

import {Clones} from "openzeppelin-contracts/contracts/proxy/Clones.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {Registry} from "./Registry.sol";
import {EntityFactory} from "./EntityFactory.sol";
import {Entity} from "./Entity.sol";
import {Org} from "./Org.sol";
import {Fund} from "./Fund.sol";
import {ISwapWrapper} from "./interfaces/ISwapWrapper.sol";

/**
 * @notice This contract is the factory for both the Org and Fund objects.
 */
contract OrgFundFactory is EntityFactory {
    using SafeTransferLib for ERC20;

    /// @notice Placeholder address used in swapping method to denote usage of ETH instead of a token.
    address public constant ETH_PLACEHOLDER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev The concrete Org used for minimal proxy deployment.
    Org public immutable orgImplementation;

    /// @dev The concrete Fund used for minimal proxy deployment.
    Fund public immutable fundImplementation;

    /// @notice Base Token address is the stable coin used throughout the system.
    ERC20 public immutable baseToken;

    /**
     * @param _registry The Registry this factory will configure Entities to interact with. This factory must be
     * approved on this Registry for it to work properly.
     */
    constructor(Registry _registry) EntityFactory(_registry) {
        orgImplementation = new Org();
        orgImplementation.initialize(_registry, bytes32("IMPL")); // necessary?
        fundImplementation = new Fund();
        fundImplementation.initialize(_registry, address(0));
        baseToken = _registry.baseToken();
    }

    /**
     * @notice Deploys a Fund.
     * @param _manager The address of the Fund's manager.
     * @param _salt A 32-byte value used to create the contract at a deterministic address.
     * @return _fund The deployed Fund.
     */
    function deployFund(address _manager, bytes32 _salt) public returns (Fund _fund) {
        _fund = Fund(
            payable(
                Clones.cloneDeterministic(
                    address(fundImplementation), keccak256(bytes.concat(bytes20(_manager), _salt))
                )
            )
        );
        _fund.initialize(registry, _manager);
        registry.setEntityActive(_fund);
        emit EntityDeployed(address(_fund), _fund.entityType(), _manager);
    }

    /**
     * @notice Deploys a Fund then pulls base token from the sender and donates to it.
     * @param _manager The address of the Fund's manager.
     * @param _salt A 32-byte value used to create the contract at a deterministic address.
     * @param _amount The amount of base token to donate.
     * @return _fund The deployed Fund.
     */
    function deployFundAndDonate(address _manager, bytes32 _salt, uint256 _amount) external returns (Fund _fund) {
        _fund = deployFund(_manager, _salt);
        _donate(_fund, _amount);
    }

    /**
     * @notice Deploys a new Fund, then pulls a ETH or ERC20 tokens, swaps them to base tokens,
     * and donates to the new Fund.
     * @param _manager The address of the Fund's manager.
     * @param _salt A 32-byte value used to create the contract at a deterministic address.
     * @param _swapWrapper The swap wrapper to use for the donation. Must be whitelisted on the Registry.
     * @param _tokenIn The address of the ERC20 token to swap and donate, or ETH_PLACEHOLDER if donating ETH.
     * @param _amountIn The amount of tokens or ETH being swapped and donated.
     * @param _data Additional call data required by the ISwapWrapper being used.
     * @return _fund The deployed Fund.
     */
    function deployFundSwapAndDonate(
        address _manager,
        bytes32 _salt,
        ISwapWrapper _swapWrapper,
        address _tokenIn,
        uint256 _amountIn,
        bytes calldata _data
    ) external payable returns (Fund _fund) {
        _fund = deployFund(_manager, _salt);
        _swapAndDonate(_fund, _swapWrapper, _tokenIn, _amountIn, _data);
    }

    /**
     * @notice Deploys an Org.
     * @param _orgId The Org's ID for tax purposes.
     * @return _org The deployed Org.
     */
    function deployOrg(bytes32 _orgId) public returns (Org _org) {
        _org = Org(payable(Clones.cloneDeterministic(address(orgImplementation), _orgId)));
        _org.initialize(registry, _orgId);
        registry.setEntityActive(_org);
        emit EntityDeployed(address(_org), _org.entityType(), _org.manager());
    }

    /**
     * @notice Deploys an Org then pulls base token from the sender and donates to it.
     * @param _orgId The Org's ID for tax purposes.
     * @param _amount The amount of base token to donate.
     * @return _org The deployed Org.
     */
    function deployOrgAndDonate(bytes32 _orgId, uint256 _amount) external returns (Org _org) {
        _org = deployOrg(_orgId);
        _donate(_org, _amount);
    }

    /**
     * @notice Deploys a new Org, then pulls a ETH or ERC20 tokens, swaps them to base tokens,
     * and donates to the new Org.
     * @param _orgId The Org's ID for tax purposes.
     * @param _swapWrapper The swap wrapper to use for the donation. Must be whitelisted on the Registry.
     * @param _tokenIn The address of the ERC20 token to swap and donate, or ETH_PLACEHOLDER if donating ETH.
     * @param _amountIn The amount of tokens or ETH being swapped and donated.
     * @param _data Additional call data required by the ISwapWrapper being used.
     * @return _org The deployed Org.
     */
    function deployOrgSwapAndDonate(
        bytes32 _orgId,
        ISwapWrapper _swapWrapper,
        address _tokenIn,
        uint256 _amountIn,
        bytes calldata _data
    ) external payable returns (Org _org) {
        _org = deployOrg(_orgId);
        _swapAndDonate(_org, _swapWrapper, _tokenIn, _amountIn, _data);
    }

    /**
     * @notice Calculates an Org contract's deployment address.
     * @param _orgId Org's tax ID.
     * @return The Org's deployment address.
     * @dev This function is used off-chain by the automated tests to verify proper contract address deployment.
     */
    function computeOrgAddress(bytes32 _orgId) external view returns (address) {
        return Clones.predictDeterministicAddress(address(orgImplementation), _orgId, address(this));
    }

    /**
     * @notice Calculates a Fund contract's deployment address.
     * @param _manager The manager of the fund.
     * @param _salt A 32-byte value used to create the contract at a deterministic address.
     * @return The Fund's deployment address.
     * @dev This function is used off-chain by the automated tests to verify proper contract address deployment.
     */
    function computeFundAddress(address _manager, bytes32 _salt) external view returns (address) {
        return Clones.predictDeterministicAddress(
            address(fundImplementation), keccak256(bytes.concat(bytes20(_manager), _salt)), address(this)
        );
    }

    /// @dev Pulls base tokens from sender and donates them to the entity.
    function _donate(Entity _entity, uint256 _amount) private {
        // Send tokens directly to the entity, then reconcile its balance. Cheaper than doing a double transfer
        // and calling `donate`.
        baseToken.safeTransferFrom(msg.sender, address(_entity), _amount);
        _entity.reconcileBalance();
    }

    /// @dev Pulls ERC20 tokens, or receives ETH, and swaps and donates them to the entity.
    function _swapAndDonate(
        Entity _entity,
        ISwapWrapper _swapWrapper,
        address _tokenIn,
        uint256 _amountIn,
        bytes calldata _data
    ) private {
        if (_tokenIn != ETH_PLACEHOLDER) {
            ERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
            ERC20(_tokenIn).safeApprove(address(_entity), 0);
            ERC20(_tokenIn).safeApprove(address(_entity), _amountIn);
        }

        _entity.swapAndDonate{value: msg.value}(_swapWrapper, _tokenIn, _amountIn, _data);
    }
}

//SPDX-License-Identifier: BSD 3-Clause
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Registry} from "./Registry.sol";
import {Entity} from "./Entity.sol";
import {EndaomentAuth} from "./lib/auth/EndaomentAuth.sol";
import {RolesAuthority} from "./lib/auth/authorities/RolesAuthority.sol";
import {Math} from "./lib/Math.sol";

abstract contract Portfolio is ERC20, EndaomentAuth {
    using Math for uint256;

    Registry public immutable registry;
    uint256 public cap;
    uint256 public depositFee;
    uint256 public redemptionFee;
    address public immutable asset;
    bool public didShutdown;

    error InvalidSwapper();
    error TransferDisallowed();
    error DepositAfterShutdown();
    error DidShutdown();
    error NotEntity();
    error ExceedsCap();
    error PercentageOver100();
    error RoundsToZero();
    error CallFailed(bytes response);

    /// @notice `sender` has exchanged `assets` (after fees) for `shares`, and transferred those `shares` to `receiver`.
    /// The sender paid a total of `depositAmount` and was charged `fee` for the transaction.
    event Deposit(
        address indexed sender,
        address indexed receiver,
        uint256 assets,
        uint256 shares,
        uint256 depositAmount,
        uint256 fee
    );

    /// @notice `sender` has exchanged `shares` for `assets`, and transferred those `assets` to `receiver`.
    /// The sender received a net of `redeemedAmount` after the conversion of `assets` into base tokens
    /// and was charged `fee` for the transaction.
    event Redeem(
        address indexed sender,
        address indexed receiver,
        uint256 assets,
        uint256 shares,
        uint256 redeemedAmount,
        uint256 fee
    );

    /// @notice Event emitted when `cap` is set.
    event CapSet(uint256 cap);

    /// @notice Event emitted when `depositFee` is set.
    event DepositFeeSet(uint256 fee);

    /// @notice Event emitted when `redemptionFee` is set.
    event RedemptionFeeSet(uint256 fee);

    /// @notice Event emitted when management takes fees.
    event FeesTaken(uint256 amount);

    /// @notice Event emitted when admin forcefully swaps portfolio asset balance for baseToken.
    event Shutdown(uint256 assetAmount, uint256 baseTokenOut);

    /**
     * @param _registry Endaoment registry.
     * @param _name Name of the ERC20 Portfolio share tokens.
     * @param _symbol Symbol of the ERC20 Portfolio share tokens.
     * @param _cap Amount in baseToken that value of totalAssets should not exceed.
     * @param _depositFee Percentage fee as ZOC that will go to treasury on asset deposit.
     * @param _redemptionFee Percentage fee as ZOC that will go to treasury on share redemption.
     */
    constructor(
        Registry _registry,
        address _asset,
        string memory _name,
        string memory _symbol,
        uint256 _cap,
        uint256 _depositFee,
        uint256 _redemptionFee
    ) ERC20(_name, _symbol, ERC20(_asset).decimals()) {
        registry = _registry;
        if (_redemptionFee > Math.ZOC) revert PercentageOver100();
        depositFee = _depositFee;
        redemptionFee = _redemptionFee;
        cap = _cap;
        asset = _asset;
        __initEndaomentAuth(_registry, "portfolio");
    }

    /**
     * @notice Function used to determine whether an Entity is active on the registry.
     * @param _entity The Entity.
     */
    function _isEntity(Entity _entity) internal view returns (bool) {
        return registry.isActiveEntity(_entity);
    }

    /**
     * @notice Set the Portfolio cap.
     * @param _amount Amount, denominated in baseToken.
     */
    function setCap(uint256 _amount) external virtual requiresAuth {
        cap = _amount;
        emit CapSet(_amount);
    }

    /**
     * @notice Set deposit fee.
     * @param _pct Percentage as ZOC (e.g. 1000 = 10%).
     */
    function setDepositFee(uint256 _pct) external virtual requiresAuth {
        if (_pct > Math.ZOC) revert PercentageOver100();
        depositFee = _pct;
        emit DepositFeeSet(_pct);
    }

    /**
     * @notice Set redemption fee.
     * @param _pct Percentage as ZOC (e.g. 1000 = 10%).
     */
    function setRedemptionFee(uint256 _pct) external virtual requiresAuth {
        if (_pct > Math.ZOC) revert PercentageOver100();
        redemptionFee = _pct;
        emit RedemptionFeeSet(_pct);
    }

    /**
     * @notice Total amount of the underlying asset that is managed by the Portfolio.
     */
    function totalAssets() external view virtual returns (uint256);

    /**
     * @notice Takes some amount of assets from this portfolio as assets under management fee.
     * @param _amountAssets Amount of assets to take.
     */
    function takeFees(uint256 _amountAssets) external virtual;

    /**
     * @notice Exchange `_amountBaseToken` for some amount of Portfolio shares.
     * @param _amountBaseToken The amount of the Entity's baseToken to deposit.
     * @param _data Data that the portfolio needs to make the deposit. In some cases, this will be swap parameters.
     * @return shares The amount of shares that this deposit yields to the Entity.
     */
    function deposit(uint256 _amountBaseToken, bytes calldata _data) external virtual returns (uint256 shares);

    /**
     * @notice Exchange `_amountShares` for some amount of baseToken.
     * @param _amountShares The amount of the Entity's portfolio shares to exchange.
     * @param _data Data that the portfolio needs to make the redemption. In some cases, this will be swap parameters.
     * @return baseTokenOut The amount of baseToken that this redemption yields to the Entity.
     */
    function redeem(uint256 _amountShares, bytes calldata _data) external virtual returns (uint256 baseTokenOut);

    /**
     * @notice Calculates the amount of shares that the Portfolio should exchange for the amount of assets provided.
     * @param _amountAssets Amount of assets.
     */
    function convertToShares(uint256 _amountAssets) public view virtual returns (uint256);

    /**
     * @notice Calculates the amount of assets that the Portfolio should exchange for the amount of shares provided.
     * @param _amountShares Amount of shares.
     */
    function convertToAssets(uint256 _amountShares) public view virtual returns (uint256);

    /**
     * @notice Exit out all assets of portfolio for baseToken. Must persist a mechanism for entities to redeem their shares for baseToken.
     * @param _data Data that the portfolio needs to exit from asset. In some cases, this will be swap parameters.
     * @return baseTokenOut The amount of baseToken that this exit yielded.
     */
    function shutdown(bytes calldata _data) external virtual returns (uint256 baseTokenOut);

    /// @notice `transfer` disabled on Portfolio tokens.
    function transfer(
        address,
        /**
         * to
         */
        uint256
    )
        /**
         * amount
         */
        public
        pure
        override
        returns (bool)
    {
        revert TransferDisallowed();
    }

    /// @notice `transferFrom` disabled on Portfolio tokens.
    function transferFrom(
        address,
        /**
         * from
         */
        address,
        /**
         * to
         */
        uint256
    )
        /**
         * amount
         */
        public
        pure
        override
        returns (bool)
    {
        revert TransferDisallowed();
    }

    /// @notice `approve` disabled on Portfolio tokens.
    function approve(
        address,
        /**
         * to
         */
        uint256
    )
        /**
         * amount
         */
        public
        pure
        override
        returns (bool)
    {
        revert TransferDisallowed();
    }

    /// @notice `permit` disabled on Portfolio tokens.
    function permit(
        address, /* owner */
        address, /* spender */
        uint256, /* value */
        uint256, /* deadline */
        uint8, /* v */
        bytes32, /* r */
        bytes32 /* s */
    ) public pure override {
        revert TransferDisallowed();
    }

    /**
     * @notice Permissioned method that allows Endaoment admin to make arbitrary calls acting as this Portfolio.
     * @param _target The address to which the call will be made.
     * @param _value The ETH value that should be forwarded with the call.
     * @param _data The calldata that will be sent with the call.
     * @return _return The data returned by the call.
     */
    function callAsPortfolio(address _target, uint256 _value, bytes memory _data)
        external
        payable
        requiresAuth
        returns (bytes memory)
    {
        (bool _success, bytes memory _response) = payable(_target).call{value: _value}(_data);
        if (!_success) revert CallFailed(_response);
        return _response;
    }

    /// @dev Internal helper method to calculate the fee on a base token amount for a given fee multiplier.
    function _calculateFee(uint256 _amount, uint256 _feeMultiplier)
        internal
        pure
        returns (uint256 _netAmount, uint256 _fee)
    {
        if (_feeMultiplier > Math.ZOC) revert PercentageOver100();
        unchecked {
            // unchecked as no possibility of overflow with baseToken precision
            _fee = _amount.zocmul(_feeMultiplier);
            // unchecked as the _feeMultiplier check with revert above protects against overflow
            _netAmount = _amount - _fee;
        }
    }
}

//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

import {Math} from "./lib/Math.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "./lib/auth/Auth.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {RegistryAuth} from "./RegistryAuth.sol";
import {Entity} from "./Entity.sol";
import {ISwapWrapper} from "./interfaces/ISwapWrapper.sol";
import {Portfolio} from "./Portfolio.sol";

// --- Errors ---
error Unauthorized();
error UnsupportedSwapper();

/**
 * @notice Registry entity - manages Factory and Entity state info.
 */
contract Registry is RegistryAuth {
    // --- Storage ---

    /// @notice Treasury address can receives fees.
    address public treasury;

    /// @notice Base Token address is the stable coin contract used throughout the system.
    ERC20 public immutable baseToken;

    /// @notice Mapping of approved factory contracts that are allowed to register new Entities.
    mapping(address => bool) public isApprovedFactory;
    /// @notice Mapping of active status of entities.
    mapping(Entity => bool) public isActiveEntity;

    /// @notice Maps entity type to donation fee percentage stored as a zoc, where type(uint32).max represents 0.
    mapping(uint8 => uint32) defaultDonationFee;
    /// @notice Maps specific entity receiver to donation fee percentage stored as a zoc.
    mapping(Entity => uint32) donationFeeReceiverOverride;

    /// @notice Maps entity type to payout fee percentage stored as a zoc, where type(uint32).max represents 0.
    mapping(uint8 => uint32) defaultPayoutFee;
    /// @notice Maps specific entity sender to payout fee percentage stored as a zoc.
    mapping(Entity => uint32) payoutFeeOverride;

    /// @notice Maps sender entity type to receiver entity type to fee percentage as a zoc.
    mapping(uint8 => mapping(uint8 => uint32)) defaultTransferFee;
    /// @notice Maps specific entity sender to receiver entity type to fee percentage as a zoc.
    mapping(Entity => mapping(uint8 => uint32)) transferFeeSenderOverride;
    /// @notice Maps sender entity type to specific entity receiver to fee percentage as a zoc.
    mapping(uint8 => mapping(Entity => uint32)) transferFeeReceiverOverride;
    /// @notice Maps swap wrappers to their enabled/disabled status.

    mapping(ISwapWrapper => bool) public isSwapperSupported;
    /// @notice Maps portfolios to their enabled/disabled status.
    mapping(Portfolio => bool) public isActivePortfolio;

    // --- Events ---

    /// @notice The event emitted when a factory is approved (whitelisted) or has it's approval removed.
    event FactoryApprovalSet(address indexed factory, bool isApproved);

    /// @notice The event emitted when an entity is set active or inactive.
    event EntityStatusSet(address indexed entity, bool isActive);

    /// @notice The event emitted when a swap wrapper is set active or inactive.
    event SwapWrapperStatusSet(address indexed swapWrapper, bool isSupported);

    /// @notice The event emitted when a portfolio is set active or inactive.
    event PortfolioStatusSet(address indexed portfolio, bool isActive);

    /// @notice Emitted when a default donation fee is set for an entity type.
    event DefaultDonationFeeSet(uint8 indexed entityType, uint32 fee);

    /// @notice Emitted when a donation fee override is set for a specific receiving entity.
    event DonationFeeReceiverOverrideSet(address indexed entity, uint32 fee);

    /// @notice Emitted when a default payout fee is set for an entity type.
    event DefaultPayoutFeeSet(uint8 indexed entityType, uint32 fee);

    /// @notice Emitted when a payout fee override is set for a specific sender entity.
    event PayoutFeeOverrideSet(address indexed entity, uint32 fee);

    /// @notice Emitted when a default transfer fee is set for transfers between entity types.
    event DefaultTransferFeeSet(uint8 indexed fromEntityType, uint8 indexed toEntityType, uint32 fee);

    /// @notice Emitted when a transfer fee override is set for transfers from an entity to a specific entityType.
    event TransferFeeSenderOverrideSet(address indexed fromEntity, uint8 indexed toEntityType, uint32 fee);

    /// @notice Emitted when a transfer fee override is set for transfers from an entityType to an entity.
    event TransferFeeReceiverOverrideSet(uint8 indexed fromEntityType, address indexed toEntity, uint32 fee);

    /// @notice Emitted when the registry treasury contract is changed
    event TreasuryChanged(address oldTreasury, address indexed newTreasury);

    /**
     * @notice Modifier for methods that require auth and that the manager cannot access.
     * @dev Overridden from Auth.sol. Reason: use custom error.
     */
    modifier requiresAuth() override {
        if (!isAuthorized(msg.sender, msg.sig)) revert Unauthorized();

        _;
    }

    // --- Constructor ---
    constructor(address _admin, address _treasury, ERC20 _baseToken) RegistryAuth(_admin, Authority(address(this))) {
        treasury = _treasury;
        emit TreasuryChanged(address(0), _treasury);
        baseToken = _baseToken;
    }

    // --- Internal fns ---

    /**
     * @notice Fee parsing to convert the special "type(uint32).max" value to zero, and zero to the "max".
     * @dev After converting, "type(uint32).max" will cause overflow/revert when used as a fee percentage multiplier and zero will mean no fee.
     * @param _value The value to be converted.
     * @return The parsed fee to use.
     */
    function _parseFeeWithFlip(uint32 _value) private pure returns (uint32) {
        if (_value == 0) {
            return type(uint32).max;
        } else if (_value == type(uint32).max) {
            return 0;
        } else {
            return _value;
        }
    }

    // --- External fns ---

    /**
     * @notice Sets a new Endaoment treasury address.
     * @param _newTreasury The new treasury.
     */
    function setTreasury(address _newTreasury) external requiresAuth {
        emit TreasuryChanged(treasury, _newTreasury);
        treasury = _newTreasury;
    }

    /**
     * @notice Sets the approval state of a factory. Grants the factory permissions to set entity status.
     * @param _factory The factory whose approval state is to be updated.
     * @param _isApproved True if the factory should be approved, false otherwise.
     */
    function setFactoryApproval(address _factory, bool _isApproved) external requiresAuth {
        isApprovedFactory[_factory] = _isApproved;
        emit FactoryApprovalSet(address(_factory), _isApproved);
    }

    /**
     * @notice Sets the enable/disable state of an Entity.
     * @param _entity The entity whose active state is to be updated.
     * @param _isActive True if the entity should be active, false otherwise.
     */
    function setEntityStatus(Entity _entity, bool _isActive) external requiresAuth {
        isActiveEntity[_entity] = _isActive;
        emit EntityStatusSet(address(_entity), _isActive);
    }

    /**
     * @notice Sets Entity as active. This is a special method to be called only by approved factories.
     * Other callers should use `setEntityStatus` instead.
     * @param _entity The entity.
     */
    function setEntityActive(Entity _entity) external {
        if (!isApprovedFactory[msg.sender]) revert Unauthorized();
        isActiveEntity[_entity] = true;
        emit EntityStatusSet(address(_entity), true);
    }

    /**
     * @notice Sets the enable/disable state of a Portfolio.
     * @param _portfolio Portfolio.
     * @param _isActive True if setting portfolio to active, false otherwise.
     */
    function setPortfolioStatus(Portfolio _portfolio, bool _isActive) external requiresAuth {
        isActivePortfolio[_portfolio] = _isActive;
        emit PortfolioStatusSet(address(_portfolio), _isActive);
    }

    /**
     * @notice Gets default donation fee pct (as a zoc) for an Entity.
     * @param _entity The receiving entity of the donation for which the fee is being fetched.
     * @return uint32 The default donation fee for the entity's type.
     * @dev Makes use of _parseFeeWithFlip, so if no default exists, "max" will be returned.
     */
    function getDonationFee(Entity _entity) external view returns (uint32) {
        return _parseFeeWithFlip(defaultDonationFee[_entity.entityType()]);
    }

    /**
     * @notice Gets lowest possible donation fee pct (as a zoc) for an Entity, among default and override.
     * @param _entity The receiving entity of the donation for which the fee is being fetched.
     * @return uint32 The minimum of the default donation fee and the receiver's fee override.
     * @dev Makes use of _parseFeeWithFlip, so if no default or override exists, "max" will be returned.
     */
    function getDonationFeeWithOverrides(Entity _entity) external view returns (uint32) {
        uint32 _default = _parseFeeWithFlip(defaultDonationFee[_entity.entityType()]);
        uint32 _receiverOverride = _parseFeeWithFlip(donationFeeReceiverOverride[_entity]);
        return _receiverOverride < _default ? _receiverOverride : _default;
    }

    /**
     * @notice Gets default payout fee pct (as a zoc) for an Entity.
     * @param _entity The sender entity of the payout for which the fee is being fetched.
     * @return uint32 The default payout fee for the entity's type.
     * @dev Makes use of _parseFeeWithFlip, so if no default exists, "max" will be returned.
     */
    function getPayoutFee(Entity _entity) external view returns (uint32) {
        return _parseFeeWithFlip(defaultPayoutFee[_entity.entityType()]);
    }

    /**
     * @notice Gets lowest possible payout fee pct (as a zoc) for an Entity, among default and override.
     * @param _entity The sender entity of the payout for which the fee is being fetched.
     * @return uint32 The minimum of the default payout fee and the sender's fee override.
     * @dev Makes use of _parseFeeWithFlip, so if no default or override exists, "max" will be returned.
     */
    function getPayoutFeeWithOverrides(Entity _entity) external view returns (uint32) {
        uint32 _default = _parseFeeWithFlip(defaultPayoutFee[_entity.entityType()]);
        uint32 _senderOverride = _parseFeeWithFlip(payoutFeeOverride[_entity]);
        return _senderOverride < _default ? _senderOverride : _default;
    }

    /**
     * @notice Gets default transfer fee pct (as a zoc) between sender & receiver Entities.
     * @param _sender The sending entity of the transfer for which the fee is being fetched.
     * @param _receiver The receiving entity of the transfer for which the fee is being fetched.
     * @return uint32 The default transfer fee.
     * @dev Makes use of _parseFeeWithFlip, so if no default exists, "type(uint32).max" will be returned.
     */
    function getTransferFee(Entity _sender, Entity _receiver) external view returns (uint32) {
        return _parseFeeWithFlip(defaultTransferFee[_sender.entityType()][_receiver.entityType()]);
    }

    /**
     * @notice Gets lowest possible transfer fee pct (as a zoc) between sender & receiver Entities, among default and overrides.
     * @param _sender The sending entity of the transfer for which the fee is being fetched.
     * @param _receiver The receiving entity of the transfer for which the fee is being fetched.
     * @return uint32 The minimum of the default transfer fee, and sender and receiver overrides.
     * @dev Makes use of _parseFeeWithFlip, so if no default or overrides exist, "type(uint32).max" will be returned.
     */
    function getTransferFeeWithOverrides(Entity _sender, Entity _receiver) external view returns (uint32) {
        uint32 _default = _parseFeeWithFlip(defaultTransferFee[_sender.entityType()][_receiver.entityType()]);
        uint32 _senderOverride = _parseFeeWithFlip(transferFeeSenderOverride[_sender][_receiver.entityType()]);
        uint32 _receiverOverride = _parseFeeWithFlip(transferFeeReceiverOverride[_sender.entityType()][_receiver]);

        uint32 _lowestFee = _default;
        _lowestFee = _senderOverride < _lowestFee ? _senderOverride : _lowestFee;
        _lowestFee = _receiverOverride < _lowestFee ? _receiverOverride : _lowestFee;
        return _lowestFee;
    }

    /**
     * @notice Sets the default donation fee for an entity type.
     * @param _entityType Entity type.
     * @param _fee The fee percentage to be set (a zoc).
     */
    function setDefaultDonationFee(uint8 _entityType, uint32 _fee) external requiresAuth {
        defaultDonationFee[_entityType] = _parseFeeWithFlip(_fee);
        emit DefaultDonationFeeSet(_entityType, _fee);
    }

    /**
     * @notice Sets the donation fee receiver override for a specific entity.
     * @param _entity Entity.
     * @param _fee The overriding fee (a zoc).
     */
    function setDonationFeeReceiverOverride(Entity _entity, uint32 _fee) external requiresAuth {
        donationFeeReceiverOverride[_entity] = _parseFeeWithFlip(_fee);
        emit DonationFeeReceiverOverrideSet(address(_entity), _fee);
    }

    /**
     * @notice Sets the default payout fee for an entity type.
     * @param _entityType Entity type.
     * @param _fee The fee percentage to be set (a zoc).
     */
    function setDefaultPayoutFee(uint8 _entityType, uint32 _fee) external requiresAuth {
        defaultPayoutFee[_entityType] = _parseFeeWithFlip(_fee);
        emit DefaultPayoutFeeSet(_entityType, _fee);
    }

    /**
     * @notice Sets the payout fee override for a specific entity.
     * @param _entity Entity.
     * @param _fee The overriding fee (a zoc).
     */
    function setPayoutFeeOverride(Entity _entity, uint32 _fee) external requiresAuth {
        payoutFeeOverride[_entity] = _parseFeeWithFlip(_fee);
        emit PayoutFeeOverrideSet(address(_entity), _fee);
    }

    /**
     * @notice Sets the default transfer fee for transfers from one specific entity type to another.
     * @param _fromEntityType The entityType making the transfer.
     * @param _toEntityType The receiving entityType.
     * @param _fee The transfer fee percentage (a zoc).
     */
    function setDefaultTransferFee(uint8 _fromEntityType, uint8 _toEntityType, uint32 _fee) external requiresAuth {
        defaultTransferFee[_fromEntityType][_toEntityType] = _parseFeeWithFlip(_fee);
        emit DefaultTransferFeeSet(_fromEntityType, _toEntityType, _fee);
    }

    /**
     * @notice Sets the transfer fee override for transfers from one specific entity to entities of a given type.
     * @param _fromEntity The entity making the transfer.
     * @param _toEntityType The receiving entityType.
     * @param _fee The overriding fee percentage (a zoc).
     */
    function setTransferFeeSenderOverride(Entity _fromEntity, uint8 _toEntityType, uint32 _fee) external requiresAuth {
        transferFeeSenderOverride[_fromEntity][_toEntityType] = _parseFeeWithFlip(_fee);
        emit TransferFeeSenderOverrideSet(address(_fromEntity), _toEntityType, _fee);
    }

    /**
     * @notice Sets the transfer fee override for transfers from entities of a given type to a specific entity.
     * @param _fromEntityType The entityType making the transfer.
     * @param _toEntity The receiving entity.
     * @param _fee The overriding fee percentage (a zoc).
     */
    function setTransferFeeReceiverOverride(uint8 _fromEntityType, Entity _toEntity, uint32 _fee)
        external
        requiresAuth
    {
        transferFeeReceiverOverride[_fromEntityType][_toEntity] = _parseFeeWithFlip(_fee);
        emit TransferFeeReceiverOverrideSet(_fromEntityType, address(_toEntity), _fee);
    }

    /**
     * @notice Sets the enable/disable state of a SwapWrapper. System owners must ensure meticulous review of SwapWrappers before approving them.
     * @param _swapWrapper A contract that implements ISwapWrapper.
     * @param _supported `true` if supported, `false` if unsupported.
     */
    function setSwapWrapperStatus(ISwapWrapper _swapWrapper, bool _supported) external requiresAuth {
        isSwapperSupported[_swapWrapper] = _supported;
        emit SwapWrapperStatusSet(address(_swapWrapper), _supported);
    }
}

//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

import {Auth, Authority} from "./lib/auth/Auth.sol";
import {RolesAuthority} from "./lib/auth/authorities/RolesAuthority.sol";

// --- Errors ---
error OwnershipInvalid();

/**
 * @notice RegistryAuth - contract to control ownership of the Registry.
 */
contract RegistryAuth is RolesAuthority {
    /// @notice Emitted when the first step of an ownership transfer (proposal) is done.
    event OwnershipTransferProposed(address indexed user, address indexed newOwner);

    /// @notice Emitted when the second step of an ownership transfer (claim) is done.
    event OwnershipChanged(address indexed owner, address indexed newOwner);

    // --- Storage ---
    /// @notice Pending owner for 2 step ownership transfer
    address public pendingOwner;

    // --- Constructor ---
    constructor(address _owner, Authority _authority) RolesAuthority(_owner, _authority) {}

    /**
     * @notice Starts the 2 step process of transferring registry authorization to a new owner.
     * @param _newOwner Proposed new owner of registry authorization.
     */
    function transferOwnership(address _newOwner) external requiresAuth {
        pendingOwner = _newOwner;

        emit OwnershipTransferProposed(msg.sender, _newOwner);
    }

    /**
     * @notice Completes the 2 step process of transferring registry authorization to a new owner.
     * This function must be called by the proposed new owner.
     */
    function claimOwnership() external {
        if (msg.sender != pendingOwner) revert OwnershipInvalid();
        emit OwnershipChanged(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    /**
     * @notice Old approach of setting a new owner in a single step.
     * @dev This function throws an error to force use of the new 2-step approach.
     */
    function setOwner(address /*newOwner*/ ) public view override requiresAuth {
        revert OwnershipInvalid();
    }
}

//SPDX-License-Identifier: BSD 3-Clause
pragma solidity >=0.8.0;

error ETHAmountInMismatch();

/**
 * @notice ISwapWrapper is the interface that all swap wrappers should implement.
 * This will be used to support swap protocols like Uniswap V2 and V3, Sushiswap, 1inch, etc.
 */
interface ISwapWrapper {
    /// @notice Event emitted after a successful swap.
    event WrapperSwapExecuted(
        address indexed tokenIn,
        address indexed tokenOut,
        address sender,
        address indexed recipient,
        uint256 amountIn,
        uint256 amountOut
    );

    /// @notice Name of swap wrapper for UX readability.
    function name() external returns (string memory);

    /**
     * @notice Swap function. Generally we expect the implementer to call some exactAmountIn-like swap method, and so the documentation
     * is written with this in mind. However, the method signature is general enough to support exactAmountOut swaps as well.
     * @param _tokenIn Token to be swapped (or 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE for ETH).
     * @param _tokenOut Token to receive (or 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE for ETH).
     * @param _recipient Receiver of `_tokenOut`.
     * @param _amount Amount of `_tokenIn` that should be swapped.
     * @param _data Additional data that the swap wrapper may require to execute the swap.
     * @return Amount of _tokenOut received.
     */
    function swap(address _tokenIn, address _tokenOut, address _recipient, uint256 _amount, bytes calldata _data)
        external
        payable
        returns (uint256);
}

// SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

library Math {
    uint256 internal constant ZOC = 1e4;

    /**
     * @dev Multiply 2 numbers where at least one is a zoc, return product in original units of the other number.
     */
    function zocmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
        unchecked {
            z /= ZOC;
        }
    }

    // Below is WAD math from solmate's FixedPointMathLib.
    // https://github.com/Rari-Capital/solmate/blob/c8278b3cb948cffda3f1de5a401858035f262060/src/utils/FixedPointMathLib.sol

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    // For tokens with 6 decimals like USDC, these scale by 1e6 (one million).
    function mulMilDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, 1e6); // Equivalent to (x * y) / 1e6 rounded down.
    }

    function divMilDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, 1e6, y); // Equivalent to (x * 1e6) / y rounded down.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) { revert(0, 0) }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Modified Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private reentrancyStatus;

    error Reentrancy();

    function __initReentrancyGuard() internal {
        if (reentrancyStatus != 0) revert Reentrancy();
        reentrancyStatus = 1;
    }

    modifier nonReentrant() {
        if (reentrancyStatus != 1) revert Reentrancy();

        reentrancyStatus = 2;

        _;

        reentrancyStatus = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// This contract is modified from Solmate only to make requiresAuth virtual on line 26

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() virtual {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(address user, address target, bytes4 functionSig) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {RolesAuthority} from "./authorities/RolesAuthority.sol";

/**
 * @notice An abstract Auth that contracts in the Endaoment ecosystem can inherit from. It is based on
 * the `Auth.sol` contract from Solmate, but does not inherit from it. Most of the functionality
 * is either slightly different, or not needed. In particular:
 * - EndaomentAuth uses an initializer such that it can be deployed with minimal proxies.
 * - EndaomentAuth contracts reference a RolesAuthority, not just an Authority, when looking up permissions.
 *   In the Endaoment ecosystem, this is assumed to be the Registry.
 * - EndaomentAuth contracts do not have an owner, but instead grant ubiquitous permission to its RoleAuthority's
 *   owner. In the Endaoment ecosystem, this is assumed to be the board of directors multi-sig.
 * - EndaomentAuth contracts can optionally declare themselves a "special target" at deploy time. Instead of passing
 *   their address to the authority when looking up their permissions, they'll instead pass the special target bytes.
 *   See documentation on `specialTarget` for more information.
 *
 */
abstract contract EndaomentAuth {
    /// @notice Thrown when an account without proper permissions calls a privileged method.
    error Unauthorized();

    /// @notice Thrown if there is an attempt to deploy with address 0 as the authority.
    error InvalidAuthority();

    /// @notice Thrown if there is a second call to initialize.
    error AlreadyInitialized();

    /// @notice The contract used to source permissions for accounts targeting this contract.
    RolesAuthority public authority;

    /**
     * @notice If set to a non-zero value, this contract will pass these byes as the target contract
     * to the RolesAuthority's `canCall` method, rather than its own contract. This allows a single
     * RolesAuthority permission to manage permissions simultaneously for a group of contracts that
     * identify themselves as a certain type. For example: set a permission for all "entity" contracts.
     */
    bytes20 public specialTarget;

    /**
     * @notice One time method to be called at deployment to configure the contract. Required so EndaomentAuth
     * contracts can be deployed as minimal proxies (clones).
     * @param _authority Contract that will be used to source permissions for accounts targeting this contract.
     * @param _specialTarget The bytes that this contract will pass as the "target" when looking up permissions
     * from the authority. If set to empty bytes, this contract will pass its own address instead.
     */
    function __initEndaomentAuth(RolesAuthority _authority, bytes20 _specialTarget) internal virtual {
        if (address(_authority) == address(0)) revert InvalidAuthority();
        if (address(authority) != address(0)) revert AlreadyInitialized();
        authority = _authority;
        specialTarget = _specialTarget;
    }

    /**
     * @notice Modifier for methods that require authorization to execute.
     */
    modifier requiresAuth() virtual {
        if (!isAuthorized(msg.sender, msg.sig)) revert Unauthorized();
        _;
    }

    /**
     * @notice Internal method that asks the authority whether the caller has permission to execute a method.
     * @param user The account attempting to call a permissioned method on this contract
     * @param functionSig The signature hash of the permissioned method being invoked.
     */
    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        RolesAuthority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.
        address _target = specialTarget == "" ? address(this) : address(specialTarget);

        // The caller has permission on authority, or the caller is the RolesAuthority owner
        return auth.canCall(user, _target, functionSig) || user == auth.owner();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// This contract is modified from Solmate only to import modified Auth.sol on line 5
import {Auth, Authority} from "../Auth.sol";

/// @notice Role based Authority that supports up to 256 roles.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/authorities/RolesAuthority.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-roles/blob/master/src/roles.sol)
contract RolesAuthority is Auth, Authority {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event UserRoleUpdated(address indexed user, uint8 indexed role, bool enabled);

    event PublicCapabilityUpdated(address indexed target, bytes4 indexed functionSig, bool enabled);

    event RoleCapabilityUpdated(uint8 indexed role, address indexed target, bytes4 indexed functionSig, bool enabled);

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

    /*///////////////////////////////////////////////////////////////
                            ROLE/USER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => bytes32) public getUserRoles;

    mapping(address => mapping(bytes4 => bool)) public isCapabilityPublic;

    mapping(address => mapping(bytes4 => bytes32)) public getRolesWithCapability;

    function doesUserHaveRole(address user, uint8 role) public view virtual returns (bool) {
        return (uint256(getUserRoles[user]) >> role) & 1 != 0;
    }

    function doesRoleHaveCapability(uint8 role, address target, bytes4 functionSig)
        public
        view
        virtual
        returns (bool)
    {
        return (uint256(getRolesWithCapability[target][functionSig]) >> role) & 1 != 0;
    }

    /*///////////////////////////////////////////////////////////////
                          AUTHORIZATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function canCall(address user, address target, bytes4 functionSig) public view virtual override returns (bool) {
        return isCapabilityPublic[target][functionSig]
            || bytes32(0) != getUserRoles[user] & getRolesWithCapability[target][functionSig];
    }

    /*///////////////////////////////////////////////////////////////
                  ROLE CAPABILITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function setPublicCapability(address target, bytes4 functionSig, bool enabled) public virtual requiresAuth {
        isCapabilityPublic[target][functionSig] = enabled;

        emit PublicCapabilityUpdated(target, functionSig, enabled);
    }

    function setRoleCapability(uint8 role, address target, bytes4 functionSig, bool enabled)
        public
        virtual
        requiresAuth
    {
        if (enabled) {
            getRolesWithCapability[target][functionSig] |= bytes32(1 << role);
        } else {
            getRolesWithCapability[target][functionSig] &= ~bytes32(1 << role);
        }

        emit RoleCapabilityUpdated(role, target, functionSig, enabled);
    }

    /*///////////////////////////////////////////////////////////////
                      USER ROLE ASSIGNMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    function setUserRole(address user, uint8 role, bool enabled) public virtual requiresAuth {
        if (enabled) {
            getUserRoles[user] |= bytes32(1 << role);
        } else {
            getUserRoles[user] &= ~bytes32(1 << role);
        }

        emit UserRoleUpdated(user, role, enabled);
    }
}