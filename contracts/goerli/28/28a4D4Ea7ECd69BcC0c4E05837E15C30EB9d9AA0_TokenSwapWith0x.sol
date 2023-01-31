/**
 *Submitted for verification at Etherscan.io on 2023-01-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

pragma solidity 0.8.15;
interface ISwapRewardUpgradeable {
    function tradeReward( 
        address account,
        address input,
        address output,
        uint256 volumeInUSDT) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external payable;
}

library StringHelper {
    function concat(
        bytes memory a,
        bytes memory b
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(a, b);
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
    address public owneraddress ;
    address public treasuryAddress;
    address public rewardAddress;
    address public ADDRESS_ETH_ZERO = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    modifier onlyowner {
        require(owneraddress == msg.sender,"Not dev address");
        _;
    }
    constructor(IWETH _weth) {
        WETH = _weth;
        owneraddress = msg.sender;
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
        bytes calldata swapCallData,
        uint volumeInUSDT
    ) public payable {
        _processBuyToken(sellToken,buyToken,paymentAmountInBuyToken,amountInSellToken, spender, swapTarget, swapCallData);
        //  ISwapRewardUpgradeable(rewardAddress).tradeReward(msg.sender,address(sellToken),address(buyToken),volumeInUSDT);
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
        require(sellToken.approve(address(this),type(uint256).max));
        require(sellToken.approve(swapTarget,type(uint256).max),"Approve sellToken to swapTarget failed");
        require(sellToken.transferFrom(msg.sender, address(this), amountInSellToken),"Transfer failed");
      }
      if(address(buyToken) == ADDRESS_ETH_ZERO ){
        uint256 currentBuyTokenBalance = address(this).balance;
        (bool success, bytes memory res) = swapTarget.call(swapCallData);
        require(success, string(bytes('SWAP_CALL_FAILED: ').concat(bytes(res.getRevertMsg()))));
        // msg.sender.transfer(address(this).balance);
        uint256 boughtAmount = address(this).balance - currentBuyTokenBalance;
        require(boughtAmount >= paymentAmountInBuyToken, "INVALID_BUY_AMOUNT");
        payable(msg.sender).transfer(boughtAmount);
      } else {
        uint256 currentBuyTokenBalance = buyToken.balanceOf(address(this));
        (bool success, bytes memory res) = swapTarget.call(swapCallData);
        require(success, string(bytes('SWAP_CALL_FAILED: ').concat(bytes(res.getRevertMsg()))));
        // msg.sender.transfer(address(this).balance);
        uint256 boughtAmount = buyToken.balanceOf(address(this)) - currentBuyTokenBalance;
        require(boughtAmount >= paymentAmountInBuyToken, "INVALID_BUY_AMOUNT");
        buyToken.approve(address(this), type(uint256).max);
        buyToken.transfer(msg.sender, boughtAmount);
      }
    
    }
    function setTreasuryAddress(address trAddress) external  onlyowner{
        treasuryAddress = trAddress;
    }
    function transferOwner(address newOwner) external  onlyowner{
        owneraddress = newOwner;
    }
    function setRewardAddress(address reward) external  onlyowner{
        rewardAddress = reward;
    }
    
    // required for refunds
    receive() external payable {}
  
}