/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

// SPDX-License-Identifier: MIT

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: Assurance.sol





pragma solidity 0.8.16;

contract Factory {
    address public CreditAgricoleAddress;
    struct Contract {
        uint time;
        address owner;
    }
    Contract[] public contracts;
    address [] public contractsDeployed;

    modifier onlyCA(){
        require(msg.sender == CreditAgricoleAddress);
        _;
    }

    constructor() {
        CreditAgricoleAddress = msg.sender;
    }

    function createContract(uint time) public  {
        Contract memory newContract;
        newContract.time = time;
        newContract.owner = msg.sender; 
        contracts.push(newContract);
    }

    function getContractsDeployed() external view returns(address [] memory ) {
        return contractsDeployed;
    }

    function deployContract(address owner, address payable fund) public onlyCA {
        Contract storage contractOwner = contracts[0]; 
        uint256 i;

        for(i = 0; i < contracts.length; i++){
            Contract storage contratto = contracts[i];
            if(contratto.owner == owner){
                contractOwner = contratto;
            }
        }
        
        address newIssuing = address ( new Issuing(contractOwner.time, contractOwner.owner,fund));

        contractsDeployed.push((newIssuing));
    }
}

contract Issuing {
    uint public tempo;
    address public owner;
    Fund public fund;
    uint public deployDate;

    modifier inTime(){
        require(tempo + deployDate <= block.timestamp);
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    modifier onlyCA(){
        require( tx.origin == 0x5D4e29DE3175148DeC95f35A7EcB42970f308a33);
        _;
    }

    constructor (uint time,address propietario,address payable fundAddress)  {//rendere deployabile solo da Credit gricole
        tempo = time;
        owner = propietario;
        fund = Fund(fundAddress);
        deployDate = block.timestamp;
    }

    function deposit() public payable onlyOwner {//migliorare

    }

    function sendToContest() public onlyOwner {
        (bool sent,) = address(fund).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
        fund.swap(address(this).balance,msg.sender);
    }

    function getBalance() public view returns(uint,address){ 
        return (
            address(this).balance,
            address(fund));
    }

}

contract Security is IERC20 {
    address public CreditAgricoleAddress;
    address public _fundAddress;

    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowances;

    uint256 public _totalSupply;

    string public _name;
    string public _symbol;

    event Mint(address indexed from, address indexed to, uint256 value);
    event Burnt(address indexed from, address indexed to, uint256 value);
    

    modifier onlyFundAddress(){
        require( msg.sender == _fundAddress);
        _;
    }

    constructor(string memory name_, string memory symbol_,address fundAddress){
        CreditAgricoleAddress = msg.sender;        
        _name = name_;
        _symbol = symbol_;
        _totalSupply = 0;
        _fundAddress = fundAddress;
    }

    function name() public view  returns (string memory) {
        return _name;
    }

  
    function symbol() public view  returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function allowance(address owner, address spender) public override view returns  (uint256){
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool){
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool){
    }

    function transfer(address to, uint256 amount) public override returns (bool){
    }

    function balanceOf(address account) public override view returns (uint256){

    }

    function _mint(address account, uint256 amount) external  {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Mint(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
        
    }

    function _burn(address account, uint256 amount) external onlyFundAddress {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Burnt(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal  {}

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal  {}

}

contract Fund {
    using SafeMath for uint256;
    Factory public factory;
    Security public security;
    mapping (address => bool) public contractsDeployed;
    address public _fundManager;
    modifier onlyContractsDeployed(){
        address [] memory listContractsDeployed = factory.getContractsDeployed();
        uint256 i;
        for(i=0; i < listContractsDeployed.length; i++) {
        contractsDeployed[listContractsDeployed[i]] = true;
        }
        require(contractsDeployed[msg.sender]);
        _;
    }

    modifier onlyOwner(){
        require(_fundManager == msg.sender );
        _;
    }

    constructor(address fundManager, address factoryAddress) {
        _fundManager = fundManager;
        factory = Factory(factoryAddress);
    }

    function interfaceSecurity(address securityAddress) public onlyOwner{
        security = Security(securityAddress);
    }

    receive() external payable {}// reindirizzamento automatico ad un wallet di accumulo fee

    function swap(uint amount, address issuingOwner)  external onlyContractsDeployed {
        uint256 netValue = amount.mul(97).div(100);
        security._mint(issuingOwner, netValue);
    }
}