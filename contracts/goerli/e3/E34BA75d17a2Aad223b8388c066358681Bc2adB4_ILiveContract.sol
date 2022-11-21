/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT
interface IERC20 {
   
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

}

abstract contract VerifySignature {
    function getMessageHash(
        address _to,
        uint256 _packageId,
        uint256 _userId,
        uint256 _amount,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _packageId, _userId, _amount, _nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verifySignature(
        address _signer,
        address _to,
        uint256 _packageId,
        uint256 _userId,
        uint256 _amount,
        uint256 _nonce,
        bytes memory _signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _packageId, _userId, _amount, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, _signature) == _signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory _sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
    }
}

contract ILiveContract is VerifySignature {
    address public erc20Address;
    address public adminReceiver;
    address public signerAddress;
    mapping(address => uint256) public nonces;

    event Transfer(
        uint256 packageId,
        uint256 amount,
        address walletAddress,
        uint256 userId
    );

    function setERC20Address(address _address) external {
        require(_address != address(0x0), "Address must be different 0x0");
        erc20Address = _address;
    }

    function setAdminReceiver(address _address) external {
        require(_address != address(0x0), "Address must be different 0x0");
        adminReceiver = _address;
    }

    function setSignerAddress(address _address) external {
        require(_address != address(0x0), "Address must be different 0x0");
        signerAddress = _address;
    }

    function transferByWalletUser(
        uint256 packageId,
        uint256 userId,
        uint256 amount,
        bytes memory signature
    ) external {
        address sender = msg.sender;

        require(
            verifySignature(
                signerAddress,
                msg.sender,
                packageId,
                userId,
                amount,
                nonces[msg.sender],
                signature
            )
        );

        

        IERC20 erc20Token = IERC20(erc20Address);

        require(
            erc20Token.allowance(sender, address(this)) >= amount,
            "Allowance insuffice"
        );
        require(erc20Token.balanceOf(sender) >= amount, "Insuffice balance");

        erc20Token.transferFrom(sender, adminReceiver, amount);
        nonces[msg.sender] += 1;
        emit Transfer(packageId, amount, sender, userId);
    }
}