// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);
}

interface IParsingNFTData {
    function getERC721HolderList(
        address nft,
        uint256[] calldata tokenIds
    ) external view returns (address[] memory holders);

    function getERC721BalanceList_OneToken(
        address nft,
        address[] calldata holders
    ) external view returns (uint256[] memory balances);

    function getERC20BalanceList_OneToken(
        address erc20,
        address[] calldata holders
    ) external view returns (uint256[] memory balances);

    function getERC1155BalanceList_OneToken(
        address erc1155,
        address[] calldata holders,
        uint256[][] calldata tokenIds
    ) external view returns (uint256[][] memory balances);

    function getERC721BalanceList_OneHolder(
        address holder,
        address[] calldata nfts
    ) external view returns (uint256[] memory balances);

    function getERC20BalanceList_OneHolder(
        address holder,
        address[] calldata erc20s
    ) external view returns (uint256[] memory balances);

    function getERC1155BalanceList_OneHolder(
        address holder,
        address[] calldata erc1155s,
        uint256[][] calldata tokenIds
    ) external view returns (uint256[][] memory balances);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IParsingNFTData.sol";

contract ParsingNFTData is IParsingNFTData {
    function getERC721HolderList(address nft, uint256[] calldata) external view returns (address[] memory holders) {
        bytes4 selector = 0x6352211e;
        /// @solidity memory-safe-assembly
        assembly {
            let len := calldataload(68)
            holders := mload(0x40)
            mstore(holders, len)
            let totalbytes := mul(len, 0x20)
            mstore(0x40, add(add(holders, 0x20), totalbytes))
            let end := add(totalbytes, 0x20)

            // prettier-ignore
            for { let i := 0x20 } lt(i, end) { i := add(i, 0x20) } {
                mstore(0, selector)
                calldatacopy(4, add(0x44, i), 0x20)

                if staticcall(gas(), nft, 0, 0x24, 0, 0x20) {
                    mstore(add(holders, i), mload(0))
                }
            }
        }
    }

    function getERC721BalanceList_OneToken(
        address nft,
        address[] calldata
    ) external view returns (uint256[] memory balances) {
        return _balanceList_OneToken(address(nft));
    }

    function getERC20BalanceList_OneToken(
        address erc20,
        address[] calldata
    ) external view returns (uint256[] memory balances) {
        return _balanceList_OneToken(address(erc20));
    }

    function _balanceList_OneToken(address token) internal view returns (uint256[] memory balances) {
        bytes4 selector = 0x70a08231;
        /// @solidity memory-safe-assembly
        assembly {
            let len := calldataload(68)
            balances := mload(0x40)
            mstore(balances, len)
            let totalbytes := mul(len, 0x20)
            mstore(0x40, add(add(balances, 0x20), totalbytes))
            let end := add(totalbytes, 0x20)

            // prettier-ignore
            for { let i := 0x20 } lt(i, end) { i := add(i, 0x20) } {
                mstore(0, selector)
                calldatacopy(4, add(0x44, i), 0x20)

                if staticcall(gas(), token, 0, 0x24, 0, 0x20) {
                    mstore(add(balances, i), mload(0))
                }
            }
        }
    }

    function getERC1155BalanceList_OneToken(
        address erc1155,
        address[] calldata holders,
        uint256[][] calldata tokenIds
    ) external view returns (uint256[][] memory balances) {
        uint256 length = holders.length;
        require(tokenIds.length == length, "LENGTH_NOT_EQUAL");
        balances = new uint256[][](length);
        for (uint256 i; i < length; ) {
            uint256 _tokenLen = tokenIds[i].length;
            balances[i] = new uint256[](_tokenLen);
            for (uint256 j; j < _tokenLen; ) {
                balances[i][j] = IERC1155(erc1155).balanceOf(holders[i], tokenIds[i][j]);
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }
    }

    function getERC721BalanceList_OneHolder(
        address holder,
        address[] calldata
    ) external view returns (uint256[] memory balances) {
        return _balanceList_OneHolder(holder);
    }

    function getERC20BalanceList_OneHolder(
        address holder,
        address[] calldata
    ) external view returns (uint256[] memory balances) {
        return _balanceList_OneHolder(holder);
    }

    function _balanceList_OneHolder(address holder) internal view returns (uint256[] memory balances) {
        bytes4 selector = 0x70a08231;
        /// @solidity memory-safe-assembly
        assembly {
            let len := calldataload(68)
            balances := mload(0x40)
            mstore(balances, len)
            let totalbytes := mul(len, 0x20)
            mstore(0x40, add(add(balances, 0x20), totalbytes))
            let end := add(totalbytes, 0x20)

            // prettier-ignore
            for { let i := 0x20 } lt(i, end) { i := add(i, 0x20) } {
                mstore(0, selector)
                mstore(4, holder)

                if staticcall(gas(), calldataload(add(0x44, i)), 0, 0x24, 0, 0x20) {
                    mstore(add(balances, i), mload(0))
                }
            }
        }
    }

    function getERC1155BalanceList_OneHolder(
        address holder,
        address[] calldata erc1155s,
        uint256[][] calldata tokenIds
    ) external view returns (uint256[][] memory balances) {
        uint256 length = erc1155s.length;
        require(tokenIds.length == length, "LENGTH_NOT_EQUAL");
        balances = new uint256[][](length);
        for (uint256 i; i < length; ) {
            uint256 _tokenLen = tokenIds[i].length;
            balances[i] = new uint256[](_tokenLen);
            for (uint256 j; j < _tokenLen; ) {
                balances[i][j] = IERC1155(erc1155s[i]).balanceOf(holder, tokenIds[i][j]);
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }
    }
}