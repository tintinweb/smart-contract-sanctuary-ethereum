pragma solidity >=0.6.0 <0.8.0;

import "./IExerciceSolution.sol";
import "./ERC20Claimable.sol";
import "./Evaluator.sol";
import "./ExerciceSolutionToken.sol";

contract ExerciceSolution is IExerciceSolution{

    address public owner;
    mapping(address => uint256) public balance;
    ERC20Claimable claimableERC20;
    Evaluator evaluator;
    ExerciceSolutionToken ecst;

    constructor(Evaluator eval, ERC20Claimable claimableERC20Address) public {
        owner = msg.sender;
        evaluator = eval;
        claimableERC20 = claimableERC20Address;
    }

    function claimTokensOnBehalf() external override{
        uint256 claimedTokens = claimableERC20.claimTokens();
		balance[msg.sender] += claimedTokens;

    }

	function tokensInCustody(address callerAddress) external override returns (uint256){
        return balance[callerAddress];
    }

	function withdrawTokens(uint256 amountToWithdraw) external override returns (uint256)
	{
        require(balance[msg.sender] >= amountToWithdraw, "Not enough tokens in custody");
		balance[msg.sender] -= amountToWithdraw;
		claimableERC20.transfer(msg.sender, amountToWithdraw);
	}

	function getERC20DepositAddress() external override returns (address){
        return address(ecst);
    }

    function depositTokens(uint256 amountToWithdraw) external override returns (uint256){
        claimableERC20.transferFrom(msg.sender, address(this), amountToWithdraw);
        balance[msg.sender] += amountToWithdraw;
        return balance[msg.sender];
    }
    function setExerciceSolutionToken(ExerciceSolutionToken ecstAddress) public{
        require(msg.sender == owner, "Only owner can set ERC20 token");
        ecst = ecstAddress;
    }

    fallback () external payable 
	{}

	receive () external payable 
	{}


}

pragma solidity ^0.6.0;

interface IExerciceSolution 
{

	function claimTokensOnBehalf() external;

	function tokensInCustody(address callerAddress) external returns (uint256);

	function withdrawTokens(uint256 amountToWithdraw) external returns (uint256); 

	function depositTokens(uint256 amountToWithdraw) external returns (uint256); 

	function getERC20DepositAddress() external returns (address);
}

pragma solidity ^0.6.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Mintable is IERC20 
{

	function setMinter(address minterAddress, bool isMinter)  external;

	function mint(address toAddress, uint256 amount)  external;

	function isMinter(address minterAddress) external returns (bool);
}

pragma solidity >=0.6.0 <0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IERC20Mintable.sol";


contract ExerciceSolutionToken is ERC20, IERC20Mintable{

    mapping(address => bool) private _minters;

    constructor(address solution) public ERC20("ExerciceSolutionToken", "ECST") {
        _minters[msg.sender] = true;
        _minters[solution] = true;
    }

    function setMinter(address minterAddress, bool isMinter)  external override {
        _minters[minterAddress] = isMinter;
    }

	function mint(address toAddress, uint256 amount) external override {
        require(_minters[msg.sender], "Only minter can mint");
        _mint(toAddress, amount);
    }

	function isMinter(address minterAddress) external override returns (bool){
        return _minters[minterAddress];
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./ERC20TD.sol";
import "./ERC20Claimable.sol";
import "./IExerciceSolution.sol";
import "./IERC20Mintable.sol";

contract Evaluator 
{

	mapping(address => bool) public teachers;
	ERC20TD TDERC20;
	ERC20Claimable claimableERC20;

	uint256[20] private randomSupplies;
	string[20] private randomTickers;
 	uint public nextValueStoreRank;


 	mapping(address => mapping(uint256 => bool)) public exerciceProgression;
 	mapping(address => IExerciceSolution) public studentExerciceSolution;
 	mapping(address => bool) public hasBeenPaired;

 	event newRandomTickerAndSupply(string ticker, uint256 supply);
 	event constructedCorrectly(address erc20Address, address claimableERC20Address);
	constructor(ERC20TD _TDERC20, ERC20Claimable _claimableERC20) 
	public 
	{
		TDERC20 = _TDERC20;
		claimableERC20 = _claimableERC20;
		emit constructedCorrectly(address(TDERC20), address(claimableERC20));
	}

	fallback () external payable 
	{}

	receive () external payable 
	{}

	function ex1_claimedPoints()
	public
	{
		// Check the user has some tokens
		require(claimableERC20.balanceOf(msg.sender) > 0, "Sender has no tokens");

		// Crediting points
		if (!exerciceProgression[msg.sender][1])
		{
			exerciceProgression[msg.sender][1] = true;
			TDERC20.distributeTokens(msg.sender, 1);
			TDERC20.distributeTokens(msg.sender, 1);
			TDERC20.distributeTokens(msg.sender, 1);
			TDERC20.distributeTokens(msg.sender, 2);
		}
	}

	function ex2_claimedFromContract()
	public
	{
		// Checking a solution was submitted
		require(exerciceProgression[msg.sender][0], "No solution submitted");

		// Checking how many tokens ExerciceSolution holds
		uint256 solutionInitBalance = claimableERC20.balanceOf(address(studentExerciceSolution[msg.sender]));

		// Claiming tokens through ExerciceSolution
		studentExerciceSolution[msg.sender].claimTokensOnBehalf();

		// Verifying ExerciceSolution holds tokens
		uint256 solutionEndBalance = claimableERC20.balanceOf(address(studentExerciceSolution[msg.sender]));
		require(solutionEndBalance - solutionInitBalance == claimableERC20.distributedAmount(), "No claimable tokens minted to ExerciceSolution");

		// Verifying ExerciceSolution kept track of our balance
		studentExerciceSolution[msg.sender].claimTokensOnBehalf();
		require(studentExerciceSolution[msg.sender].tokensInCustody(address(this)) == 2*claimableERC20.distributedAmount(), "Balance of sender not kept in ExerciceSolution");


		// Crediting points
		if (!exerciceProgression[msg.sender][2])
		{
			exerciceProgression[msg.sender][2] = true;
			TDERC20.distributeTokens(msg.sender, 2);
		}
	}

	function ex3_withdrawFromContract()
	public
	{
		// Checking a solution was submitted
		require(exerciceProgression[msg.sender][0], "No solution submitted");

		// Checking how many tokens ExerciceSolution and Evaluator hold
		uint256 solutionInitBalance = claimableERC20.balanceOf(address(studentExerciceSolution[msg.sender]));
		uint256 selfInitBalance = claimableERC20.balanceOf(address(this));
		uint256 amountToWithdraw = studentExerciceSolution[msg.sender].tokensInCustody(address(this));

		// Withdraw tokens through ExerciceSolution
		studentExerciceSolution[msg.sender].withdrawTokens(amountToWithdraw);

		// Verifying tokens where withdrew correctly
		uint256 solutionEndBalance = claimableERC20.balanceOf(address(studentExerciceSolution[msg.sender]));
		uint256 selfEndBalance = claimableERC20.balanceOf(address(this));
		uint256 amountLeft = studentExerciceSolution[msg.sender].tokensInCustody(address(this));

		require(solutionInitBalance - solutionEndBalance== amountToWithdraw, "ExerciceSolution has an incorrect amount of tokens");
		require(selfEndBalance - selfInitBalance == amountToWithdraw, "Evaluator has an incorrect amount of tokens");
		require(amountLeft == 0, "Tokens left held by ExerciceSolution");

		// Crediting points
		if (!exerciceProgression[msg.sender][3])
		{
			exerciceProgression[msg.sender][3] = true;
			TDERC20.distributeTokens(msg.sender, 2);
		}
	}

	function ex4_approvedExerciceSolution()
	public
	{
		// Checking a solution was submitted
		require(exerciceProgression[msg.sender][0], "No solution submitted");

		require(claimableERC20.allowance(msg.sender, address(studentExerciceSolution[msg.sender])) > 0,  "ExerciceSolution no allowed to spend msg.sender tokens");

		// Crediting points
		if (!exerciceProgression[msg.sender][4])
		{
			exerciceProgression[msg.sender][4] = true;
			TDERC20.distributeTokens(msg.sender, 1);
		}
	}

	function ex5_revokedExerciceSolution()
	public
	{
		// Checking a solution was submitted
		require(exerciceProgression[msg.sender][0], "No solution submitted");

		require(claimableERC20.allowance(msg.sender, address(studentExerciceSolution[msg.sender])) == 0, "ExerciceSolution still allowed to spend msg.sender tokens");

		// Crediting points
		if (!exerciceProgression[msg.sender][5])
		{
			exerciceProgression[msg.sender][5] = true;
			TDERC20.distributeTokens(msg.sender, 1);
		}
	}

	function ex6_depositTokens()
	public
	{
		// Checking a solution was submitted
		require(exerciceProgression[msg.sender][0], "No solution submitted");

		uint256 amountToDeposit = 100;

		// Checking how many tokens ExerciceSolution and Evaluator hold
		uint256 solutionInitBalance = claimableERC20.balanceOf(address(studentExerciceSolution[msg.sender]));
		uint256 selfInitBalance = claimableERC20.balanceOf(address(this));
		uint256 amountDeposited = studentExerciceSolution[msg.sender].tokensInCustody(address(this));
		require(selfInitBalance>= amountToDeposit, "Evaluator does not hold enough tokens");

		// Approve student solution to manipulate our tokens
		claimableERC20.increaseAllowance(address(studentExerciceSolution[msg.sender]), amountToDeposit);

		// Deposit tokens in student contract
		studentExerciceSolution[msg.sender].depositTokens(amountToDeposit);

		// Check balances are correct
		uint256 solutionEndBalance = claimableERC20.balanceOf(address(studentExerciceSolution[msg.sender]));
		uint256 selfEndBalance = claimableERC20.balanceOf(address(this));
		uint256 amountLeft = studentExerciceSolution[msg.sender].tokensInCustody(address(this));

		require(solutionEndBalance - solutionInitBalance == amountToDeposit, "ExerciceSolution has an incorrect amount of tokens");
		require(selfInitBalance - selfEndBalance == amountToDeposit, "Evaluator has an incorrect amount of tokens");
		require(amountLeft - amountDeposited == amountToDeposit, "Balance of Evaluator not credited correctly in ExerciceSolution");


		// Crediting points
		if (!exerciceProgression[msg.sender][6])
		{
			exerciceProgression[msg.sender][6] = true;
			TDERC20.distributeTokens(msg.sender, 2);
		}
	}

	function ex7_createERC20()
	public
	{
		// Checking a solution was submitted
		require(exerciceProgression[msg.sender][0], "No solution submitted");

		// Get ExerciceSolutionERC20 address
		address exerciceSolutionERC20 = studentExerciceSolution[msg.sender].getERC20DepositAddress();
		IERC20Mintable ExerciceSolutionERC20 = IERC20Mintable(exerciceSolutionERC20);

		// Check that ExerciceSolution is a minter to ExerciceSolutionERC20
		// Check that we are not a minter to ExerciceSolutionERC20
		require(ExerciceSolutionERC20.isMinter(address(studentExerciceSolution[msg.sender])), "ExerciceSolution is not minter");
		require(!ExerciceSolutionERC20.isMinter(address(this)), "Evaluator is minter");

		// Check that we can not mint ExerciceSolutionERC20 tokens 
		bool wasMintAccepted = false;
		try ExerciceSolutionERC20.mint(address(this), 10000)
		{
			wasMintAccepted = true;
        } 
        catch 
        {
            // This is executed in case revert() was used.
            wasMintAccepted = false;
        }

        require(!wasMintAccepted, "Evaluator was able to mint");

		// Crediting points
		if (!exerciceProgression[msg.sender][7])
		{
			exerciceProgression[msg.sender][7] = true;
			TDERC20.distributeTokens(msg.sender, 2);
		}
	}

	function ex8_depositAndMint()
	public
	{
		// Checking a solution was submitted
		require(exerciceProgression[msg.sender][0], "No solution submitted");

		uint256 amountToDeposit = 100;

		// Checking how many tokens ExerciceSolution and Evaluator hold
		uint256 solutionInitBalance = claimableERC20.balanceOf(address(studentExerciceSolution[msg.sender]));
		uint256 selfInitBalance = claimableERC20.balanceOf(address(this));
		address exerciceSolutionERC20 = studentExerciceSolution[msg.sender].getERC20DepositAddress();
		IERC20Mintable ExerciceSolutionERC20 = IERC20Mintable(exerciceSolutionERC20);
		uint256 amountDeposited = ExerciceSolutionERC20.balanceOf(address(this));
		uint256 initWrappedTotalSupply = ExerciceSolutionERC20.totalSupply();
		require(selfInitBalance>= amountToDeposit, "Evaluator does not hold enough tokens");

		// Approve student solution to manipulate our tokens
		claimableERC20.increaseAllowance(address(studentExerciceSolution[msg.sender]), amountToDeposit);

		// Deposit tokens in student contract
		studentExerciceSolution[msg.sender].depositTokens(amountToDeposit);

		// Check balances are correct
		uint256 solutionEndBalance = claimableERC20.balanceOf(address(studentExerciceSolution[msg.sender]));
		uint256 selfEndBalance = claimableERC20.balanceOf(address(this));
		uint256 amountLeft = ExerciceSolutionERC20.balanceOf(address(this));
		uint256 endWrappedTotalSupply = ExerciceSolutionERC20.totalSupply();

		require(solutionEndBalance - solutionInitBalance == amountToDeposit, "ExerciceSolution has an incorrect amount of tokens");
		require(selfInitBalance - selfEndBalance == amountToDeposit, "Evaluator has an incorrect amount of tokens");
		require(amountLeft - amountDeposited == amountToDeposit, "Balance of Evaluator not credited correctly in ExerciceSolutionErc20");
		require(endWrappedTotalSupply - initWrappedTotalSupply == amountToDeposit, "ExerciceSolutionErc20 were not minted correctly");

		// Crediting points
		if (!exerciceProgression[msg.sender][8])
		{
			exerciceProgression[msg.sender][8] = true;
			TDERC20.distributeTokens(msg.sender, 2);
		}
	}

	function ex9_withdrawAndBurn()
	public
	{
		// Checking a solution was submitted
		require(exerciceProgression[msg.sender][0], "No solution submitted");

		// Checking how many tokens ExerciceSolution and Evaluator hold
		uint256 solutionInitBalance = claimableERC20.balanceOf(address(studentExerciceSolution[msg.sender]));
		uint256 selfInitBalance = claimableERC20.balanceOf(address(this));
		address exerciceSolutionERC20 = studentExerciceSolution[msg.sender].getERC20DepositAddress();
		IERC20Mintable ExerciceSolutionERC20 = IERC20Mintable(exerciceSolutionERC20);
		uint256 amountToWithdraw = ExerciceSolutionERC20.balanceOf(address(this));
		uint256 initWrappedTotalSupply = ExerciceSolutionERC20.totalSupply();

		// Withdraw tokens through ExerciceSolution
		studentExerciceSolution[msg.sender].withdrawTokens(amountToWithdraw);

		// Verifying tokens where withdrew correctly
		uint256 solutionEndBalance = claimableERC20.balanceOf(address(studentExerciceSolution[msg.sender]));
		uint256 selfEndBalance = claimableERC20.balanceOf(address(this));
		uint256 amountLeft = ExerciceSolutionERC20.balanceOf(address(this));
		uint256 endWrappedTotalSupply = ExerciceSolutionERC20.totalSupply();

		require(solutionInitBalance - solutionEndBalance== amountToWithdraw, "ExerciceSolution has an incorrect amount of tokens");
		require(selfEndBalance - selfInitBalance == amountToWithdraw, "Evaluator has an incorrect amount of tokens");
		require(amountLeft == 0, "Tokens still credited ExerciceSolutionErc20");
		require(initWrappedTotalSupply - endWrappedTotalSupply == amountToWithdraw, "ExerciceSolutionErc20 were not burned correctly");

		// Crediting points
		if (!exerciceProgression[msg.sender][9])
		{
			exerciceProgression[msg.sender][9] = true;
			TDERC20.distributeTokens(msg.sender, 2);
		}
	}


	/* Internal functions and modifiers */ 
	function submitExercice(IExerciceSolution studentExercice)
	public
	{
		// Checking this contract was not used by another group before
		require(!hasBeenPaired[address(studentExercice)]);

		// Assigning passed ERC20 as student ERC20
		studentExerciceSolution[msg.sender] = studentExercice;
		hasBeenPaired[address(studentExercice)] = true;

		if (!exerciceProgression[msg.sender][0])
		{
			exerciceProgression[msg.sender][0] = true;
			TDERC20.distributeTokens(msg.sender, 1);
		}
	}

	modifier onlyTeachers() 
	{

	    require(TDERC20.teachers(msg.sender));
	    _;
	}

	function _compareStrings(string memory a, string memory b) 
	internal 
	pure 
	returns (bool) 
	{
    	return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
	}

	function bytes32ToString(bytes32 _bytes32) 
	public 
	pure returns (string memory) 
	{
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

}

pragma solidity ^0.6.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20TD is ERC20 {

mapping(address => bool) public teachers;
event DenyTransfer(address recipient, uint256 amount);
event DenyTransferFrom(address sender, address recipient, uint256 amount);

constructor(string memory name, string memory symbol,uint256 initialSupply) public ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
        teachers[msg.sender] = true;
    }

function distributeTokens(address tokenReceiver, uint256 amount) 
public
onlyTeachers
{
	uint256 decimals = decimals();
	uint256 multiplicator = 10**decimals;
  _mint(tokenReceiver, amount * multiplicator);
}

function setTeacher(address teacherAddress, bool isTeacher) 
public
onlyTeachers
{
  teachers[teacherAddress] = isTeacher;
}

modifier onlyTeachers() {

    require(teachers[msg.sender]);
    _;
  }

function transfer(address recipient, uint256 amount) public override returns (bool) {
	emit DenyTransfer(recipient, amount);
        return false;
    }

function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
  emit DenyTransferFrom(sender, recipient, amount);
        return false;
    }

}

pragma solidity >=0.6.0 <0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Claimable is ERC20 {

	uint256 public distributedAmount = 100002500002300000;
	constructor(string memory name, string memory symbol,uint256 initialSupply) public ERC20(name, symbol) 
	{
	   _mint(msg.sender, initialSupply);
	}

	function claimTokens() public returns (uint256)
	{
	  _mint(msg.sender, distributedAmount);
	  return distributedAmount;
	}

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}