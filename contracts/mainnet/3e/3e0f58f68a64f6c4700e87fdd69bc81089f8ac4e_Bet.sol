/**
 *Submitted for verification at Etherscan.io on 2022-10-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface ERC20Interface {
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
  function transfer(address _to, uint256 _value) external;
  function approve(address _spender, uint256 _value) external returns (bool);
  function symbol() external view returns (string memory);
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract Manager is Ownable{

    mapping(address => bool) private _managers;

    event AddManager(address indexed manager);

    event RemoveManager(address indexed manager);

    modifier onlyManager() {
        require(_msgSender() == owner() || _managers[_msgSender()], "ERC721: caller is not the owner");
        _;
    }

    function addManager(address manager) external onlyOwner {
        _managers[manager] = true;
        emit AddManager(manager);
    }

    function removeManager(address manager) external onlyOwner {
        _managers[manager] = false;
        emit RemoveManager(manager);
    }

    function isManager(address manager) external view returns(bool) {
        return _msgSender() == owner() || _managers[manager];
    }
}

contract Bet is Manager{

    // platform pool fee.
    uint public fee = 3;

    uint public poolAmount = 0;

    bool public  closeFlag = false;

    // user win the token , and count in to this pool. user address => token address => withdraw amount . if user withdraw their token ,the amount will be clear.
    mapping( address=>mapping(address=>uint256)) public winPool;

    // poolid => bet option id ( 0->draw、1->win、2->lose) => bet address => bet amount
    mapping (uint => mapping(uint => mapping(address => uint256))) public betAddressDetails; 

    // poolid => bet option id ( 0->draw、1->win、2->lose) => bet amount
    mapping (uint => mapping(uint => uint)) public betDetails;

    // poolid => bet option id ( 0->draw、1->win、2->lose) => bet addresses in the option
    mapping (uint => mapping(uint => address[])) public betAddressList;

    //bet pool
    struct Pool {
        uint poolId;
        string team1Name;
        string team1Logo;
        string team2Name;
        string team2Logo;
        string league;
        string leagueLogo;
        uint256  startDate;
        address payCoinAddress;
        uint256 betAmount;
        uint gameType;  //game type, 0-normal ,1-elimination，when the type is 1, there was no option name "draw"
    }

    //bet result
    struct PoolScore{
        bool status;    //0-close,1-open
        uint team1Score;
        uint team2Score;
    }

    mapping (uint => PoolScore) public poolStatus;

    mapping (uint => Pool) public  pools;

    event ModifyFee(
        uint _fee
    );

    event AddGamePool(
        uint256 indexed _poolId,
        string _team1Name,
        string _team1Logo,
        string _team2Name,
        string _team2Logo,
        string _league,
        string _leagueLogo,
        uint _gameType,
        uint256 _startDate,
        address _payCoinAddress
    );

    event UserBet(
        address indexed _user,
        uint indexed _poolId,
        uint _option,
        uint256 _amount,
        uint256 _date
    );

    event DeletePool(
        uint indexed _poolId
    );

    event ClosePool(
        uint indexed _poolId,
        uint _team1Score,
        uint _team2Score,
        uint256 _fee,
        uint256 _userBenfit
    );

    event UserBenfit(
        address indexed _user,
        uint indexed _poolId,
        address _token,
        uint256 _betValue,
        uint256 _benfit,
        uint _type  // 0-win 1-widthdraw 2-pool cancel
    );

    event ModifyPoolStartDate(
        uint indexed _poolId,
        uint256 _startDate
    );

    function modifyFee(uint _fee)public onlyOwner{
        fee = _fee;

        emit ModifyFee(_fee);
    }

    function modifyCloseFlag(bool flag) public onlyOwner{
        closeFlag = flag;
    }

    function date() public view returns (uint256){
        return block.timestamp;
    }

    /**/
    function addGamePool(string memory team1Name,string memory team1Logo,string memory team2Name,string memory team2Logo,string memory league,string memory leagueLogo,uint gameType,uint256  startDate,address payCoinAddress) public onlyManager{

        if(payCoinAddress != address(0)){
            string memory symbol = ERC20Interface(payCoinAddress).symbol();
            require(bytes(symbol).length != 0,"Bet,Token not exist");
        }

        //new pool
        Pool storage pool = pools[poolAmount+1];
        pool.poolId = poolAmount+1;
        pool.team1Name = team1Name; 
        pool.team1Logo = team1Logo;
        pool.team2Name = team2Name;
        pool.team2Logo = team2Logo;
        pool.league = league;
        pool.leagueLogo = leagueLogo;
        pool.startDate = startDate;
        pool.payCoinAddress = payCoinAddress;
        pool.betAmount = 0;
        pool.gameType = gameType;

        PoolScore storage score = poolStatus[pool.poolId];
        score.status = true;
        score.team1Score = 0;
        score.team2Score = 0;

        poolAmount ++;

        emit AddGamePool(pool.poolId,team1Name,team1Logo,team2Name,team2Logo,league,leagueLogo,gameType,startDate,payCoinAddress);
    }

    /*
        poolId：game pool id
        opt：bet opt( 0->draw、1->win、2->lose)
        amount 
    */
    function bet(uint poolId,uint opt,uint256 amount) public payable {

        //handle bet pool
        Pool storage pool = pools[poolId];
        PoolScore memory score = poolStatus[poolId];

        require(pool.startDate != 0,"Bet,pool is not exist.");
        require(score.status,"Bet,pool is closed");
        require(pool.startDate>block.timestamp,"Bet, game is start , donnt allow bet.");
        if(pool.gameType == 1){
            require(opt == 1 || opt == 2,"Bet,bet option is not exist.");
        }else{
            require(opt == 0 || opt == 1 || opt == 2,"Bet,bet option is not exist.");
        }

        uint256 didBetAmount = betAddressDetails[poolId][opt][msg.sender];

        if(pool.payCoinAddress == address(0)){
            require(msg.value == amount);
        }else{
            ERC20Interface(pool.payCoinAddress).transferFrom(msg.sender,address(this),amount);
        }

        if(didBetAmount == 0){
            betAddressList[poolId][opt].push(msg.sender);
        }

        //count pool bet address detail
        betAddressDetails[poolId][opt][msg.sender] = didBetAmount + amount;

        //count pool bet option amount
        betDetails[poolId][opt] = betDetails[poolId][opt] + amount;

        pool.betAmount += amount;

        emit UserBet(msg.sender,poolId,opt,amount,block.timestamp);
    }

    /*
        modifyPoolStartDate
    */  
    function modifyPoolStartDate(uint poolId,uint256 startDate)public onlyManager {

        Pool storage pool = pools[poolId];
        PoolScore memory score = poolStatus[poolId];

        require(pool.poolId != 0,"Bet,pool is not exist.");
        require(score.status,"Bet,pool is closed");

        pool.startDate = startDate;

        emit ModifyPoolStartDate(poolId,startDate);
    }

    /*
        manager close pool with team score. and update user benfit.
    */
    function closePool(uint poolId,uint team1Score,uint team2Score)public onlyManager{

        Pool storage pool = pools[poolId];
        PoolScore storage score = poolStatus[poolId];

        require(pool.startDate != 0,"Bet,pool is not exist.");
        require(score.status,"Bet,pool is closed");

        if(pool.gameType == 1){
            require(team1Score != team2Score,"Bet,pool not allow draw.");
        }

        if(!closeFlag){
            require( block.timestamp > pool.startDate + 90 minutes,"Bet,game is not start.");
        }

        //count benfit
        uint result = team1Score == team2Score ? 0 : ( team1Score > team2Score ? 1 : 2);

        //if no winer or no loser, the pool will be canceled , and all bet will reback to their balance without fee.
        if(betDetails[poolId][result] == 0 || betDetails[poolId][result] == pool.betAmount){

            uint8[3] memory results = [0,1,2];

            for(uint j=0;j<results.length;j++){
                uint inResult = results[j];
                address[] memory list = betAddressList[poolId][inResult];

                //update user win pool benfit
                for(uint i;i<list.length;i++){
                    uint256 userBetAmount = betAddressDetails[poolId][inResult][list[i]];
                    //update withdraw pool
                    winPool[list[i]][pool.payCoinAddress] = winPool[list[i]][pool.payCoinAddress] + userBetAmount;
                    //record every benfit.
                    emit UserBenfit(list[i],poolId,pool.payCoinAddress,userBetAmount,0,2);
                }
            }

            emit ClosePool(poolId,team1Score,team2Score,0,0);
        }
        //normal
        else{
            uint256 platformBenfit = (pool.betAmount - betDetails[poolId][result]) * fee / 100;
            uint256 userBenfit = pool.betAmount  - betDetails[poolId][result] - platformBenfit;
            uint256 baseBenfit = userBenfit * 10**8 / betDetails[poolId][result];

            //send benfit to owner address
            if(pool.payCoinAddress == address(0)){
                address payable payOwner = payable(owner());
                payOwner.transfer(platformBenfit);
            }else{
                ERC20Interface(pool.payCoinAddress).transfer(owner(),platformBenfit);
            }

            address[] memory list = betAddressList[poolId][result];

            //update user win pool benfit
            for(uint i;i<list.length;i++){
                uint256 userBetAmount = betAddressDetails[poolId][result][list[i]];
                uint256 benfit = userBetAmount * baseBenfit / 10**8;
                //update withdraw pool
                winPool[list[i]][pool.payCoinAddress] = winPool[list[i]][pool.payCoinAddress] + benfit + userBetAmount;
                //record every benfit.
                emit UserBenfit(list[i],poolId,pool.payCoinAddress,userBetAmount,benfit,0);
            }

            emit ClosePool(poolId,team1Score,team2Score,platformBenfit,userBenfit);
        }

        score.team1Score = team1Score;
        score.team2Score = team2Score;
        //close pool
        score.status = false;

    }

    /*
    
    */
    function deletePool(uint poolId) public  onlyManager{

        Pool storage pool = pools[poolId];
        PoolScore storage score = poolStatus[poolId];

        require(pool.startDate != 0,"Bet,pool is not exist.");
        require(score.status,"Bet,pool is closed");


        if (pool.betAmount != 0){

            uint8[3] memory results = [0,1,2];

            for(uint j=0;j<results.length;j++){
                uint inResult = results[j];
                address[] memory list = betAddressList[poolId][inResult];

                //update user win pool benfit
                for(uint i;i<list.length;i++){
                    uint256 userBetAmount = betAddressDetails[poolId][inResult][list[i]];
                    //update withdraw pool
                    winPool[list[i]][pool.payCoinAddress] = winPool[list[i]][pool.payCoinAddress] + userBetAmount;
                    //record every benfit.
                    emit UserBenfit(list[i],poolId,pool.payCoinAddress,userBetAmount,0,2);
                }
            }
        }

        //close pool
        score.status = false;

        emit DeletePool(poolId);
    }

    /*
        user withdraw their token or gas coin
    */
    function widthdraw(address tokenContract) public{
        uint256 balance = winPool[msg.sender][tokenContract];
        require(balance>0,"Bet, token balance is zero.");

        if(tokenContract == address(0)){
            _msgSender().transfer(balance);
        }else{
            ERC20Interface(tokenContract).transfer(msg.sender,balance);
        }

        winPool[msg.sender][tokenContract] = 0;

        emit UserBenfit(msg.sender,0,tokenContract,0,balance,1);
    }
}