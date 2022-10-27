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

contract CoinFlip {
  uint256 public consecutiveWins;
  uint256 private lastHash;
  uint256 private constant FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  function flip(bool _guess) public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number - 1));

    require(lastHash != blockValue, "wait one block more");

    lastHash = blockValue;
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip == 1 ? true : false;

    if (side == _guess) {
      ++consecutiveWins;
      return true;
    } else {
      consecutiveWins = 0;
      return false;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ChallengeFactory} from "../ChallengeFactory.sol";

import {CoinFlip} from "./L2.coinflip.sol";

contract L2EthernautFactory is ChallengeFactory {
    mapping(address => address) private _challengePlayer;
    string[] _contractnames = ["CoinFlip"];

    function deploy(address _player) external payable override returns (address[] memory ret) {
        require(msg.value == 0, "dont send ether");
        address _challenge = address(new CoinFlip());
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
        return _challenges[0].balance == 0 && CoinFlip(_challenges[0]).consecutiveWins() >= 10;
    }

    /// @dev optional to give a link to a readme
    function readme() external pure returns (string memory) {
        return "ipfs://QmPE8a2FttGnjP2WKX9BRqHPmCM8mBdT8pQ3DWjL3sQk89";
    }

    function name() external pure override returns (string memory) {
        return "CoinFlip";
    }

    function description() external pure override returns (string memory) {
        return "CoinFlip, challenge made by Kyle Riley, https://github.com/syncikin";
    }

    function image() external pure override returns (string memory) {
        return "ipfs://QmbcUJqoTvRxABGwy3DUmMtULMZGHnAAA95WwNLTYiLsJG";
    }
}