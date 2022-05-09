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

    address public constant owner = address(0xa3C5A1e09150B75ff251c1a7815A07182c3de2FB);
    address public constant convexCurveBooster = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

    mapping(address => PoolInfo) public poolMapping; //map wrapped token to convex pool

    constructor() {}

    /////// Owner Section /////////

    modifier onlyOwner() {
        require(owner == msg.sender, "!auth");
        _;
    }

    //set platform fees
    function addPoolInfo(address _wrapperToken) external onlyOwner{

        uint256 convexPid = ConvexWrapper(_wrapperToken).convexPoolId();
        require(convexPid > 0, "!pid");

        (address _lptoken, address _token, address _gauge, address _crvRewards, , ) = ConvexCurvePools(convexCurveBooster).poolInfo(convexPid);
    
        //set pool mapping
        poolMapping[_wrapperToken] = PoolInfo({
            poolId: convexPid,
            lptoken: _lptoken,
            token: _token,
            gauge: _gauge,
            crvRewards: _crvRewards
        });
    }
}