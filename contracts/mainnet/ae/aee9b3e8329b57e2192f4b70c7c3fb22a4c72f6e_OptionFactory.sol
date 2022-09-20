// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";

import "./OptionNFT.sol";

contract Ownable {
  address payable public owner_;

  modifier isOwner {
    if (msg.sender != owner_) { revert("must be owner"); }
    _;
  }

  constructor() {
    owner_ = payable(msg.sender);
  }

  function setOwner( address payable newowner ) public isOwner {
    owner_ = newowner;
  }
}

//
// Decentralized Exchange to create Options for Ethereum-based assets including
// Ether (amounts in wei), ERC20 tokens and stablecoins (amounts in units),
// and ERC721 NFTs (amount n/a)
//
// The maker places collateral when creating the option. The maker receives an
// OptionNFT holding the details as part of the creation process. The maker
// can sell the NFT anywhere NFTs are exchanged as desired.
//
// The eventual owner of the OptionNFT can take any time before expiry. The
// OptionNFT must be approved for this smart contract and will be burned
// when the option is taken.
//
// CALL Option AAABBB
// . right of a buyer, but not obligation, to take AAA for a price of BBB
//   before the Option expires
// . maker provides AAA as collateral held by this contract
// . taker provides BBB at time of take
// . smart contract sends AAA to taker
// . smart contract sends BBB to maker
//
// PUT Option AAABBB
// . right of a buyer, but not obligation, to sell AAA and receive BBB on or
//   before the Option expires.
// . maker provides BBB to smart contract as collateral
// . taker provides AAA at time of take
// . smart contract sends AAA to maker
// . smart contract sends BBB to taker
//
// WARNING: Do NOT send/transfer assets to this contract directly.
//          Use the make() function instead.
//
// WARNING: There is no authoritative list of "certified ok" token SCAs.
//          Beware of scam tokens. Manually verify all SCAs before using.
//
// NOTE: Gas estimates based on simple test ERC's. Real ERCs may have higher
//       requirements.

contract OptionFactory is Ownable, IERC721Receiver {

  OptionNFT public nft;

  uint256 public makefee;
  uint256 public cancelfee;
  uint256 public takefee;

  // isCall : make a call option if true, otherwise a put
  // xxxType : any erc20 token sca, nft sca, or use 0x0 for ETH
  // xxxAmount : units of xxxType, wei or token units, use 0x0 if nft
  // xxxTokenId : nft tokenId, could be zero for some tokens
  // expires : seconds from Unix epoch when option expires
  // data : passed along to the ERC721 OptionNFT constructor and ultimately
  //        to the receiver's onERC721Received() callback, iff the receiver is
  //        another smartcontract
  //
  // gas estimates:
  //   - ETH as collateral: ~= 237,000
  //   - ERC20 as collateral: 47000 to approve and 275000 to make ~= 322,000
  //   - ERC721 as collateral: 49000 to approve ERC721 and 258,000 ~= 307,000

  function make( bool isCall,
                 address aaaType,
                 uint256 aaaAmount,
                 uint256 aaaTokenId,
                 address bbbType,
                 uint256 bbbAmount,
                 uint256 bbbTokenId,
                 uint256 expires,
                 bytes memory data )
                 external payable returns (uint256 tokenId) {

    if (isCall) {
      if (aaaType == address(0x0)) { // eth
        require( msg.value == aaaAmount + makefee, "incorrect value" );
      } else { // token
        _retrieve( aaaType, aaaAmount, aaaTokenId );
      }

      tokenId = nft.mint( msg.sender,
                          OptionNFT.OptionType.CALL,
                          aaaType,
                          aaaAmount,
                          aaaTokenId,
                          bbbType,
                          bbbAmount,
                          bbbTokenId,
                          expires,
                          data );
    }
    else {
      if (bbbType == address(0x0)) { // eth
        require( msg.value == bbbAmount + makefee, "incorrect value" );
      } else { // token
        _retrieve( bbbType, bbbAmount, bbbTokenId );
      }

      tokenId = nft.mint( msg.sender,
                          OptionNFT.OptionType.PUT,
                          bbbType,
                          bbbAmount,
                          bbbTokenId,
                          aaaType,
                          aaaAmount,
                          aaaTokenId,
                          expires,
                          data );
    }

    owner_.transfer( makefee );
  }

  // gas estimates (roughly):
  // - settle with ETH to get ERC721:
  //     49k approve
  //    127k take
  //     59k transferFrom
  //    ----
  //    235,000 gas
  //
  // - settle with ETH to get ERC20:
  //     49k approve
  //    116k take
  //    ----
  //    165,000 gas

  function take( uint256 tokenId ) external payable {

    require( !nft.isSinged(tokenId), "option was singed" );

    nft.transferFrom( msg.sender, address(this), tokenId );

    if ( block.timestamp >= nft._expirations(tokenId) ) {
      // option has expired so return collateral to maker
      _dispatch( nft._makers(tokenId),
                 nft._collatTypes(tokenId),
                 nft._collatAmounts(tokenId),
                 nft._collatTokenIds(tokenId) );
    }
    else {
      // confirm payment and settlement
      if (nft._settleTypes(tokenId) == address(0)) {
        require( msg.value == takefee + nft._settleAmounts(tokenId),
                 "incorrect value for settlement" );
      }
      else { // get token(s)
        _retrieve( nft._settleTypes(tokenId),
                   nft._settleAmounts(tokenId),
                   nft._settleTokenIds(tokenId) );
      }

      // collateral to taker
      _dispatch( msg.sender,
                 nft._collatTypes(tokenId),
                 nft._collatAmounts(tokenId),
                 nft._collatTokenIds(tokenId) );

      // settlement to maker
      _dispatch( nft._makers(tokenId),
                 nft._settleTypes(tokenId),
                 nft._settleAmounts(tokenId),
                 nft._settleTokenIds(tokenId) );
    }

    owner_.transfer( takefee );
    nft.burn( tokenId );
  }

  // gas estimates (roughly):
  // - retrieve ETH: 49k approve + 70k cancel ~= 120,000 gas
  // - retrieve ERC20: 49k approve + 77k cancel ~= 126,000 gas
  // - retrieve ERC721: 49k approve + 95k cancel ~= 144,000 gas
  //                    (excludes +59k for the transferFrom)

  function cancel( uint256 tokenId ) external payable {

    require( !nft.isSinged(tokenId), "option was singed" );

    owner_.transfer( cancelfee );

    if (    nft.ownerOf(tokenId) == address(this)
         || nft.getApproved(tokenId) == address(this)
         || nft.isApprovedForAll(nft.ownerOf(tokenId), address(this) )) {
      nft.burn( tokenId );
    }
    else {
      if ( block.timestamp < nft._expirations(tokenId) ) return;
      nft.singe( tokenId );
    }

    _dispatch( nft._makers(tokenId),
               nft._collatTypes(tokenId),
               nft._collatAmounts(tokenId),
               nft._collatTokenIds(tokenId) );
  }

  //
  // Admin and internal functions ...
  //
  function _retrieve( address xxxType, uint256 xxxAmt, uint256 xxxTokenId )
  internal {

    if (xxxAmt != 0) { // erc20
      require( IERC20(xxxType).transferFrom(msg.sender, address(this), xxxAmt),
               "failed to retrieve erc20" );
    } else { // erc721
      IERC721(xxxType).transferFrom( msg.sender, address(this), xxxTokenId );
    }
  }

  function _dispatch( address to,
                      address xxxType,
                      uint256 xxxAmt,
                      uint256 xxxTokenId ) internal {

    if (xxxType == address(0x0)) {
      payable(to).transfer( xxxAmt );
    } else if (xxxAmt != 0x0) { // erc20
        IERC20(xxxType).transfer(to, xxxAmt);
    } else {
      // erc721 has no transfer function, so receiver must transferFrom
      IERC721(xxxType).approve( msg.sender, xxxTokenId );
    }
  }

  constructor( uint256 mf, uint256 cf, uint256 tf ) {
    makefee = mf;
    cancelfee = cf;
    takefee = tf;
    nft = new OptionNFT();
  }

  function setFee( uint8 which, uint256 amtwei ) public isOwner {
    if (which == uint8(0)) makefee = amtwei;
    else if (which == uint8(1)) cancelfee = amtwei;
    else if (which == uint8(2)) takefee = amtwei;
    else revert( "invalid fee specified" );
  }

  function onERC721Received( address _operator,
                             address _from,
                             uint256 _tokenId,
                             bytes calldata _data) external pure
                             returns(bytes4) {

    if (    _operator == address(0x0)
         && _from == address(0x0)
         && _tokenId == 0x0
         && _data.length > 0 ) {
      // do nothing but suppress compiler warnings about unused params
    }
    return IERC721Receiver.onERC721Received.selector;
  }
}