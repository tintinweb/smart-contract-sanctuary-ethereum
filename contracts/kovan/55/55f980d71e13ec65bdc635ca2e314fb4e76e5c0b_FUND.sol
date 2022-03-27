/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.7;
interface Vault {
    
}
interface IAsset {

}

interface IVault{
    enum SwapKind { GIVEN_IN, GIVEN_OUT }
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }
       function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

}

interface IAAVE {
    function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;
    
    function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

}

contract FUND {

   address public constant VAULT = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
   address public constant AAVE =  address(0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe);
    
    enum SwapKind { GIVEN_IN, GIVEN_OUT }
    /*struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }*/
    
    struct _singleSwap {
        IVault.SingleSwap _single;
        IVault.FundManagement _fund;
        uint256 _limit;
        uint256 _deadline;
    }

    struct Withdraw{
        address _token;
        uint256 _amount;
        address _to;
    }

    function deposit(_singleSwap[] memory _singleswap) public  {
        for (uint i=0; i < _singleswap.length ; i++ ){
            uint256 amountCalculated = IVault(VAULT).swap(_singleswap[i]._single, _singleswap[i]._fund, _singleswap[i]._limit, _singleswap[i]._deadline);
            IAAVE(AAVE).deposit(address(_singleswap[i]._single.assetOut),amountCalculated,_singleswap[i]._fund.sender,0);
        }
    }
    function _withdraw(Withdraw[] memory _with) public {
        for (uint i =0 ; i < _with.length ; i++){
            IAAVE(AAVE).withdraw(_with[i]._token, _with[i]._amount,_with[i]._to);
        }     
    }
}