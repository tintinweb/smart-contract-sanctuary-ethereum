// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./ERC721.sol";
import "./Base64.sol";
import "./Counters.sol";
import "./Strings.sol";

contract UnWalletDeveloperBadge is ERC721 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIDCounter;

    constructor() ERC721("UnWalletDeveloperBadge", "UWDB") {}

    function mint(address to) external returns (uint256) {
        uint256 tokenID = _tokenIDCounter.current();

        _mint(to, tokenID);
        _tokenIDCounter.increment();

        return tokenID;
    }

    function tokenURI(uint256 tokenID)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenID),
            "UnWalletDeveloperBadge: URI query for nonexistent token"
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name":"unWallet Developer Badge #',
                                    tokenID.toString(),
                                    '","description":"Proof of unWallet developer","image":"data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz48c3ZnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgdmlld0JveD0iMCAwIDUxMiA1MTIiPjxkZWZzPjxzdHlsZT4udXVpZC1iMmRiYzRjZS03ZGFlLTRmZWYtYTdiZS1kOTZkZTM0ZjliZWR7ZmlsbDojMDA5M2E1O308L3N0eWxlPjwvZGVmcz48cGF0aCBjbGFzcz0idXVpZC1iMmRiYzRjZS03ZGFlLTRmZWYtYTdiZS1kOTZkZTM0ZjliZWQiIGQ9Ik0yOTUuMjMsMjkwLjk5YzExLjU3LTEyLjEsMTguNjctMjguNSwxOC42Ny00Ni41NSwwLTI0LjAxLTEyLjU1LTQ1LjA3LTMxLjQ0LTU3LjAybDIxLjg5LTQxLjgyYzEuMzQsLjI4LDIuNzQsLjQzLDQuMTcsLjQzLDExLjA4LDAsMjAuMDQtOC45NywyMC4wNC0yMC4wNHMtOC45Ni0yMC4wNC0yMC4wNC0yMC4wNC0yMC4wNCw4Ljk3LTIwLjA0LDIwLjA0YzAsNS43NSwyLjQyLDEwLjk0LDYuMzEsMTQuNTlsLTIxLjkxLDQxLjgyYy04LjEtMy40Ni0xNy4wMS01LjM3LTI2LjM5LTUuMzctMzcuMjIsMC02Ny40MSwzMC4xOC02Ny40MSw2Ny40MiwwLDE2Ljk0LDYuMjQsMzIuNDIsMTYuNTYsNDQuMjVsLTM2LjEyLDM2LjkzYy01LjU3LTMuOTMtMTIuMzgtNi4yNS0xOS43Mi02LjI1LTE4Ljg0LDAtMzQuMTIsMTUuMjgtMzQuMTIsMzQuMTJzMTUuMjgsMzQuMTQsMzQuMTIsMzQuMTQsMzQuMTMtMTUuMjgsMzQuMTMtMzQuMTRjMC03LjYtMi40OC0xNC42My02LjY5LTIwLjNsMzYuMTItMzYuOTVjMTEuNjksOS43NiwyNi43MiwxNS42MSw0My4xMywxNS42MSwxNS4yOCwwLDI5LjM4LTUuMDgsNDAuNjgtMTMuNjZtLTQwLjY4LTIyLjM1Yy02LjU5LDAtMTIuNzEtMi4wMy0xNy43Ny01LjUxLTIuOTktMi4wNi01LjU5LTQuNjMtNy43Mi03LjU3LTMuNzItNS4xNS01LjkyLTExLjQ4LTUuOTItMTguMzEsMC0xNy4zMiwxNC4wOC0zMS40LDMxLjQtMzEuNCwzLjMzLDAsNi41NCwuNTIsOS41NiwxLjUsMy41LDEuMTIsNi43MiwyLjgzLDkuNTUsNS4wMiw3LjQ3LDUuNzcsMTIuMjksMTQuNzcsMTIuMjksMjQuODksMCw3LjM2LTIuNTUsMTQuMTItNi44MSwxOS40OC0yLjI0LDIuODQtNC45Niw1LjI4LTguMDQsNy4yLTQuODEsMi45OS0xMC40OCw0LjcyLTE2LjU1LDQuNzJaIi8+PHJlY3QgY2xhc3M9InV1aWQtYjJkYmM0Y2UtN2RhZS00ZmVmLWE3YmUtZDk2ZGUzNGY5YmVkIiB4PSIzMDguOTgiIHk9IjI1MS42IiB3aWR0aD0iMzQuMDUiIGhlaWdodD0iMTYzLjgyIiB0cmFuc2Zvcm09InRyYW5zbGF0ZSgtMTM5LjExIDI5OS4yNCkgcm90YXRlKC00MS40NCkiLz48cmVjdCBjbGFzcz0idXVpZC1iMmRiYzRjZS03ZGFlLTRmZWYtYTdiZS1kOTZkZTM0ZjliZWQiIHg9IjM0My4xMiIgeT0iMjkyLjY5IiB3aWR0aD0iMjkuMSIgaGVpZ2h0PSI1Ny43MSIgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoMzYyLjAxIC0xNTkuMzkpIHJvdGF0ZSg0OC41NikiLz48cmVjdCBjbGFzcz0idXVpZC1iMmRiYzRjZS03ZGFlLTRmZWYtYTdiZS1kOTZkZTM0ZjliZWQiIHg9IjM3OS44NiIgeT0iMzM0LjEzIiB3aWR0aD0iMjkuMSIgaGVpZ2h0PSI1Ny43MSIgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoNDA1LjUgLTE3Mi45Mikgcm90YXRlKDQ4LjU2KSIvPjwvc3ZnPg=="}'
                                )
                            )
                        )
                    )
                )
            );
    }
}