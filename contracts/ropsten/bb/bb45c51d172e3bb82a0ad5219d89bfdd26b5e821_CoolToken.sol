/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

// SPDX-License-Identifier: MIT
// File: ERC20own.sol



pragma solidity ^ 0.8.7;

interface ERC20own {

    function transfer (address _to , uint _value) external;

    function transferFrom (address _from ,address _to , uint _value) external;

    function balanceOf (address owner) external view returns (uint);

    function mintToken (address _to , uint _value) external ;

    function approve (address _spender , uint _value) external;

    function allowance (address _owner , address _spender)external view returns (uint);


}
// File: CoolToken.sol



pragma solidity ^ 0.8.7;


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract CoolToken is ERC20own {

    using SafeMath for uint;
    string public constant name = "CoolToken";
    string public constant symbol = "CTK";
    uint public constant decimal = 8;
    address public owner;

    uint public totalSupply;

    mapping (address => uint) private balances;
    mapping (address => mapping (address=>uint))private allowances;

    modifier onlyOwner (address _owner) {
        _owner = msg.sender;
        owner = _owner;
        require (msg.sender == _owner , "You are not msg.sender");
        _;


    }

    function balanceOf (address _owner) public view override returns (uint) {

        return balances[_owner];

    }

     function mintToken (address _to , uint _value) public onlyOwner(owner) override{
         require(_to!= address(0),"Error");
         balances[_to] =  balances[_to].add(_value);
         totalSupply = totalSupply.add(_value);

     }

     function transfer (address _to , uint _value) public override {
         require(_to!= address(0),"Error");
         require(balances[msg.sender] >= _value,"Error");

         balances[msg.sender] =balances[msg.sender].sub(_value);
          balances[_to] =  balances[_to].add(_value);


     }

     function transferFrom(address _from , address _to , uint _value) public override onlyOwner(owner){
         require(_to!= address(0),"Error");
         require(_from!= address(0),"Error");
         require(balances[_from] >= _value,"Error");
         require(_from == owner );
         balances[_from] = balances[_from].sub(_value);
        balances[_to] =  balances[_to].add(_value);
     }

     function approve (address _spender , uint _value) public override {
         require(_spender!= address(0),"Error");
         allowances[msg.sender][_spender] = _value;



     }

     function allowance (address _owner , address _spender)public view override returns (uint) {
         
         return allowances[_owner][_spender];
     }

     function myBalance () public view returns(uint){
         return balances[msg.sender];
     }

    


}