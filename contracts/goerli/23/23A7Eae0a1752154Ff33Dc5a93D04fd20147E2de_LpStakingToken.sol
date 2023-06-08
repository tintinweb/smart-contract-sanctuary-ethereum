// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.19;

import { ERC20 } from "../../../lib/solmate/src/tokens/ERC20.sol";
import { OwnerTwoStep } from "../../utils/OwnerTwoStep.sol";

contract LpStakingToken is OwnerTwoStep, ERC20 {
    // This LpStakingToken uses OwnerTwoStep for authorization of minting.
    // The LpStakingManager should be set as the admin of this contract.
    bool private _initialized;
    error LpStakingTokenAlreadyInitialized();

    /**
     * @notice constructor for the LpStakingToken
     */
    constructor() ERC20("", "", 18) {}

    /**
     * @notice Initializes the LpStakingToken
     * @param name_  the name to use for the token
     * @param symbol_  the symbol to use for the token
     */
    function initLpStakingToken(
        address owner_,
        string memory name_,
        string memory symbol_
    ) external {
        if (_initialized) {
            revert LpStakingTokenAlreadyInitialized();
        }
        _initialized = true; 
        name = name_;
        symbol = symbol_;
        _transferOwnership(owner_);
    }

    /**
     * @notice mints tokens to the given address
     *
     * @param to_ Address to mint tokens to
     * @param amount_ Amount of tokens to mint
     */
    function mint(address to_, uint256 amount_) public onlyOwner {
        _mint(to_, amount_);
    }

    /**
     * @notice returns whether the LpStaking contract has been initialized
     * @return _initialized whether the LpStaking contract has been initialized
     */
    function initialized() public view returns (bool) {
        return _initialized;
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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import { IOwnerTwoStep } from "../interface/IOwnerTwoStep.sol";

abstract contract OwnerTwoStep is IOwnerTwoStep {

    /// @dev The owner of the contract
    address private _owner;

    /// @dev The pending owner of the contract
    address private _pendingOwner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    // ***************************************************************
    // * ========================= EVENTS ========================== *
    // ***************************************************************

    event OwnerTwoStepOwnerStartedTransfer(address currentOwner, address newPendingOwner);
    event OwnerTwoStepPendingOwnerAcceptedTransfer(address newOwner);
    event OwnerTwoStepOwnershipTransferred(address previousOwner, address newOwner);
    event OwnerTwoStepOwnerRenouncedOwnership(address previousOwner);

    // ***************************************************************
    // * ========================= ERRORS ========================== *
    // ***************************************************************

    error OwnerTwoStepNotOwner();
    error OwnerTwoStepNotPendingOwner();

    // ***************************************************************
    // * =================== USER INTERFACE ======================== *
    // ***************************************************************

    ///@inheritdoc IOwnerTwoStep
    function transferOwnership(address newPendingOwner_) public virtual override onlyOwner {
        _pendingOwner = newPendingOwner_;

        emit OwnerTwoStepOwnerStartedTransfer(_owner, newPendingOwner_);
    }

    ///@inheritdoc IOwnerTwoStep
    function acceptOwnership() public virtual override onlyPendingOwner {
        emit OwnerTwoStepPendingOwnerAcceptedTransfer(msg.sender);

        _transferOwnership(msg.sender);
    }

    ///@inheritdoc IOwnerTwoStep
    function renounceOwnership() public virtual onlyOwner {

        emit OwnerTwoStepOwnerRenouncedOwnership(msg.sender);

        _transferOwnership(address(0));
    }

    // ***************************************************************
    // * =================== VIEW FUNCTIONS ======================== *
    // ***************************************************************

    ///@inheritdoc IOwnerTwoStep
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    ///@inheritdoc IOwnerTwoStep
    function pendingOwner() external view override returns (address) {
        return _pendingOwner;
    }

    // ***************************************************************
    // * ===================== MODIFIERS =========================== *
    // ***************************************************************

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @dev Throws if called by any account other than the pending owner.
     */
    modifier onlyPendingOwner {
        if (msg.sender != _pendingOwner) {
            revert OwnerTwoStepNotPendingOwner();
        }
        _;
    }

    // ***************************************************************
    // * ================== INTERNAL HELPERS ======================= *
    // ***************************************************************

    /**
     * @dev Throws if called by any account other than the owner. Saves contract size over copying 
     *   implementation into every function that uses the modifier.
     */
    function _onlyOwner() internal view virtual {
        if (msg.sender != _owner) {
            revert OwnerTwoStepNotOwner();
        }
    }


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * @param newOwner_ New owner to transfer to
     */
    function _transferOwnership(address newOwner_) internal {
        delete _pendingOwner;

        emit OwnerTwoStepOwnershipTransferred(_owner, newOwner_);

        _owner = newOwner_;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

/**
 * @title IOwnerTwoStep
 * @notice Interface for the OwnerTwoStep contract
 */
interface IOwnerTwoStep {

    // ***************************************************************
    // * =================== USER INTERFACE ======================== *
    // ***************************************************************

    /**
     * @notice Starts the ownership transfer of the contract to a new account. Replaces the 
     *   pending transfer if there is one. 
     * @dev Can only be called by the current owner.
     * @param newOwner_ The address of the new owner
     */
    function transferOwnership(address newOwner_) external;

    /**
     * @notice Completes the transfer process to a new owner.
     * @dev only callable by the pending owner that is accepting the new ownership.
     */
    function acceptOwnership() external;

    /**
     * @notice Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     */
    function renounceOwnership() external;

    // ***************************************************************
    // * =================== VIEW FUNCTIONS ======================== *
    // ***************************************************************

    /**
     * @notice Getter function to find out the current owner address
     * @return owner The current owner address
     */
    function owner() external view returns (address);

    /**
     * @notice Getter function to find out the pending owner address
     * @dev The pending address is 0 when there is no transfer of owner in progress
     * @return pendingOwner The pending owner address, if any
     */
    function pendingOwner() external view returns (address);
}