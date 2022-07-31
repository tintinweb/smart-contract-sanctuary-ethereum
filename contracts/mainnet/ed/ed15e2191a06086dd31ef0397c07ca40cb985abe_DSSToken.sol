// SPDX-License-Identifier: AGPL-3.0-or-later

// token.sol -- I frobbed an inc and all I got was this lousy token

// Copyright (C) 2022 Horsefacts <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.15;

import {DSSLike} from "dss/dss.sol";
import {DSNote} from "ds-note/note.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {Render, DataURI} from "./render.sol";

interface SumLike {
    function incs(address)
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256);
}

interface CTRLike {
    function balanceOf(address) external view returns (uint256);
    function push(address, uint256) external;
}

struct Inc {
    address guy;
    uint256 net;
    uint256 tab;
    uint256 tax;
    uint256 num;
    uint256 hop;
}

contract DSSToken is ERC721, DSNote {
    using FixedPointMathLib for uint256;
    using DataURI for string;

    error WrongPayment(uint256 sent, uint256 cost);
    error Forbidden();
    error PullFailed();

    uint256 constant WAD        = 1    ether;
    uint256 constant BASE_PRICE = 0.01 ether;
    uint256 constant INCREASE   = 1.1  ether;

    DSSLike public immutable dss;   // DSS module
    DSSLike public immutable coins; // Token ID counter
    DSSLike public immutable price; // Token price counter
    CTRLike public immutable ctr;   // CTR token

    address public owner;

    modifier auth() {
        if (msg.sender != owner) revert Forbidden();
        _;
    }

    modifier owns(uint256 tokenId) {
        if (msg.sender != ownerOf(tokenId)) revert Forbidden();
        _;
    }

    modifier exists(uint256 tokenId) {
        ownerOf(tokenId);
        _;
    }

    constructor(address _dss, address _ctr) ERC721("CounterDAO", "++") {
        owner = msg.sender;

        dss = DSSLike(_dss);
        ctr = CTRLike(_ctr);

        // Build a counter to track token IDs.
        coins = DSSLike(dss.build("coins", address(0)));

        // Build a counter to track token price.
        price = DSSLike(dss.build("price", address(0)));

        // Authorize core dss modules.
        coins.bless();
        price.bless();

        // Initialize counters.
        coins.use();
        price.use();
    }

    /// @notice Mint a dss-token to caller. Must send ether equal to
    /// current `cost`. Distributes 100 CTR to caller if a sufficient
    /// balance is available in the contract.
    function mint() external payable note {
        uint256 _cost = cost();
        if (msg.value != _cost) {
            revert WrongPayment(msg.value, _cost);
        }

        // Increment token ID.
        coins.hit();
        uint256 id = coins.see();

        // Build and initialize a counter associated with this token.
        DSSLike _count = DSSLike(dss.build(bytes32(id), address(0)));
        _count.bless();
        _count.use();

        // Distribute 100 CTR to caller.
        _give(msg.sender, 100 * WAD);
        _safeMint(msg.sender, id);
    }

    /// @notice Increase `cost` by 10%. Distributes 10 CTR to caller
    /// if a sufficient balance is available in the contract.
    function hike() external note {
        if (price.see() < 100) {
            // Increment price counter.
            price.hit();
            _give(msg.sender, 10 * WAD);
        }
    }

    /// @notice Decrease `cost` by 10%. Distributes 10 CTR to caller
    /// if a sufficient balance is available in the contract.
    function drop() external note {
        if (price.see() > 0) {
            // Decrement price counter.
            price.dip();
            _give(msg.sender, 10 * WAD);
        }
    }

    /// @notice Get cost to `mint` a dss-token.
    /// @return Current `mint` price in wei.
    function cost() public view returns (uint256) {
        return cost(price.see());
    }

    /// @notice Get cost to `mint` a dss-token for a given value
    /// of the `price` counter.
    /// @param net Value of the `price` counter.
    /// @return `mint` price in wei.
    function cost(uint256 net) public pure returns (uint256) {
        // Calculate cost to mint based on price counter value.
        // Price increases by 10% for each counter increment, i.e.:
        //
        // cost = 0.01 ether * 1.01 ether ^ (counter value)

        return BASE_PRICE.mulWadUp(INCREASE.rpow(net, WAD));
    }

    /// @notice Increment a token's counter. Only token owner.
    /// @param tokenId dss-token ID.
    function hit(uint256 tokenId) external owns(tokenId) note {
        count(tokenId).hit();
    }

    /// @notice Decrement a token's counter. Only token owner.
    /// @param tokenId dss-token ID
    function dip(uint256 tokenId) external owns(tokenId) note {
        count(tokenId).dip();
    }

    /// @notice Withdraw ether balance from contract. Only contract owner.
    /// @param dst Destination address.
    function pull(address dst) external auth note {
        (bool ok,) = payable(dst).call{ value: address(this).balance }("");
        if (!ok) revert PullFailed();
    }

    /// @notice Change contract owner. Only contract owner.
    /// @param guy New contract owner.
    function swap(address guy) external auth note {
        owner = guy;
    }

    /// @notice Read a token's counter value.
    /// @param tokenId dss-token ID.
    function see(uint256 tokenId) external view returns (uint256) {
        return count(tokenId).see();
    }

    /// @notice Get the DSSProxy for a token's counter.
    /// @param tokenId dss-token ID.
    function count(uint256 tokenId) public view returns (DSSLike) {
        // dss.scry returns the deterministic address of a DSSProxy contract for
        // a given deployer, salt, and owner. Since we know these values, we
        // don't need to write the counter address to storage.
        return DSSLike(dss.scry(address(this), bytes32(tokenId), address(0)));
    }

    /// @notice Get the Inc for a DSSProxy address.
    /// @param guy DSSProxy address.
    function inc(address guy) public view returns (Inc memory) {
        // Get low level counter information from the Sum.
        SumLike sum = SumLike(dss.sum());
        (uint256 net, uint256 tab, uint256 tax, uint256 num, uint256 hop) =
            sum.incs(guy);
        return Inc(guy, net, tab, tax, num, hop);
    }

    /// @notice Get URI for a dss-token.
    /// @param tokenId dss-token ID.
    /// @return base64 encoded Data URI string.
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        exists(tokenId)
        returns (string memory)
    {
        return tokenJSON(tokenId).toDataURI("application/json");
    }

    /// @notice Get JSON metadata for a dss-token.
    /// @param tokenId dss-token ID.
    /// @return JSON metadata string.
    function tokenJSON(uint256 tokenId)
        public
        view
        exists(tokenId)
        returns (string memory)
    {
        Inc memory countInc = inc(address(count(tokenId)));
        return Render.json(tokenId, tokenSVG(tokenId).toDataURI("image/svg+xml"), countInc);
    }

    /// @notice Get SVG image for a dss-token.
    /// @param tokenId dss-token ID.
    /// @return SVG image string.
    function tokenSVG(uint256 tokenId)
        public
        view
        exists(tokenId)
        returns (string memory)
    {
        Inc memory countInc = inc(address(count(tokenId)));
        Inc memory priceInc = inc(address(price));
        return Render.image(tokenId, coins.see(), countInc, priceInc);
    }

    function _give(address dst, uint256 wad) internal {
        if (ctr.balanceOf(address(this)) >= wad) ctr.push(dst, wad);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// dss.sol -- Decentralized Summation System

// Copyright (C) 2022 Horsefacts <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.15;

import {DSSProxy} from "./proxy/proxy.sol";

interface DSSLike {
    function sum() external view returns(address);
    function use() external;
    function see() external view returns (uint256);
    function hit() external;
    function dip() external;
    function nil() external;
    function hope(address) external;
    function nope(address) external;
    function bless() external;
    function build(bytes32 wit, address god) external returns (address);
    function scry(address guy, bytes32 wit, address god) external view returns (address);
}

interface SumLike {
    function hope(address) external;
    function nope(address) external;
}

interface UseLike {
    function use() external;
}

interface SpyLike {
    function see() external view returns (uint256);
}

interface HitterLike {
    function hit() external;
}

interface DipperLike {
    function dip() external;
}

interface NilLike {
    function nil() external;
}

contract DSS {
    // --- Data ---
    address immutable public sum;
    address immutable public _use;
    address immutable public _spy;
    address immutable public _hitter;
    address immutable public _dipper;
    address immutable public _nil;

    // --- Init ---
    constructor(
        address sum_,
        address use_,
        address spy_,
        address hitter_,
        address dipper_,
        address nil_)
    {
        sum     = sum_;     // Core ICV engine
        _use    = use_;     // Creation module
        _spy    = spy_;     // Read module
        _hitter = hitter_;  // Increment module
        _dipper = dipper_;  // Decrement module
        _nil    = nil_;     // Reset module
    }

    // --- DSS Operations ---
    function use() external {
        UseLike(_use).use();
    }

    function see() external view returns (uint256) {
        return SpyLike(_spy).see();
    }

    function hit() external {
        HitterLike(_hitter).hit();
    }

    function dip() external {
        DipperLike(_dipper).dip();
    }

    function nil() external {
        NilLike(_nil).nil();
    }

    function hope(address usr) external {
        SumLike(sum).hope(usr);
    }

    function nope(address usr) external {
        SumLike(sum).nope(usr);
    }

    function bless() external {
        SumLike(sum).hope(_use);
        SumLike(sum).hope(_hitter);
        SumLike(sum).hope(_dipper);
        SumLike(sum).hope(_nil);
    }

    function build(bytes32 wit, address god) external returns (address proxy) {
        proxy = address(new DSSProxy{ salt: wit }(address(this), msg.sender, god));
    }

    function scry(address guy, bytes32 wit, address god) external view returns (address) {
        address me = address(this);
        return address(uint160(uint256(keccak256(
            abi.encodePacked(
                bytes1(0xff),
                me,
                wit,
                keccak256(
                    abi.encodePacked(
                        type(DSSProxy).creationCode,
                        abi.encode(me),
                        abi.encode(guy),
                        abi.encode(god)
                    )
                )
            )
        ))));
    }
}

/// note.sol -- the `note' modifier, for logging calls as events

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.4.23;

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint256           wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;
        uint256 wad;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            wad := callvalue()
        }

        _;

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

// render.sol -- DSSToken render module

// Copyright (C) 2022 Horsefacts <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.15;

import {svg} from "hot-chain-svg/SVG.sol";
import {utils} from "hot-chain-svg/Utils.sol";
import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {Inc} from "./token.sol";

library DataURI {
    function toDataURI(string memory data, string memory mimeType)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            "data:", mimeType, ";base64,", Base64.encode(abi.encodePacked(data))
        );
    }
}

library Render {
    function json(uint256 _tokenId, string memory _svg, Inc memory _count)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            '{"name": "CounterDAO',
            " #",
            utils.uint2str(_tokenId),
            '", "description": "I frobbed an inc and all I got was this lousy dss-token", "image": "',
            _svg,
            '", "attributes": ',
            attributes(_count),
            '}'
        );
    }

    function attributes(Inc memory inc) internal pure returns (string memory) {
        return string.concat(
            "[",
            attribute("net", inc.net),
            ",",
            attribute("tab", inc.tab),
            ",",
            attribute("tax", inc.tax),
            ",",
            attribute("num", inc.num),
            ",",
            attribute("hop", inc.hop),
            "]"
        );
    }

    function attribute(string memory name, uint256 value)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            '{"trait_type": "',
            name,
            '", "value": "',
            utils.uint2str(value),
            '", "display_type": "number"}'
        );
    }

    function image(
        uint256 _tokenId,
        uint256 _supply,
        Inc memory _count,
        Inc memory _price
    )
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 300" style="background:#7CC3B3;font-family:Helvetica Neue, Helvetica, Arial, sans-serif;">',
            svg.el(
                "path",
                string.concat(
                    svg.prop("id", "top"),
                    svg.prop(
                        "d",
                        "M 10 10 H 280 a10,10 0 0 1 10,10 V 280 a10,10 0 0 1 -10,10 H 20 a10,10 0 0 1 -10,-10 V 10 z"
                    ),
                    svg.prop("fill", "#7CC3B3")
                ),
                ""
            ),
            svg.el(
                "path",
                string.concat(
                    svg.prop("id", "bottom"),
                    svg.prop(
                        "d",
                        "M 290 290 H 20 a10,10 0 0 1 -10,-10 V 20 a10,10 0 0 1 10,-10 H 280 a10,10 0 0 1 10,10 V 290 z"
                    ),
                    svg.prop("fill", "#7CC3B3")
                ),
                ""
            ),
            svg.text(
                string.concat(
                    svg.prop("dominant-baseline", "middle"),
                    svg.prop("font-family", "Menlo, monospace"),
                    svg.prop("font-size", "9"),
                    svg.prop("fill", "white")
                ),
                string.concat(
                    svg.el(
                        "textPath",
                        string.concat(svg.prop("href", "#top")),
                        string.concat(
                            formatInc(_count),
                            svg.el(
                                "animate",
                                string.concat(
                                    svg.prop("attributeName", "startOffset"),
                                    svg.prop("from", "0%"),
                                    svg.prop("to", "100%"),
                                    svg.prop("dur", "120s"),
                                    svg.prop("begin", "0s"),
                                    svg.prop("repeatCount", "indefinite")
                                ),
                                ""
                            )
                        )
                    )
                )
            ),
            svg.text(
                string.concat(
                    svg.prop("x", "50%"),
                    svg.prop("y", "45%"),
                    svg.prop("text-anchor", "middle"),
                    svg.prop("dominant-baseline", "middle"),
                    svg.prop("font-size", "150"),
                    svg.prop("font-weight", "bold"),
                    svg.prop("fill", "white")
                ),
                string.concat(svg.cdata("++"))
            ),
            svg.text(
                string.concat(
                    svg.prop("x", "50%"),
                    svg.prop("y", "70%"),
                    svg.prop("text-anchor", "middle"),
                    svg.prop("font-size", "20"),
                    svg.prop("fill", "white")
                ),
                string.concat(utils.uint2str(_tokenId), " / ", utils.uint2str(_supply))
            ),
            svg.text(
                string.concat(
                    svg.prop("x", "50%"),
                    svg.prop("y", "80%"),
                    svg.prop("text-anchor", "middle"),
                    svg.prop("font-size", "20"),
                    svg.prop("fill", "white")
                ),
                utils.uint2str(_count.net)
            ),
            svg.text(
                string.concat(
                    svg.prop("dominant-baseline", "middle"),
                    svg.prop("font-family", "Menlo, monospace"),
                    svg.prop("font-size", "9"),
                    svg.prop("fill", "white")
                ),
                string.concat(
                    svg.el(
                        "textPath",
                        string.concat(svg.prop("href", "#bottom")),
                        string.concat(
                            formatInc(_price),
                            svg.el(
                                "animate",
                                string.concat(
                                    svg.prop("attributeName", "startOffset"),
                                    svg.prop("from", "0%"),
                                    svg.prop("to", "100%"),
                                    svg.prop("dur", "120s"),
                                    svg.prop("begin", "0s"),
                                    svg.prop("repeatCount", "indefinite")
                                ),
                                ""
                            )
                        )
                    )
                )
            ),
            "</svg>"
        );
    }

    function formatInc(Inc memory inc) internal pure returns (string memory) {
        return svg.cdata(
            string.concat(
                "Inc ",
                Strings.toHexString(uint160(inc.guy), 20),
                " | net: ",
                utils.uint2str(inc.net),
                " | tab: ",
                utils.uint2str(inc.tab),
                " | tax: ",
                utils.uint2str(inc.tax),
                " | num: ",
                utils.uint2str(inc.num),
                " | hop: ",
                utils.uint2str(inc.hop)
            )
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// proxy.sol -- Execute DSS actions through the proxy's identity

// Copyright (C) 2022 Horsefacts <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.15;

import {DSAuth} from "ds-auth/auth.sol";
import {DSNote} from "ds-note/note.sol";

contract DSSProxy is DSAuth, DSNote {
    // --- Data ---
    address public dss;

    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth note { wards[usr] = 1; }
    function deny(address usr) external auth note { wards[usr] = 0; }
    modifier ward {
        require(wards[msg.sender] == 1, "DSSProxy/not-authorized");
        require(msg.sender != owner, "DSSProxy/owner-not-ward");
        _;
    }

    // --- Init ---
    constructor(address dss_, address usr, address god) {
        dss = dss_;
        wards[usr] = 1;
        setOwner(god);
    }

    // --- Upgrade ---
    function upgrade(address dss_) external auth note {
        dss = dss_;
    }

    // --- Proxy ---
    fallback() external ward note {
        address _dss = dss;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _dss, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import './Utils.sol';

// Core SVG utilitiy library which helps us construct
// onchain SVG's with a simple, web-like API.
library svg {
    /* MAIN ELEMENTS */
    function g(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('g', _props, _children);
    }

    function path(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('path', _props, _children);
    }

    function text(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('text', _props, _children);
    }

    function line(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('line', _props, _children);
    }

    function circle(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('circle', _props, _children);
    }

    function circle(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('circle', _props);
    }

    function rect(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('rect', _props, _children);
    }

    function rect(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('rect', _props);
    }

    function filter(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('filter', _props, _children);
    }

    function cdata(string memory _content)
        internal
        pure
        returns (string memory)
    {
        return string.concat('<![CDATA[', _content, ']]>');
    }

    /* GRADIENTS */
    function radialGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('radialGradient', _props, _children);
    }

    function linearGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('linearGradient', _props, _children);
    }

    function gradientStop(
        uint256 offset,
        string memory stopColor,
        string memory _props
    ) internal pure returns (string memory) {
        return
            el(
                'stop',
                string.concat(
                    prop('stop-color', stopColor),
                    ' ',
                    prop('offset', string.concat(utils.uint2str(offset), '%')),
                    ' ',
                    _props
                )
            );
    }

    function animateTransform(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('animateTransform', _props);
    }

    function image(string memory _href, string memory _props)
        internal
        pure
        returns (string memory)
    {
        return
            el(
                'image',
                string.concat(prop('href', _href), ' ', _props)
            );
    }

    /* COMMON */
    // A generic element, can be used to construct any SVG (or HTML) element
    function el(
        string memory _tag,
        string memory _props,
        string memory _children
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<',
                _tag,
                ' ',
                _props,
                '>',
                _children,
                '</',
                _tag,
                '>'
            );
    }

    // A generic element, can be used to construct any SVG (or HTML) element without children
    function el(
        string memory _tag,
        string memory _props
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<',
                _tag,
                ' ',
                _props,
                '/>'
            );
    }

    // an SVG attribute
    function prop(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_key, '=', '"', _val, '" ');
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Core utils used extensively to format CSS and numbers.
library utils {
    // used to simulate empty strings
    string internal constant NULL = '';

    // formats a CSS variable line. includes a semicolon for formatting.
    function setCssVar(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat('--', _key, ':', _val, ';');
    }

    // formats getting a css variable
    function getCssVar(string memory _key)
        internal
        pure
        returns (string memory)
    {
        return string.concat('var(--', _key, ')');
    }

    // formats getting a def URL
    function getDefURL(string memory _id)
        internal
        pure
        returns (string memory)
    {
        return string.concat('url(#', _id, ')');
    }

    // formats rgba white with a specified opacity / alpha
    function white_a(uint256 _a) internal pure returns (string memory) {
        return rgba(255, 255, 255, _a);
    }

    // formats rgba black with a specified opacity / alpha
    function black_a(uint256 _a) internal pure returns (string memory) {
        return rgba(0, 0, 0, _a);
    }

    // formats generic rgba color in css
    function rgba(
        uint256 _r,
        uint256 _g,
        uint256 _b,
        uint256 _a
    ) internal pure returns (string memory) {
        string memory formattedA = _a < 100
            ? string.concat('0.', utils.uint2str(_a))
            : '1';
        return
            string.concat(
                'rgba(',
                utils.uint2str(_r),
                ',',
                utils.uint2str(_g),
                ',',
                utils.uint2str(_b),
                ',',
                formattedA,
                ')'
            );
    }

    // checks if two strings are equal
    function stringsEqual(string memory _a, string memory _b)
        internal
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    // returns the length of a string in characters
    function utfStringLength(string memory _str)
        internal
        pure
        returns (uint256 length)
    {
        uint256 i = 0;
        bytes memory string_rep = bytes(_str);

        while (i < string_rep.length) {
            if (string_rep[i] >> 7 == 0) i += 1;
            else if (string_rep[i] >> 5 == bytes1(uint8(0x6))) i += 2;
            else if (string_rep[i] >> 4 == bytes1(uint8(0xE))) i += 3;
            else if (string_rep[i] >> 3 == bytes1(uint8(0x1E)))
                i += 4;
                //For safety
            else i += 1;

            length++;
        }
    }

    // converts an unsigned integer to a string
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return '0';
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: GNU-3
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.4.23;

interface DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) external view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(address(0))) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}