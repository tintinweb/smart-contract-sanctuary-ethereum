//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {REGISTRY} from "../registry/RegistryAddress.sol";
import {IVotingRegistry} from "../registry/IVotingRegistry.sol";
import {CanVoteAndDelegateImplement} from "../integration/CanVoteAndDelegateImplement.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDummyERC20, DummyERC20} from "./DummyERC20.sol";





contract DummyIntegrator is CanVoteAndDelegateImplement {

    IERC20 public dummyERC20; 
    address public owner;
    address public someoneElse;

    bytes4 public changeOwnerSelector = bytes4(bytes32(keccak256("changeOwner(address)")));
    bytes4 public changeSomeoneElseSelector = bytes4(bytes32(keccak256("changeSomeoneElse(address)")));

    constructor(address voteContract, address _dummyERC20) 
    {
        dummyERC20 = IERC20(_dummyERC20);
        owner = msg.sender;

        // approve selectors
        _selectorApproval(changeOwnerSelector, true); 
        _selectorApproval(changeSomeoneElseSelector, true);

        // whitelist some contracts
        _whitelistContractAndSetSelector(changeOwnerSelector, voteContract);
        _whitelistContractAndSetSelector(changeSomeoneElseSelector, voteContract);
    }

    /**
     * @notice Needs to be defined in order to allow voting
     */
    function start(
        bytes memory votingParams,
        bytes4 _callbackSelector,
        bytes memory _callbackArgs)
    public
    override(CanVoteAndDelegateImplement)
    {
        // some guard for calling this function might be useful.
        require(dummyERC20.balanceOf(msg.sender)>0, "Caller needs to hold DUMMY");
        _start(votingParams, _callbackSelector, _callbackArgs);
    }

    function vote(uint256 voteIndex, uint256 option)
    public 
    override(CanVoteAndDelegateImplement)
    {
        // some guard for calling this function might be useful.
        require(dummyERC20.balanceOf(msg.sender)>0, "Caller needs to hold DUMMY");
        _vote(voteIndex, option);
    }


    function changeOwner(address newOwner) 
    external 
    votingGuard(changeOwnerSelector)
    {
        owner = newOwner;
    }

    function changeSomeoneElse(address newSomeoneElse) 
    external 
    votingGuard(changeSomeoneElseSelector)
    {
        someoneElse = newSomeoneElse;
    }


    function _customFunctionGuard(bytes4 selector) 
    internal 
    view 
    override(CanVoteAndDelegateImplement)
    returns(bool)
    {
        bool ownerMayDoAnyThing = msg.sender==owner;
        bool someoneElseOnlyThis = (msg.sender==someoneElse) && (selector==changeSomeoneElseSelector);
        return ownerMayDoAnyThing || someoneElseOnlyThis;
    }

    // some introspection VIEW functions

    function getVotingContract(bytes4 selector) external view returns(address){
        return voteContract[selector];
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

address constant REGISTRY = 0xbC9BFE2CA9a27A34Bfc2057b428c7C341a017a2f;

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {IVoteContract} from "../voteContract/IVoteContract.sol";



interface IVotingRegistry {

    function register(bytes8 categoryId) external returns(uint256 registrationIndex);
    function isRegistered(address voteContract) external view returns(bool registrationFlag);

    function addCategoryToRegistration(bytes8 categoryId) external;
    function isRegisteredCategory(bytes8 categoryId) external view returns(bool registrationFlag);

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {REGISTRY} from "../registry/RegistryAddress.sol";
import {IVotingRegistry} from "../registry/IVotingRegistry.sol";
import {IVoteContract, IVoteAndImplementContract} from "../voteContract/IVoteContract.sol";
import {CanVotePrimitive, Whitelisting, FunctionGuard, VoteInfo} from "./CanVote.sol";


abstract contract CanVoteAndDelegateImplement is Whitelisting, FunctionGuard, CanVotePrimitive {

    // constructor() CanVote(){}

    function start(
        bytes memory votingParams,
        bytes4 _callbackSelector,
        bytes memory _callbackArgs)
    public virtual; 

    function vote(uint256 voteIndex, uint256 option) public virtual;

    function _start(
        bytes memory votingParams,
        bytes4 _callbackSelector,
        bytes memory _callbackArgs)
    internal 
    isVotable(_callbackSelector)
    isWhitelisted(voteContract[_callbackSelector])
    returns(uint256)
    {
        totalVotesStarted += 1;
        VoteInfo memory _voteInfo;
        _voteInfo.voteContract = voteContract[_callbackSelector];
        _voteInfo.index = IVoteAndImplementContract(_voteInfo.voteContract).start(
            votingParams, 
            _callbackSelector,
            _callbackArgs);
        voteInfo[totalVotesStarted] = _voteInfo;
        return totalVotesStarted;
    }

    function _customFunctionGuard(bytes4 selector) 
    internal 
    view 
    virtual
    override(FunctionGuard)
    returns(bool)
    {
        selector;  // silence warnings
        return false;
    }

    function _functionGuard(bytes4 selector) 
    internal 
    view 
    override(FunctionGuard)
    returns(bool)
    {
        return msg.sender == voteContract[selector];
    }

    function _supportsAdditionalInterfaces(address _voteContract)
    internal 
    view 
    override(Whitelisting)
    returns(bool)
    {
        return IVoteContract(_voteContract).supportsInterface(type(IVoteAndImplementContract).interfaceId);
    }
    
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

uint256 constant MAX_BALANCE = 1000 * (1e18);

interface IDummyERC20 {
    function freeMinting(uint256 amount) external;
}

contract DummyERC20 is ERC20 {

    bool public isDummy;

    constructor(string memory name, string memory symbol)
    ERC20(name, symbol) {
        isDummy = true;
    }

    function freeMinting(uint256 amount) external {
        _mint(msg.sender, amount);
        require(balanceOf(msg.sender)<=MAX_BALANCE, "may not mint beyond 1000 Dummies");
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

enum Response {none, successful, failed}

struct Callback {
    bytes4 selector;
    bytes arguments;
    Response response;
}

interface IVoteContract is IERC165{
    function start(bytes memory votingParams) external returns(uint256 voteIndex); 

    function vote(uint256 voteIndex, address voter, uint256 option) external returns(uint256 status);

    /**
     * @notice The result can be the casted version of an address, an integer or a pointer to a mapping that contains the entire result.
     */
    function result(uint256 voteIndex) external view returns(bytes32 votingResult);

    function statusPermitsVoting(uint256 voteIndex) external view returns(bool);
}


interface IVoteAndImplementContract is IVoteContract {
    function start(
        bytes memory votingParams,
        bytes4 _callbackSelector,
        bytes memory _callbackArgs)
    external returns(uint256 index); 

    function getCallbackResponse(uint256 voteIndex) external view returns(uint8);

    function getCallbackData(uint256 voteIndex) external view returns(bytes4 selector, bytes memory arguments);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import {REGISTRY} from "../registry/RegistryAddress.sol";
import {IVotingRegistry} from "../registry/IVotingRegistry.sol";
import {IVoteContract} from "../voteContract/IVoteContract.sol";

error NotRegisteredVoteContract(address voteContract);
error IsNotWhitelistedVoteContract(address voteContract);
error FunctionDoesntPermitVoting(bytes4 selector);
error NotPermissibleVoteContractOrSelector(bytes4 selector, address voteContract);
error DoesNotPermitVoting(uint256 voteIndex);
error MayNotCallFunction(address caller);


abstract contract FunctionGuard {
    
    function _customFunctionGuard(bytes4 selector) 
    internal 
    view 
    virtual
    returns(bool)
    {
        selector;  // silence warnings
        return false;
    }

    function _functionGuard(bytes4 selector) 
    internal 
    view 
    virtual
    returns(bool)
    {
        selector;  // silence warnings
        return true;
    }

    modifier votingGuard(bytes4 selector) {

        // TODO: Can one get the selector from the msg.data ? 

        bool mayCallFunction = _functionGuard(selector) || _customFunctionGuard(selector);
        if (!mayCallFunction) {
            revert MayNotCallFunction(msg.sender);
        }
        _;
    }

}

abstract contract Whitelisting {

    mapping(bytes4 => bool) internal votable;
    mapping(address => bool) internal whitelistedVoteContract;
    mapping(bytes4 => address) internal voteContract;
    
    // constructor () {
    //     // whitelistedVoteContract[address(0)] = false;
    // }

    function _selectorApproval(bytes4 selector, bool approval) internal {
        votable[selector] = approval;
    }

    function _supportsAdditionalInterfaces(address _voteContract)
    internal 
    virtual 
    view 
    returns(bool)
    {
        _voteContract;  // silence warnings
        return true;
    }

    function _setVoteContractForSelector(bytes4 selector, address _voteContract) 
    internal 
    isWhitelisted(_voteContract)
    isVotable(selector)
    {
        voteContract[selector] = _voteContract;
    }

    function _whitelistContractAndSetSelector(bytes4 selector, address _voteContract) 
    internal 
    {
        _whitelistVoteContract(_voteContract, true);
        _setVoteContractForSelector(selector, _voteContract);
    }

    function _whitelistVoteContract(address _voteContract, bool approve) 
    internal
    isLegitimateVoteContract(_voteContract)
    {
        whitelistedVoteContract[_voteContract] = approve;
    }

    modifier isLegitimateVoteContract(address _voteContract) {
        bool legitimate = _supportsAdditionalInterfaces(_voteContract) && IVotingRegistry(REGISTRY).isRegistered(_voteContract);
        if (!legitimate) {
            revert NotRegisteredVoteContract(_voteContract);
        }
        _;
    }

    modifier isWhitelisted(address _voteContract) {
        if (!whitelistedVoteContract[_voteContract]) {
            revert IsNotWhitelistedVoteContract(_voteContract);
        }
        _;
    }

    modifier isVotable(bytes4 selector) {
        if (!votable[selector]) {
            revert FunctionDoesntPermitVoting(selector);
        }
        _;
    }
    
}

struct VoteInfo {
    address voteContract;
    uint256 index;
}

abstract contract CanVotePrimitive is Whitelisting {

    mapping(uint256=>VoteInfo) internal voteInfo;
    uint256 internal totalVotesStarted;

    // constructor() Whitelisting(){}

    function getTotalVotesStarted() external view returns(uint256) {
        return totalVotesStarted;
    }

    function getVoteInfo(uint256 voteIndex) external view returns(address, uint256) {
        return (voteInfo[voteIndex].voteContract, voteInfo[voteIndex].index);
    }

    function _vote(uint256 voteIndex, uint256 option)
    internal
    permitsVoting(voteIndex)
    {
        IVoteContract(voteInfo[voteIndex].voteContract).vote(
            voteInfo[voteIndex].index,
            msg.sender,
            option
        );
    }

  
    modifier permitsVoting(uint256 voteIndex){
        bool permitted = IVoteContract(voteInfo[voteIndex].voteContract).statusPermitsVoting(voteInfo[voteIndex].index);
        if(! permitted){
            revert DoesNotPermitVoting(voteIndex);
        }
        _;
    }
    
}


abstract contract CanVoteWithoutStarting is CanVotePrimitive {

    // TODO: Actually this function doesnt need a selector, since no function is called upon completion.
    // TODO: Maybe change the Whitelisting abstract contract to allow for function-unspecific whitelisting of contracts.

    function _start(bytes4 selector, bytes memory votingParams) 
    internal
    isVotable(selector)
    isWhitelisted(voteContract[selector])
    returns(uint256)
    {
        totalVotesStarted += 1;
        VoteInfo memory _voteInfo;
        _voteInfo.voteContract = voteContract[selector];
        _voteInfo.index = IVoteContract(_voteInfo.voteContract).start(votingParams);
        voteInfo[totalVotesStarted] = _voteInfo;
        return totalVotesStarted;
    }
}


abstract contract CanVote is CanVoteWithoutStarting {

    function vote(uint256 voteIndex, uint256 option) public virtual;

    function start(bytes4 selector, bytes memory votingParams) public virtual;

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