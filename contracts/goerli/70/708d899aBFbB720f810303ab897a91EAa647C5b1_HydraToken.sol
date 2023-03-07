pragma solidity 0.5.4;

import "./external/openzeppelin-solidity-2.2.0/contracts/token/ERC20/ERC20Detailed.sol";
import "./external/tenx/interfaces/IModerator.sol";
import "./external/tenx/token/ERC1400.sol";

// 1594 - Moderated, issuable
// 1644 - Controllable

/**
 * @notice Hydra Token
 */
contract HydraToken is
    ERC1400,
    ERC20Detailed("Hydra DAO Token", "HYDRA", 18)
{
    constructor(IModerator _moderator) public ERC1400(_moderator) {}
}

pragma solidity ^0.5.2;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

pragma solidity ^0.5.2;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

pragma solidity ^0.5.2;

import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://eips.ethereum.org/EIPS/eip-20
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token to a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

pragma solidity ^0.5.2;

import "./IERC20.sol";

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

pragma solidity ^0.5.2;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.2;

/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

pragma solidity 0.5.4;

import "../../openzeppelin-solidity-2.2.0/contracts/utils/Address.sol";
import "../interfaces/IModerator.sol";
import "../roles/ControllerRole.sol";


contract Moderated is ControllerRole {
    IModerator public moderator; // External moderator contract

    event ModeratorUpdated(address moderator);

    constructor(IModerator _moderator) public {
        moderator = _moderator;
    }

    /**
    * @notice Links a Moderator contract to this contract.
    * @param _moderator Moderator contract address.
    */
    function setModerator(IModerator _moderator) external onlyController {
        require(address(moderator) != address(0), "Moderator address must not be a zero address.");
        require(Address.isContract(address(_moderator)), "Address must point to a contract.");
        moderator = _moderator;
        emit ModeratorUpdated(address(_moderator));
    }
}

pragma solidity 0.5.4;


/// @title IERC1594 Security Token Standard
/// @dev See https://github.com/SecurityTokenStandard/EIP-Spec
interface IERC1594 {
    // Issuance / Redemption Events
    event Issued(address indexed _operator, address indexed _to, uint256 _value, bytes _data);
    event Redeemed(address indexed _operator, address indexed _from, uint256 _value, bytes _data);

    // Transfers
    function transferWithData(address _to, uint256 _value, bytes calldata _data) external;
    function transferFromWithData(address _from, address _to, uint256 _value, bytes calldata _data) external;

    // Token Redemption
    function redeem(uint256 _value, bytes calldata _data) external;
    function redeemFrom(address _tokenHolder, uint256 _value, bytes calldata _data) external;

    // Token Issuance
    function issue(address _tokenHolder, uint256 _value, bytes calldata _data) external;
    function isIssuable() external view returns (bool);

    // Transfer Validity
    function canTransfer(address _to, uint256 _value, bytes calldata _data) external view returns (bool, byte, bytes32);
    function canTransferFrom(address _from, address _to, uint256 _value, bytes calldata _data) external view returns (bool, byte, bytes32);
}

pragma solidity 0.5.4;

import "../../openzeppelin-solidity-2.2.0/contracts/token/ERC20/IERC20.sol";


/// @title IERC1644 Controller Token Operation (part of the ERC1400 Security Token Standards)
/// @dev See https://github.com/SecurityTokenStandard/EIP-Spec
interface IERC1644 {
    // Controller Events
    event ControllerTransfer(
        address _controller,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    event ControllerRedemption(
        address _controller,
        address indexed _tokenHolder,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    // Controller Operation
    function controllerTransfer(address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;
    function controllerRedeem(address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;
    function isControllable() external view returns (bool);
}

pragma solidity 0.5.4;


interface IHasIssuership {
    event IssuershipTransferred(address indexed from, address indexed to);

    function transferIssuership(address newIssuer) external;
}

pragma solidity 0.5.4;


interface IModerator {
    function verifyIssue(address _tokenHolder, uint256 _value, bytes calldata _data) external view
        returns (bool allowed, byte statusCode, bytes32 applicationCode);

    function verifyTransfer(address _from, address _to, uint256 _amount, bytes calldata _data) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode);

    function verifyTransferFrom(address _from, address _to, address _forwarder, uint256 _amount, bytes calldata _data) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode);

    function verifyRedeem(address _sender, uint256 _amount, bytes calldata _data) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode);

    function verifyRedeemFrom(address _sender, address _tokenHolder, uint256 _amount, bytes calldata _data) external view
        returns (bool allowed, byte statusCode, bytes32 applicationCode);        

    function verifyControllerTransfer(address _controller, address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external view
        returns (bool allowed, byte statusCode, bytes32 applicationCode);

    function verifyControllerRedeem(address _controller, address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external view
        returns (bool allowed, byte statusCode, bytes32 applicationCode);
}

pragma solidity 0.5.4;

import "../../openzeppelin-solidity-2.2.0/contracts/access/Roles.sol";


// @notice Controllers are capable of performing ERC1644 forced transfers.
contract ControllerRole {
    using Roles for Roles.Role;

    event ControllerAdded(address indexed account);
    event ControllerRemoved(address indexed account);

    Roles.Role internal _controllers;

    modifier onlyController() {
        require(isController(msg.sender), "Only Controllers can execute this function.");
        _;
    }

    constructor() internal {
        _addController(msg.sender);
    }

    function isController(address account) public view returns (bool) {
        return _controllers.has(account);
    }

    function addController(address account) public onlyController {
        _addController(account);
    }

    function renounceController() public {
        _removeController(msg.sender);
    }

    function _addController(address account) internal {
        _controllers.add(account);
        emit ControllerAdded(account);
    }    

    function _removeController(address account) internal {
        _controllers.remove(account);
        emit ControllerRemoved(account);
    }
}

pragma solidity 0.5.4;

import "../../openzeppelin-solidity-2.2.0/contracts/access/Roles.sol";


// @notice Issuers are capable of issuing new TENX tokens from the TENXToken contract.
contract IssuerRole {
    using Roles for Roles.Role;

    event IssuerAdded(address indexed account);
    event IssuerRemoved(address indexed account);

    Roles.Role internal _issuers;

    modifier onlyIssuer() {
        require(isIssuer(msg.sender), "Only Issuers can execute this function.");
        _;
    }

    constructor() internal {
        _addIssuer(msg.sender);
    }

    function isIssuer(address account) public view returns (bool) {
        return _issuers.has(account);
    }

    function addIssuer(address account) public onlyIssuer {
        _addIssuer(account);
    }

    function renounceIssuer() public {
        _removeIssuer(msg.sender);
    }

    function _addIssuer(address account) internal {
        _issuers.add(account);
        emit IssuerAdded(account);
    }

    function _removeIssuer(address account) internal {
        _issuers.remove(account);
        emit IssuerRemoved(account);
    }
}

pragma solidity 0.5.4;

import "./ERC1594.sol";
import "./ERC1644.sol";
import "../interfaces/IModerator.sol";


contract ERC1400 is ERC1594, ERC1644 {
    constructor(IModerator _moderator) public Moderated(_moderator) {}
}

pragma solidity 0.5.4;

import "../token/ERC20Redeemable.sol";
import "../interfaces/IERC1594.sol";
import "../interfaces/IHasIssuership.sol";
import "../interfaces/IModerator.sol";
import "../roles/IssuerRole.sol";
import "../compliance/Moderated.sol";


contract ERC1594 is IERC1594, IHasIssuership, Moderated, ERC20Redeemable, IssuerRole {
    bool public isIssuable = true;

    event Issued(address indexed operator, address indexed to, uint256 value, bytes data);
    event Redeemed(address indexed operator, address indexed from, uint256 value, bytes data);
    event IssuershipTransferred(address indexed from, address indexed to);
    event IssuanceFinished();

    /**
    * @notice Modifier to check token issuance status
    */
    modifier whenIssuable() {
        require(isIssuable, "Issuance period has ended.");
        _;
    }

    /**
     * @notice Transfer the token's singleton Issuer role to another address.
     */
    function transferIssuership(address _newIssuer) public whenIssuable onlyIssuer {
        require(_newIssuer != address(0), "New Issuer cannot be zero address.");
        require(msg.sender != _newIssuer, "New Issuer cannot have the same address as the old issuer.");
        _addIssuer(_newIssuer);
        _removeIssuer(msg.sender);
        emit IssuershipTransferred(msg.sender, _newIssuer);
    }

    /**
     * @notice End token issuance period permanently.
     */
    function finishIssuance() public whenIssuable onlyIssuer {
        isIssuable = false;
        emit IssuanceFinished();
    }

    function issue(address _tokenHolder, uint256 _value, bytes memory _data) public whenIssuable onlyIssuer {
        bool allowed;
        (allowed, , ) = moderator.verifyIssue(_tokenHolder, _value, _data);
        require(allowed, "Issue is not allowed.");
        _mint(_tokenHolder, _value);
        emit Issued(msg.sender, _tokenHolder, _value, _data);
    }

    function redeem(uint256 _value, bytes memory _data) public {
        bool allowed;
        (allowed, , ) = moderator.verifyRedeem(msg.sender, _value, _data);
        require(allowed, "Redeem is not allowed.");

        _burn(msg.sender, _value);
        emit Redeemed(msg.sender, msg.sender, _value, _data);
    }

    function redeemFrom(address _tokenHolder, uint256 _value, bytes memory _data) public {
        bool allowed;
        (allowed, , ) = moderator.verifyRedeemFrom(msg.sender, _tokenHolder, _value, _data);
        require(allowed, "RedeemFrom is not allowed.");

        _burnFrom(_tokenHolder, _value);
        emit Redeemed(msg.sender, _tokenHolder, _value, _data);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        bool allowed;
        (allowed, , ) = canTransfer(_to, _value, "");
        require(allowed, "Transfer is not allowed.");

        success = super.transfer(_to, _value);
    }

    function transferWithData(address _to, uint256 _value, bytes memory _data) public {
        bool allowed;
        (allowed, , ) = canTransfer(_to, _value, _data);
        require(allowed, "Transfer is not allowed.");

        require(super.transfer(_to, _value), "Transfer failed.");
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        bool allowed;
        (allowed, , ) = canTransferFrom(_from, _to, _value, "");
        require(allowed, "TransferFrom is not allowed.");

        success = super.transferFrom(_from, _to, _value);
    }    

    function transferFromWithData(address _from, address _to, uint256 _value, bytes memory _data) public {
        bool allowed;
        (allowed, , ) = canTransferFrom(_from, _to, _value, _data);
        require(allowed, "TransferFrom is not allowed.");

        require(super.transferFrom(_from, _to, _value), "TransferFrom failed.");
    }

    function canTransfer(address _to, uint256 _value, bytes memory _data) public view 
        returns (bool success, byte statusCode, bytes32 applicationCode) 
    {
        return moderator.verifyTransfer(msg.sender, _to, _value, _data);
    }

    function canTransferFrom(address _from, address _to, uint256 _value, bytes memory _data) public view 
        returns (bool success, byte statusCode, bytes32 applicationCode) 
    {
        return moderator.verifyTransferFrom(_from, _to, msg.sender, _value, _data);
    }
}

pragma solidity 0.5.4;


import "../../openzeppelin-solidity-2.2.0/contracts/utils/Address.sol";
import "../token/ERC20Redeemable.sol";
import "../interfaces/IERC1644.sol";
import "../interfaces/IModerator.sol"; 
import "../compliance/Moderated.sol";


contract ERC1644 is IERC1644, Moderated, ERC20Redeemable {
    event ControllerTransfer(
        address controller,
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data,
        bytes operatorData
    );

    event ControllerRedemption(
        address controller,
        address indexed tokenHolder,
        uint256 value,
        bytes data,
        bytes operatorData
    );

    function controllerTransfer(
        address _from,
        address _to,
        uint256 _value,
        bytes memory _data,
        bytes memory _operatorData
    ) public onlyController {
        bool allowed;
        (allowed, , ) = moderator.verifyControllerTransfer(
            msg.sender,
            _from,
            _to,
            _value,
            _data,
            _operatorData
        );
        require(allowed, "controllerTransfer is not allowed.");
        require(_value <= balanceOf(_from), "Insufficient balance.");
        _transfer(_from, _to, _value);
        emit ControllerTransfer(msg.sender, _from, _to, _value, _data, _operatorData);
    }

    function controllerRedeem(
        address _tokenHolder,
        uint256 _value,
        bytes memory _data,
        bytes memory _operatorData
    ) public onlyController {
        bool allowed;
        (allowed, , ) = moderator.verifyControllerRedeem(
            msg.sender,
            _tokenHolder,
            _value,
            _data,
            _operatorData
        );
        require(allowed, "controllerRedeem is not allowed.");
        require(_value <= balanceOf(_tokenHolder), "Insufficient balance.");
        _burn(_tokenHolder, _value);
        emit ControllerRedemption(msg.sender, _tokenHolder, _value, _data, _operatorData);
    }

    function isControllable() public view returns (bool) {
        return true;
    }
}

pragma solidity 0.5.4;

import "../../openzeppelin-solidity-2.2.0/contracts/token/ERC20/ERC20.sol";
import "../../openzeppelin-solidity-2.2.0/contracts/math/SafeMath.sol";


contract ERC20Redeemable is ERC20 {
    using SafeMath for uint256;

    uint256 public totalRedeemed;

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account. Overriden to track totalRedeemed.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        totalRedeemed = totalRedeemed.add(value); // Keep track of total for Rewards calculation
        super._burn(account, value);
    }
}