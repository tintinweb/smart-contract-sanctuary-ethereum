/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

pragma solidity ^0.4.18;


// ----------------------------------------------------------------------------

// '0xBitcoin Token' contract

// Mineable ERC20 Token using Proof Of Work

//

// Symbol      : 0xBTC

// Name        : 0xBitcoin Token

// Total supply: 21,000,000.00

// Decimals    : 8

//


// ----------------------------------------------------------------------------



// ----------------------------------------------------------------------------

// Safe maths

// ----------------------------------------------------------------------------

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {

        c = a + b;

        require(c >= a);

    }

    function sub(uint a, uint b) internal pure returns (uint c) {

        require(b <= a);

        c = a - b;

    }

    function mul(uint a, uint b) internal pure returns (uint c) {

        c = a * b;

        require(a == 0 || c / a == b);

    }

    function div(uint a, uint b) internal pure returns (uint c) {

        require(b > 0);

        c = a / b;

    }

}



library ExtendedMath {


    //return the smaller of the two inputs (a or b)
    function limitLessThan(uint a, uint b) internal pure returns (uint c) {

        if(a > b) return b;

        return a;

    }
}

// ----------------------------------------------------------------------------

// ERC Token Standard #20 Interface

// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md

// ----------------------------------------------------------------------------

contract ERC20Interface {

    function totalSupply() public constant returns (uint);

    function balanceOf(address tokenOwner) public constant returns (uint balance);

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);

    function transfer(address to, uint tokens) public returns (bool success);

    function approve(address spender, uint tokens) public returns (bool success);

    function transferFrom(address from, address to, uint tokens) public returns (bool success);


    event Transfer(address indexed from, address indexed to, uint tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}


contract EIP918Interface {

  function challengeNumber() external returns (bytes32);
  function tokensMinted() external returns (uint256);
  function miningTarget() external returns (uint256);
  function maxSupplyForEra() external returns (uint256);  
  function latestDifficultyPeriodStarted() external returns (uint256);
  function rewardEra() external returns (uint256);
  function epochCount() external returns (uint256); 

}


// ----------------------------------------------------------------------------

// Contract function to receive approval and execute function in one call

//

// Borrowed from MiniMeToken

// ----------------------------------------------------------------------------

contract ApproveAndCallFallBack {

    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;

}



// ----------------------------------------------------------------------------

// Owned contract

// ----------------------------------------------------------------------------

 


// ----------------------------------------------------------------------------

// ERC20 Token, with the addition of symbol, name and decimals and an

// initial fixed supply

// ----------------------------------------------------------------------------

contract _0xBitcoinTokenUpgrade is ERC20Interface {

    using SafeMath for uint;
    using ExtendedMath for uint;


    string public symbol;

    string public name;

    uint8 public decimals;

    uint public _totalSupply;

    uint public latestDifficultyPeriodStarted;

    uint public epochCount; 

    uint public _BLOCKS_PER_READJUSTMENT = 1024;   
    uint public  _MINIMUM_TARGET = 2**16;      
    uint public  _MAXIMUM_TARGET = 2**234;


    uint public miningTarget;
    bytes32 public challengeNumber;  

    uint public rewardEra;
    uint public maxSupplyForEra;

    address public lastRewardTo;
    uint public lastRewardAmount;
    uint public lastRewardEthBlockNumber; 

    mapping(bytes32 => bool) public digestUsedForSolution;

    uint public tokensMinted;    

    mapping(address => uint) balances;   
    mapping(address => mapping(address => uint)) allowed;

    address public originalTokenContract; 
    uint256 public originalMinedSupply;  
    bool public initialized; 

    uint256 public amountDeposited;

    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

    // ------------------------------------------------------------------------

    // Constructor

    // ------------------------------------------------------------------------

    function _0xBitcoinTokenUpgrade( address _originalTokenContract ) public {

        originalTokenContract = _originalTokenContract;

        symbol = "0xBTC";

        name = "0xBitcoin Token";

        decimals = 8;
        

        _totalSupply = 21000000 * 10**uint(decimals);
 

        initialize(); 


        //You must mine this ERC20 token
        //balances[owner] = _totalSupply;
        //Transfer(address(0), owner, _totalSupply);

    }




    function initialize() internal{

      require(!initialized);
 
      epochCount = EIP918Interface( originalTokenContract  ).epochCount();

      //set values to pick up where was left off 
      tokensMinted = EIP918Interface( originalTokenContract  ).tokensMinted();
      originalMinedSupply = tokensMinted;

      rewardEra = EIP918Interface(originalTokenContract).rewardEra();
      maxSupplyForEra = EIP918Interface(originalTokenContract).maxSupplyForEra();

      miningTarget = EIP918Interface(originalTokenContract).miningTarget();

      latestDifficultyPeriodStarted = EIP918Interface(originalTokenContract).latestDifficultyPeriodStarted();   
      challengeNumber = EIP918Interface(originalTokenContract).challengeNumber();
        
      initialized = true;
    }


    function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success) {
        return mintTo(nonce,msg.sender);
    }

    function mintTo(uint256 nonce, address minter) public returns (bool success) {
        
        require(initialized);

        //the PoW must contain work that includes a recent ethereum block hash (challenge number) and the msg.sender's address to prevent MITM attacks
        bytes32 digest = keccak256(challengeNumber, minter, nonce );

        //the digest must be smaller than the target
        if(uint256(digest) > miningTarget) revert();

        //only allow one reward for each digest
        bool digestUsed = digestUsedForSolution[digest];
        digestUsedForSolution[digest] = true;
        require(digestUsed == false);  //prevent the same answer from awarding twice

        uint reward_amount = getMiningReward();

        balances[minter] = balances[minter].add(reward_amount);
        Transfer(address(this), minter, reward_amount);

        tokensMinted = tokensMinted.add(reward_amount);

        //Cannot mint more tokens than there are
        require(tokensMinted <= maxSupplyForEra);

        //set readonly diagnostics data
        lastRewardTo = minter;
        lastRewardAmount = reward_amount;
        lastRewardEthBlockNumber = block.number;


        _startNewMiningEpoch();

        Mint(minter, reward_amount, epochCount, challengeNumber );        

        return true;

    }


    
    function _startNewMiningEpoch() internal {

      //if max supply for the era will be exceeded next reward round then enter the new era before that happens

      //32 is the final reward era, almost all tokens minted
      //once the final era is reached, more tokens will not be given out because the assert function
      if(tokensMinted.add(getMiningReward()) > maxSupplyForEra && rewardEra < 31)
      {
        rewardEra = rewardEra + 1;
      }

      //set the next minted supply at which the era will change
      // total supply is 2100000000000000  because of 8 decimal places
      maxSupplyForEra = _totalSupply - _totalSupply.div( 2**(rewardEra + 1));

      epochCount = epochCount.add(1);

      //every so often, readjust difficulty. Dont readjust when deploying
      if(epochCount % _BLOCKS_PER_READJUSTMENT == 0)
      {
        _reAdjustDifficulty();
      }


      //make the latest ethereum block hash a part of the next challenge for PoW to prevent pre-mining future blocks
      //do this last since this is a protection mechanism in the mint() function
      challengeNumber = block.blockhash(block.number - 1);      

    }


 
    function _reAdjustDifficulty() internal {


        uint ethBlocksSinceLastDifficultyPeriod = block.number - latestDifficultyPeriodStarted;
        //assume 360 ethereum blocks per hour

        //we want miners to spend 10 minutes to mine each 'block', about 60 ethereum blocks = one 0xbitcoin epoch
        uint epochsMined = _BLOCKS_PER_READJUSTMENT; //256

        uint targetEthBlocksPerDiffPeriod = epochsMined * 60; //should be 60 times slower than ethereum

        //if there were less eth blocks passed in time than expected
        if( ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod )
        {
          uint excess_block_pct = (targetEthBlocksPerDiffPeriod.mul(100)).div( ethBlocksSinceLastDifficultyPeriod );

          uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(1000);
          // If there were 5% more blocks mined than expected then this is 5.  If there were 100% more blocks mined than expected then this is 100.

          //make it harder
          miningTarget = miningTarget.sub(miningTarget.div(2000).mul(excess_block_pct_extra));   //by up to 50 %
        }else{
          uint shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod.mul(100)).div( targetEthBlocksPerDiffPeriod );

          uint shortage_block_pct_extra = shortage_block_pct.sub(100).limitLessThan(1000); //always between 0 and 1000

          //make it easier
          miningTarget = miningTarget.add(miningTarget.div(2000).mul(shortage_block_pct_extra));   //by up to 50 %
        }



        latestDifficultyPeriodStarted = block.number;

        if(miningTarget < _MINIMUM_TARGET) //very difficult
        {
          miningTarget = _MINIMUM_TARGET;
        }

        if(miningTarget > _MAXIMUM_TARGET) //very easy
        {
          miningTarget = _MAXIMUM_TARGET;
        }
    }


    //this is a recent ethereum block hash, used to prevent pre-mining future blocks
    function getChallengeNumber() public constant returns (bytes32) {
        return challengeNumber;
    }

    //the number of zeroes the digest of the PoW solution requires.  Auto adjusts
     function getMiningDifficulty() public constant returns (uint) {
        return _MAXIMUM_TARGET.div(miningTarget);
    }

    function getMiningTarget() public constant returns (uint) {
       return miningTarget;
    }


     /**
     *  
     * @dev Deposit original tokens
     * @param amount Amount of original tokens to charge
     */
    function deposit(address from, uint amount) internal returns (bool)
    {
         
        require( ERC20Interface( originalTokenContract ).transferFrom( from, address(this), amount) );
            
        balances[from] = balances[from].add(amount);
        amountDeposited = amountDeposited.add(amount);
        
        Transfer(address(this), from, amount);
        
        return true;
    }



    /**
     * @dev Withdraw original tokens
     * @param amount Amount of original tokens to release
     */
    function withdraw(uint amount) public returns (bool)
    {
        address from = msg.sender;
         
        balances[from] = balances[from].sub(amount);
        amountDeposited = amountDeposited.sub(amount);
        
        Transfer( from, address(this), amount);
            
        require( ERC20Interface( originalTokenContract ).transfer( from, amount) ); 
        
        return true;
    }
    


    //21m coins total
    //reward begins at 50 and is cut in half every reward era (as tokens are mined)
    function getMiningReward() public constant returns (uint) {
        //once we get half way thru the coins, only get 25 per block

         //every reward era, the reward amount halves.

         return (50 * 10**uint(decimals) ).div( 2**rewardEra ) ;

    }

    //help debug mining software
    function getMintDigest(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number) public view returns (bytes32 digesttest) {

        bytes32 digest = keccak256(challenge_number,msg.sender,nonce);

        return digest;

    }

        //help debug mining software
    function checkMintSolution(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint testTarget) public view returns (bool success) {

        bytes32 digest = keccak256(challenge_number,msg.sender,nonce);

        if(uint256(digest) > testTarget) revert();

        return (digest == challenge_digest);

    }


    



    // ------------------------------------------------------------------------

    // Total supply

    // ------------------------------------------------------------------------

    function totalSupply() public constant returns (uint) {

        return _totalSupply;

    }


    function minedSupply() public constant returns (uint) {

        return tokensMinted;

    }



    // ------------------------------------------------------------------------

    // Get the token balance for account `tokenOwner`

    // ------------------------------------------------------------------------

    function balanceOf(address tokenOwner) public constant returns (uint balance) {

        return balances[tokenOwner];

    }



    // ------------------------------------------------------------------------

    // Transfer the balance from token owner's account to `to` account

    // - Owner's account must have sufficient balance to transfer

    // - 0 value transfers are allowed

    // ------------------------------------------------------------------------

    function transfer(address to, uint tokens) public returns (bool success) {

        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[to] = balances[to].add(tokens);

        Transfer(msg.sender, to, tokens);

        return true;

    }



    // ------------------------------------------------------------------------

    // Token owner can approve for `spender` to transferFrom(...) `tokens`

    // from the token owner's account

    //

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md

    // recommends that there are no checks for the approval double-spend attack

    // as this should be implemented in user interfaces

    // ------------------------------------------------------------------------

    function approve(address spender, uint tokens) public returns (bool success) {

        allowed[msg.sender][spender] = tokens;

        Approval(msg.sender, spender, tokens);

        return true;

    }



    // ------------------------------------------------------------------------

    // Transfer `tokens` from the `from` account to the `to` account

    //

    // The calling account must already have sufficient tokens approve(...)-d

    // for spending from the `from` account and

    // - From account must have sufficient balance to transfer

    // - Spender must have sufficient allowance to transfer

    // - 0 value transfers are allowed

    // ------------------------------------------------------------------------

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {

        balances[from] = balances[from].sub(tokens);

        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);

        balances[to] = balances[to].add(tokens);

        Transfer(from, to, tokens);

        return true;

    }



    // ------------------------------------------------------------------------

    // Returns the amount of tokens approved by the owner that can be

    // transferred to the spender's account

    // ------------------------------------------------------------------------

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {

        return allowed[tokenOwner][spender];

    }



    // ------------------------------------------------------------------------

    // Token owner can approve for `spender` to transferFrom(...) `tokens`

    // from the token owner's account. The `spender` contract function

    // `receiveApproval(...)` is then executed

    // ------------------------------------------------------------------------

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {

        allowed[msg.sender][spender] = tokens;

        Approval(msg.sender, spender, tokens);

        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);

        return true;

    }


      
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public returns (bool success) {
        
        require( token == originalTokenContract );
        
        require( deposit(from, tokens) );

        return true;

     }


    // ------------------------------------------------------------------------

    // Don't accept ETH

    // ------------------------------------------------------------------------

    function () public payable {

        revert();

    }


 
}