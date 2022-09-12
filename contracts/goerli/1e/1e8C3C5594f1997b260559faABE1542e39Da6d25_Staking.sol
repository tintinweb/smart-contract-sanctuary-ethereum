// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

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

    address constant RouterV1 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;//addr panckeyc or uni
    address constant OldCELL = 0x50D552756F51C66F180BaBA59662529217B2FBE7; // addr old cell token
    address constant Lp = 0x49dF46326D45166Ff50664b73Cf7FE4de787BD61; // addr old lp token
    //address WETH = 0x474673756595c91d137b68762D66a7658Cf250bb;
    address WETH = IUniswapV2Router01(RouterV1).WETH();
    address constant CELL = 0x4bFc6Aa1fef0A1656fe88d5bc112D3331c8959F5; // addr new cell token
    address constant newLp = 0xFa6f2BD27666B4Ed8f2D20973904Fd3A0bA4a052;
    address[] owners = [0x49939aeD5D127C2d9a056CA1aB9aDe9F79fa8E81,0xdC498209DeeCb868ACe2D47e137AfA52D6E1256e,0xA3656dc1EC5eF6779ba920B6d20157f4A169A30B];

    struct pairParams{
        address tokenAddr;
    }

    mapping(address => mapping(address => uint)) balanceSender;
    mapping(address => uint) balanceLP;
    mapping(string => pairParams) tokens;


    modifier Owners() {
        bool confirmation;
        for (uint8 i = 0; i < owners.length; i++){
            if(owners[i] == msg.sender){
                confirmation = true;
                break;
            }
        }
        require(confirmation ,"You are not on the list of owners");
        _;
    }



    
    function migrate(uint amountLP) public returns(uint,uint,uint liquidity){


        IERC20(Lp).transferFrom(msg.sender,address(this),amountLP);
        IERC20(Lp).approve(RouterV1,amountLP);

        (uint token0,uint token1) = migrateLP(amountLP);

        balanceSender[msg.sender][OldCELL]= token0;
        balanceSender[msg.sender][WETH]= token1;

        
        IERC20(CELL).approve(RouterV1,token0);
        IERC20(WETH).approve(RouterV1,token1);
        IERC20(OldCELL).transfer(address(1),balanceSender[msg.sender][OldCELL]);
        
                 
        return IUniswapV2Router01(RouterV1).addLiquidity(
            CELL,
            WETH,
            token0,
            token1,
            0,
            0,
            address(this),
            block.timestamp + 5000
        );
        
        

        }
    


    function migrateLP(uint amountLP) internal returns(uint256 token0,uint256 token1) {

        return IUniswapV2Router01(RouterV1).removeLiquidity(
            OldCELL,
            WETH,
            amountLP,
            1,
            1,
            address(this),
            block.timestamp + 5000
        );

    }

    function addPairV2(string memory tokenName, address tokenAddr) public Owners{
        tokens[tokenName] = pairParams({tokenAddr:tokenAddr});
    }

    function getPair(string memory pair) view public returns (address){
        return tokens[pair].tokenAddr;
    }


    receive () external payable{

    }



}

contract Staking is Migrate{
    
    bool pause;
    uint time;
    uint endTime;
    uint32 txId;
    uint8 constant idNetwork = 56;
    uint32 constant months = 60; //2629743;

    struct Participant{
        address sender;
        uint timeLock;
        string addrCN;
        address token;
        uint sum;
        uint timeUnlock;
        bool staked;
    }


    event staked(
        address owner,
        uint sum,
        uint8 countMonths,
        string addrCN,
        address token,
        uint timeStaking,
        uint timeUnlock,
        uint32 txId,
        uint8 procentage,
        uint8 networkID
    );

    event unlocked(
        address sender,
        uint sumUnlock,
        uint32 txID

    );


    Participant participant;
  
    // consensus information
    mapping(address => uint8) acceptance;
    // information Participant
    mapping(address => mapping(uint32 => Participant)) timeTokenLock;
    
    mapping(uint32 => Participant) checkPart;


    function pauseLock(bool answer) external Owners returns(bool){
        pause = answer;
        return pause;
    }


    //@dev calculate months in unixtime
    function timeStaking(uint _time,uint8 countMonths) internal pure returns (uint){
        require(countMonths >=3 , "Minimal month 3");
        require(countMonths <=24 , "Maximal month 24");
        return _time + (months * countMonths);
    }

    function seeAllStaking(address token) view public returns(uint){
        return IERC20(token).balanceOf(address(this));
    }


    function stake(uint _sum,uint8 count,string memory addrCN,uint8 procentage,string memory pairName) public  returns(uint32) {
        require(procentage >= 0 && procentage <= 100,"Max count procent 100");
        require(_sum >= 10 ** IERC20(getPair(pairName)).decimals(),"Minimal stake 1 token");
        require(pause == false,"Staking paused");
        require(getPair(pairName) != address(0));
        
    
        uint _timeUnlock = timeStaking(block.timestamp,count);
        //creating a staking participant
        participant = Participant(msg.sender,block.timestamp,addrCN,getPair(pairName),_sum,_timeUnlock,true);

        //identifying a participant by three keys (address, transaction ID, token address)
        timeTokenLock[msg.sender][txId] = participant;
        checkPart[txId] = participant;
        if(getPair(pairName) == Lp){    
            ( , , timeTokenLock[msg.sender][txId].sum) = migrate(_sum);
        }       
        emit staked(msg.sender,_sum,count,addrCN,getPair(pairName),block.timestamp,
            _timeUnlock,txId,procentage,idNetwork); 
        
        txId ++;
        return txId -1;
    }

    function claimFund(uint32 _txID) external {
        //require(block.timestamp >= timeTokenLock[msg.sender][_txID].timeUnlock,
         //  "The time has not yet come" );
        require(timeTokenLock[msg.sender][_txID].staked,"The steak was taken");
        require(msg.sender == timeTokenLock[msg.sender][_txID].sender,"You are not a staker");
        require(timeTokenLock[msg.sender][_txID].timeLock != 0);
        
        if(timeTokenLock[msg.sender][_txID].token == Lp){
            IERC20(newLp).transfer(msg.sender,timeTokenLock[msg.sender][_txID].sum );
        }else{
            IERC20(timeTokenLock[msg.sender][_txID].token).transfer(msg.sender,timeTokenLock[msg.sender][_txID].sum);
        }

        timeTokenLock[msg.sender][_txID].staked = false;
        checkPart[_txID].staked = false;
        emit unlocked(msg.sender,timeTokenLock[msg.sender][_txID].sum,_txID);


    }

   

    function seeStaked (uint32 txID) view public returns(uint timeLock,string memory addrCN,uint sum,uint timeUnlock,bool _staked){
        return (checkPart[txID].timeLock,checkPart[txID].addrCN,checkPart[txID].sum,
                checkPart[txID].timeUnlock,checkPart[txID].staked);
    }
    
   
}