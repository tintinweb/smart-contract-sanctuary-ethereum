/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.9 ; 

interface IERC20{
    function totalsupply() external view returns(uint256);
    function balanceof(address account) external view returns(uint256);
    function allownce(address owner , address spender)external view returns(uint256);
    function transfer(address recipient , uint256 amount)external returns (bool);
    function approve(address spender , uint256 amount)external returns (bool);
    function transferfrom(address sender , address recipient ,uint256 amount)external returns (bool);

 event transferevent(address indexed from , address indexed to , uint256 value);
 event approvalevent(address indexed owner , address indexed sepender , uint256 value);
}

contract armo_token is IERC20 {
    using SafeMath for uint256;
    
    string name ;
    string symbol;
    uint8 decimals;
    uint256 totalsupply_;

    mapping(address=> uint256) balances;
    mapping ( address => mapping(address =>uint256)) allowed;

      constructor () {

          name = "are_armo";
          symbol = "ARMO";
          decimals = 11;
          totalsupply_ = 230000000000 ;
          balances[msg.sender] = totalsupply_;
      }

      function totalsupply() public override view returns(uint256){
          return totalsupply_;
      }
      function balanceof(address tokenowner) public override view returns (uint256){
          return balances[tokenowner];
      }
      function transfer(address resiver , uint256 numtokens) public override returns (bool){
          require(numtokens <= balances[msg.sender]);
          balances[msg.sender] = balances[msg.sender] .sub(numtokens);
          balances[resiver] = balances[resiver] .add(numtokens);
          emit transferevent(msg.sender, resiver, numtokens);
          return true;
      }
      function approve(address delegate , uint256 numtokens) public override returns(bool){
          allowed[msg.sender][delegate] = numtokens;
          emit approvalevent(msg.sender, delegate , numtokens);
          return true;
      }

      function allownce(address owner , address delegate) public override view returns(uint){
          return allowed[owner][delegate];
      } 
      function transferfrom (address owner , address buyer , uint numtokens) public override returns(bool){
          require(numtokens <= balances[owner]);
          require(numtokens <= allowed[owner][msg.sender]);

          balances[owner] = balances[owner]. sub (numtokens);
          allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numtokens);
          balances[buyer] = balances[buyer].add(numtokens);
          emit transferevent(owner, buyer , numtokens);
          return true;
      }
}

library SafeMath{
    
    function sub(uint256 a, uint256 b ) internal pure returns(uint256){
         assert (b <= a);
         return a - b ;
        }
    function add(uint256 a, uint256 b) internal pure returns(uint256){
        uint256 c = a + b ; 
        assert (c >= a);
        return c;
    }
}