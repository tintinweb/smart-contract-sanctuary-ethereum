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
pragma solidity ^0.8.0;

contract Delegate {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function pwn() public {
        owner = msg.sender;
    }
}

contract Delegation {
    address public owner;
    Delegate delegate;

    constructor(address _delegateAddress) {
        delegate = Delegate(_delegateAddress);
        owner = msg.sender;
    }

    fallback() external {
        (bool result,) = address(delegate).delegatecall(msg.data);
        if (result) {
            this;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ChallengeFactory} from "../ChallengeFactory.sol";

import {Delegation, Delegate} from "./L5.delegation.sol";

contract L5EthernautFactory is ChallengeFactory {
    mapping(address => address) private _challengePlayer;
    string[] _contractnames = ["Delegation"]; // name
    address public immutable delegateAddress;

    constructor() {
        delegateAddress = address(new Delegate(address(0)));
    }

    function deploy(address _player) external payable override returns (address[] memory ret) {
        require(msg.value == 0, "dont send ether");
        address _challenge = address(new Delegation(delegateAddress));
        _challengePlayer[_challenge] = _player;
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
        address _player = _challengePlayer[_challenges[0]];
        if (_player == address(0)) {
            return false;
        }
        // @dev to win this challenge you must drain the contract and be the owner
        return Delegation(_challenges[0]).owner() == _player;
    }

    /// @dev optional to give a link to a readme
    function readme() external pure returns (string memory) {
        return "";
    }

    function name() external pure override returns (string memory) {
        return "Delegation";
    }

    function description() external pure override returns (string memory) {
        return "Delegation, challenge made by Alejandro Santander, https://github.com/ajsantander";
    }

    function image() external pure override returns (string memory) {
        return "ipfs://QmXMiLEeqy2fYQvXU9drVoZqP98JoxFNLdvPDHuHEfbFmx";
    }
}