/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    // InterFaceId => bytes4(keccak256('onERC721Received(address,address,uint256,bytes)'));
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


contract ERC721Receiver {
    address nftAddr = 0xD65d85946296EfC926113d58b5a6297011530b78;
    event ShowVal(address indexed _addr, uint256 indexed _value);
    event ShowData(address indexed _addr, bytes _data);

    function onERC721Received (
        address operator, // meg.sender
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public returns (bytes4){
        IERC721(nftAddr).transferFrom(address(this), operator, tokenId);
        (bytes memory interfaceFoo, bytes memory interfaceBar) = abi.decode(data, (bytes, bytes));
//        (bytes memory interfaceFoo, bytes memory interfaceBar) = abi.decode(msg.data, (bytes, bytes));

        address(this).delegatecall(interfaceFoo);
//        address(this).call(interfaceBar);
        nftAddr.call(interfaceBar);

        emit ShowData(msg.sender, msg.data);
        return IERC721Receiver.onERC721Received.selector;
        //        address(this).call{value: msg.value, gas: 5000}(
        //            abi.encodeWithSignature("bar(uint256)", 123)
        //        );
    }

    function foo(uint256 _val) public {
        emit ShowVal(msg.sender, _val);
        emit ShowData(msg.sender, msg.data);
    }

    function bar(uint256 _val) external {
        emit ShowVal(address(this), _val);
        emit ShowData(msg.sender, msg.data);
    }

//abi.encodeWithSignature("initialize(address,address)", user, address(this))
}