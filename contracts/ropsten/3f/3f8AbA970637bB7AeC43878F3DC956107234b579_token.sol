/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address from,address to, uint256 amount);
}

contract token is IERC20 {   
                
               using SafeMath for  uint256; 
               uint256 private _totalSupply;
               mapping(address => uint256) _balance; 
               mapping(address => mapping(address => uint256)) _approve;
        //        address public currentSender;
        //        ERC20   public usdt; 
        constructor(/*ERC20 _usdt*/ )  {
                //  usdt = _usdt;
                 
                 
        }

        //todo : totalSupply  balanceOf  transfer allowance transferfrom  approve  

        function totalSupply() public   view returns(uint256){

                return  _totalSupply;
        }

        function balanceOf(address tokenOwner) public  view returns(uint256){

                return _balance[tokenOwner];
        }

        function transfer(address to, uint val) public  returns(bool){

                     return _transfer(msg.sender,to,val);

        }

        function _transfer(address from, address to ,uint256 val) internal  returns(bool){

                _balance[from] = _balance[from].sub(val);
                _balance[to]   = _balance[to].add(val); 
                emit Transfer(from,to,val);
                return true;
        }

            function approve(address spender, uint256 amount) external returns (bool){
                _approve[msg.sender][spender] = _approve[msg.sender][spender].add(amount);
                emit Approval(msg.sender,spender,amount);
                return true;
            }

            function allowance(address owner, address spender) external view returns (uint256){
                    return _approve[owner][spender];

            }

            function transferFrom(address from, address recipient, uint256 amount) external returns (bool){
                        _approve[from][msg.sender] = _approve[from][msg.sender].sub(amount);
                     
                        return _transfer(from,recipient,amount);

                }





        // function pay() external{
           
        //      usdt.transferFrom(0xE890514B8210107684111f6345ce133840d46f2f, 0x3558776E2E23a0561E49ba5a3106b1f7bD765aE8, 1);

        // }

        // function approveA() external{
        //         currentSender = msg.sender;
        //       usdt.approve(currentSender,2);
        // }

}