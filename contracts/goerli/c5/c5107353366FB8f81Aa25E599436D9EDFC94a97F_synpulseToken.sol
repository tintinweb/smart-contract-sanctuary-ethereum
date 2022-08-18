// SPDX-License-Identifier: MIT
// This contract was designed and deployed by : Janis M. Heibel, Roy Hove and Adil Anees on behalf of Synpulse.
// This is the deployment contract of the Synpulse Global Token where mints and contract specific functions are defined. 

pragma solidity ^0.8.0;

import "synERC777.sol";

contract synpulseToken is synERC777 {
    constructor(uint256 initialSupply, address[] memory defaultOperators)
        synERC777("Synpulse Token", "SYN", defaultOperators) {
        require(defaultOperators[0] != defaultOperators[1], "The vaultContract cannot be the administrator");
        vaultContract = defaultOperators[0]; // companyName Vault, set in deploy function.
        administrator = defaultOperators[1]; // CFO, set in deploy function.

        _mint(vaultContract, initialSupply, "", "");
    }

    event Payout (
        uint256 date,
        address indexed from,
        uint256 amount,
        bytes data
    );

    // This function is called by the vaultContract in order to remove the old administrator and add a new one.
    function setAdministrator(address administrator_to_set
    ) public onlyVault returns (bool) {
        require(
            administrator_to_set != vaultContract,
            "The vaultContract cannot be the admin"
        );
        revokeOperator(administrator);
        authorizeOperator(administrator_to_set);
        administrator = administrator_to_set;
        return true;
    }

    // This function is called by the vaultContract in order to remove the old vaultContract and add a new one.
    function setVault(address vault_to_set
    ) public onlyVault returns (bool) {
        require(
            vault_to_set != administrator,
            "The vaultContract cannot be the admin"
        );
        revokeOperator(vaultContract);
        authorizeOperator(vault_to_set);
        vaultContract = vault_to_set;
        return true;
    }

    // This function is called by an operator in order to mint tokens to the vaultContract.
    function mintTokensToVault(uint256 amount
    ) public whenNotPaused {
        require(
            isOperatorFor(_msgSender(), _msgSender()),
            "Money printer for the Fed goes brrrr, but not for you. You are not an operator."
        );
        _mint(vaultContract, amount, "", "");
    }

    // This function is called by the vaultContract or administrator in order to airdrop tokens via batch transfer.
    // The amount must be the same for each recipient.
    // This uses the _send() function that does not require the whitelistEnabled flag to be true.
    function sendTokensToMultipleAddresses(
        address[] memory listOfAddresses_ToSend_To,
        uint256 amountToSend,
        bytes memory data
    ) public whenNotPaused {
        // Ensure that the total amount of tokens to send are present in the wallet sending.
        require(
            _msgSender() == administrator || _msgSender() == vaultContract, 
            "Sneaky, but not smart. Only the admin or vault can perform this action!"
        );
        require(
            balanceOf(vaultContract) >= listOfAddresses_ToSend_To.length * amountToSend,
            "Insufficient tokens"
        );
        for (uint256 z = 0; z < listOfAddresses_ToSend_To.length; z++) {
            _send(
                vaultContract,
                listOfAddresses_ToSend_To[z],
                amountToSend,
                data,
                "",
                true
            );
        }
    }

    // This function is called by the vaultContract or administrator in order to send tokens to an individual address.
    // This uses the _send() function that does not require the whitelistEnabled flag to be true.
    function sendTokensToIndividualAddress(
        address recipient,
        uint256 amount,
        bytes memory data
    ) public whenNotPaused {
        require(
            _msgSender() == administrator || _msgSender() == vaultContract, 
            "Sneaky, but not smart. Only the admin or vault can perform this action!"
        );
        _send(vaultContract, recipient, amount, data, "", true);
    }

    // This function is public and sends tokens directly to the vaultContract.
    // Emits payout event for linking automated requests to finance teams.
    function requestPayout(uint256 amount, bytes memory data
    ) public whenNotPaused {
        _send(_msgSender(), vaultContract, amount, data, "", true);
       if (amount != 0) {
            emit Payout(block.timestamp, _msgSender(), amount, data);
            }
    }

    // This function is called by defaultOperators in order to remove tokens from individuals.
    // It can only send tokens to the vaultContract.
    // Emits payout event for linking automated requests to finance teams.
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override whenNotPaused {
        require(
            isOperatorFor(_msgSender(), sender),
            "You are not the boss of me. You are not the boss of anyone. Only an operator can move funds."
        );
        require(
            recipient == vaultContract,
            "Watch yourself! An operator can only send tokens to the vaultContract."
        );
        _send(sender, recipient, amount, data, operatorData, true);
        if (amount != 0) {
            emit Payout(block.timestamp, sender, amount, data);
            }
    }

    // This functions is called by defaultOperators in order to burn tokens.
    // It can only burn tokens in the vaultContract.
    function operatorBurn(
        address account,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override whenNotPaused {
        require(
            isOperatorFor(_msgSender(), account),
            "M.C. Hammer: Duh da ra-duh duh-da duh-da, Cant Touch This. You are not an operator."
        );
        require(
            account == vaultContract,
            "Trying to be mean? An operator can only burn tokens in the vaultContract."
        );
        _burn(account, amount, data, operatorData);
    }

    // This function is called by defaultOperators in order to whitelist all listed addresses.
    // It works by changing the isWhitelistedAddress flag -> true.
    // It only changes the boolean flag for addresses in the listed input.
    function whitelistUsers(address[] memory arr
    ) public whenNotPaused {
        require(
            isOperatorFor(_msgSender(), _msgSender()),
            "Gotta ask the host before you add +1s. You are not an operator."
        );
        for (uint256 i = 0; i < arr.length; i++) {
            isWhitelistedAddress[arr[i]] = true;
        }
    }

    // This function is called by defaultOperators in order to un-whitelist all listed addresses.
    // It works by changing the isWhitelistedAddress flag -> false.
    // It only changes the boolean flag for addresses in the listed input.
    function removeFromWhitelist(address[] memory arr
    ) public whenNotPaused {
        require(
            isOperatorFor(_msgSender(), _msgSender()),
            "Do you not like them? Host your own party if you want to kick them out. You are not an operator."
        );
        for (uint256 i = 0; i < arr.length; i++) {
            isWhitelistedAddress[arr[i]] = false;
            if (balanceOf(arr[i]) > 0) {
                operatorSend(arr[i], vaultContract, balanceOf(arr[i]), "", "");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// This contract was adapted from the ERC777 standard contract and deployed by : Janis M. Heibel, Roy Hove and Adil Anees on behalf of Synpulse.
// This following piece of code complements synpulseTokenGlobal contract. 
// It specifies the roles as well as the on / off function of the overall token contract.

pragma solidity ^0.8.0;

import "IERC777.sol";
import "IERC20.sol";
import "Address.sol";
import "IERC1820Registry.sol";
import "synRoles.sol";

 // @dev Implementation of the {IERC777} interface.
 //
 // This implementation is agnostic to the way tokens are created. This means
 // that a supply mechanism has to be added in a derived contract using {_mint}.
 //
 // Support for ERC20 is included in this contract, as specified by the EIP: both
 // the ERC777 and ERC20 interfaces can be safely used when interacting with it.
 // Both {IERC777-Sent} and {IERC20-Transfer} events are emitted on token
 // movements.
 //
 // Additionally, the {IERC777-granularity} value is hard-coded to `1`, meaning that there
 // are no special restrictions in the amount of tokens that created, moved, or
 // destroyed. This makes integration with ERC20 applications seamless.
 
contract synERC777 is IERC777, IERC20, synRoles {
    using Address for address;

    IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    // This isn't ever read from - it's only used to respond to the defaultOperators query.
    address[] private _defaultOperatorsArray;

    // No longer immutable and accounts may not revoke them
    mapping(address => bool) private _defaultOperators;    

    // ERC20-allowances
    mapping(address => mapping(address => uint256)) private _allowances;

    // @dev `defaultOperators` may be an empty array.
     
    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators_
    ) {
        _name = name_;
        _symbol = symbol_;

        _defaultOperatorsArray = defaultOperators_;
        for (uint256 i = 0; i < defaultOperators_.length; i++) {
            _defaultOperators[defaultOperators_[i]] = true;
        }

        // register interfaces
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC777Token"), address(this));
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC20Token"), address(this));
    }

     // @dev See {IERC777-name}.
     
    function name() public view virtual override returns (string memory) {
        return _name;
    }

     // @dev See {IERC777-symbol}.
     
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    
     // @dev See {ERC20-decimals}.
     //
     // Always returns 18, as per the
     // [ERC777 EIP](https://eips.ethereum.org/EIPS/eip-777#backward-compatibility).
     
    function decimals() public pure virtual returns (uint8) {
        return 18;
    }

    
     // @dev See {IERC777-granularity}.
     //
     // This implementation always returns `1`.
     
    function granularity() public view virtual override returns (uint256) {
        return 1;
    }

    
     // @dev See {IERC777-totalSupply}.
     
    function totalSupply() public view virtual override(IERC20, IERC777) returns (uint256) {
        return _totalSupply;
    }

    
     // @dev Returns the amount of tokens owned by an account (`tokenHolder`).
    
    function balanceOf(address tokenHolder) public view virtual override(IERC20, IERC777) returns (uint256) {
        return _balances[tokenHolder];
    }

    
     // @dev See {IERC777-send}.
     //
     // Also emits a {IERC20-Transfer} event for ERC20 compatibility.
     // Has whitelist and pause restrictions.
     
    function send(
        address recipient,
        uint256 amount,
        bytes memory data
    ) public virtual override whenNotPaused {
        require(whitelistEnabled, "Nice try, but user transfers are not enabled.");
        require(isWhitelistedAddress[recipient], "Oops, the recipient is not a whitelisted address.");
       
        _send(_msgSender(), recipient, amount, data, "", true);      
 
    }

    
     // @dev See {IERC20-transfer}.
     //
     // Unlike `send`, `recipient` is _not_ required to implement the {IERC777Recipient}
     // interface if it is a contract.
     // Has whitelist and pause restrictions.
     // Also emits a {Sent} event.
     
    function transfer(address recipient, uint256 amount
    ) public virtual override whenNotPaused returns (bool) {
        require(whitelistEnabled, "Nice try, but user transfers are not enabled.");
        require(isWhitelistedAddress[recipient], "Oops, the recipient is not a whitelisted address.");
        require(recipient != address(0), "Are you really trying to burn this precious token? No way! You cannot transfer to the zero address.");

        address from = _msgSender();

        _move(from, from, recipient, amount, "", "");

        return true;
    }

    
     // @dev See {IERC777-burn}.
     //
     // Also emits a {IERC20-Transfer} event for ERC20 compatibility.
     // 
     // vault and paused restrictions.
     
    function burn(uint256 amount, bytes memory data) public virtual override onlyVault whenNotPaused {
        _burn(_msgSender(), amount, data, "");
    }

    
     // @dev See {IERC777-isOperatorFor}.
     // Only looks at the _defaultOperator array. 
     // Although unnecessary, tokenHolder input is required to maintain IERC777 compatability.
     
    function isOperatorFor(address operator, address tokenHolder) public view virtual override returns (bool) {
        return _defaultOperators[operator];
    }

    
     // @dev See {IERC777-authorizeOperator}.
     // Only looks at the _defaultOperator array. 
     // vault and administrator restrictions.
    
    function authorizeOperator(address operator) public virtual override {
        require(
            _msgSender() == administrator || _msgSender() == vaultContract, 
            "With great power comes great responsibility. You have neither. Only the admin or vault can do this!"
        );
        _defaultOperators[operator] = true;
        if (!isInArray(operator, _defaultOperatorsArray)) {
            _defaultOperatorsArray.push(operator);
        }

        emit AuthorizedOperator(operator, _msgSender());
    }

    
     // @dev See {IERC777-revokeOperator}.
     // Only looks at the _defaultOperator array. 
     // vault and administrator restrictions. 
     
    function revokeOperator(address operator) public virtual override {
        require(
            _msgSender() == administrator || _msgSender() == vaultContract, 
            "Tut, tut. You cannot take powers you do not even have yourself. Only the admin or vault can do this!"
        );
        _defaultOperators[operator] = false;
        removeAddress(operator, _defaultOperatorsArray);

        emit RevokedOperator(operator, _msgSender());
    }

    
     // @dev See {IERC777-defaultOperators}.
     
    function defaultOperators() public view virtual override returns (address[] memory) {
        return _defaultOperatorsArray;
    }

    
     // @dev See {IERC777-operatorSend}.
     //
     // Emits {Sent} and {IERC20-Transfer} events.
    
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override {
        require(isOperatorFor(_msgSender(), sender), "ERC777: caller is not an operator for holder");
        _send(sender, recipient, amount, data, operatorData, true);
    }

   
     // @dev See {IERC777-operatorBurn}.
     //
     // Emits {Burned} and {IERC20-Transfer} events.
     
    function operatorBurn(
        address account,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override {
        require(isOperatorFor(_msgSender(), account), "ERC777: caller is not an operator for holder");
        _burn(account, amount, data, operatorData);
    }

    
     // @dev See {IERC20-allowance}.
     //
     // Note that operator and allowance concepts are orthogonal: operators may
     // not have allowance, and accounts with allowance may not be operators
     // themselves.
     
    function allowance(address holder, address spender) public view virtual override returns (uint256) {
        return _allowances[holder][spender];
    }

    
     // @dev See {IERC20-approve}.
     //
     // Note that accounts cannot have allowance issued by their operators.
     
    function approve(address spender, uint256 value) public virtual override returns (bool) {
        address holder = _msgSender();
        _approve(holder, spender, value);
        return true;
    }

    
     // @dev See {IERC20-transferFrom}.
     //
     // Note that operator and allowance concepts are orthogonal: operators cannot
     // call `transferFrom` (unless they have allowance), and accounts with
     // allowance cannot call `operatorSend` (unless they are operators).
     //
     // Has whitelist and pause restrictions.
     // Emits {Sent}, {IERC20-Transfer} and {IERC20-Approval} events.
     
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) public virtual override whenNotPaused returns (bool) {
        require(whitelistEnabled, "Nice try, but user transfers are not enabled.");
        require(isWhitelistedAddress[recipient], "Oops, the recipient is not a whitelisted address.");
        require(recipient != address(0), "Are you really trying to burn this precious token? No way! You cannot transfer to the zero address.");
        require(holder != address(0), "Let the dead rest in peace, this also counts for tokens.");

        address spender = _msgSender();

        _move(spender, holder, recipient, amount, "", "");

        uint256 currentAllowance = _allowances[holder][spender];
        require(currentAllowance >= amount, "ERC777: transfer amount exceeds allowance.");
        _approve(holder, spender, currentAllowance - amount);

        return true;       
    }

    
     // @dev Creates `amount` tokens and assigns them to `account`, increasing
     // the total supply.
     //
     // If a send hook is registered for `account`, the corresponding function
     // will be called with `operator`, `data` and `operatorData`.
     //
     // See {IERC777Sender} and {IERC777Recipient}.
     //
     // Emits {Minted} and {IERC20-Transfer} events.
     //
     // Requirements
     //
     // - `account` cannot be the zero address.
     // - if `account` is a contract, it must implement the {IERC777Recipient}
     // interface.
    
    function _mint(
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal virtual {
        _mint(account, amount, userData, operatorData, true);
    }

    
     // @dev Creates `amount` tokens and assigns them to `account`, increasing
     // the total supply.
     //
     // If `requireReceptionAck` is set to true, and if a send hook is
     // registered for `account`, the corresponding function will be called with
     // `operator`, `data` and `operatorData`.
     //
     // See {IERC777Sender} and {IERC777Recipient}.
     //
     // Emits {Minted} and {IERC20-Transfer} events.
     //
     // Requirements
     //
     // - `account` cannot be the zero address.
     // - if `account` is a contract, it must implement the {IERC777Recipient}
     // interface.
     
    function _mint(
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal virtual {
        require(account != address(0), "ERC777: mint to the zero address.");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, amount);

        // Update state variables
        _totalSupply += amount;
        _balances[account] += amount;

        emit Minted(operator, account, amount, userData, operatorData);
        emit Transfer(address(0), account, amount);
    }

    
     // @dev Send tokens
     // @param from address token holder address
     // @param to address recipient address
     // @param amount uint256 amount of tokens to transfer
     // @param userData bytes extra information provided by the token holder (if any)
     // @param operatorData bytes extra information provided by the operator (if any)
     // @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
     
    function _send(
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal virtual {
        require(from != address(0), "ERC777: send from the zero address.");
        require(to != address(0), "ERC777: send to the zero address.");

        address operator = _msgSender();

        _move(operator, from, to, amount, userData, operatorData);

    }

   
     // @dev Burn tokens
     // @param from address token holder address
     // @param amount uint256 amount of tokens to burn
     // @param data bytes extra information provided by the token holder
     // @param operatorData bytes extra information provided by the operator (if any)
    
    function _burn(
        address from,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) internal virtual {
        require(from != address(0), "ERC777: burn from the zero address.");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), amount);

        // Update state variables
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC777: burn amount exceeds balance.");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _totalSupply -= amount;

        emit Burned(operator, from, amount, data, operatorData);
        emit Transfer(from, address(0), amount);
    }

    function _move(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) private {
        _beforeTokenTransfer(operator, from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC777: transfer amount exceeds balance.");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Sent(operator, from, to, amount, userData, operatorData);
        emit Transfer(from, to, amount);
    }

    
     // @dev See {ERC20-_approve}.
     //
     // Note that accounts cannot have allowance issued by their operators.
     
    function _approve(
        address holder,
        address spender,
        uint256 value
    ) internal {
        require(holder != address(0), "ERC777: approve from the zero address.");
        require(spender != address(0), "ERC777: approve to the zero address.");

        _allowances[holder][spender] = value;
        emit Approval(holder, spender, value);
    }

    
     // @dev Hook that is called before any token transfer. This includes
     // calls to {send}, {transfer}, {operatorSend}, minting and burning.
     //
     // Calling conditions:
     //
     // - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     // will be to transferred to `to`.
     // - when `from` is zero, `amount` tokens will be minted for `to`.
     // - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     // - `from` and `to` are never both zero.
     //
     // To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC777/IERC777.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Emitted when `amount` tokens are created by `operator` and assigned to `to`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` destroys `amount` tokens from `account`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` is made operator for `tokenHolder`
     */
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Emitted when `operator` is revoked its operator status for `tokenHolder`
     */
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

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
    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

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
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

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
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// This contract was designed and deployed by : Janis M. Heibel, Roy Hove and Adil Anees on behalf of Synpulse.
// This following piece of code complements synpulseTokenGlobal contract. 
// It specifies the roles as well as the on / off function of the overall token contract.

pragma solidity ^0.8.0;

import "Pausable.sol";

contract synRoles is Pausable {
    address public vaultContract;
    address public administrator;
    bool public whitelistEnabled = false;
    mapping(address => bool) public isWhitelistedAddress;

    // This function checks if an address is in an array of addresses and returns "true" if yes, else "false".
    function isInArray(
        address address_to_check, 
        address[] memory target_Array 
    ) internal pure returns (bool)
    {
        for (uint256 x = 0; x < target_Array.length; x++) {
            if (target_Array[x] == address_to_check) {
                return true;
            }
        }
        return false;
    }

    // This function removes an address from an array of addresses.
    function removeAddress(
        address address_to_remove,
        address[] storage target_Array
    ) internal {
        for (uint256 x = 0; x < target_Array.length; x++) {
            if (target_Array[x] == address_to_remove) {
                target_Array[x] = target_Array[target_Array.length - 1];
                target_Array.pop();
                break;
            }
        }
    }

    // The administrator can pause and unpause the contract, enable and disable the whitelisting control settings as well as add and remove defaultOperators.
    // In addition, the administrator is a defaultOperator itself on deployment.
    modifier onlyAdministrator() {
        require(
            _msgSender() == administrator,
            "You are missing a promotion to the board of directors. Only the admin can perform this action!"
        );
        _;
    }

    // The vaultContract can update the administrator address as well as update the address of the vaultContract.
    // In addition, the vaultContract is a defaultOperator itself on deployment.
    modifier onlyVault() {
        require(
            _msgSender() == vaultContract,
            "Getting power hungry? Only the vault contract can perform this action!"
        );
        _;
    }
    
    // This function is called by the administrator to enable transfers between whitelisted addresses.
    function activateWhitelist() public onlyAdministrator
    {
        whitelistEnabled = true;
    }

    // This function is called by the administrator to disable transfers between whitelisted addresses.
    function deactivateWhitelist() public onlyAdministrator {
        whitelistEnabled = false;
    }

    // This function is called by the administrator to pause the contract and preserve the current state of the holdings.
    // It is to be called in case the vested Token contract needs to be updated.
    function pauseContract () public whenNotPaused onlyAdministrator {
        _pause();
    }

    // This function is called by the administrator to unpause the contract.
    function unpauseContract() public whenPaused onlyAdministrator {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}