/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

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



// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    /** 
     * Transfers _value amount of token to address _to and MUST emit the Transfer event. 
     * The balance of msg.sender will be deducted by _value + _fee. Add _value amount to the balance of the receiver.
     */
    function transferExactDest(address _to, uint _value) external returns (bool success);

    /**
     * Transfers _value amount of token to address _to and MUST fire the Transfer event. The balance of _from will be deducted by _value + _fee. 
     */
    function transferExactDestFrom(address _from, address _to, uint _value) external returns (bool success);

    /**
     * A query function that returns the amount of tokens a receiver will get if a sender sends _sentAmount tokens.
     */
    function getReceivedAmount(uint _sentAmount) external view returns (uint receivedAmount, uint feeAmount);

    /**
     * Returns the amount of tokens the sender has to send if he wants the receiver to receive exactly _receivedAmount tokens.
     */
    function getSendAmount(uint _receivedAmount) external view returns (uint sendAmount, uint feeAmount);

    /**
     * Returns the amount of tokens that are in the account as a balance, minus the fee if you want to send the total amount.
     */
    function balanceOfWithoutFee(address account) external view returns (uint256);
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

// Was edited manually by me, is no longer a standard.

pragma solidity ^0.8.0;



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
contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;




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
    

    // Transfers _value amount of token to address _to and MUST emit the Transfer event. 
    // The balance of msg.sender will be deducted by _value + _fee. Add _value amount to the balance of the receiver.
    function transferExactDest(address _to, uint _value) public virtual override returns (bool success) {
        if(_value < 500000 * 1000000000000000000) {
            uint fee = _value/100; // for 1% fee
        address owner = _msgSender();
        _transfer(owner, _to, _value);
        _burn(owner, fee);
        } else if(_value < 10000000 * 1000000000000000000) {
            uint fee = _value/1000; // for 0,1% fee
        address owner = _msgSender();
        _transfer(owner, _to, _value);
        _burn(owner, fee);
        } else {
            uint fee = _value/2000; // for 0,05% fee
        address owner = _msgSender();
        _transfer(owner, _to, _value);
        _burn(owner, fee);
        }
        return true;
    }

    // Transfers _value amount of token to address _to and MUST fire the Transfer event. The balance of _from will be deducted by _value + _fee. 
    function transferExactDestFrom(address _from, address _to, uint _value) public virtual override returns (bool success) {
        address spender = _msgSender();
        if(_value < 100000 * 1000000000000000000) {
            uint fee = _value/100; // for 1% fee
        _spendAllowance(_from, spender, _value);
        _transfer(_from, _to, _value);
        _burn(_from, fee);
        } else if(_value < 1000000 * 1000000000000000000) {
            uint fee = _value/1000; // for 0,1% fee
        _spendAllowance(_from, spender, _value);
        _transfer(_from, _to, _value);
        _burn(_from, fee);
        } else {
            uint fee = _value/2000; // for 0,05% fee
        _spendAllowance(_from, spender, _value);
        _transfer(_from, _to, _value);
        _burn(_from, fee);
        }
        return true;
    }

    // A query function that returns the amount of tokens a receiver will get if a sender sends _sentAmount tokens. 
    function getReceivedAmount(uint _sentAmount) public virtual override view returns (uint receivedAmount, uint feeAmount) {
        uint i = _sentAmount;
        uint fee;
        if(i < 100000 * 1000000000000000000) {
            fee = i/100; // for 1% fee
        } else if(i < 1000000 * 1000000000000000000) {
            fee = i/1000; // for 0,1% fee
        } else {
            fee = i/2000; // for 0,05% fee
        }

        return (i-fee, fee);
    }

    // Returns the amount of tokens the sender has to send if he wants the receiver to receive exactly _receivedAmount tokens.
    function getSendAmount(uint _receivedAmount) public virtual override view returns (uint sendAmount, uint feeAmount) {
        uint i = _receivedAmount;
        uint fee;
        if(i < 100000 * 1000000000000000000) {
            fee = i/100; // for 1% fee
        } else if(i < 1000000 * 1000000000000000000) {
            fee = i/1000; // for 0,1% fee
        } else {
            fee = i/2000; // for 0,05% fee
        }

        return (i+fee, fee);
    }

    // Returns the amount of tokens that are in the account as a balance, minus the fee if you want to send the total amount.
    function balanceOfWithoutFee(address account) public view virtual override returns (uint256) {
        uint i = _balances[account];
        uint fee;
        if(i < 100000 * 1000000000000000000) {
            fee = i/100; // for 1% fee
        } else if(i < 1000000 * 1000000000000000000) {
            fee = i/1000; // for 0,1% fee
        } else {
            fee = i/2000; // for 0,05% fee
        }
        return i - fee;
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
    ) internal virtual{
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

pragma solidity ^0.8.0;



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

contract Lottery is Ownable, ERC20 {

    address RHTaddress = 0xd9145CCE52D386f254917e481eB44e9943F39138;
    IERC20 public RHT = ERC20(address(RHTaddress));
    address[] private allplayers;
    mapping (uint => Gamblestats) public Gamble;
    mapping (uint => GameOneStats) GambleOne;

    uint numRequests;
    uint rdnmod;

    constructor() {
        allplayers.push(_msgSender());
    }

    struct Gamblestats {
        address creator;
        address[] ticket;
        bool complete;
        uint stake;
        uint tickets;
        uint game;
    }

    struct GameOneStats {
        uint w1;
        uint w2;
        uint w3;
        uint w4;
        uint w5;
        uint g1;
        uint g2;
        uint g3;
        uint g4;
        uint g5;
    }

    function createGamble(uint stake, uint game) public {
        Gamblestats storage g = Gamble[numRequests++];
           g.complete = false;
           g.stake = stake;
           g.tickets = 0;   
           g.game = game;
           g.creator = _msgSender();
    }

    function _safeTransfer(
        IERC20 token,
        address to,
        uint amount
    ) private {
        bool sent = token.transfer(to, amount);
        require(sent, "Token transfer failed");
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp + rdnmod, rdnmod)));
    }

    function buyticket(uint gamenr, uint amount) public {
        addPlayer();
        Gamblestats storage g = Gamble[gamenr];
        require(g.game != 0);
        g.tickets += amount; 
        for (uint i = 0; i < amount; i++) {
             g.ticket.push(_msgSender());
        }  
        require(balanceOf(_msgSender()) >= g.stake*amount);
        _burn(_msgSender(), g.stake*amount);
    }

    function showTicket(uint gamenr) public view returns(address[] memory){
        Gamblestats storage g = Gamble[gamenr];
        return g.ticket;
    }

    function showlist1() public view returns(uint[] memory){
        return list1;
    }

    function payloadaccount(uint amount) public {
        uint256 allowance = RHT.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        RHT.transferFrom(msg.sender, address(this), amount);
        _mint(_msgSender(), amount);
    }

    function addPlayer() private {
        address player = _msgSender();
        bool inlist = false;
        for (uint i = 0; i < allplayers.length; i++) {
            if(player == allplayers[i]) inlist = true;
        }
        if(inlist == false) allplayers.push(_msgSender());
    }

uint[] public list1;

    function GameOne(uint gamenr) public {
        Gamblestats storage g = Gamble[gamenr];
        GameOneStats storage go = GambleOne[gamenr];
        require(g.game == 1);
        require(g.tickets >= 1);
        uint pool = (g.tickets*g.stake)-((g.tickets*g.stake)/100);
        uint winners = g.tickets/2;
        go.w1 = winners*75/100;
        go.w2 = winners*17/100;
        go.w3 = winners*5/100;
        go.w4 = winners*25/1000;
        go.w5 = winners*5/1000;
        go.g1 = (pool*45/100)/go.w1;
        go.g2 = (pool*16/100)/go.w2;
        go.g3 = (pool*10/100)/go.w3;
        go.g4 = (pool*10/100)/go.w4;
        go.g5 = (pool*15/100)/go.w5;
        winners = go.w1+go.w2+go.w3+go.w4+go.w5;
        uint[] memory clean;
        list1 = clean;
        for (uint i = 0; i < winners; i++) {
            uint winner =  pick(g.tickets);
            list1.push(winner);
        }
        
        g.complete=true;
    }

    function transferwingameone(uint gamenr) public {
        GameOneStats storage go = GambleOne[gamenr];
        for (uint i = 0; i < list1.length; i++) {
            Gamblestats storage g = Gamble[gamenr];
            address winner = g.ticket[list1[i]];
            if(i < go.w1) _mint(winner, go.g1);
            else if(i < go.w1 + go.w2) _mint(winner, go.g2);
            else if(i < go.w1 + go.w2 + go.w3) _mint(winner, go.g3);
            else if(i < go.w1 + go.w2 + go.w3 + go.w4) _mint(winner, go.g4);
            else _mint(winner, go.g5);
        }
    }

    function pick(uint x) private view returns(uint) {
        uint i = (random() % x) + 1;
        return i;
    }

    function pick2(uint x) public {
        uint[] memory clear;
        list1=clear;
        rdnmod=0;
        for (uint i = 0; i < x; i++) {
            uint winner =  pick(x);
            rdnmod++;
            list1.push(winner);
    }
    }

    function safepick(uint gamenr, uint[] storage list) private returns (uint) {
        Gamblestats storage g = Gamble[gamenr];
        uint winner = pick(g.tickets);
        bool inlist = false;
        rdnmod = 0;
        if(list.length != 0) {
            for (uint i = 0; i < list.length; i++) {
            if(winner == list[i]) inlist = true;
            }
        }
        if(inlist == false){
            rdnmod++;
            return winner;
        } else return 0;
    }

    function safepicktest() public returns (uint) {
        uint winner = random() % 400;
        rdnmod++;
        list1.push(winner);
        return winner;
        
    }

    function balanceInPool() public view returns (uint) {
        return RHT.balanceOf(address(this));
    }

    function expand(uint256 n) public view returns (uint256[] memory expandedValues) {
    expandedValues = new uint256[](n);
    for (uint256 i = 0; i < n; i++) {
        expandedValues[i] = uint256(keccak256(abi.encode(block.difficulty, block.timestamp + i, i)))%n;
    }
    return expandedValues;
    }

}