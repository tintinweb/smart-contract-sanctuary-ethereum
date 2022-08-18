// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract Bridge {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    struct Tx {
        address token;
        address to;
        uint256 amount;
        uint256 fromChian;
        uint256 toChain;
        uint256 nonce;
    }

    struct TxEth {
        address to;
        uint256 amount;
        uint256 fromChian;
        uint256 toChain;
        uint256 nonce;
    }

    address owner;
    uint256 contractNonce;
    uint256 requiredSigs = 3;

    mapping(address => bool) private signers;
    mapping(address => mapping(uint256 => bool)) private processedNonces;
    mapping(address => uint256) public nonce;

    mapping(address => bool) public supportedTokens;
    mapping(uint256 => bool) public supportedChains;

    mapping(address => uint256) private userLastBlock;

    mapping(bytes => bool) public processedTxs;

    mapping(bytes => mapping(address => bool)) userSignedTxs;

    mapping(bytes => uint256) public test;

    event ExecuteBridge(address token, address to, uint256 amount, uint256 fromChian, uint256 toChain, uint256 nonce);
    event ExecuteBridgeETH(address to, uint256 amount, uint256 fromChian, uint256 toChain, uint256 nonce);
    event SendEth(bool success);
    event SendToken(bool success);

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not the owner");
        _;
    }

    modifier onlySigners() {
        require(signers[msg.sender] || msg.sender == owner, "Sender is not a signer or the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    function bridge(address _token, address _to, uint256 _amount/*, bytes32 data*/, uint256 _destChainId/*,bytes memory signature*/) public {
        // require(verify(data, signature) == msg.sender, "Signature not verified");
        require(userLastBlock[msg.sender] < block.number, "Cannot send multiple transaction in the same block");
        require(supportedTokens[_token], "Token not supported");
        require(supportedChains[_destChainId], "Chain not supported");
        userLastBlock[msg.sender] = block.number;
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        

        processedNonces[msg.sender][nonce[msg.sender]] = true;
        emit ExecuteBridge(_token, _to, _amount, block.chainid, _destChainId, nonce[msg.sender]);
        nonce[msg.sender] += 1;
    }

    function bridgeETH(address _to/*, bytes32 data*/, uint256 _destChainId/*,bytes memory signature*/) public payable {
        // require(verify(data, signature) == msg.sender, "Signature not verified");
        require(userLastBlock[msg.sender] < block.number, "Cannot send multiple transaction in the same block");
        require(supportedChains[_destChainId], "Chain not supported");
        require(msg.value > 0, "Message value is lower than 0");
        userLastBlock[msg.sender] = block.number;
        
        processedNonces[msg.sender][nonce[msg.sender]] = true;
        nonce[msg.sender] += 1;
        emit ExecuteBridgeETH(_to, msg.value, block.chainid, _destChainId, nonce[msg.sender]);
        
    }

    function signTx(bytes calldata _hash, address _token, address _to, uint256 _amount) public onlySigners() {
        require(!userSignedTxs[_hash][msg.sender], "Transaction already signed");
        require(!processedTxs[_hash], "Transaction already executed");
        test[_hash]+=1;
        userSignedTxs[_hash][msg.sender] = true;
        if(test[_hash] >= requiredSigs) {
            sendToken(_token, _to, _amount, _hash);
        }
        userSignedTxs[_hash][msg.sender] = true;
    }

    function signTxEth(bytes calldata _hash, address _to, uint256 _amount) public onlySigners() {
        require(!userSignedTxs[_hash][msg.sender], "Transaction already signed");
        require(!processedTxs[_hash], "Transaction already eexecuted");
        test[_hash]+=1;
        
        if(test[_hash] >= requiredSigs) {
            sendEth(_to, _amount, _hash);
        }
        userSignedTxs[_hash][msg.sender] = true;
    }

    function send(address _token, address _to, uint256 _amount) private onlySigners() {
        IERC20(_token).safeTransferFrom(address(this), _to, _amount);
    }

    function sendToken(address _token, address _to, uint256 _amount, bytes calldata _hash) private onlySigners() {
        IERC20(_token).safeTransfer(_to, _amount);
        processedTxs[_hash] = true;
        emit SendToken(true);
    }

    function sendEth(address _to, uint256 _amount, bytes calldata _hash) private onlySigners() {
        (bool success, ) = _to.call{value: _amount}("");
        if(success) {
            processedTxs[_hash] = true;
            emit SendEth(success);
        }
    }


    function verify(bytes32 data, bytes memory signature) public pure returns (address)  {

        return data.recover(signature);
    }

    function setSupportedTokens(address _token) public onlyOwner() {
        supportedTokens[_token] = true;
    }

    function setSupportedChains(uint256 _chainId) public onlyOwner() {
        supportedChains[_chainId] = true;
    }

    function setOwner(address _owner) public onlyOwner() {
        owner = _owner;
    }

    function setSigners(address _signer) public onlyOwner() {
        signers[_signer] = true;
    }

}