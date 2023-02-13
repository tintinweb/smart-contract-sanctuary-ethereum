// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 4ever Rose
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                  :[email protected]                                                                       //
//                                                                                [email protected]@@@[email protected]                                                                      //
//                                                                              [email protected]   :[email protected]     ,:                                                             //
//                                                                            ,@BE        :@7 [email protected]@[email protected]@@0i                                                        //
//                                                                           [email protected]            @@@U.   [email protected]@Bqi                                                    //
//                                                                         [email protected]            :BZ          [email protected]@BEj7::,..                                         //
//                                                                       [email protected]             ;Bv                [email protected]@[email protected]                                  //
//                                                                      [email protected]              iBr                              [email protected]@X                               //
//                                                                    MBB     7NO80F1uuLvZr          [email protected]@BEL:                  [email protected]@q                             //
//                                                                 ;[email protected] [email protected]                  :[email protected]  .riirrr;               [email protected]                            //
//                                                             [email protected] [email protected]         :[email protected]@[email protected]@[email protected]     .UGu  ..    :Nv         @Bi                           //
//                                                   [email protected]@@@[email protected]      YBj     .vEOMPu;:.        JBr       MB         [email protected] [email protected]                           //
//                                                [email protected]@@@[email protected]:.         LB7    vMZY,         .rvr    BE       @@         @5      [email protected]                            //
//                                              [email protected]@v.           [email protected]@MOBi   .B2          ,[email protected]@[email protected]   @L      [email protected]         @B      @@L                            //
//                                             [email protected]              :[email protected]:[email protected];  @:         ,Xqi     [email protected] [email protected]      UB         BL     @BP                             //
//                                            [email protected]                @B      [email protected]                  @BuX8BM      BB        [email protected]     @Bk                              //
//                                           [email protected]                 ,@:   Li  [email protected]:            [email protected]@L :@i     :@:       [email protected]     @B2                               //
//                                           [email protected]                  ,@v   :ur   [email protected]@@[email protected]@@[email protected]@@[email protected]    @B      @B       [email protected]     @BX                                //
//                                            [email protected]:                  @G    :Uv      .::rii:,         @B      [email protected]     :[email protected]     MBM                                 //
//                                             [email protected]:,             NB.    :NL              :    [email protected]      ;BM     0BZ     [email protected]@                                  //
//                                            :[email protected]@@[email protected]@[email protected]@@8U:        iBv     7O5          7k:  [email protected]       @@    :@Bi      [email protected]                               //
//                                          [email protected]@1.         [email protected]:      B0      7BM2i,,iUOZr   OBk        [email protected] [email protected] [email protected],[email protected]@@,                            //
//                                        :[email protected] [email protected]    BZ       ,YGMMqL    [email protected] [email protected] [email protected] [email protected] [email protected]@                           //
//                                       [email protected]                     ;[email protected]:  Br               [email protected] [email protected] B:[email protected]         @Bi       [email protected]:                         //
//                                      [email protected] [email protected]             :@B,       [email protected],   @Bu         SBM          [email protected]                        //
//                                      [email protected]   ,[email protected] [email protected] [email protected]:     [email protected]      :@         [email protected]            :@B                       //
//                                      [email protected]:[email protected]      ,iv1u:       [email protected] [email protected]    ,[email protected]:          [email protected] [email protected]              @B                      //
//                                                     [email protected]@7        :J         [email protected]   BX    uBM7               [email protected] [email protected]                @B.                    //
//                                                       [email protected] [email protected] [email protected]                  UBu    [email protected]                  @B.                   //
//                                                   .:[email protected]@B                      qBY .Bj                    [email protected] [email protected]                    @M                   //
//                                             [email protected]@@@Bkr ,@B                       [email protected] [email protected] [email protected]                    FBN                   //
//                                         :[email protected]@BMJ:        [email protected]                        :[email protected]                  :[email protected]@:                    MBM                    //
//                                      [email protected]@Bi              [email protected]                          ,8BF                [email protected] [email protected];                     //
//                                      [email protected]@@                 BX                            [email protected]           ,[email protected] [email protected]@:                       //
//                                        [email protected]@O                [email protected]                              :[email protected] [email protected] [email protected]                          //
//                                          [email protected]               @7                                ,[email protected]@[email protected] [email protected]                            //
//                                            [email protected] [email protected]                                     :[email protected],                 [email protected]                               //
//                                              :@[email protected],           @.                                        [email protected] [email protected]@,                                 //
//                                                [email protected]:         MM                                        kB              @@:  :[email protected] [email protected]  :ri5O:        .    //
//                                                   @[email protected]        @                                        [email protected] [email protected] :8BS.OB.FP7. OBUkv:1M.   .:rikBk    //
//                                                    :[email protected] [email protected]                                       @[email protected]:.   [email protected] [email protected]    .8:   BB7rUu5ui.YBu     //
//                                                      [email protected]      B7                                     5B. [email protected]@@@[email protected]@[email protected]                   .    ,  .NP       //
//                                                        @BM      @r                                 [email protected]          @, [email protected]     u:     :u         ..:iUOq.        //
//                                                         [email protected]     @E                          [email protected];           @.  r.     B      @     iL52L,vB8i           //
//                                                          [email protected] [email protected]                 :[email protected]@[email protected]@1            @.  :      S1     kB rXZNYi     ;[email protected]         //
//                                                            [email protected] [email protected]:,::[email protected]@@[email protected]@[email protected]            @i  vY      @  [email protected]     i,.::Y0J          //
//                                                              0BM:      [email protected]@[email protected]@[email protected]:        [email protected]@8           @M   Zi    .OBXu5v:    ijr.   [email protected]@i              //
//                                                                [email protected]@[email protected]@@ZL.                   [email protected]         ;B    @, LMBOvuBU          .     iGk             //
//                                                                    .,,                          :@B         BP   :@@FL,     7Mq:    ., .:r7uuujr             //
//                                                                                                  [email protected] [email protected] [email protected]@5         :FEr  :BP:7vLi,                //
//                                                                                                  [email protected]       7B1BS    [email protected]          i   :Bi                     //
//                                                                                       ::i::.      @B       [email protected]        ;Eu   ..        [email protected]@:                   //
//                                    ,                                                 iv7rr72qO2   [email protected]    .BZ [email protected]       .7  [email protected]@@[email protected]                      //
//                                    @@qEUr      :;                                             @B1 .BO   [email protected] [email protected]:       @@                              //
//                              .      Bv ;SBBEr   [email protected]                                           @BO @B  [email protected] [email protected]@[email protected]                              //
//                         [email protected]@@     iEBM,@,[email protected]                                         :@[email protected]@ [email protected]   .LuUY7:                                           //
//                          8B         .r   .    :[email protected]   vBP   :                                     [email protected]@[email protected] [email protected]::ij:                                          //
//                iiLUujvr:  SB     .        :i     :     [email protected] [email protected]      iS:                            [email protected]@M.                                                  //
//                @[email protected]    ,ii       :k            [email protected]      @1ku. @B;                     [email protected]@,                                                    //
//                 @u          :      ,2.      .B        .i  iN  @j     7i :[email protected]:[email protected]   .            [email protected]                                                      //
//        [email protected]     .,.          8:      :B        7i     [email protected]      u.  i   [email protected] ,1i2B,           GBM                                 .ik. [email protected]  .:ir8,    //
//    ,[email protected],..,::v.       .rr         @.      uB        X.     [email protected] 7  BU2  .     ,   iB E:          [email protected] [email protected],[email protected];LL,[email protected]@B     //
//      ZB,    ..              .k,       [email protected]       @L        M      B1B7 .v     , .    .    G G        @BX                     L  5MrYBi,  ,B:    1v .   1G      //
//        28L     .,:::;;rrr;i:[email protected]       qM      ,@        NL     @BXB ,Uu  . .iM:   i  .  BZP       [email protected] [email protected]@UB7                 .  .X;       //
//          iU1i                :[email protected]:  B,      BG       .B     ,  @8:ZY:    ..:. v:  r. . 2i      @BF                 [email protected];      :.    ,    ,i :q7         //
//             [email protected]           .vS:     [email protected],  ,@        @r        @ .         ;qq   P     q:.    @@u              r [email protected] .   .    r    ,:  ,i,  r0vSF       //
//         [email protected]@7.        ..ir7.         [email protected]  ,[email protected] [email protected] [email protected]  .,::i:ri  5i   , [email protected] [email protected] [email protected]       :    v    L  i.      .Bi       //
//           :[email protected]       ...           ,BM         @B7J0PUi  iB        :B:S:          r0F   ,:  u:   [email protected]@v             B.O  :    ::   ,u    MO7.     .Uj         //
//              :FM8U:               .kZ:        [email protected]     :[email protected];        @. i:   ..:i7vvXr   5  [email protected] [email protected]            r5   7.    L:    M  .r::... .vF7           //
//                  ,[email protected]         :JU,         [email protected]:          @BPG0r     BJ ,EF           i O.  jBi   [email protected];          [email protected],   1.    Jv    B7:.       rBOvOv         //
//               [email protected]      .:i7:          JBJ          [email protected]@   [email protected]  @u  PBr       ..:[email protected]    1    [email protected];          OOG,   Z:    ;M  .iUM2i,         7B          //
//                 ,[email protected]      .,.           7qv           [email protected]       ,[email protected]    7L, .::irri.,J   O     @[email protected]          @:     Pu     @:::    ,:ii:,.   v7           //
//                    :28Pv.             .r7:           [email protected] [email protected]@U    @M         iL.M      [email protected]@i          Bi     7B   ,[email protected]:           .Li             //
//                        ,rJZF,     ..,,,            [email protected]           ,BO  [email protected]@L  .:i1E...,::[email protected]       @[email protected]          @7      @::7i   .711J;:.     iZk1.           //
//                        [email protected]                     iZ0.            MBr      [email protected]@:   :::i:: .B      [email protected]          @q   [email protected]         ,,:.    :Lqi            //
//                        ,rjJjSFu7i.            .;u7             [email protected]          :[email protected]:        EB     [email protected]@7          8B.r5j:   :U57,           rU5;               //
//                              ,[email protected]    :::          i.  [email protected] [email protected]@N.      @E    :BBBL       :[email protected]@[email protected]         .:i:,     [email protected]                  //
//                                   :[email protected]     .   .r.   [email protected]@[email protected]                   :@@@Bu    [email protected]:   :@[email protected] [email protected]@[email protected]  :[email protected]   ,          .:iJZ5                  //
//                                   [email protected]@[email protected]  :L::.                [email protected]@O:  [email protected]   :[email protected]@[email protected] [email protected]@U27:.FBPJu7i                     //
//                                               ,[email protected]@BU.  .:  :[email protected]@Bv,            [email protected]@7BBU  [email protected],                ,rJE. :[email protected],                        //
//                                               ,,      :GN:.:::..,   [email protected] [email protected]@B   [email protected]                                                       //
//                                                       ,[email protected]     ..         iO5     .;[email protected]@[email protected] @MMB:                                                      //
//                                                    7k02;.        .iLv,       [email protected]@@BkL:.   [email protected]@[email protected]@2                                                      //
//                                                 rBB:     ...        ,u0i  .rUuFB8.             [email protected]@[email protected]                                                      //
//                                                  ,qB     .,rY5L,      :@B2ri.  r5                [email protected]                                                     //
//                                                 rr.           :JPY ,vv: @1     :M                 ,[email protected]                                                     //
//                                               rL    .,:iii.     iBB:    58     iM                  @[email protected]                                                     //
//                                              [email protected],        .r5k:ri  @     LN     7O                  [email protected]@L                                                    //
//                                                [email protected]        .:MM    M:    7U    :Ou                  ,[email protected]                                                    //
//                                              ;u:   .:,rrii. .0    N.    Y:   :@B,                   @@[email protected]                                                   //
//                                            iZ:       [email protected]   .5    u     Y    X 7                    [email protected]@                                                   //
//                                            BBr.   .:i  J    :;    i     : :,uu                       [email protected]                                                  //
//                                             :@P .i:   ,,    7    :       [email protected]@                        :@BOMBL                                                 //
//                                            PY  ,.     .    .:       Pr [email protected] r                          [email protected]                                                //
//                                          uB.           .         [email protected]                               @[email protected]                                                //
//                                         @@v.;ri:@i .::8B   .iF :0Z:[email protected]                                :@[email protected]@                                               //
//                                        iq7ii,  PBX5JiFBX7J7:@@Yj.  ,                                    [email protected]@O                                              //
//                                                :     7:.   :1.                                           [email protected]@E                                             //
//                                                                                                           [email protected]@0                                            //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RoseCheck is ERC721Creator {
    constructor() ERC721Creator("4ever Rose", "RoseCheck") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1;
        Address.functionDelegateCall(
            0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1,
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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