// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dreams in Another Land
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                         .................                                                                         //
//                                                                ...................................                                                                //
//                                                           ...............................................                                                         //
//                                                      ........................................................                                                     //
//                                                   ........................... . ... . ...........................                                                 //
//                                               .................. . ... . .               . . ..... .................                                              //
//                                            .................... . ... . ...............   .   . . . ................:..                                           //
//                                          ..:.............. . . ........i::iiri:rirriirii:i........ . . ................:.                                         //
//                                       ..:.............. .   ...:::i:ii7vY7uUYLrvJrsJYuLvSXLi:::::::.... . .................                                       //
//                                     .:..............   ...:i:riLrrrri7YL7rr77775PL:JrirrIBBu7vr7rr7r::.:..   ..............:..                                    //
//                                   .::............ . ....rrirsgKrri7irr7:::i::rXvvRJ77rvirr7i77Urr7vsu77iii:.. . ..............:.                                  //
//                                 .::.................:iiuLi7Pvririr7rirri7riri2Iu.7Rgr7sK1I7r::7Z777i7sPLisvvri.. .................                                //
//                               .::............  ..:ir7YDBKPMriirrvirYLrv7Krir7vPZ7:7i::ri777Jvi:rvrr:ii7j7rYYvr7r:.. ...............                               //
//                              :::...............rrv7vPKj755ri:r:Lrii:7YLLrirrvirv7L7rirr:7r:iivii:rvrii:rir777vYjv7::...............:.                             //
//                            .i::.......... ..:i7JUPUURg7irr:r7v72P7r:rr::::i:7i::irvriiiirii:irvv7L2vrrr:iiir7rir77iii:..............:.                            //
//                           :i..............::vRgI1QgZUuLr:rJ7:rirr::i :..r:.:77:.7rs7iiirriri..:irr7ri77Ivr71rri777i7iri:..............:.                          //
//                          ::.............:iLIbXIjvrvv7Lvi:is77ii:iirr:::vrr:i777:7r7r7ir:irri::ii:.....:rv7K7r7777rvYYiiri................                         //
//                        .::.............ir772sv77r7irr777rirri77iir7ir7ii:vi.:isurir7:i7irj:iri7Lri::...:i7r7r7iirv7i7L77vr:............:.:                        //
//                       .::............:rIsY5XSiri:r1vi:i7ri:rr:rr:r7r7ir::rr.iriD7:Lv:r::v7vir:irrrqUii7vr:ii7iiiri7i:rrrrrri:.........:.:.:                       //
//                      .::.............rPq1Ijj7III7:::rr:rir:is7iJ:ii:iri:i7vi.i7.:iKjis.Lirrr::ir:7uriKLirrr7i7v7:irri7rYri777i.............:                      //
//                     .i:...........:i2KKjYruLrPP1r:.:vLi:7S7ii7i7i:i:r7riri7:::L::7Ersi:r7:i:i:rrii::rrii77r:7Jviri7rYrivir7.:rr:....:...:.:.:                     //
//                    .i:...........:r7PPIX57iUXYrrv7YYrir7i7:rr:rirrir:rir:i::i:.v:rririr7iiiiii:ii7JqI5Kvrrr::7i7rrrrirrri::vri:r:........:.:.:                    //
//                   .i:...........:1gb1XK7XdI1quuirrii7rr77ir:.:rrrrii::..::::ir:ii::::irr:rr:i..:srvPgPPIrir:irri7riii:7iriiirr7iv:........:::.:                   //
//                   i:............rPqKSSS77ddX5Jii:r:.:r7rirrii7Li:iri:r..::i7i:i::::.::iiii:r7i:::iivririii:ii::riivS7ririiriii:rr7i....:...:::.:                  //
//                  ::.:.........:rQQgdZPJrLvPQPiirr1gri::iiir:7rr..:...:i::.ir7r:.:::.:::irii7ivL:.:irr:::ri7iir7iirb7i:77rii:rr:iY:ri........::::.                 //
//                 .i::.:.......:1gdRQBBQgbjr:v:iiiDS7Urr:iirrr.:r:::irii:irr77:vr..:::i::i::r7.rL:i. ::::iiYSLrD77r7iiii:r.i7rivirB7:L:......:.::::.                //
//                 i::.........::IBBQQQMgdgMPY:irrs75iir77:::irri:.:rri777:7r77i:i....:7i::i:ii:jP:ir:...rrri7rv7rir:7iii77ii77r:7:Yviir:......:.:::.                //
//                i::.........:iSjqdgQBQQPX2KYj:7QUi7::ivvi:i:iii...:::iiri:.::.....:...:....:iiL1::i.::iiriiri.v7ririvrr77Yi77ir7:.ir:ir:....:.:.:::.               //
//               .i:.:........:7DE1urvK5KgDDPrjQ:irY77iirr.::ii. ..  ........iiirKPPMI77r7:. ..ir7:i:..ir7rrrXL::vdvrrrY::iPir7vrirvvIi:rr....::.::::i               //
//               ::.:.........:2DgD5Liirir77jUiii:.:gr:L7. :r7i .i: .:.....igg.iii:.rZgI1PBBXi:..:r.:::i777vrrrrrrLv7rr7ri7r7ii:riiJ7js:ir:....::.::::.              //
//               r::.:.......:rXgMDDqIjXPPXqXq1r25PLi:iLr..:::.ii:ir:::i.. rdi:dSr:iiPKXKULbdRgj:. .irri:i:iir7L77i::::vri7rr77rrvirri.r:ri....:.::::::              //
//              :::.:.......:rvvP2PEDZ5KPSK2jP5YU7Sv7i:rr:i::..:i...i:77v7rvK:iU..J5QgdZRi.:7qgQQsi:i77ri.:i777gdJv:r7r:irjvrisri:irii.7vi7:....:.:::::.             //
//              i:::........:SquEQgSUXu7dMddEdIJ:vrirJi.ir:..  .    :7.i7Yqq5q5U::rS::rvjJriiUXqKK:.::::::rv77:ri:irrvY7..7s7ivii:i7ii.Iu:ir...:...::::.             //
//              r::.:.......:IDXPPPJ122::PZKgRRU::ivL7r.irr:..    .:::..:.vqdbDPRKXb7:..iir77rYPgDj:: .::.:irirrrii:Yr7J: .:ririrr7ir:77r:ii:...:.::::::             //
//             .i:.:.:.....::7jIPgbPZZSv.:i7ir5qYri7ivr:::ir:. ..::riirr:iuqbRs::5ZRgqiiiii7rvvvv2Kd5r..:ii7LJvJuYvriYi71: iiiirirriiiiv:7ii::.:::::::::             //
//             :i::.:.:....i7vJv7Ju7Ysvvi:i7i:r77iS7:::rv:::..i7:77irr772KdEg:::.:dgbEBQgJrrr:iiJKqEBBr.i7r:r7KPKs7i::rrs77r7i7vvri77irr7J:rr::.::::::i:.            //
//             i::.:.......rjY7LYJYsvjuUrrvSUrir7iiJvvrr:iii.::iiu1r:r7j5KqbdIjJvXPI12i1SPUUYrrJPDPPEBZ:.i:..::::iiiiirrr77r7rrrv:ir:i7.:q.:i....:::::ii.            //
//             ii::.:......rL15IgbqSI1J7ii52Srri7r::7ii777v7v:. i2uLrrUUSXqPggRERQdr::.:v2PPgZdPdPPSSbQi.:iiiiii7rvvY5RZXS77YrirY7ir7i7:7Br:7::..:::::ii:            //
//             r::.:.:.....rSbSYjuYJ255PPbIIZgPUuXL77r::rrrrri..7K1S77uXKPPgZZdZDMdKISKSIUjXPq2I5qXSjjK7.rirrrvMggXXj:rU:gPX1q:ir7ir77rK7Iriii...::::::r:            //
//             i:::::.:....idRgIK5j1U7LqDMgEPKP1JLsvJv7rsvr7v7:.vgPS1j2SbdMggZZZMDDZRMQggPbPdPbKqXPPdbZr.irrLiirbbIYJrru:g5iriYPD7rrv..57iKL7::.::::::ii:            //
//             r::::.:.....7ZRKPDdjv7vjggMgZSZDbP5XK1v7771Jv7r: rQEPSqKPbDgRZDdDggZggMgMMMgRggDDPbPbZMg7.::r7vriisrirsr71rriir7L7rrv7ii77iBLii..:::::::r:            //
//             ri::.:.:....rgD1IUYUsXqqPPSPXdPMZDD5JJr7: :7.iii :RgbPdggDZQgZKEMRDgDRgRgMgQMRgRgMggEZgB:.::::rv7Y77rrr1r::i7ri7irii:i::77XQ7r::.::::::ii:            //
//             i::::.:.:...ijdKDgPUJ7UYSUJYsLi:rrr:iirrrirr7r7vi.qdqKdPgDgggdEEQgdXXXPPMgMgRgRgMgRMQRBS.ivv7iiiiriiJvivPUUrr:ii77Yv7rLi7s2K7i:..:::::iir:            //
//             :i::::.:....:7qEPEbPXJJuqu:r7i::rjsj777UbXvrirr77.iMEbKPbZEDDgDMgRggDgDRQBBBBBQBQBBBBBBi.r7v7v7U1s7rr7iisgJYs21Lvrir:J7irDUrii:.:::::::ii.            //
//             .r:::::.:....rPq5sUuY7i:ri..::rirjPILv77v77r7ri:i:.rBQggQgRMRgQQQgRMQRRMBQBRQQQRQMRgBBi i:i:r7uX5jsS11EPPDPSDgd5S7urr5i:rBZrr::.::::::iir             //
//              7::::::.:...rXQQRZgbKJJrirvrX52I1IPUuvr::iiiir7i:..iBBQMMgRZgRQgDdEbK2PDDPdEDZgZMQBBi .:rrr:irJuuY512dZggdP2riJ7777ur:sdqQPr::::::::iiri             //
//              ri::::.:....i5ddKbdqIUJKPMgq2KKZXPEEuss77Lj7:ii7r7r::QBBQQMQQQggDggDXKEMZEqPbggQQBP:iv7vriiri71uLLsKP5XQZM17i7UIrrri:iDZPU:i:::::::i:ii:             //
//              :r:::::.:...:72PI1SSKKPSqXK2KbS5S7YUI2X2SL7:irJv7rr:. iQBBBBBZDDgZDZbPMRREDPPEBQM:..rYv7uj7r:.r5rS5sgggIYviiriiirirIPRBQBu7:::::::i:ii7.             //
//               7::::::::.:.i1gdPPEPS1UqgKqqESs7L1j7JL7iii7r7r77i:::i..iZBBQMgMK2SdXbRQMQBBBZU:. :i:i7PIKjqZ7.is7P1:iiYXZirZZJriii2ZBBBS7ri:::i:::iirr              //
//               ir::::::.....vDBQQbbSUu1YL1q21Yrir7IjurrirY5uJvr7vrrirr:.::YXBBBBBQBBBBQqsi:.:i7riiri:ivj2rqj7ir7idZr:iBP7bELjBBPESPXQEUr::::::::iii7:              //
//               .7i::::::....:1gBMquJ1KKPqEPRQDU1UbKKSujUsUJ77v777IUri77Lr: ..:::iri:::... .r77rv7rirrr:.:rr7r7iPd5MBdvi5QBRPSBQQgQEqSEii:::i:i:iiir7               //
//                iri::::::.:..i5uU2bMQgMb22QEISPXqqPSju25Sjvs2YvvdZ277vsL7i:irii:.:..:ir7vi.:iirisKYv21Ivi:i7sSEPXdMZDZIvviUgBQQgZEQQgLi:i:::i:iiiiv:               //
//                 vi:::::::.:..rSRBQBBgZQQKL75dXqIY5S1ZDZPSS5YvSgdvr7rrYvi:i71E17:vi:rvLSUu:i7XK2rLqZ5JLSQZrrSMQMqbXZbPgBdLJ1YKQBMgDQgr:::::i:i:ii7r                //
//                 .vi:::::::.:.:PBMQBBQMPXsvZRbEPPKZBBusjIsr:uI5Lii7vvr77i:7uUv7irv7:rvY2EI7irYdSjrru2XSJIIviLSqBBQBZPEgDbXdKIJPdEQBQSi::i:i:iiiirL.                //
//                  r7ii::::::.:.rSRQgPdSuLUSgEqPDQBPPL.:7ri.iU7ii:r2S7Lu7i72qU7rrr7SLi77vSdurrrYqIui::vUUirii:::vgqPQggDbqMDDRQEqPDXj:::::i:iiiirLi                 //
//                   vri:::::::...iLPXS2XPSqREDbgMgS77riiivuuPEUP1v5DIY55r7vsSui777jqSrivj7LI1u21XburiYjPE2ruSuri::ivqgPZqgRQQQMMQBBKi::i:iiiiiir7v                  //
//                   .vr:i:::::::..:IMgMDQQQdPKPqPII5qjri5UrSMEDgDbd1uKEKssIU7ir7vrSbXKuivLv5qJ25LrULUEgERRriPjsUJiI1IPSqMEMMQMQQBQI:::::iiiiiir7u                   //
//                    .Lrii::::::::.:5BBQMQDEKP51Idgb7iiIMrLBMRqdRgSIjUdPY1IXvr7Y7r7u5qSUYJu2KjUjriiXQBQMQQMJiZMqvr2ggKLqMRZMRBQBBPi::iiiiiirir71                    //
//                     :srii::::::::.:rEZRMgZbPdPdXSvvuZUisQZbsXDbv1iriXrYMPjuPPUSEMbq5ZPu71KPL5ri1SdbPBQQgMBEiSQb77KZdRDEdggRRQPr:::iiiiririr71.                    //
//                      :srii:i::::::.:iXQBBBggQELL7ugQIuSbSu7sDSug1iii:igQMZPESUDBKDBbSgdXIPZE2riMrYMjsRQZKgB2.PgDuJ5PDBRgQBQQXi:::iiiiririrvU.                     //
//                       .Y7ii:i::::::.::7bgZK2bPXs5DD55SKPZIPM5vgKrrr:iqdZgPQgPDg:i7IRd5EdZMQBqri:rsDQKJMQDPZbI1MRE1PZMgEPQgdYi:i:iiiirirrrL2                       //
//                        .Yvriii::::::::.iIMRggMEEZP5PZgEDK775PD7rL2K7sKDRPqEgMQS2Qg7XBIuSPQQMD7LrisvRQbLXqPdPXX5bDMEgEEqEgPr::i:iiiirirr7Jj                        //
//                          7sriii:i:i::::.:rqQBBBZDbRQgbDQDSZMSY7XEDQ2XbdIPDDgXSQBQQBI2EdZPdBZgqRQqv7LbqPUISgDggRdEEEgBBBgsii:iiiirirrrrvIv                         //
//                           iU7riiiiii::::.::vRBQBQQQgDgQQEdgqUuXMRQPDMDEEZQMDJgBQgDBR7PZgdgRRDZPQDPb211SgbXERgQQBggRQBMsi:iiiirrririr7JIi                          //
//                            .uY7rriiii:i::::.:7RBBRgZDQQZdbD5PXdMgqggEDDdZDD5qgREgZQRPXPdQMQDQgbddZgZqP5dMPEMMgQQBQQEJi::iiiirirrrr7vqj.                           //
//                              7uvrriiiiii:::::::rKBQBQQggZDQMq2jqZddgPggDUK5vgRgQRRQQXKbEEggbgQMRPZgMgRDERQMBBBQBRd7i:iiiirrrrrr7rvJdi                             //
//                               .Y17rrriiiiii::::.:ivdBQBBBEZRBESUMQRbgggEEK5XQRDPZgBRbdgQMDgZMgDgRMDPPbgMBQBBBQguriiiiirr7rrr7r77sEj                               //
//                                 :UJ7rririiiiii::::.:i7KRBQbgZMgPEMRgEgEDgMEKbMPKPgESbQggdRgQgZgQgQQDqgQBQBQguriiiiirirrrrrr7rvYg1:                                //
//                                   r227rrriririi:i::::.:ir2ggBZZQgDDgbPgQQRQEEZMgBgX2EEgPZBBRgMQMQQBQBQBQP2Liiiiirirr7r7r7r77ugS:                                  //
//                                     i21Lrrrririririi:::::::ivEdgQBRRPbMBBBQBQBZBBgBBQQZgQBQRMBQBQQgE2Us7iiiiirirrrr7r7r77YIB5i                                    //
//                                       iuPsvrrrrrririiii:i:::::iirrjKXPZBBBBBBBBRQBBQBBQQBQDPDP2uJvriiiiiiirrrr7r7r7r77LsEBU:                                      //
//                                         .YqqL7r7rrrrirrririi:::i:::iiriirsj2ISPbPESPX25SUvrriiiiiiirrrirrrr777777LLJsPQRv.                                        //
//                                            i1ZPvvr7rrrrrrrrrririi:iii:i:::i:::iiiii:i:i:iiiiririrrrr7r777777vvYLJJKQBji                                           //
//                                              .r2gD1L77r7r7rrrrrrrrirriiririririiiiiiiririrrrrrr7r7r7777v7LLjs1IZBB5r                                              //
//                                                 .ijDBZSvv77rrr7r7r7r7r7rrrrr7r7rrr7r7r77777r7777v7vvsYjj11XDBBBsi                                                 //
//                                                     .7uQBQEXsLvv7v77r7r7r777r7r7rv7v7v7v7v7LLYYjJ1u22qZBQBB2i.                                                    //
//                                                         .iLqBBBBQbKuUsJLsvJLjsjsuYJsJYJsuu1U22PdRQBBBBdvi.                                                        //
//                                                              .:rLqQBBBBBBBBQMMDDZDDMgQBBBBBBBBBQKLi:                                                              //
//                                                                      .:ir7LJIXdPZbdqq1jL7i:..                                                                     //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DRMS is ERC1155Creator {
    constructor() ERC1155Creator("Dreams in Another Land", "DRMS") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC1155Creator is Proxy {

    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xb08Aa31Cc2B8C0582bE42D38Bb643292e0A4b9EB;
        Address.functionDelegateCall(
            0xb08Aa31Cc2B8C0582bE42D38Bb643292e0A4b9EB,
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