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

pragma solidity >=0.6.7;

interface DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) external view returns (bool);
}

abstract contract DSAuthEvents {
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
        virtual
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        virtual
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

    function isAuthorized(address src, bytes4 sig) virtual internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

/// GebProxyActions.sol

// Copyright (C) 2018-2020 Maker Ecosystem Growth Holdings, INC.

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

pragma solidity 0.6.7;

import "ds-auth/auth.sol";

abstract contract CollateralLike {
    function approve(address, uint) virtual public;
    function transfer(address, uint) virtual public;
    function transferFrom(address, address, uint) virtual public;
    function deposit() virtual public payable;
    function withdraw(uint) virtual public;
}

abstract contract ManagerLike {
    function safeCan(address, uint, address) virtual public view returns (uint);
    function collateralTypes(uint) virtual public view returns (bytes32);
    function ownsSAFE(uint) virtual public view returns (address);
    function safes(uint) virtual public view returns (address);
    function safeEngine() virtual public view returns (address);
    function openSAFE(bytes32, address) virtual public returns (uint);
    function transferSAFEOwnership(uint, address) virtual public;
    function allowSAFE(uint, address, uint) virtual public;
    function allowHandler(address, uint) virtual public;
    function modifySAFECollateralization(uint, int, int) virtual public;
    function transferCollateral(uint, address, uint) virtual public;
    function transferInternalCoins(uint, address, uint) virtual public;
    function quitSystem(uint, address) virtual public;
    function enterSystem(address, uint) virtual public;
    function moveSAFE(uint, uint) virtual public;
    function protectSAFE(uint, address, address) virtual public;
    function collectRewards(uint, address) virtual public;
}

abstract contract SAFEEngineLike {
    function canModifySAFE(address, address) virtual public view returns (uint);
    function collateralTypes(bytes32) virtual public view returns (uint, uint, uint, uint, uint);
    function coinBalance(address) virtual public view returns (uint);
    function safes(bytes32, address) virtual public view returns (uint, uint);
    function modifySAFECollateralization(bytes32, address, address, address, int, int) virtual public;
    function approveSAFEModification(address) virtual public;
    function transferInternalCoins(address, address, uint) virtual public;
}

abstract contract CollateralJoinLike {
    function decimals() virtual public returns (uint);
    function collateral() virtual public returns (CollateralLike);
    function join(address, uint) virtual public payable;
    function exit(address, uint) virtual public;
}

abstract contract GNTJoinLike {
    function bags(address) virtual public view returns (address);
    function make(address) virtual public returns (address);
}

abstract contract DSTokenLike {
    function balanceOf(address) virtual public view returns (uint);
    function approve(address, uint) virtual public;
    function transfer(address, uint) virtual public returns (bool);
    function transferFrom(address, address, uint) virtual public returns (bool);
}

abstract contract WethLike {
    function balanceOf(address) virtual public view returns (uint);
    function approve(address, uint) virtual public;
    function transfer(address, uint) virtual public;
    function transferFrom(address, address, uint) virtual public;
    function deposit() virtual public payable;
    function withdraw(uint) virtual public;
}

abstract contract CoinJoinLike {
    function safeEngine() virtual public returns (SAFEEngineLike);
    function systemCoin() virtual public returns (DSTokenLike);
    function join(address, uint) virtual public payable;
    function exit(address, uint) virtual public;
}

abstract contract ApproveSAFEModificationLike {
    function approveSAFEModification(address) virtual public;
    function denySAFEModification(address) virtual public;
}

abstract contract GlobalSettlementLike {
    function collateralCashPrice(bytes32) virtual public view returns (uint);
    function redeemCollateral(bytes32, uint) virtual public;
    function freeCollateral(bytes32) virtual public;
    function prepareCoinsForRedeeming(uint) virtual public;
    function processSAFE(bytes32, address) virtual public;
}

abstract contract TaxCollectorLike {
    function taxSingle(bytes32) virtual public returns (uint);
}

abstract contract CoinSavingsAccountLike {
    function savings(address) virtual public view returns (uint);
    function updateAccumulatedRate() virtual public returns (uint);
    function deposit(uint) virtual public;
    function withdraw(uint) virtual public;
}

abstract contract ProxyRegistryLike {
    function proxies(address) virtual public view returns (address);
    function build(address) virtual public returns (address);
}

abstract contract ProxyLike {
    function owner() virtual public view returns (address);
}

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a DSProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

contract Common {
    uint256 constant RAY = 10 ** 27;

    // Internal functions
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "mul-overflow");
    }

    function _coinJoin_join(address apt, address safeHandler, uint wad) internal {
        // Approves adapter to take the COIN amount
        CoinJoinLike(apt).systemCoin().approve(apt, wad);
        // Joins COIN into the safeEngine
        CoinJoinLike(apt).join(safeHandler, wad);
    }

    // Public functions
    function coinJoin_join(address apt, address safeHandler, uint wad) public {
        // Gets COIN from the user's wallet
        CoinJoinLike(apt).systemCoin().transferFrom(msg.sender, address(this), wad);

        _coinJoin_join(apt, safeHandler, wad);
    }
}

contract BasicActions is Common {
    // Internal functions

    /// @notice Safe subtraction
    /// @dev Reverts on overflows
    function subtract(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-overflow");
    }

    /// @notice Safe conversion uint -> int
    /// @dev Reverts on overflows
    function toInt(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0, "int-overflow");
    }

    /// @notice Converts a wad (18 decimal places) to rad (45 decimal places)
    function toRad(uint wad) internal pure returns (uint rad) {
        rad = multiply(wad, 10 ** 27);
    }

    function convertTo18(address collateralJoin, uint256 amt) internal returns (uint256 wad) {
        // For those collaterals that have other than 18 decimals precision we need to do the conversion before passing to modifySAFECollateralization function
        // Adapters will automatically handle the difference of precision
        uint decimals = CollateralJoinLike(collateralJoin).decimals();
        wad = amt;
        if (decimals < 18) {
          wad = multiply(
              amt,
              10 ** (18 - decimals)
          );
        } else if (decimals > 18) {
          wad = amt / 10 ** (decimals - 18);
        }
    }

    /// @notice Gets delta debt generated (Total Safe debt minus available safeHandler COIN balance)
    /// @param safeEngine address
    /// @param taxCollector address
    /// @param safeHandler address
    /// @param collateralType bytes32
    /// @return deltaDebt
    function _getGeneratedDeltaDebt(
        address safeEngine,
        address taxCollector,
        address safeHandler,
        bytes32 collateralType,
        uint wad
    ) internal returns (int deltaDebt) {
        // Updates stability fee rate
        uint rate = TaxCollectorLike(taxCollector).taxSingle(collateralType);
        require(rate > 0, "invalid-collateral-type");

        // Gets COIN balance of the handler in the safeEngine
        uint coin = SAFEEngineLike(safeEngine).coinBalance(safeHandler);

        // If there was already enough COIN in the safeEngine balance, just exits it without adding more debt
        if (coin < multiply(wad, RAY)) {
            // Calculates the needed deltaDebt so together with the existing coins in the safeEngine is enough to exit wad amount of COIN tokens
            deltaDebt = toInt(subtract(multiply(wad, RAY), coin) / rate);
            // This is neeeded due lack of precision. It might need to sum an extra deltaDebt wei (for the given COIN wad amount)
            deltaDebt = multiply(uint(deltaDebt), rate) < multiply(wad, RAY) ? deltaDebt + 1 : deltaDebt;
        }
    }

    /// @notice Gets repaid delta debt generated (rate adjusted debt)
    /// @param safeEngine address
    /// @param coin uint amount
    /// @param safe uint - safeId
    /// @param collateralType bytes32
        /// @return deltaDebt
    function _getRepaidDeltaDebt(
        address safeEngine,
        uint coin,
        address safe,
        bytes32 collateralType
    ) internal view returns (int deltaDebt) {
        // Gets actual rate from the safeEngine
        (, uint rate,,,) = SAFEEngineLike(safeEngine).collateralTypes(collateralType);
        require(rate > 0, "invalid-collateral-type");

        // Gets actual generatedDebt value of the safe
        (, uint generatedDebt) = SAFEEngineLike(safeEngine).safes(collateralType, safe);

        // Uses the whole coin balance in the safeEngine to reduce the debt
        deltaDebt = toInt(coin / rate);
        // Checks the calculated deltaDebt is not higher than safe.generatedDebt (total debt), otherwise uses its value
        deltaDebt = uint(deltaDebt) <= generatedDebt ? - deltaDebt : - toInt(generatedDebt);
    }

    /// @notice Gets repaid debt (rate adjusted rate minus COIN balance available in usr's address)
    /// @param safeEngine address
    /// @param usr address
    /// @param safe uint
    /// @param collateralType address
    /// @return wad
    function _getRepaidAlDebt(
        address safeEngine,
        address usr,
        address safe,
        bytes32 collateralType
    ) internal view returns (uint wad) {
        // Gets actual rate from the safeEngine
        (, uint rate,,,) = SAFEEngineLike(safeEngine).collateralTypes(collateralType);
        // Gets actual generatedDebt value of the safe
        (, uint generatedDebt) = SAFEEngineLike(safeEngine).safes(collateralType, safe);
        // Gets actual coin amount in the safe
        uint coin = SAFEEngineLike(safeEngine).coinBalance(usr);

        uint rad = subtract(multiply(generatedDebt, rate), coin);
        wad = rad / RAY;

        // If the rad precision has some dust, it will need to request for 1 extra wad wei
        wad = multiply(wad, RAY) < rad ? wad + 1 : wad;
    }

    /// @notice Generates Debt (and sends coin balance to address to)
    /// @param manager address
    /// @param taxCollector address
    /// @param coinJoin address
    /// @param safe uint
    /// @param wad uint - amount of debt to be generated
    /// @param to address - receiver of the balance of generated COIN
    function _generateDebt(address manager, address taxCollector, address coinJoin, uint safe, uint wad, address to) internal {
        address safeHandler = ManagerLike(manager).safes(safe);
        address safeEngine = ManagerLike(manager).safeEngine();
        bytes32 collateralType = ManagerLike(manager).collateralTypes(safe);
        // Generates debt in the SAFE
        modifySAFECollateralization(manager, safe, 0, _getGeneratedDeltaDebt(safeEngine, taxCollector, safeHandler, collateralType, wad));
        // Moves the COIN amount (balance in the safeEngine in rad) to proxy's address
        transferInternalCoins(manager, safe, address(this), toRad(wad));
        // Allows adapter to access to proxy's COIN balance in the safeEngine
        if (SAFEEngineLike(safeEngine).canModifySAFE(address(this), address(coinJoin)) == 0) {
            SAFEEngineLike(safeEngine).approveSAFEModification(coinJoin);
        }
        // Exits COIN to this contract
        CoinJoinLike(coinJoin).exit(to, wad);
    }

    /// @notice Generates Debt (and sends coin balance to address to)
    /// @param manager address
    /// @param ethJoin address
    /// @param safe uint
    /// @param value uint - amount of ETH to be locked in the Safe.
    /// @dev Proxy needs to have enough balance (> value), public functions should handle this.
    function _lockETH(
        address manager,
        address ethJoin,
        uint safe,
        uint value
    ) internal {
        // Receives ETH amount, converts it to WETH and joins it into the safeEngine
        ethJoin_join(ethJoin, address(this), value);
        // Locks WETH amount into the SAFE
        SAFEEngineLike(ManagerLike(manager).safeEngine()).modifySAFECollateralization(
            ManagerLike(manager).collateralTypes(safe),
            ManagerLike(manager).safes(safe),
            address(this),
            address(this),
            toInt(value),
            0
        );
    }

    /// @notice Repays debt
    /// @param manager address
    /// @param coinJoin address
    /// @param safe uint
    /// @param wad uint - amount of debt to be repayed
    function _repayDebt(
        address manager,
        address coinJoin,
        uint safe,
        uint wad,
        bool transferFromCaller
    ) internal {
        address safeEngine = ManagerLike(manager).safeEngine();
        address safeHandler = ManagerLike(manager).safes(safe);
        bytes32 collateralType = ManagerLike(manager).collateralTypes(safe);

        address own = ManagerLike(manager).ownsSAFE(safe);
        if (own == address(this) || ManagerLike(manager).safeCan(own, safe, address(this)) == 1) {
            // Joins COIN amount into the safeEngine
            if (transferFromCaller) coinJoin_join(coinJoin, safeHandler, wad);
            else _coinJoin_join(coinJoin, safeHandler, wad);
            // // Paybacks debt to the SAFE
            modifySAFECollateralization(manager, safe, 0, _getRepaidDeltaDebt(safeEngine, SAFEEngineLike(safeEngine).coinBalance(safeHandler), safeHandler, collateralType));
        } else {
             // Joins COIN amount into the safeEngine
            if (transferFromCaller) coinJoin_join(coinJoin, address(this), wad);
            else _coinJoin_join(coinJoin, address(this), wad);
            // Paybacks debt to the SAFE
            SAFEEngineLike(safeEngine).modifySAFECollateralization(
                collateralType,
                safeHandler,
                address(this),
                address(this),
                0,
                _getRepaidDeltaDebt(safeEngine, wad * RAY, safeHandler, collateralType)
            );
        }
    }

    /// @notice Repays debt and frees collateral ETH
    /// @param manager address
    /// @param ethJoin address
    /// @param coinJoin address
    /// @param safe uint
    /// @param collateralWad uint - amount of ETH to free
    /// @param deltaWad uint - amount of debt to be repayed
    /// @param transferFromCaller True if transferring coin from caller, false if balance in the proxy
    function _repayDebtAndFreeETH(
        address manager,
        address ethJoin,
        address coinJoin,
        uint safe,
        uint collateralWad,
        uint deltaWad,
        bool transferFromCaller
    ) internal {
        address safeHandler = ManagerLike(manager).safes(safe);
        // Joins COIN amount into the safeEngine
        if (transferFromCaller) coinJoin_join(coinJoin, safeHandler, deltaWad);
        else _coinJoin_join(coinJoin, safeHandler, deltaWad);
        // Paybacks debt to the SAFE and unlocks WETH amount from it
        modifySAFECollateralization(
            manager,
            safe,
            -toInt(collateralWad),
            _getRepaidDeltaDebt(ManagerLike(manager).safeEngine(), SAFEEngineLike(ManagerLike(manager).safeEngine()).coinBalance(safeHandler), safeHandler, ManagerLike(manager).collateralTypes(safe))
        );
        // Moves the amount from the SAFE handler to proxy's address
        transferCollateral(manager, safe, address(this), collateralWad);
        // Exits WETH amount to proxy address as a token
        CollateralJoinLike(ethJoin).exit(address(this), collateralWad);
        // Converts WETH to ETH
        CollateralJoinLike(ethJoin).collateral().withdraw(collateralWad);
    }

    // Public functions

    /// @notice ERC20 transfer
    /// @param collateral address - address of ERC20 collateral
    /// @param dst address - Transfer destination
    /// @param amt address - Amount to transfer
    function transfer(address collateral, address dst, uint amt) external {
        CollateralLike(collateral).transfer(dst, amt);
    }

    /// @notice Joins the system with the full msg.value
    /// @param apt address - Address of the adapter
    /// @param safe uint - Safe Id
    function ethJoin_join(address apt, address safe) external payable {
        ethJoin_join(apt, safe, msg.value);
    }

    /// @notice Joins the system with the a specified value
    /// @param apt address - Address of the adapter
    /// @param safe uint - Safe Id
    /// @param value uint - Value to join
    function ethJoin_join(address apt, address safe, uint value) public payable {
        // Wraps ETH in WETH
        CollateralJoinLike(apt).collateral().deposit{value: value}();
        // Approves adapter to take the WETH amount
        CollateralJoinLike(apt).collateral().approve(address(apt), value);
        // Joins WETH collateral into the safeEngine
        CollateralJoinLike(apt).join(safe, value);
    }

    /// @notice Approves an address to modify the Safe
    /// @param safeEngine address
    /// @param usr address - Address allowed to modify Safe
    function approveSAFEModification(
        address safeEngine,
        address usr
    ) external {
        ApproveSAFEModificationLike(safeEngine).approveSAFEModification(usr);
    }

    /// @notice Denies an address to modify the Safe
    /// @param safeEngine address
    /// @param usr address - Address disallowed to modify Safe
    function denySAFEModification(
        address safeEngine,
        address usr
    ) external {
        ApproveSAFEModificationLike(safeEngine).denySAFEModification(usr);
    }

    /// @notice Opens a brand new Safe
    /// @param manager address - Safe Manager
    /// @param collateralType bytes32 - collateral type
    /// @param usr address - Owner of the safe
    function openSAFE(
        address manager,
        bytes32 collateralType,
        address usr
    ) public returns (uint safe) {
        safe = ManagerLike(manager).openSAFE(collateralType, usr);
    }

    /// @notice Transfer the ownership of a proxy owned Safe
    /// @param manager address - Safe Manager
    /// @param safe uint - Safe Id
    /// @param usr address - Owner of the safe
    function transferSAFEOwnership(
        address manager,
        uint safe,
        address usr
    ) public {
        ManagerLike(manager).transferSAFEOwnership(safe, usr);
    }

    /// @notice Transfer the ownership to a new proxy owned by a different address
    /// @param proxyRegistry address - Safe Manager
    /// @param manager address - Safe Manager
    /// @param safe uint - Safe Id
    /// @param dst address - Owner of the new proxy
    function transferSAFEOwnershipToProxy(
        address proxyRegistry,
        address manager,
        uint safe,
        address dst
    ) external {
        // Gets actual proxy address
        address proxy = ProxyRegistryLike(proxyRegistry).proxies(dst);
        // Checks if the proxy address already existed and dst address is still the owner
        if (proxy == address(0) || ProxyLike(proxy).owner() != dst) {
            uint csize;
            assembly {
                csize := extcodesize(dst)
            }
            // We want to avoid creating a proxy for a contract address that might not be able to handle proxies, then losing the SAFE
            require(csize == 0, "dst-is-a-contract");
            // Creates the proxy for the dst address
            proxy = ProxyRegistryLike(proxyRegistry).build(dst);
        }
        // Transfers SAFE to the dst proxy
        transferSAFEOwnership(manager, safe, proxy);
    }

    /// @notice Allow/disallow a usr address to manage the safe
    /// @param manager address - Safe Manager
    /// @param safe uint - Safe Id
    /// @param usr address - usr address
    /// uint ok - 1 for allowed
    function allowSAFE(
        address manager,
        uint safe,
        address usr,
        uint ok
    ) external {
        ManagerLike(manager).allowSAFE(safe, usr, ok);
    }

    /// @notice Allow/disallow a usr address to quit to the sender handler
    /// @param manager address - Safe Manager
    /// @param usr address - usr address
    /// uint ok - 1 for allowed
    function allowHandler(
        address manager,
        address usr,
        uint ok
    ) external {
        ManagerLike(manager).allowHandler(usr, ok);
    }

    /// @notice Transfer wad amount of safe collateral from the safe address to a dst address.
    /// @param manager address - Safe Manager
    /// @param safe uint - Safe Id
    /// @param dst address - destination address
    /// uint wad - amount
    function transferCollateral(
        address manager,
        uint safe,
        address dst,
        uint wad
    ) public {
        ManagerLike(manager).transferCollateral(safe, dst, wad);
    }

    /// @notice Transfer rad amount of COIN from the safe address to a dst address.
    /// @param manager address - Safe Manager
    /// @param safe uint - Safe Id
    /// @param dst address - destination address
    /// uint rad - amount
    function transferInternalCoins(
        address manager,
        uint safe,
        address dst,
        uint rad
    ) public {
        ManagerLike(manager).transferInternalCoins(safe, dst, rad);
    }


    /// @notice Modify a SAFE's collateralization ratio while keeping the generated COIN or collateral freed in the SAFE handler address.
    /// @param manager address - Safe Manager
    /// @param safe uint - Safe Id
    /// @param deltaCollateral - int
    /// @param deltaDebt - int
    function modifySAFECollateralization(
        address manager,
        uint safe,
        int deltaCollateral,
        int deltaDebt
    ) public {
        ManagerLike(manager).modifySAFECollateralization(safe, deltaCollateral, deltaDebt);
    }

    /// @notice Quit the system, migrating the safe (lockedCollateral, generatedDebt) to a different dst handler
    /// @param manager address - Safe Manager
    /// @param safe uint - Safe Id
    /// @param dst - destination handler
    function quitSystem(
        address manager,
        uint safe,
        address dst
    ) external {
        ManagerLike(manager).quitSystem(safe, dst);
    }

    /// @notice Import a position from src handler to the handler owned by safe
    /// @param manager address - Safe Manager
    /// @param src - source handler
    /// @param safe uint - Safe Id
    function enterSystem(
        address manager,
        address src,
        uint safe
    ) external {
        ManagerLike(manager).enterSystem(src, safe);
    }

    /// @notice Move a position from safeSrc handler to the safeDst handler
    /// @param manager address - Safe Manager
    /// @param safeSrc uint - Source Safe Id
    /// @param safeDst uint - Destination Safe Id
    function moveSAFE(
        address manager,
        uint safeSrc,
        uint safeDst
    ) external {
        ManagerLike(manager).moveSAFE(safeSrc, safeDst);
    }

    /// @notice Lock ETH (msg.value) as collateral in safe
    /// @param manager address - Safe Manager
    /// @param ethJoin address
    /// @param safe uint - Safe Id
    function lockETH(
        address manager,
        address ethJoin,
        uint safe
    ) public payable {
        _lockETH(manager, ethJoin, safe, msg.value);
    }

    /// @notice Free ETH (wad) from safe and sends it to msg.sender
    /// @param manager address - Safe Manager
    /// @param ethJoin address
    /// @param safe uint - Safe Id
    /// @param wad uint - Amount
    function freeETH(
        address manager,
        address ethJoin,
        uint safe,
        uint wad
    ) public {
        // Unlocks WETH amount from the SAFE
        modifySAFECollateralization(manager, safe, -toInt(wad), 0);
        // Moves the amount from the SAFE handler to proxy's address
        transferCollateral(manager, safe, address(this), wad);
        // Exits WETH amount to proxy address as a token
        CollateralJoinLike(ethJoin).exit(address(this), wad);
        // Converts WETH to ETH
        CollateralJoinLike(ethJoin).collateral().withdraw(wad);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(wad);
    }


    /// @notice Exits ETH (wad) from balance available in the handler
    /// @param manager address - Safe Manager
    /// @param ethJoin address
    /// @param safe uint - Safe Id
    /// @param wad uint - Amount
    function exitETH(
        address manager,
        address ethJoin,
        uint safe,
        uint wad
    ) external {
        // Moves the amount from the SAFE handler to proxy's address
        transferCollateral(manager, safe, address(this), wad);
        // Exits WETH amount to proxy address as a token
        CollateralJoinLike(ethJoin).exit(address(this), wad);
        // Converts WETH to ETH
        CollateralJoinLike(ethJoin).collateral().withdraw(wad);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(wad);
    }

    /// @notice Generates debt and sends COIN amount to msg.sender
    /// @param manager address
    /// @param taxCollector address
    /// @param coinJoin address
    /// @param safe uint - Safe Id
    /// @param wad uint - Amount
    function generateDebt(
        address manager,
        address taxCollector,
        address coinJoin,
        uint safe,
        uint wad
    ) public {
        _generateDebt(manager, taxCollector, coinJoin, safe, wad, msg.sender);
    }

    /// @notice Repays debt
    /// @param manager address
    /// @param coinJoin address
    /// @param safe uint - Safe Id
    /// @param wad uint - Amount
    function repayDebt(
        address manager,
        address coinJoin,
        uint safe,
        uint wad
    ) public {
        _repayDebt(manager, coinJoin, safe, wad, true);
    }

    /// @notice Locks Eth, generates debt and sends COIN amount (deltaWad) to msg.sender
    /// @param manager address
    /// @param taxCollector address
    /// @param ethJoin address
    /// @param coinJoin address
    /// @param safe uint - Safe Id
    /// @param deltaWad uint - Amount
    function lockETHAndGenerateDebt(
        address manager,
        address taxCollector,
        address ethJoin,
        address coinJoin,
        uint safe,
        uint deltaWad
    ) public payable {
        _lockETH(manager, ethJoin, safe, msg.value);
        _generateDebt(manager, taxCollector, coinJoin, safe, deltaWad, msg.sender);
    }

    /// @notice Opens Safe, locks Eth, generates debt and sends COIN amount (deltaWad) to msg.sender
    /// @param manager address
    /// @param taxCollector address
    /// @param ethJoin address
    /// @param coinJoin address
    /// @param deltaWad uint - Amount
    function openLockETHAndGenerateDebt(
        address manager,
        address taxCollector,
        address ethJoin,
        address coinJoin,
        bytes32 collateralType,
        uint deltaWad
    ) external payable returns (uint safe) {
        safe = openSAFE(manager, collateralType, address(this));
        lockETHAndGenerateDebt(manager, taxCollector, ethJoin, coinJoin, safe, deltaWad);
    }

    /// @notice Repays debt and frees ETH (sends it to msg.sender)
    /// @param manager address
    /// @param ethJoin address
    /// @param coinJoin address
    /// @param safe uint - Safe Id
    /// @param collateralWad uint - Amount of collateral to free
    /// @param deltaWad uint - Amount of debt to repay
    function repayDebtAndFreeETH(
        address manager,
        address ethJoin,
        address coinJoin,
        uint safe,
        uint collateralWad,
        uint deltaWad
    ) external {
        _repayDebtAndFreeETH(manager, ethJoin, coinJoin, safe, collateralWad, deltaWad, true);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(collateralWad);
    }    
}

contract GebProxyActions is BasicActions {

    function tokenCollateralJoin_join(address apt, address safe, uint amt, bool transferFrom) public {
        // Only executes for tokens that have approval/transferFrom implementation
        if (transferFrom) {
            // Gets token from the user's wallet
            CollateralJoinLike(apt).collateral().transferFrom(msg.sender, address(this), amt);
            // Approves adapter to take the token amount
            CollateralJoinLike(apt).collateral().approve(apt, amt);
        }
        // Joins token collateral into the safeEngine
        CollateralJoinLike(apt).join(safe, amt);
    }

    function protectSAFE(
        address manager,
        uint safe,
        address liquidationEngine,
        address saviour
    ) public {
        ManagerLike(manager).protectSAFE(safe, liquidationEngine, saviour);
    }

    function makeCollateralBag(
        address collateralJoin
    ) public returns (address bag) {
        bag = GNTJoinLike(collateralJoin).make(address(this));
    }

    function safeLockETH(
        address manager,
        address ethJoin,
        uint safe,
        address owner
    ) public payable {
        require(ManagerLike(manager).ownsSAFE(safe) == owner, "owner-missmatch");
        lockETH(manager, ethJoin, safe);
    }

    function lockTokenCollateral(
        address manager,
        address collateralJoin,
        uint safe,
        uint amt,
        bool transferFrom
    ) public {
        // Takes token amount from user's wallet and joins into the safeEngine
        tokenCollateralJoin_join(collateralJoin, address(this), amt, transferFrom);
        // Locks token amount into the SAFE
        SAFEEngineLike(ManagerLike(manager).safeEngine()).modifySAFECollateralization(
            ManagerLike(manager).collateralTypes(safe),
            ManagerLike(manager).safes(safe),
            address(this),
            address(this),
            toInt(convertTo18(collateralJoin, amt)),
            0
        );
    }

    function safeLockTokenCollateral(
        address manager,
        address collateralJoin,
        uint safe,
        uint amt,
        bool transferFrom,
        address owner
    ) public {
        require(ManagerLike(manager).ownsSAFE(safe) == owner, "owner-missmatch");
        lockTokenCollateral(manager, collateralJoin, safe, amt, transferFrom);
    }

    function freeTokenCollateral(
        address manager,
        address collateralJoin,
        uint safe,
        uint amt
    ) public {
        uint wad = convertTo18(collateralJoin, amt);
        // Unlocks token amount from the SAFE
        modifySAFECollateralization(manager, safe, -toInt(wad), 0);
        // Moves the amount from the SAFE handler to proxy's address
        transferCollateral(manager, safe, address(this), wad);
        // Exits token amount to the user's wallet as a token
        CollateralJoinLike(collateralJoin).exit(msg.sender, amt);
    }

    function exitTokenCollateral(
        address manager,
        address collateralJoin,
        uint safe,
        uint amt
    ) public {
        // Moves the amount from the SAFE handler to proxy's address
        transferCollateral(manager, safe, address(this), convertTo18(collateralJoin, amt));

        // Exits token amount to the user's wallet as a token
        CollateralJoinLike(collateralJoin).exit(msg.sender, amt);
    }

    function generateDebtAndProtectSAFE(
        address manager,
        address taxCollector,
        address coinJoin,
        uint safe,
        uint wad,
        address liquidationEngine,
        address saviour
    ) external {
        generateDebt(manager, taxCollector, coinJoin, safe, wad);
        protectSAFE(manager, safe, liquidationEngine, saviour);
    }

    function safeRepayDebt(
        address manager,
        address coinJoin,
        uint safe,
        uint wad,
        address owner
    ) public {
        require(ManagerLike(manager).ownsSAFE(safe) == owner, "owner-missmatch");
        repayDebt(manager, coinJoin, safe, wad);
    }

    function repayAllDebt(
        address manager,
        address coinJoin,
        uint safe
    ) public {
        address safeEngine = ManagerLike(manager).safeEngine();
        address safeHandler = ManagerLike(manager).safes(safe);
        bytes32 collateralType = ManagerLike(manager).collateralTypes(safe);
        (, uint generatedDebt) = SAFEEngineLike(safeEngine).safes(collateralType, safeHandler);

        address own = ManagerLike(manager).ownsSAFE(safe);
        if (own == address(this) || ManagerLike(manager).safeCan(own, safe, address(this)) == 1) {
            // Joins COIN amount into the safeEngine
            coinJoin_join(coinJoin, safeHandler, _getRepaidAlDebt(safeEngine, safeHandler, safeHandler, collateralType));
            // Paybacks debt to the SAFE
            modifySAFECollateralization(manager, safe, 0, -int(generatedDebt));
        } else {
            // Joins COIN amount into the safeEngine
            coinJoin_join(coinJoin, address(this), _getRepaidAlDebt(safeEngine, address(this), safeHandler, collateralType));
            // Paybacks debt to the SAFE
            SAFEEngineLike(safeEngine).modifySAFECollateralization(
                collateralType,
                safeHandler,
                address(this),
                address(this),
                0,
                -int(generatedDebt)
            );
        }
    }

    function safeRepayAllDebt(
        address manager,
        address coinJoin,
        uint safe,
        address owner
    ) public {
        require(ManagerLike(manager).ownsSAFE(safe) == owner, "owner-missmatch");
        repayAllDebt(manager, coinJoin, safe);
    }

    function openLockETHGenerateDebtAndProtectSAFE(
        address manager,
        address taxCollector,
        address ethJoin,
        address coinJoin,
        bytes32 collateralType,
        uint deltaWad,
        address liquidationEngine,
        address saviour
    ) public payable returns (uint safe) {
        safe = openSAFE(manager, collateralType, address(this));
        lockETHAndGenerateDebt(manager, taxCollector, ethJoin, coinJoin, safe, deltaWad);
        protectSAFE(manager, safe, liquidationEngine, saviour);
    }

    function lockTokenCollateralAndGenerateDebt(
        address manager,
        address taxCollector,
        address collateralJoin,
        address coinJoin,
        uint safe,
        uint collateralAmount,
        uint deltaWad,
        bool transferFrom
    ) public {
        address safeHandler = ManagerLike(manager).safes(safe);
        address safeEngine = ManagerLike(manager).safeEngine();
        bytes32 collateralType = ManagerLike(manager).collateralTypes(safe);
        // Takes token amount from user's wallet and joins into the safeEngine
        tokenCollateralJoin_join(collateralJoin, safeHandler, collateralAmount, transferFrom);
        // Locks token amount into the SAFE and generates debt
        modifySAFECollateralization(manager, safe, toInt(convertTo18(collateralJoin, collateralAmount)), _getGeneratedDeltaDebt(safeEngine, taxCollector, safeHandler, collateralType, deltaWad));
        // Moves the COIN amount (balance in the safeEngine in rad) to proxy's address
        transferInternalCoins(manager, safe, address(this), toRad(deltaWad));
        // Allows adapter to access to proxy's COIN balance in the safeEngine
        if (SAFEEngineLike(safeEngine).canModifySAFE(address(this), address(coinJoin)) == 0) {
            SAFEEngineLike(safeEngine).approveSAFEModification(coinJoin);
        }
        // Exits COIN to the user's wallet as a token
        CoinJoinLike(coinJoin).exit(msg.sender, deltaWad);
    }

    function lockTokenCollateralGenerateDebtAndProtectSAFE(
        address manager,
        address taxCollector,
        address collateralJoin,
        address coinJoin,
        uint safe,
        uint collateralAmount,
        uint deltaWad,
        bool transferFrom,
        address liquidationEngine,
        address saviour
    ) public {
        lockTokenCollateralAndGenerateDebt(
          manager,
          taxCollector,
          collateralJoin,
          coinJoin,
          safe,
          collateralAmount,
          deltaWad,
          transferFrom
        );
        protectSAFE(manager, safe, liquidationEngine, saviour);
    }

    function openLockTokenCollateralAndGenerateDebt(
        address manager,
        address taxCollector,
        address collateralJoin,
        address coinJoin,
        bytes32 collateralType,
        uint collateralAmount,
        uint deltaWad,
        bool transferFrom
    ) public returns (uint safe) {
        safe = openSAFE(manager, collateralType, address(this));
        lockTokenCollateralAndGenerateDebt(manager, taxCollector, collateralJoin, coinJoin, safe, collateralAmount, deltaWad, transferFrom);
    }

    function openLockTokenCollateralGenerateDebtAndProtectSAFE(
        address manager,
        address taxCollector,
        address collateralJoin,
        address coinJoin,
        bytes32 collateralType,
        uint collateralAmount,
        uint deltaWad,
        bool transferFrom,
        address liquidationEngine,
        address saviour
    ) public returns (uint safe) {
        safe = openSAFE(manager, collateralType, address(this));
        lockTokenCollateralAndGenerateDebt(manager, taxCollector, collateralJoin, coinJoin, safe, collateralAmount, deltaWad, transferFrom);
        protectSAFE(manager, safe, liquidationEngine, saviour);
    }

    function openLockGNTAndGenerateDebt(
        address manager,
        address taxCollector,
        address gntJoin,
        address coinJoin,
        bytes32 collateralType,
        uint collateralAmount,
        uint deltaWad
    ) public returns (address bag, uint safe) {
        // Creates bag (if doesn't exist) to hold GNT
        bag = GNTJoinLike(gntJoin).bags(address(this));
        if (bag == address(0)) {
            bag = makeCollateralBag(gntJoin);
        }
        // Transfer funds to the funds which previously were sent to the proxy
        CollateralLike(CollateralJoinLike(gntJoin).collateral()).transfer(bag, collateralAmount);
        safe = openLockTokenCollateralAndGenerateDebt(manager, taxCollector, gntJoin, coinJoin, collateralType, collateralAmount, deltaWad, false);
    }

    function openLockGNTGenerateDebtAndProtectSAFE(
        address manager,
        address taxCollector,
        address gntJoin,
        address coinJoin,
        bytes32 collateralType,
        uint collateralAmount,
        uint deltaWad,
        address liquidationEngine,
        address saviour
    ) public returns (address bag, uint safe) {
        (bag, safe) = openLockGNTAndGenerateDebt(
          manager,
          taxCollector,
          gntJoin,
          coinJoin,
          collateralType,
          collateralAmount,
          deltaWad
        );
        protectSAFE(manager, safe, liquidationEngine, saviour);
    }

    function repayAllDebtAndFreeETH(
        address manager,
        address ethJoin,
        address coinJoin,
        uint safe,
        uint collateralWad
    ) public {
        address safeEngine = ManagerLike(manager).safeEngine();
        address safeHandler = ManagerLike(manager).safes(safe);
        bytes32 collateralType = ManagerLike(manager).collateralTypes(safe);
        (, uint generatedDebt) = SAFEEngineLike(safeEngine).safes(collateralType, safeHandler);

        // Joins COIN amount into the safeEngine
        coinJoin_join(coinJoin, safeHandler, _getRepaidAlDebt(safeEngine, safeHandler, safeHandler, collateralType));
        // Paybacks debt to the SAFE and unlocks WETH amount from it
        modifySAFECollateralization(
            manager,
            safe,
            -toInt(collateralWad),
            -int(generatedDebt)
        );
        // Moves the amount from the SAFE handler to proxy's address
        transferCollateral(manager, safe, address(this), collateralWad);
        // Exits WETH amount to proxy address as a token
        CollateralJoinLike(ethJoin).exit(address(this), collateralWad);
        // Converts WETH to ETH
        CollateralJoinLike(ethJoin).collateral().withdraw(collateralWad);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(collateralWad);
    }

    function repayDebtAndFreeTokenCollateral(
        address manager,
        address collateralJoin,
        address coinJoin,
        uint safe,
        uint collateralAmount,
        uint deltaWad
    ) external {
        address safeHandler = ManagerLike(manager).safes(safe);
        // Joins COIN amount into the safeEngine
        coinJoin_join(coinJoin, safeHandler, deltaWad);
        uint collateralWad = convertTo18(collateralJoin, collateralAmount);
        // Paybacks debt to the SAFE and unlocks token amount from it
        modifySAFECollateralization(
            manager,
            safe,
            -toInt(collateralWad),
            _getRepaidDeltaDebt(ManagerLike(manager).safeEngine(), SAFEEngineLike(ManagerLike(manager).safeEngine()).coinBalance(safeHandler), safeHandler, ManagerLike(manager).collateralTypes(safe))
        );
        // Moves the amount from the SAFE handler to proxy's address
        transferCollateral(manager, safe, address(this), collateralWad);
        // Exits token amount to the user's wallet as a token
        CollateralJoinLike(collateralJoin).exit(msg.sender, collateralAmount);
    }

    function repayAllDebtAndFreeTokenCollateral(
        address manager,
        address collateralJoin,
        address coinJoin,
        uint safe,
        uint collateralAmount
    ) public {
        address safeEngine = ManagerLike(manager).safeEngine();
        address safeHandler = ManagerLike(manager).safes(safe);
        bytes32 collateralType = ManagerLike(manager).collateralTypes(safe);
        (, uint generatedDebt) = SAFEEngineLike(safeEngine).safes(collateralType, safeHandler);

        // Joins COIN amount into the safeEngine
        coinJoin_join(coinJoin, safeHandler, _getRepaidAlDebt(safeEngine, safeHandler, safeHandler, collateralType));
        uint collateralWad = convertTo18(collateralJoin, collateralAmount);
        // Paybacks debt to the SAFE and unlocks token amount from it
        modifySAFECollateralization(
            manager,
            safe,
            -toInt(collateralWad),
            -int(generatedDebt)
        );
        // Moves the amount from the SAFE handler to proxy's address
        transferCollateral(manager, safe, address(this), collateralWad);
        // Exits token amount to the user's wallet as a token
        CollateralJoinLike(collateralJoin).exit(msg.sender, collateralAmount);
    }
}

contract GebProxyActionsGlobalSettlement is Common {

    // Internal functions
    function _freeCollateral(
        address manager,
        address globalSettlement,
        uint safe
    ) internal returns (uint lockedCollateral) {
        bytes32 collateralType = ManagerLike(manager).collateralTypes(safe);
        address safeHandler = ManagerLike(manager).safes(safe);
        SAFEEngineLike safeEngine = SAFEEngineLike(ManagerLike(manager).safeEngine());
        uint generatedDebt;
        (lockedCollateral, generatedDebt) = safeEngine.safes(collateralType, safeHandler);

        // If SAFE still has debt, it needs to be paid
        if (generatedDebt > 0) {
            GlobalSettlementLike(globalSettlement).processSAFE(collateralType, safeHandler);
            (lockedCollateral,) = safeEngine.safes(collateralType, safeHandler);
        }
        // Approves the manager to transfer the position to proxy's address in the safeEngine
        if (safeEngine.canModifySAFE(address(this), address(manager)) == 0) {
            safeEngine.approveSAFEModification(manager);
        }
        // Transfers position from SAFE to the proxy address
        ManagerLike(manager).quitSystem(safe, address(this));
        // Frees the position and recovers the collateral in the safeEngine registry
        GlobalSettlementLike(globalSettlement).freeCollateral(collateralType);
    }

    // Public functions
    function freeETH(
        address manager,
        address ethJoin,
        address globalSettlement,
        uint safe
    ) external {
        uint wad = _freeCollateral(manager, globalSettlement, safe);
        // Exits WETH amount to proxy address as a token
        CollateralJoinLike(ethJoin).exit(address(this), wad);
        // Converts WETH to ETH
        CollateralJoinLike(ethJoin).collateral().withdraw(wad);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(wad);
    }

    function freeTokenCollateral(
        address manager,
        address collateralJoin,
        address globalSettlement,
        uint safe
    ) public {
        uint amt = _freeCollateral(manager, globalSettlement, safe) / 10 ** (18 - CollateralJoinLike(collateralJoin).decimals());
        // Exits token amount to the user's wallet as a token
        CollateralJoinLike(collateralJoin).exit(msg.sender, amt);
    }

    function prepareCoinsForRedeeming(
        address coinJoin,
        address globalSettlement,
        uint wad
    ) public {
        coinJoin_join(coinJoin, address(this), wad);
        SAFEEngineLike safeEngine = CoinJoinLike(coinJoin).safeEngine();
        // Approves the globalSettlement to take out COIN from the proxy's balance in the safeEngine
        if (safeEngine.canModifySAFE(address(this), address(globalSettlement)) == 0) {
            safeEngine.approveSAFEModification(globalSettlement);
        }
        GlobalSettlementLike(globalSettlement).prepareCoinsForRedeeming(wad);
    }

    function redeemETH(
        address ethJoin,
        address globalSettlement,
        bytes32 collateralType,
        uint wad
    ) public {
        GlobalSettlementLike(globalSettlement).redeemCollateral(collateralType, wad);
        uint collateralWad = multiply(wad, GlobalSettlementLike(globalSettlement).collateralCashPrice(collateralType)) / RAY;
        // Exits WETH amount to proxy address as a token
        CollateralJoinLike(ethJoin).exit(address(this), collateralWad);
        // Converts WETH to ETH
        CollateralJoinLike(ethJoin).collateral().withdraw(collateralWad);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(collateralWad);
    }

    function redeemTokenCollateral(
        address collateralJoin,
        address globalSettlement,
        bytes32 collateralType,
        uint wad
    ) public {
        GlobalSettlementLike(globalSettlement).redeemCollateral(collateralType, wad);
        // Exits token amount to the user's wallet as a token
        uint amt = multiply(wad, GlobalSettlementLike(globalSettlement).collateralCashPrice(collateralType)) / RAY / 10 ** (18 - CollateralJoinLike(collateralJoin).decimals());
        CollateralJoinLike(collateralJoin).exit(msg.sender, amt);
    }
}

contract GebProxyActionsCoinSavingsAccount is Common {

    function deposit(
        address coinJoin,
        address coinSavingsAccount,
        uint wad
    ) public {
        SAFEEngineLike safeEngine = CoinJoinLike(coinJoin).safeEngine();
        // Executes updateAccumulatedRate to get the accumulatedRates updated to latestUpdateTime == now, otherwise join will fail
        uint accumulatedRates = CoinSavingsAccountLike(coinSavingsAccount).updateAccumulatedRate();
        // Joins wad amount to the safeEngine balance
        coinJoin_join(coinJoin, address(this), wad);
        // Approves the coinSavingsAccount to take out COIN from the proxy's balance in the safeEngine
        if (safeEngine.canModifySAFE(address(this), address(coinSavingsAccount)) == 0) {
            safeEngine.approveSAFEModification(coinSavingsAccount);
        }
        // Joins the savings value (equivalent to the COIN wad amount) in the coinSavingsAccount
        CoinSavingsAccountLike(coinSavingsAccount).deposit(multiply(wad, RAY) / accumulatedRates);
    }

    function withdraw(
        address coinJoin,
        address coinSavingsAccount,
        uint wad
    ) public {
        SAFEEngineLike safeEngine = CoinJoinLike(coinJoin).safeEngine();
        // Executes updateAccumulatedRate to count the savings accumulated until this moment
        uint accumulatedRates = CoinSavingsAccountLike(coinSavingsAccount).updateAccumulatedRate();
        // Calculates the savings value in the coinSavingsAccount equivalent to the COIN wad amount
        uint savings = multiply(wad, RAY) / accumulatedRates;
        // Exits COIN from the coinSavingsAccount
        CoinSavingsAccountLike(coinSavingsAccount).withdraw(savings);
        // Checks the actual balance of COIN in the safeEngine after the coinSavingsAccount exit
        uint bal = CoinJoinLike(coinJoin).safeEngine().coinBalance(address(this));
        // Allows adapter to access to proxy's COIN balance in the safeEngine
        if (safeEngine.canModifySAFE(address(this), address(coinJoin)) == 0) {
            safeEngine.approveSAFEModification(coinJoin);
        }
        // It is necessary to check if due rounding the exact wad amount can be exited by the adapter.
        // Otherwise it will do the minimum COIN balance in the safeEngine
        CoinJoinLike(coinJoin).exit(
            msg.sender,
            bal >= multiply(wad, RAY) ? wad : bal / RAY
        );
    }

    function withdrawAll(
        address coinJoin,
        address coinSavingsAccount
    ) public {
        SAFEEngineLike safeEngine = CoinJoinLike(coinJoin).safeEngine();
        // Executes updateAccumulatedRate to count the savings accumulated until this moment
        uint accumulatedRates = CoinSavingsAccountLike(coinSavingsAccount).updateAccumulatedRate();
        // Gets the total savings belonging to the proxy address
        uint savings = CoinSavingsAccountLike(coinSavingsAccount).savings(address(this));
        // Exits COIN from the coinSavingsAccount
        CoinSavingsAccountLike(coinSavingsAccount).withdraw(savings);
        // Allows adapter to access to proxy's COIN balance in the safeEngine
        if (safeEngine.canModifySAFE(address(this), address(coinJoin)) == 0) {
            safeEngine.approveSAFEModification(coinJoin);
        }
        // Exits the COIN amount corresponding to the value of savings
        CoinJoinLike(coinJoin).exit(msg.sender, multiply(accumulatedRates, savings) / RAY);
    }
}

/// GebProxyActions.sol

// Copyright (C) 2018-2020 Maker Ecosystem Growth Holdings, INC.

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

pragma solidity 0.6.7;
pragma experimental ABIEncoderV2;

import "./GebProxyActions.sol";
import "./external/bunni/IBunniHub.sol";
import "./external/uni-v3/interfaces/IUniswapV3Pool.sol";

abstract contract TokenPoolLike {
    function token() public virtual view returns (DSTokenLike);
}

abstract contract GebIncentivesLike {
    function ancestorPool() virtual view public returns (TokenPoolLike);
    function rewardPool() virtual view public returns (TokenPoolLike);
    function join(uint256) virtual public;
    function exit(uint256) virtual public;
    function pendingRewards(address) virtual public view returns (uint256);
    function descendantBalanceOf(address) virtual public view returns (uint256);
    function getRewards() virtual public;
    function getRewards(address, address) virtual public;
}

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a DSProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

/// @title Incentives proxy actions
/// @notice This contract is supposed to be used alongside a DSProxy contract.
/// @dev These functions are meant to be used as a a library for a DSProxy. Some are unsafe if you call them directly.
contract GebProxyIncentivesActions {
    WethLike public immutable weth;

    constructor (address weth_) public {
        weth = WethLike(weth_);
    }



    // Internal functions

    /// @notice Provides liquidity on bunni.
    /// @param bunniHub Address of the bunni hub
    /// @param params The input parameters
    /// key The Bunni position's key
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return shares The new share tokens minted to the sender
    /// @return addedLiquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function _provideLiquidityBunni(address bunniHub, IBunniHub.DepositParams memory params) internal returns (uint, uint128, uint, uint) {
        DSTokenLike(params.key.pool.token0()).approve(bunniHub, params.amount0Desired);
        DSTokenLike(IUniswapV3Pool(params.key.pool).token1()).approve(bunniHub, params.amount1Desired);

        return IBunniHub(bunniHub).deposit(params);
    }

    /// @notice Stakes in Incentives Pool (geb-incentives)
    /// @param incentives address - Liquidity mining pool
    function _stakeInMine(address incentives) internal {
        DSTokenLike lpToken = GebIncentivesLike(incentives).ancestorPool().token();
        lpToken.approve(incentives, uint(-1));
        GebIncentivesLike(incentives).join(lpToken.balanceOf(address(this)));
    }

    /// @notice Removes liquidity from Bunni
    /// @param bunniHub Address of the bunni hub
    /// @param params The input parameters
    /// key The Bunni position's key
    /// recipient The user if not withdrawing ETH, address(0) if withdrawing ETH
    /// shares The amount of share tokens to burn,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return removedLiquidity The amount of liquidity decrease
    /// @return amount0 The amount of token0 withdrawn to the recipient
    /// @return amount1 The amount of token1 withdrawn to the recipient
    function _removeLiquidityBunni(address bunniHub, IBunniHub.WithdrawParams memory params) internal returns (uint128, uint, uint) {
        IBunniToken shareToken = IBunniHub(bunniHub).getBunniToken(params.key);
        shareToken.approve(bunniHub, params.shares);
        return IBunniHub(bunniHub).withdraw(params);
    }

    /// @notice Provides liquidity on bunni.
    /// @param bunniHub Address of the bunni hub
    /// @param params The input parameters
    /// key The Bunni position's key
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    function provideLiquidityBunni(address bunniHub, IBunniHub.DepositParams calldata params) external payable {
        weth.deposit{value: msg.value}();
        DSTokenLike token0 = DSTokenLike(IUniswapV3Pool(params.key.pool).token0());
        DSTokenLike token1 = DSTokenLike(IUniswapV3Pool(params.key.pool).token1());

        if (params.amount0Desired == msg.value) 
            token1.transferFrom(msg.sender, address(this), params.amount1Desired);
        else if (params.amount1Desired == msg.value) 
            token0.transferFrom(msg.sender, address(this), params.amount0Desired);
        else revert("invalid eth value");

        // return bunni tokens to user.
        (uint shares,,,) = _provideLiquidityBunni(bunniHub, params);  
        IBunniToken shareToken = IBunniHub(bunniHub).getBunniToken(params.key);
        shareToken.transfer(msg.sender, shareToken.balanceOf(address(this)));

        // sends tokens/eth back
        weth.withdraw(weth.balanceOf(address(this)));
        address(msg.sender).call{value: address(this).balance}("");

        if (address(token0) == address(weth)) {
            token1.transfer(msg.sender, token1.balanceOf(address(this)));
        } else {
            token0.transfer(msg.sender, token0.balanceOf(address(this)));
        }
    }

    /// @notice Stakes in liquidity mining pool
    /// @param incentives address - pool address
    /// @param wad uint - amount
    function stakeInMine(address incentives, uint wad) external {
        DSTokenLike lpToken = GebIncentivesLike(incentives).ancestorPool().token();
        lpToken.transferFrom(msg.sender, address(this), wad);
        _stakeInMine(incentives);
    }

    function provideLiquidityBunniAndStake(address bunniHub, IBunniHub.DepositParams calldata params, address incentives) external payable {
        weth.deposit{value: msg.value}();
        DSTokenLike token0 = DSTokenLike(IUniswapV3Pool(params.key.pool).token0());
        DSTokenLike token1 = DSTokenLike(IUniswapV3Pool(params.key.pool).token1());

        if (params.amount0Desired == msg.value) 
            token1.transferFrom(msg.sender, address(this), params.amount1Desired);
        else if (params.amount1Desired == msg.value) 
            token0.transferFrom(msg.sender, address(this), params.amount0Desired);
        else revert("invalid eth value");

        _provideLiquidityBunni(bunniHub, params);  
        _stakeInMine(incentives);    

        // sends tokens/eth back
        weth.withdraw(weth.balanceOf(address(this)));
        address(msg.sender).call{value: address(this).balance}("");

        if (address(token0) == address(weth)) {
            token1.transfer(msg.sender, token1.balanceOf(address(this)));
        } else {
            token0.transfer(msg.sender, token0.balanceOf(address(this)));
        }            
    }

    /// @notice Harvests rewards available 
    /// @param incentives address - Liquidity mining pool
    function getRewards(address incentives) public {
        GebIncentivesLike incentivesContract = GebIncentivesLike(incentives);
        DSTokenLike rewardToken = GebIncentivesLike(incentives).rewardPool().token();
        incentivesContract.getRewards();
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }

    /// @notice Harvests rewards available 
    /// @param incentives address - Liquidity mining pool
    function getRewards(address[] memory incentives) public {
        for (uint i; i < incentives.length; i++) getRewards(incentives[i]);
    }    

    /// @notice Harvests rewards available 
    /// @param safe Safe Id
    /// @param safeManager Safe manager address
    /// @param incentives Liquidity mining pooll
    function getDebtRewards(uint256 safe, address safeManager, address incentives) public {
        ManagerLike(safeManager).collectRewards(safe, incentives);
        DSTokenLike rewardToken = GebIncentivesLike(incentives).rewardPool().token();
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }    

    /// @notice Harvests rewards available 
    /// @param safes Safe Ids
    /// @param safeManager Safe manager address
    /// @param incentives Liquidity mining pool
    function getDebtRewards(uint256[] memory safes, address safeManager, address incentives) public {
        for (uint i; i < safes.length; i++)
            ManagerLike(safeManager).collectRewards(safes[i], incentives);
        DSTokenLike rewardToken = GebIncentivesLike(incentives).rewardPool().token();
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }  

    /// @notice Harvests rewards available on both types of rewards contracts (debt, others)
    /// @param safes Safe Ids
    /// @param safeManager Safe manager address
    /// @param debtIncentives Liquidity mining pool (debt)
    /// @param incentives Liquidity mining pool (others)
    function getMultipleRewards(uint256[] calldata safes, address safeManager, address debtIncentives, address[] calldata incentives) external {
        getDebtRewards(safes, safeManager, debtIncentives);
        getRewards(incentives);
    }      


    /// @notice Withdraw LP tokens from liquidity mining pool
    /// @param incentives address - Liquidity mining pool
    /// @param value uint - value to withdraw
    function withdrawFromMine(address incentives, uint value) external {
        GebIncentivesLike incentivesContract = GebIncentivesLike(incentives);
        DSTokenLike lpToken = GebIncentivesLike(incentives).ancestorPool().token();
        incentivesContract.exit(value);
        lpToken.transfer(msg.sender, lpToken.balanceOf(address(this)));
    }

    /// @notice Removes liquidity from Bunni
    /// @param bunniHub Address of the bunni hub
    /// @param params The input parameters
    /// key The Bunni position's key
    /// recipient The user if not withdrawing ETH, address(0) if withdrawing ETH
    /// shares The amount of share tokens to burn,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    function removeLiquidityBunni(address bunniHub, IBunniHub.WithdrawParams calldata params) external {
        IBunniToken shareToken = IBunniHub(bunniHub).getBunniToken(params.key);
        shareToken.transferFrom(msg.sender, address(this), params.shares);        
        _removeLiquidityBunni(bunniHub, params);

        DSTokenLike token0 = DSTokenLike(IUniswapV3Pool(params.key.pool).token0());
        DSTokenLike token1 = DSTokenLike(IUniswapV3Pool(params.key.pool).token1());        

        // sends tokens/eth back
        weth.withdraw(weth.balanceOf(address(this)));
        address(msg.sender).call{value: address(this).balance}("");

        if (address(token0) == address(weth)) {
            token1.transfer(msg.sender, token1.balanceOf(address(this)));
        } else {
            token0.transfer(msg.sender, token0.balanceOf(address(this)));
        }        
    }

    /// @notice Withdraws from liquidity mining pool and removes liquidity from Bunni
    /// @param bunniHub Address of the bunni hub
    /// @param params The input parameters
    /// key The Bunni position's key
    /// recipient The user if not withdrawing ETH, address(0) if withdrawing ETH
    /// shares The amount of share tokens to burn,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    function withdrawAndRemoveLiquidity(address incentives, uint value, address bunniHub, IBunniHub.WithdrawParams calldata params) external {
        GebIncentivesLike incentivesContract = GebIncentivesLike(incentives);
        incentivesContract.exit(value);
        _removeLiquidityBunni(bunniHub, params);

        DSTokenLike token0 = DSTokenLike(IUniswapV3Pool(params.key.pool).token0());
        DSTokenLike token1 = DSTokenLike(IUniswapV3Pool(params.key.pool).token1());        

        // sends tokens/eth back
        weth.withdraw(weth.balanceOf(address(this)));
        address(msg.sender).call{value: address(this).balance}("");

        if (address(token0) == address(weth)) {
            token1.transfer(msg.sender, token1.balanceOf(address(this)));
        } else {
            token0.transfer(msg.sender, token0.balanceOf(address(this)));
        }        
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import {IUniswapV3Pool} from "../uni-v3/interfaces/IUniswapV3Pool.sol";

import {IMulticall} from "../uni-v3/interfaces/IMulticall.sol";
import {ISelfPermit} from "../uni-v3/interfaces/ISelfPermit.sol";

import "./Structs.sol";
import {IERC20} from "./IERC20.sol";
import {IBunniToken} from "./IBunniToken.sol";
import {ILiquidityManagement} from "./ILiquidityManagement.sol";

/// @title BunniHub
/// @author zefram.eth
/// @notice The main contract LPs interact with. Each BunniKey corresponds to a BunniToken,
/// which is the ERC20 LP token for the Uniswap V3 position specified by the BunniKey.
/// Use deposit()/withdraw() to mint/burn LP tokens, and use compound() to compound the swap fees
/// back into the LP position.
interface IBunniHub is IMulticall, ISelfPermit, ILiquidityManagement {
    /// @notice Emitted when liquidity is increased via deposit
    /// @param sender The msg.sender address
    /// @param recipient The address of the account that received the share tokens
    /// @param bunniKeyHash The hash of the Bunni position's key
    /// @param liquidity The amount by which liquidity was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    /// @param shares The amount of share tokens minted to the recipient
    event Deposit(
        address indexed sender,
        address indexed recipient,
        bytes32 indexed bunniKeyHash,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1,
        uint256 shares
    );
    /// @notice Emitted when liquidity is decreased via withdrawal
    /// @param sender The msg.sender address
    /// @param recipient The address of the account that received the collected tokens
    /// @param bunniKeyHash The hash of the Bunni position's key
    /// @param liquidity The amount by which liquidity was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    /// @param shares The amount of share tokens burnt from the sender
    event Withdraw(
        address indexed sender,
        address indexed recipient,
        bytes32 indexed bunniKeyHash,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1,
        uint256 shares
    );
    /// @notice Emitted when fees are compounded back into liquidity
    /// @param sender The msg.sender address
    /// @param bunniKeyHash The hash of the Bunni position's key
    /// @param liquidity The amount by which liquidity was increased
    /// @param amount0 The amount of token0 added to the liquidity position
    /// @param amount1 The amount of token1 added to the liquidity position
    event Compound(
        address indexed sender,
        bytes32 indexed bunniKeyHash,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    /// @notice Emitted when a new IBunniToken is created
    /// @param bunniKeyHash The hash of the Bunni position's key
    /// @param pool The Uniswap V3 pool
    /// @param tickLower The lower tick of the Bunni's UniV3 LP position
    /// @param tickUpper The upper tick of the Bunni's UniV3 LP position
    event NewBunni(
        IBunniToken indexed token,
        bytes32 indexed bunniKeyHash,
        IUniswapV3Pool indexed pool,
        int24 tickLower,
        int24 tickUpper
    );
    /// @notice Emitted when protocol fees are paid to the factory
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount1 The amount of token1 protocol fees that is withdrawn
    event PayProtocolFee(uint256 amount0, uint256 amount1);
    /// @notice Emitted when the protocol fee has been updated
    /// @param newProtocolFee The new protocol fee
    event SetProtocolFee(uint256 newProtocolFee);

    /// @param key The Bunni position's key
    /// @param amount0Desired The desired amount of token0 to be spent,
    /// @param amount1Desired The desired amount of token1 to be spent,
    /// @param amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// @param amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// @param deadline The time by which the transaction must be included to effect the change
    /// @param recipient The recipient of the minted share tokens
    struct DepositParams {
        BunniKey key;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
        address recipient;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @dev Must be called after the corresponding BunniToken has been deployed via deployBunniToken()
    /// @param params The input parameters
    /// key The Bunni position's key
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return shares The new share tokens minted to the sender
    /// @return addedLiquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function deposit(DepositParams calldata params)
        external
        payable
        returns (
            uint256 shares,
            uint128 addedLiquidity,
            uint256 amount0,
            uint256 amount1
        );

    /// @param key The Bunni position's key
    /// @param recipient The user if not withdrawing ETH, address(0) if withdrawing ETH
    /// @param shares The amount of ERC20 tokens (this) to burn,
    /// @param amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// @param amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// @param deadline The time by which the transaction must be included to effect the change
    struct WithdrawParams {
        BunniKey key;
        address recipient;
        uint256 shares;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in the position and sends the tokens to the sender.
    /// If withdrawing ETH, need to follow up with unwrapWETH9() and sweepToken()
    /// @dev Must be called after the corresponding BunniToken has been deployed via deployBunniToken()
    /// @param params The input parameters
    /// key The Bunni position's key
    /// recipient The user if not withdrawing ETH, address(0) if withdrawing ETH
    /// shares The amount of share tokens to burn,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return removedLiquidity The amount of liquidity decrease
    /// @return amount0 The amount of token0 withdrawn to the recipient
    /// @return amount1 The amount of token1 withdrawn to the recipient
    function withdraw(WithdrawParams calldata params)
        external
        returns (
            uint128 removedLiquidity,
            uint256 amount0,
            uint256 amount1
        );

    /// @notice Claims the trading fees earned and uses it to add liquidity.
    /// @dev Must be called after the corresponding BunniToken has been deployed via deployBunniToken()
    /// @param key The Bunni position's key
    /// @return addedLiquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 added to the liquidity position
    /// @return amount1 The amount of token1 added to the liquidity position
    function compound(BunniKey calldata key)
        external
        returns (
            uint128 addedLiquidity,
            uint256 amount0,
            uint256 amount1
        );

    /// @notice Deploys the BunniToken contract for a Bunni position. This token
    /// represents a user's share in the Uniswap V3 LP position.
    /// @param key The Bunni position's key
    /// @return token The deployed BunniToken
    function deployBunniToken(BunniKey calldata key)
        external
        returns (IBunniToken token);

    /// @notice Returns the BunniToken contract for a Bunni position. This token
    /// represents a user's share in the Uniswap V3 LP position.
    /// If the contract hasn't been created yet, returns 0.
    /// @param key The Bunni position's key
    /// @return token The BunniToken contract
    function getBunniToken(BunniKey calldata key)
        external
        view
        returns (IBunniToken token);

    /// @notice Sweeps ERC20 token balances to a recipient. Mainly used for extracting protocol fees.
    /// Only callable by the owner.
    /// @param tokenList The list of ERC20 tokens to sweep
    /// @param recipient The token recipient address
    function sweepTokens(IERC20[] calldata tokenList, address recipient)
        external;

    /// @notice Updates the protocol fee value. Scaled by 1e18. Only callable by the owner.
    /// @param value The new protocol fee value
    function setProtocolFee(uint256 value) external;

    /// @notice Returns the protocol fee value. Decimal value <1, scaled by 1e18.
    function protocolFee() external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;

import {IUniswapV3Pool} from "../uni-v3/interfaces/IUniswapV3Pool.sol";

import {IERC20} from "./IERC20.sol";
import {IBunniHub} from "./IBunniHub.sol";

/// @title BunniToken
/// @author zefram.eth
/// @notice ERC20 token that represents a user's LP position
interface IBunniToken is IERC20 {
    function pool() external view returns (IUniswapV3Pool);

    function tickLower() external view returns (int24);

    function tickUpper() external view returns (int24);

    function hub() external view returns (IBunniHub);

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * Modified from OpenZeppelin's IERC20 contract
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @return The name of the token
     */
    function name() external view returns (string memory);

    /**
     * @return The symbol of the token
     */
    function symbol() external view returns (string memory);

    /**
     * @return The number of decimal places the token has
     */
    function decimals() external view returns (uint8);

    function nonces(address account) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.5.0;

import {IUniswapV3Factory} from "../uni-v3/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3MintCallback} from "../uni-v3/interfaces/callback/IUniswapV3MintCallback.sol";

/// @title Liquidity management functions
/// @notice Internal functions for safely managing liquidity in Uniswap V3
interface ILiquidityManagement is IUniswapV3MintCallback {
    function factory() external view returns (IUniswapV3Factory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import {IUniswapV3Pool} from "../uni-v3/interfaces/IUniswapV3Pool.sol";

/// @param pool The Uniswap V3 pool
/// @param tickLower The lower tick of the Bunni's UniV3 LP position
/// @param tickUpper The upper tick of the Bunni's UniV3 LP position
struct BunniKey {
    IUniswapV3Pool pool;
    int24 tickLower;
    int24 tickUpper;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.5;
pragma experimental ABIEncoderV2;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.5;

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
interface ISelfPermit {
    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// Can be used instead of #selfPermit to prevent calls from failing due to a frontrun of a call to #selfPermit
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// Can be used instead of #selfPermitAllowed to prevent calls from failing due to a frontrun of a call to #selfPermitAllowed.
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#mint
/// @notice Any contract that calls IUniswapV3PoolActions#mint must implement this interface
interface IUniswapV3MintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
  /// @notice Sets the initial price for the pool
  /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
  /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
  function initialize(uint160 sqrtPriceX96) external;

  /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
  /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
  /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
  /// on tickLower, tickUpper, the amount of liquidity, and the current price.
  /// @param recipient The address for which the liquidity will be created
  /// @param tickLower The lower tick of the position in which to add liquidity
  /// @param tickUpper The upper tick of the position in which to add liquidity
  /// @param amount The amount of liquidity to mint
  /// @param data Any data that should be passed through to the callback
  /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
  /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
  function mint(
    address recipient,
    int24 tickLower,
    int24 tickUpper,
    uint128 amount,
    bytes calldata data
  ) external returns (uint256 amount0, uint256 amount1);

  /// @notice Collects tokens owed to a position
  /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
  /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
  /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
  /// actual tokens owed, e.g. (0 - uint128(1)). Tokens owed may be from accumulated swap fees or burned liquidity.
  /// @param recipient The address which should receive the fees collected
  /// @param tickLower The lower tick of the position for which to collect fees
  /// @param tickUpper The upper tick of the position for which to collect fees
  /// @param amount0Requested How much token0 should be withdrawn from the fees owed
  /// @param amount1Requested How much token1 should be withdrawn from the fees owed
  /// @return amount0 The amount of fees collected in token0
  /// @return amount1 The amount of fees collected in token1
  function collect(
    address recipient,
    int24 tickLower,
    int24 tickUpper,
    uint128 amount0Requested,
    uint128 amount1Requested
  ) external returns (uint128 amount0, uint128 amount1);

  /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
  /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
  /// @dev Fees must be collected separately via a call to #collect
  /// @param tickLower The lower tick of the position for which to burn liquidity
  /// @param tickUpper The upper tick of the position for which to burn liquidity
  /// @param amount How much liquidity to burn
  /// @return amount0 The amount of token0 sent to the recipient
  /// @return amount1 The amount of token1 sent to the recipient
  function burn(
    int24 tickLower,
    int24 tickUpper,
    uint128 amount
  ) external returns (uint256 amount0, uint256 amount1);

  /// @notice Swap token0 for token1, or token1 for token0
  /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
  /// @param recipient The address to receive the output of the swap
  /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
  /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
  /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
  /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
  /// @param data Any data to be passed through to the callback
  /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
  /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
  function swap(
    address recipient,
    bool zeroForOne,
    int256 amountSpecified,
    uint160 sqrtPriceLimitX96,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);

  /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
  /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
  /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
  /// with 0 amount{0,1} and sending the donation amount(s) from the callback
  /// @param recipient The address which will receive the token0 and token1 amounts
  /// @param amount0 The amount of token0 to send
  /// @param amount1 The amount of token1 to send
  /// @param data Any data to be passed through to the callback
  function flash(
    address recipient,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
  ) external;

  /// @notice Increase the maximum number of price and liquidity observations that this pool will store
  /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
  /// the input observationCardinalityNext.
  /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
  function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns a relative timestamp value representing how long, in seconds, the pool has spent between
    /// tickLower and tickUpper
    /// @dev This timestamp is strictly relative. To get a useful elapsed time (i.e., duration) value, the value returned
    /// by this method should be checkpointed externally after a position is minted, and again before a position is
    /// burned. Thus the external contract must control the lifecycle of the position.
    /// @param tickLower The lower tick of the range for which to get the seconds inside
    /// @param tickUpper The upper tick of the range for which to get the seconds inside
    /// @return A relative timestamp for how long the pool spent in the tick range
    function secondsInside(int24 tickLower, int24 tickUpper) external view returns (uint32);

    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return liquidityCumulatives Cumulative liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory liquidityCumulatives);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// feeGrowthOutsideX128 values can only be used if the tick is initialized,
    /// i.e. if liquidityGross is greater than 0. In addition, these values are only relative and are used to
    /// compute snapshots.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns 8 packed tick seconds outside values. See SecondsOutside for more information
    function secondsOutside(int24 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the current tick multiplied by seconds elapsed for the life of the pool as of the
    /// observation,
    /// Returns liquidityCumulative the current liquidity multiplied by seconds elapsed for the life of the pool as of
    /// the observation,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 liquidityCumulative,
            bool initialized
        );
}