// SPDX-License-Identifier: CC0-1.0

/// @title ENS Avatar Mirror Name Labeler

/**
 *        ><<    ><<<<< ><<    ><<      ><<
 *      > ><<          ><<      ><<      ><<
 *     >< ><<         ><<       ><<      ><<
 *   ><<  ><<        ><<        ><<      ><<
 *  ><<<< >< ><<     ><<        ><<      ><<
 *        ><<        ><<       ><<<<    ><<<<
 */

pragma solidity ^0.8.17;

contract ENSAvatarMirrorNameLabeler {
    function substring(string memory str, uint256 startIndex, uint256 endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function namehashLabelCount(string memory domain) internal pure returns (uint256 count) {
        bytes memory domainBytes = bytes(domain);

        if (domainBytes.length > 0) {
            count += 1;
        }

        for (uint256 i = 0; i < domainBytes.length; i++) {
            if (domainBytes[i] == ".") {
                count += 1;
            }
        }
    }

    function namehashLabels(string memory domain) internal pure returns (bytes32[] memory) {
        bytes memory domainBytes = bytes(domain);
        bytes32[] memory labels = new bytes32[](namehashLabelCount(domain));

        if (labels.length == 0) {
            return labels;
        }

        uint256 fromIndex = 0;
        uint256 labelIndex = labels.length - 1;
        for (uint256 i = 0; i < domainBytes.length && labelIndex > 0; i++) {
            if (domainBytes[i] == ".") {
                labels[labelIndex] = keccak256(abi.encodePacked(substring(domain, fromIndex, i)));
                labelIndex -= 1;
                fromIndex = i + 1;
            }
        }

        labels[labelIndex] = keccak256(abi.encodePacked(substring(domain, fromIndex, domainBytes.length)));

        return labels;
    }

    function namehash(string memory domain) external pure returns (bytes32 result) {
        bytes32[] memory labels = namehashLabels(domain);
        for (uint256 i = 0; i < labels.length; i++) {
            result = keccak256(abi.encodePacked(result, labels[i]));
        }
    }
}