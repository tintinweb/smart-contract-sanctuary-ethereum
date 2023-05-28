/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

pragma solidity 0.8.13;
// SPDX-License-Identifier: Unlicensed

// https://twitter.com/luckycoin_eth
//  
/*
.------..------..------..------..------.
|L.--. ||U.--. ||C.--. ||K.--. ||Y.--. |
| :/\: || (\/) || :/\: || :/\: || (\/) |
| (__) || :\/: || :\/: || :\/: || :\/: |
| '--'L|| '--'U|| '--'C|| '--'K|| '--'Y|
`------'`------'`------'`------'`------'
*/

/**
 * ERC20 standard interface.
 */


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * Function modifier to require caller to be contract deployer
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!Owner"); _;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Transfer ownership to new address. Caller must be deployer. Leaves old deployer authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }
    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

/*
* Lottery Interface
*/
interface ILottery{
    function checkLottery() external;
    function setTokens(address player, uint256 amount) external;
    function setTime(uint256 timeInHours) external;
    function getTotalWin() external returns (uint256);
    function getTotalWinOf(address player) external returns (uint256);
    event LotteryStart(uint256 startingTime, uint256 finishTime);
    event LotteryFinish(address winner, uint256 wonAmount);
}

contract Lottery is ILottery{
    struct Player{
        uint256 tokens;
        uint256 claimed;
    }

    struct Round{
        uint256 start;
        uint256 finish;
        uint256 won;
        address winner;
    }

    address owner;
    address _contract;
    uint256 totalTokens;
    uint256 totalWin;
    uint256 time = 24;
    bool started;
    mapping(address => Player) private playerStats;
    mapping(address => uint256) private playerIndex;
    address[] private players;
    Round[] rounds;

    constructor(address _owner) {
        _contract = msg.sender;
        owner = _owner;
    }

    modifier onlyContract{
        require(msg.sender == _contract, "Only Contract"); _;
    }

    modifier onlyOwner{
        require(msg.sender == owner, "Only Owner"); _;
    }

    function startLottery() internal onlyContract{
        require(!started, "Lottery alredy started");
        started = true;
        uint256 starting = block.timestamp;
        uint256 finish = starting + (60 * 60 * time); 
        Round memory new_round = Round({
            start: starting,
            finish:finish,
            won:0,
            winner:address(0)
            });

        rounds.push(new_round);
        emit LotteryStart(starting, finish);
    }

    function extractWinner() internal onlyContract{
        require(started, "Lottery not started");
        require(rounds[rounds.length - 1].finish <= block.timestamp, "Lottery not finished");
        uint256 number = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % totalTokens;
        for (uint256 i=0; i<players.length;i++){
            if (number <= playerStats[players[i]].tokens){
                address winner = players[i];
                uint256 claim = address(this).balance;
                playerStats[winner].claimed = playerStats[winner].claimed + claim;
                totalWin = totalWin + claim;
                rounds[rounds.length - 1].winner = winner;
                rounds[rounds.length - 1].won = claim;
                started = false;
                if(claim != 0){
                    payable(winner).transfer(claim);
                }       
                emit LotteryFinish(winner, claim);

                break;
            }
            number = number - playerStats[players[i]].tokens;
        }
    }

    function checkLottery() external override onlyContract{
        if (started){
            if (rounds[rounds.length - 1].finish <= block.timestamp){
                extractWinner();
            }            
        }else{
            startLottery();
        }
    }

    function setTokens(address player, uint256 amount) external override onlyContract{
        if(amount > 0 && playerStats[player].tokens == 0){
            addPlayer(player);
        }
        if(amount == 0){

            removePlayer(player);
        }
        totalTokens = (totalTokens - playerStats[player].tokens) + amount;

        playerStats[player].tokens = amount;
    }

    function addPlayer(address player) internal {
        playerIndex[player] = players.length;
        players.push(player);

    }

    function removePlayer(address player) internal {
        uint256 index = playerIndex[player];
        uint256 lastIndex = players.length - 1;
        players[index] = players[lastIndex];
        playerIndex[players[lastIndex]] = index;
        delete playerIndex[player];
        players.pop();

    } 

    function setTime(uint256 timeInHours) external onlyContract{
        require(timeInHours > 0);
        time = timeInHours;
    }

    function getTotalWin() external view override returns(uint256){
        return totalWin;
    }

    function getTotalWinOf(address player) external view override returns(uint256){
        return playerStats[player].claimed;
    }

    function getJackpot() external view returns(uint256){
        return address(this).balance;
    }

    function getFinish() external view returns(uint256){
        require(rounds.length > 0);
        return rounds[rounds.length - 1].finish;
    }

    function getLastRound() external view returns(uint256, uint256, uint256, address){
        return (rounds[rounds.length - 1].start, rounds[rounds.length - 1].finish, rounds[rounds.length - 1].won, rounds[rounds.length - 1].winner);
    }

    function getRound(uint256 round) external view returns(uint256, uint256, uint256, address){
        return (rounds[rounds.length - 1].start, rounds[round].finish, rounds[round].won, rounds[round].winner);
    }

    function getIsStarted() external view returns(bool){
        return started;
    }

    function getPartecipants() external view returns(uint256){
        return players.length;
    }

    function getLastWinner() external view returns(address, uint256){
        Round memory last;
        if (started){
            last = rounds[rounds.length - 2];
        }else{
            last = rounds[rounds.length -1];
        }
        return (last.winner, last.won);
                
    }

    receive() external payable { }
}

contract Lucky is IERC20, Auth {
    address private WETH;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;

    string private constant  _name = "Lucky";
    string private constant _symbol = "LUCKY";
    uint8 private constant _decimals = 9;

    uint256 private _totalSupply = 8888888 * (10 ** _decimals);
    uint256 private _maxTxAmountBuy = _totalSupply;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private cooldown;

    mapping (address => bool) private isFeeExempt;
    mapping (address => bool) private isJackpotExempt;
    mapping (address => bool) private blacklist;
            
    uint256 private totalFee = 8;
    uint256 private feeDenominator = 100;

    address payable public marketingWallet = payable(0x5B95162A51856195c224b40A0805E30929463c95); //check

    IDEXRouter public router;
    address public pair;

    bool private buyLimit = true;
    uint256 private maxBuy = 177777 * (10 ** _decimals);
    uint256 private swapLimit;
    Lottery private lottery;    
    
    bool private inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (
        address _owner,
        uint256 _swapLimitInWei
    ) Auth(_owner) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        
        _allowances[address(this)][address(router)] = type(uint256).max;

        lottery = new Lottery(_owner);
        swapLimit = _swapLimitInWei;
        isFeeExempt[_owner] = true;
        isFeeExempt[marketingWallet] = true;             
        isJackpotExempt[_owner] = true;
        isJackpotExempt[pair] = true;
        isJackpotExempt[address(this)] = true;
        isJackpotExempt[DEAD] = true;
        isJackpotExempt[ZERO] = true;        
        
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }
    receive() external payable { }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(!blacklist[sender] && !blacklist[recipient], "Blacklisted");
        if (buyLimit) { 
            if (sender!=owner && recipient!= owner) require (amount<=maxBuy, "Too much sir");        
        }

        if (sender == pair && recipient != address(router) && !isFeeExempt[recipient]) {
            //require (cooldown[recipient] < block.timestamp);
            cooldown[recipient] = block.timestamp + 60 seconds; 
        }
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        uint256 token_price = currentTokenPriceInETH();
        if(token_price != 0 && token_price * balanceOf(address(this)) >= swapLimit && recipient==pair){ swapBack(); }

        _balances[sender] = _balances[sender] - amount;
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient] + amountReceived;

        if(sender != pair && !isJackpotExempt[sender]){ try lottery.setTokens(sender, _balances[sender]) {} catch {} }
        if(recipient != pair && !isJackpotExempt[recipient]){ try lottery.setTokens(recipient, _balances[recipient]) {} catch {} }
        lottery.checkLottery();

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return ( !(isFeeExempt[sender] || isFeeExempt[recipient]) );
   }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount;
        address contractAddress = address(this);
        feeAmount = (amount * totalFee) / feeDenominator;
        _balances[contractAddress] = _balances[contractAddress] + feeAmount;
        emit Transfer(sender, contractAddress, feeAmount);   
        return amount - feeAmount;
    }

    function swapBack() internal swapping {
        // swap token for ETH
        uint256 amountToSwap = balanceOf(address(this));        
        swapTokensForEth(amountToSwap);

        // transfer ETH to marketing and lottery address
        uint256 currentEthBalance = address(this).balance;
        payable(marketingWallet).transfer(currentEthBalance / 2);        
        payable(address(lottery)).transfer(currentEthBalance / 2);
              
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function currentTokenPriceInETH() internal view returns (uint) {
        IUniswapV2Pair pool = IUniswapV2Pair(pair);
        (uint tokenReserve, uint ethReserve, ) = pool.getReserves();
        if (tokenReserve == 0){
            return 0;
        }
        uint tokenPriceInETH = (ethReserve * 1e18) / tokenReserve;
        return tokenPriceInETH;
    }

    function setBlacklist(address _address, bool toggle) external onlyOwner {
        blacklist[_address] = toggle;
        _setIsJackpotExempt(_address, toggle);
    }
    
    function setIsJackpotExempt(address holder, bool exempt) external onlyOwner {
        _setIsJackpotExempt(holder, exempt);
    }

    function _setIsJackpotExempt(address holder, bool exempt) internal onlyOwner {
        require(holder != address(this) && holder != pair, "Main contract and LP are excluded");
        isJackpotExempt[holder] = exempt;
        if(exempt){
            lottery.setTokens(holder, 0);
        }else{
            lottery.setTokens(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setMarketingWallet(address _marketingWallet) external onlyOwner {
        marketingWallet = payable(_marketingWallet);
    }

    function removeBuyLimit() external onlyOwner {
        buyLimit = false;
    }

    function setSwapLimit(uint256 amount) external onlyOwner {
        require(amount > 0, "Swap limit have to be greater than 0");
        swapLimit = amount;
    }

    function setTime(uint256 timeInHours) external onlyOwner {
        lottery.setTime(timeInHours);        
    }

    function getTotalWin() external view returns (uint256) {
        return lottery.getTotalWin();
    }

     function getTotalWinOf(address shareholder) external view returns (uint256) {
        return lottery.getTotalWinOf(shareholder);
    }

    function getJackpot() external view returns (uint256) {
        return lottery.getJackpot();
    }

    function getFinish() external view returns (uint256) {
        return lottery.getFinish();
    }

    function getRound(uint256 round) external view returns(uint256, uint256, uint256, address){
        return lottery.getRound(round);
    }

    function getIsStarted() external view returns(bool){
        return lottery.getIsStarted();
    }

    function getLastRound() external view returns(uint256, uint256, uint256, address){
        return lottery.getLastRound();
    }

    function getPartecipants() external view returns(uint256){
        return lottery.getPartecipants();
    }

    function getLastWinner() external view returns(address, uint256){
        return lottery.getLastWinner();
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO);
    }
   
}