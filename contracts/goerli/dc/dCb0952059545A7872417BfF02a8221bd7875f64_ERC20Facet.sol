//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AppStorage} from "../libraries/LibAppStorage.sol";
import {LibERC20} from "../libraries/LibERC20.sol";

contract ERC20Facet {
    AppStorage s;

    function name() external pure returns (string memory) {
        return unicode"Diamond Emoji Token";
    }

    function symbol() external pure returns (string memory) {
        return unicode"💎";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view returns (uint256) {
        return s.totalSupply;
    }

    function balanceOf(address _owner)
        external
        view
        returns (uint256 balance_)
    {
        balance_ = s.balances[_owner];
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        LibERC20.approve(s, msg.sender, _spender, _value);
        return true;
    }

    function increaseAllowance(address _spender, uint256 _addedValue)
        external
        returns (bool)
    {
        unchecked {
            LibERC20.approve(
                s,
                msg.sender,
                _spender,
                s.allowances[msg.sender][_spender] + _addedValue
            );
        }
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue)
        external
        returns (bool)
    {
        uint256 currentAllowance = s.allowances[msg.sender][_spender];
        require(
            currentAllowance >= _subtractedValue,
            "Cannot decrease allowance to less than 0"
        );
        unchecked {
            LibERC20.approve(
                s,
                msg.sender,
                _spender,
                currentAllowance - _subtractedValue
            );
        }
        return true;
    }

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining_)
    {
        return s.allowances[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        LibERC20.transfer(s, msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success) {
        LibERC20.transfer(s, _from, _to, _value);
        uint256 currentAllowance = s.allowances[_from][msg.sender];
        require(
            currentAllowance >= _value,
            "transfer amount exceeds allowance"
        );
        unchecked {
            LibERC20.approve(s, _from, msg.sender, currentAllowance - _value);
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";
import {IERC20} from "../interfaces/IERC20.sol";

library LibERC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    function transfer(
        AppStorage storage s,
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(_from != address(0), "_from cannot be zero address");
        require(_to != address(0), "_to cannot be zero address");
        uint256 balance = s.balances[_from];
        require(balance >= _value, "_value greater than balance");
        unchecked {
            s.balances[_from] -= _value;
            s.balances[_to] += _value;
        }
        emit Transfer(_from, _to, _value);
    }

    function approve(
        AppStorage storage s,
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");
        s.allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

struct AppStorage {
    uint256 totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
    mapping(address => Counters.Counter) nonces;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);
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