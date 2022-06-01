/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;




/// @title An interface for a contract that is capable of deploying Pool Pools
/// @notice A contract that constructs a pool must implement this to pass arguments to the pool
/// @dev This is used to avoid having constructor arguments in the pool contract, which results in the init code hash
/// of the pool being constant allowing the CREATE2 address of the pool to be cheaply computed on-chain
interface IPoolDeployer {
    /// @notice Get the parameters to be used in constructing the pool, set transiently during pool creation.
    /// @dev Called by the pool constructor to fetch the parameters of the pool
    /// Returns factory The factory address
    /// Returns token0 The first token of the pool by address sort order
    /// Returns token1 The second token of the pool by address sort order
    /// Returns fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// Returns tickSpacing The minimum number of ticks between initialized ticks
    function parameters()
        external
        view
        returns (
            address factory,
            address token0,
            address token1,
            uint24 fee
        );
}


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





contract Pool {


    
    address public factory;

    address public SwapTokenPool;
    address public StakeInPool;

    address public token0;

    address public token1;

    uint24 public fee;

    // struct ProtocolFees {
    //     uint256 token0;
    //     uint256 token1;
    // }

    // ProtocolFees public protocolFees;

    // uint256 public liquidity;

    /// @dev Prevents calling a function from anyone except the address returned by IPoolFactory#owner()
    // modifier onlyFactoryOwner() {
    //     require(msg.sender == IPoolFactory(factory).owner());
    //     _;
    // }

    constructor() {
        // (factory, token0, token1, fee) = IPoolDeployer(msg.sender).parameters();
        // tokenToPool(token0,token1);
    }

    uint256 count1 = 0;
    uint256 count2 = 0;
    uint256 count3 = 0;
    uint256 count4 = 0;
    uint256 count5 = 0;
    uint256 count6 = 0;

    function setToken0(address _token0) public {
        require(count3 < 1, "Only set one time");

        token0 = _token0;
        count3++;

    }
    function setToken1(address _token1) public {
        require(count4 < 1, "only set one time");
        token1 = _token1;
        count4++;
    }
    function setFactory(address _factory) public {
        require(count5 < 1, "only set one time");
        factory = _factory;
        count5++;
    }

    function setFee(uint24 _fee) public {
        require(count6 < 1, "only set one time");
        fee = _fee;
        count6++;
    }

    function setSwapTokenPool(address _SwapTokenPool) external {
        require(count1 < 1, "Only change it first");

        IBEP20 tokenOne;
        tokenOne = IBEP20(token0);
        IBEP20 tokenTwo;
        tokenTwo = IBEP20(token1);

        SwapTokenPool = _SwapTokenPool;



        uint256 totalTokens1 = tokenOne.totalSupply(); 
        uint256 totalTokens2 = tokenTwo.totalSupply();


        require(tokenOne.approve(SwapTokenPool, totalTokens1), 'approve failed.');
        require(tokenTwo.approve(SwapTokenPool, totalTokens2), 'approve failed.');

        count1++;
    }

    function setStakeInPool(address _StakeInPool) external {
        require(count2 < 1, "Only change it first");
        StakeInPool = _StakeInPool;


        IBEP20 tokenOne;
        tokenOne = IBEP20(token0);
        IBEP20 tokenTwo;
        tokenTwo = IBEP20(token1);

        uint256 totalTokens1 = tokenOne.totalSupply(); 
        uint256 totalTokens2 = tokenTwo.totalSupply();


        require(tokenOne.approve(StakeInPool, totalTokens1), 'approve failed.');
        require(tokenTwo.approve(StakeInPool, totalTokens2), 'approve failed.');

        count2++;
    }




    function tokenToPool(address tokenA, address tokenB) public {


        IBEP20 tokenOne;
        tokenOne = IBEP20(tokenA);
        IBEP20 tokenTwo;
        tokenTwo = IBEP20(tokenB);

        uint256 amountInOne = tokenOne.balanceOf(msg.sender); 
        uint256 amountInTwo = tokenTwo.balanceOf(msg.sender);

        // uint256 totalTokens1 = tokenOne.totalSupply(); 
        // uint256 totalTokens2 = tokenTwo.totalSupply();


        require(amountInOne == amountInTwo, "Didn't provide equal liquidity");


        // require(tokenOne.approve(address(this), amountInOne), 'approve failed.');
        // require(tokenTwo.approve(address(this), amountInTwo), 'approve failed.');

        require(tokenOne.transferFrom(msg.sender, address(this), amountInOne), "transferFrom failed.");


        require(tokenTwo.transferFrom(msg.sender, address(this), amountInTwo), "transferFrom failed.");

        // require(tokenOne.approve(SwapTokenPool, totalTokens1), 'approve failed.');
        // require(tokenTwo.approve(SwapTokenPool, totalTokens2), 'approve failed.');

        // require(tokenOne.approve(StakeInPool, totalTokens1), 'approve failed.');
        // require(tokenTwo.approve(StakeInPool, totalTokens2), 'approve failed.');


    }

    // function bal(address tokenA) public returns(uint256) {
    //     IBEP20 tokenOne;
    //     tokenOne = IBEP20(tokenA);
    //     // IBEP20 tokenTwo;
    //     // tokenTwo = IBEP20(tokenB);

    //     // require(tokenOne.approve(address(this), amountInOne), "approve failed.");


    //     uint256 amountInOne = tokenOne.balanceOf(msg.sender); 
    //     tokenOne.approve(msg.sender, amountInOne);
    //     // tokenOne.transfer(address(this), amountInOne);
    //     // require(tokenOne.transferFrom(address(this), address(this), amountInOne), "transferFrom failed.");


    //     // uint256 amountInTwo = tokenTwo.balanceOf(msg.sender);
    //     return amountInOne;
    // }


}
// contract IPool {}



contract PoolFactory {


    address public owner;

    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event PoolCreated( address indexed token0,address indexed token1, uint24 indexed fee,address pool);

    event FeeAmountEnabled(uint24 indexed fee);


    struct Parameters {
        address factory;
        address token0;
        address token1;
        uint24 fee;
    }

    


    Parameters internal parameters;
    

    function deploy(address factory, address token0,address token1,uint24 fee) internal returns(address pool) {
        parameters = Parameters({factory : factory, token0 : token0, token1 : token1, fee : fee});
        pool = address(new Pool{salt: keccak256(abi.encode(token0, token1, fee))}());

        // pool.tokenToPool(token1,token0);
        delete parameters;
    }

    mapping(address => mapping(address => mapping(uint24 => address))) public getPool;

    constructor() {
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);

    }

    struct User {
        address token1;
        address token2;
        address poolCreater;
        uint24 fee;
    }

    mapping(address => User) public poolInformation;
   
    function getPoolInfo(address _poolCreater) public view returns (address, address, address , uint24) {
        User storage user = poolInformation[_poolCreater];
        address t1 = user.token1;
        address t2 = user.token2;
        address pc = user.poolCreater;
        uint24 fe = user.fee;

        return (t1,t2,pc,fe);
    }





    function createPool(address tokenA, address tokenB, uint24 fee) external returns(address pool) {
        require(tokenA != tokenB);
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0));
        require(getPool[token0][token1][fee] == address(0));
        pool = deploy(address(this), token0,token1, fee);
        getPool[token0][token1][fee] = pool;
        getPool[token1][token0][fee] = pool;


        User storage user = poolInformation[pool];
        user.token1 = tokenA;
        user.token2 = tokenB;
        user.poolCreater = msg.sender;
        user.fee = fee;

        emit PoolCreated(token0,token1,fee,pool);
    }



    function setOwner(address _owner) external {
        require(msg.sender == owner);
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    function withdrawFee() payable public {
        require(msg.sender == owner);
        payable(owner).transfer(address(this).balance);
    }


}

// contract IPool {}
// contract PoolFactory {


//     address public owner;

//     event OwnerChanged(address indexed oldOwner, address indexed newOwner);
//     event PoolCreated( address indexed token0,address indexed token1, uint24 indexed fee,address pool);

//     event FeeAmountEnabled(uint24 indexed fee);


//     struct Parameters {
//         address factory;
//         address token0;
//         address token1;
//         uint24 fee;
//     }



//     Parameters internal parameters;
    

//     function deploy(address factory, address token0,address token1,uint24 fee) internal returns(address pool) {
//         parameters = Parameters({factory : factory, token0 : token0, token1 : token1, fee : fee});
//         pool = address(new IPool{salt: keccak256(abi.encode(token0, token1, fee))}());
//         delete parameters;
//     }

//     mapping(address => mapping(address => mapping(uint24 => address))) public getPool;

//     constructor() {
//         owner = msg.sender;
//         emit OwnerChanged(address(0), msg.sender);

//     }

//     struct User {
//         address token1;
//         address token2;
//         address poolCreater;
//         uint24 fee;
//     }

//     mapping(address => User) public poolInformation;

//     function getInfo(address _poolCreater) internal view returns (address n) {
//         User storage user = poolInformation[_poolCreater];
//         return user.poolCreater;
//     }





//     function createPool(address tokenA, address tokenB, uint24 fee) external returns(address pool) {
//         require(tokenA != tokenB);
//         (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
//         require(token0 != address(0));
//         require(getPool[token0][token1][fee] == address(0));
//         pool = deploy(address(this), token0,token1, fee);
//         getPool[token0][token1][fee] = pool;
//         getPool[token1][token0][fee] = pool;

//         User storage user = poolInformation[pool];
//         user.token1 = tokenA;
//         user.token2 = tokenB;
//         user.poolCreater = msg.sender;
//         user.fee = fee;

//         emit PoolCreated(token0,token1,fee,pool);
//     }



//     function setOwner(address _owner) external {
//         require(msg.sender == owner);
//         emit OwnerChanged(owner, _owner);
//         owner = _owner;
//     }

//     function withdrawFee() payable public {
//         require(msg.sender == owner);
//         payable(owner).transfer(address(this).balance);
//     }


// }