/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

/** 
    Devloped by: Mohamed Issam Adnane 
**/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    struct Contract { string numeroContract; string idProprety; string ownerLand; string buyerLand; uint cost; string desc; string date;}
    event Add (string numeroContract, string idProprety, string ownerLand, string buyerLand, uint cost, string desc, string date);
}

contract Mia is IERC20 {
    using SafeMath for uint256;

    string public constant name = "Mia";
    string public constant symbol = "Mia";
    uint8 public constant decimals = 18;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    uint256 private totalSupply_ = 100000000000000000000000000*10**uint256(decimals);

    address public owner;
    uint public PropretyCount = 0;

    mapping(uint => Contract) public Propreties;

    constructor() {
        balances[msg.sender] = totalSupply_;
        owner = msg.sender;
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }


    function transfer(address receiver, uint256 numTokens) public override returns (bool) {

        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;

    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {

        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;

    }

        modifier isOwner {
        require(msg.sender == owner);
        _;
    } 

    function addLand( string memory numeroContract,
                    string memory idProprety,
                    string memory _ownerLand,
                    string memory _buyerLand,uint _cost, 
                    string memory _desc,
                    string memory _date) 
    public isOwner {

      require(_cost > 0, 'Must be a cost');

      PropretyCount++;

      Propreties[PropretyCount] = Contract( numeroContract,
                                            idProprety,_ownerLand,
                                            _buyerLand, _cost,
                                            _desc,_date);
      
      emit Add( numeroContract,
                idProprety,_ownerLand,
                _buyerLand, _cost,
                _desc,_date);
    }

    function getNumberLands() public view returns(uint){
        return PropretyCount;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}