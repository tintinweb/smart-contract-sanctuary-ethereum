/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient,uint256 amount ) external returns (bool);
}

interface IERC721 {
    function totalSupply() external view returns (uint256);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

contract Receiver {
    address public owner;
    event Received(address caller, uint amount, string message);
    event Response(bool success, bytes data);
  
    constructor(address _owner) {
        owner = _owner;
    }


    function execute(address _addr, bytes memory _message) public payable  {
        require(owner== msg.sender,"Ownable: caller is not the owner");
        (bool success, bytes memory data) = _addr.call{value: msg.value}(_message);
        emit Response(success, data);


    }

    function sweepToken(address token, address payable recipient) external {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        IERC20(token).transfer(payable(recipient), IERC20(token).balanceOf(address(this)));

    }

    function sweepTokenNFT(address token, address payable recipient, uint256 tokenId) external {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        IERC721(token).transferFrom(address(this),payable(recipient), tokenId);

    }

    function withdrawETH(address payable recipient) external {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        payable(recipient).transfer(address(this).balance);
    }

    receive() payable  external {

    }
}

contract Caller {

    address public owner;
    Receiver [] public Receivers;
    event Response(bool success, bytes data);

    // Let's imagine that contract Caller does not have the source code for the
    // contract Receiver, but we do know the address of contract Receiver and the function to call.
    constructor() {
        owner = msg.sender;
    }

    function createReceiver(uint _n) external {
        require(owner== msg.sender,"Ownable: caller is not the ownerr");

        for (uint256 i = 0; i < _n; i++) {
        // create with salt
        Receiver receiver = new Receiver{salt: bytes32(uint256(i))}(address(this));
        // append to proxies
        Receivers.push(receiver);
        }
        

    } 


    function testBatch(address _target, bytes memory _message) public payable {
        require(owner== msg.sender,"not owner");
        // You can send ether and specify a custom gas amount

        for(uint i=0;i<Receivers.length;i++){
            address receiver = address(Receivers[i]);
            (bool success, bytes memory data) = receiver.call(abi.encodeWithSignature("execute(address,bytes)", _target,_message)
            );
            emit Response(success, data);

      
        }  
    }

    receive() external payable {

    }
}