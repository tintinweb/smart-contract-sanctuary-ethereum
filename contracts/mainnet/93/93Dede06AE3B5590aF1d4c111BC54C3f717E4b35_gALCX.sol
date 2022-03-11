// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";

import {IALCXSource} from "./interfaces/IALCXSource.sol";

/// @title A wrapper for single-sided ALCX staking
contract gALCX is ERC20 {

    IERC20 public alcx = IERC20(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);
    IALCXSource public pools = IALCXSource(0xAB8e74017a8Cc7c15FFcCd726603790d26d7DeCa);
    uint public poolId = 1;
    uint public constant exchangeRatePrecision = 1e18;
    uint public exchangeRate = exchangeRatePrecision;
    address public owner;

    event ExchangeRateChange(uint _exchangeRate);
    event Stake(address _from, uint _gAmount, uint _amount);
    event Unstake(address _from, uint _gAmount, uint _amount);

    /// @param _name The token name
    /// @param _symbol The token symbol
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol, 18) {
        owner = msg.sender;
        reApprove();
    }

    // OWNERSHIP

    modifier onlyOwner {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /// @notice Transfer contract ownership
    /// @param _owner The new owner address
    function transferOwnership(address _owner) external onlyOwner {
        owner = _owner;
    }

    /// @notice Set a new staking pool address and migrate funds there
    /// @param _pools The new pool address
    /// @param _poolId The new pool id
    function migrateSource(address _pools, uint _poolId) external onlyOwner {
        // Withdraw ALCX
        bumpExchangeRate();

        uint poolBalance = pools.getStakeTotalDeposited(address(this), poolId);
        pools.withdraw(poolId, poolBalance);
        // Update staking pool address and id
        pools = IALCXSource(_pools);
        poolId = _poolId;
        // Deposit ALCX
        uint balance = alcx.balanceOf(address(this));
        reApprove();
        pools.deposit(poolId, balance);
    }

    /// @notice Approve the staking pool to move funds in this address, can be called by anyone
    function reApprove() public {
        bool success = alcx.approve(address(pools), type(uint).max);
    }

    // PUBLIC FUNCTIONS

    /// @notice Claim and autocompound rewards
    function bumpExchangeRate() public {
        // Claim from pool
        pools.claim(poolId);
        // Bump exchange rate
        uint balance = alcx.balanceOf(address(this));

        if (balance > 0) {
            exchangeRate += (balance * exchangeRatePrecision) / totalSupply;
            emit ExchangeRateChange(exchangeRate);
            // Restake
            pools.deposit(poolId, balance);
        }
    }

    /// @notice Deposit new funds into the staking pool
    /// @param amount The amount of ALCX to deposit
    function stake(uint amount) external {
        // Get current exchange rate between ALCX and gALCX
        bumpExchangeRate();
        // Then receive new deposits
        bool success = alcx.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");
        pools.deposit(poolId, amount);
        // gAmount always <= amount
        uint gAmount = amount * exchangeRatePrecision / exchangeRate;
        _mint(msg.sender, gAmount);
        emit Stake(msg.sender, gAmount, amount);
    }

    /// @notice Withdraw funds from the staking pool
    /// @param gAmount the amount of gALCX to withdraw
    function unstake(uint gAmount) external {
        bumpExchangeRate();
        uint amount = gAmount * exchangeRate / exchangeRatePrecision;
        _burn(msg.sender, gAmount);
        // Withdraw ALCX and send to user
        pools.withdraw(poolId, amount);
        bool success = alcx.transfer(msg.sender, amount); // Should return true or revert, but doesn't hurt
        require(success, "Transfer failed"); 
        emit Unstake(msg.sender, gAmount, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

interface IALCXSource {
    function getStakeTotalDeposited(address _user, uint256 _poolId) external view returns (uint256);
    function claim(uint256 _poolId) external;
    function deposit(uint256 _poolId, uint256 _depositAmount) external;
    function withdraw(uint256 _poolId, uint256 _withdrawAmount) external;
}