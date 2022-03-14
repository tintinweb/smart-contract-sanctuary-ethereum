/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

//SPDX-License-Identifier: Unlicensed

pragma /* Caonlmua bot */ solidity /* Caonlmua bot */ ^0.8.5;
abstract /* Caonlmua bot */ contract /* Caonlmua bot */ Context /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ _msgSender() /* Caonlmua bot */ internal /* Caonlmua bot */ view /* Caonlmua bot */ virtual /* Caonlmua bot */ returns /* Caonlmua bot */ (address /* Caonlmua bot */ payable) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ payable(msg.sender);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ _msgData() /* Caonlmua bot */ internal /* Caonlmua bot */ view /* Caonlmua bot */ virtual /* Caonlmua bot */ returns /* Caonlmua bot */ (bytes /* Caonlmua bot */ memory) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ this;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ msg.data;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
}
interface /* Caonlmua bot */ IERC20 /* Caonlmua bot */ {

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ totalSupply() /* Caonlmua bot */ external /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (uint256);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ balanceOf(address /* Caonlmua bot */ account) /* Caonlmua bot */ external /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (uint256);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ transfer(address /* Caonlmua bot */ recipient, /* Caonlmua bot */ uint256 /* Caonlmua bot */ amount) /* Caonlmua bot */ external /* Caonlmua bot */ returns /* Caonlmua bot */ (bool);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ allowance(address /* Caonlmua bot */ owner, /* Caonlmua bot */ address /* Caonlmua bot */ spender) /* Caonlmua bot */ external /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (uint256);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ approve(address /* Caonlmua bot */ spender, /* Caonlmua bot */ uint256 /* Caonlmua bot */ amount) /* Caonlmua bot */ external /* Caonlmua bot */ returns /* Caonlmua bot */ (bool);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ transferFrom(address /* Caonlmua bot */ sender, /* Caonlmua bot */ address /* Caonlmua bot */ recipient, /* Caonlmua bot */ uint256 /* Caonlmua bot */ amount) /* Caonlmua bot */ external /* Caonlmua bot */ returns /* Caonlmua bot */ (bool);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ event /* Caonlmua bot */ Transfer(address /* Caonlmua bot */ indexed /* Caonlmua bot */ from, /* Caonlmua bot */ address /* Caonlmua bot */ indexed /* Caonlmua bot */ to, /* Caonlmua bot */ uint256 /* Caonlmua bot */ value);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ event /* Caonlmua bot */ Approval(address /* Caonlmua bot */ indexed /* Caonlmua bot */ owner, /* Caonlmua bot */ address /* Caonlmua bot */ indexed /* Caonlmua bot */ spender, /* Caonlmua bot */ uint256 /* Caonlmua bot */ value);
}

library /* Caonlmua bot */ SafeMath /* Caonlmua bot */ {

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ add(uint256 /* Caonlmua bot */ a, /* Caonlmua bot */ uint256 /* Caonlmua bot */ b) /* Caonlmua bot */ internal /* Caonlmua bot */ pure /* Caonlmua bot */ returns /* Caonlmua bot */ (uint256) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ c /* Caonlmua bot */ = /* Caonlmua bot */ a /* Caonlmua bot */ + /* Caonlmua bot */ b;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ require(c /* Caonlmua bot */ >= /* Caonlmua bot */ a, /* Caonlmua bot */ "SafeMath: /* Caonlmua bot */ addition /* Caonlmua bot */ overflow");

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ c;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ sub(uint256 /* Caonlmua bot */ a, /* Caonlmua bot */ uint256 /* Caonlmua bot */ b) /* Caonlmua bot */ internal /* Caonlmua bot */ pure /* Caonlmua bot */ returns /* Caonlmua bot */ (uint256) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ sub(a, /* Caonlmua bot */ b, /* Caonlmua bot */ "SafeMath: /* Caonlmua bot */ subtraction /* Caonlmua bot */ overflow");
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ sub(uint256 /* Caonlmua bot */ a, /* Caonlmua bot */ uint256 /* Caonlmua bot */ b, /* Caonlmua bot */ string /* Caonlmua bot */ memory /* Caonlmua bot */ errorMessage) /* Caonlmua bot */ internal /* Caonlmua bot */ pure /* Caonlmua bot */ returns /* Caonlmua bot */ (uint256) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ require(b /* Caonlmua bot */ <= /* Caonlmua bot */ a, /* Caonlmua bot */ errorMessage);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ c /* Caonlmua bot */ = /* Caonlmua bot */ a /* Caonlmua bot */ - /* Caonlmua bot */ b;

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ c;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ mul(uint256 /* Caonlmua bot */ a, /* Caonlmua bot */ uint256 /* Caonlmua bot */ b) /* Caonlmua bot */ internal /* Caonlmua bot */ pure /* Caonlmua bot */ returns /* Caonlmua bot */ (uint256) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ if /* Caonlmua bot */ (a /* Caonlmua bot */ == /* Caonlmua bot */ 0) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ 0;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ c /* Caonlmua bot */ = /* Caonlmua bot */ a /* Caonlmua bot */ * /* Caonlmua bot */ b;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ require(c /* Caonlmua bot */ / /* Caonlmua bot */ a /* Caonlmua bot */ == /* Caonlmua bot */ b, /* Caonlmua bot */ "SafeMath: /* Caonlmua bot */ multiplication /* Caonlmua bot */ overflow");

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ c;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ div(uint256 /* Caonlmua bot */ a, /* Caonlmua bot */ uint256 /* Caonlmua bot */ b) /* Caonlmua bot */ internal /* Caonlmua bot */ pure /* Caonlmua bot */ returns /* Caonlmua bot */ (uint256) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ div(a, /* Caonlmua bot */ b, /* Caonlmua bot */ "SafeMath: /* Caonlmua bot */ division /* Caonlmua bot */ by /* Caonlmua bot */ zero");
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ div(uint256 /* Caonlmua bot */ a, /* Caonlmua bot */ uint256 /* Caonlmua bot */ b, /* Caonlmua bot */ string /* Caonlmua bot */ memory /* Caonlmua bot */ errorMessage) /* Caonlmua bot */ internal /* Caonlmua bot */ pure /* Caonlmua bot */ returns /* Caonlmua bot */ (uint256) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ require(b /* Caonlmua bot */ > /* Caonlmua bot */ 0, /* Caonlmua bot */ errorMessage);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ c /* Caonlmua bot */ = /* Caonlmua bot */ a /* Caonlmua bot */ / /* Caonlmua bot */ b;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ c;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ mod(uint256 /* Caonlmua bot */ a, /* Caonlmua bot */ uint256 /* Caonlmua bot */ b) /* Caonlmua bot */ internal /* Caonlmua bot */ pure /* Caonlmua bot */ returns /* Caonlmua bot */ (uint256) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ mod(a,b,"SafeMath: /* Caonlmua bot */ division /* Caonlmua bot */ by /* Caonlmua bot */ zero");
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ mod(uint256 /* Caonlmua bot */ a, /* Caonlmua bot */ uint256 /* Caonlmua bot */ b, /* Caonlmua bot */ string /* Caonlmua bot */ memory /* Caonlmua bot */ errorMessage) /* Caonlmua bot */ internal /* Caonlmua bot */ pure /* Caonlmua bot */ returns /* Caonlmua bot */ (uint256) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ require(b /* Caonlmua bot */ != /* Caonlmua bot */ 0, /* Caonlmua bot */ errorMessage);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ a /* Caonlmua bot */ % /* Caonlmua bot */ b;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
}
library /* Caonlmua bot */ Address /* Caonlmua bot */ {

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ isContract(address /* Caonlmua bot */ account) /* Caonlmua bot */ internal /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (bool) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ bytes32 /* Caonlmua bot */ codehash;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ bytes32 /* Caonlmua bot */ accountHash /* Caonlmua bot */ = /* Caonlmua bot */ 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ assembly /* Caonlmua bot */ { /* Caonlmua bot */ codehash /* Caonlmua bot */ := /* Caonlmua bot */ extcodehash(account) /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ (codehash /* Caonlmua bot */ != /* Caonlmua bot */ accountHash /* Caonlmua bot */ && /* Caonlmua bot */ codehash /* Caonlmua bot */ != /* Caonlmua bot */ 0x0);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ sendValue(address /* Caonlmua bot */ payable /* Caonlmua bot */ recipient, /* Caonlmua bot */ uint256 /* Caonlmua bot */ amount) /* Caonlmua bot */ internal /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ require(address(this).balance /* Caonlmua bot */ >= /* Caonlmua bot */ amount, /* Caonlmua bot */ "Address: /* Caonlmua bot */ insufficient /* Caonlmua bot */ balance");
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ (bool /* Caonlmua bot */ success, /* Caonlmua bot */ ) /* Caonlmua bot */ = /* Caonlmua bot */ recipient.call{ /* Caonlmua bot */ value: /* Caonlmua bot */ amount /* Caonlmua bot */ }("");
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ require(success, /* Caonlmua bot */ "Address: /* Caonlmua bot */ unable /* Caonlmua bot */ to /* Caonlmua bot */ send /* Caonlmua bot */ value, /* Caonlmua bot */ recipient /* Caonlmua bot */ may /* Caonlmua bot */ have /* Caonlmua bot */ reverted");
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ functionCall(address /* Caonlmua bot */ target, /* Caonlmua bot */ bytes /* Caonlmua bot */ memory /* Caonlmua bot */ data) /* Caonlmua bot */ internal /* Caonlmua bot */ returns /* Caonlmua bot */ (bytes /* Caonlmua bot */ memory) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ functionCall(target, /* Caonlmua bot */ data, /* Caonlmua bot */ "Address: /* Caonlmua bot */ low-level /* Caonlmua bot */ call /* Caonlmua bot */ failed");
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ functionCall(address /* Caonlmua bot */ target, /* Caonlmua bot */ bytes /* Caonlmua bot */ memory /* Caonlmua bot */ data, /* Caonlmua bot */ string /* Caonlmua bot */ memory /* Caonlmua bot */ errorMessage) /* Caonlmua bot */ internal /* Caonlmua bot */ returns /* Caonlmua bot */ (bytes /* Caonlmua bot */ memory) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ _functionCallWithValue(target, /* Caonlmua bot */ data, /* Caonlmua bot */ 0, /* Caonlmua bot */ errorMessage);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ functionCallWithValue(address /* Caonlmua bot */ target, /* Caonlmua bot */ bytes /* Caonlmua bot */ memory /* Caonlmua bot */ data, /* Caonlmua bot */ uint256 /* Caonlmua bot */ value) /* Caonlmua bot */ internal /* Caonlmua bot */ returns /* Caonlmua bot */ (bytes /* Caonlmua bot */ memory) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ functionCallWithValue(target, /* Caonlmua bot */ data, /* Caonlmua bot */ value, /* Caonlmua bot */ "Address: /* Caonlmua bot */ low-level /* Caonlmua bot */ call /* Caonlmua bot */ with /* Caonlmua bot */ value /* Caonlmua bot */ failed");
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ _functionCallWithValue(address /* Caonlmua bot */ target, /* Caonlmua bot */ bytes /* Caonlmua bot */ memory /* Caonlmua bot */ data, /* Caonlmua bot */ uint256 /* Caonlmua bot */ weiValue, /* Caonlmua bot */ string /* Caonlmua bot */ memory /* Caonlmua bot */ errorMessage) /* Caonlmua bot */ private /* Caonlmua bot */ returns /* Caonlmua bot */ (bytes /* Caonlmua bot */ memory) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ require(isContract(target), /* Caonlmua bot */ "Address: /* Caonlmua bot */ call /* Caonlmua bot */ to /* Caonlmua bot */ non-contract");
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ (bool /* Caonlmua bot */ success, /* Caonlmua bot */ bytes /* Caonlmua bot */ memory /* Caonlmua bot */ returndata) /* Caonlmua bot */ = /* Caonlmua bot */ target.call{ /* Caonlmua bot */ value: /* Caonlmua bot */ weiValue /* Caonlmua bot */ }(data);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ if /* Caonlmua bot */ (success) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ returndata;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ } /* Caonlmua bot */ else /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ if /* Caonlmua bot */ (returndata.length /* Caonlmua bot */ > /* Caonlmua bot */ 0) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ assembly /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ let /* Caonlmua bot */ returndata_size /* Caonlmua bot */ := /* Caonlmua bot */ mload(returndata)
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ revert(add(32, /* Caonlmua bot */ returndata), /* Caonlmua bot */ returndata_size)
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ } /* Caonlmua bot */ else /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ revert(errorMessage);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ functionCallWithValue(address /* Caonlmua bot */ target, /* Caonlmua bot */ bytes /* Caonlmua bot */ memory /* Caonlmua bot */ data, /* Caonlmua bot */ uint256 /* Caonlmua bot */ value, /* Caonlmua bot */ string /* Caonlmua bot */ memory /* Caonlmua bot */ errorMessage) /* Caonlmua bot */ internal /* Caonlmua bot */ returns /* Caonlmua bot */ (bytes /* Caonlmua bot */ memory) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ require(address(this).balance /* Caonlmua bot */ >= /* Caonlmua bot */ value, /* Caonlmua bot */ "Address: /* Caonlmua bot */ insufficient /* Caonlmua bot */ balance /* Caonlmua bot */ for /* Caonlmua bot */ call");
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ _functionCallWithValue(target, /* Caonlmua bot */ data, /* Caonlmua bot */ value, /* Caonlmua bot */ errorMessage);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
}
contract /* Caonlmua bot */ Ownable /* Caonlmua bot */ is /* Caonlmua bot */ Context /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ private /* Caonlmua bot */ _owner;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ event /* Caonlmua bot */ OwnershipTransferred(address /* Caonlmua bot */ indexed /* Caonlmua bot */ previousOwner, /* Caonlmua bot */ address /* Caonlmua bot */ indexed /* Caonlmua bot */ newOwner);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ constructor /* Caonlmua bot */ () /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ msgSender /* Caonlmua bot */ = /* Caonlmua bot */ _msgSender();
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _owner /* Caonlmua bot */ = /* Caonlmua bot */ msgSender;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ emit /* Caonlmua bot */ OwnershipTransferred(address(0), /* Caonlmua bot */ msgSender);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ owner() /* Caonlmua bot */ public /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (address) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ _owner;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ modifier /* Caonlmua bot */ onlyOwner() /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ require(_owner /* Caonlmua bot */ == /* Caonlmua bot */ _msgSender(), /* Caonlmua bot */ "Ownable: /* Caonlmua bot */ caller /* Caonlmua bot */ is /* Caonlmua bot */ not /* Caonlmua bot */ the /* Caonlmua bot */ owner");
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ waiveOwnership() /* Caonlmua bot */ public /* Caonlmua bot */ virtual /* Caonlmua bot */ onlyOwner /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ emit /* Caonlmua bot */ OwnershipTransferred(_owner, /* Caonlmua bot */ address(0));
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _owner /* Caonlmua bot */ = /* Caonlmua bot */ address(0);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ transferOwnership(address /* Caonlmua bot */ newOwner) /* Caonlmua bot */ public /* Caonlmua bot */ virtual /* Caonlmua bot */ onlyOwner /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ require(newOwner /* Caonlmua bot */ != /* Caonlmua bot */ address(0), /* Caonlmua bot */ "Ownable: /* Caonlmua bot */ new /* Caonlmua bot */ owner /* Caonlmua bot */ is /* Caonlmua bot */ the /* Caonlmua bot */ zero /* Caonlmua bot */ address");
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ emit /* Caonlmua bot */ OwnershipTransferred(_owner, /* Caonlmua bot */ newOwner);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _owner /* Caonlmua bot */ = /* Caonlmua bot */ newOwner;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ getTime() /* Caonlmua bot */ public /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (uint256) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ block.timestamp;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
}

interface /* Caonlmua bot */ IUniswapV2Factory /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ event /* Caonlmua bot */ PairCreated(address /* Caonlmua bot */ indexed /* Caonlmua bot */ token0, /* Caonlmua bot */ address /* Caonlmua bot */ indexed /* Caonlmua bot */ token1, /* Caonlmua bot */ address /* Caonlmua bot */ pair, /* Caonlmua bot */ uint);

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ feeTo() /* Caonlmua bot */ external /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (address);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ feeToSetter() /* Caonlmua bot */ external /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (address);

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ getPair(address /* Caonlmua bot */ tokenA, /* Caonlmua bot */ address /* Caonlmua bot */ tokenB) /* Caonlmua bot */ external /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (address /* Caonlmua bot */ pair);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ allPairs(uint) /* Caonlmua bot */ external /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (address /* Caonlmua bot */ pair);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ allPairsLength() /* Caonlmua bot */ external /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (uint);

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ createPair(address /* Caonlmua bot */ tokenA, /* Caonlmua bot */ address /* Caonlmua bot */ tokenB) /* Caonlmua bot */ external /* Caonlmua bot */ returns /* Caonlmua bot */ (address /* Caonlmua bot */ pair);

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ setFeeTo(address) /* Caonlmua bot */ external;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ setFeeToSetter(address) /* Caonlmua bot */ external;
}

interface /* Caonlmua bot */ IUniswapV2Pair /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ event /* Caonlmua bot */ Approval(address /* Caonlmua bot */ indexed /* Caonlmua bot */ owner, /* Caonlmua bot */ address /* Caonlmua bot */ indexed /* Caonlmua bot */ spender, /* Caonlmua bot */ uint /* Caonlmua bot */ value);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ event /* Caonlmua bot */ Transfer(address /* Caonlmua bot */ indexed /* Caonlmua bot */ from, /* Caonlmua bot */ address /* Caonlmua bot */ indexed /* Caonlmua bot */ to, /* Caonlmua bot */ uint /* Caonlmua bot */ value);

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ name() /* Caonlmua bot */ external /* Caonlmua bot */ pure /* Caonlmua bot */ returns /* Caonlmua bot */ (string /* Caonlmua bot */ memory);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ symbol() /* Caonlmua bot */ external /* Caonlmua bot */ pure /* Caonlmua bot */ returns /* Caonlmua bot */ (string /* Caonlmua bot */ memory);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ decimals() /* Caonlmua bot */ external /* Caonlmua bot */ pure /* Caonlmua bot */ returns /* Caonlmua bot */ (uint8);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ totalSupply() /* Caonlmua bot */ external /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (uint);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ balanceOf(address /* Caonlmua bot */ owner) /* Caonlmua bot */ external /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (uint);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ allowance(address /* Caonlmua bot */ owner, /* Caonlmua bot */ address /* Caonlmua bot */ spender) /* Caonlmua bot */ external /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (uint);

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ approve(address /* Caonlmua bot */ spender, /* Caonlmua bot */ uint /* Caonlmua bot */ value) /* Caonlmua bot */ external /* Caonlmua bot */ returns /* Caonlmua bot */ (bool);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ transfer(address /* Caonlmua bot */ to, /* Caonlmua bot */ uint /* Caonlmua bot */ value) /* Caonlmua bot */ external /* Caonlmua bot */ returns /* Caonlmua bot */ (bool);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ transferFrom(address /* Caonlmua bot */ from, /* Caonlmua bot */ address /* Caonlmua bot */ to, /* Caonlmua bot */ uint /* Caonlmua bot */ value) /* Caonlmua bot */ external /* Caonlmua bot */ returns /* Caonlmua bot */ (bool);

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ DOMAIN_SEPARATOR() /* Caonlmua bot */ external /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (bytes32);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ PERMIT_TYPEHASH() /* Caonlmua bot */ external /* Caonlmua bot */ pure /* Caonlmua bot */ returns /* Caonlmua bot */ (bytes32);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ nonces(address /* Caonlmua bot */ owner) /* Caonlmua bot */ external /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (uint);

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ permit(address /* Caonlmua bot */ owner, /* Caonlmua bot */ address /* Caonlmua bot */ spender, /* Caonlmua bot */ uint /* Caonlmua bot */ value, /* Caonlmua bot */ uint /* Caonlmua bot */ deadline, /* Caonlmua bot */ uint8 /* Caonlmua bot */ v, /* Caonlmua bot */ bytes32 /* Caonlmua bot */ r, /* Caonlmua bot */ bytes32 /* Caonlmua bot */ s) /* Caonlmua bot */ external;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ event /* Caonlmua bot */ Burn(address /* Caonlmua bot */ indexed /* Caonlmua bot */ sender, /* Caonlmua bot */ uint /* Caonlmua bot */ amount0, /* Caonlmua bot */ uint /* Caonlmua bot */ amount1, /* Caonlmua bot */ address /* Caonlmua bot */ indexed /* Caonlmua bot */ to);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ event /* Caonlmua bot */ Swap(
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ indexed /* Caonlmua bot */ sender,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amount0In,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amount1In,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amount0Out,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amount1Out,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ indexed /* Caonlmua bot */ to
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ );
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ event /* Caonlmua bot */ Sync(uint112 /* Caonlmua bot */ reserve0, /* Caonlmua bot */ uint112 /* Caonlmua bot */ reserve1);

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ MINIMUM_LIQUIDITY() /* Caonlmua bot */ external /* Caonlmua bot */ pure /* Caonlmua bot */ returns /* Caonlmua bot */ (uint);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ factory() /* Caonlmua bot */ external /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (address);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ token0() /* Caonlmua bot */ external /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (address);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ token1() /* Caonlmua bot */ external /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (address);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ getReserves() /* Caonlmua bot */ external /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (uint112 /* Caonlmua bot */ reserve0, /* Caonlmua bot */ uint112 /* Caonlmua bot */ reserve1, /* Caonlmua bot */ uint32 /* Caonlmua bot */ blockTimestampLast);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ price0CumulativeLast() /* Caonlmua bot */ external /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (uint);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ price1CumulativeLast() /* Caonlmua bot */ external /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (uint);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ kLast() /* Caonlmua bot */ external /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (uint);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ burn(address /* Caonlmua bot */ to) /* Caonlmua bot */ external /* Caonlmua bot */ returns /* Caonlmua bot */ (uint /* Caonlmua bot */ amount0, /* Caonlmua bot */ uint /* Caonlmua bot */ amount1);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ swap(uint /* Caonlmua bot */ amount0Out, /* Caonlmua bot */ uint /* Caonlmua bot */ amount1Out, /* Caonlmua bot */ address /* Caonlmua bot */ to, /* Caonlmua bot */ bytes /* Caonlmua bot */ calldata /* Caonlmua bot */ data) /* Caonlmua bot */ external;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ skim(address /* Caonlmua bot */ to) /* Caonlmua bot */ external;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ sync() /* Caonlmua bot */ external;

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ initialize(address, /* Caonlmua bot */ address) /* Caonlmua bot */ external;
}

interface /* Caonlmua bot */ IUniswapV2Router01 /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ factory() /* Caonlmua bot */ external /* Caonlmua bot */ pure /* Caonlmua bot */ returns /* Caonlmua bot */ (address);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ WETH() /* Caonlmua bot */ external /* Caonlmua bot */ pure /* Caonlmua bot */ returns /* Caonlmua bot */ (address);

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ addLiquidity(
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ tokenA,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ tokenB,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountADesired,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountBDesired,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountAMin,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountBMin,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ to,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ deadline
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ ) /* Caonlmua bot */ external /* Caonlmua bot */ returns /* Caonlmua bot */ (uint /* Caonlmua bot */ amountA, /* Caonlmua bot */ uint /* Caonlmua bot */ amountB, /* Caonlmua bot */ uint /* Caonlmua bot */ liquidity);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ addLiquidityETH(
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ token,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountTokenDesired,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountTokenMin,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountETHMin,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ to,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ deadline
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ ) /* Caonlmua bot */ external /* Caonlmua bot */ payable /* Caonlmua bot */ returns /* Caonlmua bot */ (uint /* Caonlmua bot */ amountToken, /* Caonlmua bot */ uint /* Caonlmua bot */ amountETH, /* Caonlmua bot */ uint /* Caonlmua bot */ liquidity);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ removeLiquidity(
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ tokenA,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ tokenB,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ liquidity,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountAMin,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountBMin,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ to,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ deadline
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ ) /* Caonlmua bot */ external /* Caonlmua bot */ returns /* Caonlmua bot */ (uint /* Caonlmua bot */ amountA, /* Caonlmua bot */ uint /* Caonlmua bot */ amountB);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ removeLiquidityETH(
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ token,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ liquidity,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountTokenMin,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountETHMin,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ to,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ deadline
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ ) /* Caonlmua bot */ external /* Caonlmua bot */ returns /* Caonlmua bot */ (uint /* Caonlmua bot */ amountToken, /* Caonlmua bot */ uint /* Caonlmua bot */ amountETH);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ removeLiquidityWithPermit(
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ tokenA,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ tokenB,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ liquidity,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountAMin,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountBMin,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ to,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ deadline,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ bool /* Caonlmua bot */ approveMax, /* Caonlmua bot */ uint8 /* Caonlmua bot */ v, /* Caonlmua bot */ bytes32 /* Caonlmua bot */ r, /* Caonlmua bot */ bytes32 /* Caonlmua bot */ s
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ ) /* Caonlmua bot */ external /* Caonlmua bot */ returns /* Caonlmua bot */ (uint /* Caonlmua bot */ amountA, /* Caonlmua bot */ uint /* Caonlmua bot */ amountB);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ removeLiquidityETHWithPermit(
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ token,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ liquidity,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountTokenMin,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountETHMin,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ to,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ deadline,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ bool /* Caonlmua bot */ approveMax, /* Caonlmua bot */ uint8 /* Caonlmua bot */ v, /* Caonlmua bot */ bytes32 /* Caonlmua bot */ r, /* Caonlmua bot */ bytes32 /* Caonlmua bot */ s
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ ) /* Caonlmua bot */ external /* Caonlmua bot */ returns /* Caonlmua bot */ (uint /* Caonlmua bot */ amountToken, /* Caonlmua bot */ uint /* Caonlmua bot */ amountETH);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ swapExactTokensForTokens(
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountIn,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountOutMin,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address[] /* Caonlmua bot */ calldata /* Caonlmua bot */ path,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ to,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ deadline
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ ) /* Caonlmua bot */ external /* Caonlmua bot */ returns /* Caonlmua bot */ (uint[] /* Caonlmua bot */ memory /* Caonlmua bot */ amounts);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ swapTokensForExactTokens(
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountOut,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountInMax,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address[] /* Caonlmua bot */ calldata /* Caonlmua bot */ path,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ to,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ deadline
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ ) /* Caonlmua bot */ external /* Caonlmua bot */ returns /* Caonlmua bot */ (uint[] /* Caonlmua bot */ memory /* Caonlmua bot */ amounts);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ swapExactETHForTokens(uint /* Caonlmua bot */ amountOutMin, /* Caonlmua bot */ address[] /* Caonlmua bot */ calldata /* Caonlmua bot */ path, /* Caonlmua bot */ address /* Caonlmua bot */ to, /* Caonlmua bot */ uint /* Caonlmua bot */ deadline)
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ external
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ payable
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ returns /* Caonlmua bot */ (uint[] /* Caonlmua bot */ memory /* Caonlmua bot */ amounts);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ swapTokensForExactETH(uint /* Caonlmua bot */ amountOut, /* Caonlmua bot */ uint /* Caonlmua bot */ amountInMax, /* Caonlmua bot */ address[] /* Caonlmua bot */ calldata /* Caonlmua bot */ path, /* Caonlmua bot */ address /* Caonlmua bot */ to, /* Caonlmua bot */ uint /* Caonlmua bot */ deadline)
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ external
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ returns /* Caonlmua bot */ (uint[] /* Caonlmua bot */ memory /* Caonlmua bot */ amounts);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ swapExactTokensForETH(uint /* Caonlmua bot */ amountIn, /* Caonlmua bot */ uint /* Caonlmua bot */ amountOutMin, /* Caonlmua bot */ address[] /* Caonlmua bot */ calldata /* Caonlmua bot */ path, /* Caonlmua bot */ address /* Caonlmua bot */ to, /* Caonlmua bot */ uint /* Caonlmua bot */ deadline)
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ external
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ returns /* Caonlmua bot */ (uint[] /* Caonlmua bot */ memory /* Caonlmua bot */ amounts);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ swapETHForExactTokens(uint /* Caonlmua bot */ amountOut, /* Caonlmua bot */ address[] /* Caonlmua bot */ calldata /* Caonlmua bot */ path, /* Caonlmua bot */ address /* Caonlmua bot */ to, /* Caonlmua bot */ uint /* Caonlmua bot */ deadline)
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ external
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ payable
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ returns /* Caonlmua bot */ (uint[] /* Caonlmua bot */ memory /* Caonlmua bot */ amounts);

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ quote(uint /* Caonlmua bot */ amountA, /* Caonlmua bot */ uint /* Caonlmua bot */ reserveA, /* Caonlmua bot */ uint /* Caonlmua bot */ reserveB) /* Caonlmua bot */ external /* Caonlmua bot */ pure /* Caonlmua bot */ returns /* Caonlmua bot */ (uint /* Caonlmua bot */ amountB);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ getAmountOut(uint /* Caonlmua bot */ amountIn, /* Caonlmua bot */ uint /* Caonlmua bot */ reserveIn, /* Caonlmua bot */ uint /* Caonlmua bot */ reserveOut) /* Caonlmua bot */ external /* Caonlmua bot */ pure /* Caonlmua bot */ returns /* Caonlmua bot */ (uint /* Caonlmua bot */ amountOut);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ getAmountIn(uint /* Caonlmua bot */ amountOut, /* Caonlmua bot */ uint /* Caonlmua bot */ reserveIn, /* Caonlmua bot */ uint /* Caonlmua bot */ reserveOut) /* Caonlmua bot */ external /* Caonlmua bot */ pure /* Caonlmua bot */ returns /* Caonlmua bot */ (uint /* Caonlmua bot */ amountIn);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ getAmountsOut(uint /* Caonlmua bot */ amountIn, /* Caonlmua bot */ address[] /* Caonlmua bot */ calldata /* Caonlmua bot */ path) /* Caonlmua bot */ external /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (uint[] /* Caonlmua bot */ memory /* Caonlmua bot */ amounts);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ getAmountsIn(uint /* Caonlmua bot */ amountOut, /* Caonlmua bot */ address[] /* Caonlmua bot */ calldata /* Caonlmua bot */ path) /* Caonlmua bot */ external /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (uint[] /* Caonlmua bot */ memory /* Caonlmua bot */ amounts);
}

interface /* Caonlmua bot */ IUniswapV2Router02 /* Caonlmua bot */ is /* Caonlmua bot */ IUniswapV2Router01 /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ removeLiquidityETHSupportingFeeOnTransferTokens(
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ token,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ liquidity,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountTokenMin,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountETHMin,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ to,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ deadline
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ ) /* Caonlmua bot */ external /* Caonlmua bot */ returns /* Caonlmua bot */ (uint /* Caonlmua bot */ amountETH);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ token,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ liquidity,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountTokenMin,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountETHMin,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ to,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ deadline,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ bool /* Caonlmua bot */ approveMax, /* Caonlmua bot */ uint8 /* Caonlmua bot */ v, /* Caonlmua bot */ bytes32 /* Caonlmua bot */ r, /* Caonlmua bot */ bytes32 /* Caonlmua bot */ s
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ ) /* Caonlmua bot */ external /* Caonlmua bot */ returns /* Caonlmua bot */ (uint /* Caonlmua bot */ amountETH);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ swapExactTokensForTokensSupportingFeeOnTransferTokens(
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountIn,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountOutMin,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address[] /* Caonlmua bot */ calldata /* Caonlmua bot */ path,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ to,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ deadline
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ ) /* Caonlmua bot */ external;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ swapExactETHForTokensSupportingFeeOnTransferTokens(
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountOutMin,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address[] /* Caonlmua bot */ calldata /* Caonlmua bot */ path,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ to,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ deadline
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ ) /* Caonlmua bot */ external /* Caonlmua bot */ payable;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ swapExactTokensForETHSupportingFeeOnTransferTokens(
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountIn,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ amountOutMin,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address[] /* Caonlmua bot */ calldata /* Caonlmua bot */ path,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ to,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint /* Caonlmua bot */ deadline
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ ) /* Caonlmua bot */ external;
}
contract /* Caonlmua bot */ King /* Caonlmua bot */ is /* Caonlmua bot */ Context, /* Caonlmua bot */ IERC20, /* Caonlmua bot */ Ownable /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ using /* Caonlmua bot */ SafeMath /* Caonlmua bot */ for /* Caonlmua bot */ uint256;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ using /* Caonlmua bot */ Address /* Caonlmua bot */ for /* Caonlmua bot */ address;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ string /* Caonlmua bot */ private /* Caonlmua bot */ _name /* Caonlmua bot */ = /* Caonlmua bot */ "LuckyTiger";
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ string /* Caonlmua bot */ private /* Caonlmua bot */ _symbol /* Caonlmua bot */ = /* Caonlmua bot */ "LuckyTiger";
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint8 /* Caonlmua bot */ private /* Caonlmua bot */ _decimals /* Caonlmua bot */ = /* Caonlmua bot */ 9;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ payable /* Caonlmua bot */ public /* Caonlmua bot */ marketingWalletAddress;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ payable /* Caonlmua bot */ public /* Caonlmua bot */ teamWalletAddress;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ public /* Caonlmua bot */ immutable /* Caonlmua bot */ deadAddress /* Caonlmua bot */ = /* Caonlmua bot */ 0x000000000000000000000000000000000000dEaD;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ mapping /* Caonlmua bot */ (address /* Caonlmua bot */ => /* Caonlmua bot */ uint256) /* Caonlmua bot */ _balances;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ mapping /* Caonlmua bot */ (address /* Caonlmua bot */ => /* Caonlmua bot */ mapping /* Caonlmua bot */ (address /* Caonlmua bot */ => /* Caonlmua bot */ uint256)) /* Caonlmua bot */ private /* Caonlmua bot */ _allowances;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ mapping /* Caonlmua bot */ (address /* Caonlmua bot */ => /* Caonlmua bot */ bool) /* Caonlmua bot */ public /* Caonlmua bot */ isExcludedFromFee;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ mapping /* Caonlmua bot */ (address /* Caonlmua bot */ => /* Caonlmua bot */ bool) /* Caonlmua bot */ public /* Caonlmua bot */ isWalletLimitExempt;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ mapping /* Caonlmua bot */ (address /* Caonlmua bot */ => /* Caonlmua bot */ bool) /* Caonlmua bot */ public /* Caonlmua bot */ isTxLimitExempt;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ mapping /* Caonlmua bot */ (address /* Caonlmua bot */ => /* Caonlmua bot */ bool) /* Caonlmua bot */ public /* Caonlmua bot */ isMarketPair;

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ public /* Caonlmua bot */ _buyLiquidityFee /* Caonlmua bot */ = /* Caonlmua bot */ 6;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ public /* Caonlmua bot */ _buyMarketingFee /* Caonlmua bot */ = /* Caonlmua bot */ 2;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ public /* Caonlmua bot */ _buyTeamFee /* Caonlmua bot */ = /* Caonlmua bot */ 2;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ public /* Caonlmua bot */ _sellLiquidityFee /* Caonlmua bot */ = /* Caonlmua bot */ 6;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ public /* Caonlmua bot */ _sellMarketingFee /* Caonlmua bot */ = /* Caonlmua bot */ 2;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ public /* Caonlmua bot */ _sellTeamFee /* Caonlmua bot */ = /* Caonlmua bot */ 2;

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ public /* Caonlmua bot */ _liquidityShare /* Caonlmua bot */ = /* Caonlmua bot */ 4;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ public /* Caonlmua bot */ _marketingShare /* Caonlmua bot */ = /* Caonlmua bot */ 4;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ public /* Caonlmua bot */ _teamShare /* Caonlmua bot */ = /* Caonlmua bot */ 16;

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ public /* Caonlmua bot */ _totalTaxIfBuying /* Caonlmua bot */ = /* Caonlmua bot */ 12;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ public /* Caonlmua bot */ _totalTaxIfSelling /* Caonlmua bot */ = /* Caonlmua bot */ 12;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ public /* Caonlmua bot */ _totalDistributionShares /* Caonlmua bot */ = /* Caonlmua bot */ 24;

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ private /* Caonlmua bot */ _totalSupply /* Caonlmua bot */ = /* Caonlmua bot */ 1 /* Caonlmua bot */ * /* Caonlmua bot */ 10**_decimals;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ public /* Caonlmua bot */ _maxTxAmount /* Caonlmua bot */ = /* Caonlmua bot */ 1 /* Caonlmua bot */ * /* Caonlmua bot */ 10**_decimals; /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ public /* Caonlmua bot */ _walletMax /* Caonlmua bot */ = /* Caonlmua bot */ 1 /* Caonlmua bot */ * /* Caonlmua bot */ 10**_decimals;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ private /* Caonlmua bot */ minimumTokensBeforeSwap /* Caonlmua bot */ = /* Caonlmua bot */ 1 /* Caonlmua bot */ * /* Caonlmua bot */ 10**_decimals; /* Caonlmua bot */ 

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ IUniswapV2Router02 /* Caonlmua bot */ public /* Caonlmua bot */ uniswapV2Router;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address /* Caonlmua bot */ public /* Caonlmua bot */ uniswapPair;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ bool /* Caonlmua bot */ inSwapAndLiquify;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ bool /* Caonlmua bot */ public /* Caonlmua bot */ swapAndLiquifyEnabled /* Caonlmua bot */ = /* Caonlmua bot */ true;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ bool /* Caonlmua bot */ public /* Caonlmua bot */ swapAndLiquifyByLimitOnly /* Caonlmua bot */ = /* Caonlmua bot */ false;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ bool /* Caonlmua bot */ public /* Caonlmua bot */ checkWalletLimit /* Caonlmua bot */ = /* Caonlmua bot */ true;

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ event /* Caonlmua bot */ SwapAndLiquifyEnabledUpdated(bool /* Caonlmua bot */ enabled);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ event /* Caonlmua bot */ SwapAndLiquify(
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ tokensSwapped,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ ethReceived,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ tokensIntoLiqudity
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ );
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ event /* Caonlmua bot */ SwapETHForTokens(
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ amountIn,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address[] /* Caonlmua bot */ path
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ );
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ event /* Caonlmua bot */ SwapTokensForETH(
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ amountIn,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address[] /* Caonlmua bot */ path
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ );
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ modifier /* Caonlmua bot */ lockTheSwap /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ inSwapAndLiquify /* Caonlmua bot */ = /* Caonlmua bot */ true;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ inSwapAndLiquify /* Caonlmua bot */ = /* Caonlmua bot */ false;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ constructor /* Caonlmua bot */ () /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ IUniswapV2Router02 /* Caonlmua bot */ _uniswapV2Router /* Caonlmua bot */ = /* Caonlmua bot */ IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uniswapPair /* Caonlmua bot */ = /* Caonlmua bot */ IUniswapV2Factory(_uniswapV2Router.factory())
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ .createPair(address(this), /* Caonlmua bot */ _uniswapV2Router.WETH());

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uniswapV2Router /* Caonlmua bot */ = /* Caonlmua bot */ _uniswapV2Router;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _allowances[address(this)][address(uniswapV2Router)] /* Caonlmua bot */ = /* Caonlmua bot */ _totalSupply;

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ isExcludedFromFee[owner()] /* Caonlmua bot */ = /* Caonlmua bot */ true;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ isExcludedFromFee[address(this)] /* Caonlmua bot */ = /* Caonlmua bot */ true;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _totalTaxIfBuying /* Caonlmua bot */ = /* Caonlmua bot */ _buyLiquidityFee.add(_buyMarketingFee).add(_buyTeamFee);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _totalTaxIfSelling /* Caonlmua bot */ = /* Caonlmua bot */ _sellLiquidityFee.add(_sellMarketingFee).add(_sellTeamFee);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _totalDistributionShares /* Caonlmua bot */ = /* Caonlmua bot */ _liquidityShare.add(_marketingShare).add(_teamShare);

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ isWalletLimitExempt[owner()] /* Caonlmua bot */ = /* Caonlmua bot */ true;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ isWalletLimitExempt[address(uniswapPair)] /* Caonlmua bot */ = /* Caonlmua bot */ true;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ isWalletLimitExempt[address(this)] /* Caonlmua bot */ = /* Caonlmua bot */ true;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ isTxLimitExempt[owner()] /* Caonlmua bot */ = /* Caonlmua bot */ true;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ isTxLimitExempt[address(this)] /* Caonlmua bot */ = /* Caonlmua bot */ true;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ isMarketPair[address(uniswapPair)] /* Caonlmua bot */ = /* Caonlmua bot */ true;

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ teamWalletAddress /* Caonlmua bot */ = /* Caonlmua bot */ payable(owner());
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ marketingWalletAddress /* Caonlmua bot */ = /* Caonlmua bot */ payable(owner());

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _balances[_msgSender()] /* Caonlmua bot */ = /* Caonlmua bot */ _totalSupply;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ emit /* Caonlmua bot */ Transfer(address(0), /* Caonlmua bot */ _msgSender(), /* Caonlmua bot */ _totalSupply);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ name() /* Caonlmua bot */ public /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (string /* Caonlmua bot */ memory) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ _name;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ symbol() /* Caonlmua bot */ public /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (string /* Caonlmua bot */ memory) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ _symbol;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ decimals() /* Caonlmua bot */ public /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (uint8) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ _decimals;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ totalSupply() /* Caonlmua bot */ public /* Caonlmua bot */ view /* Caonlmua bot */ override /* Caonlmua bot */ returns /* Caonlmua bot */ (uint256) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ _totalSupply;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ balanceOf(address /* Caonlmua bot */ account) /* Caonlmua bot */ public /* Caonlmua bot */ view /* Caonlmua bot */ override /* Caonlmua bot */ returns /* Caonlmua bot */ (uint256) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ _balances[account];
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ allowance(address /* Caonlmua bot */ owner, /* Caonlmua bot */ address /* Caonlmua bot */ spender) /* Caonlmua bot */ public /* Caonlmua bot */ view /* Caonlmua bot */ override /* Caonlmua bot */ returns /* Caonlmua bot */ (uint256) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ _allowances[owner][spender];
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ increaseAllowance(address /* Caonlmua bot */ spender, /* Caonlmua bot */ uint256 /* Caonlmua bot */ addedValue) /* Caonlmua bot */ public /* Caonlmua bot */ virtual /* Caonlmua bot */ returns /* Caonlmua bot */ (bool) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _approve(_msgSender(), /* Caonlmua bot */ spender, /* Caonlmua bot */ _allowances[_msgSender()][spender].add(addedValue));
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ true;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ decreaseAllowance(address /* Caonlmua bot */ spender, /* Caonlmua bot */ uint256 /* Caonlmua bot */ subtractedValue) /* Caonlmua bot */ public /* Caonlmua bot */ virtual /* Caonlmua bot */ returns /* Caonlmua bot */ (bool) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _approve(_msgSender(), /* Caonlmua bot */ spender, /* Caonlmua bot */ _allowances[_msgSender()][spender].sub(subtractedValue, /* Caonlmua bot */ "ERC20: /* Caonlmua bot */ decreased /* Caonlmua bot */ allowance /* Caonlmua bot */ below /* Caonlmua bot */ zero"));
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ true;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ minimumTokensBeforeSwapAmount() /* Caonlmua bot */ public /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (uint256) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ minimumTokensBeforeSwap;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ approve(address /* Caonlmua bot */ spender, /* Caonlmua bot */ uint256 /* Caonlmua bot */ amount) /* Caonlmua bot */ public /* Caonlmua bot */ override /* Caonlmua bot */ returns /* Caonlmua bot */ (bool) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _approve(_msgSender(), /* Caonlmua bot */ spender, /* Caonlmua bot */ amount);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ true;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ _approve(address /* Caonlmua bot */ owner, /* Caonlmua bot */ address /* Caonlmua bot */ spender, /* Caonlmua bot */ uint256 /* Caonlmua bot */ amount) /* Caonlmua bot */ private /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ require(owner /* Caonlmua bot */ != /* Caonlmua bot */ address(0), /* Caonlmua bot */ "ERC20: /* Caonlmua bot */ approve /* Caonlmua bot */ from /* Caonlmua bot */ the /* Caonlmua bot */ zero /* Caonlmua bot */ address");
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ require(spender /* Caonlmua bot */ != /* Caonlmua bot */ address(0), /* Caonlmua bot */ "ERC20: /* Caonlmua bot */ approve /* Caonlmua bot */ to /* Caonlmua bot */ the /* Caonlmua bot */ zero /* Caonlmua bot */ address");

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _allowances[owner][spender] /* Caonlmua bot */ = /* Caonlmua bot */ amount;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ emit /* Caonlmua bot */ Approval(owner, /* Caonlmua bot */ spender, /* Caonlmua bot */ amount);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ setMarketPairStatus(address /* Caonlmua bot */ account, /* Caonlmua bot */ bool /* Caonlmua bot */ newValue) /* Caonlmua bot */ public /* Caonlmua bot */ onlyOwner /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ isMarketPair[account] /* Caonlmua bot */ = /* Caonlmua bot */ newValue;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ setIsTxLimitExempt(address /* Caonlmua bot */ holder, /* Caonlmua bot */ bool /* Caonlmua bot */ exempt) /* Caonlmua bot */ external /* Caonlmua bot */ onlyOwner(){
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ isTxLimitExempt[holder] /* Caonlmua bot */ = /* Caonlmua bot */ exempt;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ setIsExcludedFromFee(address /* Caonlmua bot */ account, /* Caonlmua bot */ bool /* Caonlmua bot */ newValue) /* Caonlmua bot */ public /* Caonlmua bot */ onlyOwner /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ isExcludedFromFee[account] /* Caonlmua bot */ = /* Caonlmua bot */ newValue;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ setBuyTaxes(uint256 /* Caonlmua bot */ newLiquidityTax, /* Caonlmua bot */ uint256 /* Caonlmua bot */ newMarketingTax, /* Caonlmua bot */ uint256 /* Caonlmua bot */ newTeamTax) /* Caonlmua bot */ external /* Caonlmua bot */ onlyOwner() /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _buyLiquidityFee /* Caonlmua bot */ = /* Caonlmua bot */ newLiquidityTax;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _buyMarketingFee /* Caonlmua bot */ = /* Caonlmua bot */ newMarketingTax;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _buyTeamFee /* Caonlmua bot */ = /* Caonlmua bot */ newTeamTax;

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _totalTaxIfBuying /* Caonlmua bot */ = /* Caonlmua bot */ _buyLiquidityFee.add(_buyMarketingFee).add(_buyTeamFee);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ setSellTaxes(uint256 /* Caonlmua bot */ newLiquidityTax, /* Caonlmua bot */ uint256 /* Caonlmua bot */ newMarketingTax, /* Caonlmua bot */ uint256 /* Caonlmua bot */ newTeamTax) /* Caonlmua bot */ external /* Caonlmua bot */ onlyOwner() /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _sellLiquidityFee /* Caonlmua bot */ = /* Caonlmua bot */ newLiquidityTax;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _sellMarketingFee /* Caonlmua bot */ = /* Caonlmua bot */ newMarketingTax;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _sellTeamFee /* Caonlmua bot */ = /* Caonlmua bot */ newTeamTax;

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _totalTaxIfSelling /* Caonlmua bot */ = /* Caonlmua bot */ _sellLiquidityFee.add(_sellMarketingFee).add(_sellTeamFee);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ setDistributionSettings(uint256 /* Caonlmua bot */ newLiquidityShare, /* Caonlmua bot */ uint256 /* Caonlmua bot */ newMarketingShare, /* Caonlmua bot */ uint256 /* Caonlmua bot */ newTeamShare) /* Caonlmua bot */ external /* Caonlmua bot */ onlyOwner() /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _liquidityShare /* Caonlmua bot */ = /* Caonlmua bot */ newLiquidityShare;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _marketingShare /* Caonlmua bot */ = /* Caonlmua bot */ newMarketingShare;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _teamShare /* Caonlmua bot */ = /* Caonlmua bot */ newTeamShare;

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _totalDistributionShares /* Caonlmua bot */ = /* Caonlmua bot */ _liquidityShare.add(_marketingShare).add(_teamShare);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ enableDisableWalletLimit(bool /* Caonlmua bot */ newValue) /* Caonlmua bot */ external /* Caonlmua bot */ onlyOwner /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ checkWalletLimit /* Caonlmua bot */ = /* Caonlmua bot */ newValue;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ setIsWalletLimitExempt(address /* Caonlmua bot */ holder, /* Caonlmua bot */ bool /* Caonlmua bot */ exempt) /* Caonlmua bot */ external /* Caonlmua bot */ onlyOwner /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ isWalletLimitExempt[holder] /* Caonlmua bot */ = /* Caonlmua bot */ exempt;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ setWalletLimit(uint256 /* Caonlmua bot */ newLimit) /* Caonlmua bot */ external /* Caonlmua bot */ onlyOwner /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _walletMax /* Caonlmua bot */  /* Caonlmua bot */ = /* Caonlmua bot */ newLimit;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ setNumTokensBeforeSwap(uint256 /* Caonlmua bot */ newLimit) /* Caonlmua bot */ external /* Caonlmua bot */ onlyOwner() /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ minimumTokensBeforeSwap /* Caonlmua bot */ = /* Caonlmua bot */ newLimit;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ setMarketingWalletAddress(address /* Caonlmua bot */ newAddress) /* Caonlmua bot */ external /* Caonlmua bot */ onlyOwner() /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ marketingWalletAddress /* Caonlmua bot */ = /* Caonlmua bot */ payable(newAddress);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ setTeamWalletAddress(address /* Caonlmua bot */ newAddress) /* Caonlmua bot */ external /* Caonlmua bot */ onlyOwner() /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ teamWalletAddress /* Caonlmua bot */ = /* Caonlmua bot */ payable(newAddress);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ setSwapAndLiquifyEnabled(bool /* Caonlmua bot */ _enabled) /* Caonlmua bot */ public /* Caonlmua bot */ onlyOwner(){
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ swapAndLiquifyEnabled /* Caonlmua bot */ = /* Caonlmua bot */ _enabled;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ emit /* Caonlmua bot */ SwapAndLiquifyEnabledUpdated(_enabled);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ setSwapAndLiquifyByLimitOnly(bool /* Caonlmua bot */ newValue) /* Caonlmua bot */ public /* Caonlmua bot */ onlyOwner /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ swapAndLiquifyByLimitOnly /* Caonlmua bot */ = /* Caonlmua bot */ newValue;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ getCirculatingSupply() /* Caonlmua bot */ public /* Caonlmua bot */ view /* Caonlmua bot */ returns /* Caonlmua bot */ (uint256) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ _totalSupply.sub(balanceOf(deadAddress));
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ transferToAddressETH(address /* Caonlmua bot */ payable /* Caonlmua bot */ recipient, /* Caonlmua bot */ uint256 /* Caonlmua bot */ amount) /* Caonlmua bot */ private /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ recipient.transfer(amount);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ changeRouterVersion(address /* Caonlmua bot */ newRouterAddress) /* Caonlmua bot */ public /* Caonlmua bot */ onlyOwner /* Caonlmua bot */ returns(address /* Caonlmua bot */ newPairAddress) /* Caonlmua bot */ {

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ IUniswapV2Router02 /* Caonlmua bot */ _uniswapV2Router /* Caonlmua bot */ = /* Caonlmua bot */ IUniswapV2Router02(newRouterAddress); /* Caonlmua bot */ 

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ newPairAddress /* Caonlmua bot */ = /* Caonlmua bot */ IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), /* Caonlmua bot */ _uniswapV2Router.WETH());

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ if(newPairAddress /* Caonlmua bot */ == /* Caonlmua bot */ address(0))
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ newPairAddress /* Caonlmua bot */ = /* Caonlmua bot */ IUniswapV2Factory(_uniswapV2Router.factory())
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ .createPair(address(this), /* Caonlmua bot */ _uniswapV2Router.WETH());
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uniswapPair /* Caonlmua bot */ = /* Caonlmua bot */ newPairAddress;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uniswapV2Router /* Caonlmua bot */ = /* Caonlmua bot */ _uniswapV2Router; /* Caonlmua bot */ 

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ isWalletLimitExempt[address(uniswapPair)] /* Caonlmua bot */ = /* Caonlmua bot */ true;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ isMarketPair[address(uniswapPair)] /* Caonlmua bot */ = /* Caonlmua bot */ true;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ receive() /* Caonlmua bot */ external /* Caonlmua bot */ payable /* Caonlmua bot */ {}

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ transfer(address /* Caonlmua bot */ recipient, /* Caonlmua bot */ uint256 /* Caonlmua bot */ amount) /* Caonlmua bot */ public /* Caonlmua bot */ override /* Caonlmua bot */ returns /* Caonlmua bot */ (bool) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _transfer(_msgSender(), /* Caonlmua bot */ recipient, /* Caonlmua bot */ amount);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ true;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ transferFrom(address /* Caonlmua bot */ sender, /* Caonlmua bot */ address /* Caonlmua bot */ recipient, /* Caonlmua bot */ uint256 /* Caonlmua bot */ amount) /* Caonlmua bot */ public /* Caonlmua bot */ override /* Caonlmua bot */ returns /* Caonlmua bot */ (bool) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _transfer(sender, /* Caonlmua bot */ recipient, /* Caonlmua bot */ amount);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _approve(sender, /* Caonlmua bot */ _msgSender(), /* Caonlmua bot */ _allowances[sender][_msgSender()].sub(amount, /* Caonlmua bot */ "ERC20: /* Caonlmua bot */ transfer /* Caonlmua bot */ amount /* Caonlmua bot */ exceeds /* Caonlmua bot */ allowance"));
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ true;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ _transfer(address /* Caonlmua bot */ sender, /* Caonlmua bot */ address /* Caonlmua bot */ recipient, /* Caonlmua bot */ uint256 /* Caonlmua bot */ amount) /* Caonlmua bot */ private /* Caonlmua bot */ returns /* Caonlmua bot */ (bool) /* Caonlmua bot */ {

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ require(sender /* Caonlmua bot */ != /* Caonlmua bot */ address(0), /* Caonlmua bot */ "ERC20: /* Caonlmua bot */ transfer /* Caonlmua bot */ from /* Caonlmua bot */ the /* Caonlmua bot */ zero /* Caonlmua bot */ address");
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ require(recipient /* Caonlmua bot */ != /* Caonlmua bot */ address(0), /* Caonlmua bot */ "ERC20: /* Caonlmua bot */ transfer /* Caonlmua bot */ to /* Caonlmua bot */ the /* Caonlmua bot */ zero /* Caonlmua bot */ address");
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ if(inSwapAndLiquify)
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ { /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ _basicTransfer(sender, /* Caonlmua bot */ recipient, /* Caonlmua bot */ amount); /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ else
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ if(!isTxLimitExempt[sender] /* Caonlmua bot */ && /* Caonlmua bot */ !isTxLimitExempt[recipient]) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ require(amount /* Caonlmua bot */ <= /* Caonlmua bot */ _maxTxAmount, /* Caonlmua bot */ "Transfer /* Caonlmua bot */ amount /* Caonlmua bot */ exceeds /* Caonlmua bot */ the /* Caonlmua bot */ maxTxAmount.");
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ } /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ contractTokenBalance /* Caonlmua bot */ = /* Caonlmua bot */ balanceOf(address(this));
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ bool /* Caonlmua bot */ overMinimumTokenBalance /* Caonlmua bot */ = /* Caonlmua bot */ contractTokenBalance /* Caonlmua bot */ >= /* Caonlmua bot */ minimumTokensBeforeSwap;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ if /* Caonlmua bot */ (overMinimumTokenBalance /* Caonlmua bot */ && /* Caonlmua bot */ !inSwapAndLiquify /* Caonlmua bot */ && /* Caonlmua bot */ !isMarketPair[sender] /* Caonlmua bot */ && /* Caonlmua bot */ swapAndLiquifyEnabled) /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ if(swapAndLiquifyByLimitOnly)
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ contractTokenBalance /* Caonlmua bot */ = /* Caonlmua bot */ minimumTokensBeforeSwap;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ swapAndLiquify(contractTokenBalance); /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _balances[sender] /* Caonlmua bot */ = /* Caonlmua bot */ _balances[sender].sub(amount, /* Caonlmua bot */ "Insufficient /* Caonlmua bot */ Balance");

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ finalAmount /* Caonlmua bot */ = /* Caonlmua bot */ (isExcludedFromFee[sender] /* Caonlmua bot */ || /* Caonlmua bot */ isExcludedFromFee[recipient]) /* Caonlmua bot */ ? /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ amount /* Caonlmua bot */ : /* Caonlmua bot */ takeFee(sender, /* Caonlmua bot */ recipient, /* Caonlmua bot */ amount);

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ if(checkWalletLimit /* Caonlmua bot */ && /* Caonlmua bot */ !isWalletLimitExempt[recipient])
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ require(balanceOf(recipient).add(finalAmount) /* Caonlmua bot */ <= /* Caonlmua bot */ _walletMax);

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _balances[recipient] /* Caonlmua bot */ = /* Caonlmua bot */ _balances[recipient].add(finalAmount);

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ emit /* Caonlmua bot */ Transfer(sender, /* Caonlmua bot */ recipient, /* Caonlmua bot */ finalAmount);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ true;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ _basicTransfer(address /* Caonlmua bot */ sender, /* Caonlmua bot */ address /* Caonlmua bot */ recipient, /* Caonlmua bot */ uint256 /* Caonlmua bot */ amount) /* Caonlmua bot */ internal /* Caonlmua bot */ returns /* Caonlmua bot */ (bool) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _balances[sender] /* Caonlmua bot */ = /* Caonlmua bot */ _balances[sender].sub(amount, /* Caonlmua bot */ "Insufficient /* Caonlmua bot */ Balance");
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _balances[recipient] /* Caonlmua bot */ = /* Caonlmua bot */ _balances[recipient].add(amount);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ emit /* Caonlmua bot */ Transfer(sender, /* Caonlmua bot */ recipient, /* Caonlmua bot */ amount);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ true;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ swapAndLiquify(uint256 /* Caonlmua bot */ tAmount) /* Caonlmua bot */ private /* Caonlmua bot */ lockTheSwap /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ tokensForLP /* Caonlmua bot */ = /* Caonlmua bot */ tAmount.mul(_liquidityShare).div(_totalDistributionShares).div(2);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ tokensForSwap /* Caonlmua bot */ = /* Caonlmua bot */ tAmount.sub(tokensForLP);

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ swapTokensForEth(tokensForSwap);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ amountReceived /* Caonlmua bot */ = /* Caonlmua bot */ address(this).balance;

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ totalBNBFee /* Caonlmua bot */ = /* Caonlmua bot */ _totalDistributionShares.sub(_liquidityShare.div(2));
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ amountBNBLiquidity /* Caonlmua bot */ = /* Caonlmua bot */ amountReceived.mul(_liquidityShare).div(totalBNBFee).div(2);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ amountBNBTeam /* Caonlmua bot */ = /* Caonlmua bot */ amountReceived.mul(_teamShare).div(totalBNBFee);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ amountBNBMarketing /* Caonlmua bot */ = /* Caonlmua bot */ amountReceived.sub(amountBNBLiquidity).sub(amountBNBTeam);

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ if(amountBNBMarketing /* Caonlmua bot */ > /* Caonlmua bot */ 0)
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ transferToAddressETH(marketingWalletAddress, /* Caonlmua bot */ amountBNBMarketing);

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ if(amountBNBTeam /* Caonlmua bot */ > /* Caonlmua bot */ 0)
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ transferToAddressETH(teamWalletAddress, /* Caonlmua bot */ amountBNBTeam);

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ if(amountBNBLiquidity /* Caonlmua bot */ > /* Caonlmua bot */ 0 /* Caonlmua bot */ && /* Caonlmua bot */ tokensForLP /* Caonlmua bot */ > /* Caonlmua bot */ 0)
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ addLiquidity(tokensForLP, /* Caonlmua bot */ amountBNBLiquidity);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ swapTokensForEth(uint256 /* Caonlmua bot */ tokenAmount) /* Caonlmua bot */ private /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address[] /* Caonlmua bot */ memory /* Caonlmua bot */ path /* Caonlmua bot */ = /* Caonlmua bot */ new /* Caonlmua bot */ address[](2);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ path[0] /* Caonlmua bot */ = /* Caonlmua bot */ address(this);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ path[1] /* Caonlmua bot */ = /* Caonlmua bot */ uniswapV2Router.WETH();

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _approve(address(this), /* Caonlmua bot */ address(uniswapV2Router), /* Caonlmua bot */ tokenAmount);

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ tokenAmount,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 0, /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ path,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address(this),
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ block.timestamp
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ );
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ emit /* Caonlmua bot */ SwapTokensForETH(tokenAmount, /* Caonlmua bot */ path);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ addLiquidity(uint256 /* Caonlmua bot */ tokenAmount, /* Caonlmua bot */ uint256 /* Caonlmua bot */ ethAmount) /* Caonlmua bot */ private /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _approve(address(this), /* Caonlmua bot */ address(uniswapV2Router), /* Caonlmua bot */ tokenAmount);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uniswapV2Router.addLiquidityETH{value: /* Caonlmua bot */ ethAmount}(
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ address(this),
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ tokenAmount,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 0, /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 0,
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ owner(),
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ block.timestamp
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ );
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ function /* Caonlmua bot */ takeFee(address /* Caonlmua bot */ sender, /* Caonlmua bot */ address /* Caonlmua bot */ recipient, /* Caonlmua bot */ uint256 /* Caonlmua bot */ amount) /* Caonlmua bot */ internal /* Caonlmua bot */ returns /* Caonlmua bot */ (uint256) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ uint256 /* Caonlmua bot */ feeAmount /* Caonlmua bot */ = /* Caonlmua bot */ 0;
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ if(isMarketPair[sender]) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ feeAmount /* Caonlmua bot */ = /* Caonlmua bot */ amount.mul(_totalTaxIfBuying).div(100);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ else /* Caonlmua bot */ if(isMarketPair[recipient]) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ feeAmount /* Caonlmua bot */ = /* Caonlmua bot */ amount.mul(_totalTaxIfSelling).div(100);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ if(feeAmount /* Caonlmua bot */ > /* Caonlmua bot */ 0) /* Caonlmua bot */ {
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ _balances[address(this)] /* Caonlmua bot */ = /* Caonlmua bot */ _balances[address(this)].add(feeAmount);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ emit /* Caonlmua bot */ Transfer(sender, /* Caonlmua bot */ address(this), /* Caonlmua bot */ feeAmount);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }

 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ return /* Caonlmua bot */ amount.sub(feeAmount);
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ }
 /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */  /* Caonlmua bot */ 
}