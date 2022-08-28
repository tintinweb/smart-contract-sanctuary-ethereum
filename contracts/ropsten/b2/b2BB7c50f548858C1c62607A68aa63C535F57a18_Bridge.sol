// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

// bridge ropstein 0xcC9bfC6777450C54c4dc001826EF9248b429b6B8 new 0xb2BB7c50f548858C1c62607A68aa63C535F57a18 / token 0xcc5c7DEECeC44f42bbc9F9812539e3428A802aEF
// bridge bsc test 0x8aE6D16ab429DD24b255d90Bdb4D57604f015EEB / token 0xeE38a93fEa9AaDcf619119D0230deB1eBAdE5704

contract Bridge {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    struct TokenTx {
        address token;
        address from;
        address to;
        uint256 amount;
        uint256 fromChain;
        uint256 toChain;
    }

    struct EthTx {
        address from;
        address to;
        uint256 amount;
        uint256 fromChain;
        uint256 toChain;
    }

    address owner;
    uint256 contractNonce;
    uint256 minRequiredSigs = 3;

    mapping(address => bool) private signers;
    mapping(address => mapping(uint256 => bool)) private processedNonces;
    mapping(address => uint256) public nonce;

    mapping(address => bool) public supportedTokens;
    mapping(uint256 => bool) public supportedChains;

    mapping(address => uint256) private userLastBlock;

    mapping(bytes => TokenTx) public processedTokenTxs;

    mapping(bytes => EthTx) public processedEthTxs;

    mapping(bytes32 => mapping(address => bool)) userSignedTxs;

    mapping(bytes => uint256) public CurrentSigns;

    event ExecuteBridge(address indexed token, address indexed from, address indexed to, uint256 amount, uint256 fromChain, uint256 toChain, uint256 nonce);
    event ExecuteBridgeETH(address indexed from, address indexed to, uint256 amount, uint256 fromChain, uint256 toChain, uint256 nonce);
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

    function bridge(address _token, address _to, uint256 _amount, uint256 _destChainId) public {
        // require(verify(data, signature) == msg.sender, "Signature not verified");
        require(userLastBlock[msg.sender] < block.number, "Cannot send multiple transaction in the same block");
        require(supportedTokens[_token], "Token not supported");
        require(supportedChains[_destChainId], "Chain not supported");
        userLastBlock[msg.sender] = block.number;
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        

        processedNonces[msg.sender][nonce[msg.sender]] = true;
        emit ExecuteBridge(_token, msg.sender, _to, _amount, block.chainid, _destChainId, nonce[msg.sender]);
        nonce[msg.sender] += 1;
    }

    function bridgeETH(address _to, uint256 _destChainId) public payable {
        // require(verify(data, signature) == msg.sender, "Signature not verified");
        require(userLastBlock[msg.sender] < block.number, "Cannot send multiple transaction in the same block");
        require(supportedChains[_destChainId], "Chain not supported");
        require(msg.value > 0, "Message value is lower than 0");
        userLastBlock[msg.sender] = block.number;
        
        processedNonces[msg.sender][nonce[msg.sender]] = true;
        
        emit ExecuteBridgeETH(msg.sender, _to, msg.value, block.chainid, _destChainId, nonce[msg.sender]);
        nonce[msg.sender] += 1;
    }

    function signTx(bytes calldata _hash, address _from, address _token, address _to, uint256 _amount, uint256 _fromChain) public onlySigners() {
        bytes32 txHash = keccak256(abi.encodePacked(_hash,_token,_from,_to,_amount,_fromChain));
        require(!userSignedTxs[txHash][msg.sender], "Transaction already signed");
        //require(processedTokenTxs[_hash], "Transaction already executed");
        CurrentSigns[_hash]+=1;

        if(CurrentSigns[_hash] >= minRequiredSigs) {
            sendToken(_token, _from, _to, _amount, _hash, _fromChain);
        }
        userSignedTxs[txHash][msg.sender] = true;
    }

    function signTxEth(bytes calldata _hash, address _from, address _to, uint256 _amount, uint256 _fromChain) public onlySigners() {
        bytes32 txHash = keccak256(abi.encodePacked(_hash,_from,_to,_amount,_fromChain));
        require(!userSignedTxs[txHash][msg.sender], "Transaction already signed");
        // require(!processedEthTxs[_hash], "Transaction already executed");
        CurrentSigns[_hash]+=1;
        
        if(CurrentSigns[_hash] >= minRequiredSigs) {
            sendEth(_to, _from, _amount, _hash, _fromChain);
        }

        userSignedTxs[txHash][msg.sender] = true;
    }

    function send(address _token, address _to, uint256 _amount) private onlySigners() {
        IERC20(_token).safeTransferFrom(address(this), _to, _amount);
    }

    function sendToken(address _token, address _from, address _to, uint256 _amount, bytes calldata _hash, uint256 _fromChain) private onlySigners() {
        IERC20(_token).safeTransfer(_to, _amount);
        processedTokenTxs[_hash] = TokenTx(_token, _from, _to, _amount, _fromChain, block.chainid);
        emit SendToken(true);
    }

    function sendEth(address _to, address _from, uint256 _amount, bytes calldata _hash, uint256 _fromChain) private onlySigners() {
        (bool success, ) = _to.call{value: _amount}("");
        if(success) {
            processedEthTxs[_hash] = EthTx(_from, _to, _amount, _fromChain, block.chainid);
            emit SendEth(success);
        }
    }


    function verify(bytes32 data, bytes memory signature) public pure returns (address)  {

        return data.recover(signature);
    }

    function setSupportedTokens(address _token, bool _state) public onlyOwner() {
        supportedTokens[_token] = _state;
    }

    function setSupportedChains(uint256 _chainId, bool _state) public onlyOwner() {
        supportedChains[_chainId] = _state;
    }

    function setOwner(address _owner) public onlyOwner() {
        owner = _owner;
    }

    function setSigners(address _signer, bool _state) public onlyOwner() {
        signers[_signer] = _state;
    }

    function setMinSigners(uint256 _num) public onlyOwner() {
        require(_num >= 3, "Number of required signers too low");
        minRequiredSigs = _num;
    }

}