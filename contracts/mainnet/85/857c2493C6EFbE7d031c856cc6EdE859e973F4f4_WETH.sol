pragma solidity 0.5.16;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";


contract WETH is IERC20 {
    using SafeMath for uint256;

    string public constant name = "SportX WETH";
    string public constant symbol = "WETH";
    string public constant version = "1";
    uint8 public constant decimals = 18;
    bytes2 constant private EIP191_HEADER = 0x1901;
    bytes32 public constant EIP712_UNWRAP_TYPEHASH = keccak256("Unwrap(address holder,uint256 amount,uint256 nonce,uint256 expiry)");
    bytes32 public constant EIP712_PERMIT_TYPEHASH = keccak256(
        "Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)"
    );
    bytes32 public EIP712_DOMAIN_SEPARATOR;
    uint256 private _totalSupply;
    address public defaultOperator;
    address public defaultOperatorController;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    mapping (address => uint256) public unwrapNonces;
    mapping (address => uint256) public permitNonces;

    event Deposit(address indexed dst, uint256 amount);
    event Withdrawal(address indexed src, uint256 amount);

    constructor (address _operator, uint256 _chainId, address _defaultOperatorController) public {
        defaultOperator = _operator;
        defaultOperatorController = _defaultOperatorController;
        EIP712_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                _chainId,
                address(this)
            )
        );
    }

    modifier onlyDefaultOperatorController() {
        require(
            msg.sender == defaultOperatorController,
            "ONLY_DEFAULT_OPERATOR_CONTROLLER"
        );
        _;
    }

    /**
     * @dev Alias for the deposit function to deposit ETH.
     */
    function() external payable {
        _deposit(msg.sender, msg.value);
    }

    /**
     * @dev Sets the default operator. Only callable by the default operator controller.
     * @param newDefaultOperator The new default operator.
     */
    function setDefaultOperator(address newDefaultOperator) external onlyDefaultOperatorController {
        defaultOperator = newDefaultOperator;
    }

    /**
     * @dev Unwraps ETH meta style. Exchanges this token, WETH, for ETH 1 to 1
     * @param holder The holder of WETH that wishes to withdraw.
     * @param amount The amount to withdraw.
     * @param nonce The current nonce for this holder, to prevent replays of the withdraw.
     * @param expiry The time after which this meta withdraw is not valid.
     * @param v v parameter in the ECDSA signature.
     * @param r r parameter in the ECDSA signature.
     * @param s s parameter in the ECDSA signature.
     */
    function metaWithdraw(
        address payable holder,
        uint256 amount,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 digest = keccak256(
            abi.encodePacked(
                EIP191_HEADER,
                EIP712_DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        EIP712_UNWRAP_TYPEHASH,
                        holder,
                        amount,
                        nonce,
                        expiry
                    )
                )
            )
        );

        require(holder != address(0), "INVALID_HOLDER");
        require(holder == ecrecover(digest, v, r, s), "INVALID_SIGNATURE");
        require(expiry == 0 || now <= expiry, "META_WITHDRAW_EXPIRED");
        require(nonce == unwrapNonces[holder]++, "INVALID_NONCE");
        require(_balances[holder] >= amount, "INSUFFICIENT_BALANCE");

        _withdraw(holder, amount);
    }

    /**
     * @dev Meta approval for max funds.
     * @param holder The holder of the WETH that wishes to approve another account.
     * @param spender The designated spender of the WETH.
     * @param nonce The current permit nonce for this holder, to prevent replays of the increased allowance.
     * @param expiry The time after which this meta approval is not valid.
     * @param allowed true if this spender should be allowed to spend all funds on behalf of the holder, false otherwise.
     * @param v v parameter in the ECDSA signature.
     * @param r r parameter in the ECDSA signature.
     * @param s s parameter in the ECDSA signature.
     */
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                EIP712_DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        EIP712_PERMIT_TYPEHASH,
                        holder,
                        spender,
                        nonce,
                        expiry,
                        allowed
                    )
                )
            )
        );

        require(holder != address(0), "INVALID_HOLDER");
        require(holder == ecrecover(digest, v, r, s), "INVALID_SIGNATURE");
        require(expiry == 0 || now <= expiry, "PERMIT_EXPIRED");
        require(nonce == permitNonces[holder]++, "INVALID_NONCE");
        uint256 wad = allowed ? uint256(-1) : 0;
        _allowed[holder][spender] = wad;
        emit Approval(holder, spender, wad);
    }

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
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
     * @dev Transfer token for a specified address
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
        require(spender != address(0), "SPENDER_INVALID");

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
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
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0), "SPENDER_INVALID");

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0), "SPENDER_INVALID");

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Unwraps ETH - exchanges this token, WETH, for ETH 1 to 1
     * @param amount The amount of token to withdraw.
     */
    function withdraw(uint256 amount) public {
        require(_balances[msg.sender] >= amount, "INSUFFICIENT_BALANCE");
        _withdraw(msg.sender, amount);
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) private {
        require(to != address(0), "SPENDER_INVALID");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that unwraps ETH - exchanges this token, WETH, for ETH 1 to 1.
     * @param holder The holder that wishes to withdraw to ETH.
     * @param amount The amount of token to withdraw.
     */
    function _withdraw(address payable holder, uint256 amount) private {
        _balances[holder] = _balances[holder].sub(amount);
        holder.transfer(amount);
        emit Withdrawal(holder, amount);
    }

    /**
     * @dev Wraps ETH - exchanges ETH for this token, WETH, 1 to 1
     * Additionally auto approves the defaultOperator for this token to the max amount if it is zero.
     */
    function _deposit(address sender, uint256 amount) private {
        _balances[sender] = _balances[sender].add(amount);
        uint256 senderAllowance = _allowed[sender][defaultOperator];
        if (senderAllowance == 0) {
            _allowed[sender][defaultOperator] = uint256(-1);
        }
        emit Deposit(sender, amount);
    }
}

pragma solidity ^0.5.0;

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

pragma solidity ^0.5.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
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