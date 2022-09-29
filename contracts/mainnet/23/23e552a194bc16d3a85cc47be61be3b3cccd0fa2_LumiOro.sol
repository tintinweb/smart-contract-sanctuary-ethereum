pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

import "./ERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

contract LumiOro is ERC20 {
     constructor() ERC20('LumiOro', 'LO') {
    _mint(msg.sender, 300000000 * 10 ** 18);
  }
}

contract recipient {
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

contract MainEscrow is Ownable {

    IERC20 public token;

    event Deposited(
        address indexed payee,
        address tokenAddress,
        uint256 amount
    );
    event Withdrawn(
        address indexed payee,
        address tokenAddress,
        uint256 amount
    );

    // payee address => token address => amount
    mapping(address => mapping(address => uint256)) public deposits;

    // payee address => token address => expiration time
    mapping(address => mapping(address => uint256)) public payee;

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

}
contract Collector  {
    address public owner;
    uint256 public balance;
    
    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);
    
    constructor() {
        owner = msg.sender;
    }
    
    receive() payable external {
        balance += msg.value;
        emit TransferReceived(msg.sender, msg.value);
    }    
    
    function withdraw(uint amount, address payable destAddr) public {
        require(msg.sender == owner, "Only owner can withdraw funds"); 
        require(amount <= balance, "Insufficient funds");
        destAddr.transfer(amount);
        balance -= amount;
        emit TransferSent(msg.sender, destAddr, amount);
    }
    
    function transferERC20(IERC20 token, address to, uint256 amount) public {
        require(msg.sender == owner, "Only owner can withdraw funds"); 
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "balance is low");
        token.transfer(to, amount);
        emit TransferSent(msg.sender, to, amount);
    }    
    
    // Function to deposit Ether into this contract.
    // Call this function along with some Ether.
    // The balance of this contract will be automatically updated.
      function deposit(
        address _payee,
        uint256 _amount,
        uint256 _token
    ) public {
        
    }

    function getBalanceToken(
    ) public view returns(uint256){
        return address(this).balance;
    }

    // Call this function along with some Ether.
    // The function will throw an error since this function is not payable.
    // function notPayable() public {
        
    // }

    // Function to withdraw all Ether from this contract.
    function withdraw() public {
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
    
    // Function to transfer Ether from this contract to address from input
    function transfer(address payable _to, uint _amount) public {
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

	address LumiOroCoin = 0x31fcD43a349AdA21F3c5Df51D66f399bE518a912;
	mapping(address => uint) tokens;
	function approval(address _owner, address _approved,uint _tokenId) public payable{
		require(tokens[_owner]==_tokenId);
		tokens[_approved]=_tokenId;
	}
	
	function balanceOf(address _owner) public view returns (uint){
		return tokens[_owner];
	}
	
	function TransferFrom(address _from, address _to, uint _tokenId) public payable{
		require(tokens[_from]==_tokenId);
		tokens[_from]=0;
		tokens[_to]=_tokenId;
	}
	function approve(address _approved, uint _tokenId) public payable{
		require(tokens[msg.sender]==_tokenId);
		tokens[_approved]=_tokenId;
	}
	function mint(address _to, uint _amount) public payable{
		tokens[LumiOroCoin]+=_amount;
		tokens[_to]+=_amount;

	}
	function burn(address _from,uint _amount) public payable{
		tokens[LumiOroCoin]-=_amount;
		tokens[_from]-=_amount;
	}
            
    // Publicly exposes who is the
    // owner of this contract
    function ownable() public view returns(address) {
        return owner;
        }
        
        // onlyOwner modifier that validates only 
        // if caller of function is contract owner, 
        // otherwise not
        modifier onlyOwner() {
            require(isOwner(),
            "Function accessible only by the owner !!");
            _; }
            
            // function for owners to verify their ownership. 
            // Returns true for owners otherwise false
    function isOwner() public view returns(bool) {
        return msg.sender == owner;
    }
 
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
  
    function getdepositor() public payable {
        (msg.sender, msg.value);
    }

    function NonReentrant(uint _balance) public{
        payable(address(msg.sender)).transfer(_balance);
    }

}