//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IVat {
    function ilks(address) external view returns (uint, uint, uint, uint, uint);
    function urns(address, address) external view returns (uint, uint, uint);
    function USB(address) external view returns (uint);

    function par() external view returns (uint256);
    function liquidationRatio(address) external view returns (address, uint256);
    function priceOracle() external view returns (address);
    function getPrice(address) external view returns(uint);

    function can(address, address) external view returns (uint);

    function hope(address usr) external;
    function nope(address usr) external;

    // --- Administration ---
    function init(address ilk) external;
    function setNewLine(uint data) external;
    function setParamsPerIlk(address ilk, bytes32 what, uint data) external;
    function cage() external;
    
    // --- Fungibility ---
    function slip(address ilk, address usr, int256 wad) external;
    function flux(address ilk, address src, address dst, uint256 wad) external;
    function move(address src, address dst, uint256 rad) external;

    // --- CDP Manipulation ---
    function frob(address i, address u, address v, address w, int dink, int dart) external;
    function addDebt(address i, address u, uint wad) external;
    function subDebt(address i, address u, uint wad) external;

    // --- CDP Fungibility ---
    function fork(address ilk, address src, address dst, int dink, int dart) external;

    // --- CDP Confiscation ---
    function grab(address i, address u, address v, address w, int dink, int dart) external;

    // --- Settlement ---
    function heal(uint rad) external;
    function suck(address u, address v, uint rad) external;

    // --- Rates ---
    function fold(address i, address u, int rate) external;

    function sin (address) external view returns (uint);
     
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IUSB {
    function mint(address,uint) external;
    function burn(address,uint) external;
    function approve(address, uint) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;

    
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IUSBJoin {
    function vat() external returns (address);
    function USB() external returns (address);
    function join(address , address, uint) external payable;
    function exit(address, address , uint) external;
    function wipe(address, address , uint, uint) external;
    function joinSaving(address, uint) external;
    function exitSaving(address, uint) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IPot {
    function pie(address) external view returns (uint);
    function balance(address) external view returns (uint);
    function join(uint, uint, uint) external;
    function exit(uint, uint, uint) external;

    function vat() external view returns (address);
    function chi() external view returns (uint256);
    function rho() external view returns (uint256);
    function drip() external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.0;
import "../interfaces/ICore/IVat.sol";
import "../interfaces/IGem/IUSBJoin.sol";
import "../interfaces/IGem/IUSB.sol";
import "../interfaces/IRate/IPot.sol";
import "./../utils/Math.sol";

contract DssProxyActionsDsr {
    using Math for uint;
    uint256 constant RAY = 10 ** 27;

    // Internal functions

    function USBJoin_join(address apt, address urn, uint wad) internal {
        address USB = IUSBJoin(apt).USB();
        // Gets USB from the user's wallet
        IUSB(USB).transferFrom(msg.sender, address(this), wad);
        // Approves adapter to take the USB amount
        IUSB(USB).approve(apt, wad);
        // Joins USB into the vat
        IUSBJoin(apt).joinSaving(urn, wad);
    }

    function join(
        address USBJoin,
        address pot,
        uint wad
    ) public {
        address vat = IUSBJoin(USBJoin).vat();
        // Executes drip to get the chi rate updated to rho == now, otherwise join will fail
        uint chi = IPot(pot).drip();
        // Joins wad amount to the vat balance
        USBJoin_join(USBJoin, address(this), wad);
        // Approves the pot to take out USB from the proxy's balance in the vat
        if (IVat(vat).can(address(this), address(pot)) == 0) {
            IVat(vat).hope(pot);
        }
        // Joins the pie value (equivalent to the USB wad amount) in the pot
        IPot(pot).join(wad.mul(RAY) / chi, wad, chi);
    }

    function exit(
        address USBJoin,
        address pot,
        uint wad
    ) public {
        address vat = IUSBJoin(USBJoin).vat();
        // Executes drip to count the savings accumulated until this moment
        uint chi = IPot(pot).drip();
        // Calculates the pie value in the pot equivalent to the USB wad amount
        uint pie = wad.mul(RAY) / chi;
        // Exits USB from the pot
        IPot(pot).exit(pie, wad, chi);
        // Checks the actual balance of USB in the vat after the pot exit
        uint bal = IVat(vat).USB(address(this));
        // Allows adapter to access to proxy's USB balance in the vat
        if (IVat(vat).can(address(this), address(USBJoin)) == 0) {
            IVat(vat).hope(USBJoin);
        }
        // It is necessary to check if due rounding the exact wad amount can be exited by the adapter.
        // Otherwise it will do the maximum USB balance in the vat
        IUSBJoin(USBJoin).exitSaving(
            msg.sender,
            bal >= wad.mul(RAY) ? wad : bal / RAY
        );
    }

    function exitAll(
        address USBJoin,
        address pot
    ) public {
        address vat = IUSBJoin(USBJoin).vat();
        // Executes drip to count the savings accumulated until this moment
        uint chi = IPot(pot).drip();
        uint balanceDeposit = IPot(pot).balance(address(this));
        // Gets the total pie belonging to the proxy address
        uint pie = IPot(pot).pie(address(this));
        // Exits USB from the pot
        IPot(pot).exit(pie, balanceDeposit, chi);
        // Allows adapter to access to proxy's USB balance in the vat
        if (IVat(vat).can(address(this), address(USBJoin)) == 0) {
            IVat(vat).hope(USBJoin);
        }
        // Exits the USB amount corresponding to the value of pie
        IUSBJoin(USBJoin).exitSaving(msg.sender, chi.mul(pie) / RAY);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Math {
    uint256 constant RAY = 10 ** 27;
    uint256 constant BLN = 10 **  9;
    uint256 constant WAD = 10 ** 18;

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "mul-overflow");
    }

    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, RAY) / y;
    }

    function add(uint x, int y) internal pure returns (uint z) {
        if (y < 0){
            z = x - uint(-y);
        } else{
            z = x + uint(y);
        }  
        require(y >= 0 || z <= x);
        require(y <= 0 || z >= x);
    }

    function sub(uint x, int y) internal pure returns (uint z) {
        if (y < 0){
            z = x + uint(-y);
        } else{
            z = x - uint(y);
        }          
        require(y <= 0 || z <= x, "sub-overflow");
        require(y >= 0 || z >= x, "sub-overflow");
    }
    function mul(uint x, int y) internal pure returns (int z) {
        z = int(x) * y;
        require(int(x) >= 0);
        require(y == 0 || z / y == int(x));
    }
    function add(uint x, uint y) internal pure returns (uint z) {
        z = x + y;
        require(z >= x);
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-overflow");
    }

        // --- Math ---

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x <= y ? x : y;
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, y) / WAD;
    }
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, y) / RAY;
    }

    function diff(uint x, uint y) internal pure returns (int z) {
        z = int(x) - int(y);
        require(int(x) >= 0 && int(y) >= 0);
    }

    // optimized version from dss PR #78
    function rpow(uint256 x, uint256 n, uint256 b) internal pure returns (uint256 z) {
        assembly {
            switch n case 0 { z := b }
            default {
                switch x case 0 { z := 0 }
                default {
                    switch mod(n, 2) case 0 { z := b } default { z := x }
                    let half := div(b, 2)  // for rounding.
                    for { n := div(n, 2) } n { n := div(n,2) } {
                        let xx := mul(x, x)
                        if shr(128, x) { revert(0,0) }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) { revert(0,0) }
                        x := div(xxRound, b)
                        if mod(n,2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) { revert(0,0) }
                            z := div(zxRound, b)
                        }
                    }
                }
            }
        }
    }

    function toInt(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0, "int-overflow");
    }

    function toRad(uint wad) internal pure returns (uint rad) {
        rad = mul(wad, RAY);
    }

}