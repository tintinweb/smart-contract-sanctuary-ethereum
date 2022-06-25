/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

// SPDX-License-Identifier: MIT
// File: contracts/proxyModel/Storage.sol


pragma solidity 0.8.7;

contract Storage{

    address admin_;

    mapping (address =>uint) internal balances_;

    mapping (address => mapping (address => uint256)) internal allowances_;

    uint256  internal totalSupply_ ;

}
// File: contracts/proxyModel/IERC20.sol


pragma solidity 0.8.7;
 
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
// File: contracts/proxyModel/IToken_Sea.sol


pragma solidity 0.8.7;



// abstract contract IToken_Sea {
//     function approve_add(address _address,uint256 _amount)virtual internal   returns (uint256);
//     function approve_sub(address _address,uint256 _amount)virtual internal   returns (uint256); 
// }

interface IToken_Sea {
    function approve_add(address _address,uint256 _amount) external    returns (uint256);
    function approve_sub(address _address,uint256 _amount) external    returns (uint256); 
}
// File: contracts/proxyModel/Token_Sea.sol


pragma solidity 0.8.7;




 
contract ERC20_Sea is  IToken_Sea,Storage,IERC20 {
    
    uint public decimals_;
    string public name_ ;
    constructor (uint256 _totalSupply,uint _decimals){
        admin_ = msg.sender;
        totalSupply_ = _totalSupply;
        name_ = "SEA";
    }

    function balanceOf(address _account) public override view  returns (uint256){
        return balances_[_account];
    }

    function approve(address _spender, uint _value) public  override returns (bool) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(!((_value != 0) && (allowances_[msg.sender][_spender] != 0)));

        allowances_[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint256){
        return allowances_[_owner][_spender];
    }
    
    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool){

        uint allowan = allowances_[_sender][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;

        require(allowan > _amount,"not permissions");
        balances_[_sender] -= _amount;
        balances_[_recipient] += _amount;
        emit Transfer(_sender, _recipient, _amount);
        return true;
    }

    function transfer(address _recipient, uint256 _amount) public override returns (bool){
        require(_amount > 0);

        balances_[msg.sender] -= _amount;
        balances_[_recipient] += _amount;
        emit Transfer(msg.sender,_recipient,_amount);
        return true;
    }


    function totalSupply() public override view  returns (uint256){
        return totalSupply_;
    }

   function approve_add(address _sender,uint256 _amount)public override returns (uint256){
        require(_amount > 0 ,"invalid amount");

        uint allowan = allowances_[_sender][msg.sender]; 
        require(allowan > _amount,"not permissions");

        balances_[_sender] += _amount;

        return balances_[_sender];
    }

    function approve_sub(address _sender,uint256 _amount)public override returns (uint256){
        require(_amount > 0 ,"invalid amount");

        uint allowan = allowances_[_sender][msg.sender]; 
        require(allowan > _amount,"not permissions");
        

        uint256 bal = balances_[_sender];
        require(bal > _amount,"balance not enough");
        balances_[_sender] -= _amount;

        return balances_[_sender];
    }

    function add(address _reciver,uint256 _amount)public  returns (uint256){
        require(_amount > 0 ,"invalid amount");

        balances_[_reciver] += _amount;
        
        return balances_[_reciver];
    }
    

}