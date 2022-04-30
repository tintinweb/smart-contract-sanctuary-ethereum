//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Voting.sol";
import "./Token.sol";

contract ManageVoting {
    Voting voting;
    Token token;

    address public owner;
    string[] public nameElections;
    bool isControlledVoting;

    //sets owner,
    //owner added as a stakeholder
    constructor(address _address, address _token) {
        token = Token(_token);
        voting = Voting(_address);
        owner = msg.sender;
    }

    uint256 private electionsCount = 0;
    //EVENTS
    event CreateElection(address sender, string _electionName);
    event AddCandidate(address sender, string _electionName, string _name);
    event Vote(address sender, string _electionName, uint256 _candidateID);
    event ChangeVoteStatus(address sender, string _electionName);
    event EnableVoting(address sender);
    event StopVoting(address sender);

    event AddStakeholder(address sender);
    event AddBod(address sender);
    event AddStaff(address sender);
    event RemoveStakeholderRole(address sender);

    //MAPPING
    mapping(string => Voting) public elections;
    mapping(address => bool) public stakeholders;
    mapping(address => bool) public staff;
    mapping(address => bool) public bod;
    mapping(address => bool) public student;

    //MODIFIERS
    modifier onlyChairman() {
        require(msg.sender == owner, "Chairman only access");
        _;
    }

    modifier staffOnly() {
        uint256 balance = token.balanceOf(msg.sender);
        require(balance > 99, "You are not a staff");
        _;
    }

    modifier bodOnly() {
        uint256 balance = token.balanceOf(msg.sender);
        require(balance > 199, "You are not a BOD");
        _;
    }

    modifier stakeholderOnly() {
        require(stakeholders[msg.sender], "You are not a stakeholder");
        _;
    }

    //FUNCTIONS
    function transferChairmanRole(address _adr) public onlyChairman {
        owner = _adr;
    }

    function enableVoting(string memory _electionName) public onlyChairman {
        elections[_electionName].enableVoting();
        emit EnableVoting(msg.sender);
    }

    function disableVoting(string memory _electionName) public onlyChairman {
        elections[_electionName].disableVoting();
        emit StopVoting(msg.sender);
    }

    function allowResultCompile(string memory _electionName)
        public
        onlyChairman
    {
        elections[_electionName].allowResult();
        emit ChangeVoteStatus(msg.sender, _electionName);
    }

    //add stakeholder
    function setStakeholders(address _adr) public staffOnly returns (bool) {
        return stakeholders[_adr] = true;
    }

    //Create new instance of the voting contract
    //only chairman can create election
    function createElection(string memory _electionName, string memory category)
        public
        onlyChairman
        returns (bool)
    {
        Voting myVote = new Voting();
        elections[_electionName] = myVote;
        elections[_electionName].setVotingAccess(category);
        //increment the number of elections added
        electionsCount++;
        nameElections.push(_electionName);
        emit CreateElection(msg.sender, _electionName);
        return true;
    }

    //add candidate
    function addCandidate(
        string memory _electionName,
        string memory _name,
        string memory _img
    ) public onlyChairman returns (bool) {
        elections[_electionName].addCandidate(_name, _img);
        emit AddCandidate(msg.sender, _electionName, _name);
        return true;
    }

    //stakeholders only vote
    function vote(string memory _electionName, uint256 _candidateID)
        public
        returns (bool)
    {
        require(stakeholders[msg.sender], "You are not a stakeholder");

        string memory va = elections[_electionName].getVotingAccess();

        if (keccak256(bytes(va)) == keccak256(bytes("bod"))) {
            uint256 balance = token.balanceOf(msg.sender);
            require(
                balance > 199 * 10**18,
                "You are not a member of the board of directors"
            );
        }

        if (keccak256(bytes(va)) == keccak256(bytes("staff"))) {
            uint256 balance = token.balanceOf(msg.sender);
            require(
                balance > 99 * 10**18,
                "You are not a member of the staffs"
            );
        }

        if (keccak256(bytes(va)) == keccak256(bytes("student"))) {
            uint256 balance = token.balanceOf(msg.sender);
            require(balance < 99 * 10**18, "You are not a member of student");
        }

        elections[_electionName].vote(_candidateID);
        emit Vote(msg.sender, _electionName, _candidateID);
        return true;
    }

    //get list of all election
    function getAllElection() public view returns (string[] memory) {
        return nameElections;
    }

    //get list of all candidate for election name argument
    function getAllCandidate(string memory _electionName)
        public
        view
        returns (
            string[] memory,
            uint256[] memory,
            string[] memory
        )
    {
        return elections[_electionName].getAllCandidates();
    }

    //get result of an election name argument
    function getResults(string memory _electionName)
        public
        view
        returns (string[] memory, uint256[] memory)
    {
        return elections[_electionName].compileResult();
    }

    function giveStaffRole(address _adr) public onlyChairman {
        token.transfer(_adr, 100 * 10**18);
        stakeholders[_adr] = true;
        staff[_adr] = true;
        emit AddStaff(_adr);
    }

    function giveBodRole(address _adr) public onlyChairman {
        token.transfer(_adr, 200 * 10**18);
        stakeholders[_adr] = true;
        bod[_adr] = true;
        emit AddBod(_adr);
    }

    function giveStakeholderRole(address _adr) public onlyChairman {
        token.transfer(_adr, 10 * 10**18);
        stakeholders[_adr] = true;
        emit AddStakeholder(_adr);
    }

    function removeStakeholderRole(address _adr) public onlyChairman {
        stakeholders[_adr] = false;
        emit RemoveStakeholderRole(_adr);
    }
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

contract Voting {
    //counter for every candidate; will form the id in the mapping
    uint256 candidateCount = 0;

    //the state of the voting
    enum VotingStatus {
        ready,
        ongoing,
        ended,
        result
    }

    VotingStatus public status;

    string public votingAccess;

    constructor() {
        status = VotingStatus.ready;
    }

    //EVENTS
    //events for voting and add candidate
    event AddCandidate(string name);

    //event for voting, takes in candidate ID
    event Voted(uint256 id);

    //candidates information
    struct Candidate {
        uint256 id;
        string name;
        uint256 vote;
        string imgUrl;
    }

    //MAPPING
    //maps all candidate
    mapping(uint256 => Candidate) allCandidates;

    //maps address of all stakeholder that vote
    mapping(address => bool) allVoters;

    //maps for every  name
    mapping(string => bool) candidateNames;

    //MODIFIERS

    //checks for who can vote
    //user can only vote once
    //Voting must be enabled
    modifier canVote() {
        require(!allVoters[msg.sender], "You can vote only once");
        require(candidateCount > 0, "No candidate added");
        require(status == VotingStatus.ongoing, "Voting closed");
        _;
    }

    //which candidate is eligible
    modifier eligibleCandidate(string memory _name) {
        //a name can only be registered once
        require(!candidateNames[_name], "Name already exists");
        _;
    }

    //addCandidate function
    //only the chairman can add a candidate
    function addCandidate(string memory _name, string memory _imgUrl)
        external
        eligibleCandidate(_name)
    {
        //create a new struct candidate
        //mapping the candidatecount as ID to the dandidate data
        allCandidates[candidateCount] = Candidate(
            candidateCount,
            _name,
            0,
            _imgUrl
        );
        //increment the count each time a candidate is added
        candidateCount++;

        //sets users added
        candidateNames[_name] = true;

        //event
        emit AddCandidate(_name);
    }

    function setVotingAccess(string memory _name) public {
        votingAccess = _name;
    }

    function getVotingAccess() public view returns (string memory) {
        return votingAccess;
    }

    //Voting function
    //takes the candidate of choices ID as argument
    function vote(uint256 _candidateID) external canVote returns (bool) {
        //increment the candidates vote by 1
        allCandidates[_candidateID].vote = allCandidates[_candidateID].vote + 1;

        //mark the voter as having voted
        allVoters[msg.sender] = true;

        //emit the event
        emit Voted(_candidateID);
        return true;
    }

    //get all candidate
    function getAllCandidates()
        external
        view
        returns (
            string[] memory,
            uint256[] memory,
            string[] memory
        )
    {
        //names and ids to be returned
        string[] memory names = new string[](candidateCount);
        uint256[] memory ids = new uint256[](candidateCount);
        string[] memory imgUrl = new string[](candidateCount);

        //iterate all the candidates
        //assign to the array at an index of their ID
        for (uint256 i = 0; i < candidateCount; i++) {
            Candidate storage candi = allCandidates[i];
            names[i] = candi.name;
            ids[i] = candi.id;
            imgUrl[i] = candi.imgUrl;
        }
        // return the arrays
        return (names, ids, imgUrl);
    }

    //getting results of vote
    function compileResult()
        external
        view
        returns (string[] memory, uint256[] memory)
    {
        //result can only be seen if status is "result"
        require(status == VotingStatus.result, "You can't view result yet");
        // array variables for names and vote of candidates
        string[] memory names = new string[](candidateCount);
        uint256[] memory votes = new uint256[](candidateCount);

        //iterate fot the candidates and votes
        for (uint256 i = 0; i < candidateCount; i++) {
            //stores data in a struct variable
            Candidate storage candi = allCandidates[i];
            names[i] = candi.name;
            votes[i] = candi.vote;
        }
        //return names and votes
        return (names, votes);
    }

    //enable voting function
    function enableVoting() public {
        status = VotingStatus.ongoing;
    }

    // disableVoting function
    function disableVoting() public {
        status = VotingStatus.ended;
    }

    //allowing for compile result
    function allowResult() public {
        status = VotingStatus.result;
    }

    //get election status
    function getVotingStatus() public view returns (VotingStatus) {
        return status;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
    uint256 public _totalSupply;
    address private payC;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    // Constrctor function

    constructor() ERC20("VoteToken", "VT") {
        _totalSupply = 1000000 * 10**18;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function mint(address _to, uint256 _value) external onlyOwner {
        _mint(_to, _value);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner)
        public
        view
        override
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint256 tokens)
        public
        override
        returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint256 tokens)
        public
        override
        returns (bool success)
    {
        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public override returns (bool success) {
        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
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