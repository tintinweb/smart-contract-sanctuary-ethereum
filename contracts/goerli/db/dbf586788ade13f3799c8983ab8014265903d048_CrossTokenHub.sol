/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract CrossTokenHub {

    address public owner;
    address public admin;

    struct Mirror {
        uint64 sequence;
        address dstContractAddr;
    }

    mapping(bytes32 => bool) public sequenced;
    mapping(bytes32 => Mirror) public mirrors;

    event TransferOut(uint64 seq, uint16 dstChainId, address indexed dstContractAddr, address indexed recipient, uint256 amount);
    event TransferIn(uint64 seq, uint16 srcchainId, address indexed contractAddr, address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(owner == msg.sender || admin == msg.sender, "Caller is not the admin");
        _;
    }

    constructor() {
        owner = msg.sender;
        admin = msg.sender;
    }

    function setAdmin(address newAdmin) public onlyOwner {
        admin = newAdmin;
    }

    function addMirrorToken(address contractAddr, address dstContractAddr, uint16 dstChainId) public onlyOwner {
        bytes32 mkey = getMirrorKey(contractAddr, dstChainId);
        require(mirrors[mkey].dstContractAddr == address(0), "Repeat binding");
        require(dstContractAddr != address(0) && dstChainId > 0, "Invalid params");
        mirrors[mkey].dstContractAddr = dstContractAddr;
    }

    function delMirrorToken(address contractAddr, uint16 dstChainId) public onlyOwner {
        bytes32 mkey = getMirrorKey(contractAddr, dstChainId);
        require(mirrors[mkey].dstContractAddr != address(0), "No mirror");
        mirrors[mkey].dstContractAddr = address(0);
    }

    function transferOut(uint16 dstChainId, address contractAddr, uint amount, address recipient) public {
        bytes32 mkey = getMirrorKey(contractAddr, dstChainId);
        Mirror storage mirror = mirrors[mkey];
        require(mirror.dstContractAddr != address(0), "No binding token");
        uint64 seq = mirror.sequence + 1;
        mirror.sequence = seq;
        IERC20(contractAddr).transferFrom(msg.sender, address(this), amount);
        emit TransferOut(seq, dstChainId, mirror.dstContractAddr, recipient, amount);
    }

    function transferIn(uint64 seq, uint16 srcChainId, address contractAddr, uint amount, address recipient) public onlyOwner {
        bytes32 mkey = getMirrorKey(contractAddr, srcChainId);      
        bytes32 skey = getSequencedKey(mkey, seq);
        require(seq > 0 && !sequenced[skey], "Invalid sequence");
        sequenced[skey] = true;
        Mirror storage mirror = mirrors[mkey];
        require(mirror.dstContractAddr != address(0), "No binding token");

        
        IERC20(contractAddr).transfer(recipient, amount);
        emit TransferIn(seq, srcChainId, contractAddr, recipient, amount);
    }

    function getMirrorKey(address contractAddr, uint16 chainId) public pure returns(bytes32 key){
        uint cid = chainId * 2 ** 240;
        assembly{
            let addr := and(contractAddr, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            key := or(cid, addr)
        }
    }

    function getSequencedKey(bytes32 mirrorKey, uint64 seq) public pure returns(bytes32 key){
        uint sid = seq * 2 ** 176;
        assembly{
            key := or(mirrorKey, sid)
        }
    }

}