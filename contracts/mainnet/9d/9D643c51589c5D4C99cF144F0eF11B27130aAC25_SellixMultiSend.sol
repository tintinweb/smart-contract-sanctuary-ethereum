/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

pragma solidity 0.4;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

library SafeERC20 {
    /**
    * @dev Transfer token for a specified address
    * @param _token erc20 The address of the ERC20 contract
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the _value of tokens to be transferred
    * @return bool based on the transfer if it was successful or not
    */
    function safeTransfer(Token _token, address _to, uint256 _value) internal returns (bool) {
        uint256 prevBalance = _token.balanceOf(address(this));

        if (prevBalance < _value) {
            // Insufficient funds
            return false;
        }

        address(_token).call(abi.encodeWithSignature("transfer(address,uint256)", _to, _value));

        // Fail if the new balance its not equal than previous balance sub _value
        return prevBalance - _value == _token.balanceOf(address(this));
    }
}

interface Token {
    function transfer(address _to, uint256 _value) external returns (bool success);
    function balanceOf(address who) external view returns (uint256 balance);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract SellixMultiSend {
    using SafeMath for uint256;
    
    address public owner;
    uint public tokenSendFee; // in wei
    uint public ethSendFee; // in wei

    
    constructor() public payable{
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
    
    function multiSendEth(address[] addresses, uint256[] amounts) public payable returns(bool success){
        uint total = 0;
        for(uint8 i = 0; i < amounts.length; i++){
            total = total.add(amounts[i]);
        }
        
        //ensure that the eth is enough to complete the transaction
        uint requiredAmount = total.add(ethSendFee * 1 wei); //.add(total.div(100));
        require(msg.value >= (requiredAmount * 1 wei));
        
        //transfer to each address
        for (uint8 j = 0; j < addresses.length; j++) {
            addresses[j].transfer(amounts[j] * 1 wei);
        }
        
        //return change to the sender
        if(msg.value * 1 wei > requiredAmount * 1 wei){
            uint change = msg.value.sub(requiredAmount);
            msg.sender.transfer(change * 1 wei);
        }
        return true;
    }
    
    function getbalance(address addr) public constant returns (uint value){
        return addr.balance;
    }
    
    function deposit() payable public returns (bool){
        return true;
    }
    
    function withdrawEth(address addr, uint amount) public onlyOwner returns(bool success){
        addr.transfer(amount * 1 wei);
        return true;
    }
    
    function withdrawToken(Token tokenAddr, address _to, uint _amount) public onlyOwner returns(bool success){
        SafeERC20.safeTransfer(tokenAddr, _to, _amount);
        return true;
    }
    
    function multiSendToken(Token tokenAddr, address[] addresses, uint256[] amounts) public payable returns(bool success){
        uint total = 0;
        address multisendContractAddress = this;
        for(uint8 i = 0; i < amounts.length; i++){
            total = total.add(amounts[i]);
        }
        
        require(msg.value * 1 wei >= tokenSendFee * 1 wei);
        
        // check if user has enough balance
        require(total <= tokenAddr.allowance(msg.sender, multisendContractAddress));
        
        // transfer token to addresses
        for (uint8 j = 0; j < addresses.length; j++) {
            tokenAddr.transferFrom(msg.sender, addresses[j], amounts[j]);
        }
        // transfer change back to the sender
        if(msg.value * 1 wei > (tokenSendFee * 1 wei)){
            uint change = (msg.value).sub(tokenSendFee);
            msg.sender.transfer(change * 1 wei);
        }
        return true;
        
    }
    
    function setTokenFee(uint _tokenSendFee) public onlyOwner returns(bool success){
        tokenSendFee = _tokenSendFee;
        return true;
    }
    
    function setEthFee(uint _ethSendFee) public onlyOwner returns(bool success){
        ethSendFee = _ethSendFee;
        return true;
    }
    
    function destroy (address _to) public onlyOwner {
        selfdestruct(_to);
    }
}