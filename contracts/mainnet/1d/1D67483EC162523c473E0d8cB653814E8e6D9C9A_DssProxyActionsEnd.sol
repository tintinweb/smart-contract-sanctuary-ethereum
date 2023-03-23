/**
 *Submitted for verification at Etherscan.io on 2023-03-22
*/

/**
 *Submitted for verification at Etherscan.io on 2020-04-14
*/

pragma solidity ^0.5.12;

contract GemLike {
    function approve(address, uint) public;
    function transfer(address, uint) public;
    function transferFrom(address, address, uint) public;
    function deposit() public payable;
    function withdraw(uint) public;
}

contract ManagerLike {
    function cdpCan(address, uint, address) public view returns (uint);
    function ilks(uint) public view returns (bytes32);
    function owns(uint) public view returns (address);
    function urns(uint) public view returns (address);
    function vat() public view returns (address);
    function open(bytes32, address) public returns (uint);
    function give(uint, address) public;
    function cdpAllow(uint, address, uint) public;
    function urnAllow(address, uint) public;
    function frob(uint, int, int) public;
    function flux(uint, address, uint) public;
    function move(uint, address, uint) public;
    function exit(address, uint, address, uint) public;
    function quit(uint, address) public;
    function enter(address, uint) public;
    function shift(uint, uint) public;
}

contract VatLike {
    function can(address, address) public view returns (uint);
    function ilks(bytes32) public view returns (uint, uint, uint, uint, uint);
    function dai(address) public view returns (uint);
    function urns(bytes32, address) public view returns (uint, uint);
    function frob(bytes32, address, address, address, int, int) public;
    function hope(address) public;
    function move(address, address, uint) public;
}

contract GemJoinLike {
    function dec() public returns (uint);
    function gem() public returns (GemLike);
    function join(address, uint) public payable;
    function exit(address, uint) public;
}

contract GNTJoinLike {
    function bags(address) public view returns (address);
    function make(address) public returns (address);
}

contract DaiJoinLike {
    function vat() public returns (VatLike);
    function dai() public returns (GemLike);
    function join(address, uint) public payable;
    function exit(address, uint) public;
}

contract HopeLike {
    function hope(address) public;
    function nope(address) public;
}

contract EndLike {
    function fix(bytes32) public view returns (uint);
    function cash(bytes32, uint) public;
    function free(bytes32) public;
    function pack(uint) public;
    function skim(bytes32, address) public;
}

contract JugLike {
    function drip(bytes32) public returns (uint);
}

contract PotLike {
    function pie(address) public view returns (uint);
    function drip() public returns (uint);
    function join(uint) public;
    function exit(uint) public;
}

contract ProxyRegistryLike {
    function proxies(address) public view returns (address);
    function build(address) public returns (address);
}

contract ProxyLike {
    function owner() public view returns (address);
}

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a DSProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

contract Common {
    uint256 constant RAY = 10 ** 27;

    // Internal functions

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "mul-overflow");
    }

    // Public functions

    function daiJoin_join(address apt, address urn, uint wad) public {
        // Gets DAI from the user's wallet
        DaiJoinLike(apt).dai().transferFrom(msg.sender, address(this), wad);
        // Approves adapter to take the DAI amount
        DaiJoinLike(apt).dai().approve(apt, wad);
        // Joins DAI into the vat
        DaiJoinLike(apt).join(urn, wad);
    }
}

contract DssProxyActionsEnd is Common {
    // Internal functions

    function _free(
        address manager,
        address end,
        uint cdp
    ) internal returns (uint ink) {
        bytes32 ilk = ManagerLike(manager).ilks(cdp);
        address urn = ManagerLike(manager).urns(cdp);
        VatLike vat = VatLike(ManagerLike(manager).vat());
        uint art;
        (ink, art) = vat.urns(ilk, urn);

        // If CDP still has debt, it needs to be paid
        if (art > 0) {
            EndLike(end).skim(ilk, urn);
            (ink,) = vat.urns(ilk, urn);
        }
        // Approves the manager to transfer the position to proxy's address in the vat
        if (vat.can(address(this), address(manager)) == 0) {
            vat.hope(manager);
        }
        // Transfers position from CDP to the proxy address
        ManagerLike(manager).quit(cdp, address(this));
        // Frees the position and recovers the collateral in the vat registry
        EndLike(end).free(ilk);
    }

    // Public functions
    function freeETH(
        address manager,
        address ethJoin,
        address end,
        uint cdp
    ) public {
        uint wad = _free(manager, end, cdp);
        // Exits WETH amount to proxy address as a token
        GemJoinLike(ethJoin).exit(address(this), wad);
        // Converts WETH to ETH
        GemJoinLike(ethJoin).gem().withdraw(wad);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(wad);
    }

    function freeGem(
        address manager,
        address gemJoin,
        address end,
        uint cdp
    ) public {
        uint amt = _free(manager, end, cdp) / 10 ** (18 - GemJoinLike(gemJoin).dec());
        // Exits token amount to the user's wallet as a token
        GemJoinLike(gemJoin).exit(msg.sender, amt);
    }

    function pack(
        address daiJoin,
        address end,
        uint wad
    ) public {
        daiJoin_join(daiJoin, address(this), wad);
        VatLike vat = DaiJoinLike(daiJoin).vat();
        // Approves the end to take out DAI from the proxy's balance in the vat
        if (vat.can(address(this), address(end)) == 0) {
            vat.hope(end);
        }
        EndLike(end).pack(wad);
    }

    function cashETH(
        address ethJoin,
        address end,
        bytes32 ilk,
        uint wad
    ) public {
        EndLike(end).cash(ilk, wad);
        uint wadC = mul(wad, EndLike(end).fix(ilk)) / RAY;
        // Exits WETH amount to proxy address as a token
        GemJoinLike(ethJoin).exit(address(this), wadC);
        // Converts WETH to ETH
        GemJoinLike(ethJoin).gem().withdraw(wadC);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(wadC);
    }

    function cashGem(
        address gemJoin,
        address end,
        bytes32 ilk,
        uint wad
    ) public {
        EndLike(end).cash(ilk, wad);
        // Exits token amount to the user's wallet as a token
        uint amt = mul(wad, EndLike(end).fix(ilk)) / RAY / 10 ** (18 - GemJoinLike(gemJoin).dec());
        GemJoinLike(gemJoin).exit(msg.sender, amt);
    }
}