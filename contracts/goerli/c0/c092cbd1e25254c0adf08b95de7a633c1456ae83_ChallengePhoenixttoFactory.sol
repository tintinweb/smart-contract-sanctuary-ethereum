// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ChallengeFactory {
    // @notice create challenges contract
    function deploy(address player) external payable virtual returns (address[] memory);
    function deployValue() external view virtual returns (uint256);

    // @notice return name of the contract challenges
    function contractNames() external view virtual returns (string[] memory);

    /// @notice Will true if player has complete the challenge
    function isComplete(address[] calldata) external view virtual returns (bool);

    // @notice return name for rendering the nft
    function name() external view virtual returns (string memory);

    // @notice return name for rendering the nft
    function description() external view virtual returns (string memory);

    // @notice return image for rendering the nft
    function image() external view virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ChallengeFactory} from "../ChallengeFactory.sol";
import {Laboratory} from "./ChallengePhoenixtto.sol";

contract ChallengePhoenixttoFactory is ChallengeFactory {
    string[] _contractnames = ["Laboratory"];

    function deploy(address _player) external payable override returns (address[] memory ret) {
        require(msg.value == 0, "dont send ether");
        address _challenge = address(new Laboratory(_player));
        Laboratory(_challenge).mergePhoenixDitto();
        ret = new address[](1);
        ret[0] = _challenge;
    }

    function deployValue() external pure override returns (uint256) {
        return 0;
    }

    function contractNames() external view override returns (string[] memory) {
        return _contractnames;
    }

    function isComplete(address[] calldata _challenges) external view override returns (bool) {
        // @dev to win this challenge you must drain the contract
        Laboratory _target = Laboratory(_challenges[0]);

        return _target.isCaught();
    }

    function path() external pure returns (string memory) {
        return "/tracks/eko2022/phoenixtto";
    }

    /// @dev optional to give a link to a readme
    function readme() external pure returns (string memory) {
        return "A wild Phoenixtto appears, capture the Phoenixtto, if you can...";
    }

    function name() external pure override returns (string memory) {
        return "Phoenixtto";
    }

    function description() external pure override returns (string memory) {
        return
        "Born in a crossover of harry potter, pokemon and solidity. with the ability of resurrection with a copy of other bytecode";
    }

    function image() external pure override returns (string memory) {
        return "ipfs://QmV2mwRVwYrg3AzvcrG2NPhY5JzoSY3i88T3ec6CzJXWKj";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 *     @title Phoenixtto
 *     @author Rotcivegaf https://twitter.com/victor93389091 <[email protected]>
 *     @dev Within the world of crossovers there is a special one, where the universes of pokemon,
 *         harry potter and solidity intertwine.
 *         In this crossover a mix creature is created between dumbledore's phoenix, a wild ditto and
 *         since we are in the solidity universe this creature is a contract.
 *         We have called it Phoenixtto and it has two important abilities, that of being reborn from
 *         it's ashes after its destruction and that of copying the behavior of another bytecode
 *         Try to capture the Phoenixtto, if you can...
 *     @custom:url https://www.ctfprotocol.com/tracks/eko2022/phoenixtto
 */
contract Laboratory {
    address immutable PLAYER;
    address public getImplementation;
    address public addr;

    constructor(address _player) {
        PLAYER = _player;
    }

    function mergePhoenixDitto() public {
        reBorn(type(Phoenixtto).creationCode);
    }

    function reBorn(bytes memory _code) public {
        address x;
        assembly {
            x := create(0, add(0x20, _code), mload(_code))
        }
        getImplementation = x;

        _code = hex"5860208158601c335a63aaf10f428752fa158151803b80938091923cf3";
        assembly {
            x := create2(0, add(_code, 0x20), mload(_code), 0)
        }
        addr = x;
        Phoenixtto(x).reBorn();
    }

    function isCaught() external view returns (bool) {
        return Phoenixtto(addr).owner() == PLAYER;
    }
}

contract Phoenixtto {
    address public owner;
    bool private _isBorn;

    function reBorn() external {
        if (_isBorn) return;

        _isBorn = true;
        owner = address(this);
    }

    function capture(string memory _newOwner) external {
        if (!_isBorn || msg.sender != tx.origin) return;

        address newOwner = address(uint160(uint256(keccak256(abi.encodePacked(_newOwner)))));
        if (newOwner == msg.sender) {
            owner = newOwner;
        } else {
            selfdestruct(payable(msg.sender));
            _isBorn = false;
        }
    }
}