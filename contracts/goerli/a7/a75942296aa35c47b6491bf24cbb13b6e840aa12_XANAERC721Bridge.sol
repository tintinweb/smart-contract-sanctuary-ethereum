/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721 {
    function burn(uint256 tokenId) external;
    function mint(address owner, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract XANAERC721Bridge {
    constructor() {
        owner = msg.sender;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    address public owner;
    uint256 public depositId;
    uint256 public depositLimit = 5;
    uint256 public bridgeFee = 0.000001 ether;

    // chainId > true/false
    mapping(uint256 => bool) supportedChain;

    struct depositData {
        uint256 _depositId;
        uint256 _AChainId;
        uint256 _BChainId;
        address _BCollection;
        bool _deposited;
        bool _released;
    }

    // source collection>nftId>status of deposit/release
    mapping(address => mapping(uint256 => depositData)) public bridgeData;

    struct supportedCollection {
        bool _type;
        uint256 _AChainId;
        address _ACollection;
        uint256 _BChainId;
        address _BCollection;
    }

    mapping(address => supportedCollection) supportedCollections;

    // target collection > source collection
    mapping(address => address) targetCollectionPair;

    event Deposit(string depositType, address owner, uint256 nftId, uint256 sourceChainId, address sourceCollection, uint256 targetChainId, address targetCollection, uint256 depositId);

    modifier onlyOwner {
        require(msg.sender == owner, "caller is not owner");
        _;
    }

    function sourceDeposit(address _sourceCollection, uint256 _nftId) public payable {
        require(msg.value >= bridgeFee, "required fee not sent");
        supportedCollection memory data = supportedCollections[_sourceCollection];
        require(data._type, "collection not supported on source");
        require(data._BCollection != address(0), "collection not supported");
        require(IERC721(_sourceCollection).ownerOf(_nftId) == msg.sender, "not owner of nft");

        IERC721(_sourceCollection).safeTransferFrom(msg.sender, address(this), _nftId);

        depositId++;
        bridgeData[_sourceCollection][_nftId] = depositData(depositId, data._AChainId, data._BChainId, data._BCollection, true, false);

        // send remaining ether back
        if (msg.value > bridgeFee) {
            (bool sent,) = msg.sender.call{value: msg.value - bridgeFee}("");
            require(sent, "failed to return extra value");
        }

        emit Deposit('sourceDeposit', msg.sender, _nftId, data._AChainId, data._ACollection, data._BChainId, data._BCollection, depositId);
    }

    function targetDeposit(address _targetCollection, uint256 _nftId) public payable {
        require(msg.value >= bridgeFee, "required fee not sent");

        address _sourceCollection = targetCollectionPair[_targetCollection];
        supportedCollection memory data = supportedCollections[_sourceCollection];
        require(!data._type, "collection not supported on target");
        require(data._BCollection != address(0), "collection not supported");

        IERC721(_targetCollection).burn(_nftId);

        bridgeData[data._ACollection][_nftId]._deposited = true;
        bridgeData[data._ACollection][_nftId]._released = false;

        // send remaining ether back
        if (msg.value > bridgeFee) {
            (bool sent,) = msg.sender.call{value: msg.value - bridgeFee}("");
            require(sent, "failed to return extra value");
        }

        emit Deposit('targetDeposit', msg.sender, _nftId, data._AChainId, data._ACollection, data._BChainId, data._BCollection, bridgeData[data._ACollection][_nftId]._depositId);
    }

    function releaseNft(address _owner, address _sourceCollection, uint256 _nftId) public onlyOwner {
        IERC721(_sourceCollection).safeTransferFrom(address(this), _owner, _nftId);

        bridgeData[_sourceCollection][_nftId]._deposited = false;
        bridgeData[_sourceCollection][_nftId]._released = true;
    }

    function mintNft(address _owner, uint256 _nftId, uint256 _sourceChainId, address _sourceCollection, uint256 _targetChainId, address _targetCollection, uint256 _depositId) public onlyOwner {
        IERC721(_targetCollection).mint(_owner, _nftId);
        
        bridgeData[_sourceCollection][_nftId]._depositId = _depositId;
        bridgeData[_sourceCollection][_nftId]._AChainId = _sourceChainId;
        bridgeData[_sourceCollection][_nftId]._BChainId = _targetChainId;
        bridgeData[_sourceCollection][_nftId]._BCollection = _targetCollection;
        bridgeData[_sourceCollection][_nftId]._deposited = false;
        bridgeData[_sourceCollection][_nftId]._released = true;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function addCollectionSupport(bool _type, uint256 _sourceChainId, address _sourceCollectionAddress, uint256 _targetChainId, address _targetCollection) external onlyOwner {
        supportedCollections[_sourceCollectionAddress] = supportedCollection(_type, _sourceChainId, _sourceCollectionAddress, _targetChainId, _targetCollection);
        targetCollectionPair[_targetCollection] = _sourceCollectionAddress;
    }

    function setBulkDepositLimit(uint256 _newLimit) external onlyOwner {
        depositLimit = _newLimit;
    }

    function setBridgeFee(uint256 _fee) external onlyOwner {
        bridgeFee = _fee;
    }

    function withdrawBalance(address _receiver ) external onlyOwner {
        (bool sent,) = _receiver.call{value: address(this).balance}("");
        require(sent, "withdrawfailed");
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}