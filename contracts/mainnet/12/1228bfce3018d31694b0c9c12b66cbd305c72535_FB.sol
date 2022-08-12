// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Federico Bebber
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    SrriYir:rr7i7L7iY77i7rLivrUr1L5UIIILqYPqrr1Ys15LKIbSRJ2EgPQREIgdDKBPPEDvsSQZgJb2ZvsUq122bEZ55ISvvvLi    //
//    ii:r7vrjvviriuvUL1svi777ivvjIKILrUIqIbYrrvr77X5KKS5ZdRdBEuqRZbZQZDggEBRQIvRQbMgEZgdMqRZDMBbqKPIdPZKi    //
//    s:rrI2uSdSP7IUEX11S77j1vs7UgKr7i7::7v77:vUjY2555P2ZXEPDZDPgPZSbDBbMDQQBQBDQRQDQQBQQDbMBMMPDEDqZZBQBL    //
//    r7rg121ZDgEgKq5PUK2P7jjv77r:.:::.: ..i:irqXEPgdDKgbKqESb5SisEgKMEgRQgRZQgQdRgBZQQBgQDQgQdEKddMPQgQRP    //
//    r:ruquPdgqdSd5X1qU2vsr7rrrv  .ii:.:.:rsirvgPdKgPUKXKZ25IZg2dBMRdgEZbBMQDQDBMRDgEQgQEgqgEBQQgBMRRQMBK    //
//    r7r5qg5DIP5P2qUbqSsj7UKXvqM:i5rr..i7:::BQRPgDRbEsXrX1P5P2gPK5dPEDQPdMBDQZBgQPgZggZZRbdqZdgDRgQgQDBQP    //
//    7iLsKuIXZbqSDUZ27LK1UrIj21ISr:r::::iririBBMMQgMSPKZ25uqu5Y2LIjLsdDMgQP1SEPgdREZPZMQPKdQdgdDIS2K2EDQr    //
//    irrD5K5XKPKKXbXPSSIDuUJIJKjPPdv5iIvsr7i7YEbQQBqXqbU2rUjuv17Ujvv7rbKEddSZqKqKIdgdPgPZuKgQZbSKJu1PqQRY    //
//    rivKbSgPdXZIbIDXP2XSL151I11u5qgDQQR1dX7iIMDJvirvs7vi77vrrr7rr7I777SJXKDqdERdgEMZQPgdDJZRbPQPI5P2U7Pi    //
//    rvEDPRZQZZ1gdEbEPP5X2PIbIqqPqEqQgZE77PP7rriiirrs7v:ii7r7r7rr:772rrrYrS12jRZMgPEMuKXQdbIguUKKKBIdPISv    //
//    7YQggEgPM5PPMPDgQKBXPPdbQgMZgZXUPIg7IQ5ir:i:i:iiv:i:i:rirrrrrir:vrvrrrU7KZEqgXDEPsgZPvYUUrIbRPZEDZQ5    //
//    J5IZbgDEPRdKjZd1XB  .7r7::iXdqKgXUqZIr:rrrr:.:.:.:::.:.i:i:i:ririvvvrri75jLUqgQgvs5UXs:ILruggEXDddPZ    //
//    jLgSK5ISDdD2g2 :u: .J7i. .::rrQEPQBiii77r:r.:.. . ......:...::i:::UXgv:iJv1KBKE5PIquZjr2riYKQXDdqvQ2    //
//    iY5Zgg1XSXvPBi r7rruiiii ..::rrdQZiiirivii..             . ..i.::i:YrE57:7LrrPIdXDqSrSS5rri5DPKDEBQu    //
//    LsDSddQDbYuPD.:.. ..i:ri. ..iiXE5:iivri.:::.               .::iiri::ri5ZL:rvrr7vS5EPbXDjriv1EqMMBEd:    //
//    ir112PXS1ZPB:ivv   . :ri:7vSgEiri7r7i::  .                 ::7rr:ri::vLIUr:rKXjs77vMEgdKvULXZPZgDJ:r    //
//    7rDSPUSudZB..JK. :r .1Di7D5vU:rXqvrir:i:rir::.    .       ..i7QBQL7:r:ri7gM:rsEqDS:sZPBUiiXPDbDdMIJi    //
//    i75522uDqBr rr   ::7BMui:71I77PSIEdgQBBBQBQBQqir.  .     ..7rbMQgQgq1RSrisQP:iDQEQPPZPqvi7XPDQdMgSq7    //
//    7rs1XYSjQD  : ..  7Ss7SJri7JI7r2DEMqI77ruEBQBQQXv.. .   ...rs1q5PZP7qQgXI7ZQBvXdgZBZBMMi:jgJDIPdQ7Lr    //
//    ivPZXSL7g  .. .r:::r:igQjriJssudSDIP1qEEsILqQQDQP7....     :7Li7r7i77PdB:iirQBIDXq5BMggBriSREPXggS5r    //
//    iigPPUPgi :ii iiuv:.r7Lu1YJrUSZDQdRDQRBgQU:.PgRgQMr..:i  .:.7i7r7rrrbPDQ: iiBZE2ZqMKgqbMBI7ERE5KZ1D:    //
//    :r2Ku2Lqr.rv. KJi77:.irvr7UgZEXQgRgMdQgRgX :QgZEBB7. .sv . :.::ri7i7iXYZKridgddPgQDPPQPgKMvi5ZPZI2gi    //
//    vivUIYJ7Iri::.rvj:rr:.::r:PdDDRdBgQgMgMMQBBQBQBX7r:   :Q1  :27::vYjrvYrv277UgKgPPDRRqPPXKLb:7KbSgRB.    //
//    i7r2vj7Lv2IXi::j77:77rii.gUq2DKDQQQBQBMBQBQBQP:..:..   rUI. :s7Y7vrJ77iJr.iPSDPZUdPRS5XK775g:UI51EMi    //
//    2r7vY7v7s71LQr.i77LiY7rrvQUEQZbXD1XsgBBBZii.:   :::.    :7K   i...r::.Lvi rsSXEPd2MqgsqvrrqqSLESPPZ:    //
//    rv727L7YJuJqSBr.:Lvv7LiirujDZB2Iii:riri:.: .   :rL..      ::     :::.r..  vjs2uSIq2PP5vSi77q1XqZ5Dv:    //
//    7i7r17Jij1XIqSBr.:Y7rrYrirQRgqJ7r:ri:.:.. ... .rLrri: ...                :srU1u2UJPIK77v77jY2UMbEqI:    //
//    i7Y1vu2Yi2UbSP2g7::Y7vYKir2ZKDKdX7rri7rL:. . ..7iQBBBBQBQY .         .ii:L7YjusZ5dqEIIjrrvvriYJSjPPr    //
//    7iI22jKP1iIIqE5LgS:.YsYISLdqQDBMg57:7rj::..   :rMEDdRdgPDQPi:   .  vIi7ir.:75LUbgbEXP5b7Yv2Y1Y5UbqP:    //
//    rv7UI7iL7vs22Ej7UPqr.r:7152BggRBDMjrii.:......iBZDXZKPqgEBdB.. ..:.rvr:r:i::ud72PXUDXX2S5PvuuISqPQPi    //
//    7rurr:riii7vqUI7YuEgKr:.7r5EdbQMBMR7i.:.....: 7BQZggQggQBQBr  ..:.::virr7rv.:QJrSLIXqIdKPIq1XY55ZgD:    //
//    rv7si777iv7I2b5I7LdgqB:i:i:iLMZMdMMQUr:i.:   .:2SPqgQBP: .     ..r:rs2XP7srL:21XJX2PIdIbIqISYj2PPDX:    //
//    vivJvrvri7Y1KdU77iIujIJivsPvErvDEdQRQZ7ii..     . .             .iLLSIEiir7::vMSqIK1S552q5J75XXIZDR:    //
//    rrrv7LrL:irL27rKLJvIIKiSIjKBJ.rQPgdRDZu7::.. .  .7vjri7gDP:..: ..rLDSqr:.iiriUUbSqUXIdSPIqvu1DKEPR5i    //
//    Lr7r7iJvvri:.:S7JJSII:1EiiPD..BgdEgdgbQPvir:::r1BQRgBBBgBQ. riJ77rr2DM7isr7iLPDSXJ51PqdjPJ2IPEgZgqv:    //
//    r77vri:i:Pi. r:iiv1PPDZQv::i PQBPMDDPDgRbEuX5DQBQBQBQBQBQBr7vvrr77:PSR.77ri75Z5X5P2PS57LIXvJ12jrLqri    //
//    vi7LriKi:iLiriIIPZBQQgQQBQBU:.i:rvS2REDPgZgQBBBgDKqvY17:iiirvQRgPiiUZ:.77iMdqUUUXIPqqr77P2LiL7UvSqu:    //
//    r7:riEqQi.:MIIXddMbgQBQBQgUBBBqJY5qDdgKgEgZQERPKvr.  ....i:::iiKgEvXv:igYJ1SJJ7U1SsvjrrsrjLvYUuXIdPi    //
//    urvvPLSIB.iQBD2EgPDQDr: . :ru1PPBQQPEPQdDEMY..PPQQBQBBBQBQBQBYYuSKQQviQX7YJrSj5j1U5isrvrs77vKsKIbYP:    //
//    57r17sKDPBgQPXEQEQQB.i.i:irdJYIqr:DgPgQPLRBKsXgBQBQBQQQBQBBBK5ru2dQ1:rEI7IIIUjvuLYL1rLrv7u72SPriiv7r    //
//    rijL7rEKPPD2IPBERMBK..irQYr77::...BMQgI.MgKXKZBBBMBQBQBQBMPvjvXSK5v:i7PvjUq1srJr7rs77i77sv7sgiirsvv:    //
//    iJ5PsjuSjuL1dDdDPQQI iiirBBIIBr::QBBQBjr7:.ririQQBPIi:.....rrv72Jsrris7vYX1vi777r7rvi7iL7J1Zi.:rr77i    //
//    v15UKs1JjYX5dSPqdgBb:vBi:.725ri:RBBQQYs7:.:::.:ii....     .:ii77rrSYjU5sKIuiLsX7Y7v7vrsLj7r..:7rs7Y:    //
//    rqXd5P5d2KXEPP5XXMQBr.vBEi::.:.:::::i72rivi.  .i::.:::::::.iirrsjEdq2qKJiJ72Jj1Jrvr2ii:i::.:iLrv7v7r    //
//    I2ZKb5S1U1bbZKgbDEBEBr..gBBR7:::r::.77ri7J7i7r7iiLJr5XP1Usu1P2EZQbbXSJ2sSLq1Sr2v77Xr. ::rrY7s7YrvrYi    //
//    jKqPuSj21q5EPZSZqPJ5KBPi..:i:iidPBU: . rQ7:jBB77vSMQRBMQQQdMqgdZqqUbIqSggS7YuPvL7L2Y.:.rrvrLrs7vi7ii    //
//    SIqSS5P1KIEKgEdIq2dPMZRBBri:r:uPjvKQi.:.i:rZQRLiPYMRQEMEgqPdgdZq5jX1PXg7..::77u7L7vrU7::i.::v7r.r7vi    //
//    2b5qJISqIPKZPDbZZQddZBZQQBBBQv:SdRMBr:r:.7QMZQPiv5UQXMbgKKKEPbKdXP55XDKr   ..77viv7s27r7:i:i::.rr7rr    //
//    qqZqXuqKEXZKgdMKgPEKgZMdREBDdgb1qSER::Lri:gQgdQivXb2DZQggqDPgSqXP5ZKbqP:..:.:.rrs7Iri:r:771rr:7rjvsi    //
//    XqPZ2qIEPgPEqDPdPgbgEMgZb5JXZDZBQBBr.iiXDi:BbMPU1Kq5KMgMPdbDq52PL5UX1ZK: ii7i7:ir17:.iivrs7i:L7Yvvri    //
//    UuXI271vuUSUSuIsPIPqdI5YKXPIgdBQBQi SQQgQ:rXBqK5D7Z5XPdKdKEPZqgbRdEPbEY .iri77r:i:..rrrr7ii:77vr7r7:    //
//    iJYUuv7L7Jv5JJvJY5vLYuuPXZKQdBQBi. IQMMBIuuRQXrQdSIqu22ZbgqZZgPsPdUbSRi.:vr7iv77i..rivrvrr:77vivrL7r    //
//    JLJs1vsvuvI25YUvsv77u1XJI2EgB7i. .QggDRQBP5PBZ:Z7LK:i:7MBggqDKdsSjUqDE. Lr7rv777i i::i7r7irivirrLrvi    //
//    vsYI5X71sjIP2P1SLIs5UduY1XqQ:::..SEPPgXQZJJ5MBiZ7dDSiJvBDBEdXbqPXb5QQi i7vrrruri..rr:7r7iririrrv7vrr    //
//    IvjUP5JJujK2PY7Ib5X1ZXY7sXP5i:i :BQDgQRgR15dQQuirXMsrLiQZEDdZuqSDXM7: :7vr7:rr..::7i7iri7:rrvirrLr77    //
//    2SIPSK5jvXsqISiuIEUISYiI5P1Kiri.:BZgdZDMPP1M:Zjr7gXYjRiddgPZdE5PPPr: :rY77ir:. i:r:rii:rivr7:i:rr77v    //
//    SuKKqU57uv1jI1bXqUPXPYI1KXKPdrr.LQQEgdgqqv7iub1ijbX7Mgr:RSbPqvSXY:..rivr7irii:iii:iii:ririi:ri7rvrvi    //
//    vvvJ77i7r7i7irr77v7JL7vJYsvXvr::UQKEjIKP::.:iSrrij:rPu::7uvsYvir...rr7ii:iii::.:::.::iir::.i:iir:i::    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FB is ERC721Creator {
    constructor() ERC721Creator("Federico Bebber", "FB") {}
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