/**
 *Submitted for verification at Etherscan.io on 2023-03-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//Interface for interacting with erc20

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
   
}



interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);


    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) view external returns (uint256);
    function decimals() view external returns (uint256);


}

contract Migrate {

    address constant ROUTER_V2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;//addr pancakeRouter
    address payable public marketingAddress = payable(0x50eBB0827Aa80bA1A2a30b38581629996262d481);
    address public owner;
    address OLD_KEL;


    struct pairParams{
        address tokenAddrOld;
        address tokenAddrNew;
        address LP_OLD;
        address LP_NEW;
        address token0_Old;
        address token1_Old;
        address token0_new;
        address token1_new;

    }

    event addresses(
        address tokenAddrOld,
        address tokenAddrNew,
        address LP_OLD,
        address LP_NEW,
        address token0_Old,
        address token1_Old,
        address token0_new,
        address token1_new
    );

    mapping(address => uint) balanceLP;
    mapping(string => pairParams) tokensMigrateParams;
    mapping(string => address) tokens;

    modifier onlyOwner() {
        require(msg.sender == owner,"You not owner");
        _;
    }

    constructor(address _oldkel){
        owner = msg.sender;
        OLD_KEL = _oldkel;

    }

    function migrate(uint amountLP,string memory _pair,bool _migrate) internal returns(uint) {

        if(_migrate) {
            (uint token0,uint token1) = migrateLP(amountLP,_pair);
            
            (uint t0,uint t1, ) = IUniswapV2Pair(tokensMigrateParams[_pair].LP_NEW).getReserves();
            
            uint eth;
            uint kel;

            if (t0 > t1) {
                eth = t1;
                kel = t0;
                
            } else {
                eth = t0;
                kel = t1;
            }

            if(token0 > token1){
                uint resoult = kel/eth;
                token0 = resoult * token1;

            } else {
                uint resoult = kel/eth;
                token1 = resoult * token0;
            }
            

            IERC20(tokensMigrateParams[_pair].token0_new).approve(
                ROUTER_V2,
                token0
                );

            IERC20(tokensMigrateParams[_pair].token1_new).approve(
                ROUTER_V2,
                token1
                );

            (uint tokenA,uint tokenB , uint liquidity ) = IUniswapV2Router01(ROUTER_V2).addLiquidity(
                tokensMigrateParams[_pair].token0_new,
                tokensMigrateParams[_pair].token1_new,
                token0,
                token1,
                0,
                0,
                address(this),
                block.timestamp + 5000
            );

            uint balanceOldToken = IERC20(OLD_KEL).balanceOf(address(this));
            IERC20(OLD_KEL).transfer(marketingAddress,balanceOldToken);

            if (tokenA < token0) {
                uint256 refund0 = token0 - tokenA;

                IERC20(tokensMigrateParams[_pair].token0_new).transfer(
                    msg.sender,
                    refund0
                    );

            }
            if(tokenB < token1){
                uint256 refund1 = token1 - tokenB;

                IERC20(tokensMigrateParams[_pair].token1_new).transfer(
                    msg.sender,
                    refund1
                    );
                
            }

            return liquidity;

        } else {

            IERC20(tokens[_pair]).transferFrom(
                msg.sender,
                address(this),
                amountLP
                );

            return amountLP;

            }

     }


    function migrateLP(uint amountLP,string memory _pair) internal returns(uint256 token0,uint256 token1) {

        IERC20(tokensMigrateParams[_pair].LP_OLD).transferFrom(
            msg.sender,
            address(this),
            amountLP
            );
       
        IERC20(tokensMigrateParams[_pair].LP_OLD).approve(
            ROUTER_V2,
            amountLP
            );

        return IUniswapV2Router01(ROUTER_V2).removeLiquidity(
            tokensMigrateParams[_pair].token0_Old,
            tokensMigrateParams[_pair].token1_Old,
            amountLP,
            0,
            0,
            address(this),
            block.timestamp + 5000
        );

    }
    
    function addPairToMigrate(string memory tokenName, address[4] memory tokenAddr) external onlyOwner returns(pairParams memory){
        
        address token0old = IUniswapV2Pair(tokenAddr[2]).token0();
        address token1old = IUniswapV2Pair(tokenAddr[2]).token1();

        address token0new = IUniswapV2Pair(tokenAddr[3]).token0();
        address token1new = IUniswapV2Pair(tokenAddr[3]).token1();

        tokensMigrateParams[tokenName] = pairParams({
            tokenAddrOld:tokenAddr[0],
            tokenAddrNew:tokenAddr[1],
            LP_OLD:tokenAddr[2],
            LP_NEW:tokenAddr[3],
            token0_Old:token0old,
            token1_Old:token1old,
            token0_new:token0new,
            token1_new:token1new

            });
        emit addresses(
            tokensMigrateParams[tokenName].tokenAddrOld,
            tokensMigrateParams[tokenName].tokenAddrNew,
            tokensMigrateParams[tokenName].LP_OLD,
            tokensMigrateParams[tokenName].LP_NEW,
            tokensMigrateParams[tokenName].token0_Old,
            tokensMigrateParams[tokenName].token1_Old,
            tokensMigrateParams[tokenName].token0_new,
            tokensMigrateParams[tokenName].token1_new

        );
        return tokensMigrateParams[tokenName];
    }

    function addPair(string memory tokenName, address tokenAddr) external onlyOwner{
        tokens[tokenName] = tokenAddr;
    }

    function getPairMigrate(string memory pair) view public returns (pairParams memory){
        return tokensMigrateParams[pair];
        
    }

    function getPair(string memory pair) view public returns(address){
        return tokens[pair];
    }

}

contract StakingETH is Migrate{

    bool pause;
    uint time;
    uint endTime;
    uint32 txId;
    uint8 constant idNetwork = 1;
    uint32 constant months = 2629743;

    struct Participant{
        address sender;
        uint timeLock;
        bool migrate;
        string addrCN;
        address token;
        string pairName;
        uint sum;
        uint timeUnlock;
        bool staked;
    }


    event staked(
        address sender,
        uint value,
        uint8 countMonths,
        string walletCN,
        address token,
        uint time,
        uint timeUnlock,
        uint32 txId,
        uint8 procentage,
        uint8 networkID,
        uint _block
    );

    event unlocked(
        address sender,
        uint sumUnlock,
        uint32 txID

    );

    constructor(address oldKel) Migrate(oldKel){}


    Participant participant;

    // information Participant
    mapping(address => mapping(uint32 => Participant)) timeTokenLock;

    mapping(uint32 => Participant) checkPart;


    function pauseLock(bool answer) external onlyOwner returns(bool){
        pause = answer;
        return pause;
    }

    function setMarketingAddress(address _addy) external onlyOwner {
    marketingAddress = payable(_addy);
    }


    //@dev calculate months in unixtime
    function timeStaking(uint _time,uint8 countMonths) internal pure returns (uint){
        require(
            countMonths >=3,
             "Minimal month 3"
             );
        require(
            countMonths <=24,
            "Maximal month 24"
         );
        return _time + (months * countMonths);
    }

    function seeAllStaking(address token) view public returns(uint){
        return IERC20(token).balanceOf(address(this));
    }


    function stake(uint _sum,bool _migrate,uint8 count,string memory addrCN,uint8 procentage,string memory pairName) public  returns(uint32) {
        require(
            procentage <= 100,
            "Max count procent 100"
            );
        require(
            !pause,
            "Staking paused"
            );
        require(getPair(pairName) != address(0));

        uint _timeUnlock = timeStaking(
                            block.timestamp,
                            count
                           );
        //creating a staking participant
        participant = Participant(
                        msg.sender,
                        block.timestamp,
                        _migrate,
                        addrCN,
                        getPair(pairName),
                        pairName,
                        _sum,
                        _timeUnlock,
                        true
                    );

        //identifying a participant by three keys (address, transaction ID, token address)
        timeTokenLock[msg.sender][txId] = participant;
        checkPart[txId] = participant;

        
        timeTokenLock[msg.sender][txId].sum = migrate(_sum,pairName,_migrate);
        

        emit staked(
            msg.sender,
            _sum,
            count,
            addrCN,
            getPair(pairName),
            block.timestamp,
            _timeUnlock,
            txId,
            procentage,
            idNetwork,
            block.number
            );

        txId ++;
        return txId -1;
    }

    function claimFund(uint32 _txID) external {
        require(
            block.timestamp >= timeTokenLock[msg.sender][_txID].timeUnlock,
           "The time has not yet come"
            );
        require(
            timeTokenLock[msg.sender][_txID].staked,
            "The steak was taken"
            );
        require(
            msg.sender == timeTokenLock[msg.sender][_txID].sender,
            "You are not a staker"
            );
        require(timeTokenLock[msg.sender][_txID].timeLock != 0);

        if(!timeTokenLock[msg.sender][_txID].migrate){
            IERC20(timeTokenLock[msg.sender][_txID].token).transfer(
                msg.sender,
                timeTokenLock[msg.sender][_txID].sum
                );
        }else{
            IERC20(getPairMigrate(timeTokenLock[msg.sender][_txID].pairName).LP_NEW).transfer(
                msg.sender,
                timeTokenLock[msg.sender][_txID].sum
                );
        }

        timeTokenLock[msg.sender][_txID].staked = false;
        checkPart[_txID].staked = false;
        
        emit unlocked(
            msg.sender,
            timeTokenLock[msg.sender][_txID].sum,
            _txID
            );

    }


    function seeStaked (uint32 txID) view public returns
                                                        (uint timeLock,
                                                        string memory addrCN,
                                                        uint sum,
                                                        uint timeUnlock,
                                                        bool _staked){
        return (
            checkPart[txID].timeLock,
            checkPart[txID].addrCN,
            checkPart[txID].sum,
            checkPart[txID].timeUnlock,
            checkPart[txID].staked
            );
    }

 

    function withdraw(address tokenAddr, uint _amount) external onlyOwner {
        IERC20(tokenAddr).transfer(
            msg.sender,
            _amount
            );
    }
}