// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MOTHERBOY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//    DDDDZNNZ$ONNN8888O7II??=+==++==+$OOO8DDDDDDNNNNDNDDNNDNDOOZZZ$$$88OOZZ$$$$$$7777777777777777777777777I77777777II7I7I$777    //
//    DDDDZNN8NNZDN8O7II?????======+=====OODDDDDDDDDNNNNZDDD8NZZZ$Z$$$8O8OZ$$ZZ$$$$$7777777777777777777777777777IIIII7II77II7I    //
//    DDDDZNNNNDDN877II????++============~=D8DDDDDDDNNNN8DD88OO8$$ZZ$7OO8OD7ZZZ$$$$$77777777777777777777777777I7777III7III7II7    //
//    DDDD$NNDNND777II?++++++=====~~~=~~~~~~?DDDDDDDNNNNDNND8O8OZZ777IOZO7DD7ZZZZ$$$$77777777777777777777777777777777III77II7I    //
//    DDDD$OOI+7777I???++++++=~~===~::~:~~~~~~8DDDDDNNNNNNNDDZZ87O77Z$ZO$IDDDD7ZZZZ$$$$$777777777777777777777777777II7IIIIIIII    //
//    DDDD7OO$7777I????=?++++=~~=~~~=~:,:::~~~:=8DDNNNNNNNNDDOOO$$IIZODI77DDDDDN7ZZZ$$$$$7777777777777777777777777777IIIIIIIII    //
//    DDDDIOI777I?????+=++++++====~~~~~~::,:::~:~88DNNNNNNNNO8OO778D$OD?IODDDDDDDD$ZZZZ$$$$77777777777777777777777777IIIIIIIII    //
//    DDD8+.777III???+++++?????+====~~~~:::::::~::8DNNDDDNNNOOZZ7ZOZ$$$II8DDDDDDDDD7$ZZZ$$$$$$7$7$$$$7$$$777777777777IIIIIIII7    //
//    DDDDI77IIIIII????I$ZODD8O8OOO7I?=~::::::,,::~DNNDDDNNNDOZO$7O77$=7?ZDDDDDDDDDDD7ZZZZZ$$$$$$$$$$$$7$$$$77777777777777IIII    //
//    8DD8777IIII?II+?Z8DZZIII7I??78DDOI+~~::::,,::7NNDDDNNNZZZZ$7777$77?7DDDDDDDDDDDD8ZZZZZZZ$$$$$$$$$$$$$$$77777777$7I77777I    //
//    888O77777IIIIIID8Z$77I7I??=+=?I77DD$==::::,,::NNDDDMNDZO$Z$II7I7Z7I$D8DDDDDDNDDDDD$ZZZ$$ZZZZZZ$$$$$$$$$$$$7777777IIIIIII    //
//    8D8$77I7I??7+DOOZ$I7I??++=======?+7ODI?~::,,,:ZN8DDNNNOZ$$77?II7OZI7O$8ODDDDDDNDDDDDZZZZZ$ZZZZZZZZ$$$$$$$$$$777777IIIII7    //
//    8O8777I7I?I?DOOZ$7I??+++===========?7OZI=::,,,~DZDDNNNZZ$Z7I77$7$II,~$ZZ8DDDDDDNNNNDD8OZZZZZZZZOZ$Z$$$$$$$$7777777777777    //
//    8887777I?778OZZ$$$Z$I++==============??Z$+~::,:D7DDMDDOZ$7II7I$$ZI$7$+,+$O$DDDDNMMDDNNNZZZZZZZZZZZZZ$$Z$$$$$77$7777I7I77    //
//    8887777IIIDZZO8DDDND8$I?+====+7$ZODD8OZ??O?~:,,ZI8DMDN$ZZ7$I$N?+ZO7=IZI7:,ZOONDNMNDNDNNNDOOZZZOZZZZZZZZ$$$$$$$77$777IIII    //
//    8887777IIN8ZDD8$77$$$$7I?+++++????+++=+IZ?D?~:,,IDDMDN7$Z$$ZON+?I$7OI7?:7OZ:$$DNMNNDDNNNNZ8ZZOZZZZZZZZZZZ$$$$$7777$77777    //
//    88O77II$DN8DZ$777777ZZZ$7?+==+?I$8O$ZZ$7I7$8?~,,7DDNDN$ZZ$OZOO++I$$O$IOZZ=OO+$8DNO8M8O77$III=ZOOZZZZZZZZ$$$$$$$7777IIII7    //
//    88$7777D8O88ZZZOZZ$$$Z$OIN8I$77$$$$$I+?+==+OI?:,IDDMDN$OOZ$$7I??I$$O+?ZO$I7I???+?$?I$7I?II$??II7IIIOZZZZZZZ$$$$777777777    //
//    8O$77$ODOZ88OO88ODZO?$77ODZ$Z~+77IZZ$=$I??IZOO+:~DDMDDZZZZOI7?I+??I7II$7$7I?7$7+I7I?ZZ$$$ZOI7I7$I7~$OOOZZZ$$$$$$77777777    //
//    O8$77ZNMMZ8OZO8Z$$$III77Z$I+~$=?III???+??+~78M7~:8DND8ZOZ$$+$8???===I77778$$7I?~=:$$77ZZ$7Z$Z$$+I77IIZZZZZZ$$77777777777    //
//    OO$7$ZNMN8$$$$$$$77777$$8$7+~:~=+?II++===~~$~D$+,DDND8ZZ$7I++Z$7Z+Z7$ZZ7$ZI?II+++?7+IZ7I7$$77I7I?II?$$Z$OZZ$$$$77777II77    //
//    ZZ$$$OMNDZI$777I?II7I7$OZ$I+~:$=~=++=====~:?~D8?,ZDNDD$$Z7ZI=IOZ$$OZ877I7$I$7777+7~+I?I+7?7II???????$I$O?7Z$$7777II77777    //
//    ZZ$$Z8MNDZ$D7IIIIIIII$OZZ$I+~:~+ZZI++?7$ZI~~~8D?:?DND8ZZZ$Z+++8Z?OO8OOOZO$$?77I?7=~=?I=I?I?I?++==+++?I$I?7IZ7IIIIIIIIIII    //
//    $$$7ZDMMDOZ$77IIIII7777ZZ7I+~~~~=+++++=~::~~=Z8I:Z8ND8ZZ$$7?==7$I7ODZOZZ$II77?II7+ZI+=+?I?++++++++++?+=I7I7O$I7IIIIIIIII    //
//    7$7$ODNNNOZ$$7I???++?I$$7I?+~:~~~~~~~~:::~~~=ODZ~O8ND8ZZZ$7?==7$Z888$$7?$$I??77?7IIII???++=====++=+++?~=+?$$$7$7ZOD8DDD8    //
//    77$7Z8NNNOO$$7I?++++?7$ZZ$II?++=~~~~~~::~~=~=ODI:8OND8ZOZ$I?+=?IZZZOOZ$Z$7I77I77???++++====~~==~~===++=+~?II7I$$8888DDZO    //
//    $$$$$ONNN8OZ$7II?????7ZOZOO$I+=?=~==~~~~~~~=+ZO?,8OND87Z$Z7++=I7Z8O8D8Z$$II$7II????++++===~~::::~~~==+=~=?II=?I7Z8DD8$ZO    //
//    $ZZZ$ZDNNDOOO$777I??I7$OD8Z$ZZ7?+=======~~~=?O$=ZDOND8$$$$Z++=7O$$$OZ$$ZZZZ$7II?????++++==~:::::::~=++====+??=+IIZ8ZDN8O    //
//    ZZZZ$$8ODDD8O8ZZ77$8D8888DD88ZZO7II7+=++?+++$$+NODONDDOZ77Z==+$$ZOOZOOOZZ$$III??????+++==~~~:::,:::~~=?~==+~===?$$ODDDO7    //
//    OOOO8NODOD88O8OO$Z8DDOOOZ$77I??7I$ZZ7?+?II?778NMOD8NDD7$$7$~+I$ZZ8OOZZ$$$77II??????+++++==~~~~::::::~~=~=?=~~~==+7$ON.+7    //
//    OOOOONNMNN8OO88Z$888OO8OO888ZOOZOZ8OZ$I$III?Z8NMODONDD8O$8??++$O8OZZZ$7$$77II??????++++===~~~::::::::~===+~=~~~~+++?:++I    //
//    OOOO$DMMMDDOOO8DOZO$ZZZZ7I??++==+?7O$I$$$7??ZNNMODZD8O777N?IDI$88OZZ$777777II????????++====~~::~~::::::~~:~::,::=:~?:??7    //
//    OOODMMMMMNN8OODDDZ$ZZZOOOOO$$I??++I$$$ZOZ7$78DMMODZDNOI?787?I?Z8OOOZ$777777II?II??????+==~=~~~~:~:::,,:~:::~.~.,,:~=+7++    //
//    I+NMMMMMMMNND88NNDD88Z$ZZOD8O$$I??I$$OOO$$OZMNMMODZDDII?78??+IO8OOZZZ$7777777IIIIII???+===~~~~~=~~~::::~:,,......:::~?ZI    //
//    NNNMMMMMMMM8NNNNNNNNN8O$$ZOZ7?I7ZOZ8O8Z88O++MNNN8DOD8$+?78???+$8OOOZZ$77777IIIIIIII??++==~~~===~~~::,::~~:,,.....,,=:.7$    //
//    NNNMMMMMMMM88MNNNNNNND88O$ZZII$$8ZDD8D8DD?:=NDNN8DODDO?I:O+++=$8OOOZZ$$$77IIIIIIII?????+=======~+8DDDDDO+~..,.....=:=.II    //
//    NNNMMMMMMMM8O8NMNNNNDDND888OOZ888ODNNDDDOZ$ZNNND8DOD8ZZ+=$==$+ZOOOOOOZ$$7IIIIIIIIIIIIIIII78MNNNNNNNNNNDDO:$7....,.,,~.,.    //
//    NNNNMMMMMMNDO88NMNNNNNNNND88O8D8NDDDDNODD8O7MNND8OZD87$++Z===?$O8OOOZ$$$7IIIIIIIIII7Z8NMMNZZ$$77I?+=~7N8O7Z7IZO:,=,?,,+.    //
//    NNNNMMMMMNND8O88DNNMNMNMNND88DDNNDNDD78NND88ODND88ODDZI=I8==++IO8OOOZ$$$$77I77III7$ONMNOOOZZ$$$7II?+?+DO$?+??$7Z7+=~=.,.    //
//    MNNNNMMNN8DD8OOO8DNNNMMMMNNMMMNNNNN7+?MMMND8OOODD8ZDZ8?I$O=~=++Z8OOOOOZZZ$$77777I$NMZOOO8DDNNN88O7I?+++DI===+I~I$7$~I:,,    //
//    MMNNNMMNN8OD8OZZZ8O8DDNNMMMMNMNN7?+++8MMMMND8OOO88ODZ7$Z?O=~=~++ODNNMMMNN88ZZ$$$ZMN$$OODD88NN887Z$$I?==::,,,:=:~,~I?=~,,    //
//    NMMNNNMNNN$+8OZZ$ZZZ8O888O8Z$7???++++IMNMMMNN8OOOO8DZO$7$~+===NNNMDD8DDMMMMND8ZZ8M$I$O8O88ONN8$77I??+=+:::,,::+:+=~~~,:+    //
//    NNNMNNNNNN77+ZZZ$$$ZZZOZOOZ$II?+++++IIM8MMMMND8O88O88$7$O+=7NN8?888DDNNNNNNNNZ8Z$7I7$ZZ8888OOZ$77$I++~~:,:~:,::+~,:::,,I    //
//    NNNNNNNNNNI?I?=$$$$$7$ZOZOO$7?+++++I+$O8MMMMMND8O8OOD8ZO$ZNNMDD8DDDN88DNDNN8NNZ77$:8$?ZO8OOZZZOOZ7?+~I:,,,~::,::=:,I?~:,    //
//    NNNNNNNNNNZ=++++=I777777777II?++++?++~88NMMMMNND88888OOZ$$NNIDNMNNDDD8NNDDDD8N$7+=7Z$Z$$$$$ZZZZ$7?+=I:::,,,::,::=:,?7I+~    //
//    MMNNDNNNNDNZ~~~===~~:IIIIIIII??+++=,.78ODNMMMMND888N8OO87??MI+ND8O8OO88O88DDNO$?~:+77II77$ZZ$$7II?7~:::::,,:,:::~~.=I7+:    //
//    MMMMNDDDN8ND8:,,:~~~~~::,,,,===~,...=888DDMMMNNND8DD8OODOOOZ7$8DO888888DD8DDDO7?~~~=?IIZ$$ZZ$$ZZI=~~::,:::,,:::::~.==,::    //
//    DMMMMNDDN8NDDD,,,,,,,,,,,,,,,,,,...:$DD888NMMMNNDDND88ZDD88OZIODDZ88OOOOO8DO8O7+::~~==??77$$$7II++~:::::::::::::::,,,,~~    //
//    Z8MNMMMD8DDD8D88:.,,,.............:Z8ON8O8DMMMNDNNND888OZ8888IIODD8OZZZZO8O8OZI+=~~:~=???I$7777I?+==~::~:~::,:::~~,,,,.?    //
//    $ONMNMNDD8N888N888Z,.,,,,.,,,,,,~$ODDDD8OODNMMNMNDMDDOO$O7D8ZIZI78OOZZZOZ88DO$I?+~::=++=+?7$ZZ$7I?++~~~==~~::,::::::+OI+    //
//    8Z8MMMNDD8NDN8OODDD888$+,,:=$OO8888D88D88DDNMMMMNDDNDN$8OI??$O7IZ?OOZZ$$ZOD8$7I?=~:,:::~=??I7$ZO7I?++==~==~~:,::::~+=$I:    //
//    ZZNMMMZDDDMNND8DD8DDD8DDDNNDN8DD8DD88DD8DDDDMMMMMNDDDO$DO$7I+===ZOOZ$$7$ZO8OZ$I?~~~:~+++=+???II7$Z$7I?+====~~:::~:~==~~=    //
//    D8NMMMMDDDMMMNDDONDDNDNN8NN8NDOND8ODDDODDDDDMMMMMNNNN8M8DO7O$++=+OZOZ$$$Z888OZ7$?+?I?+++++=++++??I7Z8$?+==+=~~:~~:~+++??    //
//    DDDNMMM8DDNMMMNN888NNNNNDDNDO8NDDD88DD8DDDDDDMMMMMNDN8MZ8NDD$++~?I7OOZ$$ZOO8O8OO$$7I??++==+==+++?I7ZOO7?==++~~~~~::=====    //
//    8DDDMMMNDDNMMMNMD888DDNNNNNNDDD8DDD8D8DDDDN77NMMMMNNN8M7.NOD8=+~I?$IOZZZZOOOOOOZ$77I??++++??????$NO$Z8$?=+=+==~~~:=$=~=~    //
//    DDDDMMMM8DDNMMMMND8888NDNDNDNDDDDDDOD8DI??7?=DMMNMMDNDMOZOINN8?~IIO?$O$$7OOOOOOOZ$77II??===~~:~+$ZI?IZZI?+++=~~~::IZZ~::    //
//    D88NNMMMNDDNNNMMNNDD888DDDNDDOD888$+~=+??+I++ZNMMNMNMDM8DIOMNDZ??$8$IOZ$77ZO8DNOOZZ$II+++.=,,~=OI?+=+IO7+?++=~~~::7Z77=~    //
//    ND8DNMMMM8DDNNNNNNDDOOOOD8O7$+??++~+?=I+I?I?=INMMNMNMNMD8$8MNDO$ZDZZO7OZ$77ZOO8M$?I?=I~:=:~~=II?+====?$7?+?+=~~:::ZDZ=+?    //
//    DMNNNMMMMMDDD8Z$777I=~~===IIII+=++=I?+++++?+=INNMNNNMNMMDZZDMND$ODO8Z77ZZ777OOO88O+II?=+7??I?++===~~=+77?=++=~::~~OZZZ?=    //
//    8MMNNNMMMM8?+?I7$?I?=~===+I??I+=+=?$+?++??++?+DNMMNMMMN8ZDOZMNDZON8DDOI7ZZ$77OOO88O$$$77$7II?+==~~~~==7I=?+=~:~:~+8$I?7+    //
//    DMMNNNMMNMMO=?I7$$7++==I===I?I?++++II?=?I?I+IIDNMMMMMMOZDD$I$DO78N88NZ$I$ZZ$77OOOOOOZ$$77I???+===~~~~~?+=+=~~~~~+ZZIZ??+    //
//    DNMMNNMMNMM8??II?7$O+?+=+===+?I+I??I++=I+?$==?8DMMMMMMDO$MZ$IDO$?ODDDZOI=OZ$Z7$OOOO$$777III??++===~~~~==?==~~~=+$D$ZI??7    //
//    DNMNNNNMDNNM??++$77I+==+?+===7I?=+??I=I=+???++ODMMMMMMDDI8NO7ZD$?DDD8OO?:78OZZ$ZOOOZ$$777II???+==~~:~~=?+====+?$8D878$??    //
//    ZNMDM88NN8MM?+++I7I7I7==++++=+II=??++?I+??$??+ZDMMMMMDD877NND?8Z7ID88Z7I?DDD8ZZZZOOZZ$$777II???+=~:~~=?====+?I$8DZOZZ7$Z    //
//    ZDNDNM8DNOMMM?I++77?I??=+++===+???$7++77I7II==$DNMMMM8ND7Z$ND8$8$?ZNDIZ8DDND8DOZOOOZZZ$$77II?+++=~~~=?+==+??I$8NDODZZ7$O    //
//    ZDND8N8ODONMM?I?I7??7I+==I++~+?+??I?=?77?7I$?+O8NMMMMNNDO8DDMMDN8OD7$78OMNDNOZDDOOOOZZ$$7III???+=~==++++??I7Z8NN8ZO$Z$O8    //
//    $NDDDDNOD8DMMM?I=+??II7+=?+=+??+??7+?IIIIZ$?I?ODNMMMMMNDOODDNNNDO7Z7$DDD8NDDDZ8DNDOOOZZ$77II??++=+?+??III7$Z8NNNOD8DO       //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MOTHERBOY is ERC721Creator {
    constructor() ERC721Creator("MOTHERBOY", "MOTHERBOY") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xEB067AfFd7390f833eec76BF0C523Cf074a7713C;
        Address.functionDelegateCall(
            0xEB067AfFd7390f833eec76BF0C523Cf074a7713C,
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