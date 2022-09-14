// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./IERC165.sol"; 
import "./Pausable.sol";
/*
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
*/
import "./IMintable.sol";

/**
 * @title Badium ERC20 Token 
 * @author John R. Kosinski
 * 
 * @dev Requirements: 
 * 
 * - An initial total supply of 10,000,000.
 * 
 * - A buying cost of 0.01 ETH per BAD.
 * 
 * - The contract owner can burn all tokens belonging to ALL holders, at any time.
 * 
 * - The contract owner can burn any tokens belonging to ANY individual holders, at any time. 
 * 
 * - The owner can mint an arbitrary amount of tokens at any time. 
 * 
 * - The owner can transfer tokens from one address to another whitelisted address. 
 * 
 * - The owner can specify and modify a whitelist of eligible receivers. Once bought by users,
 * tokens can be transferred only to those addresses. 
 * 
 * - Non-whitelisted addresses CAN purchase tokens from the store, but they can only transfer
 * them to whitelisted addreses. Therefore, it is possible for non-whitelisted addresses 
 * to hold tokens. 
 */
contract Badium is Context, IERC20, IERC20Metadata, Ownable, Pausable, IERC165, IMintable {
    uint256 private constant INITIAL_SUPPLY = 10**7;    //initial supply of 10 million
    string private constant NAME = "Badium";
    string private constant SYMBOL = "BAD"; 
    
    //balances and allowances
    uint256 private epoch;  
    mapping(uint256 => mapping(address => uint256)) private balances;
    mapping(uint256 => mapping(address => mapping(address => uint256))) private _allowances;
    uint256 private _totalSupply;
    uint256 public totalMinted;
    
    //this address also, in addition to the owner, has permission to call mint(*). 
    //this can be reserved for the contract which 'sells' the mints, to decouple 
    //commerce from normal ERC20 operation. 
    address public designatedMinter;    
    
    //whitelist; only these users may receive 
    mapping(address => bool) public whitelist; 
    uint256 public whitelistCount; 
    
    //ERRORS 
    error TransferToZero(); 
    error BurnFromZero(); 
    error MintToZero();
    error ApproveToZero();
    error AmountExceedsBalance(uint256 amount, uint256 balance); 
    error InsufficientAllowance();
    error AllowanceBelowZero(); 
    error NotWhitelisted(); 
    error NotAuthorizedToMint();
    
    /**
     * @dev Emits when burnAll is called, which is essentially a giant reset of all balances, 
     * supply, and allowances. 
     */
    event BurnAll(); 
    
    /**
     * @dev Emits when setDesignatedMinter is called with a new address. 
     * @param addr Address of the new designated minter. 
     */
    event DesignatedMinterSet(address addr); //TODO: add test coverage for this
    
    /**
     * @dev Emits when an address is added to the whitelist.
     * @param addr The address being added.
     */
    event AddToWhitelist(address indexed addr); 
    
    /**
     * @dev Emits when an address is removed from the whitelist.
     * @param addr The address being removed.
     */
    event RemoveFromWhitelist(address indexed addr); 
    
    /**
     * @dev 'Minter' can be either the owner, or the designated minter if one is set. 
     */
    modifier isMinter {
        if (_msgSender() != this.owner() && _msgSender() != designatedMinter)
            revert NotAuthorizedToMint();
        _;
    }
    
    /**
     * @dev Constructor. 
     */
    constructor() {
        //mint initial supply to owner 
        _mint(msg.sender, INITIAL_SUPPLY); 
    }
    
    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual override returns (string memory) {
        return NAME;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual override returns (string memory) {
        return SYMBOL;
    }

    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
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
    function decimals() external view virtual override returns (uint8) {
        return 18;
    }
    
    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) external view virtual override returns (uint256) {
        return balances[epoch][account];
    }
    
    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) external virtual override whenNotPaused returns (bool) {
        address tokenOwner = _msgSender();
        _transfer(tokenOwner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external virtual override whenNotPaused returns (bool) {
        address tokenOwner = _msgSender();
        _approve(tokenOwner, spender, amount);
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
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external virtual override whenNotPaused returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    
    /**
     * @dev Allows the contract owner to mint without limits to any address. 
     * See {IERC20-mint}.
     * 
     * Emits a {Transfer} event with `from` set to the zero address.
     * 
     * @param to Recipient of the newly minted quantity. 
     * @param amount The quantity of tokens to mint. 
     */
    function mint(address to, uint256 amount) override external whenNotPaused isMinter {
        _mint(to, amount);
    }
    
    /**
     * @dev Sets the address of an entity who has, in addition to the owner, authority
     * to mint. There can be at the most two minters: the contract owner, and the designated
     *  minter. Clear by calling setDesignatedMinter(0x00). 
     * 
     * @param minter The address, contract or non-contract, to set as authorized minter. 
     */
    function setDesignatedMinter(address minter) external onlyOwner whenNotPaused {
        if (minter != designatedMinter) {
            designatedMinter = minter;            
            emit DesignatedMinterSet(minter); 
            //TODO: test does & doesn't emit event when called 
        }
    }
    
    /**
     * @dev Allows the contract owner to burn tokens owned by the given account. 
     * 
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     * - `account` cannot be the zero address.
     * - `account` must have at least `quantity` tokens.
     * 
     * @param account The owner whose tokens to burn. 
     * @param quantity The number of tokens to burn. 
     */
    function burn(address account, uint256 quantity) external onlyOwner whenNotPaused {
        if (account == address(0))
            revert BurnFromZero();

        _beforeTokenTransfer(address(0), false);

        uint256 accountBalance = balances[epoch][account];
        if (accountBalance < quantity) 
            revert AmountExceedsBalance(quantity, accountBalance);
            
        unchecked {
            balances[epoch][account] = accountBalance - quantity;
        }
        _totalSupply -= quantity;

        emit Transfer(account, address(0), quantity);
    }
    
    /**
     * @dev Immediately burns all tokens held by all users, dropping the total supply to 0, 
     * and wiping out all balances and allowances.  
     * 
     * Emits {BurnAll} event. 
     */
    function burnAll() external onlyOwner whenNotPaused {
        _totalSupply = 0;
        epoch++;
        emit BurnAll(); 
    }
    
    
    /**
     * @dev Adds an address to the whitelist.
     * 
     * Emits { AddToWhitelist } if the address was not already whitelisted.
     * 
     * @param addr The address to add. 
     */
    function addWhitelist(address addr) external onlyOwner whenNotPaused {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            whitelistCount++;
            emit AddToWhitelist(addr);
        }
    }
    
    /**
     * @dev Removes the given address from the whitelist.
     * 
     * Emits { RemoveFromWhitelist } if the address was already whitelisted.
     * 
     * @param addr The address to un-whitelist.
     */
    function removeWhitelist(address addr) external onlyOwner whenNotPaused {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            whitelistCount--;
            emit RemoveFromWhitelist(addr);
        }
    }
    
    /**
     * @dev See { Pausable-pause }
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev See { Pausable-unpause }
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    //READ-ONLY METHODS 
    
    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address approver, address spender) public view virtual override returns (uint256) {
        //owner always has allowance to do anything
        if (spender == this.owner()) {
            return this.balanceOf(approver); 
        }
        
        return _allowances[epoch][approver][spender];
    }
    
    /**
     * @dev ERC-165 implementation. 
     * 
     * @param interfaceId An ERC-165 interface id to query. 
     * @return bool Whether or not the interface is supported by this contract. 
     */
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return 
            interfaceId == type(IERC165).interfaceId || 
            interfaceId == type(IERC20).interfaceId || 
            interfaceId == type(IERC20Metadata).interfaceId; 
    }
    
    /**
     * @dev Returns true if the given address is on the whitelist.
     * 
     * @param addr Address in question. 
     */
    function isWhitelisted(address addr) public view returns (bool) {
        return addr == owner() || whitelist[addr]; 
    }
    
    //NON-PUBLIC METHODS 
    
    
    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (to == address(0))
            revert TransferToZero();

        _beforeTokenTransfer(to, false);

        uint256 fromBalance = balances[epoch][from];
        if (fromBalance < amount) 
            revert AmountExceedsBalance(amount, fromBalance);
            
        unchecked {
            balances[epoch][from] = fromBalance - amount;
        }
        balances[epoch][to] += amount;

        emit Transfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        if (account == address(0))
            revert MintToZero();

        _beforeTokenTransfer(account, true);

        _totalSupply += amount;
        totalMinted += amount; 
        balances[epoch][account] += amount;
        emit Transfer(address(0), account, amount);
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
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address tokenOwner,
        address spender,
        uint256 amount
    ) internal virtual {
        if (spender == address(0))
            revert ApproveToZero();

        _allowances[epoch][tokenOwner][spender] = amount;
        emit Approval(tokenOwner, spender, amount);
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
        address tokenOwner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(tokenOwner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) 
                revert InsufficientAllowance();
            unchecked {
                _approve(tokenOwner, spender, currentAllowance - amount);
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
    
    /**
     * @dev Requires that the receiver be whitelisted. This restriction is not in 
     * place for minting, as anyone can receive minted tokens (e.g. from the store). 
     * They just can't transfer them to any non-whitelisted addresses afterwards. 
     * 
     * @param to The address which will receive the transfer. 
     * @param isMinting True only if the transfer is part of the { mint } call. 
     */
    function _beforeTokenTransfer(
        address to,
        bool isMinting
    ) internal virtual view {
        if (to != address(0) && !isMinting && !isWhitelisted(to))
            revert NotWhitelisted();
    }
}