/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

/**
 *Submitted for verification at BscScan.com on 2022-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
}

library StringHelper {
    function concat(
        bytes memory a,
        bytes memory b
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(a, b);
    }
    
    function toStringBytes(uint256 v) internal pure returns (bytes memory) {
        if (v == 0) { return "0"; }

        uint256 j = v;
        uint256 len;

        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        
        while (v != 0) {
            bstr[k--] = byte(uint8(48 + v % 10));
            v /= 10;
        }
        
        return bstr;
    }
    
    
    function getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        if (_returnData.length < 68) return 'Transaction reverted silently';
    
        assembly {
            _returnData := add(_returnData, 0x04)
        }

        return abi.decode(_returnData, (string));
    }
}

contract TokenSwapWith0x {
    using StringHelper for bytes;
    using StringHelper for uint256;
    IWETH public immutable WETH;
    constructor(IWETH _weth) {
        WETH = _weth;
    }
    function swap(
         // The `sellTokenAddress` field from the API response.
        IERC20 sellToken,
        // The `buyTokenAddress` field from the API response.
        IERC20 buyToken,
        uint256 paymentAmountInBuyToken,
        uint256 amountInSellToken,
        // The `allowanceTarget` field from the API response.
        address spender,
        address payable swapTarget,
        bytes calldata swapCallData
    ) public payable {
      // if (msg.value > 0) {
          _processBuyToken(sellToken,buyToken,paymentAmountInBuyToken,amountInSellToken, spender, swapTarget, swapCallData);
      // } else {
      //     require(spender == address(0), "EMPTY_SPENDER_WITHOUT_SWAP");
      //     require(swapTarget == address(0), "EMPTY_TARGET_WITHOUT_SWAP");
      //     require(swapCallData.length == 0, "EMPTY_CALLDATA_WITHOUT_SWAP");
      //   //   require(buyToken.transferFrom(msg.sender, address(this), paymentAmountInBuyToken));
      // }
    }

    function _processBuyToken(
        IERC20 sellToken,
        IERC20 buyToken,
        uint256 paymentAmountInBuyToken,
        uint256 amountInSellToken,
        address spender, // The `allowanceTarget` field from the API response.
        address payable swapTarget, // The `to` field from the API response.
        bytes calldata swapCallData // The `data` field from the API response.
    ) private {
      if(sellToken == WETH) {
        WETH.deposit{value: msg.value}();
        require(WETH.approve(spender, type(uint256).max), "approve failed");
      } else {
        sellToken.approve(address(this),type(uint256).max);
        sellToken.transferFrom(msg.sender, address(this), amountInSellToken);
      }

      uint256 currentBuyTokenBalance = buyToken.balanceOf(address(this));
      (bool success, bytes memory res) = swapTarget.call(swapCallData);
      require(success, string(bytes('SWAP_CALL_FAILED: ').concat(bytes(res.getRevertMsg()))));
      msg.sender.transfer(address(this).balance);
      uint256 boughtAmount = buyToken.balanceOf(address(this)) - currentBuyTokenBalance;
      require(boughtAmount >= paymentAmountInBuyToken, "INVALID_BUY_AMOUNT");
      buyToken.approve(address(this), type(uint256).max);
      buyToken.transfer(msg.sender, paymentAmountInBuyToken);

    }
    // required for refunds
    receive() external payable {}
  
}