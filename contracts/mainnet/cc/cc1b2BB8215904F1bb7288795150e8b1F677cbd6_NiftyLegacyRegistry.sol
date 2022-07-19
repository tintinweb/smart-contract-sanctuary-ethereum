// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

struct RoyaltyInfo {
    address beneficiary;
    uint16 bips; //max 10_000
}

interface IRegistry {
   function isValidNiftySender(address sender) external view returns (bool);
}

contract NiftyLegacyRegistry {

    bool public _initialized;
    address immutable public _registry;
    uint256 immutable public _defaultNiftyType;

    mapping(uint256 => RoyaltyInfo) public _royaltyInfoIndex;

    mapping(address => uint256[]) public _tokenToIndexSetGlobal;
    mapping(address => mapping(uint256 => uint256[])) public _tokenToIndexSetNiftyType;

    event LegacyContractAdded(address indexed tokenAddress);

    constructor(address registry_) {
        _registry = registry_;
        _defaultNiftyType = 1;
        _initialized = false;
    }

    modifier onlyValidSender() {
        require(IRegistry(_registry).isValidNiftySender(msg.sender), "NiftyLegacyRegistry: invalid msg.sender");
        _;
    }

    /**
     *
     */
    function setInitialized() public onlyValidSender {
        _initialized = true;
    }

    /**
     * 
     */
    function isLegacyToken(address tokenAddress, uint256 tokenId) public view returns (bool) {
        return _tokenToIndexSetNiftyType[tokenAddress][_getNiftyType(tokenId)].length != 0 ||
               _tokenToIndexSetGlobal[tokenAddress].length != 0;
    }

    /**
     * @dev RoyaltyRegistry.sol address verification.
     */
    function isLegacyAddress(address tokenAddress) external view returns (bool) {
        return _tokenToIndexSetNiftyType[tokenAddress][_defaultNiftyType].length != 0 ||
               _tokenToIndexSetGlobal[tokenAddress].length != 0;
    }

    /**
     *               index                                token                      bips
     * _royaltyInfoSet[1] = RoyaltyInfo(0x0000000000000000000000000000000000000000, 10000);
     *
     */
    function setRoyaltyInfoIndexBatch(uint256[] calldata indexList, RoyaltyInfo[] calldata infoList) external onlyValidSender {
        for(uint256 i = 0; i < indexList.length; i++){
            _royaltyInfoIndex[indexList[i]] = infoList[i];
        }
    }

    /**
     *
     *                                     tokenAddress                   niftyType
     * _tokenNiftyTypeToIndexSet[0x0000000000000000000000000000000000000000][1] = [1, 2];
     *                                                                     royalty info indices
     *
     */
    function setTokenToIndexNiftyType(address tokenAddress, uint256[] calldata listNiftyType, uint256[][] calldata indexList) external onlyValidSender {
        require(!_initialized, "NiftyLegacyRegistry: initialized");
        for(uint256 i = 0; i < listNiftyType.length; i++){
            uint256 niftyType = listNiftyType[i];
            _setTokenToIndexNiftyType(tokenAddress, niftyType, indexList[i]);
        }
        emit LegacyContractAdded(tokenAddress);
    }

    /**
     *
     *                                     tokenAddress                  
     * _tokenToIndexSetGlobal[0x0000000000000000000000000000000000000000] = [1, 2];
     *                                                                 royalty info indices
     */
    function setTokenToIndexGlobalBatch(address[] calldata tokenAddressList, uint256[][] calldata indexListSet) external onlyValidSender {
        require(!_initialized, "NiftyLegacyRegistry: initialized");
        for(uint256 i = 0; i < tokenAddressList.length; i++){
            _setTokenToIndexGlobal(tokenAddressList[i], indexListSet[i]);
            emit LegacyContractAdded(tokenAddressList[i]);
        }
    }

    /**
     *
     */
    function updateGlobalToNiftyType(address tokenAddress, uint256[] calldata listNiftyType, uint256[][] calldata indexList) external onlyValidSender {
        for(uint256 i = 0; i < listNiftyType.length; i++){
            uint256 niftyType = listNiftyType[i];
            _setTokenToIndexNiftyType(tokenAddress, niftyType, indexList[i]);
        }
        delete _tokenToIndexSetGlobal[tokenAddress];
    }

    /**
     *
     */
    function updateNiftyTypeToGlobal(address tokenAddress, uint256[] calldata listNiftyType, uint256[] calldata indexList) external onlyValidSender {
        for(uint256 i = 0; i < listNiftyType.length; i++){
            uint256 niftyType = listNiftyType[i];
            delete _tokenToIndexSetNiftyType[tokenAddress][niftyType];
        }
        _setTokenToIndexGlobal(tokenAddress, indexList);
    }

    /**
     *
     */
    function updateTokenToIndexGlobal(address tokenAddress, uint256[] calldata indexList) external onlyValidSender {
        delete _tokenToIndexSetGlobal[tokenAddress];
        _setTokenToIndexGlobal(tokenAddress, indexList);
    }

    /**
     *
     */
    function updateTokenToIndexNiftyType(address tokenAddress, uint256 niftyType, uint256[] calldata indexList) external onlyValidSender {
        delete _tokenToIndexSetNiftyType[tokenAddress][niftyType];
        _setTokenToIndexNiftyType(tokenAddress, niftyType, indexList);
    }

    /**
     */
    function _setTokenToIndexNiftyType(address tokenAddress, uint256 niftyType, uint256[] calldata indexList) private {
        for(uint256 i = 0; i < indexList.length; i++){
            uint256 index = indexList[i];
            _tokenToIndexSetNiftyType[tokenAddress][niftyType].push(index);
        }
    }

    /**
     */
    function _setTokenToIndexGlobal(address tokenAddress, uint256[] calldata indexList) private {
        for(uint256 i = 0; i < indexList.length; i++){
            uint256 index = indexList[i];
            _tokenToIndexSetGlobal[tokenAddress].push(index);
        }
    }

    /**
     */
    function _getNiftyType(uint256 tokenId) internal pure returns (uint256) {
        uint256 contractId  = tokenId / 100000000;
        uint256 topLevelMultiplier = contractId * 100000000;
        return (tokenId - topLevelMultiplier) / 10000;
    }

    /**
     *
     */
    function getRoyaltyInfo(uint256 index) external view returns (RoyaltyInfo memory) {
        return _royaltyInfoIndex[index];
    }

    /**
     *
     */
    function getTokenToIndexNiftyType(address tokenAddress, uint256 niftyType) public view returns (uint256[] memory) {
        return _tokenToIndexSetNiftyType[tokenAddress][niftyType];
    }

    /**
     *
     */
    function getTokenToIndexSetGlobal(address tokenAddress) public view returns (uint256[] memory) {
        return _tokenToIndexSetGlobal[tokenAddress];
    }

    /**
     * 
     */
    function getRoyalties(address tokenAddress, uint256 tokenId) external view returns (address payable[] memory, uint256[] memory) {
        require(isLegacyToken(tokenAddress, tokenId), "NiftyLegacyRegistry: invalid input");

        uint256[] memory listIndex = _tokenToIndexSetGlobal[tokenAddress];
        uint256 count = listIndex.length;

        if (count == 0) {
            listIndex = _tokenToIndexSetNiftyType[tokenAddress][_getNiftyType(tokenId)];
            count = listIndex.length;
        }

        address payable[] memory listBeneficiary = new address payable[](count);
        uint256[] memory listAmount = new uint256[](count);

        for(uint256 i = 0; i < count; i++){
            RoyaltyInfo memory info = _royaltyInfoIndex[listIndex[i]];
            listAmount[i] = info.bips;
            listBeneficiary[i] = payable(info.beneficiary);
        } 
        return (listBeneficiary, listAmount);
    }

}