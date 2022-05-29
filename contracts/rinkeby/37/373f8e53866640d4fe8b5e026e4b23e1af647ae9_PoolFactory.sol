/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;




contract IPool {}
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
        pool = address(new IPool{salt: keccak256(abi.encode(token0, token1, fee))}());
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