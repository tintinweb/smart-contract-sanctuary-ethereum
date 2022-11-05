// SPDX-License-Identifier: MIT
// Tells the Solidity compiler to compile only from v0.8.13 to v0.9.0
pragma solidity ^0.8.13;
import "./Price.sol";

interface Starknet {
    function sendMessageToL2(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);
}

contract MintFromL1 {
    address starknetContract;
    address pricingContract;
    address payable public owner;

    uint256 toAddress;
    uint256 selector;

    constructor(address _starknetContract, address _owner) {
        // on goerli: 0xde29d060D45901Fb19ED6C6e959EB22d8626708e
        starknetContract = _starknetContract;
        owner = payable(_owner); 
    }
 
    function withdraw() public {
        // get the amount of Ether stored in this contract
        uint256 amount = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function setL2Data(uint256 _toAddress, uint256 _selector) public {
        require(
            msg.sender == owner,
            "You don't have the right to call this function"
        );
        toAddress = _toAddress;
        selector = _selector;
    }

    // https://github.com/starkware-libs/cairo-lang/blob/4e233516f52477ad158bc81a86ec2760471c1b65/src/starkware/starknet/eth/StarknetMessaging.sol#L100
    function purchase(
        uint256 domain,
        uint256 token_id,
        uint256 duration_days,
        uint256 resolver,
        uint256 addr
    ) public payable {
        require(
            msg.value >= Price.compute_buy_price(domain, duration_days),
            "You didn't pay enough"
        );

        uint256[] memory payload = new uint256[](5);
        payload[0] = token_id;
        payload[1] = domain;
        payload[2] = duration_days;
        payload[3] = resolver;
        payload[4] = addr;
        Starknet(starknetContract).sendMessageToL2(
            toAddress,
            selector,
            payload
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// A library is like a contract with reusable code, which can be called by other contracts.
// Deploying common code can reduce gas costs.
library Price {
    uint256 constant simple_alphabet_size = 38;
    uint256 constant complex_alphabet_size = 2;

    function compute_buy_price(uint256 domain, uint256 duration_days)
        public
        pure
        returns (uint256 price)
    {
        // // Calculate price depending on number of characters
        uint256 number_of_character = get_amount_of_chars(domain);
        uint256 price_per_day_eth = get_price_per_day(number_of_character);
        uint256 days_to_pay = get_days_to_pay(duration_days);

        return days_to_pay * price_per_day_eth;
    }

    function get_amount_of_chars(uint256 domain)
        private
        pure
        returns (uint256 number_of_character)
    {
        if (domain == 0) {
            return 0;
        }

        uint256 remainder = domain % simple_alphabet_size;
        uint256 divided = domain / simple_alphabet_size;
        if (remainder == 37) {
            uint256 next = get_amount_of_chars(divided / complex_alphabet_size);
            return 1 + next;
        } else {
            uint256 next = get_amount_of_chars(divided);
            return 1 + next;
        }
    }

    function get_days_to_pay(uint256 duration_days)
        private
        pure
        returns (uint256 days_to_pay)
    {
        if (1824 < duration_days) {
            return (duration_days - 730);
        }

        if (1094 < duration_days) {
            return (duration_days - 365);
        }

        return duration_days;
    }

    function get_price_per_day(uint256 number_of_character)
        private
        pure
        returns (uint256 price)
    {
        if (number_of_character == 1) {
            return (1068493150684932);
        }

        if (number_of_character == 2) {
            return (1024657534246575);
        }

        if (number_of_character == 3) {
            return (931506849315068);
        }

        if (number_of_character == 4) {
            return (232876712328767);
        }

        return (24657534246575);
    }
}