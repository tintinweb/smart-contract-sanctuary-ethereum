// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.7;

interface IAsset {

}
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}
interface IVault{
    enum SwapKind { GIVEN_IN, GIVEN_OUT }
    struct SingleSwap {
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
            TransferHelper.safeTransferFrom(_singleswap[i]._single.assetIn, msg.sender, address(this), _singleswap[i]._single.amount);
            TransferHelper.safeApprove(_singleswap[i]._single.assetIn, VAULT, _singleswap[i]._single.amount);
            uint256 amountCalculated = IVault(VAULT).swap(_singleswap[i]._single, _singleswap[i]._fund, _singleswap[i]._limit, _singleswap[i]._deadline);
            //approval 
            // IVault.SingleSwap memory sin;
            // IVault.FundManagement memory fun;
            // (bool success , bytes memeory data) = VAULT.delegatecall((abi.encodeWithSignature("swap(sin,fun,uint256,uint256)"),_singleswap[i]._single, _singleswap[i]._fund, _singleswap[i]._limit, _singleswap[i]._deadline));
            // IAAVE(AAVE).deposit(_singleswap[i]._single.assetOut,amountCalculated,_singleswap[i]._fund.recipient,0);
            address  _token = _singleswap[i]._single.assetOut;
            address  _user = _singleswap[i]._fund.recipient;
            uint16 _zero = 0;
            (bool sucess, ) = AAVE.delegatecall(abi.encodeWithSignature("deposit(address, uint256 , address , uint16)", abi.encode(_token, amountCalculated, _user, _zero)));
            require(sucess,"Failed");
        }
    }
    function withdraw(Withdraw[] memory _with) public {
        for (uint i =0 ; i < _with.length ; i++){
            //atokens
            IAAVE(AAVE).withdraw(_with[i]._token, _with[i]._amount,_with[i]._to);
        }     
    }
}