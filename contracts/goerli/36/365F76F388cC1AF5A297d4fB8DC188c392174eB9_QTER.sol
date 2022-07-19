// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../onChainArcade_Snake.sol";

contract QTER is ERC20, Ownable, ReentrancyGuard {
    OCASnake oca;

    struct SnakeTokenInfo {
        uint256 stakeDate;
        uint256 lastClaim;
        uint256 layout;
    }

    // a mapping from an address to whether or not it can mint / burn
    mapping(address => bool) controllers;

    constructor(address _ocaAddress) ERC20("QTER", "QTER") {
        controllers[msg.sender] = true;
        oca = OCASnake(_ocaAddress);
    }

    modifier callerIsSender() {
        if (tx.origin != msg.sender) revert();
        _;
    }

    /**
     * mints $QTER to a recipient
     * @param to the recipient of the $QTER
     * @param amount the amount of $QTER to mint
     */
    function mint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can mint");
        _mint(to, amount);
    }

    /**
     * burns $QTER from a holder
     * @param from the holder of the $QTER
     * @param amount the amount of $QTER to burn
     */
    function burn(address from, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can burn");
        _burn(from, amount);
    }

    /**
     * enables an address to mint / burn
     * @param controller the address to enable
     */
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    /**
     * disables an address from minting / burning
     * @param controller the address to disbale
     */
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    function setOCASnake(address _address) public onlyOwner {
        oca = OCASnake(_address);
    }

    // function getStakedTimed(uint256 tokenId) public view returns (uint256) {
    //     return oca.getStakedTime(tokenId);
    // }

    function abs(int256 x) private pure returns (int256) {
        return x >= 0 ? x : -x;
    }

    function getSnakeStakeTime(uint256 tokenId)
        public
        view
        returns (SnakeTokenInfo memory)
    {
        SnakeTokenInfo memory info = SnakeTokenInfo(
            oca.getStakedTime(tokenId)[0],
            oca.getStakedTime(tokenId)[1],
            oca.getStakedTime(tokenId)[2]
        );
        return info;
    }

    function snakeTokenOwner(uint256 tokenId) public view returns (address) {
        return oca.ownerOf(tokenId);
    }

    function snakeTokenOwnerOf(uint256 tokenId) private view {
        bool isOwner = oca.ownerOf(tokenId) == msg.sender;
        require(isOwner, "You do not own this token");
    }

    function changeSnakeLayout(
        uint256 tokenId,
        uint256 layout,
        uint256 _type
    ) public callerIsSender nonReentrant {
        snakeTokenOwnerOf(tokenId);
        if (_type == 1) {
            uint256 balance = balanceOf(msg.sender);
            require(
                balance >= 1 ether,
                "You don't have enough QTER to change the layout"
            );
            //transfer 10 percent of 1ether to the oca
            uint256 amount = 0.1 ether;

            _burn(msg.sender, 1 ether);
            _mint(0x5A8168cB7f0993e1E3Fa6871D8Da2b84B4a4E1Eb, amount);
            // oca.changeLayout(tokenId, layout, 1);
        }
        oca.changeLayout(tokenId, layout, _type);
    }

    function checkBalance(address _sender) public view returns (uint256) {
        uint256 balance = balanceOf(_sender);
        require(
            balance >= 1 * 1 ether,
            "You don't have enough QTER to change the layout"
        );

        return balance;
    }

    function claimSnakeQTER(uint256 tokenId) public returns (uint256) {
        snakeTokenOwnerOf(tokenId);
        SnakeTokenInfo memory info = getSnakeStakeTime(tokenId);
        //get total time staked to increase the reward
        uint256 totalTimeStaked = (block.timestamp - info.stakeDate) / 86400;
        //get the reward amount based on last stake time;
        uint256 totalStakedSinceLastClaim = (block.timestamp - info.lastClaim) *
            5;
        //reward add multiplayer for every month staked since last claim
        uint256 rewardTotalMultiplayer = totalTimeStaked / (60 * 60 * 24);

        //reward add multiplier for every minute staked since last claim
        uint256 rewardTotal = (
            ((totalStakedSinceLastClaim * rewardTotalMultiplayer) / 60)
        ) * 1 ether;
        oca.setClaimTime(tokenId);
        _mint(msg.sender, rewardTotal);
        return rewardTotal;
    }

    function getTotalSnakeQTER(uint256 tokenId) public view returns (uint256) {
        SnakeTokenInfo memory info = getSnakeStakeTime(tokenId);
        //get total time staked to increase the reward
        uint256 totalTimeStaked = (block.timestamp - info.stakeDate) * 10;
        //get the reward amount based on last stake time;
        uint256 totalStakedSinceLastClaim = (block.timestamp - info.lastClaim) *
            10;
        //reward add multiplayer for every day staked since last claim
        uint256 rewardTotalMultiplayer = totalTimeStaked / (60 * 60 * 24);

        //reward add multiplier for every minute staked since last claim
        uint256 rewardTotal = (
            ((totalStakedSinceLastClaim + rewardTotalMultiplayer) / 60)
        ) * 1 ether;

        return rewardTotal;
    }

    // function stakeSnakeTokensCount(uint256[] memory tokenIds, uint256 count)
    //     public
    // {
    //     //        uint256 stakeDate = oca.getStakeArray(tokenId)[0];

    //     oca.stakeTokens(count, msg.sender, tokenIds);
    //     // oca.tokenInfoList(tokenId).stakeDate = block.timestamp;
    // }

    function stakeSnakeTokens(uint256[] memory tokenIds) public {
        //        uint256 stakeDate = oca.getStakeArray(tokenId)[0];

        for (uint256 index = 0; index < tokenIds.length; index++) {
            snakeTokenOwnerOf(tokenIds[index]);
            //oca.stakeToken(tokenIds[index]);
        }
        oca.stakeToken(tokenIds[0]);
        // oca.tokenInfoList(tokenId).stakeDate = block.timestamp;
    }

    function amINeo() public view returns (bool) {
        return oca.amINeo();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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

//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
//import "./ERC721Enumerable.sol";

import "./ERC721A.sol";

//import "./onChainArcade_Snake_Art.sol";

//            //////////////////////////////////////////////////////////////////////////
//            //           ______________________                    _________        //
//           //           __  __ \_  ____/__    |__________________ ______  /____    //
//          //           _  / / /  /    __  /| |_  ___/  ___/  __ `/  __  /_  _ \   //
//          //           / /_/ // /___  _  ___ |  /   / /__ / /_/ // /_/ / /  __/   //
//          //           \____/ \____/  /_/  |_/_/    \___/ \__,_/ \__,_/  \___/    //
//          //                                                                      //
//          //              ▀█▀ █▀▀ █▀▀ █ █ █▄ █ █▀█ █▀▄▀█ ▄▀█ █▄ █ █▀▀ █▄█         //
//          //               █  ██▄ █▄▄ █▀█ █ ▀█ █▄█ █ ▀ █ █▀█ █ ▀█ █▄▄  █          //
//          //                                                                      //
//                                                                                  /////////////////////
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BBBBBBPPPPPPPPPPPPPPPPPPPPPPPPPPPPB##@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&PPPPPPPPPPPPYJJJJJJJJ5PPPPPPPP5JJJJJJ#&&@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&PPPPPPPPPPPP.        ~GPPPPPPPY      JPP&@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&PPPPPPPP5^::   JBGGGGGPPPPPPPPPGGGGGG~::5BB&@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&#PPPPPPPP5      [email protected]@@@@#[email protected]@@@@@:  ?PP&@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#5PPPPPPPPPP5.     [email protected]@@@@#[email protected]@@@@@:  ?PP&@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#PPPPPPPPPPP5.     [email protected]@@@@#[email protected]@@@@@:  ?PP&@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#PPPPPPPPPPP5.     [email protected]@@@@#[email protected]@@@@@:  ?PP&@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#PPPPPPPPPPP5.     [email protected]@@@@#[email protected]@@@@&:  ?PP&@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#PPPPPPPPPPP5      .:::::7PPPPPPPPY::::::   ?PP&@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#PPPPPPPPPPP5^^^^^^^:::::?PPPPPPPPY^:^:::^^^YPP&@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP&@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#55PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP&@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##BPPPPPP###PPPPPPPPPPPPPPPPPPPPPPPPPPPPB##&@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&[email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##BPPPPPP################&&#GGGGGG&&&@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&GGPPPP555555555555PPP#@@&BBBGGGGGG&@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&PPPPPPPPPPPPPPP#@@@@@@@@&GGGGGGGBB&@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&PPPPPPPPPPPP5YJ5GG#@@@@@@&&&GGGGGG#&#&@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@&&&&&&@@@&GGGPPPPPP555J???77P&&@@@@@@@BGGBBBGGG&@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@[email protected]@@@@@[email protected]@@BGG&@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@&BB&@@@@@@@@@@@@@@@#BBGPPPPPPPPGBB#@@@[email protected]@@@@@&&&@@@&&&@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@#55B&&&&&&@@@@@@@&&[email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@#[email protected]@@@@@[email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@&&&#PPPPPPBB#@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@&PPPPPPPPP&&&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@&&#PPPPPPPPPPPPPPPPPPPP5B&&#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@&BBBPPPPPPPPPPPP555PBB&@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@&&&&&&Y?????B&&&@@@@@@@@@&&&PPPPP5J???777775&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@GPPPPP&@@@@@@@@@@@@@@@BBBBBBGPPPPPPPP#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
////////////////////////////////////////////////////////////////////////////////////////////////////////
contract OCASnake is Ownable, ERC2981, ERC721A, ReentrancyGuard {
    //apple string

    struct TokenInfo {
        uint256 stakeDate;
        uint256 lastClaim;
        uint256 layout;
        uint256 freeChange;
    }

    struct NameInformation {
        bytes32 snakeName;
        uint256 wackyAdjective;
        uint256 supremeAdjective;
    }

    struct UserConfig {
        uint256 extraLives;
        bool hasMinted;
    }

    struct ni {
        uint256 snakeNameIndex;
        uint256 adjectiveIndex;
        uint256 supremeIndex;
        uint256 combineIndex;
    }

    struct Attributes {
        string trait_type;
        string value;
    }
    struct MaintenanceDudes {
        uint256 itemType;
        bool canWithdraw;
        bool monthlyReset;
        uint256 lastWithDraw;
        uint256 withDrawAmount;
        uint256 royalities;
    }
    struct AttributesNumbers {
        string trait_type;
        string display_type;
        uint256 value;
        uint256 max;
    }

    // struct TokenInfo {
    //     uint256 stakeDate;
    //     uint256 lastClaim;
    //     uint256 layout;
    // }

    bool private midnightReleaseIsOn = false;
    bool private arcadeIsOpen = false;

    uint256 private extraLives = 2;
    uint256 private immutable maxLives = 1997;
    uint256 private immutable arcadePrice = 0.0006969 ether;
    uint256 private immutable midnightReleasePrice = 0.000420 ether;

    uint8 private maxPlay = 3;

    address private arcadeOwner;

    mapping(uint256 => TokenInfo) public tokenInfoList;
    mapping(address => UserConfig) public userConfigList;
    mapping(address => MaintenanceDudes) internal arcadeDudes;
    mapping(string => string) public difficultyNames;

    bool private turnOnThePower = false;
    string internal apple = "Different";
    string internal permanentApple = "Different";
    string[8] private opacity = [
        "1",
        "0.9",
        "0.8",
        "0.7",
        "0.6",
        "0.5",
        "0.4",
        "0.3"
    ];
    string[9] private funkyPicture = [
        "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 450 450' class='main'> <style> .main {background:",
        ";border:5px solid ",
        "}.Rrrrr{font:italic 40px serif; fill:",
        ";}</style><rect x='25' y='25' width='400' height='400' style='fill:",
        ";stroke:",
        ";stroke-width:5;stroke-opacity:0.9;'/><rect x='50' y='50' width='12' height='12' style='fill:",
        ";'/>",
        ";'/><text x='105' y='115' class='heavy'>Token</text><text x='150' y='150' class='Rrrrr'>",
        "</text></svg>"
    ];

    string[9] private funkySnake = [
        "<html><script src=https://gateway.pinata.cloud/ipfs/QmTY51seTrpBtKyR4g3jFngYXHpvj72W5gddDAxPRrNNhS>createScore = () => { }</script><body class='float' style='margin:0;padding:0;box-sizing:border-box;border:solid ",
        " 4px;background:",
        "'onload=\"sc=-1;i=0;sn='rgba(201,69,37 0.8)';change=_=>i==0?(i=1,sn='rgba(101, 69, 37, 0.8)',setTimeout(change, sp)):(sn='rgba(200,9,3,0.8)',i=0,setTimeout(change,sp));gs=false;change();df=",
        ";gri=(max)=>Math.floor(Math.random()*max);sp=525/(df+2);spf=()=> sp = sp > 54 - (df*3) ?sp - gri(8) : 54- (df*3);e=document.getElementById('e');z=v.height*=4;v.width*=2;X=0;a=h=136;s=[h];k=240;v=v.getContext('2d');to=()=>setTimeout(j=>{Y=X&k;s.unshift(h=h+X&15|h+Y&k);onkeydown=e=>X=[Y|j,X%j||15,Y||k,X%j|1][e.which==87?2:e.which==65?1:e.which==83?0:e.which==68?3:e.which&3];G=(c,l=z/j)=>P=>{v.fillStyle=c;v.fillRect(P%j*l,(P>>4)*l,l,l)};h-a?s[q](h,1)?s=[h]:s.pop():(Q=_=>s[q='includes'](a=Math.random()*256|0)||e.play()&&spf()||Q())();v.fillStyle='",
        "';v.fillRect(0,0,6,600);v.fillRect(595,0,6,600);v.fillRect(0,0,600,6);v.fillRect(0,595,600,6);G('",
        "',z)(0);G('",
        "')(a);s.map(G('",
        "'));to();createScore();(()=>{if(s.length>1 && gs==false) gs=true;else{sp=525/(df+2);gs=false}})()},sp,16);to();createScore();\"> <div class=float style=position:relative;display:flex; align-items: center;><div style=position:absolute; display:block;z-index:9999; align-items:center;><span id=oca class=oca_font> </span></div><canvas id=v style='border: 6px solid ",
        "'/></div><span id=sc class=oca_font></span><span id=sp class=oca_font> </span><div html=https://gateway.pinata.cloud/ipfs/QmSqzQFoavagaDBoQZEQADXvrCLWB9t1Ze4d1XhVd6JV4b/><audio id='e'/></html>"
    ];

    string[4] private metadata = [
        '{"name": "',
        '", "description": "On Chain Arcade (Snake) - Pushing blockchain tech and art as far as we can. A group of likeminded individuals that just want to see what we can do with the block chain. Please visit the dapp website to furth customize your Snake game.", "animation_url": "',
        '","external_url":"https://snake.OnChainArcade.xyz/',
        "}"
    ];
    string[15] internal supremeAdjectives = [
        "Degen ",
        "NGMI ",
        "GMI ",
        "Apeing ",
        "Diamond Hands ",
        "Paper Hands ",
        "Rugpuller ",
        "Whale ",
        "Hodl ",
        "Mooning ",
        "Building ",
        "Fudding ",
        "LFG ",
        "Wen "
    ];
    string[19] internal snakeSpecies = [
        "_Python",
        "",
        "_Cobra",
        "",
        "_Anaconda",
        "",
        "_Rattle",
        "",
        "_Boa",
        "",
        "_Coral",
        "",
        "_Garter",
        "",
        "_Kings",
        "",
        "_Green",
        "",
        "_Eryx"
    ];

    string[20] internal snakes = [
        "_Snake",
        "_Snak3",
        "_Sn4k3",
        "_$n4k3",
        "_SNAK3",
        "_SN4KE",
        "_$N4K3",
        "_5n4k3",
        "_5|\\|a|(3",
        "_5nak3",
        "_5n4ke",
        "_$|\\|a|<3",
        "_.../-./.-/-.-/.'////",
        "_0101001101101110011000010110101101100101",
        "_U25ha2U",
        "_83 110 97 107 101",
        "_536e616b65",
        "_Viper",
        "_V1p3r",
        "_\\/!|D3|2"
    ];
    string[270] internal wackyAdjectives = [
        "Stoic",
        "Absurd",
        "Adventurous"
        "Brazen",
        "Jester",
        "Eccentric",
        "Chucklesome",
        "Passionate",
        "Rich",
        "Poor",
        "Stooge",
        "Dumb",
        "Smart",
        "Zesty",
        "Quirky",
        "Ludicrous",
        "Goofball",
        "Facetious",
        "Anguine",
        "Hysterical",
        "Fanatical",
        "Ferocious",
        "Deranged",
        "Colubrine",
        "Elapine",
        "Serpentine",
        "Viperine",
        "Evil",
        "Center",
        "Stiff",
        "Self absorbed",
        "Artful",
        "Alert",
        "Fusion",
        "Clever",
        "Fast",
        "Misty",
        "Stats",
        "Lousy",
        "Easy",
        "Hippie",
        "Hushed",
        "Flickering",
        "Bad",
        "Seemly",
        "Poised",
        "Weary",
        "Exotic",
        "Brave",
        "Lowlife",
        "Asian",
        "Sticky",
        "Hairy",
        "Dull",
        "Patient",
        "Bored",
        "Smart",
        "Crawly",
        "Aglow",
        "Haunted",
        "Damp",
        "Cruelhearted",
        "Smooth",
        "Pagan",
        "Pygmy",
        "Worried",
        "Damaged",
        "Rude",
        "Playful",
        "Uncanny",
        "Cordial",
        "Agile",
        "Ancient",
        "Jolly",
        "Pokey",
        "Abusive",
        "Creepy",
        "Damned",
        "Search",
        "Serene",
        "Frail",
        "Steady",
        "Spastic",
        "Shiny",
        "Occult",
        "Narrow",
        "Intense",
        "Flat",
        "Large",
        "Daring",
        "Crabby",
        "Direct",
        "Prudent",
        "Picky",
        "Cheery",
        "Unholy",
        "Elderly",
        "Grumpy",
        "Witty",
        "Housebroken",
        "Cruel",
        "Boiling",
        "Magical",
        "Horrid",
        "Passive",
        "Boney",
        "Plain",
        "Joyful",
        "Lazy",
        "Lame",
        "Lovable",
        "Chilly",
        "Stylish",
        "Blunt",
        "Warm",
        "Sexy",
        "Mature",
        "Moronic",
        "Amazed",
        "Hard",
        "Grim",
        "Shallow",
        "Magic",
        "Beaten",
        "Heavy",
        "Odious",
        "Stupid",
        "Defiant",
        "Shrill",
        "Alien",
        "Masked",
        "Staid",
        "Fine",
        "Serious",
        "Amusing",
        "Territorial",
        "Gentle",
        "Dynamic",
        "Carved",
        "Sleepy",
        "Elated",
        "Maniac",
        "Wacky",
        "Silky",
        "Many",
        "Lucky",
        "Grubby",
        "Smoggy",
        "Moaning",
        "Mentally impaired",
        "High",
        "Brainy",
        "Blathering",
        "Mountain",
        "Gifted",
        "Sullen",
        "Sincere",
        "Dead",
        "Huge",
        "Ominous",
        "Undead",
        "Numb",
        "Reddit",
        "Maniacal",
        "Buried",
        "Print",
        "Bright",
        "Cloudy",
        "Dashing",
        "Dowdy",
        "Long",
        "Sweet",
        "Touchy",
        "Orderly",
        "Rapid",
        "Slight",
        "Pocket",
        "Obscene",
        "Cold",
        "Infuriating",
        "Lovely",
        "Frozen",
        "Snapping",
        "Harsh",
        "Darkish",
        "High-end",
        "Dusty",
        "Broken",
        "Pitiful",
        "Sexual",
        "Distant",
        "Chic",
        "Good",
        "Small",
        "Faith",
        "Weird",
        "Sulky",
        "Slow",
        "Wooden",
        "Extreme",
        "Morbid",
        "Drowsy",
        "Subtle",
        "Furry",
        "Demanding",
        "Groggy",
        "Bull headed",
        "Purple",
        "Helpful",
        "Moonlit",
        "Somber",
        "Slippery",
        "Unsure",
        "Feisty",
        "Little",
        "Fit",
        "Famous",
        "Popular",
        "Heathen",
        "Crazy",
        "Sharp",
        "Capable",
        "Snobby",
        "Real",
        "Local",
        "Skinny",
        "Email",
        "Divine",
        "Glued",
        "Keen",
        "Best",
        "Flaky",
        "Tripping",
        "Deviant",
        "Dry",
        "Roasted",
        "Sour",
        "Grave",
        "Black",
        "Empty",
        "Leggy",
        "Amiable",
        "Flowing",
        "Fragile",
        "Fervent",
        "Dainty",
        "Watery",
        "Direful",
        "Demure",
        "Pensive",
        "Juicy",
        "Crowded",
        "Cranky",
        "Nosy",
        "Fiery",
        "Striped",
        "Morose",
        "Testy",
        "Itchy",
        "Quirky",
        "Thrifty",
        "Stingy",
        "Calm",
        "Silent",
        "Spooked",
        "Insecure",
        "Hot",
        "Leery",
        "Amused",
        "Gory",
        "Macabre"
    ];

    constructor() ERC721A("On Chain Arcade ", "OCA_SNAKE", 1997, 1997) {
        //Set all static variables on initialization.

        arcadeDudes[0xC4741484290Ec4673c6e6Ca2d1b255e7749bB82b]
            .royalities = 750;
        arcadeDudes[0xC4741484290Ec4673c6e6Ca2d1b255e7749bB82b]
            .canWithdraw = true;
        arcadeDudes[0xC4741484290Ec4673c6e6Ca2d1b255e7749bB82b].itemType = 1;

        arcadeDudes[address(this)].itemType = 1;

        difficultyNames["0"] = "Easy";
        difficultyNames["1"] = "Medium";
        difficultyNames["2"] = "Hard";
        arcadeOwner = msg.sender;
        _setDefaultRoyalty(0xC4741484290Ec4673c6e6Ca2d1b255e7749bB82b, 750);
        // userConfigList[0xC206277b9DC22D53A7D3d9DDb6441EF8923eEd23] = UserConfig(
        //     0,
        //     5,
        //     2,
        //     0xC206277b9DC22D53A7D3d9DDb6441EF8923eEd23,
        //     0xC206277b9DC22D53A7D3d9DDb6441EF8923eEd23,
        //     "apple"
        // );
    }

    modifier callerIsSender() {
        if (tx.origin != msg.sender) revert();
        _;
    }

    modifier callerIsNeo() {
        bool isTrue = arcadeDudes[msg.sender].itemType == 1 ||
            msg.sender == arcadeOwner;
        require(isTrue, "Only the Arcade owners can call this function.");
        _;
    }

    modifier onlyValidAccess(
        uint256 _date,
        string memory _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) {
        require(
            isValidAccessMessage(msg.sender, _date, _message, _v, _r, _s),
            "Invalid access message."
        );
        _;
    }

    function whiteListTest(
        uint256 _date,
        string memory _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public view onlyValidAccess(_date, _message, _v, _r, _s) returns (bool) {
        return true;
    }

    function isValidAccessMessage(
        address _address,
        uint256 date,
        string memory message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(address(this), _address, date, message)
        );
        require(date > block.timestamp, "Request has expired.");
        address sender = ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            ),
            _v,
            _r,
            _s
        );

        bool isNeo = arcadeDudes[sender].itemType == 1 || sender == arcadeOwner;
        return isNeo;
    }

    function amINeo() public view returns (bool) {
        return
            arcadeDudes[msg.sender].itemType == 1 || msg.sender == arcadeOwner;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721A: transfer to non ERC721Receiver implementer"
        );
        tokenInfoList[tokenId].stakeDate = 0;
    }

    function getSaleState(uint256 saleType) public view returns (bool) {
        if (saleType == 0) {
            return arcadeIsOpen;
        } else if (saleType == 1) {
            return midnightReleaseIsOn;
        }
        return turnOnThePower;
    }

    function funkSnakeCreator(string[8] memory vars)
        private
        view
        returns (bytes memory)
    {
        bytes memory snakeBytes;
        for (uint256 i = 0; i < vars.length; i++) {
            snakeBytes = abi.encodePacked(snakeBytes, funkySnake[i], vars[i]);
        }
        return abi.encodePacked(snakeBytes, funkySnake[8]);
    }

    function funkPictureCreator(string[8] memory vars)
        private
        view
        returns (bytes memory)
    {
        bytes memory svgBytes;
        for (uint256 i = 0; i < vars.length; i++) {
            svgBytes = abi.encodePacked(svgBytes, funkyPicture[i], vars[i]);
        }
        return abi.encodePacked(svgBytes, funkyPicture[8]);
    }

    // function getAppleIndex(uint256 tokenId)
    //     public
    //     view
    //     returns (string[] memory)
    // {
    //     return retrofy(tokenId);
    // }

    // function funkCreator(
    //     uint256 r,
    //     uint256 g,
    //     uint256 b,
    //     uint256 a
    // ) public view returns (string memory) {
    //     return
    //         string(
    //             abi.encodePacked(
    //                 "rgba(",
    //                 Strings.toString(r),
    //                 ",",
    //                 Strings.toString(g),
    //                 ",",
    //                 Strings.toString(b),
    //                 ",",
    //                 opacity[a],
    //                 ")"
    //             )
    //         );
    // }

    function funkCreator(
        uint256 r,
        uint256 g,
        uint256 b,
        uint256 a
    ) private view returns (bytes memory) {
        return
            abi.encodePacked(
                "rgba(",
                Strings.toString(r),
                ",",
                Strings.toString(g),
                ",",
                Strings.toString(b),
                ",",
                opacity[a],
                ")"
            );
    }

    function createPixel(
        string memory color,
        uint256 x,
        uint256 y
    ) private pure returns (bytes memory) {
        return
            abi.encodePacked(
                "<rect x='",
                Strings.toString(x),
                "' y='",
                Strings.toString(y),
                "' width='12' height='12' style='fill:",
                color,
                ";' />"
            );
    }

    function generateAppleSeed(
        uint256 tokenId,
        uint256 salt,
        bool isFunk
    ) private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    isFunk ? apple : permanentApple,
                    tokenId,
                    salt,
                    uint256(0)
                )
            )
        );
        return seed;
    }

    function selectDifficulty(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return Strings.toString(generateAppleSeed(tokenId, 69420, false) % 3);
    }

    function allYourBaseAreBelongToUs(uint256 tokenId, uint256 layout)
        private
        view
        returns (string memory)
    {
        // string[30] memory selectedColors;
        // selectedColors = retrofy(tokenId);
        string[30] memory colors = generateAllColors(tokenId, layout);

        string memory base64 = Base64.encode(
            // abi.encodePacked(
            //     "<html><script src=https://gateway.pinata.cloud/ipfs/QmZVp7zVurDTromjmhPP3z2JBoEAq1wSg7quVcmSzkRcWB></script><body class='float' style='margin:0;padding:0;box-sizing:border-box;border:solid ",
            //     selectedColors[
            //         OCASnake.generateAppleSeed(tokenId, 786) % uint256(19)
            //     ],
            //     " 4px;background:",
            //     selectedColors[
            //         OCASnake.generateAppleSeed(tokenId, 69) % uint256(19)
            //     ],
            //     "'onload=\"df=",
            //     selectDifficulty(),
            //     ";gri=(max)=>Math.floor(Math.random()*max);sp=525/(df+2);spf=()=> sp = sp > 54 - (df*3) ?sp - gri(8) : 54- (df*3);e=document.getElementById('e');z=v.height*=4;v.width*=2;X=0;a=h=136;s=[h];k=240;v=v.getContext('2d');to=()=>setTimeout(j=>{Y=X&k;s.unshift(h=h+X&15|h+Y&k);onkeydown=e=>X=[Y|j,X%j||15,Y||k,X%j|1][e.which==87?2:e.which==65?1:e.which==83?0:e.which==68?3:e.which&3];G=(c,l=z/j)=>P=>{v.fillStyle=c;v.fillRect(P%j*l,(P>>4)*l,l,l)};h-a?s[q](h,1)?s=[h]:s.pop():(Q=_=>e.play()&&spf()&&sc++&&s[q='includes'](a=Math.random()*256|0)&&Q())();v.fillStyle='#000';v.fillRect(0,0,6,600);v.fillRect(595,0,6,600);v.fillRect(0,0,600,6);v.fillRect(0,595,600,6);G('",
            //     selectedColors[0],
            //     "',z)(0);G('",
            //     selectedColors[
            //         OCASnake.generateAppleSeed(tokenId, 1337) % uint256(19)
            //     ],
            //     "')(a);s.map(G('",
            //     selectedColors[
            //         OCASnake.generateAppleSeed(tokenId, 420) % uint256(19)
            //     ],
            //     "'));to();createScore()},sp,16);to();createScore()\">",
            //     "<div class=float style=position:relative;display:flex; align-items: center;><div style=position:absolute; display:block;z-index:9999; align-items:center;><span id=oca class=oca_font> </span></div><canvas id=v style='border: 6px solid ",
            //     selectedColors[
            //         OCASnake.generateAppleSeed(tokenId, 143) % uint256(19)
            //     ],
            //     "'/></div><span id=sc class=oca_font></span><span id=sp class=oca_font> </span><div html=https://gateway.pinata.cloud/ipfs/QmSqzQFoavagaDBoQZEQADXvrCLWB9t1Ze4d1XhVd6JV4b/><audio id='e'/></html>"
            // )

            funkSnakeCreator(
                [
                    colors[generateAppleSeed(tokenId, 786, true) % uint256(19)],
                    colors[generateAppleSeed(tokenId, 69, true) % uint256(19)],
                    selectDifficulty(tokenId),
                    colors[generateAppleSeed(tokenId, 23, true) % uint256(19)],
                    colors[0],
                    colors[
                        generateAppleSeed(tokenId, 1337, true) % uint256(19)
                    ],
                    colors[generateAppleSeed(tokenId, 420, true) % uint256(19)],
                    colors[generateAppleSeed(tokenId, 143, true) % uint256(19)]
                ]
            )
        );

        return string(abi.encodePacked("data:text/html;base64,", base64));
    }

    function image_funk(uint256 tokenId, uint256 layout)
        internal
        view
        returns (bytes memory)
    {
        bytes memory svgData = cloneSnake(tokenId, layout);
        return
            turnOnThePower
                ? (
                    abi.encodePacked(
                        allYourBaseAreBelongToUs(tokenId, layout),
                        '","image_data": "',
                        svgData
                    )
                )
                : abi.encodePacked(
                    "https://gateway.pinata.cloud/ipfs/QmZ9FB2Mg3tkyDhk2FF7rJ62X4T3arauiNZLBU2yG8SpcH"
                );
    }

    function generateColors(uint256 tokenId, uint256 number)
        private
        view
        returns (uint256)
    {
        return uint256(generateAppleSeed(tokenId, number, true)) % uint256(255);
    }

    function generateAllColors(uint256 tokenId, uint256 layout)
        private
        view
        returns (string[30] memory)
    {
        string[30] memory colors = retrofy(tokenId, layout);
        uint256 rn = (generateAppleSeed(tokenId, 420 * layout, true) %
            (colors.length - 10)) + 10;

        string[30] memory result;
        for (uint256 i = 0; i < rn; i++) {
            result[i] = colors[i];
        }

        return result;
    }

    function generateColorArray(
        uint256 tokenId,
        uint256 i,
        uint256 layout
    ) private view returns (uint256[4] memory) {
        uint256[4] memory colors;
        uint16[3] memory changes = [128, 420, 69];

        for (uint256 index = 0; index < colors.length - 1; index++) {
            colors[index] = i == 1
                ? generateColors(tokenId, changes[index] + layout)
                : generateColors(tokenId, changes[index] + layout + i + index);
        }
        uint256 o = uint256(generateAppleSeed(tokenId, layout + i, true) + i);
        colors[3] = uint256(o) % uint256(opacity.length);
        return colors;
    }

    function retrofy(uint256 tokenId, uint256 layout)
        internal
        view
        returns (string[30] memory)
    {
        string[30] memory parts;

        for (uint256 i = 0; i < parts.length; i++) {
            uint256[4] memory colors = generateColorArray(tokenId, i, layout);

            if (i == 1)
                parts[1] = string(
                    funkCreator(colors[0], colors[1], colors[2], 1)
                );
            else
                parts[i] = string(
                    funkCreator(colors[0], colors[1], colors[2], colors[3])
                );
        }

        return parts;
    }

    // function retrofy(
    //     uint256 tokenId,
    //     uint256 i,
    //     uint256 index,
    //     string[30] memory parts,
    //     string[4] memory colors
    // ) internal view returns (string[30] memory) {
    //     colors[index] = generateColors(
    //         tokenId,
    //         index == 0 ? 420 : 69 + i + index
    //     );

    //     if (index < 3) return retrofy(tokenId, i, index + 1, parts, colors);

    //     uint256 o = uint256(generateAppleSeed(tokenId, i) + i);
    //     colors[3] = i == 1
    //         ? opacity[0]
    //         : opacity[uint256(o) % uint256(opacity.length)];

    //     parts[i] = string(
    //         funkCreator(colors[0], colors[1], colors[2], colors[3])
    //     );

    //     if (i > 0) return retrofy(tokenId, i - 1, 0, parts, colors);
    //     return parts;
    // }

    function cloneSnake(uint256 tokenId, uint256 layout)
        private
        view
        returns (bytes memory)
    {
        string[30] memory selectedColors = generateAllColors(tokenId, layout);
        bytes memory svgData = "";
        uint256 randomSnakeLength = (generateAppleSeed(tokenId, 69, true) %
            uint256(10)) + uint256(30);
        for (uint256 i = 0; i < randomSnakeLength; i++) {
            svgData = abi.encodePacked(
                svgData,
                createPixel(
                    selectedColors[
                        generateAppleSeed(
                            tokenId,
                            420 * tokenInfoList[tokenId].layout,
                            true
                        ) % uint256(19)
                    ],
                    250 * i,
                    325
                )
            );
        }

        return
            funkPictureCreator(
                [
                    selectedColors[
                        generateAppleSeed(
                            tokenId,
                            69 * tokenInfoList[tokenId].layout,
                            true
                        ) % uint256(19)
                    ],
                    selectedColors[
                        generateAppleSeed(
                            tokenId,
                            23 * tokenInfoList[tokenId].layout,
                            true
                        ) % uint256(19)
                    ],
                    selectedColors[
                        generateAppleSeed(
                            tokenId,
                            7 * tokenInfoList[tokenId].layout,
                            true
                        ) % uint256(19)
                    ],
                    selectedColors[1],
                    selectedColors[
                        generateAppleSeed(
                            tokenId,
                            143 * tokenInfoList[tokenId].layout,
                            true
                        ) % uint256(19)
                    ],
                    selectedColors[
                        uint256(
                            generateAppleSeed(
                                tokenId,
                                1337 * tokenInfoList[tokenId].layout,
                                true
                            )
                        ) % uint256(19)
                    ],
                    string(svgData),
                    Strings.toString(tokenId)
                ]
            );
    }

    function recursiveCompareArrayCreation(
        uint256 index,
        uint256 count,
        uint256 seed,
        uint256[10] memory array
    ) private view returns (uint256[10] memory) {
        uint256 snakeNameIndexCompare = (generateAppleSeed(
            index + count,
            seed,
            false
        ) % snakes.length);
        uint256 adjectiveIndexCompare = (generateAppleSeed(
            index + count,
            seed,
            false
        ) % wackyAdjectives.length);

        array[count % 10] = snakeNameIndexCompare * adjectiveIndexCompare + 1;
        if (count < 10) {
            return recursiveCompareArrayCreation(index, count + 1, seed, array);
        } else {
            return array;
        }
    }

    // function setHighScore(uint256) public view returns (uint256) {

    //     return
    // }

    function getLayoutSize(uint256 tokenId) private view returns (uint256) {
        return uint256(generateAppleSeed(tokenId, 69, false) % uint256(9)) + 1;
    }

    function changeLayout(
        uint256 tokenId,
        uint256 layout,
        uint256 _type
    ) public {
        require(
            layout <= getLayoutSize(tokenId),
            string(
                abi.encodePacked(
                    "Layout must be between 0 and ",
                    getLayoutSize(tokenId)
                )
            )
        );

        if (_type == 0) {
            bool isTokenOwner = msg.sender == ownerOf(tokenId);
            require(isTokenOwner, "Only the owner can change the layout");
            TokenInfo memory tokenInfo = tokenInfoList[tokenId];
            require(tokenInfo.freeChange > 0, "No free changes left");
            tokenInfo.freeChange--;
            tokenInfoList[tokenId].layout = layout;
        } else {
            bool isNeo = arcadeDudes[msg.sender].itemType == 1 ||
                msg.sender == arcadeOwner;
            require(isNeo, "Only Neo can change the layout");
            tokenInfoList[tokenId].layout = layout;
        }
    }

    function roshambo(
        uint256 you,
        uint256 opponent,
        uint256 seed
    ) private view returns (bool) {
        uint256 youThrow = generateAppleSeed(you, seed + 69, false) % 3;
        uint256 opponentThrow = generateAppleSeed(opponent, seed + 69, false) %
            3;
        if (youThrow > opponentThrow) return true;
        else if (youThrow == opponentThrow)
            return roshambo(you, opponent, seed + 420);
        else return false;
        // if (youThrow == 0) {
        //     if (opponentThrow == 0) {
        //         return roshambo(you, opponent, seed + 420);
        //     } else if (opponentThrow == 1) {
        //         return false;
        //     } else {
        //         return true;
        //     }
        // } else if (youThrow == 1) {
        //     if (opponentThrow == 0) {
        //         return false;
        //     } else if (opponentThrow == 1) {
        //         return roshambo(you, opponent, seed + 69);
        //     } else {
        //         return true;
        //     }
        // } else {
        //     if (opponentThrow == 0) {
        //         return false;
        //     } else if (opponentThrow == 1) {
        //         return true;
        //     } else {
        //         return roshambo(you, opponent, seed + 1337);
        //     }
        // }
    }

    //TODO: Try to clean this function up. I bet we can send less data. and get the same results.
    function recursiveNameFind(
        uint256 tokenId,
        uint256 index,
        uint256 seed,
        bool resetTokens,
        string memory supreme,
        uint256[3] memory snakeNameIndexes
    ) private view returns (string memory) {
        if (resetTokens) {
            uint256 snakeNameIndex = (generateAppleSeed(tokenId, seed, false) %
                snakes.length);
            uint256 adjectiveIndex = (generateAppleSeed(tokenId, seed, false) %
                wackyAdjectives.length);
            uint256 speciesName = (generateAppleSeed(tokenId, seed, false) %
                snakeSpecies.length);

            if (seed == 0) supreme = "";

            snakeNameIndexes[0] = snakeNameIndex;
            snakeNameIndexes[1] = adjectiveIndex;
            snakeNameIndexes[2] = speciesName;
        }

        uint256 indexCompare = snakeNameIndexes[0] * snakeNameIndexes[1] + 1;

        bool found;
        uint256[10] memory arr;
        uint256[10] memory compareArray = recursiveCompareArrayCreation(
            index,
            0,
            seed,
            arr
        );

        for (uint256 i = 0; i < compareArray.length; i++) {
            if (compareArray[i] == indexCompare) {
                found = true;
                break;
            }
        }

        bool change = tokenId == index ? false : roshambo(tokenId, index, seed);
        if ((index < 1998 && !found) || tokenId == index) {
            return
                recursiveNameFind(
                    tokenId,
                    index + 10,
                    seed,
                    false,
                    supreme,
                    snakeNameIndexes
                );
        } else if (found && change) {
            uint256 supremeIndex = (generateAppleSeed(tokenId, seed, false) %
                supremeAdjectives.length);

            supreme = generateAppleSeed(tokenId, seed + 69, false) % 2 == 1
                ? supremeAdjectives[supremeIndex]
                : "";
            return
                setNameToString(
                    snakeNameIndexes,
                    supremeAdjectives[supremeIndex]
                );

            // return
            //     recursiveNameFind(
            //         tokenId,
            //         index + 10,
            //         seed + 420,
            //         true,
            //         supreme,
            //         snakeNameIndexes
            //     );
        } else if (found) {
            snakeNameIndexes[0] =
                generateAppleSeed(tokenId, seed + 420, false) %
                17;
            snakeNameIndexes[1] =
                generateAppleSeed(tokenId, seed + 69, false) %
                250;
            return setNameToString(snakeNameIndexes, supreme);
            // return
            //     recursiveNameFind(
            //         tokenId,
            //         index + 10,
            //         seed,
            //         false,
            //         supreme,
            //         snakeNameIndexes
            //     );
        } else {
            return setNameToString(snakeNameIndexes, supreme);
        }
    }

    function setNameToString(
        uint256[3] memory snakeNameIndexes,
        string memory supreme
    ) private view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    supreme,
                    wackyAdjectives[snakeNameIndexes[1]],
                    snakeSpecies[snakeNameIndexes[2]],
                    snakes[snakeNameIndexes[0]]
                )
            );
    }

    function generateAdjectives(uint16 tokenId)
        private
        view
        returns (string[10] memory)
    {
        //for loop to go through the array of adjectives
        string[10] memory adjectives;
        for (uint256 index = 0; index < 10; index++) {
            adjectives[index] = wackyAdjectives[
                generateAppleSeed(tokenId, index, false) %
                    wackyAdjectives.length
            ];
        }
        return adjectives;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        callerIsNeo
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    // function setWithdrawAddress(address newAddress) public callerIsNeo {
    //     arcadeMaintenanceDude = newAddress;
    // }

    function coinRemoval(address withdrawAddress) public {
        MaintenanceDudes memory maintenanceDude = arcadeDudes[withdrawAddress];
        bool success;
        (success, ) = withdrawAddress.call{value: address(this).balance}("");
        if (!success || !maintenanceDude.canWithdraw) revert();
        //   require(success, "Failed to send to withdrawAddress.");
    }

    // function midnightReleaseParty(UserConfig[] calldata configs)
    //     external
    //     callerIsNeo
    // {
    //     for (uint256 i = 0; i < configs.length; i++) {
    //         userConfigList[configs[i].readyPlayerOne] = configs[i];
    //     }
    // }

    function startTheMatrix(
        uint256 sale,
        string memory _newapple,
        uint32 limit
    ) public callerIsNeo {
        if (sale == 1 && !turnOnThePower) {
            midnightReleaseIsOn = true;
            arcadeIsOpen = true;
            extraLives = limit;
        } else if (sale == 2) {
            midnightReleaseIsOn = false;
            apple = _newapple;
            permanentApple = _newapple;
            extraLives = limit;
        } else {
            //remove the seed change when we go live (Doing for tests)
            //      apple = _newapple;
            //   arcadeIsOpen = false;
            turnOnThePower = true;
        }
    }

    function checkCoinInflation(uint256 amount) private view {
        uint256 totalCoins;
        for (uint256 i = 0; i < amount; i++) {
            if (
                midnightReleaseIsOn &&
                !userConfigList[msg.sender].hasMinted &&
                i == 0
            ) totalCoins += midnightReleasePrice;
            else totalCoins += arcadePrice;
        }
        require(msg.value >= totalCoins, "Did you ask your mom for quarters?");
    }

    function insertQuarter(
        uint256 amount,
        uint256 date,
        uint8 _v,
        bytes32[2] memory _r_s
    ) public payable callerIsSender nonReentrant {
        if (
            !midnightReleaseIsOn &&
            arcadeIsOpen &&
            userConfigList[msg.sender].hasMinted
        ) userConfigList[msg.sender] = UserConfig(extraLives, false);
        require(amount + currentIndex <= maxLives, "Coinslot is full.");
        //    require(amount <= totalSupply(), "Coinslot is full.");
        bool Neo = arcadeDudes[msg.sender].itemType > 0 ||
            msg.sender == arcadeOwner;
        if (!Neo) {
            require(arcadeIsOpen, "Out of order");

            checkCoinInflation(amount);

            if (midnightReleaseIsOn) {
                // require(userConfigList[msg.sender].extra - amount >= 0);

                isValidAccessMessage(
                    msg.sender,
                    date,
                    "",
                    _v,
                    _r_s[0],
                    _r_s[1]
                );

                require(
                    userConfigList[msg.sender].extraLives - amount > 0,
                    "Whoa now leave some for the rest of us"
                );
            } else
                require(
                    userConfigList[msg.sender].extraLives - amount > 0,
                    "No more lives"
                );

            userConfigList[msg.sender].extraLives -= amount;
            userConfigList[msg.sender].hasMinted = true;
        }

        ERC721A._safeMint(msg.sender, amount);
    }

    function getStakedTime(uint256 tokenId)
        public
        view
        returns (uint256[3] memory)
    {
        require(tokenInfoList[tokenId].stakeDate != 0, "Token is not staked.");

        return [
            tokenInfoList[tokenId].stakeDate,
            tokenInfoList[tokenId].lastClaim,
            tokenInfoList[tokenId].layout
        ];
    }

    // function stakeTokens(
    //     uint256 index,
    //     address sender,
    //     uint256[] memory tokenIds
    // ) public callerIsNeo {
    //     uint256 tokenId = tokenIds[index - 1];
    //     bool isSender = ownerOf(tokenId) == sender;

    //     require(isSender, "You are not the owner of this token.");
    //     tokenInfoList[tokenId].stakeDate = block.timestamp;
    //     tokenInfoList[tokenId].lastClaim = block.timestamp;

    //     if (index > 1) return this.stakeTokens(index - 1, sender, tokenIds);
    // }

    function stakeToken(uint256 tokenId) public callerIsNeo {
        tokenInfoList[tokenId].stakeDate = block.timestamp;
        tokenInfoList[tokenId].lastClaim = block.timestamp;
    }

    function setClaimTime(uint256 tokenId) public callerIsNeo {
        require(tokenInfoList[tokenId].stakeDate != 0, "Token is not staked.");
        tokenInfoList[tokenId].lastClaim = block.timestamp;
    }

    function setArcadeDude(
        address dudesAddress,
        uint256 dudesType,
        uint256 royalties,
        uint256 withdrawAmmount,
        bool monthlyReset,
        bool canWithdraw
    ) public callerIsNeo {
        arcadeDudes[dudesAddress] = MaintenanceDudes(
            dudesType,
            canWithdraw,
            monthlyReset,
            block.timestamp,
            withdrawAmmount,
            royalties
        );
    }

    function getStakeArray(uint256 _tokenId)
        public
        view
        returns (uint256[2] memory)
    {
        return [
            tokenInfoList[_tokenId].stakeDate,
            tokenInfoList[_tokenId].lastClaim
        ];
    }

    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual override {
        uint256 startTokenId = currentIndex;
        require(to != address(0));
        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
        require(!_exists(startTokenId));
        // require(quantity <= maxBatchSize, "Coinslot is full.");

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        AddressData memory addressData = _addressData[to];
        _addressData[to] = AddressData(
            addressData.balance + uint128(quantity),
            addressData.numberMinted + uint128(quantity)
        );
        _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

        for (uint256 i = 0; i < quantity; i++) {
            emit Transfer(address(0), to, startTokenId);
            require(
                _checkOnERC721Received(address(0), to, startTokenId, _data),
                "ERC721A: transfer to non ERC721Receiver implementer"
            );

            //   tokenInfoList[startTokenId] = TokenInfo(block.timestamp);
            //get current block timestamp.
            //  snakeNameSave(startTokenId, false);

            startTokenId++;
        }

        currentIndex = startTokenId;
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    // function metaDataCreator(uint256 tokenId)
    //     internal
    //     view
    //     returns (bytes memory)
    // {
    //     uint256[3] memory arr = [uint256(0), 0, 0];
    //     return
    //     metaDataCreator(tokenId, arr);
    // abi.encodePacked(
    //     '{"name": "',
    //     recursiveNameFind(tokenId, 0, 0, true, "0", arr),
    //     //    tokenInfoList[tokenId].name,
    //     '", "description": "On Chain Arcade (Snake) - Pushing blockchain tech and art as far as we can. A group of likeminded individuals that just want to see what we can do with the block chain. Please visit the dapp website to furth customize your Snake game.", "animation_url": "',
    //     image_funk(tokenId),
    //     '"}'
    // );
    // }

    function metaDataCreator(uint256 tokenId)
        private
        view
        returns (bytes memory)
    {
        //address tokenOwner = ownerOf(tokenId);

        uint256[3] memory arr = [uint256(0), 0, 0];
        //   if (!_exists(tokenId)) revert();
        // address tokenOwner = ownerOf(tokenId);

        string[3] memory metadataVars = [
            string(
                turnOnThePower
                    ? recursiveNameFind(tokenId, 0, 0, true, "0", arr)
                    : "Welcome to the Arcade"
            ),
            string(image_funk(tokenId, tokenInfoList[tokenId].layout)),
            Strings.toString(tokenId)
        ];

        string[30] memory colors = retrofy(
            tokenId,
            tokenInfoList[tokenId].layout
        );
        Attributes[10] memory attributes;
        AttributesNumbers[3] memory attributesNumbers;

        attributes[0] = Attributes(
            "Difficulty",
            difficultyNames[selectDifficulty(tokenId)]
        );

        attributesNumbers[0] = AttributesNumbers(
            "Color Count",
            "",
            (generateAppleSeed(
                tokenId,
                1337 * tokenInfoList[tokenId].layout,
                false
            ) % (colors.length - 10)) + 10,
            colors.length
        );
        attributesNumbers[1] = AttributesNumbers(
            "Variance Count",
            "",
            getLayoutSize(tokenId),
            10
        );
        attributesNumbers[2] = AttributesNumbers(
            "Current Variance",
            "number",
            tokenInfoList[tokenId].layout,
            // userConfigList[tokenOwner].layout,
            getLayoutSize(tokenId)
        );
        bytes memory metaBytes;

        for (uint8 i = 0; i < metadataVars.length; i++) {
            metaBytes = abi.encodePacked(
                metaBytes,
                metadata[i],
                metadataVars[i]
            );
        }

        bytes memory fullBytes = abi.encodePacked(
            metaBytes,
            turnOnThePower
                ? attributeCreator(attributes, attributesNumbers)
                : bytes('"'),
            metadata[3]
        );
        return fullBytes;
    }

    function attributeCreator(
        Attributes[10] memory attributes,
        AttributesNumbers[3] memory attributeNumbers
    ) private view returns (bytes memory) {
        bytes memory attributeBytes;
        bytes memory numberAttributeBytes;
        if (!turnOnThePower) return attributeBytes;
        for (uint8 i = 0; i < attributeNumbers.length; i++) {
            numberAttributeBytes = abi.encodePacked(
                numberAttributeBytes,
                '{"trait_type":"',
                string(attributeNumbers[i].trait_type),
                '","display_type":"',
                string(attributeNumbers[i].display_type),
                '","value":',
                Strings.toString(attributeNumbers[i].value),
                ',"max_value":',
                Strings.toString(attributeNumbers[i].max),
                "},"
            );
        }

        for (uint8 i = 0; i < attributes.length; i++) {
            bytes memory attribute = abi.encodePacked(
                attributeBytes,
                '{"trait_type":"',
                attributes[i].trait_type,
                '","value":"',
                attributes[i].value,
                i == attributes.length - 1 ? '"}]' : '"},'
            );
            attributeBytes = i == 0
                ? abi.encodePacked('","attributes":[', attribute)
                : i == 1
                ? abi.encodePacked(attributeBytes, numberAttributeBytes)
                : abi.encodePacked(attribute);
        }
        return attributeBytes;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory json = Base64.encode(metaDataCreator(tokenId));
        return string(abi.encodePacked("data:application/json;base64,", json));
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes the number of issuable tokens (collection size) is capped and fits in a uint128.
 *
 * Does not support burning tokens to address(0).
 */
contract ERC721A is
    Context,
    ERC165,
    IERC721,
    IERC721Metadata,
    IERC721Enumerable
{
    using Address for address;
    using Strings for uint256;

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
    }

    struct AddressData {
        uint128 balance;
        uint128 numberMinted;
    }

    uint256 internal currentIndex = 0;

    uint256 internal immutable collectionSize;
    uint256 internal immutable maxBatchSize;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) internal _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev
     * `maxBatchSize` refers to how much a minter can mint at a time.
     * `collectionSize_` refers to how many tokens are in the collection.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxBatchSize_,
        uint256 collectionSize_
    ) {
        require(
            collectionSize_ > 0,
            "ERC721A: collection must have a nonzero supply"
        );
        require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
        _name = name_;
        _symbol = symbol_;
        maxBatchSize = maxBatchSize_;
        collectionSize = collectionSize_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return currentIndex;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        override
        returns (uint256)
    {
        require(index < totalSupply(), "ERC721A: global index out of bounds");
        return index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(collectionSize). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns (uint256)
    {
        require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdsIdx = 0;
        address currOwnershipAddr = address(0);
        for (uint256 i = 0; i < numMintedSoFar; i++) {
            TokenOwnership memory ownership = _ownerships[i];
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == owner) {
                if (tokenIdsIdx == index) {
                    return i;
                }
                tokenIdsIdx++;
            }
        }
        revert("ERC721A: unable to get token of owner by index");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(
            owner != address(0),
            "ERC721A: balance query for the zero address"
        );
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        require(
            owner != address(0),
            "ERC721A: number minted query for the zero address"
        );
        return uint256(_addressData[owner].numberMinted);
    }

    function ownershipOf(uint256 tokenId)
        internal
        view
        returns (TokenOwnership memory)
    {
        require(_exists(tokenId), "ERC721A: owner query for nonexistent token");

        uint256 lowestTokenToCheck;
        if (tokenId >= maxBatchSize) {
            lowestTokenToCheck = tokenId - maxBatchSize + 1;
        }

        for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
            TokenOwnership memory ownership = _ownerships[curr];
            if (ownership.addr != address(0)) {
                return ownership;
            }
        }

        revert("ERC721A: unable to determine the owner of token");
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        require(to != owner, "ERC721A: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721A: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721A: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        require(operator != _msgSender(), "ERC721A: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721A: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < currentIndex;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, "");
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - there must be `quantity` tokens remaining unminted in the total collection.
     * - `to` cannot be the zero address.
     * - `quantity` cannot be larger than the max batch size.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        uint256 startTokenId = currentIndex;
        require(to != address(0), "ERC721A: mint to the zero address");
        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
        require(!_exists(startTokenId), "ERC721A: token already minted");
        require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        AddressData memory addressData = _addressData[to];
        _addressData[to] = AddressData(
            addressData.balance + uint128(quantity),
            addressData.numberMinted + uint128(quantity)
        );
        _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

        uint256 updatedIndex = startTokenId;

        for (uint256 i = 0; i < quantity; i++) {
            emit Transfer(address(0), to, updatedIndex);
            require(
                _checkOnERC721Received(address(0), to, updatedIndex, _data),
                "ERC721A: transfer to non ERC721Receiver implementer"
            );
            updatedIndex++;
        }

        currentIndex = updatedIndex;
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            getApproved(tokenId) == _msgSender() ||
            isApprovedForAll(prevOwnership.addr, _msgSender()));

        require(
            isApprovedOrOwner,
            "ERC721A: transfer caller is not owner nor approved"
        );

        require(
            prevOwnership.addr == from,
            "ERC721A: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721A: transfer to the zero address");

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        _addressData[from].balance -= 1;
        _addressData[to].balance += 1;
        _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

        // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
        // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
        uint256 nextTokenId = tokenId + 1;
        if (_ownerships[nextTokenId].addr == address(0)) {
            if (_exists(nextTokenId)) {
                _ownerships[nextTokenId] = TokenOwnership(
                    prevOwnership.addr,
                    prevOwnership.startTimestamp
                );
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    uint256 public nextOwnerToExplicitlySet = 0;

    /**
     * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
     */
    function _setOwnersExplicit(uint256 quantity) internal {
        uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
        require(quantity > 0, "quantity must be nonzero");
        uint256 endIndex = oldNextOwnerToSet + quantity - 1;
        if (endIndex > collectionSize - 1) {
            endIndex = collectionSize - 1;
        }
        // We know if the last one in the group exists, all in the group exist, due to serial ordering.
        require(_exists(endIndex), "not enough minted yet for this cleanup");
        for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
            if (_ownerships[i].addr == address(0)) {
                TokenOwnership memory ownership = ownershipOf(i);
                _ownerships[i] = TokenOwnership(
                    ownership.addr,
                    ownership.startTimestamp
                );
            }
        }
        nextOwnerToExplicitlySet = endIndex + 1;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721A: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}