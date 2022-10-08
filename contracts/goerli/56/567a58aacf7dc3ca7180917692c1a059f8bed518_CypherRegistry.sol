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
                                EVENTS
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