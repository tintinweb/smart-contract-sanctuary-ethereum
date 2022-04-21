//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2; // required to accept structs as function parameters

import "./AccessControl.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";
import "./ERC721URIStorage.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

contract LazyNFT is ERC721URIStorage, EIP712, AccessControl {
  address public salesAddress;
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  string private constant SIGNING_DOMAIN = "LazyNFT-Voucher";
  string private constant SIGNATURE_VERSION = "1";
  //string private constant PAYMENT_TOKEN = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;  //Wrapped Eth

  mapping (address => uint256) pendingWithdrawals;

  constructor()
    ERC721("LazyNFT", "LAZ") 
    EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
      salesAddress = address(0x000b69c8a960a08df188b85be9a15545ac40a5e68b);
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
      _setupRole(MINTER_ROLE, address(0x00c902d06cf317e27ad774eb0074b1f94fa33a757f));
    }

  /// @notice Represents an un-minted NFT, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFT using the redeem function.
  struct NFTVoucher {
    /// @notice The id of the token to be redeemed. Must be unique - if another token with this ID already exists, the redeem function will revert.
    uint256 tokenId;

    /// @notice The erc20 address that the NFT creator is willing to accept for the initial sale of this NFT.
    address paymentTokenAddress;

    /// @notice The minimum price (in wei) that the NFT creator is willing to accept for the initial sale of this NFT.
    uint256 minPrice;

    /// @notice The metadata URI to associate with this token.
    string uri;

    /// @notice the EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
    bytes signature;
  }

  function setSalesAddress(address newSalesAddress) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only admin can set sales address");
    
    salesAddress = newSalesAddress;
  }

  /// @notice Redeems an NFTVoucher for an actual NFT, creating it in the process.
  /// @param redeemer The address of the account which will receive the NFT upon success.
  /// @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
  function redeem(address redeemer, NFTVoucher calldata voucher) public returns (uint256) {
    // make sure signature is valid and get the address of the signer
    address signer = _verify(voucher);

    // make sure that the signer is authorized to mint NFTs
    require(hasRole(MINTER_ROLE, signer), "Signature invalid or unauthorized");

    // make sure that the redeemer is paying enough to cover the buyer's cost
    uint256 tokenBalance = ERC20(voucher.paymentTokenAddress).balanceOf(msg.sender);
    require(tokenBalance >= voucher.minPrice, "Insufficient funds to redeem");

    SafeERC20.safeTransfer(ERC20(voucher.paymentTokenAddress), salesAddress, voucher.minPrice);

    // first assign the token to the signer, to establish provenance on-chain
    _safeMint(signer, voucher.tokenId);
    _setTokenURI(voucher.tokenId, voucher.uri);
    
    // transfer the token to the redeemer
    _transfer(signer, redeemer, voucher.tokenId);

    return voucher.tokenId;
  }

  /// @notice Redeems an NFTVoucher for an actual NFT, creating it in the process.
  /// @param redeemer The address of the account which will receive the NFT upon success.
  /// @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
  /*function redeem(address redeemer, NFTVoucher calldata voucher) public payable returns (uint256) {
    // make sure signature is valid and get the address of the signer
    address signer = _verify(voucher);

    // make sure that the signer is authorized to mint NFTs
    require(hasRole(MINTER_ROLE, signer), "Signature invalid or unauthorized");

    // make sure that the redeemer is paying enough to cover the buyer's cost
    require(msg.value >= voucher.minPrice, "Insufficient funds to redeem");

    // first assign the token to the signer, to establish provenance on-chain
    _safeMint(signer, voucher.tokenId);
    _setTokenURI(voucher.tokenId, voucher.uri);
    
    // transfer the token to the redeemer
    _transfer(signer, redeemer, voucher.tokenId);

    // record payment to signer's withdrawal balance
    pendingWithdrawals[signer] += msg.value;

    return voucher.tokenId;
  }*/

  /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
  /// @param voucher An NFTVoucher to hash.
  function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
    return _hashTypedDataV4(keccak256(abi.encode(
      keccak256("NFTVoucher(uint256 tokenId,uint256 minPrice,string uri)"),
      voucher.tokenId,
      voucher.minPrice,
      keccak256(bytes(voucher.uri))
    )));
  }

  /// @notice Returns the chain id of the current blockchain.
  /// @dev This is used to workaround an issue with ganache returning different values from the on-chain chainid() function and
  ///  the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
  function getChainID() external view returns (uint256) {
    uint256 id;
    assembly {
        id := chainid()
    }
    return id;
  }

  /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
  /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
  /// @param voucher An NFTVoucher describing an unminted NFT.
  function _verify(NFTVoucher calldata voucher) internal view returns (address) {
    bytes32 digest = _hash(voucher);
    return ECDSA.recover(digest, voucher.signature);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override (AccessControl, ERC721) returns (bool) {
    return ERC721.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
  }
}