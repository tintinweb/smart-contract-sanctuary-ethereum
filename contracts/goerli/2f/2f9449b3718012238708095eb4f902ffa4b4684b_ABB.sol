// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Opensea
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                     //
//                                                                                                                                                                                     //
//    # Palkeoramix decompiler.                                                                                                                                                        //
//                                                                                                                                                                                     //
//    const unknown4060b25e = '2.0.0'                                                                                                                                                  //
//    const unknownc311c523 = 1                                                                                                                                                        //
//                                                                                                                                                                                     //
//    def storage:                                                                                                                                                                     //
//      stor0 is mapping of uint256 at storage 0                                                                                                                                       //
//      stor1 is mapping of uint8 at storage 1                                                                                                                                         //
//      owner is addr at storage 2                                                                                                                                                     //
//      unknowncd7c0326Address is addr at storage 3                                                                                                                                    //
//      name is array of uint256 at storage 4                                                                                                                                          //
//      symbol is array of uint256 at storage 5                                                                                                                                        //
//      totalSupply is mapping of uint256 at storage 6                                                                                                                                 //
//      unknownf923e8c3 is array of uint256 at storage 7                                                                                                                               //
//      uri is array of uint256 at storage 8                                                                                                                                           //
//      stor9 is uint8 at storage 9                                                                                                                                                    //
//      stor10 is mapping of uint8 at storage 10                                                                                                                                       //
//      creator is mapping of addr at storage 11                                                                                                                                       //
//                                                                                                                                                                                     //
//    def name() payable:                                                                                                                                                              //
//      return name[0 len name.length]                                                                                                                                                 //
//                                                                                                                                                                                     //
//    def uri(uint256 _id) payable:                                                                                                                                                    //
//      return uri[_id][0 len uri[_id].length]                                                                                                                                         //
//                                                                                                                                                                                     //
//    def creator(uint256 _tokenId) payable:                                                                                                                                           //
//      require calldata.size - 4 >= 32                                                                                                                                                //
//      return creator[_tokenId]                                                                                                                                                       //
//                                                                                                                                                                                     //
//    def unknown73505d35(addr _param1) payable:                                                                                                                                       //
//      require calldata.size - 4 >= 32                                                                                                                                                //
//      return bool(stor10[_param1])                                                                                                                                                   //
//                                                                                                                                                                                     //
//    def owner() payable:                                                                                                                                                             //
//      return owner                                                                                                                                                                   //
//                                                                                                                                                                                     //
//    def symbol() payable:                                                                                                                                                            //
//      return symbol[0 len symbol.length]                                                                                                                                             //
//                                                                                                                                                                                     //
//    def totalSupply(uint256 _id) payable:                                                                                                                                            //
//      require calldata.size - 4 >= 32                                                                                                                                                //
//      return totalSupply[_id]                                                                                                                                                        //
//                                                                                                                                                                                     //
//    def unknowncd7c0326() payable:                                                                                                                                                   //
//      return unknowncd7c0326Address                                                                                                                                                  //
//                                                                                                                                                                                     //
//    def unknownf923e8c3() payable:                                                                                                                                                   //
//      return unknownf923e8c3[0 len unknownf923e8c3.length]                                                                                                                           //
//                                                                                                                                                                                     //
//    #                                                                                                                                                                                //
//    #  Regular functions                                                                                                                                                             //
//    #                                                                                                                                                                                //
//                                                                                                                                                                                     //
//    def _fallback() payable: # default function                                                                                                                                      //
//      revert                                                                                                                                                                         //
//                                                                                                                                                                                     //
//    def isOwner() payable:                                                                                                                                                           //
//      return (caller == owner)                                                                                                                                                       //
//                                                                                                                                                                                     //
//    def exists(uint256 _tokenId) payable:                                                                                                                                            //
//      require calldata.size - 4 >= 32                                                                                                                                                //
//      return (totalSupply[_tokenId] > 0)                                                                                                                                             //
//                                                                                                                                                                                     //
//    def supportsInterface(bytes4 _interfaceId) payable:                                                                                                                              //
//      require calldata.size - 4 >= 32                                                                                                                                                //
//      if Mask(32, 224, _interfaceId) != 0x1ffc9a700000000000000000000000000000000000000000000000000000000:                                                                           //
//          if Mask(32, 224, _interfaceId) != 0xd9b67a2600000000000000000000000000000000000000000000000000000000:                                                                      //
//              return 0                                                                                                                                                               //
//      return 1                                                                                                                                                                       //
//                                                                                                                                                                                     //
//    def setApprovalForAll(address _to, bool _approved) payable:                                                                                                                      //
//      require calldata.size - 4 >= 64                                                                                                                                                //
//      stor1[caller][addr(_to)] = uint8(_approved)                                                                                                                                    //
//      log ApprovalForAll(                                                                                                                                                            //
//            address owner=_approved,                                                                                                                                                 //
//            address operator=caller,                                                                                                                                                 //
//            bool approved=_to)                                                                                                                                                       //
//                                                                                                                                                                                     //
//    def isApprovedForAll(address _owner, address _operator) payable:                                                                                                                 //
//      require calldata.size - 4 >= 64                                                                                                                                                //
//      if not stor10[addr(_operator)]:                                                                                                                                                //
//          require ext_code.size(unknowncd7c0326Address)                                                                                                                              //
//          static call unknowncd7c0326Address.proxies(address param1) with:                                                                                                           //
//                  gas gas_remaining wei                                                                                                                                              //
//                 args _owner                                                                                                                                                         //
//          if not ext_call.success:                                                                                                                                                   //
//              revert with ext_call.return_data[0 len return_data.size]                                                                                                               //
//          require return_data.size >= 32                                                                                                                                             //
//          if ext_call.return_data_operator:                                                                                                                                          //
//              return bool(stor1[addr(_owner)][addr(_operator)])                                                                                                                      //
//      return 1                                                                                                                                                                       //
//                                                                                                                                                                                     //
//    def unknownd26ea6c0(addr _param1) payable:                                                                                                                                       //
//      require calldata.size - 4 >= 32                                                                                                                                                //
//      if owner != caller:                                                                                                                                                            //
//          if not stor10[caller]:                                                                                                                                                     //
//              require ext_code.size(unknowncd7c0326Address)                                                                                                                          //
//              static call unknowncd7c0326Address.proxies(address param1) with:                                                                                                       //
//                      gas gas_remaining wei                                                                                                                                          //
//                     args owner                                                                                                                                                      //
//              if not ext_call.success:                                                                                                                                               //
//                  revert with ext_call.return_data[0 len return_data.size]                                                                                                           //
//              require return_data.size >= 32                                                                                                                                         //
//              if ext_call.return_data[12 len 20] != caller:                                                                                                                          //
//                  revert with 0x8c379a000000000000000000000000000000000000000000000000000000000,                                                                                     //
//                              32,                                                                                                                                                    //
//                              46,                                                                                                                                                    //
//                              0x44455243313135355472616461626c65236f6e6c794f776e65723a2043414c4c45525f49535f4e4f545f4f574e45,                                                        //
//                              mem[210 len 18]                                                                                                                                        //
//      unknowncd7c0326Address = _param1                                                                                                                                               //
//                                                                                                                                                                                     //
//    def unknown9e037eea(addr _param1) payable:                                                                                                                                       //
//      require calldata.size - 4 >= 32                                                                                                                                                //
//      if owner != caller:                                                                                                                                                            //
//          if not stor10[caller]:                                                                                                                                                     //
//              require ext_code.size(unknowncd7c0326Address)                                                                                                                          //
//              static call unknowncd7c0326Address.proxies(address param1) with:                                                                                                       //
//                      gas gas_remaining wei                                                                                                                                          //
//                     args owner                                                                                                                                                      //
//              if not ext_call.success:                                                                                                                                               //
//                  revert with ext_call.return_data[0 len return_data.size]                                                                                                           //
//              require return_data.size >= 32                                                                                                                                         //
//              if ext_call.return_data[12 len 20] != caller:                                                                                                                          //
//                  revert with 0x8c379a000000000000000000000000000000000000000000000000000000000,                                                                                     //
//                              32,                                                                                                                                                    //
//                              46,                                                                                                                                                    //
//                              0x44455243313135355472616461626c65236f6e6c794f776e65723a2043414c4c45525f49535f4e4f545f4f574e45,                                                        //
//                              mem[210 len 18]                                                                                                                                        //
//      stor10[addr(_param1)] = 0                                                                                                                                                      //
//                                                                                                                                                                                     //
//    def unknowna50aa5c3(addr _param1) payable:                                                                                                                                       //
//      require calldata.size - 4 >= 32                                                                                                                                                //
//      if owner != caller:                                                                                                                                                            //
//          if not stor10[caller]:                                                                                                                                                     //
//              require ext_code.size(unknowncd7c0326Address)                                                                                                                          //
//              static call unknowncd7c0326Address.proxies(address param1) with:                                                                                                       //
//                      gas gas_remaining wei                                                                                                                                          //
//                     args owner                                                                                                                                                      //
//              if not ext_call.success:                                                                                                                                               //
//                  revert with ext_call.return_data[0 len return_data.size]                                                                                                           //
//              require return_data.size >= 32                                                                                                                                         //
//              if ext_call.return_data[12 len 20] != caller:                                                                                                                          //
//                  revert with 0x8c379a000000000000000000000000000000000000000000000000000000000,                                                                                     //
//                              32,                                                                                                                                                    //
//                              46,                                                                                                                                                    //
//                              0x44455243313135355472616461626c65236f6e6c794f776e65723a2043414c4c45525f49535f4e4f545f4f574e45,                                                        //
//                              mem[210 len 18]                                                                                                                                        //
//      stor10[addr(_param1)] = 1                                                                                                                                                      //
//                                                                                                                                                                                     //
//    def renounceOwnership() payable:                                                                                                                                                 //
//      if owner != caller:                                                                                                                                                            //
//          if not stor10[caller]:                                                                                                                                                     //
//              require ext_code.size(unknowncd7c0326Address)                                                                                                                          //
//              static call unknowncd7c0326Address.proxies(address param1) with:                                                                                                       //
//                      gas gas_remaining wei                                                                                                                                          //
//                     args owner                                                                                                                                                      //
//              if not ext_call.success:                                                                                                                                               //
//                  revert with ext_call.return_data[0 len return_data.size]                                                                                                           //
//              require return_data.size >= 32                                                                                                                                         //
//              if ext_call.return_data[12 len 20] != caller:                                                                                                                          //
//                  revert with 0x8c379a000000000000000000000000000000000000000000000000000000000,                                                                                     //
//                              32,                                                                                                                                                    //
//                              46,                                                                                                                                                    //
//                              0x44455243313135355472616461626c65236f6e6c794f776e65723a2043414c4c45525f49535f4e4f545f4f574e45,                                                        //
//                              mem[210 len 18]                                                                                                                                        //
//      log OwnershipTransferred(                                                                                                                                                      //
//            address previousOwner=owner,                                                                                                                                             //
//            address newOwner=0)                                                                                                                                                      //
//      owner = 0                                                                                                                                                                      //
//                                                                                                                                                                                     //
//    def unknown24d88785(array _param1) payable:                                                                                                                                      //
//      require calldata.size - 4 >= 32                                                                                                                                                //
//      require _param1 <= 4294967296                                                                                                                                                  //
//      require _param1 + 36 <= calldata.size                                                                                                                                          //
//      require _param1.length <= 4294967296 and _param1 + _param1.length + 36 <= calldata.size                                                                                        //
//      if owner != caller:                                                                                                                                                            //
//          if not stor10[caller]:                                                                                                                                                     //
//              require ext_code.size(unknowncd7c0326Address)                                                                                                                          //
//              static call unknowncd7c0326Address.proxies(address param1) with:                                                                                                       //
//                      gas gas_remaining wei                                                                                                                                          //
//                     args owner                                                                                                                                                      //
//              if not ext_call.success:                                                                                                                                               //
//                  revert with ext_call.return_data[0 len return_data.size]                                                                                                           //
//              require return_data.size >= 32                                                                                                                                         //
//              if ext_call.return_data[12 len 20] != caller:                                                                                                                          //
//                  revert with 0,                                                                                                                                                     //
//                              32,                                                                                                                                                    //
//                              46,                                                                                                                                                    //
//                              0x44455243313135355472616461626c65236f6e6c794f776e65723a2043414c4c45525f49535f4e4f545f4f574e45,                                                        //
//                              mem[ceil32(_param1.length) + 242 len 18]                                                                                                               //
//      unknownf923e8c3[] = Array(len=_param1.length, data=_param1[all])                                                                                                               //
//                                                                                                                                                                                     //
//    def transferOwnership(address _newOwner) payable:                                                                                                                                //
//      require calldata.size - 4 >= 32                                                                                                                                                //
//      if owner != caller:                                                                                                                                                            //
//          if not stor10[caller]:                                                                                                                                                     //
//              require ext_code.size(unknowncd7c0326Address)                                                                                                                          //
//              static call unknowncd7c0326Address.proxies(address param1) with:                                                                                                       //
//                      gas gas_remaining wei                                                                                                                                          //
//                     args owner                                                                                                                                                      //
//              if not ext_call.success:                                                                                                                                               //
//                  revert with ext_call.return_data[0 len return_data.size]                                                                                                           //
//              require return_data.size >= 32                                                                                                                                         //
//              if ext_call.return_data[12 len 20] != caller:                                                                                                                          //
//                  revert with 0x8c379a000000000000000000000000000000000000000000000000000000000,                                                                                     //
//                              32,                                                                                                                                                    //
//                              46,                                                                                                                                                    //
//                              0x44455243313135355472616461626c65236f6e6c794f776e65723a2043414c4c45525f49535f4e4f545f4f574e45,                                                        //
//                              mem[210 len 18]                                                                                                                                        //
//      if not _newOwner:                                                                                                                                                              //
//          revert with 0x8c379a000000000000000000000000000000000000000000000000000000000,                                                                                             //
//                      32,                                                                                                                                                            //
//                      38,                                                                                                                                                            //
//                      0x544f776e61626c653a206e6577206f776e657220697320746865207a65726f20616464726573,                                                                                //
//                      mem[202 len 26]                                                                                                                                                //
//      log OwnershipTransferred(                                                                                                                                                      //
//            address previousOwner=owner,                                                                                                                                             //
//            address newOwner=_newOwner)                                                                                                                                              //
//      owner = _newOwner                                                                                                                                                              //
//                                                                                                                                                                                     //
//    def balanceOf(address _owner, uint256 _cardId) payable:                                                                                                                          //
//      require calldata.size - 4 >= 64                                                                                                                                                //
//      if not creator[_cardId]:                                                                                                                                                       //
//          if uint64(_cardId) != _owner:                                                                                                                                              //
//              if not stor10[addr(_owner)]:                                                                                                                                           //
//                  require ext_code.size(unknowncd7c0326Address)                                                                                                                      //
//                  static call unknowncd7c0326Address.proxies(address param1) with:                                                                                                   //
//                          gas gas_remaining wei                                                                                                                                      //
//                         args uint64(_cardId)                                                                                                                                        //
//                  if not ext_call.success:                                                                                                                                           //
//                      revert with ext_call.return_data[0 len return_data.size]                                                                                                       //
//                  require return_data.size >= 32                                                                                                                                     //
//                  if ext_call.return_data_owner:                                                                                                                                     //
//                      return stor0[addr(_owner)][_cardId]                                                                                                                            //
//      else:                                                                                                                                                                          //
//          if creator[_cardId] != _owner:                                                                                                                                             //
//              if not stor10[addr(_owner)]:                                                                                                                                           //
//                  require ext_code.size(unknowncd7c0326Address)                                                                                                                      //
//                  static call unknowncd7c0326Address.proxies(address param1) with:                                                                                                   //
//                          gas gas_remaining wei                                                                                                                                      //
//                         args creator[_cardId]                                                                                                                                       //
//                  if not ext_call.success:                                                                                                                                           //
//                      revert with ext_call.return_data[0 len return_data.size]                                                                                                       //
//                  require return_data.size >= 32                                                                                                                                     //
//                  if ext_call.return_data_owner:                                                                                                                                     //
//                      return stor0[addr(_owner)][_cardId]                                                                                                                            //
//      if totalSupply[_cardId] > _cardId % 1099511627776:                                                                                                                             //
//          revert with 0, 'SafeMath#sub: UNDERFLOW'                                                                                                                                   //
//      if stor0[addr(_owner)][_cardId] + (_cardId % 1099511627776) - totalSupply[_cardId] < stor0[addr(_owner)][_cardId]:                                                             //
//          revert with 0, 'SafeMath#add: OVERFLOW'                                                                                                                                    //
//      return (stor0[addr(_owner)][_cardId] + (_cardId % 1099511627776) - totalSupply[_cardId])                                                                                       //
//                                                                                                                                                                                     //
//    def unknown91686f53(uint256 _param1, addr _param2) payable:                                                                                                                      //
//      require calldata.size - 4 >= 64                                                                                                                                                //
//      if not creator[_param1]:                                                                                                                                                       //
//          if uint64(_param1) != caller:                                                                                                                                              //
//              if not stor10[caller]:                                                                                                                                                 //
//                  require ext_code.size(unknowncd7c0326Address)                                                                                                                      //
//                  static call unknowncd7c0326Address.proxies(address param1) with:                                                                                                   //
//                          gas gas_remaining wei                                                                                                                                      //
//                         args uint64(_param1)                                                                                                                                        //
//                  if not ext_call.success:                                                                                                                                           //
//                      revert with ext_call.return_data[0 len return_data.size]                                                                                                       //
//                  require return_data.size >= 32                                                                                                                                     //
//                  if ext_call.return_data[12 len 20] != caller:                                                                                                                      //
//                      revert with 0x8c379a000000000000000000000000000000000000000000000000000000000,                                                                                 //
//                                  32,                                                                                                                                                //
//                                  53,                                                                                                                                                //
//                                  0x454173736574436f6e74726163745368617265642363726561746f724f6e6c793a204f4e4c595f43524541544f525f414c4c4f5745,                                      //
//                                  mem[217 len 11]                                                                                                                                    //
//      else:                                                                                                                                                                          //
//          if creator[_param1] != caller:                                                                                                                                             //
//              if not stor10[caller]:                                                                                                                                                 //
//                  require ext_code.size(unknowncd7c0326Address)                                                                                                                      //
//                  static call unknowncd7c0326Address.proxies(address param1) with:                                                                                                   //
//                          gas gas_remaining wei                                                                                                                                      //
//                         args creator[_param1]                                                                                                                                       //
//                  if not ext_call.success:                                                                                                                                           //
//                      revert with ext_call.return_data[0 len return_data.size]                                                                                                       //
//                  require return_data.size >= 32                                                                                                                                     //
//                  if ext_call.return_data[12 len 20] != caller:                                                                                                                      //
//                      revert with 0x8c379a000000000000000000000000000000000000000000000000000000000,                                                                                 //
//                                  32,                                                                                                                                                //
//                                  53,                                                                                                                                                //
//                                  0x454173736574436f6e74726163745368617265642363726561746f724f6e6c793a204f4e4c595f43524541544f525f414c4c4f5745,                                      //
//                                  mem[217 len 11]                                                                                                                                    //
//      if not _param2:                                                                                                                                                                //
//          revert with 0x8c379a000000000000000000000000000000000000000000000000000000000,                                                                                             //
//                      32,                                                                                                                                                            //
//                      48,                                                                                                                                                            //
//                      0x734173736574436f6e74726163745368617265642373657443726561746f723a20494e56414c49445f41444452455353,                                                            //
//                      mem[212 len 16]                                                                                                                                                //
//      creator[_param1] = _param2                                                                                                                                                     //
//      log 0x39071c63: _param1, _param2                                                                                                                                               //
//                                                                                                                                                                                     //
//    def balanceOfBatch(address[] _param1, uint256[] _param2) payable:                                                                                                                //
//      require calldata.size - 4 >= 64                                                                                                                                                //
//      require _param1 <= 4294967296                                                                                                                                                  //
//      require _param1 + 36 <= calldata.size                                                                                                                                          //
//      require _param1.length <= 4294967296 and _param1 + (32 * _param1.length) + 36 <= calldata.size                                                                                 //
//      mem[128 len 32 * _param1.length] = call.data[_param1 + 36 len 32 * _param1.length]                                                                                             //
//      require _param2 <= 4294967296                                                                                                                                                  //
//      require _param2 + 36 <= calldata.size                                                                                                                                          //
//      require _param2.length <= 4294967296 and _param2 + (32 * _param2.length) + 36 <= calldata.size                                                                                 //
//      mem[(32 * _param1.length) + 128] = _param2.length                                                                                                                              //
//      mem[(32 * _param1.length) + 160 len 32 * _param2.length] = call.data[_param2 + 36 len 32 * _param2.length]                                                                     //
//      if _param1.length != _param2.length:                                                                                                                                           //
//          revert with 0,                                                                                                                                                             //
//                      32,                                                                                                                                                            //
//                      44,                                                                                                                                                            //
//                      0x54455243313135352362616c616e63654f6642617463683a20494e56414c49445f41525241595f4c454e4754,                                                                    //
//                      mem[(32 * _param1.length) + (32 * _param2.length) + 272 len 20]                                                                                                //
//      mem[(32 * _param1.length) + (32 * _param2.length) + 160] = _param1.length                                                                                                      //
//      if _param1.length:                                                                                                                                                             //
//          mem[(32 * _param1.length) + (32 * _param2.length) + 192 len 32 * _param1.length] = code.data * _param1.length]                                                             //
//      idx = 0                                                                                                                                                                        //
//      while idx < _param1.length:                                                                                                                                                    //
//          require idx < _param1.length                                                                                                                                               //
//          require idx < _param2.length                                                                                                                                               //
//          mem[0] = mem[(32 * idx) + (32 * _param1.length) + 160]                                                                                                                     //
//          mem[32] = sha3(mem[(32 * idx) + 140 len 20], 0)                                                                                                                            //
//          require idx < _param1.length                                                                                                                                               //
//          mem[(32 * idx) + (32 * _param1.length) + (32 * _param2.length) + 192] = stor0[mem[(32 * idx) + 140 len 20]][mem[(32 * idx) + (32 * _param1.length) + 160]]                 //
//          idx = idx + 1                                                                                                                                                              //
//          continue                                                                                                                                                                   //
//      mem[(64 * _param1.length) + (32 * _param2.length) + 192] = 32                                                                                                                  //
//      mem[(64 * _param1.length) + (32 * _param2.length) + 224] = _param1.length                                                                                                      //
//      mem[(64 * _param1.length) + (32 * _param2.length) + 256 len floor32(_param1.length)] = mem[(32 * _param1.length) + (32 * _param2.length) + 192 len floor32(_param1.length)]    //
//      return memory                                                                                                                                                                  //
//        from (64 * _param1.length) + (32 * _param2.length) + 192                                                                                                                     //
//         len (161 * _param1.length) + 64                                                                                                                                             //
//                                                                                                                                                                                     //
//    def setURI(uint256 _id, string _uri) payable:                                                                                                                                    //
//      require calldata.size - 4 >= 64                                                                                                                                                //
//      require _uri <= 4294967296                                                                                                                                                     //
//      require _uri + 36 <= calldata.size                                                                                                                                             //
//      require _uri.length <= 4294967296 and _uri + _uri.length + 36 <= calldata.size                                                                                                 //
//      mem[128 len _uri.length] = _uri[all]                                                                                                                                           //
//      mem[_uri.length + 128] = 0                                                                                                                                                     //
//      if not creator[_id]:                                                                                                                                                           //
//          if uint64(_id) == caller:                                                                                                                                                  //
//              uri[_id][] = Array(len=_uri.length, data=_uri[all])                                                                                                                    //
//              mem[ceil32(_uri.length) + 128] = 32                                                                                                                                    //
//              mem[ceil32(_uri.length) + 160] = _uri.length                                                                                                                           //
//              mem[ceil32(_uri.length) + 192 le                                                                                                                                       //
//                                                                                                                                                                                     //
//                                                                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ABB is ERC1155Creator {
    constructor() ERC1155Creator() {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC1155Creator is Proxy {

    constructor() {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x0C2F5313E07C12Fc013F3905D746011ad17C109e;
        Address.functionDelegateCall(
            0x0C2F5313E07C12Fc013F3905D746011ad17C109e,
            abi.encodeWithSignature("initialize()")
        );
    }

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}