// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./DataConsumerV3.sol";
import "./old_oracle.sol";
contract OracleConsumer is DataConsumerV3 {
    Rate_Oracle private _LB_Oracle;
    uint256 public _LB_rate;
    uint256 public _chainlink_rate;
    constructor(address LB_Oracle) DataConsumerV3() {
        _LB_Oracle = Rate_Oracle(LB_Oracle);
    }
    event RateUpdate(uint256 Chainlink_rate, uint256 LB_rate, uint256 difference);

    function get_LB_rate() public returns (uint256){
        uint256 rate = uint256(_LB_Oracle._last_updated_rate());
        _LB_rate = rate;
        return rate;
    }
    function get_chainlink_rate() public  returns (uint256){
        uint256 rate = uint256(getLatestData());
        _chainlink_rate = rate;
        return rate;
    }
    function get_rate_difference() public  returns (uint256){
        uint256 difference = _chainlink_rate - _LB_rate;
        return difference;
    }
    function emit_rate_update() public {
        uint256 difference = get_rate_difference();
        emit RateUpdate(_chainlink_rate, _LB_rate, difference);
    }
}

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
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED
 * VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * If you are reading data feeds on L2 networks, you must
 * check the latest answer from the L2 Sequencer Uptime
 * Feed to ensure that the data is accurate in the event
 * of an L2 sequencer outage. See the
 * https://docs.chain.link/data-feeds/l2-sequencer-feeds
 * page for details.
 */

contract DataConsumerV3 {
    AggregatorV3Interface internal dataFeed;

    /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */
    constructor() {
        dataFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
    }

    /**
     * Returns the latest answer.
     */
    function getLatestData() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./Owned.sol";
contract Rate_Oracle is Owned {
    address public _multisig;
    uint256 public _last_updated_rate;
    string public _pair;
    uint8 public _decimals;

    constructor(string memory pair, address multisig, uint8 decimals ) {
        _multisig = multisig;
        _pair = pair;
        _decimals = decimals;
    }
    event RateUpdate(uint256 rate);

    function update_rate(uint256 rate) public Only_Multisig {
        _last_updated_rate = rate;
        emit RateUpdate(rate);
    }
    function update_pair(string memory pair) public onlyOwner{
        _pair = pair;
    }

    function update_multisig(address multisig) public onlyOwner{
        _multisig= multisig;
    }

    modifier Only_Multisig {
        require(msg.sender == _multisig, "Operator only");
        _;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title The Owned contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract Owned {

 address public owner;
 address private pendingOwner;

 event OwnershipTransferRequested(
 address indexed from,
 address indexed to
 );
 event OwnershipTransferred(
 address indexed from,
 address indexed to
 );

 constructor() {
 owner = msg.sender;
 }

 /**
 * @dev Allows an owner to begin transferring ownership to a new address,
 * pending.
 */
 function transferOwnership(address _to)
 external
 onlyOwner()
 {
 pendingOwner = _to;

 emit OwnershipTransferRequested(owner, _to);
 }

 /**
 * @dev Allows an ownership transfer to be completed by the recipient.
 */
 function acceptOwnership()
 external
 {
 require(msg.sender == pendingOwner, "Must be proposed owner");

 address oldOwner = owner;
 owner = msg.sender;
 pendingOwner = address(0);

 emit OwnershipTransferred(oldOwner, msg.sender);
 }

 /**
 * @dev Reverts if called by anyone other than the contract owner.
 */
 modifier onlyOwner() {
 require(msg.sender == owner, "Only callable by owner");
 _;
 }

}