/**
 *Submitted for verification at BscScan.com on 2022-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract Ownable {
    address[2] private _owners;

    modifier onlyOwner() {
        require(msg.sender == _owners[0] || msg.sender == _owners[1], "only owner");
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor (address[2] memory newOwners) {
        require(newOwners[0] != address(0)
            && newOwners[1] != address(0)
            && newOwners[0] != newOwners[1],
            "CTOR: owners are same or contain zero address");
        _owners = newOwners;
    }

    function owners() external view returns (address[2] memory) {
        return _owners;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "the new owner is the zero address");
        require(newOwner != _owners[0] && newOwner != _owners[1], "the new owner is existed");
        if (msg.sender == _owners[0]) {
            _owners[0] = newOwner;
        } else {
            _owners[1] = newOwner;
        }
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

contract RouterConfig is Ownable {
    struct ChainConfig {
        string BlockChain;
        string RouterContract;
        uint64 Confirmations;
        uint64 InitialHeight;
        string Extra;
    }

    struct TokenConfig {
        uint8 Decimals;
        string ContractAddress;
        uint256 ContractVersion;
        string RouterContract;
        string Extra;
    }

    struct SwapConfig {
        uint256 MaximumSwap;
        uint256 MinimumSwap;
        uint256 BigValueThreshold;
    }

    struct FeeConfig {
        uint256 MaximumSwapFee;
        uint256 MinimumSwapFee;
        uint256 SwapFeeRatePerMillion;
    }

    struct MultichainToken {
        uint256 ChainID;
        string TokenAddress;
    }

    modifier checkChainconfig(ChainConfig memory config) {
        require(bytes(config.RouterContract).length > 0, "empty router contract");
        require(bytes(config.BlockChain).length > 0, "empty BlockChain");
        require(config.Confirmations > 0, "zero confirmations is unsafe");
        _;
    }

    modifier checkTokenConfig(TokenConfig memory config) {
        require(bytes(config.ContractAddress).length > 0, "empty token contract");
        _;
    }

    modifier checkSwapConfig(SwapConfig memory config) {
        require(config.MaximumSwap > 0, "zero MaximumSwap");
        require(config.MaximumSwap >= config.BigValueThreshold, "MaximumSwap < BigValueThreshold");
        require(config.BigValueThreshold >= config.MinimumSwap, "BigValueThreshold < MinimumSwap");
        _;
    }

    modifier checkFeeConfig(FeeConfig memory config) {
        require(config.MaximumSwapFee > 0, "zero MaximumSwapFee");
        require(config.MaximumSwapFee >= config.MinimumSwapFee, "MaximumSwapFee < MinimumSwapFee");
        require(config.SwapFeeRatePerMillion < 1000000, "SwapFeeRatePerMillion >= 1000000");
        require(config.SwapFeeRatePerMillion > 0 || config.MinimumSwapFee == 0, "wrong MinimumSwapFee");
        _;
    }

    uint256 public constant CONFIG_VERSION = 2;

    uint256[] private _allChainIDs;
    string[] private _allTokenIDs;
    mapping (string => MultichainToken[]) private _allMultichainTokens; // key is tokenID
    mapping(uint256 => bool) private _allChainIDsMap; // key is chainID
    mapping(string => bool) private _allTokenIDsMap; // key is tokenID
    mapping (string => mapping(uint256 => string)) private _allMultichainTokensMap; // key is tokenID,chainID

    mapping (uint256 => ChainConfig) private _chainConfig; // key is chainID
    mapping (string => mapping(uint256 => TokenConfig)) private _tokenConfig; // key is tokenID,chainID
    mapping (string => mapping(uint256 => mapping(uint256 => SwapConfig))) private _swapConfig; // key is tokenID,srcChainID,dstChainID
    mapping (string => mapping(uint256 => mapping(uint256 => FeeConfig))) private _feeConfig; // key is tokenID,srcChainID,dstChainID
    mapping (uint256 => mapping(string => string)) private _customConfig; // key is chainID,customKey
    mapping (uint256 => mapping(string => string)) private _tokenIDMap; // key is chainID,tokenAddress
    mapping (string => string) private _mpcPubkey; // key is mpc address

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

    function getMultichainToken(string memory tokenID, uint256 chainID) public view returns (string memory) {
        return _allMultichainTokensMap[tokenID][chainID];
    }

    function getTokenID(uint256 chainID, string memory tokenAddress) external view returns (string memory) {
        return _tokenIDMap[chainID][tokenAddress];
    }

    function getChainConfig(uint256 chainID) external view returns (ChainConfig memory) {
        return _chainConfig[chainID];
    }

    function getOriginalTokenConfig(string memory tokenID, uint256 chainID) external view returns (TokenConfig memory) {
        return _tokenConfig[tokenID][chainID];
    }

    function getTokenConfig(string memory tokenID, uint256 chainID) external view returns (TokenConfig memory) {
        TokenConfig memory tokenCfg = _tokenConfig[tokenID][chainID];
        if (bytes(tokenCfg.RouterContract).length == 0) {
            tokenCfg.RouterContract = _chainConfig[chainID].RouterContract;
        }
        return tokenCfg;
    }

    function getSwapConfig(string memory tokenID, uint256 srcChainID, uint256 dstChainID) external view returns (SwapConfig memory) {
        return _swapConfig[tokenID][srcChainID][dstChainID];
    }

    function getFeeConfig(string memory tokenID, uint256 srcChainID, uint256 dstChainID) external view returns (FeeConfig memory) {
        return _feeConfig[tokenID][srcChainID][dstChainID];
    }

    function getActualSwapConfig(string memory tokenID, uint256 srcChainID, uint256 dstChainID) external view returns (SwapConfig memory config) {
        require(srcChainID > 0 && dstChainID > 0, "zero chainID");
        require(bytes(tokenID).length > 0, "empty tokenID");
        config = _swapConfig[tokenID][srcChainID][dstChainID];
        if (config.MaximumSwap > 0) {
            return config;
        }
        config = _swapConfig[tokenID][srcChainID][0];
        if (config.MaximumSwap > 0) {
            return config;
        }
        config = _swapConfig[tokenID][0][dstChainID];
        if (config.MaximumSwap > 0) {
            return config;
        }
        return _swapConfig[tokenID][0][0];
    }

    function getActualFeeConfig(string memory tokenID, uint256 srcChainID, uint256 dstChainID) external view returns (FeeConfig memory config) {
        require(srcChainID > 0 && dstChainID > 0, "zero chainID");
        require(bytes(tokenID).length > 0, "empty tokenID");
        config = _feeConfig[tokenID][srcChainID][dstChainID];
        if (config.MaximumSwapFee > 0) {
            return config;
        }
        config = _feeConfig[tokenID][srcChainID][0];
        if (config.MaximumSwapFee > 0) {
            return config;
        }
        config = _feeConfig[tokenID][0][dstChainID];
        if (config.MaximumSwapFee > 0) {
            return config;
        }
        return _feeConfig[tokenID][0][0];
    }

    function getCustomConfig(uint256 chainID, string memory key) external view returns (string memory) {
        return _customConfig[chainID][key];
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
        for (uint256 i = 0; i < chainIDs.length; i++) {
            delete _chainConfig[chainIDs[i]];
        }
    }

    function removeAllChainConfig() external onlyOwner {
        return removeChainConfig(_allChainIDs);
    }

    function setChainExtraConfig(uint256 chainID, string memory extra) external onlyOwner returns (bool) {
        require(chainID > 0, "zero chainID");
        _chainConfig[chainID].Extra = extra;
        return true;
    }

    function setTokenConfig(string memory tokenID, uint256 chainID, string memory tokenAddr, uint8 decimals, uint256 version, string memory routerContract, string memory extra) external onlyOwner returns (bool) {
        return _setTokenConfig(tokenID, chainID, TokenConfig(decimals, tokenAddr, version, routerContract, extra));
    }

    function removeTokenConfig(string memory tokenID, uint256[] memory chainIDs) public onlyOwner {
        for (uint256 i = 0; i < chainIDs.length; i++) {
            delete _tokenConfig[tokenID][chainIDs[i]];
        }
    }

    function removeAllTokenConfig(string memory tokenID) external onlyOwner {
        return removeTokenConfig(tokenID, _allChainIDs);
    }

    function setTokenRouterContract(string memory tokenID, uint256 chainID, string memory routerContract) external onlyOwner returns (bool) {
        require(chainID > 0, "zero chainID");
        require(bytes(tokenID).length > 0, "empty tokenID");
        _tokenConfig[tokenID][chainID].RouterContract = routerContract;
        return true;
    }

    function setTokenExtraConfig(string memory tokenID, uint256 chainID, string memory extra) external onlyOwner returns (bool) {
        require(chainID > 0, "zero chainID");
        require(bytes(tokenID).length > 0, "empty tokenID");
        _tokenConfig[tokenID][chainID].Extra = extra;
        return true;
    }

    function setSwapAndFeeConfig(
        string memory tokenID, uint256 srcChainID, uint256 dstChainID,
        uint256 maxSwap, uint256 minSwap, uint256 bigSwap,
        uint256 maxFee, uint256 minFee, uint256 feeRate
    ) external onlyOwner returns (bool) {
        return _setSwapConfig(tokenID, srcChainID, dstChainID, SwapConfig(maxSwap, minSwap, bigSwap))
            && _setFeeConfig(tokenID, srcChainID, dstChainID, FeeConfig(maxFee, minFee, feeRate));
    }

    function removeSwapAndFeeConfig(string memory tokenID, uint256 srcChainID, uint256 dstChainID) external onlyOwner {
        delete _swapConfig[tokenID][srcChainID][dstChainID];
        delete _feeConfig[tokenID][srcChainID][dstChainID];
    }

    function setSwapConfig(string memory tokenID, uint256 srcChainID, uint256 dstChainID, uint256 maxSwap, uint256 minSwap, uint256 bigSwap) external onlyOwner returns (bool) {
        return _setSwapConfig(tokenID, srcChainID, dstChainID, SwapConfig(maxSwap, minSwap, bigSwap));
    }

    function removeSwapConfig(string memory tokenID, uint256[] memory srcChainIDs, uint256[] memory dstChainIDs) public onlyOwner {
        for (uint256 i = 0; i < srcChainIDs.length; i++) {
            for (uint256 j = 0; j < dstChainIDs.length; j++) {
                delete _swapConfig[tokenID][srcChainIDs[i]][dstChainIDs[j]];
            }
        }
    }

    function removeAllSrcSwapConfig(string memory tokenID, uint256[] memory srcChainIDs) external onlyOwner {
        removeSwapConfig(tokenID, srcChainIDs, _allChainIDs);
    }

    function removeAllDestSwapConfig(string memory tokenID, uint256[] memory dstChainIDs) external onlyOwner {
        removeSwapConfig(tokenID, _allChainIDs, dstChainIDs);
    }

    function setFeeConfig(string memory tokenID, uint256 srcChainID, uint256 dstChainID, uint256 maxFee, uint256 minFee, uint256 feeRate) external onlyOwner returns (bool) {
        return _setFeeConfig(tokenID, srcChainID, dstChainID, FeeConfig(maxFee, minFee, feeRate));
    }

    function removeFeeConfig(string memory tokenID, uint256[] memory srcChainIDs, uint256[] memory dstChainIDs) public onlyOwner {
        for (uint256 i = 0; i < srcChainIDs.length; i++) {
            for (uint256 j = 0; j < dstChainIDs.length; j++) {
                delete _feeConfig[tokenID][srcChainIDs[i]][dstChainIDs[j]];
            }
        }
    }

    function removeAllSrcFeeConfig(string memory tokenID, uint256[] memory srcChainIDs) external onlyOwner {
        removeFeeConfig(tokenID, srcChainIDs, _allChainIDs);
    }

    function removeAllDestFeeConfig(string memory tokenID, uint256[] memory dstChainIDs) external onlyOwner {
        removeFeeConfig(tokenID, _allChainIDs, dstChainIDs);
    }

    function setCustomConfig(uint256 chainID, string memory key, string memory data) external onlyOwner returns (bool) {
        require(chainID > 0, "zero chainID");
        _customConfig[chainID][key] = data;
        return true;
    }

    function removeCustomConfig(uint256 chainID, string memory key) external onlyOwner {
        delete _customConfig[chainID][key];
    }

    function setMPCPubkey(string memory addr, string memory pubkey) external onlyOwner returns (bool) {
        require(bytes(addr).length > 0, "empty address");
        require(bytes(pubkey).length > 0, "empty pubkey");
        _mpcPubkey[addr] = pubkey;
        return true;
    }

    function removeMPCPubkey(string memory addr) external onlyOwner {
        delete _mpcPubkey[addr];
    }

    function addChainID(uint256 chainID) external onlyOwner returns (bool) {
        require(!isChainIDExist(chainID), "chain ID exist");
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
            }
        }
    }

    function addTokenID(string memory tokenID) external onlyOwner returns (bool) {
        require(!isTokenIDExist(tokenID), "token ID exist");
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
            }
        }
    }

    function _isStringEqual(string memory s1, string memory s2) internal pure returns (bool) {
        return bytes(s1).length == bytes(s2).length && keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function _setChainConfig(uint256 chainID, ChainConfig memory config) internal checkChainconfig(config) returns (bool) {
        require(chainID > 0, "zero chainID");
        _chainConfig[chainID] = config;
        if (!isChainIDExist(chainID)) {
            _allChainIDs.push(chainID);
            _allChainIDsMap[chainID] = true;
        }
        return true;
    }

    function _setTokenConfig(string memory tokenID, uint256 chainID, TokenConfig memory config) internal checkTokenConfig(config) returns (bool) {
        require(chainID > 0, "zero chainID");
        require(bytes(tokenID).length > 0, "empty tokenID");
        _tokenConfig[tokenID][chainID] = config;
        if (!isTokenIDExist(tokenID)) {
            _allTokenIDs.push(tokenID);
            _allTokenIDsMap[tokenID] = true;
        }
        _setMultichainToken(tokenID, chainID, config.ContractAddress);
        return true;
    }

    function _setSwapConfig(string memory tokenID, uint256 srcChainID, uint256 dstChainID, SwapConfig memory config) internal checkSwapConfig(config) returns (bool) {
        require(bytes(tokenID).length > 0, "empty tokenID");
        _swapConfig[tokenID][srcChainID][dstChainID] = config;
        return true;
    }

    function _setFeeConfig(string memory tokenID, uint256 srcChainID, uint256 dstChainID, FeeConfig memory config) internal checkFeeConfig(config) returns (bool) {
        require(bytes(tokenID).length > 0, "empty tokenID");
        _feeConfig[tokenID][srcChainID][dstChainID] = config;
        return true;
    }

    function _setMultichainToken(string memory tokenID, uint256 chainID, string memory token) internal {
        require(chainID > 0, "zero chainID");
        require(bytes(tokenID).length > 0, "empty tokenID");
        MultichainToken[] storage _mcTokens = _allMultichainTokens[tokenID];
        for (uint256 i = 0; i < _mcTokens.length; ++i) {
            if (_mcTokens[i].ChainID == chainID) {
                string memory oldToken = _mcTokens[i].TokenAddress;
                if (!_isStringEqual(token, oldToken)) {
                    _mcTokens[i].TokenAddress = token;
                    _allMultichainTokensMap[tokenID][chainID] = token;
                    _tokenIDMap[chainID][oldToken] = "";
                    _tokenIDMap[chainID][token] = tokenID;
                }
                return;
            }
        }
        _mcTokens.push(MultichainToken(chainID, token));
        _tokenIDMap[chainID][token] = tokenID;
        _allMultichainTokensMap[tokenID][chainID] = token;
    }
}