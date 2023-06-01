//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Escrow {
    using SafeERC20 for IERC20;

    /*==============================================================
                            CONSTANTS
    ==============================================================*/

    /// @notice The owner of the contract
    address public immutable owner;

    /*==============================================================
                            VARIABLES
    ==============================================================*/

    enum DepositType {
        ETH,
        ERC20,
        ERC721
    }

    /// @notice The deposit struct
    struct Deposit {
        /// @notice The buyer address
        address buyer;
        /// @notice The seller address
        address seller;
        /// @notice The amount of the deposit (applies when deposit type is ETH or ERC20)
        uint256 amount;
        /// @notice The token address (if the deposit is ERC20 or ERC721)
        address token;
        /// @notice The token IDs (if the deposit is ERC721)
        uint256[] tokenIds;
        /// @notice The deposit type (ETH, ERC20, ERC721)
        DepositType depositType;
        /// @notice Whether the deposit has been released
        bool released;
    }

    /// @notice The current deposit ID
    uint256 public currentId;

    /// @notice The accrued fees
    uint256 public accruedFeesETH;

    mapping(address => uint256) public accruedFeesERC20;

    /// @notice The deposits mapping
    mapping(uint256 => Deposit) public deposits;

    /*==============================================================
                            MODIFIERS
    ==============================================================*/

    /// @notice Only owner can execute
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwner();
        }
        _;
    }

    /// @notice Only non-released deposits can be released
    /// @param _id The deposit ID
    modifier releaseGuard(uint256 _id) {
        Deposit storage deposit = deposits[_id];
        if (deposit.buyer == address(0)) {
            revert DepositDoesNotExist();
        }

        if (deposit.released == true) {
            revert AlreadyReleased();
        }
        _;
    }

    modifier nonEmptySeller(address _seller) {
        if (_seller == address(0)) {
            revert SellerAddressEmpty();
        }
        _;
    }

    /*==============================================================
                            FUNCTIONS
    ==============================================================*/

    constructor() {
        owner = msg.sender;
    }

    /// @notice Creates a new ETH deposit
    /// @param _seller The seller address
    function createDepositETH(
        address _seller
    ) external payable nonEmptySeller(_seller) {
        if (msg.value == 0) {
            revert DepositAmountZero();
        }

        Deposit memory deposit;
        deposit.buyer = msg.sender;
        deposit.seller = _seller;
        deposit.amount = msg.value;
        deposit.depositType = DepositType.ETH;
        deposits[++currentId] = deposit;

        emit NewDepositETH(currentId, msg.sender, _seller, msg.value);
    }

    /// @notice Creates a new ERC20 deposit
    /// @param _seller The seller address
    /// @param _token The token address
    /// @param _amount The amount of tokens
    function createDepositERC20(
        address _seller,
        address _token,
        uint256 _amount
    ) external nonEmptySeller(_seller) {
        if (_token == address(0)) {
            revert TokenAddressEmpty();
        }

        if (_amount == 0) {
            revert DepositAmountZero();
        }

        Deposit memory deposit;
        deposit.buyer = msg.sender;
        deposit.seller = _seller;
        deposit.amount = _amount;
        deposit.token = _token;
        deposit.depositType = DepositType.ERC20;
        deposits[++currentId] = deposit;

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        emit NewDepositERC20(currentId, msg.sender, _seller, _token, _amount);
    }

    /// @notice Creates a new ERC721 deposit
    /// @param _seller The seller address
    /// @param _token The token address
    /// @param _tokenIds The token IDs
    function createDepositERC721(
        address _seller,
        address _token,
        uint256[] calldata _tokenIds
    ) external nonEmptySeller(_seller) {
        if (_token == address(0)) {
            revert TokenAddressEmpty();
        }

        if (_tokenIds.length == 0) {
            revert NoTokenIds();
        }

        Deposit memory deposit;
        deposit.buyer = msg.sender;
        deposit.seller = _seller;
        deposit.token = _token;
        deposit.tokenIds = _tokenIds;
        deposit.depositType = DepositType.ERC721;
        deposits[++currentId] = deposit;

        uint256 length = _tokenIds.length;
        for (uint256 i = 0; i < length; ++i) {
            IERC721(_token).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenIds[i]
            );
        }

        emit NewDepositERC721(
            currentId,
            msg.sender,
            _seller,
            _token,
            _tokenIds
        );
    }

    function releaseDeposit(uint256 _id) external releaseGuard(_id) {
        Deposit storage deposit = deposits[_id];
        if (deposit.buyer != msg.sender) {
            revert OnlyBuyer();
        }

        deposit.released = true;

        if (deposit.depositType == DepositType.ETH) {
            _releaseDepositETH(deposit.seller, deposit.amount);
        } else if (deposit.depositType == DepositType.ERC20) {
            _releaseDepositERC20(deposit.seller, deposit.token, deposit.amount);
        } else if (deposit.depositType == DepositType.ERC721) {
            _releaseDepositERC721(
                deposit.seller,
                deposit.token,
                deposit.tokenIds
            );
        }

        emit DepositReleased(_id);
    }

    /// @notice Allows the owner to release a deposit
    /// @param _id The current deposit id
    /// @param _to The address to send the funds to
    function intervene(
        uint256 _id,
        address _to
    ) external releaseGuard(_id) onlyOwner {
        Deposit storage deposit = deposits[_id];
        deposit.released = true;

        if (deposit.depositType == DepositType.ETH) {
            _releaseDepositETH(_to, deposit.amount);
        } else if (deposit.depositType == DepositType.ERC20) {
            _releaseDepositERC20(_to, deposit.token, deposit.amount);
        } else if (deposit.depositType == DepositType.ERC721) {
            _releaseDepositERC721(_to, deposit.token, deposit.tokenIds);
        }

        emit Intervened(_id, _to);
    }

    /// @notice Allows the buyer to release the ETH deposit
    /// @param _seller The seller address
    /// @param _amount The amount of ETH
    function _releaseDepositETH(address _seller, uint256 _amount) internal {
        uint256 fee = _calculateFee(_amount);
        uint256 releaseAmount = _amount - fee;

        accruedFeesETH += fee;

        (bool success, ) = payable(_seller).call{value: releaseAmount}("");
        if (!success) {
            revert FailedToSendReleasedETH();
        }
    }

    /// @notice Allows the buyer to release the ERC20 deposit
    /// @param _seller The seller address
    /// @param _token The token address
    /// @param _amount The amount of tokens
    function _releaseDepositERC20(
        address _seller,
        address _token,
        uint256 _amount
    ) internal {
        uint256 fee = _amount / 200;
        uint256 releaseAmount = _amount - fee;

        accruedFeesERC20[_token] += fee;

        IERC20(_token).safeTransfer(_seller, releaseAmount);
    }

    /// @notice Allows the buyer to release the ERC721 deposit
    /// @param _seller The seller address
    /// @param _token The token address
    /// @param _tokenIds The token IDs
    function _releaseDepositERC721(
        address _seller,
        address _token,
        uint256[] memory _tokenIds
    ) internal {
        uint256 length = _tokenIds.length;
        for (uint256 i = 0; i < length; ++i) {
            IERC721(_token).safeTransferFrom(
                address(this),
                _seller,
                _tokenIds[i]
            );
        }
    }

    /// @notice Allows the owner to withdraw the accrued ETH fees
    /// @param _to The address to send the fees to
    function withdrawFeesETH(address _to) external onlyOwner {
        if (accruedFeesETH == 0) {
            revert NoFeesAccrued();
        }

        uint256 feesToTransfer = accruedFeesETH;
        accruedFeesETH = 0;

        (bool success, ) = payable(_to).call{value: feesToTransfer}("");
        if (!success) {
            revert FailedToSendWithdrawnETH();
        }
    }

    /// @notice Allows the owner to withdraw the accrued ERC20 fees
    /// @param _to The address to send the fees to
    /// @param _token The token address
    function withdrawFeesERC20(address _to, address _token) external onlyOwner {
        if (accruedFeesERC20[_token] == 0) {
            revert NoFeesAccrued();
        }

        uint256 feesToTransfer = accruedFeesERC20[_token];
        accruedFeesERC20[_token] = 0;

        IERC20(_token).safeTransfer(_to, feesToTransfer);
    }

    /// @notice Calculates the fee for a deposit
    /// @param _amount The amount to deposit
    /// @return Fees for the deposit
    function _calculateFee(uint256 _amount) internal pure returns (uint256) {
        return _amount / 200;
    }

    /// @notice Allows the contract to receive ERC721 tokens
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /*==============================================================
                            EVENTS
    ==============================================================*/

    /// @notice Emitted when a new deposit is created
    /// @param currentId The current deposit id
    /// @param buyer The buyer address
    /// @param seller The seller address
    /// @param amount The amount of the deposit
    event NewDepositETH(
        uint256 indexed currentId,
        address indexed buyer,
        address indexed seller,
        uint256 amount
    );

    /// @notice Emitted when a new deposit is created
    /// @param currentId The current deposit id
    /// @param buyer The buyer address
    /// @param seller The seller address
    /// @param token The token address
    /// @param amount The amount of the deposit
    event NewDepositERC20(
        uint256 indexed currentId,
        address indexed buyer,
        address indexed seller,
        address token,
        uint256 amount
    );

    /// @notice Emitted when a new deposit is created
    /// @param currentId The current deposit id
    /// @param buyer The buyer address
    /// @param seller The seller address
    /// @param token The token address
    /// @param tokenIds The token ids
    event NewDepositERC721(
        uint256 indexed currentId,
        address indexed buyer,
        address indexed seller,
        address token,
        uint256[] tokenIds
    );

    /// @notice Emitted when a deposit is released
    /// @param id Deposit id
    event DepositReleased(uint256 indexed id);

    /// @notice Emitted when the owner withdraws fees
    /// @param id The deposit id
    /// @param to The address to which the deposit is sent
    event Intervened(uint256 indexed id, address indexed to);

    /*==============================================================
                            ERRORS
    ==============================================================*/

    error OnlyOwner();

    error OnlyBuyer();

    error DepositDoesNotExist();

    error AlreadyReleased();

    error FailedToSendReleasedETH();

    error FailedToSendWithdrawnETH();

    error NoFeesAccrued();

    error NoTokenIds();

    error DepositAmountZero();

    error TokenAddressEmpty();

    error SellerAddressEmpty();

    error FailedToTransferERC20();

    error FailedToTransferERC721();

    error FailedToSendReleasedERC20();

    error FailedToSendReleasedERC721();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
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