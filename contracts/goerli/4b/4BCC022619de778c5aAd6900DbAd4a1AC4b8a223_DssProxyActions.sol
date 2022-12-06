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
pragma solidity >= 0.8.0;

interface IEnd {
    function fix(address) external view returns (uint);
    function cash(address, uint) external;
    function free(address) external;
    function pack(uint) external;
    function skim(address, address) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IGem {
    function mint(address,uint) external;
    function burn(address,uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IGemJoin {
    function vat() external returns (address);
    function dec() external returns (uint);
    function gem() external returns (address);
    function join(address, uint) external payable;
    function exit(address, uint) external;
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

interface IGNTJoin {
    function hope(address) external;
    function nope(address) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IHope {
    function hope(address) external;
    function nope(address) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IDssCdpManager {
    struct List {
        uint prev;
        uint next;
    }
    function cdpCan(address, uint, address) external view returns (uint);
    function ilks(uint) external view returns (address);
    function owns(uint) external view returns (address);
    function urns(uint) external view returns (address);
    function vat() external view returns (address);
    function open(address, address) external returns (uint);
    function give(uint, address) external;
    function cdpAllow(uint, address, uint) external;
    function urnAllow(address, uint) external;
    function frob(uint, int, int) external;
    function flux(uint, address, uint) external;
    function move(uint, address, uint) external;
    function exit(address, uint, address, uint) external;
    function quit(uint, address) external;
    function enter(address, uint) external;
    function shift(uint, uint) external;
    function count(address) external view returns (uint);
    function first(address) external view returns (uint);
    function list(uint) external view returns (List memory);
     
}

//SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IProxy {
    function owner() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IJug {
    function drip(address) external returns (uint);
    function getFeeBorrow(address) external returns (uint);
    function treasury() external returns (address);
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
import "../interfaces/IGem/IGem.sol";
import "../interfaces/IGem/IUSB.sol";
import "../interfaces/IGem/IGemJoin.sol";
import "../interfaces/IProxy/IDssCdpManager.sol";
import "../interfaces/IProxy/IProxy.sol";
import "../interfaces/IRate/IJug.sol";
import "../interfaces/IRate/IPot.sol";
import "../interfaces/IHope.sol";
import "../interfaces/IGNTJoin.sol";
import "../interfaces/IEmergencyShutdown/IEnd.sol";
import "./../utils/Math.sol";

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a DSProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

contract DssProxyActions {
    using Math for uint;
    uint256 constant RAY = 10 ** 27;
    uint constant decimal = 10000;
    //events
    event Deposit(address user, uint vault, uint amount);
    event Withdraw(address user, uint vault, uint amount);
    event Repay(address user, uint vault, uint amount, uint feeBorrow);
    event Borrow(address user, uint vault, uint amount);

    modifier onlyVaultOwner (address manager, uint cdp) {
        require(IDssCdpManager(manager).owns(cdp) == address(this) && msg.sender == IProxy(address(this)).owner(), "owner-missmatch");
        _;
    }

    function USBJoin_join(address ilk, address apt, address urn, uint wad) internal {
        // Gets USB from the user's wallet
        IUSB(IUSBJoin(apt).USB()).transferFrom(msg.sender, address(this), wad);
        // Approves adapter to take the USB amount
        IUSB(IUSBJoin(apt).USB()).approve(apt, wad);
        // Joins USB into the vat
        IUSBJoin(apt).join(ilk, urn, wad);
    }

    function USBJoin_join_wipe(address ilk, address apt, address urn, uint wad, uint actualWad) internal {
        // Gets USB from the user's wallet
        IUSB(IUSBJoin(apt).USB()).transferFrom(msg.sender, address(this), actualWad);
        // Approves adapter to take the USB amount
        IUSB(IUSBJoin(apt).USB()).approve(apt, actualWad);
        // Joins USB into the vat
        IUSBJoin(apt).wipe(ilk, urn, wad, actualWad);
    }

    function convertTo18(address gemJoin, uint256 amt) internal returns (uint256 wad) {
        // For those collaterals that have less than 18 decimals precision we need to do the conversion before passing to frob function
        // Adapters will automatically handle the difference of precision
        wad = amt.mul(10 ** (18 - IGemJoin(gemJoin).dec()));
    }


    function _getDrawDart(
        address vat,
        address jug,
        address urn,
        address ilk,
        uint wad
    ) internal returns (int dart) {
        // Updates stability fee rate
        uint rate = IJug(jug).drip(ilk);

        // Gets USB balance of the urn in the vat
        uint USB = IVat(vat).USB(urn);

        // If there was already enough USB in the vat balance, just exits it without adding more debt
        uint wadRay = wad.mul(RAY);
        if (USB < wadRay) {
            // Calculates the needed dart so together with the existing USB in the vat is enough to exit wad amount of USB tokens
            dart = (wadRay.sub(USB) / rate).toInt();
            // This is neeeded due lack of precision. It might need to sum an extra dart wei (for the given USB wad amount)
            dart = uint(dart).mul(rate) < wad.mul(RAY) ? dart + 1 : dart;
        }
    }

    function _getWipeDart(
        Info memory info,
        uint USB
    ) internal view returns (int dart) {
        // Gets actual rate from the vat
        (, uint rate,,,) = IVat(info.vat).ilks(info.ilk);
        // Gets actual art value of the urn
        (, uint art,) = IVat(info.vat).urns(info.ilk, info.urn);

        // Uses the whole USB balance in the vat to reduce the debt
        dart = (USB / rate).toInt();
        // Checks the calculated dart is not higher than urn.art (total debt), otherwise uses its value
        dart = uint(dart) <= art ? - dart : - art.toInt();
    }

    function _getWipeAllWad(
        address vat,
        address usr,
        address urn,
        address ilk
    ) public view returns (uint wad) {
        // Gets actual rate from the vat
        (, uint rate,,,) = IVat(vat).ilks(ilk);
        // Gets actual art value of the urn
        (, uint art,) = IVat(vat).urns(ilk, urn);
        // Gets actual USB amount in the urn
        uint USB = IVat(vat).USB(usr);

        uint rad = art.mul(rate).sub(USB);
        wad = rad / RAY;

        // If the rad precision has some dust, it will need to request for 1 extra wad wei
        wad = wad.mul(RAY) < rad ? wad + 1 : wad;
    }

    // Public functions

    function transfer(address gem, address dst, uint amt) public {
        IGem(gem).transfer(dst, amt);
    }

    function ethJoin_join(address apt, address urn) public payable {
        address weth = IGemJoin(apt).gem();
        // Wraps ETH in WETH
        IGem(weth).deposit{value:(msg.value)}();
        // Approves adapter to take the WETH amount
        IGem(weth).approve(address(apt), msg.value);
        // Joins WETH collateral into the vat
        IGemJoin(apt).join(urn, msg.value);
    }

    function gemJoin_join(address apt, address urn, uint amt, bool transferFrom) public {
        address gem = IGemJoin(apt).gem();
        // Only executes for tokens that have approval/transferFrom implementation
        if (transferFrom) {
            // Gets token from the user's wallet
            IGem(gem).transferFrom(msg.sender, address(this), amt);
            // Approves adapter to take the token amount
            IGem(gem).approve(apt, amt);
        }
        // Joins token collateral into the vat
        IGemJoin(apt).join(urn, amt);        
    }

    function hope(
        address obj,
        address usr
    ) public {
        IHope(obj).hope(usr);
    }

    function nope(
        address obj,
        address usr
    ) public {
        IHope(obj).nope(usr);
    }

    function open(
        address manager,
        address ilk,
        address usr
    ) public returns (uint cdp) {
        cdp = IDssCdpManager(manager).open(ilk, usr);
    }

    // function give(
    //     address manager,
    //     uint cdp,
    //     address usr
    // ) public {
    //     IDssCdpManager(manager).give(cdp, usr);
    // }

    // function giveToProxy(
    //     address proxyRegistry,
    //     address manager,
    //     uint cdp,
    //     address dst
    // ) public {
    //     // Gets actual proxy address
    //     address proxy = ProxyRegistryLike(proxyRegistry).proxies(dst);
    //     // Checks if the proxy address already existed and dst address is still the owner
    //     if (proxy == address(0) || ProxyLike(proxy).owner() != dst) {
    //         uint csize;
    //         assembly {
    //             csize := extcodesize(dst)
    //         }
    //         // We want to avoid creating a proxy for a contract address that might not be able to handle proxies, then losing the CDP
    //         require(csize == 0, "Dst-is-a-contract");
    //         // Creates the proxy for the dst address
    //         proxy = ProxyRegistryLike(proxyRegistry).build(dst);
    //     }
    //     // Transfers CDP to the dst proxy
    //     give(manager, cdp, proxy);
    // }

    function cdpAllow(
        address manager,
        uint cdp,
        address usr,
        uint ok
    ) public {
        IDssCdpManager(manager).cdpAllow(cdp, usr, ok);
    }

    function urnAllow(
        address manager,
        address usr,
        uint ok
    ) public {
        IDssCdpManager(manager).urnAllow(usr, ok);
    }

    function flux(
        address manager,
        uint cdp,
        address dst,
        uint wad
    ) public {
        IDssCdpManager(manager).flux(cdp, dst, wad);
    }

    function move(
        address manager,
        uint cdp,
        address dst,
        uint rad
    ) public {
        IDssCdpManager(manager).move(cdp, dst, rad);
    }

    function frob(
        address manager,
        uint cdp,
        int dink,
        int dart
    ) public {
        IDssCdpManager(manager).frob(cdp, dink, dart);
    }

    function quit(
        address manager,
        uint cdp,
        address dst
    ) public {
        IDssCdpManager(manager).quit(cdp, dst);
    }

    // function enter(
    //     address manager,
    //     address src,
    //     uint cdp
    // ) public {
    //     IDssCdpManager(manager).enter(src, cdp);
    // }

    // function shift(
    //     address manager,
    //     uint cdpSrc,
    //     uint cdpOrg
    // ) public {
    //     IDssCdpManager(manager).shift(cdpSrc, cdpOrg);
    // }

    // function makeGemBag(
    //     address gemJoin
    // ) public returns (address bag) {
    //     bag = GNTJoinLike(gemJoin).make(address(this));
    // }

    function lockETH(
        address manager,
        address ethJoin,
        uint cdp
    ) public payable onlyVaultOwner(manager, cdp) {
        // Receives ETH amount, converts it to WETH and joins it into the vat
        ethJoin_join(ethJoin, address(this));
        // Locks WETH amount into the CDP
        IVat(IDssCdpManager(manager).vat()).frob(
            IDssCdpManager(manager).ilks(cdp),
            IDssCdpManager(manager).urns(cdp),
            address(this),
            address(this),
            msg.value.toInt(),
            0
        );
        emit Deposit(msg.sender, cdp, msg.value);
    }

    function lockGem(
        address manager,
        address gemJoin,
        uint cdp,
        uint amt,
        bool transferFrom
    ) public onlyVaultOwner(manager, cdp) {
        // Takes token amount from user's wallet and joins into the vat
        gemJoin_join(gemJoin, address(this), amt, transferFrom);
        // Locks token amount into the CDP
        IVat(IDssCdpManager(manager).vat()).frob(
            IDssCdpManager(manager).ilks(cdp),
            IDssCdpManager(manager).urns(cdp),
            address(this),
            address(this),
            convertTo18(gemJoin, amt).toInt(),
            0
        );
        emit Deposit(msg.sender, cdp, amt);
    }

    function freeETH(
        address manager,
        address ethJoin,
        uint cdp,
        uint wad
    ) public {
        // Unlocks WETH amount from the CDP
        frob(manager, cdp, -wad.toInt(), 0);
        // Moves the amount from the CDP urn to proxy's address
        flux(manager, cdp, address(this), wad);
        // Exits WETH amount to proxy address as a token
        IGemJoin(ethJoin).exit(address(this), wad);
        // Converts WETH to ETH
        address weth = IGemJoin(ethJoin).gem();
        IGem(weth).withdraw(wad);
        // Sends ETH back to the user's wallet
        payable(msg.sender).transfer(wad);
        emit Withdraw(msg.sender, cdp, wad);
    }

    function freeGem(
        address manager,
        address gemJoin,
        uint cdp,
        uint amt
    ) public {
        uint wad = convertTo18(gemJoin, amt);
        // Unlocks token amount from the CDP
        frob(manager, cdp, -wad.toInt(), 0);
        // Moves the amount from the CDP urn to proxy's address
        flux(manager, cdp, address(this), wad);
        // Exits token amount to the user's wallet as a token
        IGemJoin(gemJoin).exit(msg.sender, wad);

        emit Withdraw(msg.sender, cdp, amt);
    }

    function exitETH(
        address manager,
        address ethJoin,
        uint cdp,
        uint wad
    ) public {
        // Moves the amount from the CDP urn to proxy's address
        flux(manager, cdp, address(this), wad);

        // Exits WETH amount to proxy address as a token
        IGemJoin(ethJoin).exit(address(this), wad);
        // Converts WETH to ETH
        address weth = IGemJoin(ethJoin).gem();
        IGem(weth).withdraw(wad);
        // Sends ETH back to the user's wallet
        payable(msg.sender).transfer(wad);
    }

    function exitGem(
        address manager,
        address gemJoin,
        uint cdp,
        uint amt
    ) public {
        // Moves the amount from the CDP urn to proxy's address
        flux(manager, cdp, address(this), convertTo18(gemJoin, amt));

        // Exits token amount to the user's wallet as a token
        IGemJoin(gemJoin).exit(msg.sender, amt);
    }

    function draw(
        address manager,
        address jug,
        address USBJoin,
        uint cdp,
        uint wad
    ) public {
        address urn = IDssCdpManager(manager).urns(cdp);
        address vat = IDssCdpManager(manager).vat();
        address ilk = IDssCdpManager(manager).ilks(cdp);
        // Generates debt in the CDP
        frob(manager, cdp, 0, _getDrawDart(vat, jug, urn, ilk, wad));
        // Moves the USB amount (balance in the vat in rad) to proxy's address
        move(manager, cdp, address(this), wad.toRad());
        // Allows adapter to access to proxy's USB balance in the vat
        if (IVat(vat).can(address(this), address(USBJoin)) == 0) {
            IVat(vat).hope(USBJoin);
        }
        // Exits USB to the user's wallet as a token
        IUSBJoin(USBJoin).exit(ilk, msg.sender, wad);
        IVat(vat).addDebt(ilk, urn, wad);
    
        emit Borrow(msg.sender, cdp, wad);
    }

    struct Info {
        address vat;
        address urn;
        address ilk;
    }
    function getInfo(address manager, uint cdp) internal view returns (Info memory info) {
        info.vat = IDssCdpManager(manager).vat();
        info.urn = IDssCdpManager(manager).urns(cdp);
        info.ilk = IDssCdpManager(manager).ilks(cdp);
    }

    function getDebtIssued(uint art , uint debt, uint rate) public pure returns(uint totalDebtIssued, uint accuralFee) {
        totalDebtIssued = art * rate / RAY;
        accuralFee = totalDebtIssued > debt  ? totalDebtIssued - debt : 0;
    }

    function chargeFeeTreasury(Info memory info, address jug, uint repayAmount, address USBJoin) internal returns (uint feeTreasury) {
        (,uint art , uint debt) = IVat(info.vat).urns(info.ilk, info.urn);
        // Gets actual rate from the vat
        (, uint rate,,,) = IVat(info.vat).ilks(info.ilk);
        uint fee = IJug(jug).getFeeBorrow(info.ilk);
        (, uint accuralFee) = getDebtIssued(art, debt, rate);
        if(accuralFee > 0) {
            feeTreasury = repayAmount >= accuralFee ? accuralFee * fee / decimal : repayAmount * fee / decimal;
            if(feeTreasury > 0) {
                address treasury = IJug(jug).treasury();
                address usb = IUSBJoin(USBJoin).USB();
                IUSB(usb).transferFrom(msg.sender, treasury, feeTreasury);
            }
        }
    }

    function calcDebt(Info memory info, uint art , uint debt, uint wad) internal {
        // Gets actual rate from the vat
        (, uint rate,,,) = IVat(info.vat).ilks(info.ilk);
        (, uint accuralFee) = getDebtIssued(art, debt, rate);
        uint wadDebt;
        if(accuralFee > 0) {
            wadDebt = accuralFee >= wad ? 0 : wad - accuralFee;
        } else {
            wadDebt = wad;
        }
        if(wadDebt >= debt) {
            wadDebt = debt;
        }
        IVat(info.vat).subDebt(info.ilk, info.urn, wadDebt);
    }

    function wipeInternal(address own, address manager, address USBJoin, uint cdp, Info memory info, uint wad, uint feeTreasury) internal {
        if (own == address(this) || IDssCdpManager(manager).cdpCan(own, cdp, address(this)) == 1) {
            // Joins USB amount into the vat
            USBJoin_join_wipe(info.ilk, USBJoin, info.urn, wad, wad - feeTreasury);
            // Paybacks debt to the CDP
            frob(manager, cdp, 0, _getWipeDart(info, IVat(info.vat).USB(info.urn)));
        } else {
            // Joins USB amount into the vat
            USBJoin_join_wipe(info.ilk, USBJoin, address(this), wad, wad - feeTreasury);
            // Paybacks debt to the CDP
            IVat(info.vat).frob(
                info.ilk,
                info.urn,
                address(this),
                address(this),
                0,
                _getWipeDart(info, wad * RAY)
            );
        }
    }

    function wipe(
        address manager,
        address USBJoin,
        address jug,
        uint cdp,
        uint wad
    ) public onlyVaultOwner(manager, cdp) {
        Info memory info = getInfo(manager, cdp);
        (, uint art, uint debt) = IVat(info.vat).urns(info.ilk, info.urn);
        address own = IDssCdpManager(manager).owns(cdp);
        uint feeTreasury = chargeFeeTreasury (info, jug, wad, USBJoin);
        wipeInternal(own, manager, USBJoin, cdp, info, wad, feeTreasury);
        calcDebt(info, art, debt, wad);

        emit Repay(msg.sender, cdp, wad, feeTreasury);
    }

    function wipeAll(
        address manager,
        address USBJoin,
        address jug,
        uint cdp
    ) public onlyVaultOwner(manager, cdp) {
        Info memory info = getInfo(manager, cdp);
        (, uint art, uint debt) = IVat(info.vat).urns(info.ilk, info.urn);
        address own = IDssCdpManager(manager).owns(cdp);
        uint feeTreasury;
        uint amount;
        if (own == address(this) || IDssCdpManager(manager).cdpCan(own, cdp, address(this)) == 1) {
            // Joins USB amount into the vat
            amount = _getWipeAllWad(info.vat, info.urn, info.urn, info.ilk);
            feeTreasury = chargeFeeTreasury (info, jug, amount, USBJoin);
            USBJoin_join_wipe(info.ilk, USBJoin, info.urn, amount, amount - feeTreasury);
            // Paybacks debt to the CDP
            frob(manager, cdp, 0, -int(art));
        } else {
            // Joins USB amount into the vat
            amount = _getWipeAllWad(info.vat, address(this), info.urn, info.ilk);
            feeTreasury = chargeFeeTreasury (info, jug, amount, USBJoin);
            USBJoin_join_wipe(info.ilk, USBJoin, address(this), amount, amount - feeTreasury);
            // Paybacks debt to the CDP
            IVat(info.vat).frob(
                info.ilk,
                info.urn,
                address(this),
                address(this),
                0,
                -int(art)
            );
        }
        calcDebt(info, art, debt, amount);

        emit Repay(msg.sender, cdp, art, feeTreasury); 
    }

    function lockETHAndDraw(
        address manager,
        address jug,
        address ethJoin,
        address USBJoin,
        uint cdp,
        uint wadD
    ) public payable {
        address urn = IDssCdpManager(manager).urns(cdp);
        address vat = IDssCdpManager(manager).vat();
        address ilk = IDssCdpManager(manager).ilks(cdp);
        // Receives ETH amount, converts it to WETH and joins it into the vat
        ethJoin_join(ethJoin, urn);
        // Locks WETH amount into the CDP and generates debt
        frob(manager, cdp, msg.value.toInt(), _getDrawDart(vat, jug, urn, ilk, wadD));
        // Moves the USB amount (balance in the vat in rad) to proxy's address
        move(manager, cdp, address(this), wadD.toRad());
        // Allows adapter to access to proxy's USB balance in the vat
        if (IVat(vat).can(address(this), address(USBJoin)) == 0) {
            IVat(vat).hope(USBJoin);
        }
        // Exits USB to the user's wallet as a token
        IUSBJoin(USBJoin).exit(ilk, msg.sender, wadD);
        IVat(vat).addDebt(ilk, urn, wadD);

        emit Deposit(msg.sender, cdp, msg.value);
        emit Borrow(msg.sender, cdp, wadD);
    }

    function openLockETHAndDraw(
        address manager,
        address jug,
        address ethJoin,
        address USBJoin,
        address ilk,
        uint wadD
    ) public payable returns (uint cdp) {
        cdp = open(manager, ilk, address(this));
        lockETHAndDraw(manager, jug, ethJoin, USBJoin, cdp, wadD);
    }

    function lockGemAndDraw(
        address manager,
        address jug,
        address gemJoin,
        address USBJoin,
        uint cdp,
        uint amtC,
        uint wadD,
        bool transferFrom
    ) public {
        address urn = IDssCdpManager(manager).urns(cdp);
        address vat = IDssCdpManager(manager).vat();
        address ilk = IDssCdpManager(manager).ilks(cdp);
        // Takes token amount from user's wallet and joins into the vat
        gemJoin_join(gemJoin, urn, amtC, transferFrom);
        // Locks token amount into the CDP and generates debt
        int lockAmount = convertTo18(gemJoin, amtC).toInt();
        int debtAmount =_getDrawDart(vat, jug, urn, ilk, wadD);
        frob(manager, cdp, lockAmount, debtAmount);
        // Moves the USB amount (balance in the vat in rad) to proxy's address
        move(manager, cdp, address(this), wadD.toRad());
        // Allows adapter to access to proxy's USB balance in the vat
        if (IVat(vat).can(address(this), address(USBJoin)) == 0) {
            IVat(vat).hope(USBJoin);
        }
        // Exits USB to the user's wallet as a token
        IUSBJoin(USBJoin).exit(ilk, msg.sender, wadD);
        IVat(vat).addDebt(ilk, urn, wadD);

        emit Deposit(msg.sender, cdp, amtC);
        emit Borrow(msg.sender, cdp,wadD);
    }

    function openLockGemAndDraw(
        address manager,
        address jug,
        address gemJoin,
        address USBJoin,
        address ilk,
        uint amtC,
        uint wadD,
        bool transferFrom
    ) public returns (uint cdp) {        
        cdp = open(manager, ilk, address(this));
        lockGemAndDraw(manager, jug, gemJoin, USBJoin, cdp, amtC, wadD, transferFrom);
    }

    // function openLockGNTAndDraw(
    //     address manager,
    //     address jug,
    //     address gntJoin,
    //     address USBJoin,
    //     address ilk,
    //     uint amtC,
    //     uint wadD
    // ) public returns (address bag, uint cdp) {
    //     // Creates bag (if doesn't exist) to hold GNT
    //     bag = GNTJoinLike(gntJoin).bags(address(this));
    //     if (bag == address(0)) {
    //         bag = makeGemBag(gntJoin);
    //     }
    //     // Transfer funds to the funds which previously were sent to the proxy
    //     GemLike(IGemJoin(gntJoin).gem()).transfer(bag, amtC);
    //     cdp = openLockGemAndDraw(manager, jug, gntJoin, USBJoin, ilk, amtC, wadD, false);
    // }

    function wipeAndFreeETH(
        address manager,
        address ethJoin,
        address USBJoin,
        address jug,
        uint cdp,
        uint wadC,
        uint wadD
    ) public onlyVaultOwner(manager, cdp) {
        Info memory info = getInfo(manager, cdp);
        // Joins USB amount into the vat
        uint feeTreasury = chargeFeeTreasury (info, jug, wadD, USBJoin);
        
        USBJoin_join_wipe(info.ilk, USBJoin, info.urn, wadD, wadD - feeTreasury);
        
        // Paybacks debt to the CDP and unlocks WETH amount from it
        int dart = _getWipeDart(
            info,
            IVat(IDssCdpManager(manager).vat()).USB(info.urn)
        );

        frob(
            manager,
            cdp,
            -wadC.toInt(),
            dart
        );
        (, uint art, uint debt) = IVat(info.vat).urns(info.ilk, info.urn);
        calcDebt(info, art, debt, wadD);
        // Moves the amount from the CDP urn to proxy's address
        flux(manager, cdp, address(this), wadC);
        // Exits WETH amount to proxy address as a token
        IGemJoin(ethJoin).exit(address(this), wadC);
        // Converts WETH to ETH
        address weth = IGemJoin(ethJoin).gem();
        IGem(weth).withdraw(wadC);
        // Sends ETH back to the user's wallet
        payable(msg.sender).transfer(wadC);
        emit Repay(msg.sender, cdp, wadD, feeTreasury);
        emit Withdraw(msg.sender, cdp, wadC);
    }

    function wipeAllAndFreeETH(
        address manager,
        address ethJoin,
        address USBJoin,
        address jug,
        uint cdp,
        uint wadC
    ) public onlyVaultOwner(manager, cdp) {
        Info memory info = getInfo(manager, cdp);
        (, uint art, uint debt) = IVat(info.vat).urns(info.ilk, info.urn);
        uint amount = _getWipeAllWad(info.vat, info.urn, info.urn, info.ilk);
        uint feeTreasury = chargeFeeTreasury (info, jug, amount, USBJoin);

        // Joins USB amount into the vat
        USBJoin_join_wipe(info.ilk, USBJoin, info.urn, amount, amount - feeTreasury);
        // Paybacks debt to the CDP and unlocks WETH amount from it
        frob(
            manager,
            cdp,
            -wadC.toInt(),
            -int(art)
        );
        calcDebt(info, art, debt, debt);
        // Moves the amount from the CDP urn to proxy's address
        flux(manager, cdp, address(this), wadC);
        // Exits WETH amount to proxy address as a token
        IGemJoin(ethJoin).exit(address(this), wadC);
        // Converts WETH to ETH
        address weth = IGemJoin(ethJoin).gem();
        IGem(weth).withdraw(wadC);
        // Sends ETH back to the user's wallet
        payable(msg.sender).transfer(wadC);
        emit Repay(msg.sender, cdp, art, feeTreasury);
        emit Withdraw(msg.sender, cdp, wadC);
    }

    function wipeAndFreeGem(
        address manager,
        address gemJoin,
        address USBJoin,
        address jug,
        uint cdp,
        uint amtC,
        uint wadD
    ) public onlyVaultOwner(manager, cdp) {
        Info memory info = getInfo(manager, cdp);
        uint feeTreasury = chargeFeeTreasury (info, jug, wadD, USBJoin);
        // Joins USB amount into the vat
        USBJoin_join_wipe(info.ilk, USBJoin, info.urn, wadD, wadD - feeTreasury);
        
        uint wadC = convertTo18(gemJoin, amtC);
        int dart = _getWipeDart(
            info,
            IVat(IDssCdpManager(manager).vat()).USB(info.urn)         
        );
        // Paybacks debt to the CDP and unlocks token amount from it
        frob(
            manager,
            cdp,
            -wadC.toInt(),
            dart
        );
        (,uint art, uint debt) = IVat(info.vat).urns(info.ilk, info.urn);
        calcDebt(info, art, debt, wadD);
        // Moves the amount from the CDP urn to proxy's address
        flux(manager, cdp, address(this), wadC);
        // Exits token amount to the user's wallet as a token
        IGemJoin(gemJoin).exit(msg.sender, wadC);
        emit Repay(msg.sender, cdp, wadD, feeTreasury);
        emit Withdraw(msg.sender, cdp, wadC);
    }

    function wipeAllAndFreeGem(
        address manager,
        address gemJoin,
        address USBJoin,
        address jug,
        uint cdp,
        uint amtC
    ) public onlyVaultOwner(manager, cdp) {
        Info memory info = getInfo(manager, cdp);
        (, uint art, uint debt) = IVat(info.vat).urns(info.ilk, info.urn);
        uint amount = _getWipeAllWad(info.vat, info.urn, info.urn, info.ilk);
        uint feeTreasury = chargeFeeTreasury (info, jug, amount, USBJoin);
        // Joins USB amount into the vat
        USBJoin_join_wipe(info.ilk, USBJoin, info.urn, amount, amount - feeTreasury);
        
        uint wadC = convertTo18(gemJoin, amtC);
        // Paybacks debt to the CDP and unlocks token amount from it
        frob(
            manager,
            cdp,
            -wadC.toInt(),
            -int(art)
        );
        calcDebt(info, art, debt, debt);
        // Moves the amount from the CDP urn to proxy's address
        flux(manager, cdp, address(this), wadC);
        // Exits token amount to the user's wallet as a token
        IGemJoin(gemJoin).exit(msg.sender, wadC);

        emit Repay(msg.sender, cdp, art, feeTreasury);
        emit Withdraw(msg.sender, cdp, amtC);
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