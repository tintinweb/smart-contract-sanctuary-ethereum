/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// File: https://github.com/yagizcolak/TLToken/blob/main/myTL_flat.sol


// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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

// File: contracts/myTL.sol


pragma solidity >=0.7.0 <0.9.0;


contract TLToken is ERC20 {

    constructor() ERC20("Turkish Lira", "TRY") {
        _mint(msg.sender, 10000*10**18);
    }

}

// File: contracts/MyLottery.sol



pragma solidity >=0.7.0 <0.9.0;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.6/contracts/token/ERC721/ERC721.sol";

// import "./myTL.sol";


contract MyLottery {

    uint private startTime;
  	TLToken TLContract;
  	uint32 constant PRICE = 10;
  	uint constant PERIOD = 1 weeks;

    mapping (address => uint256) public balances;

    struct Ticket {
      	address buyer;
        bytes32 randomNumberHash;
        bool isRevealed;
        bool isCollected;
    }

    struct Lottery {
        Ticket[] soldTickets;
        uint[] revealedTicketIndexes;
        mapping(address => uint[]) ticketList;
        uint currentRandom;
      	uint totalMoneyCollected;
    }

    mapping(uint => Lottery) public lotteries;

    constructor(address tokenContractAddress) {
        startTime = block.timestamp;
      	TLContract = TLToken(tokenContractAddress);
    }

    function getLotteryNo(uint unixtimeinweek) public pure returns (uint lottery_no) {
        lottery_no = unixtimeinweek / PERIOD;
        return lottery_no;
    }

    function buyTicket(bytes32 hash_rnd_number) public {
        uint currentLotteryNumber = (block.timestamp - startTime) / PERIOD;

        require(TLContract.transferFrom(msg.sender, address(this), PRICE), "Payment failed, please approve 10.00 TL.");

      	uint ticketNumber = lotteries[currentLotteryNumber].soldTickets.length;

      	lotteries[currentLotteryNumber].ticketList[msg.sender].push(ticketNumber); 

        Ticket memory newTicket = Ticket({
            buyer: msg.sender,
            randomNumberHash: hash_rnd_number,
        	  isRevealed: false,
        	  isCollected: false
        });

        lotteries[currentLotteryNumber].soldTickets.push(newTicket);

        lotteries[currentLotteryNumber].totalMoneyCollected += PRICE;
    }

    function revealRndNumber(uint ticket_no, uint rnd_number) public {

      	uint revealingLotteryNumber = (block.timestamp - startTime) / PERIOD - 1;
      	require(lotteries[revealingLotteryNumber].soldTickets.length > ticket_no , "This ticket does not exist.");  
      	require(lotteries[revealingLotteryNumber].soldTickets[ticket_no].isRevealed == false, "Already revealed!");
      	bytes32 hashed = keccak256(abi.encodePacked(rnd_number, msg.sender));
      	require(hashed == lotteries[revealingLotteryNumber].soldTickets[ticket_no].randomNumberHash, "Hash and rnd are not the same!");
      	lotteries[revealingLotteryNumber].currentRandom ^= rnd_number;
      	lotteries[revealingLotteryNumber].soldTickets[ticket_no].isRevealed = true;
      	lotteries[revealingLotteryNumber].revealedTicketIndexes.push(ticket_no); 
        return;
    }

    function getLastOwnedTicketNo(uint lottery_no) public view returns (uint) { 
      uint len = lotteries[lottery_no].ticketList[msg.sender].length; 
      return lotteries[lottery_no].ticketList[msg.sender][len - 1];  
    }

    function getIthOwnedTicketNo(uint i, uint lottery_no) public view returns (uint) {
      return lotteries[lottery_no].ticketList[msg.sender][i-1];
    }

    function getTotalLotteryMoneyCollected(uint lottery_no) public view returns (uint amount) {
        return lotteries[lottery_no].totalMoneyCollected;
    }

    function checkIfTicketWon(uint lottery_no, uint ticket_no) public view returns (uint amount) {
        uint currentLotteryNumber = (block.timestamp - startTime) / PERIOD;

        require(lottery_no < currentLotteryNumber-1, "This lottery has not yet concluded!");
      	require(lotteries[lottery_no].soldTickets[ticket_no].isRevealed, "Ticket isn't revealed yet!");

      	uint M = getTotalLotteryMoneyCollected(lottery_no);
      	uint P = 0;
      	uint howManyWinner = log_2(M); 

        amount = 0;
        bytes32 hash = keccak256(abi.encodePacked(lotteries[lottery_no].currentRandom)); 

        for(uint i=1; i <= howManyWinner; i++) {
            P = M % 2;
            M = M >> 1;   
            P = P + M; 
            bytes32 myHash = keccak256(abi.encodePacked(hash, i));
            uint idx = uint(myHash) % lotteries[lottery_no].revealedTicketIndexes.length;
            uint winningTicketNo = lotteries[lottery_no].revealedTicketIndexes[idx];

            if(winningTicketNo == ticket_no){
                amount = amount + P;
            }
            
        }
        return amount;
    }

    function getIthWinningTicket(uint i, uint lottery_no) public view returns (uint ticket_no, uint amount) {		
        uint currentLotteryNumber = (block.timestamp - startTime) / PERIOD;
        require(lottery_no < currentLotteryNumber-1, "This lottery has not yet concluded!");

      	uint M = getTotalLotteryMoneyCollected(lottery_no);
        uint P = 0;
      	uint howManyWinner = log_2(M);

      	require(i <= howManyWinner  , "Winner number is less than value.");
      	
      	amount = 0;
        bytes32 hash = keccak256(abi.encodePacked(lotteries[lottery_no].currentRandom)); 
        for(uint j=1; j <= i; j++) {
            P = M % 2;
            M = M >> 1;   
            P = P + M; 
            bytes32 myHash = keccak256(abi.encodePacked(hash, j)); 
            uint idx = uint(myHash) % lotteries[lottery_no].revealedTicketIndexes.length;
            uint winningTicketNo = lotteries[lottery_no].revealedTicketIndexes[idx];
            amount = P; 
            ticket_no = winningTicketNo;
        }
        return (ticket_no, amount);
    }

    // collect withdraw
    function collectTicketPrize(uint lottery_no, uint ticket_no) public {
        uint currentLotteryNumber = (block.timestamp - startTime) / PERIOD;
      	require(lottery_no <= currentLotteryNumber - 1, "This lottery has not yet concluded!");
      	require(lotteries[lottery_no].soldTickets.length > ticket_no, "There is no such ticket.");
        require(lotteries[lottery_no].soldTickets[ticket_no].isRevealed == true, "Ticket isn't revealed yet!");
      	require(lotteries[lottery_no].soldTickets[ticket_no].buyer == msg.sender, "This ticket does not belong to you.");
      	uint prize = checkIfTicketWon(lottery_no, ticket_no);
      	require(prize > 0, "There is no prize for this ticket.");
      	require(lotteries[lottery_no].soldTickets[ticket_no].isCollected == false, "You already collected your prize!");
        
        // require(TLContract.transfer(msg.sender, prize));
        balances[msg.sender] += prize;
      	lotteries[lottery_no].soldTickets[ticket_no].isCollected = true;
      	
      	return;
    }

    // collect withdraw
    function collectTicketRefund(uint lottery_no, uint ticket_no) public {
        uint currentLotteryNumber = (block.timestamp - startTime) / PERIOD;
        require(lottery_no <= currentLotteryNumber - 1, "This lottery has not yet concluded!");
        require(lotteries[lottery_no].soldTickets[ticket_no].buyer == msg.sender, "This ticket does not belong to you.");
        require(lotteries[lottery_no].soldTickets[ticket_no].isRevealed == false, "You can't get a refund, ticket is revealed!");
        uint prize = checkIfTicketWon(lottery_no, ticket_no);
      	require(prize == 0, "You can't get a refund, you won a prize!");
        
        balances[msg.sender] += PRICE/2; 
      	lotteries[lottery_no].soldTickets[ticket_no].isCollected = true;

    }

    function depositTL(uint amnt) public {
        require(TLContract.transferFrom(msg.sender, address(this), amnt), "Payment failed, make sure you have enough to deposit.");
        balances[msg.sender] += amnt;
    }

    function withdrawTL(uint amnt) public {
        require(balances[msg.sender] >= amnt, "You don't have enough balance for this!");
        require(TLContract.transfer(msg.sender, amnt));
        balances[msg.sender] -= amnt;
    }

    function myBalance() public view returns (uint256 balance) {
        return balances[msg.sender];
    }


    // The following function is directly from
    // https://ethereum.stackexchange.com/questions/8086/logarithm-math-operation-in-solidity to calculate log_2 efficiently
    function log_2(uint x) private pure returns (uint y) {
        assembly {
            let arg := x
            x := sub(x,1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
            mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
            mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
            mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
            mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
            mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
            mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
            mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
            mstore(0x40, add(m, 0x100))
            let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let shift := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m,sub(255,a))), shift)
            y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
        }  
    }

}