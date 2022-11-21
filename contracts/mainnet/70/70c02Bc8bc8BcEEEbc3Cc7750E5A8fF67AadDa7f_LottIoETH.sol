// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LottIoETH {

    AggregatorInterface immutable AGGREGATOR_LINK_USD;
    AggregatorInterface immutable AGGREGATOR_ETH_USD;
    
    address[] _tokensIn;
    address public lottToken;
    address public hardAddr;

    uint256 public LottsPerUSD;

    constructor (
        address _hardAddr
    ) {
        AGGREGATOR_LINK_USD  = AggregatorInterface(0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c);
        AGGREGATOR_ETH_USD  = AggregatorInterface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        _tokensIn = [
                    0x6B175474E89094C44Da98b954EedeAC495271d0F, // DAI
                    0x514910771AF9Ca656af840dff83E8264EcF986CA, // LINK
                    0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2  // wETH
        ];
        lottToken = 0xc86CAA33EcaFDD65951F9F809CBaf3D67eeB64bd; // Lott
        LottsPerUSD = 3000; //equals 30 Lott
        hardAddr = _hardAddr;
    }

    function tokensIn() public view returns(address[] memory temp) {
        temp = new address[](_tokensIn.length);
        for(uint8 i; i < _tokensIn.length; i++) {
            temp[i] = _tokensIn[i];
        }
    }

    function checkReferral(bytes calldata referral) public pure returns(
        address refAddr,
        uint16 fraction
    ) {
        fraction = uint16(bytes2(referral[10:12]));
        require(fraction <= 1500, "LottIoETH: up to 15 percent for referral");

        refAddr = address(bytes20(referral[12:]));
        require(
            bytes10(referral[:10]) == bytes10(keccak256(abi.encodePacked(
                refAddr, fraction, "3mgPsilocibinEveryday!"
            ))), "LottIoETH: wrong referral"
        );
    } 

    function amountLott(address tokenIn, uint256 amountIn) public view returns(uint256 _amountLott) {
        if(tokenIn == _tokensIn[0]) {
            return amountIn * LottsPerUSD / 100;
        } else if(tokenIn == _tokensIn[1]) {
            return amountIn * LottsPerUSD * uint256(AGGREGATOR_LINK_USD.latestAnswer()) / 10 ** 10;
        } else if(tokenIn == _tokensIn[2]) {
            return amountIn * LottsPerUSD * uint256(AGGREGATOR_ETH_USD.latestAnswer()) / 10 ** 10;
        } else {
            revert("LottIoETH: token not supported");
        }
    }

    function swap(
        address tokenIn,
        uint256 amountIn,
        bytes calldata referral
    ) public {
        address buyer = msg.sender;
        uint256 _amountLott = amountLott(tokenIn, amountIn);
        IERC20 lott = IERC20(lottToken);
        require(
            lott.balanceOf(address(this)) >= _amountLott,
            "LottIoETH: insufficient Lott balance in the contract."
        );

        (address refAddr, uint16 fraction) = checkReferral(referral);

        IERC20 _tokenIn = IERC20(tokenIn);
        _tokenIn.transferFrom(buyer, hardAddr, amountIn * (10000-fraction)/10000); 
        _tokenIn.transferFrom(buyer, refAddr, amountIn * fraction/10000); 

        lott.transfer(buyer, _amountLott); 
    }

    function setLottsPerUSD(uint256 _LottsPerUSD) public {
        require(msg.sender == hardAddr, "LottIoETH: only hardAddr");
        LottsPerUSD = _LottsPerUSD;
    }

    function withdrawLott(uint256 amount) public {
        require(msg.sender == hardAddr, "LottIoETH: only hardAddr");
        IERC20(lottToken).transfer(hardAddr, amount); 
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}