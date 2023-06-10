/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

pragma solidity 0.8.17;
// 3

interface IWhitelist {
    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);
    event RegistrarUpdated(
        address indexed previousRegistrar,
        address indexed newRegistrar
    );

    function updateRegistrar(address newRegistrar) external returns (bool);

    function addAddressToWhitelist(address holder) external returns (bool);

    function removeAddressFromWhitelist(address holder) external returns (bool);
}

// import 2

abstract contract Whitelist is IWhitelist {
    mapping(address => bool) public whitelist;
    address public registrar;

    constructor(address registrarAddress) {
        registrar = registrarAddress;
    }

    /**
     * @dev Throws if called by any account that's not whitelisted.
     */
    modifier onlyWhitelisted(address _addr) {
        require(whitelist[_addr], "Whitelist: address must be whitelisted");
        _;
    }
    /**
     * @dev Throws if called by any account other than the registrar.
     */
    modifier onlyRegistrar() {
        require(
            msg.sender == registrar,
            "Whitelist: Only registrar could perform that action"
        );
        _;
    }

    /**
     * @dev Allows the current registrar to transfer control of the contract to a newRegistrar.
     * @param _newRegistrar The address to transfer registrarship to.
     */
    function updateRegistrar(address _newRegistrar)
        external
        onlyRegistrar
        returns (bool)
    {
        require(
            _newRegistrar != address(0),
            "Whitelist: new registrar is the zero address"
        );
        return _transferRegistrarship(_newRegistrar);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newRegistrar`).
     * Internal function without access restriction.
     */
    function _transferRegistrarship(address _newRegistrar)
        internal
        virtual
        returns (bool)
    {
        address oldRegistrar = registrar;
        registrar = _newRegistrar;
        emit RegistrarUpdated(oldRegistrar, _newRegistrar);
        return true;
    }

    /**
     * @dev add an address to the whitelist
     * @param _addr address
     * @return true if the address was added to the whitelist, false if the address was already in the whitelist
     */
    function addAddressToWhitelist(address _addr)
        external
        onlyRegistrar
        returns (bool)
    {
        require(!whitelist[_addr], "Whitelist: Address already whitelisted");
        whitelist[_addr] = true;
        emit WhitelistedAddressAdded(_addr);
        return true;
    }

    /**
     * @dev remove an address from the whitelist
     * @param _addr address
     * @return true if the address was removed from the whitelist,
     * false if the address wasn't in the whitelist in the first place
     */
    function removeAddressFromWhitelist(address _addr)
        external
        onlyRegistrar
        returns (bool)
    {
        require(whitelist[_addr], "Whitelist: Address not whitelisted");
        whitelist[_addr] = false;
        emit WhitelistedAddressRemoved(_addr);
        return true;
    }
}


// 4

interface ISmartCoin {
    enum TransferStatus {
        Undefined,
        Created,
        Validated,
        Rejected
    }
    enum ApproveStatus {
        Undefined,
        Created,
        Validated,
        Rejected
    }
    struct TransferRequest {
        address from;
        address to;
        uint256 value;
        TransferStatus status;
        bool isTransferFrom;
        address spender;
    }
    struct ApproveRequest {
        address from;
        address to;
        uint256 value;
        ApproveStatus status;
    }

    event TransferRequested(
        bytes32 transferHash,
        address indexed from,
        address indexed to,
        address indexed spender,
        uint256 value
    );
    event TransferRejected(bytes32 transferHash);
    event TransferValidated(bytes32 transferHash);

    event ApproveRequested(
        bytes32 approveHash,
        address indexed from,
        address indexed to,
        uint256 value
    );
    event ApproveRejected(bytes32 approveHash);
    event ApproveValidated(bytes32 approveHash);

    function burn(uint256 amount) external returns (bool);

    function mint(address to, uint256 amount) external returns (bool);

    function recall(address from, uint256 amount) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function validateTransfer(bytes32 transferHash) external returns (bool);

    function rejectTransfer(bytes32 transferHash) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function engagedAmount(address addr) external view returns (uint256);

    function validateApprove(bytes32 approveHash) external returns (bool);

    function rejectApprove(bytes32 approveHash) external returns (bool);

    /* start performed by openzepplin ERC20 
     * function allowance(address owner, address spender)                            
     *        external                                                               
     *        view                                                                   
     *        returns (uint256);                                                     
     * function balanceOf(address) external view returns (uint256);                  
     * function totalSupply(address) external view returns (uint256);                
     * event Transfer(address indexed from, address indexed to, uint256 value);      
     * event Approval(                                                               
     *   address indexed owner,                                                      
     *   address indexed spender,                                                    
     *   uint256 value                                                               
     * );                                                                            
    end performed by openzepplin ERC20 */
}

// 5

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

// 7

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// 6

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// 8 

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// 9

library EncodingUtils {
    function encodeRequest(
        address _from,
        address _to,
        uint256 _value,
        uint256 counter
    ) internal view returns (bytes32) {
        return
            keccak256(abi.encode(block.timestamp, _from, _to, _value, counter));
    }
}

contract SmartCoin is Whitelist, ERC20, ISmartCoin {
    mapping(bytes32 => TransferRequest) private _transfers;
    uint256 private _requestCounter;

    mapping(address => mapping(address => bool)) private _hasOngoingApprove;
    mapping(bytes32 => ApproveRequest) private _approves;

    mapping(address => uint256) private _engagedAmount; // _engagedAmount amount in transfer or approve

    constructor(address registrar)
        ERC20("EUR Coinvertible", "EURCV")
        Whitelist(registrar)
    {}

    function validateTransfer(bytes32 transferHash)
        external
        onlyRegistrar
        returns (bool)
    {
        TransferRequest memory _transferRequest = _transfers[transferHash];
        if (_transferRequest.isTransferFrom) {
            if(!whitelist[_transferRequest.spender]){
                revert("Whitelist: address must be whitelisted");
            }
        }
        require(
            _transferRequest.status != TransferStatus.Undefined,
            "SmartCoin: transferHash does not exist"
        );
        require(
            _transferRequest.status == TransferStatus.Created,
            "SmartCoin: Invalid transfer status"
        );
        _transfers[transferHash].status = TransferStatus.Validated;
        unchecked {
            _engagedAmount[_transferRequest.from] -= _transferRequest.value;
        }
        _safeTransfer(
            _transferRequest.from,
            _transferRequest.to,
            _transferRequest.value
        );
        emit TransferValidated(transferHash);
        return true;
    }

    function _safeApprove(
        address _from,
        address _to,
        uint256 _value
    ) internal onlyWhitelisted(_from) onlyWhitelisted(_to) {
        super._approve(_from, _to, _value);
    }

    function _safeTransfer(
        address _from,
        address _to,
        uint256 _value
    ) internal onlyWhitelisted(_from) onlyWhitelisted(_to) {
        super._transfer(_from, _to, _value);
    }

    function rejectTransfer(bytes32 transferHash)
        external
        onlyRegistrar
        returns (bool)
    {
        TransferRequest memory transferRequest = _transfers[transferHash];
        if (transferRequest.isTransferFrom) {

            uint256 allowance = allowance(
                transferRequest.from,
                transferRequest.to
            );
            if (allowance != type(uint256).max) {
                _approve(
                    transferRequest.from,
                    transferRequest.to,
                    allowance + transferRequest.value
                );
            }
        }
        _engagedAmount[transferRequest.from] -= transferRequest.value;
        _transfers[transferHash].status = TransferStatus.Rejected;
        emit TransferRejected(transferHash);
        return true;
    }

    function approve(address _to, uint256 _value)
        public
        override(ERC20, ISmartCoin)
        onlyWhitelisted(_msgSender())
        onlyWhitelisted(_to)
        returns (bool)
    {
        
        require(
            _to != address(0),
            "SmartCoin:  approve spender is the zero address"
        );
        require(
            !_hasOngoingApprove[_msgSender()][_to],
            "SmartCoin: owner has ongoing approve request"
        );
        uint256 currentAllowedAmount = super.allowance(_msgSender(), _to);
        if (currentAllowedAmount > 0) super._approve(_msgSender(), _to, 0);
        bytes32 approveHash = EncodingUtils.encodeRequest(
            _msgSender(),
            _to,
            _value,
            _requestCounter
        );
        _approves[approveHash] = ApproveRequest(
            _msgSender(),
            _to,
            _value,
            ApproveStatus.Created
        );
        _hasOngoingApprove[_msgSender()][_to] = true;
        _requestCounter += 1;
        emit ApproveRequested(approveHash, _msgSender(), _to, _value);
        return true;
    }

    function validateApprove(bytes32 approveHash)
        external
        onlyRegistrar
        returns (bool)
    {
        ApproveRequest memory _approveRequest = _approves[approveHash];
        require(
            _approveRequest.status != ApproveStatus.Undefined,
            "SmartCoin: approveHash does not exist"
        );
        require(
            _approveRequest.status == ApproveStatus.Created,
            "SmartCoin: Invalid approve status"
        );
        _safeApprove(
            _approveRequest.from,
            _approveRequest.to,
            _approveRequest.value
        );
        _hasOngoingApprove[_approveRequest.from][_approveRequest.to] = false;
        _approves[approveHash].status = ApproveStatus.Validated;
        emit ApproveValidated(approveHash);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        override(ERC20, ISmartCoin)
        onlyWhitelisted(_msgSender())
        onlyWhitelisted(_from)
        onlyWhitelisted(_to)
        returns (bool)
    {
        unchecked {
            super._spendAllowance(_from, _msgSender(), _value); // we know that allowance is bigger then _value
        }
        _initiateTransfer(
            _from,
            _to,
            _value,
            true, // isTransferFrom
            _msgSender()
        );
        return true;
    }

    function rejectApprove(bytes32 _approveHash)
        external
        onlyRegistrar
        returns (bool)
    {
        ApproveRequest memory approveRequest = _approves[_approveHash];
        require(
            approveRequest.status != ApproveStatus.Undefined,
            "SmartCoin: approveHash does not exist"
        );
        require(
            approveRequest.status == ApproveStatus.Created,
            "SmartCoin: Invalid approve status"
        );
        _hasOngoingApprove[approveRequest.from][approveRequest.to] = false;
        _approves[_approveHash].status = ApproveStatus.Rejected;
        emit ApproveRejected(_approveHash);
        return true;
    }

    function transfer(address _to, uint256 _value)
        public
        override(ISmartCoin, ERC20)
        onlyWhitelisted(_msgSender())
        onlyWhitelisted(_to)
        returns (bool)
    {
        _initiateTransfer(_msgSender(), _to, _value, false, address(0));
        return true;
    }

    function _initiateTransfer(
        address _from,
        address _to,
        uint256 _value,
        bool _isTransferFrom,
        address _spender
    ) internal {
        require(
            _from != address(0),
            "SmartCoin: transfer from the zero address"
        );
        require(_to != address(0), "SmartCoin: transfer to the zero address");
        require(
            _availableBalance(_from) >= _value,
            "SmartCoin: Insufficient balance"
        );
        unchecked {
            _engagedAmount[_from] += _value; // Overflow not possible, engagedAmount amount <= balance
        }
        bytes32 transferHash = EncodingUtils.encodeRequest(
            _from,
            _to,
            _value,
            _requestCounter
        );
        _transfers[transferHash] = TransferRequest(
            _from,
            _to,
            _value,
            TransferStatus.Created,
            _isTransferFrom,
            _spender
        );
        _requestCounter += 1;
        emit TransferRequested(transferHash, _from, _to, _spender, _value);
    }

    function recall(address _from, uint256 _amount)
        external
        override
        onlyRegistrar
        returns (bool)
    {
        require(
            _availableBalance(_from) >= _amount, // _amount should not exceed balance minus engagedAmount amount
            "SmartCoin: transfer amount exceeds balance"
        );
        super._transfer(_from, registrar, _amount);
        return true;
    }

    function burn(uint256 _amount)
        external
        override
        onlyRegistrar
        returns (bool)
    {
        require(
            _availableBalance(registrar) >= _amount, // _amount should not exceed balance minus engagedAmount amount
            "SmartCoin: burn amount exceeds balance"
        );
        super._burn(registrar, _amount);
        return true;
    }

    function mint(address _to, uint256 _amount)
        external
        override
        onlyRegistrar
        onlyWhitelisted(_to)
        returns (bool)
    {
        super._mint(_to, _amount);
        return true;
    }

    function balanceOf(address _addr)
        public
        view
        override(ERC20, ISmartCoin)
        returns (uint256)
    {
        return _availableBalance(_addr); // Overflow not possible: balance >= engagedAmount amount.
    }

    function _availableBalance(address _addr) internal view returns (uint256) {
        unchecked {
            return super.balanceOf(_addr) - _engagedAmount[_addr];
        }
    }

    function engagedAmount(address _addr) public view returns (uint256) {
        return _engagedAmount[_addr];
    }
}