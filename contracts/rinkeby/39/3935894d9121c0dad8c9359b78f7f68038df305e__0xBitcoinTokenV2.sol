/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

pragma solidity ^0.8.6;


// ----------------------------------------------------------------------------

// '0xBitcoin Token' contract  

// Mineable ERC20 Token using Proof Of Work

//

// Symbol      : 0xBTC

// Name        : 0xBitcoin Token

// Total supply: 21,000,000.00

// Decimals    : 8

// Version     : 2

//


// ----------------------------------------------------------------------------






// ----------------------------------------------------------------------------

// ERC Token Standard #20 Interface

// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md

// ----------------------------------------------------------------------------

abstract contract ERC20Interface {

    function totalSupply() external virtual view returns (uint);

    function balanceOf(address tokenOwner) external virtual view returns (uint balance);

    function allowance(address tokenOwner, address spender) external virtual view returns (uint remaining);

    function transfer(address to, uint tokens) external virtual returns (bool success);

    function approve(address spender, uint tokens) external virtual returns (bool success);

    function transferFrom(address from, address to, uint tokens) external virtual returns (bool success);

    function _approve(address owner, address spender, uint tokens) internal virtual returns (bool success);

    function _transfer(address from, address to, uint tokens) internal virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

contract ERC20Standard is ERC20Interface {
 
    string public symbol;
    string public name;

    uint8 public decimals;

    mapping(address => uint) balances;   
    mapping(address => mapping(address => uint)) allowed;
 
    uint public override totalSupply; 



    function _transfer(address from, address to, uint tokens) internal override returns (bool success) {

        balances[from] = balances[from] - (tokens);

        balances[to] = balances[to] + (tokens);

        emit Transfer(from, to, tokens);

        return true;
    }



    // ------------------------------------------------------------------------

    // Get the token balance for account `tokenOwner`

    // ------------------------------------------------------------------------

    function balanceOf(address tokenOwner) public override view returns (uint balance) {

        return balances[tokenOwner];

    }



    // ------------------------------------------------------------------------

    // Transfer the balance from token owner's account to `to` account

    // - Owner's account must have sufficient balance to transfer

    // - 0 value transfers are allowed

    // ------------------------------------------------------------------------

    function transfer(address to, uint tokens) public override returns (bool success) {

        return _transfer(msg.sender, to, tokens);

    }

  


    // ------------------------------------------------------------------------

    // Token owner can approve for `spender` to transferFrom(...) `tokens`

    // from the token owner's account

    //

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md

    // recommends that there are no checks for the approval double-spend attack

    // as this should be implemented in user interfaces

    // ------------------------------------------------------------------------

    function approve(address spender, uint tokens) public override returns (bool success) {

        return _approve(msg.sender, spender,tokens);

    }

    function _approve(address owner, address spender, uint tokens) internal override returns (bool success) {

        allowed[owner][spender] = tokens;

        emit Approval(owner, spender, tokens);

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

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        
        allowed[from][msg.sender] = allowed[from][msg.sender] - (tokens);

        return _transfer(from,to,tokens);

    }


    // ------------------------------------------------------------------------

    // Returns the amount of tokens approved by the owner that can be

    // transferred to the spender's account

    // ------------------------------------------------------------------------

    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {

        return allowed[tokenOwner][spender];

    }


}




abstract contract EIP918Interface {

  function challengeNumber() virtual external returns (bytes32);
  function tokensMinted() virtual external returns (uint256);
  function miningTarget() virtual external returns (uint256);
  function maxSupplyForEra() virtual external returns (uint256);  
  function latestDifficultyPeriodStarted() virtual external returns (uint256);
  function rewardEra() virtual external returns (uint256);
  function epochCount() virtual external returns (uint256); 
  function getMiningReward() virtual external returns (uint256);

}


library ECRecover {
    /**
     * @notice Recover signer's address from a signed message
     * @dev Adapted from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/65e4ffde586ec89af3b7e9140bdc9235d1254853/contracts/cryptography/ECDSA.sol
     * Modifications: Accept v, r, and s as separate arguments
     * @param digest    Keccak-256 hash digest of the signed message
     * @param v         v of the signature
     * @param r         r of the signature
     * @param s         s of the signature
     * @return Signer address
     */
    function recover(
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert("ECRecover: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECRecover: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(digest, v, r, s);
        require(signer != address(0), "ECRecover: invalid signature");

        return signer;
    }
}



contract EIP712Domain {
    /**
     * @dev EIP712 Domain Separator
     */
    bytes32 public DOMAIN_SEPARATOR;
}



/**
 * @title EIP712
 * @notice A library that provides EIP712 helper functions
 */
library EIP712 {
    /**
     * @notice Make EIP712 domain separator
     * @param name      Contract name
     * @param version   Contract version
     * @return Domain separator
     */
    function makeDomainSeparator(string memory name, string memory version)
        internal
        view
        returns (bytes32)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return
            keccak256(
                abi.encode(
                    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    chainId,
                    address(this)
                )
            );
    }

    /**
     * @notice Recover signer's address from a EIP712 signature
     * @param domainSeparator   Domain separator
     * @param v                 v of the signature
     * @param r                 r of the signature
     * @param s                 s of the signature
     * @param typeHashAndData   Type hash concatenated with data
     * @return Signer's address
     */
    function recover(
        bytes32 domainSeparator,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes memory typeHashAndData
    ) internal pure returns (address) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(typeHashAndData)
            )
        );
        return ECRecover.recover(digest, v, r, s);
    }
 
}


/**
 * @title EIP-2612
 * @notice Provide internal implementation for gas-abstracted approvals
 */
contract EIP2612 is EIP712Domain,ERC20Standard {
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    bytes32
        public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    mapping(address => uint256) private _permitNonces;

    /**
     * @notice Nonces for permit
     * @param owner Token owner's address (Authorizer)
     * @return Next nonce
     */
    function nonces(address owner) external view returns (uint256) {
        return _permitNonces[owner];
    }

    /**
     * @notice Verify a signed approval permit and execute if valid
     * @param owner     Token owner's address (Authorizer)
     * @param spender   Spender's address
     * @param value     Amount of allowance
     * @param deadline  The time at which this expires (unix time)
     * @param v         v of the signature
     * @param r         r of the signature
     * @param s         s of the signature
     */
    function _permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        require(deadline >= block.timestamp, "Permit is expired");

        bytes memory data = abi.encode(
            PERMIT_TYPEHASH,
            owner,
            spender,
            value,
            _permitNonces[owner]++,
            deadline
        );
        require(
            EIP712.recover(DOMAIN_SEPARATOR, v, r, s, data) == owner,
            "EIP2612: invalid signature"
        );

        _approve(owner, spender, value);
    }

 
}





library ExtendedMath {


    //return the smaller of the two inputs (a or b)
    function limitLessThan(uint a, uint b) internal pure returns (uint c) {

        if(a > b) return b;

        return a;

    }
}



contract _0xBitcoinTokenV2 is ERC20Standard, EIP2612 {
   
    using ExtendedMath for uint;
   
    string public version;    

    uint public latestDifficultyPeriodStarted;

    uint public epochCount; 

    uint public _BLOCKS_PER_READJUSTMENT = 1024;   
    uint public  _MINIMUM_TARGET = 2**16;      
    uint public  _MAXIMUM_TARGET = 2**234;


    uint public miningTarget;
    bytes32 public challengeNumber;  

    uint public rewardEra;
    uint public maxSupplyForEra;

    uint public currentMiningReward;
    address public lastRewardTo;
    uint public lastRewardAmount;
    uint public lastRewardEthBlockNumber; 

    uint public tokensMinted;

    address public originalTokenContract; 

    uint256 public amountDeposited;

    event Mint(address from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);
    

    constructor( address _originalTokenContract ) {

        originalTokenContract = _originalTokenContract;

        symbol = "0xBTC2";

        name = "0xBitcoin Token v2";

        decimals = 8;

        version = "2";

        DOMAIN_SEPARATOR = EIP712.makeDomainSeparator(name, version);

        totalSupply = 21000000 * 10**uint(decimals); 

        initialize(); 

    }

    //set values to continue state forwards where it left off 
    function initialize() internal {
 
      epochCount = EIP918Interface( originalTokenContract  ).epochCount();
      
      tokensMinted = EIP918Interface( originalTokenContract  ).tokensMinted();

      rewardEra = EIP918Interface(originalTokenContract).rewardEra();
      maxSupplyForEra = EIP918Interface(originalTokenContract).maxSupplyForEra();

      miningTarget = EIP918Interface(originalTokenContract).miningTarget();

      latestDifficultyPeriodStarted = EIP918Interface(originalTokenContract).latestDifficultyPeriodStarted();   
      challengeNumber = EIP918Interface(originalTokenContract).challengeNumber();
        
      currentMiningReward = EIP918Interface(originalTokenContract).getMiningReward();

    }


    function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success) {

        return mintTo(nonce,msg.sender);

    }

    function mintTo(uint256 nonce, address minter) public returns (bool success) {
    
        //the PoW must contain work that includes a recent ethereum block hash (challenge number) and the msg.sender's address to prevent MITM attacks
        bytes32 digest = keccak256(abi.encodePacked(challengeNumber, minter, nonce ));

        //the digest must be smaller than the target
        if(uint256(digest) > miningTarget) revert();

        //only allow one reward for each block
        require(lastRewardEthBlockNumber != block.number);
      
        uint reward_amount = currentMiningReward;

        balances[minter] = balances[minter] + (reward_amount);
        emit Transfer(address(this), minter, reward_amount);

        tokensMinted = tokensMinted + (reward_amount);

        //Cannot mint more tokens than there are
        require(tokensMinted <= maxSupplyForEra);

        //set readonly diagnostics data
        lastRewardTo = minter;
        lastRewardAmount = reward_amount;
        lastRewardEthBlockNumber = block.number;

        _startNewMiningEpoch();

        emit Mint(minter, reward_amount, epochCount, challengeNumber );        

        return true;

    }


    
    function _startNewMiningEpoch() internal {

      //if max supply for the era will be exceeded next reward round then enter the new era before that happens

      //32 is the final reward era, almost all tokens minted
      //once the final era is reached, more tokens will not be given out because the assert function
      if(tokensMinted + (currentMiningReward) > maxSupplyForEra && rewardEra < 31)
      {
        rewardEra = rewardEra + 1;
        currentMiningReward = (50 * 10**uint(decimals) ) / ( 2**rewardEra ) ;
      }

      //set the next minted supply at which the era will change
      //total supply is 2100000000000000  because of 8 decimal places
      maxSupplyForEra = totalSupply - (totalSupply / ( 2**(rewardEra + 1)));

      epochCount = epochCount + 1;

      //every so often, readjust difficulty. Dont readjust when deploying
      if(epochCount % _BLOCKS_PER_READJUSTMENT == 0)
      {
        _reAdjustDifficulty();
      }


      //make the latest ethereum block hash a part of the next challenge for PoW to prevent pre-mining future blocks
      challengeNumber = blockhash(block.number - 1);      

    }


 
    function _reAdjustDifficulty() internal {

        uint ethBlocksSinceLastDifficultyPeriod = block.number - latestDifficultyPeriodStarted;

        uint epochsMined = _BLOCKS_PER_READJUSTMENT; 

        uint targetEthBlocksPerDiffPeriod = epochsMined * 60; 

        //if there were less eth blocks passed in time than expected
        if( ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod )
        {
          uint excess_block_pct = (targetEthBlocksPerDiffPeriod * (100)) / ( ethBlocksSinceLastDifficultyPeriod );

          uint excess_block_pct_extra = (excess_block_pct - 100).limitLessThan(1000);
          // If there were 5% more blocks mined than expected then this is 5.  If there were 100% more blocks mined than expected then this is 100.

          //make it harder
          miningTarget = miningTarget - ((miningTarget / 2000) * excess_block_pct_extra);   //by up to 50 %
        }else{
          uint shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod * (100)) / ( targetEthBlocksPerDiffPeriod );

          uint shortage_block_pct_extra = (shortage_block_pct - 100).limitLessThan(1000); //always between 0 and 1000

          //make it easier
          miningTarget = miningTarget + ((miningTarget / 2000) * shortage_block_pct_extra);   //by up to 50 %
        }


        latestDifficultyPeriodStarted = block.number;

        if(miningTarget < _MINIMUM_TARGET) //most difficult
        {
          miningTarget = _MINIMUM_TARGET;
        }

        if(miningTarget > _MAXIMUM_TARGET) //most easy
        {
          miningTarget = _MAXIMUM_TARGET;
        }
    }


    //this is a recent ethereum block hash, used to prevent pre-mining future blocks
    function getChallengeNumber() public view returns (bytes32) {
        return challengeNumber;
    }

    //the number of zeroes the digest of the PoW solution requires.  Auto adjusts
     function getMiningDifficulty() public view returns (uint) {
        return _MAXIMUM_TARGET / (miningTarget);
    }

    function getMiningTarget() public view returns (uint) {
       return miningTarget;
    }


     /**
     * @dev Burn v1 tokens to receive v2 tokens
     * @param amount Amount of original tokens to change
     */
    function deposit(address from, uint amount) internal returns (bool)
    {         
        require( ERC20Interface( originalTokenContract ).transferFrom( from, address(this), amount) );
        
        balances[from] = balances[from] + (amount);
        amountDeposited = amountDeposited + (amount);
        
        emit Transfer(address(this), from, amount);
        
        return true;
    }

   
    function getMintDigest(uint256 nonce, address minter, bytes32 challenge_number) public view returns (bytes32 digesttest) {

        bytes32 digest = keccak256(abi.encodePacked(challenge_number,minter,nonce));

        return digest;

    }
      
    function checkMintSolution(uint256 nonce, address minter, bytes32 challenge_number, uint testTarget) public view returns (bool success) {

        bytes32 digest = keccak256(abi.encodePacked(challenge_number,minter,nonce));

        if(uint256(digest) > testTarget) revert();

        return true;

    }

    function minedSupply() public view returns (uint) {

        return tokensMinted;

    }
   
      /**
     * @notice Update allowance with a signed permit
     * @param owner       Token owner's address (Authorizer)
     * @param spender     Spender's address
     * @param value       Amount of allowance
     * @param deadline    Expiration time, seconds since the epoch
     * @param v           v of the signature
     * @param r           r of the signature
     * @param s           s of the signature
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        _permit(owner, spender, value, deadline, v, r, s);
    }

      
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public returns (bool success) {
        
        require( token == originalTokenContract );
        
        require( deposit(from, tokens) );

        return true;

     }


    // ------------------------------------------------------------------------

    // Don't accept ETH

    // ------------------------------------------------------------------------

    receive() external payable {

        revert();

    }

 
}