/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// File: dumper_shiled_smart_contract/Splitter.sol



pragma solidity ^0.8.0;



library Splitter {



    struct Deposit {

        uint256 tokenARate;

        uint256 tokenBRate;

        uint256 shares;

    }



    struct SplitterSet {

        mapping(address => Deposit) deposits;       // user => Deposit

        mapping(uint256 => uint256) sharesOrRateB;  // base token B rate => shares with this rate OR token B rate

        uint256[] tokenARatesShares;

        uint256 index;

        uint256 tokenARate;  // with 18 decimals

        uint256 tokenBRate;  // with 18 decimals

        uint256 totalShares; // 1 share = 1 token A

        uint256 totalTokenA; // token that should be sold

        uint256 totalTokenB; // token that should be payed - native coin (BNB, ETH)

    }





    // deposit token A for sell by token B and claim tokens B (if user has sold tokens A)

    // returns: 

    // valueAonSale - amount of tokens A that left on sale

    // valueB - amount of tokens B send to user (if user has sold tokens A)

    function deposit(SplitterSet storage set, address user, uint256 valueA) internal returns (uint256 valueAonSale, uint256 valueB){

        Deposit storage d = set.deposits[user];

        uint256 rateA = set.tokenARate + 1 ether;

        if(d.tokenARate == rateA) {

            d.shares += valueA;

        } else {

            if (d.shares != 0) {

                (valueAonSale, valueB) = claim(set, user);

                valueA += valueAonSale;

            }

            d.shares = valueA;

            d.tokenARate = rateA;

            d.tokenBRate = set.tokenBRate;

        }

        if(set.tokenARatesShares.length != 0 && set.tokenARatesShares[set.tokenARatesShares.length-1] == rateA) {

            set.sharesOrRateB[rateA] += valueA;

        } else {

            set.tokenARatesShares.push(rateA);

            set.sharesOrRateB[rateA] = valueA;

        }

        set.totalShares += valueA;

        set.totalTokenA += valueA;

        valueAonSale = valueA;

    }



    // Claim tokens A and B according user's shares

    function claim(SplitterSet storage set, address user) internal returns (uint256 valueA, uint256 valueB) {

        Deposit storage d = set.deposits[user];

        uint256 shares = d.shares;

        uint256 rateA = d.tokenARate;

        if (set.tokenARatesShares[set.index] <= rateA) {  // withdraw both tokens and reduce shares

            valueA = (rateA - set.tokenARate)*shares / 1 ether;

            valueB = (set.tokenBRate - d.tokenBRate)*shares / 1 ether;

            set.totalShares -= shares;

            set.sharesOrRateB[rateA] -= shares;  // reduce shares for this rate

        } else {    // all tokens A where sold

            valueB = (set.sharesOrRateB[rateA] - d.tokenBRate)*shares / 1 ether;

        }

        d.shares = 0;

        set.totalTokenA -= valueA;

        _transfer(set, user, valueB);

    }



    // get values of tokens A and B the user can claim

    function claimInfo(SplitterSet storage set, address user) internal view returns (uint256 valueA, uint256 valueB) {

        Deposit storage d = set.deposits[user];

        uint256 shares = d.shares;

        uint256 rateA = d.tokenARate;

        if (set.tokenARate < rateA) {  // withdraw both tokens and reduce shares

            valueA = (rateA - set.tokenARate)*shares / 1 ether;

            valueB = (set.tokenBRate - d.tokenBRate)*shares / 1 ether;

        } else {    // all tokens A where sold

            valueB = (set.sharesOrRateB[rateA] - d.tokenBRate)*shares / 1 ether;

        }

    }



    // transfer valueB of token B (native coin) to user

    function _transfer(SplitterSet storage set, address user, uint256 valueB) internal {

        set.totalTokenB -= valueB;

        payable(user).transfer(valueB);

    }



    // swap valueA to valueB

    function swap(SplitterSet storage set, uint256 valueA, uint256 valueB) internal {

        set.totalTokenA -= valueA;

        set.totalTokenB += valueB;

        uint256 _totalShares = set.totalShares;

        uint256 _tokenARate = set.tokenARate;

        uint256 _tokenBRate = set.tokenBRate;

        uint256 idx = set.index;

        while (valueA > 0) {

            uint256 rateA = set.tokenARatesShares[idx]; // minimal rate that has unsold shares

            uint256 amount = (rateA - _tokenARate) * _totalShares / 1 ether;

            if (valueA >= amount) {

                uint256 subB = valueB * amount / valueA;

                _tokenARate = rateA;

                _tokenBRate = _tokenBRate + (subB * 1 ether / _totalShares);

                _totalShares -= set.sharesOrRateB[rateA];   // remove shares 

                set.sharesOrRateB[rateA] = _tokenBRate;     // and save current rate B

                delete set.tokenARatesShares[idx];

                idx++;

                valueA -= amount;

                valueB -= subB;

            } else {

                _tokenARate = _tokenARate + (valueA * 1 ether / _totalShares);

                _tokenBRate = _tokenBRate + (valueB * 1 ether / _totalShares);

                valueA = 0;

            }

        }

        set.totalShares = _totalShares;

        set.tokenARate = _tokenARate;

        set.tokenBRate = _tokenBRate;

        set.index = idx;        

    }

}
// File: dumper_shiled_smart_contract/Voting.sol



pragma solidity ^0.8.0;



contract Voting {

    

    uint256 public ballotIds;

    uint256 public rulesIds;

    

    enum Vote {None, Yea, Nay}

    enum Status {New , Executed}



    struct Rule {

        //address contr;      // contract address which have to be triggered

        uint32 majority;  // require more than this percentage of participants voting power (in according tokens).

        string funcAbi;     // function ABI (ex. "transfer(address,uint256)")

    }



    struct Ballot {

        uint256 closeVote; // timestamp when vote will close

        uint256 ruleId; // rule which edit

        address token;  // shielded token to vote

        bytes args; // ABI encoded arguments for proposal which is required to call appropriate function

        Status status;

        address creator;    // wallet address of ballot creator.

        uint256 yea;  // YEA votes according communities (tokens)

        uint256 totalVotes;  // The total voting power od all participant according communities (tokens)

    }

    

    mapping(address => mapping(uint256 => bool)) public voted;      // user => ballotID => isVoted

    mapping(address => mapping(address => uint256)) public locked;  // token => user => locked until (time)

    mapping(address => uint256) public votingTime;   // duration of voting

    mapping(address => uint256) public minimalLevel; // user who has this percentage of token can suggest change

    mapping(uint256 => Ballot) public ballots;

    mapping(uint256 => Rule) public rules;

    mapping(address => uint256) public totalSupply;   // token address => total supply of locked tokens

    mapping(address => mapping(address => uint256)) public dsBalanceOf;   // token => dumper shield user contract => balance (real balance may be different)

    //event AddRule(address indexed contractAddress, string funcAbi, uint32 majorMain);

    event ApplyBallot(address indexed token, uint256 indexed ruleId, uint256 indexed ballotId);

    event BallotCreated(address indexed token, uint256 indexed ruleId, uint256 indexed ballotId);

    

    modifier onlyVoting() {

        require(address(this) == msg.sender, "onlyVoting");

        _;        

    }



    function initialize() internal {

        rules[0] = Rule(75,"setVotingDuration(address,uint256)");

        rules[1] = Rule(75,"setMinimalLevel(address,uint256)");

        rules[2] = Rule(75,"setRouter(address,address)");

        rules[3] = Rule(75,"setUnlockDate(address,uint256)");

        rules[4] = Rule(75,"setLimits(address,uint256,uint256)");

        rules[5] = Rule(75,"setDAO(address,address)");

        rulesIds = 5;

        //super.initialize();

    }

    

    // placeholder

    function _updateBalanceAndTotal(address token, address dumperShieldUser) internal virtual returns (uint256 realBalance) {}



    /**

     * @dev Add new rule - function that call target contract to change setting.

        * @param contr The contract address which have to be triggered

        * @param majority The majority level (%) for the tokens 

        * @param funcAbi The function ABI (ex. "transfer(address,uint256)")

     */

     /*

    function addRule(

        address contr,

        uint32  majority,

        string memory funcAbi

    ) external onlyOwner {

        require(contr != address(0), "Zero address");

        rulesIds +=1;

        rules[rulesIds] = Rule(contr, majority, funcAbi);

        emit AddRule(contr, funcAbi, majority);

    }

    */



    /**

     * @dev Set voting duration

     * @param time duration in seconds

    */

    function setVotingDuration(address token, uint256 time) external onlyVoting {

        require(time > 600);

        votingTime[token] = time;

    }

    

    /**

     * @dev Set minimal level to create proposal

     * @param level in percentage. I.e. 10 = 10%

    */

    function setMinimalLevel(address token, uint256 level) external onlyVoting {

        require(level >= 1 && level <= 51);    // not less then 1% and not more then 51%

        minimalLevel[token] = level;

    }

    

    /**

     * @dev Get rules details.

     * @param ruleId The rules index

     * @return majority The level of majority in according tokens

     * @return funcAbi The function Abi (ex. "transfer(address,uint256)")

    */

    function getRule(uint256 ruleId) external view returns(uint32 majority, string memory funcAbi) {

        Rule storage r = rules[ruleId];

        return (r.majority, r.funcAbi);

    }

    

    function _checkMajority(uint32 majority, uint256 _ballotId) internal view returns(bool){

        Ballot storage b = ballots[_ballotId];

        if (b.yea * 2 > totalSupply[b.token]) {

            return true;

        }

        if((b.totalVotes - b.yea) * 2 > totalSupply[b.token]){

            return false;

        }

        if (block.timestamp >= b.closeVote && b.yea > b.totalVotes * majority / 100) {

            return true;

        }

        return false;

    }



    function vote(uint256 _ballotId, bool yea) external returns (bool){

        require(_ballotId <= ballotIds, "Wrong ballotID");

        require(!voted[msg.sender][_ballotId], "already voted");

        

        Ballot storage b = ballots[_ballotId];

        uint256 closeVote = b.closeVote;

        require(closeVote > block.timestamp, "voting closed");

        uint256 power = _updateBalanceAndTotal(b.token, msg.sender);

        

        if(yea){

            b.yea += power;    

        }

        b.totalVotes += power;

        voted[msg.sender][_ballotId] = true;

        if(_checkMajority(rules[b.ruleId].majority, _ballotId)) {

            _executeBallot(_ballotId);

        } else if (locked[b.token][msg.sender] < closeVote) {

            locked[b.token][msg.sender] = closeVote;

        }

        return true;

    }



    function createBallot(address token, uint256 ruleId, bytes calldata args) external {

        require(ruleId <= rulesIds, "Wrong ruleID");

        Rule storage r = rules[ruleId];

        address argToken = abi.decode(args,(address));

        require(argToken == token, "Wrong token");

        uint256 power = _updateBalanceAndTotal(token, msg.sender);

        require(power >= totalSupply[token] * minimalLevel[token] / 100, "wrong level");

        uint256 closeVote = block.timestamp + votingTime[token];

        ballotIds += 1;

        Ballot storage b = ballots[ballotIds];

        b.ruleId = ruleId;

        b.token = token;

        b.args = args;

        b.creator = msg.sender;

        b.yea = power;

        b.totalVotes = power;

        b.closeVote = closeVote;

        b.status = Status.New;

        voted[msg.sender][ballotIds] = true;

        emit BallotCreated(token, ruleId, ballotIds);

        

        if (_checkMajority(r.majority, ballotIds)) {

            _executeBallot(ballotIds);

        } else if (locked[token][msg.sender] < closeVote) {

            locked[token][msg.sender] = closeVote;

        }

    }

    

    function executeBallot(uint256 _ballotId) external {

        Ballot storage b = ballots[_ballotId];

        if(_checkMajority(rules[b.ruleId].majority, _ballotId)){

            _executeBallot(_ballotId);

        }

    }

    

    

    /**

     * @dev Apply changes from ballot.

     * @param ballotId The ballot index

     */

    function _executeBallot(uint256 ballotId) internal {

        Ballot storage b = ballots[ballotId];

        require(b.status != Status.Executed,"already executed");

        Rule storage r = rules[b.ruleId];

        bytes memory command = abi.encodePacked(bytes4(keccak256(bytes(r.funcAbi))), b.args);

        trigger(address(this), command);

        b.closeVote = block.timestamp;

        b.status = Status.Executed;

        emit ApplyBallot(b.token, b.ruleId, ballotId);

    }



    

    /**

     * @dev Apply changes from Governance System. Call destination contract.

     * @param contr The contract address to call

     * @param params encoded params

     */

    function trigger(address contr, bytes memory params) internal  {

        (bool success,) = contr.call(params);

        require(success, "Trigger error");

    }

}
// File: dumper_shiled_smart_contract/DumperShieldToken.sol



pragma solidity ^0.8.0;



interface IERC20 {

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

}



interface IDSFactory {

    function totalSupply(address token) external view returns (uint256);

    function getLock(address token, address user) external view returns(uint256);

    function setLock(address token, address user, uint256 time) external returns(bool);

}



contract DumperShieldUser {



    address public factory; // dumper shield factory

    address public user;

/*

    address public dumperShield;

    modifier onlyDumperShield() {

        require(dumperShield == msg.sender, "Only dumperShield allowed");

        _;

    }

*/

    modifier onlyFactory() {

        require(factory == msg.sender, "onlyFactory");

        _;

    }



    constructor (address _user, address _factory) {

        require(_user != address(0) && _factory != address(0));

        user = _user;

        factory = _factory;

    }



    function safeTransfer(address token, address to, uint value) external onlyFactory {

        // bytes4(keccak256(bytes('transfer(address,uint256)')));

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));

        require(success && (data.length == 0 || abi.decode(data, (bool))), 'DumperShieldUser: TRANSFER_FAILED');

    }

}



contract DumperShieldToken {

    IERC20 public shieldedToken;   // address of shielded token

    address public factory; // dumper shield factory

    //address public router;

    mapping(address => address) public dumperShieldUsers;   // user address => DumperShieldUser contract

    address public DAO; // address of global voting contract



    event CreateDumperShieldUser(address user, address dsUserContract);



    modifier onlyFactory() {

        require(factory == msg.sender, "onlyFactory");

        _;

    }



    function initialize(address _token, address _dao) external {

        require(address(shieldedToken) == address(0) && _token != address(0));

        shieldedToken = IERC20(_token);

        DAO = _dao;

        //router = _router;

        factory = msg.sender;

    }

    /**

     * @dev Gets the balance of the specified address.

     * @param user The address to query the the balance of.

     * @return balance an uint256 representing the amount owned by the passed address.

     */

    function balanceOf(address user) external view returns (uint256 balance) {

        return shieldedToken.balanceOf(dumperShieldUsers[user]);

    }



    // returns DumperShieldUser contract address. If user has not contract - create it.

    function createDumperShieldUser(address user, address dsUser) external onlyFactory returns(address) {



        if (dsUser == address(0)) {

            dsUser = address(new DumperShieldUser(user, factory));

            emit CreateDumperShieldUser(user, dsUser);

        } else if (dumperShieldUsers[user] == dsUser) {

            return dsUser;

        }

        dumperShieldUsers[user] = dsUser;

        return dsUser;

    }



    function totalSupply() external view returns (uint256) {

        return IDSFactory(factory).totalSupply(address(shieldedToken));

    }



    function setLock(address user, uint256 time) external returns(bool) {

        require(msg.sender == DAO, "Only DAO");

        return IDSFactory(factory).setLock(address(shieldedToken), user, time);

    }



    function getLock(address user) external view returns(uint256) {

        return IDSFactory(factory).getLock(address(shieldedToken),user);

    }



    function setDAO(address _dao) external returns (bool) {

        require(msg.sender == factory, "Only factory");

        DAO = _dao;

        return true;

    }



    // allow to rescue tokens that were transferet to this contract by mistake

    function safeTransfer(address token, address to, uint value) external onlyFactory {

        // bytes4(keccak256(bytes('transfer(address,uint256)')));

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));

        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');

    }

}
// File: dumper_shiled_smart_contract/DumperShield.sol



pragma solidity ^0.8.0;






interface IRouter {

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function factory() external pure returns (address);

}



interface IFactory {

    function getPair(address tokenA, address tokenB) external view returns (address pair);

}



interface IPair {

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

}



// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false

library TransferHelper {

    function safeApprove(address token, address to, uint value) internal {

        // bytes4(keccak256(bytes('approve(address,uint256)')));

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));

        require(success && (data.length == 0 || abi.decode(data, (bool))), 'APPROVE_FAILED');

    }



    function safeTransfer(address token, address to, uint value) internal {

        // bytes4(keccak256(bytes('transfer(address,uint256)')));

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));

        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');

    }



    function safeTransferFrom(address token, address from, address to, uint value) internal {

        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));

        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FROM_FAILED');

    }



    function safeTransferETH(address to, uint value) internal {

        (bool success,) = to.call{value:value}(new bytes(0));

        require(success, 'ETH_TRANSFER_FAILED');

    }

}



abstract contract Ownable {

    address internal _owner;



    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);



    /**

     * @dev Initializes the contract setting the deployer as the initial owner.

     */

/*  we use proxy, so owner will be set in initialize() function

    constructor () {

        _owner = msg.sender;

        emit OwnershipTransferred(address(0), msg.sender);

    }

*/

    /**

     * @dev Returns the address of the current owner.

     */

    function owner() public view virtual returns (address) {

        return _owner;

    }



    /**

     * @dev Throws if called by any account other than the owner.

     */

    modifier onlyOwner() {

        require(owner() == msg.sender, "onlyOwner"); //Ownable: caller is not the owner

        _;

    }



    /**

     * @dev Transfers ownership of the contract to a new account (`newOwner`).

     * Can only be called by the current owner.

     */

    function transferOwnership(address newOwner) public virtual onlyOwner {

        require(newOwner != address(0)); //"Ownable: new owner is the zero address"

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;

    }

}







contract DumperShieldFactory is Ownable, Voting {

    using TransferHelper for address;

    using Splitter for Splitter.SplitterSet;



    enum OrderStatus {Completed, Created, Canceled, Restricted}

    address constant public NATIVE_COIN = address(1);

    address public WETH;

    address public DumperShieldTokenImplementation; // implementation contract for DumperShieldToken



    struct Order {

        address seller;

        address buyer;

        address tokenSell;  // token to sell

        uint256 sellAmount;  // how many token sell

        address wantToken;  // which token want to receive (address(0) for base coin (ETH, BNB))

        address router; // router where "wantToken" can be swapped to native coin (ETH, BNB)

        uint256 value;  // the value in native cion (ETH, BNB) want to receive

        OrderStatus status;     // 0 - completed, 1 - created, 2 - canceled; 3 -restricted

        address confirmatory;   // the address third person who confirm transaction, if order is restricted.

    }



    Order[] public orders;



    struct Limit {

        uint256 period; // period of time while calculate tokens demand

        uint256 limit;  // current limit amount. If limit == 0 than no limits

        uint256 spent;  // amount of token that was spent;

        uint256 endTime;  // timestamp when current period ends

        uint256 nextLimit; // limit for next period

        // if limit was spent by less than period * 50% (ie. 1 day * 50%) the limit *= 2

        // if during period was spend less than `percentage` (ie. spent < limit * 50%) the limit /= 2

    }



    mapping(address => Limit) public limits;    // token => limit for sale

    mapping(address => DumperShieldToken) public dumperShieldTokens;   // token address => DumperShieldToken contract address

    mapping(address => address) public dumperShieldUsers;   // user address => DumperShieldUser contract address

    mapping(address => address) public dsRouters;     // token => router

    mapping(address => uint256) public dsUnlockDate;  // token => unlock date (unix timestamp in seconds)

    mapping(address => mapping(address => uint256)) public restrictedBalance;   // token => user => restricted balance

    mapping(address => Splitter.SplitterSet) public tokensSale; // token => sale library



    uint256 private _status;



    event CreateDumperShield(address indexed token, address router, address dumperShieldToken);

    event PaymentFromGateway(uint256 indexed channelId, address indexed token, uint256 value, uint256 soldValue);

    event CreateOrder(

        uint256 orderId, 

        address indexed seller, 

        address indexed buyer, 

        address indexed tokenSell,

        uint256 sellAmount,

        address wantToken,

        address router,

        uint256 value, 

        OrderStatus status,

        address confirmatory

    );

    event CompleteOrder(uint256 indexed orderId);

    event ConfirmOrder(uint256 indexed orderId);

    event CancelOrder(uint256 indexed orderId);

    event PutOnSale(

        address indexed token,  // taken address that put on sale

        address indexed from,   // user address

        uint256 value,          // value of tokens that user put on sale

        uint256 valueA,         // total value of tokens that user has on sale

        uint256 valueB          // value of coin (BNB, ETH) transferred to user for sold tokens

    );

    event RemoveFromSale(address indexed token, address indexed from, uint256 valueA, uint256 valueB);

    event BuyOrder(uint256 indexed orderId, address indexed buyer, uint256 paymentAmount, uint256 receiveAmount);



    /**

     * @dev Prevents a contract from calling itself, directly or indirectly.

     * Calling a `nonReentrant` function from another `nonReentrant`

     * function is not supported. It is possible to prevent this from happening

     * by making the `nonReentrant` function external, and making it call a

     * `private` function that does the actual work.

     */

    modifier nonReentrant() {

        // On the first call to nonReentrant, _notEntered will be true

        require(_status != 1, "reentrant");



        // Any calls to nonReentrant after this point will fail

        _status = 1;



        _;



        // By storing the original value once again, a refund is triggered (see

        // https://eips.ethereum.org/EIPS/eip-2200)

        _status = 2;

    }



    // run only once from proxy

    function initialize(address newOwner, address newDumperShieldTokenImplementation) external {

        require(newOwner != address(0) && _owner == address(0)); // run only once

        _owner = newOwner;

        emit OwnershipTransferred(address(0), msg.sender);

        //WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // Ethereum WETH

        //WETH = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c); // Main BSC net WBNB

        WETH = address(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd); // test BSC net WBNB

        DumperShieldTokenImplementation = newDumperShieldTokenImplementation;

        orders.push();  // order ID starts from 1. Zero order ID means - no order

        super.initialize();

    }



    function setWETH(address _WETH) external onlyOwner {

        require(_WETH != address(0));

        WETH = _WETH;

    }



    // View functions

    // get user balance of token on the dumper shield

    function balanceOf(address token, address user) public view returns (uint256 total, uint256 available) {

        address dsUser = dumperShieldUsers[user];

        if(dsUser == address(0)) return (0,0); //User is not in dumper shield

        total = IERC20(token).balanceOf(dsUser);

        uint256 restricted = restrictedBalance[token][user];

        if (total > restricted) {

            available = total - restricted;

        }



    }

// debug functions

    function getSplitter_tokenARatesShares(address token, uint256 index) external view returns(uint tokenARatesShares) {

        tokenARatesShares = tokensSale[token].tokenARatesShares[index];

    }



    function getSplitter_sharesOrRateB(address token, uint256 rateA) external view returns(uint sharesOrRateB) {

        sharesOrRateB = tokensSale[token].sharesOrRateB[rateA];

    }



    function getSplitter_deposits(address token, address user) external view 

    returns

    (

        uint256 tokenARate,

        uint256 tokenBRate,

        uint256 shares    

    ) {

        tokenARate = tokensSale[token].deposits[user].tokenARate;

        tokenBRate = tokensSale[token].deposits[user].tokenBRate;

        shares = tokensSale[token].deposits[user].shares;

    }



    function updateVars() external onlyOwner {

        rules[5] = Rule(75,"setDAO(address,address)");

        rulesIds = 5;

    }

// end debug



    // return estimate value of tokens A in tokens B

    function getQuote(address router, address tokenA, address tokenB, uint256 amountA) public view returns(uint256 amountB) {

        address factory = IRouter(router).factory();

        address pair = IFactory(factory).getPair(tokenA, tokenB);

        (uint reserve0, uint reserve1,) = IPair(pair).getReserves();

        (uint reserveA, uint reserveB) = tokenA < tokenB ? (reserve0, reserve1) : (reserve1, reserve0);

        amountB = amountA * reserveB / reserveA;

    }



    // get total number of orders

    function getOrdersNumber() external view returns(uint256 number) {

        return orders.length;

    }



    // get order ID of last active sell order of seller

    function getLastSellOrder(address seller) external view returns(uint256[] memory)

    {

        uint256[] memory orderIDs = new uint256[](20);

        uint len = orders.length;

        uint min;

        uint index;

        if (len > 200) min = len - 200; // check last 200 orders

        while(len > min) {

            len--;

            Order storage o = orders[len];

            if ((o.status == OrderStatus.Restricted || o.status == OrderStatus.Created) && o.seller == seller) {

                orderIDs[index] = len;

                index++;

                if (index == 20) break;

            }

        }

        return orderIDs; // No orders available

    }



    // get order ID of last active buy order of buyer

    function getLastBuyOrder(address buyer) external view returns(uint256[] memory)

    {

        uint256[] memory orderIDs = new uint256[](20);

        uint len = orders.length;

        uint min;

        uint index;

        if (len > 200) min = len - 200; // check last 200 orders

        while(len > min) {

            len--;

            Order storage o = orders[len];

            if ((o.status == OrderStatus.Restricted || o.status == OrderStatus.Created) && o.buyer == buyer) {

                orderIDs[index] = len;

                index++;

                if (index == 20) break;

            }

        }

        return orderIDs; // No orders available

    }



    // get order ID of last restricted order that should be confirmed by confirmatory

    function getLastOrderToConfirm(address confirmatory) external view returns(uint256[] memory) {

        uint256[] memory orderIDs = new uint256[](20);

        uint len = orders.length;

        uint min;

        uint index;

        if (len > 200) min = len - 200; // check last 200 orders

        while(len > min) {

            len--;

            Order storage o = orders[len];

            if (o.status == OrderStatus.Restricted && o.confirmatory == confirmatory) {

                orderIDs[index] = len;

                index++;

                if (index == 20) break;

            }

        }

        return orderIDs; // No orders available

    }



    function setLock(address token, address user, uint256 time) external returns(bool) {

        require(msg.sender == address(dumperShieldTokens[token]), "onlyDSToken");

        if (locked[token][user] < time) {

            locked[token][user] = time;

        }

        return true;

    }

    

    function getLock(address token, address user) external view returns(uint256) {

        return locked[token][user];

    }



    // exported functions

    // Deposit tokens to user's address into Dumper Shield. Should be called approve() before deposit.

    function deposit(

        address token,

        uint256 amount,

        address user

    ) external returns (bool)

    {

        DumperShieldToken dsToken = dumperShieldTokens[token];

        require(address(dsToken) != address(0), "token0");   //Token is not shielded

        address dsUser = dumperShieldUsers[user];

        address dsNewUser = dsToken.createDumperShieldUser(user, dsUser);

        if (dsUser == address(0)) {

            dumperShieldUsers[user] = dsNewUser;

        }



        token.safeTransferFrom(msg.sender, dsNewUser, amount);

        _updateBalanceAndTotal(token, user);



        return true;

    }



    /**

     * @dev transfer token for a specified address into Escrow contract

     * @param token The address of token to transfer to.

     * @param to The address to transfer to.

     * @param value The amount to be transferred.

     */

    function transfer(address token, address to, uint256 value) external returns (bool) {

        //restrictedBalance[token][to] += value;     // transfer to restricted account

        return _transfer(token, msg.sender, to, value);

    }



    /**

     * @dev transfer token for a specified address into Escrow contract from restricted group

     * @param token The address of token to transfer to.

     * @param to The address to transfer to.

     * @param value The amount to be transferred.

     * @param confirmatory The address of third party who have to confirm this transfer

     */

    function transferRestricted(address token, address to, uint256 value, address confirmatory) external {

        _createOrder(msg.sender, to, token, value, address(0), address(0), 0, confirmatory);   // Create restricted order where wantValue = 0.

    }



    // Sell tokens to other user (inside Escrow contract).

    function sellToken(

        address buyer,  // buyer address, can be address(0) if anybody can buy it (no specific buyer)

        address tokenSell,  // token to sell

        uint256 sellAmount,  // how many token sell

        address wantToken,  // which token want to receive (address(0) for base coin (ETH, BNB))

        address router, // router where "wantToken" can be swapped to native coin (ETH, BNB)

        uint256 value,  // the value in native cion (ETH, BNB) want to receive

        address confirmatory   // the address third person who confirm transaction, if order is restricted.

    ) external {

        _createOrder(msg.sender, buyer, tokenSell, sellAmount, wantToken, router, value, confirmatory);

    }





    // confirm restricted order by third-party confirmatory address

    function confirmOrder(uint256 orderId) external {

        Order storage o = orders[orderId];

        require(o.confirmatory == msg.sender, "OnlyConfirmatory");

        require(o.status == OrderStatus.Restricted, "Wrong status");

        if (o.value == 0) { // if it's simple transfer, complete it immediately.

            o.status = OrderStatus.Completed;

            if(o.buyer != o.seller) restrictedBalance[o.tokenSell][o.buyer] += o.sellAmount;    // transfer to restricted account

            // else remove restriction

            _transfer(o.tokenSell, address(this), o.buyer, o.sellAmount);

            emit ConfirmOrder(orderId);

            emit CompleteOrder(orderId);

        }

        else {

            o.status = OrderStatus.Created;   // remove restriction

            emit ConfirmOrder(orderId);

        }

    }



    // cancel sell order

    function cancelOrder(uint256 orderId) external {

        Order storage o = orders[orderId];

        require(msg.sender == o.seller || msg.sender == o.buyer, "can't cancel");

        require(o.status == OrderStatus.Created || o.status == OrderStatus.Restricted, "Wrong order"); // user can cancel restricted order too.

        if (o.status == OrderStatus.Restricted) restrictedBalance[o.tokenSell][o.seller] += o.sellAmount;    // transfer to restricted account

        o.status = OrderStatus.Canceled;   // cancel

        _transfer(o.tokenSell, address(this), o.seller, o.sellAmount);

        emit CancelOrder(orderId);

    }



    // buy selected order (ID). If is used ERC20 token to buy, the amount should be approved for Escrow contract.

    function buyOrder(uint256 orderId, uint256 paymentAmount) external payable nonReentrant {

        Order storage o = orders[orderId];

        require(o.buyer == address(0) || o.buyer == msg.sender, "Wrong buyer");

        require(o.status == OrderStatus.Created, "Wrong status");



        address token = o.wantToken;

        uint256 value = o.value;

        uint256 sellAmount = o.sellAmount;

        if (value > 0) {

            if (token == address(0)) {

                if (msg.value > value) {

                    paymentAmount = value;

                    msg.sender.safeTransferETH(msg.value - value);  // return rest

                } else {

                    paymentAmount = msg.value;

                }

                (o.seller).safeTransferETH(paymentAmount);

            } else {

                value = getQuote(o.router, WETH, token, value);   // value in token

                require (value != 0, "tokenAmount 0");

                if (paymentAmount > value) paymentAmount = value;



                if (address(dumperShieldTokens[token]) == address(0)) {

                    (o.wantToken).safeTransferFrom(msg.sender, o.seller, paymentAmount);

                } else {

                    _transfer(o.wantToken, msg.sender, o.seller, paymentAmount);

                }



            }

            uint256 sellPart = sellAmount * paymentAmount / value;

            if (sellPart < sellAmount) {

                o.sellAmount = sellAmount - sellPart;

                value = o.value;

                o.value = value - (value * sellPart / sellAmount);

                sellAmount = sellPart;

            } else {

                o.sellAmount = 0;

                o.value = 0;

                o.status = OrderStatus.Completed;

                emit CompleteOrder(orderId);

            }

            emit BuyOrder(orderId, msg.sender, paymentAmount, sellAmount);

        } else {

            if (msg.value > 0) msg.sender.safeTransferETH(msg.value);  // return money if value == 0

            o.status = OrderStatus.Completed;

            emit CompleteOrder(orderId);

        }

        //restrictedBalance[o.tokenSell][o.buyer] += o.sellAmount;    // transfer to restricted account

        _transfer(o.tokenSell, address(this), msg.sender, sellAmount);

    }



    // buy token from Dumper Shield by pool price, without slippage

    function buyToken(

        address token,      // token that should be bought

        uint256 buyAmountMin,  // minimum amount to buy

        address sendToken,  // token that used to buy, should be address(0) = native coin (BNB, ETH)

        uint256 sendAmount  // amount of native coin == msg.value

    ) external payable returns (uint256 tokenAmountOut)

    {

        require(sendToken <= address(32), "onlyCoin");

        require(sendAmount == msg.value, "wrong value");

        require(address(dumperShieldTokens[token]) != address(0), "token0");  // Token is not in dumper shield

        tokenAmountOut = getQuote(dsRouters[token], WETH, token, sendAmount);

        _updateLimits(token, tokenAmountOut);    // check and update limits

        Splitter.SplitterSet storage set = tokensSale[token];

        require(set.totalTokenA >= tokenAmountOut, "amount 1"); //Not enough available tokens

        require(tokenAmountOut >= buyAmountMin, "amount 2"); //Amount is less then minimum

        set.swap(tokenAmountOut, sendAmount);

        token.safeTransfer(msg.sender, tokenAmountOut);

    }



    // get available token for sell

    function getAvailableTokens(address token) public view returns (uint256 amount) {

        amount = tokensSale[token].totalTokenA;

        uint256 limit = limits[token].limit;

        if (limit != 0) {

            uint256 endTime = limits[token].endTime;

            if(block.timestamp < endTime) {

                limit = limit - limits[token].spent;

            } else {

                // if spent less than 50% of limit during last period

                if(limits[token].spent < limit/2 && endTime != 0) {

                    // decrease limit

                    limit = limit/2;

                }                 

            }

            amount = amount < limit ? amount : limit;

        }

    }

    

    // get output amount of token that can be bought from Dumper Shield

    function getOutputTokens(address sendToken, uint256 sendAmount, address token) external view returns (uint256 amount)

    {

        require(sendToken <= address(32), "coin");

        amount = getQuote(dsRouters[token], WETH, token, sendAmount);

    }

    // end exported functions

 

    // withdraw token from user's DumperShield address

    function withdrawToken(address token, uint256 amount) external {

        require(dsUnlockDate[token] < block.timestamp, "locked 1"); //tokens is locked

        require(locked[token][msg.sender] < block.timestamp, "locked 2"); // tokens is locked in voting



        address dsUser = dumperShieldUsers[msg.sender];

        require(dsUser != address(0), "user0");  //



        DumperShieldUser(dsUser).safeTransfer(token, msg.sender, amount);

        _updateBalanceAndTotal(token, msg.sender);

    }





    // Create Dumper Shield for new token

    function createDumperShield(

        address token,  // token contract address

        address router, // Uniswap compatible AMM router address where exist Token <> WETH pair

        uint256 unlockDate, // Epoch time (in second) when tokens will be unlocked

        address dao         // Address of token's voting contract if exist. Otherwise = address(0).

    ) 

        external 

    {

        require(address(dumperShieldTokens[token]) == address(0), "shielded"); //Token already shielded

        require(unlockDate > block.timestamp, "DateInPast");  //unlockDate in past

        address[] memory path = new address[](2);

        path[0] = WETH;

        path[1] = token;

        uint[] memory amounts = IRouter(router).getAmountsOut(1 ether, path);

        require(amounts[1] != 0, "router");

        DumperShieldToken dsToken = DumperShieldToken(clone(DumperShieldTokenImplementation));// = new DumperShieldToken(token);

        dsToken.initialize(token, dao);

        dumperShieldTokens[token] = dsToken;

        dsRouters[token] = router;

        dsUnlockDate[token] = unlockDate;

        votingTime[token] = 1 days;

        minimalLevel[token] = 10;

        emit CreateDumperShield(token, router, address(dsToken));

    }



    // Set address of token's voting contract if exist. Otherwise = address(0).

    function setDAO(address token, address newDAO) external onlyVoting {

        dumperShieldTokens[token].setDAO(newDAO);

    }



    function setRouter(address token, address newRouter) external onlyVoting {

        require(dsRouters[token] != address(0));    //No dumperShieldToken

        address[] memory path = new address[](2);

        path[0] = WETH;

        path[1] = token;

        uint[] memory amounts = IRouter(newRouter).getAmountsOut(1 ether, path);

        require(amounts[1] != 0, "router");    

        dsRouters[token] = newRouter;

    }



    function setUnlockDate(address token, uint256 newUnlockDate) external onlyVoting {

        require(dsUnlockDate[token] != 0);  //No dumperShieldToken

        require(newUnlockDate > block.timestamp, "DateInPast");

        dsUnlockDate[token] = newUnlockDate;

    }



    // set period (in seconds) and initial limit for token sale. If limit == 0, then no limits

    function setLimits(address token, uint256 period, uint256 limit) external onlyVoting {

        require(dsUnlockDate[token] != 0);  //No dumperShieldToken

        limits[token].period = period;

        limits[token].limit = limit;

        limits[token].nextLimit = limit;

    }



    // Put token on sale

    // value - amount of tokens to pur on sale

    // if value == 0, user claim his part of money for sold tokens

    function putOnSale(address token, uint256 value) external {

        require(address(dumperShieldTokens[token]) != address(0), "token0");  //Token is not shielded

        (,uint256 balance) = balanceOf(token, msg.sender);

        require(balance >= value, "balance");

        Splitter.SplitterSet storage set = tokensSale[token];

        address dsUser = dumperShieldUsers[msg.sender];

        DumperShieldUser(dsUser).safeTransfer(token, address(this), value);

        _updateBalanceAndTotal(token, msg.sender);

        (uint256 valueA, uint256 valueB) = set.deposit(msg.sender, value);

        emit PutOnSale(token, msg.sender, value, valueA, valueB);

    }



    // Remove token form sale

    // user will receive unsold tokens back to his DumperShield address and receive money (BNB, ETH) for sold tokens to his wallet

    function claimFromSale(address token) external {

        require(address(dumperShieldTokens[token]) != address(0), "token0");  //Token is not shielded

        Splitter.SplitterSet storage set = tokensSale[token];

        require(set.deposits[msg.sender].shares != 0, "shares"); //You have no tokens on sale

        (uint256 valueA, uint256 valueB) = set.claim(msg.sender);

        address dsUser = dumperShieldUsers[msg.sender];

        token.safeTransfer(dsUser, valueA);

        _updateBalanceAndTotal(token, msg.sender);

        emit RemoveFromSale(token, msg.sender, valueA, valueB);

    }



    // get values of tokens A and B the user can claim

    function getTokensOnSale(address token, address user) external view returns (uint256 valueA, uint256 valueB) {

        require(address(dumperShieldTokens[token]) != address(0), "token0");  //Token is not shielded

        Splitter.SplitterSet storage set = tokensSale[token];

        (valueA, valueB) = set.claimInfo(user);

    }



    // user - wallet address related to dumper shield contract

    function _updateBalanceAndTotal(address token, address user) internal override returns (uint256 realBalance) {

        address dsUser = dumperShieldUsers[user];

        require(dsUser != address(0), "user0");  // User is not in dumper shield

        uint256 dsBalance = dsBalanceOf[token][dsUser];

        realBalance = IERC20(token).balanceOf(dsUser);

        if (dsBalance != realBalance) {

            dsBalanceOf[token][dsUser] = realBalance;

            uint256 ts = totalSupply[token] + realBalance ;

            if (ts > dsBalance) {

                totalSupply[token] = ts - dsBalance;

            } else {

                totalSupply[token] = 0;

            }

        }

    }



    /**

     * @dev transfer token for a specified address into Escrow contract

     * @param to The address to transfer to.

     * @param value The amount to be transferred.

     */

    function _transfer(address token, address from, address to, uint256 value) internal returns (bool) {

        require(to != address(0));

        DumperShieldToken dsToken = dumperShieldTokens[token];

        require(address(dsToken) != address(0), "token0");    //Token is not shielded

        require(locked[token][from] < block.timestamp, "locked"); //tokens is locked in voting

        address dsUser = dumperShieldUsers[to];

        address dsNewUser = dsToken.createDumperShieldUser(to, dsUser);

        if (dsUser == address(0)) {

            dumperShieldUsers[to] = dsNewUser;

        }

        if (from == address(this)) {

            token.safeTransfer(dsNewUser, value);

        } else {

            (uint256 total, uint256 available) = balanceOf(token, from);

            // disable restricted !!!

            //require(available >= value, "balance");  // Not enough balance

            require(total >= value, "balance");  // Not enough balance

            if (available != total) restrictedBalance[token][from] = 0;

            // end disable restricted

            address dsFrom = dumperShieldUsers[from];

            DumperShieldUser(dsFrom).safeTransfer(token, dsNewUser, value);

            _updateBalanceAndTotal(token, from);

        }

        _updateBalanceAndTotal(token, to);

        return true;

    }



    // Create order which may require confirmation from third-party confirmatory address. For simple transfer the wantValue = 0.

    function _createOrder(

        address seller,

        address buyer,      // if address(0) - anyone can buy this order

        address tokenSell,  // token to sell

        uint256 sellAmount,  // how many token sell

        address wantToken,  // which token want to receive (address(0) for base coin (ETH, BNB))

        address router, // router where "wantToken" can be swapped to native coin (ETH, BNB)

        uint256 value,  // the value in native cion (ETH, BNB) want to receive

        address confirmatory   // the address third person who confirm transaction, if order is restricted.        address tokenSell, 

    ) 

        internal 

    {

        require(sellAmount != 0, "amount 0");

        require(address(dumperShieldTokens[tokenSell]) != address(0), "token 0"); //Token is not shielded

        require(locked[tokenSell][seller] < block.timestamp, "locked");   //tokens is locked in voting

        OrderStatus status;

        if (confirmatory != address(0)) {

            require(seller != confirmatory && buyer != confirmatory && address(0) != dumperShieldUsers[confirmatory], "confirm"); //Wrong confirmatory address

            uint256 balance = restrictedBalance[tokenSell][seller];

            require(balance >= sellAmount, "balance"); //Not enough tokens on restricted account

            restrictedBalance[tokenSell][seller] -= sellAmount;

            status = OrderStatus.Restricted;

        } else {

            status = OrderStatus.Created;

            (,uint256 balance) = balanceOf(tokenSell, seller);

            require(balance >= sellAmount, "balance");    // Not enough tokens

        }

        uint256 orderId = orders.length;

        orders.push(Order(seller, buyer, tokenSell, sellAmount, wantToken, router, value, status, confirmatory));  //add restricted order

        address dsUser = dumperShieldUsers[seller];

        DumperShieldUser(dsUser).safeTransfer(tokenSell, address(this), sellAmount);

        _updateBalanceAndTotal(tokenSell, seller);

        emit CreateOrder(orderId, seller, buyer, tokenSell, sellAmount, wantToken, router, value, status, confirmatory);

    }    



    function _updateLimits(address token, uint256 buyAmount) internal {

        uint256 limit = limits[token].limit;

        if (limit != 0) {

            uint256 endTime = limits[token].endTime;

            if(block.timestamp < endTime) {

                // period is not ended

                uint256 timeLeft = endTime - block.timestamp;

                buyAmount = limits[token].spent + buyAmount; // bought amount

                // if was spent more than 95% of limits during half of time period

                if(buyAmount > limit*95/100 && timeLeft >= limits[token].period/2) {

                    // increase limit

                    limits[token].nextLimit = limit*2;

                }

            } else {

                // new period

                // if spent less than 50% of limit during last period

                if(limits[token].spent < limit/2 && endTime != 0) {

                    // decrease limit

                    limit = limit/2;

                    limits[token].limit = limit;

                }

                if(endTime == 0) {

                    //start first period

                    limits[token].endTime = block.timestamp + limits[token].period;

                } else {

                    uint256 sinceStart = (block.timestamp - endTime) % limits[token].period;

                    limits[token].endTime = block.timestamp + limits[token].period - sinceStart;

                }

            }

            require(limit >= buyAmount, "OutOfLimit");

            limits[token].spent = buyAmount;

        }        

    }



    /**

     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.

     *

     * This function uses the create opcode, which should never revert.

     */

    function clone(address implementation) internal returns (address instance) {

        assembly {

            let ptr := mload(0x40)

            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)

            mstore(add(ptr, 0x14), shl(0x60, implementation))

            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

            instance := create(0, ptr, 0x37)

        }

        require(instance != address(0), "ERC1167: create failed");

    }

}