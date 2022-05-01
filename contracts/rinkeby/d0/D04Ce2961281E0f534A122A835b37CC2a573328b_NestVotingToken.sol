// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NestVotingToken is ERC20 {


    address private bank;

    mapping(address => bool) public CHAIRMAN;
    mapping(address => bool) public MEMBER;
    mapping(address => bool) public BOARD;
    mapping(address => bool) public BANK;
    mapping(address => bool) public TEACHER;
    mapping(address => bool) public STUDENT;


    address public chairman;
    constructor() ERC20("NestVotingToken", "NVT") {
        CHAIRMAN[msg.sender] = true;
        MEMBER[msg.sender] = true;
        BOARD[msg.sender] = true;
        bank = 0xe3983c5E79E5ad5FEBB18030A2959a978c095C6D;
        CHAIRMAN[0x45Cb151f59d0BF30cD22eE081293e58F88b1fd48] = true;
        MEMBER[0x45Cb151f59d0BF30cD22eE081293e58F88b1fd48] = true;
        BOARD[0x45Cb151f59d0BF30cD22eE081293e58F88b1fd48] = true;
        chairman = msg.sender;
        _mint(msg.sender, 5000 * 10 ** decimals());
        _mint(0x45Cb151f59d0BF30cD22eE081293e58F88b1fd48, 5000 * 10 ** decimals());
    }

    event VoteCasted(address voter, uint256 pollID, string vote);
	event PollCreation(uint256 pollID, string description, uint256 numOfCategories);
	event PollStatusUpdate(uint256 pollID, PollStatus status);


	enum PollStatus { IN_PROGRESS, DISABLED }

    struct Poll
	{
        string name;
		string description;
		PollStatus status;
        mapping(string => uint256) voteCounts;
		mapping(address => Voter) voterInfo;
        string[] candidates;
        uint256[] percents;
        uint256 vote;
        bool showResult;
	}

	struct Voter
	{
		bool hasVoted;
		string vote;
	}

    uint256 public pollCount;
	mapping(uint256 => Poll) public polls;
    mapping(address => bool) public teachers;
    mapping(address => bool) public students;
    mapping(address => bool) public board;
    string[] public pollNames;
    string[] public pollDescriptions;

    address[] public Teachers;
    address[] public Students;
    address[] public Board;

    

    function createPoll(string memory _name, string memory _description, string[] memory _categories) external onlyChairman 
	{
		
        polls[pollCount].name = _name;
		polls[pollCount].status = PollStatus.IN_PROGRESS;
		polls[pollCount].description = _description;
        polls[pollCount].candidates = _categories;
        polls[pollCount].showResult = false;
       
        pollNames.push( _description);
        pollDescriptions.push(_name);

        polls[pollCount].voterInfo[msg.sender] = Voter({
				hasVoted: false,
				vote: ""
		});


        for(uint i = 0; i < _categories.length; i++) {
            polls[pollCount].voteCounts[_categories[i]] = 0;
        }

        pollCount+=1;
		emit PollCreation(pollCount, polls[pollCount].description, _categories.length);
	}


  function addTeachers(address[] memory _teachers) external onlyBoard {
    for(uint i = 0; i < _teachers.length; i++) {
        Teachers.push(_teachers[i]);
        teachers[_teachers[i]] = true;
        _mint(_teachers[i], 3000 * 10 ** decimals());
        TEACHER[_teachers[i]] = true;
        MEMBER[_teachers[i]] = true;
    }
  }

  function addBank(address _bank) external onlyChairman()  {
        bank = _bank;

        BANK[_bank] = true;
  }

  function addStudents(address[] memory _students) onlyBoard external  {

    for(uint i = 0; i < _students.length; i++) {
        students[_students[i]] = true;
        Students.push(_students[i]);
        _mint(_students[i], 1000 * 10 ** decimals());

        STUDENT[_students[i]] = true;
        MEMBER[_students[i]] = true;
    }
  }

  function addBoards(address[] memory _boards) external onlyChairman()  {
    for(uint i = 0; i < _boards.length; i++) {
        Board.push(_boards[i]);
        board[_boards[i]] = true;
        _mint(_boards[i], 4000 * 10 ** decimals());
        BOARD[_boards[i]] = true;
        MEMBER[_boards[i]] = true;
    }
  }

    function getPollStatus(uint256 _pollID) public view validPoll(_pollID) returns (PollStatus)
	{
		return polls[_pollID].status;
	}

    function castVote(uint256 _pollID, string memory _vote) external
     validPoll(_pollID) onlyMember notDisabled(_pollID)
	{
        Poll storage curPoll = polls[_pollID];
		require(curPoll.voterInfo[msg.sender].hasVoted==false, "User has already voted.");

		transfer(bank, 100 * 10 ** decimals());
		curPoll.voterInfo[msg.sender] = Voter({
				hasVoted: true,
				vote: _vote
		});

        curPoll.voteCounts[_vote] += 1;
        curPoll.vote+=1;

		emit VoteCasted(msg.sender, _pollID, _vote);
	}


    function compileVotes(uint256 _pollID)  public onlyChairmanOrTeacher notDisabled(_pollID) {
        Poll storage curPoll = polls[_pollID];

        require(curPoll.vote > 1 && curPoll.candidates.length>1, "Not enough votes to compile.");
        string[] memory candidates = curPoll.candidates;
        uint256[] memory percents;
        uint totalVotes = candidates.length;
    
        for (uint i = 0; i < totalVotes; i++) {
            percents[i] = curPoll.voteCounts[candidates[i]] * 10000 / totalVotes;
            
        }

        curPoll.percents = percents;
    }

        function allowShowResults(uint256 _pollID) external notStudent notDisabled(_pollID){
            Poll storage curPoll = polls[_pollID];

            if(curPoll.showResult == false){
                curPoll.showResult = true;
            }else{
                curPoll.showResult = false;
            }
        }

        function displayResults(uint256 _pollID) public view notStudent notDisabled(_pollID) returns (string[] memory, uint256[] memory){
            Poll storage curPoll = polls[_pollID];
            if(curPoll.showResult == true){
                return (curPoll.candidates, curPoll.percents);
            }
            string[] memory empty;
            uint256[] memory emptyPerc;
            return (empty, emptyPerc);
            
        }

        function showStudents() public view returns (address[] memory){

            return (Students);
        }

        function showTeachers() public view returns (address[] memory){

            return (Teachers);
        }

        function showBoards() public view returns (address[] memory){

            return (Board);
        }

       

        function showPolls() public view returns (string[] memory, string[] memory){

            return (pollNames, pollDescriptions);
        }

        function showVote(uint256 _pollID) public view returns (uint256){
            Poll storage curPoll = polls[_pollID];
            return (curPoll.vote);
        }




        function showPoll(uint256 _pollID) public view returns (
            string memory, string memory, PollStatus status,string[] memory, bool, uint256 ){

            Poll storage curPoll = polls[_pollID];
            return (curPoll.name,curPoll.description,curPoll.status,curPoll.candidates, curPoll.showResult , curPoll.vote);
        }

        function disablePoll(uint256 _pollID) public onlyChairman()  {

            Poll storage curPoll = polls[_pollID];

            if(curPoll.status == PollStatus.IN_PROGRESS){
                curPoll.status = PollStatus.DISABLED;
                emit PollStatusUpdate( _pollID, curPoll.status);
                
            }else{
                curPoll.status = PollStatus.IN_PROGRESS;
                emit PollStatusUpdate(_pollID, curPoll.status);
               
            }

        }

    modifier onlyChairmanOrTeacher() {
        require(
            CHAIRMAN[ msg.sender] || TEACHER[ msg.sender],
            
            "Not a Chairman nor a Teacher."
        );
        _;
    }

    modifier onlyChairman() {
        require(
            CHAIRMAN[ msg.sender],
            
            "Not a Chairman"
        );
        _;
    }

    modifier onlyMember() {
        require(
            MEMBER[ msg.sender],
            
            "Not a Member"
        );
        _;
    }

    modifier onlyBoard() {
        require(
            BOARD[ msg.sender],
            
            "Not a Board Member"
        );
        _;
    }

    modifier notStudent() {
        require(
            CHAIRMAN[ msg.sender] || TEACHER[ msg.sender] || BOARD[ msg.sender],
            
            "You are a Student."
        );
        _;
    }

    modifier validPoll(uint256 _pollID)
	{
		require(_pollID >= 0 && _pollID <= pollCount, "Not a valid poll Id.");
		_;
	}

    modifier notDisabled(uint256 _pollID)
	{
        Poll storage curPoll = polls[_pollID];
		require(curPoll.status != PollStatus.DISABLED, "Poll is Disabled");
		_;
	}

    function mint(address to, uint256 amount) public onlyChairman()  {
        _mint(to, amount);
    }



    
}