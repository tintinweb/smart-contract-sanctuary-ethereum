// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./AccessControl.sol";
import "./IERC721.sol";

contract MAYCHolder is AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    mapping(address => uint256) private holders;
    mapping(uint256 => address) private tokens;
    address public maycNFTAddress;
    bool public activated = false;

    constructor(address adminAddress, address operatorAddress, address maycAddress) {
        maycNFTAddress = maycAddress;

        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _setupRole(OPERATOR_ROLE, operatorAddress);
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "Caller is not an operator");
        _;
    }

    function requestToClaim(uint256[] calldata tokenIds) external {
        require(activated, "Request to claim is deactivated");
        require(tokenIds.length > 0, "Cannot request to claim with empty tokens");
        uint256 count = 0;

        for(uint i=0; i<tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(IERC721(maycNFTAddress).ownerOf(tokenId) == _msgSender(), "Sender is not the owner of the token");
            require(tokens[tokenId] == address(0), "The Token has been already used");
            tokens[tokenId] = _msgSender();
            count++;
            emit ClaimRequested(_msgSender(), tokenId);
        }

        holders[_msgSender()] += count;
    }

    function getRequestedCount(address owner) external view returns (uint256) {
        return holders[owner];
    }
    
    function getRequestOwner(uint256 tokenId) external view returns (address) {
        return tokens[tokenId];
    }
    
    function getOwnersFromTokenIds(uint256[] calldata tokenIds) external view returns (address[] memory addresses) {
        addresses = new address[](tokenIds.length);
        for (uint i=0; i<tokenIds.length; i++) {
            addresses[i] = tokens[tokenIds[i]];
        }
        return addresses;
    }

    // operator
    function activate(bool value) external onlyOperator {
        activated = value;
    }
    
    function cancelRequest(uint256[] calldata tokenIds) external onlyOperator {
        for(uint i=0; i<tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            holders[tokens[tokenId]]--;
            require(holders[tokens[tokenId]] >= 0, "Holder count cannot be less than 0");
            tokens[tokenId] = address(0);
            emit RequestCanceled(_msgSender(), tokenId);
        }
    }

    // events
    event ClaimRequested(address owner, uint256 tokenId);
    event RequestCanceled(address owner, uint256 tokenId);
}