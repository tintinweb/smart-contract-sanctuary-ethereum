/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBEP20 {

        function totalSupply() external view returns (uint256);
        
        function decimals() external view returns (uint8);
        
        function symbol() external view returns (string memory);
        
        function name() external view returns (string memory);
        
        function balanceOf(address account) external view returns (uint256);
        
        function transfer(address recipient, uint256 amount) external returns (bool);
        
        function allowance(address _owner, address spender) external view returns (uint256);
        
        function approve(address spender, uint256 amount) external returns (bool);
        
        function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
        
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner,address indexed spender,uint256 value);
}

interface IPoolFactory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);


        // address[] public allPools = [];

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

     function getInfo(address _poolCreater) external view returns (address n);

    struct User {
        address token1;
        address token2;
        address poolCreater;
        uint24 fee;
    }
    
        function getPoolInfo(address _poolCreater) external view returns (address, address, address , uint24);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;


        // mapping(address => User) public poolInformation;


}



contract SwapInPool {


    IPoolFactory public factory;



    constructor(IPoolFactory _factory) {
        factory = _factory;
    }






    function getPoolInfo(address info) external view  returns (address, address, address , uint24) {
        return (factory.getPoolInfo(info));

    }

    function tokenAToB(address _pool, uint256 amount) public {
        (address token1, address token2 , address poolCreater, uint24 fee) = factory.getPoolInfo(_pool);

        IBEP20 tokenOne;
        tokenOne = IBEP20(token1);
        IBEP20 tokenTwo;
        tokenTwo = IBEP20(token2);


        require(tokenOne.balanceOf(msg.sender) > amount , "SwapInPool::tokenAToB: not enough balance");
        require(tokenOne.balanceOf(_pool) > amount , "SwapInPool::tokenAToB: not enough balance");



        uint256 feeForPoolCreater = amount * (fee) / 10000;
        uint256 feeForFactory = amount * (30) / 10000;

        uint256 toPool = amount - (feeForPoolCreater + feeForFactory);

        address facOwner = factory.owner();


        tokenOne.transferFrom(msg.sender,poolCreater, feeForPoolCreater);
        tokenOne.transferFrom(msg.sender,facOwner, feeForFactory);
        tokenOne.transferFrom(msg.sender,_pool, toPool);

        require(tokenTwo.balanceOf(_pool) > amount , "SwapInPool::tokenAToB: not enough balance in pool");



        uint256 feeForPool = toPool * (100) / 10000;
        uint256 toSwapper = toPool - feeForPool;


        // tokenOne.transferFrom(msg.sender,_pool, amount);
        tokenTwo.transferFrom(_pool,msg.sender, toSwapper);

    }


    function tokenBtoA(address _pool,uint256 amount) public {

        (address token1, address token2 , address poolCreater, uint24 fee) = factory.getPoolInfo(_pool);

        IBEP20 tokenOne;
        tokenOne = IBEP20(token1);
        IBEP20 tokenTwo;
        tokenTwo = IBEP20(token2);


        require(tokenTwo.balanceOf(msg.sender) > amount , "SwapInPool::tokenAToB: not enough balance");
        require(tokenTwo.balanceOf(_pool) > amount , "SwapInPool::tokenAToB: not enough balance");

        uint256 feeForPoolCreater = amount * (fee) / 10000;
        uint256 feeForFactory = amount * (30) / 10000;

        uint256 toPool = amount - (feeForPoolCreater + feeForFactory);

        address facOwner = factory.owner();


        tokenTwo.transferFrom(msg.sender,poolCreater, feeForPoolCreater);
        tokenTwo.transferFrom(msg.sender,facOwner, feeForFactory);
        tokenTwo.transferFrom(msg.sender,_pool, toPool);


        require(tokenOne.balanceOf(_pool) > amount , "SwapInPool::tokenAToB: not enough balance in pool");



        uint256 feeForPool = toPool * (100) / 10000;
        uint256 toSwapper = toPool - feeForPool;


        // tokenOne.transferFrom(msg.sender,_pool, amount);
        tokenOne.transferFrom(_pool,msg.sender, toSwapper);




    }
}