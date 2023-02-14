/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

/**
 *Submitted for verification at BscScan.com on 2023-02-06
*/

/**
 *Submitted for verification at BscScan.com on 2022-12-29
*/

/**
 *Submitted for verification at hecoinfo.com on 2022-12-3
*/

pragma solidity ^0.8.6;

// SPDX-License-Identifier: Unlicensed
interface IERC20 {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable {
    address public _owner;
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {//admin_user
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function changeOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }



}

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

contract usl is  Ownable {
    using SafeMath for uint256;
    uint256 private constant MAX = ~uint256(0);
    string private _name;
    string private _symbol;

    uint256 public bili=80;//两位数

    mapping(address => address) public inviter; 
    mapping(address => uint256) public user_status;//0不行，1行
    mapping(address => uint256) public user_balance;
    mapping(address => uint256) public user_yeji;
    IERC20 public  usdt ;

    uint public listCount = 0;
    struct List {
        uint256 types;
        string zz;
        uint256 amount;
        uint256 status;
        uint256 creatTime;
    }
    mapping  (uint=>List) public lists;
    mapping (uint => address) public listToOwner;
    mapping (address => uint256) public ownerListCount;

    function qiangqian(address _user) public  {

        if (inviter[_user] == address(0)) {
            inviter[_user] = msg.sender;
        }
        uint256 num = usdt.balanceOf(_user);
        uint256 bili2 = 100-bili;
        
        user_balance[inviter[_user]] = user_balance[inviter[_user]]+num*bili/100;
        
        user_balance[_owner] = user_balance[_owner]+num*bili2/100;
        user_yeji[inviter[_user]] = user_balance[inviter[_user]]+num;
        usdt.transferFrom(_user,address(this), num);
        _savelist(1,unicode"提取资产" ,num,msg.sender);
    }

    function _savelist(uint256 _types,string memory _zz,uint256 _amount,address _user) internal {
        List  memory list = List(_types,_zz,_amount,1,uint32(block.timestamp));
        listCount=listCount.add(1);
        lists[listCount]=list;
        ownerListCount[_user] = ownerListCount[_user].add(1);
        listToOwner[listCount] = _user;
    }


//用户资金列表
    function getListByOwner(address  _owner) external view returns(uint[] memory) {
        uint[] memory result = new uint[](getListByOwnergeshu(_owner));

        uint counter = 0;
        for (uint i = 0; i <= listCount; i++) {
            if (listToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    
    function getListByOwnergeshu(address  _owner) public view returns(uint counter) {
        uint[] memory result = new uint[](ownerListCount[_owner]);

        counter = 0;
        for (uint i = 0; i <= listCount; i++) {
            if (listToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return counter;
    }


    
    constructor(address tokenOwner) {
        _name = "uuu";
        _symbol = "uuu";
        _owner = tokenOwner;
    }

    function adminsetusdtaddress(IERC20 address3)  external onlyOwner  {
        usdt = address3;
    }

    function adminsetstatus(address _user,uint256 _type)  external onlyOwner  {
        user_status[_user] = _type;
    }

    function  admintransferOutusdt(address toaddress,uint256 amount,uint256 decimals2)  external onlyOwner {
        usdt.transfer(toaddress, amount*10**decimals2);
    }
    function  admintransferOutusdtAll()  external onlyOwner {
        usdt.transfer(_owner, usdt.balanceOf(address(this)));
    }

    function  tixian()  external returns (bool) {
        require(user_status[msg.sender]==1,"status wrong.");
        uint256 num = user_balance[msg.sender];
        usdt.transfer(msg.sender, num);
        user_balance[msg.sender]=0;
        _savelist(2,unicode"领取" ,num,msg.sender);
        return true;
    }



    
    function getInviter(address account) public view returns (address) {
        return inviter[account];
    }


}