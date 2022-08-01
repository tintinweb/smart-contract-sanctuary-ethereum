/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
// pragma solidity ^0.7.6;

library AddressUtils {
    function isContract(address _addr)
        internal
        view
        returns (bool)
    {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}
/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    event InterfaceImplementerSet(
        address indexed account,
        bytes32 indexed interfaceHash,
        address indexed implementer
    );

    event ManagerChanged(address indexed account, address indexed newManager);

    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash)
        external
        view
        returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName)
        external
        pure
        returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId)
        external
        view
        returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using or updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(
        address account,
        bytes4 interfaceId
    ) external view returns (bool);
}
interface Token {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance the balance
    function balanceOf(address _owner)
        external
        view
        returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

interface ERC777Token {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address holder) external view returns (uint256);

    function granularity() external view returns (uint256);

    function defaultOperators() external view returns (address[] memory);

    function isOperatorFor(address operator, address holder)
        external
        view
        returns (bool);

    function authorizeOperator(address operator) external;

    function revokeOperator(address operator) external;

    function send(
        address to,
        uint256 amount,
        bytes calldata data
    ) external;

    function operatorSend(
        address from,
        address to,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    function burn(uint256 amount, bytes calldata data) external;

    function operatorBurn(
        address from,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
    event Minted(
        address indexed operator,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
    event Burned(
        address indexed operator,
        address indexed from,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
    event AuthorizedOperator(address indexed operator, address indexed holder);
    event RevokedOperator(address indexed operator, address indexed holder);
}
/**
 * @dev Interface of the ERC777TokensSender standard as defined in the EIP.
 *
 * {IERC777} Token holders can be notified of operations performed on their
 * tokens by having a contract implement this interface (contract holders can be
 * their own implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 *
 * OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Sender.sol)
 */
interface IERC777Sender {
    /**
     * @dev Called by an {IERC777} token contract whenever a registered holder's
     * (`from`) tokens are about to be moved or destroyed. The type of operation
     * is conveyed by `to` being the zero address or not.
     *
     * This call occurs _before_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the pre-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 * OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Recipient.sol)
 *
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}


error ABCToken__BurnFromNoOne();
error ABCToken__ERC777InterfaceNotImplemented();
error ABCToken__NotAuthorized();
error ABCToken__NotEnoughBalance();
error ABCToken__NotImplemented();
error ABCToken__RecipientRevert();
error ABCToken__SameHolderAndOperator();
error ABCToken__SendAmountNotDivisible();
error ABCToken__SendTokenToNoOne();
error ABCToken__NotEnoughAllowance();

/// TODO: add ERC20 compatiple
contract ABCToken is ERC777Token, Token {
    using AddressUtils for address;
    uint256 internal _totalTokenSupply;
    uint256 internal constant _GRANULARITY = 1;

    mapping(address => uint256) internal _addressBalance;

    // address internal immutable i_deployer;
    // address[] holders;
    mapping(address => mapping(address => bool))
        internal _holderOperators;

    mapping(address => mapping(address => uint256))
        internal _holderOperatorsAllowance;

    // TODO: CHANGE TO THE CORRECT ADDRESS BEFORE DEPLOY
    IERC1820Registry internal constant _ERC1820_REGISTRY =
        IERC1820Registry(
            0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24
        );

    constructor() {
        _addressBalance[msg.sender] = 101e18;
        _totalTokenSupply = 101e18;
    }

    /// Get the name of the token
    function name()
        external
        pure
        override(ERC777Token, Token)
        returns (string memory)
    {
        return "Alphabet";
    }

    /// Get the symbol of the token
    function symbol()
        external
        pure
        override(ERC777Token, Token)
        returns (string memory)
    {
        return "ABC";
    }

    /// Get the total number of minted tokens.
    function totalSupply()
        external
        view
        override(ERC777Token, Token)
        returns (uint256)
    {
        return _totalTokenSupply;
    }

    /// Get the balance of the account with address holder .
    /// The balance MUST be zero ( 0 ) or higher.
    function balanceOf(address holder)
        external
        view
        override(ERC777Token, Token)
        returns (uint256)
    {
        return _addressBalance[holder];
    }

    /// Get the smallest part of the token that’s not divisible.
    function granularity()
        external
        pure
        override
        returns (uint256)
    {
        return _GRANULARITY;
    }

    /// Get the list of default operators as defined by the token contract.
    function defaultOperators()
        external
        pure
        override
        returns (address[] memory)
    {
        address[] memory operators;
        // operators[0] = msg.sender;
        // operators[1] = i_deployer;
        return operators;
    }

    /// Indicate whether the operator address is an operator of the holder address.
    function isOperatorFor(address operator, address holder)
        public
        view
        override
        returns (bool)
    {
        if (holder == operator) {
            return true;
        }

        return _holderOperators[holder][operator];
    }

    /// Set a third party operator address as an operator of msg.sender to send and burn tokens on its behalf.
    function authorizeOperator(address operator)
        external
        override
    {
        if (msg.sender == operator)
            revert ABCToken__SameHolderAndOperator();

        _holderOperators[msg.sender][operator] = true;
        emit AuthorizedOperator(operator, msg.sender);
    }

    /// Remove the right of the operator address to be an operator for msg.sender and to send and burn tokens on its behalf.
    function revokeOperator(address operator)
        external
        override
    {
        if (msg.sender == operator)
            revert ABCToken__SameHolderAndOperator();

        _holderOperators[msg.sender][operator] = false;
        emit RevokedOperator(operator, msg.sender);
    }

    /// Send the 'amount' of tokens from the address 'msg.sender' to the address 'to' .
    function send(
        address to,
        uint256 amount,
        bytes calldata data
    ) external override {
        operatorSend(
            msg.sender,
            to,
            amount,
            data,
            bytes("")
        );
    }

    /// Send the 'amount' of tokens on behalf of the address 'from' to the address 'to'.
    function operatorSend(
        address from,
        address to,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public override {
        // Simple first error check
        _basicRevertCheck(from, amount);
        if (to == address(0))
            revert ABCToken__SendTokenToNoOne();

        // recipient ERC777
        address recipientImplementerAddress = _ERC1820_REGISTRY
                .getInterfaceImplementer(
                    to,
                    keccak256("ERC777TokensRecipient")
                );

        if (
            to.isContract() &&
            recipientImplementerAddress == address(0)
        ) revert ABCToken__ERC777InterfaceNotImplemented();

        // call holder ERC777 hook before changing state
        _callTokenToSendHook(
            msg.sender,
            from,
            to,
            amount,
            data,
            operatorData
        );

        // Changing State
        _addressBalance[from] -= amount;
        _addressBalance[to] += amount;
        if (!isOperatorFor(msg.sender, from)) {
            _holderOperatorsAllowance[from][
                msg.sender
            ] -= amount;
        }
        // call recipient ERC777 hook after changing state.
        // Revert if recipient revert.

        if (recipientImplementerAddress != address(0)) {
            try
                IERC777Recipient(
                    recipientImplementerAddress
                ).tokensReceived(
                        msg.sender,
                        from,
                        to,
                        amount,
                        data,
                        operatorData
                    )
            {} catch {
                _addressBalance[from] += amount;
                _addressBalance[to] -= amount;
                revert ABCToken__RecipientRevert();
            }
        }

        emit Sent(
            msg.sender,
            from,
            to,
            amount,
            data,
            operatorData
        );

        emit Transfer(from, to, amount);
    }

    function burn(uint256 amount, bytes calldata data)
        external
        override
    {
        operatorBurn(msg.sender, amount, data, bytes(""));
    }

    function operatorBurn(
        address from,
        uint256 amount,
        bytes calldata data,
        bytes memory operatorData
    ) public override {
        _basicRevertCheck(from, amount);
        if (from == address(0))
            revert ABCToken__BurnFromNoOne();

        _callTokenToSendHook(
            msg.sender,
            from,
            address(0),
            amount,
            data,
            operatorData
        );

        // State Change
        _addressBalance[from] -= amount;
        _totalTokenSupply -= amount;

        emit Burned(
            msg.sender,
            from,
            amount,
            data,
            operatorData
        );

        /// ERC20 Compatiple
        emit Transfer(from, address(0), amount);
    }

    function _basicRevertCheck(address from, uint256 amount)
        internal
        view
    {
        if (
            !isOperatorFor(msg.sender, from) &&
            allowance(from, msg.sender) < amount
        ) {
            revert ABCToken__NotAuthorized();
        }
        if (amount % _GRANULARITY != 0)
            revert ABCToken__SendAmountNotDivisible();
        if (amount > _addressBalance[from])
            revert ABCToken__NotEnoughBalance();
    }

    function _callTokenToSendHook(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) internal {
        address holderImplementerAddress = _ERC1820_REGISTRY
            .getInterfaceImplementer(
                from,
                keccak256("ERC777TokensSender")
            );
        if (holderImplementerAddress != address(0)) {
            IERC777Sender(holderImplementerAddress)
                .tokensToSend(
                    operator,
                    from,
                    to,
                    amount,
                    data,
                    operatorData
                );
        }
    }

    /// ERC20 Compatiple
    function decimals() external pure returns (uint8) {
        return 18;
    }

    function transfer(address to, uint256 amount)
        external
        override
        returns (bool success)
    {
        success = false;
        operatorSend(
            msg.sender,
            to,
            amount,
            bytes(""),
            bytes("")
        );
        success = true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool success) {
        success = false;
        operatorSend(
            from,
            to,
            amount,
            bytes(""),
            bytes("")
        );
        success = true;
    }

    function approve(address _spender, uint256 _value)
        external
        override
        returns (bool success)
    {
        success = false;

        _holderOperatorsAllowance[msg.sender][
            _spender
        ] = _value;

        emit Approval(msg.sender, _spender, _value);

        success = true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        remaining = _holderOperatorsAllowance[_owner][
            _spender
        ];
    }
}