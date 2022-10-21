// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Brain Pain
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                     ....          .                    .             .                          ...                                          //
//                                      ..           .                   . .            .                          ...                                          //
//                                    . . .         ....                  ..           . .              ..         ..                                           //
//                                   .   .           .::                  :v            i:             ...          j.                                          //
//                                      JQ            i7.                 B5.:         .q.j            :u          .B                       . .                 //
//                                      dB7           ..:.              .vL1rE:       iPi:Ki         .:sXr         2Q                     ....                  //
//                                      BEBi          : rSL             i2iiXLP.      Pv2Js5        :.i7rE      ..7BS      .            ...                     //
//                                 ..  rBv1B     i.  .15L2bjr.          r5PX.sqR     vP7XEdb:      :v.P. R     .:vri:     ..           ...                      //
//                                 ..  b5r  R   iBg2  ruvu: :v7:.r:     BEUPBsqQQ    b7iudU sY     v:dBX P7   ri.. r.     ...         ...                       //
//                                   . BLr7:DJ   QSr  .i   7.  :rUqL   JB.LBQs :gZ  i7u :Z2r jU.  Pi ::  sB  7M.  .v      ...        ....                       //
//                             ..      BQ.PgLiB :Mi:   r uBBBBI.  iME  Q  u1j7i iM: :jv i:rKi KBMMs :     QE2r5   r.      ...   .   ..r..                       //
//                             ..:     PBv:dS.JriB:..iB i BBQBQBR. .vBBg :urY71r iqI:U i27:Y  .1QB  : QQ: :BsJ:  L2.      ...   ..   .:7                        //
//                             ..r     iBY1iI.JBY:J.. 7 i: BZi:i7SL  rQB:    BbUs 7Zbi 7QBB. jDg sR: 7BBB 7B.2  LqXr      :i.  ....   .v7                       //
//                          :    i.    .BgPY  7UQ  ruu v:U. ..:i7PU. ::J27 .qMJ1P: .uI  BS:  MP   RB:..B. BgU: rs:7:  .. .7v   . ..   .LS.                      //
//                          .i:  .:     IBIr E.SB.  .BJ.r : :rJvr.: rr : rS:..::2B ri  7Bqr MJ 7i 7:...  ZrJX D   7   .QDv s    ...   .Jq.                      //
//                            LU  uQu   :QU rQ.Bq: uS 7Lr B51MPgBB  i   .  i Kr:LY v.  Kr: Qi DB .  :.  5R L :Bu ..  rbB:  X   .g...  .7v.                      //
//                             :viDB.    7Bj Q.g: .QBr . :YS7   :QD.  :QBQQr.v: B:  L.iB. 7..::Er :Bd:  B  ::.DDY..  7: rr 7ii gb   .  gX                       //
//                               KQ5:     2B. .5   Brr7i.i27 .j.  vBE 7BBri:.K rMi 7D:i.   :r  i:.iBQXr7....i DDBBBBML BB i7S iBi   .:vD                        //
//                               .QEvr7.   BQ  Y. .s:QB7:LJ  ZBdi  ir EBr   Ri ::r.  .7r PBBu .r:. :qBBXr1:.r BQi7EBB:gB :r71riBr    :iJ ..                     //
//                                MBrJDg   rBv S.IS:YQb.rBB. i: .rdB. ...IjQg  ...   Jri YZvQr ri: .YB5  gS ..BLrrrP bBu v:bXS Br    .:P7:                      //
//                                Kgj:JBg7  QK.7: i .1Y..rBB  ..vr: . r  7BRAIN-PAIN X:     g7rvr: YBq:.dBB. ivKrMgIEQq: ii:  .7r    1BL                        //
//                                iD5u :BBP :Ki.i Ur ..PBQBB  2BU:. . BD:.      :Pr  :qB77 .r JBZBirBJvBQ1.   7JYPMBB    .:.  :rr  :vPg.                        //
//                                .E.r  .dBBrXL.s B:   .PPr:: rB: i   BB77  Qi  .:Z:XBBPr: :  .PQQu  .LBB7 iZv .. 7QB . PXv  ..7i  :Jjb                         //
//                                .B5r:  27XBM5:g.7::     :gr  ..iZB.:BI. iBr..   QBBP..   jd7 ibg. .:iLv gBb. . .rBM . BB7  ::v    sQS                         //
//                                ..sQv  u   iQYB .     .7  BdirLIRBBBB  dB  DB.  .P..2Qi17 BBQ.  :u:Lj  :EB   :i.5Bi  .5B  : d     YBP                         //
//                                 .iqg. v.   7IP rD:   :qq: PBBMBBBBg .BBi. KB: . ::rQB.:r  bBBB7.i r:   bi sDSSgBB : :qg   Q2 Qi  5IE                         //
//                                  uP7  5:  :::S 7Pqrri rBQI :qBQBM: uBQ: .L..i ru rE7 r: r  .QB.         .UgDZEQB. . vB:i XQ BB. :Yq2                         //
//                             .     gQ  Br  :::r 5B2BQRs .BBg: :BX.rBME. IBDggBr BX . QY iQBR. :..      rQBqX1SDBg .  ig ::g iBB  L2g.                         //
//                              .    .Bs QQ  ::Id 5BMXKXBQ  uBBY..igB2Y.2BBg:. sI  QjiB: dBQBBBi Pj      BBBBBBQBB.  5 Lr Lb :BBI :5YY                          //
//                              ...   .B..B. .i2B DBBQgMBBBr rBB1ugBvi:qBBP:::ivPZ .BB  BBPULY5BP      v: iBBBBBBB   J.Z  B2 ZsBD P:i:                          //
//                              ....   :D rq  rJP QBBBBBBBBBQ .uBBBr .i:     vBBP vQ.PB  gQSEBBB. QBd 5BB7  QBBBBBq77 Pr LBi :RB.:S v                           //
//                              ....    rI g. iI  QBBBBBBBBBd iBQdPQ7  rL:i1sBBr Xq . 5B. BBBBQ  BBYvS:rBBQ. LBBBBBB vb  i:v ZBb 1r:7                           //
//                              ....     ruJi rB. .PBBBBBBBiiQBb i1DBQ. bBPBBq  :. gBU .U iQBs rBP.  :Y iRBBP  BBBB :B:  i7i.BB5 i:L.                           //
//                               .:BJ      757JB .   :iSBQ.LBBi jdvi1BBY :BBr    JBBBBRi  .Br UBj  MQ .j : XBP. .   Bi  :ug:MBB  7rr                            //
//                                 iB2iP.r.  rig:v7 :   v.PBB  RBBgr.:XBB:      gBBBBBBBd  . QBY  QBBM  i   ..r  :S1D:  qUsDBMQ  Y7                             //
//                                . Ib.RBPUgQ:KY 5M.r   :BBD  BBBBBBBJ.iBB    YBQBBBBBBBBBY :B. iBr  BQsr  i dL  7QbR7 :qissrBB.idi                             //
//                          .U      .P  :ubib1Qvirid7  7BBs :BBBBBBBBBB7v7.. RBBBBBBBQBBBQB .. ZD.   DBBB. Q YK rQBvP. .:.ui M525P                              //
//                          BB7      Rq   :b .Krvi BQ ..BY iBBBKQMi2BBBBQ  7::BBBBBBBBBBBg    :BB. q: BBBB sd.vMPBi:U.. i.dr 7 PIi                              //
//                         dBrB:     :B:   7I .KIv  Bi    . BBr7    BQBQi ...   .vBBBQBQBB :I YQQB .B  57.iKBQK:SRu.v : 27Z  Uvir                               //
//                        .B. rB      Qr    i..RQ:  MD. Xd :QBvSL:. BBBB..B7 .    BBQBBBQBq B. . .iiXB:::IgBQi 7 B: S    rv :Q:7r.                              //
//                        Y5   BB     RS   .. .5Zv  gBBvBB iLLr7rB: 1PPB7 BU ..r KBriQB   .:BB5Y22ZQQ:E    2:7   g .E .rP...Q5.gr                               //
//                        ..vQ DB.    IB.  .:  PDB  2r .XBEr:5J52BBYs5:.i.ZB  Sg :. . r vvSB71QL   vP ir   g .i UI LYi2BU LPIsUS                                //
//                          5Bi BB    :EP  .i  ZEg. rQ  jrB.  rqZQMQ. iUbJ2EZ.EL  Y7r5  QB..  E    KK  X  vS .v B. QdBPi .B2iRD                                 //
//                          27:: BB    :ZP..i  D Ku  B  g vB   Ed.rRu B5.d..QEBB Y.. iL:BB i  :7   u2  g. gr :r d iPPQi rijJvR                                  //
//                           U.L iQ     iLXr.i S::g. 71 R  BI rZb  DP..b:Q  iU.BP1 BB  gjL.1 q 2.Q Pi  Q. B. i:iL 27Mi:v. L7Qv                                  //
//                           22 :. i     :72:v.vr q7  Q.d.. B.vMs  .BK usR . j.dRJ Bdr B.:Lv B I. .R  .g Y1  :.D :Q2Q7:  vj5IL                                  //
//                .I5BBBEI7  i2i :iX.      UB..qr gi  7X2 Q JdLZr   PB: 7Q:1 rir D 7:r i :K iB :. X.: iR.Q : uB. Bi:7.  rKR rs                                  //
//                 rQ:LBbsQBr ULL :.s.      vg IY vg   QK jR XKZ:   :B2 iR.d2 sr     .g: :R 2B.  72 B 7Bg 7s R. qS ui  iKQ: rU                                  //
//                  .:   iUBI . B:.I r  .r   7.r5 .Qb  :R.jiq.BD .v. rS.:g:PQ g: BBb .BQL d QB: .5 iB iQi B    Yg.1vv :MY   vU                                  //
//                         :BBX rB.:u iv:XI. . rq5. BI  .:M 11uQ BB: .ZU.PiXB dL BQBP BBQ . QB i:I BB..q iBQd :Br.:i .BY    Yu                                  //
//                           QBq D7 vQ .Y 7Z ri.BBB uQs  :B .Qig u:.. iE LLiB:.Z Q: . BBB  iBg RB. :B.  .QBBs B5r  : Bi     uL                                  //
//                            BB U1 gBBi  :i .uPY2BM XuU .B  q7DX  vK  XriU BP 7 B1:  SBB  bB5 Q. r ZB :QBBS gXK  i1I.rY    1J                                  //
//                             QQ i.:BBBBJ .:  .J.7BL 1vIiB ..DrU  77j  Z55 .  .5QB .  B. v Br   .2: BBQBBQ 2Rs  :BL..ui    rs                                  //
//                              BB d LBBBBBY..g7:v: B1 JBPB . Bi . L.7r .QK  U sQBq Y PBi B LB.i 2:r BBBQB .QS. rB.::.Qi     s                                  //
//                              :Bi Z BBBBBQBQBBK i  QX IBB7  Lu7B Ki Bi  1  sv BQQ g vB5 XJ BBB g . dBBBr BB:  Yvi. PI .   .g                                  //
//                               BQ :i YgBBBBBBBDBj.rBBS :PBX :DY: Pir.B r: .IQ :BQ gX BD Y1 iQ JY : 7BBB sBY 7.X:   7i7    .B                                  //
//                               BBB i:  .BBBBBBERDBBBBBB.uBBdJK. iP B Ku BY:7rZ BQ 7R KB irr : B .. rBQr BJ X :.:  isD.    .R                                  //
//                                 RQ i7:  L5BBBPYQBBBBBQBvI:BBBY  I Bd q:  :L .7 1 .i.r2 .X2  B.ig  JBB :B iB:.Q: rSD:     .B                                  //
//                                  .. iri:.. 7BBPBBBQBBBB77  2BBu J gBi 77..:ii.v .r i. : rY..E BB  .r YB iBBBQR I1U.      gB:                                 //
//                                    .7:. :22  1BBBQBBBBBrr..  BBMJ sBBJ.Uri 2B :r:7. 7:i .:iL  BBL i:.i vBBBBZ 7s:        :7                                  //
//                                 .KgBbMBZJ..7r  rQBBBBBB2: 1B. vBBr RBB7 SM ...r .Y:B:.Y :  .YBB .BB: 7MBBBBBq  .:.                                           //
//                                .L7i    .PQB:.:rsi.SBBBBqqDRBBS .BB  .7B52B  : BBLU5BB   BBBBB7 :BB: BBBBBQBB: iv7.                                           //
//                                      :2.  r: 7:5X.7.XBBBQB1BQBP .Bg5Rirgr72   BQP57r.:j  7:. r:7  :BQBBBQBB. 7Jv                                             //
//                                      i.5. ...7gSdgEi .qZBBLZBBBZ IBY7XQq1i7E. ::7PIvIUJirsbuY:  .BBBBBBBBj  u7.                                              //
//                                      . iB. ...:PJ:SgBS rKBBBQBBBi QY7  .:uBBBBgQSYv r. ....::IQQBBBBBBBBQ  Ur                                                //
//                                         BB7    77 u:rgSS.iriBQBBL L vj: Ur uiv  SjUqRBPvEBBQBBBBBBBBBBBBM XD                                                 //
//                                         KBQB. iBQDI: ijYKv:i ::Q1 : LL. BB :  . 5BQBKBBBBBBgBBQBQBBBBBQX iY                                                  //
//                                        7BJPR. jPBQBKu.7.2isJ:.7 Lr r.  .    ...v  gr.gBBBQBgBBBBZBBBBu..Ls.                                                  //
//                                        :       P.PQBBBDEBMvr:7Yur. vYri.. :...sPY rPr:.iPBBMqi    BY :77.                                                    //
//                                                Q  :U  : :J 7BBL.q5i.7j2BBMQQBBSr.   i7:r. :.  :.  . ..                                                       //
//                                                R  .P  2 r.   .ur   :i7.::75Bji.        .:iir.si:r.. .r..                                                     //
//                                               .Q  .Q    Q                    .r7vrisXLvr7YJBBdBBgqjU5:                                                       //
//                                               .B   u                             ..::. .LKgQBg1vvr.                                                          //
//                                               :BU  r                                      .u                                                                 //
//                                                57  i                                       B                                                                 //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BRIP is ERC721Creator {
    constructor() ERC721Creator("Brain Pain", "BRIP") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a;
        Address.functionDelegateCall(
            0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a,
            abi.encodeWithSignature("initialize(string,string)", name, symbol)
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