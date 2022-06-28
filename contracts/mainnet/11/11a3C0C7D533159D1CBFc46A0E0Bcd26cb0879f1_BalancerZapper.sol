// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

//a simple contract to get round balancer's crazy inputs

struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }
interface IBalancerVault{
    function joinPool(
    bytes32 poolId, 
    address sender, 
    address recipient, 
    JoinPoolRequest memory request
) external;

function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

}
interface IERC20{
    function transfer(address, uint256) external;
    function approve(address, uint256) external;
    function transferFrom(address, address, uint256) external;
    function balanceOf(address) external view returns (uint256);
}

contract BalancerZapper  {
    address immutable internal owner;

    IBalancerVault balancerVault = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    
    constructor() public{
        owner = msg.sender;
    }
    
    function joinPool(address _inToken, uint256 _amount, bytes32 _poolId, address _recepient, uint256[] calldata _amountsIn, uint256 _minOut) external{
        IERC20(_inToken).transferFrom(msg.sender, address(this), _amount);
        IERC20(_inToken).approve(address(balancerVault), _amount);

        uint256 JoinKind = 1; //EXACT_TOKENS_IN_FOR_BPT_OUT
        
        bytes memory userDataEncoded = abi.encode(JoinKind, _amountsIn, _minOut);
        (address[] memory poolTokens, , ) = balancerVault.getPoolTokens(_poolId);
        JoinPoolRequest memory jpr = JoinPoolRequest(poolTokens, _amountsIn, userDataEncoded, false);

        //must approve this contract as relayer
        balancerVault.joinPool(_poolId, address(this), _recepient, jpr);
    }

    function sweep(address token) external{
        require(msg.sender == owner);
        IERC20(token).transfer(owner, IERC20(token).balanceOf(address(this)));
    }
}