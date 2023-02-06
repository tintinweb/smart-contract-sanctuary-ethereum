/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./interfaces/ISeaport.sol";

interface IConduitController {
    function getConduit(bytes32 conduitKey) external view returns (address conduit, bool exists);
}

interface INFT {
    function balanceOf(address owner) external view returns (uint256 balance);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract OkxExchangeCheckerFeature {

    address public immutable OKX;
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    constructor(address okx) {
        OKX = okx;
    }

    struct OkxCheckInfo {
        address conduit;
        bool conduitExists;
        address erc721Owner;
        bool isApprovedForAll; // erc721.isApprovedForAll or erc1155.isApprovedForAll
        address erc721ApprovedAccount; // erc721.getApproved(tokenId)
        uint256 erc1155Balance;
        bool isValidated;
        bool isCancelled;
        uint256 totalFilled;
        uint256 totalSize;
    }

    /// @param itemType itemType 0: ERC721, 1: ERC1155
    function getOkxCheckInfo(
        address account,
        uint8 itemType,
        address token,
        uint256 tokenId,
        bytes32 conduitKey,
        bytes32 orderHash,
        uint256 counter
    ) external view returns (OkxCheckInfo memory info) {
        (info.conduit, info.conduitExists) = getConduit(conduitKey);
        if (itemType == 0) {
            info.erc721Owner = ownerOf(token, tokenId);
            info.erc721ApprovedAccount = getApproved(token, tokenId);
            info.isApprovedForAll = isApprovedForAll(token, account, info.conduit);
        } else if (itemType == 1) {
            info.erc1155Balance = balanceOf(token, account, tokenId);
            info.isApprovedForAll = isApprovedForAll(token, account, info.conduit);
        }

        try ISeaport(OKX).getOrderStatus(orderHash) returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        ) {
            info.isValidated = isValidated;
            info.isCancelled = isCancelled;
            info.totalFilled = totalFilled;
            info.totalSize = totalSize;

            if (totalFilled > 0 && totalFilled == totalSize) {
                info.isCancelled = true;
            }
        } catch {}

        try ISeaport(OKX).getCounter(account) returns(uint256 _counter) {
            if (counter != _counter) {
                info.isCancelled = true;
            }
        } catch {}
        return info;
    }

    function getConduit(bytes32 conduitKey) public view returns (address conduit, bool exists) {
        if (conduitKey == 0x0000000000000000000000000000000000000000000000000000000000000000) {
            conduit = OKX;
            exists = true;
        } else {
            try ISeaport(OKX).information() returns (string memory, bytes32, address conduitController) {
                try IConduitController(conduitController).getConduit(conduitKey) returns (address _conduit, bool _exists) {
                    conduit = _conduit;
                    exists = _exists;
                } catch {
                }
            } catch {
            }
        }
        return (conduit, exists);
    }

    function ownerOf(address nft, uint256 tokenId) internal view returns (address owner) {
        try INFT(nft).ownerOf(tokenId) returns (address _owner) {
            owner = _owner;
        } catch {
        }
        return owner;
    }

    function getApproved(address nft, uint256 tokenId) internal view returns (address operator) {
        try INFT(nft).getApproved(tokenId) returns (address approvedAccount) {
            operator = approvedAccount;
        } catch {
        }
        return operator;
    }

    function isApprovedForAll(address nft, address owner, address operator) internal view returns (bool isApproved) {
        if (operator != address(0)) {
            try INFT(nft).isApprovedForAll(owner, operator) returns (bool _isApprovedForAll) {
                isApproved = _isApprovedForAll;
            } catch {
            }
        }
        return isApproved;
    }

    function balanceOf(address nft, address account, uint256 id) internal view returns (uint256 balance) {
        try INFT(nft).balanceOf(account, id) returns (uint256 _balance) {
            balance = _balance;
        } catch {
        }
        return balance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

interface ISeaport {
    /**
     * @notice Retrieve the status of a given order by hash, including whether
     *         the order has been cancelled or validated and the fraction of the
     *         order that has been filled.
     *
     * @param orderHash The order hash in question.
     *
     * @return isValidated A boolean indicating whether the order in question
     *                     has been validated (i.e. previously approved or
     *                     partially filled).
     * @return isCancelled A boolean indicating whether the order in question
     *                     has been cancelled.
     * @return totalFilled The total portion of the order that has been filled
     *                     (i.e. the "numerator").
     * @return totalSize   The total size of the order that is either filled or
     *                     unfilled (i.e. the "denominator").
     */
    function getOrderStatus(bytes32 orderHash)
        external
        view
        returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        );

    /**
     * @notice Retrieve the current counter for a given offerer.
     *
     * @param offerer The offerer in question.
     *
     * @return counter The current counter.
     */
    function getCounter(address offerer) external view returns (uint256 counter);

    /**
     * @notice Retrieve configuration information for this contract.
     *
     * @return version           The contract version.
     * @return domainSeparator   The domain separator for this contract.
     * @return conduitController The conduit Controller set for this contract.
     */
    function information()
        external
        view
        returns (
            string memory version,
            bytes32 domainSeparator,
            address conduitController
        );
}