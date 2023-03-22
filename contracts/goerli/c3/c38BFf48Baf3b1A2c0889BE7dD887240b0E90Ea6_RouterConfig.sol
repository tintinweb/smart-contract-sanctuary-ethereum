/**
 *Submitted for verification at Etherscan.io on 2023-03-22
*/

/**
 *Submitted for verification at polygonscan.com on 2023-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract Ownable {
    address[2] private _owners;

    modifier onlyOwner() {
        require(msg.sender == _owners[0] || msg.sender == _owners[1], "only owner");
        _;
    }

    constructor (address[2] memory newOwners) {
        _owners = newOwners;
    }

    function owners() external view returns (address[2] memory) {
        return _owners;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        require(newOwner != _owners[0] && newOwner != _owners[1]);
        if (msg.sender == _owners[0]) {
            _owners[0] = newOwner;
        } else {
            _owners[1] = newOwner;
        }
    }
}

contract RouterConfig is Ownable {
    // stored in map
    struct ChainConfig {
        string BlockChain;
        string RouterContract;
        uint64 Confirmations;
        uint64 InitialHeight;
        string Extra;
    }

    // stored in array
    struct ChainConfig2 {
        uint256 ChainID;
        string BlockChain;
        string RouterContract;
        uint64 Confirmations;
        uint64 InitialHeight;
        string Extra;
    }

    // stored in map
    struct TokenConfig {
        uint8 Decimals;
        string ContractAddress;
        uint256 ContractVersion;
        string RouterContract;
        string Extra;
    }

    // stored in array
    struct TokenConfig2 {
        uint256 ChainID;
        uint8 Decimals;
        string ContractAddress;
        uint256 ContractVersion;
        string RouterContract;
        string Extra;
    }

    // stored in map
    struct SwapConfig {
        uint256 MaximumSwap;
        uint256 MinimumSwap;
        uint256 BigValueThreshold;
    }

    // stored in array
    struct SwapConfig2 {
        uint256 FromChainID;
        uint256 ToChainID;
        uint256 MaximumSwap;
        uint256 MinimumSwap;
        uint256 BigValueThreshold;
    }

    // stored in map
    struct FeeConfig {
        uint256 MaximumSwapFee;
        uint256 MinimumSwapFee;
        uint256 SwapFeeRatePerMillion;
    }

    // stored in array
    struct FeeConfig2 {
        uint256 FromChainID;
        uint256 ToChainID;
        uint256 MaximumSwapFee;
        uint256 MinimumSwapFee;
        uint256 SwapFeeRatePerMillion;
    }

    // stored in array
    struct MultichainToken {
        uint256 ChainID;
        string TokenAddress;
    }

    modifier checkChainconfig(ChainConfig memory config) {
        require(bytes(config.RouterContract).length > 0, "empty router contract");
        require(bytes(config.BlockChain).length > 0, "empty BlockChain");
        require(config.Confirmations > 0, "zero confirmations");
        _;
    }

    modifier checkTokenConfig(TokenConfig memory config) {
        require(bytes(config.ContractAddress).length > 0, "empty token contract");
        _;
    }

    modifier checkSwapConfig(SwapConfig2 memory config) {
        require(config.MaximumSwap > 0, "zero max");
        require(config.MaximumSwap >= config.BigValueThreshold, "max < big");
        require(config.BigValueThreshold >= config.MinimumSwap, "big < min");
        _;
    }

    modifier checkFeeConfig(FeeConfig2 memory config) {
        require(config.MaximumSwapFee > 0, "zero max");
        require(config.MaximumSwapFee >= config.MinimumSwapFee, "max < min");
        require(config.SwapFeeRatePerMillion < 1000000, "feeRate >= 1000000");
        require(config.SwapFeeRatePerMillion > 0 || config.MinimumSwapFee == 0, "wrong min");
        _;
    }

    uint256 public constant CONFIG_VERSION = 2;

    uint256[] private _allChainIDs;
    string[] private _allTokenIDs;
    mapping(string => MultichainToken[]) private _allMultichainTokens; // key is tokenID
    mapping(string => SwapConfig2[]) private _allSwapConfigs; // key is tokenID
    mapping(string => FeeConfig2[]) private _allFeeConfigs; // key is tokenID

    mapping(uint256 => bool) private _allChainIDsMap; // key is chainID
    mapping(string => bool) private _allTokenIDsMap; // key is tokenID
    mapping(string => mapping(uint256 => string)) private _allMultichainTokensMap; // key is tokenID,chainID

    mapping(uint256 => ChainConfig) private _chainConfig; // key is chainID
    mapping(string => mapping(uint256 => TokenConfig)) private _tokenConfig; // key is tokenID,chainID
    mapping(string => mapping(uint256 => mapping(uint256 => SwapConfig))) private _swapConfig; // key is tokenID,srcChainID,dstChainID
    mapping(string => mapping(uint256 => mapping(uint256 => FeeConfig))) private _feeConfig; // key is tokenID,srcChainID,dstChainID
    mapping(uint256 => mapping(string => string)) private _customConfig; // key is chainID,customKey
    mapping(string => string) private _extraConfig; // key is customKey
    mapping(uint256 => mapping(string => string)) private _tokenIDMap; // key is chainID,tokenAddress
    mapping(string => string) private _mpcPubkey; // key is mpc address

    event UpdateConfig();

    constructor(address[2] memory owners) Ownable(owners) {
    }

    function getAllChainIDs() external view returns (uint256[] memory) {
        return _allChainIDs;
    }

    function getAllChainIDLength() external view returns (uint256) {
        return _allChainIDs.length;
    }

    function getChainIDByIndex(uint256 index) external view returns (uint256) {
        return _allChainIDs[index];
    }

    function isChainIDExist(uint256 chainID) public view returns (bool) {
        return _allChainIDsMap[chainID];
    }

    function getAllTokenIDs() external view returns (string[] memory result) {
        return _allTokenIDs;
    }

    function getAllTokenIDLength() external view returns (uint256) {
        return _allTokenIDs.length;
    }

    function getTokenIDByIndex(uint256 index) external view returns (string memory) {
        return _allTokenIDs[index];
    }

    function isTokenIDExist(string memory tokenID) public view returns (bool) {
        return _allTokenIDsMap[tokenID];
    }

    function getAllMultichainTokens(string memory tokenID) external view returns (MultichainToken[] memory) {
        return _allMultichainTokens[tokenID];
    }

    function getMultichainToken(string memory tokenID, uint256 chainID) external view returns (string memory) {
        return _allMultichainTokensMap[tokenID][chainID];
    }

    function getAllMultichainTokenConfig(string memory tokenID) external view returns (TokenConfig2[] memory) {
        MultichainToken[] memory _mcTokens = _allMultichainTokens[tokenID];
        uint256 count = _mcTokens.length;
        TokenConfig2[] memory result = new TokenConfig2[](count);
        mapping(uint256 => TokenConfig) storage _configs = _tokenConfig[tokenID];
        TokenConfig memory c;
        for (uint256 i = 0; i < count; i++) {
            uint256 chainID = _mcTokens[i].ChainID;
            c = _configs[chainID];
            if (bytes(c.RouterContract).length == 0 && bytes(c.ContractAddress).length > 0) {
                c.RouterContract = _chainConfig[chainID].RouterContract;
            }
            result[i] = TokenConfig2(
                chainID,
                c.Decimals,
                c.ContractAddress,
                c.ContractVersion,
                c.RouterContract,
                c.Extra
            );
        }
        return result;
    }

    function getTokenID(uint256 chainID, string memory tokenAddress) external view returns (string memory) {
        return _tokenIDMap[chainID][tokenAddress];
    }

    function getChainConfig(uint256 chainID) external view returns (ChainConfig memory) {
        return _chainConfig[chainID];
    }

    function getAllChainConfig() external view returns (ChainConfig2[] memory) {
        uint256 count = _allChainIDs.length;
        ChainConfig2[] memory result = new ChainConfig2[](count);
        ChainConfig memory c;
        for (uint256 i = 0; i < count; i++) {
            uint256 chainID = _allChainIDs[i];
            c = _chainConfig[chainID];
            result[i] = ChainConfig2(
                chainID,
                c.BlockChain,
                c.RouterContract,
                c.Confirmations,
                c.InitialHeight,
                c.Extra
            );
        }
        return result;
    }

    function getOriginalTokenConfig(string memory tokenID, uint256 chainID) external view returns (TokenConfig memory) {
        return _tokenConfig[tokenID][chainID];
    }

    function getTokenConfig(string memory tokenID, uint256 chainID) external view returns (TokenConfig memory) {
        TokenConfig memory c = _tokenConfig[tokenID][chainID];
        if (bytes(c.RouterContract).length == 0) {
            c.RouterContract = _chainConfig[chainID].RouterContract;
        }
        return c;
    }

    function getSwapConfig(string memory tokenID, uint256 srcChainID, uint256 dstChainID) external view returns (SwapConfig memory) {
        return _swapConfig[tokenID][srcChainID][dstChainID];
    }

    function getFeeConfig(string memory tokenID, uint256 srcChainID, uint256 dstChainID) external view returns (FeeConfig memory) {
        return _feeConfig[tokenID][srcChainID][dstChainID];
    }

    function getAllSwapConfigs(string memory tokenID) external view returns (SwapConfig2[] memory) {
        return _allSwapConfigs[tokenID];
    }

    function getSwapConfigsCount(string memory tokenID) external view returns (uint256) {
        return _allSwapConfigs[tokenID].length;
    }

    function getSwapConfigAtIndex(string memory tokenID, uint256 index) external view returns (SwapConfig2 memory) {
        return _allSwapConfigs[tokenID][index];
    }

    function getSwapConfigAtIndexRange(string memory tokenID, uint256 startIndex, uint256 endIndex) external view returns (SwapConfig2[] memory) {
        SwapConfig2[] storage _configs = _allSwapConfigs[tokenID];
        if (endIndex > _configs.length) {
            endIndex = _configs.length;
        }
        uint256 count = endIndex - startIndex;
        SwapConfig2[] memory result = new SwapConfig2[](count);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = _configs[i];
        }
        return result;
    }

    function getAllFeeConfigs(string memory tokenID) external view returns (FeeConfig2[] memory) {
        return _allFeeConfigs[tokenID];
    }

    function getFeeConfigsCount(string memory tokenID) external view returns (uint256) {
        return _allFeeConfigs[tokenID].length;
    }

    function getFeeConfigAtIndex(string memory tokenID, uint256 index) external view returns (FeeConfig2 memory) {
        return _allFeeConfigs[tokenID][index];
    }

    function getFeeConfigAtIndexRange(string memory tokenID, uint256 startIndex, uint256 endIndex) external view returns (FeeConfig2[] memory) {
        FeeConfig2[] storage _configs = _allFeeConfigs[tokenID];
        if (endIndex > _configs.length) {
            endIndex = _configs.length;
        }
        uint256 count = endIndex - startIndex;
        FeeConfig2[] memory result = new FeeConfig2[](count);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = _configs[i];
        }
        return result;
    }

    function getCustomConfig(uint256 chainID, string memory key) external view returns (string memory) {
        return _customConfig[chainID][key];
    }

    function getExtraConfig(string memory key) external view returns (string memory) {
        return _extraConfig[key];
    }

    function getMPCPubkey(string memory mpcAddress) external view returns (string memory) {
        return _mpcPubkey[mpcAddress];
    }

    function updateConfig() external onlyOwner {
        emit UpdateConfig();
    }

    function setChainConfig(uint256 chainID, string memory blockChain, string memory routerContract, uint64 confirmations, uint64 initialHeight, string memory extra) external onlyOwner returns (bool) {
        return _setChainConfig(chainID, ChainConfig(blockChain, routerContract, confirmations, initialHeight, extra));
    }

    function removeChainConfig(uint256[] memory chainIDs) public onlyOwner {
        uint256 chainID;
        for (uint256 i = 0; i < chainIDs.length; i++) {
            chainID = chainIDs[i];
            delete _chainConfig[chainID];
            this.removeChainID(chainID);
        }
    }

    function removeAllChainConfig() external onlyOwner {
        return removeChainConfig(_allChainIDs);
    }

    function setChainExtraConfig(uint256 chainID, string memory extra) external onlyOwner returns (bool) {
        require(chainID > 0);
        _chainConfig[chainID].Extra = extra;
        return true;
    }

    function setTokenConfig(string memory tokenID, uint256 chainID, string memory tokenAddr, uint8 decimals, uint256 version, string memory routerContract, string memory extra) external onlyOwner returns (bool) {
        return _setTokenConfig(tokenID, chainID, TokenConfig(decimals, tokenAddr, version, routerContract, extra));
    }

    function removeTokenConfig(string memory tokenID, uint256[] memory chainIDs) public onlyOwner {
        uint256 chainID;
        for (uint256 i = 0; i < chainIDs.length; i++) {
            chainID = chainIDs[i];
            delete _tokenConfig[tokenID][chainID];
            this.removeMultichainToken(tokenID, chainID);
        }
    }

    function removeAllTokenConfig(string memory tokenID) external onlyOwner {
        return removeTokenConfig(tokenID, _allChainIDs);
    }

    function setTokenRouterContract(string memory tokenID, uint256 chainID, string memory routerContract) external onlyOwner returns (bool) {
        require(chainID > 0 && bytes(tokenID).length > 0);
        _tokenConfig[tokenID][chainID].RouterContract = routerContract;
        return true;
    }

    function setTokenExtraConfig(string memory tokenID, uint256 chainID, string memory extra) external onlyOwner returns (bool) {
        require(chainID > 0 && bytes(tokenID).length > 0);
        _tokenConfig[tokenID][chainID].Extra = extra;
        return true;
    }

    function setSwapAndFeeConfig(
        string memory tokenID, uint256 srcChainID, uint256 dstChainID,
        uint256 maxSwap, uint256 minSwap, uint256 bigSwap,
        uint256 maxFee, uint256 minFee, uint256 feeRate
    ) external onlyOwner returns (bool) {
        return _setSwapConfig(tokenID, SwapConfig2(srcChainID, dstChainID, maxSwap, minSwap, bigSwap))
            && _setFeeConfig(tokenID, FeeConfig2(srcChainID, dstChainID, maxFee, minFee, feeRate));
    }

    function removeSwapAndFeeConfig(string memory tokenID, uint256 srcChainID, uint256 dstChainID) external onlyOwner {
        _removeSwapConfig(tokenID, srcChainID, dstChainID);
        _removeFeeConfig(tokenID, srcChainID, dstChainID);
    }

    function setSwapConfig(string memory tokenID, uint256 srcChainID, uint256 dstChainID, uint256 maxSwap, uint256 minSwap, uint256 bigSwap) external onlyOwner returns (bool) {
        return _setSwapConfig(tokenID, SwapConfig2(srcChainID, dstChainID, maxSwap, minSwap, bigSwap));
    }

    function setSwapConfigs(string memory tokenID, SwapConfig2[] calldata configs) external onlyOwner {
        for (uint256 i = 0; i < configs.length; i++) {
            _setSwapConfig(tokenID, configs[i]);
        }
    }

    function removeSwapConfig(string memory tokenID, uint256[] memory srcChainIDs, uint256[] memory dstChainIDs) public onlyOwner {
        for (uint256 i = 0; i < srcChainIDs.length; i++) {
            for (uint256 j = 0; j < dstChainIDs.length; j++) {
                _removeSwapConfig(tokenID, srcChainIDs[i], dstChainIDs[i]);
            }
        }
    }

    function _getAllChainIDsAndZero() internal view returns (uint256[] memory) {
        uint256 count = _allChainIDs.length + 1;
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count-1; i++) {
            result[i] = _allChainIDs[i];
        }
        result[count-1] = 0;
        return result;
    }

    function removeAllSwapConfig(string memory tokenID) external onlyOwner {
        uint256[] memory chainIDs = _getAllChainIDsAndZero();
        removeSwapConfig(tokenID, chainIDs, chainIDs);
    }

    function removeAllSrcSwapConfig(string memory tokenID, uint256[] memory srcChainIDs) external onlyOwner {
        removeSwapConfig(tokenID, srcChainIDs, _getAllChainIDsAndZero());
    }

    function removeAllDestSwapConfig(string memory tokenID, uint256[] memory dstChainIDs) external onlyOwner {
        removeSwapConfig(tokenID, _getAllChainIDsAndZero(), dstChainIDs);
    }

    function setFeeConfig(string memory tokenID, uint256 srcChainID, uint256 dstChainID, uint256 maxFee, uint256 minFee, uint256 feeRate) external onlyOwner returns (bool) {
        return _setFeeConfig(tokenID, FeeConfig2(srcChainID, dstChainID, maxFee, minFee, feeRate));
    }

    function setFeeConfigs(string memory tokenID, FeeConfig2[] calldata configs) external onlyOwner {
        for (uint256 i = 0; i < configs.length; i++) {
            _setFeeConfig(tokenID, configs[i]);
        }
    }

    function removeFeeConfig(string memory tokenID, uint256[] memory srcChainIDs, uint256[] memory dstChainIDs) public onlyOwner {
        for (uint256 i = 0; i < srcChainIDs.length; i++) {
            for (uint256 j = 0; j < dstChainIDs.length; j++) {
                _removeFeeConfig(tokenID, srcChainIDs[i], dstChainIDs[i]);
            }
        }
    }

    function removeAllFeeConfig(string memory tokenID) external onlyOwner {
        uint256[] memory chainIDs = _getAllChainIDsAndZero();
        removeFeeConfig(tokenID, chainIDs, chainIDs);
    }

    function removeAllSrcFeeConfig(string memory tokenID, uint256[] memory srcChainIDs) external onlyOwner {
        removeFeeConfig(tokenID, srcChainIDs, _getAllChainIDsAndZero());
    }

    function removeAllDestFeeConfig(string memory tokenID, uint256[] memory dstChainIDs) external onlyOwner {
        removeFeeConfig(tokenID, _getAllChainIDsAndZero(), dstChainIDs);
    }

    function setCustomConfig(uint256 chainID, string memory key, string memory data) external onlyOwner {
        _customConfig[chainID][key] = data;
    }

    function setExtraConfig(string memory key, string memory data) external onlyOwner {
        _extraConfig[key] = data;
    }

    function setMPCPubkey(string memory addr, string memory pubkey) external onlyOwner {
        _mpcPubkey[addr] = pubkey;
    }

    function removeMPCPubkey(string memory addr) external onlyOwner {
        delete _mpcPubkey[addr];
    }

    function addChainID(uint256 chainID) external onlyOwner returns (bool) {
        require(!isChainIDExist(chainID));
        _allChainIDs.push(chainID);
        _allChainIDsMap[chainID] = true;
        return true;
    }

    function removeChainID(uint256 chainID) external onlyOwner {
        uint256 length = _allChainIDs.length;
        for (uint256 i = 0; i < length; ++i) {
            if (_allChainIDs[i] == chainID) {
                _allChainIDs[i] = _allChainIDs[length-1];
                _allChainIDs.pop();
                _allChainIDsMap[chainID] = false;
                break;
            }
        }
    }

    function addTokenID(string memory tokenID) external onlyOwner returns (bool) {
        require(!isTokenIDExist(tokenID));
        _allTokenIDs.push(tokenID);
        _allTokenIDsMap[tokenID] = true;
        return true;
    }

    function removeTokenID(string memory tokenID) external onlyOwner {
        uint256 length = _allTokenIDs.length;
        for (uint256 i = 0; i < length; ++i) {
            if (_isStringEqual(_allTokenIDs[i], tokenID)) {
                _allTokenIDs[i] = _allTokenIDs[length-1];
                _allTokenIDs.pop();
                _allTokenIDsMap[tokenID] = false;
                break;
            }
        }
    }

    function setMultichainToken(string memory tokenID, uint256 chainID, string memory token) public onlyOwner {
        _setMultichainToken(tokenID, chainID, token);
    }

    function removeAllMultichainTokens(string memory tokenID) external onlyOwner {
        MultichainToken[] storage _mcTokens = _allMultichainTokens[tokenID];
        for (uint256 i = 0; i < _mcTokens.length; ++i) {
            MultichainToken memory _mcToken = _mcTokens[i];
            _tokenIDMap[_mcToken.ChainID][_mcToken.TokenAddress] = "";
            _allMultichainTokensMap[tokenID][_mcToken.ChainID] = "";
        }
        delete _allMultichainTokens[tokenID];
    }

    function removeMultichainToken(string memory tokenID, uint256 chainID) external onlyOwner {
        MultichainToken[] storage _mcTokens = _allMultichainTokens[tokenID];
        uint256 length = _mcTokens.length;
        for (uint256 i = 0; i < length; ++i) {
            if (_mcTokens[i].ChainID == chainID) {
                _tokenIDMap[chainID][_mcTokens[i].TokenAddress] = "";
                _allMultichainTokensMap[tokenID][chainID] = "";
                _mcTokens[i] = _mcTokens[length-1];
                _mcTokens.pop();
                break;
            }
        }
    }

    function _isStringEqual(string memory s1, string memory s2) internal pure returns (bool) {
        return bytes(s1).length == bytes(s2).length && keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function _setChainConfig(uint256 chainID, ChainConfig memory config) internal checkChainconfig(config) returns (bool) {
        require(chainID > 0);
        _chainConfig[chainID] = config;
        if (!isChainIDExist(chainID)) {
            _allChainIDs.push(chainID);
            _allChainIDsMap[chainID] = true;
        }
        return true;
    }

    function _setTokenConfig(string memory tokenID, uint256 chainID, TokenConfig memory config) internal checkTokenConfig(config) returns (bool) {
        require(chainID > 0 && bytes(tokenID).length > 0);
        _tokenConfig[tokenID][chainID] = config;
        if (!isTokenIDExist(tokenID)) {
            _allTokenIDs.push(tokenID);
            _allTokenIDsMap[tokenID] = true;
        }
        _setMultichainToken(tokenID, chainID, config.ContractAddress);
        return true;
    }

    function _setSwapConfig(string memory tokenID, SwapConfig2 memory config) internal checkSwapConfig(config) returns (bool) {
        require(bytes(tokenID).length > 0);

        uint256 srcChainID = config.FromChainID;
        uint256 dstChainID = config.ToChainID;
        _swapConfig[tokenID][srcChainID][dstChainID] = SwapConfig(config.MaximumSwap, config.MinimumSwap, config.BigValueThreshold);

        SwapConfig2[] storage _configs = _allSwapConfigs[tokenID];
        uint256 length = _configs.length;
        SwapConfig2 memory _config;
        for (uint256 i = 0; i < length; ++i) {
            _config = _configs[i];
            if (_config.FromChainID == srcChainID && _config.ToChainID == dstChainID) {
                _configs[i] = config;
                return true;
            }
        }
        _configs.push(config);
        return true;
    }

    function _removeSwapConfig(string memory tokenID, uint256 srcChainID, uint256 dstChainID) internal {
        if (_swapConfig[tokenID][srcChainID][dstChainID].MaximumSwap == 0) {
            return;
        }

        delete _swapConfig[tokenID][srcChainID][dstChainID];

        SwapConfig2[] storage _configs = _allSwapConfigs[tokenID];
        uint256 length = _configs.length;
        SwapConfig2 memory _config;
        for (uint256 i = 0; i < length; ++i) {
            _config = _configs[i];
            if (_config.FromChainID == srcChainID && _config.ToChainID == dstChainID) {
                _configs[i] = _configs[length-1];
                _configs.pop();
                break;
            }
        }
    }

    function _setFeeConfig(string memory tokenID, FeeConfig2 memory config) internal checkFeeConfig(config) returns (bool) {
        require(bytes(tokenID).length > 0);

        uint256 srcChainID = config.FromChainID;
        uint256 dstChainID = config.ToChainID;
        _feeConfig[tokenID][srcChainID][dstChainID] = FeeConfig(config.MaximumSwapFee, config.MinimumSwapFee, config.SwapFeeRatePerMillion);

        FeeConfig2[] storage _configs = _allFeeConfigs[tokenID];
        uint256 length = _configs.length;
        FeeConfig2 memory _config;
        for (uint256 i = 0; i < length; ++i) {
            _config = _configs[i];
            if (_config.FromChainID == srcChainID && _config.ToChainID == dstChainID) {
                _configs[i] = config;
                return true;
            }
        }
        _configs.push(config);
        return true;
    }

    function _removeFeeConfig(string memory tokenID, uint256 srcChainID, uint256 dstChainID) internal {
        if (_feeConfig[tokenID][srcChainID][dstChainID].MaximumSwapFee == 0) {
            return;
        }

        delete _feeConfig[tokenID][srcChainID][dstChainID];

        FeeConfig2[] storage _configs = _allFeeConfigs[tokenID];
        uint256 length = _configs.length;
        FeeConfig2 memory _config;
        for (uint256 i = 0; i < length; ++i) {
            _config = _configs[i];
            if (_config.FromChainID == srcChainID && _config.ToChainID == dstChainID) {
                _configs[i] = _configs[length-1];
                _configs.pop();
                break;
            }
        }
    }

    function _setMultichainToken(string memory tokenID, uint256 chainID, string memory token) internal {
        require(chainID > 0 && bytes(tokenID).length > 0);

        _tokenIDMap[chainID][token] = tokenID;
        _allMultichainTokensMap[tokenID][chainID] = token;

        MultichainToken[] storage _mcTokens = _allMultichainTokens[tokenID];
        for (uint256 i = 0; i < _mcTokens.length; ++i) {
            if (_mcTokens[i].ChainID == chainID) {
                string memory oldToken = _mcTokens[i].TokenAddress;
                if (!_isStringEqual(token, oldToken)) {
                    _mcTokens[i].TokenAddress = token;
                    _tokenIDMap[chainID][oldToken] = "";
                }
                return;
            }
        }
        _mcTokens.push(MultichainToken(chainID, token));
    }
}