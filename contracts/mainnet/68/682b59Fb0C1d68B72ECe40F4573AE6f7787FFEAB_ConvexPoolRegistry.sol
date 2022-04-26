// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


interface ConvexCurvePools{
    function poolInfo(uint256 _pid) external returns(address _lptoken, address _token, address _gauge, address _crvRewards, address _stash, bool _shutdown);
}

interface ConvexWrapper{
    function convexPoolId() external returns(uint256 _poolId);
}

/*
Module that maps a convex staking token to convex pool information such as lp token, convex deposit token, pool id, etc
*/
contract ConvexPoolRegistry{

    struct PoolInfo {
        uint256 poolId;
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
    }

    address public constant owner = address(0x59CFCD384746ec3035299D90782Be065e466800B);
    address public constant convexCurveBooster = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

    mapping(address => PoolInfo) public poolMapping; //map wrapped token to convex pool

    constructor() {}

    /////// Owner Section /////////

    modifier onlyOwner() {
        require(owner == msg.sender, "!auth");
        _;
    }

    //set platform fees
    function addPoolInfo(address _wrapperToken, uint256 _convexPid) external onlyOwner{
        require(ConvexWrapper(_wrapperToken).convexPoolId() == _convexPid, "!pid");

        (address _lptoken, address _token, address _gauge, address _crvRewards, , ) = ConvexCurvePools(convexCurveBooster).poolInfo(_convexPid);
    
        //set pool mapping
        poolMapping[_wrapperToken] = PoolInfo({
            poolId: _convexPid,
            lptoken: _lptoken,
            token: _token,
            gauge: _gauge,
            crvRewards: _crvRewards
        });
    }
}