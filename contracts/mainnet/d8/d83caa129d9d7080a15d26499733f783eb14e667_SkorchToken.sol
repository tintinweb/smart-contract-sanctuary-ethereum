pragma solidity ^0.4.18;


// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0kxolc:;,,'''''''''',,;:cloxk0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMWN0kdl:,''''',,;;:::::cc:::::;;,,''''';:ldk0NWMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMWN0xo:,''',;:cloodxxkkkkkkkkkkkkkkxxdoolc:;,''',:ox0NWMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMWXOdc,''';:lodxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdoc:;''',cdOXWMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMN0d:,'',:loxkkkkkkkkkkkkkkkkkkkkkxodkkkkkkkkkkkkkkkkxol:,'',:d0NMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWXxc,'',:ldxkkkkkkkkkkkkkkkkkkkkkxl:;cxkkkkkkkkkkkkkkkkkkkxdl:,'',cxXWMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMWKd:''';ldxkkkkkkkkkkkkkkkkkkkkkkxo:'';dkkkkkkkkkkkkkkkkkkkkkkkxdl;''':dKWMMMMMMMMMMMMM
// MMMMMMMMMMMWKd;'',:oxxkkxxkkxkkxxxxxxxxxkkxkkxl,'',cxxkkxxxxxxxxxkkkxkkkxkkxkkxxo:,'';dKWMMMMMMMMMMM
// MMMMMMMMMMXx:'',:oxxxxxxxxxxxxxxxxxxxxxxxxxxxl,'',:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:,'':xXMMMMMMMMMM
// MMMMMMMMW0c''':oxxxxxxxxxxxxxxxxxxxxxxxxxxxxd;''';coxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:'''c0WMMMMMMMM
// MMMMMMMXx;'';ldxxxxxxxxxxxxxxxxxxxxxxxxxxxxxc,''';coxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdl;'';xXMMMMMMM
// MMMMMMKl,'':oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:'''',:lxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:'',lKMMMMMM
// MMMMW0c'',cdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:'''',;ldxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdc,''c0WMMMM
// MMMW0c'',cdxddddddddddddddddddddddddddddxddo:'''''':dddddddooddxddddddddddddddddddddddddxdl,''c0WMMM
// MMW0c'',lddddddddddddddddddddddddddddddddddd:'''''',lddddddoc:lddddddddddddddddddddddddddddl,''c0MMM
// MMKl'',cddddddddddddddddddddddddddddddddddddc''''''':oddddddl,,codddddddddddddddddddddddddddc,''lKMM
// MNd,''coddddddddddddddddddddddddddddddddddddc,'''''',cddddddo:'';codddddddddddddddddddddddddoc'',dNM
// WO;'';odddddddddddddddddddddddddddddddddddddl,''''''';lddddddl,''';loddddddddddddddddddddddddo:'';OW
// Xl'',codoodddddddddddddddddddddddoddddoollodl;'''''''';loddodo:'''',:odooddddddddddddddoodddool,''lX
// k;'':oooooooooooooooooooooooooooooooooo:,cooo;''''''''',cooooo:'''''';loooooooooooooooooooooooo:'';k
// o'',cooooooooooooooooooooooooooooooool;'':ooo:'''''''''',:loooc,'''''',:oooooooooooooooooooooooc,''o
// :'';loooooooooooooooooooooooooooooooc;''':ooo:'''''''''''';cll:''''''''';loooooooooooooooooooool;'':
// ,'';loooooooooooooooooooooooooooool:,''',coooc'''''''''''''',,''''''''''';looooooooooooooooooool;'';
// ''':loooooooooooooooooooooooooool:,''''';loooc,''''''''''''''''''''''''''';coooooooooooooooooool:'''
// ''':loolllllllllllllllllloollllc;'''''',cllllc,'''''''''''''''''''''''''''';cllollllllllllllolll:'''
// ''':lllllllllllllllllllllllllc;'''''''';lllllc,''''''''''''''''''''''''''''';lllllllllllllllllll:'''
// ,'';lllllllllllllllllllllllc;''''''''',clllllc,'''''''''''''''''''''''''''''':llllllllllllllllll;'',
// ;'';cllllllllllllllllllllc:,'''''''''':llllll:,'''''',,'''''''''''''''''''''',:llllllllllllllllc;'';
// c'',:lllllllllllllllllll:,''''''''''',:lllllc;'''''''cc''''''''''''''''''''''';clllllllllllllll:,''l
// x,'';cllllllllllllccllc:,''''''''''''',:cccc;''''''',oo;''''''''''''''''''''''':clllllllcllcllc;'',x
// 0:'',ccccccccccccccccc;''''''''''''''''',,,''''''''':dd;''''''''''''''''''''''',ccccccccccccccc,'':0
// Nd,'';ccccccccccccccc;''''''''''''''''''''''''''''';oxd;'''''''''''''''''''''''':ccccccccccccc;'',dN
// MKc'',:ccccccccccccc;'''''''''''';:,''''''''''''',;ldxo;'''''''''''''''''''''''';cccccccccccc:,''cKM
// MWO;'',:ccccccccccc:,''''''''''';odl;''''''''''',lodddl,'''''''''''''''''''''''';:cccccccccc:,'';OWM
// MMWx,'',:cccccccccc;''''''''''';ldddo:,''''''',:ldddddc''''''''''''''''''''''''',:ccccccccc:,'',xWMM
// MMMNd,'',:::c::c:c:,'''''''''',coooodolc;,,,;:looodddo;''''''''''''''''''''''''',:c::::ccc:,'',dNMMM
// MMMMNd,'',:::::::::,'''''''''';loooooooooolloooooooooc,''''''''''''''''''''''''';:::::::::,'',xNMMMM
// MMMMMNx;'',;:::::::,'''''''''':looooooooooooooooooooo:''''''''''''''''''''''''',;:::::::;,'';xNMMMMM
// MMMMMMWOc''',::::::;''''''''',:llllllllllllllllllllll:''''''''''''''''''''''''',::::::;,'''cOWMMMMMM
// MMMMMMMMKo,'',;::::;,'''''''',:llllllllllllllllllllll:'''''';;'''''''''''''''',;:::::;,'',oKMMMMMMMM
// MMMMMMMMMNOc''',;;:;,'''''''',:lllllllllllllllllllcll:,'''',:c,''''''''''''''';;:::;,'''ckNMMMMMMMMM
// MMMMMMMMMMWXx:''',;;;,'''''''':ccccccccccccccccccccccc:;,,,:cc;'''''''''''''',;;;;,''':xXWMMMMMMMMMM
// MMMMMMMMMMMMWKd;''',,;,''''''';ccccccccccccccccccccccccc::cccc;''''''''''''',;;,,''':dKWMMMMMMMMMMMM
// MMMMMMMMMMMMMMWXxc,''',''''''',:::::::::::::::::::::::::::::::;'''''''''''',,,''',:xXWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWXOo;'''''''''',::::::::::::::::::::::::::::::,'''''''''''''''';lONWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMWKkl;'''''''',;:::::::::::::::::::::::::::;,''''''''''''';lkKWMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMWKko:,''''',,;;;;;;;;;;;;;;;;;;;;;;;;;;,'''''''''',:okKWMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMWN0koc;,'''''',,,,,,,,,,,,,,,,,,,,,''''''',;cok0NWMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNX0kdlc;,,'''''''''''''''''''',,:cldk0XNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxdlc:;,,'''''',,;;cloxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//
// ----------------------------------------------------------------------------------------------------
//
// Website: https://skorch.io 
// Reddit: https://reddit.com/r/SkorchToken
// Twitter: https://twitter.com/SkorchToken

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

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
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

contract SkorchToken is ERC20Interface, Owned {

    using SafeMath for uint;
    using ExtendedMath for uint;

    string public symbol;

    string public  name;

    uint8 public decimals;

    uint public _totalSupply;
    uint public latestDifficultyPeriodStarted;
    uint public epochCount;
    uint public _BLOCKS_PER_READJUSTMENT = 1024;

    uint public  _MINIMUM_TARGET = 2**16;

    uint public  _MAXIMUM_TARGET = 2**234;

    uint public miningTarget;
    
    uint256 public MinimumPoStokens = 20000 * 10**uint(decimals); // set minimum tokens to stake 

    bytes32 public challengeNumber;   //generate a new one when a new reward is minted

    uint public rewardEra;
    uint public maxSupplyForEra;

    address public lastRewardTo;
    uint public lastRewardAmount;
    uint public lastRewardEthBlockNumber;

    mapping(bytes32 => bytes32) solutionForChallenge;

    uint public tokensMinted;

    mapping(address => uint) balances;

    mapping(address => mapping(address => uint)) allowed;
    
    mapping(address => uint256) timer; // timer to check PoS 
    
    // how to calculate doubleUnit: 
    // specify how much percent increase you want per year 
    // e.g. 130% -> 2.3 multiplier every year 
    // now divide (1 years) by LOG(2.3) where LOG is the natural logarithm (not LOG10)
    // in this case LOG(2.3) is 0.83290912293
    // hence multiplying by 1/0.83290912293 is the same 
    // 31536000 = 1 years (to prevent deprecated warning in solc)
    uint256 doubleUnit = (31536000) * 1.2;

    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

    constructor()
        public 
        onlyOwner()
    {
        symbol = "SKO";
        name = "Skorch Token";
        decimals = 18;
        // uncomment this to test 
        //balances[msg.sender] = (20000) * (10 ** uint(decimals)); // change 20000 to some lower number than 20000 
        //to see you will not get PoS tokens if you have less than 20000 tokens 
        //timer[msg.sender] = now - (1 years);
        _totalSupply = 21000000 * 10**uint(decimals);
        tokensMinted = 0;
        rewardEra = 0;
        maxSupplyForEra = _totalSupply.div(2);
        miningTarget = _MAXIMUM_TARGET;
        latestDifficultyPeriodStarted = block.number;
        _startNewMiningEpoch();
        
        
    }
    
    function setPosTokens(uint256 newTokens)
        public 
        onlyOwner
    {
        require(newTokens >= 100000);
        // note: newTokens should be multiplied with 10**uint(decimals) (10^18);
        // require is in place to prevent fuck up. for 1000 tokens you need to enter 1000* 10^18 
        MinimumPoStokens = newTokens;
    }

        function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success) {
            bytes32 digest =  keccak256(challengeNumber, msg.sender, nonce );
            if (digest != challenge_digest) revert();
            if(uint256(digest) > miningTarget) revert();
             bytes32 solution = solutionForChallenge[challengeNumber];
             solutionForChallenge[challengeNumber] = digest;
             if(solution != 0x0) revert();  //prevent the same answer from awarding twice
             _claimTokens(msg.sender);
            uint reward_amount = getMiningReward();
            balances[msg.sender] = balances[msg.sender].add(reward_amount);
            tokensMinted = tokensMinted.add(reward_amount);
            assert(tokensMinted <= maxSupplyForEra);
            lastRewardTo = msg.sender;
            lastRewardAmount = reward_amount;
            lastRewardEthBlockNumber = block.number;
             _startNewMiningEpoch();
              emit Mint(msg.sender, reward_amount, epochCount, challengeNumber );
           return true;
        }

    function _startNewMiningEpoch() internal {
      if( tokensMinted.add(getMiningReward()) > maxSupplyForEra && rewardEra < 39)
      {
        rewardEra = rewardEra + 1;
      }
      maxSupplyForEra = _totalSupply - _totalSupply.div( 2**(rewardEra + 1));
      epochCount = epochCount.add(1);
      if(epochCount % _BLOCKS_PER_READJUSTMENT == 0)
      {
        _reAdjustDifficulty();
      }
      challengeNumber = block.blockhash(block.number - 1);
    }

    function _reAdjustDifficulty() internal {
        uint ethBlocksSinceLastDifficultyPeriod = block.number - latestDifficultyPeriodStarted;
        uint epochsMined = _BLOCKS_PER_READJUSTMENT; 
        uint targetEthBlocksPerDiffPeriod = epochsMined * 60; //should be 60 times slower than ethereum
        if( ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod )
        {
          uint excess_block_pct = (targetEthBlocksPerDiffPeriod.mul(100)).div( ethBlocksSinceLastDifficultyPeriod );
          uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(1000);
          miningTarget = miningTarget.sub(miningTarget.div(2000).mul(excess_block_pct_extra));   //by up to 50 %
        }else{
          uint shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod.mul(100)).div( targetEthBlocksPerDiffPeriod );
          uint shortage_block_pct_extra = shortage_block_pct.sub(100).limitLessThan(1000); //always between 0 and 1000
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

    function getChallengeNumber() public constant returns (bytes32) {
        return challengeNumber;
    }

    function getMiningDifficulty() public constant returns (uint) {
        return _MAXIMUM_TARGET.div(miningTarget);
    }

    function getMiningTarget() public constant returns (uint) {
       return miningTarget;
   }

    function getMiningReward() public constant returns (uint) {
         return (50 * 10**uint(decimals) ).div( 2**rewardEra ) ;
    }

    function getMintDigest(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number) public view returns (bytes32 digesttest) {
        bytes32 digest = keccak256(challenge_number,msg.sender,nonce);
        return digest;
      }
      
      function checkMintSolution(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint testTarget) public view returns (bool success) {
          bytes32 digest = keccak256(challenge_number,msg.sender,nonce);
          if(uint256(digest) > testTarget) revert();
          return (digest == challenge_digest);
        }

    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];// + _getPoS(tokenOwner); // add unclaimed pos tokens 
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        _claimTokens(msg.sender);
        _claimTokens(to);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        _claimTokens(from);
        _claimTokens(to);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function () public payable {
        revert();
    } 
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    function claimTokens() public {
        _claimTokens(msg.sender);        
    }
    
    function _claimTokens(address target) internal{
        if (timer[target] == 0){
            // russian hackers BTFO
            return;
        }
        if (timer[target] == now){
            // 0 seconds passed, 0 tokens gotten via PoS 
            // return so no gas waste 
            return;
        }
        
        uint256 totalTkn = _getPoS(target);
        balances[target] = balances[target].add(totalTkn);
        _totalSupply.add(totalTkn);
        timer[target] = now;
        emit Transfer(address(0x0), target, totalTkn);
    }
    
    function _getPoS(address target) internal view returns (uint256){
        if (balances[target] <= MinimumPoStokens){
            return 0;
        }
        int ONE_SECOND = 0x10000000000000000;
        int PORTION_SCALED = (int(now - timer[target]) * ONE_SECOND) / int(doubleUnit); 
        uint256 exp = fixedExp(PORTION_SCALED);
        
        return ((balances[target].mul(exp)) / uint(one)).sub(balances[target]); 
    }
    
    
    
    int256 constant ln2       = 0x0b17217f7d1cf79ac;
    int256 constant ln2_64dot5= 0x2cb53f09f05cc627c8;
    int256 constant one       = 0x10000000000000000;
	int256 constant c2 =  0x02aaaaaaaaa015db0;
	int256 constant c4 = -0x000b60b60808399d1;
	int256 constant c6 =  0x0000455956bccdd06;
	int256 constant c8 = -0x000001b893ad04b3a;
	function fixedExp(int256 a) public pure returns (uint256 exp) {
		int256 scale = (a + (ln2_64dot5)) / ln2 - 64;
		a -= scale*ln2;
		// The polynomial R = 2 + c2*x^2 + c4*x^4 + ...
		// approximates the function x*(exp(x)+1)/(exp(x)-1)
		// Hence exp(x) = (R(x)+x)/(R(x)-x)
		int256 z = (a*a) / one;
		int256 R = ((int256)(2) * one) +
			(z*(c2 + (z*(c4 + (z*(c6 + (z*c8/one))/one))/one))/one);
		exp = (uint256) (((R + a) * one) / (R - a));
		if (scale >= 0)
			exp <<= scale;
		else
			exp >>= -scale;
		return exp;
	}

}