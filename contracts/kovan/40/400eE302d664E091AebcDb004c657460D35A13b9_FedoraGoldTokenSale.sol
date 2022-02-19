/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

pragma solidity ^0.5.16;

// ----------------------------------------------------------------------------
// Send MATIC to Get Fedora Gold Token - FEDG
// Author: Rebalance Development Team
// Ver 1.0
//
// Deployed to : 
// Symbol      : FEDG
// Name        : Fedora Gold Token Sale
// Total supply: 50,000,000,000
// Decimals    : 18
// Price : enter price while creating contract or set later
// Details of Contract : Users will be able to Redeem FEDG tokens by sending > 1 Matic amount to contract.
// Users will have to enter Fedora Gold Coin Transaction ID after sending FED coins to Burn address.
// After entering Txn Id, it will be saved in the smart contract and system will get the token amount from 
// Fedora Gold Coin Blockchain and send FEDG Tokens to the ERC 20 Address.
// Only Use Rebalance DAPP to interact with this Smart Contract.
// ------------------------------------------------------------------------------------------------------------


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Owned {

    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract FedoraGoldToken1 is Owned  {
    
   mapping(address => uint256) balances;
   mapping(address => mapping(address => uint)) allowed;
   //uint _totalSupply;
    
   event Transfer(address indexed from, address indexed to, uint tokens);

   function balanceOf(address tokenOwner) public view returns (uint balance);

   // To release tokens to the address that have send ether.
   function releaseTokens(address _receiver, uint _amount) public;

   // To take back tokens after refunding ether.
   function refundTokens(address _receiver, uint _amount) public;
   
   function transfer(address to, uint tokens) public returns (bool);
   
   function transferFrom(address from, address to, uint tokens) public returns (bool success);

}

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

contract FedoraGoldTokenSale {
   
   using SafeMath for uint256;

   uint public redeemStart;
   uint public redeemEnd;
   uint public tokenRate;
   FedoraGoldToken1 public token;   
   uint public fundingGoal;
   uint public tokensRedeemed;
   uint public etherRaised;
   address payable public owner;
   uint decimals = 18;
   
   event BuyTokens(address buyer, uint etherAmount);
   event RedeemTokens(address buyer, uint etherAmount);
   event Transfer(address indexed from, address indexed to, uint tokens);
   event BuyerBalance(address indexed buyer, uint buyermoney);
   event BuyerTokensAndRate(address indexed buyer, uint buyermoney, uint convertrate);
   event TakeTokensBack(address ownerAddress, uint quantity );
   
   mapping(string => bool) transactionidexists;
   string[] public transactionsArray;

   mapping(address => bool) addressredeemed;
   address[] public redeemedaddressesArray;

   mapping(address => FedTransaction ) fedtransactions;

   struct FedTransaction {
       string transactionid;
       address destinationaddress;
       uint amountcoins;
   }


   event RecordSetFedTransaction(string _transaction, address _fedaddress, uint _funds );
   event RecordTxnNotExist(string _transaction);
   event RecordGetFedTransaction(string transaction, address myfedaddress, uint funds);
   
   modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

   constructor( uint _tokenRate, address _tokenAddress, uint _fundingGoal) public {

      require( _tokenRate != 0 &&
      _tokenAddress != address(0) &&
      _fundingGoal != 0);
     
      redeemStart = now;
      redeemStart = block.timestamp;
      
      redeemEnd = redeemStart + 4 weeks;
      tokenRate = _tokenRate;
      token = FedoraGoldToken1(_tokenAddress);
      fundingGoal = _fundingGoal;
      owner = msg.sender;
   }


    // Function to receive Ether. msg.data must be empty
    // this fallback method will always call redeem() method
    function() external payable {
       redeem();
    }

    // buy tokens based on the Matic to token conversion rate  
    function buy() public payable {

      emit BuyTokens( msg.sender , msg.value);
	  
      require(msg.sender!=owner);
      require(etherRaised < fundingGoal);
      require(now < redeemEnd && now > redeemStart);
	  
      uint tokensToGet;
      uint etherUsed =  msg.value;
      tokensToGet = etherUsed.mul(tokenRate).div(10**18);

      owner.transfer(etherUsed);
      
      // transfer tokens
      token.transfer(msg.sender, tokensToGet);
      
      emit BuyerBalance(msg.sender, tokensToGet);
      emit BuyerTokensAndRate(msg.sender, tokensToGet, tokenRate);
      
      tokensRedeemed += tokensToGet;
      etherRaised += etherUsed;
   }

   function redeem() public payable {

      emit RedeemTokens( msg.sender , msg.value);
	  
      require(msg.sender!=owner);
      require(msg.value>=1);
      require(now < redeemEnd && now > redeemStart);

	  FedTransaction memory p = fedtransactions[msg.sender];
     
      require(transactionidexists[p.transactionid],"transaction doesnot exist");
	  
      uint tokensToGet;
      uint etherUsed = msg.value;
      tokensToGet = p.amountcoins.mul(1).div(10**18);

      owner.transfer(etherUsed);
      
      // transfer tokens if not reedemed yet

      require(!addressredeemed[p.destinationaddress],"address already redeemed");

      token.transfer(p.destinationaddress, tokensToGet);

      addressredeemed[p.destinationaddress] = true;
      redeemedaddressesArray.push(p.destinationaddress);
      
      emit BuyerBalance(msg.sender, tokensToGet);
      
      tokensRedeemed += tokensToGet;
      etherRaised += etherUsed;
   }
   
    function setRedeemEndDate(uint time) public onlyOwner {
        require(time>0);
        redeemEnd = time;
    }

    function getRedeemEndDate() public view returns (uint) {
      return redeemEnd;
    }
   
    function setFundingGoal(uint goal) public onlyOwner {
        fundingGoal = goal;
    }

    function getFundingGoal() public view returns (uint) {
     return fundingGoal;
   }
   
   function setTokenRate(uint tokenEthMultiplierRate) public onlyOwner {
        tokenRate = tokenEthMultiplierRate;
   }
   
   // since 1:1 will be used, so no 
   function getTokenRate() public view returns (uint) {
     return tokenRate;
   }

   // Take the locked tokens back once the bridge is over
   function takeTokensBackAfterRedeemOver(uint quantity) public onlyOwner {
        token.transfer(owner, quantity);
        emit TakeTokensBack(owner, quantity);
   }
   
  
  // add transactions to the approved List
  // for security reasons, only contract creater can add transactions
  function setFedtransaction(string memory _transaction, address _fedaddress, uint _funds ) public onlyOwner {
	 emit RecordSetFedTransaction(_transaction,_fedaddress,_funds);
	 FedTransaction memory newTransaction = FedTransaction(_transaction, _fedaddress,_funds );
     // transaction hash should not exist already
     require(!transactionidexists[_transaction], "transaction hash already used");
     // claim address should not exist already
     require(fedtransactions[_fedaddress].destinationaddress!=_fedaddress,"address already used");
	 emit RecordTxnNotExist(_transaction);
     fedtransactions[_fedaddress] = newTransaction;
     transactionsArray.push(_transaction);
     transactionidexists[_transaction] = true;
  }

  // List of transaction hashes which already submitted and approved on blockchain
  function getTransactions() view public returns(string[] memory ){
        return transactionsArray;
  }

  // List of addresses which already redeemed tokens
  function getRedeemedAddresses() view public returns(address[] memory ){
        return redeemedaddressesArray;
  }

  // Get transaction details based on one address
  function getFedtransaction(address payable fedaddress) public view returns (string memory transaction, address myfedaddress, uint funds)
  {  
     // copy the data into memory
     FedTransaction memory p = fedtransactions[fedaddress];
     // break the struct's members out into a tuple in the same order that they appear in the struct
     return (p.transactionid,  p.destinationaddress, p.amountcoins);
  }

 }