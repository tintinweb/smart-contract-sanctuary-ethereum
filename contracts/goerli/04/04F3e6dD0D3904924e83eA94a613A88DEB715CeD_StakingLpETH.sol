// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/IV3Migrator.sol';
//Interface for interacting with erc20

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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


    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address owner) view external returns (uint256);

    function decimals() view external returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function token0() external view returns (address);
    function token1() external view returns (address);


}

contract MigrateV2toV3{

    struct pairParams{
        int24 _tickLower;
        int24 _tickUpper;
        address tokenAddr;
    }

    mapping(string => pairParams) tokens;
    address[3] owners = [0x49939aeD5D127C2d9a056CA1aB9aDe9F79fa8E81,0xdC498209DeeCb868ACe2D47e137AfA52D6E1256e,0xA3656dc1EC5eF6779ba920B6d20157f4A169A30B];

    modifier OnlyThis(){
        require(msg.sender == address(this),"Only a contract can call");
        _;
    }

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

    IV3Migrator public V3Migrator = IV3Migrator(0xA5644E29708357803b5A882D272c41cC0dF92B34);

    function addPairV2(string memory tokenName, address tokenAddr,int24 _tickLower,int24 _tickUpper) public Owners{
        tokens[tokenName] = pairParams({_tickLower:_tickLower,_tickUpper:_tickUpper,tokenAddr:tokenAddr});
    }

    function getPair(string memory pair) view public returns (address){
        return tokens[pair].tokenAddr;
    }

    function migrate(uint amount,string memory tokenName,address sender) public OnlyThis{
        require(tokens[tokenName].tokenAddr != address(0),"Not tokens");

        
        IERC20(tokens[tokenName].tokenAddr).approve(address(V3Migrator),amount);

        IV3Migrator.MigrateParams memory params = IV3Migrator.MigrateParams({
            pair: tokens[tokenName].tokenAddr,
            liquidityToMigrate: amount,
            percentageToMigrate: 100,
            token0:IERC20(tokens[tokenName].tokenAddr).token0(),
            token1:IERC20(tokens[tokenName].tokenAddr).token1(),
            fee:3000,
            tickLower: tokens[tokenName]._tickLower,
            tickUpper: tokens[tokenName]._tickUpper,
            amount0Min: 0,
            amount1Min: 0,
            recipient: sender,
            deadline: block.timestamp + 5000,
            refundAsETH:true
        });
        
        V3Migrator.migrate(params);

    }

}





contract StakingLpETH is MigrateV2toV3{
   
    bool pause;
    uint time;
    uint endTime;
    uint32 txId;
    uint8 constant idNetwork = 1;
    uint32 constant months = 2629743;

    struct Participant{
        address sender;
        uint timeLock;
        string addrCN;
        uint sum;
        uint timeUnlock;
        address token;
        bool staked;
    }


    event staked(
        address owner,
        uint sum,
        uint8 countMonths,
        address token,
        string addrCN,
        uint timeStaking,
        uint timeUnlock,
        uint32 txId,
        uint8 procentage,
        uint8 networkID
    );

    event unlocked(
        address sender,
        uint sumUnlock,
        address tokenAddr,
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


    function stake(uint _sum,uint8 count,string memory addrCN,uint8 procentage,string memory _tokenName) public  returns(uint32) {
        require(procentage >= 0 && procentage <= 100,"Max count procent 100");
        require(_sum >= 10 ** IERC20(getPair(_tokenName)).decimals(),"Minimal stake 1 token");
        require(getPair(_tokenName) != address(0),"not this token");
        require(pause == false,"Staking paused");
        

        uint _timeUnlock = timeStaking(block.timestamp,count);
        //creating a staking participant
        participant = Participant(msg.sender,block.timestamp,addrCN,_sum,_timeUnlock,getPair(_tokenName),true);
        //identifying a participant by three keys (address, transaction ID, token address)
        timeTokenLock[msg.sender][txId] = participant;
   

        checkPart[txId] = participant;
        IERC20(getPair(_tokenName)).transferFrom(msg.sender,address(this),_sum);
         
        emit staked(msg.sender,_sum,count,getPair(_tokenName),addrCN,block.timestamp,
            _timeUnlock,txId,procentage,idNetwork); 
        
        txId ++;
        return txId -1;
    }

    function claimFund(uint32 _txID,string memory pairName) external {
        //require(block.timestamp >= timeTokenLock[msg.sender][_txID].timeUnlock,
         //  "The time has not yet come" );
        require(timeTokenLock[msg.sender][_txID].staked,"The steak was taken");
        require(msg.sender == timeTokenLock[msg.sender][_txID].sender,"You are not a staker");
        require(timeTokenLock[msg.sender][_txID].timeLock != 0);
        
        //migrateV2toV3(timeTokenLock[msg.sender][_txID].sum);
        (bool success, ) = address(this).call(
            abi.encodeWithSignature("migrate(uint256,string,address)",timeTokenLock[msg.sender][_txID].sum,pairName,msg.sender)
        );
        require(success,"not success");
        timeTokenLock[msg.sender][_txID].staked = false;
        //emit unlocked(msg.sender,timeTokenLock[msg.sender][_txID].sum,_token,_txID);


    }

   

    function seeStaked (uint32 txID) view public returns(uint timeLock,string memory addrCN,uint sum,uint timeUnlock,address token,bool _staked){
        return (checkPart[txID].timeLock,checkPart[txID].addrCN,checkPart[txID].sum,
                checkPart[txID].timeUnlock,checkPart[txID].token,checkPart[txID].staked);
    }

   


}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import './IMulticall.sol';
import './ISelfPermit.sol';
import './IPoolInitializer.sol';

/// @title V3 Migrator
/// @notice Enables migration of liqudity from Uniswap v2-compatible pairs into Uniswap v3 pools
interface IV3Migrator is IMulticall, ISelfPermit, IPoolInitializer {
    struct MigrateParams {
        address pair; // the Uniswap v2-compatible pair
        uint256 liquidityToMigrate; // expected to be balanceOf(msg.sender)
        uint8 percentageToMigrate; // represented as a numerator over 100
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Min; // must be discounted by percentageToMigrate
        uint256 amount1Min; // must be discounted by percentageToMigrate
        address recipient;
        uint256 deadline;
        bool refundAsETH;
    }

    /// @notice Migrates liquidity to v3 by burning v2 liquidity and minting a new position for v3
    /// @dev Slippage protection is enforced via `amount{0,1}Min`, which should be a discount of the expected values of
    /// the maximum amount of v3 liquidity that the v2 liquidity can get. For the special case of migrating to an
    /// out-of-range position, `amount{0,1}Min` may be set to 0, enforcing that the position remains out of range
    /// @param params The params necessary to migrate v2 liquidity, encoded as `MigrateParams` in calldata
    function migrate(MigrateParams calldata params) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
interface ISelfPermit {
    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// Can be used instead of #selfPermit to prevent calls from failing due to a frontrun of a call to #selfPermit
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// Can be used instead of #selfPermitAllowed to prevent calls from failing due to a frontrun of a call to #selfPermitAllowed.
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}