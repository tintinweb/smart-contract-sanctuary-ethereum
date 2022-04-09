//SPDX-License-Identifier: AGPL-3.0-or-later
// Boxer
// Boxer is an omnichain NFT, Produced by dLab.
pragma solidity ^0.8.9;
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ILayerZeroEndpoint.sol";
import "./ILayerZeroReceiver.sol";
import "./ILayerZeroUserApplicationConfig.sol";

contract Boxer is
    Ownable,
    ERC721Enumerable,
    ILayerZeroReceiver,
    ILayerZeroUserApplicationConfig
{
    string private baseURI;
    uint256 limit = 1;
    uint256 counter = 0;
    uint256 nextId = 0;
    uint256 currentSupply = 200;
    uint256 maxId = 0;
    uint256 gas = 350000;
    ILayerZeroEndpoint public endpoint;
    mapping(uint256 => bytes) public uaMap;

    event ReceiveNFT(
        uint16 _srcChainId,
        address _from,
        uint256 _tokenId,
        uint256 counter
    );

    constructor(
        string memory baseURI_,
        address _endpoint,
        uint256 _startId,
        uint256 _total,
        uint256 _currentSupply
    ) ERC721("Boxer", "Boxer") {
        endpoint = ILayerZeroEndpoint(_endpoint);
        baseURI = baseURI_;
        nextId = _startId;
        maxId = _total;
        currentSupply = _currentSupply;
    }

    function mintSeed(uint256 amount) external onlyOwner {
        require(nextId + 1 <= maxId, "Max supply exceed");
        require(nextId + amount <= currentSupply, "Supply exceed");
        for (uint256 index = 0; index < amount; index++) {
            nextId += 1;
            _safeMint(msg.sender, nextId);
            counter += 1;
        }
    }

    function mint() external payable {
        require(nextId + 1 <= currentSupply, "Mint ended");
        require(nextId + 1 <= maxId, "Max supply exceed");
        require(
            (balanceOf(msg.sender) < limit),
            "Account Balance on Current chain exceeds limit"
        );
        nextId += 1;
        _safeMint(msg.sender, nextId);
        counter += 1;
    }

    function crossChain(uint16 _dstChainId, uint256 tokenId) public payable {
        require(msg.sender == ownerOf(tokenId), "Only owner call cross chain");
        require(uaMap[_dstChainId].length > 0, "Invalid chainId");
        // burn NFT
        _burn(tokenId);
        counter -= 1;
        bytes memory payload = abi.encode(msg.sender, tokenId);

        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(version, gas);

        (uint256 messageFee, ) = endpoint.estimateFees(
            _dstChainId,
            address(this),
            payload,
            false,
            adapterParams
        );
        require(msg.value >= messageFee, "Message Fee Not Enough");

        endpoint.send{value: msg.value}(
            _dstChainId,
            uaMap[_dstChainId],
            payload,
            payable(msg.sender),
            address(0x0),
            adapterParams
        );
    }

    function withdraw(uint256 amount) external onlyOwner {
        (bool sent, ) = payable(owner()).call{value: amount}("");
        require(sent, "Error!");
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes memory _from,
        uint64,
        bytes memory _payload
    ) external override {
        require(msg.sender == address(endpoint));
        require(
            _from.length == uaMap[_srcChainId].length &&
                keccak256(_from) == keccak256(uaMap[_srcChainId]),
            "Call must send from valid user application"
        );
        address from;
        assembly {
            from := mload(add(_from, 20))
        }
        (address toAddress, uint256 tokenId) = abi.decode(
            _payload,
            (address, uint256)
        );

        // mint the tokens
        _safeMint(toAddress, tokenId);
        counter += 1;
        emit ReceiveNFT(_srcChainId, toAddress, tokenId, counter);
    }

    function estimateFees(
        uint16 _dstChainId,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee) {
        return
            endpoint.estimateFees(
                _dstChainId,
                address(this),
                _payload,
                _payInZRO,
                _adapterParams
            );
    }

    function setUaAddress(uint256 _dstChainId, bytes calldata _uaAddress)
        public
        onlyOwner
    {
        uaMap[_dstChainId] = _uaAddress;
    }

    function setEndpoint(address _endpoint) public onlyOwner {
        endpoint = ILayerZeroEndpoint(_endpoint);
    }

    function setLimit(uint256 _limit) public onlyOwner {
        limit = _limit;
    }

    function setCurrentSupply(uint256 _supply) public onlyOwner {
        currentSupply = _supply;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setGas(uint256 _gas) external onlyOwner {
        gas = _gas;
    }

    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external override onlyOwner {
        endpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        endpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        endpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        override
        onlyOwner
    {
        endpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }
}