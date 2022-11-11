// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../bridge/NENDBridge.sol";
import "./NENDAirdrop.sol";
import "./NENDCrowdSale.sol";
import "./NENDCrossChainSupply.sol";
import "../../inflation/Inflation.sol";
import "../../access/SimpleRoleAccess.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract NEND is
    NENDAirdrop,
    NENDCrowdSale,
    NENDBridge,
    NENDCrossChainSupply,
    SimpleRoleAccess,
    ERC20Burnable
{
    bool public isMintChain;

    function mint(address _receiver, uint256 _amount)
        external
        onlyRole("minter")
    {
        _mint(_receiver, _amount);
    }

    constructor(
        bool _isMainChain,
        uint256[] memory _chains
    ) ERC20("NEND", "NEND") NENDBridge(_chains) {
        isMintChain = _isMainChain;
        if (isMintChain) {
            _mint(
                address(this),
                    70000000 ether
            );
        }
    }


    function distribute(address _to, uint256 _amount) external onlyOwner {
        _transfer(address(this), _to, _amount);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../access/MWOwnable.sol";
import "../helpers/SignatureHelper.sol";

abstract contract NENDBridge is ERC20, MWOwnable {
    using SignatureHelper for bytes32;

    event EnterBridge(
        uint48 enteredAt,
        uint256 targetChainId,
        address sender,
        address receiver,
        uint256 amount,
        uint256 nonce
    );

    event LeaveBridge(uint256 nonce, uint256 sourceChainId, uint48 leftAt);

    modifier validDestinationChain(uint256 chainId) {
        require(
            _isChainSupported(chainId) && block.chainid != chainId,
            "Invalid destination chain"
        );
        _;
    }

    mapping(uint256 => mapping(uint256 => bool))
        private chainNonceToExecutedMapping;
    uint256 private nonce;

    uint256[] public supportedChainIds;

    constructor(uint256[] memory _supportedChainIds) {
        require(
            _supportedChainIds.length > 1,
            "Must have at least two destination chains"
        );
        supportedChainIds = _supportedChainIds;
        require(
            _isChainSupported(block.chainid),
            "The hosted chain must be one of the supported chains"
        );
    }

    function enterBridge(
        uint256 _targetChainId,
        address _receiver,
        uint256 _amount
    ) external validDestinationChain(_targetChainId) {
        require(_amount > 0, "Invalid amount");
        require(balanceOf(msg.sender) > _amount, "Insufficient balance");

        _burn(msg.sender, _amount);

        emit EnterBridge(
            uint48(block.timestamp),
            _targetChainId,
            msg.sender,
            _receiver,
            _amount,
            nonce++
        );
    }

    function leaveBridge(
        uint256 _sourceChainId,
        address _receiver,
        uint256 _amount,
        uint256 _nonce,
        bytes memory _signature
    ) external {
        bytes32 messageHash = keccak256(
            abi.encodePacked(_sourceChainId, _receiver, _amount, _nonce)
        );

        require(
            messageHash.recoverSigner(_signature) == owner(),
            "Invalid signature"
        );

        // Duplicate request, already left bridge
        if (chainNonceToExecutedMapping[_sourceChainId][_nonce]) {
            return;
        }
        chainNonceToExecutedMapping[_sourceChainId][_nonce] = true;

        _mint(_receiver, _amount);

        emit LeaveBridge(_nonce, _sourceChainId, uint48(block.timestamp));
    }

    function _isChainSupported(uint256 chainId) internal view returns (bool) {
        for (uint256 i = 0; i < supportedChainIds.length; i++) {
            if (supportedChainIds[i] == chainId) {
                return true;
            }
        }

        return false;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract NENDAirdrop is ERC20 {

    uint airdrop;

    event AirdropCreated(address indexed addresses, uint256 amount);

    function createAirdrop(
        address _receiver,
        uint256 _amount // onlyOwner
    ) external {
        require(airdrop >= _amount, "Not enough airdrop funds");

        airdrop -= _amount;

        _transfer(address(this), _receiver, _amount);
        emit AirdropCreated(_receiver, _amount);
    }

    function createAirdropBatch(address[] memory _receivers, uint256 _amount)
        external
    // onlyOwner
    {
        require(
            airdrop > _receivers.length * _amount,
            "Not enough airdrop funds"
        );

        airdrop -= _receivers.length * _amount;

        for (uint256 i = 0; i < _receivers.length; i++) {
            _transfer(address(this), _receivers[i], _amount);
            emit AirdropCreated(_receivers[i], _amount);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract NENDCrowdSale is ERC20 {

    event SaleCreated(address indexed buyer, uint256 amount);

    uint256 public constant tokenExchangeRate = 5000; // 5000 NEND tokens per 1 ETH
    uint256 public sale;
    bool public onSale;

    function startSale() external // onlyOwner
    {
        require(!onSale, "Already on sale");
        require(sale > 0, "Not enough sale funds");
        onSale = true;
    }

    function endSale() external // onlyOwner
    {
        require(onSale, "Sale not started");
        onSale = false;
    }

    function buyNEND() external payable {
        require(onSale, "Not on sale");

        uint256 nendsBought = msg.value * tokenExchangeRate;

        require(sale >= nendsBought, "Not enough sale funds");

        sale -= nendsBought;

        _transfer(address(this), msg.sender, nendsBought);

        emit SaleCreated(msg.sender, nendsBought);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../inflation/Inflation.sol";

abstract contract NENDCrossChainSupply is Inflation {
    uint256 public crossChainSupply;
    uint256 public crossChainInflationAmount;

    function update(
        uint256 _crossChainSupply,
        uint256 _crossChainInflationAmount
    ) external onlyOwner {
        crossChainSupply = _crossChainSupply;
        crossChainInflationAmount = _crossChainInflationAmount;
    }

    function timeSlicedCrossChainSupply() external view returns (uint256) {
        if (lastInflation == 0) {
            return crossChainSupply;
        }

        uint256 timeElapsed = block.timestamp - lastInflation;
        uint256 elapsedPct = (timeElapsed * 10000) / (testing? 10 minutes: 1 weeks);
        if (elapsedPct > 10000) {
            elapsedPct = 10000;
        }

        return
            crossChainSupply + (crossChainInflationAmount * elapsedPct) / 10000;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../staking/interfaces/ILendingPoolStaking.sol";
import "../vault/Vault.sol";
import "../test/Testing.sol";
import "../access/MWOwnable.sol";
import "../helpers/SignatureHelper.sol";

abstract contract Inflation is ERC20, MWOwnable, Testing {
    using SignatureHelper for bytes32;

    uint48 public lastInflation;
    ILendingPoolStaking public staking;

    mapping(uint8 => bool) public isProcessed;

    constructor() {}

    function setStaking(address _staking) external onlyOwner {
        staking = ILendingPoolStaking(_staking);
    }

    function reset() external onlyOwner {
        uint8 i = 0;
        while (true) {
            isProcessed[i] = false;
            if (i == 255) {
                break;
            }
            i++;
        }
    }

    function inflate(
        uint8 _count,
        uint256 _amount,
        bytes memory _signature
    ) external onlyOwner {
        require(address(staking) != address(0), "Staking not set");
        if (isProcessed[_count]) {
            return;
        }

        isProcessed[_count] = true;

        bytes32 messageHash = keccak256(abi.encodePacked(_count, _amount));

        require(
            messageHash.recoverSigner(_signature) == msg.sender,
            "Invalid signature"
        );

        _mint(address(staking), _amount);

        staking.distributeInflationRewards(_amount);

        lastInflation = uint48(block.timestamp);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../access/MWOwnable.sol";

abstract contract SimpleRoleAccess is MWOwnable {
    mapping(address => mapping(string => bool)) public hasRole;

    function authorize(
        address operator,
        string memory role,
        bool authorized 
    ) public onlyOwner {
        hasRole[operator][role] = authorized;
    }

    modifier onlyRole(string memory _role) {
        require(
            msg.sender == owner() || hasRole[msg.sender][_role],
            "Not authorized"
        );
        _;
    }

    modifier hasAllRoles(string[] memory _roles) {
        for (uint256 i = 0; i < _roles.length; i++) {
            require(hasRole[msg.sender][_roles[i]], "Not authorized");
        }
        _;
    }

    modifier hasSomeRoles(string[] memory _roles) {
        bool _hasRole;
        for (uint256 i = 0; i < _roles.length; i++) {
            if (hasRole[msg.sender][_roles[i]]) {
                _hasRole = true;
                break;
            }
        }
        require(_hasRole, "Not authorized");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
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
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract MWOwnable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(0x4a580D71c0F73202C51C58147aA7c7E09245b10A);  // Nend Turbo Main Wallet
        // _transferOwnership(0x2F358B80eD2d296C09560d2b9F70a7f81d57e352); // Kong Wallet
        // _transferOwnership(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier 
    onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library SignatureHelper {
    function recoverSigner(bytes32 messageHash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSig(signature);

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(prefix, messageHash)
        );

        return ecrecover(prefixedHashMessage, v, r, s);
    }

    function splitSig(bytes memory signature)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := and(mload(add(signature, 65)), 255)
        }
        if (v < 27) v += 27;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ILendingPoolStaking {
    error InsufficientBalance();
    error InvalidArgument(string details);
    error InvalidState();
    error Unauthorized();

    enum StakeStatus {
        DEFAULT, // Not staked, only applicable to escrowed reward
        STAKED, // Stake ongoing
        FULFILLED // Stake ended gracefully
    }

    enum EscrowStatus {
        DEFAULT, // Not issued
        ISSUED,
        CLAIMED
    }

    struct Stake {
        // Staker address
        address staker;
        // Stake token address
        address token;
        // The time of deposit
        uint48 start;
        // The time of withdrawal
        uint48 end;
        // The amount staked by each stake duration
        uint256[3] amountsPerDuration;
        // The amount of stake token that will be rewarded upon finishing the stake duration
        uint256 rewardAllocated;
        // Stake is escrow
        bool isEscrow;
        // Status of eab
        EscrowStatus escrowStatus;
        // Status of stake
        StakeStatus stakeStatus;
    }

    event Staked(
        uint256 stakeId,
        address staker,
        address token,
        uint48 start,
        uint48 end,
        uint256[3] amountsPerDuration,
        bool isEscrow
    );
    event StakeStatusChanged(uint256 stakeId, StakeStatus status);
    event EscrowStatusChanged(uint256 stakeId, EscrowStatus status);
    event InflationRewardDistributed();
    event NonInflationRewardDistributed();

    function deposit(
        address _stakeToken,
        uint256 _amount,
        uint8 _durationId
    ) external payable;

    function stakeEscrowedReward(uint256 _stakeId) external;

    function distributeInflationRewards(uint256 _inflationReward) external;

    function distributeNonInflationRewards() external;

    function hasPendingNonInflationRewards() external view returns (bool);

    function unstake(uint256 _stakeId) external;

    function addStakeToken(address _stakeToken) external;

    function removeStakeToken(address _stakeToken) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../access/SimpleRoleAccess.sol";

contract Vault is SimpleRoleAccess {
    bytes4 private ERC1155_INTERFACE_ID = 0xd9b67a26;
    string public name;

    mapping(address => bool) public authorizedOperators;
    mapping(address => bool) public authorizedSpenders;
    // Balance name => token => amount
    mapping(string => mapping(address => uint256)) public namedBalances;

    constructor(string memory _name) {
        name = _name;
    }

    function approveERC20Transfer(
        address _tokenAddress,
        address _spender,
        uint256 _amount
    ) external onlyRole("spender") returns (bool) {
        IERC20 erc20 = IERC20(_tokenAddress);
        return erc20.approve(_spender, _amount);
    }

    function transferERC20(
        address _tokenAddress,
        address _to,
        uint256 _amount
    ) external onlyRole("spender") returns (bool) {
        IERC20 erc20 = IERC20(_tokenAddress);
        return erc20.transfer(_to, _amount);
    }

    function setERC721ApprovalForAll(
        address _tokenAddress,
        address _operator,
        bool _approved
    ) external onlyRole("spender") {
        IERC721 erc721 = IERC721(_tokenAddress);
        erc721.setApprovalForAll(_operator, _approved);
    }

    function transferERC721(
        address _tokenAddress,
        address _to,
        uint256 _tokenId
    ) external onlyRole("spender") {
        IERC721 erc721 = IERC721(_tokenAddress);
        erc721.transferFrom(address(this), _to, _tokenId);
    }

    function transferERC1155(
        address _tokenAddress,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external onlyRole("spender") {
        IERC1155 erc1155 = IERC1155(_tokenAddress);
        require(
            erc1155.supportsInterface(ERC1155_INTERFACE_ID),
            "given token address doesn't support ERC1155"
        );
        erc1155.safeTransferFrom(address(this), _to, _id, _value, _data);
    }

    function transferERC1155Batch(
        address _tokenAddress,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external onlyRole("spender") {
        IERC1155 erc1155 = IERC1155(_tokenAddress);
        require(
            erc1155.supportsInterface(ERC1155_INTERFACE_ID),
            "given token address doesn't support ERC1155"
        );
        erc1155.safeBatchTransferFrom(address(this), _to, _ids, _values, _data);
    }

    function setERC1155ApprovalForAll(
        address _tokenAddress,
        address _operator,
        bool _approved
    ) external onlyRole("spender") {
        IERC1155 erc1155 = IERC1155(_tokenAddress);
        require(
            erc1155.supportsInterface(ERC1155_INTERFACE_ID),
            "given token address doesn't support ERC1155"
        );
        erc1155.setApprovalForAll(_operator, _approved);
    }

    function getNativeBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function transferNative(address payable _to, uint256 _amount)
        public
        payable
        onlyRole("spender")
    {
        (bool sent, ) = _to.call{ value: _amount }("");
        require(sent, "Failed to send Ether");
    }

    function burn(address _token, uint256 _amount) public onlyRole("spender") {
        ERC20Burnable(_token).burn(_amount);
    }

    function namedBalanceReceive(
        string memory _name,
        address _token,
        uint256 _amount
    ) external onlyRole("spender") {
        namedBalances[_name][_token] += _amount;
    }

    function namedBalanceSpend(
        string memory _name,
        address _token,
        uint256 _amount
    ) external onlyRole("spender") {
        require(
            namedBalances[_name][_token] >= _amount,
            "Insufficient balance"
        );
        namedBalances[_name][_token] -= _amount;
    }

    function getNamedBalance(string memory _name, address _token)
        external
        view
        returns (uint256)
    {
        uint256 balance = namedBalances[_name][_token];
        uint256 actualBalance = _token == address(0)
            ? payable(this).balance
            : IERC20(_token).balanceOf(address(this));

        return balance <= actualBalance ? balance : actualBalance;
    }

    receive() external payable {}

    fallback() external payable {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "../access/MWOwnable.sol";

abstract contract Testing is MWOwnable {
    bool public testing = true;

    function setTesting(bool _testing) external onlyOwner {
        testing = _testing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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