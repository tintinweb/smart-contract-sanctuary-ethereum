// SPDX-License-Identifier: MIT

/*
 * Created by masataka.eth (@masataka_net)
 */

pragma solidity >=0.7.0 <0.9.0;

contract WalletFamily {
    mapping (address => address[]) public approveFamilys;
    mapping (address => address[]) public fixFamilys;

    event approvedChild(address indexed parent, address indexed child);
    event admitFixChild(address indexed parent, address indexed child);

    //////////////////////////////////////
    // intaernal
    //////////////////////////////////////
    // approve ----------------------------
    function _addApproveFamily(address _parent, address _child) internal {
        approveFamilys[_parent].push(_child);
    }

    function _deleteApprove(address _parent, address _child) internal returns (bool){
        for(uint256 i = 0; i < approveFamilys[_parent].length; i++){
            if(approveFamilys[_parent][i] == _child){
                delete approveFamilys[_parent][i];
                return true;
            } 
        }
        return false;
    }

    function _getApproveList(address _parent) internal view returns (address[] memory) {
        return  approveFamilys[_parent];
    }

    function _getApprove(address _parent,address _child) internal view returns (bool){
        for(uint256 i = 0; i < approveFamilys[_parent].length; i++){
            if(approveFamilys[_parent][i] == _child){
                return true;
            } 
        }
        return false;
    }

    // fix ----------------------------
    function _addFixFamily(address _parent, address _child) internal {
        fixFamilys[_parent].push(_child);
    }

    function _getFixList(address _parent)internal view returns (address[] memory) {
        return fixFamilys[_parent];
    }

    function _getFix(address _parent, address _child) internal view returns (bool) {
        for (uint256 i = 0; i < fixFamilys[_parent].length; i++) {
            if (fixFamilys[_parent][i] == _child) {
                return true;
            }
        }
        return false;
    }

    //////////////////////////////////////
    // external・public
    //////////////////////////////////////
    // approve ----------------------------
    function approveChild(address _parent,bytes32 _nonce, bytes memory _signature) external {
        require(_parent != address(0),"address is no valid");
        require(isVerify(_parent,_nonce,_signature) == true,"coupon is no valid");
        _addApproveFamily(_parent,msg.sender);

        emit approvedChild(_parent,msg.sender);
    }

    function deleteApprove(address _parent,address _child) external returns (bool){
        require(_parent == msg.sender,"no parent");
        return _deleteApprove(_parent,_child);
    }

    function getApproveList() external view returns(address[] memory) {
        return _getApproveList(msg.sender);
    }

    // fix ----------------------------
    function fixChild(address _child) external{
        require(_child != address(0),"address is no valid");
        require(_getApprove(msg.sender,_child) == true,"no aprove");
        _deleteApprove(msg.sender,_child);
        _addFixFamily(msg.sender,_child);

        emit admitFixChild(msg.sender,_child);
    }

    function isChild(address _child) external view returns (bool) {
        return _getFix(msg.sender,_child);
    }

    function isChildPair(address _parent, address _child) external view returns (bool) {
        return _getFix(_parent,_child);
    }

    function getFixList(address _parent) external view returns (address[] memory) {
        return _getFixList(_parent);
    }

    // VerifySignature ----------------------------
    function getMessageHash(address _child,address _parent,bytes32 _nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_child, _parent,_nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function isVerify(address _parent,bytes32 _nonce,bytes memory signature) public view returns (bool) {
        bytes32 messageHash = getMessageHash(msg.sender, _parent,_nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) ==  msg.sender;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s,uint8 v){
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}