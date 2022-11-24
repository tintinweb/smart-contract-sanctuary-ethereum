// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LUCY EIGHTOWLS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                             ~G#J.                                                                                          //
//                                                                                         .Y&@@B#@@B~                                                                                        //
//                                                                                      [email protected]@@&5 .~5&@&7                                                                                      //
//                                                                                    [email protected]@@&GJ7! .:[email protected]&^                                                                                    //
//                                                                                  [email protected]@&B5?P!P^ .!#5 :[email protected]&!                                                                                   //
//                                                                                [email protected]@&YJ5B&B#P    [email protected]@^                                                                                  //
//                                                                               [email protected]@&?!JGG&#B#G?7~^?5B#[email protected]                                                                                  //
//                                           .^                                ^@@&Y??P5!~:::::^~~~^[email protected]&&#&@:                                                                                 //
//                                          !&@&#BBBGGY^.                     ^G&J^J?~.:7YG&&@&@@&#B~:~PBGG&&~                                                                                //
//                                         [email protected]@&&#&@@&&&&&&&BY:              [email protected]@? J~^[email protected]@@@@@@@@@@@@@@P:!?7G&#                  ..:~!~!!7777777!^.                                            //
//                                         [email protected]&J:^5!!7!PGYY5B&&&G~          [email protected]@[email protected]@@@@@@@@@@@@@@@@@@@?!:Y?&             .!5B##&&#####GB&&&&&@@@#G.                                         //
//                                        [email protected]@#^ :5PG&#&&#P7!7!?G&&J.       [email protected][email protected]@@@@&P7JY5Y?#@@@@@@@B!~:[email protected]?         :!P&&&&5PGPBBG#&7JBGGB&BJ&@@P                                         //
//                                        &@&J..~JP#@@@&#BYJGGJ?YJYGG~    ^@P ?~7#&&@@&!.   ... .~&@@@@@@5: !#&     :YB##&&B55BGJ7JPPB&###BGG&@B [email protected]@G                                         //
//                                       [email protected]@B~.~YGB&&BY7~.^JY!!??~:.~JB~  [email protected]&[email protected]&~..: .!77~. [email protected]@@@@@&. ^7&   ^B#BGP55G:.^::^^:..!YJPG!^?#@[email protected]@P                                         //
//                                       [email protected]&J .!P&P!::!G#&@@@@@@#B#5~  ^~7&..!Y#&&&&&^.?!7   7J?^  [email protected]@@@@&. .^# .?PG?7^:?&@&&@@@@@@#!~~. 5Y7##Y!JG&@B                                         //
//                                       [email protected]&~  ^#B :[email protected]@@@@@@@@@@@@@@#P! ~#Y ^[email protected]@&&&@G .^5&^::[email protected]  J#@@@@P.  :&J~.7?G&#[email protected]@@@@@@@@@@@@@@~ ~P#&Y!?P#@@!                                        //
//                                      [email protected]@#^  7B.~&@@@@@@&GPB&@@@@@@@@Y     &@@&#&@G  G&&JJY&@&. .&@@@@@P   .?. [email protected]@@@@@@@@@@@@@@@@@@@&7 :[email protected]@~                                        //
//                                      [email protected]@G..:J~^@@@@@@&Y!    [email protected]@@@@@&Y    [email protected]@G5&&#  5#@@@@@&: :?#B#&@@: .:: ^Y&@@@@@@&GGBBPJ?J&@@@@@@@@5 BJ:~5Y&@Y                                         //
//                                       [email protected] ^[email protected]@@&5!~J7:.~:  !GG&@@@@Y ~. [email protected]@##&&?:!7:^~~^J~!~PJ7#@@~ :~: [email protected]@@@@@@B~  ...    [email protected]@@@@@@@[email protected]@^                                         //
//                                       [email protected]?#[email protected]~: .YPY#PGYG. JG&@@@@# .J: J&GJP&#G5~~!^^^~!??!?#@&! 7&Y ~&@@@@@&!   ..^!..:  ^&@@@@@@@P:B5!^[email protected]@:                                         //
//                                       [email protected]&?G5^&@@B.  Y#Y..~P7B7 ~Y&@@@@5 [email protected]~ [email protected]#BGP#B&&&&[email protected]@7 [email protected]:@@@&@@@? :77G5~   .^:[email protected]@@@@@@&B!.:[email protected]@?                                          //
//                                       [email protected]#?G:[email protected]@@@. .B&@7 :?.#&:[email protected]@@@@J :J&&[email protected]&Y77!!G#BY~5&#&G^..:[email protected]? [email protected]&&&#^.&@@@Y   ~5Y! [email protected]@@@@@&?G:^[email protected]@P                                           //
//                                       .&&!P~#@&&@J ^Y5BGGBJG&&57B#G&@@: :[email protected]^ ..^P#BG#&&#PYB#?^^[email protected]#. [email protected]&&&&^[email protected]@G:..!#Y?  [email protected]@@@@@GPP7Y&@B                                            //
//                                        [email protected][email protected]@@@@J.:5GGBG7^.:7#@[email protected]@!  [email protected] .^^::::~7~:.:~^^YGJ?&@#J~~ [email protected]@@&&&B::^5B5!JG&B~7..J&@@@@&G!:?#@@:                                            //
//                                         [email protected]!^J&@@@@&J~^^^:!~^[email protected]! :J:[email protected]@@^ :G&Y!^^:^~!5&##[email protected]@@^.P~:7#&&&B&&^.^  .~!??!~~??5&&@@&G^.!#@#.                                             //
//                                          #@7:[email protected]&&@&#BB##GY&&G##P&&5^[email protected]@B.^[email protected]&P7!?J#&&#[email protected]#: 7GP7^JB#7Y&&&7:^7#&P.:!5BP5GB&@#Y::[email protected]                                               //
//                                          [email protected]~7~Y&#B&@@@@&@@B!7#@@5. ~5^[email protected]&^[email protected]@@@&&&&@@@@&&~^@&:!.~&#!:?P&Y?5#&&BG&@@@#GYGBGG&@&Y^.^[email protected]@#                                                //
//                             .^!5GGGGP555YYBJ.   :5B&@#[email protected]&[email protected]@#~.:^~~Y#&#Y^#@#[email protected]@@@@@@@@@@@G.#&[email protected]&JGG5!:~YG&P&@&&&&&&#&&@@&@@&Y:.~:!BBB#&&&&&&&##B!^:.                                  //
//                           ^[email protected]@@BJJ~:::. .^7?~ .... .?PY5J?!!^!JJPGBGB&@@@@@&~#&[email protected]@@@@@@@@@@@@5!P^&@@@@@@@&G?7^YPP5JB&&&##&&&#5!^. .~!:....:~~!!7777Y#&@@@&G7:                              //
//                       .?G&@&5!^::7Y5!:7J~:.:.  .57&BBP^   .^YPY&@@@@@@@@@@@@#J5#@@@@&@@@@@@@@Y7!&@@@@@@@@@@@#J^::!?7??!^.....~YPY^.^!JGBBBG5J7~~^^^~!J55PB&&@&GY!:.                        //
//                      [email protected]@@#J:  .^[email protected]@&&@@&#[email protected]@@&J~:. :[email protected]@@@@P5&@@&GY&&@@@@&[email protected]@@@&&#@&#@@@@@@@@##&@@@&5?!?~^~?YGPG#&@#!..~5&@@@@@@@@@@@&P!7Y!!?5B###B#&&@@&#!                      //
//                    7&@@B~....!GP~J&&@@@@@@@@@@@&5^ ~JPPG??#B^.^[email protected]@@@@@#&@@PPBGP#[email protected]@@@@@@[email protected]@GB#@@@@@@&@@@@@@@@&P!~Y&@[email protected]@@&7 .J&&&&&&&&@@@@@@@@@PYY!!?YP&&#PYPGB#B&&Y.                    //
//                 [email protected]@@&?^~^:^PG^J#@@@@@@@@@@@@@@@@@B  ^[email protected]@@[email protected]@@@@@@B5&@@@@&B&&&@@@&B&@@&[email protected]@@@@@@@@@@@@@&P!5&@@@#GY: [email protected]&&BP#&&@@@@@@@@@@@@@@[email protected]@&P#&&#P?G&&G.                  //
//               [email protected]@&P!77J&#5J#[email protected]@@#J~::^^^~7P#&@@&@B. ^~B#&@@@@@[email protected]@@@&@@@P&@@@@@@@#~BG&@@@@@G^[email protected]@@#&B#[email protected]@@@&#&&&&BGYY?~.7&@&J?GGJ7^^:.....~5&@@@@@@&. J5&@@&@@7:~7GG#@&!                 //
//               [email protected]@B~.  :~^[email protected]@&!...:!5~7G? .7G&&@@#: ^^...7JYG&B5#@5B#[email protected]@&@BPY7:::[email protected]@@@BB&#&&@[email protected]@P!7~J~. :!^::::.  [email protected]@@@@B .5B&&&&5~5#G?^^&@@G.               //
//                [email protected]@GJ:.~77JB5 [email protected]@&!  .?PG&[email protected]#..?P&[email protected]#::^^~:7?:5G5PP#B5?Y#BG&P!:           .:!7~G##@@@@@&[email protected]@&&&@@@@&#G!::P&^[email protected]^~ [email protected]@&#BGG5^.  [email protected]@@@@B~:BY7YG5GBB5!:7&@@@Y               //
//                 [email protected]@@[email protected]@@[email protected]@@@J .PY5JJYBG&[email protected]@J.7?~^B&B&@@&Y#[email protected]@@@#BJ?:               . !#&&@@@&Y&@@@@@@@@@&B#P!7&&GG#B7:[email protected]@@?J:   .... [email protected]@@@@@G7#?~!PG55GB##@@@@&.               //
//                                                                                                                                                                                            //
//                            '||'      '||'  '|'   ..|'''.| '||' '|'    '||''''|  '||'  ..|'''.|  '||'  '||' |''||''|  ..|''||   '|| '||'  '|' '||'       .|'''.|                            //
//                             ||        ||    |  .|'     '    || |       ||  .     ||  .|'     '   ||    ||     ||    .|'    ||   '|. '|.  .'   ||        ||..  '                            //
//                             ||        ||    |  ||            ||        ||''|     ||  ||    ....  ||''''||     ||    ||      ||   ||  ||  |    ||         ''|||.                            //
//                             ||        ||    |  '|.      .    ||        ||        ||  '|.    ||   ||    ||     ||    '|.     ||    ||| |||     ||       .     '||                           //
//                            .||.....|   '|..'    ''|....'    .||.      .||.....| .||.  ''|...'|  .||.  .||.   .||.    ''|...|'      |   |     .||.....| |'....|'                            //
//                                                                                                                                                                                            //
//                           [email protected]@&?5JYJY&@@@@@@@@&&B?^~.~^5#&&&&&@@&GJB&@@@@@@@&J~J~:.         ~JP5Y^!Y75B&&@&@&Y#@&@@@@@@@@@&7. .. ......:...:^^~~~!^^?G&@@@#5!.                              //
//                            [email protected]@BY7J?:~Y?PPBP7^..^75!:[email protected]@@@&#P5P5B&@@@@@@@@@@@5!P#GP?!^. :^~~:&#[email protected]@@@@@&&@@&&&&#Y5PG##&@@&&#&&&BY~.   :^::^^~J5PG&@@@#!                                   //
//                             .^!?#@&?:       :[email protected]@BYPYJJ~.  [email protected]@&#&@@@@@@@##7B&&&&B55575?G##G#@&#@@&&@@@@@PY&@@&&Y::^^:~?JYYJ7!~~^.     [email protected]@@&#GY7^                                      //
//                                  .J&&P7:  .::~^^^::.      :!&JP&@@P##&@@@@@@Y&[email protected]@@@@@@@@&[email protected]@@@@@&B#@GB&@@@@@@@@BJPY5!....Y#B#&#BP?^:.  .^..7BY                                            //
//                                     [email protected]@7 ..    ~P#&&B?7^ .~!5J:[email protected]@P~7&@@@SUCCESS MONEY LIGHT PEACE [email protected]@@@@@@&?~JPBGGB&&&###&&&@@@@@&5^.    ^57                                          //
//                                     [email protected]~~~^:!#&@@@@@@@@@&&GJ^[email protected]@&G&@@@@@@@@P&@@@@#@@&#&@@@@@@@@@@@@@@@@@@@&GPYG&&GJP55&&##&&&&@@@@@@@@&P^  .:7G!                                        //
//                                   .J#?!7^:5&@@@@@&&&&&@@@@@&#@BJ7&@@@@@@@@@@G&[email protected]@@@@@@@G#@@G&&55G&@@@@@@@&&@[email protected]@&P77YBPGG#&&&&&@@@@@@@@@@@@B^^BP~JG:                                      //
//                                  [email protected]&J.:~^[email protected]@@@@&@&&###&G&@@&[email protected]&GY5Y5B&[email protected]&[email protected]@@@@@@@@@@@@@@&[email protected]&G&@@@@&&&[email protected][email protected]@@@@@@@@Y:!&G.:P5.                                    //
//                                 .&@#^[email protected]@@@@@@B7.:^::^[email protected]@&???!~7^!:7&@&Y&@@@@@@@@@@@@@@@[email protected]#!#@@@@&[email protected]#~J~!?!^~7?&&&@@@!   .Y&@@@@@@@#[email protected]::[email protected]^                                   //
//                                 [email protected]@5:[email protected]@@@@&^  ^5#J.   ^?.5&&&@&?!^7?^^[email protected]@Y^#&@@@@@@&@@@@@@@@[email protected]~!JYY?^[email protected]~B&Y.  [email protected]?5G#@J7 .. :&@@@@@@@?5#&&.^!&&:                                  //
//                                .#@&:!BY [email protected]@&#&^   J##B57!!?Y!7B&&@@5  !J [email protected]@@@:[email protected]&&@@@@@@@@@@@@@@@^[email protected]@5^^~^!&#^5#&B~ .BP^5J^ .^?P:   :&@@@@@@@^YY~B7 JJ&@^                                 //
//                                [email protected]@&7?PG [email protected]@@@#.  ~!#@5YJYGB!^~!P?Y&&:   .&@@@Y !Y&&&&&@@&&&&##&@@@^:@@##~  [email protected]!&B#B: .#B#&@G.  .:.    [email protected]@@@@@@:PY..7:[email protected]@.                                //
//                                 #@&~75G:[email protected]@@@&^ ^G^7:   7&G. :[email protected]@&@@@?  [email protected]@@B  ^7Y7!!?YJPGBBP5YBG5~ 7&&@@^ [email protected]&G&#&#G7 [email protected]@@@@BG^.:.   [email protected]@#??B5^&?  ^[email protected]@G                                //
//                                [email protected]@B!?5#~:@@@@@#7:Y5:  .Y&&&#..7&@@@@@P .&@@@^  ~~J5PB#55##PPY#@@&&Y! :#@@&: [email protected]&&&&&&@5 :PBG7GG!..^^~J&@@@&BG!?PB~..~JBBP&@@:                               //
//                                [email protected]@BJB#B^ [email protected]@@@@G^... ~~Y5&@@:.~#@@@@@B !&@&:  .G&@#G5GJ77?J7~P##&&&@#..!Y#&  #@PB&&##&&J!BBP&P?JP&@@@@@@@@B7?BY~:::~7P#[email protected]@~                               //
//                                [email protected]@#PB&[email protected]@@@@Y:   !!J^5G~ [email protected]@@@@& [email protected]@B   [email protected]&?J#&&P!?7~7Y#&&&&#&&&#J..J~ .G&&&&&&&@@@@@@@@@@@@@@@@@&&G7!#B7.   :^[email protected]@J                               //
//                                [email protected]@&YG&[email protected]@@@@@P7~::J5^.?&@#&@@@@@! 7&#7 [email protected]&BGB5GB~...::!YPB#@&&#&@@B: .   ^P#BB&@@@@@@@@@@@@@@#G#&##BBY5G5!:~~!!:  [email protected]@&                               //
//                                [email protected]@#5P&@&&[email protected]@@@@@@@@@@&&@@@@@@@@@@?  YG^  [email protected]&&5.!^ Y!~?JB5G?7B&&&&@@@@~    .^5P?GG&&@@&&&&#&&5^:7BG!~~!??YGPP#@@@&Y:^[email protected]@!                              //
//                                [email protected]@#5.^&@@B5P!^[email protected]@@@@@@@@@@@@@@@@@@G   7.. [email protected]@P!B#Y5P ~GBG???#@&[email protected]@@@@@@&   .B&&&&B!.^!7JY5GGGBBB##BY~..^7PBB#&&&@&@@@&&@@&                              //
//                                [email protected]@@&~.YG7  !PP7.~BB&@@@@@@@@@@@@@B~   .. . [email protected]@@GY&#57~5BBY :!&BP!  &@@@@@@@~  [email protected]@@@@@@#J77~7JPGB#&&&&&##GG##&&&&@@@@@@@@@@@@@.                             //
//                                :[email protected]@@5^.  :5P^~5PJ?~:5G&&&&#&@@@&Y^..^J#...:[email protected]@#[email protected] :[email protected]&5  :@7 ^  [email protected]#Y7JG&7 :J&:  ~PGB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BPY?                              //
//                                  [email protected]  :~5Y^[email protected]@&5G??5JYJJYY?: ^J#BG&. [email protected]@&#@:   5&JJ  ^B~    ~7~75G57^.7?G          ..:~~~!!!~~~~7JPGGP5Y5Y!^....                                    //
//                                  &@PY7~?~:...!Y?5#PBY!YBJ!77!^^7#@B!  &: Y&.JP#@@@P^  ^J5!  !5.  .^~PBBGP5P5^^P&.                                                                          //
//                                 [email protected]@@@@&#GJJ5BBPYP#5!7YJ!!5B#&&B~.    &B~55 [email protected]@@@@#?!:.   .  ?BJ#B#BBG?~G&[email protected]@:                                                                          //
//                                   .~7?5&@@&@@@@@@@@@@@@@@&PY?^        [email protected]?Y:  :[email protected]@@@@&J.75!^.G&[email protected]@#5B&@@&&@G                                                                           //
//                                         ..  ^~~~~~~??7~~:              [email protected]&.  ^BBY55#@@&@&#&@&##5?YP#BJ#&@@@#[email protected]@.                                                                           //
//                                                                        !&@G?:~Y7.5GJ!?JY&BG57Y57YYJGB&@@@@#~#@^                                                                            //
//                                                                          [email protected]@&#P:.!GGBP5GBGBBPGY?Y#@@@@&@@JP&@~                                                                             //
//                                                                           ^#@@&^.7#!?J^B&PY?J!:#@@@@@@@@[email protected]@J                                                                              //
//                                                                             ^[email protected]@GGG.^[email protected]@#J~:..B&@@@@@&[email protected]@5                                                                               //
//                                                                               [email protected]@@@G7:7P#B!:.. [email protected]@G                                                                                //
//                                                                                ^Y#@@@&&5B7  [email protected]@@?                                                                                 //
//                                                                                   .5&@@@@#J!^.  [email protected]@@#.                                                                                  //
//                                                                                      .?#@@@@&[email protected]@@@P                                                                                    //
//                                                                                         .7B&@@@@@@@@B^                                                                                     //
//                                                                                             :P&&&#Y.                                                                                       //
//                                                                                                                                                                                            //
//                                                                 .|,   .__..__ .___.  .  .._..   .     .__ ._. __..___  .|,                                                                 //
//                                                                 -*-   [__][__)  |    |  | | |   |     [__) | (__ [__   -*-                                                                 //
//                                                                 '|`   |  ||  \  |    |/\|_|_|___|___  |  \_|_.__)[___  '|`                                                                 //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EIGHTOWLS is ERC721Creator {
    constructor() ERC721Creator("LUCY EIGHTOWLS", "EIGHTOWLS") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x03F18a996cD7cB84303054a409F9a6a345C816ff;
        Address.functionDelegateCall(
            0x03F18a996cD7cB84303054a409F9a6a345C816ff,
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