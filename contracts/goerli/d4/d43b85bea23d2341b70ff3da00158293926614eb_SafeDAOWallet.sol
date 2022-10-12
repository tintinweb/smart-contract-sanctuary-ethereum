// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ICypherEscrow} from "../../src/interfaces/ICypherEscrow.sol";
import {CypherProtocol} from "../../src/CypherProtocol.sol";

contract SafeDAOWallet is CypherProtocol {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public ethBalances;

    constructor(address architect, address registry) CypherProtocol("DAOWallet", architect, registry) {}

    function deposit() public payable {
        ethBalances[msg.sender] += (msg.value);
    }

    function depositTokens(address token, uint256 amount) public {
        ERC20(token).transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
    }

    function balanceOf(address _who) public view returns (uint256 balance) {
        return ethBalances[_who];
    }

    function balanceOf(address _who, address _token) public view returns (uint256 balance) {
        return balances[_who];
    }

    function withdrawETH() public {
        require(ethBalances[msg.sender] >= 0, "INSUFFICIENT_FUNDS");

        ICypherEscrow escrow = ICypherEscrow(getEscrow());
        escrow.escrowETH{value: ethBalances[msg.sender]}(msg.sender, msg.sender);

        ethBalances[msg.sender] = 0;
    }

    function withdraw(address token, uint256 _amount) public {
        // if the user has enough balance to withdraw
        require(balances[msg.sender] >= _amount, "INSUFFICIENT_FUNDS");

        ICypherEscrow escrow = ICypherEscrow(getEscrow());
        ERC20(token).approve(address(escrow), _amount);
        escrow.escrowTokens(address(this), msg.sender, token, _amount);

        balances[msg.sender] -= _amount;
    }

    function getContractBalance() public returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ICypherEscrow {
    function escrowTokens(
        address origin,
        address dst,
        address asset,
        uint256 amount
    ) external;

    function escrowETH(address origin, address dst) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {CypherRegistry} from "./CypherRegistry.sol";

/// @title Cypher Escrow Protocol
/// @author bmwoolf
/// @author zksoju
/// @notice A skeleton for a protocol contract when creating a new escrow
abstract contract CypherProtocol {
    /*//////////////////////////////////////////////////////////////
                            PROTOCOL STATE
    //////////////////////////////////////////////////////////////*/

    address registry;
    address architect;
    string protocolName;

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event ProtocolCreated(address indexed registry, address indexed architect, string protocolName);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _protocolName,
        address _architect,
        address _registry
    ) {
        architect = _architect;
        registry = _registry;
        protocolName = _protocolName;

        emit ProtocolCreated(_registry, _architect, _protocolName);
    }

    /*//////////////////////////////////////////////////////////////
                              GETTERS
    //////////////////////////////////////////////////////////////*/

    function getEscrow() internal view returns (address) {
        return address(CypherRegistry(registry).getEscrowForProtocol(address(this)));
    }

    function getArchitect() external view returns (address) {
        return architect;
    }

    function getProtocolName() external view returns (string memory) {
        return protocolName;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {CypherEscrow} from "./CypherEscrow.sol";
import {ICypherProtocol} from "./interfaces/ICypherProtocol.sol";

/// @title Cypher Escrow System Registry
/// @author bmwoolf
/// @author zksoju
/// @notice Registry for storing the escrows for a protocol
contract CypherRegistry {
    /*//////////////////////////////////////////////////////////////
                            REGISTRY STATE
    //////////////////////////////////////////////////////////////*/

    mapping(address => CypherEscrow) public getEscrowForProtocol;

    /*//////////////////////////////////////////////////////////////
                             EVENTS
    //////////////////////////////////////////////////////////////*/

    event EscrowCreated(
        address indexed escrow,
        address indexed protocol,
        address token,
        uint256 tokenThreshold,
        uint256 timeLimit,
        address[] oracles
    );
    event EscrowAttached(address indexed escrow, address indexed protocol);

    /*//////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

    error ProtocolAlreadyRegistered();

    /*//////////////////////////////////////////////////////////////
                             MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier architectOnly(address protocol) {
        require(ICypherProtocol(protocol).getArchitect() == msg.sender, "ok");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {}

    /*//////////////////////////////////////////////////////////////
                            CREATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Creates a new escrow for a protocol
    /// @param protocol The address of the contract to protect
    /// @param token The address of the token that is being stored in the protocols smart contracts
    /// @param tokenThreshold The amount per tx to limit on withdraw
    /// @param timeLimit How long the funds should stay locked up until release (if the team does not respond)
    /// @param oracles The addresses of the signers who can release the funds
    function createEscrow(
        address protocol,
        address token,
        uint256 tokenThreshold,
        uint256 timeLimit,
        address[] memory oracles
    ) public architectOnly(protocol) returns (address) {
        if (getEscrowForProtocol[protocol] != CypherEscrow(address(0))) revert ProtocolAlreadyRegistered();
        CypherEscrow escrow = new CypherEscrow(token, tokenThreshold, timeLimit, oracles);
        getEscrowForProtocol[protocol] = escrow;

        emit EscrowCreated(address(escrow), protocol, token, tokenThreshold, timeLimit, oracles);

        return address(escrow);
    }

    /// @dev Assigns an existing escrow to a protocol
    function attachEscrow(address escrow, address protocol) public architectOnly(protocol) {
        getEscrowForProtocol[protocol] = CypherEscrow(escrow);

        emit EscrowAttached(escrow, protocol);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "./interfaces/IERC20.sol";
import {IWETH9} from "./interfaces/IWETH9.sol";

import {ReentrancyGuard} from "./utils/ReentrancyGuard.sol";

/// @title Cypher Escrow System
/// @author bmwoolf
/// @author zksoju
/// @notice Rate limiter for smart contract withdrawals- much like the bank's rate limiter
contract CypherEscrow is ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                            ESCROW STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the token being stored in the escrow
    address public token;

    /// @notice The amount of tokens that will create an escrow
    uint256 public tokenThreshold;

    /// @notice The amount of time before the funds can be released if no response from the oracles
    uint256 public timeLimit;

    /// @notice Allowed oracle addresses to sign off on escrowed transactions
    mapping(address => bool) isOracle;

    /// @notice Whales that are whitelisted to withdraw without rate limiting
    mapping(address => bool) public isWhitelisted;

    /// @notice Request info mapping
    mapping(bytes32 => Transaction) public getTransactionInfo;

    /// @notice The counter for the source contract
    mapping(address => uint256) public getCounterForOrigin;

    /// @notice Withdraw request info
    struct Transaction {
        address origin;
        address protocol;
        address dst;
        address asset;
        uint256 amount;
    }

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event AmountStopped(
        bytes32 key,
        address indexed origin,
        address indexed protocol,
        address indexed dst,
        address tokenContract,
        uint256 amount,
        uint256 counter
    );
    event TransactionAccepted(bytes32 key);
    event TransactionDenied(bytes32 key);
    event OracleAdded(address indexed user, address oracle);
    event TimeLimitSet(uint256 timeLimit);
    event AddressAddedToWhitelist(address indexed user, address whitelist);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotOracle();
    error NotValidAddress();
    error NotApproved();
    error MustBeDisapproved();
    error TransferFailed();

    /*//////////////////////////////////////////////////////////////
                             MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOracle() {
        bool isAuthorized = isOracle[msg.sender];
        if (!isAuthorized) revert NotOracle();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _token,
        uint256 _tokenThreshold,
        uint256 _timeLimit,
        address[] memory _oracles
    ) {
        token = _token;
        tokenThreshold = _tokenThreshold;
        timeLimit = _timeLimit;

        for (uint256 i = 0; i < _oracles.length; i++) {
            isOracle[_oracles[i]] = true;
        }
    }

    /*//////////////////////////////////////////////////////////////
                            ESCROW LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Check if an ETH withdraw is valid
    /// @param origin The address of the user who initiated the withdraw
    /// @param dst The address of the user who will receive the ETH
    function escrowETH(address origin, address dst) external payable nonReentrant {
        // check if the stop has been overwritten by protocol owner on the frontend
        // if (msg.sender != sourceContract) revert NotSourceContract();
        if (origin == address(0) || dst == address(0)) revert NotValidAddress();

        uint256 amount = msg.value;

        // create key hash for getTransactionInfo mapping
        bytes32 key = hashTransactionKey(origin, msg.sender, dst, getCounterForOrigin[origin]);

        // if they are whitelisted or amount is less than threshold, just transfer the tokens
        if (amount < tokenThreshold || isWhitelisted[dst]) {
            (bool success, ) = address(dst).call{value: amount}("");
            if (!success) revert TransferFailed();
        } else if (getTransactionInfo[key].origin == address(0)) {
            addToLimiter(key, origin, msg.sender, dst, address(0), amount);
        }
    }

    /// @notice Check if an ERC20 withdraw is valid
    /// @param origin The address of the user who initiated the withdraw
    /// @param dst The address to transfer to
    /// @param asset The ERC20 token contract to withdraw from
    /// @param amount The amount to withdraw
    function escrowTokens(
        address origin,
        address dst,
        address asset,
        uint256 amount
    ) external {
        // check if the stop has been overwritten by protocol owner on the frontend
        // if (msg.sender != sourceContract) revert NotSourceContract();
        if (origin == address(0) || dst == address(0)) revert NotValidAddress();

        // create key hash for getTransactionInfo mapping
        bytes32 key = hashTransactionKey(origin, msg.sender, dst, getCounterForOrigin[origin]);

        // if they are whitelisted or amount is less than threshold, just transfer the tokens
        if (amount < tokenThreshold || isWhitelisted[origin]) {
            bool result = IERC20(asset).transferFrom(msg.sender, dst, amount);
            if (!result) revert TransferFailed();
        } else if (getTransactionInfo[key].origin == address(0)) {
            bool result = IERC20(asset).transferFrom(msg.sender, address(this), amount);
            if (!result) revert TransferFailed();
            addToLimiter(key, origin, msg.sender, dst, asset, amount);
        }
    }

    /// @notice Add a user to the limiter
    /// @param key The key to check the Transaction struct info
    /// @param origin The address of the user who initiated the withdraw
    /// @param protocol The address of the protocol to withdraw from
    /// @param dst The address to transfer to
    /// @param amount The amount to add to the limiter
    function addToLimiter(
        bytes32 key,
        address origin,
        address protocol,
        address dst,
        address asset,
        uint256 amount
    ) internal {
        getTransactionInfo[key].origin = origin;
        getTransactionInfo[key].protocol = protocol;
        getTransactionInfo[key].dst = dst;
        getTransactionInfo[key].asset = asset;
        getTransactionInfo[key].amount = amount;

        emit AmountStopped(key, origin, protocol, dst, asset, amount, getCounterForOrigin[origin] += 1);
    }

    /*//////////////////////////////////////////////////////////////
                          ORACLE AUTH LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Send approved funds to a user
    /// @param key The key to check the Transaction struct info
    function acceptTransaction(bytes32 key) external onlyOracle nonReentrant {
        Transaction memory txInfo = getTransactionInfo[key];

        uint256 amount = txInfo.amount;
        delete getTransactionInfo[key];

        if (txInfo.asset == address(0x0)) {
            (bool success, ) = address(txInfo.dst).call{value: amount}("");
            if (!success) revert TransferFailed();
        } else {
            /// @notice Our contract needs approval to swap tokens
            bool result = IERC20(txInfo.asset).transferFrom(address(this), txInfo.dst, txInfo.amount);
            if (!result) revert TransferFailed();
        }

        emit TransactionAccepted(key);
    }

    /// @notice Sends the funds back to the protocol- needs to be after they have fixed the exploit
    /// @param key The key to check the Transaction struct info
    /// @param to Address to redirect the funds to (in case protocol is compromised or cannot handle the funds)
    function denyTransaction(bytes32 key, address to) external onlyOracle nonReentrant {
        Transaction memory txInfo = getTransactionInfo[key];

        // update storage first to prevent reentrancy
        delete getTransactionInfo[key];

        // Send ETH back
        if (txInfo.asset == address(0x0)) {
            (bool success, ) = address(to).call{value: txInfo.amount}("");
            if (!success) revert TransferFailed();
        } else {
            // Send ERC20 back
            /// @notice Our contract needs approval to swap tokens
            bool result = IERC20(txInfo.asset).transferFrom(address(this), to, txInfo.amount);
            if (!result) revert TransferFailed();
        }

        emit TransactionDenied(key);
    }

    /*//////////////////////////////////////////////////////////////
                              SETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Set the timelimit for the tx before reverting
    /// @param _timeLimit The time limit in seconds
    function setTimeLimit(uint256 _timeLimit) external onlyOracle {
        timeLimit = _timeLimit;

        emit TimeLimitSet(timeLimit);
    }

    /// @notice Add an address to the whitelist
    /// @param to The addresses to add to the whitelist
    function addToWhitelist(address[] memory to) external onlyOracle {
        for (uint256 i = 0; i < to.length; i++) {
            isWhitelisted[to[i]] = true;

            emit AddressAddedToWhitelist(msg.sender, to[i]);
        }
    }

    /// @dev Add a new oracle
    /// @param _oracle The address of the new oracle
    /// @notice Can only come from a current oracle
    function addOracle(address _oracle) external onlyOracle {
        isOracle[_oracle] = true;

        emit OracleAdded(msg.sender, _oracle);
    }

    /*//////////////////////////////////////////////////////////////
                              GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Get wallet balance for specific wallet
    /// @param key The key to check the Transaction struct info
    /// @return Token amount
    function getTransaction(bytes32 key) external view returns (address, uint256) {
        Transaction memory txn = getTransactionInfo[key];
        return (txn.asset, txn.amount);
    }

    /*//////////////////////////////////////////////////////////////
                              UTILS
    //////////////////////////////////////////////////////////////*/

    /// @dev Hash the transaction information for reads
    /// @param origin Origin caller
    /// @param protocol The protocol to grab fund from
    /// @param dst The address to send to
    function hashTransactionKey(
        address origin,
        address protocol,
        address dst,
        uint256 counter
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(origin, protocol, dst, counter));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ICypherProtocol {
    function getArchitect() external view returns (address);

    function getEscrow() external view returns (address);

    function getProtocolName() external view returns (string memory);
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IERC20.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
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