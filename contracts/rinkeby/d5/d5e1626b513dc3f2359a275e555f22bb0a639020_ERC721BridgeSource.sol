/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


contract ERC721Holder is IERC721Receiver {
   
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}



contract ERC721BridgeSource is ERC721Holder {
    address public fallbackContract;
    uint8 public immutable flag = 0;

    address public fromCaller; // address of the caller from the source chain
    uint256 public fromChainId; // chain id of the source chain
    address public gateway;

    constructor(
        address _gateway,
        address _fromCaller,
        uint256 _fromChainId,
        address _fallbackContract
    ) {
        gateway = _gateway;
        fromCaller = _fromCaller;
        fromChainId = _fromChainId;
        fallbackContract = _fallbackContract;
    }

    modifier onlyGateway() {
        address _executor = IGateway(gateway).executor();
        (address _fromCaller, uint256 _fromChainId, ) = IExecutor(_executor).context();
        require(fromCaller == _fromCaller, "!caller");
        require(fromChainId == _fromChainId, "!chainId");
        _;
    }

    function bridgeIn(address _token, uint256 _tokenId) external {
        IERC721(_token).safeTransferFrom(address(msg.sender), address(this), _tokenId);

        ICallProxy(gateway).anyCall(
            fromCaller, // contract address on the destination chain
            abi.encode(address(msg.sender), _token, _tokenId), // sending the encoded bytes of the string msg and decode on the destination chain
            fallbackContract, // 0x as fallback address because we don't have a fallback function
            fromChainId, // chainid of polygon
            flag // Using 0 flag to pay fee on destination chain
        );
    }

    function anyExecute(bytes memory _data) external onlyGateway returns (bool success, bytes memory result) {
        (address _account, address _token, uint256 _tokenId) = abi.decode(_data, (address, address, uint256));

        IERC721(_token).safeTransferFrom(address(this), address(_account), _tokenId);

        success = true;
        result = "";
    }
}

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


interface IERC721 is IERC165 {
  
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

   
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    
    function approve(address to, uint256 tokenId) external;

    
    function setApprovalForAll(address operator, bool _approved) external;

    
    function getApproved(uint256 tokenId) external view returns (address operator);

   
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}





interface ICallProxy {
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    ) external payable;
}


interface IExecutor {
    function context()
        external
        returns (
            address from,
            uint256 fromChainID,
            uint256 nonce
        );
}



interface IGateway {
    function executor() external view returns (address executor);
}