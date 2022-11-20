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

pragma solidity ^0.8.0;

/// @title: Todd Stephens A
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                       //
//                                                                                                                                       //
//    Shoot the hash // chief.sol - select an authority by consensus                                                                     //
//                                                                                                                                       //
//    // Copyright (C) 2017  DappHub, LLC                                                                                                //
//                                                                                                                                       //
//    // This program is free software: you can redistribute it and/or modify                                                            //
//    // it under the terms of the GNU General Public License as published by                                                            //
//    // the Free Software Foundation, either version 3 of the License, or                                                               //
//    // (at your option) any later version.                                                                                             //
//                                                                                                                                       //
//    // This program is distributed in the hope that it will be useful,                                                                 //
//    // but WITHOUT ANY WARRANTY; without even the implied warranty of                                                                  //
//    // MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                                                                   //
//    // GNU General Public License for more details.                                                                                    //
//                                                                                                                                       //
//    // You should have received a copy of the GNU General Public License                                                               //
//    // along with this program.  If not, see <http://www.gnu.org/licenses/>.                                                           //
//                                                                                                                                       //
//    pragma solidity >=0.4.23;                                                                                                          //
//                                                                                                                                       //
//    contract DSMath {                                                                                                                  //
//        function add(uint x, uint y) internal pure returns (uint z) {                                                                  //
//            require((z = x + y) >= x, "ds-math-add-overflow");                                                                         //
//        }                                                                                                                              //
//        function sub(uint x, uint y) internal pure returns (uint z) {                                                                  //
//            require((z = x - y) <= x, "ds-math-sub-underflow");                                                                        //
//        }                                                                                                                              //
//        function mul(uint x, uint y) internal pure returns (uint z) {                                                                  //
//            require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");                                                           //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function min(uint x, uint y) internal pure returns (uint z) {                                                                  //
//            return x <= y ? x : y;                                                                                                     //
//        }                                                                                                                              //
//        function max(uint x, uint y) internal pure returns (uint z) {                                                                  //
//            return x >= y ? x : y;                                                                                                     //
//        }                                                                                                                              //
//        function imin(int x, int y) internal pure returns (int z) {                                                                    //
//            return x <= y ? x : y;                                                                                                     //
//        }                                                                                                                              //
//        function imax(int x, int y) internal pure returns (int z) {                                                                    //
//            return x >= y ? x : y;                                                                                                     //
//        }                                                                                                                              //
//                                                                                                                                       //
//        uint constant WAD = 10 ** 18;                                                                                                  //
//        uint constant RAY = 10 ** 27;                                                                                                  //
//                                                                                                                                       //
//        //rounds to zero if x*y < WAD / 2                                                                                              //
//        function wmul(uint x, uint y) internal pure returns (uint z) {                                                                 //
//            z = add(mul(x, y), WAD / 2) / WAD;                                                                                         //
//        }                                                                                                                              //
//        //rounds to zero if x*y < WAD / 2                                                                                              //
//        function rmul(uint x, uint y) internal pure returns (uint z) {                                                                 //
//            z = add(mul(x, y), RAY / 2) / RAY;                                                                                         //
//        }                                                                                                                              //
//        //rounds to zero if x*y < WAD / 2                                                                                              //
//        function wdiv(uint x, uint y) internal pure returns (uint z) {                                                                 //
//            z = add(mul(x, WAD), y / 2) / y;                                                                                           //
//        }                                                                                                                              //
//        //rounds to zero if x*y < RAY / 2                                                                                              //
//        function rdiv(uint x, uint y) internal pure returns (uint z) {                                                                 //
//            z = add(mul(x, RAY), y / 2) / y;                                                                                           //
//        }                                                                                                                              //
//                                                                                                                                       //
//        // This famous algorithm is called "exponentiation by squaring"                                                                //
//        // and calculates x^n with x as fixed-point and n as regular unsigned.                                                         //
//        //                                                                                                                             //
//        // It's O(log n), instead of O(n) for naive repeated multiplication.                                                           //
//        //                                                                                                                             //
//        // These facts are why it works:                                                                                               //
//        //                                                                                                                             //
//        //  If n is even, then x^n = (x^2)^(n/2).                                                                                      //
//        //  If n is odd,  then x^n = x * x^(n-1),                                                                                      //
//        //   and applying the equation for even x gives                                                                                //
//        //    x^n = x * (x^2)^((n-1) / 2).                                                                                             //
//        //                                                                                                                             //
//        //  Also, EVM division is flooring and                                                                                         //
//        //    floor[(n-1) / 2] = floor[n / 2].                                                                                         //
//        //                                                                                                                             //
//        function rpow(uint x, uint n) internal pure returns (uint z) {                                                                 //
//            z = n % 2 != 0 ? x : RAY;                                                                                                  //
//                                                                                                                                       //
//            for (n /= 2; n != 0; n /= 2) {                                                                                             //
//                x = rmul(x, x);                                                                                                        //
//                                                                                                                                       //
//                if (n % 2 != 0) {                                                                                                      //
//                    z = rmul(z, x);                                                                                                    //
//                }                                                                                                                      //
//            }                                                                                                                          //
//        }                                                                                                                              //
//    }                                                                                                                                  //
//                                                                                                                                       //
//    interface DSAuthority {                                                                                                            //
//        function canCall(                                                                                                              //
//            address src, address dst, bytes4 sig                                                                                       //
//        ) external view returns (bool);                                                                                                //
//    }                                                                                                                                  //
//                                                                                                                                       //
//    contract DSAuthEvents {                                                                                                            //
//        event LogSetAuthority (address indexed authority);                                                                             //
//        event LogSetOwner     (address indexed owner);                                                                                 //
//    }                                                                                                                                  //
//                                                                                                                                       //
//    contract DSAuth is DSAuthEvents {                                                                                                  //
//        DSAuthority  public  authority;                                                                                                //
//        address      public  owner;                                                                                                    //
//                                                                                                                                       //
//        constructor() public {                                                                                                         //
//            owner = msg.sender;                                                                                                        //
//            emit LogSetOwner(msg.sender);                                                                                              //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function setOwner(address owner_)                                                                                              //
//            public                                                                                                                     //
//            auth                                                                                                                       //
//        {                                                                                                                              //
//            owner = owner_;                                                                                                            //
//            emit LogSetOwner(owner);                                                                                                   //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function setAuthority(DSAuthority authority_)                                                                                  //
//            public                                                                                                                     //
//            auth                                                                                                                       //
//        {                                                                                                                              //
//            authority = authority_;                                                                                                    //
//            emit LogSetAuthority(address(authority));                                                                                  //
//        }                                                                                                                              //
//                                                                                                                                       //
//        modifier auth {                                                                                                                //
//            require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");                                                        //
//            _;                                                                                                                         //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function isAuthorized(address src, bytes4 sig) internal view returns (bool) {                                                  //
//            if (src == address(this)) {                                                                                                //
//                return true;                                                                                                           //
//            } else if (src == owner) {                                                                                                 //
//                return true;                                                                                                           //
//            } else if (authority == DSAuthority(0)) {                                                                                  //
//                return false;                                                                                                          //
//            } else {                                                                                                                   //
//                return authority.canCall(src, address(this), sig);                                                                     //
//            }                                                                                                                          //
//        }                                                                                                                              //
//    }                                                                                                                                  //
//                                                                                                                                       //
//    contract DSToken is DSMath, DSAuth {                                                                                               //
//        bool                                              public  stopped;                                                             //
//        uint256                                           public  totalSupply;                                                         //
//        mapping (address => uint256)                      public  balanceOf;                                                           //
//        mapping (address => mapping (address => uint256)) public  allowance;                                                           //
//        bytes32                                           public  symbol;                                                              //
//        uint256                                           public  decimals = 18; // standard token precision. override to customize    //
//        bytes32                                           public  name = "";     // Optional token name                                //
//                                                                                                                                       //
//        constructor(bytes32 symbol_) public {                                                                                          //
//            symbol = symbol_;                                                                                                          //
//        }                                                                                                                              //
//                                                                                                                                       //
//        event Approval(address indexed src, address indexed guy, uint wad);                                                            //
//        event Transfer(address indexed src, address indexed dst, uint wad);                                                            //
//        event Mint(address indexed guy, uint wad);                                                                                     //
//        event Burn(address indexed guy, uint wad);                                                                                     //
//        event Stop();                                                                                                                  //
//        event Start();                                                                                                                 //
//                                                                                                                                       //
//        modifier stoppable {                                                                                                           //
//            require(!stopped, "ds-stop-is-stopped");                                                                                   //
//            _;                                                                                                                         //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function approve(address guy) external returns (bool) {                                                                        //
//            return approve(guy, uint(-1));                                                                                             //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function approve(address guy, uint wad) public stoppable returns (bool) {                                                      //
//            allowance[msg.sender][guy] = wad;                                                                                          //
//                                                                                                                                       //
//            emit Approval(msg.sender, guy, wad);                                                                                       //
//                                                                                                                                       //
//            return true;                                                                                                               //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function transfer(address dst, uint wad) external returns (bool) {                                                             //
//            return transferFrom(msg.sender, dst, wad);                                                                                 //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function transferFrom(address src, address dst, uint wad)                                                                      //
//            public                                                                                                                     //
//            stoppable                                                                                                                  //
//            returns (bool)                                                                                                             //
//        {                                                                                                                              //
//            if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {                                                         //
//                require(allowance[src][msg.sender] >= wad, "ds-token-insufficient-approval");                                          //
//                allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);                                                     //
//            }                                                                                                                          //
//                                                                                                                                       //
//            require(balanceOf[src] >= wad, "ds-token-insufficient-balance");                                                           //
//            balanceOf[src] = sub(balanceOf[src], wad);                                                                                 //
//            balanceOf[dst] = add(balanceOf[dst], wad);                                                                                 //
//                                                                                                                                       //
//            emit Transfer(src, dst, wad);                                                                                              //
//                                                                                                                                       //
//            return true;                                                                                                               //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function push(address dst, uint wad) external {                                                                                //
//            transferFrom(msg.sender, dst, wad);                                                                                        //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function pull(address src, uint wad) external {                                                                                //
//            transferFrom(src, msg.sender, wad);                                                                                        //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function move(address src, address dst, uint wad) external {                                                                   //
//            transferFrom(src, dst, wad);                                                                                               //
//        }                                                                                                                              //
//                                                                                                                                       //
//                                                                                                                                       //
//        function mint(uint wad) external {                                                                                             //
//            mint(msg.sender, wad);                                                                                                     //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function burn(uint wad) external {                                                                                             //
//            burn(msg.sender, wad);                                                                                                     //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function mint(address guy, uint wad) public auth stoppable {                                                                   //
//            balanceOf[guy] = add(balanceOf[guy], wad);                                                                                 //
//            totalSupply = add(totalSupply, wad);                                                                                       //
//            emit Mint(guy, wad);                                                                                                       //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function burn(address guy, uint wad) public auth stoppable {                                                                   //
//            if (guy != msg.sender && allowance[guy][msg.sender] != uint(-1)) {                                                         //
//                require(allowance[guy][msg.sender] >= wad, "ds-token-insufficient-approval");                                          //
//                allowance[guy][msg.sender] = sub(allowance[guy][msg.sender], wad);                                                     //
//            }                                                                                                                          //
//                                                                                                                                       //
//            require(balanceOf[guy] >= wad, "ds-token-insufficient-balance");                                                           //
//            balanceOf[guy] = sub(balanceOf[guy], wad);                                                                                 //
//            totalSupply = sub(totalSupply, wad);                                                                                       //
//            emit Burn(guy, wad);                                                                                                       //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function stop() public auth {                                                                                                  //
//            stopped = true;                                                                                                            //
//            emit Stop();                                                                                                               //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function start() public auth {                                                                                                 //
//            stopped = false;                                                                                                           //
//            emit Start();                                                                                                              //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function setName(bytes32 name_) external auth {                                                                                //
//            name = name_;                                                                                                              //
//        }                                                                                                                              //
//    }                                                                                                                                  //
//                                                                                                                                       //
//    contract DSRoles is DSAuth, DSAuthority                                                                                            //
//    {                                                                                                                                  //
//        mapping(address=>bool) _root_users;                                                                                            //
//        mapping(address=>bytes32) _user_roles;                                                                                         //
//        mapping(address=>mapping(bytes4=>bytes32)) _capability_roles;                                                                  //
//        mapping(address=>mapping(bytes4=>bool)) _public_capabilities;                                                                  //
//                                                                                                                                       //
//        function getUserRoles(address who)                                                                                             //
//            public                                                                                                                     //
//            view                                                                                                                       //
//            returns (bytes32)                                                                                                          //
//        {                                                                                                                              //
//            return _user_roles[who];                                                                                                   //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function getCapabilityRoles(address code, bytes4 sig)                                                                          //
//            public                                                                                                                     //
//            view                                                                                                                       //
//            returns (bytes32)                                                                                                          //
//        {                                                                                                                              //
//            return _capability_roles[code][sig];                                                                                       //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function isUserRoot(address who)                                                                                               //
//            public                                                                                                                     //
//            view                                                                                                                       //
//            returns (bool)                                                                                                             //
//        {                                                                                                                              //
//            return _root_users[who];                                                                                                   //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function isCapabilityPublic(address code, bytes4 sig)                                                                          //
//            public                                                                                                                     //
//            view                                                                                                                       //
//            returns (bool)                                                                                                             //
//        {                                                                                                                              //
//            return _public_capabilities[code][sig];                                                                                    //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function hasUserRole(address who, uint8 role)                                                                                  //
//            public                                                                                                                     //
//            view                                                                                                                       //
//            returns (bool)                                                                                                             //
//        {                                                                                                                              //
//            bytes32 roles = getUserRoles(who);                                                                                         //
//            bytes32 shifted = bytes32(uint256(uint256(2) ** uint256(role)));                                                           //
//            return bytes32(0) != roles & shifted;                                                                                      //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function canCall(address caller, address code, bytes4 sig)                                                                     //
//            public                                                                                                                     //
//            view                                                                                                                       //
//            returns (bool)                                                                                                             //
//        {                                                                                                                              //
//            if( isUserRoot(caller) || isCapabilityPublic(code, sig) ) {                                                                //
//                return true;                                                                                                           //
//            } else {                                                                                                                   //
//                bytes32 has_roles = getUserRoles(caller);                                                                              //
//                bytes32 needs_one_of = getCapabilityRoles(code, sig);                                                                  //
//                return bytes32(0) != has_roles & needs_one_of;                                                                         //
//            }                                                                                                                          //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function BITNOT(bytes32 input) internal pure returns (bytes32 output) {                                                        //
//            return (input ^ bytes32(uint(-1)));                                                                                        //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function setRootUser(address who, bool enabled)                                                                                //
//            public                                                                                                                     //
//            auth                                                                                                                       //
//        {                                                                                                                              //
//            _root_users[who] = enabled;                                                                                                //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function setUserRole(address who, uint8 role, bool enabled)                                                                    //
//            public                                                                                                                     //
//            auth                                                                                                                       //
//        {                                                                                                                              //
//            bytes32 last_roles = _user_roles[who];                                                                                     //
//            bytes32 shifted = bytes32(uint256(uint256(2) ** uint256(role)));                                                           //
//            if( enabled ) {                                                                                                            //
//                _user_roles[who] = last_roles | shifted;                                                                               //
//            } else {                                                                                                                   //
//                _user_roles[who] = last_roles & BITNOT(shifted);                                                                       //
//            }                                                                                                                          //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function setPublicCapability(address code, bytes4 sig, bool enabled)                                                           //
//            public                                                                                                                     //
//            auth                                                                                                                       //
//        {                                                                                                                              //
//            _public_capabilities[code][sig] = enabled;                                                                                 //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function setRoleCapability(uint8 role, address code, bytes4 sig, bool enabled)                                                 //
//            public                                                                                                                     //
//            auth                                                                                                                       //
//        {                                                                                                                              //
//            bytes32 last_roles = _capability_roles[code][sig];                                                                         //
//            bytes32 shifted = bytes32(uint256(uint256(2) ** uint256(role)));                                                           //
//            if( enabled ) {                                                                                                            //
//                _capability_roles[code][sig] = last_roles | shifted;                                                                   //
//            } else {                                                                                                                   //
//                _capability_roles[code][sig] = last_roles & BITNOT(shifted);                                                           //
//            }                                                                                                                          //
//                                                                                                                                       //
//        }                                                                                                                              //
//                                                                                                                                       //
//    }                                                                                                                                  //
//                                                                                                                                       //
//    contract DSNote {                                                                                                                  //
//        event LogNote(                                                                                                                 //
//            bytes4   indexed  sig,                                                                                                     //
//            address  indexed  guy,                                                                                                     //
//            bytes32  indexed  foo,                                                                                                     //
//            bytes32  indexed  bar,                                                                                                     //
//            uint256           wad,                                                                                                     //
//            bytes             fax                                                                                                      //
//        ) anonymous;                                                                                                                   //
//                                                                                                                                       //
//        modifier note {                                                                                                                //
//            bytes32 foo;                                                                                                               //
//            bytes32 bar;                                                                                                               //
//            uint256 wad;                                                                                                               //
//                                                                                                                                       //
//            assembly {                                                                                                                 //
//                foo := calldataload(4)                                                                                                 //
//                bar := calldataload(36)                                                                                                //
//                wad := callvalue()                                                                                                     //
//            }                                                                                                                          //
//                                                                                                                                       //
//            _;                                                                                                                         //
//                                                                                                                                       //
//            emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);                                                                //
//        }                                                                                                                              //
//    }                                                                                                                                  //
//                                                                                                                                       //
//    contract DSThing is DSAuth, DSNote, DSMath {                                                                                       //
//        function S(string memory s) internal pure returns (bytes4) {                                                                   //
//            return bytes4(keccak256(abi.encodePacked(s)));                                                                             //
//        }                                                                                                                              //
//                                                                                                                                       //
//    }                                                                                                                                  //
//                                                                                                                                       //
//    // The right way to use this contract is probably to mix it with some kind                                                         //
//    // of `DSAuthority`, like with `ds-roles`.                                                                                         //
//    //   SEE DSChief                                                                                                                   //
//    contract DSChiefApprovals is DSThing {                                                                                             //
//        mapping(bytes32=>address[]) public slates;                                                                                     //
//        mapping(address=>bytes32) public votes;                                                                                        //
//        mapping(address=>uint256) public approvals;                                                                                    //
//        mapping(address=>uint256) public deposits;                                                                                     //
//        DSToken public GOV; // voting token that gets locked up                                                                        //
//        DSToken public IOU; // non-voting representation of a token, for e.g. secondary voting mechanisms                              //
//        address public hat; // the chieftain's hat                                                                                     //
//                                                                                                                                       //
//        uint256 public MAX_YAYS;                                                                                                       //
//                                                                                                                                       //
//        mapping(address=>uint256) public last;                                                                                         //
//                                                                                                                                       //
//        bool public live;                                                                                                              //
//                                                                                                                                       //
//        uint256 constant LAUNCH_THRESHOLD = 80_000 * 10 ** 18; // 80K MKR launch threshold                                             //
//                                                                                                                                       //
//        event Etch(bytes32 indexed slate);                                                                                             //
//                                                                                                                                       //
//        // IOU constructed outside this contract reduces deployment costs significantly                                                //
//        // lock/free/vote are quite sensitive to token invariants. Caution is advised.                                                 //
//        constructor(DSToken GOV_, DSToken IOU_, uint MAX_YAYS_) public                                                                 //
//        {                                                                                                                              //
//            GOV = GOV_;                                                                                                                //
//            IOU = IOU_;                                                                                                                //
//            MAX_YAYS = MAX_YAYS_;                                                                                                      //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function launch()                                                                                                              //
//            public                                                                                                                     //
//            note                                                                                                                       //
//        {                                                                                                                              //
//            require(!live);                                                                                                            //
//            require(hat == address(0) && approvals[address(0)] >= LAUNCH_THRESHOLD);                                                   //
//            live = true;                                                                                                               //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function lock(uint wad)                                                                                                        //
//            public                                                                                                                     //
//            note                                                                                                                       //
//        {                                                                                                                              //
//            last[msg.sender] = block.number;                                                                                           //
//            GOV.pull(msg.sender, wad);                                                                                                 //
//            IOU.mint(msg.sender, wad);                                                                                                 //
//            deposits[msg.sender] = add(deposits[msg.sender], wad);                                                                     //
//            addWeight(wad, votes[msg.sender]);                                                                                         //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function free(uint wad)                                                                                                        //
//            public                                                                                                                     //
//            note                                                                                                                       //
//        {                                                                                                                              //
//            require(block.number > last[msg.sender]);                                                                                  //
//            deposits[msg.sender] = sub(deposits[msg.sender], wad);                                                                     //
//            subWeight(wad, votes[msg.sender]);                                                                                         //
//            IOU.burn(msg.sender, wad);                                                                                                 //
//            GOV.push(msg.sender, wad);                                                                                                 //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function etch(address[] memory yays)                                                                                           //
//            public                                                                                                                     //
//            note                                                                                                                       //
//            returns (bytes32 slate)                                                                                                    //
//        {                                                                                                                              //
//            require( yays.length <= MAX_YAYS );                                                                                        //
//            requireByteOrderedSet(yays);                                                                                               //
//                                                                                                                                       //
//            bytes32 hash = keccak256(abi.encodePacked(yays));                                                                          //
//            slates[hash] = yays;                                                                                                       //
//            emit Etch(hash);                                                                                                           //
//            return hash;                                                                                                               //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function vote(address[] memory yays) public returns (bytes32)                                                                  //
//            // note  both sub-calls note                                                                                               //
//        {                                                                                                                              //
//            bytes32 slate = etch(yays);                                                                                                //
//            vote(slate);                                                                                                               //
//            return slate;                                                                                                              //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function vote(bytes32 slate)                                                                                                   //
//            public                                                                                                                     //
//            note                                                                                                                       //
//        {                                                                                                                              //
//            require(slates[slate].length > 0 ||                                                                                        //
//                slate == 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470, "ds-chief-invalid-slate");                //
//            uint weight = deposits[msg.sender];                                                                                        //
//            subWeight(weight, votes[msg.sender]);                                                                                      //
//            votes[msg.sender] = slate;                                                                                                 //
//            addWeight(weight, votes[msg.sender]);                                                                                      //
//        }                                                                                                                              //
//                                                                                                                                       //
//        // like `drop`/`swap` except simply "elect this address if it is higher than current hat"                                      //
//        function lift(address whom)                                                                                                    //
//            public                                                                                                                     //
//            note                                                                                                                       //
//        {                                                                                                                              //
//            require(approvals[whom] > approvals[hat]);                                                                                 //
//            hat = whom;                                                                                                                //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function addWeight(uint weight, bytes32 slate)                                                                                 //
//            internal                                                                                                                   //
//        {                                                                                                                              //
//            address[] storage yays = slates[slate];                                                                                    //
//            for( uint i = 0; i < yays.length; i++) {                                                                                   //
//                approvals[yays[i]] = add(approvals[yays[i]], weight);                                                                  //
//            }                                                                                                                          //
//        }                                                                                                                              //
//                                                                                                                                       //
//        function subWeight(uint weight, bytes32 slate)                                                                                 //
//            internal                                                                                                                   //
//        {                                                                                                                              //
//            address[] storage yays = slates[slate];                                                                                    //
//            for( uint i = 0; i < yays.length; i++) {                                                                                   //
//                approvals[                                                                                                             //
//                                                                                                                                       //
//                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Rehash is ERC721Creator {
    constructor() ERC721Creator("Todd Stephens A", "Rehash") {}
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