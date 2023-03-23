/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


interface IElement {
    function getHashNonce(address maker) external view returns (uint256);
}

interface ISeaport {
    function getCounter(address maker) external view returns (uint256);
}

interface IAsset {
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract SDKApproveCheckerFeature {

    IElement public immutable ELEMENT;

    constructor(IElement element) {
        ELEMENT = element;
    }

    struct SDKApproveInfo {
        uint8 tokenType; // 0: ERC721, 1: ERC1155, 2: ERC20, 255: other
        address tokenAddress;
        address operator;
    }

    function getSDKApprovalsAndCounter(
        address account,
        SDKApproveInfo[] calldata list
    )
        external
        view
        returns (uint256[] memory approvals, uint256 elementCounter, uint256 seaportCounter)
    {
        return getSDKApprovalsAndCounterV2(ISeaport(0x00000000006c3852cbEf3e08E8dF289169EdE581), account, list);
    }

    function getSDKApprovalsAndCounterV2(
        ISeaport seaport,
        address account,
        SDKApproveInfo[] calldata list
    )
        public
        view
        returns (uint256[] memory approvals, uint256 elementCounter, uint256 seaportCounter)
    {
        approvals = new uint256[](list.length);
        for (uint256 i; i < list.length; i++) {
            uint8 tokenType = list[i].tokenType;
            if (tokenType == 0 || tokenType == 1) {
                if (isApprovedForAll(list[i].tokenAddress, account, list[i].operator)) {
                    approvals[i] = 1;
                }
            } else if (tokenType == 2) {
                approvals[i] = allowanceOf(list[i].tokenAddress, account, list[i].operator);
            }
        }

        elementCounter = ELEMENT.getHashNonce(account);
        if (address(seaport) != address(0)) {
            try seaport.getCounter(account) returns (uint256 _counter) {
                seaportCounter = _counter;
            } catch (bytes memory /* reason */) {
            }
        }
        return (approvals, elementCounter, seaportCounter);
    }

    function isApprovedForAll(address nft, address owner, address operator) internal view returns (bool isApproved) {
        if (nft != address(0) && operator != address(0)) {
            try IAsset(nft).isApprovedForAll(owner, operator) returns (bool _isApprovedForAll) {
                isApproved = _isApprovedForAll;
            } catch {
            }
        }
        return isApproved;
    }

    function allowanceOf(address erc20, address owner, address spender) internal view returns (uint256 allowance) {
        if (erc20 != address(0)) {
            try IAsset(erc20).allowance(owner, spender) returns (uint256 _allowance) {
                allowance = _allowance;
            } catch {
            }
        }
        return allowance;
    }
}