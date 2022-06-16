/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// SPDX-License-Identifier: MIT



pragma solidity ^0.8.9;

library Base64 {
    string constant private B64_ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory _data) internal pure returns (string memory result) {
        if (_data.length == 0) return '';
        string memory _table = B64_ALPHABET;
        uint256 _encodedLen = 4 * ((_data.length + 2) / 3);
        result = new string(_encodedLen + 32);

        assembly {
            mstore(result, _encodedLen)
            let tablePtr := add(_table, 1)
            let dataPtr := _data
            let endPtr := add(dataPtr, mload(_data))
            let resultPtr := add(result, 32)

            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

            switch mod(mload(_data), 3)
            case 1 {mstore(sub(resultPtr, 2), shl(240, 0x3d3d))}
            case 2 {mstore(sub(resultPtr, 1), shl(248, 0x3d))}
        }

        return result;
    }
}
// File: contracts/monster blood.sol


pragma solidity ^0.8.9;


contract MonsterBloodrenderer {
    string public constant IMAGE_DATA =
        "data:image/jpeg;base64,/9j/4QAYRXhpZgAASUkqAAgAAAAAAAAAAAAAAP/sABFEdWNreQABAAQAAAAKAAD/4QMsaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLwA8P3hwYWNrZXQgYmVnaW49Iu+7vyIgaWQ9Ilc1TTBNcENlaGlIenJlU3pOVGN6a2M5ZCI/PiA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJBZG9iZSBYTVAgQ29yZSA2LjAtYzAwMiA3OS4xNjQ0ODgsIDIwMjAvMDcvMTAtMjI6MDY6NTMgICAgICAgICI+IDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+IDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bXA6Q3JlYXRvclRvb2w9IkFkb2JlIFBob3Rvc2hvcCAyMi4wIChXaW5kb3dzKSIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDo2Q0Q2MEE3Q0VENzQxMUVDODlDMUYzMTQzNjMxMjc4NyIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDo2Q0Q2MEE3REVENzQxMUVDODlDMUYzMTQzNjMxMjc4NyI+IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOjZDRDYwQTdBRUQ3NDExRUM4OUMxRjMxNDM2MzEyNzg3IiBzdFJlZjpkb2N1bWVudElEPSJ4bXAuZGlkOjZDRDYwQTdCRUQ3NDExRUM4OUMxRjMxNDM2MzEyNzg3Ii8+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8+/+4ADkFkb2JlAGTAAAAAAf/bAIQAFBAQGRIZJxcXJzImHyYyLiYmJiYuPjU1NTU1PkRBQUFBQUFERERERERERERERERERERERERERERERERERERERAEVGRkgHCAmGBgmNiYgJjZENisrNkREREI1QkRERERERERERERERERERERERERERERERERERERERERERERERERE/8AAEQgBLAEsAwEiAAIRAQMRAf/EAJUAAQADAQEBAQAAAAAAAAAAAAABAwQCBQYHAQEBAQEBAQEAAAAAAAAAAAAAAQIDBAUGEAACAgEDAQYDBAkEAwEAAAAAAQIDESESBDFBUXEiEwVhkTLBMxQ08IGxQlJykiMGodGCsuFiQxURAQACAQMCBQMDBQAAAAAAAAABAhEhMQNBElFhIjIEcbHhwRMj8IFCYhT/2gAMAwEAAhEDEQA/APmcjJANMJyMkACcjJAAnIyQAJyXQj3lUFll6AlJdxZCtPsK0aagq6rhuxZjDdjujkizjKDw44a7Gj2uPZZ7dsecwsSnJRXYUe4cii9764yU28ybfwIrxJVxXYiFCPci6ZCRUcKuPcjpVR7l8ixRLFACn0o9y+Q9KPcvkaNg2EGb0o9y+Ry649y+RqcCtxAodce5HOyPci5o4aKK9ke5EbV3I7ZGAONq7kRtXcWbSHEDNbHGqK8mqccmXGAhkZIAE5GSABORkgATkZIAAAAAAAAAAA6isgWQWEdkEgSi6EsFB0mB6tHPlVVOmONtn1Z6meVmTKpHaYVZ1O4xOYo0QiBMYHTcYPEngmcvSinjOdDI231eTMzhutctfq1949WvvMZJnulrshqUoyeE9TiUCjLWqNrj5V4GonLFowySiVNGmcSmSNMqWEsksmIHaiWcjh20RjKxYU1mOvU28LnU0V7LKY2PLe54+XQzcnkSueW3t12xzpFdyIPPkjLZHtNcymayiozAlkAAAAAAAAAAAAAAAAAC6CwjiuOWX7AOQTtIwAJRBKA7RbFFUS6AVfBGquJnrRtrQHN8E4LPeYJRcXg9flVpUQn2tmA5W3d6xozEmkGctYVqrHXobnHyrwMrPRmobY7HnTU3Vi7BNGaSNtqwZJm3FnkcZLJFTKLFM1ce+iELFdBzk1/bf8LPPyMgTJlbOmzlgU2LBWXyWUUBAAAAAAAAAAAAAACB1BZYGiqB6Fft/InBWRrk4tZUsaYMVfU9Wj3G+uEa1N7EktunTuCvOlApkj3OZfwp1ONF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";

    function render() external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"monster blood",',
                            '"description":"This is a bottle of mysterious blood that can awaken an ancient creature!",',
                            '"image":"',
                            IMAGE_DATA,
                            '"}'
                        )
                    )
                )
            );
    }
}