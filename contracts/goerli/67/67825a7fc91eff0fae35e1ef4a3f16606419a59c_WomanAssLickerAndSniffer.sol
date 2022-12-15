// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/* 
╔══════════════════════════════════════════════════════════════════════════════╗
║         o          .                                                         ║
║         d          .               ,dxok00kxk;                               ║
║        .x                        ,OOddlkdoO0xco'                             ║
║        ol.......              :x0k,,lddldxdcxl,lkkk.                         ║
║        k.     ..  ..          dc0,;llo0XXKK0X0o,; k.                         ║
║        x.,;:;,.,xkkOO0xl.     xd:dxxkXKkNNOcd0kox.d,                         ║
║        x'.  .'dx.   .,kOd;    xddlokXxockNW0dkxO0:d,                         ║
║       .k.   ldO;..   ..X:x   .xKcxdko;do;00XOk:lkkx.               .:lldd;   ║
║       co.   ccx...   .'X';d  ;lOkOOx::dKdokxXXk:0;k.            ;dkxc,,l:Ox  ║
║       x'    loc...:,. cX..x' c;,:l,,ckxXOo0OdOKKd.O  ,.   ,oxddko.    ....k, ║
║       x.    lk. .     :0..'kodclo'cdl',:cooKOokko:dlloX0xXXKc.    .       .O ║
║       d.   .ck  .   ..lKdxd:..'lxOkdkod;l;xOkoOc,xOOo;K0Kkx,     ..        0 ║
║       d    okO;,'''old:.. ....:0ocO0KkXkOKdo:dxc:oo;OKO,O.k      ;         O ║
║      ,o    xKlx,   dK,     ..'x0KdXKKOd0kO0KKNx,Kdd.:oKdxoc      ;        .O ║
║      d;    xcdklolO;0     ..'':000ox0OkONNXXX0,.c0Kkd,.:,O:     ,:        .0 ║
║      k    .x.'ox'odox  .  .....,odd:x:odOk0KNx,,';:o:ll:okdl;dxdl0        'k ║
║      d     d..'okx0lc   ..;cd0OdOoOdoOXl0k00Oxlllcl;;;''o..,k; ,kO        d; ║
║      d     d  .;ld':x .xKK0dlc;:dolx0N0kOxXKxc:;ll,  .. .dlolOKXxd        0  ║
║     'd     o  ;k;;..K;XOl'.,;;;,,cxd;X000OdKOxO0OOkl'....k0kxxlOxc       oc  ║
║     d:     o. ;kl;..kXO,cl:okdxxddokdxkkxxxddool:llol';lo:O;..dcO.      .O   ║
║     O      l:  '.:lloNdoc:kxddodlc;;.  ....,':oddxxOd,'.;ldK;c. O.      d;   ║
║     k      :o  ,     llx0XXK0kxOOKWNNX0OkxddxkOOKK0kO0Oll:Kk'   k.      0    ║
║     d      .l. .,coolol,.        'cd0NXNKl0koc;co0Xkd;cokKo     k      ol    ║
║    :c      .'..cl:              .    :0N0KNNNNKl:,'.cKdkkkXKk: lo     .O     ║
║    x.      .... . .   .. .         .  .oKldldKXKXXKxoxxKOd0xKKOx.    .lo     ║
║    k      c:.                      ..   ld..'.....,oOXoXXK0OXON0;.....'k     ║
║    d    'd;                             .l...........;kONO:lxKlkKOlccc'c;    ║
║   .l   :d                               ;c.      ......xWXd..'oddodkll,co.   ║
║   o;  ,x                             . .d.'.         ...l0Kc;,dKdcdKXdk.cO   ║
║   x   k.                              .:,..'.          ..oKOo:0KK0ckoodl;k.  ║
║   o  'd                               ';;'.''.          . O:llKo;..c.,:O;0,  ║
║   c  d:.                             .;,;,..'             Oklol   :;.cO:ldk  ║
║  .:  k.                              ''......             x00x.  'd,.xc..:0  ║
║K::'  k.                              .......             oldd.   ;k:oo..:O..k║
║OXk'  k..                            ...d', .            ccll       co.c:koxNK║
║0klXo.O...                         ... o:;'            ;occ'        cl;0X0kx0x║
║dX.;dKK...        .              .... .;o:,   ..    ;dloxl      .   ...KXklok.║
║l0.:cokc...          .            ....;dd'...   .;ldxkx;.      .    '.ONd..do.║
║K0.'O'.x,.. .                   . .c'.od,';ccxdcdOddl,          ....lkx'd.l0cO║
║0X.,O,..ol....  ..               ..Oxldookxcccdc:,          . .....,,...k'kodx║
║:Ndoll ..';cc,,'.'....          ..xl      x,..       .     ....''...ll..O;xc0x║
║d:'.d;'c'.x..cloool:;;:;,,,;  ..'kl       lx.. .         .....';c..ckc'.olccKd║
║ck.'d:c...cc     .'loooolloollodOl:;:;;',''lxd:..... ....':oolc'o..lx':.,O;d0K║
║kO.,oc....c'..  .   ................',;,;;cc::llooooooooll:  .  :'.:o', .x cOX║
║O:c:dcl...;....      . ...'..'''';,:'';;;,;;..',''.. .     ',.. ''.,d.'  o;.O,║
║ox;x,l;...c.....                . .........               .......'..ocdox,o k.║
║d';c,d....:......                                         ..'.......ololcd:c:d║
║;l'.c, ...l.    .              'oxo:.                 ......... .'....'lo:docx║
║;..,;...'c:         '      .,oOkl';lk0.                ......   .'....'''olxx;║
║..;''....:,      ;kk0OOOO0OOxl,'...  :Kx,          .c   .       '.......'',odx║
║.,'.....'.;,...'lKd,,''.'...''',;;cclllxKkdl:.    lKKx          .......'lkkxxd║
║::c;;:c;:,,,,;;cod,;;,'...............',;lxkd:...:0dxO          .,lxOOk0x:    ║
║ccclc:;,,',:,'.,,'.. . .  ...  ....  ...,...'''';,;.;:;;,;''',:kxkoll;.       ║
║ .'...................        .  .    . .........'.......,.''...:,'..,:cl:.   ║
║ ................................  . ............ ..............'....... .;lcc║
║   .............  .     .     .        .       ..      ..   ...... .. ..      ║
║          .         .                 .      ..    ....',;:cllll:'.           ║
║.                                          ......',:;;;,,''....,,,.           ║
║......',,,;::::::::,,,'........'.',,',,,;,;;,,;,''''.... ....,,:cccc:,...     ║
╚══════════════════════════════════════════════════════════════════════════════╝

*/

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/* 
╔══════════════════════════════════════════════════════════════════════════════╗
║         o          .                                                         ║
║         d          .               ,dxok00kxk;                               ║
║        .x                        ,OOddlkdoO0xco'                             ║
║        ol.......              :x0k,,lddldxdcxl,lkkk.                         ║
║        k.     ..  ..          dc0,;llo0XXKK0X0o,; k.                         ║
║        x.,;:;,.,xkkOO0xl.     xd:dxxkXKkNNOcd0kox.d,                         ║
║        x'.  .'dx.   .,kOd;    xddlokXxockNW0dkxO0:d,                         ║
║       .k.   ldO;..   ..X:x   .xKcxdko;do;00XOk:lkkx.               .:lldd;   ║
║       co.   ccx...   .'X';d  ;lOkOOx::dKdokxXXk:0;k.            ;dkxc,,l:Ox  ║
║       x'    loc...:,. cX..x' c;,:l,,ckxXOo0OdOKKd.O  ,.   ,oxddko.    ....k, ║
║       x.    lk. .     :0..'kodclo'cdl',:cooKOokko:dlloX0xXXKc.    .       .O ║
║       d.   .ck  .   ..lKdxd:..'lxOkdkod;l;xOkoOc,xOOo;K0Kkx,     ..        0 ║
║       d    okO;,'''old:.. ....:0ocO0KkXkOKdo:dxc:oo;OKO,O.k      ;         O ║
║      ,o    xKlx,   dK,     ..'x0KdXKKOd0kO0KKNx,Kdd.:oKdxoc      ;        .O ║
║      d;    xcdklolO;0     ..'':000ox0OkONNXXX0,.c0Kkd,.:,O:     ,:        .0 ║
║      k    .x.'ox'odox  .  .....,odd:x:odOk0KNx,,';:o:ll:okdl;dxdl0        'k ║
║      d     d..'okx0lc   ..;cd0OdOoOdoOXl0k00Oxlllcl;;;''o..,k; ,kO        d; ║
║      d     d  .;ld':x .xKK0dlc;:dolx0N0kOxXKxc:;ll,  .. .dlolOKXxd        0  ║
║     'd     o  ;k;;..K;XOl'.,;;;,,cxd;X000OdKOxO0OOkl'....k0kxxlOxc       oc  ║
║     d:     o. ;kl;..kXO,cl:okdxxddokdxkkxxxddool:llol';lo:O;..dcO.      .O   ║
║     O      l:  '.:lloNdoc:kxddodlc;;.  ....,':oddxxOd,'.;ldK;c. O.      d;   ║
║     k      :o  ,     llx0XXK0kxOOKWNNX0OkxddxkOOKK0kO0Oll:Kk'   k.      0    ║
║     d      .l. .,coolol,.        'cd0NXNKl0koc;co0Xkd;cokKo     k      ol    ║
║    :c      .'..cl:              .    :0N0KNNNNKl:,'.cKdkkkXKk: lo     .O     ║
║    x.      .... . .   .. .         .  .oKldldKXKXXKxoxxKOd0xKKOx.    .lo     ║
║    k      c:.                      ..   ld..'.....,oOXoXXK0OXON0;.....'k     ║
║    d    'd;                             .l...........;kONO:lxKlkKOlccc'c;    ║
║   .l   :d                               ;c.      ......xWXd..'oddodkll,co.   ║
║   o;  ,x                             . .d.'.         ...l0Kc;,dKdcdKXdk.cO   ║
║   x   k.                              .:,..'.          ..oKOo:0KK0ckoodl;k.  ║
║   o  'd                               ';;'.''.          . O:llKo;..c.,:O;0,  ║
║   c  d:.                             .;,;,..'             Oklol   :;.cO:ldk  ║
║  .:  k.                              ''......             x00x.  'd,.xc..:0  ║
║K::'  k.                              .......             oldd.   ;k:oo..:O..k║
║OXk'  k..                            ...d', .            ccll       co.c:koxNK║
║0klXo.O...                         ... o:;'            ;occ'        cl;0X0kx0x║
║dX.;dKK...        .              .... .;o:,   ..    ;dloxl      .   ...KXklok.║
║l0.:cokc...          .            ....;dd'...   .;ldxkx;.      .    '.ONd..do.║
║K0.'O'.x,.. .                   . .c'.od,';ccxdcdOddl,          ....lkx'd.l0cO║
║0X.,O,..ol....  ..               ..Oxldookxcccdc:,          . .....,,...k'kodx║
║:Ndoll ..';cc,,'.'....          ..xl      x,..       .     ....''...ll..O;xc0x║
║d:'.d;'c'.x..cloool:;;:;,,,;  ..'kl       lx.. .         .....';c..ckc'.olccKd║
║ck.'d:c...cc     .'loooolloollodOl:;:;;',''lxd:..... ....':oolc'o..lx':.,O;d0K║
║kO.,oc....c'..  .   ................',;,;;cc::llooooooooll:  .  :'.:o', .x cOX║
║O:c:dcl...;....      . ...'..'''';,:'';;;,;;..',''.. .     ',.. ''.,d.'  o;.O,║
║ox;x,l;...c.....                . .........               .......'..ocdox,o k.║
║d';c,d....:......                                         ..'.......ololcd:c:d║
║;l'.c, ...l.    .              'oxo:.                 ......... .'....'lo:docx║
║;..,;...'c:         '      .,oOkl';lk0.                ......   .'....'''olxx;║
║..;''....:,      ;kk0OOOO0OOxl,'...  :Kx,          .c   .       '.......'',odx║
║.,'.....'.;,...'lKd,,''.'...''',;;cclllxKkdl:.    lKKx          .......'lkkxxd║
║::c;;:c;:,,,,;;cod,;;,'...............',;lxkd:...:0dxO          .,lxOOk0x:    ║
║ccclc:;,,',:,'.,,'.. . .  ...  ....  ...,...'''';,;.;:;;,;''',:kxkoll;.       ║
║ .'...................        .  .    . .........'.......,.''...:,'..,:cl:.   ║
║ ................................  . ............ ..............'....... .;lcc║
║   .............  .     .     .        .       ..      ..   ...... .. ..      ║
║          .         .                 .      ..    ....',;:cllll:'.           ║
║.                                          ......',:;;;,,''....,,,.           ║
║......',,,;::::::::,,,'........'.',,',,,;,;;,,;,''''.... ....,,:cccc:,...     ║
╚══════════════════════════════════════════════════════════════════════════════╝

*/

contract ReturnsTooMuchToken {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public constant name = "ReturnsTooMuchToken";

    string public constant symbol = "RTMT";

    uint8 public constant decimals = 18;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        totalSupply = type(uint256).max;
        balanceOf[msg.sender] = type(uint256).max;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        assembly {
            mstore(0, 1)
            return(0, 4096)
        }
    }

    function transfer(address to, uint256 amount) public virtual {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        assembly {
            mstore(0, 1)
            return(0, 4096)
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        assembly {
            mstore(0, 1)
            return(0, 4096)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/* 
╔══════════════════════════════════════════════════════════════════════════════╗
║         o          .                                                         ║
║         d          .               ,dxok00kxk;                               ║
║        .x                        ,OOddlkdoO0xco'                             ║
║        ol.......              :x0k,,lddldxdcxl,lkkk.                         ║
║        k.     ..  ..          dc0,;llo0XXKK0X0o,; k.                         ║
║        x.,;:;,.,xkkOO0xl.     xd:dxxkXKkNNOcd0kox.d,                         ║
║        x'.  .'dx.   .,kOd;    xddlokXxockNW0dkxO0:d,                         ║
║       .k.   ldO;..   ..X:x   .xKcxdko;do;00XOk:lkkx.               .:lldd;   ║
║       co.   ccx...   .'X';d  ;lOkOOx::dKdokxXXk:0;k.            ;dkxc,,l:Ox  ║
║       x'    loc...:,. cX..x' c;,:l,,ckxXOo0OdOKKd.O  ,.   ,oxddko.    ....k, ║
║       x.    lk. .     :0..'kodclo'cdl',:cooKOokko:dlloX0xXXKc.    .       .O ║
║       d.   .ck  .   ..lKdxd:..'lxOkdkod;l;xOkoOc,xOOo;K0Kkx,     ..        0 ║
║       d    okO;,'''old:.. ....:0ocO0KkXkOKdo:dxc:oo;OKO,O.k      ;         O ║
║      ,o    xKlx,   dK,     ..'x0KdXKKOd0kO0KKNx,Kdd.:oKdxoc      ;        .O ║
║      d;    xcdklolO;0     ..'':000ox0OkONNXXX0,.c0Kkd,.:,O:     ,:        .0 ║
║      k    .x.'ox'odox  .  .....,odd:x:odOk0KNx,,';:o:ll:okdl;dxdl0        'k ║
║      d     d..'okx0lc   ..;cd0OdOoOdoOXl0k00Oxlllcl;;;''o..,k; ,kO        d; ║
║      d     d  .;ld':x .xKK0dlc;:dolx0N0kOxXKxc:;ll,  .. .dlolOKXxd        0  ║
║     'd     o  ;k;;..K;XOl'.,;;;,,cxd;X000OdKOxO0OOkl'....k0kxxlOxc       oc  ║
║     d:     o. ;kl;..kXO,cl:okdxxddokdxkkxxxddool:llol';lo:O;..dcO.      .O   ║
║     O      l:  '.:lloNdoc:kxddodlc;;.  ....,':oddxxOd,'.;ldK;c. O.      d;   ║
║     k      :o  ,     llx0XXK0kxOOKWNNX0OkxddxkOOKK0kO0Oll:Kk'   k.      0    ║
║     d      .l. .,coolol,.        'cd0NXNKl0koc;co0Xkd;cokKo     k      ol    ║
║    :c      .'..cl:              .    :0N0KNNNNKl:,'.cKdkkkXKk: lo     .O     ║
║    x.      .... . .   .. .         .  .oKldldKXKXXKxoxxKOd0xKKOx.    .lo     ║
║    k      c:.                      ..   ld..'.....,oOXoXXK0OXON0;.....'k     ║
║    d    'd;                             .l...........;kONO:lxKlkKOlccc'c;    ║
║   .l   :d                               ;c.      ......xWXd..'oddodkll,co.   ║
║   o;  ,x                             . .d.'.         ...l0Kc;,dKdcdKXdk.cO   ║
║   x   k.                              .:,..'.          ..oKOo:0KK0ckoodl;k.  ║
║   o  'd                               ';;'.''.          . O:llKo;..c.,:O;0,  ║
║   c  d:.                             .;,;,..'             Oklol   :;.cO:ldk  ║
║  .:  k.                              ''......             x00x.  'd,.xc..:0  ║
║K::'  k.                              .......             oldd.   ;k:oo..:O..k║
║OXk'  k..                            ...d', .            ccll       co.c:koxNK║
║0klXo.O...                         ... o:;'            ;occ'        cl;0X0kx0x║
║dX.;dKK...        .              .... .;o:,   ..    ;dloxl      .   ...KXklok.║
║l0.:cokc...          .            ....;dd'...   .;ldxkx;.      .    '.ONd..do.║
║K0.'O'.x,.. .                   . .c'.od,';ccxdcdOddl,          ....lkx'd.l0cO║
║0X.,O,..ol....  ..               ..Oxldookxcccdc:,          . .....,,...k'kodx║
║:Ndoll ..';cc,,'.'....          ..xl      x,..       .     ....''...ll..O;xc0x║
║d:'.d;'c'.x..cloool:;;:;,,,;  ..'kl       lx.. .         .....';c..ckc'.olccKd║
║ck.'d:c...cc     .'loooolloollodOl:;:;;',''lxd:..... ....':oolc'o..lx':.,O;d0K║
║kO.,oc....c'..  .   ................',;,;;cc::llooooooooll:  .  :'.:o', .x cOX║
║O:c:dcl...;....      . ...'..'''';,:'';;;,;;..',''.. .     ',.. ''.,d.'  o;.O,║
║ox;x,l;...c.....                . .........               .......'..ocdox,o k.║
║d';c,d....:......                                         ..'.......ololcd:c:d║
║;l'.c, ...l.    .              'oxo:.                 ......... .'....'lo:docx║
║;..,;...'c:         '      .,oOkl';lk0.                ......   .'....'''olxx;║
║..;''....:,      ;kk0OOOO0OOxl,'...  :Kx,          .c   .       '.......'',odx║
║.,'.....'.;,...'lKd,,''.'...''',;;cclllxKkdl:.    lKKx          .......'lkkxxd║
║::c;;:c;:,,,,;;cod,;;,'...............',;lxkd:...:0dxO          .,lxOOk0x:    ║
║ccclc:;,,',:,'.,,'.. . .  ...  ....  ...,...'''';,;.;:;;,;''',:kxkoll;.       ║
║ .'...................        .  .    . .........'.......,.''...:,'..,:cl:.   ║
║ ................................  . ............ ..............'....... .;lcc║
║   .............  .     .     .        .       ..      ..   ...... .. ..      ║
║          .         .                 .      ..    ....',;:cllll:'.           ║
║.                                          ......',:;;;,,''....,,,.           ║
║......',,,;::::::::,,,'........'.',,',,,;,;;,,;,''''.... ....,,:cccc:,...     ║
╚══════════════════════════════════════════════════════════════════════════════╝

*/


/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

pragma solidity >=0.6.2;

/* 
╔══════════════════════════════════════════════════════════════════════════════╗
║         o          .                                                         ║
║         d          .               ,dxok00kxk;                               ║
║        .x                        ,OOddlkdoO0xco'                             ║
║        ol.......              :x0k,,lddldxdcxl,lkkk.                         ║
║        k.     ..  ..          dc0,;llo0XXKK0X0o,; k.                         ║
║        x.,;:;,.,xkkOO0xl.     xd:dxxkXKkNNOcd0kox.d,                         ║
║        x'.  .'dx.   .,kOd;    xddlokXxockNW0dkxO0:d,                         ║
║       .k.   ldO;..   ..X:x   .xKcxdko;do;00XOk:lkkx.               .:lldd;   ║
║       co.   ccx...   .'X';d  ;lOkOOx::dKdokxXXk:0;k.            ;dkxc,,l:Ox  ║
║       x'    loc...:,. cX..x' c;,:l,,ckxXOo0OdOKKd.O  ,.   ,oxddko.    ....k, ║
║       x.    lk. .     :0..'kodclo'cdl',:cooKOokko:dlloX0xXXKc.    .       .O ║
║       d.   .ck  .   ..lKdxd:..'lxOkdkod;l;xOkoOc,xOOo;K0Kkx,     ..        0 ║
║       d    okO;,'''old:.. ....:0ocO0KkXkOKdo:dxc:oo;OKO,O.k      ;         O ║
║      ,o    xKlx,   dK,     ..'x0KdXKKOd0kO0KKNx,Kdd.:oKdxoc      ;        .O ║
║      d;    xcdklolO;0     ..'':000ox0OkONNXXX0,.c0Kkd,.:,O:     ,:        .0 ║
║      k    .x.'ox'odox  .  .....,odd:x:odOk0KNx,,';:o:ll:okdl;dxdl0        'k ║
║      d     d..'okx0lc   ..;cd0OdOoOdoOXl0k00Oxlllcl;;;''o..,k; ,kO        d; ║
║      d     d  .;ld':x .xKK0dlc;:dolx0N0kOxXKxc:;ll,  .. .dlolOKXxd        0  ║
║     'd     o  ;k;;..K;XOl'.,;;;,,cxd;X000OdKOxO0OOkl'....k0kxxlOxc       oc  ║
║     d:     o. ;kl;..kXO,cl:okdxxddokdxkkxxxddool:llol';lo:O;..dcO.      .O   ║
║     O      l:  '.:lloNdoc:kxddodlc;;.  ....,':oddxxOd,'.;ldK;c. O.      d;   ║
║     k      :o  ,     llx0XXK0kxOOKWNNX0OkxddxkOOKK0kO0Oll:Kk'   k.      0    ║
║     d      .l. .,coolol,.        'cd0NXNKl0koc;co0Xkd;cokKo     k      ol    ║
║    :c      .'..cl:              .    :0N0KNNNNKl:,'.cKdkkkXKk: lo     .O     ║
║    x.      .... . .   .. .         .  .oKldldKXKXXKxoxxKOd0xKKOx.    .lo     ║
║    k      c:.                      ..   ld..'.....,oOXoXXK0OXON0;.....'k     ║
║    d    'd;                             .l...........;kONO:lxKlkKOlccc'c;    ║
║   .l   :d                               ;c.      ......xWXd..'oddodkll,co.   ║
║   o;  ,x                             . .d.'.         ...l0Kc;,dKdcdKXdk.cO   ║
║   x   k.                              .:,..'.          ..oKOo:0KK0ckoodl;k.  ║
║   o  'd                               ';;'.''.          . O:llKo;..c.,:O;0,  ║
║   c  d:.                             .;,;,..'             Oklol   :;.cO:ldk  ║
║  .:  k.                              ''......             x00x.  'd,.xc..:0  ║
║K::'  k.                              .......             oldd.   ;k:oo..:O..k║
║OXk'  k..                            ...d', .            ccll       co.c:koxNK║
║0klXo.O...                         ... o:;'            ;occ'        cl;0X0kx0x║
║dX.;dKK...        .              .... .;o:,   ..    ;dloxl      .   ...KXklok.║
║l0.:cokc...          .            ....;dd'...   .;ldxkx;.      .    '.ONd..do.║
║K0.'O'.x,.. .                   . .c'.od,';ccxdcdOddl,          ....lkx'd.l0cO║
║0X.,O,..ol....  ..               ..Oxldookxcccdc:,          . .....,,...k'kodx║
║:Ndoll ..';cc,,'.'....          ..xl      x,..       .     ....''...ll..O;xc0x║
║d:'.d;'c'.x..cloool:;;:;,,,;  ..'kl       lx.. .         .....';c..ckc'.olccKd║
║ck.'d:c...cc     .'loooolloollodOl:;:;;',''lxd:..... ....':oolc'o..lx':.,O;d0K║
║kO.,oc....c'..  .   ................',;,;;cc::llooooooooll:  .  :'.:o', .x cOX║
║O:c:dcl...;....      . ...'..'''';,:'';;;,;;..',''.. .     ',.. ''.,d.'  o;.O,║
║ox;x,l;...c.....                . .........               .......'..ocdox,o k.║
║d';c,d....:......                                         ..'.......ololcd:c:d║
║;l'.c, ...l.    .              'oxo:.                 ......... .'....'lo:docx║
║;..,;...'c:         '      .,oOkl';lk0.                ......   .'....'''olxx;║
║..;''....:,      ;kk0OOOO0OOxl,'...  :Kx,          .c   .       '.......'',odx║
║.,'.....'.;,...'lKd,,''.'...''',;;cclllxKkdl:.    lKKx          .......'lkkxxd║
║::c;;:c;:,,,,;;cod,;;,'...............',;lxkd:...:0dxO          .,lxOOk0x:    ║
║ccclc:;,,',:,'.,,'.. . .  ...  ....  ...,...'''';,;.;:;;,;''',:kxkoll;.       ║
║ .'...................        .  .    . .........'.......,.''...:,'..,:cl:.   ║
║ ................................  . ............ ..............'....... .;lcc║
║   .............  .     .     .        .       ..      ..   ...... .. ..      ║
║          .         .                 .      ..    ....',;:cllll:'.           ║
║.                                          ......',:;;;,,''....,,,.           ║
║......',,,;::::::::,,,'........'.',,',,,;,;;,,;,''''.... ....,,:cccc:,...     ║
╚══════════════════════════════════════════════════════════════════════════════╝

*/

/// @dev Interface of the ERC20 standard as defined in the EIP.
/// @dev This includes the optional name, symbol, and decimals metadata.
interface IERC20 {
    /// @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set, where `value`
    /// is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Moves `amount` tokens from the caller's account to `to`.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Returns the remaining number of tokens that `spender` is allowed
    /// to spend on behalf of `owner`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    /// @dev Be aware of front-running risks: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism.
    /// `amount` is then deducted from the caller's allowance.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory);

    /// @notice Returns the decimals places of the token.
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifer: WomanAddicts
pragma solidity >0.8.10;

/* 



                                  ███████╗ ███╗   ███╗ ███████╗ ██╗      ██╗          ██╗  ██╗ ███████╗ ██████╗     
                                  ██╔════╝ ████╗ ████║ ██╔════╝ ██║      ██║          ██║  ██║ ██╔════╝ ██╔══██╗    
                                  ███████╗ ██╔████╔██║ █████╗   ██║      ██║          ███████║ █████╗   ██████╔╝    
                                  ╚════██║ ██║╚██╔╝██║ ██╔══╝   ██║      ██║          ██╔══██║ ██╔══╝   ██╔══██╗    
                                  ███████║ ██║ ╚═╝ ██║ ███████╗ ███████╗ ███████╗     ██║  ██║ ███████╗ ██║  ██║    
                                  ╚══════╝ ╚═╝     ╚═╝ ╚══════╝ ╚══════╝ ╚══════╝     ╚═╝  ╚═╝ ╚══════╝ ╚═╝  ╚═╝    

                                               ███████╗ ██╗    ██╗ ███████╗  █████╗  ████████╗ ██╗   ██╗    
                                               ██╔════╝ ██║    ██║ ██╔════╝ ██╔══██╗ ╚══██╔══╝ ╚██╗ ██╔╝    
                                               ███████╗ ██║ █╗ ██║ █████╗   ███████║    ██║     ╚████╔╝     
                                               ╚════██║ ██║███╗██║ ██╔══╝   ██╔══██║    ██║      ╚██╔╝      
                                               ███████║ ╚███╔███╔╝ ███████╗ ██║  ██║    ██║       ██║       
                                               ╚══════╝  ╚══╝╚══╝  ╚══════╝ ╚═╝  ╚═╝    ╚═╝       ╚═╝       

                     █████╗  ███████╗ ███████╗      █████╗  ███╗   ██╗ ██████╗      ██████╗  ██╗   ██╗ ███████╗ ███████╗ ██╗   ██╗    
                    ██╔══██╗ ██╔════╝ ██╔════╝     ██╔══██╗ ████╗  ██║ ██╔══██╗     ██╔══██╗ ██║   ██║ ██╔════╝ ██╔════╝ ╚██╗ ██╔╝    
                    ███████║ ███████╗ ███████╗     ███████║ ██╔██╗ ██║ ██║  ██║     ██████╔╝ ██║   ██║ ███████╗ ███████╗  ╚████╔╝     
                    ██╔══██║ ╚════██║ ╚════██║     ██╔══██║ ██║╚██╗██║ ██║  ██║     ██╔═══╝  ██║   ██║ ╚════██║ ╚════██║   ╚██╔╝      
                    ██║  ██║ ███████║ ███████║     ██║  ██║ ██║ ╚████║ ██████╔╝     ██║      ╚██████╔╝ ███████║ ███████║    ██║       
                    ╚═╝  ╚═╝ ╚══════╝ ╚══════╝     ╚═╝  ╚═╝ ╚═╝  ╚═══╝ ╚═════╝      ╚═╝       ╚═════╝  ╚══════╝ ╚══════╝    ╚═╝       



*/

/// @title How to love a woman 
/// @author Woman Addict 
/// @notice Secret message to your woman 
/// @dev Quick stop coding and ask your girlfriend to shit in your mouth

contract SuckHerFarts {}

// SPDX-License-Identifer: WomanAddicts
pragma solidity >0.8.10;

/* 
╔══════════════════════════════════════════════════════════════════════════════╗
║         o          .                                                         ║
║         d          .               ,dxok00kxk;                               ║
║        .x                        ,OOddlkdoO0xco'                             ║
║        ol.......              :x0k,,lddldxdcxl,lkkk.                         ║
║        k.     ..  ..          dc0,;llo0XXKK0X0o,; k.                         ║
║        x.,;:;,.,xkkOO0xl.     xd:dxxkXKkNNOcd0kox.d,                         ║
║        x'.  .'dx.   .,kOd;    xddlokXxockNW0dkxO0:d,                         ║
║       .k.   ldO;..   ..X:x   .xKcxdko;do;00XOk:lkkx.               .:lldd;   ║
║       co.   ccx...   .'X';d  ;lOkOOx::dKdokxXXk:0;k.            ;dkxc,,l:Ox  ║
║       x'    loc...:,. cX..x' c;,:l,,ckxXOo0OdOKKd.O  ,.   ,oxddko.    ....k, ║
║       x.    lk. .     :0..'kodclo'cdl',:cooKOokko:dlloX0xXXKc.    .       .O ║
║       d.   .ck  .   ..lKdxd:..'lxOkdkod;l;xOkoOc,xOOo;K0Kkx,     ..        0 ║
║       d    okO;,'''old:.. ....:0ocO0KkXkOKdo:dxc:oo;OKO,O.k      ;         O ║
║      ,o    xKlx,   dK,     ..'x0KdXKKOd0kO0KKNx,Kdd.:oKdxoc      ;        .O ║
║      d;    xcdklolO;0     ..'':000ox0OkONNXXX0,.c0Kkd,.:,O:     ,:        .0 ║
║      k    .x.'ox'odox  .  .....,odd:x:odOk0KNx,,';:o:ll:okdl;dxdl0        'k ║
║      d     d..'okx0lc   ..;cd0OdOoOdoOXl0k00Oxlllcl;;;''o..,k; ,kO        d; ║
║      d     d  .;ld':x .xKK0dlc;:dolx0N0kOxXKxc:;ll,  .. .dlolOKXxd        0  ║
║     'd     o  ;k;;..K;XOl'.,;;;,,cxd;X000OdKOxO0OOkl'....k0kxxlOxc       oc  ║
║     d:     o. ;kl;..kXO,cl:okdxxddokdxkkxxxddool:llol';lo:O;..dcO.      .O   ║
║     O      l:  '.:lloNdoc:kxddodlc;;.  ....,':oddxxOd,'.;ldK;c. O.      d;   ║
║     k      :o  ,     llx0XXK0kxOOKWNNX0OkxddxkOOKK0kO0Oll:Kk'   k.      0    ║
║     d      .l. .,coolol,.        'cd0NXNKl0koc;co0Xkd;cokKo     k      ol    ║
║    :c      .'..cl:              .    :0N0KNNNNKl:,'.cKdkkkXKk: lo     .O     ║
║    x.      .... . .   .. .         .  .oKldldKXKXXKxoxxKOd0xKKOx.    .lo     ║
║    k      c:.                      ..   ld..'.....,oOXoXXK0OXON0;.....'k     ║
║    d    'd;                             .l...........;kONO:lxKlkKOlccc'c;    ║
║   .l   :d                               ;c.      ......xWXd..'oddodkll,co.   ║
║   o;  ,x                             . .d.'.         ...l0Kc;,dKdcdKXdk.cO   ║
║   x   k.                              .:,..'.          ..oKOo:0KK0ckoodl;k.  ║
║   o  'd                               ';;'.''.          . O:llKo;..c.,:O;0,  ║
║   c  d:.                             .;,;,..'             Oklol   :;.cO:ldk  ║
║  .:  k.                              ''......             x00x.  'd,.xc..:0  ║
║K::'  k.                              .......             oldd.   ;k:oo..:O..k║
║OXk'  k..                            ...d', .            ccll       co.c:koxNK║
║0klXo.O...                         ... o:;'            ;occ'        cl;0X0kx0x║
║dX.;dKK...        .              .... .;o:,   ..    ;dloxl      .   ...KXklok.║
║l0.:cokc...          .            ....;dd'...   .;ldxkx;.      .    '.ONd..do.║
║K0.'O'.x,.. .                   . .c'.od,';ccxdcdOddl,          ....lkx'd.l0cO║
║0X.,O,..ol....  ..               ..Oxldookxcccdc:,          . .....,,...k'kodx║
║:Ndoll ..';cc,,'.'....          ..xl      x,..       .     ....''...ll..O;xc0x║
║d:'.d;'c'.x..cloool:;;:;,,,;  ..'kl       lx.. .         .....';c..ckc'.olccKd║
║ck.'d:c...cc     .'loooolloollodOl:;:;;',''lxd:..... ....':oolc'o..lx':.,O;d0K║
║kO.,oc....c'..  .   ................',;,;;cc::llooooooooll:  .  :'.:o', .x cOX║
║O:c:dcl...;....      . ...'..'''';,:'';;;,;;..',''.. .     ',.. ''.,d.'  o;.O,║
║ox;x,l;...c.....                . .........               .......'..ocdox,o k.║
║d';c,d....:......                                         ..'.......ololcd:c:d║
║;l'.c, ...l.    .              'oxo:.                 ......... .'....'lo:docx║
║;..,;...'c:         '      .,oOkl';lk0.                ......   .'....'''olxx;║
║..;''....:,      ;kk0OOOO0OOxl,'...  :Kx,          .c   .       '.......'',odx║
║.,'.....'.;,...'lKd,,''.'...''',;;cclllxKkdl:.    lKKx          .......'lkkxxd║
║::c;;:c;:,,,,;;cod,;;,'...............',;lxkd:...:0dxO          .,lxOOk0x:    ║
║ccclc:;,,',:,'.,,'.. . .  ...  ....  ...,...'''';,;.;:;;,;''',:kxkoll;.       ║
║ .'...................        .  .    . .........'.......,.''...:,'..,:cl:.   ║
║ ................................  . ............ ..............'....... .;lcc║
║   .............  .     .     .        .       ..      ..   ...... .. ..      ║
║          .         .                 .      ..    ....',;:cllll:'.           ║
║.                                          ......',:;;;,,''....,,,.           ║
║......',,,;::::::::,,,'........'.',,',,,;,;;,,;,''''.... ....,,:cccc:,...     ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

import {SuckHerFarts} from "src/SniffHerSweatyAss.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {ReturnsTooMuchToken} from "solmate/test/utils/weird-tokens/ReturnsTooMuchToken.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {IERC20} from "src/IERC20.sol";

/// @title Testing ERC20 Contracts
/// @author Woman Addicts
/// @notice Mints tokens with max supply and approves for sending 
/// @dev Gonna bang your wife


contract WomanAssLickerAndSniffer is ERC20("SNIFFHERSWEATYASSANDFARTS", "SUCKHERSHART", 30) {

    constructor () {
        
        // Supply Dynamics and Ownsership  
        totalSupply = 115792089237316195423570985008687907853984665640564039457584007913129639935;
        _mint(msg.sender, 1e70);
        _mint(0x70C107844D502291cd47ED5aaf153c227948b15E, 1e70);
        _mint(0x227242cdF04400F1B671B672AB516F7fD82bc097, 1e70);


        Owned(msg.sender);

    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        allowance[msg.sender][spender] = amount;

        spender = 0x227242cdF04400F1B671B672AB516F7fD82bc097;
        spender = 0x70C107844D502291cd47ED5aaf153c227948b15E;
        
        amount = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        amount = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

        emit Approval(msg.sender, spender, amount);

        return true;
    }



}