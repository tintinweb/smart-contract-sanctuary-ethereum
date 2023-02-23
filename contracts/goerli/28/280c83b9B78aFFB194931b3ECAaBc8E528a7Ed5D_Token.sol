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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error Raffle__SendMoreToBeScam();

contract Token {
    event receiveLink(address indexed player);

    // Variables
    uint256 private constant PRICE_LINK_FEE = 5e15; // = 0.005

    uint256 private s_balanceInLink = 0;
    uint256 private s_balanceInUsd = 0;
    AggregatorV3Interface private s_linkPriceFeedAddress;

    // Adresse du contrat LINK
    address public linkTokenAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;

    constructor(address linkPriceFeedAddress) {
        s_linkPriceFeedAddress = AggregatorV3Interface(linkPriceFeedAddress);
    }

    function receiveLinkTokens() public {
        // Vérifier que le contrat LINK est approuvé pour transférer des tokens
        require(
            IERC20(linkTokenAddress).allowance(msg.sender, address(this)) >= PRICE_LINK_FEE,
            "Tokens must be approved before calling this function"
        );

        // Transférer les tokens LINK du portefeuille de l'appelant au contrat de la fonction
        require(
            IERC20(linkTokenAddress).transferFrom(msg.sender, address(this), PRICE_LINK_FEE),
            "Token transfer failed"
        );

        // Convertir le prix LINK/USD en utilisant l'oracle de prix
        uint256 price = getPrice(AggregatorV3Interface(s_linkPriceFeedAddress));

        s_balanceInLink = s_balanceInLink + PRICE_LINK_FEE;
        s_balanceInUsd = s_balanceInUsd + (price * PRICE_LINK_FEE);

        emit receiveLink(msg.sender);
    }

    // Fonction utilitaire pour convertir le prix LINK/USD
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        // Convertir le prix en 18 décimales pour que ce soit lisible par ether
        return uint256(answer) * 10 ** 10;
    }

    function getBalanceInLink() public view returns (uint256) {
        return s_balanceInLink;
    }

    function getBalanceInUsd() public view returns (uint256) {
        return s_balanceInUsd;
    }
}