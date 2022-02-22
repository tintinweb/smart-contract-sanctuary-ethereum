// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";

//@title SKY Token contract interface
interface token {
    function balanceOf(address owner) external returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);
}

//@title SKY Initial Distribution Contract
contract distribution {
    uint256 public SKYPrice;

    address public token_addr;
    token public token_contract = token(token_addr);

    AggregatorInterface internal priceFeed;
    address public oracle_address = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    event sold(address seller, uint256 amount);
    event bought(address buyer, uint256 amount);
    event priceAdjusted(uint256 oldPrice, uint256 newPrice);

    address payable public owner;
    uint16 public USDperSKY = 80; //cents

    constructor() {
        owner = payable(msg.sender);

        priceFeed = AggregatorInterface(oracle_address);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender not owner!");
        _;
    }

    /**
     * @dev Multiply two integers with extra checking the result
     * @param   a Integer 1
     *          b Integer 2
     */
    function safeMultiply(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (a == 0) {
            return 0;
        } else {
            uint256 c = a * b;
            assert(c / a == b);
            return c;
        }
    }

    /**
     * @dev Divide two integers with checking b is positive
     * @param   a Integer 1
     *          b Integer 2
     */
    function safeDivide(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    /**
     * @dev Set SKY Token contract address
     * @param addr Address of SKY Token contract
     */
    function set_token_address(address addr) public onlyOwner {
        token_addr = addr;
        token_contract = token(token_addr);
    }

    /**
     * @dev Set oracle address, make sure chainlink format supported!
     * @param addr Address of oracle contract
     */
    function set_oracle(address addr) public onlyOwner {
        oracle_address = addr;
    }

    /**
     * @dev Buy SKY tokens directly from the contract
     */
    function buy_SKY() public payable returns (bool success) {
        require(msg.value > 0);

        uint256 latest_ETHUSD_USD = getLatestPrice();

        uint256 message_USD_value = safeMultiply(msg.value, latest_ETHUSD_USD);
        uint256 scaledAmount = safeDivide(message_USD_value, USDperSKY) / 1e6;
        require(
            token_contract.balanceOf(address(this)) >= scaledAmount,
            "contract balance not enough"
        );

        token_contract.transfer(msg.sender, scaledAmount);

        emit bought(msg.sender, scaledAmount);

        return true;
    }

    /**
     * @dev Fallback function for when a user sends ether to the contract
     * directly instead of calling the function
     */
    receive() external payable {
        buy_SKY();
    }

    /**
     * @dev Adjust the SKY token price
     * @param   SKYperETH the amount of SKY a user receives for 1 ETH
     */
    function adjustPrice(uint256 SKYperETH) public onlyOwner {
        emit priceAdjusted(SKYPrice, SKYperETH);

        SKYPrice = SKYperETH;
    }

    /**
     * @dev End the SKY token distribution by sending all leftover tokens and ether to the contract owner
     */
    function endSKYDistr() public onlyOwner {
        require(
            token_contract.transfer(
                owner,
                token_contract.balanceOf(address(this))
            )
        );

        owner.transfer(address(this).balance);
    }

    /**
     * @dev Gets latest price from priceFeed chainlink oracle in 10^8 units.
     */
    function getLatestPrice() public view returns (uint256) {
        uint256 price = uint256(priceFeed.latestAnswer());
        // for ETH / USD price is scaled up by 10 ** 8
        return price;
    }
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