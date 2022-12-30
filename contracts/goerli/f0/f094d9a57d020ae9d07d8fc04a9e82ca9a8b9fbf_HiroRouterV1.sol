// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@uniswap/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract HiroRouterV1 {
    address feeTreasury;

    // Example for 0.25% baseFee:
    //     baseFeeDivisor = 1 / 0.0025
    //     => 400
    uint256 public baseFeeDivisor; // fee = amount / baseFeeDivisor

    string public version;

    constructor(
        address _feeTreasury,
        uint256 _baseFeeDivisor,
        string memory _version
    ) {
        baseFeeDivisor = _baseFeeDivisor;
        feeTreasury = _feeTreasury;
        version = _version;
    }

    event Payment(
        address indexed sender,
        address indexed receiver,
        address token, /* the token that payee receives, use address(0) for AVAX*/
        uint256 amount,
        uint256 fees,
        bytes32 memo
    );

    event Convert(address indexed priceFeed, int256 exchangeRate);

    /*
    Basic payment router when sending tokens directly without DEX. 
    Most gas efficient. 

    Additional support for converting tokens via priceFeeds.

    ## Example: Pay without pricefeeds, e.g. USDC transfer

    payWithToken(
      "tx-123",   // memo
      5*10**18,   // 5$
      [],         // no pricefeeds
      0xUSDC,     // usdc token address
      0xAlice     // receiver token address
    )

    ## Example: Pay with pricefeeds (EUR / USD)

    The user entered the amount in EUR, which gets converted into
    USD by the on-chain pricefeed.

    payWithToken(
        "tx-123",   // memo
        4.5*10**18, // 4.5 EUR (~5$). 
        [0xEURUSD], // 
        0xUSDC,     // usdc token address
        0xAlice     // receiver token address
    )  


    ## Example: Pay with extra fee

    3rd parties can receive an extra fee that is taken directly from
    the receivable amount. 
    
    payWithToken(
        "tx-123",   // memo
        4.5*10**18, // 4.5 EUR (~5$). 
        [0xEURUSD], // 
        0xUSDC,     // usdc token address
        0xAlice,    // receiver token address
        0x3rdParty  // extra fee for 3rd party provider
        200,        // extra fee divisor (x = 1 / 0.005) => 0.5%
    )
    */
    function payWithToken(
        bytes32 _memo,
        uint256 _amount,
        address[] calldata _priceFeeds,
        address _token,
        address _receiver,
        address _extraFeeReceiver,
        uint256 _extraFeeDivisor
    ) external returns (bool) {
        require(_amount != 0, "invalid amount");

        // transform amount with _priceFeeds
        if (_priceFeeds.length > 0) {
            {
                int256 price;
                address priceFeed;
                (_amount, priceFeed, price) = exchangeRate(
                    _priceFeeds,
                    _amount
                );
                emit Convert(priceFeed, price);
            }
        }

        ensureAllowance(_token, _amount);

        uint256 totalFee = 0;

        if (_memo != "") {
            totalFee += transferFee(
                _amount,
                baseFeeDivisor,
                _token,
                msg.sender,
                feeTreasury
            );
        }

        if (_extraFeeReceiver != address(0)) {
            require(_extraFeeDivisor > 2, "extraFee too high");

            totalFee += transferFee(
                _amount,
                _extraFeeDivisor,
                _token,
                msg.sender,
                _extraFeeReceiver
            );
        }

        // Transfer to receiver
        TransferHelper.safeTransferFrom(
            _token,
            msg.sender,
            _receiver,
            _amount - totalFee
        );

        emit Payment(msg.sender, _receiver, _token, _amount, totalFee, _memo);

        return true;
    }

    /*
    Make life easier for frontends.
    */
    function ensureAllowance(address _token, uint256 _amount) private view {
        require(
            IERC20(_token).allowance(msg.sender, address(this)) >= _amount,
            "insufficient allowance"
        );
    }

    function transferFee(
        uint256 _amount,
        uint256 _feeDivisor,
        address _token,
        address _from,
        address _to
    ) private returns (uint256) {
        uint256 fee = _amount / _feeDivisor;
        // Transfer hiro-fee to treasury
        if (fee > 0) {
            TransferHelper.safeTransferFrom(_token, _from, _to, fee);
            return fee;
        } else {
            return 0;
        }
    }

    function exchangeRate(address[] calldata _priceFeeds, uint256 _amount)
        public
        view
        returns (
            uint256 converted,
            address priceFeed,
            int256 price
        )
    {
        require(_priceFeeds.length < 2, "invalid pricefeeds");

        // TODO: base / quote pricefeed to calc EUR/ETH via EUR/USD ETH/USD
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeeds[0]);

        uint256 decimals = uint256(10**uint256(priceFeed.decimals()));
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 converted = (_amount * uint256(price)) / decimals;

        return (converted, _priceFeeds[0], price);
    }
}