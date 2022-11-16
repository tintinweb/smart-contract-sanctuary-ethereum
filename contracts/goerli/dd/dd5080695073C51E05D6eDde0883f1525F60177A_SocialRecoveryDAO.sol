//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VerifySignature.sol";

contract SocialRecoveryDAO is VerifySignature {
    uint256 DAOID;
    uint256 baseFee = 1e15;  // 0.001 ether
    mapping(bytes32=>address[]) user_to_SP;
    mapping(uint256=>address) DAOID_to_address;
    event New_Pair(bytes32 indexed user, address[] SP_address);
    event fee_paid(address indexed user, address indexed sp);
    // set the mapping of hash(user)->address[SP]
    function set_pair(bytes32 user_hash, address[] calldata rp_addr) external
    {
        require(user_hash!=0,"user cannot be 0!");

        user_to_SP[user_hash] = rp_addr;
        emit New_Pair(user_hash,rp_addr);

    }

    // return the addresses of SP based of user hash
    function get_pair(bytes32 user_hash) external view returns(address[] memory){
        address[] memory rp_addr = user_to_SP[user_hash];
        return rp_addr;
    }


      function registerMember() external{
        DAOID_to_address[DAOID] = msg.sender;
        DAOID = DAOID+1;
      }

    function getDAOmember() external view returns(address [] memory){
        address[] memory DAOmember; // define an empty array

        for (uint256 i=0;i<DAOID;i++){
        DAOmember[i]= DAOID_to_address[i];
        }

        return DAOmember;

    }

    function VerifyAndTransfer(bytes memory signature, address sp, string memory message, uint nonce ) public payable {
    //       function verify(
    //     address _signer,
    //     address _to,
    //     string memory _message,
    //     uint _nonce,
    //     bytes memory signature
    // )
      bool result = verify(msg.sender,sp, message, nonce, signature);
      require(result==true, "signature is not correct!");
      require(payable(address(sp)).send(baseFee), "transfer fee error");
      emit fee_paid(msg.sender,sp);
    }

    function SimplTransfer(address receiver) public payable{
      payable(address(receiver)).send(msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Verify Signature on chain

contract VerifySignature {

    function getMessageHash(
        address _to,
        string memory _message,
        uint _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _message, _nonce));
    }


    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }


    function verify(
        address _signer,
        address _to,
        string  memory _message,
        uint _nonce,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _message, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
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