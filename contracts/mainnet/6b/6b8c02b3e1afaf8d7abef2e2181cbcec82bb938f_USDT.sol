/**
 *Submitted for verification at Etherscan.io on 2022-10-16
*/

pragma solidity ^0.5.17;


contract USDT {
    using SafeMath for uint;

    address public owner;

    /// @notice EIP-20 token name for this token
    string public constant name = "Tether USD";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "USDT";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 6;

    /// @notice Total number of tokens in circulation
    uint public totalSupply = 2e18; // 20 million ros

    /// @notice Allowance amounts on behalf of others
    mapping(address => mapping(address => uint)) internal allowances;

    /// @notice Official record of token balances for each account
    mapping(address => uint) internal balances;

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor(address account) public {
        owner=account;
        balances[owner] = totalSupply;
        emit Transfer(address(0), account, totalSupply);
    }

    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    function approve(address spender, uint rawAmount) external returns (bool) {
        require(spender != address(0), "approve to the zero address");
        allowances[msg.sender][spender] = rawAmount;
        emit Approval(msg.sender, spender, rawAmount);
        return true;
    }


    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

  
    function transfer(address dst, uint rawAmount) external returns (bool) {
        _transfer(msg.sender, dst, rawAmount);
        return true;
    }

  
    function transferFrom(address src, address dst, uint rawAmount) external returns (bool) {
        address spender = msg.sender;
        uint spenderAllowance = allowances[src][spender];
        if (spender != src && spenderAllowance != uint(- 1)) {
            uint newAllowance = spenderAllowance.sub(rawAmount, "transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;
            emit Approval(src, spender, newAllowance);
        }
        _transfer(src, dst, rawAmount);
        return true;
    }
    function _transfer(address from,address to,uint256 amount) internal  {
        require(from != address(0), "transfer from the zero address");
        
        balances[from]=balances[from].sub(amount,"transfer amount exceeds balance");
        balances[to]=balances[to].add(amount,"transfer amount exceeds balance");

        emit Transfer(from, to, amount);
    }

    function mint(address account, uint256 amount) external  {
        require(msg.sender == owner, "must have owner to mint");

        totalSupply += amount;

        balances[account]=balances[account].add(amount,"mint amount overflows");
       
        emit Transfer(address(0), account, amount);
    }

    function transferOwner(address account)external{
        require(msg.sender == owner, "must have owner");
        owner=account;
    }

}



library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}