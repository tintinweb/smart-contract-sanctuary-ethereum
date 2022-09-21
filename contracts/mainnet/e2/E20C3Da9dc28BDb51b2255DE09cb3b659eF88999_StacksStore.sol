// SPDX-License-Identifier: MIT
// StacksStore Marketplace - Proxy - Stacks721(tm) / StacksNET(tm) : Stacks and Stacks of Multimedia
// CryptoComics.com - A media token library marketplace built for blockchain networks.
// (c) Copyright 2022, j0zf at apogeeinvent.com
// StacksStore.sol : j0zf 2022-04-23
// Stacks721.sol : CryptoStacks(tm) Stacks721 by j0zf at ApogeeINVENT(tm) 2021-02-28
// StacksNET(tm) : Stacks and Stacks of Multimedia a Library Marketplace built upon an Ethereum sidechain PoA (proof of authority) Blockchain Network.
// .   .       .:      ...   .     * .         ..   :    .        .       .  + .     .  .  +
//   .   . x      . -      . ..       .  ...   .       .    + .          .    .    *        
//      .        .   .   .        ---=*{[ CryptoComics.com ]}*=--    .  x   .   .       .. 
//  .     .  .   . .   *   . .    +  .   .      .   .  .      :.       .              .    .
//    .  .   . .       . .       .   .      .   .  .       .       .      .     ..    .    .
//  .  :     .    ..        ____  __ __      .   *  .   :       ;  .     -=-              . 
// .        .    .   . ."_".^ .^ ^. "'.^`:`-_  .    .    .    .      .       .    :.     .  
//  .   .    +.    ,:".   .    .    "   . . .:`    .  +  .  *    .   .   . ..  .        .   
//   .     . _   ./:           `   .  ^ .  . .:``   _ .       :.     .   .  .       .       
// .   . -      ./.                   .    .  .:`\      . -      .    .  .   .    .     o  :
//   .     .   .':                       .   . .:!.   .        -+-     + + . . ..  .       :
//   O  .      .!                            . !::.      .   .         .   . .:  .     .   +
//  . . .  :.  :!    ^                    ^  . ::!:  .   .      .   :     .   .         .   
//     - .     .:.  .o..               ...o.   ::|. .   : .  .   :  .  .  .   .    .  x     
//   :     .   `: .ooooooo.          .ooooooo :::.   :.   :  _____________                :.
// .  ..  .  .. `! .ooOooooo        .ooooOooo .:'  ..  .   /   .   .       :\ .  . - .   .  
//     .+    : -. \ .ooO*Ooo.      .ooO*Oooo .:'  -     ./   ____________ ,::\ :  .  . .  . 
// .+   .   . .  . \. .oooOoo      :oOooooo..:' .  . . .!| / .   .      `::\::!" .    .  ,  
// : .     .     .. .\ .ooooo      :ooooo.::'   . .   . ( '  .  .         ::!:.)    .  .    
// .   .  .. :  -    .\    ..   .   .. ::.:' . .    : . | !   . .        .::|:|)    -      .
//   +     .  .- ." .  .\      ||     ..:'. .  .  -.  .  . .    .        ::/ //.  .    +    
//  -.   . ` . .  .   . .\.    ``     .:' .  . :. . . .  _\ \___________.:` //___    . - .  
//  .  :        .  .  _ ..:\  .___/  :'. .: _ . .  .    /  \.__ :  : _. ___/ ::""\\     .   
// .  .   . . .. .  .:  . .:\       :': . .    . .  .  !     ''..:.:::/`      `:::||       .
//   .   .     .   .  . . .:.`\_(__/ ::. . :.: .  :.   |     ! :  !  .===   ..  ::||.   x + 
//\___________-...:::::::::::!|    .:\;::::::::::::::::|:   .!  + !!  BOB :.``   :.|::..-___
//            \\:::::::::::../.  ^.: :.;:::::::::::::::!   :!`.  .!.   ^   :::   :!:::://   
//             \\::::::.::::/  .  .:: ::\:::::::::::::.:. .:|`    !! .| |  ::: . :.!:://    
//              \\:_________________________________________________________________://     

pragma solidity >=0.6.0 <0.8.0;
import "./AppBase.sol";

contract StacksStore is AppBase {
    constructor (uint32 networkId) public {
        _values["name"] = "StacksNET Marketplace";
        _values["version"] = "1.2.1";
        _networkId = networkId;
        _roles[_Admin_Role_][msg.sender] = true; // 1:Admin
        _roles[_Manager_Role_][msg.sender] = true; // 2:Manager
        _roles[_Publisher_Role_][msg.sender] = true; // 3:Publisher
    }

    receive () external payable {
        _holdingsTable.creditAccount(Holdings._Refunds_, msg.sender, msg.value);
    }

    fallback () external payable {
        return _delegateLogic();
    }
}