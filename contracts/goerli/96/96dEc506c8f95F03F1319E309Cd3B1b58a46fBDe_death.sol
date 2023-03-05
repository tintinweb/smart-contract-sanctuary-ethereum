// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Death is only a Dream
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    WWWNWWNNNWWWWWWWWWWNNNNNNNNNNNNNWMMMWNNNNNNNWMWNNNNNNXXXNWWNNWMMMMMNKO0Kk0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXWMWWWWXNNXXNNXKOkkO0XNWWWWWWWX;                        ...            //
//    WWWNWWNNNWWWWWWWWWWNNNNNNNNNNNXNWMMMWNNNNNNNWMWNNNNNXXXXNWWNNWMMMMMNKOO0kONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMXXWWWNNNXXXXXXXKKOxkk0XXNNNWWWWX;                                       //
//    WWNNNWNNNWWWWWWWWWWNNNNNNNNNXXXNWMMMWNNNNNNNWMWNNNNXXXXXXWWNXWMMMMMNKkO0xONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWXKNNWNXXKKXKKXXK0kxxkOKXXNNNNNWK;                          .   .        //
//    WWNNNWNXNNWWNNWWNWNNNNNNNNNXXXXXWMMMWNNNXNNNWMWNNNNXXXXXXNWXXWMMMMMNKkk0xkNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMWNNK0XNNXXK0KK00KK0OkxxxO0KXXXXNXNK;                          .   .   .    //
//    WWNNNNNXNNNNNNNNNNNNXXNNXNNXXXXXWMMMWNXXXXNNWMNXXXXXXXXXXNWXXWMMMMMN0xkOdkNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWMMNXX0OKXXKK0O000000OOxddxk0KKKXXXXNK;                             ..  ..    //
//    WWNXNNXXNNNNNNNNNNNNXXXXXXXXXXXXWMMMWNXXXXXNWMNXXXXXXKKKXNWXKWMMMMMN0xkOdxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMWNNWWWWMWNKKOk0KK000OOOOOOOOkddddkO0KKKKKKX0;                             ..  ..    //
//    WNNXNNXXXNNNNNNNNNNNXXXXXXXXXXXXWMMMWXXXXXXXWMNXXXXXXKKKXNWKKWMMMMMN0xxOoxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMNXNNWWWMWXK0kxO00OOOkkOkkOOkxdoddxOO00KKKKX0;                             ......    //
//    NNXXNNXXXNNNNNNNNNNXXXXXXXXXXXKXNMMMWXXXXXXXWWNXXXXXKKKKKNWKKWMMMMMXOdxkodNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMNXXNWNWWNK0OxxkOOkkkxxkxxkkxxooooxkOO00000KO,                             ......    //
//    NNXXXNXKXNNNNNNNNNNXXXXXXXXXXXKXNMMMWXXXXXXXNWNXXXXKKKKKKNWKKWMMMMMXOddkldNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMXKXXNNNWX0OkddxkkxxxdxxxxxxxdoloodkkOOO000KO,                             ......    //
//    NNXKXNXKXNNNNNNNNNNXXXXXXXXKKKKKNMMMWXXXXXXXNWNKKKKKKKKKKNWK0WMMMMMXOodkldNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMX0KXNXXXKOkxoodxxddddddddxxddlllldxkkOOOOO0k,                             ......    //
//    NNXKXXXKXXNNNNNNNNNXXXXXXXXKKKKKNMMMWXXXKKXXNWNKKKKKKK00KXW00WMMMMMXOodkcoXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWK0KXNXKK0kxdlloddddooooooddoolcllodxkkkOOOOk,                             ......    //
//    NNXKXXKKKXNNNNNNNNXXKKXXXXXKKKKKNMMMNXKKKKKXNWNKKKKKK000KXN00WMMMMMXklox:oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXN0O0KNKO0OxdocclooooolloloooolccccodxxkkkkkOx,                             ......    //
//    NNKKXXK0KXXXXXXXXNXXKKKKKXXKKKKKNMMMNXKKKKKKNWNKKKKK00000XN00WMMMMMXklld:lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKXOkO0NKkOkdolc:llllllclllloollc:cclodxxxxkkkx,                             ......    //
//    NXKKXXK0KXXXXXXXXXXXKKKKKXKKKK0KNMMMNKKKKKKKNWXKKKKK00000XN0OWMMMMMXkllo;cKWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWX0Kkxk0X0xxdolc::cccccc:ccccllcc::::cooddxxxxkx'                             ......    //
//    XXK0KXK0KXXXXXXXXXXXKKKKKKKKKK0KNMMMNKKKKKKKNWXKKKK000000XNOOWMMMMMXxccl,:ONWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNKOOxdxOKOddoll:;;::::::::::cccc::;::cloodddxxxd'                             ......    //
//    XXK0KXK0KXXXXXXXXXXKKKKKKKKKKK00NMMMNKKKKKKKNWX0000000000XNOOWMMMMMKxc:c,;xKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXX0kkdodk0koolcc;,,;;:;;;;;:::::::;;;::llooddddxd'                             ......    //
//    XXK0KX00KXXXXXXXXXXKKKKKKKKK0000NMMMNKKK00KKNWX000000OOO0KNOOWMMMMMKx:;:',oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKKOdxolox0xllc::,'',,,,,,,,;;;::;;;,;;:cllooodddo'                             ...       //
//    XXK0KX0O0XXXXXXXXXXKKKKKKKK00000NWMMNKKK000KNWX000000OOO0KNOkWMMMMMKx:,;.'cxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKO0koolcldOdc::;;'..'',',,',,,,;;;,,,,;;:clllooodo'                             ...       //
//    XX0OKX0O0KXXXXXXXXXKK0KKKKK00000XWMMNK00000KNWX00000OOOOOKNkkWMMMMMKd;',..;oXMMMMMMMMMMMWWWMMMMMWWMWWWNNNWWWWWWWWNOkOxllc:cokd:;;,,....''''''''',,,,,,,,,;:ccclllool'                              ..       //
//    XX0OKK0O0KXXXKXXXXXK00000KK00000XWMMNK00000KNWX0000OOOOOOKNkkNMMMMMKd;''..'cKMMMWWWNNXKKKKXWMMMMWWMNXK00KKKXXXXXXKkxkd:c;;:oxo;,,,'...........''',,''''',,;::cclllol.                                       //
//    XX0O0K0O0KKKKKKKXXKK00000KK000O0XWMMNK000000NWX0OOOOOOOOOKNkxNMMMMMKd;.....,x0OOOOkkxooodd0WMMMWWWMX0OxkkkOO0000Okddxl;;,,;lxl,'''...............'''''''',;;::ccclll.                                       //
//    XK0O0KOk0KKKKKKKKKKK0000000000O0XWMMN0000000XWXOOOOOOOkOOKNxxNMMMMMKo,...  .....';;;,''',;xWMMMWWWMKkdlooddxxkOkxdlldc,,'',cdc'.....   .................'',;;::ccclc.             ..                        //
//    XK0O0KOkOKKKKKKKKKK000000000OOOOXWMMN0000000XWXOOOOOOkkkOKXxxNMMMMMKo,..          ..    ..oNMMWWWWMKdl;:ccloodxdolcco:''..':o:......        .............',,;;:::ccc.                                       //
//    KKOk0KOkOKKKKKKKKKK00000000OOOOOXWMMN0000O00XWKOOOOOkkkkk0XxxNMMMMM0o,            ........lNMWWWWWM0l;'',,;:clol::;:l;.....;l:......           ...........',,;;;::c:.                                       //
//    KKOk0KOkOKKKKKKKKKK00000000OOOOOXWMMN0OOOOO0XWKOOOOOkkkkk0XxdNMMMMM0c.      .,coxO0KKXXKK0XWMWWWWWMOc'....',;:l:,,';c;.....,c;.  ..             ...........',,,;;:::.                                       //
//    KKOk00OkO0KKKKKKKKK0OO00000OOOOOXWMMN0OOOOO0XWKOOOOkkkkkk0XddNMMMMMO,   .'lkKWMMMMMMMMMMMMMMMMWWWWMk:.  ....',:,...,:,.....,c,.                     ........'',,;;:;.                                       //
//    KKOkO0OxO0KKKKKKKK00OOOOO00OOOkOXWMMN0OOOOO0XWKkkkkkkkkkk0XddNMMMMWx. .ckXWMMMMMMMMMMMMMMMMMMMMMMWMOc'     ...,'...';'    .':'.                       .......'',,;;;.                                       //
//    KKOxO0kxk0KKKKKKKK00OOOOO00OOOkOXWMMXOOOOOOOXWKkkkkkkxxxk0XddNMMMMWo'l0WMMMMMMMMMMMMMMMMMMMMMMMMMMM0o;..     ...   .;.     .;'.                         ......'',,;,.                                       //
//    KKkxO0kxk0K0000KKK00OOOOO00OkkkkXWMMXOOOOOOOXWKkkkkkxxxxx0XdoNMMMMW00WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKxl;'.    ...   .,.     .,.                           ......''',,.                                       //
//    K0kxO0kxk0000000KK00OOOOOOOOkkkkXWMMXOOOOkkOXWKkkkkkxxxxx0XooNMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXOxoo;.    ..   .'.     .'.                            ......'',,.                                       //
//    K0kxO0kdk0000000000OOOOOOOOkkkkkKWMMXOkkkkkOXWKkkkkxxxxxxOXooNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMNK00Kk,         ...     .'.                             ......'''.                                       //
//    00kdO0kdk0000000000OOOOOOOOkkkkkKWMMXOkkkkkOXWKkxxxxxxxxxOXolNMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMWWMWNNWWX;         ...     ...                              ......''.                                       //
//    00kdk0xdx0000000000OOkOOOOOkkkxkKWWMXOkkkkkOXWKxxxxxxxxxxOKolNMMMMMMMMMMMMMWWWMMMMMMMMMMMMMMMMMMNNMMMMWWK;          ..     ...                               ........                                       //
//    00xdkOxdxO000000000OkkOkkOOkkkxkKWMMXOkkkkkkXW0xxxxxxddddOKllNMMMMMMMMMMMWMWWWMMMMMMMMMMMMMMMMMWNNMMMWX0k,          ..     ...                                .......                                       //
//    00xdkOxoxO000000000OkkkkkOOkkkxxKWMMXOkkkkkkXW0xxxxxdddddOKllNMMMMMMMMMMMMMWNWMMMMMMMMMMMMMMMMMWXXMMMNkol.          .      ..                                  ......                                       //
//    0OxdkOxoxO00000000OOkkkkkOOkxxxxKWWMXkkkkkkkXW0xxxxxdddddOKlcNMMMMMMMMMMMMMWNWMWMMMWWWNNNNWMMMMWXXWWNKc,;.                                                     ......                                       //
//    0OxokOxoxO000O0000OOkkkkkkOkxxxxKWWMXkkkkxxkKW0xxxxddddddkKccNMMMMMMMMMMMMMWNNWWNKOkxoc::lkKNWMWK0NXKk,...                                                      .....                                       //
//    0OxokOxoxOOOOOOOO0OOkkkkkkkxxxxxKWWMXkxxxxxkKW0xdddddddddkKccNMWNXXXNWWWMMWWXNWKl,...      .':okxdkkkd'                                                          ...                                        //
//    0OdoxOdodOOOOOOOOOOkkkkkkkkxxxdxKWWMXkxxxxxkKW0ddddddooookKccXKdl:::ok0NWWWNXNWd.               .':ldl.                                                           ..                                        //
//    OOdoxOdldOOOOOOOOOOkkxkkkkkxxxdxKWWWXkxxxxxkKW0dddddoooookKc,l,.    .,l0WWWNKNWl                  .,cc.                                                            .                                        //
//    OOdlxkdldkOOOOOOOOOkxxkkkkkxxxdxKWWWXkxxxxxxKNOdddddoooookKc          .xNMMNKXWl                   .;;.                                                            .                                        //
//    OOdlxkdldkOOOOOOOOOkxxxxxkkxddddKWMMXkxxxxxxKNOdddddoooook0:          .lNWWN0XWl                   .',.                                                                                                     //
//    OOdlxkdldkOOOOOOOOOkxxxxxkkxdddd0WWWKxxxxddx0NOdoodoooooox0:           :0XNN0XWl                   ..'.                                                                                                     //
//    OkdldkoldkOOOOOOOOOkxxxxxkkddddd0WWWKxdxdddx0NOoooooooooox0:           ,lxKXOKWd.                   ...                                                                                                     //
//    OkocdkocokOkkkkOOOkkxxxxxkxdddod0WWWKxdddddx0XOoooooollllxKc           .':kKkKWO:.                  ...                                                                                             .       //
//    OkocdkocokkkkkkkkOkxxxxxxxxdddod0WWWKxdddddx0XkooooolllllxKl             .dOk0WXx:'.               ....                                                                                                     //
//    kkocdkocokkkkkkkkkkxxdxxxxxdddod0NWWKxdddddd0XkooooolllllxKx.            .ckx0WWNKOl'.... ....,:do. ...                                                                                                     //
//    kkocdxocokkkkkkkkkkxdddxxxxdodoo0NWWKxddddddOXkoloolllllldX0c',cd;        ;xd0X0KXNXK0000OO0KKXNXx.                                                                                                         //
//    kkocdxo:oxkkkkkkkkkxdddddxxdooooONNN0xdddoodOKklllllllllldXWXKXWXc        'ddOx'.'',:clldxxdc;:lo:.           ..                                                                                            //
//    kkl:oxl:lxkkkkkkkkkxdddddxxdooooONNN0ddddoodOKxllllllcclcdXWWWXXO'        'ooko.                ..                                                                                                          //
//    kkl:oxl:lxkkkkkkkkkxdddddxxoooooOXNN0dooooodOKxlllllcccccdxol:'cd.        .llxl.                                                                          ..                                                //
//    kxl:oxl:lxkkkkkkkkxxdddddxxoooloOXNN0dooooodOKxlllllccccco:.   ,x,   .    'lcdl. .                                                                         ..                                               //
//    kxl:oxl;lxkkxxxkkkxxdddddddoooloOXXX0dooooook0xllllcccccco:.   ,kl.  ..  ,lc:oc......       ..    ..                                                       .                                                //
//    kxl;oxl;lxxxxxxxxxxddodddddooollkXXXOdooooook0xlcclcccccco:.   ,OO;..,;.,0kc:l:.......  ...                                                                                                                 //
//    kxc;oxc;cxxxxxxxxxxdoodddddolollkKXXOdooooook0dcccccccccco:.   ,0Xd,.:l.,Kk:;c;.......  ..                                                                                                                  //
//    xxc;odc;cxxxxxxxxxxdoooooddollllkKXXOoooollok0dcccccc::::l:.   ,KWO:'lx',0x;,:,........ .                                                                                                                   //
//    xxc;ldc;cdxxxxxxxxxdoooooddollllkKKKOoooollokOdccccc:::::l:.   ,KWXl,x0;,Od,,;,........                                                                   .                                                 //
//    xxc;ldc,cdxxxxxxxxxdoooooddollclkKKKOollllloxOdccccc:::::l:.   ,KMWd;kK;;Oo'','..... .                                                                                                                      //
//    xdc,ldc,cdxxxxxxxxxdoooooddlllclxKKKkollllloxOocccc::::::l;.   ,KMWx:kK;;kc..'.....  ..                                                                                                                .    //
//    xd:,ldc,:dxxxxxxxxddoooooddlllccx0KKkollllllxOoc::c::::::l;.   ,KMWx:k0;:k:..... ..                                                                                                                         //
//    xd:,ld:,:dxxxdxxxxdollooooolllccx000kollllllxko::::::;;;;c;.   ,KMWxckO;:x;..... ..                                                                                                                         //
//    xd:,cd:':dxddddxdxdollooooolclccx000kolllcclxko:::::;;;;;c;.   ,KMWx:xk,;d' .                                                                                                                               //
//    dd:'co:':ddddddddddollooloolccccx000kllllccldko:::::;;;;;c;.   ,KMWx:dd,;o'                    ....                            .                                                                            //
//    dd:'co:':ddddddddddollllloolccccdO00xlllcccldkl::::;;;;;;c;.   ,KMWx:do';o' .                  ...                                                                                                          //
//    dd;'co:':odddddddddolllllooccc:cdOOOxlcccccldxl:;;:;;;;;;:,.   ,KMWx:ol',l'                    ...                                                                                                          //
//    dd;'co;';odddddddddolllllooccc::dOOOxlcccccldxl;;;;;;;;;;:,.   ,0MWx:l:.,c' .                                                           .                                                                   //
//    do;'co;.;odddddddddolllllooccc::dOOOxlccccccdxl;;;;;;,,,,:,.   ,0MWx:c;.,c. .                                                          ..                                                                   //
//    do;.:o;.;odddddddddolclllooc:c::dkOOxlcccc:coxl;;;;;,,,,,:,.   '0MWx;:,.':. .                                                          ..                                                                   //
//    do;.:o;.;oddddddddolcclllllc::::okkkdcccc::codc;;;;;,,,,,;,    '0MWx;;'.';. ..                                                         ..                                                                   //
//    do;.:o;.;odoooododolccllcllc::::okkkdcccc::codc;,;;,,,,,,;,    'OWWx;,...,.                                                                                                                                 //
//    oo,.:l,.,oooooooooolcccccllc::;:okkkdcc::::codc;,,;,,,,,,;'    'OWWd;'...'.                                                                                                                                 //
//    oo,.:l,.,looooooooolcccccll:::;:oxkkdc:::::codc,,,,,,,,,,;'    'kNWd,.   ..                                                                                                                                 //
//    oo,.:l,.,looooooooolcccccll:::;;oxxxdc::::::lo:,,,,,''''';'    'kNNd,.   ..                                                                                                                                 //
//    ol,.;l,.,looooooooolcccccll:;:;;lxxxoc::::::lo:,,,,,''''','    'xXXo,.   ..                                                                                                                                 //
//    ol,.;l,.,looooooooolc:cccll:;;;;lxxxoc:::;;:lo:,,,,'''''','    .xKKo,.   ..                                                                                                                                 //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract death is ERC721Creator {
    constructor() ERC721Creator("Death is only a Dream", "death") {}
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
        (bool success, ) = 0xEB067AfFd7390f833eec76BF0C523Cf074a7713C.delegatecall(abi.encodeWithSignature("initialize(string,string)", name, symbol));
        require(success, "Initialization failed");
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