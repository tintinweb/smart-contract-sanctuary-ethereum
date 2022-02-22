// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SBCC.sol";
import "./SBMP.sol";
import "./SK.sol";
import "./SOUL.sol";

contract MansionGame is Ownable, IERC721Receiver {

    SBCC private immutable sbcc;
    SBMP private immutable sbmp;
    SK private immutable sk;
    SOUL private immutable soul;
    
    struct SpookyStake {
        address owner;
        uint80 blockStakedTimestamp;
        uint16 mansionId;
    }

    struct MansionStake {
        address owner;
        uint256 owedAtTimeOfStake;
        uint80 blockStakedTimestamp;
    }

    struct Mansion {
        uint256 payoutPerDay;
        uint256 riskFactor; 
    }

    uint16[13000] rarity;


    mapping(uint256 => MansionStake) public mansionBoyStaked; 
    mapping(uint256 => SpookyStake) public spookyBoyStaked; 
    mapping(uint256 => Mansion) public mansions;
    mapping(address => uint256[]) public spookyOwnerIds;
    mapping(address => uint256[]) public mansionOwnerIds;

    uint256 public totalSpookyStaked = 0;
    uint256 public totalMansionStaked = 0;
    uint256 public owedPerMansionBoy = 0;


    constructor(address _soul) { 
        sbcc = SBCC(0xfd1076d80FfF9dC702ae9fDfEa0073467B9B3fb7);
        sbmp = SBMP(0xDa4128A4Fc209dF510E9e4483acd059D84620419);
        sk = SK(0x39AeFB036DabF9d29D33f357Dcc3dcE06dC2b899);
        soul = SOUL(_soul); 

        uint256 MAX_INT = 2**256 - 1;

        addMansion(1, 1, MAX_INT/5); // Bronze
        addMansion(69, 3, MAX_INT/5*2); // Silver
        addMansion(420, 5, MAX_INT/5*3); // Gold
        addMansion(1000, 15, 0); // Platinum
    }

    function addRarity(uint16[] calldata _values, uint16 _startingIndex) external onlyOwner {
        for( uint16 i = 0; i < _values.length; ++i ){
            rarity[_startingIndex+i] = _values[i];
        }
    }

    function getRarity(uint16 _id) external view returns(uint16){
        return rarity[_id];
    }

    function addMansion(uint256 _id, uint256 _payoutPerDay, uint256 _riskFactor) public onlyOwner {
        mansions[_id] = Mansion({
            riskFactor: _riskFactor, 
            payoutPerDay: _payoutPerDay * 1 ether
        });
    }

    function stakeSpookyBoy(uint16[] calldata _tokenIds, uint16 _mansionId) external {
        require(mansions[_mansionId].payoutPerDay != 0);
        if(_mansionId == 1000){
            require(_tokenIds.length > 5, "To stake in platinum mansion you must add atleast 6 at a time.");
        }
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(sbcc.ownerOf(_tokenIds[i]) == _msgSender(), "You cannot stake this! Nice try.");
            sbcc.transferFrom(_msgSender(), address(this), _tokenIds[i]);

            spookyBoyStaked[_tokenIds[i]] = SpookyStake({
                owner: _msgSender(),
                blockStakedTimestamp: uint80(block.timestamp),
                mansionId: _mansionId
            });
            spookyOwnerIds[_msgSender()].push(_tokenIds[i]);

            totalSpookyStaked += 1;
        }
    }

    function unstakeSpookyBoy(bool unstake) external returns(uint256){
        uint256 owedToYou = 0;
        uint256 stolen = 0;

        for (uint i = 0; i < spookyOwnerIds[_msgSender()].length; i++) {
            uint256 tokenId = spookyOwnerIds[_msgSender()][i];
            SpookyStake memory stake = spookyBoyStaked[tokenId];
            require(stake.owner == _msgSender(), "You don't own this. Nice try.");
            uint256 earnedBySpooky = (block.timestamp - stake.blockStakedTimestamp) * mansions[stake.mansionId].payoutPerDay / 1 days;

            // Platinum Mansion
            if(stake.mansionId == 1000){
                owedToYou += earnedBySpooky;
            }
            // Font Door
            else if(sk.balanceOf(stake.owner, stake.mansionId) > 0){
                owedToYou += earnedBySpooky; 
            }
            // Back Door
            else{
                // Stolen!
                if(_random(tokenId) <= mansions[stake.mansionId].riskFactor){
                    stolen += earnedBySpooky;
                }
                // Got out safely
                else{
                    owedToYou += earnedBySpooky * ((rarity[tokenId] / 13000) + 1);
                }
            }

            if(unstake){
                sbcc.safeTransferFrom(address(this), stake.owner, tokenId, "");
                delete spookyBoyStaked[tokenId];
                totalSpookyStaked -= 1;
            }else{
                spookyBoyStaked[tokenId] = SpookyStake({
                    owner: _msgSender(),
                    blockStakedTimestamp: uint80(block.timestamp),
                    mansionId: stake.mansionId
                });
            }

        }
        if(unstake){
            delete spookyOwnerIds[_msgSender()];
        }
        
        if(owedToYou != 0){
            soul.mint(_msgSender(), owedToYou);
        }

        if(stolen != 0 && totalMansionStaked != 0){
            owedPerMansionBoy += stolen / totalMansionStaked;
        }

        return owedToYou + stolen; // amount you will get if nothing is stolen
    }

    function stakeMansionBoy(uint16[] calldata _tokenIds) external {
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(sbmp.ownerOf(_tokenIds[i]) == _msgSender(), "You cannot stake this! Nice try.");
            sbmp.transferFrom(_msgSender(), address(this), _tokenIds[i]);

            mansionBoyStaked[_tokenIds[i]] = MansionStake({
                owner: _msgSender(),
                owedAtTimeOfStake: owedPerMansionBoy,
                blockStakedTimestamp: uint80(block.timestamp)
            });
            mansionOwnerIds[_msgSender()].push(_tokenIds[i]);

            totalMansionStaked += 1;
        }
    }

    function unstakeMansionBoy(bool unstake) external returns(uint256){
        uint256 owedToYou = 0;
        for (uint i = 0; i < mansionOwnerIds[_msgSender()].length; i++) {
            uint256 tokenId = mansionOwnerIds[_msgSender()][i];
            MansionStake memory stake = mansionBoyStaked[tokenId];
            require(stake.owner == _msgSender(), "You don't own this. Nice try.");
            
            owedToYou += owedPerMansionBoy - stake.owedAtTimeOfStake;

            if(unstake){
                sbmp.safeTransferFrom(address(this), stake.owner, tokenId, "");
                delete mansionBoyStaked[tokenId];
                totalMansionStaked -= 1;
            }else{
                mansionBoyStaked[tokenId] = MansionStake({
                    owner: _msgSender(),
                    owedAtTimeOfStake: owedPerMansionBoy,
                    blockStakedTimestamp: uint80(block.timestamp)
                });
            }
        }
        if(unstake){
            delete mansionOwnerIds[_msgSender()];
        }
        soul.mint(_msgSender(), owedToYou);

        return owedToYou;
    }
    

    function _random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.difficulty,
            block.timestamp,
            seed
        )));
    }

    
    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send tokens to Barn directly");
      return IERC721Receiver.onERC721Received.selector;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract SOUL is ERC20, Ownable {

  mapping(address => bool) controllers;
  
  constructor() ERC20("SOUL", "SOUL") { }

  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can mint");
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can burn");
    _burn(from, amount);
  }

  function selfBurn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// Created By: Lorenzo
abstract contract SK {

    function burnKey(address userAddress, uint256 keyId, uint256 amount)
        external
        virtual;

    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// Created By: Lorenzo
abstract contract SBMP {
    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function transferFrom(address _from, address _to, uint256 _tokenId) external virtual payable;

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external virtual payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// Created By: Lorenzo
abstract contract SBCC {
    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function transferFrom(address _from, address _to, uint256 _tokenId) external virtual payable;

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external virtual payable;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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