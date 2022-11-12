// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";

contract Lottery {
    address payable public contract_owner;
    uint256[] private num_list;

    using Counters for Counters.Counter;
    Counters.Counter private totalSupply;
    Counters.Counter public draw_id;

    struct sub_data {
        uint256[] balls;
        address payable me;
        uint256 _drawId;
    }

    event MintBalls(sub_data);
    event Winner(sub_data);
    event ReceiveGift(bool received);

    mapping(address => mapping(uint256 => sub_data)) public subscribers;

    constructor() {
        contract_owner = payable(msg.sender);
        for (uint256 i = 1; i < 65; i++) {
            num_list.push(i);
        }
    }

    function mine_balls(uint256[] memory _balls) external payable {
        require(
            msg.value >= 0.0001 ether,
            "please send the right amount of ethers"
        );
        subscribers[address(this)][totalSupply.current()] = sub_data(
            _balls,
            payable(msg.sender),
            draw_id.current()
        );
        totalSupply.increment();
        (bool sent, bytes memory data) = payable(address(this)).call{
            value: msg.value
        }("");

        require(!sent, "Failed to send Ether");
        emit MintBalls(subscribers[address(this)][totalSupply.current() - 1]);
    }

    function get_subscribers_for_all_draws()
        external
        view
        returns (sub_data[] memory)
    {
        sub_data[] memory newData = new sub_data[](totalSupply.current());
        for (uint256 i = 0; i < totalSupply.current(); i++) {
            sub_data storage _data = subscribers[address(this)][i];
            newData[i] = _data;
        }
        return newData;
    }

    function get_subscribers_for_draw_id(uint256 _drawId)
        external
        view
        returns (sub_data[] memory)
    {
        uint256 count;
        for (uint256 j = 0; j < totalSupply.current(); j++) {
            sub_data storage _data = subscribers[address(this)][j];
            if (_data._drawId == _drawId) {
                count++;
            }
        }
        sub_data[] memory newData = new sub_data[](count);
        for (uint256 i = 0; i < totalSupply.current(); i++) {
            sub_data storage data = subscribers[address(this)][i];
            if (data._drawId == _drawId) {
                newData[i] = data;
            }
        }
        return newData;
    }

    function generate_winning_balls() external view returns (uint256[] memory) {
        uint256[] memory list = num_list;
        uint256 randomHash = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        );
        uint256[] memory stats = new uint256[](6);
        for (uint256 i; i < 6; i++) {
            uint256 index = randomHash % list.length;
            stats[i] = list[index];
            list[index] = list[list.length - 1];
            delete list[list.length - 1];
            randomHash >>= 8;
        }

        return stats;
    }

    // function set_winner(uint256[] memory _balls, uint256 _drawId)
    //     external
    //     view
    //     returns (address)
    // {
    //     uint256 count;
    //     require(_drawId == draw_id.current(), "invalid draw id");

    //     for (uint256 i = 0; i < totalSupply.current(); i++) {
    //         sub_data memory _data = subscribers[address(this)][i];
    //         if (_data._drawId == _drawId) {
    //             uint256[] memory nums_at_index = _data.balls;
    //             for (uint256 j = 0; j < nums_at_index.length; j++) {
    //                 uint256 num_at_index = nums_at_index[j];
    //                 for (uint256 k = 0; k < 6; k++) {
    //                     if (num_at_index == _balls[k]) {
    //                         count++;
    //                     }
    //                 }
    //             }
    //             if (count == 6) {
    //                 delete count;
    //                 return subscribers[address(this)][i].me;
    //             }
    //             if (count < 6) {
    //                 delete count;
    //             }
    //         }
    //     }

    //     delete count;
    //     revert("no winner address for this draw");
    // }
    
    
    function set_winner(uint256[] memory _balls, uint256 _drawId)
        external
        returns (address)
    {
        uint256 count;
        require(_drawId == draw_id.current(), "invalid draw id");

        for (uint256 i = 0; i < totalSupply.current(); i++) {
            sub_data memory _data = subscribers[address(this)][i];
            if (_data._drawId == _drawId) {
                uint256[] memory nums_at_index = _data.balls;
                for (uint256 j = 0; j < nums_at_index.length; j++) {
                    uint256 num_at_index = nums_at_index[j];
                    for (uint256 k = 0; k < 6; k++) {
                        if (num_at_index == _balls[k]) {
                            count++;
                        }
                    }
                }
                if (count == 6) {
                    delete count;
                    draw_id.increment();
                    return subscribers[address(this)][i].me;
                }
                if (count < 6) {
                    delete count;
                }
            }
        }
        draw_id.increment();
        delete count;
          return 0x0000000000000000000000000000000000000000;
    }

    function receive_gift(address _winner) external {
        payable(_winner).transfer(address(this).balance);
        emit ReceiveGift(true);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}