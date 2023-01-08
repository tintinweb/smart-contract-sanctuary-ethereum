// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

/**
 * Season 1 Recruitment Officer for the Fire Guild
 *
 * Functions:
 *   setChallengePrefix   sets the Challenge Prefix, owner only
 *   setChallengeSuffix   sets the Challenge Suffix, owner only
 *   transferOwner        transfers ownership of this Contract, owner only
 *   setGuildContract     sets the Guild Contract, expect ERC-2535, owner only
 *
 * Test Data: 0x492c20496d6d6f6c61746f7220416d656c69612c207365656b2074686520666972652e
 */

interface GuildInterface {
  function mintRecruitBadge(address recruit, bytes memory data) external;
}

contract RecruitmentOfficer {
    // Metadata
    address owner;
    address guild;
    GuildInterface guildInterface;

    // Variables
    bytes public prefix = "I, ";              // 492c20;
    bytes public suffix = ", seek the fire."; // 2c207365656b2074686520666972652e;

    // Computational variables

    constructor() {
      owner = msg.sender;
    }

    // Default receive function
    receive() external payable { /* Do nothing */ }

    // Message receipt during fallback so users learn how to send arbitrary calldata
    fallback() external payable {
      enlist();
    }

    function enlist() private {
      uint m = msg.data.length;
      uint n = prefix.length;
      uint o = suffix.length;
      bytes memory pre = subarray(msg.data, 0, n, false);
      bytes memory suf = subarray(msg.data, m - o, m, false);
      if (keccak256(pre) == keccak256(prefix) && keccak256(suf) == keccak256(suffix)) {
        // Passed the Challenge
        // Now we will call the Guild contract and ask for a token
        guildInterface.mintRecruitBadge(msg.sender, msg.data[n:m - o]);
      } else {
        // Failed the Challenge
      }
    }

    // Variation functions
    function setChallengePrefix(string memory newPrefix) external {
      if (msg.sender != owner) return;
      prefix = bytes(newPrefix);
    }

    function setChallengeSuffix(string memory newSuffix) external {
      if (msg.sender != owner) return;
      suffix = bytes(newSuffix);
    }

    // Administrative functions
    function transferOwner(address newOwner) external {
      if (msg.sender != owner) return;
      owner = newOwner;
    }

    function setGuildContract(address guildAddress) external {
      if (msg.sender != owner) return;
      guild = guildAddress;
      guildInterface = GuildInterface(guild);
    }

    // Helper functions
    function subarray(bytes memory data, uint startIndex, uint endIndex, bool residual) private pure returns (bytes memory) {
      bytes memory result;
      uint c = 0;
      if (residual) {
        result = new bytes(data.length - (endIndex - startIndex));
        for (uint i = 0; i < data.length; i++) {
          if (i < startIndex) {
            result[c] = data[i];
          } else if (i > endIndex) {
            result[c] = data[i];
          }
          c++;
        }
      } else {
        result = new bytes(endIndex - startIndex);
        for (uint i = startIndex; i < endIndex; i++) {
          result[i - startIndex] = data[i];
        }
      }
      return result;
    }
}