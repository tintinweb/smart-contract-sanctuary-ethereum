/**
 *Submitted for verification at Etherscan.io on 2022-10-16
*/

pragma solidity >=0.8.0 <0.9.0;

// This is the ETH/ERC20/NFT multisig contract for Ownbit.
//
// For 2-of-3 multisig, to authorize a spend, two signtures must be provided by 2 of the 3 owners.
// To generate the message to be signed, provide the destination address and
// spend amount (in wei) to the generateMessageToSign method.
// The signatures must be provided as the (v, r, s) hex-encoded coordinates.
// The S coordinate must be 0x00 or 0x01 corresponding to 0x1b and 0x1c, respectively.
//
// WARNING: The generated message is only valid until the next spend is executed.
//          after that, a new message will need to be calculated.
//
//
// INFO: This contract is ERC20/ERC721/ERC1155 compatible.
// This contract can both receive ETH, ERC20 and NFT (ERC721/ERC1155) tokens.
// Last update time: 2022-09-25.
// [email protected]

contract OwnbitMultiSig {
    
  uint constant public MAX_OWNER_COUNT = 9;

  // The N addresses which control the funds in this contract. The
  // owners of M of these addresses will need to both sign a message
  // allowing the funds in this contract to be spent.
  mapping(address => bool) private isOwner;
  address[] private owners;
  uint private required;

  // The contract nonce is not accessible to the contract so we
  // implement a nonce-like variable for replay protection.
  uint256 private spendNonce = 0;
  
  // An event sent when funds are received.
  event Funded(address from, uint value);
  
  // An event sent when a spend is triggered to the given address.
  event Spent(address to, uint value);

  modifier validRequirement(uint ownerCount, uint _required) {
    require (ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required >= 1);
    _;
  }
  
  /// @dev Contract constructor sets initial owners and required number of confirmations.
  /// @param _owners List of initial owners.
  /// @param _required Number of required confirmations.
  constructor(address[] memory _owners, uint _required) validRequirement(_owners.length, _required) {
    for (uint i = 0; i < _owners.length; i++) {
        //onwer should be distinct, and non-zero
        if (isOwner[_owners[i]] || _owners[i] == address(0x0)) {
            revert();
        }
        isOwner[_owners[i]] = true;
    }
    owners = _owners;
    required = _required;
  }

  // The fallback function for this contract.
  fallback() external payable {
    if (msg.value > 0) {
        emit Funded(msg.sender, msg.value);
    }
  }
  
  // @dev Returns list of owners.
  // @return List of owner addresses.
  function getOwners() public view returns (address[] memory) {
    return owners;
  }
    
  function getSpendNonce() public view returns (uint256) {
    return spendNonce;
  }
    
  function getRequired() public view returns (uint) {
    return required;
  }

  // Generates the message to sign given the output destination address and amount.
  // includes this contract's address and a nonce for replay protection.
  // One option to independently verify: https://leventozturk.com/engineering/sha3/ and select keccak
  function generateMessageToSign(address destination, uint256 value, bytes memory data) private view returns (bytes32) {
    //the sequence must match generateMultiSigV3 in JS
    bytes32 message = keccak256(abi.encodePacked(address(this), destination, value, data, spendNonce));
    return message;
  }
  
  function _messageToRecover(address destination, uint256 value, bytes memory data) private view returns (bytes32) {
    bytes32 hashedUnsignedMessage = generateMessageToSign(destination, value, data);
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    return keccak256(abi.encodePacked(prefix, hashedUnsignedMessage));
  }
  
  //destination can be a normal address or a contract address, such as ERC20 contract address.
  //value is the wei transferred to the destination.
  //data for transfer ether: 0x
  //data for transfer erc20 example: 0xa9059cbb000000000000000000000000ac6342a7efb995d63cc91db49f6023e95873d25000000000000000000000000000000000000000000000000000000000000003e8
  //data for transfer erc721 example: 0x42842e0e00000000000000000000000097b65ad59c8c96f2dd786751e6279a1a6d34a4810000000000000000000000006cb33e7179860d24635c66850f1f6a5d4f8eee6d0000000000000000000000000000000000000000000000000000000000042134
  //data can contain any data to be executed. 
  function spend(address destination, uint256 value, uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss, bytes calldata data) external {
    require(destination != address(this), "Not allow sending to yourself");
    require(_validSignature(destination, value, vs, rs, ss, data), "invalid signatures");
    spendNonce = spendNonce + 1;
    //transfer tokens from this contract to the destination address
    (bool sent, bytes memory _ret) = destination.call{value: value}(data);
    if (sent) {
        emit Spent(destination, value);
    }
  }

  // Confirm that the signature triplets (v1, r1, s1) (v2, r2, s2) ...
  // authorize a spend of this contract's funds to the given destination address.
  function _validSignature(address destination, uint256 value, uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss, bytes memory data) private view returns (bool) {
    require(vs.length == rs.length);
    require(rs.length == ss.length);
    require(vs.length <= owners.length);
    require(vs.length >= required);
    bytes32 message = _messageToRecover(destination, value, data);
    address[] memory addrs = new address[](vs.length);
    for (uint i = 0; i < vs.length; i++) {
        //recover the address associated with the public key from elliptic curve signature or return zero on error 
        addrs[i] = ecrecover(message, vs[i]+27, rs[i], ss[i]);
    }
    require(_distinctOwners(addrs));
    return true;
  }
  
  // Confirm the addresses as distinct owners of this contract.
  function _distinctOwners(address[] memory addrs) private view returns (bool) {
    if (addrs.length > owners.length) {
        return false;
    }
    for (uint i = 0; i < addrs.length; i++) {
        if (!isOwner[addrs[i]]) {
            return false;
        }
        //address should be distinct
        for (uint j = 0; j < i; j++) {
            if (addrs[i] == addrs[j]) {
                return false;
            }
        }
    }
    return true;
  }

  //support ERC721 safeTransferFrom
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4) {
      return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4) {
      return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
  }
}