/**
 *Submitted for verification at Etherscan.io on 2022-03-05
*/

// Cosmic Kiss Bridge
// https://cosmickiss.io/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


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

contract CosmicBridgeETH {
    using SafeMath for uint256;

    uint256 public tax;
    address public relayer;
    address public operator;
    uint256 public minAmount;
    mapping(address => mapping(uint => bool)) public processedNonces;

    enum State { Deposit, Withdraw }
    
    event Transfer(
        address from,
        address to,
        uint256 amount,
        uint date,
        uint256 nonce,
        bytes signature,
        State indexed state
    );

    constructor(address _relayer,uint256 _tax,uint256 _minAmount) {
        minAmount = _minAmount;
        operator = msg.sender;
        tax = _tax;
        relayer = _relayer;
    }



function transferOperator(address newOperator) public returns(bool){
        require(msg.sender==operator,"only owner can call this function");
        operator = newOperator;        
        return true;
    }
    function updateRelayer(address newRelayer) public returns(bool) {
        require(msg.sender==operator,"only owner can call this function");
        relayer = newRelayer;        
        return true;
    }
    function updateTax(uint256 newTax) public returns(bool) {
        require(msg.sender==operator,"only owner can call this function");
        tax = newTax;
        return true;
    }

  function updateMinAmount(uint256 newMinAmount) public returns(bool) {
        require(msg.sender==operator,"only owner can call this function");
        minAmount = newMinAmount;
        return true;
    }
    
  function deposit(address to, uint amount, uint nonce, bytes calldata signature) external payable {
    require(msg.value>=minAmount,"insufficient amount");
    require(processedNonces[msg.sender][nonce] == false, 'transfer already processed');
    require(msg.value>=amount,"insufficient amount");
    processedNonces[msg.sender][nonce] = true;
        
    emit Transfer(
      msg.sender,
      to,
      amount,
      block.timestamp,
      nonce,
      signature,
      State.Deposit
    );
  }

  function processedNonceses(address[] memory addresses,uint256[] memory nonces) public view returns(bool[] memory){
    bool[] memory toReturn = new bool[](addresses.length);

    if(addresses.length==nonces.length){
      for(uint256 i=0;i<nonces.length;i++){
        toReturn[i]= processedNonces[addresses[i]][nonces[i]]; 
      }
    }
    return toReturn;    
  }



  function withdraw(
        address from, 
        address payable to, 
        uint256 amount, 
        uint nonce,
        bytes calldata signature,
        uint256 _gas
    ) external {
      
        require(msg.sender==relayer,"Only relayer can call this function");
        uint256 _tax = amount.mul(tax).div(10000);
        require((amount.sub(_tax).sub(_gas))>0,"wrong amount");
        require(processedNonces[from][nonce] == false, 'transfer already processed');
        bytes32 message = prefixed(keccak256(abi.encodePacked(
            from, 
            to, 
            amount,
            nonce
        )));
        require(recoverSigner(message, signature) == from , 'wrong signature');
        require(address(this).balance>amount,"insufficient balance");
        processedNonces[from][nonce] = true;

        to.transfer(amount.sub(_tax).sub(_gas));

        emit Transfer(
            from,
            to,
            amount,
            block.timestamp,
            nonce,
            signature,
            State.Withdraw
        );    
    }

    function addFunds() public payable {} 

  function prefixed(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(
      '\x19Ethereum Signed Message:\n32', 
      hash
    ));
  }

  function recoverSigner(bytes32 message, bytes memory sig)
    internal
    pure
    returns (address)
  {
    uint8 v;
    bytes32 r;
    bytes32 s;
  
    (v, r, s) = splitSignature(sig);
  
    return ecrecover(message, v, r, s);
  }

  function splitSignature(bytes memory sig)
    internal
    pure
    returns (uint8, bytes32, bytes32)
  {
    require(sig.length == 65);
  
    bytes32 r;
    bytes32 s;
    uint8 v;
  
    assembly {
        // first 32 bytes, after the length prefix
        r := mload(add(sig, 32))
        // second 32 bytes
        s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
        v := byte(0, mload(add(sig, 96)))
    }
  
    return (v, r, s);
  }
}