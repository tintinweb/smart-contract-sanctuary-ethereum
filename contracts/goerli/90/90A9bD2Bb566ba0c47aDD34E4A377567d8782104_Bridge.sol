//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./IERC20.sol";

contract Bridge {
    using Counters for Counters.Counter;

    IERC20 public token;
    Counters.Counter private nonce;

    mapping(uint256 => bool) private nonceUsed;

    constructor(IERC20 _token) {
        token = _token;
    }

    modifier EnoughFunds(uint256 amount) {
        require(token.balanceOf(msg.sender) >= amount, "not enough funds");
        _;
    }

    event SwapInitialized(address sender, address receiver, uint256 amount, uint256 nonce);

    function swap(address receiver, uint256 amount) external EnoughFunds(amount) {
        token.burn(msg.sender, amount);
        emit SwapInitialized(msg.sender, receiver, amount, nonce.current());
        nonce.increment();
    }

    function redeem(address receiver, uint256 amount, uint256 _nonce, uint8 v, bytes32 r, bytes32 s) external{
        require(nonceUsed[_nonce] == false, "nonce already used");

        bytes32 message = keccak256(
            abi.encodePacked(receiver, amount, _nonce)
        );
        address addr = ecrecover(hashMessage(message), v, r, s);
        require(receiver == addr, "wrong signature");
        nonceUsed[_nonce] = true;
        token.mint(receiver, amount);
    }

    function hashMessage(bytes32 message) private pure returns(bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, message));
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function giveAdminRole(address newAdmin) external;
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function totalSupply() external view returns(uint256);
    function balanceOf(address ownerTokens) external view returns(uint256);
    function allowance(address ownerTokens, address spender) external view returns(uint256);

    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
    function approve(address spender, uint256 value) external returns(bool);

    function burn(address account, uint256 amount) external;
    function mint(address account, uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint value);
}